// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * ```solidity
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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../../libraries/DataTypes.sol";


interface IAccount {
    function version() external pure returns (string memory);

    function addCommunityUser(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function removeCommunityUser(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function addModerator(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function removeModerator(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function addCreatedPostIdForUser(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function addCreatedCommentIdForUser(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function getCommunityUsersCounts(address _communityId) external view returns(
        uint256 normalUsers,
        uint256 bannedUsers,
        uint256 moderatorsUsers
    );

    function getCommunityUsers(address _communityId) external view returns(
        address[] memory normalUsers,
        address[] memory bannedUsers,
        address[] memory moderators
    );

    function isCommunityUser(address _communityId, address _user) external view returns(bool);

    function isBannedUser(address _communityId, address _user) external view returns(bool);

    function isModerator(address _communityId, address _user) external view returns(bool);

    function getCommunitiesByUser(address _user) external view returns(
        address[] memory _communities
    );

    function getPostIdsByUserAndCommunity(address _communityId, address _user) external view returns(
        uint256[] memory _withCommentPostIds,
        uint256[] memory _createdPostIds
    );

    function getCommentIdsByUserAndPost(
        address _communityId,
        address _user,
        uint256 _postId
    ) external view returns(uint256[] memory _commentIds);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../../libraries/DataTypes.sol";


interface ICommentData {

    function version() external pure returns (string memory);

    function ipfsHashOf(uint256 _postId, uint256 _commentId) external view returns (string memory);

    function writeComment(
        DataTypes.GeneralVars calldata vars
    ) external returns(uint256);

    function burnComment(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function setVisibility(
        DataTypes.SimpleVars calldata vars
    ) external returns(bool);

    function setGasCompensation(
        DataTypes.GasCompensationComment calldata vars
    ) external returns(
        uint256 gasConsumption,
        address creator,
        address owner
    );

    function setGasConsumption(
        DataTypes.MinSimpleVars calldata vars
    ) external returns(bool);

    function readComment(
        DataTypes.MinSimpleVars calldata vars
    ) external view returns(
        DataTypes.CommentInfo memory outData
    );

    function getCommentCount(uint256 _postId) external view returns(uint256);

    function getUpDownForComment(uint256 _postId, uint256 _commentId) external view returns(bool, bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../libraries/DataTypes.sol";


interface ICommunityBlank {

    function creator() external view returns (address);

    function name() external view returns (string memory);

    function creatingTime() external view returns (uint256);

    function authorGasCompensationPercent() external view returns (uint256);

    function ownerGasCompensationPercent() external view returns (uint256);

    function linkPlugin(bytes32 _pluginName, uint256 _version) external;

    function unLinkPlugin(bytes32 _pluginName, uint256 _version) external;

    function isLinkedPlugin(bytes32 _pluginName, uint256 _version) external view returns (bool);

    function linkRule(bytes32 _ruleGroupName, uint256 _version, bytes32 _ruleName) external;

    function unLinkRule(bytes32 _ruleGroupName, uint256 _version, bytes32 _ruleName) external;

    function isLinkedRule(bytes32 _ruleGroupName, uint256 _version, bytes32 _ruleName) external view returns (bool);

    function claimERC20Token(IERC20 _token, address _receiver, uint256 _amount) external;

    function setGasCompensationPercent(uint256 _authorPercent) external;

    function setPrice(DataTypes.PaymentType _paymentType, uint256 _newPrice) external;

    function getPrice(DataTypes.PaymentType _paymentType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../../libraries/DataTypes.sol";


interface ISinglePostData {

    function version() external pure returns (string memory);

    function isUserVerification() external view returns (bool);

    function ipfsHashOf(uint256 _tokenId) external view returns (string memory);

    function writePost(
        DataTypes.GeneralVars calldata vars
    ) external returns(uint256);

    function burnPost(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function readPost(
        DataTypes.MinSimpleVars calldata vars
    ) external view returns(
        DataTypes.SinglePostInfo memory outData
    );

    function setVisibility(
        DataTypes.SimpleVars calldata vars
    ) external returns(bool);

    function setUserVerification(
        DataTypes.SimpleVars calldata vars
    ) external returns(bool);

    function updatePostWhenNewComment(
        DataTypes.GeneralVars calldata vars
    ) external returns(bool);

    function isEncrypted(uint256 _postId) external view returns(bool);

    function isCreator(uint256 _postId, address _user) external view returns(bool);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";


library DataTypes {

    struct PostInfo {
        address creator;
        address currentOwner;
        address communityId;
        address repostFromCommunity;
        uint256 upCount;
        uint256 downCount;
        uint256 commentCount;
        uint256 encodingType;
        uint256 timestamp;
        uint256 gasConsumption;
        bool isView;
        bool isEncrypted;
        bool isGasCompensation;
        string ipfsHash;
        string category;
        string[] tags;
    }

    struct SinglePostInfo {
        address creator;
        address currentOwner;
        string ipfsHash;
        uint256 upCount;
        uint256 downCount;
        uint256 commentCount;
        uint256 encodingType;
        uint256 timestamp;
        uint256 payAmount;
        uint256 paymentType;
        uint256 minimalPeriod;
        bool isView;
        bool isEncrypted;
        bool isSensitive;
        bool isCommented;
    }

    struct CommentInfo {
        address creator;
        address owner;
        address communityId;
        uint256 timestamp;
        uint256 gasConsumption;
        bool up;
        bool down;
        bool isView;
        bool isEncrypted;
        bool isGasCompensation;
        string ipfsHash;
    }

    struct CommunityInfo {
        string name;
        address creator;
        address owner;
        uint256 creatingTime;
        uint256[] postIds;
        address[] normalUsers;
        address[] bannedUsers;
        address[] moderators;
    }

    enum UserRatesType {
        RESERVE, FOR_POST, FOR_COMMENT, FOR_UP, FOR_DOWN,
        FOR_DEAL_GUARANTOR, FOR_DEAL_SELLER, FOR_DEAL_BUYER
    }

    enum PaymentType {
        RESERVE, FOR_COMMUNITY_JOIN, FOR_PERIODIC_ACCESS, FOR_ADS, FOR_MAKE_CONTENT,
        FOR_SINGLE_POST_ONE_TIME, FOR_SINGLE_POST_DAYS, FOR_SINGLE_POST_WEEKS, FOR_SINGLE_POST_MONTHS
    }

    struct MinSimpleVars {
        bytes32 pluginName;
        uint256 version;
        bytes data;
    }

    struct SimpleVars {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        bytes data;
    }

    struct GeneralVars {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        address user;
        bytes data;
    }

    struct SoulBoundMint {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        address user;
        uint256 id;
        uint256 amount;
    }

    struct SoulBoundBatchMint {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        address user;
        uint256[] ids;
        uint256[] amounts;
    }

    struct UserRateCount {
        uint256 commentCount;
        uint256 postCount;
        uint256 upCount;
        uint256 downCount;
    }

    struct GasCompensationComment {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        uint256 postId;
        uint256 commentId;
    }

    struct GasCompensationBank {
        bytes32 executedId;
        bytes32 pluginName;
        uint256 version;
        address user;
        uint256 gas;
    }

    struct PaymentInfo {
        uint256 startTime;
        uint256 endTime;
        address communityId;
        address owner;
        DataTypes.PaymentType paymentType;
    }

    struct DealMessage {
        string message;
        address sender;
        uint256 writeTime;
    }

    struct SafeDeal {
        string description;
        address seller;
        address buyer;
        address guarantor;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        bool startSellerApprove;
        bool startBuyerApprove;
        bool endSellerApprove;
        bool endBuyerApprove;
        bool isIssue;
        bool isFinished;
        DealMessage[] messages;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../registry/interfaces/IRegistry.sol";
import "../account/interfaces/IAccount.sol";
import "../community/interfaces/ICommentData.sol";
import "./DataTypes.sol";
import "../tokens/subscription/interfaces/ISubscription.sol";

library UserLib {

    function getUserRate(
        IRegistry registry,
        address _user,
        address _communityId
    ) internal view returns(DataTypes.UserRateCount memory _counts) {
        (uint256[] memory withCommentPostIds, uint256[] memory createdPostIds) =
        IAccount(registry.account()).getPostIdsByUserAndCommunity(_communityId, _user);

        _counts.postCount += createdPostIds.length;
        for(uint256 j=0; j < withCommentPostIds.length; j++) {
            uint256 postId = withCommentPostIds[j];
            uint256[] memory commentIds = IAccount(registry.account()).getCommentIdsByUserAndPost(_communityId, _user, postId);
            _counts.commentCount += commentIds.length;
            for(uint256 k=0; k < commentIds.length; k++) {
                uint256 commentId = commentIds[k];
                (bool isUp, bool isDown) = ICommentData(registry.commentData()).getUpDownForComment(
                    postId,
                    commentId
                );
                if (isUp) {
                    _counts.upCount++;
                }
                if (isDown) {
                    _counts.downCount++;
                }
            }
        }
    }

    function checkPayment(
        IRegistry registry,
        address _user,
        uint256 _paymentType,
        uint256 _subscriptionId
    ) internal view {
        DataTypes.PaymentInfo memory info = ISubscription(registry.subscription()).getPaymentInfo(_subscriptionId);

        require(_user == info.owner, "UserLib: this user did not pay");
        require(DataTypes.PaymentType(_paymentType) == info.paymentType, "UserLib: wrong payment type");
        require(isTruePaymentType(DataTypes.PaymentType(_paymentType)), "UserLib: wrong payment type");
        require(isCorrectTime(info), "UserLib: wrong payment time");
    }

    function hasAnyPayment(
        IRegistry _registry,
        address _user,
        uint256 _paymentType
    ) internal view returns(bool) {
        if (_paymentType == 0) {
            return true;
        }

        uint256[] memory tokenIds = ISubscription(_registry.subscription()).tokensOfOwner(_user);
        uint256 count = tokenIds.length;
        if (count == 0) {
            return false;
        }
        for(uint256 i = 0; i < count; i++) {
            if(hasPayment(_registry, _user, _paymentType, tokenIds[i])) {
                return true;
            }
        }
        return false;
    }

    function hasPayment(
        IRegistry _registry,
        address _user,
        uint256 _paymentType,
        uint256 _subscriptionId
    ) internal view returns(bool) {
        DataTypes.PaymentInfo memory info = ISubscription(_registry.subscription()).getPaymentInfo(_subscriptionId);

        if (_user != info.owner) {
            return false;
        }
        if (!isTruePaymentType(info.paymentType)) {
            return false;
        }
        if (DataTypes.PaymentType(_paymentType) != info.paymentType) {
            return false;
        }
        if (!isCorrectTime(info)) {
            return false;
        }

        return true;
    }

    function isTruePaymentType(DataTypes.PaymentType _type) private pure returns(bool isCorrectType) {
        isCorrectType =
        _type == DataTypes.PaymentType.FOR_SINGLE_POST_ONE_TIME
        || _type ==  DataTypes.PaymentType.FOR_SINGLE_POST_DAYS
        || _type ==  DataTypes.PaymentType.FOR_SINGLE_POST_WEEKS
        || _type ==  DataTypes.PaymentType.FOR_SINGLE_POST_MONTHS;
    }

    function isCorrectTime(DataTypes.PaymentInfo memory _info) private view returns(bool) {
        uint256 currentTime = block.timestamp;
        return _info.startTime <= currentTime && currentTime <= _info.endTime;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Context.sol";

import "../registry/interfaces/IRegistry.sol";
import "../community/interfaces/ICommunityBlank.sol";


abstract contract BasePlugin is Context {

    uint256 internal PLUGIN_VERSION;
    bytes32 public PLUGIN_NAME;

    IRegistry public registry;

    modifier onlyExecutor() {
        require(registry.executor() == _msgSender(), "BasePlugin: caller is not the executor");
        _;
    }

    function version() external view returns (uint256) {
        return PLUGIN_VERSION;
    }

    function checkPlugin(uint256 _version, address _communityId) internal virtual view {
        require(_version == PLUGIN_VERSION, "BasePlugin: wrong version");
        (bool enable, address pluginContract) = registry.getPlugin(PLUGIN_NAME, PLUGIN_VERSION);
        require(enable, "BasePlugin: wrong enable plugin");
        require(pluginContract == address(this), "BaseWritePlugin: wrong plugin contract");

        if (_communityId != address(0)) {
            bool isLinked = ICommunityBlank(_communityId).isLinkedPlugin(PLUGIN_NAME, PLUGIN_VERSION);
            require(isLinked, "BasePlugin: plugin is not linked for the community");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title Contract of Page.PluginsList
/// @notice This contract contains a list of plugin names.
/// @dev Constants from this list are used to access plugins settings.
library PluginsList {

    bytes32 public constant COMMUNITY_CREATE = keccak256(abi.encode("COMMUNITY_CREATE"));
    bytes32 public constant COMMUNITY_JOIN = keccak256(abi.encode("COMMUNITY_JOIN"));
    bytes32 public constant COMMUNITY_QUIT = keccak256(abi.encode("COMMUNITY_QUIT"));
    bytes32 public constant COMMUNITY_INFO = keccak256(abi.encode("COMMUNITY_INFO"));
    bytes32 public constant COMMUNITY_PROFIT = keccak256(abi.encode("COMMUNITY_PROFIT"));

    bytes32 public constant USER_INFO_ONE_COMMUNITY = keccak256(abi.encode("USER_INFO_ONE_COMMUNITY"));
    bytes32 public constant USER_INFO_ALL_COMMUNITIES = keccak256(abi.encode("USER_INFO_ALL_COMMUNITIES"));

    bytes32 public constant COMMUNITY_WRITE_POST = keccak256(abi.encode("COMMUNITY_WRITE_POST"));
    bytes32 public constant COMMUNITY_READ_POST = keccak256(abi.encode("COMMUNITY_READ_POST"));
    bytes32 public constant COMMUNITY_BURN_POST = keccak256(abi.encode("COMMUNITY_BURN_POST"));
    bytes32 public constant COMMUNITY_TRANSFER_POST = keccak256(abi.encode("COMMUNITY_TRANSFER_POST"));
    bytes32 public constant COMMUNITY_CHANGE_VISIBILITY_POST = keccak256(abi.encode("COMMUNITY_CHANGE_VISIBILITY_POST"));
    bytes32 public constant COMMUNITY_POST_GAS_COMPENSATION = keccak256(abi.encode("COMMUNITY_POST_GAS_COMPENSATION"));
    bytes32 public constant COMMUNITY_EDIT_MODERATORS = keccak256(abi.encode("COMMUNITY_EDIT_MODERATORS"));
    bytes32 public constant COMMUNITY_REPOST = keccak256(abi.encode("COMMUNITY_REPOST"));

    bytes32 public constant SINGLE_WRITE_POST = keccak256(abi.encode("SINGLE_WRITE_POST"));
    bytes32 public constant SINGLE_WRITE_COMMENT = keccak256(abi.encode("SINGLE_WRITE_COMMENT"));
    bytes32 public constant SINGLE_READ_POST = keccak256(abi.encode("SINGLE_READ_POST"));
    bytes32 public constant SINGLE_READ_ALL_COMMENT = keccak256(abi.encode("SINGLE_READ_ALL_COMMENT"));
    bytes32 public constant SINGLE_BURN_POST = keccak256(abi.encode("SINGLE_BURN_POST"));
    bytes32 public constant SINGLE_BURN_COMMENT = keccak256(abi.encode("SINGLE_BURN_COMMENT"));
    bytes32 public constant SINGLE_TRANSFER_POST = keccak256(abi.encode("SINGLE_TRANSFER_POST"));
    bytes32 public constant SINGLE_CHANGE_VISIBILITY_POST = keccak256(abi.encode("SINGLE_CHANGE_VISIBILITY_POST"));
    bytes32 public constant SINGLE_CHANGE_VERIFICATION = keccak256(abi.encode("SINGLE_CHANGE_VERIFICATION"));
    bytes32 public constant SINGLE_HAS_PAYMENT_FOR_ACCESS = keccak256(abi.encode("SINGLE_HAS_PAYMENT_FOR_ACCESS"));

    bytes32 public constant COMMUNITY_WRITE_COMMENT = keccak256(abi.encode("COMMUNITY_WRITE_COMMENT"));
    bytes32 public constant COMMUNITY_READ_COMMENT = keccak256(abi.encode("COMMUNITY_READ_COMMENT"));
    bytes32 public constant COMMUNITY_READ_ALL_COMMENT = keccak256(abi.encode("COMMUNITY_READ_ALL_COMMENT"));
    bytes32 public constant COMMUNITY_BURN_COMMENT = keccak256(abi.encode("COMMUNITY_BURN_COMMENT"));
    bytes32 public constant COMMUNITY_CHANGE_VISIBILITY_COMMENT = keccak256(abi.encode("COMMUNITY_CHANGE_VISIBILITY_COMMENT"));
    bytes32 public constant COMMUNITY_COMMENT_GAS_COMPENSATION = keccak256(abi.encode("COMMUNITY_COMMENT_GAS_COMPENSATION"));

    bytes32 public constant BANK_DEPOSIT = keccak256(abi.encode("BANK_DEPOSIT"));
    bytes32 public constant BANK_WITHDRAW = keccak256(abi.encode("BANK_WITHDRAW"));
    bytes32 public constant BANK_BALANCE_OF = keccak256(abi.encode("BANK_BALANCE_OF"));
    bytes32 public constant FAUCET_TEST_MINT = keccak256(abi.encode("FAUCET_TEST_MINT"));

    bytes32 public constant SOULBOUND_GENERATE = keccak256(abi.encode("SOULBOUND_GENERATE"));
    bytes32 public constant SOULBOUND_BALANCE_OF = keccak256(abi.encode("SOULBOUND_BALANCE_OF"));

    bytes32 public constant SUBSCRIPTION_BUY = keccak256(abi.encode("SUBSCRIPTION_BUY"));
    bytes32 public constant SUBSCRIPTION_BUY_FOR_SINGLE_POST = keccak256(abi.encode("SUBSCRIPTION_BUY_FOR_SINGLE_POST"));
    bytes32 public constant SUBSCRIPTION_INFO = keccak256(abi.encode("SUBSCRIPTION_INFO"));

    bytes32 public constant SAFE_DEAL_MAKE = keccak256(abi.encode("SAFE_DEAL_MAKE"));
    bytes32 public constant SAFE_DEAL_READ = keccak256(abi.encode("SAFE_DEAL_READ"));
    bytes32 public constant SAFE_DEAL_CANCEL = keccak256(abi.encode("SAFE_DEAL_CANCEL"));
    bytes32 public constant SAFE_DEAL_FINISH = keccak256(abi.encode("SAFE_DEAL_FINISH"));
    bytes32 public constant SAFE_DEAL_ADD_MESSAGE = keccak256(abi.encode("SAFE_DEAL_ADD_MESSAGE"));
    bytes32 public constant SAFE_DEAL_SET_ISSUE = keccak256(abi.encode("SAFE_DEAL_SET_ISSUE"));
    bytes32 public constant SAFE_DEAL_CLEAR_ISSUE = keccak256(abi.encode("SAFE_DEAL_CLEAR_ISSUE"));
    bytes32 public constant SAFE_DEAL_SET_APPROVE = keccak256(abi.encode("SAFE_DEAL_SET_APPROVE"));
    bytes32 public constant SAFE_DEAL_CHANGE_TIME = keccak256(abi.encode("SAFE_DEAL_CHANGE_TIME"));
    bytes32 public constant SAFE_DEAL_CHANGE_DESCRIPTION = keccak256(abi.encode("SAFE_DEAL_CHANGE_DESCRIPTION"));

    function version() external pure returns (string memory) {
        return "1";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../../community/interfaces/ISinglePostData.sol";
import "../../community/interfaces/ICommentData.sol";
import "../../registry/interfaces/IRegistry.sol";
import "../../tokens/nft/interfaces/INFT.sol";

import "../PluginsList.sol";
import "../../libraries/DataTypes.sol";
import "../../libraries/UserLib.sol";
import "../BasePlugin.sol";


contract Read is BasePlugin {

    using UserLib for IRegistry;

    constructor(address _registry) {
        PLUGIN_VERSION = 1;
        PLUGIN_NAME = PluginsList.SINGLE_READ_POST;
        registry = IRegistry(_registry);
    }

    function read(
        uint256 _postId
    ) external view returns(DataTypes.SinglePostInfo memory outData) {
        checkPlugin(PLUGIN_VERSION, address(0));

        DataTypes.MinSimpleVars memory vars;
        vars.pluginName = PLUGIN_NAME;
        vars.version = PLUGIN_VERSION;
        vars.data = abi.encode(_postId);

        DataTypes.SinglePostInfo memory postData = ISinglePostData(registry.singlePostData()).readPost(vars);
        postData.currentOwner = INFT(registry.nft()).ownerOf(_postId);
        postData.commentCount = ICommentData(registry.commentData()).getCommentCount(_postId);

        return postData;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IRegistry {

    function version() external pure returns (string memory);

    function bank() external view returns (address);

    function oracle() external view returns (address);

    function uniV3Pool() external view returns (address);

    function token() external view returns (address);

    function dao() external view returns (address);

    function treasury() external view returns (address);

    function executor() external view returns (address);

    function rule() external view returns (address);

    function communityData() external view returns (address);

    function postData() external view returns (address);

    function singlePostData() external view returns (address);

    function commentData() external view returns (address);

    function account() external view returns (address);

    function soulBound() external view returns (address);

    function subscription() external view returns (address);

    function nft() external view returns (address);

    function safeDeal() external view returns (address);

    function profitDistribution() external view returns (address);

    function superAdmin() external view returns (address);

    function pluginList() external view returns (address);

    function ruleList() external view returns (address);

    function setBank(address _contract) external;

    function setToken(address _contract) external;

    function setOracle(address _contract) external;

    function setUniV3Pool(address _contract) external;

    function setExecutor(address _executor) external;

    function setCommunityData(address _contract) external;

    function setPostData(address _contract) external;

    function setSinglePostData(address _contract) external;

    function setCommentData(address _contract) external;

    function setAccount(address _contract) external;

    function setSoulBound(address _contract) external;

    function setSubscription(address _contract) external;

    function setProfitDistribution(address _contract) external;

    function setRule(address _contract) external;

    function setNFT(address _contract) external;

    function setSafeDeal(address _contract) external;

    function setSuperAdmin(address _user) external;

    function setVotingContract(address _contract, bool _status) external;

    function setPluginList(address _contract) external;

    function setRuleList(address _contract) external;

    function setPlugin(
        bytes32 _pluginName,
        uint256 _version,
        address _pluginContract
    ) external;

    function changePluginStatus(
        bytes32 _pluginName,
        uint256 _version
    ) external;

    function getPlugin(
        bytes32 _pluginName,
        uint256 _version
    ) external view returns (bool enable, address pluginContract);

    function getPluginContract(
        bytes32 _pluginName,
        uint256 _version
    ) external view returns (address pluginContract);

    function isEnablePlugin(
        bytes32 _pluginName,
        uint256 _version
    ) external view returns (bool enable);

    function isVotingContract(
        address _contract
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface INFT is IERC721EnumerableUpgradeable {

    function version() external pure returns (string memory);

    function setBaseTokenURI(string memory baseTokenURI) external;

    function mint(address _owner) external returns (uint256);

    function burn(uint256 tokenId) external;

    function setReceiveApproved(uint256 tokenId) external;

    function getReceiveApproved(uint256 tokenId) external view returns (address);

    function tokensOfOwner(address user) external view returns (uint256[] memory);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

import "../../../libraries/DataTypes.sol";


interface ISubscription is IERC721EnumerableUpgradeable {

    function version() external pure returns (string memory);

    function setBaseTokenURI(string memory baseTokenURI) external;

    function mint(DataTypes.SimpleVars calldata vars) external returns (uint256);

    function tokensOfOwner(address user) external view returns (uint256[] memory);

    function getPaymentInfo(uint256 _nftId) external view returns(DataTypes.PaymentInfo memory);
}