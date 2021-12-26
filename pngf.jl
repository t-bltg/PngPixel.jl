using ColorTypes
using PNGFiles

@show pathof(PNGFiles)

linear(srgb) = begin
  # en.wikipedia.org/wiki/SRGB#Transformation
  lin = similar(srgb)
  for I ∈ eachindex(srgb)
    lin[I] = if (v=srgb[I]) > .04045
      ((v + .055) / 1.055)^2.4
    else
      v / 12.92
    end
  end
  lin
end

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

  raw255(x) = round.(Int, 255x)
  lin255 = (gamma === nothing || gamma > 0) ? (x -> round.(Int, 255linear(x))) : raw255

  r, g, b, a = red.(img), green.(img), blue.(img), alpha.(img)

  R, G, B = lin255.((r, g, b))
  A = raw255(a)

  println("rgba($(R[y, x]),$(G[y, x]),$(B[y, x]),$(A[y, x]))")
  
  return
end

main()
