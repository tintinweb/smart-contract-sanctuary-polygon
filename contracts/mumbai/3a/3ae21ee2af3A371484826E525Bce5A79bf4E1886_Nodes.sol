//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../libraries/NodesStorage.sol";

contract Nodes {
    // TODO Do we need this?
    // function registerNode() external {}

    /// @notice Gets the parent node of a node
    /// @param nftProxyAddress The address of the proxy associated with the node Id
    /// @param tokenId the id associated to the node
    function getParentNode(address nftProxyAddress, uint256 tokenId)
        external
        view
        returns (uint256 parentNode)
    {
        parentNode = NodesStorage
        .getStorage()
        .nodes[nftProxyAddress][tokenId].parentNode;
    }

    /// @notice Gets information stored in an attribute of a given node
    /// @dev Returns empty string if does or attribute does not exists
    /// @param nftProxyAddress The address of the proxy associated with the token Id
    /// @param tokenId Node id from which info will be obtained
    /// @param attribute Key attribute
    /// @return info Info obtained
    function getInfo(
        address nftProxyAddress,
        uint256 tokenId,
        string calldata attribute
    ) external view returns (string memory info) {
        info = NodesStorage.getStorage().nodes[nftProxyAddress][tokenId].info[
            attribute
        ];
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

library NodesStorage {
    bytes32 internal constant NODES_STORAGE_SLOT =
        keccak256("DIMORegistry.nodes.storage");

    struct Node {
        // TODO add info to the parent node type
        address nftProxyAddress; // TODO Redundant ?
        uint256 parentNode;
        mapping(string => string) info;
    }

    struct Storage {
        mapping(address => mapping(uint256 => Node)) nodes;
    }

    /* solhint-disable no-inline-assembly */
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 slot = NODES_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}