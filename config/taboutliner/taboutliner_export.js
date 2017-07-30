function exp() {
    const tree = getTreeModel()[0];

    let nextUid = -1;

    function convertNode(node) {
        const uid = nextUid--;
        const subnodes = node.subnodes.map(convertNode);
        const tab = {
            uri: null,
            uid: uid,
            collapsed: node.colapsed,
            favicon: node.chromeTabObj && node.chromeTabObj.favIconUrl,
            children: subnodes
        };
        switch (node.type) {
        case "win":
        case "savedwin":
            tab.title = node.marks.customTitle || "Window";
            tab.typ = "group";
            break;
        case "group":
            tab.title = node.marks.customTitle || "Group";
            tab.typ = "group";
            break;
        case "savedtab":
        case "tab":
            tab.title = node.marks.customTitle || node.chromeTabObj.title;
            tab.typ = "tab";
            tab.uri = node.chromeTabObj.url;
            break;
        }
        return tab;
    }

    const data = convertNode(tree).children;
    const blob = new Blob([JSON.stringify(data)], { type: "application/json" });
    const dataUrl = URL.createObjectURL(blob);
    // window.open(dataUrl);
    const link = document.createElement("a");
    link.setAttribute("href", dataUrl);
    link.setAttribute("download", "tabs.json");
    link.click(); // This will download the data file named "my_data.csv".
}
