# Vagrant Development Environment for Craft 3

## Foreward

This documentation is meant for a rough, quick reference of all the parts needed to get up and running with Craft 3 in a local Vagrant environment. The tools involved (git, Vagrant, VirtualBox, etc.) are not covered in great detail. This guide is intended to provide a starting point, and give some additional insight or considerations that may not be readily apparent about the whole process.

While intended mainly for internal use within [Charlie Development](http://charliedev.com/) some of the resources and script documentation can apply more generally to Craft 3 or virtualized local development as a whole. It is intended that the recommendations and scripts provided herein are tuned for ease of use and speed of development. The benefits of this approach are sometimes hard to quantify, especially when compared to the speed of a more classic approach of download-edit-upload in a centralized environment.

## Installation

### Installing Git

On Windows, in order to use the automated scripts contained within this repository, you will need to install [git command line tools](https://git-scm.com/download/win).

> It is recommended to check out and commit Unix-style line endings regardless of platform. See [GitHub's documentation on line endings](https://help.github.com/articles/dealing-with-line-endings/) in order to set your `autocrlf` setting to `input`. The shell scripts used in the project will not function properly if checked out with Windows line endings, and most text editors will be able to properly understand the Unix-style line endings.

### Setting up Git

Using git from the command line will require you to have tools set up to access the repository with a key. Refer to [GitHub's documentation on ssh keys](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/) to set up your client.

> Remember, any commit made with a git client will tie a name and email with the commit, and this name/email is set _per client_ and not associated/validated with any underlying account on GitHub or otherwise. Make sure you set your email up according to your client's configuration, or see [GitHub's documentation on updating this setting](https://help.github.com/articles/setting-your-commit-email-address-in-git/) for more details. In the case of GitHub specifically, if you want to keep your email private, look for the `@users.noreply.github.com` email address in your [GitHub email settings page](https://github.com/settings/emails) and configure your client to use that.

### Install Vagrant

The Vagrantfile included with this project uses the trigger features available in vagrant 2.x. Older versions of this project contained configuration and notes regarding 1.x versions, if they are still needed for reference.

Vagrant can be found here: https://www.vagrantup.com/downloads.html

> A prior version of this guide and Vagrantfile were configured for the 1.x version of Vagrant. If updating to the 2.x version from a previous form of this guide, be sure to uninstall both previous plugins, using `vagrant plugin uninstall vagrant-triggers` and `vagrant plugin uninstall vagrant-vbguest`, first. Then, after installing the 2.x version, the `vagrant-vbguest` plugin may be reinstalled. Keep in mind the 2.x version of Vagrant comes with features similar to `vagrant-triggers` built in, and thus has a slightly different configuration file.

### Install VirtualBox

Historically, VirtualBox has updated and been incompatible with Vagrant until Vagrant has some time to update as well. Be sure to [check the VirtualBox versions compatible with the current version of Vagrant](https://www.vagrantup.com/docs/virtualbox/).

VirtualBox can be found here: https://www.virtualbox.org/wiki/Downloads

### Vagrant Setup

> When referencing the **Vagrant environment folder**, this readme means the folder containing your `Vagrantfile`. Any `vagrant` commands should be run from this folder.

Before starting up the VM, there are a few additional steps to get Vagrant where needed. Open a shell/prompt and do the following:

Run `vagrant plugin install vagrant-vbguest` to ensure the VirtualBox tools are installed on the guest OS when initialized.

### VM Setup

Open a shell/prompt and navigate to the Vagrant environment folder. Run `vagrant up` to start the guest virtual machine. The initial install process will take a while as it downloads the CentOS image, installs several packages, makes configuration changes, and ultimately sets up Craft.

That's all you need to do, once finished your Craft installation will be ready to use at [192.168.33.10](http://192.168.33.10/admin). The default Craft username is **admin** and the password is **craftdev**.

Keep in mind that the initial install of craft (at least the release candidate versions) will not come with any default sections/fields/templates, and thus 404 on visiting anything but the control panel.

## VM Usage

To shut down, restart, or completely delete the VM, use `vagrant halt`, `vagrant reload`, and `vagrant destroy`, respectively. **Do not use `reboot` via SSH to reboot the machine** as it will not remount shared folders.

> If you want a quick way to completely reset Craft to a freshly installed state, without the overhead of destroying the Vagrant box and rebuilding it, you can run `/setup/craft-reset-host.sh` on the host (or `/setup/craft-reset.sh` from within the guest), which will drop the database, delete _everything_ from the web folder, and redownload/reinstall craft. If you only want to reset the database to a clean initial state, without deleting any files, an additional parameter of `soft` may be passed to either script.

### Web Access

The default virtual address for the vagrant machine is `192.168.33.10`, and thus visiting this address in a web browser on the same local machine will take you to the Craft installation.

> There are additional configuration options available within the `Vagrantfile`. Simply run `vagrant reload` when making configuration changes. Some available options are changing the local IP address the machine uses (necessary if you have multiple machines), automatically assigning local hostnames to instances, and forwarding incoming traffic on a host's port to a guest machine.

### Files

Within the Vagrant environment folder, a `workspace` folder is created to allow development on the host machine. This folder is mounted to the guest machine as the webserver root folder (`/var/www`) used by Apache. The public folder is configured to the `/var/www/html` folder. **This folder will be automatically deleted when the vagrant machine is destroyed.**

There is an additional `/setup` folder on the guest that is synced from the `setup` folder within the Vagrant environment folder. This contains some scripts and configuration files used in setting up the machine or available for convenience as documented below.

> Use the `workspace` folder to transfer data, the `setup` folder is not actively synced back and forth. **Files written to the `/setup` folder on the guest machine will be lost on guest reboot**.

### SSH

To quickly SSH into the box, for example to run various Composer commands, run `vagrant ssh`. At this point it's like any other remote environment.

Alternatively, if you want to use a custom SSH client (or for SSH tunneling required below), you will need to use the VM's configured private key, usually located in the Vagrant environment under `./.vagrant/machines/default/virtualbox/private_key`. Using `vagrant` as the username, and `192.168.33.10` as the address, you can then SSH in to the vagrant machine. For example:

```bash
# SSH directly into the virtual machine.
ssh vagrant@192.168.33.10 -i ./.vagrant/machines/default/virtualbox/private_key
```

> In case the key isn't at the above location, you can run `vagrant ssh-config` and look for the `IdentityFile` path.

> Remember that some tools in Windows (filezilla, heidisql, etc.) will use PuTTY formatted keys (`.ppk`) which will need to be manually converted with the [puttygen](https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html) tool.

Keep in mind that every time a new Vagrant machine is created, its identification and SSH keys will be updated. Tools that need to use modified versions of openssh keys (such as PuTTY) should be avoided if possible, as key conversion/copying isn't handled automatically. If you `destroy` and then create a new box, some tools may need to be updated with new identities before you can connect to the machine, as they may cache the identity files of the old instance. In the case of regular command line SSH tools, you can run the following to clear the stored identity:

```bash
# Delete the cached host identity information.
ssh-keygen -R <host>
```

### Database

If you need to access the database, you will need to connect via an SSH tunnel (given the network configuration). Follow the steps above for finding the keyfile and connecting to SSH with a custom client. Through that tunnel, you can connect to the mysql server on `127.0.0.1` with the default username of **root** and password of **rootpassword**.

### Snapshots

VirtualBox as a provider supports [snapshots](https://www.vagrantup.com/docs/cli/snapshot.html). **Make sure to _ALWAYS_ run these commands with the --no-provision flag**, otherwise the initialization script will run again, which _will_ cause issues. Keep in mind as well, that **snapshots will not restore the `/var/www` (`workspace`) folder**, so their utility in development may be low. If you want a copy of a project to fall back to, you will need to copy it manually.

## Site Development

Working with the contents of a Craft site that are synced to a git repository is relatively straightforward. Craft excludes content that isn't necessary from the repository by default, such as the `/vendor` folder, or the contents of the `/html/cpresources` folder.

Generally these repositories contain the data mapped to the web root, so you would normally clone the repository into the Craft install, but you can't clone a git repository to a non-empty folder. An easy solution would be to clone to another location, then copy the files in.

> For convenience, and for reference if setting up automation, there is a script in the `/setup` folder called `site-setup.sh` that assists with this process. Call it from a terminal (or something like the git bash, on Windows) while within your Vagrant environment folder on the host, passing it the repository path.

```bash
# Set up a site from a repository automatically.
./setup/site-setup.sh git@github.com:user/repository
```

## Plugin Development

Craft plugins are Composer packages, which come with some setup and installation requirements, and thus cannot just be dropped in a folder to install them. Usually they can be installed from external repositories, but for development purposes this typical method is _very_ slow. There are some considerations to make in order facilitate a smooth development experience.

> To skip all the details, and get to working immediately, there is a script in the `/setup` folder called `plugin-install.sh` that will get you up and running with a plugin repository. Call it from a terminal (or something like the git bash, on Windows) while within your Vagrant environment folder on the host, passing it the package name and the repository path. **This method has some caveats outlined further below, though for general adjustments and quick testing, this can get you working without having to know all the details**.

```bash
# Install a plugin from a repository automatically.
./setup/plugin-install.sh git@github.com:user/repository
```

---

Typically, when running `composer require package/name`, composer checks [Packagist](https://packagist.org/) for the specified package. This in turn means that developing a package would require making changes to a package in a local repository, publishing the changes to Packagist, waiting for changes to become available, and then running `composer update` for each change, which costs a significant amount of time for each development change.

Composer does provide a mechanism to allow packages to be retrieved through other means. For a simple package, you might place it in a temporary location, and then add, to our `composer.json` an entry pointing to check the given path for packages when asked to install or update new ones.

```json
"repositories": [
	{
		"type": "path",
		"url": "./relative/path/to/package"
	}
],
```

Normally this would symlink the given path to the `/vendor` folder where Composer packages are installed, in addition to making the appropriate changes to the package manifests, autoloaders, and `composer.lock` files. **Keep in mind, doing this within VirtualBox's sync filesystem won't use symlinking, and instead copies the files**. This process takes us a step further, allowing our non-public package to be installed to Composer, where you can then make edits to the underlying files in the `/vendor` folder.

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
# Force update cached composer information about a plugin.
./setup/plugin-update.sh package/name
# Uninstall and completely remove a plugin.
./setup/plugin-remove.sh package/name
```

> Keep in mind, if you have made in-place edits to a plugin manually installed through git (using the `plugin-install.sh` script) it is possible that composer will fail to uninstall the plugin because of changes that have not been committed. Even if you have committed the changes normally to the `origin` branch, it will still complain about the temporary, dummy `composer` branch. In order to avoid this issue entirely, delete the `.git` folder of the plugin, and the plugin can be removed normally.

## Database Switching

Craft CMS supports both MySQL and PostgreSQL. To assist with testing, some scripts are provided to switch the Vagrant guest between MySQL and PostgreSQL for the Craft installation. **Keep in mind that when switching from one database to another the Craft installation is reset, _meaning all data in the current installation, (sites, plugins, database) will be lost_, because converting data from one database to another would otherwise be a manual process**. These scripts are `use-posgresql.sh` and `use-mysql.sh`. They will provide a confirmation before making changes, and will raise a notification if the requested database is already currently active.

## Code Guidelines/Standards

[Craft recommends following these coding standards](https://github.com/craftcms/docs/blob/master/en/coding-guidelines.md). These guidelines note following the PSR-1 coding standard & PRS-2 coding style. To help facilitate code consistency, it is recommended to use the PHP CodeSniffer tool, which will find and can automatically fix inconsistencies with these rules. For convenience, there is a `php-dev-init.sh` script provided that can be run within the environment folder on the host in order to install and set up the tool quickly. It is recommended to run the tool before every commit, to ensure code consistency.

To run the tool on some code, run the following on the guest:

```bash
# Run this only once on a guest to set up PHP development tools.
/setup/php-dev-init.sh
# Run PHPCS on code to see style warnings and errors.
phpcs /path/to/code
# Run PHPCBF on code to automatically fix style errors where possible.
phpcbf /path/to/code
```

> Note that `phpcs` may also apply some of its rules to other files (it supports `.inc`, `.js`, and `.css` files as well). In order to prevent any modifications (especially to minified files), it is important to specify `--extensions=php` when running `phpcs` or `phpcbf`.

### Customized Ruleset

Keep in mind the PSR-2 style requires spaces instead of tabs, so a slightly modified ruleset needs to be used in order to fit with our current standards. Thankfully, PHPCS allows for modification of its ruleset, either through providing a `--standard=/setup/phpcs-ruleset.xml` switch to its command line parameters, or more conveniently, it searches for a `phpcs.xml` file in the folder of the code being checked, and every parent folder thereof. It is then recommended that the `phpcs.xml` file from the `/setup` folder is included in plugin projects. For reference, there are other ruleset files within the `/setup` directory as well, with additional suffixes based on their deviations from the standard.

## HTTPS Configuration

Providing SSL certificates to use HTTPS for local development is a multi-step process with a few manual parts. Thankfully, if handled correctly, the majority of the manual process is a one-time setup.

In order to use SSL to reach HTTPS websites, the website must have a valid SSL certificate. In addition, browsers require certificates to be issued from a Certificate Authority (CA) that they trust, or else they will display a warning/error to the user, in an attempt to prevent Man in the Middle and Phishing attacks.

Being as it isn't possible to receive certificates for local development, one might choose to add exceptions for each individual site. This method is also cumbersome as the means of doing so can vary from each OS and browser, and having to replace a certificate with a new one if a development environment is recreated can introduce errors unexpectedly and takes additional time to manage manually.

Instead it is recommended to create a certificate locally for your machine and trust that certificate alone. Then, at any point, a new certificate can be generated signed by that local one, and it will simply be trusted by association without any further manual exception adding. In addition, with the manual steps out of the way, new certificate generation can be handled (mostly) automatically.

> This part of the readme is meant as a set of suggested guidelines and not a de-facto approach to this problem. It is likely any given environment might require a more tailored solution. This guide does not cover the finer details or security considerations of the following sections. It is best to have an underlying understanding of the tools involved before working with certificates manually.

### Creating a CA Certificate

Generating a CA certificate comes in two parts, creating a private key to use, and generating the certificate from the key. Creating a key is fairly simple, and can be done with the following shell command:

```bash
openssl genrsa -out ca-dev.key 4096
```

Then, using a pre-built configuration file (`ca-config.conf`), a certificate can be generated from this key:

```bash
openssl req -new -x509 -config ca-config.conf -sha256 -key ca-dev.key -out ca-dev.crt
```

It is important to note the following parts of the configuration file:

- Under the `ca_default` section, there are some files specified to be read from for certain parts of the process. If these need to be stored in a different location, it is important they are updated here.
- The `unique_subject` option is set to `no`. Signing certificates will track signatures made in the database file configured earlier. If this option is set to true, then errors will occur if a certificate's subject line is reused, which may not be preferred for volatile development environments.
- The `copy_extensions` option is set to `copy`. This means any x509 extensions (such as `subjectAltName`) that are provided with signing requests will be automatically copied. For a real CA this would require careful review of extensions provided with each request, but in a local environment, this is not a problem.
- While the identification information is set to some plain defaults, with "Local Development CA" as an organization name, it may be preferred to update this with something more recognizeable per your own situation.

After this is done, some additional files will need to be created in order to properly sign certificates. These are the signed certificate database, and the serial number storage file.

```bash
touch ca-db.txt
echo '01' > ca-serial.txt
```

After this process is finished, keep the key, certificate, configuration, db, and serial files all in a safe place for future reference. You will refer back to these whenever you want to create a new certificate for a development environment.

> The steps outlined above are contained within the `generate-ca-cert.sh` script for additional reference. It is not recommended to be used outright without first moving it to a more permanent location and checking on the configuration. If it is used, all of its generated files must be moved to a permanent location for later use.

### Trusting a CA Certificate

As long as the CA certificate is reused for each signing instance, this will be the last large part of the manual process. Trusting the root CA varies depending on the OS and browser being used.

#### Windows (General, IE, Chrome)

On Windows, Chrome and IE refer to Windows' built in certificate store. This can be accessed by running `certmgr.msc` and importing the certificate to the `Trusted Root Certification Authorities` section.

#### Windows (Firefox)

Firefox maintains its own internal list of trusted certificates, which can be managed through the `Settings -> Privacy & Security -> View Certificates` panel.

### Creating and Signing a Domain Certificate

Similar to creating a CA certificate above, a private key must first be generated for the server, which can be done with the following:

```bash
openssl genrsa -out site-dev.key 4096
```

With the key generated, a Certificate Signing Request (CSR) can be created from information regarding the domain. This can be done by providing the key and a configuration file through the following command:

```bash
openssl req -new -sha256 -nodes -key site-dev.key -out site-dev.csr -config temp-config.conf
```

For convenience, an example configuration file is provided as `site-config.conf` that can be copied and modified to suit the domain's needs. If using the provided file directly, every instance of `localhost.localdomain` should be replaced with the domain you will use for the development site.

Finally, to sign the certificate, you need the CA configuration from earlier, as well as all associated files still in their appropriate locatons as defined in said CA configuration. Using this configuration and the CSR generated in the previous command, a new certificate can be generated for the local development site:

```bash
openssl ca -batch -config ca-config.conf -policy signing_policy -extensions signing_req -out site-dev.crt -infiles site-dev.csr
```

Now you have a certificate signed by the local CA certificate that you trusted earlier, and thus is automatically trusted without further browser or OS configuration.

> The steps outlined above are contained within the `generate-cert.sh` script, with the added convenience of being able to provide the domain for automatic replacement, and the path to the CA configuration file.

```bash
# Generate and sign an SSL certificate for the given domain using the provided config.
./setup/generate-cert.sh test.dev /path/to/ca.conf
```

### Using a Domain Certificate

The provided `install-cert.sh` script can handle all of the setup procedure for installing an SSL certificate for use on the Apache server. Call the script with the domain, key path, and certificate path:

```bash
# Perform setup and configuration necessary to install the given certificate on the server.
./setup/install-cert.sh test.dev /path/to/key.key /path/to/cert.crt
```

> It is important to note, that when accessing a local HTTPS site, it cannot be accessed through the use the local virtual IP address. Instead, the domain you visit should be routed to the virtual IP instead, typically through the use of a modified `hosts` file.

## Further Considerations

### Configuration Files

Apache and PHP configurations are copied on initial provisioning, with some configuration defaults set to meet Craft's requirements. In addition, there is a PostgreSQL configuration that is included and copies on first activation of PostgreSQL in an instance.

#### FileMutex.php

Yii relies on file-based locking in order to prevent multiple PHP scripts from executing the same code at the same time. Unfortunately, while Yii correctly guesses that it is running on a Unix-based system, it uses Unix-based file locking, which will throw errors when used in a Windows host (with the virtual box file system used as the workspace). To prevent these issues, a custom-modified mutex file has been created solely for development within the virtual environment that fixes the issue. It is copied on initial setup of Craft, if it detects that the copy being replaced matches the most recent known copy. Otherwise, an error will be displayed during Craft install, and the file will have to be manually updated and copied.

### Script Documentation

All shell scripts and the Vagrantfile itself are fully documented for reference. It should be relatively self-explanatory what kinds of setup goes into each stage of the setup process.

### Preserving Workspace

Because the workspace is deleted upon reset of craft and initialization of a new Vagrant instance, if the Vagrant instance is destroyed, it is recommended to recover any necessary files before starting a new instance in the same folder.

## Doomsday Scenarios

### Provisioning script running a second time on `vagrant up`

This can happen when VirtualBox loses its VM configurations, and Vagrant cannot find a VM with the previous provided ID. When this happens, Vagrant will instruct VirtualBox to create a brand new VM and rerun provisioning all over again. There is a check in place to make sure that the `workspace` folder isn't recreated when this happens. In this case, check your VirtualBox configuration, and re-add the VMs if possible, and remove the erroneously created VM. You will also need to follow the instructions in the next two sections.

### Update Vagrant Folder to Point to a Different VM Instance

When a new VM is created in an environment folder, its `.vagrant/machines/default/virtualbox/id` file will be updated to point to the new VM in VirtualBox. In order to point the environment to a different VM, in the case of the above scenario, you must find your VM's `.vbox` file, and copy the `Machine`'s `uuid` into this `id` file.

### Authentication Failure When Running `vagrant up`

It is possible, if the `.vagrant/machines/default/virtualbox/private_key` file becomes invalid or lost, that Vagrant will be unable to connect to the running VirtualBox VM instance. In order to regain access, one option is discarding the private key and using Vagrant's default key, causing it to regenerate a new one on next startup. Start by deleting the `private_key` file, and then running the VM through the VirtualBox console. Log in with the default credentials of `vagrant` / `vagrant`. Navigate to the `~/.ssh` directory, and delete the `authorized_keys` file. Download the key to this directory by running `wget https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub`. Rename this file with `mv vagrant.pub authorized_keys`. Change the file permissions to those required by `authorized_keys` by running `chmod 600 authorized_keys`. Finally, shut down the VM, and then run Vagrant with `vagrant up --no-provision`.

> Note that `wget` doesn't exist on CentOS by default, so you'll need to run `sudo yum install wget` first.

> Also note that by default, Vagrant will re-run provisioning if it detects a missing key, in addition to simply regenerating it.

## Contents

Listed here are all the parts you need to know about your new Vagrant environment and Craft installation.

```
/.vagrant - Temporary working folder for Vagrant providers, stores configuration information, keys, etc. Generated and managed by Vagrant. Don't delete this if you have an active virtual machine tied to this folder.
	/.vagrant/machines/default/virtualbox/private_key - Likely the only file here you will need to worry about. The default location of the vagrant user's SSH key used for tunneling from host to guest.
/setup - Storage for scripts and utility files used by Vagrant automatically and available for use manually to vacilitate development. All scripts are documented.
	app.php - Craft CMS app configuration that force loads the LoginHelper module.
	ca-config.conf - A base configuration for creating a CA certificate to use in signing local development scripts.
	craft-reset.sh - Deletes any existing craft environment/database and creates a new one from scratch, faster than restroying and recreating a whole box. THIS DELETES THE ENTIRE WORKSPACE FOLDER.
	FileMutex.php - See the section above in [Further Considerations](#further-considerations)
	generate-ca-cert.sh - A reference script for generating a CA root SSL certificate.
	generate-cert.sh - A reference script for generating an SSL certificate for HTTPS use on a local domain.
	httpd.conf - Default Apache configuration used during provisioning.
	init.sh - Main Vagrant provisioning script.
	install-cert.sh - Installs an SSL certificate for HTTPS use.
	LoginHelper.php - Yii module automatically installed to extend the login page with some ease of access features for development.
	pg_hba.conf - PostgreSQL authentication configuration, allows user accounts to login with plain username/password combinations, instead of having to be tied to OS users.
	php.ini - PHP configuration used during provisioning.
	phpcs.xml - Recommended PHP CodeSniffer ruleset, enforcing tabs versus spaces.
	phpcs-documentation.xml - A PHP CodeSniffer ruleset that enforces documentation blocks.
	phpcs-samelinebraces.xml - A PHP CodeSniffer ruleset that enforces same-line braces.
	php-dev-init.sh - Installs and sets up PHP development tools on the guest box. Good for plugin development.
	plugin-install.sh - Installs Composer dependencies from a git repository.
	plugin-remove.sh - Uninstalls Composer dependencies.
	plugin-update.sh - Attempts to update a Composer dependency from the original repository.
	site-config.conf - A base configuration for createing a self-signed SSH certificates with a CA certificate for use within the local development environment.
	site-setup.sh - Clones a site repository over an existing fresh craft install.
	start.sh - Vagrant post-startup script.
	use-mysql.sh - Destroys the current Craft install and creates a new one using MySQL.
	use-postgresql.sh - Destroys the current Craft install and creates a new one using PostgreSQL.
/workspace - Synchronized to the virtual box's /var/www folder, used as a workspace for Craft sites and plugins. THIS IS DELETED ON VAGRANT DESTROY AND CRAFT RESET.
	/config - Craft configuration.
	/html - The public web root folder.
	/modules - Custom Yii modules for Craft.
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
