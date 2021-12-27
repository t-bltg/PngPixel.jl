using ColorTypes
using PNGFiles

# @show pathof(PNGFiles)

linear(x) = (
  if x > .0404482362771076
    ((x + .055) / 1.055)^2.4
  else
    x / 12.92
  end
)

revert_γ(x, γ=.455) = x^(1 / γ)

main() = begin
  x, y = parse(Int, ARGS[1]) + 1, parse(Int, ARGS[2]) + 1

  gamma = nothing
  try
    gamma = parse(Float64, ARGS[4])
  catch
  end

  img = open(ARGS[3]) do io
    PNGFiles.load(io; gamma=gamma)
  end

  r, g, b, a = red.(img), green.(img), blue.(img), alpha.(img)

  raw255(x) = floor.(Int, 255x)
  lin255(x) = floor.(Int, 255revert_γ.(x))

  lin255 = (gamma === nothing || 0 < gamma < 1) ? lin255 : raw255

  γR, γG, γB, A = raw255.((r, g, b, a))
  R, G, B = lin255.((r, g, b))

  println("rgba($(γR[y, x]),$(γG[y, x]),$(γB[y, x]),$(A[y, x])) (γ corrected)")
  println("rgba($(R[y, x]),$(G[y, x]),$(B[y, x]),$(A[y, x]))")

  return
end

main()
