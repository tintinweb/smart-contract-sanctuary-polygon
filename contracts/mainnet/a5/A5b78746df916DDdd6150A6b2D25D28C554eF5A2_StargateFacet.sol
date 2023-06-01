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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

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
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

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
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
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
            return toHexString(value, Math.log256(value) + 1);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: CC BY-NC 2.0
pragma solidity ^0.8.0;

import {LibAdmin} from "../Libraries/LibAdmin.sol";
import {LibBridge, UserBridgeData, PaymentParameters, ILiFi, ILiFiDiamond, LibSwap, StargateData, Storage} from "../Libraries/LibBridge.sol";
import {IERC20} from "./../../Interfaces/IERC20.sol";

contract StargateFacet {
    bytes32 internal constant NAMESPACE = keccak256("com.cicleo.facets.bridge");
    //----Event----------------------------------------------//

    struct BridgePaymentSpec {
        uint256 destChainId;
        uint256 subscriptionManagerId;
        uint8 subscriptionId;
        uint256 price;
    }

    /// @notice Event when a user pays for a subscription (first time or even renewing)
    event PaymentBridgeSubscription(
        address indexed user,
        BridgePaymentSpec indexed info
    );

    //----Internal function with sign part----------------------------------------------//

    //-----Bridge thing internal function

    function paymentWithBridgeWithStargate(
        PaymentParameters memory paymentParams,
        address user,
        ILiFi.BridgeData memory _bridgeData,
        LibSwap.SwapData[] calldata _swapData,
        StargateData memory _stargateData
    ) internal {
        //Do token transfer from and check if the amount is correct
        LibBridge.tokenPayment(paymentParams, user, _bridgeData);

        require(msg.value == _stargateData.lzFee, "Error msg.value");

        //Bridge the call to LiFi
        if (_swapData.length > 0) {
            ILiFiDiamond(0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE)
                .swapAndStartBridgeTokensViaStargate{value: msg.value}(
                _bridgeData,
                _swapData,
                _stargateData
            );
        } else {
            ILiFiDiamond(0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE)
                .startBridgeTokensViaStargate{value: msg.value}(
                _bridgeData,
                _stargateData
            );
        }

        emit PaymentBridgeSubscription(
            user,
            BridgePaymentSpec(
                paymentParams.chainId,
                paymentParams.subscriptionManagerId,
                paymentParams.subscriptionId,
                paymentParams.priceInSubToken
            )
        );
    }

    /// @notice Function to pay subscription with any coin on another chain
    function payFunctionWithBridge(
        PaymentParameters memory paymentParams,
        ILiFi.BridgeData memory _bridgeData,
        LibSwap.SwapData[] calldata _swapData,
        StargateData memory _stargateData,
        address referral,
        uint256 duration,
        bytes calldata signature
    ) external payable {
        paymentParams.chainId = LibBridge.getChainID();

        //Remplace the destination call by our one
        _stargateData.callData = LibBridge.handleSubscriptionCallback(
            paymentParams,
            msg.sender,
            referral,
            signature,
            _stargateData.callData
        );

        LibBridge.setSubscriptionDuration(paymentParams, duration);

        paymentWithBridgeWithStargate(
            paymentParams,
            msg.sender,
            _bridgeData,
            _swapData,
            _stargateData
        );
    }

    function renewSubscriptionByBridge(
        PaymentParameters memory paymentParams,
        address user,
        ILiFi.BridgeData memory _bridgeData,
        LibSwap.SwapData[] calldata _swapData,
        StargateData memory _stargateData
    ) public payable {
        LibBridge.verifyRenew(paymentParams, user);

        //Remplace the destination call by our one
        _stargateData.callData = LibBridge.handleRenewCallback(
            paymentParams,
            user,
            _stargateData.callData
        );

        paymentWithBridgeWithStargate(
            paymentParams,
            user,
            _bridgeData,
            _swapData,
            _stargateData
        );
    }

    //----Diamond storage functions-------------------------------------//

    /// @dev fetch local storage
    function getStorage() private pure returns (Storage storage s) {
        bytes32 namespace = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}

// SPDX-License-Identifier: CC BY-NC 2.0
pragma solidity ^0.8.9;

import {ILiFi, StargateData, AmarokData} from "./../../Interfaces/ILiFi.sol";
import {LibSwap} from "./../../Interfaces/LibSwap.sol";

/// @notice Interface of the LiFi Diamond
interface ILiFiDiamond {
    function startBridgeTokensViaStargate(
        ILiFi.BridgeData memory _bridgeData,
        StargateData calldata _stargateData
    ) external payable;

    function swapAndStartBridgeTokensViaStargate(
        ILiFi.BridgeData memory _bridgeData,
        LibSwap.SwapData[] calldata _swapData,
        StargateData calldata _stargateData
    ) external payable;

    function startBridgeTokensViaAmarok(
        ILiFi.BridgeData calldata _bridgeData,
        AmarokData calldata _amarokData
    ) external payable;

    function swapAndStartBridgeTokensViaAmarok(
        ILiFi.BridgeData memory _bridgeData,
        LibSwap.SwapData[] calldata _swapData,
        AmarokData calldata _amarokData
    ) external payable;

    function validateDestinationCalldata(
        bytes calldata data,
        bytes calldata dstCalldata
    ) external pure returns (bool isValid);
}

// SPDX-License-Identifier: CC BY-NC 2.0
pragma solidity ^0.8.0;

import {IDiamondCut} from "./../../../Diamond/Interfaces/IDiamondCut.sol";
import {CicleoSubscriptionFactory, CicleoSubscriptionSecurity} from "../../SubscriptionFactory.sol";

library LibAdmin {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("com.cicleo.facets.admin");

    struct DiamondStorage {
        CicleoSubscriptionFactory factory;
        mapping(uint256 => uint8) subscriptionNumber;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function isContractOwner(
        address user,
        uint256 subscriptionManagerId
    ) internal view returns (bool isOwner) {
        isOwner = diamondStorage().factory.verifyIfOwner(
            user,
            subscriptionManagerId
        );
    }

    function enforceIsOwnerOfSubManager(
        uint256 subscriptionManagerId
    ) internal view {
        require(
            isContractOwner(msg.sender, subscriptionManagerId),
            "LibAdmin: Must hold ownerpass for this submanager"
        );
    }

    function ids(uint256 id) internal view returns (address) {
        return diamondStorage().factory.ids(id);
    }

    function security() internal view returns (CicleoSubscriptionSecurity) {
        return diamondStorage().factory.security();
    }

    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}

// SPDX-License-Identifier: CC BY-NC 2.0
pragma solidity ^0.8.0;

import {IERC20} from "./../../Interfaces/IERC20.sol";
import {ILiFi, StargateData, AmarokData} from "./../../Interfaces/ILiFi.sol";
import {LibSwap} from "./../../Interfaces/LibSwap.sol";
import {BridgeFacet} from "../../Router/Facets/BridgeFacet.sol";
import {ILiFiDiamond} from "../Interfaces/ILiFiDiamond.sol";

struct PaymentParameters {
    uint256 chainId;
    uint256 subscriptionManagerId;
    uint8 subscriptionId;
    uint256 priceInSubToken;
    IERC20 token;
}

struct UserBridgeData {
    /// @notice last payment in timestamp to define when bot can take in the account
    uint256 nextPaymentTime;
    /// @notice Duration of the sub in secs
    uint256 subscriptionDuration;
    /// @notice Limit in subtoken
    uint256 subscriptionLimit;
}

struct Storage {
    mapping(uint256 => mapping(uint256 => mapping(address => UserBridgeData))) users;
}

library LibBridge {
    bytes32 internal constant NAMESPACE = keccak256("com.cicleo.facets.bridge");

    /// @notice Get chain id of the smartcontract
    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function tokenPayment(
        PaymentParameters memory paymentParams,
        address user,
        ILiFi.BridgeData memory _bridgeData
    ) internal {
        require(
            getStorage()
            .users[paymentParams.chainId][paymentParams.subscriptionManagerId][
                msg.sender
            ].subscriptionLimit >= paymentParams.priceInSubToken,
            "Amount too high"
        );

        uint256 balanceBefore = paymentParams.token.balanceOf(address(this));

        paymentParams.token.transferFrom(
            user,
            address(this),
            _bridgeData.minAmount
        );

        getStorage()
        .users[paymentParams.chainId][paymentParams.subscriptionManagerId][user]
            .nextPaymentTime =
            block.timestamp +
            getStorage()
            .users[paymentParams.chainId][paymentParams.subscriptionManagerId][
                user
            ].subscriptionDuration;

        //Verify if we received correct amount of token
        require(
            paymentParams.token.balanceOf(address(this)) - balanceBefore >=
                _bridgeData.minAmount,
            "Transfer failed"
        );

        //Approve the LiFi Diamond to spend the token
        paymentParams.token.approve(
            0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE,
            _bridgeData.minAmount
        );
    }

    /// @notice Encode the destination calldata
    /// @param user User to pay the subscription
    /// @param signature Signature of the user
    function getSubscribeDestinationCalldata(
        PaymentParameters memory paymentParams,
        address user,
        address referral,
        bytes memory signature
    ) public pure returns (bytes memory) {
        bytes4 selector = BridgeFacet.bridgeSubscribe.selector;
        return
            abi.encodeWithSelector(
                selector,
                paymentParams,
                user,
                referral,
                signature
            );
    }

    /// @notice Encode the destination calldata
    /// @param user User to pay the subscription
    /// @param subManagerId Id of the submanager
    function getRenewDestinationCalldata(
        address user,
        uint256 subManagerId
    ) internal pure returns (bytes memory) {
        bytes4 selector = BridgeFacet.bridgeRenew.selector;
        return abi.encodeWithSelector(selector, subManagerId, user);
    }

    /// @notice Change the destination call from LiFi parameter
    /// @param originalCalldata Original calldata
    /// @param dstCalldata Destination calldata
    /// @return finalCallData New calldata
    function changeDestinationCalldata(
        bytes memory originalCalldata,
        bytes memory dstCalldata
    ) internal pure returns (bytes memory finalCallData) {
        (
            uint256 txId,
            LibSwap.SwapData[] memory swapData,
            address assetId,
            address receiver
        ) = abi.decode(
                originalCalldata,
                (uint256, LibSwap.SwapData[], address, address)
            );
        //Change the last call data
        swapData[swapData.length - 1].callData = dstCalldata;

        return abi.encode(txId, swapData, assetId, receiver);
    }

    function handleSubscriptionCallback(
        PaymentParameters memory paymentParams,
        address user,
        address referral,
        bytes memory signature,
        bytes memory originalCalldata
    ) internal pure returns (bytes memory) {
        return
            changeDestinationCalldata(
                originalCalldata,
                getSubscribeDestinationCalldata(
                    paymentParams,
                    user,
                    referral,
                    signature
                )
            );
    }

    function handleRenewCallback(
        PaymentParameters memory paymentParams,
        address user,
        bytes memory originalCalldata
    ) internal pure returns (bytes memory) {
        return
            changeDestinationCalldata(
                originalCalldata,
                getRenewDestinationCalldata(
                    user,
                    paymentParams.subscriptionManagerId
                )
            );
    }

    function verifyRenew(
        PaymentParameters memory paymentParams,
        address user
    ) internal view {
        require(
            getStorage()
            .users[paymentParams.chainId][paymentParams.subscriptionManagerId][
                user
            ].nextPaymentTime < block.timestamp,
            "Subscription is not expired"
        );
    }

    function setSubscriptionDuration(
        PaymentParameters memory paymentParams,
        uint256 duration
    ) internal {
        getStorage()
        .users[paymentParams.chainId][paymentParams.subscriptionManagerId][
            msg.sender
        ].subscriptionDuration = duration;
    }

    //----Diamond storage functions-------------------------------------//

    /// @dev fetch local storage
    function getStorage() private pure returns (Storage storage s) {
        bytes32 namespace = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}

// SPDX-License-Identifier: CC BY-NC 2.0
pragma solidity ^0.8.9;

interface ICicleoSubscriptionRouter {
    function taxAccount() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the token decimal count.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct StargateData {
    uint256 dstPoolId;
    uint256 minAmountLD;
    uint256 dstGasForCall;
    uint256 lzFee;
    address payable refundAddress;
    bytes callTo;
    bytes callData;
}

/// @param callData The data to execute on the receiving chain. If no crosschain call is needed, then leave empty.
/// @param callTo The address of the contract on dest chain that will receive bridged funds and execute data
/// @param relayerFee The amount of relayer fee the tx called xcall with
/// @param slippageTol Max bps of original due to slippage (i.e. would be 9995 to tolerate .05% slippage)
/// @param delegate Destination delegate address
/// @param destChainDomainId The Amarok-specific domainId of the destination chain
struct AmarokData {
    bytes callData;
    address callTo;
    uint256 relayerFee;
    uint256 slippageTol;
    address delegate;
    uint32 destChainDomainId;
}

interface ILiFi {
    /// Structs ///

    struct BridgeData {
        bytes32 transactionId;
        string bridge;
        string integrator;
        address referrer;
        address sendingAssetId;
        address receiver;
        uint256 minAmount;
        uint256 destinationChainId;
        bool hasSourceSwaps;
        bool hasDestinationCall;
    }

    /// Events ///

    event LiFiTransferStarted(ILiFi.BridgeData bridgeData);

    event LiFiTransferCompleted(
        bytes32 indexed transactionId,
        address receivingAssetId,
        address receiver,
        uint256 amount,
        uint256 timestamp
    );

    event LiFiTransferRecovered(
        bytes32 indexed transactionId,
        address receivingAssetId,
        address receiver,
        uint256 amount,
        uint256 timestamp
    );

    event LiFiGenericSwapCompleted(
        bytes32 indexed transactionId,
        string integrator,
        string referrer,
        address receiver,
        address fromAssetId,
        address toAssetId,
        uint256 fromAmount,
        uint256 toAmount
    );

    // Deprecated but kept here to include in ABI to parse historic events
    event LiFiSwappedGeneric(
        bytes32 indexed transactionId,
        string integrator,
        string referrer,
        address fromAssetId,
        address toAssetId,
        uint256 fromAmount,
        uint256 toAmount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library LibSwap {
    struct SwapData {
        address callTo;
        address approveTo;
        address sendingAssetId;
        address receivingAssetId;
        uint256 fromAmount;
        bytes callData;
        bool requiresDeposit;
    }
}

// SPDX-License-Identifier: CC BY-NC 2.0
pragma solidity ^0.8.0;

import {CicleoSubscriptionManager} from "./../../SubscriptionManager.sol";
import {LibAdmin} from "../Libraries/LibAdmin.sol";
import {LibPayment} from "../Libraries/LibPayment.sol";
import {LibSubscriptionTypes} from "../Libraries/LibSubscriptionTypes.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {IERC20} from "./../../Interfaces/IERC20.sol";

struct PaymentParameters {
    uint256 chainId;
    uint256 subscriptionManagerId;
    uint8 subscriptionId;
    uint256 priceInSubToken;
    IERC20 token;
}

contract BridgeFacet {
    bytes32 internal constant NAMESPACE = keccak256("com.cicleo.facets.bridge");

    struct Storage {
        /// @notice Mapping to store the nonce of each tx per user
        mapping(address => uint256) userNonce;
    }

    //-----------Modifier---------------------------------------------//

    modifier onlyBot() {
        require(msg.sender == LibPayment.getBotAccount(), "Only bot");
        _;
    }

    //----Event----------------------------------------------//

    /// @notice Event when a user pays for a subscription (first time or even renewing)
    event PaymentSubscription(
        uint256 indexed subscriptionManagerId,
        address indexed user,
        uint8 indexed subscriptionId,
        uint256 price
    );

    /// @notice Event when a user subscription state is changed (after a payment or via an admin)
    event UserEdited(
        uint256 indexed subscriptionManagerId,
        address indexed user,
        uint8 indexed subscriptionId,
        uint256 endDate
    );

    /// @notice Event when an user select a token to pay for his subscription (when he pay first time to then store the selected coin)
    event SelectToken(
        uint256 indexed SubscriptionManagerId,
        address indexed user,
        address indexed tokenAddress
    );

    /// @notice Event when an user pay for his subscription (when he pay first time  or renew to store on what chain renew)
    event SelectBlockchain(
        uint256 indexed SubscriptionManagerId,
        address indexed user,
        uint256 indexed paymentBlockchainId
    );

    //----Internal function with sign part----------------------------------------------//

    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function getMessage(
        uint256 subscriptionManagerId,
        uint8 subscriptionId,
        address user,
        uint256 price,
        uint nonce
    ) public view returns (string memory) {
        uint256 chainId = getChainID();
        return
            string(
                abi.encodePacked(
                    "Cicleo Bridged Subscription\n\nChain: ",
                    Strings.toString(chainId),
                    "\nUser: ",
                    Strings.toHexString(uint256(uint160(user)), 20),
                    "\nSubManager: ",
                    Strings.toString(subscriptionManagerId),
                    "\nSubscription: ",
                    Strings.toString(subscriptionId),
                    "\nPrice: ",
                    Strings.toString(price),
                    "\nNonce: ",
                    Strings.toString(nonce)
                )
            ); //, "\nUser: ", user, "\nSubManager: ", Strings.toString(subscriptionManagerId), "\nSubscription: ", Strings.toString(subscriptionId), "\nPrice: ", Strings.toString(price), "\nNonce: ", Strings.toString(nonce))
    }

    function getMessageHash(
        uint256 subscriptionManagerId,
        uint8 subscriptionId,
        address user,
        uint256 price,
        uint nonce
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    getMessage(
                        subscriptionManagerId,
                        subscriptionId,
                        user,
                        price,
                        nonce
                    )
                )
            );
    }

    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n000000",
                    _messageHash
                )
            );
    }

    function verify(
        uint256 subscriptionManagerId,
        uint8 subscriptionId,
        address user,
        uint256 price,
        uint nonce,
        bytes memory signature
    ) public view returns (bool) {
        string memory messageHash = getMessage(
            subscriptionManagerId,
            subscriptionId,
            user,
            price,
            nonce
        );

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        return verifyString(messageHash, v, r, s) == user;
    }

    // Returns the address that signed a given string message
    function verifyString(
        string memory message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address signer) {
        // The message header; we will fill in the length next
        string memory header = "\x19Ethereum Signed Message:\n000000";

        uint256 lengthOffset;
        uint256 length;
        assembly {
            // The first word of a string is its length
            length := mload(message)
            // The beginning of the base-10 message length in the prefix
            lengthOffset := add(header, 57)
        }

        // Maximum length we support
        require(length <= 999999);

        // The length of the message's length in base-10
        uint256 lengthLength = 0;

        // The divisor to get the next left-most message length digit
        uint256 divisor = 100000;

        // Move one digit of the message length to the right at a time
        while (divisor != 0) {
            // The place value at the divisor
            uint256 digit = length / divisor;
            if (digit == 0) {
                // Skip leading zeros
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }

            // Found a non-zero digit or non-leading zero digit
            lengthLength++;

            // Remove this digit from the message length's current value
            length -= digit * divisor;

            // Shift our base-10 divisor over
            divisor /= 10;

            // Convert the digit to its ASCII representation (man ascii)
            digit += 0x30;
            // Move to the next character and write the digit
            lengthOffset++;

            assembly {
                mstore8(lengthOffset, digit)
            }
        }

        // The null string requires exactly 1 zero (unskip 1 leading 0)
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }

        // Truncate the tailing zeros from the header
        assembly {
            mstore(header, lengthLength)
        }

        // Perform the elliptic curve recover operation
        bytes32 check = keccak256(abi.encodePacked(header, message));

        return ecrecover(check, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        // implicitly return (r, s, v)
    }

    //----External function----------------------------------------------//

    /// @notice Function to pay for a subscription with LiFi call
    /// @param user User address to pay for the subscription
    /// @param signature Signature of the caller to verify the caller
    function bridgeSubscribe(
        PaymentParameters memory paymentParams,
        address user,
        address referral,
        bytes memory signature
    ) external {
        CicleoSubscriptionManager manager = CicleoSubscriptionManager(
            LibAdmin.ids(paymentParams.subscriptionManagerId)
        );

        require(
            verify(
                paymentParams.subscriptionManagerId,
                paymentParams.subscriptionId,
                user,
                paymentParams.priceInSubToken,
                getStorage().userNonce[user],
                signature
            ),
            "Invalid signature"
        );
        require(paymentParams.subscriptionId != 0, "Invalid Id !");

        if (paymentParams.subscriptionId != 255) {
            require(
                paymentParams.priceInSubToken >=
                    LibPayment.getChangeSubscriptionPrice(
                        paymentParams.subscriptionManagerId,
                        user,
                        paymentParams.subscriptionId
                    ),
                "Wrong price"
            );
        }

        manager.token().transferFrom(
            msg.sender,
            address(this),
            paymentParams.priceInSubToken
        );

        getStorage().userNonce[user]++;

        //Save user referrer
        LibPayment.setUserReferral(
            paymentParams.subscriptionManagerId,
            msg.sender,
            referral
        );

        //Do token distribution
        LibPayment.redistributeToken(
            paymentParams.priceInSubToken,
            manager,
            paymentParams.subscriptionManagerId,
            user
        );

        //End of the subscription
        (uint8 actualSubscription, bool isActive) = manager
            .getUserSubscriptionStatus(user);

        uint256 oldPrice = LibSubscriptionTypes
            .subscriptions(
                paymentParams.subscriptionManagerId,
                actualSubscription
            )
            .price;

        uint256 endDate = manager.bridgeSubscription(
            user,
            paymentParams.subscriptionId,
            isActive == false || oldPrice == 0,
            LibSubscriptionTypes
                .subscriptions(
                    paymentParams.subscriptionManagerId,
                    paymentParams.subscriptionId
                )
                .price
        );

        emit PaymentSubscription(
            paymentParams.subscriptionManagerId,
            user,
            paymentParams.subscriptionId,
            paymentParams.priceInSubToken
        );

        emit UserEdited(
            paymentParams.subscriptionManagerId,
            user,
            paymentParams.subscriptionId,
            endDate
        );

        emit SelectBlockchain(
            paymentParams.subscriptionManagerId,
            msg.sender,
            paymentParams.chainId
        );

        emit SelectToken(
            paymentParams.subscriptionManagerId,
            user,
            address(paymentParams.token)
        );
    }

    function bridgeRenew(
        uint256 subscriptionManagerId,
        address user
    ) external onlyBot {
        CicleoSubscriptionManager manager = CicleoSubscriptionManager(
            LibAdmin.ids(subscriptionManagerId)
        );

        (uint8 subscriptionId, bool isActive) = manager
            .getUserSubscriptionStatus(user);

        uint256 price = LibSubscriptionTypes
            .subscriptions(subscriptionManagerId, subscriptionId)
            .price;

        require(isActive == false, "Sub still running");
        require(subscriptionId != 0, "Invalid Id !");

        manager.token().transferFrom(msg.sender, address(this), price);

        //Do token distribution
        LibPayment.redistributeToken(
            price,
            manager,
            subscriptionManagerId,
            user
        );

        //End of the subscription
        uint256 endDate = block.timestamp + manager.subscriptionDuration();

        manager.editAccount(user, endDate, subscriptionId);

        emit PaymentSubscription(
            subscriptionManagerId,
            user,
            subscriptionId,
            price
        );

        emit UserEdited(subscriptionManagerId, user, subscriptionId, endDate);
    }

    //----Get Functions----------------------------------------------//

    /// @notice Get the nonce of a user
    /// @param user User address to get the nonce
    /// @return nonce of the user
    function getUserNonce(address user) external view returns (uint256) {
        return getStorage().userNonce[user];
    }

    //----Diamond storage functions-------------------------------------//

    /// @dev fetch local storage
    function getStorage() private pure returns (Storage storage s) {
        bytes32 namespace = NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}

// SPDX-License-Identifier: CC BY-NC 2.0
pragma solidity ^0.8.0;

import {IDiamondCut} from "./../../../Diamond/Interfaces/IDiamondCut.sol";
import {CicleoSubscriptionFactory, CicleoSubscriptionSecurity} from "../../SubscriptionFactory.sol";

library LibAdmin {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("com.cicleo.facets.admin");

    struct DiamondStorage {
        CicleoSubscriptionFactory factory;
        mapping(uint256 => uint8) subscriptionNumber;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function isContractOwner(
        address user,
        uint256 subscriptionManagerId
    ) internal view returns (bool isOwner) {
        isOwner = diamondStorage().factory.verifyIfOwner(
            user,
            subscriptionManagerId
        );
    }

    function enforceIsOwnerOfSubManager(
        uint256 subscriptionManagerId
    ) internal view {
        require(
            isContractOwner(msg.sender, subscriptionManagerId),
            "LibAdmin: Must hold ownerpass for this submanager"
        );
    }

    function ids(uint256 id) internal view returns (address) {
        return diamondStorage().factory.ids(id);
    }

    function security() internal view returns (CicleoSubscriptionSecurity) {
        return diamondStorage().factory.security();
    }

    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}

// SPDX-License-Identifier: CC BY-NC 2.0
pragma solidity ^0.8.0;

import {IDiamondCut} from "../../../Diamond/Interfaces/IDiamondCut.sol";
import {CicleoSubscriptionManager} from "../../SubscriptionManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LibAdmin.sol";
import {LibSubscriptionTypes} from "./LibSubscriptionTypes.sol";

library LibPayment {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("com.cicleo.facets.payment");

    struct DiamondStorage {
        /// @notice Address of the tax account (for cicleo)
        address taxAccount;
        /// @notice Address of the bot account (for cicleo)
        address botAccount;
        /// @notice Address of the LiFi executor
        address bridgeExecutor;
        /// @notice Percentage of tax to apply on each payment
        uint16 taxPercentage;
        /// @notice Mapping to store the user referral data for each submanager
        mapping(uint256 => mapping(address => address)) userReferral;
        /// @notice Mapping to store the referral percent for each submanager
        mapping(uint256 => uint16) referralPercent;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function referralPercent(uint256 id) internal view returns (uint16) {
        return diamondStorage().referralPercent[id];
    }

    function redistributeToken(
        uint256 price,
        CicleoSubscriptionManager manager,
        uint256 id,
        address user
    ) internal {
        uint256 tax = (price * diamondStorage().taxPercentage) / 1000;

        IERC20 token = IERC20(manager.tokenAddress());
        address treasury = manager.treasury();

        uint256 toOwner = price - tax;

        (, bool isActive) = manager.getUserSubscriptionStatus(
            diamondStorage().userReferral[id][user]
        );

        if (
            diamondStorage().userReferral[id][user] != address(0) &&
            diamondStorage().referralPercent[id] > 0 &&
            isActive
        ) {
            uint256 referral = (toOwner *
                diamondStorage().referralPercent[id]) / 1000;
            toOwner -= referral;
            token.transfer(diamondStorage().userReferral[id][user], referral);
        }

        token.transfer(treasury, toOwner);
        token.transfer(diamondStorage().taxAccount, tax);
    }

    /// @notice Function to get the price when we change subscription
    /// @param subscriptionManagerId Id of the submanager
    /// @param user User address to pay for the subscription
    /// @param newSubscriptionId Id of the new subscription
    function getChangeSubscriptionPrice(
        uint256 subscriptionManagerId,
        address user,
        uint8 newSubscriptionId
    ) internal view returns (uint256) {
        CicleoSubscriptionManager subManager = CicleoSubscriptionManager(
            LibAdmin.ids(subscriptionManagerId)
        );

        (uint8 oldSubscriptionId, bool isActive) = subManager
            .getUserSubscriptionStatus(user);

        uint256 oldPrice = LibSubscriptionTypes
            .subscriptions(subscriptionManagerId, oldSubscriptionId)
            .price;

        uint256 newPrice = LibSubscriptionTypes
            .subscriptions(subscriptionManagerId, newSubscriptionId)
            .price;

        if (oldSubscriptionId == 0 || isActive == false || oldPrice == 0) {
            return newPrice;
        }

        if (newPrice > oldPrice) {
            return subManager.getAmountChangeSubscription(user, newPrice);
        } else {
            return 0;
        }
    }

    function setUserReferral(
        uint256 subManagerId,
        address user,
        address referrer
    ) internal {
        DiamondStorage storage s = diamondStorage();

        s.userReferral[subManagerId][user] = referrer;
    }

    function getBotAccount() internal view returns (address) {
        return diamondStorage().botAccount;
    }
}

// SPDX-License-Identifier: CC BY-NC 2.0
pragma solidity ^0.8.0;

import {IDiamondCut} from "../../../Diamond/Interfaces/IDiamondCut.sol";
import {SubscriptionStruct} from "../../Types/CicleoTypes.sol";

library LibSubscriptionTypes {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("com.cicleo.facets.subscriptiontypes");

    struct DiamondStorage {
        /// @notice Mapping to store the subscriptions of each submanager
        mapping(uint256 => mapping(uint8 => SubscriptionStruct)) subscriptions;
        /// @notice Mapping to store the current count of subscriptions of each submanager (to calculate next id)
        mapping(uint256 => uint8) subscriptionNumber;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function subscriptions(
        uint256 subscriptionManagerId,
        uint8 subscriptionId
    ) internal view returns (SubscriptionStruct memory) {
        return
            diamondStorage().subscriptions[subscriptionManagerId][
                subscriptionId
            ];
    }

    function subscriptionNumber(
        uint256 subscriptionManagerId
    ) internal view returns (uint8) {
        return diamondStorage().subscriptionNumber[subscriptionManagerId];
    }
}

// SPDX-License-Identifier: CC BY-NC 2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IRouter} from "./Types/CicleoTypes.sol";
import {CicleoSubscriptionSecurity} from "./SubscriptionSecurity.sol";
import {CicleoSubscriptionManager} from "./SubscriptionManager.sol";
import {ICicleoSubscriptionRouter} from "./Interfaces/ICicleoSubscriptionRouter.sol";

/// @title Cicleo Subscription Factory
/// @author Pol Epie
/// @notice This contract is used to create new subscription manager
contract CicleoSubscriptionFactory is OwnableUpgradeable {
    /// @notice idCount is the number of subscription manager created
    uint256 public idCount;

    /// @notice routerSwap Contract of the subscription router
    IRouter public routerSwap;

    /// @notice routerSubscription Address of the subscription router
    address public routerSubscription;

    /// @notice security Contract of the subscription security
    CicleoSubscriptionSecurity public security;

    /// @notice ids Mapping of the subscription manager id to the corresponding address
    mapping(uint256 => address) public ids;

    /// @notice subscriptionManagerId Mapping of the subscription manager address to the id
    mapping(address => uint256) public subscriptionManagerId;

    /// @notice Emitted when a new subscription manager is created
    event SubscriptionManagerCreated(
        address creator,
        address indexed subscriptionManagerAddress,
        uint256 indexed subscriptionManagerId
    );

    function initialize(address _security) public initializer {
        __Ownable_init();

        security = CicleoSubscriptionSecurity(_security);
    }

    // SubManager get functions

    /// @notice Verify if the user is admin of the subscription manager
    /// @param user User to verify
    /// @param id Id of the subscription manager
    function verifyIfOwner(
        address user,
        uint256 id
    ) public view returns (bool) {
        return security.verifyIfOwner(user, id);
    }

    /// @notice Verify if a given address is a subscription manager
    /// @param _address Address to verify
    function isSubscriptionManager(
        address _address
    ) public view returns (bool) {
        return subscriptionManagerId[_address] != 0;
    }

    /// @notice Get the address of the tax account
    function taxAccount() public view returns (address) {
        return ICicleoSubscriptionRouter(routerSubscription).taxAccount();
    }

    // SubManager creation

    /// @notice Create a new subscription manager
    /// @param name Name of the subscription manager
    /// @param token Token used for the subscription
    /// @param treasury Address of the treasury
    /// @param timerange Time range of the subscription (in seconds) (ex: 1 day = 86400, 30 days = 2592000)
    function createSubscriptionManager(
        string memory name,
        address token,
        address treasury,
        uint256 timerange
    ) external returns (address) {
        idCount += 1;

        CicleoSubscriptionManager subscription = new CicleoSubscriptionManager();

        subscription.initialize(name, token, treasury, timerange);

        security.mintNft(msg.sender, idCount);

        emit SubscriptionManagerCreated(
            msg.sender,
            address(subscription),
            idCount
        );

        ids[idCount] = address(subscription);

        subscriptionManagerId[address(subscription)] = idCount;

        return address(subscription);
    }

    // Admin function

    /// @notice Set the address of the subscription security
    /// @param _securityAddress Address of the subscription security
    function setSecurityAddress(address _securityAddress) external onlyOwner {
        security = CicleoSubscriptionSecurity(_securityAddress);
    }

    /// @notice Set the address of the subscription router
    /// @param _routerSubscription Address of the subscription router
    function setRouterSubscription(
        address _routerSubscription
    ) external onlyOwner {
        routerSubscription = _routerSubscription;
    }

    /// @notice Set the address of the router swap (openocean)
    /// @param _routerSwap Address of the router swap
    function setRouterSwap(address _routerSwap) external onlyOwner {
        routerSwap = IRouter(_routerSwap);
    }
}

// SPDX-License-Identifier: CC BY-NC 2.0
pragma solidity ^0.8.9;

import {IERC20} from "./Interfaces/IERC20.sol";
import {SwapDescription, SubscriptionStruct, UserData, IRouter, IOpenOceanCaller} from "./Types/CicleoTypes.sol";
import {CicleoSubscriptionFactory} from "./SubscriptionFactory.sol";

/// @title Cicleo Subscription Manager
/// @author Pol Epie
/// @notice This contract is used to manage subscription payments
contract CicleoSubscriptionManager {
    /// @notice users Mapping of the user address to the corresponding user data
    mapping(address => UserData) public users;

    /// @notice token Token used for the subscription
    IERC20 public token;

    /// @notice factory Address of the subscription factory
    CicleoSubscriptionFactory public factory;

    /// @notice name Name of the subscription
    string public name;

    /// @notice treasury Address of the treasury
    address public treasury;

    /// @notice subscriptionNumber Count of subscriptions
    uint256 public subscriptionNumber;

    /// @notice subscriptionDuration Duration of the subscription in seconds
    uint256 public subscriptionDuration;

    /// @notice Event when a user change his subscription limit
    event EditSubscriptionLimit(
        address indexed user,
        uint256 amountMaxPerPeriod
    );

    /// @notice Event when a user subscription state is changed (after a payment or via an admin)
    event UserEdited(
        address indexed user,
        uint256 indexed subscriptionId,
        uint256 endDate
    );

    /// @notice Event when a user cancels / stop his subscription
    event Cancel(address indexed user);

    /// @notice Event when a user subscription is edited
    event SubscriptionEdited(
        address indexed user,
        uint256 indexed subscriptionId,
        uint256 price,
        bool isActive
    );

    /// @notice Verify if the user is admin of the subscription manager
    modifier onlyOwner() {
        require(
            factory.verifyIfOwner(
                msg.sender,
                factory.subscriptionManagerId(address(this))
            ),
            "Not allowed to"
        );
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == factory.routerSubscription(), "Not allowed to");
        _;
    }

    constructor() {
        factory = CicleoSubscriptionFactory(msg.sender);
    }

    /// @notice Initialize a subscription manager when created (called by the factory)
    /// @param _name Name of the subscription
    /// @param _token Token used for the subscription
    /// @param _treasury Address of the treasury
    /// @param _subscriptionDuration Duration of the subscription in seconds
    function initialize(
        string memory _name,
        address _token,
        address _treasury,
        uint256 _subscriptionDuration
    ) external {
        require(msg.sender == address(factory), "Not allowed to");

        name = _name;
        token = IERC20(_token);
        treasury = _treasury;
        subscriptionDuration = _subscriptionDuration;
    }

    /// @notice Edit the subscription limit
    /// @param amountMaxPerPeriod New subscription price limit per period in the submanager token
    function changeSubscriptionLimit(uint256 amountMaxPerPeriod) external {
        users[msg.sender].subscriptionLimit = amountMaxPerPeriod;

        emit EditSubscriptionLimit(msg.sender, amountMaxPerPeriod);
    }

    /// @notice Function to pay subscription with submanager token
    /// @param user User to pay the subscription
    /// @param subscriptionId Id of the subscription
    /// @param price Price of the subscription
    /// @param endDate End date of the subscription
    function payFunctionWithSubToken(
        address user,
        uint8 subscriptionId,
        uint256 price,
        uint256 endDate
    ) external {
        address routerSubscription = factory.routerSubscription();
        require(msg.sender == routerSubscription, "Not allowed to");

        require(users[user].canceled == false, "Subscription is canceled");

        require(
            users[user].lastPaymentTime <
                block.timestamp - subscriptionDuration,
            "You cannot pay twice in the same period"
        );

        //Verify subscription limit
        require(
            users[user].subscriptionLimit >= price,
            "You need to approve our contract to spend this amount of tokens"
        );

        uint256 balanceBefore = token.balanceOf(routerSubscription);

        token.transferFrom(user, routerSubscription, price);

        //Verify if the token have a transfer fees or if the swap goes okay
        uint256 balanceAfter = token.balanceOf(routerSubscription);
        require(
            balanceAfter - balanceBefore >= price,
            "The token have a transfer fee"
        );

        //Save subscription info

        UserData storage _user = users[user];

        users[user] = UserData(
            endDate,
            subscriptionId,
            _user.subscriptionLimit,
            block.timestamp,
            price,
            false
        );
    }

    /// @notice Function to pay subscription with swap (OpenOcean)
    /// @param user User to pay the subscription
    /// @param executor Executor of the swap (OpenOcean)
    /// @param desc Description of the swap (OpenOcean)
    /// @param calls Calls of the swap (OpenOcean)
    /// @param subscriptionId Id of the subscription
    /// @param price Price of the subscription
    /// @param endDate End date of the subscription
    function payFunctionWithSwap(
        address user,
        IOpenOceanCaller executor,
        SwapDescription memory desc,
        IOpenOceanCaller.CallDescription[] calldata calls,
        uint8 subscriptionId,
        uint256 price,
        uint256 endDate
    ) external {
        address routerSubscription = factory.routerSubscription();
        require(msg.sender == routerSubscription, "Not allowed to");

        require(users[user].canceled == false, "Subscription is canceled");

        require(
            users[user].lastPaymentTime <
                block.timestamp - subscriptionDuration,
            "You cannot pay twice in the same period"
        );

        //Verify subscription limit
        require(
            users[user].subscriptionLimit >= price,
            "You need to approve our contract to spend this amount of tokens"
        );

        IRouter routerSwap = factory.routerSwap();

        //OpenOcean swap
        desc.minReturnAmount = price;

        uint256 balanceBefore = token.balanceOf(address(this));

        IERC20(desc.srcToken).transferFrom(user, address(this), desc.amount);
        IERC20(desc.srcToken).approve(address(routerSwap), desc.amount);

        routerSwap.swap(executor, desc, calls);

        //Verify if the token have a transfer fees or if the swap goes okay
        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter - balanceBefore >= price, "Swap failed");

        token.transfer(routerSubscription, balanceAfter);

        //Save subscription info

        UserData storage _user = users[user];

        users[user] = UserData(
            endDate,
            subscriptionId,
            _user.subscriptionLimit,
            block.timestamp,
            price,
            false
        );
    }

    /// @notice Function to cancel / stop subscription
    function cancel() external {
        users[msg.sender].canceled = true;

        emit Cancel(msg.sender);
    }

    //Get functions

    /// @notice Return the subscription status of a user
    /// @param user User to get the subscription status
    /// @return subscriptionId Id of the subscription (0 mean no subscription and 255 mean dynamic subscription)
    /// @return isActive If the subscription is currently active
    function getUserSubscriptionStatus(
        address user
    ) public view returns (uint8 subscriptionId, bool isActive) {
        UserData memory userData = users[user];
        return (
            userData.subscriptionId,
            userData.subscriptionEndDate > block.timestamp
        );
    }

    /// @notice Return the subscription id of a user
    /// @param user User to get the subscription id
    /// @return subscriptionId Id of the subscription (0 mean no subscription and 255 mean dynamic subscription)
    function getUserSubscriptionId(
        address user
    ) external view returns (uint8 subscriptionId) {
        UserData memory userData = users[user];
        return userData.subscriptionId;
    }

    /// @notice Return the token address of the submanager
    function tokenAddress() external view returns (address) {
        return address(token);
    }

    /// @notice Return the token decimals of the submanager
    function tokenDecimals() external view returns (uint8) {
        return token.decimals();
    }

    /// @notice Return the token symbol of the submanager
    function tokenSymbol() external view returns (string memory) {
        return token.symbol();
    }

    //Admin functions

    /// @notice Edit the subscription manager name
    /// @param _name New name of the subscription manager
    function setName(string memory _name) external {
        require(msg.sender == factory.routerSubscription(), "Not allowed to");
        name = _name;
    }

    /// @notice Edit the treasury address
    /// @param _treasury New treasury address
    function setTreasury(address _treasury) external {
        require(msg.sender == factory.routerSubscription(), "Not allowed to");
        treasury = _treasury;
    }

    /// @notice Edit the token address
    /// @param _token New Token address
    function setToken(address _token) external {
        require(msg.sender == factory.routerSubscription(), "Not allowed to");
        token = IERC20(_token);
    }

    /// @notice Edit the state of a user
    /// @param user User to edit
    /// @param subscriptionEndDate New subscription end date (timestamp unix seconds)
    /// @param subscriptionId New subscription id
    function editAccount(
        address user,
        uint256 subscriptionEndDate,
        uint8 subscriptionId
    ) external {
        require(msg.sender == factory.routerSubscription(), "Not allowed to");

        UserData memory _user = users[user];

        users[user] = UserData(
            subscriptionEndDate,
            subscriptionId,
            _user.subscriptionLimit,
            _user.lastPaymentTime,
            _user.totalPaidThisPeriod,
            _user.canceled
        );
    }

    /// @notice Function to change subscription type and pay the difference for the actual period
    /// @param user User to edit
    /// @param oldPrice Price of the old subscription
    /// @param newPrice Price of the new subscription
    /// @param subscriptionId New subscription id
    function changeSubscription(
        address user,
        uint256 oldPrice,
        uint256 newPrice,
        uint8 subscriptionId
    ) external returns (uint256 toPay) {
        address routerSubscription = factory.routerSubscription();
        require(msg.sender == routerSubscription, "Not allowed to");
        require(subscriptionId != 0 && subscriptionId != 255, "Wrong sub id");

        UserData memory _user = users[user];

        if (newPrice > oldPrice) {
            // Compute the price to be paid to regulate

            uint256 priceAdjusted = getAmountChangeSubscription(user, newPrice);

            token.transferFrom(user, routerSubscription, priceAdjusted);

            toPay = priceAdjusted;

            if (oldPrice == 0) {
                _user.subscriptionEndDate =
                    block.timestamp +
                    subscriptionDuration;
            }
        }

        //Change the id of subscription
        users[user] = UserData(
            _user.subscriptionEndDate,
            subscriptionId,
            _user.subscriptionLimit,
            _user.lastPaymentTime,
            newPrice > oldPrice ? newPrice : _user.totalPaidThisPeriod,
            _user.canceled
        );
    }

    /// @notice Function to change subscription type and pay the difference for the actual period
    /// @param user User to edit
    /// @param oldPrice Price of the old subscription
    /// @param newPrice Price of the new subscription
    /// @param subscriptionId New subscription id
    function changeSubscriptionWithSwap(
        address user,
        uint256 oldPrice,
        uint256 newPrice,
        uint8 subscriptionId,
        IOpenOceanCaller executor,
        SwapDescription memory desc,
        IOpenOceanCaller.CallDescription[] memory calls
    ) external returns (uint256 toPay) {
        address routerSubscription = factory.routerSubscription();
        require(msg.sender == routerSubscription, "Not allowed to");
        require(subscriptionId != 0 && subscriptionId != 255, "Wrong sub id");

        UserData memory _user = users[user];

        if (newPrice > oldPrice) {
            // Compute the price to be paid to regulate

            uint256 priceAdjusted = getAmountChangeSubscription(user, newPrice);

            IRouter routerSwap = factory.routerSwap();

            //OpenOcean swap
            desc.minReturnAmount = priceAdjusted;

            uint256 balanceBefore = token.balanceOf(address(this));

            IERC20(desc.srcToken).transferFrom(
                user,
                address(this),
                desc.amount
            );
            IERC20(desc.srcToken).approve(address(routerSwap), desc.amount);

            routerSwap.swap(executor, desc, calls);

            //Verify if the token have a transfer fees or if the swap goes okay
            uint256 balanceAfter = token.balanceOf(address(this));
            require(
                balanceAfter - balanceBefore >= priceAdjusted,
                "Swap failed"
            );

            token.transfer(routerSubscription, balanceAfter);

            toPay = balanceAfter;
        }

        //Change the id of subscription
        users[user] = UserData(
            _user.subscriptionEndDate,
            subscriptionId,
            _user.subscriptionLimit,
            _user.lastPaymentTime,
            newPrice > oldPrice ? newPrice : _user.totalPaidThisPeriod,
            _user.canceled
        );
    }

    function bridgeSubscription(
        address user,
        uint8 subscriptionId,
        bool isNewPeriod,
        uint256 price
    ) external onlyRouter returns (uint256) {
        users[user].subscriptionId = subscriptionId;

        if (isNewPeriod) {
            users[user].totalPaidThisPeriod = price;
            users[user].subscriptionEndDate =
                block.timestamp +
                subscriptionDuration;
            users[user].lastPaymentTime = block.timestamp;

            return block.timestamp + subscriptionDuration;
        } else {
            if (price > users[user].totalPaidThisPeriod) {
                users[user].totalPaidThisPeriod = price;
            }

            return users[user].subscriptionEndDate;
        }
    }

    function getAmountChangeSubscription(
        address user,
        uint256 newPrice
    ) public view returns (uint256) {
        UserData memory _user = users[user];

        uint256 totalPayedThisPeriod = _user.totalPaidThisPeriod;

        uint256 currentTime = block.timestamp;
        uint256 timeToNextPayment = _user.subscriptionEndDate;

        if (totalPayedThisPeriod == 0) return newPrice;

        if (totalPayedThisPeriod >= newPrice) return 0;

        uint256 newPriceAdjusted = ((newPrice - totalPayedThisPeriod) *
            (timeToNextPayment - currentTime)) / subscriptionDuration;

        return newPriceAdjusted;
    }

    /// @notice Delete the submanager
    function deleteSubManager() external onlyOwner {
        factory.security().deleteSubManager();
        selfdestruct(payable(factory.taxAccount()));
    }
}

// SPDX-License-Identifier: CC BY-NC 2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {CicleoSubscriptionFactory} from "./SubscriptionFactory.sol";

/// @title Cicleo Subscription Security
/// @author Pol Epie
/// @notice This contract is used to manage ownership of subscription manager
contract CicleoSubscriptionSecurity is
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @notice Emitted when a new owner pass is minted
    event MintOwnerPass(address minter, uint256 subscriptionManagerId);

    /// @notice URI base of the NFTs
    string _baseTokenURI;

    /// @notice nftSupply is the number of NFTs minted
    uint256 public nftSupply;

    /// @notice factory Contract of the subscription factory
    CicleoSubscriptionFactory public factory;

    /// @notice ownershipByNftId Mapping of the NFT id to the corresponding subscription manager id
    mapping(uint256 => uint256) public ownershipByNftId;

    /// @notice ownershipBySubscriptionId Mapping of the subscription manager id to the corresponding Array of NFT id
    mapping(uint256 => uint256[]) public ownershipBySubscriptionId;

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __ERC721_init("Cicleo OwnerPass", "COP");
    }

    //Others

    /// @notice Return the URI base
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Set the URI base
    function setURI(string memory _URI) external onlyOwner {
        _baseTokenURI = _URI;
    }

    /// @notice Get URI of a NFT id
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    string(abi.encodePacked(_baseTokenURI, tokenId)),
                    ".json"
                )
            );
    }

    // Get functions

    /// @notice Verify if the user is admin of the subscription manager
    /// @param _user User to verify
    /// @param _subManagerId Id of the subscription manager
    function verifyIfOwner(
        address _user,
        uint256 _subManagerId
    ) public view returns (bool) {
        for (uint256 i = 0; i < balanceOf(_user); i++) {
            if (
                ownershipByNftId[tokenOfOwnerByIndex(_user, i)] == _subManagerId
            ) {
                return true;
            }
        }
        return false;
    }

    /// @notice Get the list of subscription manager id of a user
    /// @param _user User to verify
    /// @return Array of subscription manager ids
    function getSubManagerList(
        address _user
    ) public view returns (uint256[] memory) {
        uint256[] memory _subManagerList = new uint256[](balanceOf(_user));

        for (uint256 i = 0; i < balanceOf(_user); i++) {
            _subManagerList[i] = ownershipByNftId[
                tokenOfOwnerByIndex(_user, i)
            ];
        }

        return _subManagerList;
    }

    /// @notice Get the first NFT id for a subscription manager id for a user
    /// @param _user User to verify
    /// @param _subManagerId Id of the subscription manager
    function getSubManagerTokenId(
        address _user,
        uint256 _subManagerId
    ) public view returns (uint256) {
        for (uint256 i = 0; i < balanceOf(_user); i++) {
            if (
                ownershipByNftId[tokenOfOwnerByIndex(_user, i)] == _subManagerId
            ) {
                return tokenOfOwnerByIndex(_user, i);
            }
        }

        return 0;
    }

    /// @notice Get the list of owners for a subscription manager id
    /// @param _subManagerId Id of the subscription manager
    /// @return Array of owners
    function getOwnersBySubmanagerId(
        uint256 _subManagerId
    ) public view returns (address[] memory) {
        address[] memory _owners = new address[](
            ownershipBySubscriptionId[_subManagerId].length
        );

        for (
            uint256 i = 0;
            i < ownershipBySubscriptionId[_subManagerId].length;
            i++
        ) {
            _owners[i] = ownerOf(ownershipBySubscriptionId[_subManagerId][i]);
        }

        return _owners;
    }

    // Mint Functions

    /// @notice Set the factory contract
    /// @param _factory Address of the factory contract
    function setFactory(address _factory) external onlyOwner {
        factory = CicleoSubscriptionFactory(_factory);
    }

    /// @notice Internal Mint a new NFT
    /// @param _to Address of the new owner
    /// @param subscriptionManagerId Id of the subscription manager
    function _mintNft(address _to, uint256 subscriptionManagerId) internal {
        nftSupply += 1;
        _mint(_to, nftSupply);

        ownershipByNftId[nftSupply] = subscriptionManagerId;
        ownershipBySubscriptionId[subscriptionManagerId].push(nftSupply);

        emit MintOwnerPass(_to, subscriptionManagerId);
    }

    /// @notice Mint a new NFT
    /// @param _to Address of the new owner
    /// @param subscriptionManagerId Id of the subscription manager
    function mintNft(address _to, uint256 subscriptionManagerId) external {
        require(msg.sender == address(factory), "Only factory can mint");
        _mintNft(_to, subscriptionManagerId);
    }

    /// @notice Burn a NFT when the subscription manager is deleted (called by the subscription manager)
    function deleteSubManager() external {
        uint256 subscriptionManagerId = factory.subscriptionManagerId(
            msg.sender
        );

        require(subscriptionManagerId != 0, "Only subManager can burn");

        for (
            uint256 i = 0;
            i < ownershipBySubscriptionId[subscriptionManagerId].length;
            i++
        ) {
            _burn(ownershipBySubscriptionId[subscriptionManagerId][i]);
        }
    }
}

// SPDX-License-Identifier: CC BY-NC 2.0
pragma solidity ^0.8.9;

import "../Interfaces/IERC20.sol";

struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address srcReceiver;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 guaranteedAmount;
    uint256 flags;
    address referrer;
    bytes permit;
}

struct MinimifiedSubscriptionManagerStruct {
    uint256 id;
    string name;
    string tokenSymbol;
    uint256 activeSubscriptionCount;
}

struct SubscriptionManagerStruct {
    uint256 id;
    address _address;
    string name;
    address tokenAddress;
    string tokenSymbol;
    uint256 tokenDecimals;
    uint256 activeSubscriptionCount;
    address treasury;
    SubscriptionStruct[] subscriptions;
    address[] owners;
    uint256 subscriptionDuration;
    uint16 referralPercent;
}

struct SubscriptionStruct {
    uint256 price;
    bool isActive;
    string name;
}

struct UserData {
    uint256 subscriptionEndDate;
    uint8 subscriptionId;
    uint256 subscriptionLimit;
    uint256 lastPaymentTime;
    uint256 totalPaidThisPeriod;
    bool canceled;

}

struct DynamicSubscriptionData {
    string name;
    uint256 price;
}

interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable; // 0x4b64e492
}

interface IOpenOceanCaller {
    struct CallDescription {
        uint256 target;
        uint256 gasLimit;
        uint256 value;
        bytes data;
    }

    function makeCall(CallDescription memory desc) external;

    function makeCalls(CallDescription[] memory desc) external payable;
}

interface IRouter {
    function swap(
        IOpenOceanCaller caller,
        SwapDescription calldata desc,
        IOpenOceanCaller.CallDescription[] calldata calls
    ) external payable returns (uint returnAmount);
}