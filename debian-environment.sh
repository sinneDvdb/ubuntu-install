#!/bin/bash

set -e  # Exit on any error

echo "🚀 Starting Debian Environment Setup..."
echo

# Update package lists
echo "📦 Updating package lists..."
sudo apt update

# Install Zsh
echo "🔧 Installing Zsh..."
sudo apt install -y zsh curl git

echo "👤 Changing default shell to Zsh for user: $USER"
# Use usermod instead of chsh - more reliable in automated scripts
if sudo usermod -s "$(which zsh)" "$USER"; then
    echo "✅ Successfully changed default shell to Zsh"
else
    echo "⚠️  Could not change shell automatically. You can change it manually after the script completes:"
    echo "   sudo chsh -s \$(which zsh) $USER"
    echo "   or edit /etc/passwd directly"
fi

# Install Oh My Zsh
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
echo "🔁 Please log out and log back in to start using Zsh."
echo

# Install Neovim
echo "📝 Installing Neovim (latest stable from source)..."
# Remove old neovim package if installed
sudo apt remove -y neovim >/dev/null 2>&1 || true

# Check if we need to update Neovim
NEED_UPDATE=true
if [[ -f /usr/local/bin/nvim ]]; then
    echo "🔍 Checking for Neovim updates..."
    if /usr/local/bin/nvim --version >/dev/null 2>&1; then
        CURRENT_VERSION=$(/usr/local/bin/nvim --version | head -n1 | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+')
        LATEST_VERSION=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest | grep -oP '"tag_name": "v\K[^"]*')
        
        if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
            echo "✅ Neovim is already up to date (v$CURRENT_VERSION)"
            NEED_UPDATE=false
        else
            echo "📦 Update available: v$CURRENT_VERSION → v$LATEST_VERSION"
        fi
    else
        echo "⚠️  Current Neovim installation is broken, reinstalling..."
    fi
fi

if [[ "$NEED_UPDATE" == "true" ]]; then
    # Install build dependencies
    echo "� Installing build dependencies..."
    sudo apt install -y ninja-build gettext cmake unzip curl build-essential
    
    # Remove existing build directory if it exists
    rm -rf ~/neovim
    
    # Clone Neovim repository
    echo "📥 Cloning Neovim repository..."
    git clone https://github.com/neovim/neovim.git ~/neovim
    cd ~/neovim
    
    # Checkout latest stable release
    echo "🏷️  Checking out latest stable release..."
    git checkout stable
    
    # Build Neovim
    echo "� Building Neovim (this may take a few minutes)..."
    make CMAKE_BUILD_TYPE=RelWithDebInfo
    
    # Install Neovim
    echo "📦 Installing Neovim to /usr/local..."
    sudo make install
    
    # Clean up build directory
    cd ~
    rm -rf ~/neovim
    
    echo "✅ Neovim built and installed successfully!"
fi

echo "🔍 Verifying Neovim installation..."
if nvim --version >/dev/null 2>&1; then
    nvim --version
else
    echo "❌ Neovim installation failed!"
    exit 1
fi

echo
echo "🛠️  Installing Development Tools..."

# Install Git (if not already installed)
sudo apt install -y git

# Install .NET SDK
echo "🔧 Installing .NET SDK..."
# Add Microsoft package signing key and repository
wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Update package list with Microsoft repository
sudo apt update

# Install .NET SDK
sudo apt install -y dotnet-sdk-8.0

echo "✅ .NET SDK installed successfully!"
dotnet --version

# Install Ripgrep
echo "🔍 Installing Ripgrep..."
if apt-cache show ripgrep >/dev/null 2>&1; then
    sudo apt install -y ripgrep
else
    echo "📦 Ripgrep not in repos, installing from GitHub releases..."
    RG_VERSION=$(curl -s "https://api.github.com/repos/BurntSushi/ripgrep/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
    curl -Lo ripgrep.deb "https://github.com/BurntSushi/ripgrep/releases/latest/download/ripgrep_${RG_VERSION}_amd64.deb"
    sudo dpkg -i ripgrep.deb
    rm ripgrep.deb
fi

# Install fd-find
echo "📁 Installing fd-find..."
if apt-cache show fd-find >/dev/null 2>&1; then
    sudo apt install -y fd-find
    # Create symlink if fdfind exists but fd doesn't
    if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
        sudo ln -sf $(which fdfind) /usr/local/bin/fd
    fi
else
    echo "📦 fd-find not in repos, installing from GitHub releases..."
    FD_VERSION=$(curl -s "https://api.github.com/repos/sharkdp/fd/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo fd.deb "https://github.com/sharkdp/fd/releases/latest/download/fd_${FD_VERSION}_amd64.deb"
    sudo dpkg -i fd.deb
    rm fd.deb
fi

# Install fzf
echo "🔎 Installing fzf..."
if apt-cache show fzf >/dev/null 2>&1; then
    sudo apt install -y fzf
else
    echo "📦 fzf not in repos, installing from GitHub..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
fi

# Install Lazygit
echo "🚀 Installing Lazygit..."
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
rm lazygit lazygit.tar.gz

echo
echo "⚙️  Setting up Neovim configuration..."

# Backup existing config if it exists
if [[ -d "$HOME/.config/nvim" ]]; then
    echo "⚠️  Neovim config directory already exists. Backing up to ~/.config/nvim.backup"
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Clone the dotfiles repository
echo "📥 Cloning Neovim configuration from dotfiles..."
git clone https://github.com/sinneDvdb/dotfiles.git "$HOME/dotfiles-temp"

# Copy the Neovim configuration - try multiple common patterns
NVIM_INSTALLED=false

# Pattern 1: .config/nvim (most common)
if [[ -d "$HOME/dotfiles-temp/.config/nvim" ]]; then
    echo "📁 Found Neovim config at .config/nvim - setting up..."
    mkdir -p "$HOME/.config"
    cp -r "$HOME/dotfiles-temp/.config/nvim" "$HOME/.config/"
    NVIM_INSTALLED=true
# Pattern 2: nvim/ directory in root
elif [[ -d "$HOME/dotfiles-temp/nvim" ]]; then
    echo "📁 Found Neovim config at nvim/ - setting up..."
    mkdir -p "$HOME/.config"
    cp -r "$HOME/dotfiles-temp/nvim" "$HOME/.config/"
    NVIM_INSTALLED=true
# Pattern 3: config/nvim
elif [[ -d "$HOME/dotfiles-temp/config/nvim" ]]; then
    echo "📁 Found Neovim config at config/nvim - setting up..."
    mkdir -p "$HOME/.config"
    cp -r "$HOME/dotfiles-temp/config/nvim" "$HOME/.config/"
    NVIM_INSTALLED=true
# Pattern 4: .nvim directory
elif [[ -d "$HOME/dotfiles-temp/.nvim" ]]; then
    echo "📁 Found Neovim config at .nvim - setting up..."
    mkdir -p "$HOME/.config"
    cp -r "$HOME/dotfiles-temp/.nvim" "$HOME/.config/nvim"
    NVIM_INSTALLED=true
fi

if [[ "$NVIM_INSTALLED" == "true" ]]; then
    echo "✅ Neovim configuration installed successfully!"
else
    echo "⚠️  Neovim config not found in common locations"
    echo "📂 Available directories in dotfiles repo:"
    find "$HOME/dotfiles-temp" -maxdepth 2 -type d -name "*nvim*" 2>/dev/null || true
    echo "📁 Top-level structure:"
    ls -la "$HOME/dotfiles-temp/" | head -10
fi

# Clean up temporary clone
echo "🧹 Cleaning up temporary files..."
rm -rf "$HOME/dotfiles-temp"

echo "🎉 Debian Environment Setup Complete!"
echo
echo "📋 Summary of installed tools:"
echo "   • Zsh with Oh My Zsh"
echo "   • Neovim (latest stable built from source)"
echo "   • Git"
echo "   • .NET SDK 8.0"
echo "   • Ripgrep (rg)"
echo "   • fd-find"
echo "   • fzf"
echo "   • Lazygit"
echo "   • Custom Neovim configuration"
echo
echo "🔄 Important: Please log out and log back in to start using Zsh as your default shell"
echo "   If Zsh is not your default shell, run: chsh -s \$(which zsh)"
echo "🚀 You can now run 'nvim' to start Neovim with your new configuration!"
