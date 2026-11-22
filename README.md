# ProLocker — site vitrine statique

Cette version est une vitrine statique sans dépendance, conçue pour être ouverte localement et déployée sur un hébergement statique Hostinger.

## Lancer le site localement

Depuis ce dossier, lancez un serveur statique, par exemple :

```powershell
python -m http.server 8000
```

Puis ouvrez `http://localhost:8000`.

## Avant publication

1. Ouvrez `site-config.js` et complétez les informations juridiques et l’adresse e-mail professionnelle. Ne mettez aucune information inventée.
2. Vérifiez et faites valider les pages `mentions-legales.html`, `politique-confidentialite.html` et `conditions-generales.html` par les personnes compétentes.
3. Après avoir renseigné l’e-mail, les liens de contact ouvriront automatiquement le logiciel de messagerie avec un objet prérempli.
4. Vérifiez les textes et la photo de Louis Garcia avant publication.
5. Uploadez l’intégralité du contenu du dossier sur l’espace web public Hostinger (généralement `public_html`).
6. Dans Hostinger, rattachez le domaine à ce dossier, activez HTTPS et choisissez votre redirection préférée entre `www.prolocker.fr` et `prolocker.fr`.
7. Vérifiez sur le domaine final les pages, les images, les métadonnées et les liens. Ne modifiez jamais MX, SPF, DKIM ou DMARC dans le cadre du déploiement du site sans validation explicite.

## Fichiers importants

- `index.html` : page d’accueil et simulateur interactif.
- `entreprises.html`, `residences.html`, `fonctionnement.html`, `faq.html`, `contact.html` : pages commerciales.
- `site-config.js` : coordonnées et mentions administratives à compléter en un seul endroit.
- `styles.css` et `app.js` : design, animations accessibles et interactions.
- `assets/` : visuels fournis.
- `robots.txt` et `sitemap.xml` : base SEO.

## Notes techniques

- Aucun formulaire, cookie non essentiel, outil d’analyse ou service tiers n’est intégré.
- Le simulateur est local, transparent sur ses hypothèses et ne présente pas les résultats comme des économies garanties.
- Les animations sont désactivées pour les utilisateurs ayant activé `prefers-reduced-motion`.
