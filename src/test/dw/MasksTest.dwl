%dw 2.5
import * from dw::test::Tests
import * from dw::test::Asserts
import try from dw::Runtime
import applyMask, maskIt, maskKeys, maskLast, maskFirst, maskExceptLast, maskExceptFirst, maskFieldsByPattern from Masks

fun failed(operation: () -> Any): Boolean =
    try(operation) match {
        case result if (result.success == false) -> true
        else -> false
    }
---
"Masks module" describedBy [
    "maskIt masks every scalar leaf and preserves null" in do {
        var sample = {name: "Ada", age: 36, active: true, missing: null, tags: ["math"]}
        ---
        maskIt(sample) must equalTo({name: "***", age: "**", active: "****", missing: null, tags: ["****"]})
    },
    "maskKeys masks matching fields and all leaves below matching containers" in do {
        var sample = {password: "secret", profile: {token: "abc", public: "yes"}, rows: [{password: 1234}]}
        ---
        maskKeys(sample, ["password", "profile"], "#") must equalTo({
            password: "######",
            profile: {token: "###", public: "###"},
            rows: [{password: "####"}]
        })
    },
    "maskKeys does nothing when no keys are selected" in do {
        maskKeys({password: "secret"}, []) must equalTo({password: "secret"})
    },
    "maskLast masks the requested suffix" in do {
        maskLast({card: "12345678"}, ["card"], 4) must equalTo({card: "1234****"})
    },
    "maskFirst masks the requested prefix" in do {
        maskFirst({card: "12345678"}, ["card"], 4) must equalTo({card: "****5678"})
    },
    "maskExceptLast keeps the requested suffix visible" in do {
        maskExceptLast({card: "12345678"}, ["card"], 4) must equalTo({card: "****5678"})
    },
    "maskExceptFirst keeps the requested prefix visible" in do {
        maskExceptFirst({card: "12345678"}, ["card"], 4) must equalTo({card: "1234****"})
    },
    "masking count larger than the value masks the complete value" in do {
        maskFirst({code: "abc"}, ["code"], 10, "#") must equalTo({code: "###"})
    },
    "multi-character replacement text is used as-is" in do {
        maskKeys({token: "secret"}, ["token"], "[redacted]") must equalTo({token: "[redacted]"})
    },
    "maskFieldsByPattern masks field names matched by the complete regex" in do {
        var sample = {apiKey: "abc", accessKey: "def", keyHint: "visible", nested: {apiKey: "ghi"}}
        ---
        maskFieldsByPattern(sample, /.*Key/) must equalTo({
            apiKey: "***",
            accessKey: "***",
            keyHint: "visible",
            nested: {apiKey: "***"}
        })
    },
    "applyMask supports direct regex selection" in do {
        applyMask({pin: "1234", label: "safe"}, /pin/, "first", 2, "#") must equalTo({pin: "##34", label: "safe"})
    },
    "applyMask rejects negative character counts" in do {
        var didFail = failed(() -> applyMask({pin: "1234"}, ["pin"], "first", -1, "*"))
        ---
        {matches: didFail, description: "Expected applyMask to reject a negative count"} as MatcherResult
    },
    "applyMask rejects fractional character counts" in do {
        var didFail = failed(() -> applyMask({pin: "1234"}, ["pin"], "first", 1.5, "*"))
        ---
        {matches: didFail, description: "Expected applyMask to reject a fractional count"} as MatcherResult
    },
    "masking rejects non-scalar values that cannot be traversed as JSON" in do {
        var didFail = failed(() -> maskIt(|2026-01-01|))
        ---
        {matches: didFail, description: "Expected maskIt to reject a non-JSON scalar"} as MatcherResult
    }
]
