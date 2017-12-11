# Vagrant Development Environment for Craft 3

## Installation

### Installing Git

On Windows: https://git-scm.com/download/win

It is recommended to check out and commit Unix-style line endings on any platform.  The shell scripts used in the project will not function properly if checked out with Windows line endings. Make sure to install the command line tools as well, and not just the GUI.

### Setting up Git

https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/

### Install Vagrant

If using Windows 7, it's recommended to get 1.9.6 to avoid incompatibility issues with older versions of powershell

Vagrant can be found here: https://www.vagrantup.com/downloads.html

### Install VirtualBox

Vagrant is not compatible with VirtualBox 5.2 or later
	
VirtualBox can be found here: https://www.virtualbox.org/wiki/Downloads

### Vagrant Setup

> When referencing the **Vagrant environment folder**, this readme means the folder containing your `Vagrantfile`. Any `vagrant` commands should be run from this folder.

Before starting up the VM, there are a few additional steps to get Vagrant where needed. Open a shell/prompt and do the following:

Run `vagrant plugin install vagrant-vbguest` to ensure the VirtualBox tools are installed on the guest OS when initialized.

Run `vagrant plugin install vagrant-triggers` to add script trigger hooks that are used to help teardown the environment when the VM is destroyed.

### VM Setup

Open a shell/prompt and navigate to the Vagrant environment folder. Run `vagrant up` to start the guest virtual machine. The initial install process will take a while as it downloads the CentOS image, installs several packages, makes configuration changes, and ultimately sets up Craft.

That's all you need to do, once finished your Craft installation will be ready to use at [192.168.33.10](http://192.168.33.10/admin). The default Craft username is **admin** and the password is **craftdev**.

> Because Craft 3 is still under active development, it is possible that the current version installed through Github does not function, if this is the case, you will need to either report an issue and wait, or manually make adjustments to the Composer install script in order to pull a specific tagged version.

## VM Usage

To shut down, restart, or completely delete the VM, use `vagrant halt`, `vagrant reload`, and `vagrant destroy`, respectively. **Do not use `reboot` via SSH to reboot the machine** as it will not remount shared folders.

> If you want a quick way to reset Craft's database and workspace without destroying the Vagrant box and rebuilding it, while in the guest's terminal, you can run `/setup/craft-reset.sh`, which will drop the database, delete _everything_ from the web folder, and redownload/reinstall craft.

### Files

Within the Vagrant environment folder, a `workspace` folder is created to allow development on the host machine. This folder is mounted to the guest machine as the webserver root folder (`/var/www`) used by Apache. The public folder is configured to the `/var/www/html` folder. **This folder will be automatically deleted when the vagrant machine is destroyed.**

There is an additional `/setup` folder on the guest that is synced from the `setup` folder within the Vagrant environment folder. This contains some scripts and configuration files used in setting up the machine or available for convenience as documented below.

> Use the `workspace` folder to transfer data, the `setup` folder is not actively synced back and forth. **Files written to the `/setup` folder on the guest machine will be lost on guest reboot**.

### SSH

To quickly SSH into the box, for example to run various Composer commands, run `vagrant ssh`. At this point it's like any other remote linux machine.

Alternatively, if you want to use a custom SSH client (or for SSH tunneling required below), you will need to use the VM's configured private key, usually located in the Vagrant environment under `./.vagrant/machines/default/virtualbox/private_key`. Using `vagrant` as the username, and `192.168.33.10` as the address, you can then SSH in to the vagrant machine. For example:

```bash
ssh vagrant@192.168.33.10 -i ./.vagrant/machines/default/virtualbox/private_key
```

> In case the key isn't at the above location, you can run `vagrant ssh-config` and look for the `IdentityFile` path.

> Remember that some tools in Windows (filezilla, heidisql, etc.) will use PuTTY formatted keys (`.ppk`) which will need to be manually converted with the [puttygen](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) tool.

### Database

If you need to access the database, you will need to connect via an SSH tunnel (given the network configuration). Follow the steps above for finding the keyfile and connecting to SSH with a custom client. Through that tunnel, you can connect to the mysql server on `127.0.0.1` with the default username of **root** and password of **rootpassword**.

### Snapshots

VirtualBox as a provider supports [snapshots](https://www.vagrantup.com/docs/cli/snapshot.html). **Make sure to _ALWAYS_ run these commands with the --no-provision flag**, otherwise the initialization script will run again, which _will_ cause issues. Keep in mind as well, that **snapshots will not restore the `/var/www` (`workspace`) folder**, so their utility in development may be low. If you want a copy of a project to fall back to, you will need to copy it manually.

## Site Development

Working with the contents of a Craft site that are synced to a git repository is relatively straightforward. Craft excludes content that isn't necessary from the repository by default, such as the `/vendor` folder, or the contents of the `/html/cpresources` folder.

Generally these repositories contain the data mapped to the web root, so you would normally clone the repository into the Craft install, but you can't clone a git repository to a non-empty folder. An easy solution would be to clone to another location, then copy the files in.

> For convenience, and for reference if setting up automation, there is a script in the `/setup` folder called `site-setup.sh` that assists with this process. Simply call it from a terminal (or something like the git bash, on Windows) while within your Vagrant environment folder on the host, passing it the repository path.

```
./../setup/site-setup.sh git@github.com:user/repository
```

## Plugin Development

Craft plugins are Composer packages, which come with some setup and installation requirements, and thus cannot simply be dropped in a folder to install them. Usually they can be installed from external repositories, but for development purposes this typical method is _very_ slow. There are some considerations to make in order facilitate a smooth development experience.

> To skip all the details, and get to working immediately, there is a script in the `/setup` folder called `plugin-install.sh` that will get you up and running with a plugin repository. Simply call it from a terminal (or something like the git bash, on Windows) while within your Vagrant environment filder on the host, passing it the package name and the repository path. **This method has some caveats outlined further below, though for general adjustments and quick testing, this can get you working without having to know all the details**.

```bash
./../setup/plugin-install.sh git@github.com:user/repository
```

---

Typically, when running `composer require package/name`, composer checks [Packagist](https://packagist.org/) for the specified package. This in turn means that developing a package would require making changes to a package in a local repository, publishing the changes to Packagist, waiting for changes to become available, and then running `composer update` for each change, which costs a significant amount of time for each development change.

Composer does provide a mechanism to allow packages to be retrieved through other means. For a simple package, we might place it in a temporary location, and then add, to our `composer.json` an entry pointing to check the given path for packages when asked to install or update new ones.

```json
"repositories": [
	{
		"type": "path",
		"url": "./relative/path/to/package"
	}
],
```

Normally this would symlink the given path to the `/vendor` folder where Composer packages are installed, in addition to making the appropriate changes to the package manifests, autoloaders, and `composer.lock` files. **Keep in mind, doing this within VirtualBox's sync filesystem won't use symlinking, and instead copies the files**. This process takes us a step further, allowing our non-public package to be installed to Composer, where we can then make edits to the underlying files in the `/vendor` folder.

> Keep in mind that while this method may be fairly direct, it has limitations. Updates made directly to packages in the `/vendor` folder aren't picked up by `composer install` and `composer update` commands, meaning changes to version numbers and package information won't be reflected. In the case of Craft plugins, there are even more internal functions of Craft that are run on plugin install/uninstall that may not function properly on in-place edits (notice how plugins have package types of `craft-plugin` and not `library`).

---

Instead, if available, one might choose to pull composer packages from a git repository.

```json
"repositories": [
	{
		"type": "git",
		"url": "git@github.com:user/repository"
	}
],
```

This now allows us to push our updates to the repository and then `composer update` (or more specifically `composer update package/name`) to pull changes. While this removes a small bit of the overhead of the traditional approach, and allows us the capability of updating properly, it's still slower than including a project directly. Additionally, if the repository is private, the guest VM won't be able to access it without the added setup requirement of manually copying over any SSH keys or setting up credentials necessary to clone it.

---

There's no one solution that really fulfills requirements of quick in-place editing, while being functionally accurate with updates, simply because of Composer's nature of updating from source packages manually and running scripts to facilitate changes, versus the more traditional approach of dropping in files and detecting that things have changed for updates.

The provided `plugin-install.sh` script attempts to get the best it can from both methods by checking out the plugin from a dummy git repository, and then repointing the upstream branch of the installed package to the original repository. This way active development can be done on the package, but it can also be updated as needed in case of changes being made to composer files or scripts being added. To further assist with individual plugin handling, there are also `plugin-update.sh` and `plugin-remove.sh` scripts that can be run the same way, which will update composer's internal references to package behavior and version numbers, or delete the plugin outright, respectively.

```bash
./setup/plugin-update.sh package/name
# or
./setup/plugin-remove.sh package/name
```

## Code Guidelines/Standards

[Craft recommends following these coding standards](https://github.com/craftcms/docs/blob/master/en/coding-guidelines.md). These guidelines note following the PSR-1 coding standard & PRS-2 coding style. To help facilitate code consistency, it is recommended to use the PHP CodeSniffer tool, which will find and can automatically fix inconsistencies with these rules. For convenience, there is a `php-dev-init.sh` script provided that can be run within the guest in order to install and set up the tool quickly. It is recommended to run this before every commit, to ensure code consistency.

To run the tool on some code, simply run the following on the guest:

```bash
# Run PHPCS on code to see style warnings and errors.
phpcs /path/to/code
# Run PHPCBF on code to automatically fix style errors where possible.
phpcbf /path/to/code
```

### Customized Ruleset

Keep in mind the PSR-2 style requires spaces instead of tabs, so a slightly modified ruleset needs to be used in order to fit with our current standards. Thankfully, PHPCS allows for modification of its ruleset, either through providing a `--standard=/setup/phpcs-ruleset.xml` switch to its command line parameters, or more conveniently, it searches for a `phpcs.xml` file in the folder of the code being checked, and every parent folder thereof. It is then recommended that the `phpcs.xml` file from the `/setup` folder is included in plugin projects. For reference, there are other ruleset files within the `/setup` driectory as well, with additional suffixes based on their deviations from the standard.

## Further Considerations

Apache and php configurations available before provisioning (not copied every time, though I suppose they could be...)

All shell scripts and the Vagrantfile itself are fully documented for reference.

Workspace could just be renamed when the box is destroyed, instead of deleting it.

## Contents

Listed here are all the parts you need to know about your new Vagrant environment and Craft installation.

```
/.vagrant - Temporary working folder for Vagrant providers, stores configuration information, keys, etc. Generated and managed by Vagrant. Don't delete this if you have an active virtual machine tied to this folder.
	/.vagrant/machines/default/virtualbox/private_key - Likely the only file here you will need to worry about. The default location of the vagrant user's SSH key used for tunneling from host to guest.
/setup - Storage for scripts and utility files used by Vagrant automatically and available for use manually to vacilitate development. All scripts are documented.
	craft-reset.sh - Deletes any existing craft environment/database and creates a new one from scratch, faster than restroying and recreating a whole box. THIS DELETES THE ENTIRE WORKSPACE FOLDER.
	httpd.conf - Default Apache configuration used during provisioning.
	init.sh - Main Vagrant provisioning script.
	php.ini - PHP configuration used during provisioning.
	phpcs.xml - Recommended PHP CodeSniffer ruleset, enforcing tabs versus spaces.
	phpcs-samelinebraces.xml - A PHP CodeSniffer ruleset that enforces tabs and same-line braces.
	php-dev-init.sh - Installs and sets up PHP development tools on the guest box.
	plugin-remove.sh - Uninstalls Composer dependencies.
	plugin-require.sh - Installs Composer dependencies.
	plugin-update.sh - Attempts to update a Composer dependency from the original repository.
	site-setup.sh - Clones a site repository over an existing fresh craft install.
	start.sh - Vagrant post-startup script.
/workspace - Synchronized to the virtual box's /var/www folder, used as a workspace for Craft sites and plugins. THIS IS DELETED ON VAGRANT DESTROY AND CRAFT RESET.
	/config - Craft configuration.
	/html - The public web root folder.
	/modules - Custom YII modules for Craft.
	/storage - Data storage folder for Craft and its plugins.
	/templates - Craft template folder.
	/vendor - Installed composer packages.
	.env - Environment configuration, not committed, this is where credentials and the like go.
	composer.json - Composer configuration for the entire Craft package, including installed plugins.
	composer.lock - Information about exact packages and versions installed, as well as the configuration of said packages upon installation (even if removed from the composer.json)
	craft - A thin console bootstrapper for `craft` commands on Unix.
	craft.bat - A thin command line bootstrapper for `craft` commands on Windows.
README.md - This file.
Vagrantfile - The main Vagrant configuration, describing the kind of box to install, how to configure it, and what kinds of script should be run when.
```
