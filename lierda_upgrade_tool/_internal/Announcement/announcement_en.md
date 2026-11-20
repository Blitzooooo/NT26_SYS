## SDK V0107 Release Notes

### Special Notes

<span style="color:#d32f2f; font-weight:bold;">Modules using the 718_M series chip must be upgraded to this version, otherwise subsequent new-batch modules may fail to start. The related tools have been upgraded accordingly, please use the latest version of the tool.</span>

### Added

- Added hardware timer liot_timer interface
- Added VSIM support
- Added liot_telldir, liot_seekdir, liot_rewinddir interfaces to the file system
- Added direct access to 8k/16k Chinese & English TTS libraries
- Added base packages F6D_D/F9D_D with 3A algorithm support
- Added F7D_A, supporting the NT26F7D0 base package with votle
- Added liot_jpeg interface and example demo
- Router project: improved network speed and stability; added IPv6 and CLAT support
- fota demo: added a UART upgrade example
- Added support for a built-in file system during flashing
- Added support for module models NT26F7D0, NT26F8D0, NT26F8D0-0K, NT26F8D0-0TK

### Changed

- Optimized the liot_audio interface; added spicodec functionality
- MQTT connection now supports configuring send/receive buffer size, send/receive timeout, and reconnection count
- Renamed the L_CT4IT00_YP00W_01_V04 example to NT26FxDx_OpenKit and added demo_watch

### Fixed

- Fixed the compilation issue of the third-party library lvgl
- Optimized the crash bug caused by third-party MQTT exception handling
- Fixed the abnormal sim2 recognition bug on the F6D series
- Optimized some compilation and comments
