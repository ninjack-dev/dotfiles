import Gio from "gi://Gio"
import GLib from "gi://GLib"

// ChatGPT function
function readXmlFile(filePath) {
  try {
    // Create a Gio.File instance for the file path
    let file = Gio.File.new_for_path(filePath);

    // Read the contents of the file
    let [success, contents, _] = file.load_contents(null);

    if (success) {
      // Convert the contents (a GLib.Bytes) to a string
      let xmlString = imports.byteArray.toString(contents);
      return xmlString;
    } else {
      throw new Error("Failed to read the file contents.");
    }
  } catch (e) {
    logError(e, "Error reading XML file");
    return null;
  }
}

const SHORTCUT_INTERFACE_XML = readXmlFile('./org.freedesktop.portal.GlobalShortcuts.xml')
const globalShortcutProxyWrapper = Gio.DBusProxy.makeProxyWrapper(SHORTCUT_INTERFACE_XML);

let shortcutProxy

try {
  shortcutProxy = globalShortcutProxyWrapper(
    Gio.DBus.session,
    'org.freedesktop.portal.Desktop',
    '/org/freedesktop/portal/desktop');
} catch (e) { print(e) }

// https://gjs-docs.gnome.org/gio20~2.0/gio.dbusconnection#method-signal_subscribe 
const handlerId = Gio.DBus.session.signal_subscribe(
  null, // Owner (":1.8" on my system for now. Do I need to handle this?)
  'org.freedesktop.portal.Request',
  'Response',
  null,
  null,
  Gio.DBusSignalFlags.NONE, // no flags
  (connection, sender, path, iface, signal, params) => {
    console.log("Connection:", connection, "\nSender:", sender, "\nPath:", path, "\nInterface:", iface, "\nSignal:", signal, "\nParams:", params.recursiveUnpack());
    try {
      const sessionHandle = params.get_child_value(1).recursiveUnpack().session_handle;
      shortcutProxy.BindShortcutsSync(
        sessionHandle,
        [ // Top level array packer
          [ // Shortcut tuple packer
            "An Action",
            {
              description: GLib.Variant.new_string('some keybind I guess'),
            },
          ],
          [ // Shortcut tuple packer
            "Another Action",
            {
              description: GLib.Variant.new_string('some other keybind'),
            },
          ],
        ],
        '', // Hyprland doesn't have a shortcut registration popup for us to take advantage of, so we pass no window handle
        {
          handle_token: GLib.Variant.new_string('Astal1'),
        });
    } catch (e) { print(e); }
  }
);

const requestPath = shortcutProxy.CreateSessionSync({
  'handle_token': GLib.Variant.new_string('Astal'),
  'session_handle_token': GLib.Variant.new_string('Astal1')
})[0];

const ActivatedhandlerId = shortcutProxy.connectSignal('Activated', (_proxy, nameOwner, args) => {
    console.log(`Activated: ${args}`);
});

let loop = GLib.MainLoop.new(null, false);
loop.run();
