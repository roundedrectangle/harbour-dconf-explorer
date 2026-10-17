# DConf Explorer

DConf Explorer allows you to view, read, modify and monitor the DConf database.

## Implementation details

SailfishOS has Nemo.Configuration for operating dconf. However, it misses several functions, such as listing a directory, watching the whole directory and not just one key or checking if a key is writable. For these features, a Python script connects to the dconf client library via ctypes. Alternatively, we could link to dconf client and use it from C++, but that wouldn't be harbour-compatible. Using the dconf command-line tool wouldn't be very viable either, since Sailjail doesn't allow that. Using dlopen from C++ would probably actually work, but to keep things simple, a Python script was chosen instead.

## Icon

`harbour-dconf-explorer.svg` is currently used. `harbour-dconf-explorer2.svg` is an alternative version, which is unfinished, but could potentially replace the current variant.