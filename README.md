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
2. Visit `https://your-domain.com/phpmyadmin` – should show phpMyAdmin.

## Notes
- The script installs all necessary dependencies, including Docker and Nginx.
- If using Cloudflare, ensure proper SSL settings as noted above.
- Logs are stored in the `logs/` directory for debugging issues.

For any issues, check logs or restart services using:
```sh
sudo systemctl restart nginx
sudo docker-compose restart
```

## Reset WordPress Installation

The `reset-wordpress.sh` script allows you to reset your WordPress installation to its default state.

1. Make sure you're in the directory containing your `docker-compose.yml` file.

### Usage

Run the script:
```bash
./reset-wordpress.sh
```

The script will provide the following options:

1. Backup Creation:
   - Yes: Creates a timestamped backup before resetting
   - No: Proceeds without backup
   - Cancel: Exits the script

2. Reset Options:
   - WordPress Only: Resets just the WordPress files, keeping the database
   - WordPress + Database: Resets both WordPress files and the database
   - Cancel: Exits without making changes

### Backup Location

Backups are stored in directories named `backups_YYYYMMDD_HHMMSS` containing:
- `wordpress_backup.tar.gz`: WordPress files backup
- `mysql_backup.tar.gz`: Database backup

## Restore from Backup

The `restore-wordpress.sh` script allows you to restore your WordPress installation from previous backups.

1. Make sure you're in the directory containing your `docker-compose.yml` file.

### Usage

Run the script:
```bash
./restore-wordpress.sh
```

The script will:
1. List all available backups
2. Ask you to select a backup by number
3. Provide restore options:
   - WordPress Only: Restores just the WordPress files
   - Database Only: Restores just the database
   - Both: Restores both WordPress files and database
   - Cancel: Exits without making changes

## Important Notes

1. Before resetting:
   - Always create a backup if you have important data
   - Make sure you have enough disk space for backups
   - Consider downloading backups to a secure location

2. When restoring:
   - The process will stop your WordPress containers temporarily
   - Existing files/database will be overwritten
   - Make sure you select the correct backup

3. Common issues:
   - If script fails, check file permissions
   - Ensure enough disk space is available
   - Verify Docker containers are running properly

## Script Locations

Keep both scripts in your WordPress Docker directory:
```
wordpress-docker/
├── docker-compose.yml
├── reset-wordpress.sh
├── restore-wordpress.sh
└── backups_YYYYMMDD_HHMMSS/
    ├── wordpress_backup.tar.gz
    └── mysql_backup.tar.gz
```

## Troubleshooting

1. If scripts fail to run:
```bash
chmod +x reset-wordpress.sh restore-wordpress.sh
```

2. If backup/restore fails:
```bash
# Check disk space
df -h

# Check file permissions
ls -la

# Check Docker status
docker-compose ps
```

3. If WordPress doesn't load after restore:
```bash
# Restart containers
docker-compose restart

# Check container logs
docker-compose logs wordpress
```

## Support

For issues or questions:
1. Check the error messages in the script output
2. Verify your Docker installation
3. Ensure all prerequisites are met
4. Review logs in the WordPress container

## Security Considerations

1. Protect your backup files:
```bash
chmod 600 backups_*/*.tar.gz
```

2. Consider encrypting sensitive backups:
```bash
gpg -c backups_*/*.tar.gz
```

3. Regularly transfer backups to a secure off-site location

## License

These scripts are provided under the MIT License. Feel free to modify and distribute them according to your needs.