#= # for local testing, need this:
using Test
using PhyloNetworks
using PhyloPlots
=#

@testset "unconstrained NNI moves" begin

str_level1 = "(((8,9),(((((1,2,3),4),(5)#H1),(#H1,(6,7))))#H2),(#H2,10));"
net_level1 = readTopology(str_level1);
#TODO hybridbelowroot has 3 cycle, need to fix topology
str_hybridbelowroot = "((8,9),(((((1,2,3),4),(5)#H1),(#H1,(6,7))))#H2,(#H2,10));"
net_hybridbelowroot = readTopology(str_hybridbelowroot)
# same topology as: rootatnode!(net_level1, -3). edges 1:22
str_nontreechild = "((((Ag,E))#H3,(#H1:7.159::0.056,((M:0.0)#H2:::0.996,(Ak,(#H3:0.08,#H2:0.0::0.004):0.023):0.078):2.49):2.214):0.026,((Az:2.13,As:2.027):1.697)#H1:0.0::0.944,Ap);"
net_nontreechild = readTopology(str_nontreechild);
# problem: the plot has an extra vertical segment, for a clade that's not in the major tree
# --> fix that in PhyloPlots (fixit)
str_hybridladder = "(#H2:::0.2,((C,((B)#H1)#H2:::0.8),(#H1,(A1,A2))),O);"
net_hybridladder = readTopology(str_hybridladder);

#=
plot(net_level1, :R, showNodeNumber=true, showEdgeNumber=true)
plot(net_hybridbelowroot, :R, showNodeNumber=true, showEdgeNumber=true)
plot(net_nontreechild, :R, showNodeNumber=true, showEdgeNumber=true)
plot(net_hybridladder, :R, showNodeNumber=true, showEdgeNumber=true)
=#

@test isnothing(PhyloNetworks.nni!(net_level1, net_level1.edge[1], 0x01)) # external edge

@testset "level1 edge 3: BB undirected move $move" for move in 0x01:0x08
    undoinfo = PhyloNetworks.nni!(net_level1, net_level1.edge[3], move);
    #location of v node (number -4)
    if move in [1, 2, 6, 8] #check that edge alpha connected to v
        nodes = []
        for n in net_level1.edge[20].node
            push!(nodes, n.number)
        end
        @test -4 in nodes
    elseif move in [3, 4, 5, 7] #check that edge beta connected to v
        nodes = []
        for n in net_level1.edge[19].node
            push!(nodes, n.number)
        end
        @test -4 in nodes
    end
    #location of u node (number -3)
    if move in [2, 4, 5, 6] #check that edge gamma connected to u
        nodes = []
        for n in net_level1.edge[1].node
            push!(nodes, n.number)
        end
        @test -3 in nodes
    elseif move in [1, 3, 7, 8]  #check that edge delta connected to u
        nodes = []
        for n in net_level1.edge[2].node
            push!(nodes, n.number)
        end
        @test -3 in nodes
    end
    #check directionality
    if move in [3, 4, 5, 7] 
        #keeping α, β or flipping uv keeps node -4 as child of edge 3
        @test PhyloNetworks.getChild(net_level1.edge[3]).number == -4
    else 
        #switching α, β AND flipping uv or doing neither makes node -3 child of edge 3
        @test PhyloNetworks.getChild(net_level1.edge[3]).number == -3
    end
    #undo move
    PhyloNetworks.nni!(undoinfo...);
    #confirm we're back to original topology 
    @test writeTopology(net_level1) == str_level1
end #of level1 edge 3: BB undirected

@testset "level1 edge 16: BB directed move $move" for move in 0x01:0x02
    # e not hybrid, tree parent:  BB case, 2 NNIs if directed, 8 if undirected
    undoinfo = PhyloNetworks.nni!(net_level1, net_level1.edge[16], move);
    #check beta connected to u node (number -11)
    nodes = []
    for n in net_level1.edge[13].node
        push!(nodes, n.number)
    end
    @test -11 in nodes
    nodes = []
    for n in net_level1.edge[14].node
        push!(nodes, n.number)
    end
    if move == 1 #check that edge gamma connected to v
        @test -12 in nodes
    else #check that edge gamma connected to u
        @test -11 in nodes
    end
    #check directionality
    #node -11 child of edge 16 in both cases
    @test PhyloNetworks.getChild(net_level1.edge[16]).number == -11
    #undo move
    PhyloNetworks.nni!(undoinfo...);
    #confirm we're back to original topology 
    @test writeTopology(net_level1) == str_level1
end #of level1 edge 16: BB directed

@test_throws Exception PhyloNetworks.nni!(net_level1, net_level1.edge[16], 0x03);

#TODO add BR undirected 

#TODO check this looks like it labels 13 as βu because βu = u.edge[ci[1]] = 13
#This is a four-cycle so several moves will not be allowed
@testset "level1 edge 13: BR directed move $move" for move in 0x01:0x03
    # e.hybrid and tree parent:  BR case, 3 because e cannot contain the root
    undoinfo = PhyloNetworks.nni!(net_level1, net_level1.edge[13], move);
    #test that move was made
    #location of v node
    if move == 1 || (move == 3 && PhyloNetworks.getChild(net_level1.edge[17]).number == -11) #checks that alpha -> u
        #check that edge alpha connected to v
        nodes = []
        for n in net_level1.edge[17].node
            push!(nodes, n.number)
        end
        @test 8 in nodes
    elseif move == 2 || (move == 3 && PhyloNetworks.getChild(net_level1.edge[16]).number == -11) #checks beta -> u
        #check that edge beta connected to v
        nodes = []
        for n in net_level1.edge[16].node
            push!(nodes, n.number)
        end
        @test 8 in nodes
    end
    #location of u node (number -11)
    if move in [3] #check that edge gamma connected to u
        nodes = []
        for n in net_level1.edge[11].node
            push!(nodes, n.number)
        end
        @test -11 in nodes
    elseif move in [1, 2]  #check that edge delta connected to u
        nodes = []
        for n in net_level1.edge[10].node
            push!(nodes, n.number)
        end
        @test -11 in nodes
    end
    #check directionality
    if move == 0x01
        @test PhyloNetworks.getChild(net_level1.edge[13]).number == -11
    else
        @test PhyloNetworks.getChild(net_level1.edge[13]).number == 8
    end
    #undo move
    PhyloNetworks.nni!(undoinfo...);
    #confirm we're back to original topology 
    @test writeTopology(net_level1) == str_level1
end #of level1 edge 13: BR directed

@testset "level1 edge 18: RR (directed) move $move" for move in 0x01:0x04
    # RB case, 4 moves. uv edge cannot contain the root (always directed)
    undoinfo = PhyloNetworks.nni!(net_level1, net_level1.edge[18], move);
    #test that move was made
    #location of v node (node -6)
    nodes = []
    for n in net_level1.edge[19].node
        push!(nodes, n.number)
    end
    if move in [0x01, 0x03]
        #check that edge alpha connected to v
        @test -6 in nodes
    elseif move in [0x02, 0x04]
        #check that edge beta connected to v, not alpha
        @test !(-6 in nodes)
    end
    #location of u node (number 11)
    nodes = []
    for n in net_level1.edge[12].node
        push!(nodes, n.number)
    end
    if move in [0x03, 0x04] #check that edge gamma connected to u
        @test 11 in nodes
    elseif move in [0x01, 0x02]  #check that edge delta connected to u, not gamma
        @test !(11 in nodes)
    end
    #check directionality (should point toward u, node 11)
    @test PhyloNetworks.getChild(net_level1.edge[18]).number == 11
    #undo move
    PhyloNetworks.nni!(undoinfo...);
    #confirm we're back to original topology 
    @test writeTopology(net_level1) == str_level1
end #of level1 edge 18: RR (directed)

#= 
#hybrid at root
@testset "net_hybridbelowroot edge 20: BR undirected move $move" for move in 0x01:0x06
    #in this case, α->u
    undoinfo = PhyloNetworks.nni!(net_hybridbelowroot, net_hybridbelowroot.edge[20], move);
    #test that move was made
    #connections to gamma: 
    nodes = []
    for n in net_hybridbelowroot.edge[19].node
        push!(nodes, n.number)
    end
    if move in [1, 2, 4, 5] #should be connected to v
        @test 11 in nodes
    elseif move in [3, 6] #should be connected to u 
        #both α->u and β->u cases
        @test -12 in nodes
    end
    #connections to alpha (edge 22)
    nodes = []
    for n in net_hybridbelowroot.edge[22].node
        push!(nodes, n.number)
    end
    if move in [1, 3, 5] #should be connected to v 
        @test 11 in nodes
    else #should be connected to u (for 6 too since α->u)
        @test -12 in nodes
    end
    #undo move
    PhyloNetworks.nni!(undoinfo...);
    #confirm we're back to original topology 
    @test writeTopology(net_hybridbelowroot) == str_hybridbelowroot
end #of net_hybridbelowroot edge 20: BR undirected

#hybrid at root
@testset "net_hybridbelowroot edge 22: BB undirected move $move" for move in 0x01:0x06
    #in this case, α->u
    undoinfo = PhyloNetworks.nni!(net_hybridbelowroot, net_hybridbelowroot.edge[22], move);
    #test that move was made
    #connections to gamma
    nodes = []
    for n in net_hybridbelowroot.edge[20].node
        push!(nodes, n.number)
    end
    if move in [1, 3, 7, 8] #gamma connected to v
        @test -12 in nodes
    else #gamma connected to u
        @test -2 in nodes
    end
    #connections to alpha
    nodes = []
    for n in net_hybridbelowroot.edge[3].node
        push!(nodes, n.number)
    end
    if move in [1, 2, 6, 8] #alpha connected to v
        @test -12 in nodes
    else #alpha connected to u
        @test -2 in nodes
    end
    #undo move
    PhyloNetworks.nni!(undoinfo...);
    #confirm we're back to original topology 
    @test writeTopology(net_hybridbelowroot) == str_hybridbelowroot
end #of net_hybridbelowroot edge 22: BB undirected =#

@testset "non tree child net edge 3: RB (directed) move $move" for move in 0x01:0x04
    # RB case, 4 moves. uv edge cannot contain the root
    undoinfo = PhyloNetworks.nni!(net_nontreechild, net_nontreechild.edge[3], move);
    #test that move was made
    #location of v node (node -5)
    nodes = []
    for n in net_nontreechild.edge[4].node
        push!(nodes, n.number)
    end
    if move in [0x01, 0x03]
        #check that edge alpha connected to v
        @test -5 in nodes
    else
        #check that edge beta connected to v, not u
        @test !(-5 in nodes)
    end
    #check that edge delta connected to u, not v
    nodes = []
    for n in net_nontreechild.edge[2].node
        push!(nodes, n.number)
    end
    if move in [0x01, 0x02]
        @test 3 in nodes
    else
        @test !(3 in nodes)
    end
    #check directionality (should point toward u, node 3)
    @test PhyloNetworks.getChild(net_nontreechild.edge[3]).number == 3
    #undo move
    PhyloNetworks.nni!(undoinfo...);
    #confirm we're back to original topology 
    @test writeTopology(net_nontreechild) == str_nontreechild
end #of non tree child net edge 5: RB (directed)

@testset "hybrid ladder net edge 4: RR (directed) move $move" for move in 0x01:0x02
    # RR case, 2 moves. uv edge cannot contain the root (always directed)
    undoinfo = PhyloNetworks.nni!(net_hybridladder, net_hybridladder.edge[4], move);
    #test that move was made
    #location of v node (node 2)
    [n.number for n in net_hybridladder.edge[5].node]
    if move == 0x01 #check that edge alpha connected to v
        @test 4 in nodes
    else move == 0x02 #check that edge beta connected to v, not alpha
        @test !(4 in nodes)
    end
    #check that edge delta connected to u, not gamma
    nodes = []
    for n in net_hybridladder.edge[3].node
        push!(nodes, n.number)
    end
    @test 1 in nodes
    #check directionality (should point toward u, node 1)
    @test PhyloNetworks.getChild(net_hybridladder.edge[4]).number == 1
    #undo move
    PhyloNetworks.nni!(undoinfo...); 
    #confirm we're back to original topology 
    @test writeTopology(net_hybridladder) == str_hybridladder
end #of hybrid ladder net edge 4: RR (directed)

#TODO add test of edge 1
 #TODO update node and edge numbers below
@testset "hybrid ladder net edge 5: BR undirected move $move" for move in 0x01:0x06
    # BR case, 6 moves. uv edge can contain the root
    undoinfo = PhyloNetworks.nni!(net_hybridladder, net_hybridladder.edge[5], move);
    #test that move was made
    #location of v node (node 3)
    nodes = []
        for n in net_hybridladder.edge[6].node
            push!(nodes, n.number)
        end
    if move in [0x01, 0x05] || (move == 0x03 && PhyloNetworks.getChild(net_hybridladder.edge[6]).number == -6) || 
        (move == 0x06 && PhyloNetworks.getChild(net_hybridladder.edge[4]).number == -6)
        #check that edge alpha connected to v (node 3)
        @test 3 in nodes
    else
        #check that edge alpha not connected to v (node 3)
        @test !(3 in nodes)
    end
    #check which nodes delta connected to 
    nodes = []
    for n in net_hybridladder.edge[2].node
        push!(nodes, n.number)
    end
    if move in [0x01, 0x02, 0x04, 0x05]
        @test -6 in nodes #delta connected to u
    else
        @test !(-6 in nodes)
    end
    #check directionality (should point toward u, node -6)
    @test PhyloNetworks.getChild(net_hybridladder.edge[5]).number == -6
    #undo move
    PhyloNetworks.nni!(undoinfo...);
    #confirm we're back to original topology 
    @test writeTopology(net_hybridladder) == str_hybridladder
end #of hybrid ladder net edge 5: BR undirected

#for edge 17, u is connected in a 4 cycle with gamma
#if gamma connected to u, would create a 3 cycle
#TODO our checks don't catch this type of case yet
@testset "net_level1 no3cyle check edge 17: BB directed move 1" begin
    @test_throws Exception PhyloNetworks.nni!(net_level1, net_level1.edge[17], 0x01);
end #of net_level1 no3cyle check edge 17: BB directed

@testset "net_level1 no3cyle check edge 13: BR directed moves 1" begin
    @test_throws Exception PhyloNetworks.nni!(net_level1, net_level1.edge[13], 0x01);
end #of net_level1 no3cyle check edge 17: BB directed

end # of testset on unconstrained NNIs


myconstraint = PhyloNetworks.TopologyConstraint(0x03,Set("8"),net_level1)
undoinfo = PhyloNetworks.nni!(net_level1, net_level1.edge[1], myconstraint)