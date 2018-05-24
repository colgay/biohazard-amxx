#include <amxmodx>
#include <biohazard>

public plugin_precache()
{
    new index = bio_register_zclass("Zombie", "Balanced", "zombie");
    bio_register_zclass_model(index, "slum", "models/v_knife_zombie.mdl");
    bio_register_zclass_attr(index, 1000.0, 240.0, 1.0, 1.0);

    index = bio_register_zclass("Speed", "Fast", "speed");
    bio_register_zclass_model(index, "stalker", "models/v_knife_zombie.mdl");
    bio_register_zclass_attr(index, 700.0, 280.0, 1.0, 1.75);

    index = bio_register_zclass("Strong", "More HP", "strong");
    bio_register_zclass_model(index, "hulk", "models/v_knife_zombie.mdl");
    bio_register_zclass_attr(index, 2500.0, 225.0, 1.0, 0.5);

    index = bio_register_zclass("Light", "Gravity", "light");
    bio_register_zclass_model(index, "leaper", "models/v_knife_zombie.mdl");
    bio_register_zclass_attr(index, 500.0, 250.0, 0.7, 2.0);
}

public plugin_init()
{
    register_plugin("[BIO] Test Zombie Classes", "0.1", "Holla");
}