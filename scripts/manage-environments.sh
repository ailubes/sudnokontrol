#!/bin/bash

# ================================
# Multi-Environment Management Script
# ================================

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="/var/www/sudnokontrol.online"

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

# Function to show environment status
show_status() {
    echo "================================"
    echo "📊 SudnoKontrol Environment Status"
    echo "================================"
    echo ""

    # Production status
    echo "🏭 PRODUCTION (Port 8000 Frontend, Port 3000 Backend):"
    echo "   Frontend: https://sudnokontrol.online"
    echo "   API: https://api.sudnokontrol.online"
    if curl -sSf http://localhost:8000/ > /dev/null 2>&1; then
        echo -e "   Status: ${GREEN}✅ Frontend Running${NC}"
    else
        echo -e "   Status: ${RED}❌ Frontend Down${NC}"
    fi
    if curl -sSf http://localhost:3000/health > /dev/null 2>&1; then
        echo -e "   API Status: ${GREEN}✅ Backend Running${NC}"
    else
        echo -e "   API Status: ${RED}❌ Backend Down${NC}"
    fi
    echo ""

    # Development status
    echo "🛠️  DEVELOPMENT (Port 8080 Frontend, Port 3030 Backend):"
    echo "   Frontend: https://dev.sudnokontrol.online"
    echo "   API: https://api-dev.sudnokontrol.online"
    if curl -sSf http://localhost:8080/ > /dev/null 2>&1; then
        echo -e "   Status: ${GREEN}✅ Frontend Running${NC}"
    else
        echo -e "   Status: ${RED}❌ Frontend Down${NC}"
    fi
    if curl -sSf http://localhost:3030/health > /dev/null 2>&1; then
        echo -e "   API Status: ${GREEN}✅ Backend Running${NC}"
    else
        echo -e "   API Status: ${RED}❌ Backend Down${NC}"
    fi
    echo ""

    # Process status
    echo "🔄 Active Processes:"
    ps aux | grep -E "(PORT=3000|PORT=6000|PORT=8080|PORT=3030)" | grep -v grep || echo "   No environment processes found"
    echo ""

    # Database status
    echo "🗄️  Database Status:"
    if PGPASSWORD=sudno123postgres psql -h localhost -U postgres -d sudno_dpsu -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "   Production DB: ${GREEN}✅ Connected${NC}"
    else
        echo -e "   Production DB: ${RED}❌ Connection Failed${NC}"
    fi
    if PGPASSWORD=sudno123postgres psql -h localhost -U postgres -d sudno_dpsu_dev -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "   Development DB: ${GREEN}✅ Connected${NC}"
    else
        echo -e "   Development DB: ${RED}❌ Connection Failed${NC}"
    fi
    echo ""

    # Nginx status
    echo "🌐 Nginx Status:"
    if systemctl is-active --quiet nginx; then
        echo -e "   Nginx: ${GREEN}✅ Active${NC}"
    else
        echo -e "   Nginx: ${RED}❌ Inactive${NC}"
    fi
    echo ""
}

# Function to start production environment
start_production() {
    print_status "Starting production environment..."

    # Stop any existing production processes
    pkill -f "PORT=3000" || true
    pkill -f "PORT=8000" || true

    # Start production backend (port 3000)
    cd $PROJECT_ROOT/backend/backend
    print_status "Starting production backend on port 3000..."
    nohup env NODE_ENV=production PORT=3000 DB_NAME=sudno_dpsu DB_PASSWORD=sudno123postgres npm start > /tmp/prod-backend.log 2>&1 &

    # Start production frontend (port 8000)
    cd $PROJECT_ROOT/frontend
    print_status "Starting production frontend on port 8000..."
    nohup env NODE_ENV=production npm start > /tmp/prod-frontend.log 2>&1 &

    sleep 5
    print_success "Production environment started"
}

# Function to start development environment
start_development() {
    print_status "Starting development environment..."

    # Run development deployment script
    if [ -f "$SCRIPT_DIR/deploy-development.sh" ]; then
        chmod +x "$SCRIPT_DIR/deploy-development.sh"
        "$SCRIPT_DIR/deploy-development.sh" deploy
    else
        print_error "Development deployment script not found"
        exit 1
    fi
}

# Function to stop all environments
stop_all() {
    print_status "Stopping all environments..."

    # Stop all SUDNO processes
    pkill -f "PORT=3000" || true
    pkill -f "PORT=6000" || true
    pkill -f "PORT=8080" || true
    pkill -f "PORT=3030" || true

    # Wait a moment
    sleep 3

    print_success "All environments stopped"
}

# Function to restart environment
restart_environment() {
    local env="$1"
    case "$env" in
        "production"|"prod")
            print_status "Restarting production environment..."
            pkill -f "PORT=3000" || true
            pkill -f "PORT=6000" || true
            sleep 3
            start_production
            ;;
        "development"|"dev")
            print_status "Restarting development environment..."
            pkill -f "PORT=8080" || true
            pkill -f "PORT=3030" || true
            sleep 3
            start_development
            ;;
        *)
            print_error "Unknown environment: $env"
            print_status "Use: production|prod or development|dev"
            exit 1
            ;;
    esac
}

# Function to show logs
show_logs() {
    local env="$1"
    case "$env" in
        "production"|"prod")
            echo "Production logs:"
            echo "Frontend: /tmp/prod-frontend.log"
            echo "Backend: /tmp/prod-backend.log"
            if [ "$2" = "follow" ]; then
                tail -f /tmp/prod-frontend.log /tmp/prod-backend.log
            else
                tail /tmp/prod-frontend.log /tmp/prod-backend.log
            fi
            ;;
        "development"|"dev")
            echo "Development logs:"
            echo "Frontend: /tmp/dev-frontend.log"
            echo "Backend: /tmp/dev-backend.log"
            if [ "$2" = "follow" ]; then
                tail -f /tmp/dev-frontend.log /tmp/dev-backend.log
            else
                tail /tmp/dev-frontend.log /tmp/dev-backend.log
            fi
            ;;
        *)
            print_error "Unknown environment: $env"
            print_status "Use: production|prod or development|dev"
            exit 1
            ;;
    esac
}

# Function to backup database
backup_database() {
    local env="$1"
    local timestamp=$(date +"%Y%m%d_%H%M%S")

    case "$env" in
        "production"|"prod")
            local db_name="sudno_dpsu"
            local backup_file="/tmp/backup_prod_${timestamp}.sql"
            ;;
        "development"|"dev")
            local db_name="sudno_dpsu_dev"
            local backup_file="/tmp/backup_dev_${timestamp}.sql"
            ;;
        *)
            print_error "Unknown environment: $env"
            exit 1
            ;;
    esac

    print_status "Backing up $env database..."
    PGPASSWORD=sudno123postgres pg_dump -h localhost -U postgres $db_name > $backup_file
    print_success "Database backed up to: $backup_file"
}

# Main function
main() {
    local command="$1"
    local env="$2"

    case "$command" in
        "status"|"")
            show_status
            ;;
        "start")
            case "$env" in
                "production"|"prod")
                    start_production
                    ;;
                "development"|"dev")
                    start_development
                    ;;
                "all")
                    start_production
                    start_development
                    ;;
                *)
                    print_error "Please specify environment: production|development|all"
                    exit 1
                    ;;
            esac
            ;;
        "stop")
            if [ "$env" = "all" ] || [ -z "$env" ]; then
                stop_all
            else
                restart_environment "$env" # Use restart function but only stop part
                pkill -f "PORT=" || true
            fi
            ;;
        "restart")
            if [ -z "$env" ]; then
                print_error "Please specify environment: production|development"
                exit 1
            fi
            restart_environment "$env"
            ;;
        "logs")
            if [ -z "$env" ]; then
                print_error "Please specify environment: production|development"
                exit 1
            fi
            show_logs "$env" "$3"
            ;;
        "backup")
            if [ -z "$env" ]; then
                print_error "Please specify environment: production|development"
                exit 1
            fi
            backup_database "$env"
            ;;
        *)
            echo "Usage: $0 {status|start|stop|restart|logs|backup} [environment] [options]"
            echo ""
            echo "Commands:"
            echo "  status                    - Show status of all environments"
            echo "  start {prod|dev|all}      - Start specified environment(s)"
            echo "  stop [env|all]            - Stop specified environment or all"
            echo "  restart {prod|dev}        - Restart specified environment"
            echo "  logs {prod|dev} [follow]  - Show logs (add 'follow' to tail -f)"
            echo "  backup {prod|dev}         - Backup database"
            echo ""
            echo "Environments:"
            echo "  production, prod          - Production environment"
            echo "  development, dev          - Development environment"
            echo "  all                       - All environments (start/stop only)"
            echo ""
            echo "Examples:"
            echo "  $0                        - Show status"
            echo "  $0 start production       - Start production"
            echo "  $0 restart dev            - Restart development"
            echo "  $0 logs prod follow       - Follow production logs"
            echo "  $0 backup dev             - Backup development database"
            exit 1
            ;;
    esac
}

# Check if running as root for certain operations
if [[ "$1" =~ ^(start|stop|restart)$ ]] && [[ $EUID -ne 0 ]]; then
   print_error "This command must be run as root or with sudo"
   exit 1
fi

# Run main function with all arguments
main "$@"