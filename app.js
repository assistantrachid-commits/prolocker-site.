(() => {
  'use strict';

  const config = window.PROLOCKER_CONFIG || {};
  const hasEmail = Boolean(config.contactEmail && config.contactEmail.includes('@'));
  document.documentElement.lang = 'fr';

  if (hasEmail) {
    document.body.classList.add('email-ready');
    document.querySelectorAll('[data-mailto], [data-contact-link]').forEach((link) => {
      const subject = link.dataset.subject || 'Demande d’informations ProLocker';
      link.href = `mailto:${encodeURIComponent(config.contactEmail)}?subject=${encodeURIComponent(subject)}`;
    });
    document.querySelectorAll('[data-email-text]').forEach((element) => { element.textContent = config.contactEmail; });
  }

  document.querySelectorAll('[data-config]').forEach((element) => {
    const value = config[element.dataset.config];
    if (value) { element.textContent = value; element.classList.remove('placeholder'); }
  });

  const header = document.querySelector('.site-header');
  const setHeader = () => header?.classList.toggle('scrolled', window.scrollY > 12);
  setHeader();
  window.addEventListener('scroll', setHeader, { passive: true });

  const menuButtons = document.querySelectorAll('[data-menu-toggle]');
  const menu = document.querySelector('.nav-links');
  const toggleMenu = (event) => {
    event?.preventDefault();
    const open = menu.classList.toggle('is-open');
    document.body.classList.toggle('menu-open', open);
    menuButtons.forEach((button) => button.setAttribute('aria-expanded', String(open)));
  };
  menuButtons.forEach((button) => button.addEventListener('click', toggleMenu));
  menu?.querySelectorAll('a').forEach((link) => link.addEventListener('click', () => {
    menu.classList.remove('is-open');
    document.body.classList.remove('menu-open');
    menuButtons.forEach((button) => button.setAttribute('aria-expanded', 'false'));
  }));

  const revealElements = document.querySelectorAll('[data-reveal]');
  if ('IntersectionObserver' in window && !window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    const observer = new IntersectionObserver((entries) => entries.forEach((entry) => {
      if (entry.isIntersecting) { entry.target.classList.add('is-visible'); observer.unobserve(entry.target); }
    }), { threshold: .12 });
    revealElements.forEach((item) => observer.observe(item));
  } else { revealElements.forEach((item) => item.classList.add('is-visible')); }

  const form = document.querySelector('[data-calculator]');
  if (form) {
    const formatter = new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 0 });
    const hoursFormatter = new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 1 });
    const currency = new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR', maximumFractionDigits: 2 });
    const inputs = [...form.querySelectorAll('input[type="range"]')];
    const output = (id, value) => {
      const element = document.querySelector(`[data-result="${id}"]`);
      if (element) { element.textContent = value; }
    };
    const displayValue = (input) => {
      const unit = input.dataset.unit || '';
      const raw = Number(input.value);
      const text = `${formatter.format(raw)}${unit ? ` ${unit}` : ''}`;
      const outputElement = form.querySelector(`[data-output="${input.name}"]`);
      if (outputElement) { outputElement.textContent = text; }
    };
    const calculate = () => {
      const values = Object.fromEntries(inputs.map((input) => [input.name, Number(input.value)]));
      inputs.forEach(displayValue);
      const safeValue = (value) => Number.isFinite(value) ? Math.max(0, value) : 0;
      const dailyPackages = safeValue(values.incoming) + safeValue(values.outgoing);
      const savingsRate = safeValue(values.savings) / 100;
      const monthlyHours = dailyPackages * safeValue(values.minutes) * 22 * savingsRate / 60;
      const monthlyValue = monthlyHours * safeValue(values.hourlyCost);
      const interruptions = Math.round(dailyPackages * 22 * savingsRate);
      output('monthly-hours', `${hoursFormatter.format(monthlyHours)} h`);
      output('monthly-value', currency.format(monthlyValue));
      output('interruptions', formatter.format(interruptions));
    };
    inputs.forEach((input) => input.addEventListener('input', calculate));
    calculate();
  }
})();
