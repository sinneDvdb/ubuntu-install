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
    sudo usermod -s "$(command -v zsh)" "$USER"
fi

# Check if Oh My Zsh is already installed
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "✅ Oh My Zsh is already installed"
else
    echo "✨ Installing Oh My Zsh..."
    export RUNZSH=no  # Prevent auto-starting Zsh after install
    # Unset ZSH variable to avoid conflicts
    unset ZSH
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
echo "🛠️  Installing Development Tools..."

# Check if git is already installed (should be from zsh install, but double-check)
if command -v git >/dev/null 2>&1; then
    echo "✅ Git is already installed"
else
    echo "📦 Installing Git..."
    sudo apt update
    sudo apt install -y git
fi

# Check if ripgrep is already installed
if command -v rg >/dev/null 2>&1; then
    echo "✅ Ripgrep is already installed"
else
    echo "🔍 Installing Ripgrep..."
    sudo apt update
    sudo apt install -y ripgrep
fi

# Check if fd-find is already installed
if command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1; then
    echo "✅ fd-find is already installed"
else
    echo "📁 Installing fd-find..."
    sudo apt update
    sudo apt install -y fd-find
    # Create symlink if fdfind exists but fd doesn't
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
        sudo ln -sf $(which fdfind) /usr/local/bin/fd
    fi
fi

# Check if fzf is already installed
if command -v fzf >/dev/null 2>&1; then
    echo "✅ fzf is already installed"
else
    echo "🔎 Installing fzf..."
    sudo apt update
    sudo apt install -y fzf
fi

# Check if lazygit is already installed
if command -v lazygit >/dev/null 2>&1; then
    echo "✅ Lazygit is already installed"
else
    echo "🚀 Installing Lazygit..."
    # Get latest release version
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit lazygit.tar.gz
fi

echo
echo "⚙️  Setting up Neovim configuration..."

# Check if dotfiles repository already exists
if [[ -d "$HOME/dotfiles" ]]; then
    echo "📁 Dotfiles repository already exists, updating..."
    cd "$HOME/dotfiles"
    git pull
else
    echo "📥 Cloning dotfiles repository..."
    git clone https://github.com/sinneDvdb/dotfiles.git "$HOME/dotfiles"
fi

# Check if Neovim config already exists
if [[ -L "$HOME/.config/nvim" ]]; then
    echo "✅ Neovim config symlink already exists"
elif [[ -d "$HOME/.config/nvim" ]]; then
    echo "⚠️  Neovim config directory already exists. Backing up to ~/.config/nvim.backup"
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Set up Neovim configuration symlink
if [[ -d "$HOME/dotfiles/.config/nvim" ]]; then
    echo "� Creating symlink for Neovim configuration..."
    mkdir -p "$HOME/.config"
    ln -sf "$HOME/dotfiles/.config/nvim" "$HOME/.config/nvim"
    echo "✅ Neovim configuration symlinked successfully!"
    echo "💡 Your Neovim config is now linked to ~/dotfiles/.config/nvim"
    echo "💡 Any changes you make can be committed and pushed from ~/dotfiles"
else
    echo "⚠️  Neovim config not found in the expected location in dotfiles repo"
    echo "📂 Available directories in dotfiles:"
    ls -la "$HOME/dotfiles/"
fi
echo
echo "💻 Setting up Tmux configuration..."

# Ensure dotfiles repo is cloned
if [[ -d "$HOME/dotfiles" ]]; then
    # Backup existing tmux config if it exists
    if [[ -L "$HOME/.tmux.conf" || -f "$HOME/.tmux.conf" ]]; then
        echo "⚠️ Existing .tmux.conf found. Backing up..."
        mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    # Create symlink for tmux config
    ln -sf "$HOME/dotfiles/.config/tmux/.tmux.conf" "$HOME/.tmux.conf"
    echo "✅ Tmux configuration symlinked successfully!"
else
    echo "⚠️ Dotfiles repo not found. Cannot link tmux config."
fi

echo
echo "✨ Installing Powerlevel10k theme for Zsh..."

# Check if Powerlevel10k is already installed
if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
    echo "✅ Powerlevel10k is already installed"
else
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    echo "✅ Powerlevel10k installed successfully!"
fi

# Ensure ZSH_THEME="powerlevel10k/powerlevel10k" is set in .zshrc
if ! grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$HOME/.zshrc"; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
    echo "💡 Updated .zshrc to use Powerlevel10k theme"
fi
echo "🎉 Ubuntu Environment Setup Complete!"
