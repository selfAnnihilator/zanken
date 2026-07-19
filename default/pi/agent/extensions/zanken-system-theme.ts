/**
 * Sync Pi's light/dark theme with the active Zanken theme.
 */

import { existsSync, watch, type FSWatcher } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const home = process.env.HOME ?? "";
const currentThemeDir = join(home, ".config/zanken/current");
const lightModePath = join(currentThemeDir, "theme/light.mode");

function zankenPiTheme(): "light" | "dark" {
	return existsSync(lightModePath) ? "light" : "dark";
}

export default function (pi: ExtensionAPI) {
	let watcher: FSWatcher | null = null;

	pi.on("session_start", (_event, ctx) => {
		let currentTheme = zankenPiTheme();
		ctx.ui.setTheme(currentTheme);

		if (existsSync(currentThemeDir)) {
			watcher = watch(currentThemeDir, { persistent: false }, () => {
				const nextTheme = zankenPiTheme();
				if (nextTheme !== currentTheme) {
					currentTheme = nextTheme;
					ctx.ui.setTheme(currentTheme);
				}
			});
		}
	});

	pi.on("session_shutdown", () => {
		watcher?.close();
		watcher = null;
	});
}
