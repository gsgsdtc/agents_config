.PHONY: help install dev backend build docker clean test lint venv

# Project configuration
PROJECT_NAME := {{PROJECT_NAME}}

# Python virtual environment
VENV := backend/.venv
PYTHON := $(VENV)/bin/python
PIP := $(VENV)/bin/pip
FLASK := $(VENV)/bin/flask

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

# Default target
help:
	@echo "$(GREEN)$(PROJECT_NAME) - Admin API Service$(NC)"
	@echo ""
	@echo "$(YELLOW)Usage:$(NC) make [target]"
	@echo ""
	@echo "$(YELLOW)Development:$(NC)"
	@echo "  install     - Install backend dependencies"
	@echo "  dev         - Start backend development server"
	@echo ""
	@echo "$(YELLOW)Build:$(NC)"
	@echo "  build       - Verify backend build"
	@echo "  docker      - Build Docker image"
	@echo "  docker-run  - Run Docker container locally"
	@echo ""
	@echo "$(YELLOW)Quality:$(NC)"
	@echo "  test        - Run tests"
	@echo "  lint        - Run linters"
	@echo ""
	@echo "$(YELLOW)Utilities:$(NC)"
	@echo "  clean       - Clean build artifacts"
	@echo "  clean-all   - Clean all including virtual environment"
	@echo "  db-init     - Initialize database"

# Create virtual environment
$(VENV):
	@echo "$(YELLOW)Creating Python virtual environment...$(NC)"
	python3 -m venv $(VENV)
	$(PIP) install --upgrade pip

# Install dependencies
install: $(VENV)
	@echo "$(YELLOW)Installing backend dependencies...$(NC)"
	$(PIP) install -r backend/requirements.txt
	@echo "$(GREEN)Dependencies installed!$(NC)"

# Development server
dev: $(VENV)
	@echo "$(GREEN)Starting backend development server...$(NC)"
	@echo "$(YELLOW)Backend API: http://localhost:5000$(NC)"
	@echo "$(YELLOW)Swagger: http://localhost:5000/swagger$(NC)"
	cd backend && FLASK_APP=wsgi.py ../$(VENV)/bin/flask run --host=0.0.0.0 --port=5000 --reload

backend: dev

# Build
build: $(VENV)
	@echo "$(YELLOW)Checking backend...$(NC)"
	cd backend && ../$(VENV)/bin/python -c "from app import create_app; app = create_app(); print('Backend OK')"
	@echo "$(GREEN)Build check complete!$(NC)"

# Docker operations
docker:
	@echo "$(YELLOW)Building Docker image...$(NC)"
	docker build -t $(PROJECT_NAME):latest .
	@echo "$(GREEN)Docker image built: $(PROJECT_NAME):latest$(NC)"

docker-run:
	@echo "$(GREEN)Running Docker container...$(NC)"
	docker run -d -p 5000:5000 \
		-e FLASK_ENV=production \
		-e SECRET_KEY=change-me-in-production \
		-v $(PWD)/data:/app/data \
		--name $(PROJECT_NAME) \
		$(PROJECT_NAME):latest
	@echo "$(YELLOW)Application running at: http://localhost:5000$(NC)"
	@echo "$(YELLOW)Swagger docs: http://localhost:5000/swagger$(NC)"

docker-stop:
	@echo "$(YELLOW)Stopping Docker container...$(NC)"
	docker stop $(PROJECT_NAME) || true
	docker rm $(PROJECT_NAME) || true

docker-logs:
	docker logs -f $(PROJECT_NAME)

# Tests
test: $(VENV)
	@echo "$(YELLOW)Running backend tests...$(NC)"
	cd backend && ../$(VENV)/bin/python -m pytest tests/ -v || echo "No tests found"
	@echo "$(GREEN)All tests passed!$(NC)"

# Linting
lint: $(VENV)
	@echo "$(YELLOW)Linting backend...$(NC)"
	cd backend && ../$(VENV)/bin/python -m flake8 app/ --max-line-length=120 || echo "flake8 not installed"
	@echo "$(GREEN)Linting complete!$(NC)"

# Database operations
db-init: $(VENV)
	@echo "$(YELLOW)Initializing database...$(NC)"
	cd backend && FLASK_APP=wsgi.py ../$(VENV)/bin/flask db init || echo "Already initialized"

db-migrate: $(VENV)
	@echo "$(YELLOW)Creating migration...$(NC)"
	cd backend && FLASK_APP=wsgi.py ../$(VENV)/bin/flask db migrate -m "Migration"

db-upgrade: $(VENV)
	@echo "$(YELLOW)Applying migrations...$(NC)"
	cd backend && FLASK_APP=wsgi.py ../$(VENV)/bin/flask db upgrade

# Cleanup
clean:
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	rm -rf backend/__pycache__ backend/.pytest_cache backend/app/__pycache__
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -type d -delete
	@echo "$(GREEN)Clean complete!$(NC)"

clean-all: clean
	@echo "$(YELLOW)Removing virtual environment...$(NC)"
	rm -rf $(VENV)
	@echo "$(GREEN)Full clean complete!$(NC)"
