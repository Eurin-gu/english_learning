const dbKey = "assistant_pro_v1";
const state = load();
const textInput = document.getElementById("textInput");
const statusEl = document.getElementById("status");
const imageInput = document.getElementById("imageInput");
let chart;

const stopwords = new Set([
  "the","a","an","and","or","but","is","are","am","to","of","in","on","for","at","with","as","this","that",
  "be","was","were","do","did","done","have","has","had","from","by","not","it","we","you","they","he","she"
]);
const categories = [
  { key: "餐饮", hints: ["美团", "饿了么", "咖啡", "奶茶", "饭", "麦当劳", "kfc"] },
  { key: "交通", hints: ["滴滴", "地铁", "公交", "打车", "停车"] },
  { key: "学习", hints: ["课程", "书", "教材", "学费", "培训"] },
  { key: "购物", hints: ["淘宝", "京东", "拼多多", "超市"] },
  { key: "娱乐", hints: ["电影", "游戏", "ktv", "演出"] }
];

bindEvents();
hydrateFromShortcut();
renderAll();
registerSW();

function bindEvents() {
  document.getElementById("parseBtn").addEventListener("click", () => parseAndStore(textInput.value));
  document.getElementById("clearBtn").addEventListener("click", () => (textInput.value = ""));
  document.getElementById("ocrBtn").addEventListener("click", runOCR);
  document.getElementById("nightReviewBtn").addEventListener("click", makeNightReview);
}

function setStatus(msg, isError = false) {
  statusEl.textContent = msg;
  statusEl.classList.toggle("danger", isError);
}

async function runOCR() {
  const file = imageInput.files?.[0];
  if (!file) return setStatus("先选择一张图片", true);
  setStatus("OCR 识别中（微信截图优化）...");
  try {
    const preparedImage = await preprocessImage(file);
    const { data } = await Tesseract.recognize(preparedImage, "chi_sim+eng", {
      tessedit_pageseg_mode: "6",
      preserve_interword_spaces: "1"
    });
    textInput.value = data.text || "";
    setStatus("OCR 完成，点击“解析并入库”");
  } catch (e) {
    setStatus(`OCR 失败: ${e.message}`, true);
  }
}

function parseAndStore(text) {
  if (!text.trim()) return setStatus("文本为空，无法解析", true);
  const tasks = parseTasks(text);
  const expenses = parseExpenses(text);
  const words = parseWords(text);
  state.tasks.unshift(...tasks);
  state.expenses.unshift(...expenses);
  state.words.unshift(...words.filter(w => !state.words.some(x => x.word === w.word)));
  save();
  renderAll();
  setStatus(`导入成功：任务 ${tasks.length}，支出 ${expenses.length}，生词 ${words.length}`);
}

function parseTasks(text) {
  const lines = text.split(/\n+/).map(x => x.trim()).filter(Boolean);
  const kws = ["作业","截止","提交","考试","任务","deadline","assignment","quiz","meeting","tomorrow","明天"];
  return lines
    .filter(line => kws.some(k => line.toLowerCase().includes(k.toLowerCase())))
    .map(line => ({ id: uid(), title: line, due: inferDate(line), createdAt: Date.now() }));
}

function inferDate(line) {
  const now = new Date();
  if (line.includes("明天") || /tomorrow/i.test(line)) {
    return new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1).toISOString();
  }
  if (line.includes("今天") || /today/i.test(line)) return now.toISOString();
  return null;
}

function parseExpenses(text) {
  const cleaned = normalizeOCRText(text);
  const lines = cleaned.split(/\n+/).map(x => x.trim()).filter(Boolean);
  const out = lines.flatMap(line => {
    const m = line.match(/(?:¥|￥|rmb|RMB|人民币)?\s*([0-9]{1,6}(?:\.[0-9]{1,2})?)/i);
    if (!m) return [];
    const amount = Number(m[1]);
    if (!(amount > 0) || amount > 100000) return [];
    return [{
      id: uid(),
      merchant: extractMerchant(line),
      amount,
      category: inferCategory(line),
      createdAt: Date.now()
    }];
  });
  return dedupeExpenses(out);
}

function inferCategory(line) {
  const lower = line.toLowerCase();
  for (const c of categories) {
    if (c.hints.some(h => lower.includes(h.toLowerCase()))) return c.key;
  }
  return "其他";
}

function parseWords(text) {
  const words = (text.match(/\b[A-Za-z]{4,20}\b/g) || []).map(x => x.toLowerCase());
  const unique = [...new Set(words)].filter(w => !stopwords.has(w));
  return unique.map(word => ({ id: uid(), word, mastered: false, createdAt: Date.now() }));
}

function makeNightReview() {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const list = state.words.filter(w => !w.mastered && w.createdAt >= today.getTime());
  if (!list.length) return setStatus("今晚复习清单为空（今天没有新增不会词）");
  alert(`今晚复习 ${list.length} 个词:\n\n${list.map(x => x.word).join(", ")}`);
}

function renderAll() {
  renderTasks();
  renderExpenses();
  renderWords();
  renderChart();
}

function renderTasks() {
  const root = document.getElementById("taskList");
  root.innerHTML = "";
  for (const item of state.tasks.slice(0, 30)) {
    const li = document.createElement("li");
    li.className = "item";
    li.innerHTML = `<div>${escapeHtml(item.title)}</div><div class="meta">截止: ${item.due ? new Date(item.due).toLocaleString() : "未识别"}</div>`;
    root.appendChild(li);
  }
}

function renderExpenses() {
  const root = document.getElementById("expenseList");
  root.innerHTML = "";
  for (const item of state.expenses.slice(0, 40)) {
    const li = document.createElement("li");
    li.className = "item";
    li.innerHTML = `<div>${escapeHtml(item.merchant)}</div><div class="meta">${item.category} · ¥${item.amount.toFixed(2)}</div>`;
    root.appendChild(li);
  }
}

function renderWords() {
  const root = document.getElementById("wordList");
  root.innerHTML = "";
  for (const item of state.words.slice(0, 80)) {
    const li = document.createElement("li");
    li.className = "item";
    const btn = item.mastered ? "设为不会" : "设为已掌握";
    li.innerHTML = `<div>${item.word}</div><div class="meta">${item.mastered ? "已掌握" : "不会"} · ${new Date(item.createdAt).toLocaleString()}</div><button class="ghost">${btn}</button>`;
    li.querySelector("button").addEventListener("click", () => {
      item.mastered = !item.mastered;
      save();
      renderWords();
    });
    root.appendChild(li);
  }
}

function renderChart() {
  const sums = {};
  for (const e of state.expenses) sums[e.category] = (sums[e.category] || 0) + e.amount;
  const labels = Object.keys(sums);
  const values = Object.values(sums);
  const ctx = document.getElementById("expenseChart");
  if (chart) chart.destroy();
  chart = new Chart(ctx, {
    type: "doughnut",
    data: {
      labels,
      datasets: [{ data: values }]
    },
    options: {
      plugins: { legend: { labels: { color: "#d8def0" } } }
    }
  });
}

function hydrateFromShortcut() {
  const url = new URL(location.href);
  const text = decodeURIComponent(url.searchParams.get("text") || "");
  const auto = url.searchParams.get("auto") === "1";
  if (text) {
    textInput.value = text;
    if (auto) {
      parseAndStore(text);
      setStatus("已通过快捷指令自动解析并入库");
    } else {
      setStatus("已接收快捷指令文本，点“解析并入库”");
    }
  }
}

function uid() { return `${Date.now()}_${Math.random().toString(36).slice(2, 9)}`; }
function save() { localStorage.setItem(dbKey, JSON.stringify(state)); }
function load() {
  try {
    return JSON.parse(localStorage.getItem(dbKey)) || { tasks: [], expenses: [], words: [] };
  } catch {
    return { tasks: [], expenses: [], words: [] };
  }
}
function escapeHtml(s) {
  return s.replace(/[&<>"']/g, m => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;", "'": "&#39;" }[m]));
}
async function registerSW() {
  if ("serviceWorker" in navigator) {
    try { await navigator.serviceWorker.register("./sw.js"); } catch (_) {}
  }
}

async function preprocessImage(file) {
  const bmp = await createImageBitmap(file);
  const maxW = 1800;
  const scale = Math.min(1, maxW / bmp.width);
  const w = Math.round(bmp.width * scale);
  const h = Math.round(bmp.height * scale);
  const canvas = document.createElement("canvas");
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext("2d");
  ctx.drawImage(bmp, 0, 0, w, h);
  const imageData = ctx.getImageData(0, 0, w, h);
  const d = imageData.data;
  // Increase contrast and convert to near-binary grayscale for receipt-like screenshots.
  for (let i = 0; i < d.length; i += 4) {
    const gray = 0.299 * d[i] + 0.587 * d[i + 1] + 0.114 * d[i + 2];
    const boost = gray > 165 ? 255 : gray < 95 ? 0 : gray;
    d[i] = boost;
    d[i + 1] = boost;
    d[i + 2] = boost;
  }
  ctx.putImageData(imageData, 0, 0);
  return canvas;
}

function normalizeOCRText(text) {
  return text
    .replace(/O/g, "0")
    .replace(/o/g, "0")
    .replace(/[,，]/g, ".")
    .replace(/[ ]{2,}/g, " ")
    .replace(/(?:\r\n|\r)/g, "\n");
}

function extractMerchant(line) {
  const cleaned = line.replace(/(?:¥|￥|rmb|RMB|人民币)?\s*[0-9]{1,6}(?:\.[0-9]{1,2})?/g, "").trim();
  return (cleaned || line).slice(0, 24);
}

function dedupeExpenses(items) {
  const seen = new Set();
  return items.filter(e => {
    const key = `${e.merchant}_${e.amount.toFixed(2)}_${new Date(e.createdAt).toDateString()}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}
