//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../libraries/MapperStorage.sol";

// TODO Documentation
contract Mapper {
    function getLink(address nftProxyAddress, uint256 sourceNode)
        external
        view
        returns (uint256 targetNode)
    {
        targetNode = MapperStorage.getStorage().links[nftProxyAddress][
            sourceNode
        ];
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

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