# Projet d'un compilateur Langage Facile vers Langage CIL ( transpilateur ) 

  ## Description: 
    Le but de ce projet est de créer un compilateur du langage Facile ( Donné par nos professeurs ) 
    vers le Langage CIL ([Common Intermediate Langage](https://fr.wikipedia.org/wiki/Common_Intermediate_Language)) 
    afin de pouvoir utiliser le compilateur de ce langage afin de pouvoir compiler et executer des programmes
    rédiger en langage Facile.
    Pour cela nous utilisons un ensemble d'outils qui nous permettent de conduire
    les différentes phase de la compilation.
    
  ### Les phases executées sont les suivantes:
      
      - Analyse lexicale      -> lecture du flux entrant
                              -> Identification des mots clés via DAF  
                              -> Transformation du flux entrant en la suite des tokens reconnu
      - Analyse Syntaxique    -> Lecture du flux de token
                              -> Vérifie si le flux de token respecte la grammaire du langage
                                  via les règles de production (autre nom des règles de grammaire)
                              -> Génération d'un arbre syntaxique
      - Analyse Sémentique    -> Utiliser les régles sémantiques pour transformer l'arbre syntaxique en arbre sémantique
                              -> Calcul de la valeur des attributs sémantiques
                                  -> hérité (type: integer, float, string etc.)
                                  -> Synthétiser (valeur : 4, "hello world" etc.) ...
      - Production du code dans le langage cible à partir des règles sémantiques
    
  ### Mots-clés : 
      théorie des langages, lexèmes, expressions régulières (regex), automates (DAF),
      analyse lexical, analyse syntaxique, Symbole Terminal, Non Terminal, règle de production,
      Arbre Syntaxique (AST), table des valeurs, tables des erreurs, 
      automates des items arbres syntaxique, arbres sémantique.
    
  ## Outils:<br>
    - Bison:
    - Flex:
    - Mono-utils

  ### Structure et fonctions des fichiers
  ### .lex
  ### .flex
  ### .il
  ### CMakeLists.txt
  
