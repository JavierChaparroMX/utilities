@echo off
setlocal EnableDelayedExpansion

REM ============================================================
REM  BALU-SITE MEDIA OPTIMIZER v1.0
REM  100%% Native Windows Batch — No Node.js, no npm
REM  Only dependency: ffmpeg (https://ffmpeg.org/download.html)
REM
REM  Usage:
REM    optimize-media.bat                   Full conversion
REM    optimize-media.bat --dry-run         Preview only
REM    optimize-media.bat --continue        Skip already converted
REM    optimize-media.bat --skip-images     Videos only
REM    optimize-media.bat --skip-videos     Images only
REM    optimize-media.bat --verbose         Show ffmpeg output
REM    optimize-media.bat --image-quality 90
REM    optimize-media.bat --video-quality 26
REM ============================================================

title Balu-Site Media Optimizer

REM ── Defaults ────────────────────────────────────────────────
set "SOURCE=public"
set "OUTPUT=public-optimized"
set "IMG_QUALITY=80"
set "VID_CRF=28"
set "DRY_RUN=0"
set "CONTINUE_MODE=0"
set "SKIP_IMAGES=0"
set "SKIP_VIDEOS=0"
set "VERBOSE=0"
set "IMG_SKIP_KB=100"
set "VID_SKIP_KB=2048"

REM ── Parse Arguments ─────────────────────────────────────────
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--source"        ( set "SOURCE=%~2" & shift & shift & goto :parse_args )
if /i "%~1"=="--output"        ( set "OUTPUT=%~2" & shift & shift & goto :parse_args )
if /i "%~1"=="--image-quality" ( set "IMG_QUALITY=%~2" & shift & shift & goto :parse_args )
if /i "%~1"=="--video-quality" ( set "VID_CRF=%~2" & shift & shift & goto :parse_args )
if /i "%~1"=="--dry-run"       ( set "DRY_RUN=1" & shift & goto :parse_args )
if /i "%~1"=="--continue"      ( set "CONTINUE_MODE=1" & shift & goto :parse_args )
if /i "%~1"=="--skip-images"   ( set "SKIP_IMAGES=1" & shift & goto :parse_args )
if /i "%~1"=="--skip-videos"   ( set "SKIP_VIDEOS=1" & shift & goto :parse_args )
if /i "%~1"=="--verbose"       ( set "VERBOSE=1" & shift & goto :parse_args )
if /i "%~1"=="--help" goto :show_help
echo [WARN] Unknown argument: %~1
shift
goto :parse_args
:args_done

REM ── Check ffmpeg ────────────────────────────────────────────
where ffmpeg >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo.
    echo  [ERROR] ffmpeg not found in PATH!
    echo.
    echo  Download from: https://ffmpeg.org/download.html
    echo  Or with winget:  winget install Gyan.FFmpeg
    echo  Or with choco:   choco install ffmpeg
    echo.
    echo  After installing, make sure ffmpeg.exe is in your PATH.
    echo.
    pause
    exit /b 1
)

REM ── Banner ──────────────────────────────────────────────────
echo.
echo  ======================================================
echo       BALU-SITE MEDIA OPTIMIZER v1.0
echo       100%%%% Native Windows — Powered by ffmpeg
echo  ======================================================
echo.
echo  Source:         %SOURCE%
echo  Output:         %OUTPUT%
if "%DRY_RUN%"=="1" ( echo  Mode:           DRY RUN ^(no files will be written^)
) else ( echo  Mode:           LIVE )
echo  Image quality:  %IMG_QUALITY% ^(WebP^)
echo  Video CRF:      %VID_CRF% ^(lower = better^)
echo  Skip images ^< %IMG_SKIP_KB% KB, videos ^< %VID_SKIP_KB% KB
echo.

REM ── Initialize Counters ─────────────────────────────────────
set "IMG_COUNT=0"
set "IMG_SUCCESS=0"
set "IMG_SKIPPED=0"
set "IMG_ERROR=0"
set "VID_COUNT=0"
set "VID_SUCCESS=0"
set "VID_SKIPPED=0"
set "VID_ERROR=0"
set "TOTAL_ORIG_KB=0"
set "TOTAL_OPT_KB=0"

REM ── Initialize Log ──────────────────────────────────────────
set "LOGFILE=conversion.log"
echo ============================================ >> "%LOGFILE%"
echo  Conversion started: %DATE% %TIME% >> "%LOGFILE%"
echo  Source: %SOURCE% >> "%LOGFILE%"
echo  Output: %OUTPUT% >> "%LOGFILE%"
echo  Dry run: %DRY_RUN% >> "%LOGFILE%"
echo ============================================ >> "%LOGFILE%"

REM ── Initialize JSON Report ──────────────────────────────────
set "REPORTFILE=conversion-report.json"
set "TEMPFILES=conversion-files-temp.json"
if exist "%TEMPFILES%" del "%TEMPFILES%"
echo. > "%TEMPFILES%"
set "FIRST_FILE=1"

REM ── Create output dirs ──────────────────────────────────────
if "%DRY_RUN%"=="0" (
    if not exist "%OUTPUT%" mkdir "%OUTPUT%"
)

REM ══════════════════════════════════════════════════════════════
REM  IMAGE PROCESSING
REM ══════════════════════════════════════════════════════════════
if "%SKIP_IMAGES%"=="1" (
    echo  [SKIP] Image processing disabled.
    echo.
    goto :process_videos
)

echo  ── IMAGE CONVERSION ──────────────────────────────────────
echo.

for %%D in (images services reviews) do (
    if exist "%SOURCE%\%%D" (
        call :process_images_in "%SOURCE%\%%D" "%%D"
    ) else (
        echo  [INFO] Directory not found: %SOURCE%\%%D — skipping.
    )
)

echo.
echo  Images: %IMG_SUCCESS% converted, %IMG_SKIPPED% skipped, %IMG_ERROR% errors
echo.

REM ══════════════════════════════════════════════════════════════
REM  VIDEO PROCESSING
REM ══════════════════════════════════════════════════════════════
:process_videos
if "%SKIP_VIDEOS%"=="1" (
    echo  [SKIP] Video processing disabled.
    echo.
    goto :generate_report
)

echo  ── VIDEO CONVERSION ──────────────────────────────────────
echo.

for %%D in (images services reviews) do (
    if exist "%SOURCE%\%%D" (
        call :process_videos_in "%SOURCE%\%%D" "%%D"
    ) else (
        echo  [INFO] Directory not found: %SOURCE%\%%D — skipping.
    )
)

echo.
echo  Videos: %VID_SUCCESS% converted, %VID_SKIPPED% skipped, %VID_ERROR% errors
echo.

REM ══════════════════════════════════════════════════════════════
REM  REPORT
REM ══════════════════════════════════════════════════════════════
:generate_report

set /a TOTAL_PROCESSED=%IMG_SUCCESS%+%VID_SUCCESS%
set /a TOTAL_ERRORS=%IMG_ERROR%+%VID_ERROR%
set /a TOTAL_SKIPPED=%IMG_SKIPPED%+%VID_SKIPPED%

REM ── Calculate savings ───────────────────────────────────────
set "SAVINGS_PCT=0"
if %TOTAL_ORIG_KB% GTR 0 (
    set /a SAVED_KB=%TOTAL_ORIG_KB%-%TOTAL_OPT_KB%
    set /a SAVINGS_PCT=(%SAVED_KB%*100^)/%TOTAL_ORIG_KB%
)
set /a TOTAL_ORIG_MB=%TOTAL_ORIG_KB%/1024
set /a TOTAL_OPT_MB=%TOTAL_OPT_KB%/1024

REM ── Write JSON report ───────────────────────────────────────
(
    echo {
    echo   "timestamp": "%DATE% %TIME%",
    echo   "config": {
    echo     "source": "%SOURCE:\=/%",
    echo     "output": "%OUTPUT:\=/%",
    echo     "image_quality": %IMG_QUALITY%,
    echo     "video_crf": %VID_CRF%,
    echo     "dry_run": %DRY_RUN%
    echo   },
    echo   "summary": {
    echo     "total_files_processed": %TOTAL_PROCESSED%,
    echo     "images_converted": %IMG_SUCCESS%,
    echo     "videos_converted": %VID_SUCCESS%,
    echo     "files_skipped": %TOTAL_SKIPPED%,
    echo     "files_errored": %TOTAL_ERRORS%,
    echo     "original_size_mb": %TOTAL_ORIG_MB%,
    echo     "optimized_size_mb": %TOTAL_OPT_MB%,
    echo     "savings_percent": %SAVINGS_PCT%
    echo   },
    echo   "files": [
    if exist "%TEMPFILES%" type "%TEMPFILES%"
    echo   ]
    echo }
) > "%REPORTFILE%"
if exist "%TEMPFILES%" del "%TEMPFILES%"

REM ── Summary Box ─────────────────────────────────────────────
echo.
echo  ┌──────────────────────────────────────────────┐
echo  │            OPTIMIZATION COMPLETE              │
echo  ├──────────────────────────────────────────────┤
echo  │  Images converted:   %IMG_SUCCESS%
echo  │  Videos converted:   %VID_SUCCESS%
echo  │  Files skipped:      %TOTAL_SKIPPED%
echo  │  Errors:             %TOTAL_ERRORS%
echo  ├────────────��─────────────────────────────────┤
echo  │  Original size:      ~%TOTAL_ORIG_MB% MB
echo  │  Optimized size:     ~%TOTAL_OPT_MB% MB
echo  │  Savings:            ~%SAVINGS_PCT%%%
echo  ├──────────────────────────────────────────────┤
echo  │  Report: %REPORTFILE%
echo  │  Log:    %LOGFILE%
echo  └──────────────────────────────────────────────┘
echo.

echo  Conversion finished: %DATE% %TIME% >> "%LOGFILE%"
echo  Results: %TOTAL_PROCESSED% converted, %TOTAL_SKIPPED% skipped, %TOTAL_ERRORS% errors >> "%LOGFILE%"
echo  Savings: %TOTAL_ORIG_MB% MB -^> %TOTAL_OPT_MB% MB ^(%SAVINGS_PCT%%%%^) >> "%LOGFILE%"
echo ============================================ >> "%LOGFILE%"

pause
exit /b 0

REM ══════════════════════════════════════════════════════════════
REM  SUBROUTINES
REM ══════════════════════════════════════════════════════════════

REM ── Process all images recursively in a directory ───────────
:process_images_in
set "SEARCH_DIR=%~1"
set "REL_BASE=%~2"

for /r "%SEARCH_DIR%" %%F in (*.jpg *.jpeg *.png *.gif) do (
    set /a IMG_COUNT+=1
    set "SRC=%%F"
    set "EXT=%%~xF"
    set "BASENAME=%%~nF"

    REM Build relative path for output
    set "FULL=%%~dpF"
    call set "REL_PATH=%%FULL:!SEARCH_DIR!=%%"

    REM Get file size in KB
    set "FSIZE=%%~zF"
    set /a FILE_KB=!FSIZE!/1024

    REM Skip small files
    if !FILE_KB! LSS %IMG_SKIP_KB% (
        echo  [SKIP] !FILE_KB! KB ^< %IMG_SKIP_KB% KB: %%~nxF
        echo  SKIP: %%F ^(%%~zF bytes, under threshold^) >> "%LOGFILE%"
        set /a IMG_SKIPPED+=1
    ) else (
        call :convert_single_image "%%F" "!BASENAME!" "!EXT!" "!REL_BASE!" "!REL_PATH!" "!FILE_KB!"
    )
)
exit /b 0

REM ── Convert a single image ─────────────────────────────────
:convert_single_image
set "SRC=%~1"
set "BASENAME=%~2"
set "EXT=%~3"
set "REL_BASE=%~4"
set "REL_SUB=%~5"
set "ORIG_KB=%~6"

set "OUTDIR=%OUTPUT%\%REL_BASE%%REL_SUB%"
set "WEBP_OUT=%OUTDIR%%BASENAME%.webp"
set "PNG_OUT=%OUTDIR%%BASENAME%.png"

if "%DRY_RUN%"=="1" (
    echo  [DRY] %BASENAME%%EXT% -^> .webp + .png  ^(%ORIG_KB% KB^)
    echo  DRY: %SRC% -^> %WEBP_OUT% >> "%LOGFILE%"
    exit /b 0
)

REM ── Continue mode: skip if output exists ────────────────────
if "%CONTINUE_MODE%"=="1" (
    if exist "%WEBP_OUT%" (
        echo  [EXISTS] %BASENAME%.webp already exists — skipping.
        set /a IMG_SKIPPED+=1
        exit /b 0
    )
)

if not exist "%OUTDIR%" mkdir "%OUTDIR%"

REM ── Animated GIF → MP4 + WebM ──────────────────────────────
if /i "%EXT%"==".gif" (
    set "MP4_OUT=%OUTDIR%%BASENAME%.mp4"
    set "WEBM_OUT=%OUTDIR%%BASENAME%.webm"

    echo  [GIF] %BASENAME%.gif -^> .mp4 + .webm  ^(%ORIG_KB% KB^)

    if "%VERBOSE%"=="1" (
        ffmpeg -y -i "%SRC%" -movflags faststart -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -crf %VID_CRF% "!MP4_OUT!" 2>&1
        ffmpeg -y -i "%SRC%" -c:v libvpx-vp9 -crf %VID_CRF% -b:v 0 -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" "!WEBM_OUT!" 2>&1
    ) else (
        ffmpeg -y -i "%SRC%" -movflags faststart -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -crf %VID_CRF% "!MP4_OUT!" >nul 2>&1
        ffmpeg -y -i "%SRC%" -c:v libvpx-vp9 -crf %VID_CRF% -b:v 0 -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" "!WEBM_OUT!" >nul 2>&1
    )

    if exist "!MP4_OUT!" (
        for %%O in ("!MP4_OUT!") do set /a OPT_KB=%%~zO/1024
        set /a IMG_SUCCESS+=1
        set /a TOTAL_ORIG_KB+=%ORIG_KB%
        set /a TOTAL_OPT_KB+=!OPT_KB!
        echo  OK: %SRC% -^> !MP4_OUT! ^(%ORIG_KB% KB -^> !OPT_KB! KB^) >> "%LOGFILE%"
        call :append_file_json "%SRC%" "!MP4_OUT!" "%ORIG_KB%" "!OPT_KB!" "gif-^>mp4+webm" "success"
    ) else (
        echo  [FAIL] %BASENAME%.gif — ffmpeg error
        echo  ERROR: %SRC% — conversion failed >> "%LOGFILE%"
        set /a IMG_ERROR+=1
        call :append_file_json "%SRC%" "" "%ORIG_KB%" "0" "gif-^>mp4+webm" "error"
    )
    exit /b 0
)

REM ── JPG/PNG → WebP (lossy for jpg, lossless for png) ───────
echo  [IMG] %BASENAME%%EXT% -^> .webp + .png  ^(%ORIG_KB% KB^)

if /i "%EXT%"==".png" (
    REM Lossless WebP for PNG
    if "%VERBOSE%"=="1" (
        ffmpeg -y -i "%SRC%" -c:v libwebp -lossless 1 "%WEBP_OUT%" 2>&1
    ) else (
        ffmpeg -y -i "%SRC%" -c:v libwebp -lossless 1 "%WEBP_OUT%" >nul 2>&1
    )
) else (
    REM Lossy WebP for JPG/JPEG
    if "%VERBOSE%"=="1" (
        ffmpeg -y -i "%SRC%" -c:v libwebp -quality %IMG_QUALITY% "%WEBP_OUT%" 2>&1
    ) else (
        ffmpeg -y -i "%SRC%" -c:v libwebp -quality %IMG_QUALITY% "%WEBP_OUT%" >nul 2>&1
    )
)

REM PNG fallback (re-compress)
if "%VERBOSE%"=="1" (
    ffmpeg -y -i "%SRC%" -compression_level 100 "%PNG_OUT%" 2>&1
) else (
    ffmpeg -y -i "%SRC%" -compression_level 100 "%PNG_OUT%" >nul 2>&1
)

if exist "%WEBP_OUT%" (
    for %%O in ("%WEBP_OUT%") do set /a OPT_KB=%%~zO/1024
    set /a IMG_SUCCESS+=1
    set /a TOTAL_ORIG_KB+=%ORIG_KB%
    set /a TOTAL_OPT_KB+=!OPT_KB!
    echo     -^> %BASENAME%.webp ^(!OPT_KB! KB^) saved ~%ORIG_KB% KB
    echo  OK: %SRC% -^> %WEBP_OUT% ^(%ORIG_KB% KB -^> !OPT_KB! KB^) >> "%LOGFILE%"
    call :append_file_json "%SRC%" "%WEBP_OUT%" "%ORIG_KB%" "!OPT_KB!" "%EXT:~1%-^>webp" "success"
) else (
    echo  [FAIL] %BASENAME%%EXT% — ffmpeg error
    echo  ERROR: %SRC% — conversion failed >> "%LOGFILE%"
    set /a IMG_ERROR+=1
    call :append_file_json "%SRC%" "" "%ORIG_KB%" "0" "%EXT:~1%-^>webp" "error"
)
exit /b 0

REM ── Process all videos recursively in a directory ───────────
:process_videos_in
set "SEARCH_DIR=%~1"
set "REL_BASE=%~2"

for /r "%SEARCH_DIR%" %%F in (*.mp4 *.mov *.avi *.webm) do (
    set /a VID_COUNT+=1
    set "BASENAME=%%~nF"
    set "EXT=%%~xF"

    set "FULL=%%~dpF"
    call set "REL_PATH=%%FULL:!SEARCH_DIR!=%%"

    set "FSIZE=%%~zF"
    set /a FILE_KB=!FSIZE!/1024

    if !FILE_KB! LSS %VID_SKIP_KB% (
        echo  [SKIP] !FILE_KB! KB ^< %VID_SKIP_KB% KB: %%~nxF
        echo  SKIP: %%F ^(%%~zF bytes, under threshold^) >> "%LOGFILE%"
        set /a VID_SKIPPED+=1
    ) else (
        call :convert_single_video "%%F" "!BASENAME!" "!EXT!" "!REL_BASE!" "!REL_PATH!" "!FILE_KB!"
    )
)
exit /b 0

REM ── Convert a single video ─────────────────────────────────
:convert_single_video
set "SRC=%~1"
set "BASENAME=%~2"
set "EXT=%~3"
set "REL_BASE=%~4"
set "REL_SUB=%~5"
set "ORIG_KB=%~6"

set "OUTDIR=%OUTPUT%\%REL_BASE%%REL_SUB%"
set "MOBILEDIR=%OUTPUT%\mobile\%REL_BASE%%REL_SUB%"
set "MP4_OUT=%OUTDIR%%BASENAME%.mp4"
set "WEBM_OUT=%OUTDIR%%BASENAME%.webm"
set "MOBILE_OUT=%MOBILEDIR%%BASENAME%-mobile.mp4"

if "%DRY_RUN%"=="1" (
    set /a ORIG_MB=%ORIG_KB%/1024
    echo  [DRY] %BASENAME%%EXT% -^> .mp4 + .webm + mobile  ^(!ORIG_MB! MB^)
    echo  DRY: %SRC% -^> %MP4_OUT% >> "%LOGFILE%"
    exit /b 0
)

REM ── Continue mode ───────────────────────────────────────────
if "%CONTINUE_MODE%"=="1" (
    if exist "%MP4_OUT%" (
        echo  [EXISTS] %BASENAME%.mp4 already exists — skipping.
        set /a VID_SKIPPED+=1
        exit /b 0
    )
)

if not exist "%OUTDIR%" mkdir "%OUTDIR%"
if not exist "%MOBILEDIR%" mkdir "%MOBILEDIR%"

set /a ORIG_MB=%ORIG_KB%/1024
echo  [VID] %BASENAME%%EXT%  ^(!ORIG_MB! MB^)

REM ── H.264 MP4 (cap at 1920px wide) ─────────────────────────
echo     -^> %BASENAME%.mp4 ^(H.264^)
if "%VERBOSE%"=="1" (
    ffmpeg -y -i "%SRC%" -c:v libx264 -preset medium -crf %VID_CRF% -vf "scale='min(1920,iw)':-2" -movflags +faststart -c:a aac -b:a 128k "%MP4_OUT%" 2>&1
) else (
    ffmpeg -y -i "%SRC%" -c:v libx264 -preset medium -crf %VID_CRF% -vf "scale='min(1920,iw)':-2" -movflags +faststart -c:a aac -b:a 128k "%MP4_OUT%" >nul 2>&1
)

REM ── VP9 WebM ────────────────────────────────────────────────
echo     -^> %BASENAME%.webm ^(VP9^)
if "%VERBOSE%"=="1" (
    ffmpeg -y -i "%SRC%" -c:v libvpx-vp9 -crf %VID_CRF% -b:v 0 -vf "scale='min(1920,iw)':-2" -c:a libopus -b:a 96k "%WEBM_OUT%" 2>&1
) else (
    ffmpeg -y -i "%SRC%" -c:v libvpx-vp9 -crf %VID_CRF% -b:v 0 -vf "scale='min(1920,iw)':-2" -c:a libopus -b:a 96k "%WEBM_OUT%" >nul 2>&1
)

REM ── Mobile variant (640px wide) ─────────────────────────────
echo     -^> %BASENAME%-mobile.mp4 ^(640px^)
if "%VERBOSE%"=="1" (
    ffmpeg -y -i "%SRC%" -c:v libx264 -preset medium -crf %VID_CRF% -vf "scale=640:-2" -movflags +faststart -c:a aac -b:a 96k "%MOBILE_OUT%" 2>&1
) else (
    ffmpeg -y -i "%SRC%" -c:v libx264 -preset medium -crf %VID_CRF% -vf "scale=640:-2" -movflags +faststart -c:a aac -b:a 96k "%MOBILE_OUT%" >nul 2>&1
)

if exist "%MP4_OUT%" (
    for %%O in ("%MP4_OUT%") do set /a OPT_KB=%%~zO/1024
    set /a OPT_MB=!OPT_KB!/1024
    set /a VID_SUCCESS+=1
    set /a TOTAL_ORIG_KB+=%ORIG_KB%
    set /a TOTAL_OPT_KB+=!OPT_KB!
    echo     Done: !ORIG_MB! MB -^> !OPT_MB! MB
    echo  OK: %SRC% -^> %MP4_OUT% ^(%ORIG_KB% KB -^> !OPT_KB! KB^) >> "%LOGFILE%"
    call :append_file_json "%SRC%" "%MP4_OUT%" "%ORIG_KB%" "!OPT_KB!" "%EXT:~1%-^>mp4+webm" "success"
) else (
    echo  [FAIL] %BASENAME%%EXT% — ffmpeg error
    echo  ERROR: %SRC% — conversion failed >> "%LOGFILE%"
    set /a VID_ERROR+=1
    call :append_file_json "%SRC%" "" "%ORIG_KB%" "0" "%EXT:~1%-^>mp4+webm" "error"
)
exit /b 0

REM ── Append a file entry to the temp JSON ────────────────────
:append_file_json
set "J_SRC=%~1"
set "J_DST=%~2"
set "J_ORIG=%~3"
set "J_OPT=%~4"
set "J_FMT=%~5"
set "J_STATUS=%~6"
set "J_SRC=%J_SRC:\=/%"
set "J_DST=%J_DST:\=/%"

if "%FIRST_FILE%"=="1" (
    set "FIRST_FILE=0"
) else (
    echo , >> "%TEMPFILES%"
)
(
    echo     {
    echo       "original_path": "%J_SRC%",
    echo       "optimized_path": "%J_DST%",
    echo       "original_size_kb": %J_ORIG%,
    echo       "optimized_size_kb": %J_OPT%,
    echo       "format": "%J_FMT%",
    echo       "status": "%J_STATUS%"
    echo     }
) >> "%TEMPFILES%"
exit /b 0

REM ── Help Text ───────────────────────────────────────────────
:show_help
echo.
echo  BALU-SITE MEDIA OPTIMIZER v1.0
echo  ───────────────────────────────────────────────
echo.
echo  Usage: optimize-media.bat [options]
echo.
echo  OPTIONS:
echo    --source ^<path^>         Source folder (default: ./public)
echo    --output ^<path^>         Output folder (default: ./public-optimized)
echo    --dry-run               Preview without converting
echo    --continue              Skip already-converted files
echo    --image-quality ^<0-100^> WebP quality (default: 80)
echo    --video-quality ^<0-51^>  Video CRF, lower=better (default: 28)
echo    --skip-images           Only process videos
echo    --skip-videos           Only process images
echo    --verbose               Show ffmpeg output
echo    --help                  Show this help
echo.
echo  EXAMPLES:
echo    optimize-media.bat --dry-run
echo    optimize-media.bat --image-quality 90 --video-quality 26
echo    optimize-media.bat --skip-videos --continue
echo    optimize-media.bat --source public --output dist\media
echo.
echo  REQUIREMENTS:
echo    - ffmpeg in PATH (https://ffmpeg.org/download.html)
echo    - That's it!
echo.
pause
exit /b 0