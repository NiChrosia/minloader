import os, std/[options, httpclient, json, strutils, sequtils]
import releases, instances, versions, utils

# semi-constants
let folder = getAppDir() / "minloader-v1"
let instancesFolder = folder / "instances"
let versionsFolder = folder / "versions"

const helpText = """
{function}default{} = prompt this help menu
{function}new{}(name: {argument}string{}) = creates a new instance with name
{function}delete{}(name: {argument}string{}) = deletes the corresponding instance

{function}install{}(version: {argument}string{}, platforms: {argument}[string]{}) = install version for platforms
{function}uninstall{}(version: {argument}string{}, platforms: {argument}[string]{}) = uninstall version for platforms

{function}list{reset}(type: {argument}instances{} | {argument}versions{}) = list values for given type

{function}run{}(name, version: {argument}string{}, platform: {argument}string{} = "desktop"{}) = runs instance with version and platform"""

proc help() =
    let text = helpText
        .replace("{function}", "{bright}[yellow]")
        .replace("{argument}", "[blue]")
        .replace("{}", "{reset}")

    echo parse(text)

# setup
var client = newHttpClient()

if fileExists("github_secret.txt"):
    client.setSecret(readFile("github_secret.txt"))

if not dirExists(folder):
    createDir(folder)

var releasesFile = folder / "releases.json"

var mindustryReleases = if not fileExists(releasesFile):
    var releases = client.releasesFor("Anuken", "Mindustry")
    let json = %*releases

    writeFile(releasesFile, json.pretty(4))

    releases
else:
    readFile(releasesFile)
        .parseJson()
        .to(seq[Release])

client.setProgressBar()

if not dirExists(instancesFolder):
    createDir(instancesFolder)

if not dirExists(versionsFolder):
    createDir(versionsFolder)

# state
var storedInstances = storedInstances(instancesFolder)
var storedVersions = storedVersions(versionsFolder)

# command checks
proc installed(name: string, platform: string): bool =
    let maybeVersion = storedVersions.findIt(it.name == name)

    if maybeVersion.isSome():
        let version = maybeVersion.get()

        if platform == "desktop":
            return version.desktop
        elif platform == "server":
            return version.server
        else:
            echo "Unrecognized platform!"
            quit(0)
    else:
        return false

# commands
proc newInstance(name: string) =
    storedInstances.findIt(it.name == name)
        .ifSome("Instance already exists!")

    let instance = newInstance(name, instancesFolder / name)
    storedInstances.add(instance)

    echo parse("Instance '{bright}[yellow]" & name & "{reset}' created!")

proc deleteInstance(name: string) =
    let instance = storedInstances.findIt(it.name == name)
        .unwrap("No such instance!")

    removeDir(instance.directory)
    storedInstances.delete(storedInstances.find(instance))

    echo parse("Instance '{bright}[yellow]" & name & "{reset}' deleted.")

proc install(name: string, platforms: seq[string]) =
    for platform in platforms:
        if installed(name, platform):
            echo parse("Platform '{bright}[blue]" & platform & "{reset}' is already installed!")
            quit(0)

    let release = mindustryReleases.findIt(it.tag == name)
        .unwrap(parse("Version '{bright}[green]" & name & "{reset}' not found."))

    var version = newVersion(name, versionsFolder / name)

    if platforms.contains("desktop"):
        version.downloadDesktop(client, release)

    if platforms.contains("server"):
        version.downloadServer(client, release)

    storedVersions.add(version)

    echo parse("Version '{bright}[green]" & name & "{reset}' installed!")

proc uninstall(name: string, platforms: seq[string]) =
    var version = storedVersions.findIt(it.name == name)
            .unwrap("No such version!")

    let deleteAll = platforms.contains("desktop") and platforms.contains("server") or
    platforms.onlyContains("desktop") and not version.server or
    platforms.onlyContains("server") and not version.desktop

    if deleteAll:
        removeDir(version.directory)
        storedVersions.delete(storedVersions.find(version))

        echo parse("Version '{bright}[green]" & name & "{reset}' uninstalled.")
    else:
        for platform in platforms:
            if platform == "desktop":
                version.desktop = false
            elif platform == "server":
                version.server = false
            else:
                echo parse("Unrecognized platform '{bright}[blue]" & platform & "{reset}'!")

            removeFile(version.directory / platform & ".jar")

            echo parse("Platform '{bright}[blue]" & platform & "{reset}' of '{bright}[green]" & name & "{reset}' uninstalled.")

proc list(kind: string) =
    case kind
    of "instances":
        if storedInstances.len() == 0:
            echo "There are currently no instances."
            quit(0)

        echo storedInstances.mapIt(parse("{bright}[yellow]" & it.name & "{reset}")).join(", ")
    of "versions":
        if storedVersions.len() == 0:
            echo "There are no versions installed."
            quit(0)

        var longest = 0

        for version in storedVersions:
            if version.name.len() > longest:
                longest = version.name.len()

        for version in storedVersions:
            stdout.write version.name, ": "

            if version.name.len() < longest:
                stdout.write " ".repeat(longest - version.name.len())

            if version.desktop:
                stdout.write parse("{bright}[green]desktop{reset}")
            else:
                stdout.write parse("[red]desktop{reset}")

            stdout.write ", "

            if version.server:
                stdout.write parse("{bright}[green]server{reset}")
            else:
                stdout.write parse("[red]server{reset}")

            stdout.write "\n"
    else:
        echo parse("Unrecognized type '{bright}[magenta]" & kind & "{reset}'.")
        quit(0)

proc run(instanceName: string, versionName: string, platform: string = "desktop") =
    let instance = storedInstances.findIt(it.name == instanceName)
        .unwrap(parse("There is no instance named '{bright}[yellow]" & instanceName & "{reset}'!"))

    let version = storedVersions.findIt(it.name == versionName)
        .unwrap(parse("Version '{bright}[green]" & versionName & "{reset}' does not exist or is not installed!"))

    instance.run(version.directory, platform)

# arguments
proc require(arguments: seq[string], index: int, error: string): string =
    if arguments.len() == index:
        echo error
        quit(0)
    else:
        return arguments[index]

proc requireList(arguments: seq[string], index: int, error: string): seq[string] =
    if arguments.len() == index:
        echo error
        quit()
    else:
        return arguments[index .. arguments.high]

proc defaulted(arguments: seq[string], index: int, default: string): string =
    if arguments.len() == index:
        return default
    else:
        return arguments[index]

let arguments = commandLineParams()
let command = arguments.defaulted(0, "help")

case command
of "help":
    help()
of "new":
    let name = arguments.require(1, "No name specified.")

    newInstance(name)
of "delete":
    let name = arguments.require(1, "No name specified.")

    deleteInstance(name)
of "install":
    let name = arguments.require(1, "No version specified.")
    let platforms = arguments.requireList(2, "No platforms specified.")

    install(name, platforms)
of "uninstall":
    let name = arguments.require(1, "No version specified.")
    let platforms = arguments.requireList(2, "No platforms specified.")

    uninstall(name, platforms)
of "list":
    let kind = arguments.require(1, "No type specified.")

    list(kind)
of "run":
    let instanceName = arguments.require(1, "No instance specified.")
    let versionName = arguments.require(2, "No version specified.")

    let platform = arguments.defaulted(3, "desktop")

    run(instanceName, versionName, platform)
else:
    echo "Unrecognized command."
