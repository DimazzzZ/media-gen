#!/bin/bash

echo "🔍 Final YAML validation check..."
echo ""

all_passed=true

for file in .github/workflows/*.yml; do
    filename=$(basename "$file")
    echo -n "Checking $filename... "
    
    if yamllint -c .yamllint.yml "$file" >/dev/null 2>&1; then
        echo "✅"
    else
        echo "❌"
        all_passed=false
    fi
done

echo ""
if $all_passed; then
    echo "🎉 All YAML files pass yamllint validation!"
    echo "✅ Ready to commit!"
else
    echo "❌ Some files still have issues"
    echo "Run: yamllint -c .yamllint.yml .github/workflows/filename.yml"
fi