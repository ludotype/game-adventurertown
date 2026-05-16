//@name loremaster
//@display-name LOREMASTER 1.3.10
//@api 3.0
//@version 1.3.10
// @description Advanced lorebook management plugin with multi-selection, drag-drop, and folder support

// LOREMASTER Plugin for RisuAI
// Features: Dual-tab, Folders, Multi-select, Drag-drop, Search, Themes
//
// Code Structure:
// - Section 1:  State Management
// - Section 2:  Utility Functions
// - Section 3: Internationalization (I18N)
// - Section 4: RisuAI Data Access
// - Section 5: Disabled Lore Management
// - Section 6: Lore List Management
// - Section 7: Import / Export
// - Section 8: Entry CRUD Operations
// - Section 9: Render Helpers
// - Section 10: Main Render Function
// - Section 11: Event Handling
// - Section 12: Plugin Lifecycle
// - Section 13: Keyboard Shortcuts
// - Section 14: Plugin Initialization

(async () => {
  const APP_VERSION = '1.3.10';

  const ICON = `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640" width="20" height="20" aria-hidden="true">
      <path fill="currentColor" d="M192 576L512 576C529.7 576 544 561.7 544 544C544 526.3 529.7 512 512 512L512 445.3C530.6 438.7 544 420.9 544 400L544 112C544 85.5 522.5 64 496 64L192 64C139 64 96 107 96 160L96 480C96 533 139 576 192 576zM160 480C160 462.3 174.3 448 192 448L448 448L448 512L192 512C174.3 512 160 497.7 160 480zM406.6 272L375 272C373.6 295.1 369 316.2 362.4 333.2C385.1 320.7 401.8 298.4 406.6 272zM233.5 272C238.3 298.4 255 320.7 277.7 333.2C271 316.2 266.5 295.2 265.1 272L233.5 272zM309.9 327C314.4 336.6 318.1 340.8 320.1 342.5C322.1 340.8 325.8 336.7 330.3 327C336.5 313.6 341.4 294.5 343 272L297.2 272C298.8 294.5 303.7 313.6 309.9 327zM297.2 240L343 240C341.4 217.5 336.5 198.4 330.3 185C325.8 175.4 322.1 171.2 320.1 169.5C318.1 171.2 314.4 175.3 309.9 185C303.7 198.4 298.8 217.5 297.2 240zM406.7 240C401.9 213.6 385.2 191.3 362.5 178.8C369.2 195.8 373.7 216.8 375.1 240L406.7 240zM265 240C266.4 216.9 271 195.8 277.6 178.8C254.9 191.3 238.2 213.6 233.4 240L265 240zM192 256C192 185.3 249.3 128 320 128C390.7 128 448 185.3 448 256C448 326.7 390.7 384 320 384C249.3 384 192 326.7 192 256z"/>
    </svg>
  `;

  const MINIMIZE_ICON = `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640" width="18" height="18" aria-hidden="true">
      <path fill="#586069" d="M503.5 71C512.9 61.6 528.1 61.6 537.4 71L569.4 103C578.8 112.4 578.8 127.6 569.4 136.9L482.4 223.9L521.4 262.9C528.3 269.8 530.3 280.1 526.6 289.1C522.9 298.1 514.2 304 504.5 304L360.5 304C347.2 304 336.5 293.3 336.5 280L336.5 136C336.5 126.3 342.3 117.5 351.3 113.8C360.3 110.1 370.6 112.1 377.5 119L416.5 158L503.5 71zM136.5 336L280.5 336C293.8 336 304.5 346.7 304.5 360L304.5 504C304.5 513.7 298.7 522.5 289.7 526.2C280.7 529.9 270.4 527.9 263.5 521L224.5 482L137.5 569C128.1 578.4 112.9 578.4 103.6 569L71.6 537C62.2 527.6 62.2 512.4 71.6 503.1L158.6 416.1L119.6 377.1C112.7 370.2 110.7 359.9 114.4 350.9C118.1 341.9 126.8 336 136.5 336z"/>
    </svg>
  `;

  const HELP_ICON = `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640" width="20" height="20" aria-hidden="true">
      <path fill="currentColor" d="M320 576C461.4 576 576 461.4 576 320C576 178.6 461.4 64 320 64C178.6 64 64 178.6 64 320C64 461.4 178.6 576 320 576zM320 240C302.3 240 288 254.3 288 272C288 285.3 277.3 296 264 296C250.7 296 240 285.3 240 272C240 227.8 275.8 192 320 192C364.2 192 400 227.8 400 272C400 319.2 364 339.2 344 346.5L344 350.3C344 363.6 333.3 374.3 320 374.3C306.7 374.3 296 363.6 296 350.3L296 342.2C296 321.7 310.8 307 326.1 302C332.5 299.9 339.3 296.5 344.3 291.7C348.6 287.5 352 281.7 352 272.1C352 254.4 337.7 240.1 320 240.1zM288 432C288 414.3 302.3 400 320 400C337.7 400 352 414.3 352 432C352 449.7 337.7 464 320 464C302.3 464 288 449.7 288 432z"/>
    </svg>
  `;

  const MAXIMIZE_ICON = `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640" width="18" height="18" aria-hidden="true">
      <path fill="#ffffff" d="M192 576L512 576C529.7 576 544 561.7 544 544C544 526.3 529.7 512 512 512L512 445.3C530.6 438.7 544 420.9 544 400L544 112C544 85.5 522.5 64 496 64L192 64C139 64 96 107 96 160L96 480C96 533 139 576 192 576zM160 480C160 462.3 174.3 448 192 448L448 448L448 512L192 512C174.3 512 160 497.7 160 480zM406.6 272L375 272C373.6 295.1 369 316.2 362.4 333.2C385.1 320.7 401.8 298.4 406.6 272zM233.5 272C238.3 298.4 255 320.7 277.7 333.2C271 316.2 266.5 295.2 265.1 272L233.5 272zM309.9 327C314.4 336.6 318.1 340.8 320.1 342.5C322.1 340.8 325.8 336.7 330.3 327C336.5 313.6 341.4 294.5 343 272L297.2 272C298.8 294.5 303.7 313.6 309.9 327zM297.2 240L343 240C341.4 217.5 336.5 198.4 330.3 185C325.8 175.4 322.1 171.2 320.1 169.5C318.1 171.2 314.4 175.3 309.9 185C303.7 198.4 298.8 217.5 297.2 240zM406.7 240C401.9 213.6 385.2 191.3 362.5 178.8C369.2 195.8 373.7 216.8 375.1 240L406.7 240zM265 240C266.4 216.9 271 195.8 277.6 178.8C254.9 191.3 238.2 213.6 233.4 240L265 240zM192 256C192 185.3 249.3 128 320 128C390.7 128 448 185.3 448 256C448 326.7 390.7 384 320 384C249.3 384 192 326.7 192 256z"/>
    </svg>
  `;

  const FAB_RESTORE_BUTTON_ID = 'loremaster:fab:restore';

  // ============================================================================
  // SECTION 1: STATE MANAGEMENT
  // ============================================================================
  // All application state is centralized in the State object for predictable
  // state updates and easier debugging. Legacy variables are kept for backward
  // compatibility during gradual migration.
  // ============================================================================
  const State = {
    // Core UI State
    currentTab: 'character', // 'character' | 'chat'
    layoutMode: 'vertical', // 'vertical' | 'horizontal'
    themeMode: 'light', // 'light' | 'dark'
    languageMode: 'ko', // 'ko' | 'en'
    isPluginOpen: false,
    isMinimized: false,
    isHelpOpen: false,

    // Layout Dimensions
    verticalSplit: 50, // percentage for vertical layout
    horizontalSplit: 40, // percentage for horizontal layout

    // Selection State
    editingEntryId: null,
    selectedEntryIds: new Set(),
    selectionAnchorId: null,
    expandedEntries: new Set(),

    // Drag & Drop
    dragSourceId: null,

    // Search & Filter
    search: {
      query: '',
      target: 'name', // 'name' | 'keys'
      filterAlways: false,
      filterDisabled: false
    },

    // Editor Draft
    editor: {
      drafts: new Map(), // entryId -> partial updates
      dirty: new Set(),
      isComposing: false
    },

    // Event Cleanup
    removeResizeListeners: null
  };

  // Legacy accessors for backward compatibility
  // These variables mirror State properties for code that hasn't been migrated yet
  let currentTab = State.currentTab;
  let editingEntryId = State.editingEntryId;
  let selectedEntryIds = State.selectedEntryIds;
  let selectionAnchorId = State.selectionAnchorId;
  let expandedEntries = State.expandedEntries;
  let dragSourceId = State.dragSourceId;
  let layoutMode = State.layoutMode;
  let verticalSplit = State.verticalSplit;
  let horizontalSplit = State.horizontalSplit;
  let isPluginOpen = State.isPluginOpen;
  let isMinimized = State.isMinimized;
  let themeMode = State.themeMode;
  let languageMode = State.languageMode;
  let removeResizeListeners = State.removeResizeListeners;
  let isHelpOpen = State.isHelpOpen;
  let searchQuery = State.search.query;
  let searchTarget = State.search.target;
  let filterAlways = State.search.filterAlways;
  let filterDisabled = State.search.filterDisabled;
  const editorDrafts = State.editor.drafts;
  const editorDirty = State.editor.dirty;
  let isComposing = State.editor.isComposing;

  // ============================================================================
  // SECTION 2: UTILITY FUNCTIONS
  // ============================================================================

  /**
   * Generate a unique ID with timestamp and random suffix
   * Format: lm_<timestamp>_<random>
   */
  function makeId() {
    return `lm_${Date.now()}_${Math.random().toString(36).slice(2, 9)}`;
  }

  /**
   * Generate a unique ID that doesn't exist in the usedIds Set
   * @param {Set} usedIds - Set of existing IDs to avoid collisions
   */
  function makeUniqueId(usedIds) {
    let id = makeId();
    while (usedIds.has(id)) id = makeId();
    usedIds.add(id);
    return id;
  }

  /**
   * Escape HTML special characters to prevent XSS
   * @param {*} value - Value to escape
   * @returns {string} Escaped HTML string
   */
  function escapeHtml(value) {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  /**
   * Format chat title for display, extracting branch info
   * Converts "Chat Name (Branch 2)" to "Chat Name - Branch 2"
   * @param {Object} chat - Chat object from RisuAI
   * @param {number} chatIndex - Index of the chat
   */
  function formatChatTitle(chat, chatIndex) {
    const rawName = String(chat?.name || `Chat ${Number(chatIndex || 0) + 1}`).trim();
    const branchMatch = rawName.match(/^(.*?)\s*\((Branch(?:\s+\d+)?)\)\s*$/i);
    if (!branchMatch) return rawName;
    return `${branchMatch[1].trim() || rawName} - ${branchMatch[2]}`;
  }

  /**
   * Get current character and chat info from RisuAI
   * Returns fallback values if API calls fail
   */
  async function getCurrentTargetInfo() {
    try {
      const charIndex = await Risuai.getCurrentCharacterIndex();
      const chatIndex = await Risuai.getCurrentChatIndex();
      const character = await Risuai.getCharacterFromIndex(charIndex);
      const chat = await Risuai.getChatFromIndex(charIndex, chatIndex);

      return {
        characterName: String(character?.name || `Character ${Number(charIndex || 0) + 1}`),
        chatTitle: formatChatTitle(chat, chatIndex)
      };
    } catch {
      return {
        characterName: languageMode === 'ko' ? '알 수 없는 캐릭터' : 'Unknown Character',
        chatTitle: languageMode === 'ko' ? '알 수 없는 챗' : 'Unknown Chat'
      };
    }
  }

  /**
   * Remove parenthetical text for compact display
   * Removes (...) and （...） segments and normalizes whitespace
   */
  function stripParenText(name) {
    return String(name ?? '')
      .replace(/\s*\([^)]*\)\s*/g, ' ')
      .replace(/\s*（[^）]*）\s*/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();
  }

  /**
   * Debounce function calls to limit execution rate
   * @param {Function} fn - Function to debounce
   * @param {number} waitMs - Wait time in milliseconds (default: 250ms)
   */
  function debounce(fn, waitMs = 250) {
    let t = null;
    return (...args) => {
      if (t) clearTimeout(t);
      t = setTimeout(() => fn(...args), waitMs);
    };
  }

  /**
   * Find a lore entry DOM element by its ID
   * @param {string} entryId - Entry ID to find
   * @returns {Element|null} The entry element or null
   */
  function findEntryElementById(entryId) {
    return Array.from(document.querySelectorAll('.lm-entry'))
      .find(el => el.dataset.id === entryId) || null;
  }

  /**
   * Get the draft version of an entry (with unsaved changes)
   * Returns merged entry with draft changes if they exist
   */
  function getDraftForEntry(entry) {
    if (!entry?.id) return entry;
    const patch = editorDrafts.get(entry.id);
    if (!patch) return entry;
    return { ...entry, ...patch };
  }

  /**
   * Store a draft change for an entry
   * @param {string} entryId - Entry ID
   * @param {Object} patch - Partial changes to apply
   */
  function setDraft(entryId, patch) {
    if (!entryId) return;
    const prev = editorDrafts.get(entryId) || {};
    editorDrafts.set(entryId, { ...prev, ...patch });
    editorDirty.add(entryId);
  }

  /**
   * Save draft changes to persistent storage
   * @param {string} entryId - Entry ID to flush
   * @param {Object} options - Options (forceRender: re-render after save)
   */
  async function flushDraft(entryId, { forceRender = false } = {}) {
    if (!entryId) return;
    if (!editorDirty.has(entryId)) return;
    const patch = editorDrafts.get(entryId);
    if (!patch || typeof patch !== 'object') {
      editorDirty.delete(entryId);
      return;
    }
    editorDirty.delete(entryId);
    editorDrafts.delete(entryId);
    await updateEntry(entryId, patch);
    if (forceRender) {
      await render(true);
    }
  }

  // ============================================================================
  // SECTION 3: INTERNATIONALIZATION (I18N)
  // ============================================================================
  // All user-facing text is defined here for easy translation.
  // Currently supports Korean (ko) and English (en).
  // ============================================================================

  const I18N = {
    ko: {
      characterTab: '캐릭터',
      chatTab: '챗',
      lightMode: '라이트',
      darkMode: '다크',
      verticalLayout: '세로',
      horizontalLayout: '가로',
      languageToggle: 'English',
      addEntry: '+ 항목 추가',
      addFolder: '폴더 추가',
      export: '내보내기',
      import: '불러오기',
      searchPlaceholder: '검색할 내용...',
      search: '검색',
      name: '이름',
      keys: '키',
      always: '항상 활성',
      disabled: '숨겨짐',
      folder: '폴더',
      off: '숨김',
      unnamed: '이름 없음',
      editFolder: '폴더 편집',
      editEntry: '항목 편집',
      entryNamePlaceholder: '항목 이름',
      insertOrder: '삽입 순서',
      activationKeys: '활성화 키',
      commaSeparated: '쉼표로 구분',
      secondaryKeys: '보조 키',
      secondaryKeyPlaceholder: '보조 활성화 키',
      content: '내용',
      contentPlaceholder: '로어북 내용...',
      alwaysActive: '항상 활성',
      selective: '키+보조키',
      useRegex: '정규식 사용',
      disableAll: '모두 숨김',
      enableAll: '모두 표시',
      noEntries: '로어 항목이 없어. "+ 항목 추가"로 새 항목을 만들 수 있어.',
      selectEntry: '항목을 선택해 편집하세요',
      deleteTitle: '삭제',
      deleteConfirm: '이 항목을 삭제할까?',
      dragTitle: '드래그해서 순서 변경',
      resizeTitle: '드래그해서 크기 조절',
      closeTitle: '닫기',
      minimizeTitle: '최소화',
      maximizeTitle: '최대화',
      chatDockName: 'LOREMASTER',
      toggleThemeTitle: '라이트/다크 모드 전환',
      toggleLayoutTitle: '레이아웃 전환',
      toggleLanguageTitle: '언어 전환',
      newLore: '새 로어',
      newFolder: '새 폴더',
      multiSelectionHint: 'Ctrl+클릭: 다중 선택 | Shift+클릭: 범위 선택',
      multiEditHint: '여러 항목이 선택됨 - 체크박스로 일괄 변경 가능',
      selectedCount: '개 항목 선택됨',
      helpTitle: '사용 가이드',
      helpButton: '도움말',
      helpIntro: 'LOREMASTER는 로어북을 효율적으로 관리하기 위한 고급 플러그인입니다.',
      helpSelection: '<b>다중 선택:</b> Ctrl+클릭으로 여러 항목을 선택하거나, 첫 항목 클릭 후 Shift+클릭으로 범위 선택합니다.',
      helpBatch: '<b>일괄 수정:</b> 여러 항목 선택 후 우측 패널의 체크박스로 한 번에 적용합니다.',
      helpDrag: '<b>드래그:</b> 선택된 항목들을 한꺼번에 이동하거나 폴더에 넣을 수 있습니다.',
      helpFolder: '<b>폴더:</b> 항목을 폴더로 드래그하여 정리합니다. 폴더 옆 화살표로 접기/펼치기.',
      helpSearch: '<b>검색:</b> 이름이나 키워드로 필터링하여 원하는 항목을 빠르게 찾습니다.',
      addKeyTitle: '선택한 항목에 활성화 키 추가',
      removeKeyTitle: '선택한 항목에서 활성화 키 삭제',
      addSecondKeyTitle: '선택한 항목에 보조 키 추가',
      removeSecondKeyTitle: '선택한 항목에서 보조 키 삭제',
      promptAddKey: '추가할 활성화 키를 입력하세요 (쉼표로 구분):',
      promptAddSecondKey: '추가할 보조 키를 입력하세요 (쉼표로 구분):',
      promptRemoveKey: '삭제할 활성화 키를 입력하세요:',
      promptRemoveSecondKey: '삭제할 보조 키를 입력하세요:',
      helpClose: '닫기'
    },
    en: {
      characterTab: 'Character',
      chatTab: 'Chat',
      lightMode: 'Light',
      darkMode: 'Dark',
      verticalLayout: 'Vertical',
      horizontalLayout: 'Horizontal',
      languageToggle: '한국어',
      addEntry: '+ Add Entry',
      addFolder: 'Add Folder',
      export: 'Export',
      import: 'Import',
      searchPlaceholder: 'Search...',
      search: 'Search',
      name: 'Name',
      keys: 'Keys',
      always: 'Always',
      disabled: 'Disabled',
      folder: 'Folder',
      off: 'Off',
      unnamed: 'Unnamed',
      editFolder: 'Edit Folder',
      editEntry: 'Edit Entry',
      entryNamePlaceholder: 'Entry name',
      insertOrder: 'Insert Order',
      activationKeys: 'Activation Keys',
      commaSeparated: 'comma separated',
      secondaryKeys: 'Secondary Keys',
      secondaryKeyPlaceholder: 'Secondary activation key',
      content: 'Content',
      contentPlaceholder: 'Lorebook content...',
      alwaysActive: 'Always Active',
      selective: 'Match both',
      useRegex: 'Use Regex',
      disableAll: 'Disable All',
      enableAll: 'Enable All',
      noEntries: 'No lore entries yet. Click "+ Add Entry" to create one.',
      selectEntry: 'Select an entry to edit',
      deleteTitle: 'Delete',
      deleteConfirm: 'Delete this entry?',
      dragTitle: 'Drag to reorder',
      resizeTitle: 'Drag to resize',
      closeTitle: 'Close',
      minimizeTitle: 'Minimize',
      maximizeTitle: 'Maximize',
      chatDockName: 'LOREMASTER',
      toggleThemeTitle: 'Toggle light/dark mode',
      toggleLayoutTitle: 'Toggle layout',
      toggleLanguageTitle: 'Toggle language',
      newLore: 'New Lore',
      newFolder: 'New Folder',
      multiSelectionHint: 'Ctrl+click: multi-select | Shift+click: range select',
      multiEditHint: 'Multiple items selected - use checkboxes for batch changes',
      selectedCount: 'items selected',
      helpTitle: 'User Guide',
      helpButton: 'Help',
      helpIntro: 'LOREMASTER is an advanced plugin for efficient lorebook management.',
      helpSelection: '<b>Multi-Select:</b> Ctrl+click to select multiple items, or click first item then Shift+click last item for range selection.',
      helpBatch: '<b>Batch Edit:</b> When multiple items are selected, use checkboxes in the right panel to apply changes to all.',
      helpDrag: '<b>Drag:</b> Move selected items together. Drop on folders to organize, or between items to reorder.',
      helpFolder: '<b>Folders:</b> Drag items into folders to organize. Use the arrow to expand/collapse folder contents.',
      helpSearch: '<b>Search:</b> Filter by name or keywords to quickly find entries.',
      addKeyTitle: 'Add activation key to selected items',
      removeKeyTitle: 'Remove activation key from selected items',
      addSecondKeyTitle: 'Add secondary key to selected items',
      removeSecondKeyTitle: 'Remove secondary key from selected items',
      promptAddKey: 'Enter activation key(s) to add (comma-separated):',
      promptAddSecondKey: 'Enter secondary key(s) to add (comma-separated):',
      promptRemoveKey: 'Enter activation key to remove:',
      promptRemoveSecondKey: 'Enter secondary key to remove:',
      helpClose: 'Close'
    }
  };

  /**
   * Translation helper - gets text for current language
   * Falls back to English if key is missing in current language
   * @param {string} key - Translation key
   * @returns {string} Translated text
   */
  function t(key) {
    return I18N[languageMode]?.[key] || I18N.en[key] || key;
  }

  // ============================================================================
  // SECTION 4: RISUAI DATA ACCESS
  // ============================================================================
  // Functions to interact with RisuAI's character and chat data.
  // These abstract the RisuAI Plugin API for cleaner code.
  // ============================================================================

  /**
   * Get current character info from RisuAI
   * Ensures globalLore array exists on the character
   */
  async function getCurrentCharacterInfo() {
    const charIndex = await Risuai.getCurrentCharacterIndex();
    const character = await Risuai.getCharacterFromIndex(charIndex);
    if (!character) throw new Error('현재 봇을 읽지 못했습니다.');
    if (!Array.isArray(character.globalLore)) character.globalLore = [];
    return { charIndex, character };
  }

  /**
   * Get current chat info from RisuAI
   * Ensures localLore array exists on the chat
   */
  async function getCurrentChatInfo() {
    const charIndex = await Risuai.getCurrentCharacterIndex();
    const chatIndex = await Risuai.getCurrentChatIndex();
    const chat = await Risuai.getChatFromIndex(charIndex, chatIndex);
    if (!chat) throw new Error('현재 채팅을 읽지 못했습니다.');
    if (!Array.isArray(chat.localLore)) chat.localLore = [];
    return { charIndex, chatIndex, chat };
  }

  // ============================================================================
  // SECTION 5: DISABLED LORE MANAGEMENT
  // ============================================================================
  // When entries are "hidden" (disabled), we can't delete them completely
  // because RisuAI might re-add them. Instead, we convert them to placeholder
  // entries and store the original in a separate disabled map.
  // ============================================================================

  /**
   * Get the storage key for disabled lore map based on current tab/character/chat
   * Different keys are used for character vs chat lore to keep them separate
   */
  async function getDisabledStoreKey() {
    const charIndex = await Risuai.getCurrentCharacterIndex();
    const character = await Risuai.getCharacterFromIndex(charIndex);
    const charKey = character?.chaId || `char-${charIndex}`;

    if (currentTab === 'character') {
      return `loremaster:disabled:character:${charKey}`;
    }

    const chatIndex = await Risuai.getCurrentChatIndex();
    const chat = await Risuai.getChatFromIndex(charIndex, chatIndex);
    const chatKey = chat?.id || `chat-${chatIndex}`;
    return `loremaster:disabled:chat:${charKey}:${chatKey}`;
  }

  /**
   * Add [X] prefix to indicate a disabled entry
   * Used when creating placeholder entries
   */
  function disabledPrefixComment(comment) {
    const text = String(comment || '');
    return text.startsWith('[X] ') ? text : `[X] ${text}`;
  }

  /**
   * Remove [X] or [DISABLED] prefix from comment
   * Used when restoring disabled entries
   */
  function stripDisabledPrefix(comment) {
    return String(comment || '').replace(/^\[(?:DISABLED|X)\]\s*/, '');
  }

  /**
   * Deep clone a lore entry to avoid reference issues
   */
  function cloneLoreEntry(entry) {
    return JSON.parse(JSON.stringify(entry || {}));
  }

  /**
   * Create a placeholder entry for disabled lore
   * Keeps the ID and comment but clears all functional data
   * The original data is stored separately in the disabled map
   */
  function createDisabledPlaceholder(entry) {
    return {
      ...cloneLoreEntry(entry),
      comment: disabledPrefixComment(stripDisabledPrefix(entry?.comment)),
      key: '',
      content: '',
      secondkey: '',
      alwaysActive: false,
      selective: false,
      useRegex: false,
      disabled: true
    };
  }

  /**
   * Load the disabled lore map from plugin storage
   * Returns an object mapping entry IDs to their original data
   */
  async function loadDisabledLoreMap() {
    try {
      const key = await getDisabledStoreKey();
      const stored = await Risuai.pluginStorage.getItem(key);

      if (Array.isArray(stored)) {
        return stored.reduce((map, entry) => {
          if (entry?.id) map[entry.id] = cloneLoreEntry(entry);
          return map;
        }, {});
      }

      return stored && typeof stored === 'object' ? stored : {};
    } catch {
      return {};
    }
  }

  /**
   * Save the disabled lore map to plugin storage
   * @param {Object} map - Object mapping entry IDs to original data
   */
  async function saveDisabledLoreMap(map) {
    const key = await getDisabledStoreKey();
    await Risuai.pluginStorage.setItem(key, map);
  }

  /**
   * Split a lore list into active entries and disabled map
   * Handles restoring disabled entries from the backup map
   * Folders are always kept active (can't be disabled)
   *
   * @param {Array} list - Full lore list from RisuAI
   * @param {Object} disabledMap - Map of disabled entry backups
   * @returns {Object} { active: Array, disabledMap: Object }
   */
  function splitActiveAndDisabledLore(list, disabledMap = {}) {
    const active = [];
    const nextDisabledMap = {};

    list.forEach((entry) => {
      if (!entry?.id) return;

      // Folders can't be disabled - always keep them active
      if (entry.mode === 'folder') {
        active.push({ ...entry, disabled: false, folder: undefined });
        return;
      }

      // Entry is currently disabled - store backup and create placeholder
      if (entry.disabled) {
        const previous = disabledMap[entry.id];
        const backup = previous ? cloneLoreEntry(previous) : cloneLoreEntry(entry);
        backup.comment = stripDisabledPrefix(backup.comment);
        backup.folder = entry.folder;
        backup.insertorder = entry.insertorder;
        backup.disabled = true;
        nextDisabledMap[entry.id] = backup;
        active.push(createDisabledPlaceholder(backup));
        return;
      }

      // Entry was previously disabled but now active - restore from backup
      if (disabledMap[entry.id]) {
        const restored = cloneLoreEntry(disabledMap[entry.id]);
        restored.folder = entry.folder;
        restored.insertorder = entry.insertorder;
        restored.disabled = false;
        active.push(restored);
        return;
      }

      // Normal active entry
      active.push({ ...entry, disabled: false });
    });

    return { active, disabledMap: nextDisabledMap };
  }

  // ============================================================================
  // SECTION 6: LORE LIST MANAGEMENT
  // ============================================================================
  // Core functions for reading and writing lore data to RisuAI.
  // Handles data normalization, ID assignment, and disabled entry handling.
  // ============================================================================

  /**
   * Get the current lore list (global or local based on currentTab)
   * Handles ID normalization, disabled entry restoration, and data cleanup
   * @returns {Array} Normalized lore entries
   */
  async function getLoreList() {
    try {
      let list = [];
      if (currentTab === 'character') {
        const { character } = await getCurrentCharacterInfo();
        list = character.globalLore || [];
      } else {
        const { chat } = await getCurrentChatInfo();
        list = chat.localLore || [];
      }

      const disabledMap = await loadDisabledLoreMap();
      const seenIds = new Set(list.map(entry => entry?.id).filter(Boolean));
      Object.values(disabledMap).forEach((entry) => {
        if (entry?.id && !seenIds.has(entry.id)) {
          list.push(createDisabledPlaceholder(entry));
          seenIds.add(entry.id);
        }
      });

      // --- 버그 수정: id가 없거나 중복된 기존 RisuAI 로어 항목에 고유 ID 부여 ---
      let needsSave = false;
      const usedIds = new Set();
      list.forEach(entry => {
        if (!entry.id || usedIds.has(entry.id)) {
          entry.id = makeUniqueId(usedIds);
          needsSave = true;
        } else {
          usedIds.add(entry.id);
        }
      });

      // 새 ID가 부여된 항목이 있다면 RisuAI 데이터에 덮어씌워 저장
      if (needsSave) {
        await saveLoreList(list);
      }
      // ----------------------------------------------------------------

      let normalizedFolders = false;
      list.forEach(entry => {
        if (entry.mode === 'folder' && entry.folder) {
          entry.folder = undefined;
          normalizedFolders = true;
        }
      });

      if (normalizedFolders) {
        await saveLoreList(list);
      }

      let restoredDisabledBackups = false;
      list.forEach(entry => {
        const backup = entry?.extentions?.__lm_disabled_backup;
        if (backup && typeof backup === 'object') {
          applyDisabledBehavior(entry, Boolean(entry.disabled));
          restoredDisabledBackups = true;
        }
      });

      if (restoredDisabledBackups) {
        await saveLoreList(list);
      }

      return list;
    } catch {
      return [];
    }
  }

  /**
   * Save the lore list to RisuAI
   * Handles disabled entries by storing them in the disabled map
   * and saving placeholders to the main lore array
   * @param {Array} list - Full lore list to save
   */
  async function saveLoreList(list) {
    const disabledMap = await loadDisabledLoreMap();
    const { active, disabledMap: nextDisabledMap } = splitActiveAndDisabledLore(list, disabledMap);
    await saveDisabledLoreMap(nextDisabledMap);

    if (currentTab === 'character') {
      const { charIndex, character } = await getCurrentCharacterInfo();
      character.globalLore = active;
      await Risuai.setCharacterToIndex(charIndex, character);
    } else {
      const { charIndex, chatIndex, chat } = await getCurrentChatInfo();
      chat.localLore = active;
      await Risuai.setChatToIndex(charIndex, chatIndex, chat);
    }
  }

  /**
   * Normalize an entry to ensure all required fields exist with correct types
   * Used when creating new entries or importing external data
   * @param {Object} source - Source object to normalize
   * @returns {Object} Normalized entry
   */
  function normalizeEntry(source = {}) {
    return {
      id: source.id || makeId(),
      key: String(source.key ?? ''),
      comment: String(source.comment || source.name || ''),
      content: String(source.content || ''),
      mode: source.mode || 'normal',
      insertorder: Number(source.insertorder ?? 100),
      alwaysActive: Boolean(source.alwaysActive),
      secondkey: String(source.secondkey ?? ''),
      selective: Boolean(source.selective),
      useRegex: Boolean(source.useRegex),
      disabled: Boolean(source.disabled),
      folder: source.mode === 'folder' ? undefined : (source.folder || undefined)
    };
  }

  function convertExternalLorebookEntries(entries) {
    const lore = [];
    if (!entries || typeof entries !== 'object') return lore;
    for (const k of Object.keys(entries)) {
      const currentLore = entries[k] || {};
      const keysArr = Array.isArray(currentLore.key) ? currentLore.key
        : Array.isArray(currentLore.keys) ? currentLore.keys
        : Array.isArray(currentLore.keywords) ? currentLore.keywords
        : [];

      lore.push(normalizeEntry({
        key: keysArr.join(', '),
        insertorder: currentLore.order ?? currentLore.priority ?? currentLore?.contextConfig?.budgetPriority ?? 0,
        comment: currentLore.comment || currentLore.name || currentLore.displayName || '',
        content: currentLore.content || currentLore.entry || currentLore.text || '',
        mode: 'normal',
        alwaysActive: currentLore.constant ?? currentLore.forceActivation ?? false,
        secondkey: Array.isArray(currentLore.secondary_keys) ? currentLore.secondary_keys.join(', ') : '',
        selective: currentLore.selective ?? false
      }));
    }
    return lore;
  }

  function normalizeImportedEntry(source, usedIds) {
    const entry = normalizeEntry(source);
    if (!entry.id || usedIds.has(entry.id)) {
      entry.id = makeUniqueId(usedIds);
    } else {
      usedIds.add(entry.id);
    }
    return entry;
  }

  function ensureExt(entry) {
    if (!entry.extentions || typeof entry.extentions !== 'object') entry.extentions = {};
    return entry.extentions;
  }

  function applyDisabledBehavior(entry, disabled) {
    if (!entry || entry.mode === 'folder') return;

    const ext = ensureExt(entry);
    const backupKey = '__lm_disabled_backup';
    const b = ext[backupKey];

    if (b && typeof b === 'object') {
      entry.key = String(b.key ?? '');
      entry.secondkey = String(b.secondkey ?? '');
      entry.alwaysActive = Boolean(b.alwaysActive);
      entry.selective = Boolean(b.selective);
      entry.useRegex = Boolean(b.useRegex);
      delete ext[backupKey];
    }
  }

  // ============================================================================
  // SECTION 7: IMPORT / EXPORT
  // ============================================================================
  // Functions for exporting lorebook data to JSON and importing from
  // various formats including RisuAI exports and other lorebook tools.
  // ============================================================================

  /**
   * Trigger a file download with JSON content
   * @param {string} filename - Name for the downloaded file
   * @param {Object} obj - Object to serialize as JSON
   */
  function downloadJson(filename, obj) {
    const data = JSON.stringify(obj, null, 2);
    const blob = new Blob([data], { type: 'application/json;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }

  /**
   * Export current lore list to a JSON file
   */
  async function exportLoreBookCurrent() {
    try {
      const lore = await getLoreList();
      downloadJson('lorebook_export.json', { type: 'risu', ver: 1, data: lore });
    } catch (e) {
      alert(e?.message || String(e));
    }
  }

  /**
   * Import lore entries from a JSON file
   * Supports RisuAI format and various external lorebook formats
   */
  async function importLoreBookCurrent() {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json,.lorebook,application/json';
    input.style.display = 'none';
    document.body.appendChild(input);

    const readFile = () => new Promise((resolve) => {
      input.onchange = () => resolve(input.files?.[0] || null);
      input.click();
    });

    const file = await readFile();
    input.remove();
    if (!file) return;

    const text = await file.text();
    let imported;
    try {
      imported = JSON.parse(text);
    } catch (e) {
      alert('Import 실패: JSON 파싱에 실패했어.');
      return;
    }

    const list = await getLoreList();
    const usedIds = new Set(list.map(e => e.id).filter(Boolean));
    try {
      if (imported?.type === 'risu' && Array.isArray(imported?.data)) {
        imported.data.forEach((e) => list.push(normalizeImportedEntry(e, usedIds)));
      } else if (imported?.entries && typeof imported.entries === 'object') {
        convertExternalLorebookEntries(imported.entries)
          .forEach((e) => list.push(normalizeImportedEntry(e, usedIds)));
      } else {
        alert('Import 실패: 지원하지 않는 로어북 포맷이야.');
        return;
      }

      // Hard rule: folders can never be inside folders
      list.forEach(e => {
        if (e.mode === 'folder') e.folder = undefined;
      });

      // Apply disabled behavior normalization (skip like deleted)
      list.forEach(e => {
        if (e.disabled) applyDisabledBehavior(e, true);
      });

      // Recalculate order
      list.forEach((e, i) => e.insertorder = (i + 1) * 10);
      await saveLoreList(list);
      await render(true);
      await syncChatDockButton();
    } catch (e) {
      alert(e?.message || String(e));
    }
  }

  // ============================================================================
  // SECTION 8: ENTRY CRUD OPERATIONS
  // ============================================================================
  // Create, Read, Update, Delete operations for lore entries and folders.
  // Also includes batch operations for multi-selection.
  // ============================================================================

  /**
   * Create a new lore entry
   * Adds to the end of the list and selects it for editing
   */
  async function addEntry() {
    const list = await getLoreList();
    const newEntry = normalizeEntry({
      comment: `${t('newLore')} ${list.length + 1}`,
      insertorder: list.length > 0
        ? Math.max(...list.map(e => e.insertorder || 100)) + 10
        : 100
    });
    list.push(newEntry);
    await saveLoreList(list);
    editingEntryId = newEntry.id;
    expandedEntries.add(newEntry.id);
    await render();
    await syncChatDockButton();
  }

  /**
   * Create a new folder
   * Folders use a special key format: "folder:<id>" for internal identification
   * The folder is inserted above the currently selected entry if one exists
   */
  async function addFolder() {
    const list = await getLoreList();
    const folderId = makeId();
    const newFolder = normalizeEntry({
      comment: t('newFolder'),
      mode: 'folder',
      key: `folder:${folderId}`,
      insertorder: list.length > 0
        ? Math.max(...list.map(e => e.insertorder || 100)) + 10
        : 100
    });

    // Insert above the currently selected root entry or the parent folder of the selected child
    const sorted = [...list].sort((a, b) => (a.insertorder || 0) - (b.insertorder || 0));
    let anchor = null;
    if (editingEntryId) {
      const selected = sorted.find(e => e.id === editingEntryId) || null;
      if (selected) {
        if (selected.folder) {
          anchor = sorted.find(e => e.mode === 'folder' && e.key === selected.folder) || selected;
        } else {
          anchor = selected;
        }
      }
    }

    if (anchor) {
      const idx = sorted.findIndex(e => e.id === anchor.id);
      sorted.splice(Math.max(0, idx), 0, newFolder);
    } else {
      sorted.push(newFolder);
    }

    sorted.forEach((e, i) => { e.insertorder = (i + 1) * 10; });

    await saveLoreList(sorted);
    editingEntryId = newFolder.id;
    expandedEntries.add(newFolder.id);
    await render();
    await syncChatDockButton();
  }

  /**
   * Update a single entry by ID
   * @param {string} entryId - Entry ID to update
   * @param {Object} updates - Partial updates to apply
   */
  async function updateEntry(entryId, updates) {
    const list = await getLoreList();
    const index = list.findIndex(e => e.id === entryId);
    if (index === -1) return;
    list[index] = { ...list[index], ...updates };
    if (updates && Object.prototype.hasOwnProperty.call(updates, 'disabled')) {
      applyDisabledBehavior(list[index], Boolean(updates.disabled));
    }
    await saveLoreList(list);
  }

  /**
   * Set disabled state for all children of a folder
   * Used for "Hide All" / "Show All" buttons in folder editor
   * @param {string} folderKey - Folder key to target
   * @param {boolean} disabled - New disabled state
   */
  async function setFolderChildrenDisabled(folderKey, disabled) {
    const list = await getLoreList();
    let changed = false;
    list.forEach(e => {
      if (e.folder === folderKey && e.disabled !== disabled) {
        e.disabled = disabled;
        changed = true;
      }
    });
    if (changed) {
      await saveLoreList(list);
      await render(true);
      await syncChatDockButton();
    }
  }

  /**
   * Delete an entry by ID
   * If the entry is a folder, all its children are also deleted
   * @param {string} entryId - Entry ID to delete
   */
  async function deleteEntry(entryId) {
    const list = await getLoreList();
    const entry = list.find(e => e.id === entryId);
    if (!entry) return;

    // If folder, also remove children
    if (entry.mode === 'folder') {
      const folderKey = entry.key;
      const newList = list.filter(e => e.id !== entryId && e.folder !== folderKey);
      await saveLoreList(newList);
    } else {
      const newList = list.filter(e => e.id !== entryId);
      await saveLoreList(newList);
    }

    // Remove from selection if present
    if (selectedEntryIds.has(entryId)) {
      selectedEntryIds.delete(entryId);
    }

    if (editingEntryId === entryId) {
      editingEntryId = null;
    }
    expandedEntries.delete(entryId);
    await render();
    await syncChatDockButton();
  }

  /**
   * Toggle folder expanded/collapsed state
   * @param {string} entryId - Folder entry ID
   */
  function toggleExpand(entryId) {
    if (expandedEntries.has(entryId)) {
      expandedEntries.delete(entryId);
    } else {
      expandedEntries.add(entryId);
    }
  }

  /**
   * Get all children of a folder
   * @param {Array} list - Full lore list
   * @param {string} folderKey - Folder key to search for
   * @returns {Array} Child entries
   */
  function getFolderChildren(list, folderKey) {
    return list.filter(e => e.folder === folderKey);
  }

  function renderEntry(entry, isChild = false, listForFolder = null, listIndex = null) {
    const isExpanded = expandedEntries.has(entry.id);
    const isEditing = editingEntryId === entry.id;
    const isMultiSelected = selectedEntryIds.has(entry.id);
    const isFolder = entry.mode === 'folder';
    const folderChildren = (isFolder && Array.isArray(listForFolder)) ? getFolderChildren(listForFolder, entry.key) : [];
    const hasChildren = isFolder ? folderChildren.length > 0 : false;
    const folderPreview = isFolder && hasChildren
      ? folderChildren
        .map((c) => stripParenText(c.comment || ''))
        .filter(Boolean)
        .slice(0, 10)
        .join(' | ') + (folderChildren.length > 10 ? ' | ...' : '')
      : '';

    const FOLDER_ICON_HAS = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640"><path d="M128 512L512 512C547.3 512 576 483.3 576 448L576 208C576 172.7 547.3 144 512 144L362.7 144C355.8 144 349 141.8 343.5 137.6L305.1 108.8C294 100.5 280.5 96 266.7 96L128 96C92.7 96 64 124.7 64 160L64 448C64 483.3 92.7 512 128 512z"/></svg>`;
    const FOLDER_ICON_EMPTY = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640"><path d="M128 464L512 464C520.8 464 528 456.8 528 448L528 208C528 199.2 520.8 192 512 192L362.7 192C345.4 192 328.5 186.4 314.7 176L276.3 147.2C273.5 145.1 270.2 144 266.7 144L128 144C119.2 144 112 151.2 112 160L112 448C112 456.8 119.2 464 128 464zM512 512L128 512C92.7 512 64 483.3 64 448L64 160C64 124.7 92.7 96 128 96L266.7 96C280.5 96 294 100.5 305.1 108.8L343.5 137.6C349 141.8 355.8 144 362.7 144L512 144C547.3 144 576 172.7 576 208L576 448C576 483.3 547.3 512 512 512z"/></svg>`;

    const dragAttrs = `draggable="true" data-id="${escapeHtml(entry.id)}" data-index="${listIndex ?? ''}"`;

    return `
      <div class="lm-entry ${isChild ? 'lm-child' : ''} ${isFolder ? 'lm-folder' : ''} ${entry.disabled ? 'lm-disabled-entry' : ''} ${isEditing || isMultiSelected ? 'lm-selected' : ''} ${isMultiSelected && !isEditing ? 'lm-multi-selected' : ''}" ${dragAttrs}>
        <div class="lm-entry-header">
          <div class="lm-entry-checkbox" title="Ctrl+클릭 또는 Shift+클릭으로 다중 선택">
            <input type="checkbox" class="lm-select-checkbox" data-id="${escapeHtml(entry.id)}" ${isMultiSelected ? 'checked' : ''}>
          </div>
          <div class="lm-drag-handle" title="${escapeHtml(t('dragTitle'))}">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="9" cy="12" r="1" fill="currentColor" stroke="none"/>
              <circle cx="15" cy="12" r="1" fill="currentColor" stroke="none"/>
              <circle cx="9" cy="6" r="1" fill="currentColor" stroke="none"/>
              <circle cx="15" cy="6" r="1" fill="currentColor" stroke="none"/>
              <circle cx="9" cy="18" r="1" fill="currentColor" stroke="none"/>
              <circle cx="15" cy="18" r="1" fill="currentColor" stroke="none"/>
            </svg>
          </div>

          ${isFolder ? `
            <button class="lm-expand-btn" data-action="expand" data-id="${escapeHtml(entry.id)}">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="transform: ${isExpanded ? 'rotate(90deg)' : 'none'}; transition: transform 0.2s;">
                <polyline points="9 18 15 12 9 6"></polyline>
              </svg>
            </button>
          ` : '<div class="lm-expand-placeholder"></div>'}

          <div class="lm-entry-title">
            ${isFolder
              ? `<div class="lm-entry-title-row">
                  <span class="lm-folder-icon">${hasChildren ? FOLDER_ICON_HAS : FOLDER_ICON_EMPTY}</span>
                  <span class="lm-entry-name ${entry.disabled ? 'lm-disabled' : ''}">${escapeHtml(entry.comment || t('unnamed'))}</span>
                </div>`
              : `<span class="lm-entry-name ${entry.disabled ? 'lm-disabled' : ''}">${escapeHtml(entry.comment || t('unnamed'))}</span>`
            }
            ${isFolder
              ? `${!isExpanded ? `<span class="lm-entry-key lm-folder-preview">${escapeHtml(folderPreview || '')}</span>` : ''}`
              : (!entry.alwaysActive && entry.key ? `<span class="lm-entry-key">${escapeHtml(entry.key.slice(0, 30))}${entry.key.length > 30 ? '...' : ''}</span>` : '')
            }
          </div>

          <div class="lm-entry-badges">
            ${entry.alwaysActive ? `<span class="lm-badge always">${escapeHtml(t('always'))}</span>` : ''}
            ${entry.disabled ? `<span class="lm-badge off">${escapeHtml(t('off'))}</span>` : ''}
            ${isFolder ? `<span class="lm-badge folder">${escapeHtml(t('folder'))}</span>` : ''}
          </div>

          <button class="lm-icon-btn lm-delete" data-action="delete" data-id="${escapeHtml(entry.id)}" title="${escapeHtml(t('deleteTitle'))}">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="3 6 5 6 21 6"></polyline>
              <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
            </svg>
          </button>
        </div>

      </div>
    `;
  }

  function renderHelpPanel() {
    if (!isHelpOpen) return '';

    return `
      <div class="lm-help-overlay" data-action="close-help-overlay">
        <div class="lm-help-panel">
          <div class="lm-help-header">
            <h3>${escapeHtml(t('helpTitle'))}</h3>
            <button class="lm-close-help" data-action="toggle-help">✕</button>
          </div>
          <div class="lm-help-body">
            <div class="lm-help-section">
              <p>${t('helpIntro')}</p>
            </div>
            <div class="lm-help-section">
              ${t('helpSelection')}
            </div>
            <div class="lm-help-section">
              ${t('helpBatch')}
            </div>
            <div class="lm-help-section">
              ${t('helpDrag')}
            </div>
            <div class="lm-help-section">
              ${t('helpFolder')}
            </div>
            <div class="lm-help-section">
              ${t('helpSearch')}
            </div>
          </div>
          <div class="lm-help-footer">
            <button class="lm-btn lm-btn-primary" data-action="toggle-help">${escapeHtml(t('helpClose'))}</button>
          </div>
        </div>
      </div>
    `;
  }

  function renderEditor(entry) {
    if (!entry) return '';

    const isMultiSelect = selectedEntryIds.size > 1;
    entry = getDraftForEntry(entry);
    const isFolder = entry.mode === 'folder';

    return `
      <div class="lm-editor ${isMultiSelect ? 'lm-editor-multi' : ''}">
        <div class="lm-editor-header">
          <h3>${isMultiSelect
            ? `📋 ${escapeHtml(selectedEntryIds.size + ' ' + t('selectedCount'))}`
            : isFolder ? `📁 ${escapeHtml(t('editFolder'))}` : `📄 ${escapeHtml(t('editEntry'))}`}</h3>
          <button class="lm-close-editor" data-action="close-editor">✕</button>
        </div>

        ${isMultiSelect ? `
        <div class="lm-multi-select-notice">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"/>
            <line x1="12" y1="8" x2="12" y2="12"/>
            <line x1="12" y1="16" x2="12.01" y2="16"/>
          </svg>
          <span>${escapeHtml(t('multiEditHint'))}</span>
        </div>
        ` : ''}

        <div class="lm-editor-body">
          <!-- Top Section: Main Fields -->
          <div class="lm-editor-top">
            <!-- Row 1: Name & Order -->
            <div class="lm-editor-row">
              <div class="lm-field lm-field-grow ${isMultiSelect ? 'lm-field-disabled' : ''}">
                <label>${escapeHtml(t('name'))}</label>
                <input type="text" id="lm-edit-comment" class="lm-input" value="${escapeHtml(entry.comment)}" placeholder="${escapeHtml(t('entryNamePlaceholder'))}" ${isMultiSelect ? 'disabled' : ''}>
              </div>
              <div class="lm-field lm-field-narrow ${isMultiSelect ? 'lm-field-disabled' : ''}">
                <label>${escapeHtml(t('insertOrder'))}</label>
                <input type="number" id="lm-edit-order" class="lm-input lm-number" value="${entry.insertorder}" min="0" max="1000" ${isMultiSelect ? 'disabled' : ''}>
              </div>
            </div>

            <!-- Row 2: Activation Keys & Secondary Keys -->
            ${!isFolder ? `
            <div class="lm-editor-row-keys">
              <div class="lm-field ${isMultiSelect ? 'lm-field-disabled' : ''}">
                <label class="lm-key-label">
                  ${escapeHtml(t('activationKeys'))} <span class="lm-hint">(${escapeHtml(t('commaSeparated'))})</span>
                  ${isMultiSelect ? `
                    <span class="lm-key-buttons">
                      <button class="lm-key-btn lm-key-btn-add" data-action="batch-key-add" data-field="key" title="${escapeHtml(t('addKeyTitle'))}">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640" width="18" height="18"><path d="M160 96C124.7 96 96 124.7 96 160L96 480C96 515.3 124.7 544 160 544L480 544C515.3 544 544 515.3 544 480L544 160C544 124.7 515.3 96 480 96L160 96zM296 408L296 344L232 344C218.7 344 208 333.3 208 320C208 306.7 218.7 296 232 296L296 296L296 232C296 218.7 306.7 208 320 208C333.3 208 344 218.7 344 232L344 296L408 296C421.3 296 432 306.7 432 320C432 333.3 421.3 344 408 344L344 344L344 408C344 421.3 333.3 432 320 432C306.7 432 296 421.3 296 408z"/></svg>
                      </button>
                      <button class="lm-key-btn lm-key-btn-remove" data-action="batch-key-remove" data-field="key" title="${escapeHtml(t('removeKeyTitle'))}">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640" width="18" height="18"><path d="M160 96C124.7 96 96 124.7 96 160L96 480C96 515.3 124.7 544 160 544L480 544C515.3 544 544 515.3 544 480L544 160C544 124.7 515.3 96 480 96L160 96zM232 296L408 296C421.3 296 432 306.7 432 320C432 333.3 421.3 344 408 344L232 344C218.7 344 208 333.3 208 320C208 306.7 218.7 296 232 296z"/></svg>
                      </button>
                    </span>
                  ` : ''}
                </label>
                <textarea id="lm-edit-key" class="lm-input lm-autogrow" rows="1" placeholder="@keyword, #tag" ${isMultiSelect ? 'disabled' : ''}>${escapeHtml(entry.key)}</textarea>
              </div>
              <div class="lm-field ${isMultiSelect ? 'lm-field-disabled' : ''}">
                <label class="lm-key-label">
                  ${escapeHtml(t('secondaryKeys'))}
                  ${isMultiSelect ? `
                    <span class="lm-key-buttons">
                      <button class="lm-key-btn lm-key-btn-add" data-action="batch-key-add" data-field="secondkey" title="${escapeHtml(t('addSecondKeyTitle'))}">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640" width="18" height="18"><path d="M160 96C124.7 96 96 124.7 96 160L96 480C96 515.3 124.7 544 160 544L480 544C515.3 544 544 515.3 544 480L544 160C544 124.7 515.3 96 480 96L160 96zM296 408L296 344L232 344C218.7 344 208 333.3 208 320C208 306.7 218.7 296 232 296L296 296L296 232C296 218.7 306.7 208 320 208C333.3 208 344 218.7 344 232L344 296L408 296C421.3 296 432 306.7 432 320C432 333.3 421.3 344 408 344L344 344L344 408C344 421.3 333.3 432 320 432C306.7 432 296 421.3 296 408z"/></svg>
                      </button>
                      <button class="lm-key-btn lm-key-btn-remove" data-action="batch-key-remove" data-field="secondkey" title="${escapeHtml(t('removeSecondKeyTitle'))}">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640" width="18" height="18"><path d="M160 96C124.7 96 96 124.7 96 160L96 480C96 515.3 124.7 544 160 544L480 544C515.3 544 544 515.3 544 480L544 160C544 124.7 515.3 96 480 96L160 96zM232 296L408 296C421.3 296 432 306.7 432 320C432 333.3 421.3 344 408 344L232 344C218.7 344 208 333.3 208 320C208 306.7 218.7 296 232 296z"/></svg>
                      </button>
                    </span>
                  ` : ''}
                </label>
                <textarea id="lm-edit-secondkey" class="lm-input lm-autogrow" rows="1" placeholder="${escapeHtml(t('secondaryKeyPlaceholder'))}" ${isMultiSelect ? 'disabled' : ''}>${escapeHtml(entry.secondkey)}</textarea>
              </div>
            </div>
            ` : ''}
          </div>

          <!-- Bottom Section: Content & Checkboxes -->
          <div class="lm-editor-bottom">
            <!-- Content -->
            ${!isFolder ? `
            <div class="lm-field lm-content-field ${isMultiSelect ? 'lm-field-disabled' : ''}">
              <label>${escapeHtml(t('content'))}</label>
              <textarea id="lm-edit-content" class="lm-textarea lm-content-textarea" rows="8" placeholder="${escapeHtml(t('contentPlaceholder'))}" ${isMultiSelect ? 'disabled' : ''}>${escapeHtml(entry.content)}</textarea>
            </div>
            ` : '<div class="lm-field lm-content-field"></div>'}

            <!-- Checkboxes -->
            <div class="lm-editor-right">
              ${!isFolder ? `
              <div class="lm-checkbox-stack">
                <label class="lm-check-item">
                  <input type="checkbox" id="lm-edit-disabled" ${entry.disabled ? 'checked' : ''} data-action="batch-checkbox" data-field="disabled">
                  <span>${escapeHtml(t('disabled'))}</span>
                  ${isMultiSelect ? '<span class="lm-batch-indicator">(일괄)</span>' : ''}
                </label>
                <label class="lm-check-item">
                  <input type="checkbox" id="lm-edit-always" ${entry.alwaysActive ? 'checked' : ''} data-action="batch-checkbox" data-field="alwaysActive">
                  <span>${escapeHtml(t('alwaysActive'))}</span>
                  ${isMultiSelect ? '<span class="lm-batch-indicator">(일괄)</span>' : ''}
                </label>
                <label class="lm-check-item">
                  <input type="checkbox" id="lm-edit-selective" ${entry.selective ? 'checked' : ''} data-action="batch-checkbox" data-field="selective">
                  <span>${escapeHtml(t('selective'))}</span>
                  ${isMultiSelect ? '<span class="lm-batch-indicator">(일괄)</span>' : ''}
                </label>
                <label class="lm-check-item">
                  <input type="checkbox" id="lm-edit-regex" ${entry.useRegex ? 'checked' : ''} data-action="batch-checkbox" data-field="useRegex">
                  <span>${escapeHtml(t('useRegex'))}</span>
                  ${isMultiSelect ? '<span class="lm-batch-indicator">(일괄)</span>' : ''}
                </label>
              </div>
              ` : `
              <div class="lm-checkbox-stack">
                <button class="lm-btn lm-btn-secondary" data-action="folder-disable-all" data-key="${escapeHtml(entry.key)}" style="width: 100%; justify-content: center;">${escapeHtml(t('disableAll'))}</button>
                <button class="lm-btn lm-btn-secondary" data-action="folder-enable-all" data-key="${escapeHtml(entry.key)}" style="width: 100%; justify-content: center;">${escapeHtml(t('enableAll'))}</button>
              </div>
              `}
            </div>
          </div>
        </div>

        <div class="lm-editor-footer"></div>
      </div>
    `;
  }

  // ==================== THEME COLORS ====================
  const Themes = {
    light: {
      // Backgrounds
      bg: '#f6f7f8',
      containerBg: 'rgba(248, 249, 250, 0.82)',
      surface: '#fff',
      surfaceHover: '#fafbfc',

      // Text
      text: '#24292e',
      textMuted: '#6a737d',
      textDisabled: '#cf222e',

      // Accents
      primary: '#0969da',
      primaryLight: '#f1f8ff',
      primaryHover: '#e6f2ff',

      // Borders
      border: '#e8eaed',
      borderHover: '#c4c9d0',

      // Folder
      folderBg: '#0969da',
      folderBgHover: '#063a8a',
      folderText: '#fff',

      // Badges
      badgeAlways: '#ddf4ff',
      badgeAlwaysText: '#0969da',
      badgeOff: '#ffebe9',
      badgeOffText: '#cf222e',

      // Shadows
      shadow: '0 16px 40px rgba(0, 0, 0, 0.12)'
    },

    dark: {
      // Backgrounds
      bg: '#2d3243',
      containerBg: 'rgba(26, 27, 38, 0.85)',
      surface: 'rgba(40, 44, 56, 0.9)',
      surfaceHover: '#394056',

      // Text
      text: '#e1e4e8',
      textMuted: '#959da5',
      textDisabled: '#ff7b72',

      // Accents
      primary: '#4299e1',
      primaryLight: '#1e3a5f',
      primaryHover: '#1c3a66',

      // Borders
      border: '#4a5160',
      borderHover: '#505564',

      // Folder
      folderBg: '#24416b',
      folderBgHover: '#1c3354',
      folderText: '#fff',

      // Badges
      badgeAlways: 'rgba(66, 153, 225, 0.2)',
      badgeAlwaysText: '#4299e1',
      badgeOff: 'rgba(255, 123, 114, 0.1)',
      badgeOffText: '#ff7b72',

      // Shadows
      shadow: '0 16px 40px rgba(0, 0, 0, 0.3)'
    }
  };

  const theme = Themes[themeMode];

  /**
   * Parse a comma-separated key string into an array of trimmed, non-empty keys
   * @param {string} keyString - Comma-separated keys
   * @returns {string[]} Array of trimmed keys
   */
  function parseKeys(keyString) {
    return String(keyString || '')
      .split(',')
      .map(k => k.trim())
      .filter(k => k.length > 0);
  }

  /**
   * Convert an array of keys back to a comma-separated string
   * @param {string[]} keys - Array of keys
   * @returns {string} Comma-separated string
   */
  function joinKeys(keys) {
    return keys.join(', ');
  }

  /**
   * Add key(s) to multiple entries in batch
   * @param {string} field - Either 'key' (activation) or 'secondkey' (secondary)
   */
  async function handleBatchKeyAdd(field) {
    if (selectedEntryIds.size === 0) return;

    const isSecondary = field === 'secondkey';
    const promptMessage = isSecondary ? t('promptAddSecondKey') : t('promptAddKey');
    const input = prompt(promptMessage);

    if (input === null || input === undefined) return; // Cancelled

    const keysToAdd = parseKeys(input);
    if (keysToAdd.length === 0) return; // Empty input

    const list = await getLoreList();
    let changed = false;

    list.forEach(entry => {
      if (selectedEntryIds.has(entry.id) && entry.mode !== 'folder') {
        const currentKeys = parseKeys(entry[field]);
        const newKeys = [...currentKeys];

        keysToAdd.forEach(key => {
          if (!newKeys.includes(key)) {
            newKeys.push(key);
            changed = true;
          }
        });

        if (changed) {
          entry[field] = joinKeys(newKeys);
        }
      }
    });

    if (changed) {
      await saveLoreList(list);
      await render(true);
      await syncChatDockButton();
    }
  }

  /**
   * Remove key(s) from multiple entries in batch
   * Only removes if the key exactly matches an existing key
   * @param {string} field - Either 'key' (activation) or 'secondkey' (secondary)
   */
  async function handleBatchKeyRemove(field) {
    if (selectedEntryIds.size === 0) return;

    const isSecondary = field === 'secondkey';
    const promptMessage = isSecondary ? t('promptRemoveSecondKey') : t('promptRemoveKey');
    const input = prompt(promptMessage);

    if (input === null || input === undefined) return; // Cancelled

    const keysToRemove = parseKeys(input);
    if (keysToRemove.length === 0) return; // Empty input

    const list = await getLoreList();
    let changed = false;

    list.forEach(entry => {
      if (selectedEntryIds.has(entry.id) && entry.mode !== 'folder') {
        const currentKeys = parseKeys(entry[field]);
        const newKeys = currentKeys.filter(k => !keysToRemove.includes(k));

        if (newKeys.length !== currentKeys.length) {
          entry[field] = joinKeys(newKeys);
          changed = true;
        }
      }
    });

    if (changed) {
      await saveLoreList(list);
      await render(true);
      await syncChatDockButton();
    }
  }

  // ============================================================================
  // SECTION 9: RENDER HELPERS
  // ============================================================================
  // Helper functions for filtering, sorting, and rendering the lore list.
  // These are separated from the main render() function for better
  // maintainability and to enable scroll preservation.
  // ============================================================================

  /**
   * Get the filtered and sorted lore list based on current search/filter settings
   * Handles special cases:
   * - If a folder matches search, include all its children
   * - If a child matches search, ensure its parent folder is visible
   * @returns {Array} Filtered and sorted lore entries
   */
  async function getFilteredList() {
    const fullList = await getLoreList();

    // Apply filters
    let list = fullList.filter(e => {
      if (searchQuery) {
        const q = searchQuery.toLowerCase();
        if (searchTarget === 'name') {
          if (!String(e.comment).toLowerCase().includes(q)) return false;
        } else {
          const keys = (String(e.key) + ' ' + String(e.secondkey)).toLowerCase();
          if (!keys.includes(q)) return false;
        }
      }
      if (filterAlways && !e.alwaysActive) return false;
      if (filterDisabled && !e.disabled) return false;
      return true;
    });

    // 1. If a folder matches, include all its children
    const matchedFolderKeys = new Set(list.filter(e => e.mode === 'folder').map(e => e.key));
    fullList.forEach(e => {
      if (e.folder && matchedFolderKeys.has(e.folder) && !list.includes(e)) {
        list.push(e);
      }
    });

    // 2. If a child matches, ensure its parent folder is included
    const folderKeysToInclude = new Set();
    list.forEach(e => {
      if (e.folder) folderKeysToInclude.add(e.folder);
    });
    fullList.forEach(e => {
      if (e.mode === 'folder' && folderKeysToInclude.has(e.key) && !list.includes(e)) {
        list.push(e);
      }
    });

    return list.sort((a, b) => (a.insertorder || 0) - (b.insertorder || 0));
  }

  /**
   * Render the list of lore entries as HTML
   * Builds the entry list HTML with folder expansion handling
   * @param {Array} list - Filtered lore list
   * @returns {string} HTML string
   */
  function renderListItems(list) {
    const rootEntries = list.filter(e => !e.folder);
    if (list.length === 0) {
      return `<div class="lm-empty">${escapeHtml(t('noEntries'))}</div>`;
    }

    let html = '';
    let index = 0;
    rootEntries.forEach((entry) => {
      html += renderEntry(entry, false, list, index++);
      // Render children if folder is expanded
      if (entry.mode === 'folder' && expandedEntries.has(entry.id)) {
        const children = getFolderChildren(list, entry.key);
        if (children.length > 0) {
          html += `<div class="lm-folder-children">`;
          children.forEach((child) => {
            html += renderEntry(child, true, list, index++);
          });
          html += `</div>`;
        }
      }
    });
    return html;
  }

  /**
   * Get the current scroll position for preservation
   * @param {boolean} preserveScroll - Whether to preserve scroll
   * @returns {number} Scroll position in pixels
   */
  function getScrollPosition(preserveScroll) {
    if (!preserveScroll) return 0;
    const scrollEl = document.querySelector('.lm-list-scroll');
    return scrollEl?.scrollTop || 0;
  }

  // ============================================================================
  // SECTION 10: MAIN RENDER FUNCTION
  // ============================================================================
  // The main render function that builds the entire UI. It generates all CSS,
  // HTML structure, and attaches event listeners after rendering.
  // Uses scroll preservation to maintain user position during updates.
  // ============================================================================

  /**
   * Main render function - builds the entire plugin UI
   * @param {boolean} preserveScroll - Whether to preserve scroll position (default: true)
   */
  async function render(preserveScroll = true) {
    const list = await getFilteredList();
    const fullList = await getLoreList();
    const editingEntry = fullList.find(e => e.id === editingEntryId);
    const targetInfo = await getCurrentTargetInfo();
    const scrollPos = getScrollPosition(preserveScroll);
    const rootEntries = list.filter(e => !e.folder);

    document.body.innerHTML = `
      <style>
        * { box-sizing: border-box; }

        body {
          margin: 0;
          padding: 0;
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
          background: transparent;
          color: #2c3e50;
          font-size: 14px;
          line-height: 1.5;
        }

        .lm-container {
          max-width: 1500px;
          width: min(1500px, calc(100vw - 40px));
          margin: 20px auto 0;
          padding: 16px;
          background: rgba(248, 249, 250, 0.82);
          backdrop-filter: blur(8px);
          border: 1px solid rgba(225, 228, 232, 0.55);
          border-radius: 16px;
          box-shadow: 0 16px 40px rgba(0, 0, 0, 0.12);
        }

        .lm-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          margin-bottom: 24px;
          padding-bottom: 16px;
          border-bottom: 1px solid rgba(225, 228, 232, 0.6);
        }

        .lm-header-left {
          display: flex;
          align-items: center;
          gap: 12px;
          min-width: 0;
        }

        .lm-control-cluster {
          display: flex;
          align-items: center;
          gap: 6px;
          flex-shrink: 0;
        }

        .lm-header-right {
          display: flex;
          align-items: center;
          gap: 12px;
        }

        .lm-target-info {
          min-width: 0;
          line-height: 1.2;
        }

        .lm-target-character {
          color: #1a1a1a;
          font-size: 24px;
          font-weight: 700;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
          max-width: 520px;
        }

        .lm-target-chat {
          margin-top: 4px;
          color: #586069;
          font-size: 13px;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
          max-width: 520px;
        }

        .lm-app-icon {
          display: flex;
          align-items: center;
          justify-content: center;
          width: 28px;
          height: 28px;
        }

        .lm-close-btn {
          width: 36px;
          height: 36px;
          border: 1px solid #d1d5da;
          background: #fff;
          color: #586069;
          cursor: pointer;
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          transition: all 0.15s;
        }

        .lm-close-btn:hover {
          background: #ffebe9;
          color: #cf222e;
          border-color: #cf222e;
        }

        .lm-help-btn {
          width: 36px;
          height: 36px;
          border: 1px solid #d1d5da;
          background: #fff;
          color: #586069;
          cursor: pointer;
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          transition: all 0.15s;
        }

        .lm-help-btn:hover {
          background: #f1f8ff;
          color: #0969da;
          border-color: #0969da;
        }

        /* Help Panel Styles */
        .lm-help-overlay {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(0, 0, 0, 0.5);
          display: flex;
          align-items: center;
          justify-content: center;
          z-index: 1000;
          padding: 20px;
        }

        .lm-help-panel {
          background: #fff;
          border: 1px solid #d1d5da;
          border-radius: 12px;
          max-width: 600px;
          width: 100%;
          max-height: 80vh;
          overflow: hidden;
          box-shadow: 0 16px 40px rgba(0, 0, 0, 0.15);
        }

        .lm-help-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 16px 20px;
          background: linear-gradient(135deg, #5db8f0, #2578b8);
          color: #fff;
        }

        .lm-help-header h3 {
          margin: 0;
          font-size: 16px;
          font-weight: 700;
        }

        .lm-close-help {
          width: 28px;
          height: 28px;
          border: none;
          background: rgba(255, 255, 255, 0.2);
          color: #fff;
          font-size: 16px;
          cursor: pointer;
          border-radius: 6px;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .lm-close-help:hover {
          background: rgba(255, 255, 255, 0.3);
        }

        .lm-help-body {
          padding: 20px;
          overflow-y: auto;
          max-height: 60vh;
        }

        .lm-help-section {
          margin-bottom: 16px;
          padding-bottom: 16px;
          border-bottom: 1px solid #e1e4e8;
          line-height: 1.7;
          font-size: 13px;
          color: #24292e;
        }

        .lm-help-section:last-child {
          margin-bottom: 0;
          padding-bottom: 0;
          border-bottom: none;
        }

        .lm-help-footer {
          padding: 14px 20px;
          background: #fafbfc;
          border-top: 1px solid #e1e4e8;
          text-align: center;
        }

        .lm-header-actions {
          display: flex;
          align-items: center;
          gap: 8px;
        }

        .lm-title {
          font-size: 18px;
          font-weight: 600;
          color: #1a1a1a;
          letter-spacing: 0.5px;
        }

        .lm-tabs {
          display: flex;
          gap: 4px;
          background: #e1e4e8;
          padding: 4px;
          border-radius: 8px;
        }

        .lm-tab {
          padding: 8px 16px;
          border: none;
          background: transparent;
          color: #586069;
          font-size: 13px;
          font-weight: 500;
          cursor: pointer;
          border-radius: 6px;
          transition: all 0.2s;
        }

        .lm-tab:hover {
          color: #24292e;
        }

        .lm-tab.active {
          background: #fff;
          color: #24292e;
          box-shadow: 0 1px 2px rgba(0,0,0,0.1);
        }

        .lm-main {
          display: grid;
          gap: 0;
          align-items: start;
          height: calc(100vh - 132px);
          overflow: hidden;
        }

        .lm-main.vertical {
          grid-template-columns: minmax(250px, 1fr) 12px minmax(250px, 1fr);
          grid-template-areas: "list center-resizer editor";
        }

        .lm-main.horizontal {
          grid-template-columns: 1fr;
          grid-template-rows: 1fr 12px var(--split-percent, 40%);
          grid-template-areas: "list" "bottom-resizer" "editor";
        }

        .lm-resizer {
          background: transparent;
          position: relative;
          z-index: 10;
          display: flex;
          align-items: center;
          justify-content: center;
          transition: background 0.15s;
        }

        .lm-resizer:hover,
        .lm-resizer.resizing {
          background: rgba(9, 105, 218, 0.1);
        }

        .lm-resizer::after {
          content: '';
          background: #d1d5da;
          border-radius: 2px;
          transition: background 0.15s;
        }

        .lm-resizer:hover::after,
        .lm-resizer.resizing::after {
          background: #0969da;
        }

        /* Vertical layout resizers */
        .lm-main.vertical .lm-resizer {
          cursor: col-resize;
          width: 12px;
          height: 100%;
          grid-area: center-resizer;
        }

        .lm-main.vertical .lm-resizer::after {
          width: 4px;
          height: 40px;
        }

        /* Horizontal layout resizer */
        .lm-main.horizontal .lm-resizer {
          cursor: row-resize;
          height: 12px;
          width: 100%;
          grid-area: bottom-resizer;
        }

        .lm-main.horizontal .lm-resizer::after {
          height: 4px;
          width: 40px;
        }

        .lm-list-panel { grid-area: list; min-width: 0; }
        .lm-editor-panel { grid-area: editor; min-width: 0; }

        .lm-list-panel {
          background: rgba(255, 255, 255, 0.85);
          border: 1px solid rgba(225, 228, 232, 0.6);
          border-radius: 12px;
          overflow: hidden;
          backdrop-filter: blur(12px);
          display: flex;
          flex-direction: column;
          height: 100%;
          min-height: 0;
        }

        .lm-main.horizontal .lm-list-panel {
          border-radius: 0 0 12px 12px;
          border-top: none;
        }

        .lm-list-scroll {
          flex: 1;
          overflow-y: auto;
          overflow-x: hidden;
          padding: 8px;
        }

        .lm-list-scroll::-webkit-scrollbar {
          width: 6px;
        }

        .lm-list-scroll::-webkit-scrollbar-track {
          background: transparent;
        }

        .lm-list-scroll::-webkit-scrollbar-thumb {
          background: rgba(149, 157, 165, 0.5);
          border-radius: 3px;
        }

        .lm-list-scroll::-webkit-scrollbar-thumb:hover {
          background: rgba(149, 157, 165, 0.8);
        }

        .lm-toolbar {
          display: flex;
          gap: 8px;
          padding: 12px 16px;
          border-bottom: 1px solid #e1e4e8;
          background: #fafbfc;
        }

        .lm-search-bar {
          display: flex;
          gap: 12px;
          padding: 12px 16px;
          border-bottom: 1px solid #e1e4e8;
          background: #fafbfc;
          align-items: center;
          flex-wrap: wrap;
        }

        .lm-search-input-group {
          display: flex;
          flex: 1;
          min-width: 200px;
        }

        .lm-search-input-group .lm-input {
          border-radius: 6px 0 0 6px;
          flex: 1;
        }

        .lm-search-input-group .lm-btn {
          border-radius: 0 6px 6px 0;
          margin-left: -1px;
          padding: 0 12px;
        }

        .lm-select {
          padding: 8px 12px;
          border: 1px solid #d1d5da;
          border-radius: 6px;
          font-size: 13px;
          background: #fff;
          color: #24292e;
          outline: none;
          height: 36px;
          cursor: pointer;
        }

        .lm-btn {
          padding: 8px 14px;
          border: 1px solid #d1d5da;
          background: #fff;
          color: #24292e;
          font-size: 13px;
          font-weight: 500;
          border-radius: 6px;
          cursor: pointer;
          display: inline-flex;
          align-items: center;
          gap: 6px;
          transition: all 0.15s;
        }

        .lm-btn:hover {
          background: #f6f8fa;
          border-color: #c6cbd1;
        }

        .lm-btn-primary {
          background: #2ea44f;
          color: #fff;
          border-color: #2ea44f;
        }

        .lm-btn-primary:hover {
          background: #2c974b;
          border-color: #2c974b;
        }

        .lm-btn-secondary {
          background: #f6f8fa;
        }

        .lm-btn-folder {
          background: #0969da;
          border-color: #0969da;
          color: #fff;
        }

        .lm-btn-folder:hover {
          background: #0550ae;
          border-color: #0550ae;
          color: #fff;
        }

        .lm-btn-folder svg {
          stroke: #fff;
        }

        .lm-list {
          display: flex;
          flex-direction: column;
          gap: 4px;
        }

        .lm-empty {
          padding: 40px;
          text-align: center;
          color: #6a737d;
        }

        .lm-entry {
          border: 1px solid #e8eaed;
          border-radius: 8px;
          background: #f6f7f8;
          transition: all 0.15s;
        }

        .lm-entry:hover {
          border-color: #c4c9d0;
          background: #ebedef;
        }

        .lm-entry.lm-selected {
          border-color: #0969da;
          background: #f1f8ff;
        }

        .lm-entry.lm-selected .lm-entry-name {
          font-weight: 700;
          color: #0969da;
        }

        .lm-entry.lm-selected .lm-entry-header {
          background: transparent;
        }

        .lm-entry.dragging,
        .lm-entry.lm-multi-dragging {
          opacity: 0.5;
        }

        .lm-entry.lm-multi-drag-source {
          border: 2px dashed #0969da;
          background: #f1f8ff;
        }

        .lm-entry.lm-multi-selected.lm-multi-drag-source {
          border-color: #0969da;
          background: #e6f2ff;
        }

        .lm-entry.lm-folder-drop-target {
          background: #cf222e !important;
          border-color: #cf222e !important;
        }
        .lm-dark-theme .lm-entry.lm-folder-drop-target {
          background: #da3633 !important;
          border-color: #da3633 !important;
        }

        .lm-drop-before {
          box-shadow: inset 0 2px 0 0 #0969da !important;
        }
        .lm-drop-after {
          box-shadow: inset 0 -2px 0 0 #0969da !important;
        }
        .lm-dark-theme .lm-drop-before {
          box-shadow: inset 0 2px 0 0 #4299e1 !important;
        }
        .lm-dark-theme .lm-drop-after {
          box-shadow: inset 0 -2px 0 0 #4299e1 !important;
        }

        .lm-entry-header {
          display: flex;
          align-items: center;
          gap: 8px;
          padding: 10px 12px;
          user-select: none;
        }

        .lm-entry:not(.lm-folder):hover .lm-entry-header {
          background: rgba(246, 248, 250, 0.8);
        }

        .lm-entry.lm-folder:hover .lm-entry-header {
          background: transparent;
        }

        .lm-entry {
          cursor: pointer;
        }

        .lm-drag-handle,
        .lm-expand-btn,
        .lm-icon-btn {
          cursor: default;
        }

        .lm-drag-handle {
          color: #959da5;
          cursor: grab;
          padding: 2px;
          opacity: 0;
          transition: opacity 0.15s;
        }

        .lm-entry:hover .lm-drag-handle {
          opacity: 1;
        }

        .lm-drag-handle:active {
          cursor: grabbing;
        }

        .lm-expand-btn, .lm-expand-placeholder {
          width: 24px;
          height: 24px;
          display: flex;
          align-items: center;
          justify-content: center;
          color: #586069;
        }

        .lm-expand-btn {
          background: none;
          border: none;
          cursor: pointer;
          border-radius: 4px;
        }

        .lm-expand-btn:hover {
          background: #f0f1f2;
        }

        .lm-entry-title {
          flex: 1;
          display: flex;
          flex-direction: column;
          min-width: 0;
        }

        .lm-entry-title-row {
          display: flex;
          align-items: center;
          gap: 8px;
          min-width: 0;
        }

        .lm-folder-icon {
          width: 18px;
          height: 18px;
          color: #6a737d;
          display: inline-flex;
          align-items: center;
          justify-content: center;
        }

        .lm-folder-icon svg {
          width: 18px;
          height: 18px;
          fill: currentColor;
          display: block;
        }

        .lm-entry.lm-selected .lm-folder-icon {
          color: #0969da;
        }

        .lm-entry.lm-folder {
          background: #0969da;
          border-color: rgba(9, 105, 218, 0.6);
        }

        .lm-entry.lm-folder:hover {
          background: #063a8a;
          border-color: rgba(6, 58, 138, 0.9);
        }

        .lm-entry.lm-folder .lm-entry-name,
        .lm-entry.lm-folder .lm-folder-icon {
          color: #fff;
        }

        .lm-entry.lm-folder .lm-entry-key {
          color: rgba(255, 255, 255, 0.85);
        }

        .lm-entry.lm-folder .lm-entry-badges .lm-badge.folder {
          background: rgba(255, 255, 255, 0.2);
          color: #fff;
        }

        .lm-entry.lm-folder .lm-expand-btn,
        .lm-entry.lm-folder .lm-expand-placeholder {
          color: #fff;
        }

        /* Folder selected state - override colors to show selection */
        .lm-entry.lm-folder.lm-selected {
          background: #e6f2ff;
          border-color: #0969da;
        }

        .lm-entry.lm-folder.lm-selected .lm-entry-name {
          color: #0969da;
          font-weight: 700;
        }

        .lm-entry.lm-folder.lm-selected .lm-folder-icon {
          color: #0969da;
        }

        .lm-entry.lm-folder.lm-selected .lm-entry-key {
          color: #6a737d;
        }

        .lm-entry.lm-folder.lm-selected .lm-expand-btn,
        .lm-entry.lm-folder.lm-selected .lm-expand-placeholder {
          color: #0969da;
        }

        .lm-entry.lm-folder.lm-selected .lm-entry-badges .lm-badge.folder {
          background: rgba(9, 105, 218, 0.15);
          color: #0969da;
        }

        .lm-entry-name {
          font-weight: 500;
          color: #24292e;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }

        .lm-entry-name.lm-disabled {
          text-decoration: line-through;
          color: #cf222e;
        }

        .lm-disabled-entry .lm-entry-name,
        .lm-disabled-entry .lm-entry-key {
          color: #cf222e;
        }

        .lm-entry-key {
          font-size: 12px;
          color: #6a737d;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }

        .lm-folder-preview {
          font-style: italic;
        }

        .lm-entry-badges {
          display: flex;
          gap: 6px;
          flex-shrink: 0;
        }

        .lm-badge {
          padding: 3px 8px;
          font-size: 11px;
          font-weight: 500;
          border-radius: 12px;
          text-transform: uppercase;
          letter-spacing: 0.3px;
        }

        .lm-badge.always {
          background: #ddf4ff;
          color: #0969da;
        }

        .lm-badge.keyword {
          background: #fff8c5;
          color: #7d4e00;
        }

        .lm-badge.off {
          background: #ffebe9;
          color: #cf222e;
        }

        .lm-badge.folder {
          background: #f1f8ff;
          color: #0969da;
        }

        .lm-icon-btn {
          width: 28px;
          height: 28px;
          border: none;
          background: transparent;
          color: #959da5;
          cursor: pointer;
          border-radius: 6px;
          display: flex;
          align-items: center;
          justify-content: center;
          transition: all 0.15s;
        }

        .lm-icon-btn:hover {
          background: #f0f1f2;
          color: #24292e;
        }

        .lm-icon-btn.lm-delete:hover {
          background: #ffebe9;
          color: #cf222e;
        }

        .lm-child {
          margin-left: 32px;
          border-left: 2px solid #e1e4e8;
        }

        .lm-folder-children {
          display: flex;
          flex-direction: column;
          gap: 2px;
          margin-top: 2px;
          margin-bottom: 2px;
        }

        .lm-folder-preview {
          white-space: nowrap;
        }

        .lm-editor-panel {
          height: 100%;
          min-height: 0;
          display: flex;
          flex-direction: column;
        }

        .lm-main.horizontal .lm-editor-panel,
        .lm-main.horizontal .lm-list-panel {
          width: 100%;
          max-width: 100%;
        }

        .lm-main.horizontal .lm-editor-panel {
          padding: 0;
        }

        .lm-main.vertical .lm-editor-panel {
          padding: 0 0 0 16px;
        }

        .lm-editor {
          background: rgba(255, 255, 255, 0.9);
          border: 1px solid rgba(225, 228, 232, 0.6);
          border-radius: 12px;
          overflow: hidden;
          backdrop-filter: blur(12px);
          display: flex;
          flex-direction: column;
          height: 100%;
        }

        .lm-main.horizontal .lm-editor {
          border-radius: 12px 12px 0 0;
          border-bottom: none;
        }

        .lm-editor-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 14px 16px;
          border-bottom: 1px solid #e1e4e8;
          background: #fafbfc;
          flex-shrink: 0;
        }

        .lm-editor-header h3 {
          margin: 0;
          font-size: 14px;
          font-weight: 600;
          color: #24292e;
        }

        .lm-close-editor {
          width: 28px;
          height: 28px;
          border: none;
          background: transparent;
          color: #586069;
          font-size: 16px;
          cursor: pointer;
          border-radius: 6px;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .lm-close-editor:hover {
          background: #f0f1f2;
          color: #24292e;
        }

        /* Editor Layout */
        .lm-editor-body {
          display: flex;
          flex-direction: column;
          gap: 16px;
          padding: 16px;
          flex: 1;
          min-height: 0;
          overflow-y: auto;
        }

        .lm-editor-top {
          display: flex;
          flex-direction: column;
          gap: 12px;
          flex-shrink: 0;
        }

        .lm-editor-row {
          display: grid;
          grid-template-columns: 1fr 120px;
          gap: 12px;
        }

        .lm-editor-row-keys {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 12px;
        }

        .lm-editor-bottom {
          display: flex;
          gap: 20px;
          flex: 1;
          min-height: 0;
        }

        .lm-editor-right {
          display: flex;
          flex-direction: column;
          width: 140px;
          flex-shrink: 0;
          padding-top: 22px;
        }

        .lm-checkbox-stack {
          display: flex;
          flex-direction: column;
          gap: 12px;
        }

        .lm-check-item {
          display: flex;
          align-items: center;
          gap: 8px;
          font-size: 13px;
          cursor: pointer;
          white-space: nowrap;
        }

        .lm-check-item input[type="checkbox"] {
          width: 16px;
          height: 16px;
          cursor: pointer;
          margin: 0;
        }

        .lm-check-item span {
          color: #24292e;
        }

        .lm-field {
          display: flex;
          flex-direction: column;
          gap: 4px;
        }

        .lm-field label {
          font-size: 12px;
          font-weight: 500;
          color: #24292e;
        }

        .lm-hint {
          font-weight: 400;
          color: #6a737d;
          font-size: 11px;
        }

        .lm-key-label {
          display: flex;
          align-items: center;
          gap: 8px;
        }

        .lm-key-buttons {
          display: inline-flex;
          gap: 4px;
          margin-left: auto;
        }

        .lm-key-btn {
          width: 28px;
          height: 28px;
          padding: 0;
          border: 1px solid #d1d5da;
          border-radius: 4px;
          background: #f6f8fa;
          cursor: pointer;
          display: flex;
          align-items: center;
          justify-content: center;
          transition: all 0.15s;
          flex-shrink: 0;
        }

        .lm-key-btn svg {
          flex-shrink: 0;
          display: block;
        }

        .lm-key-btn:hover {
          background: #0969da;
          border-color: #0969da;
        }

        .lm-key-btn:hover svg path {
          fill: #fff;
        }

        .lm-key-btn-add {
          background: #ddf4ff;
          border-color: #54aeff;
        }

        .lm-key-btn-add svg path {
          fill: #0969da;
        }

        .lm-key-btn-add:hover {
          background: #54aeff;
          border-color: #54aeff;
        }

        .lm-key-btn-remove {
          background: #ffebe9;
          border-color: #ff8182;
        }

        .lm-key-btn-remove svg path {
          fill: #cf222e;
        }

        .lm-key-btn-remove:hover {
          background: #ff8182;
          border-color: #ff8182;
        }

        .lm-input, .lm-textarea {
          padding: 8px 12px;
          border: 1px solid #d1d5da;
          border-radius: 6px;
          font-size: 14px;
          font-family: inherit;
          color: #24292e;
          background: #fff;
          transition: border-color 0.15s;
          width: 100%;
        }

        .lm-input:focus, .lm-textarea:focus {
          outline: none;
          border-color: #0969da;
          box-shadow: 0 0 0 3px rgba(9, 105, 218, 0.1);
        }

        .lm-input {
          height: 36px;
        }

        /* Multi-selection styles */
        .lm-entry-checkbox {
          display: flex;
          align-items: center;
          justify-content: center;
          width: 28px;
          height: 24px;
          flex-shrink: 0;
          opacity: 0;
          transition: opacity 0.15s;
        }

        .lm-entry:hover .lm-entry-checkbox,
        .lm-entry.lm-selected .lm-entry-checkbox,
        .lm-entry.lm-multi-selected .lm-entry-checkbox {
          opacity: 1;
        }

        .lm-select-checkbox {
          width: 16px;
          height: 16px;
          cursor: pointer;
          margin: 0;
          accent-color: #0969da;
        }

        .lm-entry.lm-selected {
          border-color: #0969da;
          background: #f1f8ff;
        }

        .lm-entry.lm-multi-selected {
          border-color: #0969da;
          background: #e6f2ff;
        }

        .lm-entry.lm-multi-selected .lm-entry-name {
          font-weight: 600;
          color: #0969da;
        }

        .lm-multi-select-notice {
          display: flex;
          align-items: center;
          gap: 8px;
          padding: 10px 16px;
          background: #fff8c5;
          border-bottom: 1px solid #e1e4e8;
          color: #7d4e00;
          font-size: 13px;
        }

        .lm-editor-multi .lm-field-disabled {
          opacity: 0.5;
          background: #f0f1f2;
          border-radius: 6px;
        }

        .lm-editor-multi .lm-field-disabled .lm-input,
        .lm-editor-multi .lm-field-disabled .lm-textarea {
          background: #e1e4e8;
          cursor: not-allowed;
        }

        .lm-batch-indicator {
          font-size: 11px;
          color: #0969da;
          font-weight: 500;
          margin-left: auto;
        }

        .lm-selection-hint {
          font-size: 12px;
          color: #6a737d;
          margin-left: auto;
          white-space: nowrap;
        }

        @media (max-width: 900px) {
          .lm-selection-hint {
            display: none;
          }
        }

        /* Auto-growing textarea for keys */
        .lm-autogrow {
          min-height: 36px;
          height: auto;
          resize: none;
          overflow: hidden;
          field-sizing: content; /* Modern browsers */
          line-height: 1.4;
        }

        .lm-autogrow::-webkit-scrollbar {
          width: 0;
          height: 0;
        }

        /* Content textarea - full width, resizable */
        .lm-content-field {
          flex: 1;
          display: flex;
          flex-direction: column;
          min-height: 0;
        }

        .lm-content-textarea {
          flex: 1;
          min-height: 120px;
          resize: vertical;
          max-width: 100%;
          overflow: auto;
        }

        .lm-number {
          width: 100%;
        }

        /* Horizontal layout adjustments */
        .lm-main.horizontal .lm-editor-row {
          grid-template-columns: 1fr 100px;
        }

        /* Mobile adjustments */
        @media (max-width: 900px) {
          .lm-editor-body {
            flex-direction: column;
          }

          .lm-editor-bottom {
            flex-direction: column;
          }

          .lm-editor-right {
            width: 100%;
            padding-top: 0;
          }

          .lm-checkbox-stack {
            flex-direction: row;
            flex-wrap: wrap;
            gap: 16px;
          }
        }

        .lm-editor-footer {
          display: flex;
          gap: 10px;
          padding: 12px 16px;
          border-top: 1px solid #e1e4e8;
          background: #fafbfc;
        }

        .lm-editor-footer .lm-btn {
          flex: 1;
        }

        .lm-no-selection {
          background: rgba(255, 255, 255, 0.85);
          border: 1px solid rgba(225, 228, 232, 0.6);
          border-radius: 12px;
          padding: 40px;
          text-align: center;
          color: #6a737d;
          backdrop-filter: blur(12px);
        }

        @media (max-width: 900px) {
          .lm-main {
            grid-template-columns: 1fr !important;
            grid-template-rows: 1fr !important;
            grid-template-areas: "list" "editor" !important;
            height: auto;
          }

          .lm-main.vertical,
          .lm-main.horizontal {
            grid-template-columns: 1fr !important;
            grid-template-rows: auto 1fr !important;
          }

          .lm-resizer {
            display: none;
          }

          .lm-list-panel {
            max-height: 50vh;
          }

          .lm-editor {
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            z-index: 100;
            border-radius: 0;
            height: 100vh;
          }

          .lm-main.horizontal .lm-editor-panel,
          .lm-main.vertical .lm-editor-panel {
            padding: 0;
          }

          .lm-main.horizontal .lm-editor-body,
          .lm-main.vertical .lm-editor-body {
            display: flex;
            flex-direction: column;
          }
        }

        .lm-layout-toggle {
          padding: 6px 10px;
          border: 1px solid #d1d5da;
          background: #fff;
          color: #586069;
          font-size: 12px;
          font-weight: 500;
          border-radius: 6px;
          cursor: pointer;
          display: flex;
          align-items: center;
          gap: 6px;
          transition: all 0.15s;
        }

        .lm-layout-toggle:hover {
          background: #f6f8fa;
          border-color: #c6cbd1;
          color: #24292e;
        }

        /* Dark Theme Overrides */
        .lm-dark-theme {
          background: rgba(26, 27, 38, 0.85);
          color: #e1e4e8;
        }
        .lm-dark-theme .lm-header { border-bottom-color: rgba(80, 85, 100, 0.6); }
        .lm-dark-theme .lm-target-character { color: #e1e4e8; }
        .lm-dark-theme .lm-target-chat { color: #959da5; }
        .lm-dark-theme .lm-title { color: #e1e4e8; }
        .lm-app-icon { color: #1a1a1a; }
        .lm-dark-theme .lm-app-icon { color: #e1e4e8; }
        .lm-dark-theme .lm-close-btn, .lm-dark-theme .lm-layout-toggle {
          background: #2d3243; border-color: #505564; color: #e1e4e8;
        }
        .lm-dark-theme .lm-layout-toggle:hover {
          background: #394056; border-color: #6a737d; color: #fff;
        }
        .lm-dark-theme .lm-close-btn:hover {
          background: #3a1f24;
          color: #ff7b72;
          border-color: #da3633;
        }
        .lm-dark-theme .lm-tabs { background: #1e212b; }
        .lm-dark-theme .lm-tab { color: #959da5; }
        .lm-dark-theme .lm-tab:hover { color: #e1e4e8; }
        .lm-dark-theme .lm-tab.active { background: #2d3243; color: #e1e4e8; box-shadow: 0 1px 2px rgba(0,0,0,0.3); }
        .lm-dark-theme .lm-list-panel, .lm-dark-theme .lm-editor, .lm-dark-theme .lm-no-selection {
          background: rgba(40, 44, 56, 0.9); border-color: rgba(80, 85, 100, 0.6); color: #959da5;
        }
        .lm-dark-theme .lm-toolbar, .lm-dark-theme .lm-search-bar, .lm-dark-theme .lm-editor-header, .lm-dark-theme .lm-editor-footer {
          background: #282c38; border-color: #505564;
        }
        .lm-dark-theme .lm-select { background: #1e212b; border-color: #505564; color: #e1e4e8; }
        .lm-dark-theme .lm-btn { background: #2d3243; border-color: #505564; color: #e1e4e8; }
        .lm-dark-theme .lm-btn:hover { background: #394056; border-color: #6a737d; }
        .lm-dark-theme .lm-btn-primary { background: #238636; border-color: #238636; color: #fff; }
        .lm-dark-theme .lm-btn-primary:hover { background: #2ea043; border-color: #2ea043; }
        .lm-dark-theme .lm-btn-secondary { background: #2d3243; }
        .lm-dark-theme .lm-btn-folder { background: #24416b; border-color: #4299e1; color: #fff; }
        .lm-dark-theme .lm-btn-folder:hover { background: #1c3354; border-color: #4299e1; color: #fff; }
        .lm-dark-theme .lm-btn-folder svg { stroke: #fff; }
        .lm-dark-theme .lm-key-btn { background: #1e212b; border-color: #505564; }
        .lm-dark-theme .lm-key-btn:hover { background: #4299e1; border-color: #4299e1; }
        .lm-dark-theme .lm-key-btn:hover svg path { fill: #fff; }
        .lm-dark-theme .lm-key-btn-add { background: #1c3a5f; border-color: #4299e1; }
        .lm-dark-theme .lm-key-btn-add svg path { fill: #4299e1; }
        .lm-dark-theme .lm-key-btn-add:hover { background: #4299e1; border-color: #4299e1; }
        .lm-dark-theme .lm-key-btn-remove { background: #3d1f1f; border-color: #ff7b72; }
        .lm-dark-theme .lm-key-btn-remove svg path { fill: #ff7b72; }
        .lm-dark-theme .lm-key-btn-remove:hover { background: #ff7b72; border-color: #ff7b72; }
        .lm-dark-theme .lm-entry { background: #2d3243; border-color: #4a5160; }
        .lm-dark-theme .lm-entry:not(.lm-folder):hover { border-color: #505564; background: #394056; }
        .lm-dark-theme .lm-entry:not(.lm-folder):hover .lm-entry-header { background: rgba(57, 64, 86, 0.8); }
        .lm-dark-theme .lm-entry.lm-selected { border-color: #4299e1; background: #1e3a5f; }
        .lm-dark-theme .lm-entry.lm-selected .lm-entry-name { color: #4299e1; }
        .lm-dark-theme .lm-entry.lm-folder { background: #24416b; border-color: rgba(66, 153, 225, 0.4); }
        .lm-dark-theme .lm-entry.lm-folder:hover { background: #1c3354; border-color: rgba(66, 153, 225, 0.6); }
        .lm-dark-theme .lm-entry.lm-folder .lm-entry-key { color: rgba(225, 228, 232, 0.85); }

        /* Dark theme folder selected state */
        .lm-dark-theme .lm-entry.lm-folder.lm-selected {
          background: #1e3a5f;
          border-color: #4299e1;
        }

        .lm-dark-theme .lm-entry.lm-folder.lm-selected .lm-entry-name {
          color: #4299e1;
          font-weight: 700;
        }

        .lm-dark-theme .lm-entry.lm-folder.lm-selected .lm-folder-icon {
          color: #4299e1;
        }

        .lm-dark-theme .lm-entry.lm-folder.lm-selected .lm-entry-key {
          color: #959da5;
        }

        .lm-dark-theme .lm-entry.lm-folder.lm-selected .lm-expand-btn,
        .lm-dark-theme .lm-entry.lm-folder.lm-selected .lm-expand-placeholder {
          color: #4299e1;
        }

        .lm-dark-theme .lm-entry.lm-folder.lm-selected .lm-entry-badges .lm-badge.folder {
          background: rgba(66, 153, 225, 0.2);
          color: #4299e1;
        }
        .lm-dark-theme .lm-entry-name { color: #e1e4e8; }
        .lm-dark-theme .lm-entry-key { color: #959da5; }
        .lm-dark-theme .lm-folder-icon { color: #959da5; }
        .lm-dark-theme .lm-entry.lm-selected .lm-folder-icon { color: #4299e1; }
        .lm-dark-theme .lm-drag-handle { color: #6a737d; }
        .lm-dark-theme .lm-expand-btn, .lm-dark-theme .lm-expand-placeholder { color: #959da5; }
        .lm-dark-theme .lm-expand-btn:hover { background: #394056; }
        .lm-dark-theme .lm-icon-btn { color: #6a737d; }
        .lm-dark-theme .lm-icon-btn:hover { background: #394056; color: #e1e4e8; }
        .lm-dark-theme .lm-icon-btn.lm-delete:hover { background: rgba(255, 123, 114, 0.1); color: #ff7b72; }
        .lm-dark-theme .lm-child { border-left-color: #505564; }
        .lm-dark-theme .lm-badge.always { background: rgba(66, 153, 225, 0.2); color: #4299e1; }
        .lm-dark-theme .lm-badge.keyword { background: rgba(210, 153, 34, 0.2); color: #e3b341; }
        .lm-dark-theme .lm-badge.off { background: rgba(255, 123, 114, 0.1); color: #ff7b72; }
        .lm-dark-theme .lm-badge.folder { background: rgba(66, 153, 225, 0.15); color: #4299e1; }
        .lm-dark-theme .lm-entry.lm-folder .lm-entry-badges .lm-badge.folder { background: rgba(255, 255, 255, 0.15); color: #fff; }
        .lm-dark-theme .lm-editor-header h3 { color: #e1e4e8; }
        .lm-dark-theme .lm-close-editor { color: #959da5; }
        .lm-dark-theme .lm-close-editor:hover { background: #394056; color: #e1e4e8; }
        .lm-dark-theme .lm-field label { color: #e1e4e8; }
        .lm-dark-theme .lm-hint { color: #959da5; }
        .lm-dark-theme .lm-input, .lm-dark-theme .lm-textarea { background: #1e212b; border-color: #505564; color: #e1e4e8; }
        .lm-dark-theme .lm-input:focus, .lm-dark-theme .lm-textarea:focus { border-color: #4299e1; box-shadow: 0 0 0 3px rgba(66, 153, 225, 0.2); }
        .lm-dark-theme .lm-check-item span { color: #e1e4e8; }
        .lm-dark-theme .lm-resizer::after { background: #505564; }
        .lm-dark-theme .lm-resizer:hover::after, .lm-dark-theme .lm-resizer.resizing::after { background: #4299e1; }
        .lm-dark-theme .lm-resizer:hover, .lm-dark-theme .lm-resizer.resizing { background: rgba(66, 153, 225, 0.1); }
        .lm-dark-theme .lm-entry-name.lm-disabled { color: #ff7b72; }
        .lm-dark-theme .lm-disabled-entry .lm-entry-name, .lm-dark-theme .lm-disabled-entry .lm-entry-key { color: #ff7b72; }

        /* Dark theme multi-selection */
        .lm-dark-theme .lm-select-checkbox { accent-color: #4299e1; }
        .lm-dark-theme .lm-entry.lm-multi-selected {
          border-color: #4299e1;
          background: #1e3a5f;
        }
        .lm-dark-theme .lm-entry.lm-multi-selected .lm-entry-name {
          color: #4299e1;
        }
        .lm-dark-theme .lm-entry.lm-multi-drag-source {
          border: 2px dashed #4299e1;
          background: #1e3a5f;
        }
        .lm-dark-theme .lm-multi-select-notice {
          background: rgba(210, 153, 34, 0.2);
          border-bottom-color: #505564;
          color: #e3b341;
        }
        .lm-dark-theme .lm-editor-multi .lm-field-disabled {
          opacity: 0.4;
          background: #1e212b;
        }
        .lm-dark-theme .lm-editor-multi .lm-field-disabled .lm-input,
        .lm-dark-theme .lm-editor-multi .lm-field-disabled .lm-textarea {
          background: #282c38;
          color: #6a737d;
        }
        .lm-dark-theme .lm-batch-indicator {
          color: #4299e1;
        }
        .lm-dark-theme .lm-selection-hint {
          color: #959da5;
        }

        /* Dark theme help panel */
        .lm-dark-theme .lm-help-btn {
          background: #2d3243;
          border-color: #505564;
          color: #e1e4e8;
        }
        .lm-dark-theme .lm-help-btn:hover {
          background: #394056;
          border-color: #4299e1;
          color: #4299e1;
        }
        .lm-dark-theme .lm-help-panel {
          background: #2d3243;
          border-color: #505564;
        }
        .lm-dark-theme .lm-help-body {
          color: #e1e4e8;
        }
        .lm-dark-theme .lm-help-section {
          border-bottom-color: #505564;
          color: #c8d8e8;
        }
        .lm-dark-theme .lm-help-section b {
          color: #4299e1;
        }
        .lm-dark-theme .lm-help-footer {
          background: #282c38;
          border-top-color: #505564;
        }
      </style>

      <div class="lm-container ${themeMode === 'dark' ? 'lm-dark-theme' : ''}" tabindex="-1">
        <div class="lm-header">
          <div class="lm-header-left">
            <div class="lm-tabs">
              <button class="lm-tab ${currentTab === 'character' ? 'active' : ''}" data-tab="character">${escapeHtml(t('characterTab'))}</button>
              <button class="lm-tab ${currentTab === 'chat' ? 'active' : ''}" data-tab="chat">${escapeHtml(t('chatTab'))}</button>
            </div>
            <div class="lm-control-cluster">
              <button class="lm-layout-toggle" data-action="toggle-theme" title="${escapeHtml(t('toggleThemeTitle'))}">
                <svg width="16" height="16" viewBox="0 0 640 640" fill="currentColor">
                  <path d="M420.9 448C428.2 425.7 442.8 405.5 459.3 388.1C492 353.7 512 307.2 512 256C512 150 426 64 320 64C214 64 128 150 128 256C128 307.2 148 353.7 180.7 388.1C197.2 405.5 211.9 425.7 219.1 448L420.8 448zM416 496L224 496L224 512C224 556.2 259.8 592 304 592L336 592C380.2 592 416 556.2 416 512L416 496zM312 176C272.2 176 240 208.2 240 248C240 261.3 229.3 272 216 272C202.7 272 192 261.3 192 248C192 181.7 245.7 128 312 128C325.3 128 336 138.7 336 152C336 165.3 325.3 176 312 176z"/>
                </svg>
                <span>${themeMode === 'light' ? escapeHtml(t('lightMode')) : escapeHtml(t('darkMode'))}</span>
              </button>
              <button class="lm-layout-toggle" data-action="toggle-layout" title="${escapeHtml(t('toggleLayoutTitle'))}">
                ${layoutMode === 'vertical'
                  ? `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <rect x="3" y="3" width="18" height="18" rx="2" />
                      <line x1="12" y1="3" x2="12" y2="21" />
                     </svg>`
                  : `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <rect x="3" y="3" width="18" height="18" rx="2" />
                      <line x1="3" y1="12" x2="21" y2="12" />
                     </svg>`
                }
                <span>${layoutMode === 'vertical' ? escapeHtml(t('verticalLayout')) : escapeHtml(t('horizontalLayout'))}</span>
              </button>
              <button class="lm-layout-toggle" data-action="toggle-language" title="${escapeHtml(t('toggleLanguageTitle'))}">
                <span>${escapeHtml(t('languageToggle'))}</span>
              </button>
            </div>
            <div class="lm-target-info">
              <div class="lm-target-character">${escapeHtml(targetInfo.characterName)}</div>
              <div class="lm-target-chat">${escapeHtml(targetInfo.chatTitle)}</div>
            </div>
          </div>
          <div class="lm-header-right">
            <div class="lm-app-icon">${ICON}</div>
            <div class="lm-title">LOREMASTER v${escapeHtml(APP_VERSION)}</div>
            <div class="lm-header-actions">
              <button class="lm-help-btn" data-action="toggle-help" title="${escapeHtml(t('helpButton'))}">
                ${HELP_ICON}
              </button>
              <button class="lm-close-btn" data-action="close" title="${escapeHtml(t('closeTitle'))}">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <line x1="18" y1="6" x2="6" y2="18"></line>
                  <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
              </button>
            </div>
          </div>
        </div>

        <div class="lm-main ${layoutMode}" style="${layoutMode === 'horizontal' ? `--split-percent: ${horizontalSplit}%` : ''}">
          <div class="lm-list-panel">
            <div class="lm-search-bar">
              <div class="lm-search-input-group">
                <input type="text" id="lm-search-input" class="lm-input" placeholder="${escapeHtml(t('searchPlaceholder'))}" value="${escapeHtml(searchQuery)}">
                <button class="lm-btn lm-btn-secondary" id="lm-search-btn" title="${escapeHtml(t('search'))}">
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 640" width="14" height="14" fill="currentColor"><path d="M480 272C480 317.9 465.1 360.3 440 394.7L566.6 521.4C579.1 533.9 579.1 554.2 566.6 566.7C554.1 579.2 533.8 579.2 521.3 566.7L394.7 440C360.3 465.1 317.9 480 272 480C157.1 480 64 386.9 64 272C64 157.1 157.1 64 272 64C386.9 64 480 157.1 480 272zM272 416C351.5 416 416 351.5 416 272C416 192.5 351.5 128 272 128C192.5 128 128 192.5 128 272C128 351.5 192.5 416 272 416z"/></svg>
                </button>
              </div>
              <select id="lm-search-target" class="lm-select">
                <option value="name" ${searchTarget === 'name' ? 'selected' : ''}>${escapeHtml(t('name'))}</option>
                <option value="keys" ${searchTarget === 'keys' ? 'selected' : ''}>${escapeHtml(t('keys'))}</option>
              </select>
              <label class="lm-check-item">
                <input type="checkbox" id="lm-filter-always" ${filterAlways ? 'checked' : ''}>
                <span>${escapeHtml(t('always'))}</span>
              </label>
              <label class="lm-check-item">
                <input type="checkbox" id="lm-filter-disabled" ${filterDisabled ? 'checked' : ''}>
                <span>${escapeHtml(t('disabled'))}</span>
              </label>
            </div>
            <div class="lm-toolbar">
              <button class="lm-btn lm-btn-primary" data-action="add-entry">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <line x1="12" y1="5" x2="12" y2="19"></line>
                  <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
                ${escapeHtml(t('addEntry'))}
              </button>
              <button class="lm-btn lm-btn-folder" data-action="add-folder">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"></path>
                </svg>
                ${escapeHtml(t('addFolder'))}
              </button>
              <button class="lm-btn lm-btn-secondary" data-action="export-lore">
                ${escapeHtml(t('export'))}
              </button>
              <button class="lm-btn lm-btn-secondary" data-action="import-lore">
                ${escapeHtml(t('import'))}
              </button>
            </div>

            <div class="lm-list-scroll">
              <div class="lm-list">
                ${(() => {
                  if (list.length === 0) {
                    return `<div class="lm-empty">${escapeHtml(t('noEntries'))}</div>`;
                  }
                  let html = '';
                  let index = 0;
                  rootEntries.forEach((entry) => {
                    html += renderEntry(entry, false, list, index++);
                    if (entry.mode === 'folder' && expandedEntries.has(entry.id)) {
                      const children = getFolderChildren(list, entry.key);
                      if (children.length > 0) {
                        html += `<div class="lm-folder-children">`;
                        children.forEach((child) => {
                          html += renderEntry(child, true, list, index++);
                        });
                        html += `</div>`;
                      }
                    }
                  });
                  return html;
                })()}
              </div>
            </div>
          </div>

          ${layoutMode === 'vertical' ? `<div class="lm-resizer lm-resizer-center" data-action="resize-center" title="${escapeHtml(t('resizeTitle'))}"></div>` : ''}
          ${layoutMode === 'horizontal' ? `<div class="lm-resizer lm-resizer-bottom" data-action="resize-bottom" title="${escapeHtml(t('resizeTitle'))}"></div>` : ''}

          <div class="lm-editor-panel">
            ${editingEntry
              ? renderEditor(editingEntry)
              : selectedEntryIds.size > 1
                ? renderEditor(fullList.find(e => selectedEntryIds.has(e.id)))
                : `<div class="lm-no-selection">
                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="margin-bottom: 12px; opacity: 0.3;">
                      <path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1 0-5H20"/>
                    </svg>
                    <div>${escapeHtml(t('selectEntry'))}</div>
                  </div>`
            }
          </div>
        </div>
      </div>

      ${renderHelpPanel()}
    `;

    attachEventListeners();

    // Restore scroll position
    if (preserveScroll) {
      const scrollEl = document.querySelector('.lm-list-scroll');
      if (scrollEl) scrollEl.scrollTop = scrollPos;
    }
  }

  // ============================================================================
  // SECTION 11: EVENT HANDLING
  // ============================================================================
  // All user interactions are handled here. The main render() function calls
  // this after generating the HTML to attach event listeners.
  // Handles: clicks, keyboard shortcuts, drag-and-drop, resizing, and form input.
  // ============================================================================

  /**
   * Mobile-safe tap listener. Registers both click and touchend.
   * Prevents double-firing and ignores touches that moved (scrolls).
   */
  function addTapListener(element, handler) {
    if (!element) return;
    let touchHandled = false;
    let touchX = 0;
    let touchY = 0;

    element.addEventListener('touchstart', (e) => {
      touchHandled = false;
      touchX = e.touches[0].clientX;
      touchY = e.touches[0].clientY;
    }, { passive: true });

    element.addEventListener('touchend', (e) => {
      const dx = e.changedTouches[0].clientX - touchX;
      const dy = e.changedTouches[0].clientY - touchY;
      if (Math.abs(dx) < 10 && Math.abs(dy) < 10) {
        touchHandled = true;
        handler(e);
      }
    }, { passive: false });

    element.addEventListener('click', (e) => {
      if (touchHandled) {
        touchHandled = false;
        return;
      }
      handler(e);
    });
  }

  function addTapListenerAll(selector, handler) {
    document.querySelectorAll(selector).forEach(el => addTapListener(el, handler));
  }

  /**
   * Attach all event listeners to the rendered DOM
   * Called after each render() to wire up interactive elements
   */
  function attachEventListeners() {
    if (removeResizeListeners) {
      removeResizeListeners();
    }

    // ESC key handler - add to multiple elements for reliability
    const escHandler = async (e) => {
      if ((e.key === 'Escape' || e.code === 'Escape') && isPluginOpen && !isMinimized) {
        e.preventDefault();
        e.stopPropagation();
        clearSelection();
        await minimizeLoremaster();
        return false;
      }
    };
    document.body.addEventListener('keydown', escHandler, true);
    document.querySelector('.lm-container')?.addEventListener('keydown', escHandler, true);
    document.querySelector('.lm-list-scroll')?.addEventListener('keydown', escHandler, true);

    // Close editor button (clears selection)
    addTapListener(document.querySelector('[data-action="close-editor"]'), async () => {
      await flushDraft(editingEntryId);
      clearSelection();
      editingEntryId = null;
      await render(true);
      await syncChatDockButton();
    });

    // Close button (now acts as minimize)
    addTapListener(document.querySelector('[data-action="close"]'), () => {
      clearSelection();
      minimizeLoremaster();
    });

    // Help button toggle - use querySelectorAll for multiple buttons
    addTapListenerAll('[data-action="toggle-help"]', async (e) => {
      e.preventDefault();
      isHelpOpen = !isHelpOpen;
      await render(true);
    });

    // Help overlay close (click outside panel)
    const helpOverlay = document.querySelector('[data-action="close-help-overlay"]');
    if (helpOverlay) {
      addTapListener(helpOverlay, async (e) => {
        if (e.target === helpOverlay) {
          isHelpOpen = false;
          await render(true);
        }
      });
    }

    // Batch key add/remove buttons (only visible in multi-select mode)
    addTapListenerAll('[data-action="batch-key-add"]', async (e) => {
      e.preventDefault();
      e.stopPropagation();
      const btn = e.target.closest('[data-action="batch-key-add"]');
      const field = btn?.dataset.field;
      if (field) await handleBatchKeyAdd(field);
    });

    addTapListenerAll('[data-action="batch-key-remove"]', async (e) => {
      e.preventDefault();
      e.stopPropagation();
      const btn = e.target.closest('[data-action="batch-key-remove"]');
      const field = btn?.dataset.field;
      if (field) await handleBatchKeyRemove(field);
    });

    // Main window click-outside-to-close (when in fullscreen)
    const container = document.querySelector('.lm-container');
    if (container && isPluginOpen && !isMinimized) {
      addTapListener(container, async (e) => {
        // If clicked directly on container (not on any child element)
        if (e.target === container && !isHelpOpen) {
          clearSelection();
          await minimizeLoremaster();
        }
      });
    }

    // Layout toggle
    addTapListener(document.querySelector('[data-action="toggle-layout"]'), async () => {
      layoutMode = layoutMode === 'vertical' ? 'horizontal' : 'vertical';
      await render();
      await syncChatDockButton();
    });

    // Theme toggle
    addTapListener(document.querySelector('[data-action="toggle-theme"]'), async () => {
      themeMode = themeMode === 'light' ? 'dark' : 'light';
      await render();
      await syncChatDockButton();
    });

    addTapListener(document.querySelector('[data-action="toggle-language"]'), async () => {
      languageMode = languageMode === 'ko' ? 'en' : 'ko';
      await render();
      await syncChatDockButton();
    });

    // Search actions
    const triggerSearch = async () => {
      searchQuery = document.getElementById('lm-search-input')?.value || '';
      searchTarget = document.getElementById('lm-search-target')?.value || 'name';
      filterAlways = document.getElementById('lm-filter-always')?.checked || false;
      filterDisabled = document.getElementById('lm-filter-disabled')?.checked || false;
      await render(true);
      await syncChatDockButton();
      const input = document.getElementById('lm-search-input');
      if (input) {
        input.focus();
        const len = input.value.length;
        input.setSelectionRange(len, len);
      }
    };

    addTapListener(document.getElementById('lm-search-btn'), triggerSearch);
    document.getElementById('lm-search-input')?.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') {
        e.preventDefault();
        triggerSearch();
      }
    });
    document.getElementById('lm-search-target')?.addEventListener('change', triggerSearch);
    document.getElementById('lm-filter-always')?.addEventListener('change', triggerSearch);
    document.getElementById('lm-filter-disabled')?.addEventListener('change', triggerSearch);

    // Tab switching
    addTapListenerAll('[data-tab]', async (e) => {
      const btn = e.target.closest('[data-tab]');
      if (!btn) return;
      await flushDraft(editingEntryId);
      clearSelection();
      currentTab = btn.dataset.tab;
      editingEntryId = null;
      expandedEntries.clear();
      await render();
      await syncChatDockButton();
    });

    // Resizing handlers
    let isResizing = false;
    let resizeType = null; // 'center' | 'bottom'
    let startPos = 0;
    let startSplit = 0;
    let mainRect = null;

    const setupResizer = (selector, type) => {
      const resizer = document.querySelector(selector);
      if (resizer) {
        resizer.addEventListener('mousedown', (e) => {
          isResizing = true;
          resizeType = type;
          startPos = (type === 'bottom') ? e.clientY : e.clientX;
          const main = document.querySelector('.lm-main');
          mainRect = main.getBoundingClientRect();
          startSplit = (type === 'bottom') ? horizontalSplit : verticalSplit;
          resizer.classList.add('resizing');
          document.body.style.cursor = (type === 'bottom') ? 'row-resize' : 'col-resize';
          document.body.style.userSelect = 'none';
        });
      }
    };

    setupResizer('[data-action="resize-center"]', 'center');
    setupResizer('[data-action="resize-bottom"]', 'bottom');

    const onMouseMove = (e) => {
      if (!isResizing) return;
      e.preventDefault();

      const currentPos = (resizeType === 'bottom') ? e.clientY : e.clientX;
      const delta = currentPos - startPos;
      const totalSize = (resizeType === 'bottom') ? mainRect.height : mainRect.width;
      const deltaPercent = (delta / totalSize) * 100;

      let newSplit = startSplit;
      const minSize = 25;
      const maxSize = 75;

      if (layoutMode === 'vertical') {
        // Vertical mode: Dragging right (+delta) -> increase list percentage
        newSplit = Math.max(minSize, Math.min(maxSize, startSplit + deltaPercent));
        verticalSplit = newSplit;
        const listPercent = newSplit;
        const editorPercent = 100 - newSplit;
        const main = document.querySelector('.lm-main');
        main.style.gridTemplateColumns = `minmax(250px, ${listPercent}fr) 12px minmax(250px, ${editorPercent}fr)`;
      } else {
        // Horizontal mode: Dragging down (+delta) -> decrease editor percentage
        newSplit = Math.max(minSize, Math.min(maxSize, startSplit - deltaPercent));
        horizontalSplit = newSplit;
        const main = document.querySelector('.lm-main');
        main.style.setProperty('--split-percent', `${newSplit}%`);
      }
    };

    const onMouseUp = () => {
      if (!isResizing) return;
      isResizing = false;
      resizeType = null;
      document.querySelectorAll('.lm-resizer').forEach(r => r.classList.remove('resizing'));
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
    };

    document.addEventListener('mousemove', onMouseMove);
    document.addEventListener('mouseup', onMouseUp);
    removeResizeListeners = () => {
      document.removeEventListener('mousemove', onMouseMove);
      document.removeEventListener('mouseup', onMouseUp);
      removeResizeListeners = null;
    };

    // Add buttons (clear selection when adding new items)
    addTapListener(document.querySelector('[data-action="add-entry"]'), async () => {
      clearSelection();
      await addEntry();
    });
    addTapListener(document.querySelector('[data-action="add-folder"]'), async () => {
      clearSelection();
      await addFolder();
    });
    addTapListener(document.querySelector('[data-action="export-lore"]'), exportLoreBookCurrent);
    addTapListener(document.querySelector('[data-action="import-lore"]'), importLoreBookCurrent);

    // Multi-selection helper functions
    const toggleSelection = (entryId) => {
      if (selectedEntryIds.has(entryId)) {
        selectedEntryIds.delete(entryId);
      } else {
        selectedEntryIds.add(entryId);
      }
    };

    const selectRange = (startId, endId, list) => {
      const allEntries = [];
      list.forEach((entry) => {
        allEntries.push(entry);
        if (entry.mode === 'folder' && expandedEntries.has(entry.id)) {
          const children = getFolderChildren(list, entry.key);
          children.forEach((child) => allEntries.push(child));
        }
      });

      const startIndex = allEntries.findIndex(e => e.id === startId);
      const endIndex = allEntries.findIndex(e => e.id === endId);

      if (startIndex === -1 || endIndex === -1) return;

      const minIndex = Math.min(startIndex, endIndex);
      const maxIndex = Math.max(startIndex, endIndex);

      for (let i = minIndex; i <= maxIndex; i++) {
        selectedEntryIds.add(allEntries[i].id);
      }
    };

    const clearSelection = () => {
      selectedEntryIds.clear();
      selectionAnchorId = null;
    };

    // Batch update for multi-selected entries
    const batchUpdateEntries = async (field, value) => {
      const list = await getLoreList();
      let changed = false;

      for (const entryId of selectedEntryIds) {
        const entry = list.find(e => e.id === entryId);
        if (entry && entry.mode !== 'folder') {
          if (entry[field] !== value) {
            entry[field] = value;
            if (field === 'disabled') {
              applyDisabledBehavior(entry, value);
            }
            changed = true;
          }
        }
      }

      if (changed) {
        await saveLoreList(list);
        await render(true);
        await syncChatDockButton();
      }
    };

    // Entry actions - using event delegation for better reliability
    const listScrollEl = document.querySelector('.lm-list-scroll');
    if (listScrollEl) {
      listScrollEl.addEventListener('click', async (e) => {
        const expandBtn = e.target.closest('[data-action="expand"]');
        if (expandBtn) {
          e.stopPropagation();
          toggleExpand(expandBtn.dataset.id);
          await render(true);
          await syncChatDockButton();
          return;
        }

        const deleteBtn = e.target.closest('[data-action="delete"]');
        if (deleteBtn) {
          e.stopPropagation();
          if (confirm(t('deleteConfirm'))) {
            await deleteEntry(deleteBtn.dataset.id);
          }
          await syncChatDockButton();
          return;
        }

        const dragHandle = e.target.closest('.lm-drag-handle');
        if (dragHandle) {
          return;
        }

        // Checkbox click for selection
        const checkbox = e.target.closest('.lm-select-checkbox');
        if (checkbox) {
          e.stopPropagation();
          const entryId = checkbox.dataset.id;
          if (e.shiftKey && selectionAnchorId) {
            const list = await getLoreList();
            selectRange(selectionAnchorId, entryId, list);
          } else {
            if (e.ctrlKey || e.metaKey) {
              toggleSelection(entryId);
              selectionAnchorId = entryId;
            } else {
              const wasSelected = selectedEntryIds.has(entryId);
              clearSelection();
              if (!wasSelected || selectedEntryIds.size === 0) {
                selectedEntryIds.add(entryId);
              }
              selectionAnchorId = entryId;
            }
          }
          editingEntryId = entryId;
          await render(true);
          return;
        }

        const entryEl = e.target.closest('.lm-entry');
        if (!entryEl) return;

        const entryId = entryEl.dataset.id;
        if (!entryId) return;

        // Handle Ctrl+click / Shift+click selection
        if (e.ctrlKey || e.metaKey) {
          e.preventDefault();
          e.stopPropagation();
          toggleSelection(entryId);
          selectionAnchorId = entryId;
          editingEntryId = entryId;
          await render(true);
          return;
        }

        if (e.shiftKey && selectionAnchorId) {
          e.preventDefault();
          e.stopPropagation();
          const list = await getLoreList();
          selectRange(selectionAnchorId, entryId, list);
          editingEntryId = entryId;
          await render(true);
          return;
        }

        // Normal click - clear selection and select single
        await flushDraft(editingEntryId);
        clearSelection();
        selectedEntryIds.add(entryId);
        selectionAnchorId = entryId;
        editingEntryId = entryId;
        await render(true);
        await syncChatDockButton();
      });
    }

    // Folder bulk actions
    document.querySelector('[data-action="folder-disable-all"]')?.addEventListener('click', async (e) => {
      const folderKey = e.target.dataset.key;
      await setFolderChildrenDisabled(folderKey, true);
    });
    document.querySelector('[data-action="folder-enable-all"]')?.addEventListener('click', async (e) => {
      const folderKey = e.target.dataset.key;
      await setFolderChildrenDisabled(folderKey, false);
    });

    // Editor actions: draft on input, flush on blur. Checkboxes flush immediately.
    const id = editingEntryId;
    if (id) {
      const onComposeStart = () => { isComposing = true; };
      const onComposeEnd = () => { isComposing = false; };

      const bindDraft = (selector, key, { parse } = {}) => {
        const el = document.querySelector(selector);
        if (!el) return;
        el.addEventListener('compositionstart', onComposeStart);
        el.addEventListener('compositionend', onComposeEnd);
        el.addEventListener('input', () => {
          const v = ('value' in el) ? el.value : '';
          setDraft(id, { [key]: parse ? parse(v) : v });
          // Keep list label responsive without saving
          if (key === 'comment') {
            const row = findEntryElementById(id);
            const nameEl = row?.querySelector('.lm-entry-name');
            if (nameEl) nameEl.textContent = v || t('unnamed');
          }
        });
        el.addEventListener('blur', async () => {
          await flushDraft(id);
        });
        el.addEventListener('keydown', async (e) => {
          if (e.key === 'Enter' && !e.shiftKey && !e.ctrlKey && !e.altKey) {
            if (isComposing) return;
            // For name/order inputs: Enter commits (blur)
            if (selector === '#lm-edit-comment' || selector === '#lm-edit-order') {
              e.preventDefault();
              el.blur();
            }
          }
          if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
            if (isComposing) return;
            // For textareas: Ctrl+Enter commits
            if (selector === '#lm-edit-key' || selector === '#lm-edit-secondkey' || selector === '#lm-edit-content') {
              e.preventDefault();
              el.blur();
            }
          }
        });
      };

      bindDraft('#lm-edit-comment', 'comment');
      bindDraft('#lm-edit-key', 'key');
      bindDraft('#lm-edit-secondkey', 'secondkey');
      bindDraft('#lm-edit-content', 'content');
      bindDraft('#lm-edit-order', 'insertorder', { parse: (v) => parseInt(v) || 100 });

      const bindImmediateCheck = (selector, key) => {
        const el = document.querySelector(selector);
        if (!el) return;
        el.addEventListener('change', async () => {
          const checked = Boolean(el.checked);

          // Multi-selection batch update
          if (selectedEntryIds.size > 1 && el.dataset.action === 'batch-checkbox') {
            await batchUpdateEntries(key, checked);
            return;
          }

          // Save immediately; these are low-risk for focus issues
          await updateEntry(id, { [key]: checked });

          // Update row styling/badges without full re-render where possible
          const row = findEntryElementById(id);
          if (row && key === 'disabled') {
            row.classList.toggle('lm-disabled-entry', checked);
            const nameEl = row.querySelector('.lm-entry-name');
            if (nameEl) nameEl.classList.toggle('lm-disabled', checked);
          }

          // Disabled toggling changes tombstone behavior; refresh editor view
          if (key === 'disabled') {
            await render(true);
            await syncChatDockButton();
          }
        });
      };

      bindImmediateCheck('#lm-edit-disabled', 'disabled');
      bindImmediateCheck('#lm-edit-always', 'alwaysActive');
      bindImmediateCheck('#lm-edit-selective', 'selective');
      bindImmediateCheck('#lm-edit-regex', 'useRegex');
    }

    // Auto-grow textarea behavior for key fields
    document.querySelectorAll('.lm-autogrow').forEach(textarea => {
      const autoGrow = () => {
        textarea.style.height = 'auto';
        textarea.style.height = textarea.scrollHeight + 'px';
      };
      textarea.addEventListener('input', autoGrow);
      // Initial sizing
      setTimeout(autoGrow, 0);
    });

    // Drag and drop - using event delegation
    if (listScrollEl) {
      const clearDropIndicators = () => {
        document.querySelectorAll('.lm-folder-drop-target, .lm-drop-before, .lm-drop-after').forEach(el => {
          el.classList.remove('lm-folder-drop-target', 'lm-drop-before', 'lm-drop-after');
        });
      };

      const getDropIntent = (targetEntry, clientY, sourceId) => {
        if (!targetEntry) return null;
        const targetId = targetEntry.dataset.id;
        if (!targetId || targetId === sourceId) return null;

        const rect = targetEntry.getBoundingClientRect();
        const y = clientY - rect.top;
        const isFolderTarget = targetEntry.classList.contains('lm-folder');
        const sourceEntry = sourceId ? findEntryElementById(sourceId) : null;
        const isFolderSource = sourceEntry?.classList.contains('lm-folder') || false;

        if (isFolderTarget) {
          if (isFolderSource) {
            return { targetId, position: y < rect.height / 2 ? 'before' : 'after' };
          }
          if (y < rect.height * 0.25) return { targetId, position: 'before' };
          if (y > rect.height * 0.75) return { targetId, position: 'after' };
          return { targetId, position: 'inside' };
        }

        return { targetId, position: y < rect.height / 2 ? 'before' : 'after' };
      };

      const applyDropIndicator = (targetEntry, intent) => {
        clearDropIndicators();
        if (!targetEntry || !intent) return;
        if (intent.position === 'inside') targetEntry.classList.add('lm-folder-drop-target');
        else if (intent.position === 'before') targetEntry.classList.add('lm-drop-before');
        else targetEntry.classList.add('lm-drop-after');
      };

      const reorderLoreList = (list, sourceId, targetId, position, multiSourceIds = null) => {
        const sortedList = [...list].sort((a, b) => (a.insertorder || 0) - (b.insertorder || 0));
        sortedList.forEach(entry => {
          if (entry.mode === 'folder') entry.folder = undefined;
        });

        const targetItem = sortedList.find(e => e.id === targetId);
        if (!targetItem) return null;

        // Determine which items to move
        const idsToMove = multiSourceIds && multiSourceIds.length > 0
          ? multiSourceIds.filter(id => id !== targetId)
          : [sourceId].filter(id => id !== targetId);

        if (idsToMove.length === 0) return null;

        const movedItems = idsToMove.map(id => sortedList.find(e => e.id === id)).filter(Boolean);
        if (movedItems.length === 0) return null;

        // Separate folders and non-folders being moved
        const movedFolders = movedItems.filter(e => e.mode === 'folder');
        const movedEntries = movedItems.filter(e => e.mode !== 'folder');

        const rootItems = sortedList.filter(e => !e.folder && !idsToMove.includes(e.id));
        const childrenMap = {};
        sortedList.forEach(e => {
          if (!e.folder || idsToMove.includes(e.id)) return;
          if (!childrenMap[e.folder]) childrenMap[e.folder] = [];
          childrenMap[e.folder].push(e);
        });

        // Handle dropping into a folder (only entries can go into folders, not folders themselves)
        if (position === 'inside' && targetItem.mode === 'folder') {
          // Move non-folder entries into the target folder
          movedEntries.forEach(item => {
            item.folder = targetItem.key;
            if (!childrenMap[targetItem.key]) childrenMap[targetItem.key] = [];
            childrenMap[targetItem.key].push(item);
          });

          // Move folders to root after the target folder
          const targetIndex = rootItems.findIndex(e => e.id === targetItem.id);
          movedFolders.forEach((folder, idx) => {
            folder.folder = undefined;
            const insertIndex = targetIndex !== -1 ? targetIndex + 1 + idx : rootItems.length;
            rootItems.splice(insertIndex, 0, folder);
          });
        } else {
          // Dropping before/after a target
          const isTargetRoot = !targetItem.folder;
          const targetFolderKey = targetItem.folder;

          // Handle folders - they always stay at root level
          movedFolders.forEach(folder => {
            folder.folder = undefined;
          });

          if (isTargetRoot) {
            // Target is a root item (folder or root-level entry)
            const targetIndex = rootItems.findIndex(e => e.id === targetItem.id);

            // Place folders
            if (movedFolders.length > 0) {
              const insertIndex = position === 'before' ? targetIndex : targetIndex + 1;
              rootItems.splice(insertIndex >= 0 ? insertIndex : rootItems.length, 0, ...movedFolders);
            }

            // Place entries in the same root area
            movedEntries.forEach(item => {
              item.folder = undefined;
            });
            const insertIdx = position === 'before' ? targetIndex : targetIndex + 1;
            rootItems.splice(insertIdx >= 0 ? insertIdx : rootItems.length, 0, ...movedEntries);

          } else {
            // Target is inside a folder - move entries to same folder
            movedEntries.forEach(item => {
              item.folder = targetFolderKey;
            });

            // Place folders at root
            const folderInsertIndex = rootItems.findIndex(e => e.id === targetFolderKey);
            if (movedFolders.length > 0) {
              const insertIdx = position === 'before' ? folderInsertIndex : folderInsertIndex + 1;
              rootItems.splice(insertIdx >= 0 ? insertIdx : rootItems.length, 0, ...movedFolders);
            }

            // Add entries to children map
            if (!childrenMap[targetFolderKey]) childrenMap[targetFolderKey] = [];
            const childArray = childrenMap[targetFolderKey];
            const targetChildIndex = childArray.findIndex(e => e.id === targetItem.id);
            const insertIdx = position === 'before' ? targetChildIndex : targetChildIndex + 1;
            childArray.splice(insertIdx >= 0 ? insertIdx : childArray.length, 0, ...movedEntries);
          }
        }

        // Rebuild flat list
        const flatList = [];
        rootItems.forEach(root => {
          flatList.push(root);
          if (root.mode === 'folder' && childrenMap[root.key]) {
            flatList.push(...childrenMap[root.key]);
          }
        });

        // Add any remaining items that weren't in the main structure
        sortedList.forEach(e => {
          if (!flatList.some(item => item.id === e.id)) flatList.push(e);
        });

        // Recalculate insert orders
        flatList.forEach((entry, index) => {
          entry.insertorder = (index + 1) * 10;
        });

        return flatList;
      };

      listScrollEl.addEventListener('dragstart', (e) => {
        const entry = e.target.closest('.lm-entry');
        if (!entry) return;
        const entryId = entry.dataset.id;

        // If dragging an item not in the current selection, clear selection and select just this one
        if (selectedEntryIds.size > 0 && !selectedEntryIds.has(entryId)) {
          clearSelection();
          selectedEntryIds.add(entryId);
          selectionAnchorId = entryId;
          editingEntryId = entryId;
          // Re-render to show selection before dragging
          render(true);
        }

        // If no multi-selection, select the dragged item
        if (selectedEntryIds.size === 0) {
          selectedEntryIds.add(entryId);
          selectionAnchorId = entryId;
          editingEntryId = entryId;
        }

        // Store all selected IDs for the drag operation
        dragSourceId = entryId;
        const selectedIds = Array.from(selectedEntryIds);

        // Add visual indicator to all selected items
        selectedIds.forEach(id => {
          const el = findEntryElementById(id);
          if (el) {
            el.classList.add('lm-multi-drag-source');
          }
        });
        entry.classList.add('dragging');

        e.dataTransfer.effectAllowed = 'move';
        e.dataTransfer.setData('text/plain', entryId);
        e.dataTransfer.setData('application/x-loremaster-entry-id', entryId);
        e.dataTransfer.setData('application/x-loremaster-multi-drag', JSON.stringify(selectedIds));
      });

      listScrollEl.addEventListener('dragend', (e) => {
        const entry = e.target.closest('.lm-entry');
        if (entry) entry.classList.remove('dragging');
        // Remove multi-drag visual indicators
        document.querySelectorAll('.lm-multi-drag-source').forEach(el => {
          el.classList.remove('lm-multi-drag-source');
        });
        dragSourceId = null;
        clearDropIndicators();
      });

      listScrollEl.addEventListener('dragover', (e) => {
        e.preventDefault();
        e.dataTransfer.dropEffect = 'move';

        const targetEntry = e.target.closest('.lm-entry');
        const sourceId = dragSourceId || e.dataTransfer.getData('application/x-loremaster-entry-id') || e.dataTransfer.getData('text/plain');
        applyDropIndicator(targetEntry, getDropIntent(targetEntry, e.clientY, sourceId));
      });

      listScrollEl.addEventListener('drop', async (e) => {
        e.preventDefault();
        const targetEntry = e.target.closest('.lm-entry');

        const sourceId = dragSourceId || e.dataTransfer.getData('application/x-loremaster-entry-id') || e.dataTransfer.getData('text/plain');
        // Get multi-selection data if present
        let multiSourceIds = null;
        try {
          const multiData = e.dataTransfer.getData('application/x-loremaster-multi-drag');
          if (multiData) {
            multiSourceIds = JSON.parse(multiData);
          }
        } catch (e) {
          // Ignore parsing errors
        }

        const intent = getDropIntent(targetEntry, e.clientY, sourceId);
        clearDropIndicators();

        if (!intent || !sourceId) {
          return;
        }

        const list = await getLoreList();
        const nextList = reorderLoreList(list, sourceId, intent.targetId, intent.position, multiSourceIds);
        if (nextList) {
          await saveLoreList(nextList);
          await render(true);
          await syncChatDockButton();
        }
      });
    }
  }

  async function safeUnregisterUiPart(id) {
    try {
      if (typeof Risuai.unregisterUIPart !== 'function') return;
      await Risuai.unregisterUIPart(id);
    } catch (e) {
      console.log(`LOREMASTER unregisterUiPart failed (${id}): ${e?.message || String(e)}`);
    }
  }

  async function syncChatMenuButton() {
    try {
      await Risuai.registerButton({
        name: 'LOREMASTER',
        icon: ICON,
        iconType: 'html',
        location: 'chat'
      }, openLoremaster);
    } catch (e) {
      console.log(`LOREMASTER chat menu register failed: ${e?.message || String(e)}`);
    }
  }

  async function syncChatDockButton() {
    try {
      await Risuai.registerButton({
        name: t('chatDockName'),
        icon: MAXIMIZE_ICON,
        iconType: 'html',
        location: 'action',
        id: FAB_RESTORE_BUTTON_ID
      }, openLoremaster);
    } catch (e) {
      console.log(`LOREMASTER FAB register failed: ${e?.message || String(e)}`);
    }
  }

  async function syncRootDockButton() {
    // Root-document dock was removed. RisuAI's supported action FAB is used instead.
  }

  async function removeRootDockButton() {
    // No-op. Kept to avoid stale calls during hot reloads.
  }

  // ============================================================================
  // SECTION 12: PLUGIN LIFECYCLE
  // ============================================================================
  // Functions for opening, closing, minimizing, and toggling the plugin.
  // These manage the plugin's visibility state and sync UI buttons.
  // ============================================================================

  /**
   * Minimize the plugin (hide but keep state)
   * Flushes any pending drafts before hiding
   */
  async function minimizeLoremaster() {
    await flushDraft(editingEntryId);
    if (removeResizeListeners) {
      removeResizeListeners();
    }
    isPluginOpen = false;
    isMinimized = true;
    await Risuai.hideContainer();
    await syncChatDockButton();
    await syncRootDockButton();
  }

  /**
   * Close the plugin completely
   * Clears selection and flushes drafts
   */
  async function closeLoremaster() {
    isPluginOpen = false;
    isMinimized = false;
    await flushDraft(editingEntryId);
    clearSelection();
    if (removeResizeListeners) {
      removeResizeListeners();
    }
    await Risuai.hideContainer();
    await syncChatDockButton();
    await syncRootDockButton();
  }

  /**
   * Open the plugin
   * Renders the UI and shows the container in fullscreen mode
   */
  async function openLoremaster() {
    isMinimized = false;
    await render();
    await Risuai.showContainer('fullscreen');
    isPluginOpen = true;
    // Focus the container for keyboard events
    setTimeout(() => {
      const container = document.querySelector('.lm-container');
      if (container) {
        container.focus();
        container.click();
      }
    }, 100);
    await syncChatDockButton();
    await syncRootDockButton();
  }

  /**
   * Toggle plugin open/closed state
   */
  async function toggleLoremaster() {
    if (isPluginOpen) {
      await closeLoremaster();
    } else {
      await openLoremaster();
    }
  }

  // ============================================================================
  // SECTION 13: KEYBOARD SHORTCUTS
  // ============================================================================
  // Global keyboard shortcuts for plugin control.
  // Esc minimizes the plugin when open.
  // ============================================================================

  /**
   * Global hotkey handler for Escape key
   * Minimizes the plugin when Escape is pressed
   */
  const onHotkey = async (e) => {
    if ((e.key === 'Escape' || e.code === 'Escape') && isPluginOpen && !isMinimized) {
      e.preventDefault();
      e.stopPropagation();
      clearSelection();
      await minimizeLoremaster();
      return false;
    }
  };

  // Add listeners at multiple levels for reliability in iframe
  window.addEventListener('keydown', onHotkey, true);
  document.addEventListener('keydown', onHotkey, true);
  document.addEventListener('keyup', onHotkey, true);

  // Also try to capture on parent if same origin
  try {
    if (window.parent && window.parent !== window) {
      window.parent.addEventListener('keydown', onHotkey, true);
    }
  } catch (e) {
    // Cross-origin, ignore
  }

  // ============================================================================
  // SECTION 14: PLUGIN INITIALIZATION
  // ============================================================================
  // Registers the plugin with RisuAI, sets up buttons in the UI,
  // and handles cleanup on unload.
  // ============================================================================

  try {
    // RisuAI may re-run plugin scripts when switching bots while the iframe
    // still has fullscreen display state. Start hidden unless the user opens it.
    isPluginOpen = false;
    isMinimized = true;
    await Risuai.hideContainer();

    // Register chat dock button (opens the plugin)
    await Risuai.registerButton({
      name: 'LOREMASTER',
      icon: ICON,
      iconType: 'html',
      location: 'chat'
    }, openLoremaster);

    // Register settings menu entry
    await Risuai.registerSetting('LOREMASTER', openLoremaster, ICON, 'html');

    // Sync UI button states
    await syncChatDockButton();
    await syncRootDockButton();

    // Cleanup on plugin unload
    await Risuai.onUnload(async () => {
      await removeRootDockButton();
      await safeUnregisterUiPart(FAB_RESTORE_BUTTON_ID);
    });

    console.log('LOREMASTER initialized.');
  } catch (error) {
    console.log(`LOREMASTER init failed: ${error.message}`);
  }
})();
