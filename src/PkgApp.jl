module PkgApp

using Pkg

#=
operations:
- build: create endpoints



=#

# 1) how do


function add(pkgspec::PackageSpec)
    APPDIR = joinpath(DEPOT_PATH[1], "apps")
    mkpath(APPDIR)
    tempappdir = mktempdir(APPDIR)
    ctx = Pkg.Types.Context(env=Pkg.Types.EnvCache(tempappdir))
    Pkg.add(ctx, [pkgspec])
    pkgpath = Pkg.Operations.source_path(ctx.env.project_file, pkgspec, ctx.julia_version)

end


function build(ctx::Pkg.API.Context=Pkg.API.Context())
    #cd(dirname(ctx.env.project_file)) do
        Pkg.instantiate(ctx; verbose=true)
    #end
    apps = get(ctx.env.project.other, "apps", Dict())

    project_path = dirname(ctx.env.project_file)
    binpath = "bin"
    for (appname, appvals) in apps
        if haskey(appvals, "function")
            create_function_wrapper(ctx, joinpath(binpath, appname), appvals["function"])
        elseif haskey(appvals, "script")
            create_script_wrapper(ctx, joinpath(binpath, appname), appvals["script"])
        else
            error("invalid app")
        end
    end
end

function make_executable(filename)
    chmod(filename, stat(filename).mode & 0o777 | 0o111)
end


function create_function_wrapper(ctx::Pkg.Types.Context, filename, funcname)
    julia = joinpath(Sys.BINDIR, Base.julia_exename())
    project_file = ctx.env.project_file
    filename_full = joinpath(dirname(project_file), filename)
    project_from_filedir = relpath(dirname(project_file), dirname(filename_full))

    pkgname = split(funcname, ".")[1]
    mkpath(dirname(filename_full))
    @info "creating file" filename_full
    open(filename_full, "w+") do io
        write(io, """
            #!/bin/sh
            export JULIA_PROJECT="\$(dirname "\$(realpath "\$0")")/$project_from_filedir"
            $julia --startup-file=no -e 'import $pkgname; $funcname(ARGS)' "\$@"
            """)
    end
    make_executable(filename_full)
end
function create_script_wrapper(ctx::Pkg.Types.Context, filename, script)
    julia = joinpath(Sys.BINDIR, Base.julia_exename())
    project_file = ctx.env.project_file
    filename_full = joinpath(dirname(project_file), filename)
    project_from_filedir = relpath(dirname(project_file), dirname(filename_full))

    mkpath(dirname(filename_full))
    @info "creating file" filename_full
    open(filename_full, "w+") do io
        write(io, """
            #!/bin/sh
            export JULIA_PROJECT="\$(dirname "\$(realpath "\$0")")/$project_from_filedir"
            $julia --startup-file=no "\$JULIA_PROJECT/$script" "\$@"
            """)
    end
    make_executable(filename_full)
end


end # module
