# Structure

Générateur 2-gramme multithreaded de tweets Trump.

## tweets

Dossier contenant les fichiers texte sous le format "part_N.txt".<br>
(Où 'N' est un entier positif)

## main.oz

Point de départ du programme.

Les paramètres sont :

Paramètre|Défaut|Description
|-|-|-|
FilesNumber|208|Le nombre de fichiers au format "part_X.txt"
ThreadsNumber|16|Le nombre de threads de la threadpool

Il y a autant de jobs que de fichiers.<br>
Un job représente un thread actif au sein de la threadpool.

Chaque job renferme :
- 1 thread dedié à la lecture [reader](#readeroz)
- 1 thread pour le parsing [parser](#parseroz)

(Le stream généré par le 1er thread est utilisé comme "input" par le 2ème)

## Reader.oz

Module permettant de lire le contenu d'un fichier.

## Parser.oz

Module permettant le parsing ligne par ligne d'un fichier.<br>
Ces lignes sont ensuite découpées en mots.<br>
Ces mots sont rassemblés en phrases.<br>
Chaque mot, de chaque phrase, est finalement envoyé au dictionnaire de prédiction.

Les paramètres sont :

Paramètre|Défaut|Description
|-|-|-|
BreakList|. : - ( ) [ ] { } , ' ! ?|Les caractères de fin de phrase
ToRemove|TBD|Pas utilisé

## PredictionDictionary.oz

Module permettant la sauvegarde des mots liés à un (1) ou deux mots (2).

- (1) prédiction basée sur une structure "1-gramme"<br>
La clé du dictionnaire est composée d'un mot.

- (2) prédiction basée sur une structure "2-gramme"<br>
La clé du dictionnaire est composée de deux mots.

Les clés sont liées à un dictionnaire de prédiction.
- La clé -> un mot
- La valeur -> un nombre d'occurrences

## GUI.oz

Module graphique.

Permet à l'utilisateur d'insérer un mot qui servira de base à la prédiction.<br>
Des boutons sont générés au fur et à mesure afin de permettre à l'utilisateur
de choisir une prédiction se basant sur le dernier mot (1-gramme) ou les 2 derniers
mots (2-gramme).<br>
A tout moment l'utilisateur peut créer une nouvelle phrase en cliquant sur "NEXT".
