#!/bin/bash

echo "🔧 Fixing API route URLs for production deployment..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Find all route.js files in the API directory
find "$ROOT_DIR/edutube/src/app/api" -name "route.js" -type f | while read -r file; do
    echo "Processing: $file"
    
    # Replace hardcoded backend URLs with getBackendUrl() function
    sed -i 's|http://localhost:5001|${getBackendUrl()}|g' "$file"
    sed -i 's|http://backend:5001|${getBackendUrl()}|g' "$file"
    
    # Add import for getBackendUrl if not present and file uses backend URLs
    if grep -q "getBackendUrl()" "$file" && ! grep -q "getBackendUrl" "$file" | head -1; then
        # Add import after existing imports
        sed -i '/^import.*from/a import { getBackendUrl } from "@/utils/apiConfig";' "$file"
    fi
    
    # Replace environment variable usage with function call
    sed -i 's/process\.env\.BACKEND_URL || ['"'"'"][^'"'"'"]*['"'"'"]/getBackendUrl()/g' "$file"
    sed -i 's/const BACKEND_URL = .*/\/\/ Using getBackendUrl() from apiConfig/g' "$file"
done

echo "✅ API routes updated successfully!"
echo "📋 Summary of changes:"
echo "   - Replaced hardcoded URLs with getBackendUrl() function"
echo "   - Added proper imports where needed"
echo "   - Standardized backend URL configuration"
