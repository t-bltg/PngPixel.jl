import imageio
import sys
import os


def main(args):
    x, y = int(args[1]), int(args[2])
    for gamma in (True, False):
        for kw in (
            dict(plugin='PNG-FI', ignoregamma=not gamma),
            dict(plugin='PNG-PIL', ignoregamma=not gamma),
            dict(plugin='pillow', apply_gamma=gamma, mode='RGBA'),
        ):
            print(kw)
            uri = f'file://{os.path.abspath(args[3])}'
            with imageio.imopen(uri, 'ri', plugin=kw.pop('plugin')) as file:
                img = file.read(index=0, **kw)
            r = img[:, :, 0]
            g = img[:, :, 1]
            b = img[:, :, 2]
            a = img[:, :, 3]

            print(f'rgba({r[y, x]},{g[y, x]},{b[y, x]},{a[y, x]})')


if __name__ == '__main__':
    main(sys.argv)
