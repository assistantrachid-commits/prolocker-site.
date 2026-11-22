(() => {
  const path = location.pathname.split('/').pop() || 'index.html';
  const links = [
    ['index.html', 'Accueil'], ['entreprises.html', 'Entreprises'], ['residences.html', 'Résidences'],
    ['fonctionnement.html', 'Fonctionnement'], ['faq.html', 'FAQ'], ['contact.html', 'Contactez-nous']
  ];
  const active = (href) => path === href ? ' active' : '';
  const navigation = links.map(([href, label]) => {
    const isContact = label === 'Contactez-nous';
    const classes = isContact ? 'button button--small' : active(href);
    const contactData = isContact ? ' data-contact-link data-subject="Demande d’informations ProLocker"' : '';
    return `<a class="${classes}" href="${href}"${contactData}>${label}</a>`;
  }).join('');
  const header = document.querySelector('#site-header');
  if (header) header.innerHTML = `
    <a class="skip-link" href="#main">Passer au contenu</a>
    <header class="site-header">
      <nav class="nav" aria-label="Navigation principale">
        <a class="brand" href="index.html" aria-label="ProLocker, accueil"><img class="brand__image" src="assets/logo-prolocker.png" width="1080" height="1350" alt=""><span class="brand__name">Pro<strong>Locker</strong></span></a>
        <a class="mobile-menu-link" href="#navigation" data-menu-toggle aria-label="Ouvrir le menu" aria-expanded="false">Menu</a>
        <div class="nav-links">${navigation}</div>
      </nav>
    </header>`;
  const footer = document.querySelector('#site-footer');
  if (footer) footer.innerHTML = `
    <footer class="site-footer">
      <div class="footer-main">
        <div><a class="brand" href="index.html"><img class="brand__image" src="assets/logo-prolocker.png" width="1080" height="1350" alt=""><span class="brand__name">Pro<strong>Locker</strong></span></a><p>Des casiers connectés en location pour fluidifier la réception et le retrait de colis dans les environnements professionnels et résidentiels.</p></div>
        <div><p class="footer-title">Explorer</p><div class="footer-links"><a href="entreprises.html">Pour les entreprises</a><a href="residences.html">Pour les résidences</a><a href="fonctionnement.html">Comment ça fonctionne</a><a href="faq.html">Questions fréquentes</a></div></div>
        <div><p class="footer-title">Informations</p><div class="footer-links"><a href="contact.html" data-contact-link data-subject="Demande d’informations ProLocker">Contactez-nous</a><a href="mentions-legales.html">Mentions légales</a><a href="politique-confidentialite.html">Confidentialité</a><a href="cookies.html">Cookies</a><a href="conditions-generales.html">Conditions générales</a></div></div>
      </div>
      <div class="footer-bottom">© <span data-year></span> ProLocker. Informations et documents contractuels à compléter et à valider avant publication.</div>
    </footer>`;
  document.querySelectorAll('[data-year]').forEach((element) => { element.textContent = new Date().getFullYear(); });
})();
