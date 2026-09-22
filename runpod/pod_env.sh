# Environment for a RunPod pod. Sourced by zshrc.sh when /workspace exists, by runpod_setup.sh,
# and by any non-interactive ssh command that needs uv or the caches.
# Everything that must survive a pod stop/start lives on /workspace; /root and /usr do not.
export WORKSPACE=${WORKSPACE:-/workspace}
export HF_HOME=$WORKSPACE/.cache/huggingface
export UV_CACHE_DIR=$WORKSPACE/.cache/uv
export UV_PYTHON_INSTALL_DIR=$WORKSPACE/.cache/uv-python
export UV_LINK_MODE=hardlink
export TOKENIZERS_PARALLELISM=false
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
# hf-xet: more parallel chunk transfers on a datacenter pipe (model shards are the slow part)
export HF_XET_HIGH_PERFORMANCE=1
