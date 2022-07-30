using Test

@show pkgdir = tempname()
cp(joinpath(@__DIR__, "TestApp"), pkgdir)
pushfirst!(LOAD_PATH, Base.active_project())
Base.ACTIVE_PROJECT[] = pkgdir

using PkgApp

PkgApp.build()

@test read(`$pkgdir/bin/hello_function`, String) == "hello from $(pwd())\n"
@test read(`$pkgdir/bin/hello_function "aa bb" cc`, String) == "hello aa bb, cc\n"

@test read(`$pkgdir/bin/hello_script`, String) == "hello from $(pwd())\n"
@test read(`$pkgdir/bin/hello_script "aa bb" cc`, String) == "hello aa bb, cc\n"

