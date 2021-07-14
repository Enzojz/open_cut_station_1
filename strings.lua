local descEn = [[This is the opencut station convert and improved from mod for Tpf1 with the same name. Some improvements are done with the features of the game.
Original Features:
* From 2 to 12 tracks
* From 40m to 480m platform lengths
* Options to have different layout of passes and tram tracks.
* With retaining wall as track asset.

Improvements:
* 3rd party tracks are available
* All streets are available as overpasses
* Street catch system makes the mod with less options but more flexible
* Improved material shading
* New choices to main entrance building
* New choices to retaining walls
* New choices to platform styles
]]

local descFr = [[Ce mod est une conversion puis amélioration du mod de même nom de Tpf1.
Caractéristiques originals :
* Longueur de plateformes de 40m jusqu'à 480m
* De 2 jusqu'à 12 voies
* Options pour plusieurs configurations des passages et voie de tram.
* Contient un outil de construction pour mur de soutènement

Améliorations:
* les voies de 3e partie sont disponbiles
* Tous les type de routes sont disponbiles pour les passages aériennes
* Le mod profit de système de liaison automatique pour réduire les options avec une encore meilleur flexibilté
* Amélioration sur les rendues des certains matériels
* Nouvelle choix pour BV
* Nouvelle choix pour les murs de soutènements
* Nouvelle choix pour les plateformes
]]

local descSc = [[本模组由Tpf1同名模组转换而来，并且利用Tpf2的游戏特性做出了一些改进
原特点：
* 站台长度从40米到480米
* 二至十二条股道
* 多种街道和有轨电车选项
* 带有护土墙建造工具

改进内容:
* 可以选择所有的第三方轨道
* 可以选择游戏中任意道路类型作为过街天桥
* 利用游戏的自动连接功能简化了选项，但给玩家获得了更高的自由度
* 更好的材质
* 可以选择的车站入口
* 可以选择的挡土墙风格
* 可以选择的站台类型
]]


local descTc = [[本模组由Tpf1同名模组转换而来，并且利用Tpf2的游戏特性做出了一些改进
原特点：
* 站台长度从40米到480米
* 二至十二条股道
* 多种街道和有轨电车选项
* 带有护土墙建造工具

改进内容:
* 可以选择所有的第三方轨道
* 可以选择游戏中任意道路类型作为过街天桥
* 利用游戏的自动连接功能简化了选项，但给玩家获得了更高的自由度
* 更好的材质
* 可以选择的车站入口
* 可以选择的挡土墙风格
* 可以选择的站台类型
]]

function data()
    return {
        en = {
            MOD_NAME                 = "Open-cut Station & Retaining Wall",
            MOD_DESC                 = descEn,
            MENU_NAME                = "Open-cut station",
            MENU_DESC                = "An open-cut station with passes options",
            MENU_TRACK_NR            = "Number of tracks",
            MENU_TRACK_LAYOUT        = "Track Layout",
            MENU_PLATFORM_LENGTH     = "Platform length(m)",
            MENU_DEPTH               = "Depth(m)",
            MENU_OVERPASS            = "Overpasses",
            MENU_NONE                = "None",
            MENU_STREET_TYPE         = "Street Type",
            MENU_OVERPASS_ENTRY      = "Entry on overpasses",
            MENU_FREENODE            = "Free streets",
            MENU_NO_BUILD            = "Not build",
            MENU_WALL_STYLE          = "Wall Type",
            MENU_PLATFORM_ERA        = "Platform Era",
            MENU_ERA_A               = "Era A",
            MENU_ERA_B               = "Era B",
            MENU_ERA_C               = "Era C",
            MENU_ENTRY_TYPE          = "Entry type",
            MENU_CATENARY            = "Catenary",
            MENU_TRACK_TYPE          = "Track Type",
            MENU_WALL_NAME           = "Retaining Wall",
            MENU_WALL_DESC           = "Retaining walls for tracks with geometric options",
            MENU_WALL_LENGTH         = "Wall length(m)",
            MENU_WALL_HEIGHT         = "Wall height(m)",
            MENU_WALL_RAMP           = "Ramp height(m)",
            MENU_WALL_SLOPE          = "Slope(‰)",
            MENU_WALL_NARROWING      = "Narrowing(m)",
            MENU_WALL_TRACK_DISTANCE = "Distance to track(m)",
            MENU_WALL_THICKNESS      = "Thickness(m)",
            MENU_WALL_TERRAIN        = "Terrain Deformation",
            MENU_TRAM                = "Tram Tracks"
        },
        fr = {
            MOD_NAME                 = "Gare dans la trachée ouverte & mur de soutènement",
            MOD_DESC                 = descFr,
            MENU_NAME                = "Gare dans la trachée ouverte",
            MENU_DESC                = "Une gare dans la tranchée ouverte avec options de route de passages.",
            MENU_TRACK_NR            = "Nombre de voies",
            MENU_TRACK_LAYOUT        = "Disposition de voie",
            MENU_PLATFORM_LENGTH     = "Longeur de plateformes(m)",
            MENU_DEPTH               = "Profondeur(m)",
            MENU_OVERPASS            = "Pont-routes",
            MENU_NONE                = "Aucun",
            MENU_STREET_TYPE         = "Type de passage",
            MENU_OVERPASS_ENTRY      = "Entrée sur pont-route",
            MENU_FREENODE            = "Voie à la destruction libre",
            MENU_NO_BUILD            = "Ne pas construire",
            MENU_WALL_STYLE          = "Type de mur",
            MENU_PLATFORM_ERA        = "Type de plateformes",
            MENU_ERA_A               = "Époque A",
            MENU_ERA_B               = "Époque B",
            MENU_ERA_C               = "Époque C",
            MENU_ENTRY_TYPE          = "Type d'entrée",
            MENU_CATENARY            = "Caténaire",
            MENU_TRACK_TYPE          = "Type de voie",
            MENU_WALL_NAME           = "Mur de soutènement",
            MENU_WALL_DESC           = "Mur de soutènement pour les voie avec paramètres géométriques",
            MENU_WALL_LENGTH         = "Longueur de mur(m)",
            MENU_WALL_HEIGHT         = "Hauteur de mur(m)",
            MENU_WALL_RAMP           = "Hauteur de rampe(m)",
            MENU_WALL_SLOPE          = "Gradient(‰)",
            MENU_WALL_NARROWING      = "Rétrécissement(m)",
            MENU_WALL_TRACK_DISTANCE = "Distance vers la voie(m)",
            MENU_WALL_THICKNESS      = "Épaisseur de mur(m)",
            MENU_WALL_TERRAIN        = "Déformation du terrain",
            MENU_TRAM                = "Voie Tram"
        },
        zh_CN = {
            MOD_NAME                 = "下沉式车站和护土墙",
            MOD_DESC                 = descSc,
            MENU_NAME                = "下沉式车站",
            MENU_DESC                = "一座下沉结构中的车站，可以同时设置平行或者交错的街道。",
            MENU_TRACK_NR            = "轨道数量",
            MENU_TRACK_LAYOUT        = "轨道布局",
            MENU_PLATFORM_LENGTH     = "站台长度",
            MENU_DEPTH               = "深度",
            MENU_OVERPASS            = "过站街道",
            MENU_NONE                = "无",
            MENU_STREET_TYPE         = "街道类型",
            MENU_OVERPASS_ENTRY      = "街道进站口",
            MENU_FREENODE            = "可自由修改道路",
            MENU_NO_BUILD            = "不建造",
            MENU_WALL_STYLE          = "挡土墙类型",
            MENU_PLATFORM_ERA        = "站台类型",
            MENU_ERA_A               = "石块",
            MENU_ERA_B               = "砖块",
            MENU_ERA_C               = "地砖",
            MENU_ENTRY_TYPE          = "入口类型",
            MENU_CATENARY            = "接触网",
            MENU_TRACK_TYPE          = "轨道类型",
            MENU_WALL_NAME           = "挡土墙",
            MENU_WALL_DESC           = "有大量几何参数选项的挡土墙",
            MENU_WALL_LENGTH         = "长度(米)",
            MENU_WALL_HEIGHT         = "高度(米)",
            MENU_WALL_RAMP           = "斜面高度(米)",
            MENU_WALL_SLOPE          = "坡度(‰)",
            MENU_WALL_NARROWING      = "收窄(米)",
            MENU_WALL_TRACK_DISTANCE = "到轨道距离(米)",
            MENU_WALL_THICKNESS      = "厚度(米)",
            MENU_WALL_TERRAIN        = "改变地形",
            MENU_TRAM                = "有轨电车轨道"
        },
        zh_TW = {
            MOD_NAME                 = "下沉式車站和護土牆",
            MOD_DESC                 = descTc,
            MENU_NAME                = "下沉式車站",
            MENU_DESC                = "一座下沉結構中的車站，可以同時設置平行或者交錯的街道。",
            MENU_TRACK_NR            = "軌道數量",
            MENU_TRACK_LAYOUT        = "軌道佈局",
            MENU_PLATFORM_LENGTH     = "月臺長度",
            MENU_DEPTH               = "深度",
            MENU_OVERPASS            = "過站街道",
            MENU_NONE                = "無",
            MENU_STREET_TYPE         = "街道類型",
            MENU_OVERPASS_ENTRY      = "街道進站口",
            MENU_FREENODE            = "可自由修改道路",
            MENU_NO_BUILD            = "不建造",
            MENU_WALL_STYLE          = "擋土牆類型",
            MENU_PLATFORM_ERA        = "月臺類型",
            MENU_ERA_A               = "石塊",
            MENU_ERA_B               = "磚塊",
            MENU_ERA_C               = "地磚",
            MENU_ENTRY_TYPE          = "入口類型",
            MENU_CATENARY            = "接觸網",
            MENU_TRACK_TYPE          = "軌道類型",
            MENU_WALL_NAME           = "擋土牆",
            MENU_WALL_DESC           = "有大量幾何參數選項的擋土牆",
            MENU_WALL_LENGTH         = "長度(公尺)",
            MENU_WALL_HEIGHT         = "高度(公尺)",
            MENU_WALL_RAMP           = "斜面高度(公尺)",
            MENU_WALL_SLOPE          = "坡度(‰)",
            MENU_WALL_NARROWING      = "收窄(公尺)",
            MENU_WALL_TRACK_DISTANCE = "到軌道距離(公尺)",
            MENU_WALL_THICKNESS      = "厚度(公尺)",
            MENU_WALL_TERRAIN        = "改變地形",
            MENU_TRAM                = "有軌電車軌道"
        },
    }
end
