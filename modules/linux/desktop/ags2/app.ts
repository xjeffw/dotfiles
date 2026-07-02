import { App, Gdk, Gtk } from "astal/gtk3";
import { TopBar, BottomBar } from "./widget/Bar";
import { bind } from "astal";
import { cssOut, watchCss } from "./build";
import { nextTrack, playPause, previousTrack, seekDelta, selectNextPlayer } from "./widget/Media";

let bars: Gtk.Widget[] = [];

const startBars = (monitors: Gdk.Monitor[]) => {
  bars.forEach((bar) => bar.destroy());
  bars = [];
  for (const monitor of monitors) {
    const idx = monitors.indexOf(monitor);
    bars.push(TopBar({ monitorId: idx, monitor }));
    // bars.push(BottomBar({ monitorId: idx, monitor }));
  }
};

const tryStartApp = () => {
  try {
    App.start({
      css: cssOut,
      requestHandler(request: string, res: (response: any) => void) {
        if (request == "playPause") {
          playPause();
        } else if (request == "selectNextPlayer") {
          selectNextPlayer();
        } else if (request == "nextTrack") {
          nextTrack();
        } else if (request == "previousTrack") {
          previousTrack();
        } else if (request.startsWith("seekDelta ")) {
          const delta = Number(request.split(" ")[1]);
          seekDelta(delta);
        } else {
          res("unknown command");
        }
      },
      main() {
        startBars(App.get_monitors());
        bind(App, "monitors").subscribe((monitors) => {
          startBars(monitors);
        });
      },
    });
    console.log("App started");
    watchCss();
  } catch (e) {
    bars = [];
    console.warn(e);
    console.log("Failed to start app, retrying...");
    setTimeout(() => tryStartApp(), 3000);
  }
};

tryStartApp();
