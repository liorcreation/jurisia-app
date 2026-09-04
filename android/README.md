# Signature de release Android

`flutter build apk --release` / `flutter build appbundle --release` signent
désormais avec une **vraie clé de release** (`upload-keystore.jks`,
alias `upload`) au lieu de la clé debug — condition nécessaire pour publier
sur le Play Store.

## Fichiers, jamais versionnés (voir `.gitignore`)

- `android/upload-keystore.jks` — le magasin de clés.
- `android/key.properties` — les mots de passe + le chemin du magasin.

**⚠️ Sauvegardez ces deux fichiers en lieu sûr, hors de ce dépôt**
(gestionnaire de mots de passe, coffre-fort chiffré…). Les perdre revient à
perdre la capacité de publier une mise à jour de l'app sous la même
identité de signature sur le Play Store — il n'y a pas de « mot de passe
oublié » pour un magasin de clés.

## Comportement sans ces fichiers

Un poste de développement neuf, ou la CI, n'a pas `key.properties` : la
build de release retombe alors silencieusement sur la signature **debug**
(comme avant cette mise en place) — `flutter run --release` continue de
fonctionner sans rien configurer. Seule une vraie soumission au Play Store
exige la clé de release.

## Régénérer le magasin de clés (une seule fois, sur un poste de confiance)

```
cd android
keytool -genkeypair -v \
  -keystore upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Puis créer `android/key.properties` :

```
storePassword=<mot de passe du magasin>
keyPassword=<mot de passe de la clé>
keyAlias=upload
storeFile=upload-keystore.jks
```

## Vérifier l'empreinte du certificat de release

Utile pour toute configuration qui a besoin de l'empreinte SHA-1 / SHA-256
(ex. Google Sign-In, App Signing du Play Store) :

```
"$ANDROID_SDK/build-tools/<version>/apksigner" verify --print-certs \
  build/app/outputs/flutter-apk/app-release.apk
```

## Play Store — App Signing

Au premier envoi sur le Play Store, activez **Play App Signing** : Google
conserve alors la clé finale de signature de l'app, et `upload-keystore.jks`
ne sert plus qu'à signer les envois vers la console (une clé d'upload peut
être remplacée sur demande à Google si elle est un jour compromise ou
perdue — pas la clé finale).
