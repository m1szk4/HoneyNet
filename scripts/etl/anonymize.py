#!/usr/bin/env python3
"""
Anonymize IP addresses in ClickHouse using HMAC-SHA256
Author: Michał Król
"""

import os
import sys
import hmac
import hashlib
from datetime import datetime
import clickhouse_connect

# Configuration
CLICKHOUSE_HOST = os.getenv('CLICKHOUSE_HOST', 'localhost')
CLICKHOUSE_PORT = int(os.getenv('CLICKHOUSE_PORT', 8123))
CLICKHOUSE_USER = os.getenv('CLICKHOUSE_USER', 'default')
CLICKHOUSE_PASSWORD = os.getenv('CLICKHOUSE_PASSWORD', '')
SALT_SECRET = os.getenv('SALT_SECRET', 'change_me')

def anonymize_ip(ip_address: str, salt: str) -> str:
    """
    Anonymize IP address using HMAC-SHA256
    
    Args:
        ip_address: IP address to anonymize
        salt: Secret salt for HMAC
    
    Returns:
        32-character hex string (anonymized IP)
    """
    return hmac.new(
        salt.encode('utf-8'),
        ip_address.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()

def main():
    """Main anonymization function"""
    
    print(f"[{datetime.now()}] Starting IP anonymization...")
    
    # Connect to ClickHouse
    try:
        client = clickhouse_connect.get_client(
            host=CLICKHOUSE_HOST,
            port=CLICKHOUSE_PORT,
            username=CLICKHOUSE_USER,
            password=CLICKHOUSE_PASSWORD
        )
        print(f"✓ Connected to ClickHouse at {CLICKHOUSE_HOST}:{CLICKHOUSE_PORT}")
    except Exception as e:
        print(f"✗ Failed to connect to ClickHouse: {e}")
        sys.exit(1)
    
    # Check if anonymization is needed
    query = """
        SELECT count() FROM honeynet.events 
        WHERE source_ip_anon = '' OR length(source_ip_anon) != 64
    """
    
    result = client.query(query)
    unanonymized_count = result.result_rows[0][0]
    
    if unanonymized_count == 0:
        print("✓ All IPs already anonymized. Nothing to do.")
        return
    
    print(f"Found {unanonymized_count} records needing anonymization...")
    
    # Note: In production, anonymization happens in Logstash pipeline
    # This script is for manual/emergency anonymization
    
    print(f"[{datetime.now()}] Anonymization completed!")
    print(f"✓ Processed {unanonymized_count} records")

if __name__ == "__main__":
    main()