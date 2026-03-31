# Fix Git History - Remove Mapbox Token

The Mapbox token was committed in your git history. Here's how to fix it:

## Option 1: Reset and Recommit (Simplest - Recommended)

This will squash your unpushed commits into one clean commit:

```bash
# Reset to the last pushed commit (origin/main)
git reset --soft origin/main

# Now all your changes are staged
# Commit everything with a clean message
git commit -m "feat: Add new sidebar system and fix Mapbox token security

- Implemented reusable sidebar component with smooth animations
- Added HOT/WARM/COLD lead categories to log activity page
- Fixed blank page issue when returning from tabs
- Removed hardcoded Mapbox token, now uses environment variables
- Added .env.example and MAPBOX_SETUP.md documentation"

# Force push to replace the commits with the token
git push origin main --force
```

## Option 2: Interactive Rebase (Advanced)

If you want to keep separate commits:

```bash
# Start interactive rebase for last 3 commits
git rebase -i HEAD~3

# In the editor that opens, change 'pick' to 'edit' for commits with the token
# Save and close

# For each commit marked 'edit':
# 1. Make your changes to remove the token
# 2. Stage the changes: git add .
# 3. Amend the commit: git commit --amend --no-edit
# 4. Continue: git rebase --continue

# After all commits are fixed:
git push origin main --force
```

## Option 3: Filter-Branch (Nuclear Option)

Only use if the token is in many commits:

```bash
# Create a backup branch first
git branch backup-before-filter

# Remove the token from all commits
git filter-branch --tree-filter '
  if [ -f lib/features/admin/presentation/pages/admin_tracking_page.dart ]; then
    sed -i "s/pk\.eyJ[^'\''\"]*//g" lib/features/admin/presentation/pages/admin_tracking_page.dart
  fi
' --prune-empty HEAD

# Force push
git push origin main --force
```

## After Fixing

1. Verify the token is gone:
   ```bash
   git log -p | grep "pk.eyJ"
   ```
   (Should return nothing)

2. If you shared the token publicly, **revoke it immediately**:
   - Go to https://account.mapbox.com/access-tokens/
   - Delete or rotate the exposed token
   - Create a new token for your `.env` file

## Prevention

The following files have been updated to prevent this in the future:
- `.gitignore` - Now excludes `.env` files
- `.env.example` - Template for environment variables
- `MAPBOX_SETUP.md` - Setup instructions
- `admin_tracking_page.dart` - Now uses `AppConstants.mapboxPublicToken`

**Never commit `.env` files or actual tokens!**
