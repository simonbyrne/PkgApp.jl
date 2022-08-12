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
    chmod(filename, stat(filename).mode & 0o777 | 0o111)
end


function create_function_wrapper(ctx::Pkg.Types.Context, filename, funcname; sysimage=nothing)
    julia = joinpath(Sys.BINDIR, Base.julia_exename())
    project_file = ctx.env.project_file
    filename_full = joinpath(dirname(project_file), filename)
    project_from_filedir = relpath(dirname(project_file), dirname(filename_full))

    pkgname = split(funcname, ".")[1]
    mkpath(dirname(filename_full))
    if isnothing(sysimage)
        sysimage_flag = ""
    else
        sysimage_flag = "--sysimage \"\$JULIA_PROJECT/$sysimage\""
    end
    @debug "creating file" filename_full
    open(filename_full, "w+") do io
        write(io, """
            #!/bin/sh
            JULIA_PROJECT="\$( cd -- "\$(dirname "\$0")/$project_from_filedir" >/dev/null 2>&1 ; pwd -P )"
            $julia --project="\$JULIA_PROJECT" $sysimage_flag --startup-file=no -e 'import $pkgname; $funcname(ARGS)' "\$@"
            """)
    end
    make_executable(filename_full)
end
function create_script_wrapper(ctx::Pkg.Types.Context, filename, script; sysimage=nothing)
    julia = joinpath(Sys.BINDIR, Base.julia_exename())
    project_file = ctx.env.project_file
    filename_full = joinpath(dirname(project_file), filename)
    project_from_filedir = relpath(dirname(project_file), dirname(filename_full))

    mkpath(dirname(filename_full))
    if isnothing(sysimage)
        sysimage_flag = ""
    else
        sysimage_flag = "--sysimage \"\$JULIA_PROJECT/$sysimage\""
    end

    @debug "creating file" filename_full
    open(filename_full, "w+") do io
        write(io, """
            #!/bin/sh
            JULIA_PROJECT="\$( cd -- "\$(dirname "\$0")/$project_from_filedir" >/dev/null 2>&1 ; pwd -P )"
            $julia --project="\$JULIA_PROJECT" $sysimage_flag --startup-file=no "\$JULIA_PROJECT/$script" "\$@"
            """)
    end
    make_executable(filename_full)
end


end # module
