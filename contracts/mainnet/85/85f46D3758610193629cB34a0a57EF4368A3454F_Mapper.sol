//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../libraries/MapperStorage.sol";

/// @title Mapper
/// @notice Contract to map relationships between nodes
contract Mapper {
    /// @notice Gets the link between two nodes
    /// @param idProxyAddress The address of the NFT proxy
    /// @param sourceNode The node Id to be queried
    function getLink(address idProxyAddress, uint256 sourceNode)
        external
        view
        returns (uint256 targetNode)
    {
        targetNode = MapperStorage.getStorage().links[idProxyAddress][
            sourceNode
        ];
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @title MapperStorage
/// @notice Storage of the Mapper contract
library MapperStorage {
    bytes32 internal constant MAPPER_STORAGE_SLOT =
        keccak256("DIMORegistry.mapper.storage");

    struct Storage {
        mapping(address => mapping(uint256 => uint256)) links;
    }

    /* solhint-disable no-inline-assembly */
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 slot = MAPPER_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}