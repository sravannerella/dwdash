%dw 2.5
import * from dw::test::Tests
import * from dw::test::Asserts
import mapLeaves from Shared
---
"Shared module" describedBy [
    "mapLeaves transforms scalar leaves and preserves containers" in do {
        var sample = {
            name: "Ada",
            nested: {count: 2, active: true},
            values: ["x", null]
        }
        ---
        mapLeaves(sample, (value) -> if (value is String) upper(value) else value) must equalTo({
            name: "ADA",
            nested: {count: 2, active: true},
            values: ["X", null]
        })
    }
]
