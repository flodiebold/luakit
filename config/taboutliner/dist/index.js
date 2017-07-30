var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

const state = {
    selected: null,
    collapsed: new Set()
};

var createVNode = Inferno.createVNode;
function Tab(props) {
    let className = "tab";
    if (!props.active) {
        className += " inactive";
    }
    let ref;
    if (props.uid === state.selected) {
        className += " selected";
        ref = elem => {
            // make sure the element is scrolled into view
            if (elem) {
                const rect = elem.getBoundingClientRect();
                if (rect.top < 0) {
                    elem.scrollIntoView(true);
                } else if (rect.bottom > window.innerHeight) {
                    elem.scrollIntoView(false);
                }
            }
        };
    }
    const hasSubtree = props.subtree && props.subtree.length > 0;
    return createVNode(2, "li", "tab-subtree", [createVNode(2, "div", className, [props.title, hasSubtree && props.collapsed && createVNode(2, "span", "ellipsis", "(...)")], null, null, ref), hasSubtree && !props.collapsed && createVNode(16, TabList, null, null, {
        "subtree": true,
        "tabs": props.subtree
    })]);
}

function TabList(props) {
    let className = "tabs ";
    if (props.subtree) {
        className += "subtree";
    }
    return createVNode(2, "ul", className, props.tabs.map(tab => createVNode(16, Tab, null, null, _extends({}, tab, {
        "subtree": tab.children
    }))));
}

function render(data) {
    Inferno.render(createVNode(2, "div", null, createVNode(16, TabList, null, null, _extends({}, data))), document.getElementById("output"));
};

function selectDefault(data) {
    if (state.selected === null) {
        const first = visibleTabs(data.tabs).next().value;
        if (first) {
            state.selected = first.uid;
        }
    }
    return data;
}

window.update = function () {
    getData().then(selectDefault).then(render).catch(err => console.error(err));
};

function command(name, handler) {
    window[name] = function (...args) {
        getData().then(data => handler(data, ...args)).catch(err => {
            print(`An error occurred in command ${name}: ${err}`);
            console.error(err);
        });
    };
}

function* visibleTabs(tabs) {
    for (let tab of tabs) {
        yield tab;
        if (tab.children && tab.children.length > 0 && !tab.collapsed) {
            yield* visibleTabs(tab.children);
        }
    }
}

command("next", (data, count = 1) => {
    let currentFound = false;
    let last = null;
    for (let tab of visibleTabs(data.tabs)) {
        if (currentFound && count <= 1) {
            state.selected = tab.uid;
            break;
        } else if (currentFound) {
            count--;
        } else {
            currentFound = tab.uid === state.selected;
        }
        last = tab;
    }
    if (count > 1 && last !== null) {
        state.selected = last.uid;
    }
    render(data);
});

command("previous", (data, count = 1) => {
    const recent = [];
    for (let tab of visibleTabs(data.tabs)) {
        recent.unshift(tab);
        if (tab.uid === state.selected) {
            let target;
            if (recent.length > count) {
                target = recent[count];
            } else {
                target = recent[recent.length - 1];
            }
            if (target) {
                state.selected = target.uid;
            }
            break;
        }
    }
    render(data);
});

window.getSelected = function () {
    return state.selected;
};

update();