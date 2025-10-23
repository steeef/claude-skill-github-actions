#!/usr/bin/env bash

# Test script for GitHub Actions skill
# This script tests the helper functions and common workflows

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
declare -a FAILED_TESTS

# Helper functions
print_test() {
    echo -e "\n${YELLOW}[TEST]${NC} $1"
    TESTS_RUN=$((TESTS_RUN + 1))
}

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILED_TESTS+=("$1")
}

# Test 1: Check gh CLI availability
test_gh_cli_available() {
    print_test "Check gh CLI is available"

    if command -v gh &> /dev/null; then
        pass "gh CLI found at $(which gh)"
        return 0
    else
        fail "gh CLI not found - this skill requires gh to be installed"
        return 1
    fi
}

# Test 2: Check gh authentication
test_gh_auth() {
    print_test "Check gh authentication status"

    if gh auth status &> /dev/null; then
        pass "gh is authenticated"
        return 0
    else
        fail "gh is not authenticated - run 'gh auth login'"
        return 1
    fi
}

# Test 3: Test GitHub repo detection in test repo
test_github_repo_detection() {
    print_test "Test GitHub repository detection"

    # Create a temporary test repo
    TEST_REPO=$(mktemp -d)
    cd "$TEST_REPO"

    git init -q
    git remote add origin "https://github.com/test-user/test-repo.git"

    if git remote get-url origin 2>/dev/null | grep -q github.com; then
        pass "Successfully detected GitHub remote"
        cd "$SKILL_ROOT"
        rm -rf "$TEST_REPO"
        return 0
    else
        fail "Failed to detect GitHub remote"
        cd "$SKILL_ROOT"
        rm -rf "$TEST_REPO"
        return 1
    fi
}

# Test 4: Test owner/repo extraction
test_owner_repo_extraction() {
    print_test "Test owner/repo name extraction"

    TEST_REPO=$(mktemp -d)
    cd "$TEST_REPO"

    git init -q
    git remote add origin "https://github.com/test-owner/test-repo.git"

    EXTRACTED=$(git remote get-url origin | sed -E 's#.*github\.com[:/]([^/]+)/([^.]+)(\.git)?#\1/\2#')

    if [ "$EXTRACTED" = "test-owner/test-repo" ]; then
        pass "Correctly extracted 'test-owner/test-repo'"
        cd "$SKILL_ROOT"
        rm -rf "$TEST_REPO"
        return 0
    else
        fail "Expected 'test-owner/test-repo' but got '$EXTRACTED'"
        cd "$SKILL_ROOT"
        rm -rf "$TEST_REPO"
        return 1
    fi
}

# Test 5: Test SSH URL extraction
test_ssh_url_extraction() {
    print_test "Test SSH URL owner/repo extraction"

    TEST_REPO=$(mktemp -d)
    cd "$TEST_REPO"

    git init -q
    git remote add origin "git@github.com:test-owner/test-repo.git"

    EXTRACTED=$(git remote get-url origin | sed -E 's#.*github\.com[:/]([^/]+)/([^.]+)(\.git)?#\1/\2#')

    if [ "$EXTRACTED" = "test-owner/test-repo" ]; then
        pass "Correctly extracted 'test-owner/test-repo' from SSH URL"
        cd "$SKILL_ROOT"
        rm -rf "$TEST_REPO"
        return 0
    else
        fail "Expected 'test-owner/test-repo' but got '$EXTRACTED'"
        cd "$SKILL_ROOT"
        rm -rf "$TEST_REPO"
        return 1
    fi
}

# Test 6: Test non-GitHub repo detection
test_non_github_repo() {
    print_test "Test non-GitHub repository detection"

    TEST_REPO=$(mktemp -d)
    cd "$TEST_REPO"

    git init -q
    git remote add origin "https://gitlab.com/test-user/test-repo.git"

    if git remote get-url origin 2>/dev/null | grep -q github.com; then
        fail "Should not detect non-GitHub repo as GitHub"
        cd "$SKILL_ROOT"
        rm -rf "$TEST_REPO"
        return 1
    else
        pass "Correctly rejected non-GitHub repository"
        cd "$SKILL_ROOT"
        rm -rf "$TEST_REPO"
        return 0
    fi
}

# Test 7: Test workflow file detection
test_workflow_file_detection() {
    print_test "Test GitHub Actions workflow file detection"

    TEST_REPO=$(mktemp -d)
    cd "$TEST_REPO"

    mkdir -p .github/workflows
    touch .github/workflows/ci.yml

    if [ -d ".github/workflows" ] && [ -n "$(ls -A .github/workflows)" ]; then
        pass "Successfully detected workflow files"
        cd "$SKILL_ROOT"
        rm -rf "$TEST_REPO"
        return 0
    else
        fail "Failed to detect workflow files"
        cd "$SKILL_ROOT"
        rm -rf "$TEST_REPO"
        return 1
    fi
}

# Test 8: Test empty workflows directory
test_empty_workflows_dir() {
    print_test "Test empty workflows directory detection"

    TEST_REPO=$(mktemp -d)
    cd "$TEST_REPO"

    mkdir -p .github/workflows

    if [ -d ".github/workflows" ] && [ -z "$(ls -A .github/workflows)" ]; then
        pass "Correctly identified empty workflows directory"
        cd "$SKILL_ROOT"
        rm -rf "$TEST_REPO"
        return 0
    else
        fail "Failed to detect empty workflows directory"
        cd "$SKILL_ROOT"
        rm -rf "$TEST_REPO"
        return 1
    fi
}

# Test 9: Test helper script existence
test_helper_script_exists() {
    print_test "Test helper script exists"

    if [ -f "$SKILL_ROOT/scripts/gh_actions_helper.sh" ]; then
        pass "Helper script exists"
        return 0
    else
        fail "Helper script not found at scripts/gh_actions_helper.sh"
        return 1
    fi
}

# Test 10: Test helper script is executable
test_helper_script_executable() {
    print_test "Test helper script is executable or can be sourced"

    if [ -f "$SKILL_ROOT/scripts/gh_actions_helper.sh" ]; then
        if [ -x "$SKILL_ROOT/scripts/gh_actions_helper.sh" ] || bash -n "$SKILL_ROOT/scripts/gh_actions_helper.sh" 2>/dev/null; then
            pass "Helper script is valid bash script"
            return 0
        else
            fail "Helper script has syntax errors"
            return 1
        fi
    else
        # Skip if script doesn't exist yet (will be caught by previous test)
        echo "Skipping - helper script not yet created"
        return 0
    fi
}

# Test 11: Test get_gh_account function
test_get_gh_account() {
    print_test "Test get_gh_account function"

    if ! command -v gh &> /dev/null; then
        echo "Skipping - gh not installed"
        return 0
    fi

    if ! gh auth status &> /dev/null; then
        echo "Skipping - gh not authenticated"
        return 0
    fi

    # Source the helper script
    source "$SKILL_ROOT/scripts/gh_actions_helper.sh"

    local account
    account=$(get_gh_account)

    if [ -n "$account" ]; then
        pass "Successfully retrieved gh account: $account"
        return 0
    else
        fail "Failed to retrieve gh account"
        return 1
    fi
}

# Test 12: Test check_repo_access with valid repo
test_check_repo_access_public() {
    print_test "Test repo access check with public repo"

    if ! command -v gh &> /dev/null; then
        echo "Skipping - gh not installed"
        return 0
    fi

    if ! gh auth status &> /dev/null; then
        echo "Skipping - gh not authenticated"
        return 0
    fi

    # Source the helper script
    source "$SKILL_ROOT/scripts/gh_actions_helper.sh"

    # Test with a known public repo
    if check_repo_access "cli/cli"; then
        pass "Successfully verified access to public repo"
        return 0
    else
        fail "Should have access to public repo cli/cli"
        return 1
    fi
}

# Test 13: Test check_repo_access with invalid repo
test_check_repo_access_invalid() {
    print_test "Test repo access check with invalid repo"

    if ! command -v gh &> /dev/null; then
        echo "Skipping - gh not installed"
        return 0
    fi

    if ! gh auth status &> /dev/null; then
        echo "Skipping - gh not authenticated"
        return 0
    fi

    # Source the helper script
    source "$SKILL_ROOT/scripts/gh_actions_helper.sh"

    # Test with a repo that doesn't exist
    if ! check_repo_access "this-user-does-not-exist-12345/this-repo-does-not-exist-12345" 2>/dev/null; then
        pass "Correctly detected no access to non-existent repo"
        return 0
    else
        fail "Should not have access to non-existent repo"
        return 1
    fi
}

# Test 14: Test get_all_gh_accounts function
test_get_all_accounts() {
    print_test "Test get_all_gh_accounts function"

    if ! command -v gh &> /dev/null; then
        echo "Skipping - gh not installed"
        return 0
    fi

    if ! gh auth status &> /dev/null; then
        echo "Skipping - gh not authenticated"
        return 0
    fi

    # Source the helper script
    source "$SKILL_ROOT/scripts/gh_actions_helper.sh"

    local accounts
    accounts=$(get_all_gh_accounts)

    if [ -n "$accounts" ]; then
        local count
        count=$(echo "$accounts" | wc -l | tr -d ' ')
        pass "Successfully retrieved $count authenticated account(s)"
        return 0
    else
        fail "Failed to retrieve authenticated accounts"
        return 1
    fi
}

# Main test execution
main() {
    echo "======================================"
    echo "GitHub Actions Skill Test Suite"
    echo "======================================"

    # Run all tests
    test_gh_cli_available
    test_gh_auth
    test_github_repo_detection
    test_owner_repo_extraction
    test_ssh_url_extraction
    test_non_github_repo
    test_workflow_file_detection
    test_empty_workflows_dir
    test_helper_script_exists
    test_helper_script_executable
    test_get_gh_account
    test_check_repo_access_public
    test_check_repo_access_invalid
    test_get_all_accounts

    # Print summary
    echo ""
    echo "======================================"
    echo "Test Summary"
    echo "======================================"
    echo "Total tests: $TESTS_RUN"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"

    if [ $TESTS_FAILED -gt 0 ]; then
        echo ""
        echo "Failed tests:"
        for test in "${FAILED_TESTS[@]}"; do
            echo -e "  ${RED}✗${NC} $test"
        done
        exit 1
    else
        echo -e "\n${GREEN}All tests passed!${NC}"
        exit 0
    fi
}

# Run main function
main
