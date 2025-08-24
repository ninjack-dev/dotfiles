import { Variable, GLib, bind } from "astal"
import { Astal, Gtk, Gdk } from "astal/gtk3"
import Hyprland from "gi://AstalHyprland"
import Battery from "gi://AstalBattery"
import Wp from "gi://AstalWp"
import Tray from "gi://AstalTray"
import GlobalShortcuts from "../services/GlobalShortcuts"

// TODO
// Make this a menu with multiple options for editing, rebuilding, etc.
function NixEdit() {
  return <box className="NixEdit">
    <icon
      icon="nix-snowflake"
    />
  </box>
}

function SysTray() {
  const tray = Tray.get_default()

  return <box className="SysTray">
    {bind(tray, "items").as(items => items.map(item => (
      <menubutton
        tooltipMarkup={bind(item, "tooltipMarkup")}
        usePopover={false}
        actionGroup={bind(item, "actionGroup").as(ag => ["dbusmenu", ag])}
        menuModel={bind(item, "menuModel")}>
        <icon gicon={bind(item, "gicon")} />
      </menubutton>
    )))}
  </box>
}

// function Wifi() {
//   const network = Network.get_default()
//   const wifi = bind(network, "wifi")
//
//   return <box visible={wifi.as(Boolean)}>
//     {wifi.as(wifi => wifi && (
//       <icon
//         tooltipText={bind(wifi, "ssid").as(String)}
//         className="Wifi"
//         icon={bind(wifi, "iconName")}
//       />
//     ))}
//   </box>
//
// }

function AudioSlider() {
  const speaker = Wp.get_default()?.audio.defaultSpeaker!

  return <box className="AudioSlider" css="min-width: 140px">
    <icon icon={bind(speaker, "volumeIcon")} />
    <slider
      hexpand
      onDragged={({ value }) => speaker.volume = value}
      value={bind(speaker, "volume")}
    />
  </box>
}

// TODO:
// - Make the submap indicator slide in from the right-hand side instead of popping into existence
function Submap() {
  const hypr = Hyprland.get_default();

  let current = hypr.message("submap").trim()
  current = current === "default" ? "" : current;

  const submapVar = new Variable(current);
  hypr.connect('submap', (_, name) => {
    submapVar.set(name);
  });
  const submap = bind(submapVar);

  // Assumes submap is in form `submap_mode`
  function normalizeSubmapName(str: string) {
    return str
      .replace("mode", "")
      .toLowerCase()
      .split('_')
      .map((s) => s.charAt(0).toUpperCase() + s.substring(1))
      .join(' ')
  }

  return <box visible={submap.as(s => s !== "")}>
    <label label={submap.as(s => " " + normalizeSubmapName(s))} />
  </box>
}

function BatteryLevel() {
  const bat = Battery.get_default()

  return <box className="Battery"
    visible={bind(bat, "isPresent")}>
    <icon icon={bind(bat, "batteryIconName")} />
    <label label={bind(bat, "percentage").as(p =>
      `${Math.floor(p * 100)} %`
    )} />
  </box>
}

// function Media() {
//   const mpris = Mpris.get_default()
//
//   return <box className="Media">
//     {bind(mpris, "players").as(ps => ps[0] ? (
//       <box>
//         <box
//           className="Cover"
//           valign={Gtk.Align.CENTER}
//           css={bind(ps[0], "coverArt").as(cover =>
//             `background-image: url('${cover}');`
//           )}
//         />
//         <label
//           label={bind(ps[0], "metadata").as(() =>
//             `${ps[0].title} - ${ps[0].artist}`
//           )}
//         />
//       </box>
//     ) : (
//       <label label="Nothing Playing" />
//     ))}
//   </box>
// }

function Workspaces({ monitor }: { monitor: Gdk.Monitor }) {
  const hypr = Hyprland.get_default()
  const shortcutManager = GlobalShortcuts.get_session();
  const super_key = shortcutManager.getShortcut('Super');

  return <box className="Workspaces">
    {bind(hypr, "workspaces").as(wss => wss
      .filter(ws => !(ws.id >= -99 && ws.id <= -2)) // filter out special workspaces
      .sort((a, b) => a.id - b.id)
      .map(ws => {
        const label: Variable<string> = Variable.derive(
          [bind(ws, "name"), bind(super_key!, 'activated')],
          (wsname: string, super_held: boolean) => {
            if (super_held || wsname == '')
              return `${ws.id}`
            return `${wsname}`
          }
        );

        // The following uses the hacky name comparison which will be fixed in Gtk4
        const workspaceClass: Variable<string> = Variable.derive(
          [bind(hypr, "focusedWorkspace"), bind(ws, "monitor")],
          (focusedWorkspace, thisWorkspaceMonitor) => {
            if (ws === focusedWorkspace)
              return "focused"
            else if (thisWorkspaceMonitor.get_model() === monitor.get_model() && thisWorkspaceMonitor.active_workspace === ws)
              return "visible"
            else return ""
          }
        )

        return (
          <button
            className={bind(workspaceClass).as((a) => a)}
            onClicked={() => ws.focus()}>
            {bind(label).as(v => v)}
          </button>
        )
      })
    )}

  </box>
}

function FocusedClient() {
  const hypr = Hyprland.get_default()
  const focused = bind(hypr, "focusedClient")

  return <box
    className="Focused"
    visible={focused.as(Boolean)}>
    {focused.as(client => (
      client && <label label={bind(client, "title").as(String)} />
    ))}
  </box>
}

function Time({ format = "%H:%M - %A %e." }) {
  const time = Variable<string>("").poll(1000, () =>
    GLib.DateTime.new_now_local().format(format)!)

  return <label
    className="Time"
    onDestroy={() => time.drop()}
    label={time()}
  />
}

export default function Bar(monitor: Gdk.Monitor) {
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return <window
    className="Bar"
    gdkmonitor={monitor}
    exclusivity={Astal.Exclusivity.EXCLUSIVE}
    anchor={TOP | LEFT | RIGHT}>
    <centerbox>
      <box hexpand halign={Gtk.Align.START}>
        <NixEdit />
        <Workspaces monitor={monitor} />
        <FocusedClient />
      </box>
      <box>
      </box>
      <box hexpand halign={Gtk.Align.END} >
        <SysTray />
        <AudioSlider />
        <BatteryLevel />
        <Time />
        <Submap />
      </box>
    </centerbox>
  </window>
}
