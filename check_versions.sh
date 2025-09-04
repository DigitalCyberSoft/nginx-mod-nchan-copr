#!/bin/bash
# check_versions.sh - Check for new versions of nginx and nchan
# Auto-commits and pushes changes when new versions are detected

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_FILE="$SCRIPT_DIR/versions.json"
DEFAULT_NGINX_VERSION="1.28.0"

# Parse command line arguments
MODE="check"
DRY_RUN=0
FORCE=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --update)
            MODE="update"
            shift
            ;;
        --check-only)
            MODE="check"
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --force)
            FORCE=1
            shift
            ;;
        --help)
            echo "Usage: $0 [--check-only|--update] [--dry-run] [--force]"
            echo "  --check-only  Check for updates but don't modify anything (default)"
            echo "  --update      Update versions.json and commit+push if changed"
            echo "  --dry-run     Show what would be done without making changes"
            echo "  --force       Force update even if versions haven't changed"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Function to get current timestamp
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Function to get nginx version from Fedora repos
get_nginx_version() {
    local version=""
    
    if command -v dnf >/dev/null 2>&1; then
        version=$(dnf repoquery --latest-limit=1 --qf="%{version}" nginx 2>/dev/null || echo "")
    fi
    
    if [ -z "$version" ]; then
        echo "Warning: Could not query nginx version from Fedora repos, using default" >&2
        version="$DEFAULT_NGINX_VERSION"
    fi
    
    echo "$version"
}

# Function to get nchan latest commit from GitHub
get_nchan_version() {
    local api_url="https://api.github.com/repos/slact/nchan/commits/master"
    local commit_info=""
    
    # Try to get commit info from GitHub API
    if command -v curl >/dev/null 2>&1; then
        commit_info=$(curl -s "$api_url" | grep -E '"sha":|"date":' | head -2 || echo "")
    fi
    
    if [ -n "$commit_info" ]; then
        # Extract commit SHA (first 7 characters)
        local commit=$(echo "$commit_info" | grep '"sha":' | sed 's/.*"sha": *"\([^"]*\)".*/\1/' | cut -c1-7)
        echo "$commit"
    else
        # Fallback to git if available and repo exists
        if command -v git >/dev/null 2>&1; then
            if [ -d "$SCRIPT_DIR/nchan-master" ]; then
                cd "$SCRIPT_DIR/nchan-master"
                git fetch origin master >/dev/null 2>&1 || true
                git rev-parse --short origin/master 2>/dev/null || echo "unknown"
            else
                # Clone temporarily to get version
                cd "$SCRIPT_DIR"
                git clone --depth=1 https://github.com/slact/nchan.git nchan-temp >/dev/null 2>&1
                cd nchan-temp
                local version=$(git describe --tags --always 2>/dev/null || git rev-parse --short HEAD)
                cd ..
                rm -rf nchan-temp
                echo "$version" | sed 's/^v//'
            fi
        else
            echo "unknown"
        fi
    fi
}

# Function to read current versions from JSON
read_current_versions() {
    if [ -f "$VERSIONS_FILE" ]; then
        CURRENT_NGINX=$(grep -A1 '"nginx"' "$VERSIONS_FILE" | grep '"version"' | sed 's/.*"version": *"\([^"]*\)".*/\1/')
        CURRENT_NCHAN=$(grep -A2 '"nchan"' "$VERSIONS_FILE" | grep '"commit"' | sed 's/.*"commit": *"\([^"]*\)".*/\1/')
        
        # Fallback if commit field doesn't exist
        if [ -z "$CURRENT_NCHAN" ]; then
            CURRENT_NCHAN=$(grep -A1 '"nchan"' "$VERSIONS_FILE" | grep '"version"' | sed 's/.*"version": *"\([^"]*\)".*/\1/' | cut -d'-' -f3 | cut -c2-8)
        fi
    else
        CURRENT_NGINX=""
        CURRENT_NCHAN=""
    fi
}

# Function to write versions to JSON
write_versions() {
    local nginx_ver="$1"
    local nchan_ver="$2"
    local timestamp="$(get_timestamp)"
    
    # Generate full nchan version string for display
    local nchan_full="1.3.7-2-g${nchan_ver}"
    
    cat > "$VERSIONS_FILE" <<EOF
{
  "nginx": {
    "version": "$nginx_ver",
    "source": "fedora",
    "last_checked": "$timestamp"
  },
  "nchan": {
    "version": "$nchan_full",
    "commit": "$nchan_ver",
    "last_checked": "$timestamp"
  },
  "last_update": "$timestamp"
}
EOF
}

# Function to commit and push changes
commit_and_push() {
    local old_nginx="$1"
    local new_nginx="$2"
    local old_nchan="$3"
    local new_nchan="$4"
    
    cd "$SCRIPT_DIR"
    
    # Configure git if needed (for CI environments)
    if ! git config user.name >/dev/null 2>&1; then
        git config user.name "Version Checker Bot"
        git config user.email "bot@github-actions"
    fi
    
    # Stage the versions file
    git add versions.json
    
    # Create commit message
    local commit_msg="Auto-update versions:"
    local changes=()
    
    if [ "$old_nginx" != "$new_nginx" ]; then
        changes+=("nginx $old_nginx -> $new_nginx")
    fi
    
    if [ "$old_nchan" != "$new_nchan" ]; then
        changes+=("nchan $old_nchan -> $new_nchan")
    fi
    
    if [ ${#changes[@]} -gt 0 ]; then
        commit_msg="$commit_msg $(IFS=', '; echo "${changes[*]}")"
    else
        commit_msg="Force update versions.json"
    fi
    
    commit_msg="$commit_msg

This commit triggers automatic COPR rebuild with latest versions.
Generated by check_versions.sh on $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    
    # Commit
    git commit -m "$commit_msg"
    
    # Push to origin
    git push origin master
}

# Main execution
echo "=== Version Check Script ==="
echo "Mode: $MODE"
echo "Checking versions at $(get_timestamp)"
echo

# Get current versions from file
read_current_versions

# Get latest versions
echo "Checking latest nginx version..."
NEW_NGINX=$(get_nginx_version)
echo "Latest nginx version: $NEW_NGINX"

echo "Checking latest nchan version..."
NEW_NCHAN=$(get_nchan_version)
echo "Latest nchan commit: $NEW_NCHAN"
echo

# Compare versions
VERSIONS_CHANGED=0
if [ "$CURRENT_NGINX" != "$NEW_NGINX" ] || [ "$CURRENT_NCHAN" != "$NEW_NCHAN" ]; then
    VERSIONS_CHANGED=1
fi

if [ $FORCE -eq 1 ]; then
    echo "Force mode enabled - will update regardless of changes"
    VERSIONS_CHANGED=1
fi

# Report status
if [ $VERSIONS_CHANGED -eq 1 ]; then
    echo "=== Version changes detected ==="
    if [ "$CURRENT_NGINX" != "$NEW_NGINX" ]; then
        echo "  nginx: $CURRENT_NGINX -> $NEW_NGINX"
    fi
    if [ "$CURRENT_NCHAN" != "$NEW_NCHAN" ]; then
        echo "  nchan: $CURRENT_NCHAN -> $NEW_NCHAN"
    fi
    echo
    
    if [ "$MODE" = "update" ]; then
        if [ $DRY_RUN -eq 1 ]; then
            echo "DRY RUN: Would update versions.json"
            echo "DRY RUN: Would commit with message about version changes"
            echo "DRY RUN: Would push to origin/master"
        else
            echo "Updating versions.json..."
            write_versions "$NEW_NGINX" "$NEW_NCHAN"
            echo "versions.json updated"
            
            echo "Committing and pushing changes..."
            commit_and_push "$CURRENT_NGINX" "$NEW_NGINX" "$CURRENT_NCHAN" "$NEW_NCHAN"
            echo "Changes committed and pushed successfully"
        fi
    else
        echo "Running in check-only mode - no changes made"
        echo "Run with --update to apply changes"
    fi
    
    exit 1  # Exit with error code to indicate changes available
else
    echo "=== No version changes detected ==="
    echo "  nginx: $CURRENT_NGINX (unchanged)"
    echo "  nchan: $CURRENT_NCHAN (unchanged)"
    exit 0
fi