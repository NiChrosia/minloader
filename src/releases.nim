import std/[json, httpclient, strutils, tables, base64]
import links

type
    Asset* = object
        name*, download*: string

    Release* = object
        tag*: string
        assets*: seq[Asset]

# downloads
proc download*(client: HttpClient, asset: Asset, file: string) =
    discard

# assets
proc toAsset*(json: JsonNode): Asset =
    assert json.kind == JObject

    result.name = json["name"].getStr()
    result.download = json["browser_download_url"].getStr()

# releases
proc toRelease*(json: JsonNode): Release =
    assert json.kind == JObject

    result.tag = json["tag_name"].getStr()

    for assetJson in json["assets"]:
        result.assets.add(toAsset(assetJson))

proc addReleases*(target: var seq[Release], json: JsonNode) =
    assert json.kind == JArray

    for releaseJson in json:
        target.add(toRelease(releaseJson))

proc toReleases*(json: JsonNode): seq[Release] =
    result.addReleases(json)

# utilities
proc setSecret*(client: HttpClient, secret: string) =
    client.headers["Authorization"] = "Basic " & base64.encode(secret)

proc getPage*(link: string): int =
    let query = "?page="
    let queryStart = link.find(query) + query.len()
    let queryEnd = link.high

    let queryString = link[queryStart .. queryEnd]
    result = queryString.parseInt()

proc withPage*(link: string, page: int): string =
    return link & "?page=" & $page

# usage
proc releasesFor*(client: HttpClient, username, repository: string): seq[Release] =
    let url = "https://api.github.com/repos/" & username & "/" & repository & "/releases"

    let links = client.newLink(url)
    let last = links.relations["last"]

    for page in 1 .. last.getPage():
        let pageUrl = url.withPage(page)
        let content = client.getContent(pageUrl)
        let json = content.parseJson()

        result.addReleases(json)
