# Minloader

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
