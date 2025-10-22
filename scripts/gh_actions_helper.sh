#!/usr/bin/env bash

# GitHub Actions Helper Script
# Utility functions for detecting and working with GitHub Actions

# Check if gh CLI is available
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        echo "Error: gh CLI is not installed" >&2
        echo "Install from: https://cli.github.com/" >&2
        return 1
    fi

    if ! gh auth status &> /dev/null; then
        echo "Error: gh is not authenticated" >&2
        echo "Run: gh auth login" >&2
        return 1
    fi

    return 0
}

# Detect if current directory is a GitHub repository
# Returns: 0 if GitHub repo, 1 otherwise
# Outputs: owner/repo on success, error message on failure
detect_github_repo() {
    if ! git rev-parse --git-dir &> /dev/null; then
        echo "Error: Not a git repository" >&2
        return 1
    fi

    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null)

    if [ -z "$remote_url" ]; then
        echo "Error: No origin remote configured" >&2
        return 1
    fi

    if ! echo "$remote_url" | grep -q "github.com"; then
        echo "Error: Not a GitHub repository (remote: $remote_url)" >&2
        return 1
    fi

    # Extract owner/repo from URL
    local owner_repo
    owner_repo=$(echo "$remote_url" | sed -E 's#.*github\.com[:/]([^/]+)/([^.]+)(\.git)?#\1/\2#')

    echo "$owner_repo"
    return 0
}

# Check if GitHub Actions workflows exist
# Returns: 0 if workflows exist, 1 otherwise
check_github_actions_enabled() {
    # First check for local workflow files
    if [ -d ".github/workflows" ] && [ -n "$(ls -A .github/workflows 2>/dev/null)" ]; then
        local workflow_count
        workflow_count=$(find .github/workflows -name "*.yml" -o -name "*.yaml" | wc -l | tr -d ' ')
        echo "Found $workflow_count workflow file(s) in .github/workflows/"
        return 0
    fi

    # If gh CLI is available, check via API
    if check_gh_cli &> /dev/null; then
        local total_count
        total_count=$(gh api repos/:owner/:repo/actions/workflows --jq '.total_count' 2>/dev/null)

        if [ -n "$total_count" ] && [ "$total_count" -gt 0 ]; then
            echo "Found $total_count workflow(s) via GitHub API"
            return 0
        fi
    fi

    echo "No GitHub Actions workflows found" >&2
    return 1
}

# Check if current directory is a GitHub repo with Actions
# Combines detection functions for convenience
check_github_actions_repo() {
    local owner_repo
    owner_repo=$(detect_github_repo) || return 1

    echo "Detected GitHub repository: $owner_repo"

    if ! check_github_actions_enabled; then
        return 1
    fi

    return 0
}

# Get the latest workflow run for a specific commit
# Args: $1 = commit SHA
# Returns: 0 if found, 1 otherwise
# Outputs: JSON with run information
get_latest_run_for_commit() {
    local commit_sha="$1"

    if [ -z "$commit_sha" ]; then
        echo "Error: Commit SHA required" >&2
        return 1
    fi

    check_gh_cli || return 1

    local runs
    runs=$(gh run list --commit "$commit_sha" --json databaseId,status,conclusion,workflowName,createdAt --limit 10)

    if [ -z "$runs" ] || [ "$runs" = "[]" ]; then
        echo "No workflow runs found for commit $commit_sha" >&2
        return 1
    fi

    echo "$runs"
    return 0
}

# Get failed runs for current branch
# Args: $1 = branch name (optional, defaults to current branch)
# Returns: 0 if found, 1 otherwise
# Outputs: JSON with failed run information
get_failed_runs() {
    local branch="$1"

    if [ -z "$branch" ]; then
        branch=$(git branch --show-current)
    fi

    check_gh_cli || return 1

    local runs
    runs=$(gh run list --branch "$branch" --status failure --json databaseId,conclusion,workflowName,createdAt --limit 10)

    if [ -z "$runs" ] || [ "$runs" = "[]" ]; then
        echo "No failed runs found for branch $branch" >&2
        return 1
    fi

    echo "$runs"
    return 0
}

# Analyze failure logs for common patterns
# Args: $1 = run ID
# Returns: 0 on success, 1 on failure
analyze_failure_logs() {
    local run_id="$1"

    if [ -z "$run_id" ]; then
        echo "Error: Run ID required" >&2
        return 1
    fi

    check_gh_cli || return 1

    echo "Fetching failed logs for run $run_id..."
    echo ""

    local logs
    logs=$(gh run view "$run_id" --log-failed 2>&1)

    if [ -z "$logs" ]; then
        echo "No failed logs found (run may have succeeded or be in progress)" >&2
        return 1
    fi

    # Output the logs
    echo "$logs"
    echo ""
    echo "=== Common Error Patterns ==="

    # Check for common error patterns
    if echo "$logs" | grep -qi "permission denied"; then
        echo "⚠️  Found: Permission issues"
    fi

    if echo "$logs" | grep -qi "command not found"; then
        echo "⚠️  Found: Missing command or tool"
    fi

    if echo "$logs" | grep -qi "no such file or directory"; then
        echo "⚠️  Found: Missing file or directory"
    fi

    if echo "$logs" | grep -qiE "(test.*failed|failed.*test|assertion.*error)"; then
        echo "⚠️  Found: Test failures"
    fi

    if echo "$logs" | grep -qiE "(syntax.*error|parse.*error)"; then
        echo "⚠️  Found: Syntax or parse errors"
    fi

    if echo "$logs" | grep -qiE "(timeout|timed out)"; then
        echo "⚠️  Found: Timeout issues"
    fi

    if echo "$logs" | grep -qiE "(out of memory|oom)"; then
        echo "⚠️  Found: Memory issues"
    fi

    if echo "$logs" | grep -qiE "(connection.*refused|connection.*timeout|network.*error)"; then
        echo "⚠️  Found: Network connectivity issues"
    fi

    return 0
}

# Get workflow run summary
# Args: $1 = run ID
# Returns: 0 on success, 1 on failure
get_run_summary() {
    local run_id="$1"

    if [ -z "$run_id" ]; then
        echo "Error: Run ID required" >&2
        return 1
    fi

    check_gh_cli || return 1

    gh run view "$run_id" --verbose
    return $?
}

# List all workflows in the repository
list_workflows() {
    check_gh_cli || return 1

    echo "Available workflows:"
    gh api repos/:owner/:repo/actions/workflows --jq '.workflows[] | "\(.id)\t\(.name)\t\(.state)\t\(.path)"'
    return $?
}

# Get recent runs with summary
# Args: $1 = limit (optional, defaults to 10)
get_recent_runs() {
    local limit="${1:-10}"

    check_gh_cli || return 1

    gh run list --limit "$limit" --json databaseId,status,conclusion,workflowName,headBranch,createdAt,event
    return $?
}

# Find run ID for current HEAD commit
# Returns: run ID if found, empty otherwise
get_current_commit_run() {
    local commit_sha
    commit_sha=$(git rev-parse HEAD)

    local runs
    runs=$(get_latest_run_for_commit "$commit_sha")

    if [ $? -eq 0 ]; then
        echo "$runs" | jq -r '.[0].databaseId'
        return 0
    fi

    return 1
}

# Check status of most recent workflow run
# Returns: 0 if success, 1 if failed, 2 if in progress, 3 if other
check_latest_status() {
    check_gh_cli || return 1

    local latest_run
    latest_run=$(gh run list --limit 1 --json status,conclusion)

    local status
    status=$(echo "$latest_run" | jq -r '.[0].status')

    local conclusion
    conclusion=$(echo "$latest_run" | jq -r '.[0].conclusion')

    echo "Status: $status"
    echo "Conclusion: $conclusion"

    case "$conclusion" in
        "success")
            return 0
            ;;
        "failure")
            return 1
            ;;
        "")
            # Still in progress
            return 2
            ;;
        *)
            return 3
            ;;
    esac
}

# Functions are available when sourced (no export needed for bash/zsh)
