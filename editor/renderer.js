'use strict';

/* ==================== State ==================== */
let dataRoot = localStorage.getItem('gm_data_root') || '';
let projectTree = null;
let openTabs = [];
let activeTabId = null;
let dirtyFields = new Set();
let _sidebarExpanded = new Set();

/* ==================== Init ==================== */
function init() {
  if (!window.electronAPI) {
    document.getElementById('tree-content').innerHTML = `
      <div style="padding:20px;color:var(--pink);text-align:center">
        <div style="font-weight:700;margin-bottom:8px">preload.js failed to load</div>
        <div style="font-size:12px">Check the terminal for <code>[main] preload path:</code> log.</div>
      </div>
    `;
    return;
  }
  initMenuBar();
  initKeyboard();

  if (dataRoot) {
    loadFolder(dataRoot);
  } else {
    showOpenFolderUI();
  }
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}

/* ==================== Menu Bar ==================== */
function initMenuBar() {
  document.querySelectorAll('.menu-item').forEach(item => {
    const label = item.querySelector('.menu-label');
    if (!label) return;
    label.addEventListener('click', (e) => {
      e.stopPropagation();
      const isOpen = item.classList.contains('open');
      closeAllMenus();
      if (!isOpen) item.classList.add('open');
    });
  });

  document.addEventListener('click', () => closeAllMenus());

  document.querySelectorAll('.menu-action').forEach(el => {
    el.addEventListener('click', (e) => {
      e.stopPropagation();
      const action = el.dataset.action;
      if (action === 'open-folder') openFolderDialog();
      else if (action === 'save') saveAll();
      else if (action === 'quit') window.electronAPI.quit?.() || window.close();
      closeAllMenus();
    });
  });

  refreshRecentMenu();
}

function closeAllMenus() {
  document.querySelectorAll('.menu-item.open').forEach(el => el.classList.remove('open'));
}

function refreshRecentMenu() {
  const submenu = document.getElementById('menu-recent-submenu');
  if (!submenu) return;
  submenu.innerHTML = '';
  const recent = getRecentFolders();
  if (recent.length === 0) {
    const empty = document.createElement('div');
    empty.style.cssText = 'padding:6px 14px;font-size:12px;color:var(--text-secondary);';
    empty.textContent = 'No recent folders';
    submenu.appendChild(empty);
    return;
  }
  for (const folderPath of recent) {
    const name = folderPath.split(/[\\/]/).pop();
    const el = document.createElement('div');
    el.className = 'menu-recent-item';
    el.innerHTML = `<span>${escapeHtml(name)}</span><span class="recent-path" title="${escapeHtml(folderPath)}">${escapeHtml(folderPath)}</span>`;
    el.addEventListener('click', () => loadFolder(folderPath));
    submenu.appendChild(el);
  }
}

function getRecentFolders() {
  try {
    return JSON.parse(localStorage.getItem('gm_recent_folders') || '[]');
  } catch (e) { return []; }
}

function addRecentFolder(folderPath) {
  if (!folderPath) return;
  const recent = getRecentFolders().filter(p => p !== folderPath);
  recent.unshift(folderPath);
  localStorage.setItem('gm_recent_folders', JSON.stringify(recent.slice(0, 10)));
  refreshRecentMenu();
}

/* ==================== Folder Loading ==================== */
async function openFolderDialog() {
  try {
    const result = await window.electronAPI.openFolderDialog();
    if (!result.canceled && result.filePaths.length > 0) {
      loadFolder(result.filePaths[0]);
    }
  } catch (err) {
    alert('Failed to open folder dialog: ' + (err.message || err));
    console.error(err);
  }
}

function loadFolder(folderPath) {
  dataRoot = folderPath;
  localStorage.setItem('gm_data_root', folderPath);
  addRecentFolder(folderPath);

  const treeContainer = document.getElementById('tree-content');
  treeContainer.innerHTML = '';
  renderTree(folderPath, treeContainer, 0);

  document.getElementById('file-label').textContent = folderPath;
  updateTitle();
}

function showOpenFolderUI() {
  const container = document.getElementById('tree-content');
  container.innerHTML = `
    <div style="padding:16px;color:var(--text-secondary);text-align:center">
      <div style="margin-bottom:12px">No data folder selected.</div>
      <button class="btn-primary" id="btn-open-folder">Open Data Folder</button>
      <div style="margin-top:8px;font-size:11px">Or use File &gt; Open Data Folder</div>
    </div>
  `;
  document.getElementById('btn-open-folder').addEventListener('click', openFolderDialog);
  document.getElementById('file-label').textContent = '';
}

/* ==================== Tree ==================== */
function renderTree(dirPath, container, depth) {
  let entries;
  try {
    entries = window.electronAPI.readDir(dirPath);
  } catch (e) {
    container.innerHTML = '<div style="padding:8px;color:var(--text-secondary)">Unable to read folder</div>';
    return;
  }

  const folders = entries.filter(e => e.isDirectory).sort((a, b) => a.name.localeCompare(b.name));
  const files = entries.filter(e => !e.isDirectory && e.name.endsWith('.json')).sort((a, b) => a.name.localeCompare(b.name));

  folders.forEach(folder => {
    const fullPath = window.electronAPI.joinPath(dirPath, folder.name);
    const nodeId = fullPath;
    const isExpanded = _sidebarExpanded.has(nodeId);

    const row = document.createElement('div');
    row.className = `tree-item indent-${Math.min(depth, 4)}`;
    const arrow = isExpanded ? '▼' : '▶';
    row.innerHTML = `<span class="arrow">${arrow}</span><span class="icon">📁</span><span>${escapeHtml(folder.name)}</span>`;

    const childContainer = document.createElement('div');
    childContainer.className = 'tree-children' + (isExpanded ? ' expanded' : '');

    row.addEventListener('click', (e) => {
      e.stopPropagation();
      const expanding = !childContainer.classList.contains('expanded');
      if (expanding) {
        _sidebarExpanded.add(nodeId);
        if (childContainer.children.length === 0) {
          renderTree(fullPath, childContainer, depth + 1);
        }
      } else {
        _sidebarExpanded.delete(nodeId);
      }
      childContainer.classList.toggle('expanded');
      row.querySelector('.arrow').textContent = expanding ? '▼' : '▶';
      // Show list for this folder
      renderList(fullPath);
    });

    container.appendChild(row);
    container.appendChild(childContainer);
  });

  files.forEach(file => {
    const fullPath = window.electronAPI.joinPath(dirPath, file.name);
    const row = document.createElement('div');
    row.className = `tree-item indent-${Math.min(depth + 1, 4)}`;
    row.innerHTML = `<span class="arrow"></span><span class="icon">📄</span><span>${escapeHtml(file.name)}</span>`;
    row.addEventListener('click', (e) => {
      e.stopPropagation();
      openFile(fullPath);
    });
    container.appendChild(row);
  });
}

/* ==================== List ==================== */
function renderList(folderPath) {
  const container = document.getElementById('list-content');
  container.innerHTML = '';

  let entries;
  try {
    entries = window.electronAPI.readDir(folderPath).filter(e => !e.isDirectory && e.name.endsWith('.json'));
  } catch (e) {
    container.innerHTML = '<div style="padding:8px;color:var(--text-secondary)">Empty</div>';
    return;
  }

  entries.sort((a, b) => a.name.localeCompare(b.name));

  if (entries.length === 0) {
    container.innerHTML = '<div style="padding:8px;color:var(--text-secondary)">Empty</div>';
    return;
  }

  entries.forEach(file => {
    const fullPath = window.electronAPI.joinPath(folderPath, file.name);
    let title = file.name;
    let sub = '';
    try {
      const text = window.electronAPI.readFile(fullPath);
      const json = JSON.parse(text);
      title = json.label || json.interaction_id || json.condition_id || json.event_id || json.place_id || json.item_id || file.name;
      sub = file.name;
    } catch (e) {
      /* ignore parse error */
    }

    const card = document.createElement('div');
    card.className = 'entry-card';
    card.innerHTML = `<div class="entry-title">${escapeHtml(title)}</div><div class="entry-sub">${escapeHtml(sub)}</div>`;
    card.addEventListener('click', () => {
      document.querySelectorAll('.entry-card.selected').forEach(el => el.classList.remove('selected'));
      card.classList.add('selected');
      openFile(fullPath);
    });
    container.appendChild(card);
  });
}

/* ==================== Tabs & Editor ==================== */
function openFile(filePath) {
  const existing = openTabs.find(t => t.filePath === filePath);
  if (existing) {
    activateTab(existing.id);
    return;
  }

  let data;
  try {
    const text = window.electronAPI.readFile(filePath);
    data = JSON.parse(text);
  } catch (e) {
    alert('Failed to open file: ' + e.message);
    return;
  }

  const id = 'tab_' + Date.now() + '_' + Math.random().toString(36).slice(2, 7);
  const tabInfo = {
    id,
    filePath,
    data: deepClone(data),
    originalData: deepClone(data),
    dirty: false,
    container: null
  };
  openTabs.push(tabInfo);
  createTabUI(tabInfo);
  activateTab(id);
}

function createTabUI(tabInfo) {
  const tabsBar = document.getElementById('editor-tabs');
  const editorContainer = document.getElementById('editor-container');

  // Tab element
  const tabEl = document.createElement('div');
  tabEl.className = 'editor-tab';
  tabEl.dataset.tabId = tabInfo.id;
  tabEl.innerHTML = `<span class="tab-label">${escapeHtml(window.electronAPI.pathBasename(tabInfo.filePath))}</span><span class="tab-modified" style="display:none">●</span><span class="tab-close">×</span>`;
  tabEl.addEventListener('click', (e) => {
    if (e.target.classList.contains('tab-close')) {
      e.stopPropagation();
      closeTab(tabInfo.id);
    } else {
      activateTab(tabInfo.id);
    }
  });
  tabsBar.appendChild(tabEl);

  // Editor container
  const container = document.createElement('div');
  container.className = 'form-editor';
  container.style.display = 'none';
  container.dataset.tabId = tabInfo.id;
  editorContainer.appendChild(container);
  tabInfo.container = container;

  buildForm(tabInfo.data, container, () => markDirty(tabInfo.id));
}

function activateTab(tabId) {
  if (activeTabId === tabId) return;

  document.querySelectorAll('.editor-tab').forEach(el => el.classList.toggle('active', el.dataset.tabId === tabId));
  document.querySelectorAll('#editor-container > .form-editor').forEach(el => {
    el.style.display = el.dataset.tabId === tabId ? 'flex' : 'none';
  });

  activeTabId = tabId;
  updateTitle();
}

function closeTab(tabId) {
  const idx = openTabs.findIndex(t => t.id === tabId);
  if (idx === -1) return;
  const tabInfo = openTabs[idx];

  if (tabInfo.dirty) {
    const ok = confirm('Unsaved changes. Discard?');
    if (!ok) return;
  }

  // Remove DOM
  const tabEl = document.querySelector(`.editor-tab[data-tab-id="${tabId}"]`);
  if (tabEl) tabEl.remove();
  if (tabInfo.container) tabInfo.container.remove();

  openTabs.splice(idx, 1);
  dirtyFields.delete(tabId);

  if (activeTabId === tabId) {
    activeTabId = openTabs.length > 0 ? openTabs[Math.min(idx, openTabs.length - 1)].id : null;
    if (activeTabId) activateTab(activeTabId);
    else {
      document.getElementById('editor-tabs').innerHTML = '';
      document.getElementById('editor-container').innerHTML = `
        <div class="empty-state">Select a JSON file to edit</div>
      `;
      updateTitle();
    }
  }
}

function markDirty(tabId) {
  const tabInfo = openTabs.find(t => t.id === tabId);
  if (!tabInfo) return;
  tabInfo.dirty = true;
  dirtyFields.add(tabId);
  const tabEl = document.querySelector(`.editor-tab[data-tab-id="${tabId}"]`);
  if (tabEl) {
    const dot = tabEl.querySelector('.tab-modified');
    if (dot) dot.style.display = '';
  }
  updateTitle();
}

function clearDirty(tabId) {
  const tabInfo = openTabs.find(t => t.id === tabId);
  if (!tabInfo) return;
  tabInfo.dirty = false;
  dirtyFields.delete(tabId);
  tabInfo.originalData = deepClone(tabInfo.data);
  const tabEl = document.querySelector(`.editor-tab[data-tab-id="${tabId}"]`);
  if (tabEl) {
    const dot = tabEl.querySelector('.tab-modified');
    if (dot) dot.style.display = 'none';
  }
  updateTitle();
}

/* ==================== Form Builder ==================== */
function isShortField(val) {
  if (typeof val === 'boolean') return true;
  if (typeof val === 'number') return true;
  if (typeof val === 'string') {
    return (val || '').length <= 60;
  }
  return false;
}

function buildForm(data, container, markDirtyFn) {
  container.innerHTML = '';
  if (typeof data !== 'object' || data === null) {
    container.innerHTML = '<div class="empty-state">Only JSON objects can be edited</div>';
    return;
  }
  renderObjectFields(data, container, markDirtyFn, 0);
}

function renderObjectFields(data, container, markDirtyFn, depth) {
  const keys = Object.keys(data);
  if (keys.length === 0) {
    container.innerHTML = '<div class="empty-state">Empty JSON object</div>';
    return;
  }

  const simple = [];
  const complex = [];
  keys.forEach(key => {
    const val = data[key];
    if (Array.isArray(val) || (typeof val === 'object' && val !== null)) {
      complex.push(key);
    } else {
      simple.push(key);
    }
  });
  const ordered = [...simple, ...complex];

  let shortQueue = [];
  function flushQueue() {
    if (shortQueue.length === 0) return;
    const row = document.createElement('div');
    row.className = 'form-row';
    container.appendChild(row);
    const rowBuilder = new FormBuilder(row, false, markDirtyFn);
    for (const { key, val } of shortQueue) {
      if (typeof val === 'boolean') {
        rowBuilder.checkbox(key, () => data[key], (v) => { data[key] = v; });
      } else if (typeof val === 'number') {
        rowBuilder.number(key, () => data[key], (v) => { data[key] = v; });
      } else {
        rowBuilder.text(key, () => data[key], (v) => { data[key] = v; });
      }
    }
    shortQueue = [];
  }

  const builder = new FormBuilder(container, false, markDirtyFn);
  ordered.forEach(key => {
    const val = data[key];
    if (Array.isArray(val) || (typeof val === 'object' && val !== null)) {
      flushQueue();

      const group = document.createElement('div');
      group.className = 'form-group nested-group';

      const bar = document.createElement('div');
      bar.className = 'nested-label-bar';

      const lbl = document.createElement('span');
      lbl.className = 'nested-label';
      lbl.textContent = key;

      const toggle = document.createElement('button');
      toggle.className = 'nested-toggle';
      toggle.type = 'button';
      toggle.textContent = 'Raw JSON';

      bar.appendChild(lbl);
      bar.appendChild(toggle);
      group.appendChild(bar);

      const content = document.createElement('div');
      content.className = 'nested-content';
      group.appendChild(content);

      const raw = document.createElement('textarea');
      raw.className = 'form-input nested-raw';
      raw.rows = 6;
      raw.value = JSON.stringify(val, null, '\t');
      raw.style.display = 'none';
      group.appendChild(raw);

      let isRaw = false;
      toggle.addEventListener('click', () => {
        if (isRaw) {
          try {
            const parsed = JSON.parse(raw.value);
            data[key] = parsed;
            content.innerHTML = '';
            buildNestedForm(data[key], content, markDirtyFn, depth + 1, key);
            content.style.display = '';
            raw.style.display = 'none';
            toggle.textContent = 'Raw JSON';
            isRaw = false;
            markDirtyFn();
          } catch (e) {
            alert('Invalid JSON: ' + e.message);
          }
        } else {
          raw.value = JSON.stringify(data[key], null, '\t');
          content.style.display = 'none';
          raw.style.display = '';
          toggle.textContent = 'Form View';
          isRaw = true;
        }
      });

      container.appendChild(group);
      buildNestedForm(val, content, markDirtyFn, depth + 1, key);
    } else if (isShortField(val)) {
      shortQueue.push({ key, val });
      if (shortQueue.length >= 2) flushQueue();
    } else {
      flushQueue();
      builder.textarea(key, () => data[key], (v) => { data[key] = v; }, 10);
    }
  });
  flushQueue();
}

function buildNestedForm(data, container, markDirtyFn, depth = 0, label = null) {
  container.innerHTML = '';

  if (Array.isArray(data)) {
    const toolbar = document.createElement('div');
    toolbar.className = 'array-toolbar';

    const addBtn = document.createElement('button');
    addBtn.className = 'array-btn';
    addBtn.textContent = '+ Add item';
    addBtn.addEventListener('click', () => {
      let defaultItem = {};
      if (data.length > 0) {
        const first = data[0];
        if (typeof first === 'string') defaultItem = '';
        else if (typeof first === 'number') defaultItem = 0;
        else if (typeof first === 'boolean') defaultItem = false;
      }
      data.push(defaultItem);
      markDirtyFn();
      buildNestedForm(data, container, markDirtyFn, depth, label);
    });
    toolbar.appendChild(addBtn);
    container.appendChild(toolbar);

    if (data.length === 0) {
      const empty = document.createElement('div');
      empty.className = 'empty-state';
      empty.textContent = 'Empty array — click + Add item';
      container.appendChild(empty);
    }

    data.forEach((item, index) => {
      const card = document.createElement('div');
      card.className = 'nested-card array-item-card';
      card.draggable = true;

      const header = document.createElement('div');
      header.className = 'nested-header array-item-header';

      const dragHandle = document.createElement('span');
      dragHandle.className = 'drag-handle';
      dragHandle.textContent = '⋮⋮';

      const badge = document.createElement('span');
      badge.className = 'array-index';
      badge.textContent = `[${index}]`;

      const actions = document.createElement('span');
      actions.className = 'array-actions';

      const upBtn = document.createElement('button');
      upBtn.className = 'array-btn';
      upBtn.textContent = '▲';
      upBtn.title = 'Move up';
      upBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        if (index > 0) {
          [data[index], data[index - 1]] = [data[index - 1], data[index]];
          markDirtyFn();
          buildNestedForm(data, container, markDirtyFn, depth, label);
        }
      });

      const downBtn = document.createElement('button');
      downBtn.className = 'array-btn';
      downBtn.textContent = '▼';
      downBtn.title = 'Move down';
      downBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        if (index < data.length - 1) {
          [data[index], data[index + 1]] = [data[index + 1], data[index]];
          markDirtyFn();
          buildNestedForm(data, container, markDirtyFn, depth, label);
        }
      });

      const delBtn = document.createElement('button');
      delBtn.className = 'array-btn array-btn-danger';
      delBtn.textContent = '✕';
      delBtn.title = 'Remove';
      delBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        data.splice(index, 1);
        markDirtyFn();
        buildNestedForm(data, container, markDirtyFn, depth, label);
      });

      actions.appendChild(upBtn);
      actions.appendChild(downBtn);
      actions.appendChild(delBtn);

      header.appendChild(dragHandle);
      header.appendChild(badge);
      header.appendChild(actions);
      card.appendChild(header);

      const body = document.createElement('div');
      body.className = 'nested-body';
      card.appendChild(body);

      card.addEventListener('dragstart', (e) => {
        e.dataTransfer.setData('text/plain', String(index));
        e.dataTransfer.effectAllowed = 'move';
        card.style.opacity = '0.5';
      });
      card.addEventListener('dragend', () => {
        card.style.opacity = '';
      });

      container.appendChild(card);
      buildNestedForm(item, body, markDirtyFn, depth + 1, `[${index}]`);
    });

    if (!container._arrayListenersAdded) {
      container._arrayListenersAdded = true;
      container.addEventListener('dragover', (e) => {
        e.preventDefault();
        e.dataTransfer.dropEffect = 'move';
      });
      container.addEventListener('drop', (e) => {
        e.preventDefault();
        const fromIndex = parseInt(e.dataTransfer.getData('text/plain'), 10);
        if (isNaN(fromIndex)) return;
        const dropTarget = e.target.closest('.array-item-card');
        if (!dropTarget || !container.contains(dropTarget)) return;
        const cards = Array.from(container.querySelectorAll('.array-item-card'));
        const toIndex = cards.indexOf(dropTarget);
        if (toIndex === -1 || toIndex === fromIndex) return;
        const item = data.splice(fromIndex, 1)[0];
        data.splice(toIndex, 0, item);
        markDirtyFn();
        buildNestedForm(data, container, markDirtyFn, depth, label);
      });
    }

    return;
  }

  if (typeof data === 'object' && data !== null) {
    if (depth > 0) {
      const section = document.createElement('div');
      section.className = 'nested-section';
      container.appendChild(section);
      renderObjectFields(data, section, markDirtyFn, depth);
    } else {
      renderObjectFields(data, container, markDirtyFn, depth);
    }
    return;
  }

  // Primitive at nested level
  const builder = new FormBuilder(container, false, markDirtyFn);
  builder.textarea('value', () => data, (v) => {}, 3);
}

class FormBuilder {
  constructor(container, readonly, markDirty) {
    this.container = container;
    this.readonly = readonly;
    this.markDirty = markDirty;
  }
  text(label, getter, setter, placeholder = '') {
    const wrap = document.createElement('div');
    wrap.className = 'form-group';
    wrap.style.cssText = 'display:block;';
    const lbl = document.createElement('span');
    lbl.className = 'form-label';
    lbl.style.display = 'block';
    lbl.style.marginBottom = '4px';
    lbl.textContent = label;
    const input = document.createElement('input');
    input.className = 'form-input';
    input.type = 'text';
    input.placeholder = placeholder;
    input.style.width = '100%';
    input.value = getter() || '';
    if (this.readonly) { input.disabled = true; input.readOnly = true; }
    else {
      input.addEventListener('input', () => { setter(input.value); this.markDirty(); });
    }
    wrap.appendChild(lbl);
    wrap.appendChild(input);
    this.container.appendChild(wrap);
    return input;
  }
  number(label, getter, setter, opts = {}) {
    const wrap = document.createElement('div');
    wrap.className = 'form-group';
    wrap.style.cssText = 'display:block;';
    const lbl = document.createElement('span');
    lbl.className = 'form-label';
    lbl.style.display = 'block';
    lbl.style.marginBottom = '4px';
    lbl.textContent = label;
    const input = document.createElement('input');
    input.className = 'form-input';
    input.type = 'number';
    input.style.width = '100%';
    const val = getter();
    input.value = (val !== undefined && val !== null) ? val : '';
    if (opts.min !== undefined) input.min = opts.min;
    if (opts.max !== undefined) input.max = opts.max;
    if (opts.step !== undefined) input.step = opts.step;
    if (this.readonly) { input.disabled = true; input.readOnly = true; }
    else {
      input.addEventListener('input', () => { setter(parseFloat(input.value)); this.markDirty(); });
    }
    wrap.appendChild(lbl);
    wrap.appendChild(input);
    this.container.appendChild(wrap);
    return input;
  }
  checkbox(label, getter, setter) {
    const wrap = document.createElement('label');
    wrap.className = 'form-group';
    wrap.style.cssText = 'display:flex;align-items:center;gap:6px;cursor:pointer;';
    const cb = document.createElement('input');
    cb.type = 'checkbox';
    cb.checked = !!getter();
    if (this.readonly) cb.disabled = true;
    else {
      cb.addEventListener('change', () => { setter(cb.checked); this.markDirty(); });
    }
    const lbl = document.createElement('span');
    lbl.className = 'form-label';
    lbl.style.marginBottom = '0';
    lbl.textContent = label;
    wrap.appendChild(cb);
    wrap.appendChild(lbl);
    this.container.appendChild(wrap);
    return cb;
  }
  textarea(label, getter, setter, rows = 6) {
    const wrap = document.createElement('div');
    wrap.className = 'form-group';
    wrap.style.cssText = 'display:block;';
    const lbl = document.createElement('span');
    lbl.className = 'form-label';
    lbl.style.display = 'block';
    lbl.style.marginBottom = '4px';
    lbl.textContent = label;
    const ta = document.createElement('textarea');
    ta.className = 'form-input';
    ta.rows = rows;
    ta.style.width = '100%';
    ta.style.minHeight = '80px';
    ta.value = getter() || '';
    if (this.readonly) { ta.disabled = true; ta.readOnly = true; }
    else {
      ta.addEventListener('input', () => { setter(ta.value); this.markDirty(); });
    }
    wrap.appendChild(lbl);
    wrap.appendChild(ta);
    this.container.appendChild(wrap);
    return ta;
  }
}

/* ==================== Save ==================== */
function saveAll() {
  openTabs.forEach(t => {
    if (t.dirty) saveTab(t.id);
  });
}

function saveTab(tabId) {
  const tabInfo = openTabs.find(t => t.id === tabId);
  if (!tabInfo || !tabInfo.dirty) return;
  try {
    const text = JSON.stringify(tabInfo.data, null, '\t');
    window.electronAPI.writeFile(tabInfo.filePath, text);
    clearDirty(tabId);
  } catch (e) {
    alert('Save failed: ' + e.message);
  }
}

/* ==================== Keyboard ==================== */
function initKeyboard() {
  document.addEventListener('keydown', (e) => {
    if (e.ctrlKey || e.metaKey) {
      if (e.key === 's') {
        e.preventDefault();
        saveAll();
      } else if (e.key === 'o') {
        e.preventDefault();
        openFolderDialog();
      } else if (e.key === 'q') {
        e.preventDefault();
        window.electronAPI.quit?.() || window.close();
      }
    }
  });
}

/* ==================== Utils ==================== */
function updateTitle() {
  const base = dataRoot ? dataRoot.split(/[\\/]/).pop() : 'GuildMaster Data Editor';
  const dirty = dirtyFields.size > 0;
  document.title = dirty ? `GuildMaster Data Editor — ${base} *` : `GuildMaster Data Editor — ${base}`;
}

function deepClone(obj) {
  return JSON.parse(JSON.stringify(obj));
}

function escapeHtml(str) {
  if (str === null || str === undefined) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
