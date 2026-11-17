# dwdash

`dwdash` is a reusable MuleSoft DataWeave 2.x library for common JSON cleanup, field selection, recursive key manipulation, and sensitive-data masking. It is packaged as a `dw-library` Maven artifact and can be imported from Mule applications or other DataWeave libraries.

## Requirements

- Java 8 or later
- Maven 3.8 or later
- Access to the MuleSoft Maven repositories declared in `pom.xml`

## Quick start

Build the library and run its complete test suite:

```bash
mvn clean test
```

Package the reusable JAR:

```bash
mvn clean package
```

The artifact is written to `target/dwdash-0.1.0-SNAPSHOT-dw-library.jar`. To consume a local build from another Maven project, first run `mvn install`, then add:

```xml
<dependency>
  <groupId>org.askme</groupId>
  <artifactId>dwdash</artifactId>
  <version>0.1.0-SNAPSHOT</version>
  <classifier>dw-library</classifier>
</dependency>
```

Import only the functions needed by a DataWeave script:

```dataweave
%dw 2.0
output application/json
import maskExceptLast from Masks
import omitKeys, trimStrings from Objects
---
maskExceptLast(
  trimStrings(omitKeys(payload, ["internalNote"])),
  ["cardNumber"],
  4
)
```

## Available functions

| Module | Function | Description |
| --- | --- | --- |
| `Shared` | `mapLeaves(data, mapper)` | Recursively applies a mapper to scalar leaves while preserving objects and arrays. |
| `Objects` | `omitKeys(data, keys)` | Recursively removes fields whose names occur in `keys`. |
| `Objects` | `hasKeys(data, keys)` | Checks whether an object has all requested direct keys; returns one Boolean per array item. |
| `Objects` | `pickKeys(data, keys)` | Selects requested direct fields from objects, including objects in arrays. |
| `Objects` | `renameKeys(data, names)` | Recursively renames keys using an old-to-new name map; rejects collisions and non-string targets. |
| `Objects` | `trimStrings(data)` | Recursively trims strings without coercing other scalar types. |
| `Objects` | `blankToNull(data)` | Recursively converts empty and whitespace-only strings to `null`. |
| `Masks` | `applyMask(data, keys, mode, count, character)` | Low-level masking primitive used by the convenience functions. |
| `Masks` | `maskIt(data, maskWithCharacter = "*")` | Fully masks every JSON scalar leaf. |
| `Masks` | `maskKeys(data, keys, maskWithCharacter = "*")` | Fully masks leaves below fields with the selected names. |
| `Masks` | `maskLast(data, keys, numberOfCharactersToMask = 4, maskWithCharacter = "*")` | Masks the last N characters. |
| `Masks` | `maskFirst(data, keys, numberOfCharactersToMask = 4, maskWithCharacter = "*")` | Masks the first N characters. |
| `Masks` | `maskExceptLast(data, keys, numberOfCharactersToKeep = 4, maskWithCharacter = "*")` | Masks everything except the last N characters. |
| `Masks` | `maskExceptFirst(data, keys, numberOfCharactersToKeep = 4, maskWithCharacter = "*")` | Masks everything except the first N characters. |
| `Masks` | `maskFieldsByPattern(data, pattern, maskWithCharacter = "*")` | Fully masks values under field names matched by a full regular expression. |

Masking preserves `null`, but stringifies masked numbers and Booleans because a masked value is replacement text. Counts must be non-negative integers. A one-character replacement is repeated to the masked length; a multi-character replacement such as `[redacted]` replaces the selected masked portion as one literal string.

## Examples

### Remove and rename fields

```dataweave
%dw 2.0
output application/json
import omitKeys, renameKeys from Objects
var input = {
  first_name: "Ada",
  password: "secret",
  profile: {first_name: "Augusta", password: "hidden"}
}
---
renameKeys(omitKeys(input, ["password"]), {first_name: "firstName"})
```

Result:

```json
{"firstName":"Ada","profile":{"firstName":"Augusta"}}
```

### Normalize string values

```dataweave
%dw 2.0
output application/json
import trimStrings, blankToNull from Objects
---
blankToNull(trimStrings({name: "  Ada  ", nickname: "   ", active: true}))
```

Result:

```json
{"name":"Ada","nickname":null,"active":true}
```

### Mask selected values

```dataweave
%dw 2.0
output application/json
import maskExceptLast, maskFieldsByPattern from Masks
var input = {
  cardNumber: "4111111111111111",
  apiKey: "abc123",
  displayName: "Ada"
}
---
maskFieldsByPattern(
  maskExceptLast(input, ["cardNumber"], 4),
  /.*Key/
)
```

Result:

```json
{"cardNumber":"************1111","apiKey":"******","displayName":"Ada"}
```

## Testing and releases

Tests live in `src/test/dw/*Test.dwl` and cover every public function, recursion, arrays, boundary conditions, and validation failures. Run them with `mvn clean test`; the HTML report is generated under `target/data-weave-test-reports/`.

The GitHub Actions workflow runs the same tests on every push to `main` and on pull requests targeting `main`. Successful main builds upload the packaged library as a workflow artifact. To create a reusable GitHub Release, push a semantic-version tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

The workflow tests the tagged commit, sets the Maven artifact version from the tag (for example, `v0.1.0` becomes `0.1.0`), packages the library, and attaches the versioned JAR to the GitHub Release.

## Consume from GitHub Packages

Released versions are also published as Maven packages at `https://maven.pkg.github.com/sravannerella/dwdash` using these coordinates:

```text
org.askme:dwdash:0.1.0
```

GitHub requires authentication when downloading Maven packages, including public packages. Create a classic personal access token with `read:packages`, then add a matching server to `~/.m2/settings.xml`:

```xml
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd">
  <servers>
    <server>
      <id>github</id>
      <username>YOUR_GITHUB_USERNAME</username>
      <password>YOUR_GITHUB_TOKEN</password>
    </server>
  </servers>
</settings>
```

Add the registry and dependency to the consuming project's `pom.xml`:

```xml
<repositories>
  <repository>
    <id>github</id>
    <url>https://maven.pkg.github.com/sravannerella/dwdash</url>
  </repository>
</repositories>

<dependencies>
  <dependency>
    <groupId>org.askme</groupId>
    <artifactId>dwdash</artifactId>
    <version>0.1.0</version>
    <classifier>dw-library</classifier>
  </dependency>
</dependencies>
```

Every future `v*` tag publishes the package after tests pass. The workflow can also republish an existing release version through **Run workflow** by supplying `release_version`.
