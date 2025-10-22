-- =====================================================
-- ClickHouse Schema for IoT Honeynet
-- Database: honeynet
-- Author: Michał Król
-- =====================================================

CREATE DATABASE IF NOT EXISTS honeynet;

-- =====================================================
-- Main Events Table
-- Stores all honeypot events with optimized compression
-- =====================================================

CREATE TABLE IF NOT EXISTS honeynet.events (
    -- Timestamp
    timestamp DateTime64(3) CODEC(DoubleDelta, ZSTD(3)),
    event_date Date MATERIALIZED toDate(timestamp),
    
    -- Event metadata
    event_id UUID DEFAULT generateUUIDv4(),
    event_type LowCardinality(String),
    honeypot_name LowCardinality(String),
    
    -- Network identifiers (anonymized)
    source_ip_anon FixedString(32) CODEC(ZSTD(3)),  -- HMAC-SHA256 hash
    source_port UInt16,
    dest_ip IPv4,
    dest_port UInt16,
    protocol LowCardinality(String),
    
    -- Geographic data
    country_code FixedString(2) DEFAULT '',
    asn UInt32 DEFAULT 0,
    
    -- Attack classification
    attack_technique LowCardinality(String) DEFAULT '',  -- MITRE ATT&CK ID
    attack_tactic LowCardinality(String) DEFAULT '',
    severity Enum8('info'=1, 'low'=2, 'medium'=3, 'high'=4, 'critical'=5) DEFAULT 'info',
    
    -- Session metadata
    session_id String DEFAULT '' CODEC(ZSTD(3)),
    duration UInt32 DEFAULT 0,  -- Session duration in seconds
    
    -- Payload and metadata
    payload String CODEC(ZSTD(3)),  -- Command, HTTP request, etc.
    payload_size UInt32 DEFAULT 0,
    user_agent String DEFAULT '' CODEC(ZSTD(3)),
    
    -- Additional fields
    username String DEFAULT '' CODEC(ZSTD(3)),
    password_hash String DEFAULT '' CODEC(ZSTD(3)),  -- Hashed for privacy
    url String DEFAULT '' CODEC(ZSTD(3)),
    http_method LowCardinality(String) DEFAULT '',
    
    -- File downloads
    file_hash String DEFAULT '' CODEC(ZSTD(3)),  -- MD5/SHA256
    file_size UInt32 DEFAULT 0,
    
    -- Flags
    is_malicious UInt8 DEFAULT 1,  -- Honeypot assumes all traffic is malicious
    is_bruteforce UInt8 DEFAULT 0,
    is_exploit UInt8 DEFAULT 0,
    
    -- Metadata
    metadata String DEFAULT '{}' CODEC(ZSTD(3))  -- JSON for flexible fields

) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, dest_port, source_ip_anon)
TTL timestamp + INTERVAL 90 DAY  -- Auto-delete after 90 days
SETTINGS index_granularity = 8192;

-- =====================================================
-- SSH Events Table (detailed SSH logs from Cowrie)
-- =====================================================

CREATE TABLE IF NOT EXISTS honeynet.ssh_events (
    timestamp DateTime64(3) CODEC(DoubleDelta, ZSTD(3)),
    event_date Date MATERIALIZED toDate(timestamp),
    
    source_ip_anon FixedString(32) CODEC(ZSTD(3)),
    session_id String CODEC(ZSTD(3)),
    
    event_type LowCardinality(String),  -- login, command, download
    username String CODEC(ZSTD(3)),
    password_hash String CODEC(ZSTD(3)),
    
    command String DEFAULT '' CODEC(ZSTD(3)),
    success UInt8 DEFAULT 0,
    
    country_code FixedString(2) DEFAULT '',
    
    metadata String DEFAULT '{}' CODEC(ZSTD(3))

) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, source_ip_anon)
TTL timestamp + INTERVAL 90 DAY
SETTINGS index_granularity = 8192;

-- =====================================================
-- HTTP Events Table (HTTP requests from Dionaea)
-- =====================================================

CREATE TABLE IF NOT EXISTS honeynet.http_events (
    timestamp DateTime64(3) CODEC(DoubleDelta, ZSTD(3)),
    event_date Date MATERIALIZED toDate(timestamp),
    
    source_ip_anon FixedString(32) CODEC(ZSTD(3)),
    
    method LowCardinality(String),
    url String CODEC(ZSTD(3)),
    user_agent String CODEC(ZSTD(3)),
    referer String DEFAULT '' CODEC(ZSTD(3)),
    
    status_code UInt16,
    response_size UInt32,
    
    country_code FixedString(2) DEFAULT '',
    
    -- Flags
    is_exploit UInt8 DEFAULT 0,
    exploit_type LowCardinality(String) DEFAULT '',
    
    payload String DEFAULT '' CODEC(ZSTD(3))

) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, source_ip_anon, method)
TTL timestamp + INTERVAL 90 DAY
SETTINGS index_granularity = 8192;

-- =====================================================
-- IDS Alerts Table (Suricata alerts)
-- =====================================================

CREATE TABLE IF NOT EXISTS honeynet.ids_alerts (
    timestamp DateTime64(3) CODEC(DoubleDelta, ZSTD(3)),
    event_date Date MATERIALIZED toDate(timestamp),
    
    source_ip_anon FixedString(32) CODEC(ZSTD(3)),
    source_port UInt16,
    dest_ip IPv4,
    dest_port UInt16,
    protocol LowCardinality(String),
    
    alert_signature String CODEC(ZSTD(3)),
    alert_category LowCardinality(String),
    alert_severity UInt8,
    
    signature_id UInt32,
    revision UInt16,
    
    mitre_technique LowCardinality(String) DEFAULT '',
    mitre_tactic LowCardinality(String) DEFAULT '',
    
    payload String DEFAULT '' CODEC(ZSTD(3)),
    
    country_code FixedString(2) DEFAULT ''

) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, alert_category, signature_id)
TTL timestamp + INTERVAL 90 DAY
SETTINGS index_granularity = 8192;

-- =====================================================
-- Downloaded Files Table (malware samples)
-- =====================================================

CREATE TABLE IF NOT EXISTS honeynet.downloaded_files (
    timestamp DateTime64(3) CODEC(DoubleDelta, ZSTD(3)),
    event_date Date MATERIALIZED toDate(timestamp),
    
    source_ip_anon FixedString(32) CODEC(ZSTD(3)),
    
    file_hash String CODEC(ZSTD(3)),  -- SHA256
    file_size UInt32,
    file_type LowCardinality(String) DEFAULT '',
    
    download_url String CODEC(ZSTD(3)),
    honeypot_name LowCardinality(String),
    
    country_code FixedString(2) DEFAULT ''

) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, file_hash)
TTL timestamp + INTERVAL 90 DAY
SETTINGS index_granularity = 8192;

-- =====================================================
-- Indexes for Performance
-- =====================================================

-- Index for IP lookups
ALTER TABLE honeynet.events ADD INDEX idx_source_ip source_ip_anon TYPE bloom_filter GRANULARITY 1;

-- Index for port lookups
ALTER TABLE honeynet.events ADD INDEX idx_dest_port dest_port TYPE set(100) GRANULARITY 1;

-- Index for MITRE ATT&CK techniques
ALTER TABLE honeynet.events ADD INDEX idx_technique attack_technique TYPE set(50) GRANULARITY 1;

-- Index for severity
ALTER TABLE honeynet.events ADD INDEX idx_severity severity TYPE set(10) GRANULARITY 1;