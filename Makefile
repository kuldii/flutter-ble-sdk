.PHONY: help get clean analyze format test coverage build pub-publish

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

get: ## Get dependencies
	@echo "📦 Getting dependencies..."
	@flutter pub get
	@cd example && flutter pub get

clean: ## Clean build artifacts
	@echo "🧹 Cleaning project..."
	@./scripts/clean.sh

analyze: ## Analyze code for issues
	@echo "🔍 Analyzing code..."
	@./scripts/analyze.sh

format: ## Format Dart code
	@echo "🎨 Formatting code..."
	@./scripts/format.sh

test: ## Run all tests
	@echo "🧪 Running tests..."
	@./scripts/test.sh

coverage: ## Generate test coverage report
	@echo "📊 Generating coverage report..."
	@./scripts/generate_coverage.sh
	@echo ""
	@echo "✅ Coverage report generated at: coverage/html/index.html"

check: format analyze test ## Format, analyze and test

build: clean get ## Clean and get dependencies
	@echo "🔨 Building project..."
	@flutter build apk --release || echo "⚠️  Build requires Android SDK"

pub-dry-run: ## Dry run publish to pub.dev
	@echo "🚀 Testing package publication..."
	@flutter pub publish --dry-run

pub-publish: ## Publish to pub.dev
	@echo "⚠️  WARNING: This will publish to pub.dev!"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read
	@flutter pub publish

dev: ## Setup development environment
	@echo "🛠️  Setting up development environment..."
	@make get
	@make format
	@make analyze
	@echo "✅ Development environment ready!"

ci: ## Run CI checks (format, analyze, test, coverage)
	@echo "🤖 Running CI checks..."
	@make format
	@make analyze
	@make test
	@make coverage
	@echo "✅ All CI checks passed!"
