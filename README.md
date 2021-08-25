
Cuttlefish app (screenshot) which you can install with sudo apt install plasma-sdk.


## Install and test

install:

    kpackagetool5 -t Plasma/Applet --i package
	

	kpackagetool5 -t Plasma/Applet --u package
	
    kpackagetool5 -t Plasma/Applet --r package

test:

    plasmoidviewer --applet package

    plasmoidviewer --applet package --containment org.kde.panel  -l bottomedge -s 800x100
