#!/bin/bash

# 定义数据集列表
datasets=("assist2009")

# 定义基础保存目录
BASE_SAVE_DIR="/home/wujingchao/pykt-toolkit/examples/saved_model"

# 训练函数
train_model() {
    local dataset=$1
    local fold=$2
    echo "Training on dataset: $dataset, fold: $fold"
    python wandb_routerkt_train.py --dataset_name=$dataset --fold $fold
}

# 评测函数
evaluate_model() {
    local dataset=$1
    local fold=$2
    local model_dir=$3
    echo "Evaluating model: $model_dir"
    python wandb_predict.py --save_dir "$model_dir"
}

# 主循环
for dataset in "${datasets[@]}"; do
    echo "Processing dataset: $dataset"
    
    # 对每个fold进行训练和评测
    for fold in {0..4}; do
        echo "Starting fold $fold for $dataset"
        
        # 训练模型
        train_model $dataset $fold
        
        # 等待训练完成
        sleep 5
        
        # 查找对应的模型目录
        model_dir=$(find $BASE_SAVE_DIR -maxdepth 1 -type d -name "${dataset}_routerkt_qid_saved_model_*_${fold}_*" | sort -r | head -n 1)
        
        if [ -z "$model_dir" ]; then
            echo "Warning: Could not find model directory for $dataset fold $fold"
            continue
        fi
        
        # 评测模型
        evaluate_model $dataset $fold "$model_dir"
        
        # 等待评测完成
        sleep 5
    done
done

echo "All training and evaluation completed!"