Trying to debug the following [issue](https://discourse.julialang.org/t/reading-png-rgb-channels-julia-vs-python/73599) reported in [PNGFiles](https://github.com/JuliaIO/PNGFiles.jl/issues/48).

pngpixel.c taken from [libpng](https://github.com/glennrp/libpng/blob/libpng16/contrib/examples/pngpixel.c).

c
-
```bash
$ gcc pngpixel.c -lpng
$ ./a.out 2 2 img.png
INDEXED 13 = 233 173 4 244
```

julia
-----
```bash
$ julia pngpixel.jl 2 2 img.png
INDEXED 13 = 233 173 4 244
```

julia + PNGFiles
----------------
```bash
$ julia pngf.jl 2 2 img.png
rgba(233,171,5,244)  # <== wrong !
```

python
------
```bash
$ python3 pngpixel.py 2 2 img.png
rgba(233,173,4,244)
```

shell
-----
```bash
$ convert img.png txt:- | grep '2,2:'
2,2: (59881,44461,1028,62708)  #E9AD04F4  rgba(233,173,4,0.956863)
```
