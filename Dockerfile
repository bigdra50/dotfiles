ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential packages
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    wget \
    git \
    zsh \
    build-essential \
    ca-certificates \
    locales \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Generate locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create a non-root user with sudo privileges
ARG USERNAME=dotuser
ARG USER_UID=1001
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && chsh -s /bin/zsh $USERNAME

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME

# Copy dotfiles repository
COPY --chown=$USERNAME:$USERNAME . /home/$USERNAME/dev/github.com/bigdra50/dotfiles/

# Configure git safe directory for Docker environment
RUN git config --global --add safe.directory /home/$USERNAME/dev/github.com/bigdra50/dotfiles

# Set PATH for subsequent commands
ENV PATH="/home/$USERNAME/.local/bin:$PATH"

WORKDIR /home/$USERNAME/dev/github.com/bigdra50/dotfiles

# Set zsh as the default shell for the container
CMD ["/bin/zsh"]