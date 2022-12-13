// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IRoyaltyFeeRegistry} from "../interfaces/IRoyaltyFeeRegistry.sol";
import {IOwnable} from "../interfaces/IOwnable.sol";

/**
 * @title slabs exchange RoyaltyFeeRegistry
 * @notice It is a royalty fee registry for the slabs exchange.
 */
contract RoyaltyFeeRegistry is IRoyaltyFeeRegistry, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public maxNumberOfReceivers;
    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    // ERC2981 interfaceID
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    struct RoyaltyInfo {
        uint256 totalFee;
        EnumerableSet.AddressSet receiver;
        mapping(address => uint256) fee;
    }

    struct FeeInfo {
        address defaultReceiver;
        uint256 defaultFee;
        mapping(uint256 => RoyaltyInfo) tokenIdToRoyaltyInfo;
    }

    // Limit (if enforced for fee royalty in percentage (10,000 = 100%)
    uint256 public royaltyFeeLimitForERC721;
    uint256 public royaltyFeeLimitForERC1155;

    mapping(address => FeeInfo) private _royaltyFeeInfoCollection;

    event NewRoyaltyFeeLimitForERC1155(uint256 royaltyFeeLimit);
    event NewRoyaltyFeeLimitForERC721(uint256 royaltyFeeLimit);
    event UpdateRoyaltyReceiverLimit(uint256 newMaxNumberOfReceivers);
    event RoyaltyFeeUpdate(
        address indexed collection,
        address indexed receiver,
        uint256 fee
    );
    event RoyaltyFeeUpdateOfNFT(
        address indexed collection,
        uint256 indexed tokenId,
        address receiver,
        uint256 fee
    );
    event AddRoyaltyReceiver(
        address collection,
        uint256 tokenId,
        address receiver,
        uint256 fee
    );
    event RemoveRoyaltyReceiver(
        address collection,
        uint256 tokenId,
        address receiver
    );
    event RemoveRoyaltyInfoForNFT(address collection, uint256 tokenId);

    /**
     * @notice Constructor
     */
    constructor() {
        royaltyFeeLimitForERC721 = 1000;
        royaltyFeeLimitForERC1155 = 500;
        maxNumberOfReceivers = 10;
    }

    /**
     * @notice Update royalty info for ERC721 collection
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyFeeLimitForERC721(uint256 _royaltyFeeLimit)
        external
        override
        onlyOwner
    {
        require(_royaltyFeeLimit <= 5000, "Owner: Royalty fee limit too high");
        require(royaltyFeeLimitForERC721 != _royaltyFeeLimit, "already there");
        royaltyFeeLimitForERC721 = _royaltyFeeLimit;
        emit NewRoyaltyFeeLimitForERC721(_royaltyFeeLimit);
    }

    /**
     * @notice Update royalty info for ERC1155 collection
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyFeeLimitForERC1155(uint256 _royaltyFeeLimit)
        external
        override
        onlyOwner
    {
        require(_royaltyFeeLimit <= 5000, "Owner: Royalty fee limit too high");
        require(royaltyFeeLimitForERC1155 != _royaltyFeeLimit, "already there");
        royaltyFeeLimitForERC1155 = _royaltyFeeLimit;
        emit NewRoyaltyFeeLimitForERC1155(_royaltyFeeLimit);
    }

    /**
     * @notice Update royalty max royalty reveivers addresses
     * @param newMaxNumberOfReceivers new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyReceiverLimit(uint256 newMaxNumberOfReceivers)
        external
        override
        onlyOwner
    {
        require(
            newMaxNumberOfReceivers <= 20,
            "Owner: newMaxNumberOfReceivers is high"
        );
        require(
            maxNumberOfReceivers != newMaxNumberOfReceivers,
            "already there"
        );
        maxNumberOfReceivers = newMaxNumberOfReceivers;
        emit UpdateRoyaltyReceiverLimit(newMaxNumberOfReceivers);
    }

    /**
     * @notice Update royalty info for collection if admin
     * @dev Only to be called if there is no setter address
     * @param collection address of the NFT contract
     * @param defaultReceiver receiver for the royalty fee
     * @param defaultFee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollectionIfAdmin(
        address collection,
        address defaultReceiver,
        uint256 defaultFee
    ) external {
        require(
            !IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981),
            "Admin: Must not be ERC2981"
        );
        require(
            _msgSender() == IOwnable(collection).admin(),
            "Admin: Not the admin"
        );
        _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(
            collection,
            defaultReceiver,
            defaultFee
        );
    }

    /**
     * @notice Update royalty info for collection if owner
     * @dev Only to be called if there is no setter address
     * @param collection address of the NFT contract
     * @param defaultReceiver receiver for the royalty fee
     * @param defaultFee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollectionIfOwner(
        address collection,
        address defaultReceiver,
        uint256 defaultFee
    ) external {
        require(
            !IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981),
            "Owner: Must not be ERC2981"
        );
        require(
            _msgSender() == IOwnable(collection).owner(),
            "Owner: Not the owner"
        );
        _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(
            collection,
            defaultReceiver,
            defaultFee
        );
    }

    /**
     * @notice Update royalty info for collection NFT inital owner
     * @dev Only to be called if there is no inital owner
     * @param collection address of the NFT contract
     * @param tokenId NFT token Id
     * @param receivers array receiver for the royalty fee
     * @param fees array fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForNFTInitalOwner(
        address collection,
        uint256 tokenId,
        address[] memory receivers,
        uint256[] memory fees
    ) external {
        require(
            _msgSender() == IOwnable(collection).initialOwner(tokenId),
            "caller is not inital owner"
        );
        _updateRoyaltyInfoForCollection(collection, tokenId, receivers, fees);
    }

    /**
     * @notice Update royalty info for collection through collection
     * @dev Only to be called if there is no inital owner
     * @param collection address of the NFT contract
     * @param tokenId NFT token Id
     * @param receivers array receiver for the royalty fee
     * @param fees array fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForNFT(
        address collection,
        uint256 tokenId,
        address[] memory receivers,
        uint256[] memory fees
    ) external override {
        require(_msgSender() == collection, "caller is not inital owner");
        _updateRoyaltyInfoForCollection(collection, tokenId, receivers, fees);
    }

    /**
     * @notice remove royalty info for collection through collection
     * @dev Only to be called if there is no inital owner
     * @param collection address of the NFT contract
     * @param tokenId NFT token Id
     */
    function removeRoyaltyInfoForNFT(address collection, uint256 tokenId)
        external
        override
    {
        require(_msgSender() == collection, "caller is not inital owner");
        require(
            (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721) ||
                IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)),
            "Setter: Not ERC721/ERC1155"
        );
        address[] memory _receivers = _royaltyFeeInfoCollection[collection]
            .tokenIdToRoyaltyInfo[tokenId]
            .receiver
            .values();
        for (uint256 i = 0; i < _receivers.length; i++) {
            _royaltyFeeInfoCollection[collection]
                .tokenIdToRoyaltyInfo[tokenId]
                .receiver
                .remove(_receivers[i]);
        }
        delete _royaltyFeeInfoCollection[collection].tokenIdToRoyaltyInfo[
            tokenId
        ];
        emit RemoveRoyaltyInfoForNFT(collection, tokenId);
    }

    /**
     * @notice add royalty info for collection token id
     * @dev Only to be called if there _msgSender() is the setter
     * @param collection address of the NFT contract
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function addRoyaltyReceiver(
        address collection,
        uint256 tokenId,
        address receiver,
        uint256 fee
    ) external {
        FeeInfo storage feeInfo = _royaltyFeeInfoCollection[collection];
        require(
            _msgSender() == IOwnable(collection).initialOwner(tokenId),
            "caller is not inital owner"
        );
        require(
            isValidRoyalityLimit(
                collection,
                feeInfo.tokenIdToRoyaltyInfo[tokenId].totalFee + fee
            ),
            "Registry: Royalty fee too high"
        );
        require(
            (feeInfo.tokenIdToRoyaltyInfo[tokenId].receiver.length()) <
                maxNumberOfReceivers,
            "Registry: royality reveiver limit full"
        );
        require(
            !feeInfo.tokenIdToRoyaltyInfo[tokenId].receiver.contains(receiver),
            "Registry: receivers is already in the list"
        );
        feeInfo.tokenIdToRoyaltyInfo[tokenId].receiver.add(receiver);
        feeInfo.tokenIdToRoyaltyInfo[tokenId].fee[receiver] = fee;
        feeInfo.tokenIdToRoyaltyInfo[tokenId].totalFee += fee;
        emit AddRoyaltyReceiver(collection, tokenId, receiver, fee);
    }

    /**
     * @notice remove royalty info for collection token ID
     * @dev Only to be called if there _msgSender() is the setter
     * @param collection address of the NFT contract
     * @param tokenId address that sets the receiver
     * @param receiver receiver for the royalty fee
     */
    function removeRoyaltyReceiver(
        address collection,
        uint256 tokenId,
        address receiver
    ) external {
        FeeInfo storage feeInfo = _royaltyFeeInfoCollection[collection];
        require(
            _msgSender() == IOwnable(collection).initialOwner(tokenId),
            "caller is not inital owner"
        );
        require(
            feeInfo.tokenIdToRoyaltyInfo[tokenId].receiver.contains(receiver),
            "Registry: is not in list"
        );
        feeInfo.tokenIdToRoyaltyInfo[tokenId].receiver.remove(receiver);
        feeInfo.tokenIdToRoyaltyInfo[tokenId].totalFee -= feeInfo
            .tokenIdToRoyaltyInfo[tokenId]
            .fee[receiver];
        feeInfo.tokenIdToRoyaltyInfo[tokenId].fee[receiver] = 0;
        // console.log(collection);
        // console.log(tokenId);
        // console.log(receiver);
        emit RemoveRoyaltyReceiver(collection, tokenId, receiver);
    }

    /**
     * @notice Update information and perform checks before updating royalty fee registry
     * @param collection address of the NFT contract
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(
        address collection,
        address receiver,
        uint256 fee
    ) internal {
        require(
            (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721) ||
                IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)),
            "Setter: Not ERC721/ERC1155"
        );
        updateRoyaltyInfoForCollection(collection, receiver, fee);
    }

    /**
     * @notice Update information and perform checks before updating royalty fee registry
     * @param collection address of the NFT contract
     * @param tokenId address of the NFT contract
     * @param receivers receiver for the royalty fee
     * @param fees fee (500 = 5%, 1,000 = 10%)
     */
    function _updateRoyaltyInfoForCollection(
        address collection,
        uint256 tokenId,
        address[] memory receivers,
        uint256[] memory fees
    ) internal {
        require(
            (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721) ||
                IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)),
            "Setter: Not ERC721/ERC1155"
        );
        updateRoyaltyInfoForCollection(collection, tokenId, receivers, fees);
    }

    /**
     * @notice Update royalty info for collection
     * @param collection address of the NFT contract
     * @param defaultReceiver receiver for the royalty fee
     * @param defaultFee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollection(
        address collection,
        address defaultReceiver,
        uint256 defaultFee
    ) internal {
        require(
            isValidRoyalityLimit(collection, defaultFee),
            "Registry: Royalty fee too high"
        );
        FeeInfo storage feeInfo = _royaltyFeeInfoCollection[collection];
        feeInfo.defaultReceiver = defaultReceiver;
        feeInfo.defaultFee = defaultFee;
        emit RoyaltyFeeUpdate(collection, defaultReceiver, defaultFee);
    }

    /**
     * @notice Update royalty info for collection
     * @param collection address of the NFT contract
     * @param receivers receiver for the royalty fee
     * @param fees fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollection(
        address collection,
        uint256 tokenId,
        address[] memory receivers,
        uint256[] memory fees
    ) internal {
        require(
            receivers.length == fees.length,
            "receivers.length must be equal to fees.length"
        );
        FeeInfo storage feeInfo = _royaltyFeeInfoCollection[collection];
        require(
            (feeInfo.tokenIdToRoyaltyInfo[tokenId].receiver.length() +
                receivers.length) <= maxNumberOfReceivers,
            "Registry: royality reveiver limit full"
        );
        for (uint256 i = 0; i < receivers.length; i++) {
            require(
                isValidRoyalityLimit(
                    collection,
                    feeInfo.tokenIdToRoyaltyInfo[tokenId].totalFee + fees[i]
                ),
                "Registry: Royalty fee too high"
            );
            require(
                !feeInfo.tokenIdToRoyaltyInfo[tokenId].receiver.contains(
                    receivers[i]
                ),
                "Registry: receivers is already in the list"
            );
            feeInfo.tokenIdToRoyaltyInfo[tokenId].totalFee += fees[i];
            feeInfo.tokenIdToRoyaltyInfo[tokenId].receiver.add(receivers[i]);
            feeInfo.tokenIdToRoyaltyInfo[tokenId].fee[receivers[i]] = fees[i];
            emit RoyaltyFeeUpdateOfNFT(
                collection,
                tokenId,
                receivers[i],
                fees[i]
            );
        }
    }

    function isValidRoyalityLimit(address collection, uint256 limit)
        internal
        view
        returns (bool)
    {
        if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721)) {
            return (royaltyFeeLimitForERC721 >= limit);
        }
        if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)) {
            return (royaltyFeeLimitForERC1155 >= limit);
        }
        return false;
    }

    /**
     * @notice View royalty info for a collection address
     * @param collection collection address
     */
    function royaltyFeeInfoCollection(address collection)
        public
        view
        override
        returns (address, uint256)
    {
        return (
            _royaltyFeeInfoCollection[collection].defaultReceiver,
            _royaltyFeeInfoCollection[collection].defaultFee
        );
    }

    /**
     * @notice View royalty info for a collection address
     * @param collection collection address
     */
    function royaltyFeeInfoCollection(address collection, uint256 tokenId)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        FeeInfo storage feeInfo = _royaltyFeeInfoCollection[collection];
        uint256[] memory _fees = new uint256[](
            feeInfo.tokenIdToRoyaltyInfo[tokenId].receiver.length()
        );
        for (
            uint256 i = 0;
            i < feeInfo.tokenIdToRoyaltyInfo[tokenId].receiver.length();
            i++
        ) {
            address _reciver = feeInfo
                .tokenIdToRoyaltyInfo[tokenId]
                .receiver
                .at(i);
            _fees[i] = feeInfo.tokenIdToRoyaltyInfo[tokenId].fee[_reciver];
        }
        return (feeInfo.tokenIdToRoyaltyInfo[tokenId].receiver.values(), _fees);
    }

    /**
     * @notice Check royalty info for collection
     * @param collection collection address
     * @param tokenId collection tokenId
     * @return (whether there is a setter (address(0 if not)),
     * Position
     * 0: Royalty setter is set in the registry
     * 1: intial onwer of the NFT
     * 2: ERC2981 and no setter
     * 3: setter can be set using owner()
     * 4: setter can be set using admin()
     * 5: setter cannot be set, nor support for ERC2981
     */
    function checkForCollectionSetter(address collection, uint256 tokenId)
        external
        view
        returns (address, uint8)
    {
        try IOwnable(collection).initialOwner(tokenId) returns (
            address setter
        ) {
            return (setter, 1);
        } catch {}
        try
            IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981)
        returns (bool interfaceSupport) {
            if (interfaceSupport) {
                return (address(0), 2);
            }
        } catch {}
        try IOwnable(collection).owner() returns (address setter) {
            return (setter, 3);
        } catch {
            try IOwnable(collection).admin() returns (address setter) {
                return (setter, 4);
            } catch {
                return (address(0), 4);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
    function transferOwnership(address newOwner) external;

    function owner() external view returns (address);

    function admin() external view returns (address);

    function initialOwner(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltyFeeRegistry {
    function updateRoyaltyFeeLimitForERC721(uint256 _royaltyFeeLimit) external;
    function updateRoyaltyFeeLimitForERC1155(uint256 _royaltyFeeLimit) external;

    function updateRoyaltyReceiverLimit(uint256 newMaxNumberOfReceivers)
        external;

    function updateRoyaltyInfoForNFT(
        address collection,
        uint256 tokenId,
        address[] memory receivers,
        uint256[] memory fees
    ) external;

    function royaltyFeeInfoCollection(address collection)
        external
        view
        returns (address, uint256);

    function royaltyFeeInfoCollection(address collection, uint256 tokenId)
        external
        view
        returns (address[] memory, uint256[] memory);

    function removeRoyaltyInfoForNFT(address collection, uint256 tokenId)
        external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}