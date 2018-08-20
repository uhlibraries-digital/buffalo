# buffalo
Bayou City DAMS digital collections migration utilities

---

## migration_report.rb

This script creates reports for the BCDAMS-MAP Migration site: https://vocab.lib.uh.edu/bcdams-map/migration

Usage: In a command prompt, enter a CDM collection alias, crosswalk file name from the 'dmwg' directory, and your name as shown in your O: drive config file.
Example: `ruby migration_report.rb p15195coll38 p15195coll38_crosswalk andy`

You must have a valid config file in the following folder: `O:\Metadata and Digitization Services\Metadata\Migration\config`
Example Config: `andy.yml`
```yaml
dmwg: 'M:\Software\dmwg'
map: 'M:\Software\bcdams-map'
items:
```

`dmwg:` points to the location of your local [dmwg](https://github.com/uhlibraries-digital/dmwg) repository clone.
`map:` points to the location of your local [bcdams-map](https://github.com/uhlibraries-digital/bcdams-map) repository clone.
`items:` identifies the CDM numbers for a collection subset in the following format: `[363,350,358]`. This must be left blank (shown in the Example Config) if the report should include all items in a collection.

After running this script, push the changes to the BCDAMS-MAP repository. Results will be immediately available here: https://uhlibraries-digital.github.io/bcdams-map/migration/
