FROM nvcr.io/nvidia/pytorch:23.05-py3

#install ffmpeg and sudo
RUN apt update && \
        apt install -y software-properties-common && \
        add-apt-repository -y ppa:jonathonf/ffmpeg-4 && \
        apt install -y ffmpeg && \
        apt install -y sudo && \
        rm -rf /var/lib/apt/lists/*

#install git-lfs
COPY script.deb.sh script.deb.sh
RUN bash script.deb.sh && \
        apt install -y git-lfs -y && \
        git lfs install

#install requirements
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt && \
        pip uninstall -y jupyterlab_widgets && \
        pip install jupyterlab_widgets

# Prepare for SM Studio

ARG NB_USER="sagemaker-user"
ARG NB_UID="1000"
ARG NB_GID="100"

######################
# OVERVIEW
# 1. Creates the `sagemaker-user` user with UID/GID 1000/100.
# 2. Ensures this user can `sudo` by default. 
# 3. Installs and configures Poetry, then installs the environment defined in pyproject.toml
# 4. Configures the kernel (ipykernel should be installed on the parent image or defined in pyproject.toml)
# 5. Make the default shell `bash`. This enhances the experience inside a Jupyter terminal as otherwise Jupyter defaults to `sh`
######################

# Setup the "sagemaker-user" user with root privileges.

RUN \
    useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    chmod g+w /etc/passwd && \
    echo "${NB_USER}    ALL=(ALL)    NOPASSWD:    ALL" >> /etc/sudoers && \
    # Prevent apt-get cache from being persisted to this layer.
    rm -rf /var/lib/apt/lists/*

# Install and configure the kernel. 
RUN pip install ipykernel && \
        python -m ipykernel install --sys-prefix

# Make the default shell bash (vs "sh") for a better Jupyter terminal UX
ENV SHELL=/bin/bash

USER $NB_UID
