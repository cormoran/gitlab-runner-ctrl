#!/usr/bin/env bash
# mapping from gpu name to tag
function get_gpu_level_tag() {
    if [ $1 = "GeForce-GTX-980-Ti" ]; then
        echo ",G9"
    elif [ $1 = "GeForce-GTX-1080" ]; then
        echo ",G10"
    elif [ $1 = "GeForce-GTX-1080-Ti" ]; then
        echo ",G10"
    elif [ $1 = "GeForce-RTX-2080-Ti" ]; then
        echo ",G10,G20"
    elif [ $1 = "TITAN-V" ]; then
        echo ",G10,G20"
    else
        echo ""
    fi
}

docker-compose up -d
docker-compose exec gitlab-runner gitlab-runner verify --delete
GPU_ID=0
for GPU in $(nvidia-smi --query-gpu=name --format=csv,noheader | sed "s/ /-/g");
do
    SERVER=$(uname -n | sed 's/\..*//g')
    NAME="${SERVER} ${GPU} ${GPU_ID}"
    if docker-compose exec gitlab-runner gitlab-runner list | grep -q "$NAME" > /dev/null; then
        echo "$NAME is already registerd."
    else
        docker-compose exec gitlab-runner gitlab-runner register --non-interactive \
        --url "TODO: PASTE GITLAB URL HERE" \
        --registration-token "TODO: PASTE GITLAB TOKEN HERE" \
        --name "$NAME" \
        --limit 1 \
        --executor docker \
        --env "NVIDIA_VISIBLE_DEVICES=all" \
        --env "NVIDIA_DRIVER_CAPABILITIES=utility,compute" \
        --env "CUDA_VISIBLE_DEVICES=${GPU_ID}" \
        --tag-list "${GPU},${SERVER}$(get_gpu_level_tag $GPU)" \
        --docker-image continuumio/miniconda \
        --docker-runtime nvidia \
        --docker-shm-size 10737418240
    fi
    GPU_ID=$(expr $GPU_ID + 1)
done

sed -i "s/^concurrent = .*$/concurrent = ${GPU_ID}/g" ./config/config.toml
