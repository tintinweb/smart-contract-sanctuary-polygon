// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
pragma solidity ^0.8.0;

interface ICalRandomItem {

    function randShopItem(uint256 number, uint256 level) external view returns (uint16[] memory);

    function randShopEssence(uint256[] memory number, uint256 level) external view returns (uint16[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICalRandomResource {
    // function randShop2Resource(uint256 number, uint256 level, uint256 ratio, uint256 option) external view returns (uint16[] memory);
    
    function randShopResource(uint256 number, uint256 num, uint256 level, uint256 ratio, uint256 option) external view returns (uint16[] memory);
    
    function randShop20Resource(uint256[] memory number, uint256 level, uint256 ratio, uint256 option) external view returns (uint16[] memory);
    
    function randShop30Resource(uint256[] memory number, uint256 level, uint256 ratio, uint256 option) external view returns (uint16[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGame {
    struct RequestResult {
        uint256 requestId;
        address player;
        uint16 numResource; // 1, 2, ... số lần hiện shop; 20 = 1 shop hiện 20 resource, 30 = 1 shop hiện 30 resource
        uint16 numItem; // 1, 2, ... số lần xuất hiện shop
        uint8 shop2Resource; // 0 = ko shop nào, 1 shop đầu có 2 resource
        uint8 must; // 0 = tự do, 1 = phải chọn 1 resource, 2 = phải skip resource
        uint8 end; // 0 = chưa chọn, 1 = đã chọn
        uint8 option; //option = 0: bình thường, option = 1: rare + veryRare, 2: veryRare
        uint16 ratio;
        uint16[] resources;
        uint16[] items;
        uint16[] essences;
    }


    event LandDeposited(address from, uint256 landId);
    event LandWithdrew(address from, uint256 landId);
    event Rolled(address from, uint256 landId, uint256 requestId, uint256[20] position);
    event BoughtFromShop(
        address from,
        uint256 landId, 
        uint16[] resourceId, 
        uint16[] itemId, 
        uint16[] essenceId
    );

    function cogResources() external view returns (address);

    function getType(uint8 level, bool option, uint256 number, uint16 ratio) external view returns (uint256 type_);

    function executeRoll(uint256[] memory randomNumber, uint256 requestId) external;

    function ownerOfLand(address account, uint256 landId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC721EnumerableUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface ILand is IERC721EnumerableUpgradeable {
    event NFTMinted (address to, uint256[] ids);

    function maxAmount() external view returns (uint256);

    function currentAmount() external view returns (uint256);

    function mintToken(address to, uint256 id) external;

    function mintBatchToken(address to, uint256[] memory ids) external;

    function genesisMinter(address) external view returns (bool);

    function baseURI() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILandManager {
    event LandMinted(
        address owner,
        uint256 id,
        uint256 rarity,
        uint256 floor,
        uint256 maticPrice,
        uint256 nvsPrice
    );
    event LandUpgrade(
        address owner,
        uint256 id,
        uint256 floor,
        uint256 richness,
        uint256 price
    );

    struct LandInfo {
        uint16 rarityType; // 1 = common; 2 = uncommon; 3 = rare; 4 = very rare
        uint16 floor; // 1 - 5
        uint16 level; // 1- 12
        uint16 richness;
        uint64 currentNumber;
        // uint64 removeTokenUse;
        uint64 resourceDeposit;
        uint32 isPaid; // 0 = chưa trả phí, 1 = đã trả phí
        uint32 numEmty;
        uint256 balance; // balance of token A
        uint256 essenceToken;
        uint256 overTax;
        bool isGameOver;
    }

    struct Limit {
        uint64 perResource;
        uint64 totalItem;
        // uint64 totalRemoveTokenUse;
        uint64 resourceDepositLimit;
    }

    struct RequestInfo {
        address ownerRequest;
        uint256 maticCost;
        uint256 nvsCost;
    }

    struct SpecialResource {
        int256 payout;
        uint256 prop;
    }

    function landInfos(uint256 id) external view returns (LandInfo memory);

    function stash() external view returns (address);

    function richnesses(uint256, uint256) external view returns (uint256);

    function getAddress() external view returns (address, address);

    function getSpecialResources(
        uint256 landId,
        uint256 resourceId
    ) external view returns (SpecialResource[] memory);

    function getSpecialItems(
        uint256 landId,
        uint256 itemId
    ) external view returns (uint256[] memory);

    function getAResource(
        uint256 landId,
        uint256 resourceId
    ) external view returns (bool, uint256);

    function getAItem(
        uint256 landId,
        uint256 itemId
    ) external view returns (bool, uint256);

    function getASpecialItem(
        uint256 landId,
        uint256 itemId,
        uint256 index
    ) external view returns (uint256);

    function getASpecialResource(
        uint256 landId,
        uint256 itemId,
        uint256 index
    ) external view returns (SpecialResource memory);

    function getArrayResources(
        uint256 landId
    ) external view returns (uint256[] memory sym, uint256 total);

    function getResources(
        uint256 landId
    ) external view returns (uint256[] memory sym, uint256[] memory qt);

    function getItems(
        uint256 landId
    ) external view returns (uint256[] memory it, uint256[] memory qt);

    function getDestroyedResources(
        uint256 landId
    ) external view returns (uint256[] memory sym, uint256[] memory qt);

    function isItemExist(
        uint256 landId,
        uint256 itemId
    ) external view returns (bool);

    function getDestroyedItems(
        uint256 landId
    ) external view returns (uint256[] memory it, uint256[] memory qt);

    function getRemovedResources(
        uint256 landId
    ) external view returns (uint256[] memory sym, uint256[] memory qt);

    function getLimit(uint256 id) external view returns (Limit memory);

    function getTotalItem(uint256 landId) external view returns (uint256 total);

    function getType(uint256 id) external view returns (uint256);

    function executeMint(uint256 randomNumber, uint256 requestId) external;

    function nextNumber(uint256 id) external;

    function payTax(uint256 id, uint256 option) external;

    function enrich(uint256 id, uint256 newRichness) external;

    function updateBalance(uint256 id, uint256 amount, bool incre) external;

    function updateEssenceToken(uint256 id, uint256 amount, bool incre) external;

    function updateResourceDeposit(uint256 landId, uint256 amount) external;

    function addResource(
        uint256 landId,
        uint256 resourceId,
        uint256 quantity,
        int256 payout,
        uint256 prop
    ) external;

    function removeResource(
        uint256 landId,
        uint256 resourceId,
        uint256 id
    ) external;

    function updateSpecialResource(
        uint256 landId,
        uint256 resourceId,
        uint256 id,
        int256 newPayout,
        uint256 newProp
    ) external;

    function addItem(uint256 id, uint256 itemId, uint256 prop) external;

    function removeItem(uint256 landId, uint256 itemId, uint256 id) external;

    function updateSpecialItem(
        uint256 landId,
        uint256 itemId,
        uint256 id,
        uint256 newProp
    ) external;

    function removeAllAResource(uint256 landId, uint256 resourceId) external;

    function addDestroyedResources(uint256 landId, uint256 resourceId) external;

    function addDestroyedItems(uint256 landId, uint256 itemId) external;

    function addRemovedResources(uint256 landId, uint256 resourceId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPrices {
    function prices(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 
 
 interface IRandom {

    function requestRandomWords(uint256 option_) external returns (uint256 requestId);
    function getRequestStatus(
        uint256 _requestId
    ) external view returns (uint256 paid, bool fulfilled, uint256[] memory randomWords);
 }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IResource is IERC1155Upgradeable {
    function genesisMinter(address) external view returns (bool);

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { ERC721HolderUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import { EnumerableSetUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./../interfaces/IGame.sol";
import "./../interfaces/ILandManager.sol";
import "./../interfaces/IRandom.sol";
import "./../interfaces/ILand.sol";
import "./../interfaces/IPrices.sol";
import "./../interfaces/IResource.sol"; 
import "./logic/resources/interfaces/ICoGResources.sol";
import "./logic/IGameController.sol";
import "./logic/items/interfaces/ICoGItems.sol";
import "./../interfaces/ICalRandomResource.sol"; 
import "./../interfaces/ICalRandomItem.sol";
import "./../library/SafeToken.sol"; 

contract Game is
    ERC721HolderUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    IGame
{
    using SafeToken for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    IERC20Upgradeable public token;
    IRandom public random;
    ILand public land;
    ILandManager public manager;
    IResource public resourceAddr;
    ICalRandomResource public calRandomResource;
    ICalRandomItem public calRandomItem;
    IPrices public prices;
    address public override cogResources;
    address public treasury;
    IGameController public gameController;
    
    mapping (address => EnumerableSetUpgradeable.UintSet) private lands;
    mapping (uint256 => EnumerableSetUpgradeable.UintSet) private items;
    mapping (uint256 => mapping(uint256 => uint256)) public rarities; // level => loại Resource (1 - 4) / loại Resource (5 - 8) => rarity 4 loại Resources + rarity 4 loại items
    mapping (uint256 => uint256) public requests; // requestId => landId
    mapping (uint256 => RequestResult) public landRequests; // landId => result

    function initialize(
        address token_,
        address resource_,
        address random_,
        address land_,
        address manager_,
        address calRandomResource_,
        address calRandomItem_,
        address prices_,
        address treasury_
    ) external initializer {
        __Pausable_init();
        __Ownable_init();
        __ERC721Holder_init();
        token = IERC20Upgradeable(token_);
        resourceAddr = IResource(resource_);
        random = IRandom(random_);
        land = ILand(land_);
        manager = ILandManager(manager_);
        calRandomResource = ICalRandomResource(calRandomResource_);
        calRandomItem = ICalRandomItem(calRandomItem_);
        prices = IPrices(prices_);
        treasury = treasury_;
    }

    function depositLand(uint256 landId) external nonReentrant whenNotPaused {
        require(land.ownerOf(landId) == msg.sender, "caller is not owner");
        address account = msg.sender;
        lands[account].add(landId);
        land.safeTransferFrom(account, address(this), landId);
        emit LandDeposited(account, landId);
    }

    function roll(uint256 landId) external nonReentrant whenNotPaused {
        require(landId != 0 && lands[msg.sender].contains(landId), "caller is not owner");
        ILandManager.LandInfo memory info = manager.landInfos(landId);
        require(!info.isGameOver && info.isPaid == 1, "game over");
        uint256 requestId = random.requestRandomWords(1);
        requests[requestId] = landId;
        landRequests[landId].player = msg.sender;
    }

    // sửa mấy resource thay đổi tỷ lệ random cho shop, thêm payout cho resource trong inventory
    function executeRoll(uint256[] memory randomNumber, uint256 requestId) external nonReentrant whenNotPaused {
        require(msg.sender == address(random), "caller is not random");
        uint256 landId = requests[requestId];
        uint256[20] memory position =  calPosition(randomNumber[0], landId);
        uint16 numResource; // 1, 2, ... số lần hiện shop; 20 = 1 shop hiện 20 resource, 30 = 1 shop hiện 30 resource
        uint16 numItem; // 1, 2, ... số lần xuất hiện shop
        uint8 shop2Resource; // 0 = ko shop nào, 1 shop đầu có 2 resource
        uint8 must; // 0 = tự do, 1 = phải chọn 1 resource, 2 = phải skip resource
        uint8 option; //option = 0: bình thường, option = 1: rare + veryRare, 2: veryRare
        uint16 ratio;
        uint256 newBalance;
        // tính toán balance và cập nhật inventory vs position và randomNumber[8], set ratio;
        (numResource,numItem,shop2Resource,must,option,ratio,newBalance) = gameController.executeGame(landId, position, randomNumber[8]);
        manager.updateBalance(landId, newBalance, true);
        manager.nextNumber(landId);
        address player = landRequests[landId].player;
        landRequests[landId].requestId = requestId;
        landRequests[landId].numResource = numResource;
        landRequests[landId].numItem = numItem;
        landRequests[landId].shop2Resource = shop2Resource;
        landRequests[landId].must = must;
        landRequests[landId].ratio = ratio;
        landRequests[landId].option = option;
        landRequests[landId].end = 0;
        emit Rolled(player, landId, requestId, position);
    }

    function payTax(uint256 landId, uint256 option_) external nonReentrant whenNotPaused {
        require(landId != 0 && lands[msg.sender].contains(landId), "caller is not owner");
        require(!manager.landInfos(landId).isGameOver, "game over");
        if (manager.landInfos(landId).isPaid == 0) {
            // check đk option_: // option 0 = trả tiền bình thường, 1 = thêm 1 lượt spin, 2 = bỏ qua tax và thêm 66 emty, 3 = bỏ qua tax
            manager.payTax(landId, option_);
        } else {
            // check đk Comfy_pillow
            manager.nextNumber(landId);
            require(manager.landInfos(landId).isPaid == 0, "invalid");
            manager.payTax(landId, 0);
            if (manager.landInfos(landId).isPaid == 1) {
                landRequests[landId].option = landRequests[landId].option == 2 ? 2 : 1;
            }
        }
    }

    function calPosition(uint256 number, uint256 landId) public view returns (uint256[20] memory position) {
        (uint256[] memory resources, uint256 total) = manager.getArrayResources(landId);
        uint256 count = total;
        for (uint256 i = 0; i < 20; i++) {
            uint256 temp = (number / (1000 ** i)) % 1000;
            uint256 id = temp % count;
            position[i] = resources[id];
            if (id < count - 1) {
                resources[id] = resources[count - 1];
            }
            count -= 1;
        }
    }

    //option = 0: bình thường, option = 1: rare + veryRare, 2: veryRare
    function calResource(uint256[] memory number, uint256 landId, uint16 ratio, uint256 option) public view returns (uint16[] memory) {
        uint256 level = manager.landInfos(landId).level == 1 ? 12 : manager.landInfos(landId).level - 1;
        uint256 num = landRequests[landId].numResource;
        uint256 is2Resource = landRequests[landId].shop2Resource;
        uint16[] memory shop_;
        uint256[] memory number_ = number;
        uint16 ratio_ = ratio;
        uint256 option_ = option;
        if (num <= 3) {
            uint256 length_ = is2Resource == 1 ? num * 3 - 1 : num * 3;
            shop_ = new uint16[](length_);
            uint256 count;
            if (is2Resource == 1) { 
                uint16[] memory shop0 = calRandomResource.randShopResource(number_[0] % 1e21, 2, level, ratio_, option_);
                shop_[0] = shop0[0];
                shop_[1] = shop0[1];
                count = 2;
            
            } else {
                uint16[] memory shop0 = calRandomResource.randShopResource(number_[0] % 1e21, 3, level, ratio_, option_);
                shop_[0] = shop0[0];
                shop_[1] = shop0[1];
                shop_[2] = shop0[2];
                count = 3;
            }
            for (uint256 i = 1; i < num; i++) {
                uint16[] memory shop1 = calRandomResource.randShopResource((number_[0] / ((1e21) ** i)) % 1e21, 3, level, ratio_, 0);
                shop_[count] = shop1[0];
                shop_[count + 1] = shop1[1];
                shop_[count + 2] = shop1[2];
                count += 3;
            } 
        } else if (num == 20) {
            shop_ = calRandomResource.randShop20Resource(number_, level, ratio_, option_);
        } else if (num == 30) {
            shop_ = calRandomResource.randShop30Resource(number_, level, ratio_, option_);
        }
        return shop_;
    }

    function calItem(uint256 number, uint256 landId) public view returns (uint16[] memory) {
        uint256 level = manager.landInfos(landId).level == 0 ? 12 : manager.landInfos(landId).level - 1;
        uint256 num = landRequests[landId].numItem;
        uint16[] memory shop_ = new uint16[](num * 3);
        for (uint256 i = 0; i < num; i++) {
            uint16[] memory shop = calRandomItem.randShopItem((number / ((1e24) ** i)) % (1e24) , level);
            shop_[3 * i] = shop[0];
            shop_[3 * i + 1] = shop[1];
            shop_[3 * i + 2] = shop[2];
        }
        return shop_;
    }

    function calEssence(uint256 number1, uint256 number2, uint256 landId) public view returns (uint16[] memory shop) {
        uint256 level = manager.landInfos(landId).level == 0 ? 12 : manager.landInfos(landId).level - 1;
        uint256 balanceEssence = manager.landInfos(landId).essenceToken;
        uint256 num = balanceEssence > 5 ? 5 : balanceEssence;
        uint16[] memory shop_ = new uint16[](num * 3);
        for (uint256 i = 0; i < num; i++) {
            uint256[] memory number = new uint256[](2);
            number[0] = (number1 / ((1e15) ** i)) % (1e15);
            number[1] = (number2 / ((1e9) ** i)) % (1e9);
            uint16[] memory shop0 = calRandomItem.randShopEssence(number , level);
            shop_[3 * i] = shop0[0];
            shop_[3 * i + 1] = shop0[1];
            shop_[3 * i + 2] = shop0[2];
        }
        return shop_;
    }

    function getLand(address account) external view returns (uint256[] memory landIds) {
        uint256 length_ = lands[account].length();
        for (uint256 i = 0; i < length_; i++) {
            landIds[i] = lands[account].at(i);
        }
    }

    // option = true => resource, false => item
    function getType(uint8 level, bool option, uint256 number, uint16 ratio) public override view returns (uint256 type_) {
        if (option) {
            uint256 total;
            if (ratio != 0) {
                for (uint256 i = 1; i <= 4; i++) {                    
                    if (i == 1) {
                        total += 10000 - ((rarities[level][2] + rarities[level][3] + rarities[level][4]) * ratio / 100);
                    } else {
                        total += rarities[level][i] * ratio / 100;
                    }                   
                    if (number < total) {
                        return i;
                    }
                }
            } else {
                for (uint256 i = 1; i <= 4; i++) {
                    total += rarities[level][i];
                    if (number < total) {
                        return i;
                    }
                }
            }
        } else {
            uint256 total;
            for (uint256 i = 5; i <= 8; i++) {
                total += rarities[level][i];
                if (number < total) {
                    return i - 4;
                }
            }
        }
    }

    function isShowItemShop(uint256 landId) public view returns (bool) {
        ILandManager.LandInfo memory info = manager.landInfos(landId);
        return (info.floor != 1 || info.level != 1) &&
            info.currentNumber == 0 &&
            info.balance > 0 &&
            landRequests[landId].numItem > 0 &&
            info.isPaid == 1;
    }

    function isShowEssenceShop(uint256 landId) public view returns (bool) {
        ILandManager.LandInfo memory info = manager.landInfos(landId);
        return (info.floor != 1 || info.level >= 3) &&
            info.currentNumber == 0 &&
            info.essenceToken > 0;
    }

    function setLandRequest(uint256 landId, uint256[] memory randomNumber) internal {
        uint16[] memory resource;
        uint16[] memory item;
        uint16[] memory essence;
        RequestResult storage res = landRequests[landId];
        if (landRequests[landId].numResource > 0) {
            uint256[] memory numberResource = new uint256[](4);
            for (uint256 i = 0; i < 4; i++) {
                numberResource[i] = randomNumber[i + 1];
            }
            resource = calResource(numberResource, landId, res.ratio, res.option);
        }
        if (isShowItemShop(landId)) {
            item = calItem(randomNumber[5], landId);
        }
        if (isShowEssenceShop(landId)) {
            essence = calEssence(randomNumber[6], randomNumber[7], landId);
        }
        landRequests[landId].resources = resource;
        landRequests[landId].items = item;
        landRequests[landId].essences = essence;
    }

    // chọn resource or deposit resource or withdraw resource; chọn items
    // resourceId != 0 => import from wallet
    // resource < 3 && isWithdraw => rút về ví
    // resource < 3 && !isWithdraw => add vào inventory
    // item < 3 check đk => add item vào inventory
    // nếu ko thì skip
    function choose(uint256 landId, uint256[] memory resource_, uint256[] memory item, uint256[] memory essence ) external nonReentrant whenNotPaused {
        (,bool fulfilled, uint256[] memory randomWords) = random.getRequestStatus(landRequests[landId].requestId);
        require(
            lands[msg.sender].contains(landId) &&
            fulfilled && 
            landRequests[landId].end == 0 &&
            manager.landInfos(landId).isPaid == 1, 
            "caller is not owner"
        );
        uint256 balanceEssence = manager.landInfos(landId).essenceToken;
        uint256 num = balanceEssence > 5 ? 5 : balanceEssence;
        require(
            resource_.length == landRequests[landId].numResource &&
            item.length == landRequests[landId].numItem && 
            essence.length == num,
            "invalid"
        );
        setLandRequest(landId, randomWords);
        address account = msg.sender;
        uint16[] memory rId; 
        uint16[] memory iId;
        uint16[] memory eId;
        RequestResult memory res = landRequests[landId];
        (bool check, uint256[] memory resources_) = checkResource(landId, resource_);
        uint256 landId_ = landId;
        if (check && resources_.length > 0) {
            rId = new uint16[](resources_.length);
            for (uint256 i = 0; i < resource_.length; i++) {
                if (resources_[i] < 50 && manager.landInfos(landId_).balance > prices.prices(res.resources[resources_[i]])) {
                    rId[i] = (res.resources[resources_[i]]);          
                    int256 payout  = ICoGResources(cogResources).resourcesInitPayout(uint8(rId[i]));
                    manager.addResource(landId_, rId[i], 1, payout, 0);
                    manager.updateBalance(landId_, prices.prices(res.resources[resources_[i]]), false);
                }
            }
        }        
        
        if (isShowItemShop(landId_)) {
            uint256[] memory item_ = getItemId(item);
            iId = new uint16[](item.length);
            for (uint256 i = 0; i < item.length; i++) {
                if (item_[i] < 50 && manager.landInfos(landId_).balance > prices.prices(res.items[item_[i]])) {
                    eId[i] = (res.items[item_[i]]);          
                    manager.addItem(landId_, iId[i], 0);                           
                    manager.updateBalance(landId_, prices.prices(res.items[item_[i]]), false);
                }
            }
        }
        if (isShowEssenceShop(landId_)) {
            uint256[] memory essence_ = getItemId(essence);
            eId = new uint16[](essence.length);
            for (uint256 i = 0; i < essence.length; i++) {
                if (essence_[i] < 50 && manager.landInfos(landId_).essenceToken > 0) {
                    eId[i] = (res.essences[essence_[i]]);          
                    manager.addItem(landId_, eId[i], 0);
                    manager.updateBalance(landId_, 1, false);
                }
            }
        }
        landRequests[landId_].end = 1;
        emit BoughtFromShop(account, landId_, rId, iId, eId); 
    }

    function checkResource(uint256 landId, uint256[] memory resource_) public view returns (bool, uint256[] memory) {
        RequestResult memory res = landRequests[landId];
        uint256[] memory rId;
        uint256 total;
        uint256 count;
        if (res.must == 2) {
            return (true, rId);
        }
        rId = new uint256[](resource_.length);
        if (res.shop2Resource == 1) {
            if (resource_[0] < 2) {
                rId[0] =  resource_[0];
                total += 1;
            } else {
                rId[0] = 50;
            }             
            count += 2;
        } else if (res.shop2Resource == 0) {
            if (resource_[0] < 3) {
                rId[0] =  resource_[0];
                total += 1;
            } else {
                rId[0] = 50;
            }
            count += 3;
        }
        for (uint256 i = 1; i < resource_.length; i++) {
            if (resource_[i] < 3) {
                rId[i] =  count + resource_[i];
                total += 1;
            } else {
                rId[i] =  50;
            }
            count += 3;
        }
        if (res.must == 1 && total == 0) {
            return (false, rId);
        }
        return (true, rId);
    }

    function getItemId(uint256[] memory item) public pure returns (uint256[] memory) {
        uint256[] memory iId;
        iId = new uint256[](item.length);
        for (uint256 i = 0; i < item.length; i++) {
            if (item[i] < 3) {
                iId[i] =  i * 3 + item[i];
            } else {
                iId[i] =  50;
            }
        }
        return (iId);
    }

    function withdrawToken(uint256 landId, address to, uint256 amount) external nonReentrant whenNotPaused {
        require(landId != 0 && lands[msg.sender].contains(landId) && manager.landInfos(landId).currentNumber == 0, "caller is not owner");
        uint256 balance = manager.landInfos(landId).balance;
        require(balance >= amount, "exceed balance");
        manager.updateBalance(landId, amount, false);
        SafeToken.safeTransfer(address(token), to, amount * 1e18);
    }

    function withdrawLand(uint256 landId) external nonReentrant whenNotPaused {
        require(landId != 0 && lands[msg.sender].contains(landId), "caller is not owner");
        address account = msg.sender;
        lands[account].remove(landId);
        land.safeTransferFrom(address(this), account, landId);
        emit LandWithdrew(account, landId);
    }

    function setRarity(uint256 level, uint256[8] memory rate) external onlyOwner {
        for (uint256 i = 0; i < 8; i++) {
            rarities[level][i + 1] = rate[i];
        }
    }

    function setGameController(address controller_) public onlyOwner {
        gameController = IGameController(controller_);
    }

    function setCoGResource(address cog) external onlyOwner {
        cogResources = cog;
    }

    function ownerOfLand(address account, uint256 landId) external override view returns (bool) {
        return landId != 0 && lands[account].contains(landId);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawEmergency(address token_, address to, uint256 value) external onlyOwner {
        SafeToken.safeTransfer(token_, to, value);
    }

    uint256[47] private __gap;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface IGameController {
    function executeGame(
        uint256 id,
        uint256[20] memory position,
        uint256 randomNumber
    ) external returns (uint8 numResouce,uint8 numItem,uint8 shop2Resource, uint8 must, uint8 option, uint16 ration, uint256 coin);

    function findPosition(
        uint256 id,
        uint256 resourceId
    ) external view returns (uint16[] memory);

    function atPosition(uint256, uint256) external view returns (uint256);

    function countResource(uint256, uint256) external view returns (uint256);

    function updatePayout(
        uint256 id,
        uint16 position,
        int256 mul,
        int256 divide,
        int256 add
    ) external;

    function updateProp(uint256, uint256, uint256) external;

    function getProp(uint256, uint256) external view returns (uint256);

    function getPayout(uint256, uint256) external view returns (int256);

    function getInitialPayout(uint256) external view returns (int256);

    function getIndex(
        uint256 id,
        uint256 position
    ) external view returns (uint256);

    function updateMap(
        uint256 id,
        uint256 position,
        uint256 oldResourceId,
        uint256 newResourceId
    ) external;

    function updateNewAddedResource(uint256 id) external;

    function getCountAddedNewRes(uint256 id) external view returns (uint256);

    function getTotalCountResource(uint256 id) external view returns (uint256);

    function getQuantityResource(
        uint256 id,
        uint256 index
    ) external view returns (uint256, uint256);

    function getDestroyPosition(uint256 id) external returns (uint256[] memory);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ICoGItems {
    function getCategory(
        string memory sort
    ) external view returns (uint256[] memory items);

    function getCategory16(
        string memory sort
    ) external view returns (uint16[] memory items);

    function contains(string memory sort, uint256 itemsId)
        external
        view
        returns (bool);

    function categoryLength(string memory sort) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ICoGResources {
    function ResourcesToString(uint8) external view returns (string memory);

    function resourcesInitPayout(uint8) external view returns (int256);

    function getCategory(
        string memory sort
    ) external view returns (uint256[] memory resources);

    function getCategory16(
        string memory sort
    ) external view returns (uint16[] memory resources);

    function contains(string memory sort, uint256 resource)
        external
        view
        returns (bool);

    function at(string memory sort, uint256 index)
        external
        view
        returns (uint256);

    function categoryLength(string memory sort) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
}

library SafeToken {
    function myBalance(address token) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(address(this));
    }

    function balanceOf(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeApprove");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransferFrom");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "!safeTransferETH");
    }
}