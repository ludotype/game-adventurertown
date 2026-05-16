import os

def fix_image_padding(target_dir):
    print(f"🔍 '{target_dir}' 및 하위 폴더에서 이미지를 검색합니다...")
    
    # 처리할 확장자 목록
    extensions = ('.png', '.jpg', '.jpeg', '.webp')
    fixed_count = 0
    skipped_count = 0

    for root, dirs, files in os.walk(target_dir):
        for file in files:
            if file.lower().endswith(extensions):
                file_path = os.path.join(root, file)
                
                # 파일 크기 확인
                try:
                    file_size = os.path.getsize(file_path)
                    
                    # 파일 크기가 3의 배수이면 Base64 패딩(=)이 생기지 않음
                    if file_size % 3 == 0:
                        # 파일 끝에 1바이트(null) 추가
                        with open(file_path, 'ab') as f:
                            f.write(b'\x00')
                        
                        new_size = os.path.getsize(file_path)
                        print(f"✅ 수정됨: {file} ({file_size} -> {new_size} bytes)")
                        fixed_count += 1
                    else:
                        # 이미 3의 배수가 아니면 패딩이 생기므로 건너뜀
                        skipped_count += 1
                except Exception as e:
                    print(f"❌ 오류 발생 ({file}): {e}")

    print("\n--- 작업 완료 ---")
    print(f"✨ 수정된 파일: {fixed_count}개")
    print(f"⏩ 건너뛴 파일: {skipped_count}개 (이미 패딩 조건을 만족함)")

if __name__ == "__main__":
    # 스크립트가 실행되는 현재 디렉토리를 기준으로 작업 시작
    current_directory = os.getcwd()
    fix_image_padding(current_directory)
