Trying to debug the following [issue](https://discourse.julialang.org/t/reading-png-rgb-channels-julia-vs-python/73599) reported in [PNGFiles](https://github.com/JuliaIO/PNGFiles.jl/issues/48).

pngpixel.c taken from [libpng](https://github.com/glennrp/libpng/blob/libpng16/contrib/examples/pngpixel.c).

`5c5cdaa477dcae516c7183c3e710ef65a0bb6ab0.png` has no `gAMA` chunk, and colorspace is `sRGBA`, so `gamma` defaults to `.45455`.

`img.png` has a `gAMA` chunk set to `1.`, and the colorspace is `RGB`.

C
-
```bash
$ gcc pngpixel.c -lpng
$ ./a.out 2 2 img.png
INDEXED 13 = 233 173 4 244
$ ./a.out 2 2 5c5cdaa477dcae516c7183c3e710ef65a0bb6ab0.png
INDEXED 39 = 233 173 4 244
```

Julia
-----
```bash
$ julia pngpixel.jl 2 2 img.png
INDEXED 13 = 233 173 4 244
$ julia pngpixel.jl 2 2 5c5cdaa477dcae516c7183c3e710ef65a0bb6ab0.png
INDEXED 39 = 233 173 4 244
```

Julia + PNGFiles
----------------
```bash
$ UNCORRECT=1 julia pngf.jl 2 2 img.png
# rgba(233,171,5,244)  # <== wrong when using en.wikipedia.org/wiki/SRGB#Transformation
rgba(245,214,39,244) (γ corrected)  # != ImageMagick, but identical to freeimage plugin with python
rgba(233,173,4,244)
$ UNCORRECT=0 julia pngf.jl 2 2 5c5cdaa477dcae516c7183c3e710ef65a0bb6ab0.png
rgba(233,173,4,244)
```

Julia + ImageMagick
-------------------
```bash
$ UNCORRECT=1 julia imgm.jl 2 2 img.png
rgba(245,215,34,244) (γ corrected)  # != PNGFiles, seems to use en.wikipedia.org/wiki/SRGB#Transformation
rgba(233,173,4,244)
$ UNCORRECT=0 julia imgm.jl 2 2 5c5cdaa477dcae516c7183c3e710ef65a0bb6ab0.png
rgba(233,173,4,244)
```

Python
------
```bash
$ python3 pngpixel.py 2 2 img.png
{'plugin': 'PNG-FI', 'ignoregamma': False}
rgba(245,214,39,244)
{'plugin': 'PNG-PIL', 'ignoregamma': False}
rgba(233,173,4,244)
{'plugin': 'pillow', 'apply_gamma': True, 'mode': 'RGBA'}
rgba(233,173,4,244)
{'plugin': 'PNG-FI', 'ignoregamma': True}
rgba(233,173,4,244)
{'plugin': 'PNG-PIL', 'ignoregamma': True}
rgba(233,173,4,244)
{'plugin': 'pillow', 'apply_gamma': False, 'mode': 'RGBA'}
rgba(233,173,4,244)
$ python3 pngpixel.py 2 2 5c5cdaa477dcae516c7183c3e710ef65a0bb6ab0.png
{'plugin': 'PNG-FI', 'ignoregamma': False}
rgba(233,173,4,244)
{'plugin': 'PNG-PIL', 'ignoregamma': False}
rgba(233,173,4,244)
{'plugin': 'pillow', 'apply_gamma': True, 'mode': 'RGBA'}
rgba(233,173,4,244)
{'plugin': 'PNG-FI', 'ignoregamma': True}
rgba(233,173,4,244)
{'plugin': 'PNG-PIL', 'ignoregamma': True}
rgba(233,173,4,244)
{'plugin': 'pillow', 'apply_gamma': False, 'mode': 'RGBA'}
rgba(233,173,4,244)
```

shell (ImageMagick)
-------------------
```bash
$ convert img.png txt:- | grep '2,2:'
2,2: (59881,44461,1028,62708)  #E9AD04F4  rgba(233,173,4,0.956863)
$ convert 5c5cdaa477dcae516c7183c3e710ef65a0bb6ab0.png txt:- | grep '2,2:'
2,2: (59881,44461,1028,62708)  #E9AD04F4  srgba(233,173,4,0.956863)
```
