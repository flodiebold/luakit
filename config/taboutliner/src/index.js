const state = {
    selected: null,
    collapsed: new Set()
};

function Tab(props) {
    let className = "tab";
    if (!props.active) {
        className += " inactive";
    }
    let ref;
    if (props.uid === state.selected) {
        className += " selected";
        ref = (elem) => {
            // make sure the element is scrolled into view
            if (elem) {
                const rect = elem.getBoundingClientRect();
                if (rect.top < 0) {
                    elem.scrollIntoView(true);
                } else if (rect.bottom > window.innerHeight) {
                    elem.scrollIntoView(false);
                }
            }
        }
    }
    const hasSubtree = props.subtree && props.subtree.length > 0;
    return (
        <li className="tab-subtree">
          <div className={className} ref={ref}>
            {props.title}
            {props.comment && <span className="comment"> ~ {props.comment}</span>}
            {hasSubtree && props.collapsed && <span className="ellipsis">(...)</span>}
          </div>
          {hasSubtree && !props.collapsed && <TabList subtree={true} tabs={props.subtree} />}
        </li>
    );
}

function TabList(props) {
    let className = "tabs ";
    if (props.subtree) {
        className += "subtree";
    }
    return (
        <ul className={className}>
          {props.tabs.map(tab => <Tab {...tab} subtree={tab.children} />)}
        </ul>
    );
}

function render(data) {
    Inferno.render(
        <div>
          <TabList {...data} />
        </div>,
        document.getElementById("output")
    );
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

window.update = function() {
    getData().then(selectDefault).then(render).catch(err => console.error(err));
};

function command(name, handler) {
    window[name] = function(...args) {
        getData().then(data => handler(data, ...args)).catch(err => {
            print(`An error occurred in command ${name}: ${err}`);
            console.error(err);
        });
    }
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

window.getSelected = function() {
    return state.selected;
}

update();
