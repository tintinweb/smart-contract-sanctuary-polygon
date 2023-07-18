// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "openzeppelin4/utils/structs/EnumerableSet.sol";
import "./../interfaces/IAccessControl.sol";
import "../interfaces/IMarketplaceAdmin.sol";
import "../utils/FacetInitializable.sol";

import { LibStructStorage as StructStorage } from "./../libraries/LibStructStorage.sol";
import { LibMarketplaceStorage as Storage } from "./../libraries/LibMarketplaceStorage.sol";

contract MarketplaceAdminFacet is IMarketplaceAdmin, FacetInitializable {
    using EnumerableSet for EnumerableSet.AddressSet;

    function splitsNonces(uint nonce) external view returns (bool) {
        Storage.MarketplaceStorage storage data = Storage.getStorage();
        return data.splitsNonces[nonce];
    }

    function sellNonces(uint nonce) external view returns (bool) {
        Storage.MarketplaceStorage storage data = Storage.getStorage();
        return data.splitsNonces[nonce];
    }

    function externalIds(uint externalId) external view returns (bool) {
        Storage.MarketplaceStorage storage data = Storage.getStorage();
        return data.externalIds[externalId];
    }

    function acceptedTokens() external view returns (address[] memory) {
        Storage.MarketplaceStorage storage data = Storage.getStorage();
        return data.acceptedTokens.values();
    }

    function addAcceptedToken(address token) external only(StructStorage.OPERATOR_ROLE) {
        Storage.MarketplaceStorage storage data = Storage.getStorage();
        data.acceptedTokens.add(token);
    }

    function removeAcceptedToken(address token) external only(StructStorage.OPERATOR_ROLE) {
        Storage.MarketplaceStorage storage data = Storage.getStorage();
        data.acceptedTokens.remove(token);
    }

    function setBaseUtilityUri(string calldata _baseUtilityUri) external only(StructStorage.OPERATOR_ROLE) {
        Storage.MarketplaceStorage storage data = Storage.getStorage();
        data.baseUtilityUri = _baseUtilityUri;
    }

    function editionsMinted(uint256 dropId) external view returns (uint256) {
        Storage.MarketplaceStorage storage data = Storage.getStorage();
        return data.editionsMinted[dropId];
    }

    function setDummyImplementation(address _implementation) external only(StructStorage.OPERATOR_ROLE) {
        Storage.MarketplaceStorage storage data = Storage.getStorage();
        data.dummyImplementation = _implementation;
    }

    function implementation() external view returns (address) {
        Storage.MarketplaceStorage storage data = Storage.getStorage();
        return data.dummyImplementation;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IAccessControl {
    function initializeAccessControl(address fundsAdmin) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    function setDiamondOwner(address newOwner) external;

    function getDiamondOwner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { LibStructStorage as StructStorage } from "../libraries/LibStructStorage.sol";

interface IMarketplaceAdmin {
    function splitsNonces(uint256 nonce) external view returns (bool);

    function sellNonces(uint256 nonce) external view returns (bool);

    function externalIds(uint256 externalId) external view returns (bool);

    function acceptedTokens() external view returns (address[] memory);

    function addAcceptedToken(address token) external;

    function removeAcceptedToken(address token) external;

    function setBaseUtilityUri(string calldata _baseUtilityUri) external;

    function editionsMinted(uint256 tokenId) external view returns (uint256);

    function setDummyImplementation(address _implementation) external;

    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "openzeppelin4/utils/structs/EnumerableSet.sol";
import "./../libraries/LibStructStorage.sol";

library LibMarketplaceStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    bytes32 public constant MARKETPLACE_STORAGE_SLOT = keccak256("KTHD.MARKETPLACE.STORAGE");

    struct MarketplaceStorage {
        LibStructStorage.InitFlag inited;
        // Mapping used to ensure that a payments payload is used only once
        mapping(uint256 => bool) splitsNonces;
        // Mapping used to ensure that a sell payload is used only once
        mapping(uint256 => bool) sellNonces;
        // Backend number used for processing logs efficiently
        mapping(uint256 => bool) externalIds;
        // Mapping used for limiting the edition number for a drop (dropId => number of editions minted
        mapping(uint256 => uint) editionsMinted;
        // Set used for accepted payment tokens
        EnumerableSet.AddressSet acceptedTokens;
        // String used for computing utility URI for the NFTs with utility associated
        string baseUtilityUri;
        // Address used for dummy implementation used for Etherscan visibility of the Diamond
        address dummyImplementation;
    }

    function getStorage() external pure returns (MarketplaceStorage storage storageStruct) {
        bytes32 position = MARKETPLACE_STORAGE_SLOT;
        assembly {
            storageStruct.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library LibStructStorage {
    //encoded roles
    bytes32 internal constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant FUNDS_ADMIN_ROLE = keccak256("FUNDS_ADMIN_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    //numeric constants
    uint256 internal constant MAX_CALLDATA_PROOF_LENGTH = 10;

    //general
    error INVALID_SIGNATURE(); //0xa3402a38
    error EXTERNAL_ID_USED(uint256 externalId); //0xcf1823bf
    error PAYMENT_TOKEN_NOT_ACCEPTED(address tokenAddress); //0xb31d0d90

    //merkle proof
    error MERKLE_PROOF_TOO_LARGE(uint256 sellNonce, uint256 length); //0xc4ebf85a
    error MERKLE_PROOF_INVALID(uint256 sellNonce); //0x2e218f81
    error INVALID_PROOF_HEIGHT(uint256 height); //0x56e0614d

    //primary market
    error EDITION_LIMIT(uint256 dropId); //0x452a12bb
    error MINTS_SIGNATURE(bytes signature); //0x670079be

    //funds facet
    error FA_NATIVE_TRANSFER(); //0xe9dd4fbc
    error FA_DISTRIBUTOR_CALLER_TRANSFER(); //0x81522ab7

    //splits
    error SPLITS_EXPIRED(uint256 splitsNonce); //0x2eed249c
    error SPLITS_NONCE_INVALID(uint256 splitsNonce); //0x4cb00050
    error SPLITS_SIGNATURE(uint256 splitsNonce); //0xe9a2746d

    //sell and delist
    error SELL_NONCE_INVALID(uint256 sellNonce); //0x4d7b9199
    error SELL_DATA_EXPIRED(uint256 sellNonce); //0x209878c5
    error SELL_SIGNATURE(uint256 sellNonce); //0x5397bc4f
    error SELL_NONCE_ALREADY_CANCELED(uint256 sellNonce); //0x69df89fa
    error CALLER_NOT_OWNER_OR_SELLER(uint256 sellNonce); //0xe1efaf1e

    //role
    error MISSING_ROLE(bytes32 role); //0x6a9d0f78

    bytes4 internal constant IERC721_INTERFACE = 0x80ac58cd;

    enum MerkleNodePosition {
        Left,
        Right
    }

    struct MerkleNode {
        bytes32 value;
        MerkleNodePosition position;
    }

    struct MerkleTree {
        bytes32 root;
        MerkleNode[] proof;
    }

    struct SellData {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 sellNonce;
        uint256 expirationDate;
    }

    struct SellDTO {
        SellData[] sells;
        bytes[] sellerSignatures;
        MerkleTree[] merkleTrees;
    }

    struct Payment {
        uint256 amount;
        address recipient;
    }

    struct Splits {
        Payment[] payments;
        uint256 actionExpiration;
        address token;
        uint256 nonce;
        bytes signature;
    }

    struct DropData {
        uint dropId;
        uint maxEditions;
        uint mintEditions;
        uint16 royaltiesPercent;
        address creatorAddress;
        string tokenUri;
        string[] utilityIds;
    }

    struct MintData {
        address nftAddress;
        DropData[] drops;
    }

    /*
        @dev: DO NOT modify struct; doing so will break the diamond storage layout
    */
    struct InitFlag {
        bool inited;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

abstract contract ContextMixin {
    function _msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./../libraries/LibStructStorage.sol";
import "./../utils/ContextMixin.sol";
import "./../interfaces/IAccessControl.sol";

abstract contract FacetInitializable is ContextMixin {
    modifier initializer(LibStructStorage.InitFlag storage flag) {
        require(!flag.inited, "already inited");
        _;
        flag.inited = true;
    }

    modifier only(bytes32 role) {
        if (!IAccessControl(address(this)).hasRole(role, msg.sender)) {
            revert LibStructStorage.MISSING_ROLE(role);
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}