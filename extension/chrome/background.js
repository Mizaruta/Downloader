chrome.runtime.onInstalled.addListener(() => {
    chrome.contextMenus.create({
        id: "send-to-downloader",
        title: "Download with Modern Downloader",
        contexts: ["link", "page", "selection"]
    });
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
    if (info.menuItemId === "send-to-downloader") {
        let url = info.linkUrl || info.pageUrl;
        if (url) {
            const protocolUrl = "moderndownloader://open?url=" + encodeURIComponent(url);
            // Create a tab to trigger the protocol handler, then usage depends on browser settings.
            // Some browsers might prompt the user to open the app.
            chrome.tabs.create({ url: protocolUrl });
        }
    }
});

chrome.action.onClicked.addListener((tab) => {
    if (tab.url && !tab.url.startsWith("chrome://")) {
        const protocolUrl = "moderndownloader://open?url=" + encodeURIComponent(tab.url);
        chrome.tabs.create({ url: protocolUrl });
    }
});
