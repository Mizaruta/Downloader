// Modern Downloader Content Script (Premium)
// Scans for videos and links to add permanent, customizable download buttons with quality selection.

const PROCESSED = new WeakSet();
const VIDEO_PATTERNS = [
    '/video-', '/watch?v=', '/reels/', '/reel/', '/status/',
    '/view_video.php', '/video_view', '/play/', '/v/', '/view/', '/watch/',
    'tiktok.com', 'instagram.com/p/', 'x.com/status'
];

// Default Settings
let SETTINGS = {
    btnColor: '#6C5DD3', // Modern Purple
    btnPosition: 'top-right', // top-right, top-left, bottom-right, bottom-left
    btnSize: 'normal', // small, normal, large
    showQualitySelector: true
};

// Load settings
chrome.storage.sync.get(['btnColor', 'btnPosition', 'btnSize'], (items) => {
    if (items.btnColor) SETTINGS.btnColor = items.btnColor;
    if (items.btnPosition) SETTINGS.btnPosition = items.btnPosition;
    if (items.btnSize) SETTINGS.btnSize = items.btnSize;
});

// Helper: Find platform specific URL
function findPlatformSpecificUrl(element) {
    const hostname = window.location.hostname;
    const pageUrl = window.location.href;

    // ... (Existing logic for finding URL) ...
    const findNearestPermalink = (el) => {
        if (el.tagName === 'A' && el.href && VIDEO_PATTERNS.some(p => el.href.includes(p))) {
            return el.href.split('?')[0];
        }
        let curr = el.parentElement;
        let depth = 0;
        while (curr && depth < 8) {
            if (curr.tagName === 'A' && curr.href && VIDEO_PATTERNS.some(p => curr.href.includes(p)) && !curr.href.includes('preview')) {
                return curr.href.split('?')[0];
            }
            curr = curr.parentElement;
            depth++;
        }
        return null;
    };

    if (element.tagName === 'VIDEO') {
        const deepLink = findNearestPermalink(element);
        if (deepLink) return deepLink;
        let mediaUrl = element.currentSrc || element.src;
        if (mediaUrl && !mediaUrl.startsWith('blob:') && !mediaUrl.includes('preview')) {
            return mediaUrl;
        }
    } else if (element.tagName === 'A') {
        return element.href.split('?')[0];
    }

    // Fallback to page URL if specifically on a video page
    if (VIDEO_PATTERNS.some(p => pageUrl.includes(p))) return pageUrl.split('?')[0];

    return null; // Return null if not sure, to avoid spamming buttons on non-video pages
}

function createButtonUI(targetUrl) {
    const wrapper = document.createElement('div');
    wrapper.className = 'md-btn-wrapper';

    // Positioning styles based on settings
    Object.assign(wrapper.style, {
        position: 'absolute',
        zIndex: '2147483647', // Max Z-Index
        display: 'flex',
        alignItems: 'center',
        fontFamily: "'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
        gap: '2px',
        gap: '2px',
        opacity: '1', // Always visible
        transition: 'opacity 0.2s ease',
        pointerEvents: 'auto' // Always clickable
    });

    // Handle position
    const offset = '8px';
    if (SETTINGS.btnPosition === 'top-right') { wrapper.style.top = offset; wrapper.style.right = offset; }
    else if (SETTINGS.btnPosition === 'top-left') { wrapper.style.top = offset; wrapper.style.left = offset; }
    else if (SETTINGS.btnPosition === 'bottom-right') { wrapper.style.bottom = offset; wrapper.style.right = offset; }
    else if (SETTINGS.btnPosition === 'bottom-left') { wrapper.style.bottom = offset; wrapper.style.left = offset; }

    // Main Button
    const btn = document.createElement('button');
    btn.innerHTML = `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg> Download`;

    // Style
    const basePadding = SETTINGS.btnSize === 'small' ? '4px 8px' : '6px 12px';
    const fontSize = SETTINGS.btnSize === 'small' ? '11px' : '13px';

    Object.assign(btn.style, {
        backgroundColor: SETTINGS.btnColor,
        color: 'white',
        border: 'none',
        borderRadius: '6px 0 0 6px',
        padding: basePadding,
        fontSize: fontSize,
        fontWeight: '600',
        cursor: 'pointer',
        boxShadow: '0 4px 12px rgba(0,0,0,0.3)',
        display: 'flex',
        alignItems: 'center',
        gap: '6px',
        pointerEvents: 'auto'
    });

    if (!SETTINGS.showQualitySelector) btn.style.borderRadius = '6px';

    // Dropdown Toggle
    let toggle = null;
    let dropdown = null;
    let selectedQuality = 'best'; // default

    if (SETTINGS.showQualitySelector) {
        toggle = document.createElement('button');
        toggle.innerHTML = `<svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"></polyline></svg>`;
        Object.assign(toggle.style, {
            backgroundColor: SETTINGS.btnColor,
            filter: 'brightness(0.9)', // Slightly darker
            color: 'white',
            border: 'none',
            borderLeft: '1px solid rgba(255,255,255,0.2)',
            borderRadius: '0 6px 6px 0',
            padding: basePadding,
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            height: '100%',
            pointerEvents: 'auto',
            boxShadow: '2px 0 12px rgba(0,0,0,0.1)'
        });

        // Dropdown Menu
        dropdown = document.createElement('div');
        Object.assign(dropdown.style, {
            position: 'absolute',
            top: '100%',
            right: '0',
            marginTop: '0px', // Remove gap to prevent mouseleave
            backgroundColor: '#1E1E24',
            borderRadius: '6px',
            boxShadow: '0 4px 20px rgba(0,0,0,0.5)',
            border: '1px solid #333',
            display: 'none',
            flexDirection: 'column',
            overflow: 'hidden',
            minWidth: '120px',
            pointerEvents: 'auto'
        });

        const options = [
            { label: 'Best Quality', val: 'best' },
            { label: '1080p', val: '1080p' },
            { label: '720p', val: '720p' },
            { label: 'Audio Only', val: 'audio' }
        ];

        options.forEach(opt => {
            const item = document.createElement('div');
            item.textContent = opt.label;
            Object.assign(item.style, {
                padding: '8px 12px',
                color: '#EEE',
                fontSize: '12px',
                cursor: 'pointer',
                transition: 'background 0.1s'
            });
            item.onmouseenter = () => item.style.backgroundColor = SETTINGS.btnColor;
            item.onmouseleave = () => item.style.backgroundColor = 'transparent';
            item.onclick = (e) => {
                e.stopPropagation();
                selectedQuality = opt.val;
                btn.innerHTML = selectedQuality === 'audio'
                    ? `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 18V5l12-2v13"></path><circle cx="6" cy="18" r="3"></circle><circle cx="18" cy="16" r="3"></circle></svg> Audio`
                    : `<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg> ${opt.label}`;
                dropdown.style.display = 'none';
            };
            dropdown.appendChild(item);
        });

        wrapper.appendChild(dropdown);
    }

    // Logic
    btn.onclick = (e) => {
        console.log("Download button clicked!");
        e.preventDefault();
        e.stopPropagation();

        const opts = {};
        if (selectedQuality === 'audio') opts.isAudioOnly = true;
        else if (selectedQuality !== 'best') opts.preferredQuality = selectedQuality;

        chrome.runtime.sendMessage({
            type: 'DOWNLOAD_BTN_CLICK',
            url: targetUrl,
            pageUrl: window.location.href,
            options: opts
        });

        const originalText = btn.innerHTML;
        btn.innerHTML = 'Sent!';
        btn.style.backgroundColor = '#4CAF50';
        if (toggle) toggle.style.backgroundColor = '#4CAF50';

        setTimeout(() => {
            btn.innerHTML = originalText;
            btn.style.backgroundColor = SETTINGS.btnColor;
            if (toggle) toggle.style.backgroundColor = SETTINGS.btnColor;
        }, 2000);
    };

    if (toggle) {
        toggle.onclick = (e) => {
            e.preventDefault();
            e.stopPropagation();
            const isOpen = dropdown.style.display === 'flex';
            dropdown.style.display = isOpen ? 'none' : 'flex';
            // Clear any pending close timer if we manually toggle
            if (wrapper._closeTimer) clearTimeout(wrapper._closeTimer);
        };

        // Robust hover handling with delay
        wrapper.onmouseenter = () => {
            if (wrapper._closeTimer) clearTimeout(wrapper._closeTimer);
        };

        wrapper.onmouseleave = () => {
            wrapper._closeTimer = setTimeout(() => {
                dropdown.style.display = 'none';
            }, 500); // 500ms grace period
        };

        // Ensure jumping from button to dropdown clears timer
        dropdown.onmouseenter = () => {
            if (wrapper._closeTimer) clearTimeout(wrapper._closeTimer);
        };
    }

    wrapper.appendChild(btn);
    if (toggle) wrapper.appendChild(toggle);

    return wrapper;
}

function injectButton(container, targetUrl) {
    if (PROCESSED.has(container)) return;

    const style = window.getComputedStyle(container);
    if (style.position === 'static') {
        container.style.position = 'relative';
    }

    const ui = createButtonUI(targetUrl);
    container.appendChild(ui);
    PROCESSED.add(container);

    // Always visible
    ui.style.opacity = '1';
    ui.style.pointerEvents = 'auto';
}

function scan() {
    // 1. Videos
    document.querySelectorAll('video').forEach(video => {
        if (!video.parentElement) return;
        const url = findPlatformSpecificUrl(video);
        if (url) injectButton(video.parentElement, url);
    });

    // 2. Thumbnails (Aggressive scan)
    document.querySelectorAll('a').forEach(a => {
        if (PROCESSED.has(a)) return;
        const href = a.href;
        if (href && VIDEO_PATTERNS.some(p => href.includes(p))) {
            // Basic heuristic
            const rect = a.getBoundingClientRect();
            if (rect.width > 100 && rect.height > 60) {
                const url = href.split('?')[0];
                injectButton(a, url);
            }
        }
    });
}

// Initial
scan();
setInterval(scan, 2000);

// Observer
const observer = new MutationObserver((mutations) => {
    if (mutations.length > 0) scan();
});
observer.observe(document.body, { childList: true, subtree: true });
