import { Bar } from "./bar.js"
import { NotificationPopups } from "./notificationPopups.js"
const hyprland = await Service.import("hyprland")

Utils.timeout(100, () => Utils.notify({
    summary: "Notification Popup Example",
    iconName: "info-symbolic",
    body: "Lorem ipsum dolor sit amet, qui minim labore adipisicing "
        + "minim sint cillum sint consectetur cupidatat.",
    actions: {
        "Cool": () => print("pressed Cool"),
    },
}))

/**
 * @param {import("types/@girs/gtk-3.0/gtk-3.0.js").Gtk.Window} window
 */
function getWindowMonitorID(window) {
    const match = window.name?.match(/^bar-(\d+)$/);
    return match ? parseInt(match[1], 10) : null;
}

hyprland.connect('monitor-added', () => {
    const currentMonitorIDs = hyprland.monitors.map(monitor => monitor.id);
    currentMonitorIDs.forEach(id => {
      if (!App.windows.some(window => window.name === `bar-${id}`)) {
        App.add_window(Bar(id))
      }
      if (!App.windows.some(window => window.name === `notifications-${id}`)) {
        App.add_window(NotificationPopups(id))
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
    ...hyprland.monitors.flatMap((monitor) => [Bar(monitor.id), NotificationPopups(monitor.id)]),
  ]
});

export { }
