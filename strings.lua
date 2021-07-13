local descEn = [[An open-cut station with retaining wall as track asset.
Features:
* From 2 to 12 tracks
* From 40m to 480m platform lengths
* Options to have different layout of passes and tram tracks.
* Available from 1980
* Bus/Tram stop included
* With retaining wall as track asset.
]]

local descFr = [[Une gare dans la trachée ouverte avec outil de construction pour mur de soutènement
Caractéristiques :
* Longueur de plateformes de 40m jusqu'à 480m
* De 2 jusqu'à 12 voies
* Options pour plusieurs configurations des passages et voie de tram.
* Disponible depuis 1980
* Arrêt de bus/tram intergré
* Contient un outil de construction pour mur de soutènement

]]

local descZh = [[一种设置在地堑结构中的车站，可以同时设置平行或者交错的街道。
特点：
* 站台长度从40米到480米
* 二至十二条股道
* 多种街道和有轨电车选项
* 1980 年起可用
* 公交车站选项
* 带有护土墙建造工具
 
]]

function data()
    return {
        en = {
            MOD_NAME             = "Open-cut Station & Retaining Wall",
            MOD_DESC             = descEn,
            MENU_NAME            = "Open-cut station",
            MENU_DESC            = "An open-cut station with passes options",
            MENU_TRACK_NR        = "Number of tracks",
            MENU_TRACK_LAYOUT    = "Track Layout",
            MENU_PLATFORM_LENGTH = "Platform length",
            MENU_DEPTH           = "Depth",
            MENU_OVERPASS        = "Overpasses",
            MENU_NONE            = "None",
            MENU_STREET_TYPE     = "Street Type",
            MENU_OVERPASS_ENTRY  = "Entry on overpasses",
            MENU_FREENODE        = "Free streets",
            MENU_NO_BUILD        = "Not build",
        },
        fr = {
            MOD_NAME             = "Gare dans la trachée ouverte & mur de soutènement",
            MOD_DESC             = descFr,
            MENU_NAME            = "Gare dans la trachée ouverte",
            MENU_DESC            = "Une gare dans la tranchée ouverte avec options de route de passages.",
            MENU_TRACK_NR        = "Nombre de voies",
            MENU_TRACK_LAYOUT    = "Disposition de voie",
            MENU_PLATFORM_LENGTH = "Longeur de plateformes",
            MENU_DEPTH           = "Profondeur",
            MENU_OVERPASS        = "Pont-routes",
            MENU_NONE            = "Aucun",
            MENU_STREET_TYPE     = "Type de passage",
            MENU_OVERPASS_ENTRY  = "Entrée sur pont-route",
            MENU_FREENODE        = "Voie à la destruction libre",
            MENU_NO_BUILD        = "Ne pas construire"
        },
        zh_CN = {
            MOD_NAME             = "地堑结构车站和护土墙",
            MOD_DESC             = descZh,
            MENU_NAME            = "地堑结构车站",
            MENU_DESC            = "一座设置在地堑结构中的车站，可以同时设置平行或者交错的街道。",
            MENU_TRACK_NR        = "轨道数量",
            MENU_TRACK_LAYOUT    = "轨道布局",
            MENU_PLATFORM_LENGTH = "站台长度",
            MENU_DEPTH           = "深度",
            MENU_OVERPASS        = "过站街道",
            MENU_NONE            = "无",
            MENU_STREET_TYPE     = "街道类型",
            MENU_OVERPASS_ENTRY  = "街道进站口",
            MENU_FREENODE        = "可自由修改道路",
            MENU_NO_BUILD        = "不建造"
        },
    }
end
