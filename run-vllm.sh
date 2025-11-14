#!/bin/bash

# Run vLLM Docker container with Qwen2.5-7B-Instruct-AWQ model
# Usage: ./run-vllm.sh

# Change to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Environment variables (plain ASCII quotes only)
# NOTE: Set these in your environment or .env file - do not commit secrets!
# export HF_TOKEN="your-huggingface-token-here"
# export VLLM_API_KEY="your-vllm-api-key-here"

echo "=========================================="
echo "  Starting vLLM Docker Container"
echo "=========================================="
echo ""
echo "Model: Qwen/Qwen2.5-7B-Instruct-AWQ"
echo "Port: 8001 (mapped to container port 8000)"
echo "API Key: ${VLLM_API_KEY:0:20}..."
echo ""

# Check if container already exists
if docker ps -a --format '{{.Names}}' | grep -q "^vllm-qwen7b-awq$"; then
    echo "Container 'vllm-qwen7b-awq' already exists."
    read -p "Do you want to remove it and start fresh? (y/N): " REMOVE
    
    if [[ "$REMOVE" =~ ^[Yy]$ ]]; then
        echo "Stopping and removing existing container..."
        docker stop vllm-qwen7b-awq 2>/dev/null
        docker rm vllm-qwen7b-awq 2>/dev/null
        echo "Container removed."
        echo ""
    else
        echo "Starting existing container..."
        docker start vllm-qwen7b-awq
        echo "Container started. Check logs with: docker logs -f vllm-qwen7b-awq"
        exit 0
    fi
fi

echo "Starting Docker container..."
echo ""

docker run -d \
  --name vllm-qwen7b-awq \
  -p 8001:8000 \
  --gpus all \
  --restart=no \
  -e HF_HUB_ENABLE_HF_TRANSFER=1 \
  -e HUGGING_FACE_HUB_TOKEN="$HF_TOKEN" \
  -e VLLM_API_KEY="$VLLM_API_KEY" \
  -e CUDA_VISIBLE_DEVICES=0 \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  vllm/vllm-openai:latest \
  --host 0.0.0.0 \
  --api-key "$VLLM_API_KEY" \
  --model Qwen/Qwen2.5-7B-Instruct-AWQ \
  --quantization awq_marlin \
  --dtype auto \
  --download-dir /root/.cache/huggingface \
  --max-model-len 768 \
  --max-num-seqs 1 \
  --max-num-batched-tokens 512 \
  --gpu-memory-utilization 0.15 \
  --swap-space 0 \
  --enforce-eager

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "  Container Started Successfully"
    echo "=========================================="
    echo ""
    echo "Container name: vllm-qwen7b-awq"
    echo "API endpoint: http://localhost:8001/v1"
    echo ""
    echo "Useful commands:"
    echo "  View logs:    docker logs -f vllm-qwen7b-awq"
    echo "  Stop:         docker stop vllm-qwen7b-awq"
    echo "  Remove:       docker rm -f vllm-qwen7b-awq"
    echo "  Status:       docker ps | grep vllm-qwen7b-awq"
    echo ""
else
    echo ""
    echo "=========================================="
    echo "  Error Starting Container"
    echo "=========================================="
    echo ""
    echo "Check Docker logs for details."
    exit 1
fi

