# Interactive Account Switching Demo

This document demonstrates how the GitHub Actions skill now handles authentication issues interactively.

## Scenario

You have multiple GitHub accounts authenticated with `gh`:
- `personal-account` (your personal GitHub)
- `work-account` (your company GitHub)

You're working in a repository owned by your company organization, but `gh` is currently authenticated with your personal account.

## What Happens Now

### Before (Original Behavior)

```bash
$ source scripts/gh_actions_helper.sh
$ check_gh_cli

Error: Current gh account 'personal-account' does not have access to 'company/private-repo'

This may be because:
  - The repository is in an organization you don't have access to
  - You're authenticated with the wrong GitHub account
  - The repository is private and you lack permissions

To fix this:
  1. Check available accounts: gh auth status
  2. Switch accounts: gh auth switch
  3. Or login with correct account: gh auth login

# User must manually run gh auth switch
$ gh auth switch
# ... interactive prompt from gh ...
```

### After (New Interactive Behavior)

```bash
$ source scripts/gh_actions_helper.sh
$ check_gh_cli

Current account 'personal-account' cannot access 'company/private-repo'

Available accounts:
 1. personal-account
 2. work-account

Select an account to switch to (1-2, or 'n' to skip): 2
Switching to account: work-account
Successfully switched to work-account
✓ Account work-account has access to company/private-repo

# Automatically continues - no manual intervention needed!
```

## How It Works

The `check_gh_cli()` function now:

1. **Detects access issue**: Tries to access the repository with the current account
2. **Checks for interactive terminal**: Uses `[ -t 0 ] && [ -t 1 ]` to detect if running interactively
3. **Lists available accounts**: Extracts all authenticated accounts from `gh auth status`
4. **Prompts for selection**: Asks user to pick the correct account
5. **Switches automatically**: Calls `gh auth switch -u <account>`
6. **Verifies access**: Confirms the new account can access the repository
7. **Returns success**: If access granted, the script continues normally

## Non-Interactive Mode

In CI/CD or scripts where stdin/stdout are not TTYs, the function falls back to showing the error message with manual instructions, preventing it from hanging waiting for input.

## Testing Interactive Mode

To test the interactive prompt (you'll need at least 2 authenticated gh accounts):

```bash
# Create a test repo with an org you don't have access to
cd /tmp
mkdir test-auth && cd test-auth
git init
git remote add origin git@github.com:some-private-org/private-repo.git

# Source the helper and run check
source /path/to/scripts/gh_actions_helper.sh
check_gh_cli
# Will prompt you to select an account
```

## Benefits

1. **Seamless workflow**: No need to remember manual commands
2. **Clear context**: Shows exactly which repo needs access
3. **Validation**: Confirms the selected account actually has access
4. **Safe**: Only prompts in interactive mode, won't break automation
5. **User-friendly**: Lists all options with numbered selection
