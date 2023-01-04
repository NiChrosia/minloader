import httpclient, os, json, tables, strutils, algorithm, strformat, terminal, asyncdispatch

const HELP = """
usage: minldr [command]

commands:
(l)ist [(a)vailable | (i)nstalled]
:: lists versions either available for download or installed

(d)ownload [version] [(d)esktop | (s)erver] [file]
:: downloads [version] of platform [desktop | server] to [file]

(i)nstall [version] [(d)esktop | (s)erver]
:: essentially [download], but is tracked by minldr

(u)ninstall [version] [(d)esktop | (s)erver]
:: deletes [platform] for [version]

(e)xecute [jar] [directory]
:: runs the Mindustry [jar] in [directory]

(r)un [version] [(d)esktop | (s)erver] [directory]
:: runs [platform] of [version] in [directory]

minldr version v0.3.1
"""

type
    Platform = enum
        desktop, server

# utility
proc onProgressChanged(total, progress, speed: BiggestInt) {.async.} =
    let length = 100
    # max(progress, total) exists because total is sometimes weirdly less than progress
    let barProgress = int(float(progress) / float(max(progress, total)) * float(length))

    # erase previous progress bar first
    stdout.cursorUp(1)
    stdout.eraseLine()

    stdout.write("[")

    var bar: string
    bar &= "—".repeat(barProgress)

    if barProgress > 0:
        # replace last - with >
        bar[^1] = '>'

    bar &= " ".repeat(length - barProgress)

    stdout.styledWrite(fgGreen, bar)
    stdout.write("]\n")

proc downloadWithBar(client: var AsyncHttpClient, link: string, file: string) =
    # progress bar is exclusive to this function, so only add it here
    client.onProgressChanged = onProgressChanged

    # provide empty bar, as each progress report replaces the previous line
    echo ""
    waitFor client.onProgressChanged(1, 0, 0)

    # download the file, with progress reports
    waitFor client.downloadFile(link, file)

    # the final stretch is never called, so do it manually
    waitFor client.onProgressChanged(1, 1, 0)

    echo "download complete!"

proc parseLinks(raw: string): Table[string, string] =
    for link in raw.split(", "):
        var url, rel: string

        for part in link.split("; "):
            if part[0] == '<':
                # url
                
                let start = 1
                let stop = part.high - 1

                # remove <>
                url = part[start .. stop]
            elif part[0] == 'r':
                # rel
                
                let start = "rel=\"".len
                let stop = part.high - 1

                rel = part[start .. stop]

        result[rel] = url

proc assets(client: AsyncHttpClient): Future[OrderedTable[string, OrderedTable[string, string]]] {.async.} =
    var call = "https://api.github.com/repos/Anuken/Mindustry/releases"
    var responses: seq[AsyncResponse]

    while true:
        let response = await client.get(call)
        responses.add(response)

        let headers = response.headers.table
        let links = headers["link"][0].parseLinks()

        if links.hasKey("next"):
            call = links["next"]
        else:
            break

    # get releases
    var releases: seq[JsonNode]

    for response in responses:
        let root = parseJson(await response.body)

        for release in root:
            releases.add(release)

    for release in releases:
        let tag = release["tag_name"].getStr()
        let assets = release["assets"]

        var downloads: OrderedTable[string, string]

        for asset in assets:
            let name = asset["name"].getStr()
            let url = asset["browser_download_url"].getStr()

            downloads[name] = url

        result[tag] = downloads

proc fail(error: string) =
    echo error
    quit(QuitFailure)

proc expect(count: int) =
    # first argument is command
    let found = paramCount() - 1

    if found < count:
        let command = paramStr(1)

        var start, stop: int

        if command.len == 1:
            # abbreviation
            start = HELP.find(fmt"({command})")
        else:
            # full name
            let first = command[0]
            let rest = command[1 .. command.high]

            # i.e., (c)ommand
            start = HELP.find(fmt"({first}){rest}")

        var newlines = 0

        for i in start .. HELP.high:
            if HELP[i] == '\n':
                newlines += 1

            if newlines == 2:
                # we don't want the second newline
                stop = i - 1
                break

        let help = HELP[start .. stop]
        echo help

        quit(fmt"{found}/{count} arguments given!")

# initialize application folder
let dir = getConfigDir() / "minloader"
if not dirExists(dir):
    createDir(dir)

proc jar(tag: string, platform: Platform): string =
    let jarDir = dir / "jars"
    if not dirExists(jarDir):
        createDir(jarDir)

    let file = fmt"{jarDir}/{tag}-{platform}.jar"
    return file

proc downloadLink(tag: string, platform: Platform): string =
    var client = newAsyncHttpClient()

    let assets = waitFor client.assets()

    if not assets.hasKey(tag):
        fail(fmt"version '{tag}' does not exist!")

    let attachedAssets = assets[tag]

    if attachedAssets.len == 0:
        fail(fmt"version '{tag}' does not have any platforms!")

    let platformFiles = case platform
    of desktop:
        @["desktop-release.jar", "Mindustry.jar"]
    of server:
        @["server-release.jar"]

    for file in attachedAssets.keys:
        if file in platformFiles:
            return attachedAssets[file]

    fail(fmt"{platform} asset not found!")

proc download(tag: string, platform: Platform, file: string) =
    var client = newAsyncHttpClient()

    let link = downloadLink(tag, platform)
    client.downloadWithBar(link, file)

proc listAvailable() =
    var client = newAsyncHttpClient()
    let assets = waitFor client.assets()

    var available: seq[string]

    for tag in assets.keys:
        if assets[tag].len > 0:
            available.add(tag)

    for i in 0 .. available.high:
        let tag = available[i]

        stdout.write tag

        if i < available.high:
            stdout.write ", "
        else:
            stdout.write "\n"

proc listInstalled() =
    let jarDir = dir / "jars"
    if not dirExists(jarDir):
        quit("no versions installed!")

    # version - platforms in binary
    # 10 = desktop, 01 = server, 11 = both
    var platforms: Table[string, int]

    var childrenInDir = 0

    for (kind, path) in walkDir(jarDir):
        if kind != pcFile:
            continue

        childrenInDir += 1

        # example: v140.4-desktop.jar
        let (_, name, _) = splitFile(path)
        let parts = name.split("-")

        let version = parts[0]
        let platform = parts[1]

        if not platforms.hasKey(version):
            platforms[version] = 0b00

        case platform
        of "desktop":
            platforms[version] = platforms[version] or 0b10
        of "server":
            platforms[version] = platforms[version] or 0b01
        else:
            discard

    if childrenInDir == 0:
        fail("no versions installed!")

    for version in platforms.keys:
        let bits = platforms[version]

        let desktop = bool((bits and 0b10) shr 1)
        let server = bool(bits and 0b01)

        # color code for easier overall viewing
        let color = if desktop and server:
            fgMagenta
        elif desktop:
            fgRed
        elif server:
            fgBlue
        else:
            # not possible, existence in the
            # table requires at least one platform
            fgDefault

        stdout.styledWrite color, version
        stdout.write ": "

        if desktop and server:
            stdout.writeLine "desktop, server"
        elif desktop:
            stdout.writeLine "desktop"
        elif server:
            stdout.writeLine "server"

proc install(tag: string, platform: Platform) =
    var client = newAsyncHttpClient()
    client.downloadWithBar(downloadLink(tag, platform), jar(tag, platform))

proc uninstall(tag: string, platform: Platform) =
    let jar = jar(tag, platform)

    if fileExists(jar):
        removeFile(jar)
    else:
        fail(fmt"platform '{platform}' of version '{tag}' not installed!")

proc execute(jar, directory: string) =
    let command = "java -jar " & absolutePath(jar)

    if not fileExists(jar):
        fail(fmt"jar at location '{jar}' does not exist!")

    if not dirExists(directory):
        fail(fmt"directory '{directory}' does not exist!")

    # handles directories for desktop & server, respectively
    putEnv("MINDUSTRY_DATA_DIR", absolutePath(directory))
    setCurrentDir(directory)

    discard execShellCmd(command)

proc run(tag, directory: string, platform: Platform) =
    ## run a mindustry jar in the specified directory

    let jar = jar(tag, platform)

    if not fileExists(jar):
        fail(fmt"platform '{platform}' of version '{tag}' is not installed!")

    execute(jar, directory)

var arguments = commandLineParams().reversed()

if arguments.len == 0:
    echo HELP

let command = arguments.pop()

case command
of "list", "l":
    expect(1)

    let choice = arguments.pop()

    case choice
    of "available", "a":
        listAvailable()
    of "installed", "i":
        listInstalled()
    else:
        fail(fmt"unrecognized choice '{choice}'!")
of "download", "d":
    expect(3)

    let version = arguments.pop()
    let platform = arguments.pop()
    let file = arguments.pop()

    case platform
    of "desktop", "d":
        download(version, desktop, file)
    of "server", "s":
        download(version, server, file)
    else:
        fail("unrecognized platform '" & platform & "'!")
of "install", "i":
    expect(2)

    let version = arguments.pop()
    let platform = arguments.pop()

    case platform
    of "desktop", "d":
        install(version, platform = desktop)
    of "server", "s":
        install(version, platform = server)
    else:
        fail("unrecognized platform '" & platform & "'!")
of "uninstall", "u":
    expect(2)

    let version = arguments.pop()
    let platform = arguments.pop()

    case platform
    of "desktop", "d":
        uninstall(version, desktop)
    of "server", "s":
        uninstall(version, server)
    else:
        fail("unrecognized platform '" & platform & "'!")
of "execute", "e":
    expect(2)

    let jar = arguments.pop()
    let directory = arguments.pop()

    execute(jar, directory)
of "run", "r":
    expect(3)

    let version = arguments.pop()
    let platform = arguments.pop()
    let directory = arguments.pop()

    case platform
    of "desktop", "d":
        run(version, directory, desktop)
    of "server", "s":
        run(version, directory, server)
    else:
        fail("unrecognized platform '" & platform & "'!")
else:
    fail("unrecognized command '" & command & "'!")
