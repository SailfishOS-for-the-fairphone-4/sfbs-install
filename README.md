# sfbs-install
An installer script if you are too lazy to execute all the setup steps yourself.

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

Then get the `sfbs-installer`:
```bash
git clone git@github.com:SailfishOS-for-the-fairphone-4/sfbs-install.git
cd sfbootstrap
```
### Existing (Hybris) ports
These are all the commands you need to perform a clean install of the Sailfish environment for the Fairphone 4.

```bash
# to choose your device interactively:
./sfbootstrap.sh init
./sfbootstrap.sh chroot setup
./sfbootstrap.sh sync
./sfbootstrap.sh build hal
./sfbootstrap.sh build packages
```

## Files read from host environment
* `~/.gitconfig` (reused for `repo` in HA build chroot for automation etc.)
