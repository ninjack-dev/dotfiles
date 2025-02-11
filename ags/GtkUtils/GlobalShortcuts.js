import Gio from "gi://Gio"
import GLib from "gi://GLib"

let requestPath
let shortcutRegRequestPath


const callback = 
  (connection, sender, path, iface, signal, params) => {
    console.log(connection, sender, path, iface, signal,)
    for (let i in params.recursiveUnpack()) { i.toString() }

    if (path === requestPath) {
      Gio.DBus.session.signal_unsubscribe(handlerId);
      const sessionHandle = params.get_child_value(1).recursiveUnpack().session_handle;
      const shortcutRegistrationParameters = new GLib.Variant('(oa(sa{sv})sa{sv})', [ // Top level tuple packer for DBus
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
          handle_token: GLib.Variant.new_string('astal1'),
        },
      ]);

      shortcutRegRequestPath = Gio.DBus.session.call_sync(
        'org.freedesktop.portal.Desktop',
        '/org/freedesktop/portal/desktop',
        'org.freedesktop.portal.GlobalShortcuts',
        'BindShortcuts',
        shortcutRegistrationParameters,
        new GLib.VariantType('(o)'),       // The expected reply type
        Gio.DBusCallFlags.NONE,
        -1,
        null);

      Gio.DBus.session.signal_subscribe(
        null,
        'org.freedesktop.portal.GlobalShortcuts',
        'Activated',
        null,
        null, // no filter on sender
        Gio.DBusSignalFlags.NONE, // no flags
        (connection, sender, path, iface, signal, params) => {
          console.log("Activated:", params.recursiveUnpack())
        }
      )

      Gio.DBus.session.signal_subscribe(
        null,
        'org.freedesktop.portal.GlobalShortcuts',
        'Deactivated',
        null,
        null, // no filter on sender
        Gio.DBusSignalFlags.NONE, // no flags
        (connection, sender, path, iface, signal, params) => {
          console.log("Deactivated:", params.recursiveUnpack())
        }
      )
    }
  }

const handlerId = Gio.DBus.session.signal_subscribe( // https://gjs-docs.gnome.org/gio20~2.0/gio.dbusconnection#method-signal_subscribe 
  null, // I've had issues finding the right interface/object to connect to
  null,
  'Response',
  null,
  null,
  Gio.DBusSignalFlags.NONE, // no flags
  callback
);

const sessionValues = new GLib.Variant('(a{sv})', [{
  handle_token: GLib.Variant.new_string('astal'),
  session_handle_token: GLib.Variant.new_string('Astal1'),
}]);

requestPath = Gio.DBus.session.call_sync(
  'org.freedesktop.portal.Desktop',
  '/org/freedesktop/portal/desktop',
  'org.freedesktop.portal.GlobalShortcuts',
  'CreateSession',
  sessionValues, // The method arguments
  new GLib.VariantType('(o)'),       // The expected reply type
  //GLib.VariantType, // This doesn't work, not sure why.
  Gio.DBusCallFlags.NONE,
  -1,
  null).get_child_value(0).unpack();

let loop = GLib.MainLoop.new(null, false);
loop.run();
console.error("DARN");
