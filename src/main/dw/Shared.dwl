%dw 2.9

fun mapLeaves(data: Any, mapper: (Any) -> Any): Any =
    if (data is Object)
        data mapObject ((value, key) -> {(key): mapLeaves(value, mapper)})
    else if (data is Array)
        data map ((value) -> mapLeaves(value, mapper))
    else mapper(data)