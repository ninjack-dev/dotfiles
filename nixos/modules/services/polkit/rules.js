/* 
 * Documentation: https://www.freedesktop.org/software/polkit/docs/latest/polkit.8.html
 */

/* Don't require sudo for reboot/power-off */
polkit.addRule(function(action, subject) {
  if (
    subject.isInGroup("users") &&
    [
      "org.freedesktop.login1.reboot",
      "org.freedesktop.login1.reboot-multiple-sessions",
      "org.freedesktop.login1.power-off",
      "org.freedesktop.login1.power-off-multiple-sessions",
    ].indexOf(action.id) !== -1
  ) {
    return polkit.Result.YES;
  }
});
