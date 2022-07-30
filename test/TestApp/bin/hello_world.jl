if isempty(ARGS)
    println("hello from $(pwd())")
else
    println("hello ", join(ARGS,", "))
end