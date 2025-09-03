#!/bin/bash
# Patch management helper script

set -euo pipefail

PATCHES_DIR="patches"
UPSTREAM_REPO="kubernetes/kubernetes"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function usage() {
    cat << EOF
Kubernetes Fork Patch Helper

Usage: $0 <command> [options]

Commands:
    create <name>     Create a patch from current changes
    test <tag>        Test all patches against a specific upstream tag
    list              List all patches
    apply             Apply all patches in order
    update <patch>    Update a specific patch file
    
Examples:
    $0 create my-feature
    $0 test v1.32.5
    $0 apply
    
EOF
    exit 1
}

function create_patch() {
    local name=$1
    local patch_num=$(ls -1 "$PATCHES_DIR"/*.patch 2>/dev/null | wc -l)
    patch_num=$((patch_num + 1))
    local patch_file=$(printf "%s/%03d-%s.patch" "$PATCHES_DIR" "$patch_num" "$name")
    
    echo -e "${YELLOW}Creating patch: $patch_file${NC}"
    
    # Check for uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        echo -e "${YELLOW}You have uncommitted changes. Commit them first.${NC}"
        exit 1
    fi
    
    # Create patch from last commit
    git format-patch -1 --stdout > "$patch_file"
    
    echo -e "${GREEN}✓ Patch created: $patch_file${NC}"
    echo "Don't forget to test it with: $0 test <upstream-tag>"
}

function test_patches() {
    local tag=$1
    local temp_branch="patch-test-$$"
    
    echo -e "${YELLOW}Testing patches against $tag${NC}"
    
    # Save current branch
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    
    # Create test branch from upstream tag
    git fetch upstream --tags
    git checkout -b "$temp_branch" "$tag" 2>/dev/null || {
        echo -e "${RED}✗ Failed to checkout tag $tag${NC}"
        exit 1
    }
    
    # Test each patch
    local failed=0
    for patch in "$PATCHES_DIR"/*.patch; do
        if [[ -f "$patch" ]]; then
            echo -n "Testing $(basename "$patch")... "
            if git apply --check "$patch" 2>/dev/null; then
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${RED}✗ CONFLICT${NC}"
                ((failed++))
            fi
        fi
    done
    
    # Cleanup
    git checkout "$current_branch"
    git branch -D "$temp_branch"
    
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}✓ All patches apply cleanly to $tag${NC}"
    else
        echo -e "${RED}✗ $failed patches have conflicts${NC}"
        exit 1
    fi
}

function list_patches() {
    echo -e "${YELLOW}Current patches:${NC}"
    for patch in "$PATCHES_DIR"/*.patch; do
        if [[ -f "$patch" ]]; then
            echo "  - $(basename "$patch")"
            # Show first line of commit message
            grep -m1 "^Subject:" "$patch" | sed 's/Subject: \[PATCH\] /    /'
        fi
    done
}

function apply_patches() {
    echo -e "${YELLOW}Applying all patches...${NC}"
    
    local applied=0
    local failed=0
    
    for patch in "$PATCHES_DIR"/*.patch; do
        if [[ -f "$patch" ]]; then
            echo -n "Applying $(basename "$patch")... "
            if git apply "$patch" 2>/dev/null; then
                echo -e "${GREEN}✓${NC}"
                git add -A
                # Extract commit message from patch
                local msg=$(grep -m1 "^Subject:" "$patch" | sed 's/Subject: \[PATCH\] //')
                git commit -m "$msg" -m "Applied from patch: $(basename "$patch")"
                ((applied++))
            else
                echo -e "${RED}✗ FAILED${NC}"
                ((failed++))
            fi
        fi
    done
    
    echo -e "\n${GREEN}Applied: $applied${NC}, ${RED}Failed: $failed${NC}"
}

function update_patch() {
    local patch_name=$1
    local patch_file="$PATCHES_DIR/$patch_name"
    
    if [[ ! -f "$patch_file" ]]; then
        echo -e "${RED}✗ Patch file not found: $patch_file${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Updating patch: $patch_name${NC}"
    echo "1. Make your changes and commit them"
    echo "2. Run: git format-patch -1 --stdout > $patch_file"
    echo "3. Test with: $0 test <upstream-tag>"
}

# Main script logic
if [[ $# -eq 0 ]]; then
    usage
fi

# Ensure patches directory exists
mkdir -p "$PATCHES_DIR"

# Add upstream remote if not exists
if ! git remote | grep -q upstream; then
    echo "Adding upstream remote..."
    git remote add upstream "https://github.com/$UPSTREAM_REPO.git"
fi

case "$1" in
    create)
        [[ $# -eq 2 ]] || usage
        create_patch "$2"
        ;;
    test)
        [[ $# -eq 2 ]] || usage
        test_patches "$2"
        ;;
    list)
        list_patches
        ;;
    apply)
        apply_patches
        ;;
    update)
        [[ $# -eq 2 ]] || usage
        update_patch "$2"
        ;;
    *)
        usage
        ;;
esac
