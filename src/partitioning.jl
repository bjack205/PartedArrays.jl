
function create_partition(lengths::NTuple{N,Int}) where N
    num = 0
    partition = UnitRange{Int}[]
    for i = 1:length(lengths)
        push!(partition, (1:lengths[i]) .+ num)
        num += lengths[i]
    end
    return partition
end

function create_partition(lengths::NTuple{N,Int}, names::NTuple{N,Symbol}) where {N,T}
    partition = Tuple(create_partition(lengths))
    named_part = NamedTuple{names,NTuple{N,UnitRange{Int}}}(partition)
    return named_part
    # return named_part::NamedTuple{M,NTuple{N,UnitRange{Int}}}
end

function create_partition2(lengths::NTuple{N,Int}) where N
    part1 = create_partition(lengths)
    partition = NTuple{2,UnitRange{Int}}[]
    for (rng1,rng2) in Iterators.product(part1,part1)
        push!(partition, (rng1,rng2))
    end
    # linds = LinearIndices((N,N))
    # return [linds[id[1],id[2]] for id in partition]
    # return CartesianIndices.(partition)
    return partition
end

function create_partition2(lengths::NTuple{N,Int}, names::NTuple{N,Symbol}) where N
    partition = create_partition2(lengths)
    names_all = vec(collect(Iterators.product(names,names)))
    names_all = Tuple([Symbol(string(a) * string(b)) for (a,b) in names_all])
    named_part = NamedTuple{names_all}(partition)
    return named_part
end
