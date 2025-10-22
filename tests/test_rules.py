#!/usr/bin/env python3
"""
Test Suricata IDS rules against known attack patterns
Author: Michał Król
"""

import subprocess
import sys
import json

def test_rule(rule_id, test_pcap):
    """Test a single Suricata rule"""
    
    cmd = f"suricata -c /etc/suricata/suricata.yaml -r {test_pcap} -l /tmp/suricata-test"
    
    try:
        subprocess.run(cmd, shell=True, check=True, capture_output=True)
        
        # Check if alert was generated
        with open('/tmp/suricata-test/fast.log', 'r') as f:
            logs = f.read()
            if str(rule_id) in logs:
                return True
    except Exception as e:
        print(f"Error testing rule {rule_id}: {e}")
    
    return False

def main():
    """Main test function"""
    
    print("="*60)
    print("  SURICATA RULES VALIDATION TEST")
    print("="*60)
    
    # Test cases: (rule_id, test_pcap, expected_alert)
    test_cases = [
        (5000001, "tests/fixtures/mirai_telnet.pcap", "Mirai credentials"),
        (5000010, "tests/fixtures/ssh_bruteforce.pcap", "SSH brute force"),
        (5000020, "tests/fixtures/shellshock.pcap", "ShellShock exploit")
    ]
    
    passed = 0
    failed = 0
    
    for rule_id, pcap, description in test_cases:
        print(f"\nTesting: {description} (SID: {rule_id})")
        print(f"  PCAP: {pcap}")
        
        if test_rule(rule_id, pcap):
            print(f"  ✓ PASS: Alert generated")
            passed += 1
        else:
            print(f"  ✗ FAIL: No alert generated")
            failed += 1
    
    # Summary
    print("\n" + "="*60)
    print(f"Results: {passed} passed, {failed} failed")
    print("="*60)
    
    return 0 if failed == 0 else 1

if __name__ == "__main__":
    sys.exit(main())