#!/bin/zsh
set -euo pipefail

MATLAB_BIN="/Applications/MATLAB_R2025a.app/bin/matlab"
PROJECT_CODE_DIR="/Users/kalanit/Projects/PerceptualMagnification/Paper/ExperimentalData/code"

exec "$MATLAB_BIN" -softwareopengl -nosplash -r "addpath(genpath('$PROJECT_CODE_DIR')); safe_matlab_startup('$PROJECT_CODE_DIR')"
