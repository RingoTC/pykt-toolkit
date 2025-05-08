#!/bin/bash

# 定义数据集列表
# datasets=("assist2009" "algebra2005" "bridge2algebra2006" "nips_task34" "statics2011" "assist2015" "poj")

datasets=("assist2009")

# 定义基础保存目录
BASE_SAVE_DIR="/home/wujingchao/pykt-toolkit/examples/saved_model"

rm -rf $BASE_SAVE_DIR/*

# 检查是否提供了模型名称
if [ -z "$1" ]; then
    echo "Usage: $0 <model_name>"
    echo "Available models: routerkt, akt, simplekt, dkt"
    exit 1
fi

MODEL_NAME=$1

# 训练函数
train_model() {
    local dataset=$1
    local fold=$2
    local model=$3
    echo "训练数据集: $dataset, Fold: $fold, 模型: $model"
    
    case $model in
        "routerkt")
            python wandb_routerkt_train.py --dataset_name=$dataset --fold $fold
            ;;
        "akt")
            python wandb_akt_train.py --dataset_name=$dataset --fold $fold
            ;;
        "simplekt")
            python wandb_simplekt_train.py --dataset_name=$dataset --fold $fold
            ;;
        "dkt")
            python wandb_dkt_train.py --dataset_name=$dataset --fold $fold
            ;;
        *)
            echo "Unknown model: $model"
            exit 1
            ;;
    esac
}

# 评测函数
evaluate_model() {
    local dataset=$1
    local fold=$2
    local model_dir=$3
    echo "评估模型: $model_dir"
    python wandb_predict.py --save_dir "$model_dir"
}

# 主循环
for dataset in "${datasets[@]}"; do
    echo "Processing dataset: $dataset"
    
    # 对每个fold进行训练和评测
    for fold in {0..4}; do
        echo "Starting fold $fold for $dataset"
        
        # 训练模型
        train_model $dataset $fold $MODEL_NAME
        
        # 等待训练完成
        sleep 5
        
        # 查找对应的模型目录
        model_dir=$(find $BASE_SAVE_DIR -maxdepth 1 -type d -name "${dataset}_${MODEL_NAME}_qid_saved_model_*_${fold}_*" | sort -r | head -n 1)
        
        if [ -z "$model_dir" ]; then
            echo "Warning: Could not find model directory for $dataset fold $fold"
            echo "模型目录: $model_dir"
            continue
        fi
        
        # 评测模型
        evaluate_model $dataset $fold "$model_dir"
        
        # 等待评测完成
        sleep 5
    done
done

echo "All training and evaluation completed!"