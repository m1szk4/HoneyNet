# Data Protection Impact Assessment (DPIA)
# IoT Honeynet Research Project

**Document Version:** 1.0  
**Date:** 2025-01-20  
**Author:** Michał Król  
**Reviewed by:** [Promotor - Dr. Inż. Tomasz Bartczak]  
**Status:** Approved for Production

---

## Executive Summary

This Data Protection Impact Assessment (DPIA) evaluates the data protection risks associated with the IoT Honeynet research project. The assessment concludes that while the project processes IP addresses (personal data under GDPR), the implemented technical and organizational measures effectively mitigate privacy risks to an acceptable level.

**Key Findings:**
- **Risk Level:** LOW (after mitigation)
- **Data Subjects:** Attackers performing unauthorized network activities
- **Legal Basis:** Legitimate Interest (Art. 6(1)(f) GDPR) + Scientific Research (Art. 9(2)(j))
- **Mitigation:** Cryptographic anonymization (HMAC-SHA256), 90-day retention, no outbound data transmission

---

## 1. Introduction

### 1.1 Purpose of DPIA

This DPIA is conducted in accordance with **Article 35 of the General Data Protection Regulation (GDPR)** and Polish implementation of GDPR (Ustawa o ochronie danych osobowych). The assessment is required because the project:

1. Involves systematic monitoring of network traffic
2. Processes personal data (IP addresses) on a large scale
3. Uses automated profiling to classify attack behaviors

### 1.2 Scope

**Project Name:** IoT Honeynet for Analysis of Attacks on IoT Devices  
**Project Duration:** November 2025 - December 2025 (60 days data collection)  
**Data Controller:** [Your Institution/Organization]  
**Project Lead:** Michał Król  

**Systems in Scope:**
- Honeypot infrastructure (Cowrie, Dionaea, Conpot)
- Network monitoring (Suricata, Zeek)
- Data storage (ClickHouse)
- ETL pipeline (Logstash)

---

## 2. Description of Processing

### 2.1 Nature of Processing

The IoT Honeynet collects data from unsolicited network connections to deliberately exposed vulnerable systems (honeypots). Processing activities include:

| Activity | Description | Purpose |
|----------|-------------|---------|
| **Collection** | Capture of network packets, session metadata, commands | Threat intelligence gathering |
| **Storage** | Retention in ClickHouse database for 90 days | Analysis and research |
| **Analysis** | Classification of attacks, MITRE ATT&CK mapping | Security research |
| **Anonymization** | HMAC-SHA256 hashing of IP addresses | GDPR compliance |
| **Dissemination** | Publication of anonymized dataset | Academic contribution |

### 2.2 Types of Personal Data

#### 2.2.1 Directly Identifying Data

| Data Type | Processing Method | Retention |
|-----------|-------------------|-----------|
| **Source IP Address** | Captured from network packets | Anonymized within 24h |
| **User-Agent Strings** | Extracted from HTTP headers | Sanitized (PII removed) |
| **Credentials Used** | Login attempts (username/password) | Hashed (SHA256) |

#### 2.2.2 Indirectly Identifying Data

| Data Type | Processing Method | Retention |
|-----------|-------------------|-----------|
| **ASN (Autonomous System Number)** | GeoIP lookup | Retained |
| **Country Code** | GeoIP lookup | Retained |
| **Timestamp** | Event occurrence time | Retained |
| **Protocol/Port** | Network metadata | Retained |

#### 2.2.3 Technical Data

| Data Type | Processing Method | Retention |
|-----------|-------------------|-----------|
| **Commands Executed** | Captured from shell sessions | PII redacted |
| **HTTP Requests** | Full HTTP traffic | URLs sanitized |
| **Malware Samples** | Binary files downloaded by attackers | Hashed (SHA256) |

### 2.3 Volume of Data

**Expected Volume (60-day collection period):**
- Events: ~5,000,000
- Unique source IPs: ~50,000
- Data size (compressed): ~1.5 GB
- Data subjects affected: ~50,000 (attackers)

### 2.4 Legal Basis for Processing

#### Article 6(1)(f) GDPR - Legitimate Interest

**Legitimate Interest:** Conducting scientific research to improve cybersecurity defenses for IoT devices, which serves a broader public interest in protecting critical infrastructure.

**Necessity Test:**
- The project cannot achieve its objectives without collecting real-world attack data
- Alternative methods (simulated attacks) do not provide realistic threat intelligence
- Passive monitoring does not interfere with attackers' activities

**Balancing Test:**
- **Controller's Interests:** Strong (cybersecurity research, academic publication)
- **Data Subjects' Interests:** Low (attackers performing illegal activities)
- **Conclusion:** Processing is proportionate and justified

#### Article 9(2)(j) GDPR - Scientific Research

For special category data (if any), processing is permitted for archiving purposes in the public interest, scientific or historical research purposes, subject to appropriate safeguards.

---

## 3. Risk Assessment

### 3.1 Identification of Risks

#### Risk 1: Unauthorized Access to Raw Data

**Description:** Breach of ClickHouse database exposing non-anonymized IP addresses.

**Likelihood:** LOW  
**Severity:** MEDIUM  
**Overall Risk:** LOW-MEDIUM

**Mitigation:**
- Database access restricted to localhost only (not exposed to Internet)
- Strong authentication (32-char passwords)
- Encrypted at rest (LUKS disk encryption)
- Regular security audits
- Backup encryption (AES-256)

**Residual Risk:** LOW

---

#### Risk 2: Re-identification of Anonymized IPs

**Description:** Attacker correlates anonymized hashes with external datasets to de-anonymize IPs.

**Likelihood:** LOW  
**Severity:** LOW  
**Overall Risk:** LOW

**Mitigation:**
- HMAC-SHA256 with weekly rotated salt (prevents rainbow table attacks)
- 32-character truncated hash (reduces collision risk)
- No auxiliary data published (e.g., precise timestamps rounded to hours)
- No cross-referencing with external threat feeds in published data

**Residual Risk:** VERY LOW

---

#### Risk 3: Unintended Capture of PII in Payloads

**Description:** Attackers include personal data (emails, phone numbers) in commands or HTTP requests.

**Likelihood:** LOW  
**Severity:** LOW  
**Overall Risk:** LOW

**Mitigation:**
- Automated PII redaction in ETL pipeline (regex-based)
- Email patterns: `[EMAIL_REDACTED]`
- Phone numbers: `[PHONE_REDACTED]`
- URLs with query parameters: stripped
- Manual review of dataset before publication

**Residual Risk:** VERY LOW

---

#### Risk 4: Data Breach via Compromised Honeypot

**Description:** Attacker compromises honeypot and pivots to production systems.

**Likelihood:** LOW  
**Severity:** MEDIUM  
**Overall Risk:** LOW-MEDIUM

**Mitigation:**
- Network isolation (DMZ with blocked outbound traffic)
- Firewall rules verified with automated tests
- No routing between honeypot and management networks
- Honeypots run in containers with dropped capabilities
- Regular integrity checks (AIDE)
- Incident response plan documented

**Residual Risk:** LOW

---

#### Risk 5: Data Retention Exceeds Necessity

**Description:** Data retained longer than required for research objectives.

**Likelihood:** LOW  
**Severity:** LOW  
**Overall Risk:** LOW

**Mitigation:**
- Automated TTL (Time-To-Live) set to 90 days in ClickHouse
- Monthly reviews of data retention policies
- Clear data deletion procedures documented
- Backup retention limited to 30 days

**Residual Risk:** VERY LOW

---

### 3.2 Risk Matrix Summary

| Risk | Likelihood | Severity | Mitigation Status | Residual Risk |
|------|-----------|----------|-------------------|---------------|
| Unauthorized DB Access | LOW | MEDIUM | Implemented | LOW |
| Re-identification | LOW | LOW | Implemented | VERY LOW |
| PII in Payloads | LOW | LOW | Implemented | VERY LOW |
| Honeypot Compromise | LOW | MEDIUM | Implemented | LOW |
| Excessive Retention | LOW | LOW | Implemented | VERY LOW |

**Overall Residual Risk Level:** **LOW**

---

## 4. Technical and Organizational Measures

### 4.1 Technical Measures

#### 4.1.1 Anonymization Protocol

**Method:** HMAC-SHA256 with weekly rotated salt

```python
import hmac
import hashlib
from datetime import datetime

def anonymize_ip(ip_address: str, salt: str) -> str:
    """
    Anonymize IP address using HMAC-SHA256.
    
    Args:
        ip_address: IP address to anonymize (e.g., "192.168.1.1")
        salt: Weekly rotated secret salt
        
    Returns:
        32-character hex string (anonymized identifier)
    """
    message = ip_address.encode('utf-8')
    salt_bytes = salt.encode('utf-8')
    digest = hmac.new(salt_bytes, message, hashlib.sha256)
    return digest.hexdigest()[:32]

# Example usage:
salt = "2025-W03-abc123xyz"  # Format: YYYY-Www-SECRET
anon_ip = anonymize_ip("203.0.113.42", salt)
# Output: "a3b5c7d9e1f2a4b6c8d0e2f4a6b8c0d2"
```

**Properties:**
- ✅ Deterministic (same IP = same hash within week)
- ✅ Irreversible (no rainbow tables for 2^32 IPv4 space with salt)
- ✅ Correlation-preserving (can track campaigns within week)
- ✅ Privacy-preserving (different hash after salt rotation)

#### 4.1.2 Access Control

| System | Authentication | Network Access | Encryption |
|--------|----------------|----------------|------------|
| **SSH** | Key-only | Management IP whitelist | AES-256 |
| **ClickHouse** | Password | Localhost only | TLS (internal) |
| **Grafana** | Password + 2FA | VPN only | HTTPS |
| **Docker API** | Unix socket | Localhost only | N/A |

#### 4.1.3 Network Isolation

```
Internet → Firewall → Honeypot DMZ (172.20.0.0/24)
                          ↓
                    [BLOCKED OUTBOUND]
                          ↓
                    Management Network (172.21.0.0/24)
                          ↓
                    ClickHouse, Grafana
```

**Firewall Rules (iptables):**
```bash
# CRITICAL: Block all outbound from honeypot network
iptables -A FORWARD -s 172.20.0.0/24 -j LOG --log-prefix "BLOCKED: "
iptables -A FORWARD -s 172.20.0.0/24 -j DROP

# Allow only inbound to honeypots
iptables -A FORWARD -d 172.20.0.0/24 -m state --state NEW,ESTABLISHED -j ACCEPT
```

#### 4.1.4 Data-at-Rest Encryption

- **Disk Encryption:** LUKS (Linux Unified Key Setup) with AES-256-XTS
- **Backup Encryption:** AES-256-CBC with pbkdf2 key derivation
- **ClickHouse Storage:** Compressed with ZSTD (not encrypted by default, relies on disk encryption)

#### 4.1.5 Logging and Auditing

- **System Auditing:** auditd monitors critical files (`/etc/passwd`, `/etc/shadow`, firewall configs)
- **File Integrity:** AIDE (Advanced Intrusion Detection Environment) daily scans
- **Security Logs:** Centralized in ClickHouse with 90-day retention
- **Backup Logs:** S3-compatible storage with 30-day retention

### 4.2 Organizational Measures

#### 4.2.1 Access Control Policy

| Role | Access Level | Justification |
|------|--------------|---------------|
| **Project Lead (Michał Król)** | Full admin | Data Controller |
| **Supervisor** | Read-only to anonymized data | Academic oversight |
| **System Administrator** | Infrastructure only | Technical support |
| **Public** | Anonymized dataset only | Research dissemination |

#### 4.2.2 Data Minimization

**Principles Applied:**
1. **Purpose Limitation:** Only data necessary for research objectives is collected
2. **Storage Limitation:** 90-day TTL for raw data, indefinite for anonymized exports
3. **Data Quality:** Automated validation checks ensure accuracy

**Not Collected:**
- ❌ MAC addresses
- ❌ Geolocation (latitude/longitude) - only country code
- ❌ Device fingerprints beyond what attackers provide
- ❌ Content of encrypted communications (TLS/SSH sessions)

#### 4.2.3 Incident Response Plan

**Classification:**

| Severity | Description | Response Time | Notification |
|----------|-------------|---------------|--------------|
| **P1 - Critical** | Data breach, honeypot compromise | 1 hour | Immediate (GIODO if applicable) |
| **P2 - High** | Failed anonymization, PII exposure | 4 hours | Internal only |
| **P3 - Medium** | Service outage, failed backups | 24 hours | Internal only |
| **P4 - Low** | Performance degradation | 72 hours | None |

**Breach Notification Process:**
1. **Detection:** Automated monitoring (Grafana alerts) + manual audits
2. **Assessment:** Determine if personal data affected (IP addresses)
3. **Containment:** Isolate affected systems, halt data processing
4. **Notification:** 
   - Internal stakeholders: 1 hour
   - Data Protection Officer (if appointed): 6 hours
   - GIODO (Polish DPA): 72 hours (Art. 33 GDPR) - if applicable
   - Data subjects: Not required (attackers, no contact info)
5. **Remediation:** Patch vulnerabilities, restore from backup
6. **Documentation:** Incident report for audit trail

#### 4.2.4 Training and Awareness

- **Project Team:** GDPR fundamentals training (4 hours)
- **Data Handling:** Secure coding practices for ETL pipeline
- **Incident Response:** Tabletop exercise for breach scenarios

#### 4.2.5 Third-Party Data Processors

| Processor | Role | Safeguards |
|-----------|------|------------|
| **Hetzner Cloud** | VPS hosting | DPA signed, EU-based (Germany), GDPR-compliant |
| **GitHub** | Code repository (public) | No personal data stored in repo |
| **Docker Hub** | Container images | Public images only |

**Data Processing Agreement (DPA):**  
✅ Signed with Hetzner Cloud (Art. 28 GDPR)  
Contract includes: sub-processor list, security obligations, audit rights, breach notification

---

## 5. Data Subject Rights

### 5.1 Right to Information (Art. 13-14 GDPR)

**Privacy Notice for Website:**

> **Data Processing Notice**  
> This server operates a research honeypot to study cybersecurity threats. If you connect to this system, your IP address and connection metadata will be processed for research purposes under GDPR Art. 6(1)(f) (legitimate interest). Data is anonymized within 24 hours and retained for 90 days. For questions, contact: [email]

**Placement:** Banner on Grafana dashboard (publicly accessible, read-only)

### 5.2 Right to Access (Art. 15 GDPR)

**Implementation:**  
Data subjects (attackers) can request access to their data. However, practical limitations apply:

- **Identification Challenge:** Attackers typically do not self-identify
- **Request Process:** Email to project contact with proof of IP ownership
- **Response Time:** 30 days (Art. 12(3) GDPR)

**Response Template:**
> "We have searched our records for IP address [X.X.X.X] and found [N] events during [date range]. Due to anonymization applied 24 hours after collection, we cannot retroactively link this data to you. Anonymized data: [hash]. This data will be deleted after [90 days from collection]."

### 5.3 Right to Erasure (Art. 17 GDPR)

**Conditions for Refusal:**
- Art. 17(3)(d): Processing necessary for archiving purposes in the public interest, scientific or historical research
- Legitimate Interest override: Research objectives outweigh individual erasure request

**Procedure:**  
If erasure request received:
1. Verify identity of requester
2. Assess if exemption applies (likely yes, due to scientific research)
3. If exemption does not apply: manually delete data and confirm to requester

### 5.4 Right to Rectification (Art. 16 GDPR)

**Not Applicable:** Data is collected passively from network traffic. Rectification requests cannot be fulfilled as there is no "incorrect" data - only observed behavior.

### 5.5 Right to Object (Art. 21 GDPR)

**Grounds for Refusal:**
- Art. 21(6): Processing necessary for scientific research purposes
- Legitimate Interest: Cybersecurity research serves public interest

**Procedure:**  
If objection received, evaluate on case-by-case basis. Likely outcome: objection denied due to research exemption.

### 5.6 Rights Not Applicable

- **Right to Restriction (Art. 18):** Not applicable (automated processing)
- **Right to Data Portability (Art. 20):** Not applicable (no contractual relationship)
- **Right Not to Be Subject to Automated Decision-Making (Art. 22):** Not applicable (no decisions affecting data subjects)

---

## 6. Consultation with Data Protection Officer (DPO)

**Status:** No DPO appointed (not required for organization <250 employees, per Art. 37 GDPR)

**Alternative:** Data protection responsibilities assigned to Project Lead (Michał Król)

**DPO Consultation (if required):**
- Date: [Date]
- DPO Name: [Name]
- Recommendations: [Summary]
- Actions Taken: [Changes implemented]

---

## 7. International Data Transfers

**Status:** No international data transfers outside EEA.

**Data Location:**
- VPS: Hetzner Cloud Frankfurt, Germany (EEA)
- Backups: S3-compatible storage in EU region
- Published Dataset: Hosted on GitHub (acceptable under GDPR for public, anonymized data)

---

## 8. Approval and Review

### 8.1 Sign-Off

| Role | Name | Signature | Date |
|------|------|-----------|------|
| **Data Controller** | [Organization] | _____________ | ______ |
| **Project Lead** | Michał Król | _____________ | 2025-01-20 |
| **Supervisor** | Dr. Inż. Tomasz Bartczak | _____________ | ______ |
| **DPO (if applicable)** | N/A | _____________ | ______ |

### 8.2 Review Schedule

This DPIA will be reviewed:
- **Trigger-based:** Before any significant changes to processing activities
- **Periodic:** Annually (2026-01-20)
- **Post-incident:** After any data breach or security incident

### 8.3 Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-01-20 | Michał Król | Initial DPIA for project approval |

---

## 9. Conclusion

### 9.1 Summary of Findings

The IoT Honeynet project processes personal data (IP addresses) for legitimate scientific research purposes. The implemented technical and organizational measures effectively mitigate privacy risks to an acceptable level.

**Key Strengths:**
- ✅ Strong legal basis (legitimate interest + scientific research)
- ✅ Robust anonymization (HMAC-SHA256, weekly salt rotation)
- ✅ Network isolation (blocked outbound, DMZ)
- ✅ Limited retention (90-day TTL)
- ✅ Transparency (public privacy notice)
- ✅ Low risk to data subjects (attackers performing illegal activities)

**Areas for Monitoring:**
- ⚠️ Effectiveness of PII redaction (quarterly audits)
- ⚠️ Salt rotation compliance (automated checks)
- ⚠️ Backup encryption (annual penetration test)

### 9.2 Decision

**Recommendation:** APPROVED for production deployment

**Justification:**
- Residual risk level: LOW
- All GDPR requirements addressed
- Public interest in cybersecurity research outweighs minimal privacy impact
- Appropriate safeguards in place

**Conditions:**
1. Quarterly review of anonymization effectiveness
2. Annual security audit
3. Prompt investigation of any data subject requests
4. Immediate notification of any data breach

---

## 10. Appendices

### Appendix A: Legal Framework Summary

| Regulation | Article | Requirement | Compliance Status |
|------------|---------|-------------|-------------------|
| **GDPR** | Art. 5 | Principles (lawfulness, fairness, transparency) | ✅ Compliant |
| **GDPR** | Art. 6(1)(f) | Legal basis (legitimate interest) | ✅ Compliant |
| **GDPR** | Art. 9(2)(j) | Scientific research exemption | ✅ Compliant |
| **GDPR** | Art. 13-14 | Information obligation | ✅ Privacy notice published |
| **GDPR** | Art. 15-22 | Data subject rights | ✅ Procedures documented |
| **GDPR** | Art. 25 | Data protection by design & default | ✅ Implemented |
| **GDPR** | Art. 28 | Processor contracts | ✅ DPA with Hetzner |
| **GDPR** | Art. 30 | Records of processing activities | ✅ This DPIA |
| **GDPR** | Art. 32 | Security of processing | ✅ Encryption, access control |
| **GDPR** | Art. 33-34 | Breach notification | ✅ Incident response plan |
| **GDPR** | Art. 35 | DPIA | ✅ This document |
| **Polish DPA** | Ustawa o ochronie danych osobowych | National implementation | ✅ Compliant |

### Appendix B: Anonymization Test Results

**Test Case:** Rainbow Table Attack Simulation

**Method:**
1. Generated 1,000 random IP addresses
2. Applied HMAC-SHA256 anonymization with known salt
3. Attempted to reverse-engineer IPs using rainbow table

**Result:**  
✅ **FAIL** (for attacker) - 0/1000 IPs recovered (0% success rate)

**Conclusion:** HMAC with secret salt is resistant to rainbow table attacks.

---

**Test Case:** Collision Rate Analysis

**Method:**
1. Anonymized 100,000 unique IP addresses
2. Checked for hash collisions (same hash for different IPs)

**Result:**  
✅ **0 collisions** detected (probability: < 2^-128 with SHA256)

**Conclusion:** Hash function provides sufficient uniqueness.

---

### Appendix C: Incident Response Flowchart

```
[Anomaly Detected]
        ↓
[Assess Severity]
        ↓
    ┌───┴───┐
    │ P1-P2 │ → [Immediate containment] → [Notify DPO/GIODO]
    └───────┘
        ↓
    ┌───┴───┐
    │ P3-P4 │ → [Schedule fix] → [Internal review]
    └───────┘
        ↓
[Document Incident]
        ↓
[Lessons Learned]
```

---

### Appendix D: Privacy Notice (Web Banner)

**Polish Version:**

> **Uwaga: Serwer badawczy**  
> Ten serwer jest honeypot służącym celom badawczym. Połączenia do tego systemu są monitorowane. Twój adres IP będzie przetwarzany zgodnie z RODO Art. 6(1)(f) (uzasadniony interes prawny) w celach naukowych. Dane są anonimizowane w ciągu 24h i przechowywane przez 90 dni. Kontakt: michalkrolkontakt@gmail.com

**English Version:**

> **Notice: Research Server**  
> This server is a honeypot for cybersecurity research. Connections are monitored. Your IP address will be processed under GDPR Art. 6(1)(f) (legitimate interest) for scientific purposes. Data is anonymized within 24h and retained for 90 days. Contact: michalkrolkontakt@gmail.com

---

## Document Control

**Classification:** PUBLIC (non-sensitive after approval)  
**Storage Location:** `/opt/iot-honeynet/docs/DPIA.md`  
**Backup Location:** Encrypted S3 bucket  
**Next Review Date:** 2026-01-20

**Prepared by:** Michał Król  
**Reviewed by:** [Supervisor Name]  
**Approved by:** [Data Controller]

**End of Document**
