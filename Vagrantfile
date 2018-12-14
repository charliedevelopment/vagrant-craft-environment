# Module for determining if the host OS is windows or not.
# https://stackoverflow.com/a/26889312
module OS
	def OS.windows?
		(/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
	end
end

# Configure Vagrant, configuration version 2
Vagrant.configure("2") do |config|

	# Set up some defaults for the VirtualBox provider
	config.vm.provider "virtualbox" do |v|
  		v.memory = 1024
	end

	# Use a centos 7 box
	config.vm.box = "centos/7"

	# Treat guest VM as if it is the following IP on the network
	config.vm.network "private_network", ip: "192.168.33.10"

	# Uncomment to allow access to the guest vm's port 80 through the host's port 8081
#	config.vm.network "forwarded_port", guest: 80, host: 8081

	# Automatically use a given hostname on the host system to point to the guest machine
	# To use this, first run `vagrant plugin install vagrant-hostsupdater` to install the plugin
	# Then uncomment the following line, changing the host to whatever you would like
#	config.vm.hostname = "dev.test"

	# Disable the default shared folder, we're going to provide more granular options
	config.vm.synced_folder ".", "/vagrant", disabled: true

	# Mount the setup folder via rsync
	# This will push to the guest VM, but doesn't actively sync anything back and forth
	config.vm.synced_folder "setup", "/setup", type: "rsync"

	# Mount the workspace folder via the VirtualBox sync system
	# This will actively keep the contents of the filesystem in sync
	config.vm.synced_folder "workspace", "/var/www", create: true, type: "virtualbox", group: 48, owner: 48, mount_options: ["dmode=775,fmode=774,umask=0002"]

	# Run this script on first provision
	config.vm.provision :shell, path: "setup/init.sh"

	# Run this script on first provision
	config.vm.provision :shell, path: "setup/craft-reset.sh", args: "quiet"

	# Run this script on any `vagrant up`
	config.vm.provision :shell, run: "always", path: "setup/start.sh"

	# Clean up workspace when the VM is destroyed
	config.trigger.after :destroy do |trigger|
		if OS.windows?
			trigger.run = {inline: "Remove-Item workspace -force -recurse"}
		else
			trigger.run = {inline: "rm -rf workspace"}
		end
	end
end
