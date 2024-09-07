#!/bin/bash

# Runs the "340M" parameter model (Bert - Large)

export CUDA_DEVICE_MAX_CONNECTIONS=1

GPUS_PER_NODE=4
NUM_NODES=2
WORLD_SIZE=$(($GPUS_PER_NODE * $NUM_NODES))

echo "GPUS_PER_NODE: $GPUS_PER_NODE"
echo "NUM_NODES: $NUM_NODES"
echo "Calculated WORLD_SIZE: $WORLD_SIZE"

CHECKPOINT_PATH=$1
TENSORBOARD_LOGS_PATH=$2
VOCAB_FILE=$3
DATA_PATH=$4

export NODE_RANK=${NODE_RANK:-0} # Default to 0 if not set
export MASTER_ADDR=${MASTER_ADDR:-"bert-4b-training-0.bert-4b-training.default.svc.cluster.local"}
export MASTER_PORT=${MASTER_PORT:-"23456"}

DISTRIBUTED_ARGS=(
    --nproc_per_node $GPUS_PER_NODE 
    --nnodes $NUM_NODES 
    --node_rank $NODE_RANK 
    --master_addr $MASTER_ADDR 
    --master_port $MASTER_PORT
)

BERT_MODEL_ARGS=(
    --num-layers 24 
    --hidden-size 1024 
    --num-attention-heads 16 
    --seq-length 512 
    --max-position-embeddings 512 
)

TRAINING_ARGS=(
    --micro-batch-size 4 
    --global-batch-size 32 
    --train-iters 1000000 
    --weight-decay 1e-2 
    --clip-grad 1.0 
    --fp16
    --lr 0.0001
    --lr-decay-iters 990000 
    --lr-decay-style linear 
    --min-lr 1.0e-5 
    --weight-decay 1e-2 
    --lr-warmup-fraction .01 
    --clip-grad 1.0 
)

MODEL_PARALLEL_ARGS=(
    --tensor-model-parallel-size 2
    --pipeline-model-parallel-size 2
)

DATA_ARGS=(
    --data-path $DATA_PATH 
    --vocab-file $VOCAB_FILE 
    --split 949,50,1
)

EVAL_AND_LOGGING_ARGS=(
    --log-interval 100
    --save-interval 10000 
    --eval-interval 1000 
    --save $CHECKPOINT_PATH 
    --load $CHECKPOINT_PATH 
    --eval-iters 10
    --tensorboard-dir $TENSORBOARD_LOGS_PATH 
)

torchrun ${DISTRIBUTED_ARGS[@]} pretrain_bert.py \
    ${BERT_MODEL_ARGS[@]} \
    ${TRAINING_ARGS[@]} \
    ${MODEL_PARALLEL_ARGS[@]} \
    ${DATA_ARGS[@]} \
    ${EVAL_AND_LOGGING_ARGS[@]}
