import { Bar } from "./bar.js"
const hyprland = await Service.import("hyprland")

function getWindowMonitorID(window) {
    const match = window.name.match(/^bar-(\d+)$/);
    return match ? parseInt(match[1], 10) : null;
}

hyprland.connect('monitor-added', () => {
    const currentMonitorIDs = hyprland.monitors.map(monitor => monitor.id);
    currentMonitorIDs.forEach(id => {
      if (!App.windows.some(window => window.name === `bar-${id}`)) {
        App.add_window(Bar(id))
      }
    })
});

hyprland.connect('monitor-removed', () => {
    const currentMonitorIDs = hyprland.monitors.map(monitor => monitor.id);

    App.windows.forEach(window => {
        const barID = getWindowMonitorID(window)

        if (barID != null && !currentMonitorIDs.includes(barID)) {
            App.removeWindow(window);
        }
    });
});


App.config({
  style: "./style.css",
  windows: [
    ...hyprland.monitors.map((monitor) => Bar(monitor.id)),
  ]
});

export { }
