#!/usr/bin/env bash
# Generic bootstrap for one of Enrique's RunPod pods. Idempotent, run as root on the pod.
#
#   curl -fsSL https://raw.githubusercontent.com/visual-snow/dotfiles/master/runpod/runpod_setup.sh | bash
#
# Optional environment: HF_TOKEN (written to $HF_HOME/token, then forgotten),
#                       GIT_NAME and GIT_EMAIL (git identity for commits made on the pod).
# A project then only needs `uv sync --frozen` in its own folder under /workspace.
set -euo pipefail
DOT=$HOME/git/dotfiles
log() { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }

# 0. RunPod containers stall on IPv6 to raw.githubusercontent.com; make every curl use IPv4
grep -qx 'ipv4' "$HOME/.curlrc" 2>/dev/null || echo 'ipv4' >> "$HOME/.curlrc"

# 1. apt basics, once per container
if ! command -v nvtop >/dev/null 2>&1 || ! command -v sudo >/dev/null 2>&1; then
  log "apt packages"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y -qq sudo less nano htop ncdu nvtop lsof rsync jq btop tmux zsh git curl >/dev/null
fi

# 2. these dotfiles
mkdir -p "$HOME/git"
if [ -d "$DOT/.git" ]; then
  git -C "$DOT" pull --ff-only -q || true
else
  git clone -q https://github.com/visual-snow/dotfiles.git "$DOT"
fi
source "$DOT/runpod/pod_env.sh"
mkdir -p "$HF_HOME" "$UV_CACHE_DIR" "$UV_PYTHON_INSTALL_DIR" "$WORKSPACE/.vscode-server"

# 3. uv, latest, in ~/.local/bin; its cache and pythons live on /workspace via pod_env.sh
# base images ship an old /usr/bin/uv that cannot read current lockfiles, so check our own copy
if [ ! -x "$HOME/.local/bin/uv" ]; then
  log "installing uv"
  curl -4 -LsSf https://astral.sh/uv/install.sh | sh >/dev/null
fi
hash -r
log "uv $("$HOME/.local/bin/uv" --version)"

# 4. zsh + oh-my-zsh + powerlevel10k + tmux, then the rc files
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "install.sh --zsh --tmux"
  (cd "$DOT" && ./install.sh --zsh --tmux >/dev/null 2>&1)
fi
if ! grep -q 'dotfiles/config/zshrc.sh' "$HOME/.zshrc" 2>/dev/null; then
  log "deploy.sh --aliases=enrique"
  (cd "$DOT" && ./deploy.sh --aliases=enrique </dev/null >/dev/null 2>&1) || true
fi
# bash is what Jupyter's terminal and non-login ssh commands get, so it sees the same env
if ! grep -q 'runpod/pod_env.sh' "$HOME/.bashrc" 2>/dev/null; then
  { echo "source $DOT/runpod/pod_env.sh"; cat "$HOME/.bashrc" 2>/dev/null; } > "$HOME/.bashrc.new"
  mv "$HOME/.bashrc.new" "$HOME/.bashrc"
fi

# 5. VS Code server on the persistent volume, so a fresh container does not re-download it
[ -e "$HOME/.vscode-server" ] || ln -s "$WORKSPACE/.vscode-server" "$HOME/.vscode-server"

# 6. secrets and identity
if [ -n "${HF_TOKEN:-}" ]; then
  printf '%s' "$HF_TOKEN" > "$HF_HOME/token" && chmod 600 "$HF_HOME/token"
  unset HF_TOKEN
  log "hf token written to $HF_HOME/token"
fi
git config --global user.name "${GIT_NAME:-Enrique}"
git config --global user.email "${GIT_EMAIL:-74030303+eaguaida@users.noreply.github.com}"
git config --global init.defaultBranch main

date > "$WORKSPACE/.runpod_setup_done"
log "pod ready: zsh, tmux, uv, caches on $WORKSPACE"
