parameter _bf is "dboot.ks".

copyPath("0:/boot/" + _bf, "/boot/" + _bf).
set Core:BootFileName to "/boot/" + _bf.
reboot.
