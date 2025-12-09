# Development Scripts

This directory contains helper scripts for development and maintenance of the KGiTON BLE SDK.

## Available Scripts

### 🧪 Testing & Coverage

#### `test.sh`
Runs all unit tests.

```bash
./scripts/test.sh
```

#### `generate_coverage.sh`
Runs tests with coverage and generates HTML report.

```bash
./scripts/generate_coverage.sh
```

The coverage report will be available at `coverage/html/index.html`.

### 🔍 Code Quality

#### `analyze.sh`
Analyzes the codebase for issues and warnings.

```bash
./scripts/analyze.sh
```

#### `format.sh`
Formats all Dart code according to Dart style guidelines.

```bash
./scripts/format.sh
```

### 🧹 Maintenance

#### `clean.sh`
Cleans build artifacts and cache files.

```bash
./scripts/clean.sh
```

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (included with Flutter)
- lcov (for coverage reports)
  ```bash
  brew install lcov  # macOS
  ```

## Development Workflow

1. **Before committing:**
   ```bash
   ./scripts/format.sh
   ./scripts/analyze.sh
   ./scripts/test.sh
   ```

2. **Generate coverage report:**
   ```bash
   ./scripts/generate_coverage.sh
   ```

3. **Clean project:**
   ```bash
   ./scripts/clean.sh
   flutter pub get
   ```

## Continuous Integration

These scripts can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Run tests
  run: ./scripts/test.sh

- name: Analyze code
  run: ./scripts/analyze.sh

- name: Generate coverage
  run: ./scripts/generate_coverage.sh
```

## Script Permissions

All scripts are executable. If needed, run:

```bash
chmod +x scripts/*.sh
```
