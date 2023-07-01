// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

/* solhint-disable no-console */
/* solhint-disable reason-string */
/* solhint-disable no-global-import */
/* solhint-disable no-console */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol';
import '../interfaces/ITranchePool.sol';
import '../interfaces/IRMWNft.sol';
import '../libraries/dsMath.sol';
import '../storage/TranchePoolStorage.sol';

//                                    ('-.      (`\ .-') /`  ('-.     .-') _    .-') _
//                                   ( OO ).-.   `.( OO ),' ( OO ).-.(  OO) )  (  OO) )
//   ,----.     ,-.-')   ,----.      / . --. /,--./  .--.   / . --. //     '._ /     '._
//  '  .-./-')  |  |OO) '  .-./-')   | \-.  \ |      |  |   | \-.  \ |'--...__)|'--...__)
//  |  |_( O- ) |  |  \ |  |_( O- ).-'-'  |  ||  |   |  |,.-'-'  |  |'--.  .--''--.  .--'
//  |  | .--, \ |  |(_/ |  | .--, \ \| |_.'  ||  |.'.|  |_)\| |_.'  |   |  |      |  |
// (|  | '. (_/,|  |_.'(|  | '. (_/  |  .-.  ||         |   |  .-.  |   |  |      |  |
//  |  '--'  |(_|  |    |  '--'  |   |  | |  ||   ,'.   |   |  | |  |   |  |      |  |
//   `------'   `--'     `------'    `--' `--''--'   '--'   `--' `--'   `--'      `--'

contract TranchePool is ITranchePool, TrancheStorage, OwnableUpgradeable, ERC721Upgradeable, ERC1155HolderUpgradeable {
  using DSMath for uint256;

  function initiatePool(
    uint256 _rmwNFTId,
    address _RMWContract,
    address _asset,
    uint64 _maxNumberOfEpoch,
    uint64 _durationOfEpoch,
    uint64 _borrowTimeLimit,
    uint128 _percentageForReserves,
    uint256 _totalAmountOfInvestment,
    uint256 _seniorMonthlyRate,
    uint256 _juniorMonthlyRate,
    address owner
  ) external override(ITranchePool) initializer {
    __Ownable_init();
    __ERC721_init('Gigawatt Tranche Pool', 'GPT');
    __ERC1155Holder_init();
    transferOwnership(owner);
    IERC1155Upgradeable(_RMWContract).safeTransferFrom(msg.sender, address(this), _rmwNFTId, 1, '0x');
    pool.rmwID = _rmwNFTId;
    pool.asset = _asset;
    pool.totalAmountOfInvestment = _totalAmountOfInvestment;
    pool.percentageForReserves = _percentageForReserves;
    pool.maxNumberOfEpoch = _maxNumberOfEpoch;
    pool.durationOfEpoch = _durationOfEpoch;
    pool.seniorMonthlyRate = _seniorMonthlyRate;
    pool.juniorMonthlyRate = _juniorMonthlyRate;
    pool.RMWContract = _RMWContract;
    pool.borrowTimeLimit = _borrowTimeLimit; // TODO: add checks in consecutive functions
    epochs[epochCounter].startingBlockTimestamp = block.timestamp;
  }

  function getMaxRedeemAmount() public view override(ITranchePool) returns (uint256) {
    return globalTrancheDetails.totalBalance - globalTrancheDetails.totalBorrowed;
  }

  // DEPOSIT RELATED FUNCTIONS

  /// @notice if space available then investment goes through otherwise investment put into queue
  function investSenior(uint256 amount) external override(ITranchePool) {
    _invest(amount, msg.sender, true);
    emit InvestSenior(amount);
  }

  /// @notice if space available then investment goes through otherwise investment put into queue
  function investJunior(uint256 amount) external override(ITranchePool) {
    _invest(amount, msg.sender, false);
    emit InvestJunior(amount);
  }

  function _invest(
    uint256 amount,
    address account,
    bool isSeniorTranche
  ) private {
    require(amount > 0, 'Amount cannot be 0');
    require(epochCounter <= pool.maxNumberOfEpoch, 'Max number of epochs reached');
    // require(whitelistedAsset[.asset] != 0, 'Asset Not whitelisted for use');

    Tranche memory tranche = isSeniorTranche ? accounts[account].seniorTranche : accounts[account].juniorTranche;

    if (tranche.amount != 0) {
      uint256 interest = calculateInterestEarned(isSeniorTranche, account);

      isSeniorTranche ? pendingClaimRequestSenior[account].amount += interest : pendingClaimRequestJunior[account].amount += interest;
    }

    tranche.account = account;
    tranche.profitsEpoch = epochCounter;

    if (pool.totalAmountOfInvestment >= globalTrancheDetails.totalBalance + amount) {
      tranche.amount += amount;

      if (isSeniorTranche) {
        accounts[account].seniorTranche = tranche;
        epochs[epochCounter].totalAmountSeniorDeposits += amount;
      } else {
        accounts[account].juniorTranche = tranche;
        epochs[epochCounter].totalAmountJuniorDeposits += amount;
      }

      globalTrancheDetails.totalBalance += amount; // TODO: scale to 18 decimals

      _mint(account, ++globalTrancheDetails.tokenId);
    } else {
      uint256 amountToBePutInQueue = globalTrancheDetails.totalBalance + amount - pool.totalAmountOfInvestment;
      tranche.amount += amount - amountToBePutInQueue;
      tranche.pendingSwap += amountToBePutInQueue;

      if (isSeniorTranche) {
        epochs[epochCounter].totalAmountSeniorDeposits += amount - amountToBePutInQueue;
        accounts[account].seniorTranche = tranche;

        seniorWaitingQueue.push(tranche);
      } else {
        epochs[epochCounter].totalAmountJuniorDeposits += amount - amountToBePutInQueue;
        accounts[account].juniorTranche = tranche;
        juniorWaitingQueue.push(tranche);
      }

      _mint(account, ++globalTrancheDetails.tokenId);
      globalTrancheDetails.totalBalance += amount - amountToBePutInQueue;
    }
    require(IERC20Upgradeable(pool.asset).transferFrom(account, address(this), amount), 'ERC20 transfer fail');
  }

  // REDEEM RELATED FUNCTIONS

  function queueRedeem(uint256 amount, bool isSeniorPool) external override(ITranchePool) {
    Tranche storage tranche = isSeniorPool ? accounts[msg.sender].seniorTranche : accounts[msg.sender].juniorTranche;
    require(amount <= tranche.amount, 'Amount to redeem exceeds balance');
    tranche.amount -= amount;
    tranche.amountToRedeem = amount;
    emit QueueRedeem(amount, isSeniorPool);
  }

  function cancelRedeem(uint256 amount, bool isSeniorPool) external override(ITranchePool) {
    Tranche storage tranche = isSeniorPool ? accounts[msg.sender].seniorTranche : accounts[msg.sender].juniorTranche;
    require(amount <= tranche.amountToRedeem, 'Amount to reduce exceeds queue');
    tranche.amountToRedeem -= amount;
    emit CancelRedeem(amount, isSeniorPool);
  }

  function redeem(bool isSeniorPool) external override(ITranchePool) {
    Tranche storage tranche = isSeniorPool ? accounts[msg.sender].seniorTranche : accounts[msg.sender].juniorTranche;
    require(tranche.amountToRedeem > 0, 'Amount invalid');

    claim(isSeniorPool); // so that new claim starts with new amount from this epoch
    _orderRedemption(msg.sender, isSeniorPool);
    emit Redeem(isSeniorPool);
  }

  function rollOverEpoch() external override(ITranchePool) {
    require(epochs[epochCounter].startingBlockTimestamp + pool.durationOfEpoch > block.timestamp, 'Epoch has not ended');

    require(pool.maxNumberOfEpoch + 1 >= epochCounter, 'Max number of epochs reached');
    /// @review security issues ?
    epochCounter++;
    epochs[epochCounter].startingBlockTimestamp = block.timestamp;
    epochs[epochCounter].totalAmountSeniorDeposits = epochs[epochCounter - 1].totalAmountSeniorDeposits;
    epochs[epochCounter].totalAmountJuniorDeposits = epochs[epochCounter - 1].totalAmountJuniorDeposits;
    epochs[epochCounter].totalAmountBorrowed = epochs[epochCounter - 1].totalAmountBorrowed;
  }

  // BORROW RELATED FUNCTIONS

  //  borrow using a minted nft called by the borrow account / NFT contract
  function postBorrowNFT(address _account, uint256 _tokenId) external override(ITranchePool) {
    require(msg.sender == pool.RMWContract, 'Sender not RMW contract');
    Account memory account = accounts[_account];
    require(account.borrowId == 0, 'Already a borrow request in progress');
    uint256 amount = IRMWNft(msg.sender).getBorrowNFT(_tokenId).amount;
    require(amount <= pool.totalAmountOfInvestment, 'Exceeds allowed investment cap');
    account.borrowAmount = amount;
    account.borrowId = _tokenId;

    accounts[_account] = account;

    IERC1155Upgradeable(msg.sender).safeTransferFrom(_account, address(this), _tokenId, 1, '0x');
    emit PostBorrowNFT(_account, _tokenId);
  }

  /// @notice claim can be partial or complete
  function claimBorrowAmount() external override(ITranchePool) {
    _claimBorrowAmount(msg.sender);
    emit ClaimBorrowAmount();
  }

  function claimOnBehalfAmount(address _account) external override(ITranchePool) {
    require(hasDelegated[_account] == msg.sender, 'Not delegated');
    _claimBorrowAmount(_account);
    emit ClaimOnBehalfAmount(_account);
  }

  function repayBorrowAmount(uint256 amount) external override(ITranchePool) {
    _repayBorrowAmount(amount);
    emit RepayBorrowAmount(amount);
  }

  function repayOnBehalfAmount(address _account, uint256 amount) external override(ITranchePool) {
    require(hasDelegated[_account] == msg.sender, 'Not delegated');
    _repayBorrowAmount(amount);
    emit RepayOnBehalfAmount(_account, amount);
  }

  function postProfits(uint256 amount) external override(ITranchePool) {
    Account storage account = accounts[msg.sender];
    require(account.borrowId != 0, 'No borrow token associated with this account');
    require(account.borrowAmountFinanced > 0, 'borrow claimed not done yet');
    require(account.epochBorrowed < epochCounter, 'Cannot post profits in the same epoch');

    uint256 srProfits = pool.seniorMonthlyRate.wmul(epochs[epochCounter - 1].totalAmountSeniorDeposits);

    if (srProfits > amount) {
      srProfits = amount;
    } else {
      epochs[epochCounter - 1].totalProfitsJunior += amount - srProfits;
      globalTrancheDetails.totalJuniorProfitsAvailable += amount - srProfits;
    }

    epochs[epochCounter - 1].totalProfitsSenior += srProfits;
    globalTrancheDetails.totalSeniorProfitsAvailable += srProfits;

    IERC20Upgradeable(pool.asset).transferFrom(msg.sender, address(this), amount);
    emit PostProfits(amount);
  }

  // TODO: combine this and the previous function using wrappers
  function postProfitsForOlderEpoch(uint256 amount, uint256 epoch) external override(ITranchePool) {
    Account storage account = accounts[msg.sender];
    require(account.borrowId != 0, 'No borrow token associated with this account');
    require(account.borrowAmountFinanced > 0, 'borrow claimed not done yet');
    require(account.epochBorrowed < epochCounter, 'Cannot post profits in the same epoch');

    uint256 srProfits = pool.seniorMonthlyRate.wmul(epochs[epoch].totalAmountSeniorDeposits);

    if (srProfits > amount) {
      srProfits = amount;
    } else {
      epochs[epoch].totalProfitsJunior += amount - srProfits;
      globalTrancheDetails.totalJuniorProfitsAvailable += amount - srProfits;
    }

    epochs[epoch].totalProfitsSenior += srProfits;
    globalTrancheDetails.totalSeniorProfitsAvailable += srProfits;

    IERC20Upgradeable(pool.asset).transferFrom(msg.sender, address(this), amount);
    emit PostProfitsForOlderEpoch(amount, epoch);
  }

  // PROFIT CLAIM FUNCTIONS

  /// @notice to claim profits made during the period
  function claim(bool isSeniorTranche) public {
    isSeniorTranche
      ? require(pendingClaimRequestSenior[msg.sender].amount == 0, 'Pending claim request')
      : require(pendingClaimRequestJunior[msg.sender].amount == 0, 'Pending claim request');

    uint256 amount = calculateInterestEarned(isSeniorTranche, msg.sender);

    Tranche storage tranche = isSeniorTranche ? accounts[msg.sender].seniorTranche : accounts[msg.sender].juniorTranche;

    _claim(msg.sender, amount, isSeniorTranche, epochCounter - 1); // gives airthmetic overflow error if first epoch ( acceptable since no profits made in first epoch so code has to break anyway )
    tranche.profitsEpoch = epochCounter;
  }

  function processPendingClaims(bool isSeniorTranche) external override(ITranchePool) {
    // condition to check new epoch hasn't started yet
    ClaimRequests storage request = isSeniorTranche ? pendingClaimRequestSenior[msg.sender] : pendingClaimRequestJunior[msg.sender];
    _claim(msg.sender, request.amount, isSeniorTranche, request.epoch);
    emit ProcessPendingClaims(isSeniorTranche);
  }

  function delegateBorrowRights(address addr) external override(ITranchePool) {
    hasDelegated[msg.sender] = addr;
    emit DelegateBorrowRights(addr);
  }

  // only owner?
  function annihilate() external override(ITranchePool) {
    require(pool.maxNumberOfEpoch * pool.durationOfEpoch < block.timestamp, 'NFT yet to expire');
    IRMWNft(pool.RMWContract).burnRMWNft(pool.rmwID);
    emit Annihilate();
  }

  function withdraw() external override(ITranchePool) {
    require(epochCounter > pool.maxNumberOfEpoch, 'Epoch not over yet');
    IERC20Upgradeable(pool.asset).transfer(msg.sender, accounts[msg.sender].seniorTranche.amount);
    IERC20Upgradeable(pool.asset).transfer(msg.sender, accounts[msg.sender].juniorTranche.amount);
    emit Withdraw();
  }

  // *****************
  // PRIVATE FUNCTIONS
  // *****************

  function _claim(
    address account,
    uint256 amount,
    bool isSeniorTranche,
    uint256 counter
  ) private {
    // if profits made are sufficient than posted, continue
    // else use profits avalaible first then reserve pool
    // if still redemption cannot be completed put the claim req in queue

    if (isSeniorTranche) {
      if (globalTrancheDetails.totalSeniorProfitsAvailable >= amount) {
        IERC20Upgradeable(pool.asset).transfer(account, amount);
        globalTrancheDetails.totalSeniorProfitsAvailable -= amount;
      } else if (globalTrancheDetails.totalSeniorProfitsAvailable + globalTrancheDetails.reservor >= amount) {
        IERC20Upgradeable(pool.asset).transfer(account, amount);

        globalTrancheDetails.reservor -= amount - globalTrancheDetails.totalSeniorProfitsAvailable;
        globalTrancheDetails.totalSeniorProfitsAvailable = 0;
      } else {
        IERC20Upgradeable(pool.asset).transfer(account, globalTrancheDetails.totalSeniorProfitsAvailable + globalTrancheDetails.reservor);

        pendingClaimRequestSenior[account] = ClaimRequests(
          amount - globalTrancheDetails.totalSeniorProfitsAvailable - globalTrancheDetails.reservor,
          counter
        );
        globalTrancheDetails.totalSeniorProfitsAvailable = 0;
        globalTrancheDetails.reservor = 0;
      }
    } else {
      if (globalTrancheDetails.totalJuniorProfitsAvailable >= amount) {
        IERC20Upgradeable(pool.asset).transfer(account, amount);
        globalTrancheDetails.totalJuniorProfitsAvailable -= amount;
      } else if (globalTrancheDetails.totalJuniorProfitsAvailable + globalTrancheDetails.reservor >= amount) {
        IERC20Upgradeable(pool.asset).transfer(account, amount);
        globalTrancheDetails.reservor -= amount - globalTrancheDetails.totalJuniorProfitsAvailable;
        globalTrancheDetails.totalJuniorProfitsAvailable = 0;
      } else {
        IERC20Upgradeable(pool.asset).transfer(account, globalTrancheDetails.totalJuniorProfitsAvailable + globalTrancheDetails.reservor);
        pendingClaimRequestJunior[account] = ClaimRequests(
          amount - globalTrancheDetails.totalJuniorProfitsAvailable - globalTrancheDetails.reservor,
          counter
        );
        globalTrancheDetails.totalJuniorProfitsAvailable = 0;
        globalTrancheDetails.reservor = 0;
      }
    }
  }

  function withdrawFromQueue(
    uint256 amount,
    bool isSeniorPool,
    uint256 index
  ) external {
    if (isSeniorPool) {
      Tranche storage tranche = accounts[msg.sender].seniorTranche;
      require(tranche.pendingSwap >= amount, 'Amount exceeds pending swap');
      tranche.pendingSwap -= amount;
      delete seniorWaitingQueue[index];
      IERC20Upgradeable(pool.asset).transfer(msg.sender, amount);
    } else {
      Tranche storage tranche = accounts[msg.sender].juniorTranche;
      require(tranche.pendingSwap >= amount, 'Amount exceeds pending swap');
      tranche.pendingSwap -= amount;
      delete juniorWaitingQueue[index];
      IERC20Upgradeable(pool.asset).transfer(msg.sender, amount);
    }
  }

  /// @notice function that uses FIFO
  /// @return amountCouldNotBeAccomodated The amount that couldn't be filled ( fitted into the sack ) i.e. partial redemption. This amount is rolled over to next epoch.
  function _orderRedemption(address account, bool isSeniorPool) private returns (uint256 amountCouldNotBeAccomodated) {
    if (isSeniorPool) {
      Tranche storage srTranche = accounts[account].seniorTranche;
      while (true) {
        if (seniorQueueCounter >= seniorWaitingQueue.length) {
          amountCouldNotBeAccomodated = srTranche.amountToRedeem;
          break;
        }

        Tranche storage queuedAccount = seniorWaitingQueue[seniorQueueCounter]; // not efficient approach
        _claim(queuedAccount.account, queuedAccount.amount, true, epochCounter - 1);
        queuedAccount.profitsEpoch = epochCounter;

        if (srTranche.amountToRedeem > queuedAccount.pendingSwap) {
          IERC20Upgradeable(pool.asset).transfer(account, queuedAccount.pendingSwap);
          queuedAccount.amount += queuedAccount.pendingSwap;
          srTranche.amountToRedeem -= queuedAccount.pendingSwap;
          queuedAccount.pendingSwap = 0;
          accounts[queuedAccount.account].seniorTranche = queuedAccount;
          delete seniorWaitingQueue[seniorQueueCounter];
          seniorQueueCounter++;
          continue;
        } else if (srTranche.amountToRedeem == queuedAccount.pendingSwap) {
          IERC20Upgradeable(pool.asset).transfer(account, queuedAccount.pendingSwap);
          queuedAccount.amount += queuedAccount.pendingSwap;
          srTranche.amountToRedeem = 0;
          queuedAccount.pendingSwap = 0;
          accounts[queuedAccount.account].seniorTranche = queuedAccount;
          delete seniorWaitingQueue[seniorQueueCounter];
          if (srTranche.amount == 0) delete accounts[account].seniorTranche;
          seniorQueueCounter++;
          break;
        } else {
          IERC20Upgradeable(pool.asset).transfer(account, srTranche.amountToRedeem);
          queuedAccount.amount += srTranche.amountToRedeem;
          queuedAccount.pendingSwap -= srTranche.amountToRedeem;
          srTranche.amountToRedeem = 0;
          accounts[queuedAccount.account].seniorTranche = queuedAccount;
          if (srTranche.amount == 0) delete accounts[account].seniorTranche;
          break;
        }
      }
    } else {
      Tranche storage jrTranche = accounts[account].juniorTranche;
      while (true) {
        if (juniorQueueCounter >= juniorWaitingQueue.length) {
          amountCouldNotBeAccomodated = jrTranche.amountToRedeem;
          break;
        }
        Tranche storage queuedAccount = juniorWaitingQueue[juniorQueueCounter];

        _claim(queuedAccount.account, queuedAccount.amount, false, epochCounter - 1);

        queuedAccount.profitsEpoch = epochCounter;

        if (jrTranche.amountToRedeem > queuedAccount.pendingSwap) {
          IERC20Upgradeable(pool.asset).transfer(account, queuedAccount.pendingSwap);
          _claim(queuedAccount.account, queuedAccount.amount, false, epochCounter - 1);
          queuedAccount.amount += queuedAccount.pendingSwap;
          jrTranche.amountToRedeem -= queuedAccount.pendingSwap;
          queuedAccount.pendingSwap = 0;
          accounts[queuedAccount.account].juniorTranche = queuedAccount;

          delete juniorWaitingQueue[juniorQueueCounter];
          juniorQueueCounter++;
          continue;
        } else if (jrTranche.amountToRedeem == queuedAccount.pendingSwap) {
          IERC20Upgradeable(pool.asset).transfer(account, queuedAccount.pendingSwap);
          _claim(queuedAccount.account, queuedAccount.amount, false, epochCounter - 1);
          queuedAccount.amount += queuedAccount.pendingSwap;

          jrTranche.amountToRedeem = 0;
          queuedAccount.pendingSwap = 0;
          accounts[queuedAccount.account].juniorTranche = queuedAccount;

          delete juniorWaitingQueue[juniorQueueCounter];
          if (jrTranche.amount == 0) delete accounts[account].juniorTranche;
          juniorQueueCounter++;
          break;
        } else {
          IERC20Upgradeable(pool.asset).transfer(account, jrTranche.amountToRedeem);
          _claim(queuedAccount.account, queuedAccount.amount, false, epochCounter - 1);
          queuedAccount.amount += jrTranche.amountToRedeem;
          queuedAccount.pendingSwap -= jrTranche.amountToRedeem;
          jrTranche.amountToRedeem = 0;
          accounts[queuedAccount.account].juniorTranche = queuedAccount;

          if (jrTranche.amount == 0) delete accounts[account].juniorTranche;
          break;
        }
      }
    }
  }

  function _claimBorrowAmount(address _account) private {
    Account memory account = accounts[_account];
    require(account.borrowId != 0, 'No borrow request in progress');
    require(account.borrowAmountFinanced != account.borrowAmount, 'Already claimed');
    require(IRMWNft(pool.RMWContract).getBorrowNFT(account.borrowId).period >= epochCounter - account.epochBorrowed, 'Invalid borrow amount');

    uint256 amountToBeBorrowed = account.borrowAmount - account.borrowAmountFinanced;

    uint256 amountForReserves = (amountToBeBorrowed).wmul(pool.percentageForReserves);

    amountToBeBorrowed -= amountForReserves;

    epochs[epochCounter].totalAmountBorrowed += amountToBeBorrowed;

    require(
      amountToBeBorrowed + amountForReserves <= pool.totalAmountOfInvestment - globalTrancheDetails.totalBorrowed,
      'excess borrowed amount expected'
    );

    globalTrancheDetails.reservor += amountForReserves;

    if (globalTrancheDetails.totalBalance - globalTrancheDetails.totalBorrowed >= amountToBeBorrowed) {
      IERC20Upgradeable(pool.asset).transfer(_account, amountToBeBorrowed);
      account.borrowAmountFinanced += amountToBeBorrowed;
      globalTrancheDetails.totalBorrowed += amountToBeBorrowed;
    } else {
      uint256 availableFunds = globalTrancheDetails.totalBalance - globalTrancheDetails.totalBorrowed;
      IERC20Upgradeable(pool.asset).transfer(_account, availableFunds);
      account.borrowAmountFinanced += availableFunds;
      globalTrancheDetails.totalBorrowed += availableFunds;
    }

    if (account.epochBorrowed == 0) account.epochBorrowed = epochCounter;

    accounts[_account] = account;
  }

  function _repayBorrowAmount(uint256 amount) private {
    require(amount > 0, 'Amount cannot be 0');
    Account memory account = accounts[msg.sender];

    require(account.borrowId != 0, 'Repayment for non existing borrow nft');
    require(account.epochBorrowed < epochCounter, 'Repayment in the same epoch not allowed');
    require(account.borrowAmountFinanced > 0, 'Already repaid or never took out a loan');

    IERC20Upgradeable(pool.asset).transferFrom(msg.sender, address(this), amount);
    account.amountRefinanced += amount;
    // TODO: add check to see if the monthly profits were posted or not
    if (
      account.amountRefinanced == account.borrowAmountFinanced
      // TODO: add additional condition to check if the time period for the nft has expired
    ) {
      IRMWNft(pool.RMWContract).repayBorrowedNFT(pool.rmwID, account.borrowId, msg.sender);
      if (globalTrancheDetails.reservor >= account.borrowAmount - account.borrowAmountFinanced)
        globalTrancheDetails.reservor -= account.borrowAmount - account.borrowAmountFinanced;
      else globalTrancheDetails.reservor = 0;
      account.borrowAmount = 0;
      account.borrowAmountFinanced = 0;
      account.borrowId = 0;
      account.epochBorrowed = 0;
    }

    accounts[msg.sender] = account;
  }

  // ****************
  // HELPER FUNCTIONS
  // ****************

  function calculateInterestEarned(bool isSeniorTranche, address account) public view override(ITranchePool) returns (uint256 interest) {
    if (isSeniorTranche) {
      Tranche storage tranche = accounts[account].seniorTranche;

      for (uint256 i = tranche.profitsEpoch; i < epochCounter; i++) {
        if (epochs[i].totalProfitsSenior == 0) {
          // this gets deducted from reservor
          uint256 _interest = pool.seniorMonthlyRate.wmul(tranche.amount);
          interest += _interest;
          continue;
        }

        if (epochs[i].totalAmountSeniorDeposits == 0) {
          break;
        }

        interest += epochs[i].totalProfitsSenior.wmul(tranche.amount).wdiv(epochs[i].totalAmountSeniorDeposits);
      }
    } else {
      Tranche storage tranche = accounts[account].juniorTranche;

      for (uint256 i = tranche.profitsEpoch; i < epochCounter; i++) {
        // if profits not posted, then the reserves are used to safe gaurd senior tranche
        if (epochs[i].totalProfitsJunior == 0) {
          continue;
        }

        if (epochs[i].totalAmountJuniorDeposits == 0) {
          break;
        }

        interest += epochs[i].totalProfitsJunior.wmul(tranche.amount).wdiv(epochs[i].totalAmountJuniorDeposits);
      }
    }
  }

  // function compareEpochProjection(uint256 _epoch, bool senior) external view returns (int256) {
  //   Epoch memory epoch = epochs[_epoch];
  //   if (senior) {
  //     uint256 estimatedInterest = epoch.totalAmountSeniorDeposits.wmul(pool.seniorMonthlyRate);
  //     return int256(epoch.totalProfitsSenior) - int256(estimatedInterest);
  //   } else {
  //     uint256 estimatedInterest = epoch.totalAmountJuniorDeposits.wmul(pool.juniorMonthlyRate);
  //     return int256(epoch.totalProfitsJunior) - int256(estimatedInterest);
  //   }
  // }

  // function getAPY(uint256 startEpoch, uint256 endEpoch, bool senior) public view override(ITranchePool) returns (uint256) {
  //   require(endEpoch > startEpoch, 'Invalid epoch values');
  //   uint256 amountEarned;
  //   for (uint256 i = startEpoch; i < endEpoch; i++) {
  //     if (senior && epochs[i].totalAmountSeniorDeposits != 0) {
  //       amountEarned += epochs[i].totalProfitsSenior.wdiv(epochs[i].totalAmountSeniorDeposits);
  //     }
  //     if (!senior && epochs[i].totalAmountJuniorDeposits != 0) {
  //       amountEarned += epochs[i].totalProfitsJunior.wdiv(epochs[i].totalAmountJuniorDeposits);
  //     }
  //   }
  //   return amountEarned / (endEpoch - startEpoch);
  // }

  function getBorrowTimeLimit() external view override(ITranchePool) returns (uint256) {
    return pool.borrowTimeLimit;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, ERC1155ReceiverUpgradeable) returns (bool) {
    return interfaceId == type(ERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
  }

  function setProfitsRate(uint256 seniorProfitsRate, uint256 juniorProfitsRate) external onlyOwner {
    pool.seniorMonthlyRate = seniorProfitsRate;
    pool.juniorMonthlyRate = juniorProfitsRate;
  }

  function setWhitelistAssetPrice(address asset, uint256 assetPrice) external onlyOwner {
    whitelistedAsset[asset] = assetPrice;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RMWNFTParams, BorrowNFTParams} from '../types/RmwNFTTypes.sol';

interface IRMWNft {
  /// @notice mints a new rmw token to create a pool
  /// @dev : params for sig to be defined by biz team
  function mintRmwNFT(RMWNFTParams calldata nft) external returns (uint256 tokenId);

  /// @notice mints a new rmw token to create a pool
  /// @dev : params for sig to be defined by biz team
  function mintRmwNFTAndGeneratePool(RMWNFTParams calldata nft) external returns (uint256 tokenId);

  /// @notice to mint a nft for the borrower to be put in pool as collateral
  function mintBorrowNFT(BorrowNFTParams calldata borrowNFT) external returns (uint256 tokenId);

  /// @notice to mint a nft for the borrower to be put in pool as collateral
  function mintBorrowNFTAndSendTheBorrowReq(BorrowNFTParams calldata borrowNFT) external returns (uint256 tokenId);

  /// @notice for the smart contract to call to legalise the payback of the borrowed money by burning the NFT
  function repayBorrowedNFT(
    uint256 rmwNFT,
    uint256 borrowNFTId,
    address user
  ) external;

  /// @notice to be called by SC to finish an investment period of a pool
  function burnRMWNft(uint256 rmwID) external;

  function getBorrowNFT(uint256 id) external view returns (BorrowNFTParams memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITranchePool {
  event InvestSenior(uint256 indexed amount);
  event InvestJunior(uint256 indexed amount);
  event QueueRedeem(uint256 indexed amount, bool indexed isSeniorPool);
  event CancelRedeem(uint256 indexed amount, bool indexed isSeniorPool);
  event Redeem(bool indexed isSeniorPool);
  event PostBorrowNFT(address indexed account, uint256 indexed tokenId);
  event PostProfits(uint256 indexed amount);
  event PostProfitsForOlderEpoch(uint256 indexed amount, uint256 indexed epoch);
  event ClaimBorrowAmount();
  event ClaimOnBehalfAmount(address indexed account);
  event ProcessPendingClaims(bool indexed isSeniorTranche);
  event RepayBorrowAmount(uint256 indexed amount);
  event RepayOnBehalfAmount(address indexed account, uint256 indexed amount);
  event DelegateBorrowRights(address indexed addr);
  event Annihilate();
  event Withdraw();

  // called be pool creator or nft contract
  function initiatePool(
    uint256 _rmwNFTId,
    address _RMWContract,
    address _asset,
    uint64 _maxNumberOfEpoch,
    uint64 _durationOfEpoch,
    uint64 _borrowTimeLimit,
    uint128 _percentageForReserves,
    uint256 _totalAmountOfInvestment,
    uint256 _seniorMonthlyRate,
    uint256 _juniorMonthlyRate,
    address owner
  ) external;

  /// @notice if space available then investment goes through otherwise investment put into queue
  function investSenior(uint256 amount) external;

  /// @notice if space available then investment goes through otherwise investment put into queue
  function investJunior(uint256 amount) external;

  function queueRedeem(uint256 amount, bool isSeniorPool) external;

  function cancelRedeem(uint256 amount, bool isSeniorPool) external;

  function redeem(bool isSeniorPool) external;

  function rollOverEpoch() external;

  // // initiate a redeem process to prevent funds to roll over into the next epoch
  // function initiateRedeem() external;

  // // get back your investment atnthe end of epoch ( profit projection made till this point are returned )
  // // if not possible, the req is transfered to the next epoc
  // function finaliseRedeem(uint256 amount) external;

  // // function which prioritise certain redeem req first in order to make sure the correct order of redemption goest through
  // // eg, sr > jr pool
  // function partialRedeem(uint256 amount) external;

  //  borrow using a minted nft called by the borrow user / NFT contract
  function postBorrowNFT(address _account, uint256 _tokenId) external;

  function postProfits(uint256 amount) external;

  function postProfitsForOlderEpoch(uint256 amount, uint256 epoch) external;

  function processPendingClaims(bool isSeniorTranche) external;

  function claimBorrowAmount() external;

  function claimOnBehalfAmount(address _account) external;

  function repayBorrowAmount(uint256 amount) external;

  function repayOnBehalfAmount(address _account, uint256 amount) external;

  function delegateBorrowRights(address addr) external;

  function calculateInterestEarned(bool isSeniorTranche, address account) external view returns (uint256 interest);

  // function getAPY(
  //   uint256 startEpoch,
  //   uint256 endEpoch,
  //   bool senior
  // ) external view returns (uint256);

  function getMaxRedeemAmount() external view returns (uint256);

  function getBorrowTimeLimit() external view returns (uint256);

  function annihilate() external;

  function withdraw() external;
}

pragma solidity ^0.8.0;

library DSMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, 'ds-math-add-overflow');
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, 'ds-math-sub-underflow');
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
  }

  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x <= y ? x : y;
  }

  function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x >= y ? x : y;
  }

  function imin(int256 x, int256 y) internal pure returns (int256 z) {
    return x <= y ? x : y;
  }

  function imax(int256 x, int256 y) internal pure returns (int256 z) {
    return x >= y ? x : y;
  }

  uint256 constant WAD = 10**18;
  uint256 constant RAY = 10**27;
  uint256 internal constant WAD_RAY_RATIO = 1e9;

  //rounds to zero if x*y < WAD / 2
  function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, y), WAD / 2) / WAD;
  }

  //rounds to zero if x*y < WAD / 2
  function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, y), RAY / 2) / RAY;
  }

  //rounds to zero if x*y < WAD / 2
  function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, WAD), y / 2) / y;
  }

  //rounds to zero if x*y < RAY / 2
  function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, RAY), y / 2) / y;
  }

  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;

    return add(halfRatio, a) / (WAD_RAY_RATIO);
  }

  function wadToRay(uint256 a) internal pure returns (uint256) {
    return mul(a, WAD_RAY_RATIO);
  }

  // This famous algorithm is called "exponentiation by squaring"
  // and calculates x^n with x as fixed-point and n as regular unsigned.
  //
  // It's O(log n), instead of O(n) for naive repeated multiplication.
  //
  // These facts are why it works:
  //
  //  If n is even, then x^n = (x^2)^(n/2).
  //  If n is odd,  then x^n = x * x^(n-1),
  //   and applying the equation for even x gives
  //    x^n = x * (x^2)^((n-1) / 2).
  //
  //  Also, EVM division is flooring and
  //    floor[(n-1) / 2] = floor[n / 2].
  //
  function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
      x = rmul(x, x);

      if (n % 2 != 0) {
        z = rmul(z, x);
      }
    }
  }
}

/* solhint-disable */
pragma solidity ^0.8.4;

import '../types/TranchePoolTypes.sol';

contract TrancheStorage {
  Pool internal pool;

  uint256 public epochCounter;

  TrancheDetails internal globalTrancheDetails;

  uint256 internal seniorQueueCounter;
  uint256 internal juniorQueueCounter;
  Tranche[] internal seniorWaitingQueue;
  Tranche[] internal juniorWaitingQueue;

  mapping(uint256 => Epoch) internal epochs;
  mapping(address => Account) public accounts;
  mapping(address => uint256) internal whitelistedAsset;
  mapping(address => address) internal hasDelegated;
  mapping(address => ClaimRequests) internal pendingClaimRequestSenior;
  mapping(address => ClaimRequests) internal pendingClaimRequestJunior;

  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct RMWNFTParams {
  uint256 latitude;
  uint256 longitude;
  uint256 area;
  uint256 cashFlowIncome;
  uint256 estimatedProjections;
  uint256 numberOfResidence;
  uint256 estimatedSalarySpendings;
  uint256 period;
  bytes sig; // null on input
  address signerAddress; // used to store the valid signer info, to be passed as Zero address from the user end
}

struct BorrowNFTParams {
  address issuer;
  bytes purpose;
  uint256 period; // number of epoch for the claim of nft to be valid
  uint256 amount;
  bytes signature;
  address signerAddress;
  uint256 rmwId;
  uint256 tokenId;
  bool expired; // TODO remove
  uint256 monthlyRate; // in ray, and param modified on monthly basis with proper signature
}

struct Pool {
  address RMWContract;
  address asset;
  uint256 rmwID;
  uint64 maxNumberOfEpoch;
  uint64 durationOfEpoch;
  uint64 borrowTimeLimit;
  uint128 totalAmountOfInvestment;
  uint128 percentageForReserves; // scaled to 10**18
  uint256 seniorMonthlyRate; // in RAD
  uint256 juniorMonthlyRate;
}

struct TrancheDetails {
  uint256 pendingAmount;
  uint256 totalBalance;
  uint256 totalBalanceSenior;
  uint256 totalBalanceJunior;
  uint256 totalNumberOfShares;
  uint256 seniorProfits;
  uint256 juniorProfits;
  uint256 totalBorrowed;
  uint256 tokenId;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct ClaimRequests {
  uint256 amount;
  uint256 epoch;
}

struct Tranche {
  uint256 amount;
  uint256 amountToRedeem;
  uint256 profitsEpoch; // starting epoch from which we start calculating profits
  uint256 pendingSwap;
  address account;
}

struct Account {
  Tranche seniorTranche;
  Tranche juniorTranche;
  uint256 borrowId;
  uint256 borrowAmount;
  uint256 borrowAmountFinanced;
  uint256 amountRefinanced;
  uint256 epochBorrowed; // for borrow nft to keep track of monthly project
}

struct Epoch {
  uint256 totalAmountSeniorDeposits;
  uint256 totalAmountJuniorDeposits;
  uint256 totalAmountBorrowed;
  uint256 startingBlockTimestamp;
  uint256 totalProfitsSenior;
  uint256 totalProfitsJunior;
}

struct Pool {
  address RMWContract;
  address asset;
  uint256 rmwID;
  uint64 seniorTrancheCap;
  uint64 maxNumberOfEpoch;
  uint64 durationOfEpoch;
  uint64 borrowTimeLimit;
  uint128 percentageForReserves; // scaled to 10**18
  uint256 totalAmountOfInvestment;
  uint256 seniorMonthlyRate; // in RAD
  uint256 juniorMonthlyRate;
}

struct TrancheDetails {
  uint256 pendingAmount;
  uint256 totalBalance;
  uint256 totalBorrowed;
  uint256 totalSeniorProfitsAvailable;
  uint256 totalJuniorProfitsAvailable;
  uint256 reservor;
  uint256 tokenId;
}