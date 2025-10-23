# Installation Guide - IoT Honeynet

> **Przewodnik instalacji kompletnego honeynetu dedykowanego urządzeniom IoT**

## Spis treści

1. [Wymagania wstępne](#wymagania-wstępne)
2. [Przygotowanie środowiska](#przygotowanie-środowiska)
3. [Instalacja krok po kroku](#instalacja-krok-po-kroku)
4. [Konfiguracja zmiennych środowiskowych](#konfiguracja-zmiennych-środowiskowych)
5. [Weryfikacja instalacji](#weryfikacja-instalacji)
6. [Pierwszy start i podstawowa konfiguracja](#pierwszy-start-i-podstawowa-konfiguracja)
7. [Dostęp do komponentów](#dostęp-do-komponentów)
8. [Rozwiązywanie problemów](#rozwiązywanie-problemów)
9. [Bezpieczeństwo](#bezpieczeństwo)

---

## Wymagania wstępne

### Środowisko sprzętowe

| Komponent | Minimum | Zalecane | Krytyczne |
|-----------|---------|----------|-----------|
| **CPU** | 4 vCPU | 8 vCPU | ✓ Multi-core (dla Suricata) |
| **RAM** | 8 GB | 16 GB | ✓ 8 GB minimum |
| **Dysk** | 200 GB SSD | 500 GB SSD | ✓ SSD zalecane |
| **Sieć** | 100 Mbps | 1 Gbps | ✓ Publiczny IPv4 |
| **Przepustowość** | Nielimitowana | Nielimitowana | ✓ Bez limitów transferu |

### System operacyjny

- **Ubuntu 22.04 LTS** (zalecane) lub nowszy
- **Debian 11/12** (wspierane)
- **RHEL/CentOS 8+** (wymaga adaptacji playbooks)

**UWAGA:** Projekt testowany głównie na Ubuntu 22.04 LTS. Inne dystrybucje mogą wymagać modyfikacji playbooks Ansible.

### Dostęp i uprawnienia

- ✅ Dostęp root/sudo do serwera
- ✅ Publiczny adres IPv4 (konieczne dla ekspozycji honeypota)
- ✅ Możliwość otwierania portów w firewallu dostawcy (AWS Security Groups, Azure NSG, OVH Firewall, etc.)
- ✅ Klucz SSH do zdalnego zarządzania

### Oprogramowanie bazowe

Zostaną zainstalowane automatycznie przez Ansible, ale możesz je zainstalować ręcznie:

- Docker 24.0+
- Docker Compose v2.20+
- Python 3.10+
- Git
- OpenSSH Server

---

## Przygotowanie środowiska

### 1. Aktualizacja systemu

```bash
sudo apt update && sudo apt upgrade -y
sudo reboot
```

### 2. Instalacja Git (jeśli brak)

```bash
sudo apt install -y git
```

### 3. Klonowanie repozytorium

```bash
cd ~
git clone https://github.com/m1szk4/HoneyNet.git
cd HoneyNet
```

### 4. Instalacja Ansible (na lokalnej maszynie zarządzającej)

Jeśli planujesz uruchomić playbooks Ansible zdalnie z twojej maszyny lokalnej:

```bash
# Na Ubuntu/Debian
sudo apt install -y ansible sshpass

# Na macOS
brew install ansible

# Weryfikacja
ansible --version  # Powinno być >= 2.12
```

**UWAGA:** Ansible może być także uruchomiony bezpośrednio na serwerze docelowym (localhost deployment).

---

## Instalacja krok po kroku

### Metoda A: Automatyczna instalacja (Zalecana)

Pełna automatyzacja z użyciem Ansible i Makefile.

#### Krok 1: Konfiguracja inventory

Edytuj plik z konfiguracją serwerów:

```bash
nano ansible/inventory/hosts.ini
```

Zastąp placeholdery prawdziwymi wartościami:

```ini
[honeynet]
honeynet-01 ansible_host=YOUR_SERVER_PUBLIC_IP ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa

[honeynet:vars]
ansible_python_interpreter=/usr/bin/python3
management_ip=YOUR_LOCAL_IP_FOR_SSH_WHITELIST
```

**Przykład:**
```ini
[honeynet]
honeynet-01 ansible_host=203.0.113.42 ansible_user=root ansible_ssh_private_key_file=~/.ssh/honeynet_key

[honeynet:vars]
ansible_python_interpreter=/usr/bin/python3
management_ip=198.51.100.10
```

#### Krok 2: Konfiguracja zmiennych środowiskowych

Skopiuj i edytuj plik `.env`:

```bash
cp .env.example .env
nano .env
```

**Sekcje do wypełnienia** (szczegóły w następnej sekcji):
- `ANON_SECRET_KEY` - Klucz do anonimizacji (minimum 32 znaki)
- `GRAFANA_ADMIN_PASSWORD` - Hasło do Grafana
- `CLICKHOUSE_PASSWORD` - Hasło do bazy ClickHouse

**Generowanie silnych haseł:**

```bash
# Generuj wszystkie hasła jednocześnie
echo "ANON_SECRET_KEY=$(openssl rand -base64 32)"
echo "GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 24)"
echo "CLICKHOUSE_PASSWORD=$(openssl rand -base64 24)"
```

Skopiuj wygenerowane wartości do pliku `.env`.

#### Krok 3: Test połączenia Ansible

```bash
cd ansible
ansible -i inventory/hosts.ini honeynet -m ping
```

Oczekiwany output:
```
honeynet-01 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

#### Krok 4: Deployment z Ansible

Uruchom playbooks w kolejności:

```bash
# 1. Hardening systemu (UFW, fail2ban, auditd, AIDE, rkhunter)
ansible-playbook -i inventory/hosts.ini playbooks/00-hardening.yml

# 2. Instalacja Docker i Docker Compose
ansible-playbook -i inventory/hosts.ini playbooks/01-docker-install.yml

# 3. Deploy honeynetu
ansible-playbook -i inventory/hosts.ini playbooks/02-deploy-honeypots.yml
```

**LUB użyj Makefile (wykonuje wszystkie kroki):**

```bash
cd ..  # Wróć do głównego katalogu
make deploy
```

Deployment potrwa **10-15 minut**. Po zakończeniu zobaczysz:

```
✅ Deployment zakończony!
🏥 Health check...
✓ Docker daemon running
✓ All containers running (8/8)
✓ ClickHouse accessible
✓ Grafana accessible
✓ Network isolation OK
```

#### Krok 5: Weryfikacja

```bash
make health-check
make test-isolation
docker-compose ps
```

---

### Metoda B: Instalacja ręczna (bez Ansible)

Jeśli wolisz pełną kontrolę lub nie możesz użyć Ansible.

#### Krok 1: Zainstaluj Docker

```bash
# Usuń stare wersje
sudo apt remove -y docker docker-engine docker.io containerd runc

# Zainstaluj zależności
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# Dodaj oficjalne repozytorium Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Zainstaluj Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Weryfikacja
docker --version  # Powinno być >= 24.0
docker compose version  # Powinno być v2.20+
```

#### Krok 2: Konfiguracja Docker

```bash
# Dodaj użytkownika do grupy docker (opcjonalne)
sudo usermod -aG docker $USER
newgrp docker

# Uruchom Docker
sudo systemctl enable docker
sudo systemctl start docker
```

#### Krok 3: Konfiguracja firewall (iptables)

```bash
# Uruchom skrypt konfiguracyjny
sudo bash scripts/deployment/setup-firewall.sh
```

Ten skrypt:
- Przekierowuje porty 22→2222, 23→2323, 80, 445, 502 do honeypotów
- **BLOKUJE ruch wychodzący** z sieci honeypot (172.20.0.0/24) - data control
- Umożliwia dostęp SSH tylko z whitelistowanych IP

#### Krok 4: Utwórz strukturę katalogów

```bash
sudo mkdir -p /opt/iot-honeynet/data/{cowrie,dionaea,conpot,suricata/pcap,zeek,clickhouse,grafana,exports}
sudo mkdir -p /opt/iot-honeynet/logs
sudo mkdir -p /opt/iot-honeynet/backups

# Skopiuj konfiguracje
sudo cp -r configs /opt/iot-honeynet/
sudo cp docker-compose.yml /opt/iot-honeynet/
sudo cp .env /opt/iot-honeynet/
```

#### Krok 5: Uruchom honeynetu

```bash
cd /opt/iot-honeynet
docker compose up -d
```

#### Krok 6: Zweryfikuj

```bash
docker compose ps
docker compose logs -f
```

---

## Konfiguracja zmiennych środowiskowych

Plik `.env` zawiera wszystkie kluczowe parametry honeynetu.

### Obowiązkowe zmienne (MUST CHANGE!)

```bash
# === Security ===
# Klucz do anonimizacji IP (HMAC-SHA256) - minimum 32 znaki
ANON_SECRET_KEY=CHANGE_ME_TO_RANDOM_STRING_MIN_32_CHARS

# Hasło administratora Grafana
GRAFANA_ADMIN_PASSWORD=CHANGE_ME_STRONG_PASSWORD

# === ClickHouse Database ===
CLICKHOUSE_USER=honeynet
CLICKHOUSE_PASSWORD=CHANGE_ME_CLICKHOUSE_PASSWORD
CLICKHOUSE_DB=honeynet
```

### Generowanie bezpiecznych sekretów

**Metoda 1: OpenSSL (zalecana)**

```bash
# Generuj klucz anonimizacji (base64, 32+ znaki)
openssl rand -base64 32

# Generuj hasła
openssl rand -base64 24
```

**Metoda 2: Python**

```python
import secrets
print(secrets.token_urlsafe(32))  # ANON_SECRET_KEY
print(secrets.token_urlsafe(24))  # Hasła
```

**Metoda 3: /dev/urandom (Linux)**

```bash
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1
```

### Opcjonalne zmienne

#### Backup do S3/MinIO

Jeśli chcesz automatyczne backupy do S3:

```bash
S3_ENDPOINT=https://s3.amazonaws.com
S3_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE
S3_SECRET_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
S3_BUCKET=honeynet-backups
```

#### Alerty (Discord/Email)

**Discord webhook:**

```bash
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/123456789/abcdef123456
```

**Email (SMTP):**

```bash
ALERT_EMAIL=admin@example.com
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your.email@gmail.com
SMTP_PASSWORD=your-app-password  # NIE używaj hasła konta! Użyj App Password
```

Dla Gmail: [Instrukcja tworzenia App Password](https://support.google.com/accounts/answer/185833?hl=pl)

#### Tuning wydajności

Jeśli masz więcej zasobów:

```bash
# Zwiększ wątki Suricata (domyślnie 4)
SURICATA_THREADS=8

# Zwiększ limity pamięci
SURICATA_MEM_LIMIT=4g
CLICKHOUSE_MEM_LIMIT=6g
```

### Sieci (NIE ZMIENIAJ bez zrozumienia architektury!)

```bash
HONEYPOT_SUBNET=172.20.0.0/24      # Sieć DMZ dla honeypotów
MANAGEMENT_SUBNET=172.21.0.0/24    # Sieć zarządzania
```

---

## Weryfikacja instalacji

### 1. Status kontenerów

```bash
docker compose ps
```

Oczekiwany output - wszystkie kontenery **Up**:

```
NAME                IMAGE                              STATUS
clickhouse          clickhouse/clickhouse-server       Up (healthy)
conpot              honeynet/conpot                    Up
cowrie              cowrie/cowrie                      Up
dionaea             dinotools/dionaea                  Up
grafana             grafana/grafana                    Up
jupyter             jupyter/scipy-notebook             Up
logstash            elastic/logstash                   Up
suricata            jasonish/suricata                  Up
zeek                zeek/zeek                          Up
```

### 2. Test izolacji sieciowej (KRYTYCZNE!)

```bash
make test-isolation
# LUB
python3 tests/test_isolation.py
```

**MUSI zakończyć się sukcesem!** Ten test weryfikuje, że honeypoty **nie mogą** łączyć się z Internetem (data control).

Oczekiwany output:

```
✓ Outbound HTTP blocked from honeypot network
✓ Outbound DNS blocked from honeypot network
✓ Honeypots cannot reach Internet
✓ Management network has Internet access
✓ All isolation tests PASSED
```

### 3. Test komponentów

```bash
# ClickHouse
docker exec clickhouse clickhouse-client --query "SELECT 1"

# Grafana (sprawdź czy odpowiada)
curl -I http://localhost:3000

# Logstash (sprawdź pipeline)
docker exec logstash curl -XGET 'localhost:9600/_node/stats/pipelines?pretty'
```

### 4. Logi

Sprawdź czy nie ma błędów:

```bash
# Wszystkie kontenery
make logs

# Konkretny honeypot
docker compose logs cowrie
docker compose logs suricata
```

---

## Pierwszy start i podstawowa konfiguracja

### 1. Dostęp do Grafana

Otwórz przeglądarkę:

```
http://YOUR_SERVER_IP:3000
```

**Login:**
- Username: `admin`
- Password: `[wartość z GRAFANA_ADMIN_PASSWORD w .env]`

**Po pierwszym logowaniu:**
1. Zmień hasło (jeśli używasz słabego tymczasowego)
2. Przejdź do: **Dashboards → Browse**
3. Otwórz dashboard: **"Honeynet Overview"**

Powinieneś zobaczyć:
- Całkowita liczba ataków (na początku: 0)
- Mapę geograficzną (pusta na starcie)
- Top targeted ports
- Attack timeline

### 2. Weryfikacja zbierania danych

Po 15-30 minutach ekspozycji sprawdź:

```bash
# Zapytanie do ClickHouse
docker exec clickhouse clickhouse-client --query "SELECT COUNT(*) FROM honeynet.events"

# Powinno zwrócić liczbę > 0 (jeśli są ataki)
```

**Jeśli COUNT(*) = 0 po 1 godzinie:**
- Sprawdź czy serwer ma publiczny IP: `curl ifconfig.me`
- Sprawdź czy porty są otwarte: `nmap -p 22,23,80 YOUR_SERVER_IP` (z innego hosta)
- Sprawdź logi Logstash: `docker compose logs logstash`

### 3. Testowe ataki (z INNEJ maszyny!)

**UWAGA:** NIE uruchamiaj z serwera honeynetu! Użyj swojego laptopa lub innego hosta.

```bash
# Test Telnet honeypot (Cowrie)
telnet YOUR_SERVER_IP 23
# Spróbuj zalogować się: root / password

# Test SSH honeypot
ssh root@YOUR_SERVER_IP -p 22
# Spróbuj hasło: admin

# Test HTTP honeypot (Dionaea)
curl http://YOUR_SERVER_IP/
```

Po kilku próbach, sprawdź w Grafanie czy pojawiły się zdarzenia.

---

## Dostęp do komponentów

### Grafana (Wizualizacja)

- **URL:** `http://YOUR_SERVER_IP:3000`
- **Login:** admin / [GRAFANA_ADMIN_PASSWORD]
- **Dashboards:**
  - Honeynet Overview - Główny dashboard
  - Attack Analysis - Szczegółowa analiza ataków

### Jupyter Lab (Analiza danych)

- **URL:** `http://YOUR_SERVER_IP:8888`
- **Token:** Znajdź w logach:

  ```bash
  docker logs jupyter 2>&1 | grep "token="
  ```

  Skopiuj token z URL, np.: `http://127.0.0.1:8888/lab?token=abc123def456...`

- **Notebooks:** Zobacz `notebooks/EDA_example.ipynb` dla przykładów

### ClickHouse (Baza danych)

**Lokalne zapytania (z serwera honeynetu):**

```bash
# Interaktywny klient
docker exec -it clickhouse clickhouse-client

# Pojedyncze zapytanie
docker exec clickhouse clickhouse-client --query "SELECT COUNT(*) FROM honeynet.events"
```

**Zdalne zapytania (z Twojego laptopa):**

```bash
# Zainstaluj klienta
sudo apt install -y clickhouse-client

# Połącz się (wymaga wystawienia portu 9000 lub tunelu SSH)
clickhouse-client --host YOUR_SERVER_IP --port 9000 --user honeynet --password YOUR_PASSWORD
```

**Przykładowe zapytania:**

```sql
-- Top 10 krajów źródłowych
SELECT geo_country, COUNT(*) as attacks
FROM honeynet.events
WHERE timestamp > now() - INTERVAL 24 HOUR
GROUP BY geo_country
ORDER BY attacks DESC
LIMIT 10;

-- Najczęściej atakowane porty
SELECT dest_port, COUNT(*) as hits
FROM honeynet.events
GROUP BY dest_port
ORDER BY hits DESC
LIMIT 10;

-- MITRE ATT&CK coverage
SELECT mitre_technique, COUNT(*) as occurrences
FROM honeynet.events
WHERE mitre_technique != ''
GROUP BY mitre_technique
ORDER BY occurrences DESC;
```

### SSH do honeypotów (debugging)

```bash
# Cowrie (SSH/Telnet honeypot)
docker exec -it cowrie /bin/bash

# Dionaea (Multi-protocol honeypot)
docker exec -it dionaea /bin/bash

# Conpot (ICS/SCADA honeypot)
docker exec -it conpot /bin/bash
```

---

## Rozwiązywanie problemów

### Problem: Kontenery nie startują

**Symptom:**

```bash
docker compose ps
# Pokazuje kontenery w stanie "Exited" lub "Restarting"
```

**Rozwiązanie:**

```bash
# Sprawdź logi konkretnego kontenera
docker compose logs [nazwa_kontenera]

# Najczęstsze przyczyny:
# 1. Błąd w .env (brakujące zmienne)
cat .env | grep CHANGE_ME  # Powinno być puste!

# 2. Port już zajęty
sudo netstat -tulpn | grep -E ':(22|23|80|3000|8888)'

# 3. Brak miejsca na dysku
df -h

# 4. Problemy z siecią Docker
docker network ls
docker network inspect iot-honeynet_honeypot_net
```

### Problem: ClickHouse connection refused

**Symptom:**

```
Error: Connection refused (clickhouse:9000)
```

**Rozwiązanie:**

```bash
# Sprawdź czy ClickHouse działa
docker compose ps clickhouse

# Sprawdź logi ClickHouse
docker compose logs clickhouse | tail -100

# Sprawdź czy port nasłuchuje
docker exec clickhouse netstat -tulpn | grep 9000

# Restart ClickHouse
docker compose restart clickhouse
```

### Problem: Brak danych w Grafanie

**Symptom:** Dashboardy puste mimo trwającej ekspozycji.

**Rozwiązanie:**

```bash
# 1. Sprawdź czy są dane w ClickHouse
docker exec clickhouse clickhouse-client --query "SELECT COUNT(*) FROM honeynet.events"

# Jeśli 0:
# 2. Sprawdź czy Logstash przetwarza dane
docker compose logs logstash | grep -i error

# 3. Sprawdź czy honeypoty generują logi
docker compose logs cowrie | tail -50
ls -lh data/cowrie/log/

# 4. Sprawdź pipeline Logstash
docker exec logstash curl -XGET 'localhost:9600/_node/stats/pipelines?pretty'

# 5. Zrestartuj pipeline ETL
docker compose restart logstash
```

### Problem: Honeypot nie odbiera ataków

**Symptom:** Brak ruchu na honeypotach po kilku godzinach.

**Możliwe przyczyny:**

1. **Serwer za NAT/firewallem:**

   ```bash
   # Sprawdź publiczny IP
   curl ifconfig.me

   # Porównaj z IP w `docker compose logs`
   # Jeśli różne - serwer za NAT, skonfiguruj port forwarding u dostawcy
   ```

2. **Firewall dostawcy blokuje porty:**

   Sprawdź w panelu dostawcy (AWS Security Groups, Azure NSG, OVH Firewall), czy porty są otwarte:
   - 22 (SSH)
   - 23, 2323 (Telnet)
   - 80, 8080 (HTTP)
   - 445 (SMB)
   - 502 (Modbus)
   - 554 (RTSP)
   - 1900 (UPnP)

3. **iptables blokuje ruch:**

   ```bash
   sudo iptables -L -n -v

   # Jeśli zbyt restrykcyjne reguły:
   sudo bash scripts/deployment/setup-firewall.sh  # Zastosuj ponownie
   ```

4. **IP już znany jako honeypot:**

   Niektóre botnety unikają znanych honeypotów. Rozważ zmianę IP lub użycie nowego serwera.

### Problem: Test izolacji kończy się błędem

**Symptom:**

```
✗ Honeypots CAN reach Internet - ISOLATION BREACH!
```

**KRYTYCZNE!** Honeypoty mogą zostać użyte do ataków na zewnątrz.

**Rozwiązanie:**

```bash
# 1. Sprawdź reguły iptables
sudo iptables -L -n -v | grep 172.20.0.0

# Powinny być reguły DROP dla 172.20.0.0/24

# 2. Zastosuj firewall ponownie
sudo bash scripts/deployment/setup-firewall.sh

# 3. Weryfikuj ręcznie (z WEWNĄTRZ kontenera Cowrie)
docker exec cowrie ping -c 3 8.8.8.8
# Powinno: "Network unreachable" lub timeout

# 4. Sprawdź routing
docker exec cowrie ip route
# NIE powinno być default gateway poza 172.20.0.0/24
```

### Problem: Wysokie użycie CPU przez Suricata

**Symptom:** Suricata zużywa > 80% CPU.

**Rozwiązanie:**

```bash
# 1. Zmniejsz liczbę wątków (jeśli masz mało rdzeni)
nano .env
# Ustaw: SURICATA_THREADS=2

# 2. Wyłącz nieużywane funkcje w suricata.yaml
nano configs/suricata/suricata.yaml
# Ustaw: pcap-log.enabled: no (jeśli nie potrzebujesz pełnych pcap)

# 3. Zwiększ limity pamięci
# W .env: SURICATA_MEM_LIMIT=4g

# 4. Restart Suricata
docker compose restart suricata
```

### Problem: Brak miejsca na dysku

**Symptom:**

```bash
df -h
# /dev/sda1  200G  195G  0G  100% /
```

**Rozwiązanie:**

```bash
# 1. Wyczyść stare logi (> 30 dni)
make clean

# 2. Ręczne czyszczenie
find data/ -name "*.log" -mtime +30 -delete
find data/ -name "*.pcap" -mtime +7 -delete

# 3. Wyczyść Docker (unused images, containers)
docker system prune -a -f

# 4. Zmniejsz TTL w ClickHouse (domyślnie 90 dni)
nano configs/clickhouse/schema.sql
# Zmień: TTL timestamp + INTERVAL 90 DAY -> 30 DAY
# Zaaplikuj:
docker exec clickhouse clickhouse-client --query "ALTER TABLE honeynet.events MODIFY TTL timestamp + INTERVAL 30 DAY"
```

---

## Bezpieczeństwo

### 1. Izolacja sieciowa (Data Control)

**ZAWSZE weryfikuj po każdej zmianie:**

```bash
make test-isolation
```

Honeypoty **NIE MOGĄ** mieć dostępu do Internetu. Naruszenie tej zasady może prowadzić do:
- Wykorzystania Twojego serwera do ataków DDoS
- Odpowiedzialności prawnej
- Blacklisty IP

### 2. Dostęp SSH

**Ogranicz dostęp SSH tylko do Twojego IP:**

```bash
# W ansible/inventory/hosts.ini ustaw:
management_ip=YOUR_STATIC_IP

# Albo ręcznie dodaj regułę iptables:
sudo iptables -I INPUT 1 -p tcp --dport 22 -s YOUR_IP -j ACCEPT
sudo iptables -I INPUT 2 -p tcp --dport 22 -j DROP
```

**Użyj kluczy SSH zamiast haseł:**

```bash
# Na Twojej lokalnej maszynie
ssh-keygen -t ed25519 -C "honeynet-access"

# Skopiuj klucz na serwer
ssh-copy-id -i ~/.ssh/id_ed25519.pub root@YOUR_SERVER_IP

# Wyłącz autentykację hasłem
sudo nano /etc/ssh/sshd_config
# Ustaw: PasswordAuthentication no
sudo systemctl restart sshd
```

### 3. Hasła i sekrety

- **NIE commituj** `.env` do Git (już w `.gitignore`)
- **Używaj silnych haseł** (minimum 24 znaki, losowe)
- **Zmieniaj domyślne hasła** Grafany po pierwszym logowaniu
- **Regularnie rotuj** `ANON_SECRET_KEY` (co 6 miesięcy)

### 4. Aktualizacje

```bash
# Aktualizuj system co tydzień
sudo apt update && sudo apt upgrade -y

# Aktualizuj obrazy Docker co miesiąc
make update

# Monitoruj CVE dla używanych komponentów
```

### 5. Monitoring i alerty

Skonfiguruj alerty (Discord/Email) dla:
- Nieprawidłowy restart kontenerów
- Brak miejsca na dysku (< 10 GB)
- Naruszenie izolacji sieciowej

### 6. Backup

**Regularnie twórz backupy:**

```bash
# Ręczny backup
make backup

# Automatyczny backup przez Ansible
cd ansible
ansible-playbook -i inventory/hosts.ini playbooks/99-backup.yml
```

Backupy zawierają:
- Wszystkie konfiguracje (`configs/`)
- Zaszyfrowany plik `.env`
- Eksport danych z ClickHouse (Parquet)

---

## Następne kroki

Po pomyślnej instalacji:

1. **Ekspozycja:** Pozostaw honeynet włączony przez minimum 30-60 dni dla reprezentatywnych danych
2. **Monitoring:** Codziennie sprawdzaj `make health-check`
3. **Analiza:** Co tydzień przeglądaj dashboardy w Grafanie
4. **Dokumentacja:** Zobacz [DATA_ANALYSIS.md](DATA_ANALYSIS.md) dla metodologii analizy zebranych danych
5. **Tuning:** Po pierwszym tygodniu dostosuj reguły IDS - zobacz [Wnioski dla IDS](../README.md#wnioski-dla-ids)

---

## Wsparcie

- **Issues:** [https://github.com/m1szk4/HoneyNet/issues](https://github.com/m1szk4/HoneyNet/issues)
- **Dokumentacja:** Zobacz pozostałe pliki w `docs/`
- **Email:** michalkrolkontakt@gmail.com

---

**⚠️ PRZYPOMNIENIE:** Ten honeynet jest celowo podatny na ataki. **NIE URUCHAMIAJ w sieci produkcyjnej!**

---

*Ostatnia aktualizacja: 2025-10-23*
*Wersja: 1.0*
