import zlib
import struct

def check_zlib_integrity(file_path):
    try:
        with open(file_path, 'rb') as f:
            f.read(8) # Skip signature
            idat_data = b''
            while True:
                len_bytes = f.read(4)
                if not len_bytes: break
                length = struct.unpack('>I', len_bytes)[0]
                chunk_type = f.read(4).decode('ascii', errors='ignore')
                data = f.read(length)
                f.read(4) # Skip CRC
                if chunk_type == 'IDAT':
                    idat_data += data
                if chunk_type == 'IEND':
                    break
            
            # Try to decompress
            try:
                decompressed = zlib.decompress(idat_data)
                return f"Success: {len(decompressed)} bytes decompressed."
            except zlib.error as e:
                return f"Zlib Error: {e}"
    except Exception as e:
        return f"File Error: {e}"

print(f"20260418007.png: {check_zlib_integrity('20260418007.png')}")
print(f"120260418007.png: {check_zlib_integrity('120260418007.png')}")
