# Data Dictionary - IoT Honeynet Dataset

## Przegląd

Dataset zawiera zanonimizowane logi z 60-dniowego okresu ekspozycji honeynetu IoT (01.11.2025 - 31.12.2025) w regionie CEE (Polska).

**Format:** Apache Parquet z kompresją ZSTD  
**Wielkość:** ~1.5 GB (skompresowane)  
**Liczba rekordów:** ~5,000,000 zdarzeń  
**Licencja:** CC BY 4.0

---

## Tabele

### 1. `events` - Główna tabela zdarzeń

Zawiera wszystkie zdarzenia z honeypotów z podstawową klasyfikacją.

| Pole | Typ | Opis | Przykład | Nullable |
|------|-----|------|----------|----------|
| `timestamp` | DateTime64(3) | Czas zdarzenia (UTC) z milisekundami | `2025-11-15 14:32:18.456` | NO |
| `event_date` | Date | Data zdarzenia (materialized) | `2025-11-15` | NO |
| `event_id` | UUID | Unikalny identyfikator zdarzenia | `550e8400-e29b-41d4-a716-446655440000` | NO |
| `event_type` | String | Typ zdarzenia | `cowrie.login.failed`, `dionaea.http.request` | NO |
| `honeypot_name` | String | Nazwa honeypota | `cowrie`, `dionaea`, `conpot` | NO |
| `source_ip_anon` | FixedString(32) | Zanonimizowany IP źródłowy (HMAC-SHA256) | `a3b4c5d6e7f8...` | NO |
| `source_port` | UInt16 | Port źródłowy | `52341` | NO |
| `dest_ip` | IPv4 | IP docelowy (honeypot) | `172.20.0.10` | NO |
| `dest_port` | UInt16 | Port docelowy | `22`, `23`, `80`, `502` | NO |
| `protocol` | String | Protokół | `tcp`, `udp` | NO |
| `country_code` | FixedString(2) | Kod kraju (ISO 3166-1 alpha-2) | `CN`, `US`, `RU`, `PL` | YES |
| `asn` | UInt32 | Autonomous System Number | `15169` (Google), `16509` (AWS) | YES |
| `attack_technique` | String | MITRE ATT&CK Technique ID | `T1078.001`, `T1110.001` | YES |
| `attack_tactic` | String | MITRE ATT&CK Tactic | `Initial Access`, `Credential Access` | YES |
| `severity` | Enum | Poziom zagrożenia | `info`, `low`, `medium`, `high`, `critical` | NO |
| `session_id` | String | Identyfikator sesji | `abc123def456` | YES |
| `duration` | UInt32 | Czas trwania sesji (sekundy) | `120` | YES |
| `payload` | String | Payload ataku (zanonimizowany) | `wget http://...`, `SELECT * FROM` | YES |
| `payload_size` | UInt32 | Rozmiar payloadu (bajty) | `1024` | YES |
| `user_agent` | String | User-Agent (HTTP) | `Mozilla/5.0 ...`, `python-requests/2.28.1` | YES |
| `username` | String | Nazwa użytkownika (login attempt) | `root`, `admin`, `user` | YES |
| `password_hash` | String | Hash hasła (SHA256) | `5e884898da28047...` | YES |
| `url` | String | URL (HTTP request) | `/cgi-bin/test.cgi`, `/admin/login.php` | YES |
| `http_method` | String | Metoda HTTP | `GET`, `POST`, `PUT` | YES |
| `file_hash` | String | Hash pobranego pliku (SHA256) | `e3b0c44298fc1c1...` | YES |
| `file_size` | UInt32 | Rozmiar pliku (bajty) | `524288` | YES |
| `is_malicious` | UInt8 | Czy ruch jest złośliwy (zawsze 1 w honeynecie) | `1` | NO |
| `is_bruteforce` | UInt8 | Czy to atak brute-force | `0`, `1` | NO |
| `is_exploit` | UInt8 | Czy to próba exploita | `0`, `1` | NO |
| `metadata` | String | Dodatkowe metadane (JSON) | `{"user_agent_parsed": {...}}` | YES |

---

### 2. `ssh_events` - Zdarzenia SSH (Cowrie)

Szczegółowe logi SSH/Telnet z Cowrie.

| Pole | Typ | Opis | Przykład |
|------|-----|------|----------|
| `timestamp` | DateTime64(3) | Czas zdarzenia | `2025-11-15 14:32:18.456` |
| `source_ip_anon` | FixedString(32) | Zanonimizowany IP | `a3b4c5d6...` |
| `session_id` | String | ID sesji | `abc123` |
| `event_type` | String | Typ | `login`, `command`, `download`, `disconnect` |
| `username` | String | Login | `root`, `admin` |
| `password_hash` | String | Hash hasła | SHA256 |
| `command` | String | Komenda wykonana | `cat /etc/passwd`, `wget http://...` |
| `success` | UInt8 | Czy sukces | `0`, `1` |
| `country_code` | FixedString(2) | Kraj | `CN`, `RU` |

---

### 3. `http_events` - Zdarzenia HTTP (Dionaea)

Żądania HTTP do honeypota.

| Pole | Typ | Opis | Przykład |
|------|-----|------|----------|
| `timestamp` | DateTime64(3) | Czas | `2025-11-15 14:32:18.456` |
| `source_ip_anon` | FixedString(32) | Zanonimizowany IP | `a3b4c5d6...` |
| `method` | String | Metoda HTTP | `GET`, `POST` |
| `url` | String | URL żądania | `/cgi-bin/test`, `/admin/` |
| `user_agent` | String | User-Agent | `Mozilla/5.0 ...` |
| `referer` | String | Referer | `http://example.com` |
| `status_code` | UInt16 | Kod odpowiedzi | `200`, `404`, `500` |
| `response_size` | UInt32 | Rozmiar odpowiedzi | `1024` |
| `is_exploit` | UInt8 | Czy exploit | `0`, `1` |
| `exploit_type` | String | Typ exploita | `shellshock`, `sqli`, `rce` |
| `payload` | String | Payload | Zanonimizowany |

---

### 4. `ids_alerts` - Alerty Suricata

Alerty z systemu wykrywania intruzów.

| Pole | Typ | Opis | Przykład |
|------|-----|------|----------|
| `timestamp` | DateTime64(3) | Czas alertu | `2025-11-15 14:32:18.456` |
| `source_ip_anon` | FixedString(32) | Zanonimizowany IP | `a3b4c5d6...` |
| `alert_signature` | String | Nazwa reguły | `IoT Botnet Mirai - Telnet Login` |
| `alert_category` | String | Kategoria | `trojan-activity`, `attempted-recon` |
| `alert_severity` | UInt8 | Priorytet (1=critical, 3=low) | `1`, `2`, `3` |
| `signature_id` | UInt32 | SID reguły Suricata | `5000001` |
| `revision` | UInt16 | Wersja reguły | `1`, `2` |
| `mitre_technique` | String | MITRE ATT&CK ID | `T1078.001` |
| `mitre_tactic` | String | Taktyka | `Initial Access` |
| `payload` | String | Payload | Zanonimizowany |

---

### 5. `downloaded_files` - Pobrane pliki (malware)

Binarne pliki pobrane przez atakujących.

| Pole | Typ | Opis | Przykład |
|------|-----|------|----------|
| `timestamp` | DateTime64(3) | Czas pobrania | `2025-11-15 14:32:18.456` |
| `source_ip_anon` | FixedString(32) | Zanonimizowany IP | `a3b4c5d6...` |
| `file_hash` | String | SHA256 hash | `e3b0c44298fc1c1...` |
| `file_size` | UInt32 | Rozmiar (bajty) | `524288` |
| `file_type` | String | Typ pliku | `ELF`, `PE`, `Shell Script` |
| `download_url` | String | URL źródłowy | `http://malicious.com/bot` |
| `honeypot_name` | String | Honeypot | `cowrie`, `dionaea` |

---

## Anonimizacja

### Metoda anonimizacji IP

**Algorytm:** HMAC-SHA256 z rotowanym saltem (co 7 dni)
```python
source_ip_anon = HMAC-SHA256(salt_weekly, source_ip)
```

**Właściwości:**
- ✅ Deterministyczny (ten sam IP = ten sam hash w ciągu tygodnia)
- ✅ Nieodwracalny (brak możliwości de-anonimizacji)
- ✅ Zachowuje możliwość śledzenia kampanii atakujących
- ✅ Zgodny z RODO/GDPR

### Inne dane zanonimizowane

- **Hasła:** Tylko hash SHA256 (nigdy plaintext)
- **Payloady:** Usunięte potencjalne PII (emails, phone numbers)
- **URLs:** Usunięte query parameters z potencjalnymi danymi osobowymi

---

## Mapowanie MITRE ATT&CK

### Obserwowane techniki (28 unikalnych)

#### Initial Access (5 technik)
- **T1078.001** - Valid Accounts: Default Accounts (Mirai credentials)
- **T1190** - Exploit Public-Facing Application (ShellShock, SQLi)
- **T1133** - External Remote Services (Telnet, SSH)

#### Execution (3 techniki)
- **T1059.004** - Command and Scripting Interpreter: Unix Shell
- **T1203** - Exploitation for Client Execution

#### Persistence (2 techniki)
- **T1543** - Create or Modify System Process
- **T1053** - Scheduled Task/Job

#### Credential Access (3 techniki)
- **T1110.001** - Brute Force: Password Guessing
- **T1110.002** - Brute Force: Password Cracking
- **T1110.003** - Brute Force: Password Spraying

#### Discovery (4 techniki)
- **T1046** - Network Service Scanning
- **T1595.001** - Active Scanning: Scanning IP Blocks
- **T1595.002** - Active Scanning: Vulnerability Scanning
- **T1083** - File and Directory Discovery

#### Command and Control (3 techniki)
- **T1071.001** - Application Layer Protocol: Web Protocols
- **T1105** - Ingress Tool Transfer
- **T1573** - Encrypted Channel

#### Impact (5 technik)
- **T1498** - Network Denial of Service
- **T1496** - Resource Hijacking
- **T1490** - Inhibit System Recovery

#### ICS-specific (3 techniki)
- **T0836** - Modify Parameter (Modbus writes)
- **T0868** - Detect Operating Mode
- **T0855** - Unauthorized Command Message

---

## Statystyki datasetu

### Rozkład protokołów
- **SSH (22):** 45% zdarzeń
- **Telnet (23, 2323):** 35%
- **HTTP (80, 443):** 15%
- **Pozostałe (SMB, Modbus, etc.):** 5%

### Top 10 krajów źródłowych
1. 🇨🇳 China - 32%
2. 🇺🇸 USA - 18%
3. 🇷🇺 Russia - 12%
4. 🇧🇷 Brazil - 8%
5. 🇮🇳 India - 6%
6. 🇻🇳 Vietnam - 5%
7. 🇹🇷 Turkey - 4%
8. 🇩🇪 Germany - 3%
9. 🇫🇷 France - 3%
10. 🇬🇧 UK - 2%

### Top 10 kombinacji login/hasło
1. `root:xc3511` (Mirai) - 15% prób
2. `admin:admin` - 12%
3. `root:root` - 8%
4. `admin:password` - 6%
5. `root:888888` - 5%
6. `admin:1234` - 4%
7. `root:default` - 3%
8. `user:user` - 2%
9. `admin:123456` - 2%
10. `root:password` - 2%

---

## Użycie datasetu

### Python (Pandas)
```python
import pandas as pd

# Wczytaj Parquet
df = pd.read_parquet('events_2025-11-01_to_2025-12-31.parquet')

# Podstawowe statystyki
print(df.describe())

# Top 10 krajów
print(df['country_code'].value_counts().head(10))

# Filtrowanie - tylko ataki Mirai
mirai = df[df['attack_technique'] == 'T1078.001']
```

### ClickHouse
```sql
-- Import Parquet do ClickHouse
CREATE TABLE imported_events ENGINE = MergeTree()
ORDER BY timestamp
AS SELECT * FROM file('events_2025-11-01_to_2025-12-31.parquet', Parquet);

-- Zapytania analityczne
SELECT 
    country_code,
    count() as attacks
FROM imported_events
WHERE country_code != ''
GROUP BY country_code
ORDER BY attacks DESC
LIMIT 10;
```

---

## Cytowanie

Jeśli używasz tego datasetu w publikacjach, cytuj:
```bibtex
@misc{honeynet-iot-2025,
  author = {Michał Król},
  title = {IoT Honeynet Dataset - CEE Region 2025},
  year = {2025},
  publisher = {GitHub},
  url = {https://github.com/m1szk4/HoneyNet},
  note = {60-day honeypot deployment (Nov-Dec 2025)}
}
```

---

## Licencja

Dataset: **CC BY 4.0** - możesz używać, modyfikować i dystrybuować z podaniem źródła.

## Kontakt

Pytania? michalkrolkontakt@gmail.com