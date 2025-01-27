#!/bin/bash

# Function to check for command existence
command_exists() {
    command -v "$1" &>/dev/null
}

# Function for updating system and installing dependencies for apt-based systems
setup_apt() {
    echo "Setting up development environment for apt-based systems..."
    sudo apt update && sudo apt upgrade -y

    # Install basic dependencies
    sudo apt install -y wget gpg curl

    # Add Microsoft and Git repositories
    echo "Setting up Microsoft repository..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f packages.microsoft.gpg

    sudo add-apt-repository -y ppa:git-core/ppa

    # Install development tools
    echo "Installing development tools..."
    sudo apt update
    sudo apt install -y git zsh code

    echo "Setting up docker and docker compose dependencies..."

    # Add Docker's official GPG key:
    sudo apt-get update -y
    sudo apt-get install ca-certificates curl -y
    sudo install -m 0755 -d /etc/apt/keyrings -y
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    # Installing docker and docker compose
    echo "Installing docker and docker compose"
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Enable and start docker service
    sudo systemctl enable docker
    sudo systemctl start docker

    # Testing functionality of docker
    sudo docker run hello-world
    
    echo "Docker installation success!!"
}

# Function for updating system and installing dependencies for yay-based systems
setup_yay() {
    echo "Setting up development environment for yay-based systems..."
    yay -Syu --noconfirm

    # Install development tools
    echo "Installing development tools..."
    yay -S --noconfirm git zsh visual-studio-code-bin docker docker-compose
}

# Check package manager and execute setup accordingly
echo "Welcome to your personal development environment setup!"
read -p "What is your package manager? [apt, yay]: " packageManager

case "$packageManager" in
    apt)
        setup_apt
        ;;
    yay)
        setup_yay
        ;;
    *)
        echo "Unsupported package manager."
        exit 1
        ;;
esac

# Check if curl and git are installed
if ! command_exists "curl"; then
    echo "curl is required but not installed. Please install it and rerun the script."
    exit 1
fi

if ! command_exists "git"; then
    echo "git is required but not installed. Please install it and rerun the script."
    exit 1
fi

# Install Oh My Zsh and NVM
echo "Installing Oh My Zsh and NVM..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Set NVM environment variables
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Install Node.js LTS version
echo "Installing Node.js LTS..."
nvm install --lts
nvm use --lts

# Git configuration
echo "Setting up Git configuration..."
read -p "What is your Git username? " username
git config --global user.name "$username"

read -p "What is your Git email? " email
git config --global user.email "$email"

# Set default branch to 'main'
git config --global init.defaultBranch main
echo "Git config setup complete!"

# SSH setup
echo "Setting up SSH client..."

# Check for existing SSH key
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    echo "No existing SSH key found, generating a new one..."
    read -p "What is your Git email again? " emailAgain
    ssh-keygen -t ed25519 -C "$emailAgain" -f "$HOME/.ssh/id_ed25519" -N ""

    echo "SSH key generated. You can now add the following public key to your Git service (e.g., GitHub):"
    cat "$HOME/.ssh/id_ed25519.pub"
else
    echo "SSH key already exists. Skipping key generation."
fi

echo "Post installation of Docker tweaks..."
sudo usermod -aG docker "$USER"

echo "You have been added to the 'docker' group."
echo "Please log out and log back in, or restart your terminal to apply the changes."

echo "Development environment setup complete!"
echo "Please add your SSH public key to GitHub, GitLab, or any other Git service you use."
