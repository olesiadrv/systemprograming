Vagrant.configure("2") do |config|
  config.vm.define "web" do |web|
    web.vm.box = "ubuntu/bionic64"
    web.vm.network "private_network", ip: "192.168.56.10"
    web.vm.network "forwarded_port", guest: 80, host: 8080

    web.vm.provision "shell", inline: <<-SHELL
      sudo apt update -y
      sudo apt install -y nginx php-fpm php-mysql

      sudo tee /etc/nginx/sites-available/default > /dev/null <<OD
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.php index.html index.htm;

    server_name _;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
OD

      sudo systemctl restart nginx php7.2-fpm

      sudo tee /var/www/html/index.php > /dev/null <<OD
<?php
$conn = new mysqli("192.168.56.11", "vagrant", "vagrant", "test_db");

if (\$conn->connect_error) {
    die("Connection failed: " . \$conn->connect_error);
}

\$result = \$conn->query("SELECT * FROM users");

echo "<h1>Users List</h1>";
while (\$row = \$result->fetch_assoc()) {
    echo "<p>" . \$row["id"] . ". " . \$row["name"] . "</p>";
}

\$conn->close();
?>
OD

      sudo chown -R www-data:www-data /var/www/html
      sudo chmod -R 755 /var/www/html
    SHELL
  end

  config.vm.define "db" do |db|
    db.vm.box = "ubuntu/bionic64"
    db.vm.network "private_network", ip: "192.168.56.11"
    db.vm.network "forwarded_port", guest: 3306, host: 13306

    db.vm.provision "shell", inline: <<-OD
      sudo apt update -y
      sudo apt install -y mysql-server

      # Налаштування бази даних
      sudo mysql -e "CREATE DATABASE test_db;"
      sudo mysql -e "CREATE USER 'admin'@'%' IDENTIFIED BY 'admin';"

      # Надаємо права користувачу 'admin' для роботи з базою test_db
      sudo mysql -e "GRANT ALL PRIVILEGES ON test_db.* TO 'admin'@'%';"
      sudo mysql -e "FLUSH PRIVILEGES;"

      # Створення таблиці users та додавання даних
      sudo mysql -e "USE test_db; CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100) NOT NULL);"
      sudo mysql -e "USE test_db; INSERT INTO users (name) VALUES ('Alice'), ('Bob'), ('Charlie');"

      # Налаштування MySQL для прослуховування всіх IP
      sudo sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
      sudo systemctl restart mysql
    OD
  end
end
