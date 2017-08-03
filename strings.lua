local descEn = [[An open-cut station with retaining wall as track asset.
Features:
* From 2 to 12 tracks
* From 40m to 480m platform lengths
* Options to have different layout of passes and tram tracks.
* Available from 1980
* With retaining wall as track asset.

Known Issue
* Terrain calculate error when the station is rebuilt. (It's a game bug)

---------------
Changelog
1.3
Fix of crash with Build 13446
1.2
Added second road connection to the station
1.1
Fixed crash problem of connection to large road entry
1.0
First release
0.9
Pre-release beta
]]

local descFr = [[Une gare dans la trachée ouverte avec outil de construction pour mur de soutènement
Caractéristiques :
* Longueur de plateformes de 40m jusqu'à 480m
* De 2 jusqu'à 12 voies
* Options pour plusieurs configurations des passages et voie de tram.
* Disponible depuis 1980
* Contient un outil de construction pour mur de soutènement

Problème connu
* Erreur de calculs de terrain lors la reconstruction de la gare.(It s'agit un bug de jeux.)

---------------
Changelog
1.3
Correction de plantage sur la version 13446
1.2
Ajoute de connexion routière secondaire.
1.1
Correction de plantage lors la connexion ver entrée du route large.
1.0
Première version
0.9
Version beta
]]

local descZh = [[一种设置在地堑结构中的车站，可以同时设置平行或者交错的街道。
特点：
* 站台长度从40米到480米
* 二至十二条股道
* 多种街道和有轨电车选项
* 1980 年起可用
* 带有护土墙建造工具

 已知问题
 * 重建车站时地面高度计算错误（游戏BUG）
 
---------------
Changelog
1.3
修正了13446版本后的崩溃问题
1.2
增加了第二入口的道路连接
1.1
修正了连接至宽马路入口时的游戏崩溃问题
1.0
正式发布
0.9
Beta测试版
]]

function data()
    return {
        en = {
            ["mod"] = "Open-cut Station & Retaining Wall",
            ["name"] = "Open-cut station",
            ["desc"] = descEn
        },
        fr = {
            ["mod"] = "Gare dans la trachée ouverte & mur de soutènement",
            ["name"] = "Gare dans la trachée ouverte",
            ["desc"] = descFr,
            ["An open-cut station with passes options."] = "Une gare dans la tranchée ouverte avec options de route de passages.",
            ["Number of tracks"] = "Nombre de voies",
            ["Track Layout"] = "Disposition de voie",
            ["Platform length"] = "Longeur de plateformes",
            ["Depth"] = "Profondeur",
            ["Overpasses"] = "Pont-routes",
            ["None"] = "Aucun",
            ["Side Passes"] = "Routes en parallèle",
            ["Street Type"] = "Type de passage",
            ["Height Adjustment"] = "Ajustement d'hauteur",
            ["Left"] = "Gauche",
            ["Right"] = "Droite",
            ["Slope"] = "Pente",
            ["Modify terrain"] = "Modification de terrain",
            ["Concrete Retaining Wall"] = "Mur de soutènement en béton",
            ["Entry on overpasses"] = "Entrée sur pont-route"
        },
        zh_CN = {
            ["mod"] = "地堑结构车站和护土墙",
            ["name"] = "地堑结构车站",
            ["desc"] = descZh,
            ["An open-cut station with passes options."] = "一座设置在地堑结构中的车站，可以同时设置平行或者交错的街道。",
            ["Number of tracks"] = "轨道数量",
            ["Track Layout"] = "轨道布局",
            ["Platform length"] = "站台长度",
            ["Depth"] = "深度",
            ["Overpasses"] = "过站街道",
            ["None"] = "无",
            ["Side Passes"] = "平行街道",
            ["Street Type"] = "街道类型",
            ["Height Adjustment"] = "高度调整",
            ["Left"] = "左",
            ["Right"] = "右",
            ["Slope"] = "坡度",
            ["Modify terrain"] = "修改地形",
            ["Concrete Retaining Wall"] = "护土墙",
            ["Entry on overpasses"] = "街道进站口"
        },
    }
end
