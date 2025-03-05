Vagrant.configure("2") do |config|
  config.vm.define "db" do |db|
    db.vm.box = "ubuntu/bionic64"
    db.vm.network "private_network", ip: "192.168.56.11"
    db.vm.network "forwarded_port", guest: 3306, host: 33306
    db.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
    end
    db.vm.provision "shell", inline: <<-SHELL
      sudo apt update
      sudo apt install -y mysql-server
    SHELL
  end

  config.vm.define "web" do |web|
    web.vm.box = "ubuntu/bionic64"
    web.vm.network "private_network", ip: "192.168.56.12"
    web.vm.network "forwarded_port", guest: 80, host: 8080
    web.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
    end
    web.vm.provision "shell", inline: <<-SHELL
      sudo apt update
      sudo apt install -y nginx
    SHELL
  end
end
