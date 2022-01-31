# Copyright (c) Facebook, Inc. and its affiliates.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

from simuleval.agents import TextAgent
from simuleval import READ_ACTION, WRITE_ACTION, DEFAULT_EOS
import websocket
import kenlm
import sentencepiece

class Translator():

    def __init__(self, lm_model, port, bpe_code, dynamic_mask):
        self.hyp = []
        self.ws = websocket.create_connection("ws://localhost:{}/translate".format(port))
        self.lm = None
        self.full_sent = False
        if lm_model:
           self.lm = kenlm.Model(lm_model)
           self.lm_score = float('inf')
        self.spm = sentencepiece.SentencePieceProcessor(model_file=bpe_code)
        self.dynamic_mask = dynamic_mask

    def reset(self):
         self.hyp = []
         self.full_sent = False
         self.lm_score = float('inf')

    def marian(self, src, trg=""):
        if not self.ws:
            print("Marian is not running.")
            exit()
        src = " ".join(self.spm.encode(src, out_type=str))
        self.ws.send(src + trg)
        out = self.ws.recv()
        out = out.replace(" ","").replace("\u2581", " ")
        return out
 
    def translate(self, src, is_finished=False):
        # check with lm score
        if self.lm:
            prev_score = self.lm_score
            self.lm_score = self.get_lm_score(src)
            # the current score is higher than prev, read more words
            if self.lm_score > prev_score:
                return ""

        if not self.full_sent:
            self.out = self.marian(src)
            self.out = self.out.strip().split(" ")
            if self.dynamic_mask and not is_finished:
                self.out = self.masked_out(src)
            self.full_sent = is_finished
        return self.next_word()

    def common_prefix(self, p1, p2):
        idx = 0
        for s, t in zip(p1, p2):
           if s != t:
                break
           idx += 1
        return p1[:idx]

    def masked_out(self, src):
        src = src + " <unk>"
        out = self.marian(src).strip().split(" ")
        return self.common_prefix(out, self.out)

    def next_word(self):
        hyp_len = len(self.hyp)
        if len(self.out) > hyp_len:
            word = self.out[hyp_len]
            #self.flicker()
            self.hyp.append(word)
            return word
        else:
            return ""
 
    def get_lm_score(self, sent):
        sent_prefix = " ".join(sent.split(" ")[:-1])
        return self.lm.score(sent_prefix, bos = True, eos = False) \
               - self.lm.score(sent, bos = True, eos = False)

class DummyWaitkTextAgent(TextAgent):

    data_type = "text"

    def __init__(self, args):
        super().__init__(args)
        self.waitk = args.waitk
        # Initialize your agent here, for example load model, vocab, etc
        self.translator = Translator(args.lm, args.marian_port, args.bpe_code, args.dynamic_mask)
        print(args)

    @staticmethod
    def add_args(parser):
        # Add additional command line arguments here
        parser.add_argument("--waitk", type=int, default=3)
        parser.add_argument("--lm", default=None)
        parser.add_argument("--marian_port", type=int, default=8080)
        parser.add_argument("--bpe_code")
        parser.add_argument("--dynamic_mask", action="store_true")

    def policy(self, states):
        # Make decision here
        if len(states.source) - len(states.target) < self.waitk and not states.finish_read():
            return READ_ACTION
        else:
            src = " ".join(states.source.value)
            self.next_word = self.translator.translate(src, states.finish_read())
            if not self.next_word and not states.finish_read():
               return READ_ACTION
            else: #if not finished
               return WRITE_ACTION
             
    def predict(self, states):
        # predict token here
        if not self.next_word:
            self.translator.reset()
            return DEFAULT_EOS
        return self.next_word

