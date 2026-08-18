The reason there are 3, and then one install.sh that runs those three, is for if you make changes to just one of those things, and want to "install" just that.  
By install, I just mean "move the code from the directory (aka folder) pi-kiosk to where it needs to be to be run on the Raspberry Pi," so if you change anything in the code contained in the pi-kiosk directory, and want that to run instead of what you had previously installed, you can simply run the installer sctipt for that section and it will update!  

<details>
<summary>AI's version lol</summary>

There are three separate installers in this directory because each component
can be installed independently.

If changes are made to only one component of the project, you can run that
component's installer to update only that part of the Raspberry Pi.

`install.sh` is a convenience script that runs all three installers in order.

By "install", I simply mean taking the current code from this repository and
putting it where it needs to be on the Raspberry Pi. Running an installer
again updates the existing installation with the current version from the
repository.

</details>
