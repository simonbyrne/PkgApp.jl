using Test
using PkgApp

if Sys.iswindows()
    @show get(ENV, "PATHEXT", nothing)
end

execext = Sys.iswindows() ? ".cmd" : ""

function with_temp_project(fn, pkgdir)
    temppkgdir = tempname()
    cp(pkgdir, temppkgdir)
    pushfirst!(LOAD_PATH, Base.active_project())
    old_active_project = Base.ACTIVE_PROJECT[]
    Base.ACTIVE_PROJECT[] = temppkgdir
    try
        fn(temppkgdir)
    finally
        Base.ACTIVE_PROJECT[] = old_active_project
        popfirst!(LOAD_PATH)
    end
end


with_temp_project(joinpath(@__DIR__, "TestApp")) do pkgdir
    PkgApp.build(;use_sysimage=false)

    bindir = joinpath(pkgdir, "bin")
    @show readdir(bindir)

    withenv("PATH" =>string(ENV["PATH"], Sys.iswindows() ? ";" : ":", bindir)) do
        @test read(`$("hello_function$execext")`, String) == "hello from $(pwd())\n"
        @test read(`$("hello_function$execext") "aa bb" cc`, String) == "hello aa bb, cc\n"

        @test read(`$("hello_script$execext")`, String) == "hello from $(pwd())\n"
        @test read(`$("hello_script$execext") "aa bb" cc`, String) == "hello aa bb, cc\n"
    end
end

if Sys.WORD_SIZE == 64
    with_temp_project(joinpath(@__DIR__, "TestApp")) do pkgdir
        PkgApp.build(;use_sysimage=true)
        bindir = joinpath(pkgdir, "bin")
        @show readdir(bindir)

        withenv("PATH" =>string(ENV["PATH"], Sys.iswindows() ? ";" : ":", bindir)) do
    
            @test read(`$("hello_function$execext")`, String) == "hello from $(pwd())\n"
            @test read(`$("hello_function$execext") "aa bb" cc`, String) == "hello aa bb, cc\n"

            @test read(`$("hello_script$execext")`, String) == "hello from $(pwd())\n"
            @test read(`$("hello_script$execext") "aa bb" cc`, String) == "hello aa bb, cc\n"
        end
    end
end