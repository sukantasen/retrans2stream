#!/bin/bash

set -e 

SRC=${1:-tst.COMMON.en}
TRG=${2:-tst.COMMON.de}
out=${3:-output}
gpu_id=0
dockername=ediniwslt

mkdir -p $out
chmod 777 $out

COMMAND="-n 1.0 -b 12 -d $gpu_id"
echo "Starting the docker in background..."
docker run --gpus all -e COMMAND="$COMMAND" --rm -d \
 -v $(dirname $(readlink -f $SRC)):/mt/src \
 -v $(dirname $(readlink -f $TRG)):/mt/trg \
 -v $PWD/agent:/mt/agent \
 -v $PWD/$out:/mt/out \
 --name $dockername edin.iwslt2021.v4

echo "Running SimulEval..."

docker exec -i $dockername \
  simuleval --agent /mt/agent/agent.py \
    --source /mt/src/$(basename $1) \
    --target /mt/trg/$(basename $2) \
    --waitk 3 \
    --bpe_code /mt/model/spm.32000.en-de.model \
    --output /mt/out/base.k$k

echo "Stopping the docker..."
docker stop $dockername
