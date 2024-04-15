import Gdk from "gi://Gdk";
import Bar from "./bar";
import Gio from "gi://Gio";
import GLib from "gi://GLib?version=2.0";

import { Notification } from "resource:///com/github/Aylur/ags/service/notifications.js";

const range = (length, start = 1) => Array.from({ length }, (_, i) => i + start);
// TODO: fix this so it updates on monitor changes (hypridle)
function forMonitors(widget) {
  const n = Gdk.Display.get_default()?.get_n_monitors() || 1;
  return range(n, 0).map(widget).flat(1);
}

const cssOut = `${App.configDir}/style.css`;

let app;

const tryStartApp = () => {
  if (!app) {
    try {
      app = App.config({
        gtkTheme: "adw-gtk3-dark",
        style: cssOut,
        windows: () => forMonitors(Bar),
        cacheCoverArt: false,
      });
      console.log("App started");
    } catch (e) {
      console.warn(e.message);
      console.log("Failed to start app, retrying...");
      setTimeout(() => tryStartApp(), 3000);
    }
  }
};

const tryApplyCss = (_file: Gio.File, event: Gio.FileMonitorEvent) => {
  // console.log("file event", event, "on", cssOut);
  if (event !== 1) return; // skip duplicate CHANGED events
  try {
    const timeStart = GLib.get_monotonic_time();
    App.applyCss(cssOut); // don't wipe out CSS until we know the new one is valid
    App.applyCss(cssOut, true);
    const timeElapsed = GLib.get_monotonic_time() - timeStart;
    console.log("CSS updated in", timeElapsed / 1000, "ms");
  } catch (e) {
    console.warn(e);
    console.warn("Failed to apply css, waiting for changes");
    Utils.notify({
      summary: "ags: Error loading CSS",
      transient: true,
      timeout: 5000,
    });
  }
};

tryStartApp();

const cssMon = Utils.monitorFile(cssOut, tryApplyCss);
