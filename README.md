# buffalo
Bayou City DAMS digital collections migration utilities

---

## element_list.rb

This script creates lists of unique CONTENTdm values for each of the elements defined in a crosswalk config file. Each value is checked against the [University of Houston Libraries Vocabularies](https://vocab.lib.uh.edu). If an exact match is found, then the ARK identifier for that vocabulary term is recorded in the report for that element.

### Usage

In a command prompt, enter a CDM collection alias, crosswalk file name from the 'dmwg' directory, and your name as shown in your O: drive config file.
Example: `ruby element_list.rb p15195coll38 p15195coll38_crosswalk andy`

### Workflow

1. Before running `element_list.rb`, pull any recent changes to the DMWG repository.
2. If necessary, create a new project folder in the DMWG repository for the CONTENTdm collection.
3. Run `element_list.rb` with the instructions above.
4. Commit reports to the DMWG repository to share with the metadata team if desired.

## migration_report.rb

This script creates reports for the BCDAMS-MAP Migration site: https://vocab.lib.uh.edu/bcdams-map/migration

### Usage

In a command prompt, enter a CDM collection alias, crosswalk file name from the 'dmwg' directory, and your name as shown in your O: drive config file.
Example: `ruby migration_report.rb p15195coll38 p15195coll38_crosswalk andy`

### Workflow

1. Before running `migration_report.rb`, pull any recent changes to the BCDAMS-MAP repository.
2. Run `migration_report.rb` with the instructions above.
3. If desired, edit the new report link `label:` in `bcdams-map/_data/migration.yml`.
4. After running `migration_report.rb` and making edits to the report `label:`, push the changes to the BCDAMS-MAP repository. Results will be immediately available here: https://uhlibraries-digital.github.io/bcdams-map/migration/
5. The changes to BCDAMS-MAP will be available here on the following day: https://vocab.lib.uh.edu/bcdams-map/migration

## Crosswalk Configuration

The output of these scripts depends on a valid metadata crosswalk config file in the [dmwg](https://github.com/uhlibraries-digital/dmwg) repository. The crosswalk config must be nested in the project folder for a CONTENTdm collection. Each element from the BCDAMS-MAP should be followed with a list of CONTENTdm field labels, as shown below.

Example Config: `crosswalk_controlled_vocab.yml`
```yaml
creator:
  - Creator (LCNAF)
  - Creator (HOT)
  - Creator (ULAN)
  - Creator (Local)

publisher:
  - Publisher

subject:
  - Subject.Topical (LCSH)
  - Subject.Topical (TGM-1)
  - Subject.Topical (AAT)
  - Subject.Topical (SAA)
  - Subject.Topical (Local)
  - Subject.Name (LCNAF)
  - Subject.Name (HOT)
  - Subject.Name (ULAN)
  - Subject.Name (Local)
```

## Personal Configuration

In order to run these scripts, you must have a valid personal config file in the following folder: `O:\Metadata and Digitization Services\Metadata\Migration\config`

Example Config: `andy.yml`
```yaml
dmwg: 'M:\Software\dmwg'
map: 'M:\Software\bcdams-map'
items:
```
- `dmwg:` points to the location of your local [dmwg](https://github.com/uhlibraries-digital/dmwg) repository clone.
- `map:` points to the location of your local [bcdams-map](https://github.com/uhlibraries-digital/bcdams-map) repository clone.
- `items:` identifies the CDM numbers for a collection subset in the following format: `[363,350,358]`. This must be left blank (shown in the Example Config) if the report should include all items in a collection.
