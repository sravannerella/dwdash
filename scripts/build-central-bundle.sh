#!/usr/bin/env bash
set -euo pipefail

version="${1:?Usage: build-central-bundle.sh VERSION}"
artifact="dwdash-${version}"
staging_root="target/central-corrected"
artifact_dir="${staging_root}/io/github/sravannerella/dwdash/${version}"
bundle="target/central-publishing/central-bundle.zip"

files=(
  "target/${artifact}-dw-library.jar"
  "target/${artifact}-dw-library.jar.asc"
  "target/${artifact}-sources.jar"
  "target/${artifact}-sources.jar.asc"
  "target/${artifact}-javadoc.jar"
  "target/${artifact}-javadoc.jar.asc"
  "target/${artifact}.pom.asc"
  "pom.xml"
)

for file in "${files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Missing Maven Central artifact: $file" >&2
    exit 1
  fi
done

rm -rf "$staging_root"
mkdir -p "$artifact_dir" "$(dirname "$bundle")"

cp "target/${artifact}-dw-library.jar" "$artifact_dir/"
cp "target/${artifact}-dw-library.jar.asc" "$artifact_dir/"
cp "target/${artifact}-sources.jar" "$artifact_dir/"
cp "target/${artifact}-sources.jar.asc" "$artifact_dir/"
cp "target/${artifact}-javadoc.jar" "$artifact_dir/"
cp "target/${artifact}-javadoc.jar.asc" "$artifact_dir/"
cp pom.xml "$artifact_dir/${artifact}.pom"
cp "target/${artifact}.pom.asc" "$artifact_dir/"

while IFS= read -r -d '' file; do
  md5sum "$file" | awk '{print $1}' > "${file}.md5"
  sha1sum "$file" | awk '{print $1}' > "${file}.sha1"
done < <(find "$artifact_dir" -type f ! -name '*.asc' ! -name '*.md5' ! -name '*.sha1' -print0)

rm -f "$bundle"
(
  cd "$staging_root"
  zip -q -r "../central-publishing/central-bundle.zip" .
)

echo "Created corrected Maven Central bundle: $bundle"
