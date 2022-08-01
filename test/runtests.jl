using Test
using PkgApp

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

    @test read(`$pkgdir/bin/hello_function`, String) == "hello from $(pwd())\n"
    @test read(`$pkgdir/bin/hello_function "aa bb" cc`, String) == "hello aa bb, cc\n"

    @test read(`$pkgdir/bin/hello_script`, String) == "hello from $(pwd())\n"
    @test read(`$pkgdir/bin/hello_script "aa bb" cc`, String) == "hello aa bb, cc\n"

end


with_temp_project(joinpath(@__DIR__, "TestApp")) do pkgdir
    PkgApp.build(;use_sysimage=true)

    @test read(`$pkgdir/bin/hello_function`, String) == "hello from $(pwd())\n"
    @test read(`$pkgdir/bin/hello_function "aa bb" cc`, String) == "hello aa bb, cc\n"

    @test read(`$pkgdir/bin/hello_script`, String) == "hello from $(pwd())\n"
    @test read(`$pkgdir/bin/hello_script "aa bb" cc`, String) == "hello aa bb, cc\n"

end