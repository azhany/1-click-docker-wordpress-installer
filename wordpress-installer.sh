#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print colored status messages
print_status() {
    echo -e "${BLUE}[*] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[+] $1${NC}"
}

print_error() {
    echo -e "${RED}[-] $1${NC}"
}

# Get domain name from user
get_domain_name() {
    read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
    if [ -z "$DOMAIN_NAME" ]; then
        print_error "Domain name cannot be empty"
        exit 1
    fi
}

# Check if script is run with sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "Please run this script with sudo"
        exit 1
    fi
}

# Install prerequisites
install_prerequisites() {
    print_status "Checking and installing prerequisites..."
    
    apt-get update
    PACKAGES="curl apt-transport-https ca-certificates software-properties-common nginx certbot python3-certbot-nginx"
    apt-get install -y $PACKAGES
    
    if ! command -v docker &> /dev/null; then
        print_status "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl enable docker
        systemctl start docker
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        print_status "Installing Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    if [ -n "$SUDO_USER" ]; then
        usermod -aG docker $SUDO_USER
    fi
    
    print_success "All prerequisites installed successfully"
}

# Create necessary directories
create_directories() {
    print_status "Creating project directories..."
    
    mkdir -p wordpress-docker
    cd wordpress-docker
    
    mkdir -p {wordpress,mysql,php,logs,nginx}
    mkdir -p wordpress/{wp-content,wp-config}
    mkdir -p logs/{apache,php,nginx}

    # Ensure php.ini exists to prevent Docker from treating it as a directory
    touch php/php.ini

    chown -R $SUDO_USER:$SUDO_USER .
    
    print_success "Directories created successfully"
}

# Configure Nginx
configure_nginx() {
    print_status "Configuring Nginx..."
    
	# Create Nginx configuration
    cat > /etc/nginx/sites-available/$DOMAIN_NAME << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /phpmyadmin/ {
        proxy_pass http://localhost:8081/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Increase max upload size
    client_max_body_size 64M;
}
EOF

	# Enable the site
    ln -sf /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default

    nginx -t && systemctl restart nginx
    
    print_success "Nginx configured successfully"
}

# Create docker-compose.yml
create_docker_compose() {
    print_status "Creating docker-compose.yml..."
    
    cat > docker-compose.yml << EOF
version: '3'

services:
  wordpress:
    image: wordpress:latest
    container_name: wp_site
    restart: always
    environment:
      - WORDPRESS_DB_HOST=db
      - WORDPRESS_DB_USER=wordpress
      - WORDPRESS_DB_PASSWORD=wordpress_password
      - WORDPRESS_DB_NAME=wordpress
    volumes:
      - ./wordpress:/var/www/html
      - ./php/php.ini:/usr/local/etc/php/php.ini
      - ./logs/apache:/var/log/apache2
      - ./logs/php:/var/log/php
    ports:
      - "8080:80"
    depends_on:
      - db

  db:
    image: mysql:5.7
    container_name: wp_mysql
    restart: always
    environment:
      - MYSQL_DATABASE=wordpress
      - MYSQL_USER=wordpress
      - MYSQL_PASSWORD=wordpress_password
      - MYSQL_ROOT_PASSWORD=somewordpress
    volumes:
      - ./mysql:/var/lib/mysql

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: wp_phpmyadmin
    restart: always
    environment:
      - PMA_HOST=db
      - MYSQL_ROOT_PASSWORD=somewordpress
    ports:
      - "8081:80"
    depends_on:
      - db
EOF

    chown $SUDO_USER:$SUDO_USER docker-compose.yml
}

# Setup SSL with Certbot
setup_ssl() {
    print_status "Setting up SSL with Let's Encrypt..."
    
	# Get SSL certificate
    certbot --nginx -d $DOMAIN_NAME -d www.$DOMAIN_NAME --non-interactive --agree-tos --email webmaster@$DOMAIN_NAME

    systemctl reload nginx

    print_success "SSL certificate installed successfully"
}

# Update WordPress configuration
update_wordpress_config() {
    print_status "Updating WordPress configuration..."
    
    # Wait for wp-config.php to be generated
    TIMEOUT=60
    while [ ! -f wordpress/wp-config.php ] && [ $TIMEOUT -gt 0 ]; do
        sleep 5
        TIMEOUT=$((TIMEOUT-5))
    done

    if [ ! -f wordpress/wp-config.php ]; then
        print_error "wp-config.php was not found. Exiting..."
        exit 1
    fi

    cat >> wordpress/wp-config.php << EOF

/* SSL and domain configuration */
define('WP_HOME', 'https://$DOMAIN_NAME');
define('WP_SITEURL', 'https://$DOMAIN_NAME');
define('FORCE_SSL_ADMIN', true);
if (strpos(\$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false)
    \$_SERVER['HTTPS']='on';
EOF

    print_success "WordPress configuration updated successfully"
}

# Main installation function
main() {
    print_status "Starting WordPress Docker setup with public access..."
    
    check_sudo
    get_domain_name
    install_prerequisites
    create_directories
    create_docker_compose
    configure_nginx
    
    docker-compose up -d
    
    setup_ssl
    update_wordpress_config
    
    docker-compose restart
    
    print_success "Setup completed successfully!"
    echo -e "${GREEN}Your WordPress site is now available at: https://$DOMAIN_NAME${NC}"
    echo -e "${BLUE}phpMyAdmin is available at: https://$DOMAIN_NAME/phpmyadmin${NC}"
}

main
