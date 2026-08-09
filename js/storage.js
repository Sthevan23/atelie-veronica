/**
 * storage.js — Verônica Rodrigues
 * Offline: usa default-data.js · Online: MySQL via API Hostinger
 */
const Storage = (() => {
  const KEY = 'veronica_confeitaria_data';
  const DATA_VERSION = 19;
  const PRODUCTION_API = 'https://xn--ateliveronica-thb.com.br/api/data.php';
  const STORE_NAME_RE = /ver[oô]nica/i;
  const isLocalHost = /^(localhost|127\.0\.0\.1)$/i.test(location.hostname || '');
  const isFile = location.protocol === 'file:';

  const API = (() => {
    if (isFile) return PRODUCTION_API || '';
    if (isLocalHost) return PRODUCTION_API || '/api/data.php';
    const path = window.location.pathname || '';
    if (path.includes('/admin/')) {
      return path.replace(/\/admin\/.*$/, '/api/data.php');
    }
    if (path.endsWith('/')) return path + 'api/data.php';
    return path.replace(/\/[^/]*$/, '/api/data.php');
  })();

  let cloudEnabled = false;
  let lastRemoteJson = '';
  let pollTimer = null;
  let publicPollTimer = null;
  let memoryData = null;
  let pushBusy = false;
  let pushTail = Promise.resolve();
  let queuedPushData = null;
  let queuedPushResolvers = [];
  const PASS_KEY = 'veronica_admin_password';

  function emptyStore() {
    return {
      version: 0,
      settings: {
        name: '',
        tagline: '',
        logo: '',
        banner: '',
        sobreImage: '',
        whatsapp: '',
        instagram: '',
        instagramUser: '',
        facebook: '',
        email: '',
        address: '',
        hours: '',
        followers: '',
        posts: '',
        mapEmbed: '',
        heroBadge: '',
        heroStory: [],
        sobreText1: '',
        sobreText2: '',
      },
      auth: { email: '', password: '' },
      categories: [],
      products: [],
      clients: [],
      orders: [],
      finance: [],
      coupons: [],
      reviews: [],
      faq: [],
      gallery: [],
    };
  }

  function seedFromDefault() {
    if (typeof AURORA_DEFAULT_DATA === 'object' && AURORA_DEFAULT_DATA) {
      try {
        return JSON.parse(JSON.stringify(AURORA_DEFAULT_DATA));
      } catch {
        return { ...AURORA_DEFAULT_DATA };
      }
    }
    return emptyStore();
  }

  function init() {
    if (!memoryData) {
      try {
        const cached = localStorage.getItem(KEY);
        if (cached) {
          const parsed = JSON.parse(cached);
          // Mantém edições do painel mesmo se a versão do seed subir —
          // antes, version baixa apagava o cache e voltava o cardápio padrão.
          if (Array.isArray(parsed?.products) && parsed.products.length && parsed.settings) {
            const defaultVer = (typeof AURORA_DEFAULT_DATA === 'object' && AURORA_DEFAULT_DATA)
              ? Number(AURORA_DEFAULT_DATA.version) || DATA_VERSION
              : DATA_VERSION;
            if (Number(parsed.version) < defaultVer) {
              parsed.version = defaultVer;
              try { localStorage.setItem(KEY, JSON.stringify(parsed)); } catch { /* ignore */ }
            }
            memoryData = setMemory(parsed);
            return memoryData;
          }
        }
      } catch { /* ignore */ }
      memoryData = setMemory(seedFromDefault());
      try {
        localStorage.setItem(KEY, JSON.stringify(memoryData));
      } catch { /* ignore */ }
    }
    return memoryData;
  }

  function getAll() {
    if (!memoryData) return init();
    return memoryData;
  }

  function setMemory(data) {
    memoryData = data && typeof data === 'object' ? data : emptyStore();
    if (!Array.isArray(memoryData.finance)) memoryData.finance = [];
    if (!Array.isArray(memoryData.coupons)) memoryData.coupons = [];
    if (!Array.isArray(memoryData.products)) memoryData.products = [];
    if (!Array.isArray(memoryData.categories)) memoryData.categories = [];
    if (!Array.isArray(memoryData.orders)) memoryData.orders = [];
    if (!Array.isArray(memoryData.clients)) memoryData.clients = [];
    if (!Array.isArray(memoryData.gallery)) memoryData.gallery = [];
    return memoryData;
  }

  function persistLocal(data) {
    data.version = Math.max(Number(data.version) || 0, DATA_VERSION);
    setMemory(data);
    try {
      localStorage.setItem(KEY, JSON.stringify(memoryData));
    } catch { /* ignore */ }
    notifyUpdated();
  }

  function save(data) {
    persistLocal(data);
    // fire-and-forget (compatível com o resto do admin)
    if (API) pushToCloud(data).catch(() => {});
  }

  async function saveAsync(data) {
    persistLocal(data);
    return pushToCloud(data);
  }

  function getAdminPassword() {
    const fromSession = sessionStorage.getItem('admin_password') || '';
    if (fromSession) return fromSession;
    // Celular às vezes perde sessionStorage ao trocar de aba — localStorage segura a senha da sessão do painel
    try {
      const fromLocal = localStorage.getItem(PASS_KEY) || '';
      if (fromLocal) {
        sessionStorage.setItem('admin_password', fromLocal);
        return fromLocal;
      }
    } catch { /* ignore */ }
    return '';
  }

  function setAdminPassword(password) {
    if (password) {
      sessionStorage.setItem('admin_password', password);
      try { localStorage.setItem(PASS_KEY, password); } catch { /* ignore */ }
    } else {
      sessionStorage.removeItem('admin_password');
      try { localStorage.removeItem(PASS_KEY); } catch { /* ignore */ }
    }
  }

  function isCloudEnabled() {
    return cloudEnabled;
  }

  function notifyUpdated() {
    window.dispatchEvent(new CustomEvent('storage-updated'));
  }

  async function fetchWithTimeout(url, options = {}, ms = 12000) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), ms);
    try {
      return await fetch(url, { ...options, signal: controller.signal, cache: 'no-store' });
    } finally {
      clearTimeout(timer);
    }
  }

  async function probeCloud() {
    if (!API) {
      cloudEnabled = false;
      return false;
    }
    try {
      const res = await fetchWithTimeout(API + '?ping=' + Date.now());
      const type = (res.headers.get('content-type') || '').toLowerCase();
      const body = await res.clone().json().catch(() => ({}));
      cloudEnabled = res.ok && type.includes('json') && body.ok !== false;
      return cloudEnabled;
    } catch {
      cloudEnabled = false;
      return false;
    }
  }

  async function pullPublic() {
    if (!(await probeCloud())) return false;
    try {
      const res = await fetchWithTimeout(API + '?t=' + Date.now());
      if (!res.ok) return false;
      const remote = await res.json();
      if (remote.empty || remote.error) return false;
      if (!remote.settings || !Array.isArray(remote.products)) return false;
      // Evita puxar cardápio de outro site (ex.: Aurora) no mesmo Hostinger
      const remoteName = String(remote.settings.name || '');
      const remoteWa = String(remote.settings.whatsapp || '').replace(/\D/g, '');
      const looksLikeVeronica =
        STORE_NAME_RE.test(remoteName) ||
        remoteWa.endsWith('37998741557') ||
        remoteWa.includes('37998741557');
      if (!looksLikeVeronica) {
        console.info('[Verônica] API conectada, mas o banco ainda não é deste ateliê — usando cardápio local.');
        return false;
      }
      const merged = {
        ...emptyStore(),
        version: remote.version || DATA_VERSION,
        settings: remote.settings,
        categories: remote.categories || [],
        products: remote.products || [],
        reviews: remote.reviews || [],
        faq: remote.faq || [],
        gallery: remote.gallery || [],
        coupons: Array.isArray(remote.coupons) ? remote.coupons : [],
        clients: [],
        orders: [],
        finance: [],
        auth: { email: '', password: '' },
      };
      const json = JSON.stringify(merged);
      if (json === lastRemoteJson) {
        cloudEnabled = true;
        return true;
      }
      setMemory(merged);
      try { localStorage.setItem(KEY, JSON.stringify(merged)); } catch { /* ignore */ }
      lastRemoteJson = json;
      cloudEnabled = true;
      notifyUpdated();
      return true;
    } catch {
      return false;
    }
  }

  async function pullFull() {
    const password = getAdminPassword();
    if (!password || !(await probeCloud())) return false;
    try {
      const res = await fetchWithTimeout(API + '?full=1&t=' + Date.now(), {
        headers: { 'X-Admin-Password': password },
      });
      if (!res.ok) return false;
      const remote = await res.json();
      if (!remote || !remote.settings) return false;
      const json = JSON.stringify(remote);
      if (json === lastRemoteJson) return true;
      setMemory(remote);
      lastRemoteJson = json;
      notifyUpdated();
      return true;
    } catch {
      return false;
    }
  }

  async function doPushToCloud(data) {
    const password = getAdminPassword() || (data.auth && data.auth.password) || '';
    if (!password) {
      console.warn('[Verônica] Sem senha de admin — não enviou pra nuvem');
      return false;
    }

    // Garante que a senha da sessão vá no payload (evita sobrescrever auth vazio)
    if (!data.auth || typeof data.auth !== 'object') {
      data.auth = { email: '', password };
    } else if (!data.auth.password) {
      data.auth = { ...data.auth, password };
    }

    pushBusy = true;
    try {
      const payload = JSON.stringify({ data });
      const timeoutMs = payload.length > 400000 ? 90000 : 45000;
      const res = await fetchWithTimeout(API, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Admin-Password': password,
        },
        body: payload,
      }, timeoutMs);

      let result = {};
      try {
        result = await res.json();
      } catch {
        result = {};
      }

      if (res.ok && result.ok !== false) {
        setMemory(data);
        try { localStorage.setItem(KEY, JSON.stringify(memoryData)); } catch { /* ignore */ }
        lastRemoteJson = JSON.stringify(data);
        cloudEnabled = true;
        return true;
      }
      console.warn('[Verônica] Falha ao salvar na nuvem', res.status, result);
      return false;
    } catch (err) {
      console.warn('[Verônica] Erro de rede ao salvar', err);
      return false;
    } finally {
      pushBusy = false;
    }
  }

  async function flushPushQueue() {
    if (!queuedPushData) return false;
    const toSend = queuedPushData;
    const resolvers = queuedPushResolvers.slice();
    queuedPushData = null;
    queuedPushResolvers = [];
    const ok = await doPushToCloud(toSend);
    resolvers.forEach((resolve) => resolve(ok));
    if (queuedPushData) return flushPushQueue();
    return ok;
  }

  function pushToCloud(data) {
    // Só envia o estado mais recente (vários cliques = 1 sync final)
    queuedPushData = data;
    return new Promise((resolve) => {
      queuedPushResolvers.push(resolve);
      pushTail = pushTail.then(flushPushQueue).catch(() => {
        queuedPushResolvers.splice(0).forEach((r) => r(false));
        return false;
      });
    });
  }

  async function loginRemote(email, password) {
    email = String(email || '').trim().toLowerCase().replace(/\s+/g, '');
    password = String(password || '').trim();
    const probed = await probeCloud();
    if (!probed) {
      return { ok: false, error: 'api_offline' };
    }
    try {
      const res = await fetchWithTimeout(API, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'login', email, password }),
      }, 30000);
      const result = await res.json().catch(() => ({}));
      if (!res.ok || !result.ok) {
        const msg = String(result.error || '');
        if (res.status >= 500 || /mysql|conexão|conexao|banco/i.test(msg)) {
          return { ok: false, error: 'api_offline', detail: msg };
        }
        return { ok: false, error: 'auth', detail: msg };
      }

      setAdminPassword(password);
      cloudEnabled = true;

      // Login leve: busca o painel completo em seguida
      if (result.lite || !result.data) {
        const pulled = await pullFull();
        if (!pulled) {
          return { ok: false, error: 'api_offline', detail: 'Login ok, mas não carregou os dados' };
        }
        return { ok: true };
      }

      setMemory(result.data);
      lastRemoteJson = JSON.stringify(result.data);
      return { ok: true };
    } catch {
      return { ok: false, error: 'api_offline' };
    }
  }

  function loginLocal() {
    // Desativado: login só via MySQL/API
    return { ok: false, error: 'api_offline' };
  }

  function startCloudPolling(intervalMs = 5000) {
    stopCloudPolling();
    if (!getAdminPassword()) return;
    pollTimer = setInterval(() => {
      if (pushBusy) return;
      pullFull();
    }, intervalMs);
  }

  function stopCloudPolling() {
    if (pollTimer) {
      clearInterval(pollTimer);
      pollTimer = null;
    }
  }

  function startPublicPolling(intervalMs = 12000) {
    stopPublicPolling();
    publicPollTimer = setInterval(() => {
      pullPublic().catch(() => {});
    }, intervalMs);
  }

  function stopPublicPolling() {
    if (publicPollTimer) {
      clearInterval(publicPollTimer);
      publicPollTimer = null;
    }
  }

  async function initCloud({ full = false } = {}) {
    init();
    // No celular a 1ª tentativa às vezes falha — tenta de novo
    for (let attempt = 0; attempt < 3; attempt += 1) {
      const ok = full ? await pullFull() : await pullPublic();
      if (ok && cloudEnabled) return true;
      await new Promise((r) => setTimeout(r, 400 * (attempt + 1)));
    }
    return false;
  }

  function getApiUrl() {
    return API;
  }

  function getSettings() { return getAll().settings; }
  function saveSettings(settings) {
    const data = getAll();
    data.settings = { ...data.settings, ...settings };
    save(data);
  }
  async function saveSettingsAsync(settings) {
    const data = getAll();
    data.settings = { ...data.settings, ...settings };
    return saveAsync(data);
  }
  function getProducts() { return getAll().products; }
  function saveProducts(products) {
    const data = getAll();
    data.products = products;
    save(data);
  }
  async function saveProductsAsync(products) {
    const data = getAll();
    data.products = products;
    return saveAsync(data);
  }
  async function saveClientsAsync(clients) {
    const data = getAll();
    data.clients = clients;
    return saveAsync(data);
  }
  function getCategories() { return getAll().categories; }
  function saveCategories(categories) {
    const data = getAll();
    data.categories = categories;
    save(data);
  }
  async function saveCategoriesAsync(categories) {
    const data = getAll();
    data.categories = categories;
    return saveAsync(data);
  }
  async function saveOrdersAsync(orders) {
    const data = getAll();
    data.orders = orders;
    return saveAsync(data);
  }
  function getClients() { return getAll().clients; }
  function saveClients(clients) {
    const data = getAll();
    data.clients = clients;
    save(data);
  }
  function getOrders() { return getAll().orders; }
  function saveOrders(orders) {
    const data = getAll();
    data.orders = orders;
    save(data);
  }
  function getFinance() {
    return getAll().finance || [];
  }
  function saveFinance(entries) {
    const data = getAll();
    data.finance = entries;
    save(data);
  }
  function getCoupons() {
    return getAll().coupons || [];
  }
  function saveCoupons(coupons) {
    const data = getAll();
    data.coupons = coupons;
    save(data);
  }
  async function saveCouponsAsync(coupons) {
    const data = getAll();
    data.coupons = coupons;
    return saveAsync(data);
  }
  function findCouponByCode(code) {
    const needle = String(code || '').trim().toUpperCase();
    if (!needle) return null;
    return getCoupons().find((c) => {
      const active = c.active !== false;
      return active && String(c.code || '').trim().toUpperCase() === needle;
    }) || null;
  }
  function calcCouponDiscount(coupon, subtotal) {
    const total = Math.max(0, Number(subtotal) || 0);
    if (!coupon || total <= 0) return 0;
    const minOrder = Number(coupon.minOrder) || 0;
    if (total < minOrder) return 0;
    const value = Number(coupon.value) || 0;
    if (value <= 0) return 0;
    if (coupon.type === 'fixed') {
      return Math.min(total, value);
    }
    // percent
    const pct = Math.min(100, Math.max(0, value));
    return Math.round((total * (pct / 100)) * 100) / 100;
  }
  function addFinanceEntry({ type, amount, description, category }) {
    const entries = getFinance();
    const entry = {
      id: generateId('f'),
      type: type === 'expense' ? 'expense' : 'income',
      amount: Number(amount) || 0,
      description: String(description || '').trim(),
      category: category || (type === 'expense' ? 'Despesa' : 'Manual'),
      date: new Date().toISOString(),
    };
    entries.unshift(entry);
    saveFinance(entries);
    return entry;
  }
  function deleteFinanceEntry(id) {
    saveFinance(getFinance().filter((e) => e.id !== id));
  }
  function getFinanceSummary() {
    const entries = getFinance();
    const incomeManual = entries.filter((e) => e.type === 'income').reduce((s, e) => s + Number(e.amount || 0), 0);
    const expense = entries.filter((e) => e.type === 'expense').reduce((s, e) => s + Number(e.amount || 0), 0);
    const fromOrders = getDashboardStats().totalSales;
    return {
      orderSales: fromOrders,
      incomeManual,
      expense,
      balance: fromOrders + incomeManual - expense,
      entries,
    };
  }
  function getReviews() { return getAll().reviews || []; }
  function getFaq() { return getAll().faq || []; }
  function getGallery() { return getAll().gallery || []; }

  function login(email, password) { return loginLocal(email, password); }
  async function loginAsync(email, password) {
    const result = await loginRemote(email, password);
    // Compatível com código antigo que espera true/false
    if (result && typeof result === 'object') {
      loginAsync.lastError = result.error || '';
      return !!result.ok;
    }
    loginAsync.lastError = '';
    return !!result;
  }
  loginAsync.lastError = '';
  loginAsync.getLastError = () => loginAsync.lastError;

  function updatePassword(currentPassword, newPassword) {
    const data = getAll();
    const sessionPass = getAdminPassword();
    const okCurrent =
      data.auth.password === currentPassword ||
      (sessionPass && sessionPass === currentPassword);
    if (!okCurrent) return false;
    data.auth.password = newPassword;
    setAdminPassword(newPassword);
    save(data);
    return true;
  }

  async function updatePasswordAsync(currentPassword, newPassword) {
    const data = getAll();
    const sessionPass = getAdminPassword();
    const okCurrent =
      data.auth.password === currentPassword ||
      (sessionPass && sessionPass === currentPassword);
    if (!okCurrent) return false;
    data.auth.password = newPassword;
    setAdminPassword(newPassword);
    return saveAsync(data);
  }

  function generateId(prefix) {
    return prefix + Date.now().toString(36) + Math.random().toString(36).substr(2, 5);
  }

  function generateOrderNumber() {
    const orders = getOrders();
    const year = new Date().getFullYear();
    let max = 0;
    orders.forEach((order) => {
      const match = String(order.number || '').match(/PED-(\d{4})-(\d+)/i);
      if (match && Number(match[1]) === year) max = Math.max(max, Number(match[2]) || 0);
    });
    return `PED-${year}-${String(max + 1).padStart(3, '0')}`;
  }

  function getCategoryName(categoryId) {
    const cat = getCategories().find((c) => c.id === categoryId);
    return cat ? cat.name : 'Outros';
  }

  function formatCurrency(value) {
    return Number(value || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
  }

  function productDisplayPrice(product) {
    if (product.promoActive && product.promoPrice != null && product.promoPrice >= 0) {
      return Number(product.promoPrice);
    }
    return Number(product.price || 0);
  }

  function getDashboardStats() {
    const orders = getOrders();
    const finished = orders.filter((o) => o.status === 'finalizado');
    const totalSales = finished.reduce((sum, o) => sum + o.total, 0);
    const today = new Date().toISOString().split('T')[0];
    const todaySales = finished.filter((o) => o.date.startsWith(today)).reduce((s, o) => s + o.total, 0);
    const month = new Date().toISOString().slice(0, 7);
    const monthSales = finished.filter((o) => o.date.startsWith(month)).reduce((s, o) => s + o.total, 0);
    return {
      totalOrders: orders.length,
      totalSales,
      totalClients: getClients().length,
      totalProducts: getProducts().length,
      todaySales,
      monthSales,
    };
  }

  function getMonthlyRevenue() {
    const orders = getOrders().filter((o) => o.status === 'finalizado');
    const months = {};
    const monthNames = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    for (let i = 5; i >= 0; i--) {
      const d = new Date();
      d.setMonth(d.getMonth() - i);
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
      months[key] = { label: monthNames[d.getMonth()], value: 0 };
    }
    orders.forEach((o) => {
      const key = o.date.slice(0, 7);
      if (months[key]) months[key].value += o.total;
    });
    return Object.values(months);
  }

  function getFinishedOrdersByPeriod(period = 'all') {
    const finished = getOrders().filter((o) => o.status === 'finalizado');
    if (period === 'today') {
      const today = new Date().toISOString().split('T')[0];
      return finished.filter((o) => o.date.startsWith(today));
    }
    if (period === 'month') {
      const month = new Date().toISOString().slice(0, 7);
      return finished.filter((o) => o.date.startsWith(month));
    }
    return finished;
  }

  function getProductSalesBreakdown(period = 'all') {
    const orders = getFinishedOrdersByPeriod(period);
    const map = {};
    orders.forEach((order) => {
      (order.items || []).forEach((item) => {
        const key = item.productId || item.name;
        if (!map[key]) {
          map[key] = { productId: item.productId || null, name: item.name || 'Produto', qty: 0, revenue: 0 };
        }
        const qty = Number(item.qty) || 0;
        const price = Number(item.price) || 0;
        map[key].qty += qty;
        map[key].revenue += qty * price;
        map[key].name = item.name || map[key].name;
      });
    });
    return Object.values(map)
      .map((row) => ({ ...row, avgPrice: row.qty > 0 ? row.revenue / row.qty : 0 }))
      .sort((a, b) => b.revenue - a.revenue);
  }

  function getSalesPeriodStats(period = 'all') {
    const orders = getFinishedOrdersByPeriod(period);
    const breakdown = getProductSalesBreakdown(period);
    return {
      orderCount: orders.length,
      totalRevenue: orders.reduce((sum, o) => sum + (Number(o.total) || 0), 0),
      cakesSold: breakdown.reduce((sum, row) => sum + row.qty, 0),
      products: breakdown,
    };
  }

  function nextOrderNumber(orders) {
    const year = new Date().getFullYear();
    let max = 0;
    (orders || []).forEach((order) => {
      const match = String(order.number || '').match(/PED-(\d{4})-(\d+)/i);
      if (match && Number(match[1]) === year) max = Math.max(max, Number(match[2]) || 0);
    });
    return `PED-${year}-${String(max + 1).padStart(3, '0')}`;
  }

  function orderFingerprint(phone, items, notes) {
    const itemKey = (items || [])
      .map((item) => `${item.productId || ''}|${item.name || ''}|${item.qty || 1}|${item.price || 0}|${item.detail || ''}`)
      .join(';');
    return `${phone}::${itemKey}::${notes || ''}`;
  }

  function findRecentDuplicate(orders, phone, items, notes, windowMs = 90000) {
    const fingerprint = orderFingerprint(phone, items, notes);
    const now = Date.now();
    return (orders || []).find((order) => {
      const orderPhone = String(order.clientWhatsapp || '').replace(/\D/g, '');
      if (orderPhone !== phone) return false;
      const age = now - new Date(order.date || 0).getTime();
      if (Number.isNaN(age) || age < 0 || age > windowMs) return false;
      return orderFingerprint(orderPhone, order.items, order.notes) === fingerprint;
    });
  }

  function phoneMatchKeys(whatsapp) {
    const phone = String(whatsapp || '').replace(/\D/g, '');
    if (!phone || phone.length < 10) return new Set();
    const keys = new Set();
    const add = (p) => {
      if (p && String(p).length >= 10) keys.add(String(p));
    };
    add(phone);
    const local = phone.startsWith('55') && phone.length >= 12 ? phone.slice(2) : phone;
    add(local);
    add(phone.startsWith('55') ? phone : `55${phone}`);
    add(local.startsWith('55') ? local : `55${local}`);
    if (local.length === 11 && local[2] === '9') {
      const noNine = local.slice(0, 2) + local.slice(3);
      add(noNine);
      add(`55${noNine}`);
    } else if (local.length === 10) {
      const withNine = `${local.slice(0, 2)}9${local.slice(2)}`;
      add(withNine);
      add(`55${withNine}`);
    }
    return keys;
  }

  function phonesEquivalent(a, b) {
    const ka = phoneMatchKeys(a);
    const kb = phoneMatchKeys(b);
    if (!ka.size || !kb.size) return false;
    for (const k of ka) {
      if (kb.has(k)) return true;
    }
    return false;
  }

  function computeLoyaltyFromOrders(orders, whatsapp, bonusOverride) {
    const goal = 15;
    const gift = '1 brinde surpresa da Verônica';
    const phone = String(whatsapp || '').replace(/\D/g, '');
    if (!phone || phone.length < 10) {
      return {
        phone: '', total: 0, siteTotal: 0, bonus: 0, progress: 0, goal, remaining: goal,
        rewards: 0, eligible: false, gift,
      };
    }
    const siteTotal = (orders || []).filter((o) => {
      if (String(o.status || '').toLowerCase() === 'cancelado') return false;
      return phonesEquivalent(phone, o.clientWhatsapp || '');
    }).length;

    let bonus = 0;
    if (typeof bonusOverride === 'number' && Number.isFinite(bonusOverride)) {
      bonus = Math.max(0, Math.floor(bonusOverride));
    } else {
      const clients = getClients() || [];
      const client = clients.find((c) => phonesEquivalent(phone, c.phone || ''));
      bonus = Math.max(0, Math.floor(Number(client?.loyaltyBonus) || 0));
    }

    const total = siteTotal + bonus;
    const rewards = Math.floor(total / goal);
    const mod = total % goal;
    const eligible = total > 0 && mod === 0;
    const progress = eligible ? goal : mod;
    const remaining = eligible ? 0 : (goal - progress);
    return { phone, total, siteTotal, bonus, progress, goal, remaining, rewards, eligible, gift };
  }

  async function getLoyaltyStatus(whatsapp) {
    const phone = String(whatsapp || '').replace(/\D/g, '');
    if (!phone || phone.length < 10) {
      return computeLoyaltyFromOrders([], phone);
    }
    if (location.protocol !== 'file:' || isLocalHost) {
      try {
        const res = await fetch(API, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ action: 'loyalty_status', phone }),
        });
        const result = await res.json().catch(() => ({}));
        if (res.ok && result.ok && result.loyalty) return result.loyalty;
      } catch { /* fallback local */ }
    }
    return computeLoyaltyFromOrders(getOrders(), phone);
  }

  async function createPublicOrder({ fullName, whatsapp, items, total, notes }) {
    const phone = String(whatsapp || '').replace(/\D/g, '');
    const name = String(fullName || '').trim();
    if (!name || phone.length < 10 || !items || !items.length) {
      return { ok: false, error: 'Dados incompletos' };
    }

    const data = getAll();
    data.orders = data.orders || [];
    data.clients = data.clients || [];

    const duplicate = findRecentDuplicate(data.orders, phone, items, notes);
    if (duplicate) {
      return {
        ok: true,
        order: duplicate,
        duplicated: true,
        loyalty: computeLoyaltyFromOrders(data.orders, phone),
      };
    }

    let client = data.clients.find((c) => String(c.phone || '').replace(/\D/g, '') === phone);
    if (!client) {
      client = { id: generateId('c'), name, email: '', phone, address: '' };
      data.clients.push(client);
    } else {
      client.name = name;
      client.phone = phone;
    }

    const order = {
      id: generateId('o'),
      number: nextOrderNumber(data.orders),
      clientId: client.id,
      clientName: name,
      clientWhatsapp: phone,
      items,
      total: Number(total) || items.reduce((s, i) => s + (Number(i.price) || 0) * (Number(i.qty) || 1), 0),
      status: 'novo',
      date: new Date().toISOString(),
      notes: notes || '',
      source: 'site',
    };

    let loyalty = null;
    if (location.protocol !== 'file:' || isLocalHost) {
      try {
        const res = await fetch(API, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ action: 'create_order', order, client }),
        });
        const result = await res.json().catch(() => ({}));
        if (!res.ok || !result.ok) {
          const detail = result.detail ? ` (${result.detail})` : '';
          return { ok: false, error: (result.error || 'Falha ao gravar no MySQL') + detail };
        }
        if (result.orderNumber) order.number = result.orderNumber;
        if (result.loyalty) loyalty = result.loyalty;
      } catch {
        return { ok: false, error: 'Sem conexão com a API Hostinger' };
      }
    } else {
      return { ok: false, error: 'Abra pelo localhost ou pelo site online' };
    }

    data.orders.push(order);
    setMemory(data);
    if (!loyalty) loyalty = computeLoyaltyFromOrders(data.orders, phone);
    return { ok: true, order, loyalty };
  }

  return {
    init, getAll, save,
    getSettings, saveSettings, saveSettingsAsync,
    getProducts, saveProducts, saveProductsAsync,
    getCategories, saveCategories, saveCategoriesAsync,
    getClients, saveClients, saveClientsAsync,
    getOrders, saveOrders, saveOrdersAsync,
    getFinance, saveFinance, addFinanceEntry, deleteFinanceEntry, getFinanceSummary,
    getCoupons, saveCoupons, saveCouponsAsync, findCouponByCode, calcCouponDiscount,
    getReviews, getFaq, getGallery,
    login, loginAsync, updatePassword, updatePasswordAsync,
    generateId, generateOrderNumber,
    getCategoryName, formatCurrency, productDisplayPrice,
    getDashboardStats, getMonthlyRevenue,
    getFinishedOrdersByPeriod, getProductSalesBreakdown, getSalesPeriodStats,
    initCloud, pullFull, pullPublic, pushToCloud, saveAsync,
    isCloudEnabled, setAdminPassword, getAdminPassword,
    startCloudPolling, stopCloudPolling, startPublicPolling, stopPublicPolling, notifyUpdated,
    createPublicOrder, getLoyaltyStatus, computeLoyaltyFromOrders, getApiUrl,
  };
})();

Storage.init();
