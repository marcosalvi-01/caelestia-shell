pragma Singleton

import Quickshell
import Caelestia
import Caelestia.Config
import qs.utils

Searcher {
    id: root

    function compareEntries(a: AppEntry, b: AppEntry): int {
        if (a.frequency !== b.frequency)
            return b.frequency - a.frequency;
        if (a.lastLaunched !== b.lastLaunched)
            return b.lastLaunched - a.lastLaunched;
        return a.name.localeCompare(b.name);
    }

    function mapRankedResults(results: list<var>): list<var> {
        return results.sort((a, b) => {
            if (a.score !== b.score)
                return b.score - a.score;
            return compareEntries(a.item, b.item);
        }).map(r => r.item.entry);
    }

    function launch(entry: DesktopEntry): void {
        appDb.incrementFrequency(entry.id);

        if (entry.runInTerminal)
            Quickshell.execDetached({
                command: ["app2unit", "--", ...GlobalConfig.general.apps.terminal, `${Quickshell.shellDir}/assets/wrap_term_launch.sh`, ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        else
            Quickshell.execDetached({
                command: ["app2unit", "--", ...entry.command],
                workingDirectory: entry.workingDirectory
            });
    }

    function search(search: string): list<var> {
        const prefix = GlobalConfig.launcher.specialPrefix;

        if (search.startsWith(`${prefix}i `)) {
            keys = ["id", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}c `)) {
            keys = ["categories", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}d `)) {
            keys = ["comment", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}e `)) {
            keys = ["execString", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}w `)) {
            keys = ["startupClass", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}g `)) {
            keys = ["genericName", "name"];
            weights = [0.9, 0.1];
        } else if (search.startsWith(`${prefix}k `)) {
            keys = ["keywords", "name"];
            weights = [0.9, 0.1];
        } else {
            keys = ["name", "genericName", "comment", "execString", "keywords", "id"];
            weights = [0.4, 0.2, 0.15, 0.15, 0.07, 0.03];

            if (!search.startsWith(`${prefix}t `))
                return mapRankedResults(queryWithMetadata(search));
        }

        const results = mapRankedResults(queryWithMetadata(search.slice(prefix.length + 2)));
        if (search.startsWith(`${prefix}t `))
            return results.filter(a => a.runInTerminal);
        return results;
    }

    function selector(item: var): string {
        return keys.map(k => item[k]).join(" ");
    }

    list: appDb.apps
    useFuzzy: GlobalConfig.launcher.useFuzzy.apps

    AppDb {
        id: appDb

        path: `${Paths.state}/apps.sqlite`
        favouriteApps: GlobalConfig.launcher.favouriteApps
        entries: DesktopEntries.applications.values.filter(a => !Strings.testRegexList(GlobalConfig.launcher.hiddenApps, a.id))
    }
}
