#!/bin/bash

set -e  # Exit on any error

echo "🚀 Starting Ubuntu Environment Setup..."
echo

# Check if Zsh is already installed and configured
if command -v zsh >/dev/null 2>&1 && [[ "$SHELL" == "$(which zsh)" ]]; then
    echo "✅ Zsh is already installed and set as default shell"
else
    echo "🔧 Installing Zsh..."
    sudo apt update
    sudo apt install -y zsh curl git

    echo "👤 Changing default shell to Zsh for user: $USER"
    chsh -s "$(which zsh)"
fi

# Check if Oh My Zsh is already installed
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "✅ Oh My Zsh is already installed"
else
    echo "✨ Installing Oh My Zsh..."
    export RUNZSH=no  # Prevent auto-starting Zsh after install
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "✅ Zsh and Oh My Zsh setup completed!"
echo "🔁 Please log out and log back in to start using Zsh (if not already done)."
echo

# Check if Neovim is already installed
if command -v nvim >/dev/null 2>&1; then
    echo "✅ Neovim is already installed"
    nvim --version
else
    echo "🧱 Installing dependencies for building Neovim..."
    sudo apt update
    sudo apt install -y ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl doxygen

    # Check if Neovim repository already exists
    if [[ -d "$HOME/neovim" ]]; then
        echo "📁 Neovim repository already exists, updating..."
        cd ~/neovim
        git pull
    else
        echo "📥 Cloning Neovim repository..."
        git clone https://github.com/neovim/neovim.git ~/neovim
        cd ~/neovim
    fi

    echo "🔨 Building Neovim (Release mode)..."
    make CMAKE_BUILD_TYPE=Release

    echo "📦 Installing Neovim to /usr/local..."
    sudo make install

    echo "✅ Neovim installed successfully!"
    nvim --version
fi

echo
echo "🎉 Ubuntu Environment Setup Complete!"