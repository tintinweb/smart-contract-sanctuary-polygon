// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IAction.sol";
import "../../interfaces/ISiloFactory.sol";
import "../../interfaces/ISilo.sol";

contract SiloSubFactory is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public siloFactory;

    mapping(address => EnumerableSet.AddressSet) private acceptSenderList;

    mapping(address => EnumerableSet.AddressSet) private approvedReceiverList;

    mapping(address => bool) public skipActionValidTeamCheck; //when assigning a strategy this check makes sure team still deems action valid
    mapping(address => bool) public skipActionValidLogicCheck; //when assigning a strategy this check makes sure farms have not ended

    event SiloAcceptSender(address sender, address receiver);
    event SiloRejectSender(address sender, address receiver);
    event SiloStatusUpdate(uint256 siloID, uint256 status);
    event SiloNameUpdate(uint256 siloID, string name);
    event SiloDelayUpdate(uint256 siloID, uint256 delay);

    modifier isOwner(uint256 siloID) {
        require(
            ISiloFactory(siloFactory).ownerOf(siloID) == msg.sender,
            "Caller does not own this silo!"
        );
        _;
    }

    constructor(address _siloFactory) {
        siloFactory = _siloFactory;
    }

    /***************************************external onlyOwner *************************************/
    function updateSiloFactory(address _siloFactory) external onlyOwner {
        siloFactory = _siloFactory;
    }

    function adjustActionTeamCheck(bool _state) external {
        skipActionValidTeamCheck[msg.sender] = _state;
    }

    function adjustActionLogicCheck(bool _state) external {
        skipActionValidLogicCheck[msg.sender] = _state;
    }

    function checkActionLogicValid(
        address user,
        address _implementation,
        bytes memory _configurationData
    ) public view returns (bool) {
        (bool team, bool logic) = IAction(_implementation).actionValid(
            _configurationData
        );
        if (!skipActionValidTeamCheck[user]) {
            require(
                team,
                "Gravity Finance: Team no longer deems action to be valid"
            );
        }

        if (!skipActionValidLogicCheck[user]) {
            require(
                logic,
                "Gravity Finance: action is no  longer logically valid"
            );
        }
        return true;
    }

    function checkActionsLogicValid(
        address user,
        address[] memory _actions,
        bytes[] memory _configurationData
    ) public view returns (bool) {
        if (
            !skipActionValidTeamCheck[user] || !skipActionValidLogicCheck[user]
        ) {
            //need to check that every action is still valid
            for (uint256 i; i < _actions.length; ) {
                checkActionLogicValid(user, _actions[i], _configurationData[i]);
                unchecked {
                    i++;
                }
            }
        }
        return true;
    }

    /*************************** accept transfers from ********************/

    function acceptedSenders(
        address receiver
    ) public view returns (address[] memory) {
        return acceptSenderList[receiver].values();
    }

    function approvedReceivers(
        address sender
    ) public view returns (address[] memory) {
        return approvedReceiverList[sender].values();
    }

    function acceptTransfersFrom(
        address to,
        address from
    ) public view returns (bool) {
        return acceptSenderList[to].contains(from);
    }

    function approveTransfersFrom(address _from) external {
        acceptSenderList[msg.sender].add(_from);

        approvedReceiverList[_from].add(msg.sender);

        emit SiloAcceptSender(_from, msg.sender);
    }

    function rejectTransfersFrom(address _from) external {
        acceptSenderList[msg.sender].remove(_from);

        approvedReceiverList[_from].remove(msg.sender);

        emit SiloRejectSender(_from, msg.sender);
    }

    function pauseSilo(uint256 siloID) external isOwner(siloID) {
        ISilo silo = ISilo(ISiloFactory(siloFactory).siloMap(siloID));
        silo.pause();
        emit SiloStatusUpdate(siloID, 0);
    }

    function unpauseSilo(uint256 siloID) external isOwner(siloID) {
        ISilo silo = ISilo(ISiloFactory(siloFactory).siloMap(siloID));
        silo.unpause();
        emit SiloStatusUpdate(siloID, 1);
    }

    function activeSilo(uint256 siloID) external isOwner(siloID) {
        ISilo silo = ISilo(ISiloFactory(siloFactory).siloMap(siloID));
        silo.setActive();
        emit SiloStatusUpdate(siloID, 2);
    }

    function adjustSiloDelay(
        uint256 siloID,
        uint256 _newDelay
    ) external isOwner(siloID) {
        ISilo silo = ISilo(ISiloFactory(siloFactory).siloMap(siloID));
        silo.adjustSiloDelay(_newDelay);
        emit SiloDelayUpdate(siloID, _newDelay);
    }

    function nameSilo(
        uint256 siloID,
        string memory _name
    ) external isOwner(siloID) {
        ISilo silo = ISilo(ISiloFactory(siloFactory).siloMap(siloID));
        silo.setName(_name);
        emit SiloNameUpdate(siloID, _name);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct ActionBalance {
    uint256 collateral;
    uint256 debt;
    address collateralToken;
    address debtToken;
    uint256 collateralConverted;
    address collateralConvertedToken;
    string lpUnderlyingBalances;
    string lpUnderlyingTokens;
}

interface IAction {
    function getConfig() external view returns (bytes memory config);

    function checkMaintain(
        bytes memory configuration
    ) external view returns (bool, uint256);

    function checkUpkeep(
        bytes memory configuration
    ) external view returns (bool);

    function extraInfo(
        bytes memory configuration
    ) external view returns (uint256[4] memory info);

    function validateConfig(
        bytes memory configData
    ) external view returns (bool);

    function getMetaData() external view returns (string memory);

    function getFactory() external view returns (address);

    function getDecimals() external view returns (uint256);

    function showFee(
        address _action
    ) external view returns (string memory actionName, uint256[4] memory fees);

    function showBalances(
        address _silo,
        bytes memory _configurationData
    ) external view returns (ActionBalance memory);

    function showDust(
        address _silo,
        bytes memory _configurationData
    ) external view returns (address[] memory, uint256[] memory);

    function vaultInfo(
        address _silo,
        bytes memory configuration
    ) external view returns (uint256, uint256, uint256, uint256, uint256);

    function actionValid(
        bytes memory _configurationData
    ) external view returns (bool, bool);

    function getIsSilo(address _silo) external view returns (bool);

    function getIsSiloManager(
        address _silo,
        address _manager
    ) external view returns (bool);

    function setFactory(address _siloFactory) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct PriceOracle {
    address oracle;
    uint256 actionPrice;
}

enum Statuses {
    PAUSED,
    DORMANT,
    MANAGED,
    UNWIND
}

interface ISilo {
    function initialize(
        uint256 siloID,
        uint256 main,
        address factory,
        uint256 autoType
    ) external;

    function autoType() external view returns (uint256);

    function deposit() external;

    function withdraw(uint256 _requestedOut) external;

    function maintain() external;

    function exitSilo(address caller) external;

    function adminCall(address target, bytes memory data) external;

    function setStrategy(
        address[5] memory input,
        bytes[] memory _configurationData,
        address[] memory _implementations
    ) external;

    function getConfig() external view returns (bytes memory config);

    function withdrawToken(address token, address recipient) external;

    function adjustSiloDelay(uint256 _newDelay) external;

    function checkUpkeep(
        bytes calldata checkData
    ) external view returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;

    function siloDelay() external view returns (uint256);

    function name() external view returns (string memory);

    function lastTimeMaintained() external view returns (uint256);

    function setName(string memory name) external;

    function deposited() external view returns (bool);

    function isNew() external view returns (bool);

    function status() external view returns (Statuses);

    function setStrategyName(string memory _strategyName) external;

    function setStrategyCategory(uint256 _strategyCategory) external;

    function strategyName() external view returns (string memory);

    function tokenMinimum(address token) external view returns (uint256);

    function strategyCategory() external view returns (uint256);

    function main() external view returns (uint256);

    function lastPid() external view returns (uint256);

    function adjustStrategy(
        uint256 _index,
        bytes memory _configurationData,
        address _implementation
    ) external;

    function viewStrategy()
        external
        view
        returns (address[] memory actions, bytes[] memory configData);

    function highRiskAction() external view returns (bool);

    function showActionStackValidity() external view returns (bool, bool);

    function getInputTokens() external view returns (address[5] memory);

    function getStatus() external view returns (Statuses);

    function pause() external;

    function unpause() external;

    function setActive() external;

    function possibleReinvestSilo() external view returns (bool possible);

    function getExtraSiloInfo()
        external
        view
        returns (
            uint256 strategyType,
            uint256 currentBalance,
            uint256 possibleWithdraw,
            uint256 availableBlock,
            uint256 pendingReward,
            uint256 lastPid
        );

    function getReferralInfo()
        external
        view
        returns (uint256 fee, address recipient);

    function setReferralInfo(bytes32 _code) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface ISiloFactory is IERC721Enumerable{
    function tokenMinimum(address _token) external view returns(uint _minimum);
    function balanceOf(address _owner) external view returns(uint);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function managerFactory() external view returns(address);
    function siloMap(uint _id) external view returns(address);
    function tierManager() external view returns(address);
    function ownerOf(uint _id) external view returns(address);
    function siloToId(address silo) external view returns(uint);
    // function createSilo(address recipient) external returns(uint);
    function setActionStack(uint siloID, address[5] memory input, address[] memory _implementations, bytes[] memory _configurationData) external;
    // function withdraw(uint siloID) external;
    function getFeeInfo(address _action) external view returns(uint fee, address recipient);
    function strategyMaxGas() external view returns(uint);
    function strategyName(string memory _name) external view returns(uint);
    
    function getCatalogue(uint _type) external view returns(string[] memory);
    function getStrategyInputs(uint _id) external view returns(address[5] memory inputs);
    function getStrategyActions(uint _id) external view returns(address[] memory actions);
    function getStrategyConfigurationData(uint _id) external view returns(bytes[] memory configurationData);
    function useCustom(address _action) external view returns(bool);
    // function getFeeList(address _action) external view returns(uint[4] memory);
    function feeRecipient(address _action) external view returns(address);
    function defaultFeeList() external view returns(uint[4] memory);
    function defaultRecipient() external view returns(address);
    // function getTier(address _silo) external view returns(uint);

    function getFeeInfoNoTier(address _action) external view returns(uint[4] memory);
    function highRiskActions(address _action) external view returns(bool);
    function actionValid(address _action) external view returns(bool);
    function skipActionValidTeamCheck(address _user) external view returns(bool);
    function skipActionValidLogicCheck(address _user) external view returns(bool);
    function isSilo(address _silo) external view returns(bool);

    function isSiloManager(address _silo,address _manager) external view returns(bool);

    function currentStrategyId() external view returns(uint);
    function minBalance() external view returns(uint);

    function mainActoins(string memory strategyName) external view returns(uint);
    
    function subFactory() external view returns(address);
    function referral() external view returns(address);
}