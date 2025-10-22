# Contributing to IoT Honeynet

Dziękujemy za zainteresowanie projektem! 🎉

## 🤝 Jak kontrybuować?

### Zgłaszanie bugów

Jeśli znalazłeś bug:

1. Sprawdź, czy [issue już istnieje](https://github.com/m1szk4/HoneyNet/issues).
2. Jeśli nie, utwórz nowe issue z tagiem `bug`.
3. Opisz:
   - Kroki do reprodukcji
   - Oczekiwane zachowanie
   - Aktualne zachowanie
   - Zrzuty ekranu (jeśli dotyczy)
   - Środowisko (OS, Docker version, itp.)

### Propozycje nowych funkcji

1. Otwórz issue z tagiem `enhancement`.
2. Opisz:
   - Problem, który funkcja rozwiązuje
   - Proponowane rozwiązanie
   - Alternatywy, które rozważałeś

### Pull Requests

#### Workflow

1. **Fork** repozytorium.
2. **Clone** swojego forka:
   ```bash
   git clone https://github.com/YOUR_USERNAME/HoneyNet.git
   cd HoneyNet
   ```
3. **Utwórz branch** dla swojej zmiany:
   ```bash
   git checkout -b feature/your-feature-name
   # lub
   git checkout -b fix/bug-description
   ```
4. **Commit** z jasnym opisem:
   ```bash
   git commit -m "feat: add new honeypot for MQTT protocol"
   # lub
   git commit -m "fix: clickhouse connection timeout"
   ```
5. **Push** do swojego forka:
   ```bash
   git push origin feature/your-feature-name
   ```
6. **Otwórz Pull Request** na GitHub.

#### Konwencje commit messages

Używamy [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` nowa funkcjonalność
- `fix:` naprawa buga
- `docs:` zmiany w dokumentacji
- `style:` formatowanie, brakujące średniki (bez zmian w logice)
- `refactor:` refaktoryzacja kodu
- `test:` dodanie testów
- `chore:` zmiany w build process, dependencies

**Przykłady:**
```
feat: add support for MQTT honeypot
fix: resolve ClickHouse memory leak in aggregations
docs: update installation instructions for Ubuntu 24.04
test: add integration tests for Logstash pipelines
```

#### Wymagania dla PR

- [ ] Kod jest przetestowany (dodaj testy, jeśli to możliwe)
- [ ] Dokumentacja jest zaktualizowana
- [ ] Commit messages są zgodne z konwencją
- [ ] Branch jest aktualny z `main`
- [ ] CI/CD przechodzi (jeśli skonfigurowane)

---

### Rozwój lokalny

#### Setup środowiska deweloperskiego

1. Zainstaluj zależności:
   ```bash
   pip3 install -r requirements.txt
   ```
2. Skopiuj i uzupełnij `.env`:
   ```bash
   cp .env.example .env
   nano .env
   ```
3. Uruchom w trybie dev:
   ```bash
   docker compose up -d
   # lub: docker-compose up -d
   ```
4. Sprawdź logi:
   ```bash
   make logs
   ```
5. Uruchom testy:
   ```bash
   make test-all
   ```

#### Testowanie zmian

Przed wysłaniem PR uruchom:
```bash
# Testy izolacji (krytyczne)
make test-isolation

# Testy reguł IDS
make test-rules

# End-to-end
python3 tests/test_e2e.py
```

---

### Code Style

#### Python
- PEP 8
- Type hints
- Docstrings dla funkcji publicznych

```python
import hmac
import hashlib

def anonymize_ip(ip_address: str, salt: str) -> str:
    """
    Anonymize IP address using HMAC-SHA256.

    Args:
        ip_address: IP address to anonymize
        salt: Secret salt for HMAC

    Returns:
        64-character hex string.

    Example:
        >>> anonymize_ip("192.168.1.1", "secret_salt")[:8]
        'a3b4c5d6'
    """
    return hmac.new(salt.encode(), ip_address.encode(), hashlib.sha256).hexdigest()
```

#### Bash
- Shebang: `#!/bin/bash`
- `set -euo pipefail` dla skryptów produkcyjnych
- Komentarze przy złożonych operacjach

#### YAML/JSON
- Indentacja: 2 spacje
- Spójne formatowanie

---

### Dodawanie nowych honeypotów

Jeśli dodajesz nowy honeypot:

1. **Dodaj do `docker-compose.yml`:**
   ```yaml
   your_honeypot:
     image: your/honeypot:latest
     container_name: your_honeypot
     networks:
       honeypot_net:
         ipv4_address: 172.20.0.XX
     ports:
       - "PORT:PORT"
     volumes:
       - ./configs/your_honeypot:/etc/your_honeypot:ro
       - ./data/your_honeypot:/var/log/your_honeypot
     restart: unless-stopped
   ```
2. **Dodaj konfigurację** w `configs/your_honeypot/`.
3. **Dodaj pipeline Logstash** w `configs/logstash/pipelines/your_honeypot.conf`.
4. **Zaktualizuj dokumentację** w `README.md` i `docs/`.
5. **Dodaj testy** w `tests/`.

---

### Dodawanie nowych reguł IDS

Reguły Suricata w `configs/suricata/rules/iot-botnet.rules`:

**Template:**
```conf
alert tcp $EXTERNAL_NET any -> $HOME_NET PORT (
  msg:"IoT Attack - Description";
  flow:to_server,established;
  content:"pattern";
  metadata:mitre_technique_id TXXXX;
  classtype:attempted-user;
  sid:5000XXX; rev:1;
)
```

**Wymagania:**
- Unikalny SID (`5000001–5999999` dla custom rules)
- Tag MITRE ATT&CK w `metadata`
- Testowy PCAP w `tests/fixtures/`

---

## 📝 Licencja

Kontrybuując do projektu, zgadzasz się, że Twój kod będzie licencjonowany na licencji MIT.

## ❓ Pytania?

Otwórz [issue](https://github.com/m1szk4/HoneyNet/issues) lub napisz email: michalkrolkontakt@gmail.com

## 🙏 Podziękowania

Dziękujemy wszystkim kontrybutorom:
- [Lista kontrybutorów](https://github.com/m1szk4/HoneyNet/contributors)
