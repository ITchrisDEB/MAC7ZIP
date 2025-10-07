# Mac7zip - Application d'archivage native pour macOS
*Version 1.0.76 - Application macOS native avec support multi-fenêtres*

## 📋 Description

Mac7zip est une application macOS native développée en Swift/SwiftUI qui fournit une interface graphique moderne pour 7-Zip. L'application offre une expérience utilisateur intuitive avec support complet des fenêtres multiples et localisation français/anglais.

### ✨ Fonctionnalités Principales

- **Interface SwiftUI moderne** avec support du mode sombre
- **Multi-fenêtres indépendantes** avec raccourcis clavier ciblés (@FocusedBinding)
- **Navigation hiérarchique** dans les archives avec arborescence complète
- **Localisation FR/EN** avec changement dynamique
- **Support universel** de tous les formats 7-Zip (50+ formats)
- **Chiffrement AES-256** et options de sécurité avancées

## 📦 Installation

### Prérequis
- **macOS 12.0+** (Monterey ou plus récent)
- **Apple Silicon** ou Intel
- **15 MB** d'espace disque

### Installation Simple
1. Téléchargez `Mac7zip.app` ou le DMG
2. Glissez dans le dossier **Applications**
3. Lancez depuis le Launchpad

## 🎮 Utilisation

### Raccourcis Clavier (par fenêtre)
| Raccourci | Action |
|-----------|--------|
| `Cmd+N` | Nouvelle fenêtre |
| `Cmd+O` | Ouvrir archive |
| `Cmd+B` | Nouvelle archive |
| `Cmd+E` | Extraire |
| `Cmd+I` | Propriétés |

### Multi-fenêtres
- **Fenêtres indépendantes** : Chaque fenêtre gère sa propre archive
- **Raccourcis ciblés** : Les raccourcis s'appliquent à la fenêtre active uniquement
- **Architecture @FocusedBinding** : Technologie Apple native

### Changer de Langue
1. **Mac7zip → Préférences**
2. Section **"Langue"**
3. Sélectionner **Français** 🇫🇷 ou **Anglais** 🇺🇸
4. Interface change immédiatement

## 📁 Formats Supportés

### Principaux
- **7z, ZIP, RAR, TAR, GZIP, BZIP2, XZ, LZMA**

### Système
- **DMG, ISO, CAB, MSI, PKG, XAR**

### Machines Virtuelles
- **VDI, VHD, VMDK, QCOW**

**Total : 50+ formats supportés**

## 🏗️ Architecture

```
Mac7zip/
├── Mac7zipApp.swift              # @FocusedBinding pour multi-fenêtres
├── ContentView.swift             # focusedSceneValue par fenêtre
├── ArchiveEngine.swift           # Moteur 7-Zip
├── ArchiveTreeItem.swift         # Structure hiérarchique
├── LocalizationManager.swift    # Gestionnaire FR/EN
├── Localizations/
│   ├── fr.lproj/Localizable.strings (189 clés)
│   └── en.lproj/Localizable.strings (189 clés)
└── .build/Mac7zip_1.0.44.app    # Application finale
```

## 🔧 Développement

### Compilation
```bash
# Build automatique
./build.sh

# Lancer l'application  
open .build/Mac7zip_latest.app
```

### Tests
```bash
# Tests multi-fenêtres
# 1. Cmd+N → Nouvelle fenêtre
# 2. Ouvrir archives différentes
# 3. Tester Cmd+B dans chaque fenêtre
# 4. Vérifier indépendance

# Tests localisation
# 1. Préférences → Langue → Anglais
# 2. Vérifier interface change
# 3. Redémarrer → Vérifier persistance
```

## ✅ Corrections Majeures Apportées

### Version 1.0.76 (Actuelle)
- ✅ **Menu contextuel fonctionnel** : Clic droit sur les fichiers dans l'archive fonctionne
- ✅ **Binaires 7-Zip intégrés** : Tous les binaires correctement placés dans Resources/
- ✅ **Structure DMG optimisée** : DMG avec icône, info.md et alias Applications
- ✅ **Interface améliorée** : Navigation hiérarchique complète

### Version 1.0.44
- ✅ **Multi-fenêtres @FocusedBinding** : Raccourcis clavier indépendants par fenêtre
- ✅ **Architecture Apple native** : Utilisation des meilleures pratiques SwiftUI

### Corrections Précédentes
- ✅ **Bug création 7z** : Création d'archives 7z fonctionnelle
- ✅ **Arborescence hiérarchique** : Navigation complète avec indentation
- ✅ **"Ouvrir avec Mac7zip"** : Ouverture directe depuis Finder
- ✅ **Menus contextuels** : Extraire/Propriétés opérationnels
- ✅ **Expansion dossiers** : Contenu des dossiers visible

## 📄 Licence

**Mac7zip** : Licence MIT  
**7-Zip** : Licence LGPL  
**Frameworks Apple** : Licence Apple

## 🆘 Support

- **GitHub** : https://github.com/mac7zip/mac7zip
- **Email** : support@mac7zip.app

---

**Mac7zip v1.0.76** - Solution d'archivage native pour macOS 🚀