# Register RTL and specifications

The authoritative YAML register specifications are in `spec/`. The generated
synthesis closure is checked in beside this README: package definitions,
package-list includes, hit decoders, and main MMR modules for all six blocks.
Serial generator outputs are intentionally excluded.

The generated RTL is transformed for the open-source profile: FUSA/RAS
interfaces and logic are removed, protected infrastructure flops use
`generic_dff`, and assertions use the public generic assertion macros.
`opensrc_generation_manifest.json` records source and released hashes. Do not
edit generated files by hand.
