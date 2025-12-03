# Contributing Guidelines

## ⚠️ Proprietary Software Notice

This is **proprietary software** owned by PT KGiTON. This repository does not accept external contributions.

## For PT KGiTON Internal Developers

### Repository Access

This repository is private and restricted to authorized PT KGiTON developers only.

### Development Workflow

1. **Clone Repository**
   ```bash
   git clone https://github.com/kuldii/flutter-ble-sdk.git
   cd flutter-ble-sdk
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Changes**
   - Follow Dart/Flutter style guide
   - Update documentation as needed
   - Test on real devices

4. **Commit Changes**
   ```bash
   git add .
   git commit -m "feat: description of changes"
   ```

5. **Push to Repository**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create Pull Request**
   - Request review from team lead
   - Address review comments
   - Merge after approval

### Commit Message Convention

Use conventional commits format:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting)
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

**Example:**
```
feat: add iOS CoreBluetooth implementation
fix: resolve Android connection timeout issue
docs: update API documentation for setNotify method
```

### Code Standards

- **Dart**: Follow effective Dart guidelines
- **Kotlin**: Follow Kotlin coding conventions
- **Swift**: Follow Swift API design guidelines
- **Comments**: Document all public APIs
- **Tests**: Add tests for new features

### Testing Requirements

Before committing:
1. Run `flutter analyze` - No errors
2. Run `flutter format .` - Code formatted
3. Test on Android device - Working
4. Test on iOS device - Working (when implemented)
5. Update example app if needed

### Documentation Requirements

Update documentation for:
- New features → README.md + API docs
- Bug fixes → CHANGELOG.md
- Breaking changes → CHANGELOG.md + Migration guide

## External Contributors

This is closed-source software. External contributions are not accepted.

For bug reports or feature requests from authorized users:
- Email: support@kgiton.com
- Include your license ID

## Questions?

Contact the development team:
- Technical Lead: support@kgiton.com
- Support: support@kgiton.com

---

© 2025 PT KGiTON - All Rights Reserved
