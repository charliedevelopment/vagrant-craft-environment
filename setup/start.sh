# This script runs after every restart of the box.
# Do not run this script manually, Vagrant does this for you.

### Start Apache

# We manually start Apache on each initialization to ensure it launches _after_ the shared folder is mounted
sudo systemctl start httpd.service