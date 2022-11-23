import httpclient, os, cligen, base64, json, tables

# utility
proc setAuth(client: var HttpClient, auth: string) =
    let auth = "Basic " & base64.encode(auth)
    client.headers["Authorization"] = auth

proc parseLinks(raw: string): Table[string, string] =
    ## because it's normally unusable

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

# commands
proc run(jar, directory: string) =
    ## run a mindustry jar in the specified directory
    let command = "java -jar " & absolutePath(jar)

    # handles directories for desktop & server, respectively
    putEnv("MINDUSTRY_DATA_DIR", absolutePath(directory))
    setCurrentDir(directory)

    discard execShellCmd(command)

proc search(token: string = "") =
    ## list available mindustry versions, optionally
    ## with a token to raise the ratelimit
    var client = newHttpClient()

    if token != "":
        client.setAuth(token)

    let assets = assets(client)

    for tag in assets.keys:
        stdout.write(tag & ": ")

        for name in assets[tag].keys:
            stdout.write(name & ", ")

        stdout.write("\n")

proc download(tag, asset: string, destination: string, token: string = "") =
    ## download a mindustry version, by tag
    ## also optionally accepts a token
    var client = newHttpClient()

    if token != "":
        client.setAuth(token)

    let assets = assets(client)

    # indentation lol
    for tTag in assets.keys:
        if tag == tTag:
            for tAsset in assets[tag].keys:
                if asset == tAsset:
                    let download = assets[tag][asset]
                    client.downloadFile(download, destination)

dispatchMulti(
    [run, help = {
        "jar": "The Mindustry jar file to run",
        "directory": "Working directory for the Mindustry instance"
    }],
    [search, help = {
        "token": "Optional GitHub token to raise the default ratelimit"
    }],
    [download, help = {
        "tag": "The tag of the release to download from",
        "asset": "The release asset to download",
        "destination": "Where to download the release asset",
        "token": "Optional Github token to raise the defualt ratelimit"
    }]
)
