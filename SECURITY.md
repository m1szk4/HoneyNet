# Security Policy

## ⚠️ Important Security Notice

This project is a **research honeypot** intentionally designed to attract and log malicious activity. 

**DO NOT:**
- Deploy in production networks
- Use in networks containing sensitive data
- Expose management interfaces publicly
- Disable data control mechanisms

## Reporting Security Issues

If you discover a security vulnerability in the honeypot infrastructure itself (not captured attacks), please report it via:

1. Open a **private security advisory** on GitHub
2. Or email: michalkrolkontakt@gmail.com

**Do not** open public issues for security vulnerabilities.

## Security Best Practices

### Before Deployment

- [ ] Change ALL default passwords in `.env`
- [ ] Generate strong `ANON_SECRET_KEY` (min 32 chars)
- [ ] Restrict SSH access to management IPs only
- [ ] Enable firewall rules (run `scripts/deployment/setup-firewall.sh`)
- [ ] Test network isolation (`scripts/deployment/test-isolation.sh`)

### During Operation

- [ ] Monitor alerts (Discord/Email)
- [ ] Review logs weekly for anomalies
- [ ] Update honeypot images monthly
- [ ] Backup configurations daily
- [ ] Check AIDE integrity reports

### Data Handling

- [ ] Anonymize IPs before sharing data
- [ ] DO NOT publish raw logs containing PII
- [ ] Follow GDPR/RODO guidelines (see docs/dpia.md)
- [ ] Encrypt backups

## Compliance

This project implements:
- RODO/GDPR data anonymization
- Data Protection Impact Assessment (DPIA)
- 90-day data retention policy
- Automated IP anonymization with weekly salt rotation

See [docs/dpia.md](docs/dpia.md) for full compliance documentation.