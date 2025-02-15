#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored status messages
print_status() {
    echo -e "${BLUE}[*] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[+] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_error() {
    echo -e "${RED}[-] $1${NC}"
}

# Function to create backup
create_backup() {
    print_status "Creating backup..."
    BACKUP_DIR="backups_$(date +%Y%m%d_%H%M%S)"
    mkdir -p $BACKUP_DIR

    # Backup WordPress files
    if [ -d "wordpress" ]; then
        tar -czf "$BACKUP_DIR/wordpress_backup.tar.gz" wordpress/
        print_success "WordPress files backed up to $BACKUP_DIR/wordpress_backup.tar.gz"
    fi

    # Backup MySQL data
    if [ -d "mysql" ]; then
        tar -czf "$BACKUP_DIR/mysql_backup.tar.gz" mysql/
        print_success "MySQL data backed up to $BACKUP_DIR/mysql_backup.tar.gz"
    fi

    print_success "Backup completed in directory: $BACKUP_DIR"
}

# Function to reset WordPress
reset_wordpress() {
    print_status "Resetting WordPress files..."
    if [ -d "wordpress" ]; then
        rm -rf wordpress/*
        print_success "WordPress files removed"
    else
        print_error "WordPress directory not found!"
        exit 1
    fi
}

# Function to reset database
reset_database() {
    print_status "Resetting MySQL database..."
    if [ -d "mysql" ]; then
        rm -rf mysql/*
        print_success "MySQL data removed"
    else
        print_error "MySQL directory not found!"
        exit 1
    fi
}

# Main menu
main() {
    echo -e "${BLUE}WordPress Reset Script${NC}"
    echo "------------------------"
    echo "This script will help you reset your WordPress installation."
    echo ""
    
    # Backup prompt
    echo -e "${YELLOW}Would you like to create a backup before proceeding?${NC}"
    select backup_choice in "Yes" "No" "Cancel"; do
        case $backup_choice in
            Yes )
                create_backup
                break
                ;;
            No )
                print_warning "Proceeding without backup..."
                break
                ;;
            Cancel )
                print_status "Operation cancelled"
                exit 0
                ;;
        esac
    done

    echo ""
    echo -e "${YELLOW}What would you like to reset?${NC}"
    select reset_choice in "WordPress Only" "WordPress + Database" "Cancel"; do
        case $reset_choice in
            "WordPress Only" )
                # Stop containers
                print_status "Stopping Docker containers..."
                docker-compose down

                # Reset WordPress
                reset_wordpress

                # Start containers
                print_status "Starting Docker containers..."
                docker-compose up -d

                print_success "WordPress has been reset. You can now access your site and complete the installation."
                break
                ;;
            "WordPress + Database" )
                # Stop containers
                print_status "Stopping Docker containers..."
                docker-compose down

                # Reset WordPress and database
                reset_wordpress
                reset_database

                # Start containers
                print_status "Starting Docker containers..."
                docker-compose up -d

                print_success "WordPress and database have been reset. You can now access your site and complete the installation."
                break
                ;;
            "Cancel" )
                print_status "Operation cancelled"
                exit 0
                ;;
        esac
    done
}

# Check if script is run in the correct directory
if [ ! -f "docker-compose.yml" ]; then
    print_error "docker-compose.yml not found! Please run this script in your WordPress Docker directory."
    exit 1
fi

# Run the script
main