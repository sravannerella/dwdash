%dw 2.0
import fail from dw::Runtime
import everyEntry from dw::core::Objects
import every from dw::core::Arrays
import mapLeaves from Shared

/** Remove matching fields and containers recursively, with a per-call key lookup. */
fun omitKeys(data: Any, keys: Array<String>): Any = do {

    fun omit(data: Any, selected: Object): Any = do {
        if (data is Object)
            (data filterObject ((value, key) -> selected[key as String] == null))
                mapObject ((value, key) -> {(key): omit(value, selected)})
        else if (data is Array) data map ((value) -> omit(value, selected))
        else data
    }
    ---
    if (isEmpty(keys)) data else omit(data, keys groupBy ((key) -> key))
}

/** Checks all direct keys; arrays return one result per element. Null counts as present. */
fun hasKeys(data: Any, keys: Array<String>): Any = do {
    if (data is Array) data map ((value) -> hasKeys(value, keys))
    else if (data is Object) keys every ((key) -> data[key]?)
    else false
}

/** Selects direct keys per object, preserving array order and complete selected values. */
fun pickKeys(data: Any, keys: Array<String>): Any = do {
    var selected = keys groupBy ((key) -> key)

    fun pick(value: Any): Any =
        if (value is Array) value map ((child) -> pick(child))
        else if (value is Object)
            value filterObject ((child, key) -> selected[key as String] != null)
        else value
    ---
    pick(data)
}

/** Native map validation occurs once, followed by collision-safe recursive renaming. */
fun renameKeys(data: Any, names: Object): Any = do {

    fun rename(data: Any, names: Object): Any = do {
        if (data is Object) do {
            var targets = data pluck ((value, key) -> names[key as String] default (key as String))
            ---
            if (sizeOf(targets distinctBy ((key) -> key)) != sizeOf(targets))
                fail("renameKeys would create duplicate keys")
            else data mapObject ((value, key) -> {
                ((names[key as String] default (key as String)) as String): rename(value, names)
            })
        }
        else if (data is Array) data map ((value) -> rename(value, names))
        else data
    }
    ---
    if (not (names everyEntry ((value, key) -> value is String)))
        fail("renameKeys mapping values must be strings")
    else if (isEmpty(names)) data
    else rename(data, names)
}


/** Trims strings recursively without coercing numbers or booleans. */
fun trimStrings(data: Any): Any =
    mapLeaves(data, (value) -> if (value is String) trim(value) else value)


/** Converts empty and whitespace-only strings to null. */
fun blankToNull(data: Any): Any =
    mapLeaves(data, (value) ->
        if (value is String) (if (isBlank(value)) null else value) else value)
