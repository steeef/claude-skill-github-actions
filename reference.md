# GitHub Actions API Reference

This document provides reference information for working with GitHub Actions via the `gh` CLI and REST API.

## GitHub CLI Commands

### Workflow Runs

#### List runs
```bash
gh run list [flags]
```

**Useful flags:**
- `--branch <branch>` - Filter by branch
- `--commit <SHA>` - Filter by commit SHA
- `--status <status>` - Filter by status (queued, completed, in_progress, requested, waiting, pending, action_required, cancelled, failure, neutral, skipped, stale, startup_failure, success, timed_out)
- `--workflow <name>` - Filter by workflow name
- `--limit <N>` - Maximum number of runs (default 20)
- `--json <fields>` - Output as JSON with specified fields
- `--jq <expression>` - Filter JSON output

**Useful JSON fields:**
- `databaseId` - Run ID
- `status` - Current status
- `conclusion` - Final result (null if in progress)
- `workflowName` - Workflow name
- `headBranch` - Branch name
- `headSha` - Commit SHA
- `createdAt` - Creation timestamp
- `updatedAt` - Last update timestamp
- `event` - Trigger event (push, pull_request, etc.)

#### View run details
```bash
gh run view [<run-id>] [flags]
```

**Useful flags:**
- `--log` - View full logs
- `--log-failed` - View logs for failed steps only
- `--verbose` - Show all job steps
- `--job <job-id>` - View specific job
- `--json <fields>` - Output as JSON
- `--exit-status` - Exit with non-zero if run failed

**Useful JSON fields:**
- `jobs` - Array of job objects
- `status` - Run status
- `conclusion` - Run conclusion
- `workflowName` - Workflow name
- `headBranch` - Branch name

#### Download run artifacts
```bash
gh run download [<run-id>] [flags]
```

**Useful flags:**
- `-n, --name <name>` - Download specific artifact by name
- `-D, --dir <directory>` - Download directory

#### Watch run
```bash
gh run watch [<run-id>]
```

Live updates of run progress.

#### Rerun workflow
```bash
gh run rerun [<run-id>] [flags]
```

**Useful flags:**
- `--failed` - Rerun only failed jobs

### Workflows

#### List workflows
```bash
gh workflow list [flags]
```

#### View workflow details
```bash
gh workflow view [<workflow>] [flags]
```

#### Run workflow manually
```bash
gh workflow run <workflow> [flags]
```

**Useful flags:**
- `--ref <branch>` - Branch or tag to run on
- `-f, --field <key=value>` - Workflow input

## GitHub REST API Endpoints

All endpoints use the base URL: `https://api.github.com`

### List workflow runs
```
GET /repos/{owner}/{repo}/actions/runs
```

**Query parameters:**
- `actor` - Filter by user
- `branch` - Filter by branch
- `event` - Filter by trigger event
- `status` - Filter by status
- `created` - Filter by creation date
- `per_page` - Results per page (default 30, max 100)
- `page` - Page number

**Example with gh:**
```bash
gh api repos/:owner/:repo/actions/runs --jq '.workflow_runs[] | {id: .id, name: .name, status: .status, conclusion: .conclusion}'
```

### Get workflow run
```
GET /repos/{owner}/{repo}/actions/runs/{run_id}
```

**Example with gh:**
```bash
gh api repos/:owner/:repo/actions/runs/{run_id}
```

### List workflow run jobs
```
GET /repos/{owner}/{repo}/actions/runs/{run_id}/jobs
```

**Example with gh:**
```bash
gh api repos/:owner/:repo/actions/runs/{run_id}/jobs --jq '.jobs[] | {id: .id, name: .name, status: .status, conclusion: .conclusion}'
```

### Get job logs
```
GET /repos/{owner}/{repo}/actions/jobs/{job_id}/logs
```

Returns raw log content.

**Example with gh:**
```bash
gh api repos/:owner/:repo/actions/jobs/{job_id}/logs
```

### Download workflow run logs
```
GET /repos/{owner}/{repo}/actions/runs/{run_id}/logs
```

Returns a ZIP file containing all logs.

**Example with gh:**
```bash
gh api repos/:owner/:repo/actions/runs/{run_id}/logs > logs.zip
```

### List workflows
```
GET /repos/{owner}/{repo}/actions/workflows
```

**Example with gh:**
```bash
gh api repos/:owner/:repo/actions/workflows --jq '.workflows[] | {id: .id, name: .name, state: .state, path: .path}'
```

### List workflow runs for a workflow
```
GET /repos/{owner}/{repo}/actions/workflows/{workflow_id}/runs
```

**Example with gh:**
```bash
gh api repos/:owner/:repo/actions/workflows/{workflow_id}/runs
```

## Common Patterns

### Get latest run for current commit
```bash
COMMIT_SHA=$(git rev-parse HEAD)
RUN_ID=$(gh run list --commit $COMMIT_SHA --json databaseId --jq '.[0].databaseId')
gh run view $RUN_ID
```

### Get all failed runs in last 24 hours
```bash
YESTERDAY=$(date -u -v-1d '+%Y-%m-%dT%H:%M:%SZ')  # macOS
# YESTERDAY=$(date -u -d '1 day ago' '+%Y-%m-%dT%H:%M:%SZ')  # Linux

gh api repos/:owner/:repo/actions/runs \
  --jq ".workflow_runs[] | select(.conclusion == \"failure\" and .created_at > \"$YESTERDAY\") | {id: .id, name: .name, branch: .head_branch, created_at: .created_at}"
```

### Extract error messages from logs
```bash
gh run view $RUN_ID --log-failed | grep -i "error" | head -20
```

### Check if workflow is passing
```bash
gh run view $(gh run list --limit 1 --json databaseId --jq '.[0].databaseId') --exit-status
echo $?  # 0 = success, non-zero = failure
```

### Compare failed vs successful run
```bash
# Get latest successful run
SUCCESS_ID=$(gh run list --status success --limit 1 --json databaseId --jq '.[0].databaseId')

# Get latest failed run
FAILURE_ID=$(gh run list --status failure --limit 1 --json databaseId --jq '.[0].databaseId')

# Compare commits
gh run view $SUCCESS_ID --json headSha --jq '.headSha'
gh run view $FAILURE_ID --json headSha --jq '.headSha'

# Show diff
git diff $(gh run view $SUCCESS_ID --json headSha --jq -r '.headSha') $(gh run view $FAILURE_ID --json headSha --jq -r '.headSha')
```

### Monitor build status
```bash
# Watch current run
gh run watch $(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')
```

## Common Error Patterns

### Authentication errors
```
Error: HTTP 401: Bad credentials
```
**Solution:** Run `gh auth refresh` or `gh auth login`

### Permission errors
```
Error: Resource not accessible by integration
```
**Solution:** Check repository permissions or run `gh auth refresh -s repo`

### Rate limiting
```
Error: API rate limit exceeded
```
**Solution:** Wait or authenticate with `gh auth login` for higher limits

### No runs found
```
no runs found
```
**Causes:**
- No workflows configured in `.github/workflows/`
- Workflows exist but haven't run yet
- Filters are too restrictive

## Status and Conclusion Values

### Status Values
- `queued` - Run is queued but not started
- `in_progress` - Run is currently executing
- `completed` - Run has finished (check conclusion)
- `waiting` - Waiting for approval or resource
- `requested` - Run requested but not queued yet
- `pending` - Pending execution

### Conclusion Values (for completed runs)
- `success` - All jobs succeeded
- `failure` - At least one job failed
- `cancelled` - Run was cancelled
- `skipped` - Run was skipped
- `timed_out` - Run exceeded time limit
- `action_required` - Manual action needed
- `neutral` - No jobs ran
- `stale` - Run is outdated
- `startup_failure` - Failed to start

## Troubleshooting Tips

1. **Start with failed logs only**: Use `--log-failed` to reduce noise
2. **Check timing**: Recent failures may indicate flaky tests or infrastructure issues
3. **Compare with main branch**: See if issue exists on main/master
4. **Look at job steps**: Use `--verbose` to see which step failed
5. **Check for patterns**: Multiple similar failures may indicate systemic issue
6. **Examine artifacts**: Download artifacts if logs don't show full picture
7. **Review workflow file**: Check `.github/workflows/*.yml` for configuration issues

## Useful jq Patterns

### Extract specific fields
```bash
gh run list --json databaseId,status,conclusion,workflowName,createdAt | jq '.[]'
```

### Filter by conclusion
```bash
gh run list --json databaseId,conclusion | jq '.[] | select(.conclusion == "failure")'
```

### Format as table
```bash
gh run list --json databaseId,workflowName,status,conclusion | jq -r '.[] | "\(.databaseId)\t\(.workflowName)\t\(.status)\t\(.conclusion)"'
```

### Get first matching run
```bash
gh run list --json databaseId,conclusion | jq -r 'first(.[] | select(.conclusion == "failure")) | .databaseId'
```

### Count by status
```bash
gh run list --json status --limit 100 | jq 'group_by(.status) | map({status: .[0].status, count: length})'
```
