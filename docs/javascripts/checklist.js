(function () {
  var STORAGE_KEY = 'mp-checklist';

  function pageKey() {
    return location.pathname;
  }

  function load() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}');
    } catch (_) {
      return {};
    }
  }

  function save(boxes) {
    var state = {};
    boxes.forEach(function (cb, i) { state[i] = cb.checked; });
    var all = load();
    all[pageKey()] = state;
    localStorage.setItem(STORAGE_KEY, JSON.stringify(all));
  }

  function getBoxes() {
    return Array.from(
      document.querySelectorAll('.task-list-item input[type="checkbox"]')
    );
  }

  function init() {
    var boxes = getBoxes();
    if (!boxes.length) return false;
    var stored = load()[pageKey()] || {};
    boxes.forEach(function (cb, i) {
      cb.checked = stored[i] === true;
      cb.addEventListener('change', function () { save(getBoxes()); });
    });
    return true;
  }

  document.addEventListener('DOMContentLoaded', function () {
    if (init()) return;
    // Page content is still encrypted - watch for post-decryption DOM injection
    var observer = new MutationObserver(function () {
      if (init()) observer.disconnect();
    });
    observer.observe(document.body, { childList: true, subtree: true });
  });
})();
