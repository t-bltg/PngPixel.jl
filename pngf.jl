using ColorTypes
using PNGFiles

# @show pathof(PNGFiles)

revert_γ(x, screen_γ=2.2, image_γ=1.) = x^(screen_γ * image_γ)

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

  if parse(Int, get(ENV, "UNCORRECT", "0")) != 0
    lin255 = (gamma === nothing || 0 < gamma < 1) ? lin255 : raw255

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
