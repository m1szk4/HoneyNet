#!/bin/bash
# Master deployment script
# Author: Michał Król

set -e

HONEYNET_DIR="/opt/iot-honeynet"
LOG_FILE="/var/log/honeynet-deploy.log"

echo "========================================"
echo "  IoT Honeynet - Deployment Script"
echo "========================================"
echo ""

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log "ERROR: Please run as root"
    exit 1
fi

# Check prerequisites
log "Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    log "ERROR: Docker not installed"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    log "ERROR: Docker Compose not installed"
    exit 1
fi

log "✓ Prerequisites OK"

# Create directory structure
log "Creating directory structure..."
mkdir -p $HONEYNET_DIR/{configs,data,scripts,logs,backups}
cd $HONEYNET_DIR

# Pull images
log "Pulling Docker images..."
docker-compose pull

# Start services
log "Starting services..."
docker-compose up -d

# Wait for services to be healthy
log "Waiting for services to start..."
sleep 30

# Health check
log "Running health check..."
if ./scripts/monitoring/health_check.sh; then
    log "✓ Health check passed"
else
    log "✗ Health check failed"
    exit 1
fi

# Run isolation test
log "Testing network isolation (CRITICAL!)..."
if python3 tests/test_isolation.py; then
    log "✓ Network isolation OK"
else
    log "✗ Network isolation FAILED - STOPPING DEPLOYMENT"
    docker-compose down
    exit 1
fi

# Record production start
date > $HONEYNET_DIR/PRODUCTION_START_DATE
log "✓ Production start date recorded"

# Setup cron jobs
log "Setting up cron jobs..."
(crontab -l 2>/dev/null; echo "0 8 * * * $HONEYNET_DIR/scripts/monitoring/daily_report.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 2 * * 0 $HONEYNET_DIR/scripts/deployment/backup.sh") | crontab -

log "✓ Cron jobs configured"

# Final summary
log ""
log "========================================"
log "  DEPLOYMENT COMPLETED SUCCESSFULLY"
log "========================================"
log ""
log "Grafana: http://$(hostname -I | awk '{print $1}'):3000"
log "  Username: admin"
log "  Password: (check .env file)"
log ""
log "ClickHouse: http://$(hostname -I | awk '{print $1}'):8123"
log ""
log "Data collection period: $(cat PRODUCTION_START_DATE) - $(date -d '+60 days' '+%Y-%m-%d')"
log ""
log "Next steps:"
log "  1. Monitor dashboards in Grafana"
log "  2. Check daily reports"
log "  3. Review logs: docker-compose logs -f"
log "========================================"