# Configuration des Secrets GitHub Actions

Ce document explique comment configurer les secrets nécessaires pour le pipeline CI/CD de Mac7zip.

## Secrets Requis

### 1. Certificats de Signature de Code

#### CERTIFICATE_P12
- **Description** : Certificat de signature de code au format P12
- **Comment l'obtenir** :
  1. Exporter votre certificat "Developer ID Application" depuis le trousseau
  2. Convertir en base64 : `base64 -i certificate.p12 | pbcopy`
  3. Coller le résultat dans les secrets GitHub

#### CERTIFICATE_PASSWORD
- **Description** : Mot de passe du certificat P12
- **Format** : Texte brut
- **Exemple** : `mon_mot_de_passe_certificat`

### 2. Identifiants Apple Developer

#### APPLE_ID
- **Description** : Identifiant Apple Developer
- **Format** : Email
- **Exemple** : `developer@example.com`

#### APPLE_PASSWORD
- **Description** : Mot de passe Apple ID (utiliser un mot de passe d'application)
- **Format** : Texte brut
- **Note** : Utiliser un mot de passe d'application, pas le mot de passe principal

#### TEAM_ID
- **Description** : ID de l'équipe Apple Developer
- **Format** : 10 caractères alphanumériques
- **Exemple** : `ABC123DEF4`

#### DEVELOPER_ID
- **Description** : Nom complet du certificat de signature
- **Format** : Nom complet du certificat
- **Exemple** : `Developer ID Application: Votre Nom (ABC123DEF4)`

## Configuration des Secrets

### Via l'Interface GitHub

1. Aller sur la page du repository GitHub
2. Cliquer sur **Settings** > **Secrets and variables** > **Actions**
3. Cliquer sur **New repository secret**
4. Ajouter chaque secret avec son nom et sa valeur

### Via GitHub CLI

```bash
# Installer GitHub CLI
brew install gh

# Se connecter
gh auth login

# Ajouter les secrets
gh secret set CERTIFICATE_P12 --body "$(base64 -i certificate.p12)"
gh secret set CERTIFICATE_PASSWORD --body "mon_mot_de_passe"
gh secret set APPLE_ID --body "developer@example.com"
gh secret set APPLE_PASSWORD --body "mot_de_passe_app"
gh secret set TEAM_ID --body "ABC123DEF4"
gh secret set DEVELOPER_ID --body "Developer ID Application: Votre Nom (ABC123DEF4)"
```

## Vérification de la Configuration

### Test des Secrets

```bash
# Vérifier que les secrets sont configurés
gh secret list

# Tester la signature de code localement
codesign --force --deep --sign "Developer ID Application: Votre Nom" Mac7zip.app

# Tester la notarisation
xcrun notarytool submit Mac7zip.dmg \
  --apple-id "developer@example.com" \
  --password "mot_de_passe_app" \
  --team-id "ABC123DEF4" \
  --wait
```

## Dépannage

### Erreurs de Signature

- **"No identity found"** : Vérifier que DEVELOPER_ID correspond exactement au nom du certificat
- **"Invalid certificate"** : Vérifier que CERTIFICATE_P12 est correctement encodé en base64
- **"Wrong password"** : Vérifier CERTIFICATE_PASSWORD

### Erreurs de Notarisation

- **"Invalid credentials"** : Vérifier APPLE_ID et APPLE_PASSWORD
- **"Team not found"** : Vérifier TEAM_ID
- **"App not found"** : Vérifier que l'application est correctement signée

### Erreurs de Build

- **"Xcode not found"** : Vérifier que le runner macOS a Xcode installé
- **"7zz binary not found"** : Vérifier que le binaire 7zz est présent dans le repository

## Sécurité

### Bonnes Pratiques

1. **Ne jamais commiter les certificats** dans le repository
2. **Utiliser des mots de passe d'application** pour Apple ID
3. **Roter régulièrement** les certificats et mots de passe
4. **Limiter les permissions** des secrets aux workflows nécessaires
5. **Surveiller l'utilisation** des secrets dans les logs

### Rotation des Secrets

```bash
# Mettre à jour un secret
gh secret set CERTIFICATE_PASSWORD --body "nouveau_mot_de_passe"

# Supprimer un secret
gh secret delete CERTIFICATE_PASSWORD
```

## Support

Pour toute question sur la configuration des secrets :

1. Consulter la [documentation GitHub Actions](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
2. Consulter la [documentation Apple Developer](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
3. Ouvrir une issue sur le repository GitHub
