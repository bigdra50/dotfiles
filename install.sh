#!/bin/bash

mkdir -p ~/.local/bin
curl --proto '=https' --tlsv1.3 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin/
export PATH="$HOME/.local/bin:$PATH"
