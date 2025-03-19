#!/bin/bash

set -e

# Define variables
db_name="snipeit"
db_user="snipeit_user"
db_pass="snipeit_pass"
snipeit_dir="/var/www/snipeit"
server_ip=$(hostname -I | awk '{print $1}')

# Function to check if a package is installed
check_install() {
    dpkg -l | grep -q "$1" || sudo apt-get install -y "$1"
}

# Update system and install required packages
echo "Updating system and installing required packages..."
sudo apt update -qq
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update -qq
for pkg in apache2 mariadb-server php8.2 php8.2-cli php8.2-mbstring php8.2-xml php8.2-bcmath php8.2-curl php8.2-mysql php8.2-zip php8.2-tokenizer php8.2-fileinfo php8.2-gd php8.2-intl unzip git composer; do
    check_install "$pkg"
done

# Set PHP 8.2 as default
echo "Setting PHP 8.2 as default..."
sudo update-alternatives --set php /usr/bin/php8.2
php -v

# Start and enable services
echo "Starting and enabling required services..."
sudo systemctl enable --now apache2 mariadb

# Verify and set up the database
echo "Setting up the database..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS $db_name;"
user_exists=$(sudo mysql -e "SELECT user FROM mysql.user WHERE user='$db_user';" | grep $db_user || true)
if [ -n "$user_exists" ]; then
    sudo mysql -e "DROP USER '$db_user'@'localhost';"
fi
sudo mysql -e "CREATE USER '$db_user'@'localhost' IDENTIFIED BY '$db_pass';"
sudo mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Ensure proper permissions for Composer config directory
echo "Setting permissions for Composer..."
sudo mkdir -p /var/www/.config/composer
sudo chown -R www-data:www-data /var/www/.config
sudo chmod -R 775 /var/www/.config

# Download and extract Snipe-IT
echo "Downloading and setting up Snipe-IT..."
if [ ! -d "$snipeit_dir" ]; then
    sudo git clone https://github.com/snipe/snipe-it.git "$snipeit_dir"
fi
cd "$snipeit_dir"
sudo cp .env.example .env
sudo sed -i "s|APP_URL=.*|APP_URL=http://$server_ip|" .env
sudo sed -i "s/DB_DATABASE=.*/DB_DATABASE=$db_name/" .env
sudo sed -i "s/DB_USERNAME=.*/DB_USERNAME=$db_user/" .env
sudo sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$db_pass/" .env

# Set permissions and enable Apache modules
echo "Configuring Apache and permissions..."
sudo chown -R www-data:www-data "$snipeit_dir"
sudo chmod -R 755 "$snipeit_dir"
sudo a2enmod rewrite

# Install PHP dependencies
echo "Installing PHP dependencies..."
sudo -u www-data composer install --no-dev --prefer-source || { echo "Composer install failed!"; exit 1; }

# Configure Apache virtual host
apache_conf="/etc/apache2/sites-available/snipeit.conf"
echo "<VirtualHost *:80>
    DocumentRoot $snipeit_dir/public
    <Directory $snipeit_dir/public>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/snipeit_error.log
    CustomLog \${APACHE_LOG_DIR}/snipeit_access.log combined
</VirtualHost>" | sudo tee "$apache_conf"

sudo a2dissite 000-default.conf
sudo a2ensite snipeit.conf
sudo systemctl restart apache2

# Run Laravel configuration commands
echo "Configuring Laravel..."
sudo -u www-data php artisan config:clear
sudo -u www-data php artisan cache:clear
sudo -u www-data php artisan key:generate

# Run migration
echo "Running database migrations..."
sudo -u www-data php artisan migrate --force || { echo "Database migration failed!"; exit 1; }

# Provide installation details
echo "Installation complete! Access Snipe-IT at http://$server_ip"
