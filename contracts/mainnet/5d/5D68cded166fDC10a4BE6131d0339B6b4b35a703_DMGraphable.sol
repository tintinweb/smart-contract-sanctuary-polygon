//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/* 
   Properties: 
*/

contract DMGraphable 
{
    struct Param
    { 
        bytes32 name; 
        bytes32 value; 
    }
    struct Node
    {
        bytes32 nodeHash; // 
        uint256 tokenId;
        address container;       
        bytes32 nodeType; // node types can be on swarm
    }
    struct Edge
    {
        bytes32  edgeHash; // 
        uint256  from;
        uint256  to;
    }
    struct Graph
    { 
        address creator;
    } 

    Graph[] internal graphs;
    mapping (address => uint256[]) internal ownerGraphs; // what graphs owner has 

    mapping (uint256 => Node[]) internal   _nodes; // per graph nodes
    mapping (uint256 => Edge[]) internal   _edges; // per graph edges
    mapping (bytes32 => Param[]) internal  _params;  // nodeHash to params array

    struct GraphNode
    {
        uint256 graphIdx; 
        uint256 idx; // node or edge 
    }
    mapping (bytes32 => GraphNode) internal hashToNode; 
    mapping (bytes32 => GraphNode) internal hashToEdge; 

    constructor() { 

    }

    function numGraphs() public view returns (uint256) {
        return (graphs.length);
    }
    function getGraph(uint256 graphIdx) public view returns (Graph memory, Node[] memory, Edge[] memory) {
        require(graphIdx<graphs.length,"!g");
        return (graphs[graphIdx],_nodes[graphIdx], _edges[graphIdx]);
    }
    function getGraphsCountFor(address graphOwner) public view returns (uint256[] memory) {
        return ownerGraphs[graphOwner];
    }
    function getGraphFrom(address graphOwner, uint256 index) public view returns (Graph memory) {
        return graphs[ownerGraphs[graphOwner][index]]; // return
    }

    /* @dev  */
    function createGraph() public returns (Graph memory) {
        Graph memory g = Graph({creator:msg.sender}); //Graph({creator:msg.sender, nodes:nodes, edges:edges});
        g.creator = msg.sender;

        ownerGraphs[msg.sender].push(graphs.length);
        graphs.push(g);
        return g;
    }

    function addNode(uint256 graphIdx, uint256 tokenId, address nftCollection, bytes32 nodeType) public returns (bytes32)
    {
       require(graphIdx<graphs.length,"!g");
       Graph storage g = graphs[graphIdx];
       require(g.creator==msg.sender,"!o");

       bytes32 hash = keccak256(abi.encodePacked(graphIdx,tokenId, nftCollection, nodeType, block.timestamp, block.number));
       Node memory n = Node({nodeHash: hash, tokenId:tokenId, container: nftCollection, nodeType:nodeType});

       GraphNode memory gn = GraphNode({graphIdx:graphIdx, idx:_nodes[graphIdx].length}); 
       hashToNode[hash] = gn;

       _nodes[graphIdx].push(n);
       return hash;
    }
    function addEdge(uint256 graphIdx, uint256 fromNode, uint256 toNode) public returns (uint256 edgeIdx)
    {
       require(graphIdx<graphs.length,"!g");
       Graph storage g = graphs[graphIdx];
       require(g.creator==msg.sender,"!o");

       require(fromNode<_nodes[graphIdx].length,">from");
       require(toNode<_nodes[graphIdx].length,">to");

       bytes32 hash = keccak256(abi.encodePacked(graphIdx, fromNode, toNode, _nodes[graphIdx].length, _edges[graphIdx].length, block.timestamp, block.number));

       Edge memory e = Edge({edgeHash: hash, from: fromNode, to: toNode});

       GraphNode memory gn = GraphNode({graphIdx:graphIdx, idx:_edges[graphIdx].length}); 
       hashToEdge[hash] = gn;

       _edges[graphIdx].push(e);
       return _edges[graphIdx].length;
    }
    
    function addParamToNode(uint256 graphIdx, uint256 nodeIdx, string memory name, string memory value) public returns (uint256 paramIdx)
    {
       require(graphIdx<graphs.length,"!g");
       Graph storage g = graphs[graphIdx];
       require(g.creator==msg.sender,"!o");
       require(nodeIdx<_nodes[graphIdx].length,"!from");

       Param memory p;
       p.name = stringToBytes32(name);
       p.value = stringToBytes32(value);
       
       bytes32 nodeHash = _nodes[graphIdx][nodeIdx].nodeHash;
       _params[nodeHash].push(p);
       
       return _params[nodeHash].length;
    }

   /****************************************************************************** */
    /* Helpers */

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }
}