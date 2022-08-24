import os, std/[httpclient, strutils, strformat, terminal]
import releases, utils

const desktopFiles* = ["Mindustry.jar", "desktop-release.jar"]
const serverFiles* = ["server-release.jar"]

const progressBarLength = 30
const progressBarLine = "─"
const progressBarStyle = "{bright}[green]"

type
    Version* = object
        name*: string
        directory*: string

        desktop*, server*: bool

proc newVersion*(name, directory: string): Version =
    if not dirExists(directory):
        createDir(directory)

    result.name = name
    result.directory = directory

proc progressBar(total, progress, speed: BiggestInt) =
    let fraction = progress.float64 / total.float64
    let barLength = int8(fraction * progressBarLength)

    var bar = ""
    bar &= "["

    bar &= progressBarStyle

    if barLength > 0:
        bar &= progressBarLine.repeat(barLength - 1)
    bar &= ">"

    bar &= "{reset}"

    bar &= " ".repeat(progressBarLength - barLength)

    bar &= "]"

    stdout.cursorUp()
    stdout.eraseLine()

    stdout.writeLine parse(bar)

proc setProgressBar*(client: var HttpClient) =
    client.onProgressChanged = progressBar

proc downloadDesktop*(version: var Version, client: HttpClient, release: Release) =
    let file = version.directory / "desktop.jar"
    let asset = release.assets.findIt(it.name in desktopFiles)
        .unwrap(fmt"No desktop asset present in version '{release.tag}'!")

    client.downloadFile(asset.download, file)
    # onProgressChanged isn't called on completion, for whatever reason'
    progressBar(progressBarLength, progressBarLength, 0)

    version.desktop = true

proc downloadServer*(version: var Version, client: HttpClient, release: Release) =
    let file = version.directory / "server.jar"
    let asset = release.assets.findIt(it.name in serverFiles)
        .unwrap(fmt"No server asset present in version '{release.tag}'!")

    client.downloadFile(asset.download, file)
    progressBar(progressBarLength, progressBarLength, 0)

    version.server = true

# utilities
proc storedVersions*(folder: string): seq[Version] =
    for (kind, path) in walkDir(folder, false):
        if kind != pcDir:
            continue

        let names = path.split("/")
        let name = names[names.high]

        var version = newVersion(name, path)

        for (kind, path) in walkDir(path, true):
            if kind != pcFile:
                continue

            let names = path.split("/")
            let name = names[names.high]

            if name == "desktop.jar":
                version.desktop = true
            elif name == "server.jar":
                version.server = true

        result.add(version)
