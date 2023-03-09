parameter _bf is "dboot.ks".

set arcBF to "0:/boot/" + _bf.
set locBF to "/boot/" + _bf.
copyPath(arcBF, locBF).
set Core:BootFileName to choose locBF if exists(Path(locBF)) else arcBF.
reboot.