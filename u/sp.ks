runOncePath("0:/lib/part/lib_launchpad").

mlp_gen_on().
wait 5.
mlp_fallback_open_clamp().
wait 5.
mlp_fuel_on().
wait 5.
mlp_fallback_partial().
wait 5.
mlp_fallback_full().
wait 5.
mlp_retract_holddown().