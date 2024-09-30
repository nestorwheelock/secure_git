#!/bin/bash

# Variables
LOGFILE="secure_git_setup.log"
DEPENDENCIES=("git" "grep" "awk" "git-filter-repo" "truffleHog" "git-secrets")
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

            # Install missing dependencies
            case "$dep" in
                git-filter-repo)
                    log "   Installing '$dep' via pip..."
                    pip install git-filter-repo || { log "❌ Failed to install $dep."; exit 1; }
                    ;;
                truffleHog)
                    log "   Installing '$dep' via pip..."
                    pip install truffleHog || { log "❌ Failed to install $dep."; exit 1; }
                    ;;
                git-secrets)
                    log "   Installing '$dep' via package manager..."
                    if [[ -n "$(command -v apt)" ]]; then
                        sudo apt update && sudo apt install -y git-secrets
                    elif [[ -n "$(command -v yum)" ]]; then
                        sudo yum install -y git-secrets
                    elif [[ -n "$(command -v brew)" ]]; then
                        brew install git-secrets
                    else
                        log "❌ Unsupported package manager. Please install $dep manually."
                        exit 1
                    fi
                    ;;
                *)
                    log "   Installing '$dep' via system package manager..."
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
                    ;;
            esac

            log "✔️ Dependency '$dep' installed."
        else
            log "✔️ Dependency '$dep' is already installed."
        fi
    done
}

# Function to check if inside a Git repository
check_git_repo() {
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        log "✔️ Found a Git repository."
        return 0
    else
        log "❌ Not a Git repository."
        return 1
    fi
}

# Function to scan repository for sensitive data leaks using truffleHog
scan_sensitive_data_trufflehog() {
    log "🔍 Scanning repository for sensitive data using truffleHog..."
    truffleHog --entropy=False --json . | tee -a "$LOGFILE"

    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        log "✔️ No sensitive data leaks detected by truffleHog."
    else
        log "❌ truffleHog detected potential sensitive data. Check log for details."
    fi
}

# Function to scan repository with git-secrets
scan_with_git_secrets() {
    log "🔍 Scanning repository with git-secrets..."

    # Initialize git-secrets
    git secrets --install
    git secrets --register-aws

    # Scan for any secrets in history and staged commits
    if git secrets --scan; then
        log "✔️ No secrets detected by git-secrets."
    else
        log "❌ git-secrets detected potential secrets. Check log for details."
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

# Function to commit and push changes to GitHub
commit_and_push_changes() {
    # Check if there are changes to commit
    if [[ -n "$(git status --porcelain)" ]]; then
        log "🔄 Changes detected in the repository. Preparing to commit..."

        # Stage all changes
        git add .

        # Commit the changes
        git commit -m "Automatic updates: added .gitignore and removed sensitive files"

        # Push to remote repository
        if git rev-parse --is-inside-work-tree &>/dev/null; then
            remote_url=$(git remote get-url origin 2>/dev/null)

            if [[ -n "$remote_url" ]]; then
                log "🚀 Pushing changes to GitHub remote repository..."
                git push origin $(git rev-parse --abbrev-ref HEAD)
                log "✔️ Changes pushed to GitHub successfully."
            else
                log "❌ No remote repository is configured. Skipping the push step."
            fi
        else
            log "⚠️ Not inside a Git repository. Skipping the push step."
        fi
    else
        log "✔️ No changes to commit."
    fi
}

# Function to process a single repository
process_repo() {
    repo_dir="$1"
    log "🔍 Processing repository: $repo_dir"
    
    cd "$repo_dir" || { log "❌ Could not enter directory: $repo_dir"; return; }

    if check_git_repo; then
        scan_sensitive_data_trufflehog
        scan_with_git_secrets
        check_gitignore
        remove_sensitive_from_history
        commit_and_push_changes
    else
        log "Skipping: $repo_dir is not a Git repository."
    fi
}

# Function to recursively search for Git repositories
search_and_process_repos() {
    base_dir="$1"
    log "🔍 Searching for Git repositories in directory: $base_dir"
    
    find "$base_dir" -type d -name ".git" | while read -r git_dir; do
        repo_dir=$(dirname "$git_dir")
        process_repo "$repo_dir"
    done
}

# Main function to run the script
main() {
    # Check if directory argument is provided
    if [[ -z "$1" ]]; then
        log "❌ Please provide the path to the directory containing the repositories."
        exit 1
    fi

    # Check if the provided directory exists
    if [[ ! -d "$1" ]]; then
        log "❌ The specified directory does not exist: $1"
        exit 1
    fi

    # Install dependencies
    check_and_install_dependencies

    # Search and process repositories recursively
    search_and_process_repos "$1"
}

# Run the main function with the provided argument
main "$1"

