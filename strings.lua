local descEn = [[An open-cut station with side passes and over passes, with retaining wall as track asset.
Features:
* From 2 to 12 tracks
* From 40m to 480m platform lengths
* Options to have different layout of passes and tram tracks.
* Available from 1980
* With retaining wall as track asset.

To be implemented:
* Entry from side passes.

Known Issue
* Terrain calculate error when the station is rebuilt. (It's a game bug)

=== WARNING ===
This version 0.9 is pre-release beta, available for testing, preview and collection feedback.
Please take attention to use it with your important game saves.
=== WARNING ===

---------------
Changelog
0.9
Pre-release beta
--------------- 
* Planned projects 
- Curved station 
]]

local descFr = [[Une gare dans la traché ouvert, avec passages-pont et passages en parallèle.
Caractéristiques:
* Longueur de platformes de 40m jusqu'à 480m
* De 2 jusqu'à 12 voies
* Options pour plusieurs configuration des passages et voie de tram.
* Disponible depuis 1980

À implémenter
* Entrée depuis la passage-pont

Problème connu
* Erreur de calculs de trarrain lors la reconstuction de la gare.(It s'agit un bug de jeux.)

=== ATTENTION ===
C'est la verison 0.9 pour teste et collection des opinions, donc pontentielment il consiste de bug.
Veuillez être prudent lors utilisation avec votre sauvegarde important! 
]]

local descZh = [[一种设置在地堑结构中的车站，可以同时设置平行或者交错的街道。
特点：
* 站台长度从40米到480米
* 二至十二条股道
* 多种街道和有轨电车选项
* 1990年起可用

 将实现内容
 * 过站街道的车站入口

 已知问题
 * 重建车站时地面高度计算错误（游戏BUG）

 === 注意 ===
 该版本为0.9测试版本，请谨慎使用！
]]

function data()
    return {
        en = {
            ["name"] = "Open-cut station",
            ["desc"] = descEn
        },
        fr = {
            ["name"] = "Gare dans tranché ouvert",
            ["desc"] = descFr,
            ["Number of tracks"] = "Nombre de voies",
            ["Track Layout"] = "Disposition de voie",
            ["Platform length"] = "Longeur de plateforms",
            ["Depth"] = "Profondeur",
            ["Overpasses"] = "Passages-pont",
            ["None"] = "Aucun",
            ["Side Passes"] = "Passages en parallèle",
            ["Street Type"] = "Type de passage",
            ["Height Adjustment"] = "Ajustement d'hauteur",
            ["Left"] = "Gauche",
            ["Right"] = "Droite",
            ["Slope"] = "Pente",
            ["Modify terrain"] = "Modification de terrain",
            ["Concrete Retaining Wall"] = "Mur de soutènement en béton"

        },
        zh_CN = {
            ["name"] = "地堑结构车站",
            ["desc"] = descZh,
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
            ["Concrete Retaining Wall"] = "护土墙"
        },
    }
end
