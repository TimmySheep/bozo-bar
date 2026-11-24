#!/usr/bin/env python3
"""Extract the headphone artwork from the centrally placed supplied design."""
import pathlib, struct, subprocess, sys, zlib

source, out = map(pathlib.Path, sys.argv[1:])
out.mkdir(parents=True, exist_ok=True)
N = 1254
raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(source), '-frames:v', '1', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'])
assert len(raw) == N*N*3

def png(path, n, data):
    def chunk(kind, payload):
        return struct.pack('>I', len(payload)) + kind + payload + struct.pack('>I', zlib.crc32(kind+payload))
    lines = b''.join(b'\0'+data[i:i+4*n] for i in range(0,len(data),4*n))
    path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',n,n,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(lines,9))+chunk(b'IEND',b''))

def artwork(x, y):
    if not (155 <= x < 1100 and 145 <= y < 1110):
        return 0, 0
    i = (y*N+x)*3
    brightness = round(sum(raw[i:i+3])/3)
    return min(45, brightness), max(0, min(255, round((225-brightness)*255/180)))

for name, n, tile in [('Foreground.png', 1024, False), ('Legacy.png', 1024, True), ('MenuBarSource.png', 256, False)]:
    data = bytearray()
    for y in range(n):
        for x in range(n):
            dx,dy = (x+0.5)/n-.5,(y+0.5)/n-.5
            scale = 0.805 if tile else (1.23 if n == 256 else 1.0)
            sx,sy = int((dx/scale+.5)*N),int((dy/scale+.5)*N)
            gray,alpha = artwork(sx, sy)
            if tile:
                # Match the white tile in the reference. The old-system icon has transparent outer margins.
                radius,half = .162,.4025
                distance = (max(abs(dx)-(half-radius),0)**2+max(abs(dy)-(half-radius),0)**2)**.5
                gray = round((249*(255-alpha)+gray*alpha)/255)
                alpha = max(0,min(255,round((radius-distance)*n*255+127.5)))
            if n == 256:
                gray = 0
            data.extend((gray,gray,gray,alpha))
    assert all(data[(y*n+x)*4+3] == 0 for x,y in [(0,0),(0,n-1),(n-1,0),(n-1,n-1)])
    if not tile:
        assert sum(a>200 for a in data[3::4]) > n*n*0.12
        assert data[4*((n//2)*n+n//2)+3] == 0
    png(out/name, n, data)
    print(name, f'{n}x{n} RGBA', (out/name).stat().st_size)
