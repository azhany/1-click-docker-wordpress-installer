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

# Function to list available backups
list_backups() {
    # Get all backup directories
    backup_dirs=($(ls -d backups_* 2>/dev/null))
    
    if [ ${#backup_dirs[@]} -eq 0 ]; then
        print_error "No backup directories found!"
        exit 1
    fi

    echo -e "${BLUE}Available backups:${NC}"
    echo "----------------"
    
    for i in "${!backup_dirs[@]}"; do
        echo "$((i+1))) ${backup_dirs[$i]}"
        # List contents of backup
        if [ -f "${backup_dirs[$i]}/wordpress_backup.tar.gz" ]; then
            echo "   - WordPress files backup"
        fi
        if [ -f "${backup_dirs[$i]}/mysql_backup.tar.gz" ]; then
            echo "   - MySQL database backup"
        fi
        echo "----------------"
    done

    return 0
}

# Function to restore WordPress files
restore_wordpress() {
    local backup_dir=$1
    
    if [ -f "$backup_dir/wordpress_backup.tar.gz" ]; then
        print_status "Restoring WordPress files..."
        rm -rf wordpress/*
        tar -xzf "$backup_dir/wordpress_backup.tar.gz" --strip-components=1 -C wordpress/
        print_success "WordPress files restored"
    else
        print_error "WordPress backup not found in $backup_dir"
        return 1
    fi
}

# Function to restore database
restore_database() {
    local backup_dir=$1
    
    if [ -f "$backup_dir/mysql_backup.tar.gz" ]; then
        print_status "Restoring MySQL database..."
        rm -rf mysql/*
        tar -xzf "$backup_dir/mysql_backup.tar.gz" --strip-components=1 -C mysql/
        print_success "MySQL database restored"
    else
        print_error "MySQL backup not found in $backup_dir"
        return 1
    fi
}

# Main function
main() {
    echo -e "${BLUE}WordPress Restore Script${NC}"
    echo "------------------------"
    
    # Check if docker-compose.yml exists
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found! Please run this script in your WordPress Docker directory."
        exit 1
    fi

    # List available backups
    list_backups
    
    # Get user selection for backup directory
    read -p "Select backup number to restore (or 'q' to quit): " backup_number
    
    if [[ $backup_number == "q" ]]; then
        print_status "Operation cancelled"
        exit 0
    fi

    # Validate selection
    if ! [[ $backup_number =~ ^[0-9]+$ ]] || [ $backup_number -lt 1 ] || [ $backup_number -gt ${#backup_dirs[@]} ]; then
        print_error "Invalid selection!"
        exit 1
    fi

    selected_backup="${backup_dirs[$((backup_number-1))]}"
    print_status "Selected backup: $selected_backup"

    # Ask what to restore
    echo -e "\n${YELLOW}What would you like to restore?${NC}"
    select restore_choice in "WordPress Only" "Database Only" "Both" "Cancel"; do
        case $restore_choice in
            "WordPress Only" )
                # Stop containers
                print_status "Stopping Docker containers..."
                docker-compose down

                # Restore WordPress
                restore_wordpress "$selected_backup"
                
                # Start containers
                print_status "Starting Docker containers..."
                docker-compose up -d
                break
                ;;
            "Database Only" )
                # Stop containers
                print_status "Stopping Docker containers..."
                docker-compose down

                # Restore database
                restore_database "$selected_backup"
                
                # Start containers
                print_status "Starting Docker containers..."
                docker-compose up -d
                break
                ;;
            "Both" )
                # Stop containers
                print_status "Stopping Docker containers..."
                docker-compose down

                # Restore both
                restore_wordpress "$selected_backup"
                restore_database "$selected_backup"
                
                # Start containers
                print_status "Starting Docker containers..."
                docker-compose up -d
                break
                ;;
            "Cancel" )
                print_status "Operation cancelled"
                exit 0
                ;;
        esac
    done

    print_success "Restore operation completed!"
}

# Run the script
main