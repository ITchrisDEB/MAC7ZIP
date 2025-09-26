# MODIFICATIONS COMPRESSION TAR.GZ ET TAR.BZ2

## PROBLÈME IDENTIFIÉ

Le slider de compression ne fonctionne pas pour TAR.GZ et TAR.BZ2 car `methodsForFormat` ne retourne que "Copy" au lieu des vraies méthodes de compression.

## CODE AVANT CORRECTION

### CompressionMethods.swift - Lignes 288-302

```swift
case .tar, .gzip, .bzip2:
    return [
        CompressionMethod(
            id: "Copy",
            name: "Copy",
            description: "Aucune compression (TAR)",
            isAvailable: true,
            supportsEncryption: false,
            supportsSolid: false,
            supportsMultithreading: false,
            defaultLevel: 0,
            maxLevel: 0,  // ❌ PROBLÈME : maxLevel = 0
            minLevel: 0   // ❌ PROBLÈME : minLevel = 0
        )
    ]
```

## CONTRADICTION DANS LE CODE

### defaultMethodForFormat (lignes 197-200) - CORRECT
```swift
case .gzip:
    return CompressionMethod.method(named: "GZip") ?? methodsForFormat(format).first!
case .bzip2:
    return CompressionMethod.method(named: "BZip2") ?? methodsForFormat(format).first!
```

### methodsForFormat (lignes 288-302) - INCORRECT
```swift
case .tar, .gzip, .bzip2:
    return [CompressionMethod(id: "Copy", ...)]  // ❌ Ne retourne que "Copy"
```

## MÉTHODES EXISTANTES DANS allMethods

### GZip (lignes 165-175)
```swift
CompressionMethod(
    id: "GZip",
    name: "GZip",
    description: "Méthode de compression GZip",
    isAvailable: true,
    supportsEncryption: false,
    supportsSolid: false,
    supportsMultithreading: true,
    defaultLevel: 6,
    maxLevel: 9,    // ✅ CORRECT
    minLevel: 1     // ✅ CORRECT
)
```

### BZip2 (lignes 55-65)
```swift
CompressionMethod(
    id: "BZip2",
    name: "BZip2",
    description: "Méthode de compression BZip2 (bonne compression)",
    isAvailable: true,
    supportsEncryption: true,
    supportsSolid: true,
    supportsMultithreading: true,
    defaultLevel: 5,
    maxLevel: 9,    // ✅ CORRECT
    minLevel: 1     // ✅ CORRECT
)
```

## COMMANDES TESTÉES ET FONCTIONNELLES

### TAR.GZ
```bash
GZIP=-1 tar -czf archive.tar.gz dossier/  # Niveau 1
GZIP=-6 tar -czf archive.tar.gz dossier/  # Niveau 6
GZIP=-9 tar -czf archive.tar.gz dossier/  # Niveau 9
```

### TAR.BZ2
```bash
BZIP2=-1 tar -cjf archive.tar.bz2 dossier/  # Niveau 1
BZIP2=-6 tar -cjf archive.tar.bz2 dossier/  # Niveau 6
BZIP2=-9 tar -cjf archive.tar.bz2 dossier/  # Niveau 9
```

## CORRECTION NÉCESSAIRE

Séparer les cas dans `methodsForFormat` :

```swift
// ❌ ACTUEL
case .tar, .gzip, .bzip2:
    return [CompressionMethod(id: "Copy", ...)]

// ✅ CORRIGER VERS
case .gzip:
    return availableMethods().filter { ["GZip"].contains($0.name) }
case .bzip2:
    return availableMethods().filter { ["BZip2"].contains($0.name) }
case .tar:
    return [CompressionMethod(id: "Copy", ...)]
```

## RÉSULTAT ATTENDU

Après correction :
- **TAR.GZ** : Méthode "GZip" avec slider 1-9
- **TAR.BZ2** : Méthode "BZip2" avec slider 1-9
- **Slider fonctionnel** : 3 positions (1, 6, 9)
- **Commandes** : `GZIP=-1/-6/-9` et `BZIP2=-1/-6/-9` fonctionnelles

