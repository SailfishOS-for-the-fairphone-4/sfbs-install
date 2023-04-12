# sfbs-install
An installer script if you are too lazy to execute all the setup steps yourself. This script will set up a complete SailfishOS build environmen and builds all the components needed for flashing Sailfish to your device!

## Quick start
In case you haven't already, you should configure git with the basics:
```bash
git config --global user.name "Your Name"
git config --global user.email "youremail@example.com"
git config --global color.ui "auto"
```

Setup SSH for github (The project uses SSH):
```bash
ssh-keygen
```

The last step is adding the public SSH-key to your own GitHub (Here's a [link](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account?platform=windows) if you need help ):
```bash
cat ~/.ssh/id_rsa.pub
```

Then get the `sfbs-installer` (also another check if SSH is set up correctly):
```bash
git clone git@github.com:SailfishOS-for-the-fairphone-4/sfbs-install.git
cd sfbootstrap
```
## Run the Script
```bash
# For a complete install
source setup.sh
```
Here are some commandline-arguments you could use:

| cmd-argument | Description |
| -----------  | ----------- |
| -h, --help            | How to use the script?       |
| -p, --install-all-packages           | Install all needed packages (only for apt)        |
| -i, --install         | Start the main build process      |
| -v, --version         | Get the current sfbs-install version      |



## Files read from host environment
* `~/.gitconfig` (reused for `repo` in HA build chroot for automation etc.)
* `~/.ssh/id_rsa.pub` (used for setting up SSH  with GitHub)


Sfbs-install is inspired by [this repository](https://github.com/JamiKettunen/sfbootstrap/tree/28d3f685db04a203242a14363cee30f74eab7a65). We modified/patched the script so it would also work for the Fairphone 4.
