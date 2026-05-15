import struct

def analyze_png_chunks(file_path):
    chunks = []
    ihdr_info = {}
    try:
        with open(file_path, 'rb') as f:
            signature = f.read(8)
            if signature != b'\x89PNG\r\n\x1a\n':
                return f"Error: Not a valid PNG file signature ({file_path})", {}
            
            while True:
                length_bytes = f.read(4)
                if not length_bytes:
                    break
                length = struct.unpack('>I', length_bytes)[0]
                chunk_type = f.read(4).decode('ascii', errors='ignore')
                
                data = f.read(length)
                if chunk_type == 'IHDR':
                    w, h, bd, ct, cm, fm, im = struct.unpack('>IIBBBBB', data)
                    ihdr_info = {
                        'Width': w, 'Height': h, 'Bit Depth': bd, 
                        'Color Type': ct, 'Compression': cm, 'Filter': fm, 'Interlace': im
                    }
                
                crc = f.read(4)
                chunks.append((chunk_type, length))
                if chunk_type == 'IEND':
                    break
        return chunks, ihdr_info
    except Exception as e:
        return f"Error: {e}", {}

files = ['20260418007.png', '120260418007.png']
for file in files:
    chunks, ihdr = analyze_png_chunks(file)
    print(f"\n--- {file} ---")
    print(f"IHDR Info: {ihdr}")
    for chunk_type, length in chunks:
        if chunk_type != 'IDAT': # IDAT는 너무 많으므로 생략하거나 요약
            print(f"Chunk: {chunk_type}, Length: {length}")
        else:
            # 첫 번째와 마지막 IDAT만 출력하거나 개수만 출력
            pass
    idats = [c for c in chunks if c[0] == 'IDAT']
    print(f"IDAT Count: {len(idats)}, Total IDAT Length: {sum(c[1] for c in idats)}")
