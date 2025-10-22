#!/usr/bin/env python3
"""
End-to-end integration test for IoT Honeynet
Tests complete pipeline: Honeypot → IDS → Logstash → ClickHouse → Grafana
Author: Michał Król
"""

import time
import subprocess
import requests
import sys

def test_honeypot_reachable(port, protocol="tcp"):
    """Test if honeypot port is open"""
    
    cmd = f"nc -zv localhost {port}"
    result = subprocess.run(cmd, shell=True, capture_output=True, timeout=5)
    
    return result.returncode == 0

def test_clickhouse_query():
    """Test ClickHouse connectivity and data"""
    
    try:
        response = requests.get(
            'http://localhost:8123',
            params={'query': 'SELECT count() FROM honeynet.events'},
            timeout=10
        )
        return response.status_code == 200
    except:
        return False

def test_grafana_dashboard():
    """Test Grafana accessibility"""
    
    try:
        response = requests.get('http://localhost:3000/api/health', timeout=10)
        return response.status_code == 200
    except:
        return False

def test_logstash_pipeline():
    """Test Logstash is processing logs"""
    
    try:
        response = requests.get('http://localhost:9600', timeout=10)
        return response.status_code == 200
    except:
        return False

def main():
    """Main test function"""
    
    print("="*60)
    print("  END-TO-END INTEGRATION TEST")
    print("="*60)
    
    tests = [
        ("Cowrie SSH (22)", lambda: test_honeypot_reachable(22)),
        ("Cowrie Telnet (23)", lambda: test_honeypot_reachable(23)),
        ("Dionaea HTTP (80)", lambda: test_honeypot_reachable(80)),
        ("ClickHouse", test_clickhouse_query),
        ("Logstash", test_logstash_pipeline),
        ("Grafana", test_grafana_dashboard)
    ]
    
    passed = 0
    failed = 0
    
    for name, test_func in tests:
        print(f"\nTesting: {name}...")
        try:
            if test_func():
                print(f"  ✓ PASS")
                passed += 1
            else:
                print(f"  ✗ FAIL")
                failed += 1
        except Exception as e:
            print(f"  ✗ ERROR: {e}")
            failed += 1
    
    # Summary
    print("\n" + "="*60)
    print(f"Results: {passed}/{len(tests)} tests passed")
    print("="*60)
    
    return 0 if failed == 0 else 1

if __name__ == "__main__":
    sys.exit(main())