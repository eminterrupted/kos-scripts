parameter _bf is "bl_51.ks".

set arcBF to "0:/boot/" + _bf.
set locBF to "/boot/" + _bf.
copyPath(arcBF, locBF).
wait 0.01.
set Core:BootFileName to locBF.// if exists(Path(locBF)) else arcBF.
reboot.