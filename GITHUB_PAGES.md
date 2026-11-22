# Publication ProLocker avec GitHub Pages

Ce dossier est un site statique : il se publie directement depuis la racine du dépôt, sans installation ni commande de build.

## Configuration déjà préparée

- `CNAME` contient `prolocker.fr` : il sera pris en compte par GitHub Pages une fois le domaine configuré dans les réglages du dépôt.
- `.nojekyll` empêche tout traitement Jekyll et garantit que les fichiers HTML, CSS, JavaScript et les images sont servis tels quels.
- Les URL canoniques et le sitemap utilisent les noms de pages réellement disponibles sur GitHub Pages (`.html`).

## À faire dans GitHub

1. Créer et publier le dépôt avec GitHub Desktop.
2. Dans le dépôt GitHub : **Settings** → **Pages**.
3. Choisir **Deploy from a branch**, puis `main` et `/(root)`, puis enregistrer.
4. Attendre la publication et vérifier l’URL `https://<votre-compte>.github.io/<nom-du-depot>/`.
5. Dans le même écran, saisir `prolocker.fr` dans **Custom domain**, puis enregistrer.
6. Attendre avant de modifier les DNS : GitHub doit d’abord accepter le domaine.

## DNS Hostinger à effectuer uniquement après validation GitHub

Pour `prolocker.fr` (domaine racine), créer les quatre enregistrements `A` suivants avec l’hôte `@` :

- `185.199.108.153`
- `185.199.109.153`
- `185.199.110.153`
- `185.199.111.153`

Pour `www.prolocker.fr`, créer un `CNAME` vers `<votre-compte-github>.github.io` (sans le nom du dépôt).

Après propagation, revenir dans **Settings** → **Pages**, vérifier le domaine puis activer **Enforce HTTPS**. Ne modifiez pas les enregistrements e-mail (MX, SPF, DKIM ou DMARC).

## Notes

- Le fichier `.htaccess` est ignoré par GitHub Pages. Les liens internes du site utilisent déjà les fichiers `.html` et restent donc fonctionnels.
- GitHub Pages gratuit nécessite normalement un dépôt public. Vérifiez que le dépôt ne contient aucune information confidentielle avant publication.
- La synchronisation locale ProLocker regroupe les modifications pendant 75 secondes avant de créer un commit ; son journal est stocké hors du projet dans %LOCALAPPDATA%\ProLockerGitAutoSync\sync.log.
