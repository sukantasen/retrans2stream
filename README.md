# Adapting Retranslation to Streaming in Simultaneous Translation
Please to refer to https://aclanthology.org/2021.iwslt-1.4.pdf

# Building the Docker
You can use the docker that we submitted to IWSLT2021
(wget https://data.statmt.org/sukanta/retrans2stream/edin.iwslt2021.v4.tar)

OR

Download the models https://data.statmt.org/sukanta/retrans2stream/model

Build docker by executing
`make docker-build`

Save the docker by executing
`make docker-save`

# Running the Baseline System

Run the baseline system using

`./run.sh <source file> <reference file>`

additionally you can pass

`--dynamic_mask` for dynamic mask

and/or `--lm <KenLM file>` for LM Score
