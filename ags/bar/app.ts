import { App, Gdk, Gtk } from "astal/gtk3"
import style from "./style.scss"
import GlobalShortcuts, { GlobalShortcut } from "./services/GlobalShortcuts"
import Bar from "./widget/Bar"


async function main() {
  const bars = new Map<Gdk.Monitor, Gtk.Widget>()
  const shortcutManager = GlobalShortcuts.get_session();
  await shortcutManager.bindShortcuts(
    new GlobalShortcut('Super'),
  );

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

