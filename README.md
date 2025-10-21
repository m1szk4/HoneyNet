# IoT Honeynet - Inżynierska Praca Dyplomowa

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-24.0+-blue.svg)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/Python-3.11+-green.svg)](https://www.python.org/)

> **Honeynet do analizy ataków na urządzenia IoT: projekt i wnioski dla IDS**  
> Engineering Thesis - Computer Science

## 📋 Opis projektu

Repozytorium zawiera kompletną implementację honeynetu dedykowanego dla urządzeń IoT, służącego do:
- Zbierania rzeczywistych prób ataków na urządzenia IoT
- Klasyfikacji ataków według frameworku MITRE ATT&CK
- Opracowania reguł IDS (Suricata) dostosowanych do zagrożeń IoT w regionie CEE

## 🏗️ Architektura
```
Internet → Firewall → Honeypots (Cowrie, Dionaea, Conpot)
                    ↓
              IDS Layer (Suricata, Zeek)
                    ↓
              ETL Pipeline (Logstash)
                    ↓
           Storage (ClickHouse) → Visualization (Grafana)
```

## 🚀 Quick Start

### Wymagania

- Ubuntu 22.04 LTS (lub nowszy)
- Docker 24.0+ i Docker Compose v2
- Minimum 4 vCPU, 8 GB RAM, 200 GB SSD
- Publiczny adres IPv4

### Deployment
```bash
# 1. Sklonuj repozytorium
git https://github.com/m1szk4/HoneyNet.git
cd HoneyNet

# 2. Skopiuj i skonfiguruj zmienne środowiskowe
cp .env.example .env
nano .env  # Uzupełnij passwords, API keys

# 3. Uruchom Ansible playbooks (setup środowiska)
cd ansible
ansible-playbook -i inventory/hosts playbooks/00-hardening.yml
ansible-playbook -i inventory/hosts playbooks/01-docker-install.yml

# 4. Deploy honeynetu
cd ..
docker-compose up -d

# 5. Weryfikacja
docker-compose ps
./scripts/deployment/test-isolation.sh
```

## 📊 Komponenty

| Komponent | Opis | Port |
|-----------|------|------|
| **Cowrie** | SSH/Telnet honeypot | 22, 23, 2323 |
| **Dionaea** | Multi-protocol honeypot (SMB, HTTP, FTP) | 80, 445, 21 |
| **Conpot** | ICS/SCADA honeypot (Modbus, BACnet) | 502, 47808 |
| **Suricata** | Network IDS | - |
| **Zeek** | Network Security Monitor | - |
| **ClickHouse** | OLAP Database | 8123 |
| **Grafana** | Dashboards | 3000 |

## 🎯 MITRE ATT&CK Coverage

Projekt mapuje zaobserwowane ataki do **28 technik MITRE ATT&CK**:
- 21 technik z ATT&CK for Enterprise
- 7 technik z ATT&CK for ICS

Zobacz: [docs/mitre-attack-mapping.md](docs/mitre-attack-mapping.md)

## 🛡️ Reguły IDS

Repozytorium zawiera **10+ custom reguł Suricata** dla ataków IoT:
- Mirai botnet detection
- Brute-force SSH/Telnet
- HTTP exploit attempts (ShellShock, CGI)
- RTSP camera exploits
- UPnP abuse

Zobacz: [configs/suricata/rules/iot-botnet.rules](configs/suricata/rules/iot-botnet.rules)

## 📁 Struktura projektu
```
HoneyNet/
├── ansible/           # Infrastructure as Code
├── configs/           # Konfiguracje wszystkich komponentów
├── data/              # Persistent storage (nie w Git)
├── docs/              # Dokumentacja projektu
├── scripts/           # Skrypty maintenance i ETL
├── tests/             # Testy integracyjne
├── docker-compose.yml # Główna orkiestracja
└── .env.example       # Template zmiennych środowiskowych
```

## 📖 Dokumentacja

- [Przewodnik instalacji](docs/installation.md)
- [Konfiguracja zaawansowana](docs/advanced-config.md)
- [Bezpieczeństwo i hardening](docs/security.md)
- [Analiza danych](docs/data-analysis.md)
- [DPIA (RODO Compliance)](docs/dpia.md)

## 🔒 Bezpieczeństwo

⚠️ **WAŻNE:** Ten honeynet jest celowo podatny na ataki. **NIE URUCHAMIAJ** w sieci produkcyjnej!

- Wszystkie honeypoty są izolowane w DMZ
- Brak komunikacji outbound (data control)
- Anonimizacja danych zgodna z RODO
- Monitoring i alerting 24/7

Zobacz: [SECURITY.md](SECURITY.md)

## 📊 Wyniki badań

W trakcie 45-dniowego okresu ekspozycji zebrano:
- **X,XXX,XXX** zdarzeń bezpieczeństwa
- **XX,XXX** unikalnych adresów IP źródłowych
- **XXX** zidentyfikowanych kampanii atakujących
- Pokrycie **XX/28** technik MITRE ATT&CK

*Pełne wyniki w pracy dyplomowej (link TBD)*

## 📝 Cytowanie

Jeśli używasz tego projektu w swojej pracy badawczej, proszę cytuj:
```bibtex
@mastersthesis{HoneyNet-2025,
  author = {Michał Król},
  title = {Honeynet do analizy ataków na urządzenia IoT: projekt i wnioski dla IDS},
  school = {Uczelnia Techniczno-Handlowa im. Heleny Chodkowskiej},
  year = {2025},
  type = {Praca inżynierska},
  url = {https://github.com/m1szk4/HoneyNet.git}
}
```

## 🤝 Wkład (Contributing)

Projekt jest open-source! Zapraszamy do:
- Zgłaszania issues
- Pull requests z ulepszeniami
- Dzielenia się wynikami z własnych deploymentów

## 📄 Licencja

MIT License - zobacz [LICENSE](LICENSE) dla szczegółów.

## 👥 Autorzy

-  *Michał Król* - [GitHub](https://github.com/m1szk4)
-  *Dr. Inż Tomasz Bartczak*

## 🙏 Podziękowania

- [The Honeynet Project](https://www.honeynet.org/)
- [MITRE ATT&CK](https://attack.mitre.org/)
- [Suricata](https://suricata.io/)
- [Zeek](https://zeek.org/)

## 📧 Kontakt

Pytania? Otwórz [Issue](https://github.com/m1szk4/HoneyNet/issues) lub napisz: michalkrolkontakt@gmail.com

---

**⚠️ Disclaimer:** Ten projekt jest prowadzony wyłącznie w celach badawczych i edukacyjnych. Autor nie ponosi odpowiedzialności za niewłaściwe użycie oprogramowania.
