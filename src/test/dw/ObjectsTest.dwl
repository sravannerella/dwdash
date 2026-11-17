%dw 2.5
import * from dw::test::Tests
import * from dw::test::Asserts
import try from dw::Runtime
import omitKeys, hasKeys, pickKeys, renameKeys, trimStrings, blankToNull from Objects

fun failed(operation: () -> Any): Boolean =
    try(operation) match {
        case result if (result.success == false) -> true
        else -> false
    }
---
"Objects module" describedBy [
    "omitKeys removes matching keys at every depth" in do {
        var sample = {id: 1, secret: "top", nested: {secret: "inner", keep: true}, rows: [{secret: "row", id: 2}]}
        ---
        omitKeys(sample, ["secret"]) must equalTo({id: 1, nested: {keep: true}, rows: [{id: 2}]})
    },
    "omitKeys returns the original structure for an empty key list" in do {
        omitKeys({id: 1}, []) must equalTo({id: 1})
    },
    "hasKeys checks direct object keys and treats null as present" in do {
        var sample = [{id: 1, note: null}, {id: 2}, "not-an-object"]
        ---
        hasKeys(sample, ["id", "note"]) must equalTo([true, false, false])
    },
    "pickKeys selects direct fields and preserves array order" in do {
        var sample = [{id: 1, name: "Ada", extra: true}, {id: 2, name: "Lin", extra: false}]
        ---
        pickKeys(sample, ["id", "name"]) must equalTo([{id: 1, name: "Ada"}, {id: 2, name: "Lin"}])
    },
    "renameKeys renames keys recursively" in do {
        var sample = {first_name: "Ada", nested: {first_name: "Lin"}}
        ---
        renameKeys(sample, {first_name: "firstName"}) must equalTo({firstName: "Ada", nested: {firstName: "Lin"}})
    },
    "renameKeys rejects non-string target names" in do {
        var didFail = failed(() -> renameKeys({id: 1}, {id: 2}))
        ---
        {matches: didFail, description: "Expected renameKeys to reject a non-string target"} as MatcherResult
    },
    "renameKeys rejects duplicate keys created by a rename" in do {
        var didFail = failed(() -> renameKeys({first: "Ada", name: "Lovelace"}, {first: "name"}))
        ---
        {matches: didFail, description: "Expected renameKeys to reject a key collision"} as MatcherResult
    },
    "trimStrings trims strings recursively without coercing other scalars" in do {
        var sample = {name: "  Ada  ", nested: [" x ", 4, true, null]}
        ---
        trimStrings(sample) must equalTo({name: "Ada", nested: ["x", 4, true, null]})
    },
    "blankToNull converts only blank strings" in do {
        var sample = {empty: "", spaces: "   ", value: " Ada ", count: 0}
        ---
        blankToNull(sample) must equalTo({empty: null, spaces: null, value: " Ada ", count: 0})
    }
]
