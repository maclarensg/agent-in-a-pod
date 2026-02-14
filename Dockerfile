FROM ubuntu:24.04

ARG USERNAME=lilith
ARG USER_UID=1000
ARG USER_GID=1000
ARG NODE_VERSION=22
ARG PYTHON_VERSION=3.12
ARG TTYD_VERSION=1.7.7

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# ── System packages ──────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core
    ca-certificates curl wget gnupg2 \
    # Dev tools
    build-essential cmake pkg-config \
    # Git + SSH
    git openssh-client openssh-server \
    # Terminal
    tmux screen htop less vim nano jq ripgrep fd-find \
    # Python
    python${PYTHON_VERSION} python${PYTHON_VERSION}-venv python${PYTHON_VERSION}-dev python3-pip pipx \
    # Libs (useful for Python packages)
    libffi-dev libssl-dev zlib1g-dev \
    # Misc
    sudo locales unzip tree \
    && rm -rf /var/lib/apt/lists/*

# ── Python: make default ─────────────────────────────────────────
RUN update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1

# ── Node.js ──────────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g npm@latest

# ── ttyd (web terminal) ─────────────────────────────────────────
RUN curl -fsSL https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64 \
    -o /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# ── Claude Code CLI ─────────────────────────────────────────────
RUN npm install -g @anthropic-ai/claude-code

# ── User setup ───────────────────────────────────────────────────
RUN userdel -r ubuntu 2>/dev/null || true \
    && groupadd --force --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} --no-log-init -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USERNAME}

# ── SSH directory prep ───────────────────────────────────────────
RUN mkdir -p /home/${USERNAME}/.ssh \
    && chmod 700 /home/${USERNAME}/.ssh \
    && chown ${USER_UID}:${USER_GID} /home/${USERNAME}/.ssh

# ── tmux config ──────────────────────────────────────────────────
COPY --chown=${USER_UID}:${USER_GID} config/.tmux.conf /home/${USERNAME}/.tmux.conf

# ── Entrypoint ───────────────────────────────────────────────────
COPY --chmod=755 scripts/entrypoint.sh /usr/local/bin/entrypoint.sh

USER ${USERNAME}
WORKDIR /home/${USERNAME}/workspace

EXPOSE 7681

ENTRYPOINT ["entrypoint.sh"]
CMD ["ttyd", "-i", "0.0.0.0", "-p", "7681", "-W", \
     "-t", "titleFixed=Lilith", \
     "-t", "fontSize=14", \
     "tmux", "new", "-A", "-s", "lilith"]
