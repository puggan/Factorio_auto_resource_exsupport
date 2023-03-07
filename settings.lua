data:extend({
    {
        type = "bool-setting",
        name = "show-resources-with-0",
        setting_type = "runtime-global",
        default_value = false
    },
    {
        type = "string-setting",
        name = "preferred-fuel",
        setting_type = "runtime-global",
        default_value = "coal",
        auto_trim = true
    },
    {
        type = "int-setting",
        name = "max-item",
        setting_type = "startup",
        default_value = "2000",
        auto_trim = true
    },
    {
        type = "int-setting",
        name = "max-liquid",
        setting_type = "startup",
        default_value = "25000",
        auto_trim = true
    },
})