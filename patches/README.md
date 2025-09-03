# Kubernetes Fork Patches

This directory contains patches that are automatically applied to upstream Kubernetes releases.

## Patch Naming Convention

Patches are applied in alphabetical order, so use a naming convention like:
- `001-feature-name.patch`
- `002-another-feature.patch`
- `003-bugfix-description.patch`

## Creating Patches

To create a patch from commits:
```bash
# Create patch from the last N commits
git format-patch -N --stdout > patches/00X-description.patch

# Create patch from a specific commit
git format-patch -1 <commit-hash> --stdout > patches/00X-description.patch

# Create patch from a range
git diff upstream/master..feature-branch > patches/00X-description.patch
```

## Testing Patches

Before committing patches, test them:
```bash
# Check if patch applies cleanly
git apply --check patches/00X-description.patch

# Apply patch (dry run)
git apply --3way patches/00X-description.patch
```

## Updating Patches

When patches need updates due to upstream changes:
1. Apply the patch manually with conflicts
2. Resolve conflicts
3. Create a new patch file
4. Replace the old patch file

## Patch Guidelines

1. Keep patches focused and minimal
2. Add clear commit messages in patches
3. Document why each patch exists
4. Consider upstreaming patches when possible
