using BinDeps

vers = "1.12.1"

# Set to true to build locally with internal compressors:
build_locally_w_internal_compressors = true
#build_locally_w_internal_compressors = false

tagfile = "installed_vers"
target = "libblosc.$(Libdl.dlext)"
if !isfile(tagfile) || readchomp(tagfile) != vers
    if !build_locally_w_internal_compressors && is_windows()
        run(download_cmd("http://ab-initio.mit.edu/blosc/libblosc$(Sys.WORD_SIZE)-$vers.dll", target))
    elseif !build_locally_w_internal_compressors && is_apple()
        run(download_cmd("http://ab-initio.mit.edu/blosc/libblosc$(Sys.WORD_SIZE)-$vers.dylib", target))
    else
        tarball = "c-blosc-$vers.tar.gz"
        maindir = "c-blosc-$vers" 
        srcdir = "c-blosc-$vers/blosc"
        if !isfile(tarball)
            run(download_cmd("https://github.com/Blosc/c-blosc/archive/v$vers.tar.gz", tarball))
        end
        run(unpack_cmd(tarball, ".", ".gz", ".tar"))
        if !build_locally_w_internal_compressors
            cd(srcdir) do
                println("Compiling libblosc...")
                for f in ("blosc.c", "blosclz.c", "shuffle.c")
                    println("   CC $f")
                    run(`gcc -fPIC -O3 -msse2 -I. -c $f`)
                end
                println("   LINK libblosc")
                run(`gcc -shared -o ../../$target blosc.o blosclz.o shuffle.o`)
            end
        else
            cd(maindir) do
                println("Compiling libblosc with internal compressor libs...")
                run(`mkdir build`)
                cd("build") do
                    run(`cmake -DPREFER_EXTERNAL_COMPLIBS=OFF ..`)
                    run(`make`)
                    run(`cp blosc/$target ../..`)
                    run(`make clean`)
                end
            end
            run(`rm -rf $maindir $tarball`)
            println("Compiled libblosc with internal compressor libs...")
        end
    end
    open(tagfile, "w") do f
        println(f, "$vers $(Sys.WORD_SIZE)")
    end 
end
  
            
 
