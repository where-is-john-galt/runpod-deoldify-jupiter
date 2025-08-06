# CUDA 11.8 + cuDNN 8 + Ubuntu 20.04
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Instalacja narzędzi systemowych i repozytorium Deadsnakes
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    build-essential \
    git \
    curl \
    ca-certificates \
    wget \
    gnupg \
    ffmpeg \
    libsm6 \
    libxext6 \
    python3.7 \
    python3.7-venv \
    python3.7-distutils \
    && rm -rf /var/lib/apt/lists/*

# Instalacja pip dla Python 3.7
RUN curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
 && python3.7 get-pip.py \
 && rm get-pip.py

# Ustawienie python/pip domyślnie na wersję 3.7
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1 \
 && update-alternatives --install /usr/bin/pip pip /usr/local/bin/pip 1

# Konfiguracja SSH i użytkowników
RUN mkdir /var/run/sshd \
 && echo "root:root" | chpasswd \
 && useradd -m developer \
 && echo "developer:developer" | chpasswd \
 && sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config \
 && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# Instalacja bibliotek Python (kompatybilnych z DeOldify)
RUN pip install --upgrade pip \
 && pip install \
    numpy==1.19.5 \
    pandas \
    matplotlib \
    fastai==1.0.61 \
    opencv-python==4.1.2.30 \
    Pillow==6.2.2 \
    jupyterlab \
    ipywidgets \
    notebook \
    jupyter-server \
    jupyterlab-git \
    torchvision==0.8.2 \
    torch==1.7.1+cu110 \
    -f https://download.pytorch.org/whl/torch_stable.html

# Ustawienie katalogu roboczego
WORKDIR /workspace
RUN chown developer:developer /workspace

# Pobranie DeOldify
RUN git clone https://github.com/jantic/DeOldify.git /workspace/DeOldify \
 && cd /workspace/DeOldify && git checkout master

# Pobranie pretrenowanego modelu
RUN mkdir -p /workspace/DeOldify/models \
 && cd /workspace/DeOldify/models \
 && wget https://data.deepai.org/deoldify/ColorizeArtistic_gen.pth

# Tworzenie folderów input/output
RUN mkdir -p /workspace/input_images /workspace/output_images

# Eksponowanie portów: JupyterLab (8888) i SSH (2222)
EXPOSE 8888 2222

# Start SSH i JupyterLab
CMD ["bash", "-c", "service ssh start && jupyter]()
