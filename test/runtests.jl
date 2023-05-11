using Test
using PkgApp

if Sys.iswindows()
    @show get(ENV, "PATHEXT", nothing)
end

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

    @show readdir(joinpath(pkgdir, "bin"))

    @test read(`$(joinpath(pkgdir, "bin", "hello_function"))`, String) == "hello from $(pwd())\n"
    @test read(`$(joinpath(pkgdir, "bin", "hello_function")) "aa bb" cc`, String) == "hello aa bb, cc\n"

    @test read(`$(joinpath(pkgdir, "bin", "hello_script"))`, String) == "hello from $(pwd())\n"
    @test read(`$(joinpath(pkgdir, "bin", "hello_script")) "aa bb" cc`, String) == "hello aa bb, cc\n"

end

if Sys.WORD_SIZE == 64
    with_temp_project(joinpath(@__DIR__, "TestApp")) do pkgdir
        PkgApp.build(;use_sysimage=true)

        @test read(`$(joinpath(pkgdir, "bin", "hello_function"))`, String) == "hello from $(pwd())\n"
        @test read(`$(joinpath(pkgdir, "bin", "hello_function")) "aa bb" cc`, String) == "hello aa bb, cc\n"

        @test read(`$(joinpath(pkgdir, "bin", "hello_script"))`, String) == "hello from $(pwd())\n"
        @test read(`$(joinpath(pkgdir, "bin", "hello_script")) "aa bb" cc`, String) == "hello aa bb, cc\n"

    end
end