#!/usr/bin/env python3
"""
Generate comprehensive statistics from collected data
Author: Michał Król
"""

import os
import sys
from datetime import datetime
import clickhouse_connect
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# Configuration
CLICKHOUSE_HOST = os.getenv('CLICKHOUSE_HOST', 'localhost')
CLICKHOUSE_PORT = int(os.getenv('CLICKHOUSE_PORT', 8123))
CLICKHOUSE_PASSWORD = os.getenv('CLICKHOUSE_PASSWORD', '')
OUTPUT_DIR = '/opt/iot-honeynet/data/analysis'

def get_client():
    """Connect to ClickHouse"""
    return clickhouse_connect.get_client(
        host=CLICKHOUSE_HOST,
        port=CLICKHOUSE_PORT,
        username='default',
        password=CLICKHOUSE_PASSWORD
    )

def generate_overview_stats(client):
    """Generate overview statistics"""
    
    print("\n" + "="*50)
    print("OVERVIEW STATISTICS")
    print("="*50)
    
    queries = {
        "Total Events": "SELECT count() FROM honeynet.events",
        "Unique Source IPs": "SELECT uniq(source_ip_anon) FROM honeynet.events",
        "Date Range": "SELECT min(toDate(timestamp)), max(toDate(timestamp)) FROM honeynet.events",
        "Total Data Size": "SELECT formatReadableSize(sum(total_bytes)) FROM system.tables WHERE database='honeynet'"
    }
    
    for name, query in queries.items():
        result = client.query(query)
        print(f"{name}: {result.result_rows[0]}")

def generate_protocol_stats(client):
    """Protocol distribution"""
    
    print("\n" + "="*50)
    print("PROTOCOL DISTRIBUTION")
    print("="*50)
    
    query = """
        SELECT protocol, count() as cnt 
        FROM honeynet.events 
        GROUP BY protocol 
        ORDER BY cnt DESC
    """
    
    result = client.query(query)
    df = pd.DataFrame(result.result_rows, columns=['Protocol', 'Count'])
    print(df.to_string(index=False))
    
    # Save plot
    plt.figure(figsize=(10, 6))
    plt.bar(df['Protocol'], df['Count'])
    plt.title('Attack Distribution by Protocol')
    plt.xlabel('Protocol')
    plt.ylabel('Number of Attacks')
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'protocol_distribution.png'))
    print(f"\n✓ Saved plot: {OUTPUT_DIR}/protocol_distribution.png")

def generate_geographic_stats(client):
    """Geographic distribution"""
    
    print("\n" + "="*50)
    print("TOP 20 COUNTRIES")
    print("="*50)
    
    query = """
        SELECT country_code, count() as attacks
        FROM honeynet.events
        WHERE country_code != ''
        GROUP BY country_code
        ORDER BY attacks DESC
        LIMIT 20
    """
    
    result = client.query(query)
    df = pd.DataFrame(result.result_rows, columns=['Country', 'Attacks'])
    print(df.to_string(index=False))

def generate_mitre_stats(client):
    """MITRE ATT&CK coverage"""
    
    print("\n" + "="*50)
    print("MITRE ATT&CK COVERAGE")
    print("="*50)
    
    query = """
        SELECT 
            attack_tactic,
            attack_technique,
            count() as occurrences
        FROM honeynet.events
        WHERE attack_technique != ''
        GROUP BY attack_tactic, attack_technique
        ORDER BY occurrences DESC
    """
    
    result = client.query(query)
    df = pd.DataFrame(result.result_rows, columns=['Tactic', 'Technique', 'Count'])
    print(df.to_string(index=False))
    
    print(f"\nTotal techniques observed: {df['Technique'].nunique()}")
    print(f"Total tactics observed: {df['Tactic'].nunique()}")

def main():
    """Main function"""
    
    print(f"[{datetime.now()}] Generating statistics...")
    
    # Create output directory
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # Connect to ClickHouse
    try:
        client = get_client()
        print(f"✓ Connected to ClickHouse")
    except Exception as e:
        print(f"✗ Failed to connect: {e}")
        sys.exit(1)
    
    # Generate statistics
    generate_overview_stats(client)
    generate_protocol_stats(client)
    generate_geographic_stats(client)
    generate_mitre_stats(client)
    
    print(f"\n[{datetime.now()}] Statistics generation completed!")

if __name__ == "__main__":
    main()