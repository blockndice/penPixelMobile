# PenPixel — Pixel Drawing Puzzle

Un jeu de puzzle de dessin par pixels, développé pour **mobile** (Android & iOS) avec le framework **[Solar2D](https://solar2d.com/)** en **Lua**.

## Concept

Le joueur doit colorier une grille pixel par pixel pour reconstituer un dessin caché. Chaque puzzle propose un nombre limité de pixels par couleur, affichés dynamiquement.  
Un mode solution est disponible pour débloquer le dessin en cas de blocage.

## Fonctionnalités

- Sélection de couleur avec molette
- Pose et suppression de pixels
- Compteur dynamique des pixels restants par couleur
- Repères colonne / ligne sur la grille interactive
- Mode solution avec animation arc-en-ciel
- Écran titre et écran de sélection des dessins
- Animations lors de la pose ou du retrait d'un pixel
- Support multi-puzzles organisés en pages

## Stack technique

| Élément | Technologie |
|---|---|
| Langage | Lua |
| Framework | Solar2D (Corona SDK) |
| Cibles | Android, iOS |
| Orientation | Paysage (landscapeRight) |

## Structure du projet

```
paintGame/
├── main.lua              # Point d'entrée
├── build.settings        # Configuration de build (Android / iOS)
├── config.lua            # Configuration de l'affichage
├── data/                 # Données des puzzles (drawMap)
├── module/               # Modules réutilisables (animation, compass, etc.)
├── swapScreen/           # Gestion des écrans (titre, sélection, dessin)
├── img/                  # Assets graphiques
├── AndroidResources/     # Icônes Android
└── Images.xcassets/      # Icônes iOS
```

## Lancer le projet

1. Installer [Solar2D](https://solar2d.com/)
2. Ouvrir le dossier `paintGame/` depuis le simulateur Solar2D
3. Sélectionner le device cible (Android ou iOS)
