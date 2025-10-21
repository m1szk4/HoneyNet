#!/bin/bash
# Test network isolation of honeypot containers

set -e

echo "==================================="
echo "Honeynet Network Isolation Test"
echo "==================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

# Test 1: Outbound should be blocked
echo ""
echo "Test 1: Outbound connectivity should be BLOCKED"
docker exec cowrie ping -c 3 -W 2 8.8.8.8 2>&1 | grep -q "100% packet loss"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PASSED${NC}: Outbound blocked from Cowrie"
    ((PASS++))
else
    echo -e "${RED}✗ FAILED${NC}: Outbound NOT blocked! Security risk!"
    ((FAIL++))
fi

# Test 2: Inbound should work
echo ""
echo "Test 2: Inbound connectivity should WORK"
timeout 5 nc -zv localhost 23 2>&1 | grep -q "succeeded"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PASSED${NC}: Inbound to Telnet working"
    ((PASS++))
else
    echo -e "${RED}✗ FAILED${NC}: Inbound not working"
    ((FAIL++))
fi

# Test 3: Containers can't reach each other (optional)
echo ""
echo "Test 3: Inter-container isolation (honeypots)"
docker exec cowrie ping -c 2 -W 2 172.20.0.11 2>&1 | grep -q "100% packet loss"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PASSED${NC}: Honeypots isolated from each other"
    ((PASS++))
else
    echo "⚠ WARNING: Honeypots can communicate (may be intentional)"
fi

# Summary
echo ""
echo "==================================="
echo "Test Results: ${GREEN}${PASS} passed${NC}, ${RED}${FAIL} failed${NC}"
echo "==================================="

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}CRITICAL FAILURES DETECTED!${NC}"
    echo "DO NOT run honeypot in production until issues are resolved!"
    exit 1
else
    echo -e "${GREEN}All critical tests passed!${NC}"
    echo "Honeypot is ready for deployment."
    exit 0
fi