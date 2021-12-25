import imageio
import sys


def main(args):
    img = imageio.imread(args[3])
    r = img[:, :, 0]
    g = img[:, :, 1]
    b = img[:, :, 2]
    a = img[:, :, 3]

    x, y = int(args[1]), int(args[2])
    print(f'rgba({r[y, x]},{g[y, x]},{b[y, x]},{a[y, x]})')


if __name__ == '__main__':
    main(sys.argv)
