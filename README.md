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

If using Windows, it's recommended to get 1.9.6 to avoid incompatibility issues with older versions of powershell. This may not entirely be the case any more, but just in case a newer version doesn't work, 1.9.6 is a safe version to roll back to.

Vagrant can be found here: https://www.vagrantup.com/downloads.html

### Install VirtualBox

Vagrant (as of writing) is not compatible with VirtualBox 5.2 or later, so it's best to use the latest 5.1 release.

VirtualBox can be found here: https://www.virtualbox.org/wiki/Downloads

### Vagrant Setup

> When referencing the **Vagrant environment folder**, this readme means the folder containing your `Vagrantfile`. Any `vagrant` commands should be run from this folder.

Before starting up the VM, there are a few additional steps to get Vagrant where needed. Open a shell/prompt and do the following:

Run `vagrant plugin install vagrant-vbguest` to ensure the VirtualBox tools are installed on the guest OS when initialized.

Run `vagrant plugin install vagrant-triggers` to add script trigger hooks that are used to help teardown the environment when the VM is destroyed.

### VM Setup

Open a shell/prompt and navigate to the Vagrant environment folder. Run `vagrant up` to start the guest virtual machine. The initial install process will take a while as it downloads the CentOS image, installs several packages, makes configuration changes, and ultimately sets up Craft.

That's all you need to do, once finished your Craft installation will be ready to use at [192.168.33.10](http://192.168.33.10/admin). The default Craft username is **admin** and the password is **craftdev**.

Keep in mind that the initial install of craft (at least the release candidate versions) will not come with any default sections/fields/templates, and thus 404 on visiting anything but the control panel.

> Because Craft 3 is still under active development, it is possible that the current version installed does not function, if this is the case, you will need to either report an issue and wait, or manually make adjustments to the Composer install script in order to pull a specific tagged version.

## VM Usage

To shut down, restart, or completely delete the VM, use `vagrant halt`, `vagrant reload`, and `vagrant destroy`, respectively. **Do not use `reboot` via SSH to reboot the machine** as it will not remount shared folders.

> If you want a quick way to reset Craft's database and workspace without destroying the Vagrant box and rebuilding it, while in the guest's terminal, you can run `/setup/craft-reset.sh`, which will drop the database, delete _everything_ from the web folder, and redownload/reinstall craft.

### Web Access

The virtual address for the vagrant machine is `192.168.33.10`, and thus visiting this address in a web browser on the same local machine will take you to the Craft installation. The web port is also forwarded through your local network on port 8081. Anyone else on your network can visit your local craft install by visiting your IP on this port (similar to [127.0.0.1:8081](http://127.0.0.1:8081/admin)).

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

[Craft recommends following these coding standards](https://github.com/craftcms/docs/blob/master/en/coding-guidelines.md). These guidelines note following the PSR-1 coding standard & PRS-2 coding style. To help facilitate code consistency, it is recommended to use the PHP CodeSniffer tool, which will find and can automatically fix inconsistencies with these rules. For convenience, there is a `php-dev-init.sh` script provided that can be run within the guest in order to install and set up the tool quickly. It is recommended to run this before every commit, to ensure code consistency.

To run the tool on some code, run the following on the guest:

```bash
# Run this only once on a guest to set up PHP development tools.
/setup/php-dev-init.sh
# Run PHPCS on code to see style warnings and errors.
phpcs /path/to/code
# Run PHPCBF on code to automatically fix style errors where possible.
phpcbf /path/to/code
```

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

## Contents

Listed here are all the parts you need to know about your new Vagrant environment and Craft installation.

```
/.vagrant - Temporary working folder for Vagrant providers, stores configuration information, keys, etc. Generated and managed by Vagrant. Don't delete this if you have an active virtual machine tied to this folder.
	/.vagrant/machines/default/virtualbox/private_key - Likely the only file here you will need to worry about. The default location of the vagrant user's SSH key used for tunneling from host to guest.
/setup - Storage for scripts and utility files used by Vagrant automatically and available for use manually to vacilitate development. All scripts are documented.
	app.php - Craft cms app configuration that force loads the LoginHelper module.
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
