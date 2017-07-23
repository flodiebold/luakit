
function Tab(props) {
    let className = "tab";
    if (!props.active) {
        className += " inactive";
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

function render(tabs) {
    Inferno.render(
        <div>
          <TabList tabs={tabs} />
        </div>,
        document.getElementById("output")
    );
};

window.update = function() {
    log("update")
    getData().then(render);
};

update();
