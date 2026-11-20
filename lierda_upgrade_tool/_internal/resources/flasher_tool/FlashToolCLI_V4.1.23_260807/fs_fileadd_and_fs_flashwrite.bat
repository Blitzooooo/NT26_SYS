@echo off
setlocal enabledelayedexpansion

rem Check input parameters
if "%~1" == "" (
    echo error: please input pkg path as first param
    exit /b 1
)

if "%~2" == "" (
    echo error: please input port name as second param
    exit /b 1
)

if "%~3" == "" (
    echo error: please input file path as third param
    exit /b 1
)

if "%~4" == "" (
    echo error: please input file name as fourth param
    exit /b 1
)

if "%~5" == "" (
    echo error: please input startaddr as fifth param
    exit /b 1
)

if "%~6" == "" (
    echo error: please input size as sixth param
    exit /b 1
)

rem Get parameters
set port_name=%~2

rem Copy pkg file to current directory
copy /y "%~1" "." >nul
for %%F in ("%~1") do set "pkg_filename=%%~nxF"
set new_arg_pkg_path_val=%pkg_filename%

set fs_image=flash_addr_len.bin
set fs_image_new=new_flash_addr_len.bin
set new_file_path=%~3
set new_file_name=%~4
set lfsutil_path=lfsutil.exe
set startaddr=%~5
set size=%~6

rem Config file path
set config_file=config_pkg_product_usb.ini

rem Temp file path
set temp_file=temp.ini

set "arg_pkg_path_val=%new_arg_pkg_path_val%"

set "target_section=[flexfile1]"
set "new_burnaddr=%startaddr%"
set "new_filepath=%cd%\new_flash_addr_len.bin"

echo "init pkg_%arg_pkg_path_val%"
echo "config_file: %config_file%"

rem ====================== First pass: update arg_pkg_path_val only ======================
> "%temp_file%" (
    for /f "usebackq delims=" %%A in ("%config_file%") do (
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
move /y "%temp_file%" "%config_file%" >nul
echo "pkg_ini update arg_pkg_path_val success!"

rem Write file to file system image
copy "%fs_image%" "%fs_image_new%" >nul
%lfsutil_path% -i %fs_image_new% -w -f %new_file_name% -F %new_file_path%
echo "add success!"

rem Execute pkg2img and probe
FlashToolCLI.exe --cfgfile config_pkg_product_usb.ini pkg2img

FlashToolCLI.exe --cfgfile config_pkg_product_usb.ini --port %port_name% probe

rem ====================== Dynamic: read productname from imagedata.json ======================
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

rem ====================== Second pass: update selected_product in config ======================
set "selected_product=!new_selected_product!"
> "%temp_file%" (
    for /f "usebackq delims=" %%A in ("%config_file%") do (
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
move /y "%temp_file%" "%config_file%" >nul
echo "pkg_ini update selected_product success!"

rem ====================== Third pass: update or append [flexfile1] after probe ======================
set "in_section=0"
set "section_found=0"
> "%temp_file%" (
    for /f "usebackq delims=" %%A in ("%config_file%") do (
        set "line=%%A"

        if "!line:~0,1!" equ "[" if "!line:~-1!" equ "]" (
            set "in_section=0"
            if "!line!" equ "!target_section!" (
                set "in_section=1"
                set "section_found=1"
            )
        )

        if !in_section! equ 1 (
            if not "!line:burnaddr=!" equ "!line!" (
                echo burnaddr = !new_burnaddr!
            ) else if not "!line:filepath=!" equ "!line!" (
                echo filepath = !new_filepath!
            ) else (
                echo !line!
            )
        ) else (
            echo !line!
        )
    )
)
rem If [flexfile1] section not found, append it
if "!section_found!" == "0" (
    echo.>> "%temp_file%"
    echo [flexfile1]>> "%temp_file%"
    echo filepath = !new_filepath!>> "%temp_file%"
    echo burnaddr = !new_burnaddr!>> "%temp_file%"
)
move /y "%temp_file%" "%config_file%" >nul
echo "pkg_ini update [flexfile1] burnaddr = %startaddr%, filepath = %new_filepath% success!"

rem Flash operations
FlashToolCLI.exe --skipconnect 1 --cfgfile config_pkg_product_usb.ini --port %port_name% flasherase %startaddr% %size% --stor_type "ap_flash"

FlashToolCLI.exe --skipconnect 1 --cfgfile config_pkg_product_usb.ini --verbose 1 --port %port_name% burnbatch --imglist flexfile1

FlashToolCLI.exe --skipconnect 1 --cfgfile config_pkg_product_usb.ini --port %port_name% sysreset

endlocal
