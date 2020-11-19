runOncePath("0:/lib/part/lib_heatshield.ks").

set p to ship:partsTaggedPattern("heatshield")[0].
print jettison_heatshield(p).