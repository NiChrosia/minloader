# Minloader

### Quickstart

- Download the [latest release](https://github.com/NiChrosia/minloader/releases/latest).
- Run `minloader search` to get a list of Mindustry jars.
-- Some versions towards the bottom don't have any assets, which is because the corresponding old releases don't either.
- Download a jar using a command like `minloader download --tag:"v140.4" --asset:"Mindustry.jar" --destination:"./Mindustry.jar"`, except with your wanted tag and asset.
-- `Mindustry.jar` and `desktop-release.jar` are generally the desktop versions.
-- `server-release.jar` is always the server version.
- Run the downloaded jar using something like `minloader run --jar:"Mindustry.jar" --directory:"./mindustry/"`
-- Mindustry should now be running, and saving its data to the specified folder.

### Run

`minloader run --jar:"~/Downloads/v140.4-desktop.jar" --directory:"~/.local/share/Mindustry"`

`--jar` takes any Mindustry jar, and runs it in `--directory`. This works with both the desktop version and a server.

### Search

`minloader search [--token:""]`

Prints a list of all Mindustry releases with their downloadable assets. Used for `minloader download`.

`--token` is an optional GitHub token argument that is used to bypass the low default ratelimit.

### Download

`minloader download --tag:"v140.4" --asset:"Mindustry.jar" --destination:"~/Downloads/v140.4-desktop.jar" [--token:""]`

Downloads `--asset` of the release tagged `--tag` to `--destination`.

As before, `--token` is an optional GitHub token argument that is used to bypass the low default ratelimit.
