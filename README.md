# GitHub Actions Skill for Claude Code

A Claude Code skill for detecting, monitoring, and troubleshooting GitHub Actions workflows.

## Features

- **Automatic Repository Detection**: Identifies GitHub repositories and checks if GitHub Actions is enabled
- **Workflow Run Discovery**: Find runs by commit SHA, branch, or recent activity
- **Log Analysis**: Download and analyze workflow logs with automatic error pattern detection
- **Status Monitoring**: Check workflow status, job details, and step-by-step execution
- **Smart Troubleshooting**: Provides actionable insights for common CI/CD failures

## Prerequisites

- [GitHub CLI (`gh`)](https://cli.github.com/) installed and authenticated
- Git repository with GitHub remote
- GitHub Actions workflows configured (`.github/workflows/`)

## Installation

### As a Project Skill (Recommended)

1. Clone or copy this repository into your project:
   ```bash
   mkdir -p .claude/skills
   cd .claude/skills
   git clone https://github.com/your-username/claude-skill-github-actions.git github-actions
   ```

2. Alternatively, symlink to a shared location:
   ```bash
   mkdir -p .claude/skills
   ln -s /path/to/claude-skill-github-actions .claude/skills/github-actions
   ```

3. Commit to share with your team:
   ```bash
   git add .claude/skills/github-actions
   git commit -m "Add GitHub Actions skill"
   ```

### As a Personal Skill

Install globally for all your projects:

```bash
mkdir -p ~/.claude/skills
cd ~/.claude/skills
git clone https://github.com/your-username/claude-skill-github-actions.git github-actions
```

## Usage

Once installed, Claude Code will automatically use this skill when you ask about GitHub Actions:

### Example Prompts

**Check CI status:**
```
"What's the status of GitHub Actions for this commit?"
"Show me the latest CI run"
"Is CI passing?"
```

**Troubleshoot failures:**
```
"Why did the latest CI run fail?"
"Show me the error logs from the failed workflow"
"What went wrong with the build?"
```

**Analyze specific runs:**
```
"Show logs for workflow run #123"
"What tests failed in the latest run?"
"Download logs for the most recent failure"
```

**Branch and commit queries:**
```
"Show CI status for feature/new-feature branch"
"Did the workflow pass for commit abc123?"
"List all failed runs on main branch"
```

## How It Works

1. **Detection**: Claude detects you're in a GitHub repository with Actions enabled
2. **Query**: Uses `gh` CLI to fetch workflow runs and status
3. **Analysis**: Downloads logs and identifies error patterns
4. **Report**: Provides concise summary with actionable next steps

## Files

- `SKILL.md` - Main skill definition with instructions for Claude
- `scripts/gh_actions_helper.sh` - Bash utility functions
- `reference.md` - GitHub Actions API reference
- `test/` - Test suite for the skill

## Testing

Run the test suite:

```bash
./test/test_skill.sh
```

See [test/README.md](test/README.md) for details.

## Helper Functions

The skill includes helper functions you can use directly:

```bash
# Source the helper script
source .claude/skills/github-actions/scripts/gh_actions_helper.sh

# Check if in a GitHub repo with Actions
check_github_actions_repo

# Get runs for a commit
get_latest_run_for_commit "abc123"

# Analyze failure logs
analyze_failure_logs "1234567890"

# Get failed runs on current branch
get_failed_runs

# List all workflows
list_workflows
```

## Authentication

Ensure `gh` is authenticated:

```bash
gh auth status
```

If not authenticated:

```bash
gh auth login
```

For private repositories, ensure proper scopes:

```bash
gh auth refresh -s repo,read:org
```

## Common Use Cases

### 1. Quick Status Check
```bash
# Claude will run:
gh run list --limit 5
```

### 2. Troubleshoot Latest Failure
```bash
# Claude will:
# 1. Find latest failed run
# 2. Download failed logs
# 3. Identify error patterns
# 4. Suggest fixes
```

### 3. Compare Failed vs Successful Runs
```bash
# Claude will compare commits and changes between runs
```

### 4. Monitor Workflow Progress
```bash
# Claude will show real-time status of running workflows
```

## Troubleshooting

### "gh CLI is not installed"
Install GitHub CLI: https://cli.github.com/

### "gh is not authenticated"
Run: `gh auth login`

### "Not a GitHub repository"
Ensure you have a GitHub remote:
```bash
git remote get-url origin | grep github.com
```

### "No workflows found"
Check if workflows exist:
```bash
ls -la .github/workflows/
```

### Rate limiting
GitHub API has rate limits. Check status:
```bash
gh api rate_limit
```

## Contributing

Contributions welcome! Please:

1. Add tests for new features
2. Update documentation
3. Follow existing code style
4. Test with real repositories

## API Reference

See [reference.md](reference.md) for detailed GitHub Actions API documentation.

## License

MIT License - See LICENSE file for details

## Links

- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [GitHub Actions API](https://docs.github.com/en/rest/actions)
- [Claude Code Skills Documentation](https://docs.claude.com/en/docs/claude-code/skills.md)
