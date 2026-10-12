LP = "[lua:4rtefakt.adaptive] "
CASES = {
    # A hit of 21 (ATK 60 against DEF 38) is 21 at first; after one death and a Retry it is 90%: 19.
    "death_eases": dict(room="S_10/S_1002/S_1002",
        drive="20:lua=ad 0;30:hurt=60;40:stats;50:hp=0;220:ok;280:ok;420:lua=ad;430:hurt=60;440:stats;441:shot;450:quit",
        expect=[LP + "level 0 rooms 0 factor 1.00", "hp 39/60", "[death] HP 0", LP + "Enemies hit at 90% (you died)",
                LP + "level 1 rooms 0 factor 0.90", "hp 41/60"], shots={"hud": 441}),
    # Three steps of help, one room per step back: each door brings the damage up one step.
    "rooms_recover": dict(room="S_10/S_1002/S_1002", settings="RoomsPerStep=1",
        drive="20:lua=ad 3;30:exit=0;200:lua=ad;210:exit=0;400:lua=ad;420:quit",
        expect=[LP + "level 3 rooms 0 factor 0.70", LP + "Enemies hit at 80% (1 rooms without dying)", LP + "level 2 ",
                LP + "Enemies hit at 90%", LP + "level 1 "]),
    # The state is outside the saves: a second boot starts where the first one ended.
    "kept": dict(room="S_10/S_1002/S_1002",
        drive="20:lua=ad 2;40:quit", drive2="20:lua=ad;30:hurt=60;40:stats;50:quit",
        expect=[LP + "level 2 ", "==== second boot", LP + "Adaptive Difficulty loaded: Enemies hit at 80%", LP + "level 2 rooms 0 factor 0.80", "hp 43/60"]),
    # Harder on a streak: one step above normal is 110%: 21 -> 23. Off: the level is clamped to normal.
    "harder": dict(room="S_10/S_1002/S_1002", settings="Harder=1",
        drive="20:lua=ad -1;30:hurt=60;40:stats;50:quit", expect=[LP + "level -1 rooms 0 factor 1.10", "hp 37/60"]),
    "not_harder": dict(room="S_10/S_1002/S_1002",
        drive="20:lua=ad -1;30:hurt=60;40:stats;50:quit", expect=[LP + "level -1 rooms 0 factor 1.00", "hp 39/60"]),
    "disabled": dict(room="S_10/S_1002/S_1002", settings="Enabled=0",
        drive="20:lua=ad 3;30:hurt=60;40:stats;50:quit", expect=["factor 1.00", "hp 39/60"]),
}
