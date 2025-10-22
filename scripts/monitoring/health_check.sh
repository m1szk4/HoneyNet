#!/bin/bash
# Health check script for IoT Honeynet
# Author: Michał Król

set -e

echo "========================================"
echo "  IoT Honeynet - Health Check"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Docker
echo -n "Docker daemon: "
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not running${NC}"
    exit 1
fi

# Check containers
echo ""
echo "Container Status:"
echo "----------------------------------------"

CONTAINERS=("cowrie" "dionaea" "conpot" "suricata" "zeek" "clickhouse" "logstash" "grafana")

for container in "${CONTAINERS[@]}"; do
    echo -n "  $container: "
    if docker ps --filter "name=$container" --filter "status=running" | grep -q $container; then
        echo -e "${GREEN}✓ Healthy${NC}"
    else
        echo -e "${RED}✗ Down${NC}"
    fi
done

# Check disk space
echo ""
echo -n "Disk space: "
DISK_USAGE=$(df -h /opt/iot-honeynet | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -lt 80 ]; then
    echo -e "${GREEN}✓ ${DISK_USAGE}% used${NC}"
elif [ "$DISK_USAGE" -lt 90 ]; then
    echo -e "${YELLOW}⚠ ${DISK_USAGE}% used (warning)${NC}"
else
    echo -e "${RED}✗ ${DISK_USAGE}% used (critical!)${NC}"
fi

# Check ClickHouse connectivity
echo ""
echo -n "ClickHouse database: "
if docker exec clickhouse clickhouse-client --query="SELECT 1" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Accessible${NC}"
    
    # Get row count
    ROW_COUNT=$(docker exec clickhouse clickhouse-client --query="SELECT count() FROM honeynet.events" 2>/dev/null || echo "0")
    echo "  Total events: $ROW_COUNT"
else
    echo -e "${RED}✗ Not accessible${NC}"
fi

# Check Grafana
echo ""
echo -n "Grafana dashboard: "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health | grep -q 200; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${RED}✗ Not accessible${NC}"
fi

# Check network isolation
echo ""
echo -n "Network isolation: "
if docker exec cowrie ping -c 1 -W 1 8.8.8.8 > /dev/null 2>&1; then
    echo -e "${RED}✗ BREACH! Outbound traffic possible${NC}"
    echo "  ⚠ WARNING: Honeypot can reach Internet - data control compromised!"
else
    echo -e "${GREEN}✓ Isolated (no outbound)${NC}"
fi

# Summary
echo ""
echo "========================================"
echo "Health check completed at $(date)"
echo "========================================"