import std/[options, terminal, strutils, strformat]

template findIt*[T](collection: openArray[T], matcher: untyped): Option[T] =
    var result: Option[T]

    for it {.inject.} in collection:
        if matcher:
            result = some(it)
            break

    result

proc unwrap*[T](option: Option[T], error: string): T =
    if option.isNone():
        echo error
        quit(0)
    else:
        return option.get()

proc ifSome*[T](option: Option[T], error: string) =
    if option.isSome():
        echo error

proc onlyContains*[T](collection: openArray[T], value: T): bool =
    return collection.contains(value) and collection.len() == 1

# enums
proc values*[T: enum](kind: typedesc[T]): seq[T] =
    for value in low(kind) .. high(kind):
        result.add(value)

proc valueOf*[T: enum](kind: typedesc[T], name: string): T =
    for value in T.values():
        if $value == name:
            return value

    raise newException(ValueError, fmt"No enum value with given name '{name}'.")

proc parse*(encoded: string): string =
    result = encoded
        .replace("{reset}", when not defined(windows): ansiResetCode else: "")

    for style in Style.values():
        let full = $style
        let capitalized = full.replace("style", "")
        let name = capitalized.toLower()

        result = result.replace("{" & name & "}", when not defined(windows): ansiStyleCode(style) else: "")

    for color in ForegroundColor.values():
        let full = $color
        let capitalized = full.replace("fg", "")
        let name = capitalized.toLower()

        result = result.replace("[" & name & "]", when not defined(windows): ansiForegroundColorCode(color) else: "")
