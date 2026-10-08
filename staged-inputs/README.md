# Staged inputs: scripts and crosswalks for the PUMS route

These are the scripts (01 to 06) that built and audited the occupation crosswalk,
extracted the prime-age PUMS samples, and ran the pre-launch checks for the
2022-2024 extension, together with the built crosswalk tables and the data
manifest. The raw Census PUMS zips they consume are not shipped; their URLs and
checksums are in DATA_MANIFEST.md. With those downloads in place, these scripts
rebuild every input the extension's 001 study starts from.
