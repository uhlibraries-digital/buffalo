# buffalo
Bayou City DAMS digital collections migration utilities

---

## carpenters_test_collections.rb
Produce preservation ingest files for Bayou City DAMS Phase One development

### Inputs
* ArchivesSpace EAD.xml
* CONTENTdm API data

### Output
* CSV for [Carpenters](https://github.com/uhlibraries-digital/carpenters) ingest 

---

## ead_hierarchy.rb
Produce reports and hierarchical representations of ArchivesSpace entities for finding aid cleanup

### Input
* ArchivesSpace EAD.xml

### Outputs
* CSV files outlining collection hierarchy and entities
* `html_tags.txt` report indicating HTML tags in EAD `<unittitle>`
* `empty_finding_aids.txt` report indicating collections with empty finding aids

---

## archivesspace_ead.py
Downloads EAD from ArchivesSpace given resource URL or homepage URL

`Usage: archivesspace_ead.py [USERNAME] [PASSWORD] [URL]`

Url can be to a ArchivesSpace resouce or the homepage to retrieve all finding aid EADs.

User must be in ArchivesSpace with proper permissions to retrieve EAD information.

### Outputs
* EAD directory containing .xml EAD for givin finding aid url in ArchivesSpace
