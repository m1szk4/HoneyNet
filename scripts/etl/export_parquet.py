#!/usr/bin/env python3
"""
Export anonymized data from ClickHouse to Parquet format
Author: Michał Król
"""

import os
import sys
from datetime import datetime, timedelta
import clickhouse_connect
import pyarrow as pa
import pyarrow.parquet as pq

# Configuration
CLICKHOUSE_HOST = os.getenv('CLICKHOUSE_HOST', 'localhost')
CLICKHOUSE_PORT = int(os.getenv('CLICKHOUSE_PORT', 8123))
CLICKHOUSE_PASSWORD = os.getenv('CLICKHOUSE_PASSWORD', '')
EXPORT_DIR = os.getenv('EXPORT_DIR', '/opt/iot-honeynet/data/exports')

def export_to_parquet(client, table_name: str, date_from: str, date_to: str):
    """
    Export ClickHouse table to Parquet format
    
    Args:
        client: ClickHouse client
        table_name: Table to export
        date_from: Start date (YYYY-MM-DD)
        date_to: End date (YYYY-MM-DD)
    """
    
    print(f"\n[{datetime.now()}] Exporting {table_name}...")
    
    query = f"""
        SELECT 
            timestamp,
            event_type,
            honeypot_name,
            source_ip_anon,
            source_port,
            dest_port,
            protocol,
            country_code,
            asn,
            attack_technique,
            attack_tactic,
            severity,
            session_id,
            duration,
            payload,
            username,
            url,
            http_method
        FROM honeynet.{table_name}
        WHERE toDate(timestamp) >= '{date_from}'
          AND toDate(timestamp) <= '{date_to}'
        ORDER BY timestamp
    """
    
    # Execute query
    result = client.query(query)
    
    if len(result.result_rows) == 0:
        print(f"  ⚠ No data found for {table_name}")
        return
    
    # Convert to PyArrow Table
    columns = result.column_names
    data = {col: [] for col in columns}
    
    for row in result.result_rows:
        for i, col in enumerate(columns):
            data[col].append(row[i])
    
    table = pa.table(data)
    
    # Write to Parquet with compression
    output_file = os.path.join(
        EXPORT_DIR,
        f"{table_name}_{date_from}_to_{date_to}.parquet"
    )
    
    pq.write_table(
        table,
        output_file,
        compression='ZSTD',
        compression_level=9
    )
    
    file_size = os.path.getsize(output_file) / (1024 * 1024)  # MB
    print(f"  ✓ Exported {len(result.result_rows)} rows to {output_file}")
    print(f"  ✓ File size: {file_size:.2f} MB")

def main():
    """Main export function"""
    
    # Parse command line arguments
    if len(sys.argv) < 2:
        print("Usage: python3 export_parquet.py <date_from> [date_to]")
        print("Example: python3 export_parquet.py 2025-11-01 2025-12-31")
        sys.exit(1)
    
    date_from = sys.argv[1]
    date_to = sys.argv[2] if len(sys.argv) > 2 else datetime.now().strftime('%Y-%m-%d')
    
    print(f"[{datetime.now()}] Starting export...")
    print(f"Date range: {date_from} to {date_to}")
    
    # Create export directory
    os.makedirs(EXPORT_DIR, exist_ok=True)
    
    # Connect to ClickHouse
    try:
        client = clickhouse_connect.get_client(
            host=CLICKHOUSE_HOST,
            port=CLICKHOUSE_PORT,
            username='default',
            password=CLICKHOUSE_PASSWORD
        )
        print(f"✓ Connected to ClickHouse")
    except Exception as e:
        print(f"✗ Failed to connect: {e}")
        sys.exit(1)
    
    # Export tables
    tables = ['events', 'ssh_events', 'http_events', 'ids_alerts']
    
    for table in tables:
        try:
            export_to_parquet(client, table, date_from, date_to)
        except Exception as e:
            print(f"  ✗ Error exporting {table}: {e}")
    
    print(f"\n[{datetime.now()}] Export completed!")
    print(f"✓ Files saved to: {EXPORT_DIR}")

if __name__ == "__main__":
    main()