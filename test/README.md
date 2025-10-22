# GitHub Actions Skill Tests

This directory contains tests for the GitHub Actions skill.

## Running Tests

```bash
./test/test_skill.sh
```

## Test Coverage

The test suite covers:

1. **Prerequisites**
   - gh CLI availability
   - gh authentication status

2. **Repository Detection**
   - GitHub repository detection (HTTPS URLs)
   - GitHub repository detection (SSH URLs)
   - Owner/repo name extraction
   - Non-GitHub repository rejection

3. **Workflow Detection**
   - Workflow file presence in `.github/workflows/`
   - Empty workflow directory detection

4. **Helper Scripts**
   - Helper script existence
   - Helper script validity

## Integration Tests

For integration testing with real repositories, you can:

1. **Test in this repository** (if it becomes a GitHub repo):
   ```bash
   cd /path/to/claude-skill-github-actions
   # Test repo detection
   git remote get-url origin | grep -q github.com && echo "GitHub repo detected"
   ```

2. **Test in another GitHub repository with Actions**:
   ```bash
   cd /path/to/your/repo
   # Check for workflow runs
   gh run list --limit 5

   # Test log fetching
   gh run view <run-id> --log-failed
   ```

3. **Test common user scenarios**:
   - "Show me why the latest CI run failed"
   - "What's the status of GitHub Actions for this commit?"
   - "Download logs for the most recent workflow run"

## Manual Testing Scenarios

### Scenario 1: Recent Push Failure
```bash
# Setup: In a repo with failed run
COMMIT_SHA=$(git rev-parse HEAD)
gh run list --commit $COMMIT_SHA --json databaseId,conclusion

# Expected: Should find and display failed runs
```

### Scenario 2: Check Branch Status
```bash
# Setup: In a repo with multiple runs
BRANCH=$(git branch --show-current)
gh run list --branch $BRANCH --limit 5

# Expected: Should show recent runs for current branch
```

### Scenario 3: Analyze Failure
```bash
# Setup: Get a failed run ID
RUN_ID=$(gh run list --status failure --limit 1 --json databaseId --jq '.[0].databaseId')
gh run view $RUN_ID --log-failed

# Expected: Should show only failed step logs
```

## Test Requirements

- `gh` CLI installed and authenticated
- Git installed
- Bash shell
- Network access (for real repository tests)

## Adding New Tests

To add a new test:

1. Create a function named `test_<description>`
2. Use `print_test` to announce the test
3. Use `pass` or `fail` to report results
4. Return 0 for success, 1 for failure
5. Add the function call to `main()`

Example:
```bash
test_my_new_feature() {
    print_test "Test my new feature"

    # Test logic here
    if [ condition ]; then
        pass "Feature works correctly"
        return 0
    else
        fail "Feature failed: reason"
        return 1
    fi
}
```
