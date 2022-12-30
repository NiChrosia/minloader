import httpclient, os, base64, json, tables, strutils, cligen

# utility
proc setAuth(client: var HttpClient, auth: string) =
    let auth = "Basic " & base64.encode(auth)
    client.headers["Authorization"] = auth

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

proc assets(client: HttpClient): OrderedTable[string, OrderedTable[string, string]] =
    var call = "https://api.github.com/repos/Anuken/Mindustry/releases"
    var responses: seq[Response]

    while true:
        let response = client.get(call)
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
        let root = parseJson(response.body)

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

# initialize application folder
let dir = getConfigDir() / "mldr"
if not dirExists(dir):
    createDir(dir)

type
    MindustryVersion = enum
        mvDesktop, mvServer

proc jar(tag: string, version: MindustryVersion): string =
    let jarDir = dir / "jars"
    if not dirExists(jarDir):
        createDir(jarDir)

    let extension = case version
    of mvDesktop:
        "desktop"
    of mvServer:
        "server"

    let file = jarDir / tag & "-" & extension & ".jar"
    return file

proc jar(tag: string, desktop, server: bool): string =
    if desktop == server:
        if desktop:
            echo "cannot use both desktop and server at the same time!"
        else:
            echo "must use at least one platform!"

        quit(QuitFailure)

    let version = if desktop: mvDesktop else: mvServer
    let jar = jar(tag, version)

    return jar

proc install(tag: string; list = false, desktop = false, server = false, token: string = "") =
    var client = newHttpClient()

    if token != "":
        client.setAuth(token)

    let assets = client.assets()

    if list:
        for tag in assets.keys:
            stdout.write(tag & ": ")

            for name in assets[tag].keys:
                stdout.write(name & ", ")

            stdout.write("\n")

        return
    
    if desktop == server:
        if desktop:
            echo "cannot use both desktop and server at the same time!"
        else:
            echo "must use at least one platform!"

        quit(QuitFailure)

    for givenTag in assets.keys:
        if givenTag != tag:
            continue

        for givenAsset in assets[givenTag].keys:
            if givenAsset == "desktop-release.jar" or givenAsset == "Mindustry.jar":
                if not desktop:
                    continue

                let jar = jar(givenTag, mvDesktop)
                client.downloadFile(assets[givenTag][givenAsset], jar)
            elif givenAsset == "server-release.jar":
                if not server:
                    continue

                let jar = jar(givenTag, mvServer)
                client.downloadFile(assets[givenTag][givenAsset], jar)
            else:
                echo "unrecognized asset '" & givenAsset & "' for tag '" & givenTag & "'; please report this on GitHub!"
                quit(QuitFailure)

proc uninstall(tag: string, list = false, desktop = false, server = false) =
    let jar = jar(tag, desktop, server)

    if fileExists(jar):
        removeFile(jar)
    else:
        echo "version not installed!"

proc run(tag, directory: string; list = false, desktop = false, server = false) =
    ## run a mindustry jar in the specified directory
    let jar = jar(tag, desktop, server)
    let command = "java -jar " & absolutePath(jar)

    # handles directories for desktop & server, respectively
    putEnv("MINDUSTRY_DATA_DIR", absolutePath(directory))
    setCurrentDir(directory)

    discard execShellCmd(command)

proc version() =
    echo "v0.3.0"

# temporary help string
const HELP = """
usage: mldr [command]

commands:
i(nstall) [tag]
-l, --list:    list available versions
-s, --server:  download the server version
-t, --token:   use the specified GitHub token to bypass the normal ratelimit

u(ninstall) [tag]
-l, --list:    list downloaded versions
-d, --desktop: remove the desktop version
-s, --server:  remove the server version

r(un) [tag] [directory]
-l, --list:    list downloaded versions
-d, --desktop: run desktop
-s, --server:  run server

v(ersion)
h(elp)
"""

if commandLineParams().len == 0:
    echo HELP
    quit(QuitSuccess)

dispatchMulti([install], [uninstall], [run], [version])
