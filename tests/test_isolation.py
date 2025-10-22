#!/usr/bin/env python3
"""
Test network isolation of honeypot containers
CRITICAL: Honeypots must NOT be able to reach external networks
Author: Michał Król
"""

import subprocess
import sys

def run_command(cmd):
    """Execute shell command and return output"""
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=10
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "Timeout"

def test_outbound_blocked(container):
    """Test that container cannot reach Internet"""
    
    print(f"\nTesting {container}...")
    print(f"  → Attempting to ping 8.8.8.8 (should FAIL)...")
    
    cmd = f"docker exec {container} ping -c 1 -W 1 8.8.8.8"
    returncode, stdout, stderr = run_command(cmd)
    
    if returncode != 0:
        print(f"  ✓ PASS: {container} cannot reach Internet")
        return True
    else:
        print(f"  ✗ FAIL: {container} CAN reach Internet - BREACH!")
        print(f"     Output: {stdout}")
        return False

def test_dns_blocked(container):
    """Test that DNS is blocked"""
    
    print(f"  → Attempting DNS lookup (should FAIL)...")
    
    cmd = f"docker exec {container} nslookup google.com"
    returncode, stdout, stderr = run_command(cmd)
    
    if returncode != 0:
        print(f"  ✓ PASS: DNS blocked")
        return True
    else:
        print(f"  ✗ FAIL: DNS works - potential data leak")
        return False

def test_http_blocked(container):
    """Test that HTTP is blocked"""
    
    print(f"  → Attempting HTTP request (should FAIL)...")
    
    cmd = f"docker exec {container} curl -m 2 http://example.com"
    returncode, stdout, stderr = run_command(cmd)
    
    if returncode != 0:
        print(f"  ✓ PASS: HTTP blocked")
        return True
    else:
        print(f"  ✗ FAIL: HTTP works - C&C communication possible!")
        return False

def main():
    """Main test function"""
    
    print("="*60)
    print("  NETWORK ISOLATION TEST - CRITICAL SECURITY CHECK")
    print("="*60)
    print("\nThis test verifies that honeypot containers are isolated")
    print("from external networks to prevent:")
    print("  - Malware C&C communication")
    print("  - Data exfiltration")
    print("  - Participation in botnet attacks")
    print("\n" + "="*60)
    
    containers = ['cowrie', 'dionaea', 'conpot']
    all_passed = True
    
    for container in containers:
        # Check if container is running
        cmd = f"docker ps --filter name={container} --filter status=running --format '{{{{.Names}}}}'"
        returncode, stdout, stderr = run_command(cmd)
        
        if container not in stdout:
            print(f"\n⚠ WARNING: {container} is not running, skipping...")
            continue
        
        # Run tests
        test_results = [
            test_outbound_blocked(container),
            test_dns_blocked(container),
            test_http_blocked(container)
        ]
        
        if not all(test_results):
            all_passed = False
    
    # Summary
    print("\n" + "="*60)
    if all_passed:
        print("  ✓ ALL TESTS PASSED - NETWORK ISOLATION OK")
        print("="*60)
        return 0
    else:
        print("  ✗ TESTS FAILED - SECURITY BREACH DETECTED!")
        print("  ⚠ DO NOT RUN HONEYNET IN PRODUCTION")
        print("="*60)
        return 1

if __name__ == "__main__":
    sys.exit(main())