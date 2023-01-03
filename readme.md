## Installation

- Download your OS executable from the [latest release](https://github.com/NiChrosia/minloader/releases/latest).
- Add it to your PATH variable.

## Usage

### Downloading Mindustry

You can either directly download version jar files, or use the built-in state.

To directly download, use `minldr download [version] [desktop | server] [file]`, or the shorthand `minldr d [version] [d | s] [file]`. For example,
`minldr d v140.4 d ~/Downloads/v140.4-desktop.jar`

To use the state, use `minldr install [version] [desktop | server]`, or the similar shorthand, `minldr i [version] [d | s]`. For example,
`minldr i v140.4 d`

### Running Mindustry

Similarly to above, you can choose whether to use the state.

To use it, call `minldr run [version] [desktop | server] [directory]`, or the corresponding shorthand.

To not use it, call `minldr execute [jar] [directory]`, or the corresponding shorthand.

For additional clarification, `[directory]` is the run directory, for either the desktop or server version.

### Other commands

To see either available or installed versions, use `minldr list [available | installed]`, or `minldr l [a | i]`.

To see the help pages, either simply call `minldr` for all of them, or `minldr [command]` for a specific command.

## Help text

Inserted for convenient access.

```
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
```
