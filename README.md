# 1-click-docker-wordpress-installer

This script automates the deployment of a WordPress site using Docker and Nginx with SSL support.

## Prerequisites

Before running the script, ensure the following:
1. Your domain's DNS is pointed to your VPS IP address in Cloudflare.
2. You have root access to the server.
3. Ports 80 and 443 are open on your VPS firewall.
4. If using Cloudflare, set SSL/TLS encryption mode to "Full" or "Full (strict)".
5. The script assumes an Ubuntu environment.

## Deployment Instructions

To deploy the WordPress site:

1. Clone this repository:
   ```sh
   git clone <repository-url>
   cd <repository-directory>
   ```
2. Make it executable:
   ```sh
   chmod +x wordpress-installer.sh
   ```
3. Run it with sudo:
   ```sh
   sudo ./wordpress-installer.sh
   ```
4. Enter your domain name when prompted.
5. Wait for the setup to complete.

## Configuration

### Updating `php.ini`
To modify PHP settings, edit `php/php.ini` with your preferred configuration. Example:
```
max_execution_time = 600
memory_limit = 128M
post_max_size = 32M
upload_max_filesize = 32M
```
Restart the Docker containers to apply changes:
```sh
cd <repository-directory>
sudo docker-compose restart
```

## Verifying the Installation

1. Visit `https://your-domain.com` – should display the WordPress installation page.
2. Visit `https://your-domain.com:8081` – should show phpMyAdmin.

## Notes
- The script installs all necessary dependencies, including Docker and Nginx.
- If using Cloudflare, ensure proper SSL settings as noted above.
- Logs are stored in the `logs/` directory for debugging issues.

For any issues, check logs or restart services using:
```sh
sudo systemctl restart nginx
sudo docker-compose restart
```

