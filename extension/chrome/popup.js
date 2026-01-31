// Popup Logic (Simplified)

const statusDot = document.getElementById('status-indicator');
const listContainer = document.getElementById('downloads-list');
const portInput = document.getElementById('port-input');
const cookiesToggle = document.getElementById('cookies-toggle');
const connectionMsg = document.getElementById('connection-msg');

// ===================================
// 1. Connection Status
// ===================================
function updateStatus() {
    chrome.action.getBadgeText({}, (text) => {
        if (text === 'ON') {
            statusDot.className = 'status-dot connected';
            statusDot.title = 'Connected';
            connectionMsg.textContent = 'Connected';
            connectionMsg.style.color = '#4CAF50';
        } else {
            statusDot.className = 'status-dot disconnected';
            statusDot.title = 'Disconnected';
            connectionMsg.textContent = 'Disconnected (Check App)';
            connectionMsg.style.color = '#F44336';
        }
    });
}
// Check every 2 seconds
updateStatus();
setInterval(updateStatus, 2000);

const browserSelect = document.getElementById('browser-select');

// ===================================
// 2. Settings (Auto-Save)
// ===================================
// Load initial
chrome.storage.local.get(['serverPort', 'autoSendCookies', 'preferredBrowser'], (result) => {
    portInput.value = result.serverPort || 6969; // Default 6969
    cookiesToggle.checked = result.autoSendCookies !== false; // Default true
    if (result.preferredBrowser) browserSelect.value = result.preferredBrowser;
});

// Save on change
function saveSettings() {
    const port = parseInt(portInput.value) || 6969;
    const autoSend = cookiesToggle.checked;
    const browser = browserSelect.value;

    chrome.storage.local.set({
        serverPort: port,
        autoSendCookies: autoSend,
        preferredBrowser: browser
    }, () => {
        // Optional: Signal background to reconnect if port changed
        // chrome.runtime.sendMessage({ type: 'CONFIG_UPDATED' });
    });
}

portInput.addEventListener('change', saveSettings);
cookiesToggle.addEventListener('change', saveSettings);
browserSelect.addEventListener('change', saveSettings);

// ===================================
// 3. Download List Rendering
// ===================================
function renderList(items) {
    listContainer.innerHTML = '';

    if (!items || items.length === 0) {
        listContainer.innerHTML = '<div class="empty-state">No active downloads</div>';
        return;
    }

    items.forEach(item => {
        const div = document.createElement('div');
        div.className = 'download-item';

        // 0=Queued, 1=Queued, 2=Extracting, 3=Downloading, 4=Completed, 5=Failed, ...
        const statusMap = ['Queued', 'Queued', 'Extracting', 'Downloading', 'Completed', 'Failed', 'Paused', 'Canceled', 'Duplicate'];
        const statusText = statusMap[item.status] || 'Processing';

        // Progress
        const progressPct = (item.progress * 100).toFixed(1);

        div.innerHTML = `
            <div class="item-row">
                <div class="item-title" title="${item.title || 'Loading...'}">${item.title || item.request?.url || 'Downloading...'}</div>
                <div class="item-status" style="color: ${item.status === 4 ? '#4CAF50' : '#AAA'}">${statusText}</div>
            </div>
            ${item.status === 3 || item.status === 2 ? `
            <div class="progress-bar">
                <div class="progress-fill" style="width: ${progressPct}%"></div>
            </div>
            ` : ''}
            <div class="item-meta">
                <span>${item.totalSize || ''}</span>
                <span>${item.speed || ''}</span>
            </div>
        `;
        listContainer.appendChild(div);
    });
}

// Initial List Load
chrome.storage.local.get(['recentDownloads'], (result) => {
    renderList(result.recentDownloads || []);
});

// Real-time Updates
chrome.storage.onChanged.addListener((changes, area) => {
    if (area === 'local' && changes.recentDownloads) {
        renderList(changes.recentDownloads.newValue);
    }
});
