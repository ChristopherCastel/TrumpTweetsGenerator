# Structure du projet

## tweets

Dossier contenant les fichiers texte sous le format "part_N.txt".
Ou 'N' est un entier positif.

## main.oz

Point de depart du programme.

Les parametres sont :

Parametre|Defaut|Description
|-|-|-|
FilesNumber|208|Le nombre de fichiers au format "part_X.txt"
ThreadsNumber|16|Le nombre de threads de lecture (et parsing)

Les fichiers sont repartis en plusieurs batches de taille egale.<br>
Le nombre de batches depend du nombre de threads disponibles.<br>

Chaque batch est traité par deux threads :
- 1 thread dedie a la lecture [Reader.oz](#Reader.oz)
- 1 thread pour le parsing [Parser.oz](#Parser.oz)

(Le stream genere par le 1er thread est utilise comme "input" par le 2eme)

## Reader.oz

Module permettant de lire un batch de N fichiers.

## Parser.oz

Module permettant le parsing ligne par ligne d'un fichier.<br>
Ces lignes sont ensuite decoupees en mots puis phrases.<br>
Chaque mot, de chaque phrase, est finalement envoye au dictionnaire.

Les parametres sont :

Parametre|Defaut|Description
|-|-|-|
BreakList|. : - ( ) [ ] { } , ' ! ?|Les caracteres de fin de phrase
ToRemove|TBD|Pas utilise

## PredictionDictionary.oz

Module permettant la sauvegarde des mots lies a un (1) ou deux mots (2).

- (1) prediction basee sur une structure "1-gramme"<br>
La cle du dictionnaire est composee d'un mot.

- (2) prediction basee sur une structure "2-gramme"<br>
La cle du dictionnaire est composee de deux mots.

Les cles sont liees a un dictionnaire de prediction.
- La cle -> un mot
- La valeur -> un nombre d'occurrences

## GUI.oz

Module graphique.

Permet a l'utilisateur d'inserer un mot qui servira de base a la prediction.<br>
Des boutons sont generes au fur et a mesure afin de permettre a l'utilisateur
de choisir une prediction se basant sur le dernier mot (1-gramme) ou les 2 derniers
mots (2-gramme).<br>
A tout moment l'utilisateur peut creer une nouvelle phrase en cliquant sur "NEXT".
