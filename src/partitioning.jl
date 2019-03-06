
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

function create_partition2(len1::NTuple{N1,Int},len2::NTuple{N2,Int}) where {N1,N2}
    part1 = create_partition(len1)
    part2 = create_partition(len2)
    partition = NTuple{2,UnitRange{Int}}[]
    for (rng1,rng2) in Iterators.product(part1,part2)
        push!(partition, (rng1,rng2))
    end
    partition
end
create_partition2(lengths::NTuple{N,Int}) where N = create_partition2(lengths,lengths)

function create_partition2(len1::NTuple{N1,Int},len2::NTuple{N2,Int},
        names1::NTuple{N1,Symbol}, names2::NTuple{N2,Symbol}) where {N1,N2}
    partition = create_partition2(len1,len2)
    names_all = vec(collect(Iterators.product(names1,names2)))
    names_all = Tuple([Symbol(string(a) * string(b)) for (a,b) in names_all])
    named_part = NamedTuple{names_all}(partition)
    return named_part
end
create_partition2(lengths::NTuple{N,Int}, names::NTuple{N,Symbol}) where N = create_partition2(lengths,lengths,names,names)
