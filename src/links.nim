import std/[httpclient, tables, strutils, sequtils]

type
    Link* = object
        relations*: Table[string, string]

proc newRelation*(raw: string): tuple[name, value: string] =
    ## Processes relations from format <link>; rel={relation} into (relation, link)

    # remove <>
    let valueStart = raw.find("<") + 1
    let valueEnd = raw.find(">") - 1

    result.value = raw[valueStart .. valueEnd]

    # remove \"
    let nameStart = raw.find("rel=\"") + 5
    let nameEnd = raw.high - 1

    result.name = raw[nameStart .. nameEnd]

proc newLink*(client: HttpClient, url: string): Link =
    let response = client.get(url)
    let headers = response.headers.table

    # only one value is present, so [0]
    let rawLink = headers["link"][0]
    let rawRelations = rawLink.split(", ")

    let relations = rawRelations.map(newRelation)
    result.relations = relations.toTable()
