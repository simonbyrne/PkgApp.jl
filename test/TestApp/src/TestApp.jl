module TestApp

function hello_world(ARGS)
    if isempty(ARGS)
        println("hello from $(pwd())")
    else
        println("hello ", join(ARGS,", "))
    end
end

end # module
