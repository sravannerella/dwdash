%dw 2.9
import fail from dw::Runtime
import repeat, substring from dw::core::Strings
import mapLeaves from Shared

fun applyMask(data: Any, keys: Array<String> | Regex | Null, mode: String, count: Number, character: String): Any = do {
    if (not (count >= 0 and floor(count) == count))
        fail("Character count must be a non-negative integer")
    else if (keys is Array and isEmpty(keys)) data
    else do {
        // Bound single-character padding; keep other replacement text unchanged.
        var prepared = if (sizeOf(character) != 1) character
                       else repeat(character, if (mode == "all" or mode == "exceptLast" or mode == "exceptFirst" or count > 64) 64 else count)

        fun maskScalar(value: Any): Any = do {
            if (value == null) null
            else if (value is String or value is Number or value is Boolean) do {
                var text = value as String
                var length = sizeOf(text)
                var masked = if (mode == "all") length
                             else if (mode == "exceptLast" or mode == "exceptFirst") (if (length > count) length - count else 0)
                             else if (length < count) length else count
                var replacement = if (sizeOf(character) != 1) prepared
                                  else if (masked == sizeOf(prepared)) prepared
                                  else if (masked < sizeOf(prepared)) substring(prepared, 0, masked)
                                  else repeat(character, masked)
                ---
                if (masked == 0) text
                else if (masked == length) replacement
                else if (mode == "last" or mode == "exceptFirst") substring(text, 0, length - masked) ++ replacement
                else replacement ++ substring(text, masked, length)
            }
            else fail("Masking supports JSON scalar values only")
        }
        fun mapSelected(value: Any, selected: Object): Any =
            if (value is Object)
                value mapObject ((child, key) -> {
                    (key): if (if (keys is Regex) (key as String) matches keys else selected[key as String] != null)
                               mapLeaves(child, maskScalar)
                           else mapSelected(child, selected)
                })
            else if (value is Array)
                value map ((child) -> mapSelected(child, selected))
            else value
        ---
        if (keys is Null) mapLeaves(data, maskScalar)
        else mapSelected(data, if (keys is Array) keys groupBy ((key) -> key) else {})
    }
}

/** Fully masks every JSON scalar leaf in the supplied value. */
fun maskIt(data: Any, maskWithCharacter: String = "*"): Any = do {
    applyMask(data, null, "all", 0, maskWithCharacter)
}

/** Masks values under matching keys, including descendants of containers. */
fun maskKeys(data: Any, keys: Array<String>, maskWithCharacter: String = "*"): Any = do {
    applyMask(data, keys, "all", 0, maskWithCharacter)
}

/** Masks the last N characters; does not keep the last N visible. */
fun maskLast(data: Any, keys: Array<String>, numberOfCharactersToMask: Number = 4, maskWithCharacter: String = "*"): Any = do {
    applyMask(data, keys, "last", numberOfCharactersToMask, maskWithCharacter)
}

/** Masks the first N characters under matching keys. */
fun maskFirst(data: Any, keys: Array<String>, numberOfCharactersToMask: Number = 4, maskWithCharacter: String = "*"): Any = do {
    applyMask(data, keys, "first", numberOfCharactersToMask, maskWithCharacter)
}

/** Keeps only the last N characters visible under matching keys. */
fun maskExceptLast(data: Any, keys: Array<String>, numberOfCharactersToKeep: Number = 4, maskWithCharacter: String = "*"): Any = do {
    applyMask(data, keys, "exceptLast", numberOfCharactersToKeep, maskWithCharacter)
}

/** Keeps only the first N characters visible under matching keys. */
fun maskExceptFirst(data: Any, keys: Array<String>, numberOfCharactersToKeep: Number = 4, maskWithCharacter: String = "*"): Any = do {
    applyMask(data, keys, "exceptFirst", numberOfCharactersToKeep, maskWithCharacter)
}

/** Fully masks values under field names matching the entire regular expression. */
fun maskFieldsByPattern(data: Any, pattern: String | Regex, maskWithCharacter: String = "*"): Any = do {
    applyMask(data, pattern as Regex, "all", 0, maskWithCharacter)
}
