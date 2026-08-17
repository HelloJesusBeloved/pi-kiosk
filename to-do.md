### To-Do

- [x]Make turpats remove my old alias's

- [ ]Figure out how to actually make journalctl logs permanent and add it to turpats

- [ ] Add ntfy support to network-watchdog

- [ ] Add hide-cursor about section

- [ ] Add explanation about how I am using this whole setup with sharepoint etc. Setup and Installation sections after Introduction and About.

- [ ] Make sure network-watchdog isn't triggered when the sheduled 3am reboot happens


### Idea's

Maybe restart firefox-kiosk.service every hour instead of using a browser extension, then I wouldn't have to check the network as often, and maybe have less fales posotives? And see if there is a way to instead start a new firefox instance behind the current one, then after a wait till it is ready kill the old one, so the transition is as fast as possible. The reason this is needed in the first place is because with my setup (using a sharepoint carosel as the website it displays) the website needs to be reloaded every so often to pull potential changes to the slides throughout the day.
Note: On first test, it appears that when the Wi-Fi is disconnected it takes about 15 minutes for the website to go to an error page.
Second test went for 90 minutes +
