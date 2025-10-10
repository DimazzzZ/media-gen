#!/bin/bash

# Script to validate GitHub Actions workflow files locally

set -e

echo "🔍 Validating GitHub Actions workflows..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .github/workflows directory exists
if [ ! -d ".github/workflows" ]; then
    echo -e "${RED}❌ .github/workflows directory not found${NC}"
    exit 1
fi

# Function to validate YAML syntax
validate_yaml() {
    local file="$1"
    echo "Validating YAML syntax for $file..."
    
    # Try to parse with Python (if PyYAML is available)
    if command -v python3 &> /dev/null; then
        if python3 -c "import yaml" 2>/dev/null; then
            python3 -c "
import yaml
import sys
try:
    with open('$file', 'r') as f:
        yaml.safe_load(f)
    print('✅ Valid YAML syntax')
except yaml.YAMLError as e:
    print('❌ YAML syntax error:', e)
    sys.exit(1)
except Exception as e:
    print('❌ Error reading file:', e)
    sys.exit(1)
            "
        else
            echo "⚠️  PyYAML not available, performing basic syntax check..."
            # Basic YAML syntax check
            if grep -E "^\s*-\s*$|^\s*:\s*$" "$file" > /dev/null; then
                echo -e "${RED}❌ Invalid YAML: empty keys or values found${NC}"
                return 1
            fi
            echo -e "${GREEN}✅ Basic YAML syntax check passed${NC}"
        fi
    else
        echo "⚠️  Python3 not available, skipping YAML syntax check"
    fi
}

# Function to check workflow structure
check_workflow_structure() {
    local file="$1"
    echo "Checking workflow structure for $file..."
    
    # Check for required fields
    if ! grep -q "^name:" "$file"; then
        echo -e "${RED}❌ Missing 'name' field${NC}"
        return 1
    fi
    
    if ! grep -q "^on:" "$file"; then
        echo -e "${RED}❌ Missing 'on' field${NC}"
        return 1
    fi
    
    if ! grep -q "^jobs:" "$file"; then
        echo -e "${RED}❌ Missing 'jobs' field${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Required fields present${NC}"
}

# Function to check for common issues
check_common_issues() {
    local file="$1"
    echo "Checking for common issues in $file..."
    
    # Check for tabs (using sed for compatibility)
    if sed -n l "$file" | grep -q $'\t'; then
        echo -e "${RED}❌ File contains tabs, should use spaces${NC}"
        return 1
    fi
    
    # Check for very long lines
    local long_lines=$(awk 'length > 150 {print NR ": " $0}' "$file")
    if [ -n "$long_lines" ]; then
        echo -e "${YELLOW}⚠️  Long lines found (>150 chars):${NC}"
        echo "$long_lines"
    fi
    
    # Check for unpinned actions
    local unpinned=$(grep -E "uses:.*@(main|master|latest)" "$file" || true)
    if [ -n "$unpinned" ]; then
        echo -e "${YELLOW}⚠️  Unpinned actions found (consider using specific versions):${NC}"
        echo "$unpinned"
    fi
    
    # Check for common typos
    if grep -iE "uses.*@(mian|mater)" "$file" > /dev/null; then
        echo -e "${RED}❌ Typos found in action versions${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ No critical issues found${NC}"
}

# Main validation loop
error_count=0
file_count=0

for file in .github/workflows/*.yml .github/workflows/*.yaml; do
    if [ -f "$file" ]; then
        echo ""
        echo "📄 Processing $file"
        echo "----------------------------------------"
        
        file_count=$((file_count + 1))
        
        # Run all checks
        if ! validate_yaml "$file"; then
            error_count=$((error_count + 1))
            continue
        fi
        
        if ! check_workflow_structure "$file"; then
            error_count=$((error_count + 1))
            continue
        fi
        
        if ! check_common_issues "$file"; then
            error_count=$((error_count + 1))
            continue
        fi
        
        echo -e "${GREEN}✅ $file passed all checks${NC}"
    fi
done

echo ""
echo "========================================="
echo "📊 Validation Summary"
echo "========================================="
echo "Files processed: $file_count"
echo "Errors found: $error_count"

if [ $error_count -eq 0 ]; then
    echo -e "${GREEN}🎉 All workflow files are valid!${NC}"
    exit 0
else
    echo -e "${RED}❌ $error_count workflow file(s) have issues${NC}"
    exit 1
fi