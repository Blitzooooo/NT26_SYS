@echo off
setlocal enabledelayedexpansion

rem check params
if "%~1" == "" (
    echo error: please input pkg path as first param
    exit /b 1
)

if "%~2" == "" (
    echo error: please input port name as second param
    exit /b 1
)

rem get params values
set port_name=%~2

rem copy pkg file to current directory
copy /y "%~1" "." >nul
for %%F in ("%~1") do set "pkg_filename=%%~nxF"
set new_arg_pkg_path_val=%pkg_filename%

rem config file path
set config_file=config_pkg_product_usb.ini

rem temp file path
set temp_file=temp.ini

set "arg_pkg_path_val=%new_arg_pkg_path_val%"

echo "init pkg_%arg_pkg_path_val%"
echo "config_file: %config_file%"

rem first pass: only update arg_pkg_path_val in config
>%temp_file% (
    for /f "delims=" %%A in ('type "%config_file%"') do (
        set "line=%%A"
        setlocal enabledelayedexpansion
        if "!line:arg_pkg_path_val =!" neq "!line!" (
            echo arg_pkg_path_val = !arg_pkg_path_val!
        ) else (
            echo !line!
        )
        endlocal
    )
)
move /y %temp_file% %config_file% >nul
echo "pkg_ini update arg_pkg_path_val success!"

FlashToolCLI.exe --cfgfile config_pkg_product_usb.ini pkg2img

FlashToolCLI.exe --cfgfile config_pkg_product_usb.ini --port %port_name% probe

rem read productname from imagedata.json
set "new_selected_product="
for /f "tokens=2 delims=:," %%A in ('findstr /c:"productname" imagedata.json') do (
    set "tmp=%%~A"
    set "new_selected_product=!tmp: =!"
)
set "new_selected_product=!new_selected_product:"=!"

if "!new_selected_product!" == "" (
    echo error: failed to read productname from imagedata.json
    exit /b 1
)
echo "detected productname: !new_selected_product!"

rem second pass: update selected_product in config
set "selected_product=!new_selected_product!"
>%temp_file% (
    for /f "delims=" %%A in ('type "%config_file%"') do (
        set "line=%%A"
        setlocal enabledelayedexpansion
        if "!line:selected_product =!" neq "!line!" (
            echo selected_product = !selected_product!
        ) else (
            echo !line!
        )
        endlocal
    )
)
move /y %temp_file% %config_file% >nul
echo "pkg_ini update selected_product success!"

rem read format_path from config
set "format_path="
for /f "tokens=1,* delims==" %%A in ('findstr /c:"format_path" %config_file%') do (
    set "format_path=%%B"
)
set "format_path=!format_path: =!"

if "!format_path!" == "" (
    echo error: failed to read format_path from %config_file%
    exit /b 1
)
echo "format_path: !format_path!"

rem parse erallum from format json and execute flasherase
set "in_erallum=0"
set "cur_begin="
set "cur_length="
set "cur_stor_type="
for /f "usebackq tokens=* delims=" %%L in ("!format_path!") do (
    set "jline=%%L"
    if "!jline:erallum=!" neq "!jline!" set "in_erallum=1"
    if "!in_erallum!" == "1" (
        if "!jline:stor_type=!" neq "!jline!" (
            for /f "tokens=2 delims=:," %%V in ("!jline!") do (
                set "tmp=%%~V"
                set "cur_stor_type=!tmp: =!"
                set "cur_stor_type=!cur_stor_type:"=!"
            )
        )
        if "!jline:begin=!" neq "!jline!" (
            for /f "tokens=2 delims=:," %%V in ("!jline!") do (
                set "tmp=%%~V"
                set "cur_begin=!tmp: =!"
                set "cur_begin=!cur_begin:"=!"
            )
        )
        if "!jline:length=!" neq "!jline!" (
            for /f "tokens=2 delims=:," %%V in ("!jline!") do (
                set "tmp=%%~V"
                set "cur_length=!tmp: =!"
                set "cur_length=!cur_length:"=!"
            )
            echo FlashToolCLI.exe --skipconnect 1 --cfgfile %config_file% --port %port_name% flasherase !cur_begin! !cur_length! --stor_type "!cur_stor_type!"
            FlashToolCLI.exe --skipconnect 1 --cfgfile %config_file% --port %port_name% flasherase !cur_begin! !cur_length! --stor_type "!cur_stor_type!"
        )
        rem detect end of erallum array
        if "!jline!" == "	]" set "in_erallum=0"
    )
)

rem build imglist dynamically from pkg_extract_tmp file count
rem base images: bootloader system cp_system (3 items)
rem each extra file beyond 3 appends one flex partition pkgflx0, pkgflx1, ...
rem   4 files -> pkgflx0; 5 files -> pkgflx0 pkgflx1; 6 files -> pkgflx0 pkgflx1 pkgflx2
set "file_count=0"
for %%F in (pkg_extract_tmp\*) do set /a file_count+=1
set "imglist=bootloader system cp_system"
if !file_count! geq 4 (
    set /a flex_max=file_count-4
    for /l %%I in (0,1,!flex_max!) do set "imglist=!imglist! pkgflx%%I"
)
echo "pkg_extract_tmp has !file_count! files, imglist: !imglist!"

FlashToolCLI.exe --port %port_name% --cfgfile config_pkg_product_usb.ini --skipconnect 1 runtmcfg

FlashToolCLI.exe --skipconnect 1 --cfgfile config_pkg_product_usb.ini --verbose 1 --port %port_name% burnbatch --imglist !imglist!

FlashToolCLI.exe --skipconnect 1 --cfgfile config_pkg_product_usb.ini --port %port_name% sysreset
