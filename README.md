# Snipe-IT Auto Installation Script

This script automates the installation and configuration of Snipe-IT on an Ubuntu-based server. It sets up the required dependencies, configures Apache, creates a database, and deploys Snipe-IT with proper permissions and optimizations.

## Features
✅ Installs and configures required packages (Apache, PHP, MariaDB, Composer, Git)  
✅ Sets up the database (Creates DB, User, and Grants Permissions)  
✅ Downloads and configures Snipe-IT automatically  
✅ Ensures proper permissions and ownership  
✅ Configures Apache Virtual Host  
✅ Clears cache, generates the Laravel app key, and runs migrations  
✅ Automatically detects and uses the current server IP  
✅ Error handling for missing dependencies, permission issues, and failed database migrations  

---

## Installation Guide

### 1️⃣ **Create and Run the Installation Script**

1. Open a terminal and create the `install.sh` file:
   ```bash
   nano install.sh
   ```
2. Copy and paste the installation script into the `install.sh` file.
3. Save the file (`CTRL+X`, then `Y`, then `Enter`).
4. Make the script executable:
   ```bash
   chmod +x install.sh
   ```
5. Run the installation script:
   ```bash
   sudo ./install.sh
   ```

### 2️⃣ **Access Snipe-IT Web Interface**
Once the installation is complete, open your browser and navigate to:
```
http://your-server-ip
```
Replace `your-server-ip` with your actual server’s IP address.

---

## Troubleshooting

If you face Token Hidden error create your github token and paste 

### 🔹 GitHub API Limit Reached
If you see an error about GitHub authentication while using Composer, you need to generate a GitHub token:

1️⃣ **Generate a Token**
1. Open the [GitHub Token Generation Page](https://github.com/settings/tokens/new).
2. Give it a name (e.g., "Composer Install").
3. Scroll down and **do not select any scopes** (public repository access is enough).
4. Click **"Generate Token"**.
5. Copy the token.

2️⃣ **Configure Composer with the Token**
```bash
composer config --global --auth github-oauth.github.com YOUR_GITHUB_TOKEN
```
Replace `YOUR_GITHUB_TOKEN` with the token you copied.

---

### 🔹 Apache Shows Default Page Instead of Snipe-IT
Run the following commands:
```bash
sudo a2dissite 000-default.conf
sudo a2ensite snipeit.conf
sudo systemctl restart apache2
```

### 🔹 Laravel Shows Errors or Fails to Load
Run these commands to clear cache and reconfigure:
```bash
cd /var/www/snipeit
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan cache:clear
sudo -u www-data php artisan key:generate
sudo -u www-data php artisan migrate --force
```

### 🔹 Check Apache Logs for Errors
```bash
sudo tail -f /var/log/apache2/error.log
```

---

## Uninstallation
If you want to remove Snipe-IT completely:
```bash
sudo systemctl stop apache2 mariadb
sudo rm -rf /var/www/snipeit
sudo mysql -e "DROP DATABASE snipeit;"
sudo mysql -e "DROP USER 'snipeit_user'@'localhost';"
```

