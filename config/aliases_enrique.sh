# -------------------------------------------------------------------
# Enrique: pods, uv, GPUs. Sourced by deploy.sh --aliases=enrique
# -------------------------------------------------------------------
alias ws='cd /workspace'
alias gpu='nvidia-smi'
alias gpuw='watch -n 1 nvidia-smi'
alias uvs='uv sync --frozen'
alias uvr='uv run'
alias pyt='uv run pytest'
alias hfw='hf auth whoami'
alias blog='tail -f /workspace/bootstrap.log'
