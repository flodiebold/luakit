var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

const state = {
    selected: null
};

var createVNode = Inferno.createVNode;
function Tab(props) {
    let className = "tab";
    if (!props.active) {
        className += " inactive";
    }
    if (props.uid === state.selected) {
        className += " selected";
    }
    return createVNode(2, "li", className, props.title);
}

function TabList(props) {
    return createVNode(2, "ul", "tabs", props.tabs.map(tab => createVNode(16, Tab, null, null, _extends({}, tab))));
}

function render(data) {
    log("render", state.selected);
    Inferno.render(createVNode(2, "div", null, createVNode(16, TabList, null, null, _extends({}, data))), document.getElementById("output"));
};

window.update = function () {
    log("update");
    getData().then(render).catch(err => console.error(err));
};

function command(name, handler) {
    window[name] = function () {
        getData().then(handler).catch(err => {
            log(`An error occurred in command ${name}: ${err}`);
            console.error(err);
        });
    };
}

command("next", data => {
    let currentIndex = _.findIndex(data.tabs, tab => tab.uid === state.selected);
    let nextIndex = currentIndex === -1 || currentIndex === data.tabs.length - 1 ? 0 : currentIndex + 1;
    if (nextIndex < data.tabs.length) {
        console.log(data.tabs[nextIndex]);
        state.selected = data.tabs[nextIndex].uid;
        render(data);
    }
});

command("previous", data => {
    let currentIndex = _.findIndex(data.tabs, tab => tab.uid === state.selected);
    let previousIndex = currentIndex === -1 || currentIndex === 0 ? data.tabs.length - 1 : currentIndex - 1;
    if (previousIndex >= 0) {
        state.selected = data.tabs[previousIndex].uid;
        render(data);
    }
});

window.getSelected = function () {
    return state.selected;
};

update();