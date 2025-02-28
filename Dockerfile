FROM nvidia/cuda:11.3.1-cudnn8-devel-ubuntu18.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3.8 \
    python3.8-dev \
    python3-pip \
    wget \
    ffmpeg \
    portaudio19-dev \
    && rm -rf /var/lib/apt/lists/*

# Install conda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /miniconda.sh \
    && bash /miniconda.sh -b -p /opt/conda \
    && rm /miniconda.sh

# Add conda to path
ENV PATH=/opt/conda/bin:$PATH

# Create conda environment
RUN conda create -n synctalk python=3.8.8 -y \
    && conda init bash \
    && echo "conda activate synctalk" >> ~/.bashrc

# Copy PyTorch3D installation script
COPY scripts/install_pytorch3d.py /tmp/install_pytorch3d.py

# Set CUDA environment variables
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}
ENV TORCH_CUDA_ARCH_LIST="6.0 6.1 7.0 7.5 8.0 8.6"

# Install build tools
RUN apt-get update && apt-get install -y \
    build-essential \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

# Install PyTorch and dependencies
RUN /opt/conda/envs/synctalk/bin/pip install torch==1.12.1+cu113 torchvision==0.13.1+cu113 torchaudio==0.12.1 --extra-index-url https://download.pytorch.org/whl/cu113 \
    && /opt/conda/envs/synctalk/bin/pip install fvcore iopath \
    && /opt/conda/envs/synctalk/bin/python /tmp/install_pytorch3d.py \
    && /opt/conda/envs/synctalk/bin/pip install tensorflow-gpu==2.8.1

WORKDIR /app/SyncTalk

# Copy the requirements and custom packages
COPY requirements.txt .
COPY freqencoder ./freqencoder
COPY shencoder ./shencoder
COPY gridencoder ./gridencoder
COPY raymarching ./raymarching

# Install remaining requirements
RUN /opt/conda/envs/synctalk/bin/pip install -r requirements.txt \
    && /opt/conda/envs/synctalk/bin/pip install ./freqencoder \
    && /opt/conda/envs/synctalk/bin/pip install ./shencoder \
    && /opt/conda/envs/synctalk/bin/pip install ./gridencoder \
    && /opt/conda/envs/synctalk/bin/pip install ./raymarching

# Set the default conda environment
SHELL ["conda", "run", "-n", "synctalk", "/bin/bash", "-c"]

# Set working directory
WORKDIR /app/SyncTalk

CMD ["/bin/bash"]
