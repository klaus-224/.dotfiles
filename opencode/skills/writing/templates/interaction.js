/* Theme switch. A saved choice wins. Without one, the standalone page opens dark
   (data-theme="dark" in its template) and an artifact follows the viewer's system theme. */
(() => {
  const toggle = document.querySelector('[data-theme-toggle]');
  if (!toggle) return;
  const root = document.documentElement;
  const system = window.matchMedia ? window.matchMedia('(prefers-color-scheme: light)') : null;
  try {
    const saved = localStorage.getItem('writing-theme');
    if (saved === 'light' || saved === 'dark') root.dataset.theme = saved;
  } catch (error) {}
  const current = () => root.dataset.theme || (system && system.matches ? 'light' : 'dark');
  function update() {
    toggle.setAttribute('aria-pressed', String(current() === 'light'));
    toggle.textContent = 'Light theme';
  }
  toggle.addEventListener('click', () => {
    root.dataset.theme = current() === 'light' ? 'dark' : 'light';
    try {
      localStorage.setItem('writing-theme', root.dataset.theme);
    } catch (error) {}
    update();
  });
  if (system && system.addEventListener) system.addEventListener('change', update);
  toggle.hidden = false;
  update();
})();
/* Progressive enhancement: every step is visible if JavaScript is unavailable. */
document.querySelectorAll('.walkthrough').forEach((container) => {
  const controls = container.querySelector('.step-controls');
  const steps = Array.from(container.querySelector('ol').children);
  const previous = controls.querySelector('[data-prev]');
  const next = controls.querySelector('[data-next]');
  const all = controls.querySelector('[data-all]');
  const status = controls.querySelector('[role=status]');
  let current = 0;
  let showAll = false;
  function update() {
    steps.forEach((step, index) => {
      step.hidden = !showAll && index !== current;
    });
    previous.disabled = showAll || current === 0;
    next.disabled = showAll || current === steps.length - 1;
    all.setAttribute('aria-pressed', String(showAll));
    all.textContent = showAll ? 'Show one step' : 'Show all steps';
    status.textContent = showAll
      ? `All ${steps.length} steps`
      : `Step ${current + 1} of ${steps.length}`;
  }
  previous.addEventListener('click', () => {
    current = Math.max(0, current - 1);
    update();
  });
  next.addEventListener('click', () => {
    current = Math.min(steps.length - 1, current + 1);
    update();
  });
  all.addEventListener('click', () => {
    showAll = !showAll;
    update();
  });
  controls.hidden = false;
  update();
});
/* Browsers differ in how closed details print. Open them while printing. */
let closedForPrint = [];
window.addEventListener('beforeprint', () => {
  closedForPrint = Array.from(document.querySelectorAll('details:not([open])'));
  closedForPrint.forEach((detail) => {
    detail.open = true;
  });
});
window.addEventListener('afterprint', () => {
  closedForPrint.forEach((detail) => {
    detail.open = false;
  });
  closedForPrint = [];
});
