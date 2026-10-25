# Big Score critical damage — P6M5-D017

User-approved live change: Big Score critical_damage_factor increases from 2 to 6. This multiplies the full current crit multiplier, including Gilded Blade. Ordinary 2x crit becomes 12x; 3x becomes 18x. Noncritical damage stays 90% weapon scaling. Cast timing stays 1800/700 ms, with no cooldown.

The tooltip reads the live factor. Gold contract regression covers 3x ordinary crit (1620 damage from a 100-damage weapon), Gilded Blade at 500 gold ((3+5)*6, 4320 damage), and unchanged noncritical damage (90). Repeated-theft fixtures explicitly bypass Pick Pocket cooldown to isolate gold accounting; live cooldown remains tested at eight seconds.

Verification: [focused suites](../project/reports/p6_d017_final/summary.json), [protected saves](../project/reports/p6_d017_final/isolation.json).

No content IDs or save revisions change. The prior D016 manifest is archived as shadow_release_manifest_pre_d017.json.
