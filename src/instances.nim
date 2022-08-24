import os, std/[strutils]

type
    Instance* = object
        name*: string
        directory*: string

proc newInstance*(name, directory: string): Instance =
    if not dirExists(directory):
        createDir(directory)

    result.name = name
    result.directory = directory

proc run*(instance: Instance, versionDirectory, platform: string) =
    let jar = versionDirectory / platform & ".jar"
    let command = "java -jar " & jar
    let variable = "MINDUSTRY_DATA_DIR"

    putEnv(variable, instance.directory)
    discard execShellCmd(command)

# utilities
proc storedInstances*(folder: string): seq[Instance] =
    for (kind, path) in walkDir(folder, false):
        if kind != pcDir:
            continue

        let names = path.split("/")
        let name = names[names.high]

        let instance = newInstance(name, path)
        result.add(instance)
