var _extends = Object.assign || function (target) { for (var i = 1; i < arguments.length; i++) { var source = arguments[i]; for (var key in source) { if (Object.prototype.hasOwnProperty.call(source, key)) { target[key] = source[key]; } } } return target; };

var createVNode = Inferno.createVNode;

function Tab(props) {
    let className = "tab";
    if (!props.active) {
        className += " inactive";
    }
    return createVNode(2, "li", className, props.title);
}

function TabList(props) {
    return createVNode(2, "ul", "tabs", props.tabs.map(tab => createVNode(16, Tab, null, null, _extends({}, tab))));
}

function render(tabs) {
    Inferno.render(createVNode(2, "div", null, createVNode(16, TabList, null, null, {
        "tabs": tabs
    })), document.getElementById("output"));
};

window.update = function () {
    log("update");
    getData().then(render);
};

update();