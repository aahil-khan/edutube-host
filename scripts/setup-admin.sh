#!/bin/bash

echo "🔐 Creating Default Admin User for EduTube"
echo "=========================================="
echo ""

# Run the admin setup script
if docker compose version &>/dev/null; then
	DC="docker compose"
else
	DC="docker-compose"
fi

$DC exec backend node scripts/setupDefaultAdmin.js

echo ""
echo "✅ Admin setup completed!"
echo ""
echo "🔑 Login credentials:"
echo "   URL: http://localhost:4000"
echo "   Email: admin@gmail.com"
echo "   Password: aahil"
echo ""
echo "⚠️  SECURITY: Please change the password after first login!"
