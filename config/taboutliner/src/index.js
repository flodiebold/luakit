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

window.next = function() {
    getData().then(data => {
        let currentIndex = null;
        for (let i = 0; i < data.tabs.length; ++i) {
            if (data.tabs[i].uid === state.selected) {
                currentIndex = i;
                break;
            }
        }
        console.log("current index", currentIndex);
        let nextIndex = (currentIndex === null || currentIndex === data.tabs.length - 1) ? 0 : currentIndex + 1;
        console.log("next index", nextIndex);
        if (nextIndex < data.tabs.length) {
            console.log(data.tabs[nextIndex]);
            state.selected = data.tabs[nextIndex].uid;
            render(data);
        }
    }).catch(err => console.error(err));
}

window.previous = function() {
    getData().then(data => {
        let currentIndex = null;
        for (let i = 0; i < data.tabs.length; ++i) {
            if (data.tabs[i].uid === state.selected) {
                currentIndex = i;
            }
        }
        let previousIndex = (currentIndex === null || currentIndex === 0) ? data.tabs.length - 1 : currentIndex - 1;
        if (previousIndex >= 0) {
            state.selected = data.tabs[previousIndex].uid;
            render(data);
        }
    }).catch(err => console.error(err));
}

update();
