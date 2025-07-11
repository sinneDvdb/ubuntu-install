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

  echo "🧱 Installing dependencies for building Neovim..."
  sudo apt update
  sudo apt install -y ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl doxygen

  echo "📥 Cloning Neovim repository..."
  git clone https://github.com/neovim/neovim.git ~/neovim
  cd ~/neovim

  echo "🔨 Building Neovim (Release mode)..."
  make CMAKE_BUILD_TYPE=Release

  echo "🧪 Running Neovim tests..."
  make test

  echo "📦 Installing Neovim to /usr/local..."
  sudo make install

  echo "✅ Neovim installed successfully!"
  nvim --version

