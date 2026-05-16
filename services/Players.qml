pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Caelestia
import Caelestia.Config
import qs.components.misc
import qs.utils

Singleton {
    id: root

    readonly property list<MprisPlayer> list: Mpris.players.values
    readonly property list<MprisPlayer> usefulPlayers: list.filter(player => isUseful(player))
    readonly property MprisPlayer active: getPreferredActive()
    property alias manualActive: props.manualActive
    property bool controllerAvailable
    property string controllerPlayerName: ""

    function normalizePlayerName(name: string): string {
        return (name ?? "").toLowerCase().replace(/[^a-z0-9]/g, "");
    }

    function isUseful(player: MprisPlayer): bool {
        return player?.playbackState === MprisPlaybackState.Playing || player?.playbackState === MprisPlaybackState.Paused;
    }

    function getControllerPlayer(): MprisPlayer {
        if (!controllerPlayerName)
            return null;

        const controllerName = normalizePlayerName(controllerPlayerName);
        return usefulPlayers.find(player => {
            const candidates = [
                player.desktopEntry,
                player.dbusName,
                player.identity,
                getIdentity(player)
            ];
            return candidates.some(candidate => normalizePlayerName(candidate).includes(controllerName));
        }) ?? null;
    }

    function getPreferredActive(): MprisPlayer {
        const controllerPlayer = getControllerPlayer();
        if (isUseful(controllerPlayer))
            return controllerPlayer;

        const manual = props.manualActive;
        if (isUseful(manual))
            return manual;

        return usefulPlayers.find(player => player.playbackState === MprisPlaybackState.Playing)
            ?? usefulPlayers.find(player => player.playbackState === MprisPlaybackState.Paused)
            ?? list.find(player => getIdentity(player) === GlobalConfig.services.defaultPlayer)
            ?? list[0]
            ?? null;
    }

    function getIdentity(player: MprisPlayer): string {
        const alias = GlobalConfig.services.playerAliases.find(a => a.from === player.identity);
        return alias?.to ?? player.identity;
    }

    function findDesktopEntry(player: MprisPlayer): var {
        if (!player)
            return null;

        const exactCandidates = [
            player.desktopEntry,
            `${player.desktopEntry}.desktop`,
            player.identity,
            getIdentity(player),
            controllerPlayerName,
            `${controllerPlayerName}.desktop`
        ].filter(Boolean);

        for (const candidate of exactCandidates) {
            const entry = DesktopEntries.applications.values.find(app => normalizePlayerName(app.id) === normalizePlayerName(candidate) || normalizePlayerName(app.name) === normalizePlayerName(candidate));
            if (entry)
                return entry;
        }

        const heuristicCandidates = [
            player.desktopEntry,
            player.identity,
            getIdentity(player),
            controllerPlayerName
        ].filter(Boolean);

        for (const candidate of heuristicCandidates) {
            const entry = DesktopEntries.heuristicLookup(candidate);
            if (entry)
                return entry;
        }

        return null;
    }

    function getIconData(player: MprisPlayer): var {
        const fallback = {
            source: "",
            materialIcon: "audio_file"
        };

        if (!player)
            return fallback;

        const entry = findDesktopEntry(player);
        return Icons.resolveDesktopEntryIcon(entry) ?? fallback;
    }

    function pinActivePlayer(): MprisPlayer {
        const player = active;
        if (player && !controllerAvailable)
            props.manualActive = player;
        return player;
    }

    function controllerExec(args: list<string>): bool {
        if (!controllerAvailable)
            return false;

        Quickshell.execDetached(args);
        controllerRefreshTimer.restart();
        return true;
    }

    function toggleActive(): void {
        if (controllerExec(["playerctl", "play-pause"]))
            return;

        const player = pinActivePlayer();
        if (player?.canTogglePlaying)
            player.togglePlaying();
    }

    function playActive(): void {
        if (controllerExec(["playerctl", "play"]))
            return;

        const player = pinActivePlayer();
        if (player?.canPlay)
            player.play();
    }

    function pauseActive(): void {
        if (controllerExec(["playerctl", "pause"]))
            return;

        const player = pinActivePlayer();
        if (player?.canPause)
            player.pause();
    }

    function previousActive(): void {
        if (controllerExec(["playerctl", "previous"]))
            return;

        const player = pinActivePlayer();
        if (player?.canGoPrevious)
            player.previous();
    }

    function nextActive(): void {
        if (controllerExec(["playerctl", "next"]))
            return;

        const player = pinActivePlayer();
        if (player?.canGoNext)
            player.next();
    }

    function stopActive(): void {
        if (controllerExec(["playerctl", "stop"]))
            return;

        pinActivePlayer()?.stop();
    }

    function getArtUrl(player: MprisPlayer): string {
        if (!player)
            return "";
        if (player.trackArtUrl)
            return player.trackArtUrl;

        const url = player.metadata["xesam:url"] ?? "";
        if (url.startsWith("https://www.youtube.com/watch")) {
            // Fallback for youtube
            const id = url.match(/[?&]v=([\w-]{11})/)?.[1];
            return id ? `https://img.youtube.com/vi/${id}/hqdefault.jpg` : "";
        }
        return "";
    }

    function selectRelativePlayer(step: int): void {
        if (controllerExec(["playerctld", step > 0 ? "shift" : "unshift"]))
            return;

        const players = usefulPlayers;
        if (!players.length)
            return;

        const current = active;
        const currentIndex = players.indexOf(current);
        const startIndex = currentIndex >= 0 ? currentIndex : 0;
        const nextIndex = (startIndex + step + players.length) % players.length;
        props.manualActive = players[nextIndex];
    }

    function selectNext(): void {
        selectRelativePlayer(1);
    }

    function selectPrevious(): void {
        selectRelativePlayer(-1);
    }

    Connections {
        function onPostTrackChanged() {
            if (!GlobalConfig.utilities.toasts.nowPlaying) {
                return;
            }
            if (root.active.trackArtist != "" && root.active.trackTitle != "") {
                Toaster.toast(qsTr("Now Playing"), qsTr("%1 - %2").arg(root.active.trackArtist).arg(root.active.trackTitle), "music_note");
            }
        }

        target: root.active
    }

    Timer {
        id: controllerRefreshTimer

        interval: 150
        onTriggered: controllerPoll.running = true
    }

    Timer {
        interval: 1000
        running: root.controllerAvailable && root.list.length > 0
        repeat: true
        onTriggered: controllerPoll.running = true
    }

    PersistentProperties {
        id: props

        property MprisPlayer manualActive

        reloadableId: "players"
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaToggle"
        description: "Toggle media playback"
        onPressed: root.toggleActive()
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaPrev"
        description: "Previous track"
        onPressed: root.previousActive()
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaNext"
        description: "Next track"
        onPressed: root.nextActive()
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaStop"
        description: "Stop media playback"
        onPressed: root.stopActive()
    }

    Process {
        id: controllerCheck

        running: true
        command: ["sh", "-c", "command -v playerctl >/dev/null && command -v playerctld >/dev/null"]
        onExited: exitCode => { // qmllint disable signal-handler-parameters
            root.controllerAvailable = exitCode === 0;
            if (root.controllerAvailable)
                controllerRefreshTimer.restart();
        }
    }

    Process {
        id: controllerPoll

        command: ["playerctl", "metadata", "--format", "{{playerName}}"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.controllerPlayerName = text.trim();
            }
        }
        onExited: exitCode => { // qmllint disable signal-handler-parameters
            if (exitCode !== 0)
                root.controllerPlayerName = "";
        }
    }

    IpcHandler {
        function getActive(prop: string): string {
            const active = root.active;
            return active ? active[prop] ?? "Invalid property" : "No active player";
        }

        function list(): string {
            return root.list.map(p => root.getIdentity(p)).join("\n");
        }

        function play(): void {
            root.playActive();
        }

        function pause(): void {
            root.pauseActive();
        }

        function playPause(): void {
            root.toggleActive();
        }

        function previous(): void {
            root.previousActive();
        }

        function next(): void {
            root.nextActive();
        }

        function stop(): void {
            root.stopActive();
        }

        target: "mpris"
    }
}
