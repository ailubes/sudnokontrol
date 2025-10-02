#!/bin/bash

# ================================
# Development Environment Deployment Script
# ================================

set -e

echo "🚀 Starting development environment deployment..."

# Configuration
DEV_DIR="/var/www/sudnokontrol.online/environments/development"
BACKEND_DIR="$DEV_DIR/backend/backend"
FRONTEND_DIR="$DEV_DIR/frontend"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root or with sudo"
   exit 1
fi

# Function to stop existing processes
stop_development_processes() {
    print_status "Stopping existing development processes..."

    # Stop development backend (port 3030)
    pkill -f "PORT=3030" || true
    pkill -f "node.*development.*3030" || true

    # Stop development frontend (port 8080)
    pkill -f "PORT=8080" || true
    pkill -f "next.*dev.*8080" || true

    print_success "Existing processes stopped"
}

# Function to update codebase
update_codebase() {
    print_status "Skipping codebase overwrite - preserving development work..."
    print_warning "Development files preserved. Use 'reset-dev' command to sync from production if needed."
    print_success "Development codebase preserved"
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing backend dependencies..."
    cd $BACKEND_DIR
    npm install

    print_status "Installing frontend dependencies..."
    cd $FRONTEND_DIR
    npm install --legacy-peer-deps

    print_success "Dependencies installed"
}

# Function to build applications
build_applications() {
    print_status "Building backend..."
    cd $BACKEND_DIR
    npm run build

    print_status "Building frontend..."
    cd $FRONTEND_DIR
    npm run build

    print_success "Applications built"
}

# Function to start applications
start_applications() {
    print_status "Starting development backend on port 3030..."
    cd $BACKEND_DIR
    nohup npm run dev > /tmp/dev-backend.log 2>&1 &

    print_status "Starting development frontend on port 8080..."
    cd $FRONTEND_DIR
    nohup npm run dev > /tmp/dev-frontend.log 2>&1 &

    print_success "Applications started"
}

# Function to verify deployment
verify_deployment() {
    print_status "Verifying development deployment..."

    sleep 10

    # Check backend health
    if curl -sSf http://localhost:3030/health > /dev/null; then
        print_success "Backend is healthy"
    else
        print_error "Backend health check failed"
        return 1
    fi

    # Check frontend
    if curl -sSf http://localhost:8080/ > /dev/null; then
        print_success "Frontend is responding"
    else
        print_warning "Frontend might still be starting up"
    fi

    print_success "Development environment is running!"
    print_status "Frontend: https://dev.sudnokontrol.online"
    print_status "Backend API: https://api-dev.sudnokontrol.online"
    print_status "Backend logs: tail -f /tmp/dev-backend.log"
    print_status "Frontend logs: tail -f /tmp/dev-frontend.log"
}

# Main deployment process
main() {
    print_status "Starting development deployment at $(date)"

    stop_development_processes
    update_codebase
    install_dependencies
    build_applications
    start_applications
    verify_deployment

    print_success "✅ Development deployment completed successfully!"
}

# Function to reset development from production
reset_development() {
    print_status "Resetting development environment from production..."

    # Copy latest code from main directories
    # IMPORTANT: Exclude .env files to preserve environment-specific configuration
    rsync -av --exclude=node_modules --exclude=.next --exclude=dist --exclude=.env --exclude=.env.local --exclude=.env.production --exclude=.env.development /var/www/sudnokontrol.online/frontend/ $FRONTEND_DIR/
    rsync -av --exclude=node_modules --exclude=dist --exclude=.env --exclude=.env.local --exclude=.env.production --exclude=.env.development /var/www/sudnokontrol.online/backend/ $DEV_DIR/backend/

    print_success "Development environment reset from production"
    print_warning "Note: .env files preserved - development environment configuration unchanged"
}

# Function to deploy development to production
deploy_to_production() {
    print_status "Deploying development changes to production..."

    # Copy development code to production directories
    # IMPORTANT: Exclude .env files to preserve environment-specific configuration
    rsync -av --exclude=node_modules --exclude=.next --exclude=dist --exclude=.env --exclude=.env.local --exclude=.env.production --exclude=.env.development $FRONTEND_DIR/ /var/www/sudnokontrol.online/frontend/
    rsync -av --exclude=node_modules --exclude=dist --exclude=.env --exclude=.env.local --exclude=.env.production --exclude=.env.development $DEV_DIR/backend/ /var/www/sudnokontrol.online/backend/

    print_success "Development changes deployed to production source"
    print_warning "Note: .env files preserved - production environment configuration unchanged"

    # Install production dependencies
    print_status "Installing production backend dependencies..."
    cd /var/www/sudnokontrol.online/backend/backend
    npm install

    print_status "Installing production frontend dependencies..."
    cd /var/www/sudnokontrol.online/frontend
    npm install --legacy-peer-deps

    print_success "Dependencies installed"

    # Build production applications
    print_status "Building production backend..."
    cd /var/www/sudnokontrol.online/backend/backend
    npm run build

    print_status "Building production frontend..."
    cd /var/www/sudnokontrol.online/frontend
    npm run build

    print_success "Production build completed"
    print_status "You can now restart production environment"
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "stop")
        stop_development_processes
        ;;
    "restart")
        stop_development_processes
        sleep 5
        start_applications
        verify_deployment
        ;;
    "reset-dev")
        stop_development_processes
        reset_development
        install_dependencies
        build_applications
        start_applications
        verify_deployment
        ;;
    "deploy-to-prod")
        deploy_to_production
        ;;
    "logs")
        echo "Backend logs:"
        tail -f /tmp/dev-backend.log &
        echo "Frontend logs:"
        tail -f /tmp/dev-frontend.log
        ;;
    "status")
        echo "Development process status:"
        ps aux | grep -E "(PORT=3030|PORT=8080)" | grep -v grep || echo "No development processes running"
        ;;
    *)
        echo "Usage: $0 {deploy|stop|restart|reset-dev|deploy-to-prod|logs|status}"
        echo "  deploy        - Start development (preserve existing code)"
        echo "  stop          - Stop development processes"
        echo "  restart       - Restart development processes"
        echo "  reset-dev     - Reset development from production source"
        echo "  deploy-to-prod - Deploy development changes to production source"
        echo "  logs          - Show development logs"
        echo "  status        - Show process status"
        exit 1
        ;;
esac