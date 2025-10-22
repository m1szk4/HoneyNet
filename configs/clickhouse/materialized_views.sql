-- =====================================================
-- Materialized Views for Performance Optimization
-- Pre-aggregated queries for Grafana dashboards
-- =====================================================

-- =====================================================
-- Daily Statistics View
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS honeynet.events_daily
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (date, dest_port, country_code)
AS SELECT
    toDate(timestamp) AS date,
    dest_port,
    country_code,
    protocol,
    attack_tactic,
    count() AS event_count,
    uniq(source_ip_anon) AS unique_sources,
    sum(payload_size) AS total_payload_size
FROM honeynet.events
GROUP BY date, dest_port, country_code, protocol, attack_tactic;

-- =====================================================
-- Hourly Statistics View (for real-time dashboard)
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS honeynet.events_hourly
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(hour)
ORDER BY (hour, dest_port)
AS SELECT
    toStartOfHour(timestamp) AS hour,
    dest_port,
    protocol,
    honeypot_name,
    count() AS event_count,
    uniq(source_ip_anon) AS unique_sources
FROM honeynet.events
GROUP BY hour, dest_port, protocol, honeypot_name;

-- =====================================================
-- Top Attackers View
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS honeynet.top_attackers
ENGINE = AggregatingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (date, source_ip_anon)
AS SELECT
    toDate(timestamp) AS date,
    source_ip_anon,
    country_code,
    asn,
    countState() AS attack_count,
    uniqState(dest_port) AS unique_ports_targeted,
    uniqState(attack_technique) AS unique_techniques_used
FROM honeynet.events
GROUP BY date, source_ip_anon, country_code, asn;

-- =====================================================
-- MITRE ATT&CK Coverage View
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS honeynet.mitre_coverage
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (date, attack_tactic, attack_technique)
AS SELECT
    toDate(timestamp) AS date,
    attack_tactic,
    attack_technique,
    count() AS occurrence_count,
    uniq(source_ip_anon) AS unique_sources,
    avg(severity) AS avg_severity
FROM honeynet.events
WHERE attack_technique != ''
GROUP BY date, attack_tactic, attack_technique;

-- =====================================================
-- Brute Force Statistics View
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS honeynet.bruteforce_stats
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (date, dest_port, username)
AS SELECT
    toDate(timestamp) AS date,
    dest_port,
    username,
    count() AS attempt_count,
    uniq(source_ip_anon) AS unique_sources,
    countIf(password_hash != '') AS password_attempts
FROM honeynet.ssh_events
WHERE event_type = 'login'
GROUP BY date, dest_port, username;

-- =====================================================
-- Exploit Attempts View
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS honeynet.exploit_attempts
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (date, attack_technique)
AS SELECT
    toDate(timestamp) AS date,
    attack_technique,
    dest_port,
    protocol,
    count() AS exploit_count,
    uniq(source_ip_anon) AS unique_sources,
    uniq(payload) AS unique_payloads
FROM honeynet.events
WHERE is_exploit = 1
GROUP BY date, attack_technique, dest_port, protocol;

-- =====================================================
-- Geographic Distribution View
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS honeynet.geo_distribution
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (date, country_code)
AS SELECT
    toDate(timestamp) AS date,
    country_code,
    count() AS attack_count,
    uniq(source_ip_anon) AS unique_ips,
    uniq(dest_port) AS ports_targeted,
    avg(severity) AS avg_severity
FROM honeynet.events
WHERE country_code != ''
GROUP BY date, country_code;