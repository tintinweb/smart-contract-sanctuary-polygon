//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../interfaces/INFT.sol";
import "../libraries/MapperStorage.sol";
import "../libraries/nodes/AftermarketDeviceStorage.sol";

/// @title Mapper
/// @notice Contract to map relationships between nodes and other contracts
contract Mapper {
    event BeneficiarySet(
        address indexed idProxyAddress,
        uint256 indexed nodeId,
        address indexed beneficiary
    );

    /// @notice Sets the beneficiary associated with the aftermarket device
    /// @dev Only the nodeId owner can set a beneficiary
    /// @dev To clear the beneficiary, users can pass the zero address
    /// @param nodeId The node Id to be associated with the beneficiary
    /// @param beneficiary The address to be a beneficiary
    function setAftermarketDeviceBeneficiary(
        uint256 nodeId,
        address beneficiary
    ) external {
        address adProxyAddress = AftermarketDeviceStorage
            .getStorage()
            .idProxyAddress;
        address nodeOwner = INFT(adProxyAddress).ownerOf(nodeId);

        require(
            nodeOwner == msg.sender || adProxyAddress == msg.sender,
            "Only owner or proxy"
        );
        require(nodeOwner != beneficiary, "Beneficiary cannot be the owner");

        MapperStorage.getStorage().beneficiaries[adProxyAddress][
            nodeId
        ] = beneficiary;

        emit BeneficiarySet(adProxyAddress, nodeId, beneficiary);
    }

    /// @notice Gets the link between vehicle and aftermarket device nodes
    /// @param idProxyAddress The address of the NFT proxy
    /// @param sourceNode The source node id to be queried
    function getLink(address idProxyAddress, uint256 sourceNode)
        external
        view
        returns (uint256 targetNode)
    {
        targetNode = MapperStorage.getStorage().links[idProxyAddress][
            sourceNode
        ];
    }

    /// @notice Gets the link between two nodes (source -> target)
    /// @param idProxyAddressSource The address of the NFT proxy source
    /// @param idProxyAddressTarget The address of the NFT proxy target
    /// @param sourceNode The source node id to be queried
    function getNodeLink(
        address idProxyAddressSource,
        address idProxyAddressTarget,
        uint256 sourceNode
    ) external view returns (uint256 targetNode) {
        targetNode = MapperStorage.getStorage().nodeLinks[idProxyAddressSource][
            idProxyAddressTarget
        ][sourceNode];
    }

    /// @notice Gets the beneficiary associated with the pair idProxy/nodeId.
    /// @notice If the beneficiary is not explicitly set, it defaults to the owner
    /// @param idProxyAddress The address of the NFT proxy
    /// @param nodeId The node Id to be queried
    function getBeneficiary(address idProxyAddress, uint256 nodeId)
        external
        view
        returns (address beneficiary)
    {
        beneficiary = MapperStorage.getStorage().beneficiaries[idProxyAddress][
            nodeId
        ];

        if (beneficiary == address(0)) {
            beneficiary = INFT(idProxyAddress).ownerOf(nodeId);
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @title INFT
/// @notice Interface of a generic NFT
interface INFT {
    function safeMint(address to) external returns (uint256);

    function safeTransferByRegistry(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function exists(uint256 tokenId) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @title MapperStorage
/// @notice Storage of the Mapper contract
library MapperStorage {
    bytes32 internal constant MAPPER_STORAGE_SLOT =
        keccak256("DIMORegistry.mapper.storage");

    struct Storage {
        // Links between Vehicles and ADs
        // idProxyAddress -> vehicleId/adId -> adId/vehicleId
        mapping(address => mapping(uint256 => uint256)) links;
        // Stores beneficiary addresses for a given nodeId of an idProxy
        // idProxyAddress -> nodeId -> beneficiary
        mapping(address => mapping(uint256 => address)) beneficiaries;
        // idProxyAddress1 -> idProxyAddress2 -> nftId1 -> nftId2
        mapping(address => mapping(address => mapping(uint256 => uint256))) nodeLinks;
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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../AttributeSet.sol";

/// @title AftermarketDeviceStorage
/// @notice Storage of the AftermarketDevice contract
library AftermarketDeviceStorage {
    using AttributeSet for AttributeSet.Set;

    bytes32 private constant AFTERMARKET_DEVICE_STORAGE_SLOT =
        keccak256("DIMORegistry.aftermarketDevice.storage");

    struct Storage {
        address idProxyAddress;
        // Allowed node attribute
        AttributeSet.Set whitelistedAttributes;
        // AD Id => already claimed or not
        mapping(uint256 => bool) deviceClaimed;
        // AD address => AD Id
        mapping(address => uint256) deviceAddressToNodeId;
        // AD Id => AD address
        mapping(uint256 => address) nodeIdToDeviceAddress;
    }

    /* solhint-disable no-inline-assembly */
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 slot = AFTERMARKET_DEVICE_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)

library AttributeSet {
    struct Set {
        string[] _values;
        mapping(string => uint256) _indexes;
    }

    function add(Set storage set, string calldata key) internal returns (bool) {
        if (!exists(set, key)) {
            set._values.push(key);
            set._indexes[key] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function remove(Set storage set, string calldata key)
        internal
        returns (bool)
    {
        uint256 valueIndex = set._indexes[key];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                string memory lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    function count(Set storage set) internal view returns (uint256) {
        return (set._values.length);
    }

    function exists(Set storage set, string calldata key)
        internal
        view
        returns (bool)
    {
        return set._indexes[key] != 0;
    }
}