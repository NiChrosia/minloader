## Specification

### Files
```
v1/
    versions/
        v137/
            desktop.jar
            server.jar
        v136/
            desktop.jar
    instances/
        main/
            mods/
            settings.bin
```

### Commands
```
[default] = prompt this help menu
new(name: string) = creates a new instance with name
delete(name: string) = deletes the corresponding instance

install(version: string, platforms: [string]) = install version for platforms
uninstall(version: string, platforms: [string]) = uninstall version for platforms

list(type: instances | versions) = list values for given type

run(name, version: string, platform: string = "desktop") = runs instance with version and platform
```

#### Animations
```
\^[abc] = animation with frames abc
\^[->] = progress bar with arrow

new
    Created instance '{bright}[green]$name[]{}'.
install
    ^[-/|\] Downloading '{bright}[green]$version[]{}'...

    desktop: ^[->]
    server: ^[->]
```
