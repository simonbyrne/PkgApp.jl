module PkgApp

using Pkg, PackageCompiler, Libdl


function build(ctx::Pkg.API.Context=Pkg.API.Context(); use_sysimage=false)
    Pkg.instantiate(ctx; verbose=true)
    apps = get(ctx.env.project.other, "apps", Dict())
    project = dirname(ctx.env.project_file)
    @info "Building app" project
    if use_sysimage
        sysimage = joinpath("lib", "julia", "sys." * Libdl.dlext)
        PackageCompiler.create_sysimage([ctx.env.pkg.name];
            sysimage_path = joinpath(project, sysimage),
            project)
    else
        sysimage = nothing
    end

    binpath = "bin"
    for (appname, appvals) in apps
        if haskey(appvals, "function")
            create_function_wrapper(ctx, joinpath(binpath, appname), appvals["function"]; sysimage)
        elseif haskey(appvals, "script")
            create_script_wrapper(ctx, joinpath(binpath, appname), appvals["script"]; sysimage)
        else
            error("invalid app")
        end
    end
end

function make_executable(filename)
    if !Sys.iswindows()
        chmod(filename, stat(filename).mode & 0o777 | 0o111)
    end
end


function create_function_wrapper(ctx::Pkg.Types.Context, filename, funcname; sysimage=nothing)
    julia = joinpath(Sys.BINDIR, Base.julia_exename())
    project_file = ctx.env.project_file
    filename_full = joinpath(dirname(project_file), filename)
    if Sys.iswindows()
        filename_full = filename_full * ".cmd"
    end
    
    pkgname = split(funcname, ".")[1]
    mkpath(dirname(filename_full))
    if isnothing(sysimage)
        sysimage_flag = ""
    else
        sysimage_full = joinpath(dirname(project_file), sysimage)
        sysimage_flag = "--sysimage \"$sysimage_full\""
    end
    @debug "creating file" filename_full
    open(filename_full, "w+") do io
        if Sys.iswindows()
            write(io, """
                @echo off
                $julia --project="$project_file" $sysimage_flag --startup-file=no -e "import $pkgname; $funcname(ARGS)" -- %*
                """)
        else
            write(io, """
                #!/bin/sh
                $julia --project="$project_file" $sysimage_flag --startup-file=no -e 'import $pkgname; $funcname(ARGS)' -- "\$@"
                """)
        end
    end
    make_executable(filename_full)
end
function create_script_wrapper(ctx::Pkg.Types.Context, filename, script; sysimage=nothing)
    julia = joinpath(Sys.BINDIR, Base.julia_exename())
    project_file = ctx.env.project_file
    filename_full = joinpath(dirname(project_file), filename)
    if Sys.iswindows()
        filename_full = filename_full * ".cmd"
    end
    script_full = joinpath(dirname(project_file), script)

    mkpath(dirname(filename_full))
    if isnothing(sysimage)
        sysimage_flag = ""
    else
        sysimage_full = joinpath(dirname(project_file), sysimage)
        sysimage_flag = "--sysimage \"$sysimage_full\""
    end

    @debug "creating file" filename_full
    open(filename_full, "w+") do io
        if Sys.iswindows()
            write(io, """
                @echo off
                $julia --project="$project_file" $sysimage_flag --startup-file=no -- "$script_full" %*
                """)
        else
            write(io, """
                #!/bin/sh
                $julia --project="$project_file" $sysimage_flag --startup-file=no -- "$script_full" "\$@"
                """)
        end
    end
    make_executable(filename_full)
end


end # module
