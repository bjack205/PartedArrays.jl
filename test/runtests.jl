using PartedArrays
using Test

function myfun(a,b)
    c = [1,3,5,6]
    d = a*b
    e = c .* d
    return e
end

@testset "Vector" begin
# Vector
x,y = collect(1:3),[5,10,1,8]
V = [x;y]
parts = (x=1:3,y=4:7)
Z = BlockArray(V,parts)
@test Z.x == x
@test Z.y == y
@test Z[:x] == x
@test Z[:y] == y
@test Z == V
@test Z.A == V
@test Z[1] == 1
@test Z[end] == 8
@test Z + Z == 2V
@test length(Z) == 7
@test size(Z) == (7,)
Z = BlockArray(V,(3,4),(:x,:y))
@test Z.x == x
@test Z.y == y
@test Z[:x] == x
@test Z[:y] == y
@test Z == V
@test Z.A == V
@test Z[1] == 1
@test Z[end] == 8
@test Z + Z == 2V
@test length(Z) == 7
@test size(Z) == (7,)
Z = BlockArray(V,[3,4],[:x,:y])
@test Z.x == x
@test Z.y == y
@test Z[:x] == x
@test Z[:y] == y
@test Z == V
@test Z.A == V
@test Z[1] == 1
@test Z[end] == 8
@test Z + Z == 2V
@test length(Z) == 7
@test size(Z) == (7,)
@inferred getindex(Z,:x)

# Test multiplication
function testfun(V::BlockArray,a)
    V.A'a
end
a = ones(7)
@inferred testfun(Z,a)

# Copying
Z2 = copy(Z)
@test Z2 isa BlockArray
@test Z2.A == Z.A
@test !(Z2.A === Z.A)
Z2 .= rand(1:7,7)
@test Z2.x != Z.x
Zs = [Z,Z2]
Zs2 = copy(Zs)
@test Zs2[1].A == Zs[1].A
@test Zs2[1].A === Zs[1].A
@test Zs2[2].A === Zs[2].A
Zs2 = deepcopy(Zs)
@test Zs2[1].A == Zs[1].A
@test !(Zs2[1].A === Zs[1].A)
@test !(Zs2[2].A === Zs[2].A)
@test Zs2 isa Vector{BlockArray{Int,1,Vector{Int},P}} where P <: NamedTuple

PartedVecTraj{T} = Vector{BlockArray{Int,1,Vector{Int},P}} where P <: NamedTuple

struct vars{T}
    X::PartedVecTraj{T}
end
v = vars(Zs2)
@inferred rand(3,3)*v.X[1].x

end

@testset "Matrix" begin
# Matrix
xx = ones(2,2)
xy = ones(2,3)*2
yx = ones(3,2)*3
yy = ones(3,3)*10
A = [xx xy;
     yx yy]
parts = (xx=(1:2,1:2),xy=(1:2,3:5),yx=(3:5,1:2),yy=(3:5,3:5))
parts2 = create_partition2((2,3),(:x,:y))
B = BlockArray(A,parts)
B2 = BlockArray(A,parts2)
@inferred rand(2,2)*B.xx
@inferred rand(2,2)*B2.xx
@test B.xx == xx
@test B.yy == yy
@test B[:xx] == xx
@test B[:yy] == yy
@test B.xy == xy
@test B == A
@test B.A == A
@test B[1] == 1
@test B[end] == 10
@test B[2,3] == 2
@test B + B == 2A
@test length(B) == 25
@test size(B) == (5,5)
B = BlockArray(A,(2,3),(:x,:y))
@test B.xx == xx
@test B.yy == yy
@test B[:xx] == xx
@test B[:yy] == yy
@test B.xy == xy
@test B == A
@test B.A == A
@test B[1] == 1
@test B[end] == 10
@test B[2,3] == 2
@test B + B == 2A
@test length(B) == 25
@test size(B) == (5,5)
inds = LinearIndices(A)[1:2,1:2]
@test B[inds] == A[inds]
@test B[inds] == B.xx

@test B + A == 2A
@test IndexStyle(B) == IndexCartesian()
A[2,2] = 10
@test B.xx[2,2] == 10
B[3,3] = 100
@test B.yy[1,1] == 100
B[1:3] .= 1
@test B.xx[:,1] == [1;1]
B[3] = 55
@test B.yx[1] == 55
end

@testset "Partitioning" begin
names = (:x,:y,:z)
lengths = (5,10,15)
lengths2 = (5,10,15,2)
@test_throws MethodError create_partition(lengths2,names)
names2 = (:a,:b)
lengths2 = (2,3)
part = @inferred create_partition2(lengths,lengths2)
@test length(part) == 6
part = create_partition2(lengths,lengths2,names,names2)
@code_warntype create_partition2(lengths,lengths2,names,names2)

@test length(part) == 6
@test part.xa == (1:5,1:2)
@test length.(part.zb) == (15,3)
end

A = rand(1000,500)
part = (x=1:400,y=401:800,z=801:1000)
part2 = Dict(:x=>1:400, :y=>401:800, :z=>801:1000)
part = (xx=(1:400,1:400),yy=(401:1000,401:500),xy=(1:400,401:500))
part2 = Dict(:xx=>(1:400,1:400),:yy=>(401:1000,401:500),:xy=>(1:400,401:500))

B = BlockArray(A,part)
P = PartedArrays.PartedArray(A,part2,true)
typeof(part2)
part2 isa Dict{Symbol,NTuple}
P.parts[:xx]
P.yy
typeof(view(A,[1 2; 3 4]))
@btime $B.yy
@btime $P.yy
@btime BlockArray($A,$part)
@btime PartedArrays.PartedArray($A,$part2,true)
@btime PartedArrays.PartedArray($A,$part2,$P.parts,false)
typeof(P.y)
@btime :x in keys($P.parts)

@code_warntype getproperty(P,:yy)

ind1(A,d,p) = A[d[p]...]
@btime ind1($A,$part,:yy)
@btime ind1($A,$part2,:yy)



function combine_names(names1,names2)
    n1 = length(names1)
    n2 = length(names2)
    function get_inds(x)
        i = cart1(x,n1,n2)
        j = cart2(x,n1,n2)
        Symbol(string(names1[i])*string(names2[j]))
    end
    partition = map(get_inds, ntuple(i->i,n1*n2))
end


function cart1(i,n,m)
    ((i-1) ÷ m)+1
end

function cart2(i,n,m)
    v = i % m
    v == 0 ? m : v
end

create_nt(::Val{names},vals) where {names} = NamedTuple{names}(vals)

function myfun(A,l1,l2)
    mypart = create_partition2(l1,l2)
    part = NamedTuple{(:xx,:xu,:ux,:uu)}(mypart)
end
