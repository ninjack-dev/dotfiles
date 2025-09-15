import { App, Gdk, Gtk } from "astal/gtk3"
import style from "./style.scss"
import GlobalShortcuts, { GlobalShortcut } from "./services/GlobalShortcuts"
import Bar from "./widget/Bar"


async function main() {
  print("Got here")
  const bars = new Map<Gdk.Monitor, Gtk.Widget>()
  const shortcutManager = GlobalShortcuts.get_session();
  // TEMPORARY FIX
  // Since updating to xdg-desktop-portal-hyprland 1.3.10, global shortcuts seem to be broken outright, along with screensharing. 
  // Apparently people have had issues with it: https://github.com/hyprwm/Hyprland/discussions/10351#discussioncomment-14397830
  // Notably for me, though, it just seems to crash at startup:
  // [CRITICAL] Couldn't connect to a wayland compositor
  try {
    await shortcutManager.bindShortcuts(
      new GlobalShortcut('Super'),
    );
  }
  catch (e) {
    print(e)
  }

  for (const gdkmonitor of App.get_monitors()) {
    bars.set(gdkmonitor, Bar(gdkmonitor))
  }

  App.connect("monitor-added", (_, gdkmonitor) => {
    bars.set(gdkmonitor, Bar(gdkmonitor))
  })

  App.connect("monitor-removed", (_, gdkmonitor) => {
    bars.get(gdkmonitor)?.destroy()
    bars.delete(gdkmonitor)
  })
}

App.start({
  css: style,
  instanceName: "bar",
  requestHandler(request, res) {
    print(request)
    res("ok")
  },
  main: main,
})

