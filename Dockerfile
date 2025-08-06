# CUDA 11.8 + cuDNN 8 + Ubuntu 20.04
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Dodaj repozytorium deadsnakes i zainstaluj Python 3.7
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
    python3.7-dev \
    python3.7-venv \
    && rm -rf /var/lib/apt/lists/*

# Konfiguracja SSH i użytkowników
RUN mkdir /var/run/sshd \
 && echo "root:root" | chpasswd \
 && useradd -m developer \
 && echo "developer:developer" | chpasswd \
 && sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config \
 && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# Ustaw Python 3.7 jako domyślny
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.7 1 \
 && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Instalacja bibliotek Python (DeOldify-kompatybilnych)
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

# Katalog roboczy
WORKDIR /workspace
RUN chown developer:developer /workspace

# Pobierz DeOldify z GitHuba
RUN git clone https://github.com/jantic/DeOldify.git /workspace/DeOldify \
 && cd /workspace/DeOldify && git checkout master

# Pobierz pretrenowane modele (colorizer art)
RUN mkdir -p /workspace/DeOldify/models \
 && cd /workspace/DeOldify/models \
 && wget https://data.deepai.org/deoldify/ColorizeArtistic_gen.pth

# Dodaj przykładowy notebook (uruchamiający DeOldify)
# COPY --chown=developer:developer deoldify_example.ipynb /workspace/DeOldify/deoldify_example.ipynb

# Eksponuj porty: 8888 (Jupyter), 2222 (SSH)
EXPOSE 8888 2222

# Start SSH + Jupyter
CMD service ssh start && \
    cd /workspace/DeOldify && \
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password=''
