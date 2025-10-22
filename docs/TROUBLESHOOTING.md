# Troubleshooting Guide

Przewodnik rozwiązywania najczęstszych problemów z IoT Honeynet.

---

## 🔴 Problemy krytyczne

### Problem: Honeypot może łączyć się z Internetem (BREACH!)

**Symptomy:**
```bash
$ docker exec cowrie ping -c 1 8.8.8.8
PING 8.8.8.8 (8.8.8.8): 56 data bytes
64 bytes from 8.8.8.8: seq=0 ttl=117 time=10.123 ms
```

**Diagnoza:**
```bash
# Sprawdź regały iptables
sudo iptables -L -v -n

# Sprawdź sieć Docker
docker network inspect br-honeypot
```

**Rozwiązanie:**

1. **NATYCHMIAST zatrzymaj honeynet:**
```bash
docker-compose down
```

2. **Sprawdź konfigurację sieci w docker-compose.yml:**
```yaml
networks:
  honeypot_net:
    driver_opts:
      com.docker.network.bridge.enable_ip_masquerade: "false"  # MUST be false!
```

3. **Dodaj regułę firewall:**
```bash
# Zablokuj outbound z honeypot network
sudo iptables -A FORWARD -s 172.20.0.0/24 -j DROP
sudo iptables-save > /etc/iptables/rules.v4
```

4. **Restart i test:**
```bash
docker-compose up -d
sleep 10
python3 tests/test_isolation.py
```

---

### Problem: ClickHouse nie startuje

**Symptomy:**
```bash
$ docker-compose ps
clickhouse   Exit 1
```

**Diagnoza:**
```bash
# Sprawdź logi
docker-compose logs clickhouse

# Typowe błędy:
# - "Cannot allocate memory"
# - "Permission denied"
# - "Port 8123 already in use"
```

**Rozwiązania:**

#### A) Brak pamięci
```bash
# Sprawdź dostępną RAM
free -h

# Zmniejsz limity w docker-compose.yml
services:
  clickhouse:
    mem_limit: 2g  # Zamiast 4g
```

#### B) Problemy z uprawnieniami
```bash
# Upewnij się że katalog istnieje
sudo mkdir -p /opt/iot-honeynet/data/clickhouse

# Ustaw właściciela (ClickHouse działa jako UID 101)
sudo chown -R 101:101 /opt/iot-honeynet/data/clickhouse
```

#### C) Port zajęty
```bash
# Sprawdź co używa portu 8123
sudo lsof -i :8123

# Jeśli coś konfliktuje, zmień port w docker-compose.yml
ports:
  - "127.0.0.1:8124:8123"  # Użyj 8124 zamiast 8123
```

---

### Problem: Suricata dropuje pakiety (packet loss)

**Symptomy:**
```bash
$ docker exec suricata suricata -c /etc/suricata/suricata.yaml --dump-config | grep drop
capture.kernel_drops: 15234
```

**Rozwiązanie:**

1. **Zwiększ ring-size w suricata.yaml:**
```yaml
af-packet:
  - interface: eth0
    ring-size: 8192      # Zamiast 4096
    buffer-size: 65536   # Zamiast 32768
```

2. **Dodaj więcej wątków:**
```yaml
threading:
  worker-cpu-set:
    cpu: [ 1,2,3,4 ]  # Więcej CPU
```

3. **Restart:**
```bash
docker-compose restart suricata
```

---

## 🟡 Problemy średnie

### Problem: Logstash lag (opóźnienie 30+ minut)

**Diagnoza:**
```bash
# Sprawdź statystyki pipeline
docker exec logstash curl -s localhost:9600/_node/stats/pipeline | jq '.pipelines'

# Szukaj:
# - queue.events (jeśli > 10000 = backlog)
# - pipeline.workers (jeśli = 1 = bottleneck)
```

**Rozwiązanie:**

1. **Zwiększ workery w pipelines.yml:**
```yaml
- pipeline.id: cowrie
  pipeline.workers: 4  # Zamiast 2
  pipeline.batch.size: 500  # Zamiast 250
```

2. **Zwiększ heap Logstash:**
```bash
# W .env
LS_JAVA_OPTS=-Xmx4g -Xms4g  # Zamiast 2g
```

3. **Restart:**
```bash
docker-compose restart logstash
```

---

### Problem: Grafana nie łączy się z ClickHouse

**Symptomy:**
```
Error: clickhouse: connection refused
```

**Rozwiązania:**

#### A) ClickHouse nie startował
```bash
# Sprawdź czy działa
docker-compose ps clickhouse

# Jeśli nie, sprawdź logi
docker-compose logs clickhouse
```

#### B) Błędne hasło
```bash
# Sprawdź czy hasło w .env zgadza się z datasources.yml
grep CLICKHOUSE_PASSWORD .env
grep password configs/grafana/datasources.yml
```

#### C) Network problem
```bash
# Sprawdź czy kontenery są w tej samej sieci
docker network inspect honeynet_management_net

# Oba powinny być listowane
```

---

### Problem: Cowrie nie loguje sesji

**Diagnoza:**
```bash
# Sprawdź logi Cowrie
docker-compose logs cowrie

# Sprawdź czy pliki są tworzone
docker exec cowrie ls -lh /cowrie/var/log/cowrie/
```

**Rozwiązania:**

#### A) Problem z volume mounts
```bash
# Sprawdź czy katalog istnieje
ls -lh data/cowrie/

# Jeśli nie, utwórz
mkdir -p data/cowrie
```

#### B) Brak połączeń
```bash
# Sprawdź czy port 22 jest otwarty
nc -zv localhost 22

# Sprawdź iptables
sudo iptables -L -n | grep 22
```

---

## 🟢 Problemy drobne

### Problem: Brak danych GeoIP

**Symptomy:** `country_code` zawsze puste

**Rozwiązanie:**
```bash
# Pobierz bazę GeoIP
cd /opt/iot-honeynet
wget https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-Country.mmdb

# Umieść w configs/
mv GeoLite2-Country.mmdb configs/geoip/

# Restart Logstash
docker-compose restart logstash
```

---

### Problem: Docker zajmuje za dużo miejsca

**Diagnoza:**
```bash
# Sprawdź wykorzystanie
docker system df

# Przykład:
# Images: 15GB
# Containers: 2GB
# Volumes: 50GB
# Build Cache: 10GB
```

**Rozwiązanie:**
```bash
# Usuń nieużywane obrazy
docker image prune -a

# Usuń nieużywane volumeny
docker volume prune

# Usuń build cache
docker builder prune

# Lub wszystko naraz
docker system prune -a --volumes

# UWAGA: To NIE usunie volumes montowanych w docker-compose.yml
```

---

### Problem: Make command not found

**Symptomy:**
```bash
$ make up
bash: make: command not found
```

**Rozwiązanie:**
```bash
# Ubuntu/Debian
sudo apt install make

# Lub użyj docker-compose bezpośrednio
docker-compose up -d
```

---

## 📊 Diagnostyka ogólna

### Health check kompletny
```bash
#!/bin/bash
# Comprehensive health check

echo "=== Docker Status ==="
systemctl status docker

echo -e "\n=== Containers ==="
docker-compose ps

echo -e "\n=== Disk Space ==="
df -h /opt/iot-honeynet

echo -e "\n=== Memory ==="
free -h

echo -e "\n=== ClickHouse Stats ==="
docker exec clickhouse clickhouse-client --query="
SELECT 
    database,
    table,
    formatReadableSize(sum(bytes_on_disk)) as size,
    count() as parts
FROM system.parts
WHERE active
GROUP BY database, table
"

echo -e "\n=== Recent Errors ==="
docker-compose logs --tail=50 | grep -i error

echo -e "\n=== Network Isolation Test ==="
python3 tests/test_isolation.py
```

Zapisz jako `scripts/monitoring/full_diagnostic.sh` i uruchom:
```bash
chmod +x scripts/monitoring/full_diagnostic.sh
./scripts/monitoring/full_diagnostic.sh
```

---

## 🆘 Gdy nic nie działa

### Nuclear option - reset kompletny

⚠️ **UWAGA:** To usunie WSZYSTKIE zebrane dane!
```bash
# 1. Stop wszystkiego
docker-compose down -v

# 2. Usuń dane
sudo rm -rf data/*

# 3. Usuń obrazy
docker-compose down --rmi all

# 4. Cleanup Docker
docker system prune -a --volumes -f

# 5. Fresh start
docker-compose pull
docker-compose up -d

# 6. Weryfikacja
make test-all
```

---

## 📞 Dalsze wsparcie

Jeśli problem nadal występuje:

1. **Zbierz informacje:**
```bash
# System info
uname -a
docker --version
docker-compose --version

# Logi
docker-compose logs > logs.txt

# Config
cat docker-compose.yml > config.txt
```

2. **Otwórz issue:** https://github.com/m1szk4/HoneyNet/issues

3. **Dołącz:**
   - Opis problemu
   - Kroki do reprodukcji
   - Logi
   - System info

4. **Email:** michalkrolkontakt@gmail.com