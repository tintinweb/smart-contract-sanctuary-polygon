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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
pragma solidity =0.8.17;

import { IPoseDelegationRegistry } from "../interface/IPoseDelegationRegistry.sol";
import { IPoseRegistry } from "../interface/IPoseRegistry.sol";
import { IPoseStaking } from "../interface/IPoseStaking.sol";

import { Ownable } from "openzeppelin-contracts/access/Ownable.sol";
import { ERC165 } from "openzeppelin-contracts/utils/introspection/ERC165.sol";

// Errors
error NotOwnerOrDelegate();
error OnlySpender();
error InsufficientBalance();
error TokenLocked();
error InvalidVault();
error InvalidToken();

contract PoseStaking is IPoseStaking, Ownable, ERC165 {
    // POSE Events
    event PoseClaimed(address collectionAddress, uint32 chainId, uint32 tokenId, uint256 amount, address vault, uint256 time);
    event PoseLocked(address collectionAddress, uint32 chainId, uint32 tokenId, uint256 duration, uint256 time);
    event PoseTransferred(address sender, address recipient, uint256 amount, uint256 time);
    event PoseWithdrawn(address vault, uint256 amount, uint256 time);

    IPoseRegistry private poseRegistry;
    IPoseDelegationRegistry private delegationRegistry;

    // ChainId, collection address, tokenId => Token
    mapping(uint32 => mapping(address => mapping(uint32 => IPoseStaking.TokenInfo))) private tokens;
    // Spender address => BOOL
    mapping(address => bool) private tokenSpender;
    // Vault Address => POSE Balance
    mapping(address => uint256) private vaultPoseBalance;
    // Staking Storage
    uint256 public stakingEmissionRate;

    constructor(IPoseRegistry _poseRegistry, IPoseDelegationRegistry _delegationRegistry) {
        poseRegistry = _poseRegistry;
        delegationRegistry = _delegationRegistry;
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IPoseStaking).interfaceId || super.supportsInterface(interfaceId);
    }

    function setStakingEmissions(uint256 _ratePerSecond) external onlyOwner {
        stakingEmissionRate = _ratePerSecond;
    }

    function setSpender(address spender, bool value) external onlyOwner {
        tokenSpender[spender] = value;
    }

    // // Vault linked to owning wallet can claim NFT's POSE balance
    function claimPose(
        address _collectionAddress,
        uint32 _chainId,
        uint32 _tokenId
    ) public override onlyTokenOwningVault(_collectionAddress, _chainId, _tokenId) {
        TokenInfo memory token = tokens[_chainId][_collectionAddress][_tokenId];
        uint256 claimablePose = getClaimablePose(_collectionAddress, _chainId, _tokenId);
        // Need POSE to claim
        if (claimablePose == 0) revert InsufficientBalance();
        // Can't claim if token locked
        if (block.timestamp < token.lockedUntil) revert TokenLocked();

        // Remove POSE from NFT
        token.claimedPose = token.claimedPose + claimablePose;
        tokens[_chainId][_collectionAddress][_tokenId] = token;

        // Add POSE to Vault Balance
        vaultPoseBalance[msg.sender] = vaultPoseBalance[msg.sender] + claimablePose;

        emit PoseClaimed(_collectionAddress, _chainId, _tokenId, claimablePose, msg.sender, block.timestamp);
    }

    function lockPose(
        address _collectionAddress,
        uint32 _chainId,
        uint32 _tokenId,
        uint256 _lockSeconds
    ) public override onlyTokenOwningVault(_collectionAddress, _chainId, _tokenId) {
        TokenInfo memory token = tokens[_chainId][_collectionAddress][_tokenId];
        token.lockedUntil = block.timestamp + (_lockSeconds * 1 seconds);
        tokens[_chainId][_collectionAddress][_tokenId] = token;
        // TODO: Change to emit locked timestamp instead of duration
        emit PoseLocked(_collectionAddress, _chainId, _tokenId, _lockSeconds, block.timestamp);
    }

    function withdrawPose(address _vault, uint256 _amount) external override {
        if (!tokenSpender[msg.sender]) revert OnlySpender();
        if (getVaultPoseBalance(_vault) < _amount) revert InsufficientBalance();

        // Remove POSE from sender balance
        vaultPoseBalance[_vault] = vaultPoseBalance[_vault] - _amount;

        emit PoseWithdrawn(_vault, _amount, block.timestamp);
    }

    // Check claimable POSE balance for NFT.
    function getClaimablePose(address _collectionAddress, uint32 _chainId, uint32 _tokenId) public view override returns (uint256) {
        uint256 reflectedTime = poseRegistry.getNftInfo(_collectionAddress, _chainId, _tokenId).reflectedTime;
        uint256 claimedPose = tokens[_chainId][_collectionAddress][_tokenId].claimedPose;
        if (reflectedTime == 0) revert InvalidToken();

        // TODO: Make this much lower
        uint256 earned = (block.timestamp - reflectedTime) * (stakingEmissionRate) - claimedPose;

        return earned;
    }

    function getClaimedPose(address _collectionAddress, uint32 _chainId, uint32 _tokenId) external view override returns (uint256) {
        return tokens[_chainId][_collectionAddress][_tokenId].claimedPose;
    }

    function getTokenUnlockTime(address _collectionAddress, uint32 _chainId, uint32 _tokenId) external view override returns (uint256) {
        return tokens[_chainId][_collectionAddress][_tokenId].lockedUntil;
    }

    function getVaultPoseBalance(address _vault) public view override returns (uint256) {
        return vaultPoseBalance[_vault];
    }

    // Ensures vault calling function is linked to wallet owning token
    modifier onlyTokenOwningVault(
        address contract_,
        uint32 _chainId,
        uint32 _tokenId
    ) {
        address wallet = poseRegistry.getNftOwner(contract_, uint32(_chainId), uint32(_tokenId));
        address vault = poseRegistry.getWalletOwner(wallet);
        if (
            poseRegistry.getWalletOwner(wallet) != msg.sender &&
            !delegationRegistry.checkDelegateForAll(msg.sender, vault) &&
            !delegationRegistry.checkDelegateForWallet(msg.sender, vault, wallet) &&
            !delegationRegistry.checkDelegateForToken(msg.sender, vault, contract_, _chainId, _tokenId)
        ) {
            revert NotOwnerOrDelegate();
        }
        _;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow
 */
interface IPoseDelegationRegistry {
    /// @notice Delegation type
    enum DelegationType {
        NONE,
        VAULT,
        WALLET,
        TOKEN
    }

    /// @notice Info about a single delegation, used for onchain enumeration
    struct DelegationInfo {
        DelegationType type_;
        address vault;
        address delegate;
        address wallet;
        address contract_;
        uint256 chainId;
        uint256 tokenId;
    }

    /// @notice Info about a single wallet-level delegation
    struct WalletDelegation {
        address wallet;
        address delegate;
    }

    /// @notice Info about a single token-level delegation
    struct TokenDelegation {
        address contract_;
        uint256 chainId;
        uint256 tokenId;
        address delegate;
    }

    /// @notice Emitted when a user delegates their entire wallet
    event DelegateForAll(address vault, address delegate, bool value);

    /// @notice Emitted when a user delegates a specific contract
    event DelegateForWallet(address vault, address delegate, address wallet, bool value);

    /// @notice Emitted when a user delegates a specific token
    event DelegateForToken(address vault, address delegate, address wallet, uint256 chainId, uint256 tokenId, bool value);

    /// @notice Emitted when a user revokes all delegations
    event RevokeAllDelegates(address vault);

    /// @notice Emitted when a user revoes all delegations for a given delegate
    event RevokeDelegate(address vault, address delegate);

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Allow the delegate to act on your behalf for all contracts
     * @param delegate The hotwallet to act on your behalf
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForAll(address delegate, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific contract
     * @param delegate The hotwallet to act on your behalf
     * @param wallet The address for the contract you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForWallet(address delegate, address wallet, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific token
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForToken(address delegate, address contract_, uint256 chainId, uint256 tokenId, bool value) external;

    /**
     * @notice Revoke all delegates
     */
    function revokeAllDelegates() external;

    /**
     * @notice Revoke a specific delegate for all their permissions
     * @param delegate The hotwallet to revoke
     */
    function revokeDelegate(address delegate) external;

    /**
     * @notice Remove yourself as a delegate for a specific vault
     * @param vault The vault which delegated to the msg.sender, and should be removed
     */
    function revokeSelf(address vault) external;

    /**
     * -----------  READ -----------
     */

    /**
     * @notice Returns all active delegations a given delegate is able to claim on behalf of
     * @param delegate The delegate that you would like to retrieve delegations for
     * @return info Array of DelegationInfo structs
     */
    function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory);

    /**
     * @notice Returns an array of wallet-level delegates for a given vault
     * @param vault The cold wallet who issued the delegation
     * @return addresses Array of wallet-level delegates for a given vault
     */
    function getDelegatesForAll(address vault) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault and contract
     * @param vault The cold wallet who issued the delegation
     * @param wallet The address for the contract you're delegating
     * @return addresses Array of contract-level delegates for a given vault and contract
     */
    function getDelegatesForWallet(address vault, address wallet) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault's token
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract holding the token
     * @param tokenId The token id for the token you're delegating
     * @return addresses Array of contract-level delegates for a given vault's token
     */
    function getDelegatesForToken(address vault, address contract_, uint256 chainId, uint256 tokenId) external view returns (address[] memory);

    /**
     * @notice Returns all contract-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of WalletDelegation structs
     */
    function getWalletLevelDelegations(address vault) external view returns (WalletDelegation[] memory delegations);

    /**
     * @notice Returns all token-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of TokenDelegation structs
     */
    function getTokenLevelDelegations(address vault) external view returns (TokenDelegation[] memory delegations);

    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(address delegate, address vault) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param wallet The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForWallet(address delegate, address vault, address wallet) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 chainId, uint256 tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "../libraries/AppStorage.sol";

/**
 * @title NFT abstraction and ownership verification protocol.
 */

interface IPoseRegistry {
    /**
     * ----- Write Functions -----
     */

    /**
     * @notice Registers a wallet as a vault. Called duringing initial gasless wallet
     *         creation by the protocol. Users are open to register any EOA or contract wallet
     *         as a vault.
     * @dev Function registers msg.sender as vault.
     */
    function registerVault() external;

    /**
     * @notice Register a name for your vault.
     * @param _name Name you want to register for your vault. 24 character limit.
     */
    function nameVault(string calldata _name) external;

    /**
     * @notice Registers a collection in the Pose protocol allowlist. Can only be called by Reflection Managers.
     * @param _collectionAddress Address of collection
     * @param _chainId ChainId of collection
     */
    function registerCollection(address _collectionAddress, uint32 _chainId) external;

    /**
     * @notice Removes a collection from the Pose protocol allowlist. Can only be called by Reflection Managers.
     * @param _collectionAddress Address of collection
     * @param _chainId ChainId of collection
     */
    function purgeCollection(address _collectionAddress, uint32 _chainId) external;

    /**
     * @notice Registers wallet with pose vault using EIP712 signatures. A wallet can only be linked to 1 vault.
     *         A vault can have many linked wallets.
     * @param wallet Struct { address vault, address wallet }
     * @param signature EIP712 signature
     */
    function registerWallet(Wallet memory wallet, bytes memory signature) external;

    /**
     * @notice Allows a vault to unlink a wallet
     * @param _wallet Address of wallet to unregister.
     */
    function unregisterWallet(address _wallet) external;

    /**
     * @notice Reflects NFT ownership from approved collections to user vaults from linked wallets.
     *         Can only be called by Reflection Managers.
     * @param _reflectNftParams Array of reflectNftParams struct
     */
    function reflectNFTs(ReflectNftParams[] calldata _reflectNftParams) external;

    /**
     * @notice Purges reflected NFTs. Can only be called by Reflection Managers.
     * @param _reflectNftParams Array of reflectNftParams struct
     */
    function purgeNFTs(ReflectNftParams[] calldata _reflectNftParams) external;

    /**
     * @notice Assigns addresses to reflection manager role
     * @param _reflectionManagers Arrary of addresses
     */
    function addReflectionManagers(address[] calldata _reflectionManagers) external;

    /**
     * @notice Removes addresses from reflection manager role
     * @param _reflectionManagers Arrary of addresses
     */
    function removeReflectionManagers(address[] calldata _reflectionManagers) external;

    /**
     * ----- Read Functions -----
     */

    /**
     * @notice Returns name for specified vault address
     * @param _vault Address of vault
     * @return Name of vault
     */
    function getVaultName(address _vault) external view returns (string memory);

    /**
     * @notice Returns address for specified vault name
     * @param _name Name of vault
     * @return Address of vault
     */
    function getVaultReverseLookup(string calldata _name) external view returns (address);

    ///
    /// @param _vault Vault to transfer name to
    function transferName(address _vault) external;

    /// @notice Removes name set from vault.
    function removeName() external;

    /**
     * @notice Returns if address is registered as a vault
     * @param _vaultAddress Addresss of vault
     * @return Bool if address is vault
     */
    function isVault(address _vaultAddress) external view returns (bool);

    /**
     * @notice Returns if collection is registered
     * @param _collectionAddress Addresss of collection
     * @param _chainId ChainId of collection
     * @return Bool if collection registered
     */
    function isCollectionRegistered(address _collectionAddress, uint32 _chainId) external view returns (bool);

    /**
     * @notice Checks if wallet exists in address set for a specific vault.
     * @param _vault Address of vault
     * @param _wallet Address of wallet to check
     * @return Bool if wallet in set
     */
    function getWalletInSet(address _vault, address _wallet) external view returns (bool);

    /**
     * @notice Get vault address wallet is linked to.
     * @param _wallet Wallet address
     * @return address Vault address
     */
    function getWalletOwner(address _wallet) external view returns (address);

    /**
     * @notice Checks if specific token has been reflected to Pose protocol.
     * @param _collectionAddress Address of collection
     * @param _chainId ChainId of collection
     * @param _tokenId TokenId of NFT
     * @return exists Bool if NFT is reflected
     */
    function isNftReflected(address _collectionAddress, uint32 _chainId, uint32 _tokenId) external view returns (bool exists);

    /**
     * @notice Returns wallet owning NFT as set and updated by reflection managers.
     * @param _collectionAddress Address of collection
     * @param _chainId ChainId of collection
     * @param _tokenId TokenId of NFT
     * @return Address of wallet owning NFT
     */
    function getNftOwner(address _collectionAddress, uint32 _chainId, uint32 _tokenId) external view returns (address);

    /**
     * @notice Returns info for reflected NFT
     * @param _collectionAddress Address of collection
     * @param _chainId ChainId of collection
     * @param _tokenId TokenId of NFT
     * @return token Struct of reflected token info
     */
    function getNftInfo(address _collectionAddress, uint32 _chainId, uint32 _tokenId) external view returns (Token memory token);

    /**
     * @notice Admin function to set toekn contract address.
     * @param tokenAddress Address of PoseToken contract.
     */
    function setTokenContract(address tokenAddress) external;

    /**
     * @notice Checks if address is set as reflection manager.
     * @param account Address to check
     * @return If address is set as refelction manager
     */
    function isReflectionManger(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IPoseStaking {
    struct TokenInfo {
        uint256 claimedPose;
        uint256 lockedUntil;
    }

    /**
     * -----------  WRITE -----------
     */

    function setStakingEmissions(uint256 _ratePerSecond) external;

    function setSpender(address spender, bool value) external;

    function claimPose(address _collectionAddress, uint32 _chainId, uint32 _tokenId) external;

    function lockPose(address _collectionAddress, uint32 _chainId, uint32 _tokenId, uint256 _lockSeconds) external;

    function withdrawPose(address _vault, uint256 _amount) external;

    /**
     * -----------  READ -----------
     */

    function getClaimablePose(address _collectionAddress, uint32 _chainId, uint32 _tokenId) external view returns (uint256);

    function getTokenUnlockTime(address _collectionAddress, uint32 _chainId, uint32 _tokenId) external view returns (uint256);

    function getClaimedPose(address _collectionAddress, uint32 _chainId, uint32 _tokenId) external view returns (uint256);

    function getVaultPoseBalance(address _vault) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import { EnumerableSet } from "openzeppelin-contracts/utils/structs/EnumerableSet.sol";

struct Collection {
    // ChainId + CollectionAddress
    string name;
    uint32 maxSupply;
}

struct Token {
    address owningWallet;
    uint256 reflectedTime;
    uint256 claimedPose;
    uint256 lockedUntil;
}

struct EIP712Domain {
    string name;
    string version;
    address verifyingContract;
}

struct ReplayProtection {
    uint256 nonce;
    uint256 queue;
}

struct Wallet {
    address poseWallet;
    address linkWallet;
}

struct ReflectNftParams {
    // Slot 1 (224/256 used)
    address collectionAddress;
    uint32 chainId;
    uint32 tokenId;
    // Slot 2 (160/256 used)
    address linkWallet;
}

struct AppStorage {
    // Vault => Bool
    mapping(address => bool) isVault;
    // Vault Address => Linked Wallet Set
    mapping(address => EnumerableSet.AddressSet) linkedWallets;
    // Linked wallet => Vault
    mapping(address => address) linkedVault;
    // ChainId => (Collection Address => Collection)
    // Currently unused
    mapping(uint32 => mapping(address => Collection)) collectionDetails;
    // ChainId => (Collection Address => Bool)
    mapping(uint32 => mapping(address => bool)) collections;
    // ChainId, collection address, tokenId => Token
    mapping(uint32 => mapping(address => mapping(uint32 => Token))) tokens;
    // Simple Access Control for Reflection Functions
    mapping(address => bool) reflectionManagers;
    // Vault => Name
    mapping(address => string) vaultNames;
    mapping(string => address) vaultReverseLookup;
    // EIP712 Vars
    string contractName;
    string version;
    bytes32 domainHash;
}

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage ds) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := 0
        }
    }
}