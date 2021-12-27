using ImageMagick
using ColorTypes

linear(x) = (  # en.wikipedia.org/wiki/SRGB#Transformation
  if x > .0404482362771076
    ((x + .055) / 1.055)^2.4
  else
    x / 12.92
  end
)

main() = begin
  x, y = parse(Int, ARGS[1]) + 1, parse(Int, ARGS[2]) + 1

  img = open(ARGS[3]) do io
    ImageMagick.load(io)
  end

  r, g, b, a = red.(img), green.(img), blue.(img), alpha.(img)

  raw255(x) = floor.(Int, 255x)
  lin255(x) = round.(Int, 255linear.(x))  # NOTE: using round instead of floor here

  if parse(Int, get(ENV, "UNCORRECT", "0")) != 0
    γR, γG, γB, A = raw255.((r, g, b, a))
    R, G, B = lin255.((r, g, b))

    println("rgba($(γR[y, x]),$(γG[y, x]),$(γB[y, x]),$(A[y, x])) (γ corrected)")
    println("rgba($(R[y, x]),$(G[y, x]),$(B[y, x]),$(A[y, x]))")
  else
    R, G, B, A = raw255.((r, g, b, a))
    println("rgba($(R[y, x]),$(G[y, x]),$(B[y, x]),$(A[y, x]))")
  end

  return
end

main()
