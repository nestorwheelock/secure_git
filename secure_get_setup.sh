#!/bin/bash

# Variables
LOGFILE="secure_git_setup.log"
DEPENDENCIES=("git" "grep" "awk" "git-filter-repo")
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Log function for output and errors
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOGFILE"
}

# Error handler
error_handler() {
    log "❌ An error occurred. Exiting..."
    exit 1
}

# Trap for error handling
trap 'error_handler' ERR

# Function to check and install dependencies
check_and_install_dependencies() {
    log "🔍 Checking for necessary dependencies..."

    for dep in "${DEPENDENCIES[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            log "⚠️  Dependency '$dep' is not installed."

            # Attempt to install missing dependency
            if [[ "$dep" == "git-filter-repo" ]]; then
                log "   Installing '$dep' via pip..."
                pip install git-filter-repo || { log "❌ Failed to install $dep."; exit 1; }
            else
                log "   Installing '$dep' via package manager..."
                if [[ -n "$(command -v apt)" ]]; then
                    sudo apt update && sudo apt install -y "$dep"
                elif [[ -n "$(command -v yum)" ]]; then
                    sudo yum install -y "$dep"
                elif [[ -n "$(command -v brew)" ]]; then
                    brew install "$dep"
                else
                    log "❌ Unsupported package manager. Please install $dep manually."
                    exit 1
                fi
            fi

            log "✔️ Dependency '$dep' installed."
        else
            log "✔️ Dependency '$dep' is already installed."
        fi
    done
}

# Function to check if git is installed and configured
check_git_installed() {
    log "🔍 Checking if Git is installed..."
    if command -v git &>/dev/null; then
        log "✔️ Git is installed."
    else
        log "❌ Git is not installed. Exiting..."
        exit 1
    fi
}

# Function to check Git user config
check_git_user_config() {
    git_name=$(git config --global user.name)
    git_email=$(git config --global user.email)

    if [[ -z "$git_name" || -z "$git_email" ]]; then
        log "❌ Git user.name or user.email is not configured."
        log "   You can configure them with the following commands:"
        log "   git config --global user.name \"Your Name\""
        log "   git config --global user.email \"you@example.com\""
    else
        log "✔️ Git user.name is set to '$git_name'."
        log "✔️ Git user.email is set to '$git_email'."
    fi
}

# Function to check if the default branch is set to 'main'
check_git_default_branch() {
    default_branch=$(git config --global init.defaultBranch)
    if [[ "$default_branch" == "main" ]]; then
        log "✔️ Default Git branch is set to 'main'."
    else
        log "❌ Default Git branch is not set to 'main'."
        log "   You can set it with: git config --global init.defaultBranch main"
    fi
}

# Function to check if a remote is configured
check_git_remote() {
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        remote_url=$(git remote get-url origin 2>/dev/null)

        if [[ -z "$remote_url" ]]; then
            log "❌ No remote repository is configured."
            log "   You can add a remote repository with: git remote add origin <remote-url>"
        else
            log "✔️ Remote repository is configured: $remote_url"
        fi
    else
        log "⚠️ Not inside a Git repository."
    fi
}

# Function to scan repository for sensitive data leaks
scan_sensitive_data() {
    log "🔍 Scanning repository for sensitive data leaks..."
    
    # Search for common sensitive patterns (hardcoded credentials, API keys, etc.)
    leaks=$(grep -ri --exclude-dir=.git --exclude='*.md' --exclude='*.txt' \
            -E '(password|api[_-]?key|secret|token|AWS_SECRET|PRIVATE_KEY)' .)

    if [[ -n "$leaks" ]]; then
        log "❌ Found potential sensitive data leaks:"
        echo "$leaks" | tee -a "$LOGFILE"

        # Add sensitive files to .gitignore
        log "🔧 Adding sensitive files to .gitignore..."
        echo "# Sensitive data files" >> .gitignore
        echo "$leaks" | awk -F: '{print $1}' | sort | uniq >> .gitignore
        log "✔️ Sensitive files added to .gitignore."

    else
        log "✔️ No sensitive data leaks found."
    fi
}

# Function to check for a .gitignore file and create if necessary
check_gitignore() {
    if [[ ! -f .gitignore ]]; then
        log "❌ No .gitignore file found."
        log "   Creating a basic .gitignore..."
        cat <<EOL > .gitignore
# Sensitive files
.env
node_modules/
*.log
*.key
*.pem
EOL
        log "✔️ .gitignore created."
    else
        log "✔️ .gitignore exists."
    fi
}

# Function to remove sensitive files from Git history
remove_sensitive_from_history() {
    log "🔧 Scanning Git history for sensitive files..."
    
    sensitive_files=("*.pem" "*.key" "*.env" "*.log")

    for file in "${sensitive_files[@]}"; do
        if git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
            log "❌ Sensitive file '$file' found in Git history."
            log "   Removing from history using git-filter-repo..."
            git filter-repo --path "$file" --invert-paths
            log "✔️ Sensitive file '$file' removed from Git history."
        fi
    done
}

# Full security check
full_security_check() {
    log "🔍 Running full security check..."
    check_git_installed
    check_git_user_config
    check_git_default_branch
    check_git_remote
    scan_sensitive_data
    check_gitignore
    remove_sensitive_from_history
    log "✔️ All security checks completed."
}

# Run all checks and install dependencies
check_and_install_dependencies
full_security_check

