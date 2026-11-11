/* Header switches: dark theme and narrow layout by default. Each choice is
   kept in localStorage when it is available. The label stays fixed and
   aria-pressed reports the state. */
[
  ['[data-theme-toggle]', 'theme', 'light', 'dark', 'writing-theme'],
  ['[data-width-toggle]', 'width', 'wide', 'narrow', 'writing-width'],
].forEach(([selector, key, on, off, storageKey]) => {
  const toggle = document.querySelector(selector);
  if (!toggle) return;
  const root = document.documentElement;
  function update() {
    toggle.setAttribute('aria-pressed', String(root.dataset[key] === on));
  }
  toggle.addEventListener('click', () => {
    root.dataset[key] = root.dataset[key] === on ? off : on;
    try {
      localStorage.setItem(storageKey, root.dataset[key]);
    } catch (error) {}
    update();
  });
  toggle.hidden = false;
  update();
});
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
