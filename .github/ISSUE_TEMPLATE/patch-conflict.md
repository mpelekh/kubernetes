---
name: Patch Conflict
about: Automated issue for patch conflicts during upstream sync
title: 'Patch Conflict: [TAG]'
labels: patch-conflict, high-priority
assignees: ''
---

## Patch Conflict Detected

An automated sync with upstream Kubernetes has encountered patch conflicts.

### Details

- **Upstream Tag**: `[TAG]`
- **PR**: [Link to PR]
- **Time**: [TIMESTAMP]

### Failed Patches

The following patches could not be applied automatically:
- [ ] List of failed patches

### Resolution Steps

1. Review the associated pull request
2. Checkout the branch locally
3. Manually resolve conflicts
4. Apply remaining patches
5. Create and push the fork tag
6. Close this issue and the PR

### Commands

```bash
# Checkout the branch
git checkout [BRANCH_NAME]

# Apply patches manually
git apply --3way patches/[PATCH_NAME]

# After resolving conflicts
git add .
git commit -m "Manually applied patch: [PATCH_NAME]"

# Create fork tag
git tag -a "[FORK_TAG]" -m "Fork of Kubernetes [TAG] with custom patches"
git push origin "[FORK_TAG]"
```

---
*This issue was automatically created by the patch conflict detection workflow.*
