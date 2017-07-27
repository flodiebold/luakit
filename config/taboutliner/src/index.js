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
    return <li className={className}>{props.title}</li>;
}

function TabList(props) {
    return (
        <ul className="tabs">
          {props.tabs.map(tab => <Tab {...tab} />)}
        </ul>
    );
}

function render(data) {
    log("render", state.selected);
    Inferno.render(
        <div>
          <TabList {...data} />
        </div>,
        document.getElementById("output")
    );
};

window.update = function() {
    log("update")
    getData().then(render).catch(err => console.error(err));
};

function command(name, handler) {
    window[name] = function() {
        getData().then(handler).catch(err => {
            log(`An error occurred in command ${name}: ${err}`);
            console.error(err);
        });
    }
}

command("next", data => {
    let currentIndex = _.findIndex(data.tabs, tab => tab.uid === state.selected);
    let nextIndex = (currentIndex === -1 || currentIndex === data.tabs.length - 1) ? 0 : currentIndex + 1;
    if (nextIndex < data.tabs.length) {
        console.log(data.tabs[nextIndex]);
        state.selected = data.tabs[nextIndex].uid;
        render(data);
    }
});

command("previous", data => {
    let currentIndex = _.findIndex(data.tabs, tab => tab.uid === state.selected);
    let previousIndex = (currentIndex === -1 || currentIndex === 0) ? data.tabs.length - 1 : currentIndex - 1;
    if (previousIndex >= 0) {
        state.selected = data.tabs[previousIndex].uid;
        render(data);
    }
});

update();
