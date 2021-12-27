using ImageMagick
using ColorTypes

revert_γ(x, γ=.455) = x^(1 / γ)

main() = begin
  x, y = parse(Int, ARGS[1]) + 1, parse(Int, ARGS[2]) + 1

  img = open(ARGS[3]) do io
    ImageMagick.load(io)
  end

  r, g, b, a = red.(img), green.(img), blue.(img), alpha.(img)

  raw255(x) = floor.(Int, 255x)
  lin255(x) = floor.(Int, 255revert_γ.(x))

  γR, γG, γB, A = raw255.((r, g, b, a))
  R, G, B = lin255.((r, g, b))

  println("rgba($(γR[y, x]),$(γG[y, x]),$(γB[y, x]),$(A[y, x])) (γ corrected)")
  println("rgba($(R[y, x]),$(G[y, x]),$(B[y, x]),$(A[y, x]))")

  return
end

main()
