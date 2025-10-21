# Contributing to IoT Honeynet

Thank you for your interest in contributing! 🎉

## Ways to Contribute

### 1. Report Bugs
Open an issue with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, Docker version)

### 2. Suggest Enhancements
- New honeypot configurations
- Additional IDS rules
- Performance optimizations
- Documentation improvements

### 3. Submit Pull Requests

#### Before submitting:
- Test your changes thoroughly
- Follow existing code style
- Update relevant documentation
- Add tests if applicable

#### PR Process:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Development Setup
```bash
# Clone your fork
git clone https://github.com/m1szk4/HoneyNet.git
cd HoneyNet

# Create .env
cp .env.example .env
# Edit .env with your values

# Run tests
python -m pytest tests/

# Deploy locally
docker-compose up -d
```

## Code Style

- Python: PEP 8
- Bash: ShellCheck compliant
- YAML: 2-space indentation
- Markdown: Standard formatting

## Testing

All changes should include tests:
```bash
# Unit tests
pytest tests/unit/

# Integration tests
pytest tests/integration/

# E2E tests
./scripts/deployment/test-e2e.sh
```

## Questions?

Open an issue or reach out via email.

Thank you for contributing! 🙏