module PartedArrays
    export
        BlockArray,
        BlockMatrix,
        BlockVector,
        create_partition,
        create_partition2

    include("partitioning.jl")

    import Base: size, getindex, setindex!, length, IndexStyle, +, -, getfield

    struct PartedArray{T,N,M<:AbstractArray{T,N},L} <: AbstractArray{T,N}
        A::M
        partition::Dict{Symbol,NTuple{N,UnitRange{Int}}}
        precompute::Bool
        parts::Dict{Symbol,SubArray{T,N,M,NTuple{N,UnitRange{Int}},L}}
        function PartedArray(A::M,
                partition::Dict{Symbol,NTuple{N,UnitRange{Int}}}, parts::Dict{Symbol,SubArray{T,N,M,NTuple{N,UnitRange{Int}},L}},
                precompute::Bool) where {M<:AbstractArray{T,N},L} where {T,N}
            if precompute
                new{T,N,M,L}(A, partition, precompute, parts)
            else
                new{T,N,M,L}(A, partition, precompute)
            end
        end
        function PartedArray(A::M, partition::Dict{Symbol,NTuple{N,UnitRange{Int}}}) where M<:AbstractArray{T,N} where {T,N}
            new{T,N,M,true}(A, partition, false)
        end
    end
    function PartedArray(A::AbstractArray{T,N}, partition::Dict{Symbol,I}, precompute::Bool) where {T,N,I}
        if precompute
            M = typeof(A)
            parts = Dict{Symbol,SubArray{T,N,M,NTuple{N,UnitRange{Int}},false}}()
            for (key,val) in pairs(partition)
                parts[key] = view(A,val...)
            end
            PartedArray(A, partition, parts, precompute)
        else
            PartedArray(A, partition)
        end
    end


    size(A::PartedArray) = size(A.A)
    getindex(A::PartedArray, i::Int) = getindex(A.A, i)
    getindex(A::PartedArray, I::Vararg{Int,2}) = A.A[I[1], I[2]]
    getindex(A::PartedArray, I...) = getindex(A.A, I...)
    setindex(A::PartedArray, I...) = setindex(A.A, I...)
    setindex!(A::PartedArray, v, i::Int) = setindex!(A.A, v, i)
    setindex!(A::PartedArray, v, I::Vararg{Int, 2}) = A.A[I[1], I[2]]
    IndexStyle(A::PartedArray) = IndexCartesian()
    length(A::PartedArray) = length(A.A)

    +(A::PartedArray, B) = A.A + B
    +(B, A::PartedArray) = B + A.A
    getindex(A::PartedArray, p::Symbol) = view(A.A, A.parts[p]...)
    function Base.getproperty(A::PartedArray{T,N,I}, p::Symbol) where {T,N,I}
        if p == :A || p == :parts
            getfield(A,p)
        else
            if getfield(A,:precompute)
                return getfield(A,:parts)[p]
            else
                return view(getfield(A,:A),getfield(A,:partition)[p]...)
            end
        end
    end

    struct BlockArray{T,N,M<:AbstractArray{T,N},P,NP,I} <: AbstractArray{T,N}
        A::M
        parts::NamedTuple{P,NTuple{NP,I}}
    end
    function BlockArray(A::AbstractMatrix,lengths::NTuple{N,Int},names::NTuple{N,Symbol}) where {N,T}
        parts = create_partition2(lengths,names)
        BlockArray(A,parts)
    end
    function BlockArray(A::AbstractVector,lengths::NTuple{N,Int},names::NTuple{N,Symbol}) where {N,T}
        parts = create_partition(lengths,Tuple(names))
        BlockArray(A,parts)
    end
    BlockArray(A::AbstractArray,lengths::Vector{Int},names::Vector{Symbol}) = BlockArray(A,Tuple(lengths),Tuple(names))
    BlockVector{T,M} = BlockArray{T,1,M}
    BlockMatrix{T,M} = BlockArray{T,2,M}

    size(A::BlockArray) = size(A.A)
    getindex(A::BlockArray, i::Int) = getindex(A.A, i)
    getindex(A::BlockArray, I::Vararg{Int, 2}) where N = A.A[I[1],I[2]]
    getindex(A::BlockArray, I...) = getindex(A.A, I...)
    setindex!(A::BlockArray, I...) = setindex!(A.A, I...)
    setindex!(A::BlockArray, v, i::Int) = setindex!(A.A, v, i)
    setindex!(A::BlockArray, v, I::Vararg{Int, N}) where N = A.A[I[1],I[2]] = v
    IndexStyle(::BlockArray) = IndexCartesian()
    length(A::BlockArray) = length(A.A)
    Base.show(io::IO,A::BlockArray) = show(io::IO,A.A)
    # Base.show(io::IO, T::MIME{Symbol("text/plain")}, X::BlockMatrix) = show(io, T::MIME"text/plain", X.A)
    # display(A::Array{BlockArray,N} where N) = display(A.A)
    +(A::BlockArray,B::Matrix) = A.A + B
    +(B::Matrix,A::BlockArray) = A.A + B
    getindex(A::BlockArray, p::Symbol) = view(A.A,getfield(A.parts,p)...)
    getindex(A::BlockVector, p::Symbol) = view(A.A,getfield(A.parts,p))
    Base.copy(A::BlockArray) = BlockArray(copy(A.A),A.parts)
    function Base.getproperty(A::BlockArray{T,N}, p::Symbol) where {T,N}
        if p == :A || p == :parts
            getfield(A,p)
        else
            if N == 1
                return view(getfield(A,:A), getfield(getfield(A,:parts),p))
            else
                return view(getfield(A,:A), getfield(getfield(A,:parts),p)...)
            end
        end
    end

end # module
