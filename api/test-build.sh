#!/bin/bash
# filepath: docker-react-nginx/api/test-build.sh

echo "=== Testing Alpine Build ==="
docker build -t api-test . 2>&1 | tee build.log

echo -e "\n=== Checking for Build Errors ==="
if grep -q "gyp ERR!" build.log; then
    echo "⚠️  Native module build errors detected - may need non-Alpine image"
fi

echo -e "\n=== Checking Package Dependencies ==="
NATIVE_DEPS=("bcrypt" "node-sass" "sharp" "canvas")
for dep in "${NATIVE_DEPS[@]}"; do
    if grep -q "\"$dep\":" package.json; then
        echo "⚠️  Found native dependency: $dep"
    fi
done

echo -e "\n=== Verifying Node Requirements ==="
cat > diagnose.js << 'EOF'
console.log('Node version:', process.version);
console.log('Platform:', process.platform);
console.log('Architecture:', process.arch);
console.log('Available modules:', Object.keys(process.features).join(', '));
console.log('Memory:', process.memoryUsage());
EOF

echo "Testing in Alpine environment:"
docker run --rm api-test node diagnose.js

echo -e "\n=== Cleanup ==="
rm diagnose.js
rm build.log

echo -e "\n=== Summary ==="
echo "If you see any warnings above or missing features,"
echo "consider using the full Node.js image (Dockerfile.full)"

# remove the image
docker rmi api-test
