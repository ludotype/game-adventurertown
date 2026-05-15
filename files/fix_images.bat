@echo off
:: 한글 출력을 위해 UTF-8 인코딩 설정
chcp 65001 >nul
setlocal
title 이미지 패딩 자동 수정기 - 히마리

echo 🔍 이미지 파일의 Base64 패딩 문제를 수정하고 있습니다...
echo.

:: 1. 파이썬 스크립트 파일이 있는지 확인
if not exist "%~dp0fix_image_padding.py" (
    echo [오류] 'fix_image_padding.py' 파일을 찾을 수 없습니다.
    echo 배치 파일과 같은 폴더에 파이썬 스크립트가 있는지 확인해 주세요.
    goto end
)

:: 2. 파이썬 실행 시도
echo [정보] 파이썬 스크립트를 실행합니다...
python "%~dp0fix_image_padding.py"

:: 3. 실행 결과 확인
if %errorlevel% neq 0 (
    echo.
    echo [오류] 스크립트 실행 중 문제가 발생했습니다. (에러 코드: %errorlevel%)
    echo 파이썬이 설치되어 있고 환경 변수(PATH)에 등록되어 있는지 확인해 주세요.
) else (
    echo.
    echo ✨ 모든 이미지 수정 작업이 성공적으로 끝났습니다!
)

:end
echo.
echo 작업을 마치려면 아무 키나 눌러 주세요...
:: 창이 바로 닫히지 않도록 대기
pause >nul
