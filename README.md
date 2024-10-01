
# Secure Git

**Secure Git** is a script designed to enhance the security of your Git repositories by scanning for sensitive data leaks, ensuring proper Git configurations, and using tools like **truffleHog** and **git-secrets** to prevent secrets from being committed to your repositories.

The script can be run recursively on a directory containing multiple Git repositories and will automatically commit and push any changes to GitHub if necessary. All operations are logged with **clear and emoji-enhanced** outputs for easy readability.

## Features

- **Dependency Check**: Automatically checks for and installs required dependencies (`git`, `grep`, `awk`, `git-filter-repo`, `truffleHog`, `git-secrets`).
- **Sensitive Data Scan**:
  - **truffleHog**: Scans for high-entropy strings and potential secrets (e.g., API keys, credentials).
  - **git-secrets**: Scans for common secrets (AWS keys, etc.) and prevents them from being committed.
- **.gitignore Check**: Ensures a `.gitignore` file exists with basic sensitive data exclusions.
- **Commit and Push**: Automatically commits and pushes changes (e.g., added `.gitignore`, removed sensitive files from history).
- **Recursive Search**: Recursively searches through a specified directory for Git repositories and performs the checks for each one.
- **Pretty Logging**: Emoji-enhanced logging for a better and more intuitive reading experience.

## Requirements

The script requires the following tools:

- **git**
- **grep**
- **awk**
- **git-filter-repo** (automatically installed via `pip` if not present)
- **truffleHog** (automatically installed via `pip` if not present)
- **git-secrets** (automatically installed via your system’s package manager)

### Supported Platforms

- **Debian/Ubuntu**: Uses `apt` for installing missing dependencies.
- **RedHat/CentOS**: Uses `yum` for installing missing dependencies.
- **macOS**: Uses `brew` for installing missing dependencies.

## Installation

Clone this repository and make the script executable:

```bash
git clone git@github.com:nestorwheelock/secure_git.git
cd secure_git
chmod +x secure_git.sh
```

## Usage

### Single Repository

To run the security checks on a single Git repository, navigate to the repository directory and execute the script:

```bash
./secure_git.sh /path/to/your/repo
```

### Recursive Scan of Multiple Repositories

If you have a directory that contains multiple Git repositories (or nested repositories), you can run the script recursively:

```bash
./secure_git.sh /path/to/directory-containing-repos
```

The script will automatically find all Git repositories in the specified directory and perform security checks on each one.

## How It Works

1. **Dependency Check**: The script first checks for the required dependencies and installs any that are missing.
2. **Sensitive Data Scan**:
   - **truffleHog**: Scans the repository for high-entropy strings (potential secrets).
   - **git-secrets**: Scans for AWS keys and other common secrets in the commit history and staged files.
3. **.gitignore Check**: If no `.gitignore` exists, the script creates one with exclusions for common sensitive files (e.g., `.env`, `*.log`, `*.key`).
4. **Git History Clean-Up**: If sensitive files are detected in the Git history, the script uses `git-filter-repo` to remove them.
5. **Commit and Push Changes**: After making necessary changes, the script commits them and pushes to the remote Git repository on GitHub (if a remote is configured).

## Pretty Logging Example

The script logs its actions in a **pretty output** format with timestamps and emojis for easier understanding of the process:

```log
[2024-09-30 18:02:08] 🔍 Checking for necessary dependencies...
[2024-09-30 18:02:08] ✔️ Dependency 'git' is already installed.
[2024-09-30 18:02:08] ✔️ Dependency 'grep' is already installed.
[2024-09-30 18:02:08] ✔️ Dependency 'awk' is already installed.
[2024-09-30 18:02:08] ⚠️  Dependency 'git-filter-repo' is not installed.
[2024-09-30 18:02:08]    Installing 'git-filter-repo' via pip...
[2024-09-30 18:02:08] ✔️ Dependency 'git-filter-repo' installed.
[2024-09-30 18:02:08] ⚠️  Dependency 'truffleHog' is not installed.
[2024-09-30 18:02:08]    Installing 'truffleHog' via pip...
[2024-09-30 18:02:08] ✔️ Dependency 'truffleHog' installed.
[2024-09-30 18:02:08] ⚠️  Dependency 'git-secrets' is not installed.
[2024-09-30 18:02:08]    Installing 'git-secrets' via package manager...
[2024-09-30 18:02:08] ✔️ Dependency 'git-secrets' installed.
[2024-09-30 18:02:08] 🔍 Searching for Git repositories in directory: .
[2024-09-30 18:02:08] 🔍 Processing repository: .
[2024-09-30 18:02:08] ✔️ Found a Git repository.
[2024-09-30 18:02:08] 🔍 Scanning repository for sensitive data using truffleHog...
[2024-09-30 18:02:08] ❌ truffleHog detected potential sensitive data. Check log for details.
[2024-09-30 18:02:08] 🔍 Scanning repository with git-secrets...
[2024-09-30 18:02:08] ✔️ No secrets detected by git-secrets.
[2024-09-30 18:02:08] ❌ No .gitignore file found.
[2024-09-30 18:02:08]    Creating a basic .gitignore...
[2024-09-30 18:02:08] ✔️ .gitignore created.
[2024-09-30 18:02:08] 🔧 Scanning Git history for sensitive files...
[2024-09-30 18:02:08] 🔄 Changes detected in the repository. Preparing to commit...
[2024-09-30 18:02:08] ❌ No remote repository is configured. Skipping the push step.
```

### Emoji Legend:
- 🔍 **Search/Scan in Progress**: Indicates the script is performing a search or scan, such as checking dependencies or searching for repositories.
- ✔️ **Success**: Indicates that a dependency or operation has completed successfully.
- ⚠️ **Warning**: Used when a dependency is missing or something needs attention (e.g., no `.gitignore` file found).
- ❌ **Error or Issue**: Indicates an error or issue detected (e.g., sensitive data found by `truffleHog` or no remote repository configured).
- 🔄 **Change Detected**: Indicates that changes were made in the repository, such as committing new files.
- 🔧 **Fixing Issue**: Indicates that the script is fixing an issue, such as creating a `.gitignore` file or removing sensitive files from history.

## Log Output

All operations are logged in a file named `secure_git.log`. After running the script, you can review the log file for details:

```bash
cat secure_git.log
```

## Customizing the Script

You can modify the script to add more features, change the scanning rules, or adjust how it handles different dependencies. The script is designed to be flexible and can be tailored to your specific security needs.

## License

This project is licensed under the GNU General Public License v3.0 (GPLv3). See the [LICENSE](LICENSE) file for more details.

## Contributing

If you'd like to contribute, feel free to submit a pull request or open an issue to discuss any ideas or improvements.
