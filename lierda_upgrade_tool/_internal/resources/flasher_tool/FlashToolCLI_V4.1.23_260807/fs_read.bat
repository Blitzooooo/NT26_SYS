@echo off
setlocal enabledelayedexpansion

 rem get param
 rem param1: new_arg_pkg_path_val (pkg path)
 rem param2: port_name
 rem param3: start_addr
 rem param4: flash_size

 if "%~1" neq "" (
     set new_arg_pkg_path_val=%~1
 ) else (
     echo "error: please input pkg path as first param"
     exit /b 1
 )

 if "%~2" neq "" (
     set port_name=%~2
 ) else (
     echo "error: please input port name as second param"
     exit /b 1
 )

 if "%~3" neq "" (
     set start_addr=%~3
 ) else (
     echo "error: please input start addr as third param"
     exit /b 1
 )

 if "%~4" neq "" (
     set flash_size=%~4
 ) else (
     echo "error: please input flash size as fouth param"
     exit /b 1
 )

 echo "using port: %port_name%"
 echo "start: %start_addr%"
 echo "size: %flash_size%"

rem Copy pkg file to current directory
copy /y "%~1" "." >nul
for %%F in ("%~1") do set "pkg_filename=%%~nxF"
set arg_pkg_path_val=%pkg_filename%

rem Config file path
set config_file=config_pkg_product_usb.ini
set temp_file=temp.ini

echo "config_file: %config_file%"

rem First pass: update arg_pkg_path_val in config
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

rem Dynamic: read productname from imagedata.json
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

rem Second pass: update selected_product in config
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

FlashToolCLI.exe --skipconnect 1 --cfgfile config_pkg_product_usb.ini --port %port_name% flashread %start_addr% %flash_size% --memrbf flash_addr_len.bin --stor_type=ap_flash

FlashToolCLI.exe --skipconnect 1 --cfgfile config_pkg_product_usb.ini --port %port_name% sysreset

endlocal