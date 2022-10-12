// SPDX-License-Identifier: Apache-2.0

import "../base/IRMRKBaseStorage.sol";
import "../equippable/IRMRKEquippable.sol";
import "../library/RMRKLib.sol";
import "./IRMRKEquipRenderUtils.sol";
// import "hardhat/console.sol";

pragma solidity ^0.8.15;

error RMRKTokenDoesNotHaveActiveResource();
error RMRKNotComposableResource();

/**
 * @dev Extra utility functions for composing RMRK extended resources.
 */

contract RMRKEquipRenderUtils is IRMRKEquipRenderUtils {
    using RMRKLib for uint64[];

    function supportsInterface(bytes4 interfaceId)
        external
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IRMRKEquipRenderUtils).interfaceId;
    }

    function getExtendedResourceByIndex(
        address target,
        uint256 tokenId,
        uint256 index
    ) external view virtual returns (IRMRKEquippable.ExtendedResource memory) {
        IRMRKEquippable target_ = IRMRKEquippable(target);
        uint64 resourceId = target_.getActiveResources(tokenId)[index];
        return target_.getExtendedResource(resourceId);
    }

    function getPendingExtendedResourceByIndex(
        address target,
        uint256 tokenId,
        uint256 index
    ) external view virtual returns (IRMRKEquippable.ExtendedResource memory) {
        IRMRKEquippable target_ = IRMRKEquippable(target);
        uint64 resourceId = target_.getPendingResources(tokenId)[index];
        return target_.getExtendedResource(resourceId);
    }

    function getExtendedResourcesById(
        address target,
        uint64[] calldata resourceIds
    )
        external
        view
        virtual
        returns (IRMRKEquippable.ExtendedResource[] memory)
    {
        IRMRKEquippable target_ = IRMRKEquippable(target);
        uint256 len = resourceIds.length;
        IRMRKEquippable.ExtendedResource[]
            memory resources = new IRMRKEquippable.ExtendedResource[](len);
        for (uint256 i; i < len; ) {
            resources[i] = target_.getExtendedResource(resourceIds[i]);
            unchecked {
                ++i;
            }
        }
        return resources;
    }

    function getEquipped(
        address target,
        uint64 tokenId,
        uint64 resourceId
    )
        public
        view
        returns (
            uint64[] memory slotParts,
            IRMRKEquippable.Equipment[] memory childrenEquipped
        )
    {
        IRMRKEquippable target_ = IRMRKEquippable(target);

        address targetBaseAddress = target_.getBaseAddressOfResource(
            resourceId
        );
        uint64[] memory slotPartIds = target_.getSlotPartIds(resourceId);

        // TODO: Clarify on docs: Some children equipped might be empty.
        slotParts = new uint64[](slotPartIds.length);
        childrenEquipped = new IRMRKEquippable.Equipment[](slotPartIds.length);

        uint256 len = slotPartIds.length;
        for (uint256 i; i < len; ) {
            slotParts[i] = slotPartIds[i];
            IRMRKEquippable.Equipment memory equipment = target_.getEquipment(
                tokenId,
                targetBaseAddress,
                slotPartIds[i]
            );
            if (equipment.resourceId == resourceId) {
                childrenEquipped[i] = equipment;
            }
            unchecked {
                ++i;
            }
        }
    }

    function composeEquippables(
        address target,
        uint256 tokenId,
        uint64 resourceId
    )
        public
        view
        returns (
            IRMRKEquippable.ExtendedResource memory resource,
            IRMRKEquippable.FixedPart[] memory fixedParts,
            IRMRKEquippable.SlotPart[] memory slotParts
        )
    {
        IRMRKEquippable target_ = IRMRKEquippable(target);

        // We make sure token has that resource. Alternative is to receive index but makes equipping more complex.
        (, bool found) = target_.getActiveResources(tokenId).indexOf(
            resourceId
        );
        if (!found) revert RMRKTokenDoesNotHaveActiveResource();

        address targetBaseAddress = target_.getBaseAddressOfResource(
            resourceId
        );
        if (targetBaseAddress == address(0)) revert RMRKNotComposableResource();

        resource = target_.getExtendedResource(resourceId);

        // Fixed parts:
        uint64[] memory fixedPartIds = target_.getFixedPartIds(resourceId);
        fixedParts = new IRMRKEquippable.FixedPart[](fixedPartIds.length);

        uint256 len = fixedPartIds.length;
        if (len != 0) {
            IRMRKBaseStorage.Part[] memory baseFixedParts = IRMRKBaseStorage(
                targetBaseAddress
            ).getParts(fixedPartIds);
            for (uint256 i; i < len; ) {
                fixedParts[i] = IRMRKEquippable.FixedPart({
                    partId: fixedPartIds[i],
                    z: baseFixedParts[i].z,
                    metadataURI: baseFixedParts[i].metadataURI
                });
                unchecked {
                    ++i;
                }
            }
        }

        // Slot parts:
        uint64[] memory slotPartIds = target_.getSlotPartIds(resourceId);
        slotParts = new IRMRKEquippable.SlotPart[](slotPartIds.length);
        len = slotPartIds.length;

        if (len != 0) {
            IRMRKBaseStorage.Part[] memory baseSlotParts = IRMRKBaseStorage(
                targetBaseAddress
            ).getParts(slotPartIds);
            for (uint256 i; i < len; ) {
                IRMRKEquippable.Equipment memory equipment = target_
                    .getEquipment(tokenId, targetBaseAddress, slotPartIds[i]);
                if (equipment.resourceId == resourceId) {
                    slotParts[i] = IRMRKEquippable.SlotPart({
                        partId: slotPartIds[i],
                        childResourceId: equipment.childResourceId,
                        z: baseSlotParts[i].z,
                        childTokenId: equipment.childTokenId,
                        childAddress: equipment.childEquippableAddress,
                        metadataURI: baseSlotParts[i].metadataURI
                    });
                } else {
                    slotParts[i] = IRMRKEquippable.SlotPart({
                        partId: slotPartIds[i],
                        childResourceId: uint64(0),
                        z: baseSlotParts[i].z,
                        childTokenId: uint256(0),
                        childAddress: address(0),
                        metadataURI: baseSlotParts[i].metadataURI
                    });
                }
                unchecked {
                    ++i;
                }
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRMRKBaseStorage is IERC165 {
    /**
     * @dev emitted when one or more addresses are added for equippable status for partId.
     */
    event AddedPart(
        uint64 indexed partId,
        ItemType indexed itemType,
        uint8 zIndex,
        address[] equippableAddresses,
        string metadataURI
    );

    /**
     * @dev emitted when one or more addresses are added for equippable status for partId.
     */
    event AddedEquippables(
        uint64 indexed partId,
        address[] equippableAddresses
    );

    /**
     * @dev emitted when one or more addresses are whitelisted for equippable status for partId.
     * Overwrites previous equippable addresses.
     */
    event SetEquippables(uint64 indexed partId, address[] equippableAddresses);

    /**
     * @dev emitted when a partId is flagged as equippable by any.
     */
    event SetEquippableToAll(uint64 indexed partId);

    /**
     * @dev Item type enum for fixed and slot parts.
     */
    enum ItemType {
        None,
        Slot,
        Fixed
    }

    /**
    @dev Base struct for a standard RMRK base item. Requires a minimum of 3 storage slots per base item,
    * equivalent to roughly 60,000 gas as of Berlin hard fork (April 14, 2021), though 5-7 storage slots
    * is more realistic, given the standard length of an IPFS URI. This will result in between 25,000,000
    * and 35,000,000 gas per 250 resources--the maximum block size of ETH mainnet is 30M at peak usage.
    */
    struct Part {
        ItemType itemType; //1 byte
        uint8 z; //1 byte
        address[] equippable; //n Collections that can be equipped into this slot
        string metadataURI; //n bytes 32+
    }

    /**
     * @dev Returns true if the part at partId is equippable by targetAddress.
     *
     * Requirements: None
     */
    function checkIsEquippable(uint64 partId, address targetAddress)
        external
        view
        returns (bool);

    /**
     * @dev Returns true if the part at partId is equippable by all addresses.
     *
     * Requirements: None
     */
    function checkIsEquippableToAll(uint64 partId) external view returns (bool);

    /**
     * @dev Returns the part object at reference partId.
     *
     * Requirements: None
     */
    function getPart(uint64 partId) external view returns (Part memory);

    /**
     * @dev Returns the part objects at reference partIds.
     *
     * Requirements: None
     */
    function getParts(uint64[] calldata partIds)
        external
        view
        returns (Part[] memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../multiresource/IRMRKMultiResource.sol";

interface IRMRKEquippable is IRMRKMultiResource {
    struct Equipment {
        uint64 resourceId;
        uint64 childResourceId;
        uint256 childTokenId;
        address childEquippableAddress;
    }

    struct ExtendedResource {
        // Used for input/output only
        uint64 id; // ID of this resource
        uint64 equippableRefId;
        address baseAddress;
        string metadataURI;
    }

    struct FixedPart {
        uint64 partId;
        uint8 z; //1 byte
        string metadataURI; //n bytes 32+
    }

    struct SlotPart {
        uint64 partId;
        uint64 childResourceId;
        uint8 z; //1 byte
        uint256 childTokenId;
        address childAddress;
        string metadataURI; //n bytes 32+
    }

    struct IntakeEquip {
        uint256 tokenId;
        uint256 childIndex;
        uint64 resourceId;
        uint64 slotPartId;
        uint64 childResourceId;
    }

    /**
     * @dev emitted when a child's resource is equipped into one of its parent resources.
     */
    event ChildResourceEquipped(
        uint256 indexed tokenId,
        uint64 indexed resourceId,
        uint64 indexed slotPartId,
        uint256 childTokenId,
        address childAddress,
        uint64 childResourceId
    );

    /**
     * @dev emitted when a child's resource is removed from one of its parent resources.
     */
    event ChildResourceUnequipped(
        uint256 indexed tokenId,
        uint64 indexed resourceId,
        uint64 indexed slotPartId,
        uint256 childTokenId,
        address childAddress,
        uint64 childResourceId
    );

    /**
     * @dev emitted when it's declared that resources with the referenceId, are equippable into the parent address, on the partId slot
     */
    event ValidParentReferenceIdSet(
        uint64 indexed referenceId,
        uint64 indexed slotPartId,
        address parentAddress
    );

    /**
     * @dev Returns if the tokenId is considered to be equipped into another resource.
     */
    function isChildEquipped(
        uint256 tokenId,
        address childAddress,
        uint256 childTokenId
    ) external view returns (bool);

    /**
     * @dev Returns whether or not tokenId with resourceId can be equipped into parent contract at slot
     *
     */
    function canTokenBeEquippedWithResourceIntoSlot(
        address parent,
        uint256 tokenId,
        uint64 resourceId,
        uint64 slotId
    ) external view returns (bool);

    /**
     * @dev returns slotPartIds present on a given resource.
     *
     */
    function getSlotPartIds(uint64 resourceId)
        external
        view
        returns (uint64[] memory);

    /**
     * @dev returns fixedPartIds present on a given resource.
     *
     */
    function getFixedPartIds(uint64 resourceId)
        external
        view
        returns (uint64[] memory);

    /**
     * @dev returns Equipment object equipped into slotPartId on tokenId for targetBaseAddress.
     *
     */
    function getEquipment(
        uint256 tokenId,
        address targetBaseAddress,
        uint64 slotPartId
    ) external view returns (Equipment memory);

    /**
     * @dev returns extended resource for resourceId, including baseAddress and equipment reference ID.
     *
     */
    function getExtendedResource(uint64 resourceId)
        external
        view
        returns (ExtendedResource memory);

    /**
     * @dev returns base address associated with a given resource.
     *
     */
    function getBaseAddressOfResource(uint64 resourceId)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

library RMRKLib {
    function removeItemByValue(uint64[] storage array, uint64 value) internal {
        uint64[] memory memArr = array; //Copy array to memory, check for gas savings here
        uint256 length = memArr.length; //gas savings
        for (uint256 i; i < length; ) {
            if (memArr[i] == value) {
                removeItemByIndex(array, i);
                break;
            }
            unchecked {
                ++i;
            }
        }
    }

    //For resource storage array
    function removeItemByIndex(uint64[] storage array, uint256 index) internal {
        //Check to see if this is already gated by require in all calls
        require(index < array.length);
        array[index] = array[array.length - 1];
        array.pop();
    }

    // indexOf adapted from Cryptofin-Solidity arrayUtils
    function indexOf(uint64[] memory A, uint64 a)
        internal
        pure
        returns (uint256, bool)
    {
        uint256 length = A.length;
        for (uint256 i; i < length; ) {
            if (A[i] == a) {
                return (i, true);
            }
            unchecked {
                ++i;
            }
        }
        return (0, false);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "../equippable/IRMRKEquippable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRMRKEquipRenderUtils is IERC165 {
    /**
     * @notice Returns `ExtendedResource` object associated with `resourceId`
     *
     * Requirements:
     *
     * - `resourceId` must exist.
     *
     */
    function getExtendedResourceByIndex(
        address target,
        uint256 tokenId,
        uint256 index
    ) external view returns (IRMRKEquippable.ExtendedResource memory);

    /**
     * @notice Returns `ExtendedResource` object at `index` of active resource array on `tokenId`
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - `index` must be inside the range of active resource array
     */
    function getPendingExtendedResourceByIndex(
        address target,
        uint256 tokenId,
        uint256 index
    ) external view returns (IRMRKEquippable.ExtendedResource memory);

    /**
     * @notice Returns `ExtendedResource` objects for the given ids
     *
     * Requirements:
     *
     * - `resourceIds` must exist.
     */
    function getExtendedResourcesById(
        address target,
        uint64[] calldata resourceIds
    ) external view returns (IRMRKEquippable.ExtendedResource[] memory);

    function getEquipped(
        address target,
        uint64 tokenId,
        uint64 resourceId
    )
        external
        view
        returns (
            uint64[] memory slotParts,
            IRMRKEquippable.Equipment[] memory childrenEquipped
        );

    function composeEquippables(
        address target,
        uint256 tokenId,
        uint64 resourceId
    )
        external
        view
        returns (
            IRMRKEquippable.ExtendedResource memory resource,
            IRMRKEquippable.FixedPart[] memory fixedParts,
            IRMRKEquippable.SlotPart[] memory slotParts
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRMRKMultiResource is IERC165 {
    /**
     * @notice emitted when a resource object is initialized at resourceId
     */
    event ResourceSet(uint64 indexed resourceId);

    /**
     * @notice emitted when a resource object at resourceId is added to tokenId's pendingResource array
     */
    event ResourceAddedToToken(
        uint256 indexed tokenId,
        uint64 indexed resourceId
    );

    /**
     * @notice emitted when a resource object at resourceId is accepted by tokenId and migrated from tokenId's pendingResource array to resource array
     */
    event ResourceAccepted(uint256 indexed tokenId, uint64 indexed resourceId);

    /**
     * @notice emitted when a resource object at resourceId is rejected from tokenId and is dropped from the pendingResource array
     */
    event ResourceRejected(uint256 indexed tokenId, uint64 indexed resourceId);

    /**
     * @notice emitted when tokenId's prioritiy array is reordered.
     */
    event ResourcePrioritySet(uint256 indexed tokenId);

    /**
     * @notice emitted when a resource object at resourceId is proposed to tokenId, and that proposal will initiate an overwrite of overwrites with resourceId if accepted.
     */
    event ResourceOverwriteProposed(
        uint256 indexed tokenId,
        uint64 indexed resourceId,
        uint64 indexed overwritesId
    );

    /**
     * @notice emitted when a pending resource with an overwrite is accepted, overwriting tokenId's resource overwritten
     */
    event ResourceOverwritten(
        uint256 indexed tokenId,
        uint64 indexed oldResourceId,
        uint64 indexed newResourceId
    );

    /**
     * @notice emitted when owner approves approved to manage the resources of tokenId. Approvals are cleared on action.
     */
    event ApprovalForResources(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @notice emitted when owner approves operator to manage the resources of tokenId. Approvals are not cleared on action.
     */
    event ApprovalForAllForResources(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Resource object used by the RMRK NFT protocol
     */
    struct Resource {
        uint64 id; //8 bytes
        string metadataURI; //32+
    }

    /**
     * @notice Accepts a resource at `index` on pending array of `tokenId`.
     * Migrates the resource from the token's pending resource array to the active resource array.
     *
     * Active resources cannot be removed by anyone, but can be replaced by a new resource.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     * - `index` must be in range of the length of the pending resource array.
     *
     * Emits an {ResourceAccepted} event.
     */
    function acceptResource(uint256 tokenId, uint256 index) external;

    /**
     * @notice Rejects a resource at `index` on pending array of `tokenId`.
     * Removes the resource from the token's pending resource array.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     * - `index` must be in range of the length of the pending resource array.
     *
     * Emits a {ResourceRejected} event.
     */
    function rejectResource(uint256 tokenId, uint256 index) external;

    /**
     * @notice Rejects all resources from the pending array of `tokenId`.
     * Effecitvely deletes the array.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits a {ResourceRejected} event with resourceId = 0.
     */
    function rejectAllResources(uint256 tokenId) external;

    /**
     * @notice Sets a new priority array on `tokenId`.
     * The priority array is a non-sequential list of uint16s, where lowest uint64 is considered highest priority.
     * `0` priority is a special case which is equibvalent to unitialized.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     * - The length of `priorities` must be equal to the length of the active resources array.
     *
     * Emits a {ResourcePrioritySet} event.
     */
    function setPriority(uint256 tokenId, uint16[] calldata priorities)
        external;

    /**
     * @notice Returns IDs of active resources of `tokenId`.
     * Resource data is stored by reference, in order to access the data corresponding to the id, call `getResourceMeta(resourceId)`
     */
    function getActiveResources(uint256 tokenId)
        external
        view
        returns (uint64[] memory);

    /**
     * @notice Returns IDs of pending resources of `tokenId`.
     * Resource data is stored by reference, in order to access the data corresponding to the id, call `getResourceMeta(resourceId)`
     */
    function getPendingResources(uint256 tokenId)
        external
        view
        returns (uint64[] memory);

    /**
     * @notice Returns priorities of active resources of `tokenId`.
     */
    function getActiveResourcePriorities(uint256 tokenId)
        external
        view
        returns (uint16[] memory);

    //TODO: review definition
    /**
     * @notice Returns the resource which will be overridden if resourceId is accepted from
     * a pending resource array on `tokenId`.
     * Resource data is stored by reference, in order to access the data corresponding to the id, call `getResourceMeta(resourceId)`
     */
    function getResourceOverwrites(uint256 tokenId, uint64 resourceId)
        external
        view
        returns (uint64);

    /**
     * @notice Returns raw bytes of `customResourceId` of `resourceId`
     * Raw bytes are stored by reference in a double mapping structure of `resourceId` => `customResourceId`
     *
     * Custom data is intended to be stored as generic bytes and decode by various protocols on an as-needed basis
     *
     */
    function getResourceMeta(uint64 resourceId)
        external
        view
        returns (string memory);

    /**
     * @notice Fetches resource data for the token's active resource with the given index.
     * @dev Resources are stored by reference mapping _resources[resourceId]
     * @dev Can be overriden to implement enumerate, fallback or other custom logic
     */
    function getResourceMetaForToken(uint256 tokenId, uint64 resourceIndex)
        external
        view
        returns (string memory);

    /**
     * @notice Returns the ids of all stored resources
     */
    function getAllResources() external view returns (uint64[] memory);

    // Approvals

    /**
     * @notice Gives permission to `to` to manage `tokenId` resources.
     * This differs from transfer approvals, as approvals are not cleared when the approved
     * party accepts or rejects a resource, or sets resource priorities. This approval is cleared on token transfer.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {ApprovalForResources} event.
     */
    function approveForResources(address to, uint256 tokenId) external;

    /**
     * @notice Returns the account approved to manage resources of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApprovedForResources(uint256 tokenId)
        external
        view
        returns (address);

    /**
     * @dev Approve or remove `operator` as an operator of resources for the caller.
     * Operators can call {acceptResource}, {rejectResource}, {rejectAllResources} or {setPriority} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAllForResources} event.
     */
    function setApprovalForAllForResources(address operator, bool approved)
        external;

    /**
     * @notice Returns if the `operator` is allowed to manage all resources of `owner`.
     *
     * See {setApprovalForAllForResources}
     */
    function isApprovedForAllForResources(address owner, address operator)
        external
        view
        returns (bool);
}