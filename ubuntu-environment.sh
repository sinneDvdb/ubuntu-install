#!/bin/bash

set -e  # Exit on any error

echo "🔧 Installing Zsh..."
sudo apt update
sudo apt install -y zsh curl git

echo "👤 Changing default shell to Zsh for user: $USER"
chsh -s "$(which zsh)"

echo "✨ Installing Oh My Zsh..."
export RUNZSH=no  # Prevent auto-starting Zsh after install
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "✅ Zsh and Oh My Zsh installed successfully!"
echo "🔁 Please log out and log back in to start using Zsh."
