#!/bin/bash

set -e  # Exit on any error

echo "🚀 Starting Arch Linux Environment Setup..."
echo

# --- Helper: check if a package is installed ---
is_installed() {
    pacman -Qi "$1" &>/dev/null
}

# --- Zsh installation ---
if command -v zsh >/dev/null 2>&1 && [[ "$SHELL" == "$(which zsh)" ]]; then
    echo "✅ Zsh is already installed and set as default shell"
else
    echo "🔧 Installing Zsh, Curl, and Git..."
    sudo pacman -Syu --needed --noconfirm zsh curl git

    echo "👤 Changing default shell to Zsh for user: $USER"
    chsh -s "$(which zsh)"
fi

# --- Oh My Zsh ---
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "✅ Oh My Zsh is already installed"
else
    echo "✨ Installing Oh My Zsh..."
    export RUNZSH=no
    unset ZSH
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "✅ Zsh and Oh My Zsh setup completed!"
echo

# --- Neovim ---
if command -v nvim >/dev/null 2>&1; then
    echo "✅ Neovim is already installed"
    nvim --version
else
    echo "🧱 Installing Neovim..."
    sudo pacman -Syu --needed --noconfirm neovim
    nvim --version
fi

echo
echo "🛠️ Installing Development Tools..."

# --- Git ---
if command -v git >/dev/null 2>&1; then
    echo "✅ Git is already installed"
else
    sudo pacman -Syu --needed --noconfirm git
fi

# --- Ripgrep ---
if command -v rg >/dev/null 2>&1; then
    echo "✅ Ripgrep is already installed"
else
    sudo pacman -Syu --needed --noconfirm ripgrep
fi

# --- fd ---
if command -v fd >/dev/null 2>&1; then
    echo "✅ fd is already installed"
else
    sudo pacman -Syu --needed --noconfirm fd
fi

# --- fzf ---
if command -v fzf >/dev/null 2>&1; then
    echo "✅ fzf is already installed"
else
    sudo pacman -Syu --needed --noconfirm fzf
fi

# --- Lazygit ---
if command -v lazygit >/dev/null 2>&1; then
    echo "✅ Lazygit is already installed"
else
    echo "🚀 Installing Lazygit..."
    sudo pacman -Syu --needed --noconfirm lazygit || {
        echo "⚠️ Lazygit not in pacman? Installing from AUR..."
        if command -v yay >/dev/null 2>&1; then
            yay -S --needed --noconfirm lazygit
        else
            echo "❌ 'yay' not found. Please install an AUR helper (yay or paru)."
        fi
    }
fi

echo
echo "⚙️ Setting up Neovim configuration..."

# --- Dotfiles ---
if [[ -d "$HOME/dotfiles" ]]; then
    echo "📁 Dotfiles repo exists, updating..."
    cd "$HOME/dotfiles"
    git pull
else
    echo "📥 Cloning dotfiles repo..."
    git clone https://github.com/sinneDvdb/dotfiles.git "$HOME/dotfiles"
fi

# --- Neovim config ---
if [[ -L "$HOME/.config/nvim" ]]; then
    echo "✅ Neovim config symlink already exists"
elif [[ -d "$HOME/.config/nvim" ]]; then
    echo "⚠️ Backing up existing Neovim config..."
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
fi

if [[ -d "$HOME/dotfiles/.config/nvim" ]]; then
    echo "🔗 Symlinking Neovim config..."
    mkdir -p "$HOME/.config"
    ln -sf "$HOME/dotfiles/.config/nvim" "$HOME/.config/nvim"
    echo "✅ Neovim configuration symlinked!"
else
    echo "⚠️ Neovim config missing in dotfiles"
fi

echo
echo "💻 Setting up Tmux configuration..."

if [[ -d "$HOME/dotfiles" ]]; then
    if [[ -L "$HOME/.tmux.conf" || -f "$HOME/.tmux.conf" ]]; then
        echo "⚠️ Backing up existing .tmux.conf..."
        mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    ln -sf "$HOME/dotfiles/.config/tmux/.tmux.conf" "$HOME/.tmux.conf"
    echo "✅ Tmux configuration symlinked!"
else
    echo "⚠️ Dotfiles repo not found, skipping Tmux config."
fi

echo
echo "✨ Installing Powerlevel10k for Zsh..."

if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
    echo "✅ Powerlevel10k already installed"
else
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    echo "✅ Powerlevel10k installed!"
fi

if ! grep -q 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$HOME/.zshrc"; then
    sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
    echo "💡 Updated .zshrc to use Powerlevel10k theme"
fi

echo
echo "🎉 Arch Linux Environment Setup Complete!"
