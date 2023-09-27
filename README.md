Tool for making Parcel and CSD of Apache Kyuubi
===

```
build/dist - tool for making Parcel and CSD of Apache Kyuubi

Usage:
+----------------------------------------+
| build/dist [--parcel] [--csd] [--all]  |
+----------------------------------------+
parcel: -  build Parcel
csd:    -  build CSD
all:    -  build Parcel and CSD
```

The output of Parcel and CSD
```
$ tree *-dist
csd-dist
└── KYUUBI-1.7.3-p0-csd.jar
parcel-dist
├── KYUUBI-1.7.3-p0-el7.parcel
└── manifest.json
```
