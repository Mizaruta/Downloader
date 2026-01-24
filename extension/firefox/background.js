// background.js (service worker pour Firefox V3)

// Crée le menu contextuel quand l'extension est installée
chrome.runtime.onInstalled.addListener(() => {
    chrome.contextMenus.create({
        id: "send-to-downloader",
        title: "Download with Modern Downloader",
        contexts: ["link", "page", "selection"]
    });
});

// Gère le clic sur le menu contextuel
chrome.contextMenus.onClicked.addListener((info, tab) => {
    if (info.menuItemId === "send-to-downloader") {
        let url = info.linkUrl || info.pageUrl || info.selectionText;
        if (url) {
            const protocolUrl = "moderndownloader://open?url=" + encodeURIComponent(url);
            // Ouvre un nouvel onglet pour déclencher le protocole
            chrome.tabs.create({ url: protocolUrl });
        }
    }
});

// Gère le clic sur l'icône de l'extension
chrome.action.onClicked.addListener((tab) => {
    if (tab.url && !tab.url.startsWith("about:") && !tab.url.startsWith("chrome://")) {
        const protocolUrl = "moderndownloader://open?url=" + encodeURIComponent(tab.url);
        chrome.tabs.create({ url: protocolUrl });
    }
});
