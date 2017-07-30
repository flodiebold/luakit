const state = {
    selected: null
};

function Tab(props) {
    let className = "tab";
    if (!props.active) {
        className += " inactive";
    }
    if (props.uid === state.selected) {
        className += " selected";
    }
    if (props.subtree && props.subtree.length > 0) console.log("tab has subtree:", props);
    return (
        <li className="tab-subtree">
          <div className={className}>
            {props.title}
          </div>
          {props.subtree && props.subtree.length > 0 && <TabList subtree={true} tabs={props.subtree} />}
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
            console.log("first", first);
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
            log(`An error occurred in command ${name}: ${err}`);
            console.error(err);
        });
    }
}

function* visibleTabs(tabs) {
    for (let tab of tabs) {
        console.log("visible tab:", tab);
        yield tab;
        if (tab.children && tab.children.length > 0) {
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
