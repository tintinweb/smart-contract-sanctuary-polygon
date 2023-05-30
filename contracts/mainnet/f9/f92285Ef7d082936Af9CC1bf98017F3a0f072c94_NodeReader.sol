// SPDX-License-Identifier: MIT
/*
    Created by DeNet

    This Contract is Helpful interface to work directly with Node.
*/

pragma solidity ^0.8.1;

import "../interfaces/INodeNFT.sol";

contract NodeReader  {
    
    /*
        get all nodes.
    */
    function getAllNodes(address contractAddress, uint globalShift) external view returns (IMetaData.DeNetNode[32] memory) {
        IDeNetNodeNFT denet_node = IDeNetNodeNFT(contractAddress);
        IMetaData denet_node_data = IMetaData(contractAddress);

        uint amount_of_nodes = denet_node.totalSupply();

        IMetaData.DeNetNode[32] memory _returns;
        for (uint i = 1; i <= amount_of_nodes && i <= 32 && i + globalShift <= amount_of_nodes; i++) {
            _returns[i - 1] = denet_node_data.nodeInfo(i + globalShift);
        }
        return _returns;
    }
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet
*/
pragma solidity ^0.8.0;

interface ISimpleINFT {
    // Create or Transfer Node
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    // Return amount of Nodes by owner
    function balanceOf(address owner) external view returns (uint256);

    // Return Token ID by Node address
    function getNodeIDByAddress(address _node) external view returns (uint256);

    // Return owner address by Token ID
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IMetaData {
    // Create or Update Node
    event UpdateNodeStatus(
        address indexed from,
        uint256 indexed tokenId,
        uint8[4]  ipAddress,
        uint16 port
    );

    // Structure for Node
    struct DeNetNode{
        uint8[4] ipAddress; // for example [127,0,0,1]
        uint16 port;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 updatesCount;
        uint256 rank;
    }

    // Return Node info by token ID;
    function nodeInfo(uint256 tokenId) external view returns (DeNetNode memory);
}

interface IDeNetNodeNFT {
     function totalSupply() external view returns (uint256);

     // PoS Only can ecevute
     function addSuccessProof(address _nodeOwner) external;

     function getLastUpdateByAddress(address _user) external view returns(uint256);
     function getNodesRow(uint _startId, uint _endId) external view returns(IMetaData.DeNetNode[] memory);
}