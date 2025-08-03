# Base image -> https://github.com/runpod/containers/blob/main/official-templates/base/Dockerfile
# DockerHub -> https://hub.docker.com/r/runpod/base/tags
FROM runpod/base:0.6.2-cuda12.1.0

# The base image comes with many system dependencies pre-installed to help you get started quickly.
# Please refer to the base image's Dockerfile for more information before adding additional dependencies. [cite: 2]
# IMPORTANT: The base image overrides the default huggingface cache location. [cite: 3]
WORKDIR /app

# Python dependencies
COPY builder/requirements.txt /requirements.txt
# Zmieniono wersję Pythona z 3.11 na 3.9, aby była kompatybilna z pakietem torch==1.11.0
RUN python3.9 -m pip install --upgrade pip && \
    python3.9 -m pip install --upgrade -r /requirements.txt --no-cache-dir && \
    rm /requirements.txt

RUN git clone https://github.com/jantic/DeOldify.git /app

# Add src files (Worker Template)
ADD src /app

RUN wget -O models/ColorizeArtistic_gen.pth https://data.deepai.org/deoldify/ColorizeArtistic_gen.pth

CMD sleep infinity