# Kubernetes Fork Automation Setup Guide

This guide helps you set up automated synchronization with upstream Kubernetes releases.

## Prerequisites

1. Fork the Kubernetes repository
2. Clone your fork locally
3. Ensure you have GitHub Actions enabled

## Initial Setup

### 1. Add the automation files

Copy all the files created by this setup:
- `.github/workflows/sync-upstream-kubernetes.yml` - Main sync workflow
- `.github/workflows/patch-notifications.yml` - Notification workflow
- `patches/` directory - Store your patch files here
- `scripts/patch-helper.sh` - Helper script for patch management

### 2. Configure repository settings

#### Required Repository Secrets (optional for notifications):
- `SLACK_WEBHOOK_URL` - For Slack notifications
- `SMTP_SERVER`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD` - For email notifications
- `NOTIFICATION_EMAIL` - Email to receive notifications

#### Required Permissions:
- Ensure GitHub Actions has write permissions to your repository
- Go to Settings → Actions → General → Workflow permissions
- Select "Read and write permissions"

### 3. Prepare your patches

Replace the example patch with your actual patches:

```bash
# Make the helper script executable
chmod +x scripts/patch-helper.sh

# Remove the example patch
rm patches/001-example-custom-feature.patch

# Create your patches
# Option 1: From existing commits
git format-patch -1 <commit-hash> --stdout > patches/001-your-feature.patch

# Option 2: From current changes
./scripts/patch-helper.sh create your-feature-name

# Test patches against a Kubernetes version
./scripts/patch-helper.sh test v1.32.5
```

## How It Works

### Automatic Sync Process

1. **Hourly Check**: The workflow runs every hour to check for new upstream tags
2. **Tag Detection**: Compares upstream tags with your fork's tags
3. **Patch Application**: For each new tag:
   - Creates a branch from the upstream tag
   - Applies all patches in order
   - If successful: Creates a new tag (e.g., `v1.32.5-fork.1`)
   - If conflicts: Creates a PR for manual resolution

### Manual Sync

You can manually trigger the sync for a specific tag:

```bash
# Via GitHub UI
Go to Actions → Sync Upstream Kubernetes → Run workflow → Enter tag

# Via GitHub CLI
gh workflow run sync-upstream-kubernetes.yml -f tag=v1.32.5
```

## Managing Patches

### Creating New Patches

```bash
# 1. Make your changes on a branch
git checkout -b my-feature

# 2. Commit your changes
git add .
git commit -m "Add my custom feature"

# 3. Create the patch
./scripts/patch-helper.sh create my-feature

# 4. Test against latest upstream
./scripts/patch-helper.sh test v1.32.5
```

### Updating Existing Patches

When patches no longer apply cleanly:

```bash
# 1. Checkout the problematic upstream version
git checkout v1.32.5

# 2. Manually apply and fix the patch
git apply --3way patches/001-your-feature.patch
# Fix conflicts...
git add .
git commit -m "Updated patch for v1.32.5"

# 3. Recreate the patch
git format-patch -1 --stdout > patches/001-your-feature.patch
```

### Patch Best Practices

1. **Keep patches minimal**: Smaller patches are easier to maintain
2. **Use descriptive names**: `001-add-custom-scheduler.patch`
3. **Document patches**: Add comments explaining why each patch exists
4. **Consider upstreaming**: If a patch could benefit others, consider contributing it upstream

## Handling Conflicts

When the automation detects conflicts:

1. A PR will be created with details about which patches failed
2. You'll receive notifications (if configured)
3. To resolve:

```bash
# 1. Checkout the PR branch
git fetch origin
git checkout auto-patch-v1.32.5

# 2. See which patches failed
git status

# 3. Manually apply and fix failed patches
git apply --3way patches/002-conflicting-patch.patch
# Resolve conflicts...
git add .
git commit -m "Apply patch: 002-conflicting-patch.patch"

# 4. Continue with remaining patches
./scripts/patch-helper.sh apply

# 5. Create the fork tag
git tag -a "v1.32.5-fork.1" -m "Fork of Kubernetes v1.32.5 with custom patches"
git push origin "v1.32.5-fork.1"

# 6. Close the PR
```

## Monitoring

### Viewing Sync Status

- **GitHub Actions**: Check the Actions tab for workflow runs
- **Releases**: Successfully synced versions appear in Releases
- **Pull Requests**: Conflicts create PRs labeled `needs-manual-intervention`

### Debugging Failed Syncs

```bash
# Check workflow logs
Go to Actions → Select failed run → View logs

# Test patches locally
./scripts/patch-helper.sh test v1.32.5

# Run sync manually with specific tag
gh workflow run sync-upstream-kubernetes.yml -f tag=v1.32.5
```

## Versioning Scheme

The automation uses this versioning pattern:
- Upstream: `v1.32.5`
- Your fork: `v1.32.5-fork.1`

If you need to make additional changes to a synced version:
- `v1.32.5-fork.2`, `v1.32.5-fork.3`, etc.

## Customization

### Changing Check Frequency

Edit `.github/workflows/sync-upstream-kubernetes.yml`:
```yaml
schedule:
  - cron: '0 */6 * * *'  # Every 6 hours instead of hourly
```

### Modifying Tag Pattern

To sync only specific versions (e.g., stable releases):
```bash
# In sync-upstream-kubernetes.yml, modify the tag filter
git tag -l 'v*.*.0' --merged upstream/master  # Only x.y.0 releases
```

### Custom Notification Methods

Add additional notification steps to `patch-notifications.yml`:
- Discord webhooks
- Microsoft Teams
- Custom APIs

## Troubleshooting

### Common Issues

1. **"Permission denied" when pushing tags**
   - Check repository permissions for GitHub Actions
   - Ensure GITHUB_TOKEN has write access

2. **Patches apply locally but fail in CI**
   - Check for line ending differences (CRLF vs LF)
   - Ensure patches were created with `git format-patch`

3. **Workflow doesn't trigger**
   - Verify the workflow file is in the default branch
   - Check Actions are enabled in repository settings

4. **Too many tags being processed**
   - The workflow limits to 5 tags per run
   - Adjust the `head -5` limit in the workflow if needed

## Advanced Usage

### Multi-Version Support

To maintain patches for multiple Kubernetes versions:

```
patches/
├── 1.30/
│   ├── 001-feature.patch
│   └── 002-bugfix.patch
├── 1.31/
│   ├── 001-feature.patch
│   └── 002-bugfix.patch
└── 1.32/
    ├── 001-feature.patch
    └── 002-bugfix.patch
```

Modify the workflow to select patches based on the version being synced.

### Integration with CI/CD

Add steps to your existing CI/CD to:
1. Build your forked version
2. Run tests with your patches
3. Deploy to your infrastructure

## Support

For issues with:
- **Automation**: Check GitHub Actions logs and this guide
- **Patches**: Use `./scripts/patch-helper.sh test` to validate
- **Kubernetes**: Refer to upstream documentation

Remember to regularly review and update your patches as Kubernetes evolves!
