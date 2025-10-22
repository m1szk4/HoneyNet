#!/bin/bash
# Daily statistics report
# Author: Michał Król

REPORT_FILE="/tmp/honeynet-daily-report-$(date +%Y%m%d).txt"

cat > $REPORT_FILE << EOF
========================================
IoT Honeynet - Daily Report
Date: $(date +%Y-%m-%d)
========================================

SYSTEM STATUS
----------------------------------------
$(docker-compose ps 2>/dev/null || echo "Error getting container status")

DISK USAGE
----------------------------------------
$(df -h /opt/iot-honeynet)

CLICKHOUSE STATISTICS (Last 24h)
----------------------------------------
EOF

# Get stats from ClickHouse
docker exec clickhouse clickhouse-client --query="
SELECT
    'Total Events' AS metric,
    formatReadableQuantity(count()) AS value
FROM honeynet.events
WHERE timestamp >= now() - INTERVAL 1 DAY
UNION ALL
SELECT
    'Unique Source IPs',
    formatReadableQuantity(uniq(source_ip_anon))
FROM honeynet.events
WHERE timestamp >= now() - INTERVAL 1 DAY
UNION ALL
SELECT
    'Top Country',
    concat(country_code, ' (', toString(count()), ' attacks)')
FROM honeynet.events
WHERE timestamp >= now() - INTERVAL 1 DAY AND country_code != ''
GROUP BY country_code
ORDER BY count() DESC
LIMIT 1
FORMAT Pretty
" >> $REPORT_FILE 2>/dev/null || echo "Error querying ClickHouse" >> $REPORT_FILE

echo "" >> $REPORT_FILE
echo "========================================" >> $REPORT_FILE

# Display report
cat $REPORT_FILE

# Send via email if configured
if [ ! -z "$ALERT_EMAIL" ]; then
    mail -s "Honeynet Daily Report - $(date +%Y-%m-%d)" $ALERT_EMAIL < $REPORT_FILE
fi