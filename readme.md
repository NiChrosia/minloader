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

Full command: `minldr run [version] [desktop | server] [directory]`
Shorthand: `minldr r [version] [d | s] [directory]`
Example: `minldr r v140.4 d ~/.local/share/Mindustry/`, or for the default Windows folder, `~/AppData/Roaming/Mindustry/`.

For additional clarification, `[directory]` is the run directory, for either the desktop or server version.

### Other commands

To see either available or installed versions, use `minldr list [available | installed]`, or `minldr l [a | i]`.

To see the help pages, either simply call `minldr` for all of them, or `minldr [command]` for a specific command.
