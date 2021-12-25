import PNGFiles: png_error_fn_c, png_warn_fn_c, maybe_lock, readcallback_c, libpng, _AlphaBuffer
import PNGFiles

import ColorTypes: N0f8
using ColorTypes
using Printf

include(joinpath(PNGFiles.libpng_wrap_dir, "libpng_api.jl"))
include(joinpath(dirname(pathof(PNGFiles)), "wraphelpers.jl"))

function component(row::png_voidp, x, c, bit_depth, channels)::Cuint
    bit_offset_hi::png_uint_32 = bit_depth * ((x >> 6) * channels)
    bit_offset_lo::png_uint_32 = bit_depth * ((x & 0x3f) * channels + c)

    R = convert(png_const_bytep, row)
    R += bit_offset_hi * sizeof(png_byte)
    R += (bit_offset_lo >> 3) * sizeof(png_byte)
    bit_offset_lo &= 0x07

    if bit_depth == 1
        return (unsafe_load(R) >> (7 - bit_offset_lo)) & 0x01
    elseif bit_depth == 2
        return (unsafe_load(R) >> (6 - bit_offset_lo)) & 0x03
    elseif bit_depth ==  4
        return (unsafe_load(R) >> (4 - bit_offset_lo)) & 0x0f
    elseif bit_depth ==  8
        return unsafe_load(R)
    elseif bit_depth == 16
        return (unsafe_load(R) << 8) + unsafe_load(R, 2)
    else
        throw(error("pngpixel: invalid bit depth"))
    end
end

raw255(x) = round.(Int, 255x)

function print_pixel(png_ptr, info_ptr, row::png_voidp, x)
    bit_depth = png_get_bit_depth(png_ptr, info_ptr)
    color_type = png_get_color_type(png_ptr, info_ptr)

    if color_type == PNG_COLOR_TYPE_GRAY
        @printf "GRAY %u\n" component(row, x, 0, bit_depth, 1)
    elseif color_type == PNG_COLOR_TYPE_PALETTE
        index = component(row, x, 0, bit_depth, 1)
        palette_length = Ref{Cint}()
        palette_buffer = Vector{RGB{N0f8}}(undef, PNG_MAX_PALETTE_LENGTH)
        png_get_PLTE(png_ptr, info_ptr, pointer_from_objref(palette_buffer), palette_length)

        palette = palette_buffer[1:palette_length[]]
        if png_get_valid(png_ptr, info_ptr, PNG_INFO_tRNS) != 0
            trans_alpha = Vector{_AlphaBuffer}(undef, palette_length[])
            num_trans = Ref{Cint}()
            png_get_tRNS(png_ptr, info_ptr, pointer_from_objref(trans_alpha), num_trans, C_NULL)
            if num_trans[] > 0 && length(trans_alpha) > 0
                @printf(
                    "INDEXED %u = %d %d %d %d\n",
                    index,
                    raw255(red(palette[index+1])),
                    raw255(green(palette[index+1])),
                    raw255(blue(palette[index+1])),
                    index < num_trans[] ? raw255(trans_alpha[index+1].val) : 255
                )
            else
                @printf(
                    "INDEXED %u = %d %d %d\n",
                    index,
                    raw255(red(palette[index+1])),
                    raw255(green(palette[index+1])),
                    raw255(blue(palette[index+1]))
                )
            end
        end
    elseif color_type == PNG_COLOR_TYPE_RGB
        @printf(
            "RGB %u %u %u\n",
            component(row, x, 0, bit_depth, 3),
            component(row, x, 1, bit_depth, 3),
            component(row, x, 2, bit_depth, 3)
        )
    elseif color_type == PNG_COLOR_TYPE_GRAY_ALPHA
        @printf(
            "GRAY+ALPHA %u %u\n",
            component(row, x, 0, bit_depth, 2),
            component(row, x, 1, bit_depth, 2)
        )
    elseif color_type == PNG_COLOR_TYPE_RGB_ALPHA
        @printf(
            "RGBA %u %u %u %u\n",
            component(row, x, 0, bit_depth, 4),
            component(row, x, 1, bit_depth, 4),
            component(row, x, 2, bit_depth, 4),
            component(row, x, 3, bit_depth, 4)
        )
    end
end

function png_pixel(s::IO, x, y)
    isreadable(s) || throw(ArgumentError("read failed, IOStream is not readable"))
    Base.eof(s) && throw(EOFError())

    png_ptr = create_read_struct()
    info_ptr = create_info_struct(png_ptr)

    maybe_lock(s) do
        if s isa IOBuffer
            png_set_read_fn(png_ptr, pointer_from_objref(s), readcallback_iobuffer_c[])
        else
            png_set_read_fn(png_ptr, s.handle, readcallback_c[])
        end
        # https://stackoverflow.com/questions/22564718/libpng-error-png-unsigned-integer-out-of-range
        png_set_sig_bytes(png_ptr, 0)

        ########################################################
        # from contrib/examples/pngpixel.c
        png_read_info(png_ptr, info_ptr)

        width = png_get_image_width(png_ptr, info_ptr)
        height = png_get_image_height(png_ptr, info_ptr)

        row = png_malloc(png_ptr, png_get_rowbytes(png_ptr, info_ptr))
        # @show typeof(row)
        png_start_read_image(png_ptr)

        for i = 1:png_set_interlace_handling(png_ptr)
            for py = 0:(height-1)
                png_read_row(png_ptr, row, C_NULL)
                ppx = 0
                if y == py
                    for px = 0:(width-1)
                        if x == px
                            print_pixel(png_ptr, info_ptr, row, ppx)
                            @goto pass_loop_end
                        end
                        ppx += 1
                    end
                end
            end
        end
        @label pass_loop_end
        png_free(png_ptr, row)
        ########################################################
    end
    png_destroy_read_struct(Ref{Ptr{Cvoid}}(png_ptr), Ref{Ptr{Cvoid}}(info_ptr), C_NULL)
end

main() = begin
  open(ARGS[3]) do io
    png_pixel(io, parse(Int, ARGS[1]), parse(Int, ARGS[2]))
  end
  return
end

main()
