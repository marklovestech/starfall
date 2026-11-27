###    Resource Name
---    -----------------------------
001    copper ore
002    pure copper
003    gold ore
004    gold bullion
005    iron ore
006    pure iron
007    gems
008    lead ore
009    pure lead
010    zinc ore
011    pure zinc
012    mercury ore
013    pure mercury
014    poor coal
015    rich coal
016    aluminum ore
017    pure aluminum
018    tin ore
019    pure tin
020    magnesium ore
021    pure magnesium
022    salt
023    strontium
024    clay
025    sulphur
026    Gravitic Mineral Det. Equip.
027    Magnetic Mineral Det. Equip.
028    Seismic Mineral Det. Equip.
029    Chemical Mineral Det. Equip.
030    Horse and plow team
031    Small farming combine
032    Automatic combine machine
033    Mining Equip.
034    Oxide refinery
035    Sulphide refinery
036    food
037    seed
038    Space Shuttle
039    Huffer
040    High-speed Jet
041    Cargo Plane
042    Jeep
043    Amphibious crawler
044    Land crawler
045    Moving cargo platform
046    Small trawler
047    Medium-sized cargo ship
048    Ocean Liner/Tanker
049    Hydrofoil
050    Basic shelter
051    People
052    irrigation equip
053    ice
054    rock
055    sand
056    cacti desert
057    shrub desert
058    jungle
059    deciduous forest
060    coniferous forest
061    light forest
062    prairie
063    grassland
064    tundra
065    timber
066    arable land
067    native plants
068    rare spices
069
070
071
072
073
074
075
076
077 etc...


Resource Parameters:

Name                                    Type                  Units
--------------------------------------- --------------------- ----------
Resource Name                           String[30]            n/a
Resource Units                          String[10]            n/a
Usable for Transportation?              Y/N                   n/a
Usable for Exploration?                 Y/N                   n/a
Usable for Extraction?                  Y/N                   n/a
Usable for Development?                 Y/N                   n/a
Usable for Refining?                    Y/N                   n/a
Usable for Production?                  Y/N                   n/a
End of game score value                 integer               ea.
Cost                                    integer               credits
Number of operators needed              integer               people
Fuel usage                              integer               kilos/time unit
Empty Weight                            real                  kilos
Air Speed                               real                  blocks/time unit
Water Speed                             real                  blocks/time unit
Land Speed                              real                  blocks/time unit
Cargo Capacity                          real                  kilos
Surface Exploration Speed               real                  blocks/time unit
Subsurface Exploration Speed            real                  blocks/time unit
Mineral Extraction Speed                integer               kilos/time unit
Surface Development Speed               integer               kilos/time unit
Base Food Yield                         integer               kilos/time unit
Oxide Refining Speed                    integer               kilos/time unit
Sulphide Refining Speed                 integer               kilos/time unit
Magnetic Susceptibility Percentage      integer               0..100
Gravity Susceptibility Percentage       integer               0..100
Chemical Susceptibility Percentage      integer               0..100
Seismic Susceptibility Percentage       integer               0..100
Surface/Subsurface Resource?            Surface/Subsurface    n/a
Can this resource be Extracted?         Y/N                   n/a
Resource # made by Extraction           intege                resource #
Can this resource be Developed?         Y/N                   n/a
Resource # made by Development          integer               resource #
Can this resource be Refined?           Y/N                   n/a
Resource # made by Refinement           integer               resource #
Can this resource be Produced?          Y/N                   n/a
Typical Deposit Size                    real                  kilos
Typical Purity                          integer               0..100
Likelihood of Occurence                 integer               0..100
Deposit Contagion Ratio                 integer               0..100
Naturally Occuring?                     Y/N                   n/a
Expendable?                             Y/N                   n/a
Movable?                                Y/N                   n/a

LIST of resources and amounts to:
  EXTRACT                               resource#/real        #/units
  DEVELOP                               resource#/real        #/units
  REFINE                                resource#/real        #/units
  PRODUCE                               resource#/real        #/units


