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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

// EIP-712 is Final as of 2022-08-11. This file is deprecated.

import "./EIP712.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
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
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./modified/ERC721Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./interfaces/ISubscriptionModule.sol";
import "./libraries/StringUtils.sol";
import "./GasRestrictor.sol";

contract DappsDns is Initializable, ERC721Upgradeable, OwnableUpgradeable {
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    struct NftDetails {
        string name;
        string url;
    }

    // tokenId => Nft
    mapping(uint256 => NftDetails) public nfts;

    // domain => tokenId
    mapping(string => uint256) public tokenIdByDomain;

    struct Tld {
        string name;
        bool onSale;
    }

    mapping(bytes32 => Tld) public tlds; // top level domains

    // name => owner
    mapping(string => address) public domains;

    // name => dns records
    mapping(string => string[]) public records;

    // // name => tld => owner
    // mapping(string => mapping(string => address)) public domains;

    // // name => tld => dns records
    // mapping(string => mapping(string => string[])) public records;

    ISubscriptionModule public subsModule;

    GasRestrictor public gasRestrictor;

    mapping(address => bool) public hasClaimed;

    struct DnsRecord {
        uint8 recordType;
        string domain;
        string location;
        uint256 priority;
    }

    uint256 public recordCount;

    // domain => index => dns record
    mapping(string => mapping(uint256 => DnsRecord)) public dnsRecords;

    event NameRegistered(
        address indexed account, 
        string domain,
        string name,
        string tld,
        bytes32 dappId
    );

    event NftMinted(
        address indexed account,
        string domain,
        uint256 tokenId,
        string metadataUrl
    );

    event DnsRecordUpdated(
        address indexed user,
        string name,               // web3 domain
        uint256 recordIndex,
        uint8 recordType,
        string domain,
        string location,
        uint256 priority
    );

    event DnsRecordDeleted(
        string domain,
        uint256 index
    );

    function _onlyOwnerOrDappAdmin(bytes32 _dappId) internal view {
        require(
            _msgSender() == owner() ||
                _msgSender() == subsModule.getDappAdmin(_dappId),
            "INVALID_SENDER"
        );
    }

    modifier onlyOwnerOrDappAdmin(bytes32 _dappId) {
        _onlyOwnerOrDappAdmin(_dappId);
        _;
    }

     modifier GasNotZero(address user, bool isOauthUser) {
        _gasNotZero(user, isOauthUser);
        _;
    }

    function __DappsDns_init(
        ISubscriptionModule _subsModule,
        GasRestrictor _gasRestrictor,
        address _trustedForwarder
    ) public initializer {
        __ERC721_init("DappsDns", "DDNS");
        __Ownable_init(_trustedForwarder);
        subsModule = _subsModule;
        gasRestrictor = _gasRestrictor;
    }

    function updateGasRestrictor(
        GasRestrictor _gasRestrictor
    ) external onlyOwner {
        require(address(_gasRestrictor) != address(0), "ZERO_ADDRESS");
        gasRestrictor = _gasRestrictor;
    }

    function updateSubscriptionModule(
        ISubscriptionModule _subsModule
    ) external onlyOwner {
        require(address(_subsModule) != address(0), "ZERO_ADDRESS");
        subsModule = _subsModule;
    }

    function _gasNotZero(address user, bool isOauthUser) internal view {
        if (isTrustedForwarder[msg.sender]) {
            if (!isOauthUser) {
                if (
                    subsModule.getPrimaryFromSecondary(user) == address(0)
                ) {} else {
                    (, , uint256 u) = gasRestrictor.gaslessData(
                        subsModule.getPrimaryFromSecondary(user)
                    );
                    require(u != 0, "0_GASBALANCE");
                }
            } else {
                (, , uint256 u) = gasRestrictor.gaslessData(user);
                require(u != 0, "0_GASBALANCE");
            }
        }
    }

    function addTld(
        bytes32 _dappId, 
        string memory _tldName,
        bool _onSale
    ) external onlyOwner {
        require(bytes(_tldName).length > 0, "INVALID_TLD");
        _tldName = StringUtils.toLower(_tldName);
        tlds[_dappId] = Tld({
            name: _tldName,
            onSale: _onSale
        });
    }

    function updateTldSaleStatus(
        bytes32 _dappId, 
        bool _onSale
    ) external onlyOwnerOrDappAdmin(_dappId) {
        Tld storage tld = tlds[_dappId];
        require(bytes(tld.name).length > 0, "INVALID_TLD");
        require(tld.onSale != _onSale, "UNCHANGED");
        tld.onSale = _onSale;
    }

    // function setRecord(
    //     address _user,
    //     string calldata _name,      // web3 domain
    //     string[] memory _record,    // list of web2 name servers
    //     bool isOauthUser
    // ) external GasNotZero(_msgSender(), isOauthUser) {
    //     uint256 gasLeftInit = gasleft();

    //     require(domains[_name] == _user, "NOT_DOMAIN_OWNER");
    //     records[_name] = _record;

    //     _updateGaslessData(gasLeftInit);
    // }

    // function getRecords(string calldata _domain) external view returns (string[] memory) {
    //     return records[_domain];
    // }

    function setRecord(
        address _user,
        string memory _name,      // web3 domain
        uint256 _recordIndex,       // 0 if new record is to be added, otherwise the index to be updated
        uint8 _recordType,
        string calldata _domain,
        string calldata _location,
        uint256 _priority,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();

        _name = StringUtils.toLower(_name);
        require(domains[_name] == _user, "NOT_DOMAIN_OWNER");
        require(_recordType > 0 && _recordType < 5, "INVALID_TYPE");
        require(bytes(_domain).length > 0 && bytes(_location).length > 0, "INVALID_LEN");
        if(_recordIndex == 0)
            _recordIndex = ++recordCount;

        dnsRecords[_name][_recordIndex] = DnsRecord({
            recordType: _recordType,
            domain: _domain,
            location: _location,
            priority: _priority
        });

        emit DnsRecordUpdated(_user, _name, _recordIndex, _recordType, _domain, _location, _priority);

        _updateGaslessData(gasLeftInit);
    }

    function deleteRecord(
        address _user,
        string memory _domain,
        uint256 _index,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();

        _domain = StringUtils.toLower(_domain);
        require(domains[_domain] == _user, "NOT_DOMAIN_OWNER");
        require(dnsRecords[_domain][_index].recordType != 0, "RECORD_NA");
        delete dnsRecords[_domain][_index];
        emit DnsRecordDeleted(_domain, _index);

        _updateGaslessData(gasLeftInit);
    }

    function getRecord(
        string memory _domain,
        uint256 _index
    ) external view returns (DnsRecord memory) {
        _domain = StringUtils.toLower(_domain);
        return dnsRecords[_domain][_index];
    } 

    // to get the price of a domain based on length
    function price(string calldata name) public pure returns (uint256) {
        uint256 len = StringUtils.strlen(name);
        require(len > 0, "INVALID_LENGTH");

        if (len == 1) {
            return 10**23;      // 100_000 Matic
        } else if (len == 2) {
            return 10**21;      // 10_000 Matic
        } else if (len == 3) {
            return 10**21;      // 1000 Matic
        } else if (len == 4) {
            return 10**20;      // 100 Matic
        } else if (len == 5) {
            return 10**19;      // 10 Matic
        } else {
            return 10**18;      // 1 Matic
        }
    }

    function claimDomain(
        address _user,
        bytes32 _dappId,
        string calldata _name,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) {
        revert("FREE_CLAIM_NA");
        uint256 gasLeftInit = gasleft();

        require(!hasClaimed[_user], "CLAIMED!");
        _claimDomain(_user, _dappId, _name);

        _updateGaslessData(gasLeftInit);
    }

    function _claimDomain(
        address _user,
        bytes32 _dappId,
        string memory _name
    ) internal {
        Tld memory tld = tlds[_dappId];
        require(bytes(tld.name).length > 0, "TLD_NA");   // TLD_NOT_AVAILABLE
        require(tld.onSale, "NOT_ON_SALE");

        // length >= 4, [A-Z a-z 0-9]
        uint256 len = StringUtils.strlen(_name);
        require(len >= 4, "MIN_4_CHARS");

        bool success = StringUtils.checkAlphaNumeric(_name);
        require(success, "ONLY_ALPHANUMERIC");

        _name = StringUtils.toLower(_name);
        string memory domain = _concatenate(_name, tld.name);
        require(domains[domain] == address(0), "DOMAIN_UNAVAILABLE");

        hasClaimed[_user] = true;
        domains[domain] = _user;
        emit NameRegistered(_user, domain, _name, tld.name, _dappId);
    }

    function register(
        bytes32 _dappId,
        string calldata _name
    ) external payable onlyOwner {
        string memory tld = tlds[_dappId].name;
        require(bytes(tld).length > 0, "INVALID_TLD");
        // length >= 4, [A-Z a-z 0-9 /]

        string memory domain = _concatenate(_name, tld);
        require(domains[domain] == address(0), "DOMAIN_UNAVAILABLE");

        // uint256 _price = price(_name);
        // require(msg.value >= _price, "Not enough Matic paid");

        domains[domain] = _msgSender();
        emit NameRegistered(_msgSender(), domain, _name, tld, _dappId);
    }

    function safeMint(
        address _user,
        string memory _domainName,
        string calldata _url,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();

        _domainName = StringUtils.toLower(_domainName);
        require(domains[_domainName] == _user, "NOT_DOMAIN_OWNER");

        _tokenIdCounter.increment();    // to start tokenId from 1
        uint256 tokenId = _tokenIdCounter.current();
        NftDetails memory nft = NftDetails({
            name: _domainName,
            url: _url
        });
        nfts[tokenId] = nft;
        tokenIdByDomain[_domainName] = tokenId;
        
        // _tokenIdCounter.increment();
        _safeMint(_user, tokenId);
        emit NftMinted(_user, _domainName, tokenId, _url);

        _updateGaslessData(gasLeftInit);
    }

    function transferFrom(
        string memory _domain,
        address _from,
        address _to,
        // uint256 _tokenId,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();

        _domain = StringUtils.toLower(_domain);
        require(domains[_domain] == _from, "FROM_NOT_OWNER");
        uint256 tokenId = tokenIdByDomain[_domain];
        require(tokenId != 0, "NOT_MINTED");

        safeTransferFrom(_from, _to, tokenId);
        domains[_domain] = _to;
        _updateGaslessData(gasLeftInit);
    }

    function _concatenate(
        string memory _name,
        string memory _tld
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(_name, _tld));
    }

    function _updateGaslessData(uint256 _gasLeftInit) internal {
        if (isTrustedForwarder[msg.sender]) {
            gasRestrictor._updateGaslessData(_msgSender(), _gasLeftInit);
        }
    }

    function _msgSender() internal view override(ContextUpgradeable, OwnableUpgradeable) returns (address) {
        return OwnableUpgradeable._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./interfaces/ISubscriptionModule.sol";
import "./libraries/StringUtils.sol";
import "./GasRestrictor.sol";

contract DappsDnsCopy is Initializable, ERC721Upgradeable, OwnableUpgradeable {
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    struct NftDetails {
        string name;
        string url;
    }

    // tokenId => Nft
    mapping(uint256 => NftDetails) public nfts;

    // domain => tokenId
    mapping(string => uint256) public tokenIdByDomain;

    struct Tld {
        string name;
        bool onSale;
    }

    mapping(bytes32 => Tld) public tlds; // top level domains

    // name => owner
    mapping(string => address) public domains;

    // name => dns records
    mapping(string => string[]) public records;

    // // name => tld => owner
    // mapping(string => mapping(string => address)) public domains;

    // // name => tld => dns records
    // mapping(string => mapping(string => string[])) public records;

    ISubscriptionModule public subsModule;

    GasRestrictor public gasRestrictor;

    mapping(address => bool) public hasClaimed;

    event NameRegistered(
        address indexed account, 
        string domain,
        string name,
        string tld,
        bytes32 dappId
    );

    event NftMinted(
        address indexed account,
        string domain,
        uint256 tokenId,
        string metadataUrl
    );

    function _onlyOwnerOrDappAdmin(bytes32 _dappId) internal view {
        require(
            _msgSender() == owner() ||
                _msgSender() == subsModule.getDappAdmin(_dappId),
            "INVALID_SENDER"
        );
    }

    modifier onlyOwnerOrDappAdmin(bytes32 _dappId) {
        _onlyOwnerOrDappAdmin(_dappId);
        _;
    }

     modifier GasNotZero(address user, bool isOauthUser) {
        _gasNotZero(user, isOauthUser);
        _;
    }

    function __DappsDns_init(
        ISubscriptionModule _subsModule,
        GasRestrictor _gasRestrictor,
        address _trustedForwarder
    ) public initializer {
        __ERC721_init("DappsDns", "DDNS");
        __Ownable_init(_trustedForwarder);
        subsModule = _subsModule;
        gasRestrictor = _gasRestrictor;
    }

    function updateGasRestrictor(
        GasRestrictor _gasRestrictor
    ) external onlyOwner {
        require(address(_gasRestrictor) != address(0), "ZERO_ADDRESS");
        gasRestrictor = _gasRestrictor;
    }

    function updateSubscriptionModule(
        ISubscriptionModule _subsModule
    ) external onlyOwner {
        require(address(_subsModule) != address(0), "ZERO_ADDRESS");
        subsModule = _subsModule;
    }

    function _gasNotZero(address user, bool isOauthUser) internal view {
        if (isTrustedForwarder[msg.sender]) {
            if (!isOauthUser) {
                if (
                    subsModule.getPrimaryFromSecondary(user) == address(0)
                ) {} else {
                    (, , uint256 u) = gasRestrictor.gaslessData(
                        subsModule.getPrimaryFromSecondary(user)
                    );
                    require(u != 0, "0_GASBALANCE");
                }
            } else {
                (, , uint256 u) = gasRestrictor.gaslessData(user);
                require(u != 0, "0_GASBALANCE");
            }
        }
    }

    function addTld(
        bytes32 _dappId, 
        string calldata _tldName,
        bool _onSale
    ) external onlyOwner {
        require(bytes(_tldName).length > 0, "INVALID_TLD");
        tlds[_dappId] = Tld({
            name: _tldName,
            onSale: _onSale
        });
    }

    function updateTldSaleStatus(
        bytes32 _dappId, 
        bool _onSale
    ) external onlyOwnerOrDappAdmin(_dappId) {
        Tld storage tld = tlds[_dappId];
        require(bytes(tld.name).length > 0, "INVALID_TLD");
        require(tld.onSale != _onSale, "UNCHANGED");
        tld.onSale = _onSale;
    }

    function setRecord(
        address _user,
        string calldata _name,      // web3 domain
        string[] memory _record,    // list of web2 name servers
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();

        require(domains[_name] == _user, "NOT_DOMAIN_OWNER");
        records[_name] = _record;

        _updateGaslessData(gasLeftInit);
    }

    function getRecords(string calldata _domain) external view returns (string[] memory) {
        return records[_domain];
    }

    // to get the price of a domain based on length
    function price(string calldata name) public pure returns (uint256) {
        uint256 len = StringUtils.strlen(name);
        require(len > 0, "INVALID_LENGTH");

        if (len == 1) {
            return 10**23;      // 100_000 Matic
        } else if (len == 2) {
            return 10**21;      // 10_000 Matic
        } else if (len == 3) {
            return 10**21;      // 1000 Matic
        } else if (len == 4) {
            return 10**20;      // 100 Matic
        } else if (len == 5) {
            return 10**19;      // 10 Matic
        } else {
            return 10**18;      // 1 Matic
        }
    }

    function claimDomain(
        address _user,
        bytes32 _dappId,
        string calldata _name,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();

        require(!hasClaimed[_user], "CLAIMED!");
        _claimDomain(_user, _dappId, _name);

        _updateGaslessData(gasLeftInit);
    }

    function _claimDomain(
        address _user,
        bytes32 _dappId,
        string memory _name
    ) internal {
        Tld memory tld = tlds[_dappId];
        require(bytes(tld.name).length > 0, "TLD_NA");   // TLD_NOT_AVAILABLE
        require(tld.onSale, "NOT_ON_SALE");

        // length >= 4, [A-Z a-z 0-9]
        uint256 len = StringUtils.strlen(_name);
        require(len >= 4, "MIN_4_CHARS");

        bool success = StringUtils.checkAlphaNumeric(_name);
        require(success, "ONLY_ALPHANUMERIC");

        _name = StringUtils.toLower(_name);
        string memory domain = _concatenate(_name, tld.name);
        require(domains[domain] == address(0), "DOMAIN_UNAVAILABLE");

        hasClaimed[_user] = true;
        domains[domain] = _user;
        emit NameRegistered(_user, domain, _name, tld.name, _dappId);
    }

    function register(
        bytes32 _dappId,
        string calldata _name
    ) external payable onlyOwner {
        string memory tld = tlds[_dappId].name;
        require(bytes(tld).length > 0, "INVALID_TLD");
        // length >= 4, [A-Z a-z 0-9 /]

        string memory domain = _concatenate(_name, tld);
        require(domains[domain] == address(0), "DOMAIN_UNAVAILABLE");

        // uint256 _price = price(_name);
        // require(msg.value >= _price, "Not enough Matic paid");

        domains[domain] = _msgSender();
        emit NameRegistered(_msgSender(), domain, _name, tld, _dappId);
    }

    function safeMint(
        address _user,
        string calldata _domainName,
        string calldata _url,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();

        require(domains[_domainName] == _user, "NOT_DOMAIN_OWNER");

        _tokenIdCounter.increment();    // to start tokenId from 1
        uint256 tokenId = _tokenIdCounter.current();
        NftDetails memory nft = NftDetails({
            name: _domainName,
            url: _url
        });
        nfts[tokenId] = nft;
        tokenIdByDomain[_domainName] = tokenId;
        
        // _tokenIdCounter.increment();
        _safeMint(_user, tokenId);
        emit NftMinted(_user, _domainName, tokenId, _url);

        _updateGaslessData(gasLeftInit);
    }

    function _concatenate(
        string memory _name,
        string memory _tld
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(_name, _tld));
    }

    function _updateGaslessData(uint256 _gasLeftInit) internal {
        if (isTrustedForwarder[msg.sender]) {
            gasRestrictor._updateGaslessData(_msgSender(), _gasLeftInit);
        }
    }

    function _msgSender() internal view override(ContextUpgradeable, OwnableUpgradeable) returns (address) {
        return OwnableUpgradeable._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
// import "./modified/ERC721Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./libraries/StringUtils.sol";
// import "hardhat/console.sol";

contract DappsDnsNew is Initializable, ERC721Upgradeable, OwnableUpgradeable {
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    struct NftDetails {
        string name;
        string url;
    }

    // tokenId => Nft
    mapping(uint256 => NftDetails) public nfts;

    // domain => tokenId
    mapping(string => uint256) public tokenIdByDomain;

    // struct Tld {
    //     string name;
    //     bool onSale;
    // }

    // mapping(bytes32 => Tld) public tlds; // top level domains
    mapping(string => bool) public isTldCreated;
    mapping(string => bool) public isTldOnSale;

    // type(1: btc, 2: polka, 3: tezos) => isAllowed
    mapping(uint256 => bool) public isAllowedAccount;

    struct Domain {
        // bytes32 dappId;
        string tld;
        address owner;
        uint256 expiryTimestamp;
        bool isForLifetime;
    }

    // name => owner
    mapping(string => Domain) public domains;

    // domain => type (1: btc, 2: polka, 3: tezos) => address
    mapping(string => mapping(uint256 => string)) public otherAccounts;

    // 1 credit = 1 wei
    mapping(address => uint256) public credits;

    uint256 public gracePeriod;

    struct DnsRecord {
        uint8 recordType;
        string domain;
        string location;
        uint256 priority;
    }

    uint256 public recordCount;

    // domain => index => dns record
    mapping(string => mapping(uint256 => DnsRecord)) public records;

    uint256 public domainsCount;

    uint256 public annualPrice;

    uint256 public lifetimePrice;

    uint256 public tldCount;

    event TldUpdated(
        string tldName,
        bool onSale,
        uint256 count
    );

    event NameRegistered(
        address indexed account, 
        string domain,
        string name,
        string tld,
        bool isForLifetime,
        string referrerDomain,
        uint256 count,
        uint256 expiryTimestamp
    );

    event NftMinted(
        address indexed account,
        string domain,
        uint256 tokenId,
        string metadataUrl
    );

    event UpdatedAllowedAccountType(
        uint256 accountType,
        bool status
    );
    
    event UpdatedOtherAccounts(
        address indexed user,
        string domainName,
        uint256 otherAccountType,
        string otherAccount
    );

    event DnsRecordUpdated(
        address indexed user,
        string name,               // web3 domain
        uint256 recordIndex,
        uint8 recordType,
        string domain,
        string location,
        uint256 priority
    );

    event DnsRecordDeleted(
        string domain,
        uint256 index
    );

    event MetadataUpdated (
        uint256 tokenId,
        string url
    );

    function __DappsDns_init(
        address _trustedForwarder,
        uint256 _annualPrice,
        uint256 _lifetimePrice
    ) public initializer {
        __ERC721_init("Dapps Soul", "DS");
        __Ownable_init(_trustedForwarder);
        gracePeriod = 30 days;
        annualPrice = _annualPrice;
        lifetimePrice = _lifetimePrice;
    }

    function updateAnnualPrice(uint256 _annualPrice) external onlyOwner {
        annualPrice = _annualPrice;
    }

    function updateLifetimePrice(uint256 _lifetimePrice) external onlyOwner {
        lifetimePrice = _lifetimePrice;
    }

    function getDomainData(
        string memory _domain
    ) external view returns (Domain memory) {
        _domain = StringUtils.toLower(_domain);
        return domains[_domain];
    }

    function addTld( 
        string memory _tldName,
        bool _onSale
    ) external onlyOwner {
        require(bytes(_tldName).length > 0, "INVALID_TLD");
        _tldName = StringUtils.toLower(_tldName);
        require(!isTldCreated[_tldName], "TLD_EXISTS");
        isTldCreated[_tldName] = true;
        isTldOnSale[_tldName] = _onSale;
        emit TldUpdated(_tldName, _onSale, ++tldCount);
    }

    function updateTldSaleStatus(
        string memory _tld,
        bool _onSale
    ) external onlyOwner {
        require(bytes(_tld).length > 0, "INVALID_TLD");
        _tld = StringUtils.toLower(_tld);
        require(isTldOnSale[_tld] != _onSale, "UNCHANGED");
        isTldOnSale[_tld] = _onSale;
        emit TldUpdated(_tld, _onSale, tldCount);
    }

    // function setRecord(
    //     address _user,
    //     string calldata _name,      // web3 domain
    //     uint _recordType,
    //     string calldata _domain,
    //     string calldata _location,
    //     string memory _priority,
    //     bool isOauthUser
    // ) external GasNotZero(_msgSender(), isOauthUser) {
    //     uint256 gasLeftInit = gasleft();

    //     require(domains[_name].owner == _user, "NOT_DOMAIN_OWNER");

    //     if(_recordType == 1) {
    //         records[_name].aRecord = Record({
    //             domain: _domain,
    //             location: _location
    //         });
    //     }
    //     else if(_recordType == 2) {
    //         records[_name].cName = Record({
    //             domain: _domain,
    //             location: _location
    //         });
    //     }
    //     else if(_recordType == 3) {
    //         records[_name].mxRecord = MxRecord({
    //             domain: _domain,
    //             location: _location,
    //             priority: _priority
    //         });
    //     }
    //     else if(_recordType == 4) {
    //         records[_name].txt = Record({
    //             domain: _domain,
    //             location: _location
    //         });
    //     }

    //     _updateGaslessData(gasLeftInit);
    // }

    // function getRecords(string calldata _domain) external view returns (DnsRecord memory) {
    //     return records[_domain];
    // } 

    function setRecord(
        string memory _name,      // web3 domain
        uint256 _recordIndex,       // 0 if new record is to be added, otherwise the index to be updated
        uint8 _recordType,
        string calldata _domain,
        string calldata _location,
        uint256 _priority
    ) external {
        address _user = _msgSender();
        _name = StringUtils.toLower(_name);
        require(domains[_name].owner == _user, "NOT_DOMAIN_OWNER");
        require(_recordType > 0 && _recordType < 5, "INVALID_TYPE");
        require(bytes(_domain).length > 0 && bytes(_location).length > 0, "INVALID_LEN");
        if(_recordIndex == 0)
            _recordIndex = ++recordCount;

        records[_name][_recordIndex] = DnsRecord({
            recordType: _recordType,
            domain: _domain,
            location: _location,
            priority: _priority
        });

        emit DnsRecordUpdated(_user, _name, _recordIndex, _recordType, _domain, _location, _priority);
    }

    function deleteRecord(
        string memory _domain,    // web3 domain
        uint256 _index
    ) external {
        address _user = _msgSender();
        _domain = StringUtils.toLower(_domain);
        require(domains[_domain].owner == _user, "NOT_DOMAIN_OWNER");
        require(records[_domain][_index].recordType != 0, "RECORD_NA");
        delete records[_domain][_index];
        emit DnsRecordDeleted(_domain, _index);
    }

    function getRecord(
        string memory _domain,
        uint256 _index
    ) external view returns (DnsRecord memory) {
        _domain = StringUtils.toLower(_domain);
        return records[_domain][_index];
    } 

    function addCredits(
        address _user,
        uint256 _credits
    ) external onlyOwner {
        require(_credits > 0, "ZERO_VALUE");
        credits[_user] += _credits;
    }

    function registerDomain(
        string memory _tld,
        string memory _name,
        bool _isForLifetime,
        string memory _referrer
    ) external payable {
        _registerDomain(_msgSender(), _tld, _name, _isForLifetime, _referrer);
    }

    function _registerDomain(
        address _user,
        string memory _tld,
        string memory _name,
        bool _isForLifetime,
        string memory _referrer
    ) internal {
        // console.log("msg.value2: ", msg.value);
        require(bytes(_tld).length > 0, "TLD_NA");   // TLD_NOT_AVAILABLE

        _tld = StringUtils.toLower(_tld);
        require(isTldOnSale[_tld], "NOT_ON_SALE");
        
        // length >= 3, [A-Z a-z 0-9]
        if(_msgSender() != owner())
            require(StringUtils.strlen(_name) >= 3, "MIN_3_CHARS");
        require(StringUtils.checkAlphaNumeric(_name), "ONLY_ALPHANUMERIC");

        _name = StringUtils.toLower(_name);
        string memory domain = StringUtils.concatenate(_name, _tld);
        Domain memory domainData = domains[domain];
        
        // should not be already registered for lifetime
        require(!domainData.isForLifetime, "ALREADY_REG_FOR_LT");

        // when domain is locked for next 30 days after expiry
        if(block.timestamp >= domainData.expiryTimestamp && block.timestamp < domainData.expiryTimestamp + gracePeriod)
            revert("LOCKED_DOMAIN");
        
        // when 1 year is not over since the domain is registered
        if(block.timestamp < domainData.expiryTimestamp && domainData.owner != address(0))
            revert("DOMAIN_UNAVAILABLE");


        uint256 expiryTimestamp;
        if(_isForLifetime) {
            expiryTimestamp = type(uint256).max;
            uint256 creditValue = _updateCreditValue(_user, lifetimePrice);
            _rewardReferrer(_referrer, lifetimePrice);
            domains[domain] = Domain({
                tld: _tld,
                owner: _user,
                expiryTimestamp: expiryTimestamp,
                isForLifetime: true
            });
            
            _sendBackNativeToken(_user, lifetimePrice, creditValue);
        }
        else {
            expiryTimestamp = block.timestamp + 365 days;
            uint256 creditValue = _updateCreditValue(_user, annualPrice);
            _rewardReferrer(_referrer, annualPrice);
            domains[domain] = Domain({
                tld: _tld,
                owner: _user,
                expiryTimestamp: expiryTimestamp,    // register for 1 year
                isForLifetime: false
            });

            _sendBackNativeToken(_user, annualPrice, creditValue);
        }

        // console.log("tx done");
        emit NameRegistered(_user, domain, _name, _tld, _isForLifetime, _referrer, ++domainsCount, expiryTimestamp);
    }

    function _updateCreditValue(
        address _user,
        uint256 _domainPrice
    ) internal returns (uint256) {
        // 80% of payment can be done using credit points 
        // Case I (lifetime) : 25 ether * 80 / 100 = 20 ether
        // Case II (one year) : 10 ether * 80 / 100 = 8 ether
        uint256 allowedCredits =  _domainPrice * 4 / 5;
        // console.log("allowedCredits: ", allowedCredits);
        uint256 creditValue;
        if(credits[_user] >= allowedCredits)
            creditValue = allowedCredits;
        else
            creditValue = credits[_user];

        credits[_user] -= creditValue;
        require((msg.value + creditValue) >= _domainPrice, "LESS_AMOUNT");

        // console.log("creditValue: ", creditValue);
        return creditValue;
    }

    function _rewardReferrer(
        string memory _referrer,
        uint256 _domainPrice
    ) internal {
        if(bytes(_referrer).length > 0) {
            _referrer = StringUtils.toLower(_referrer);
            require(domains[_referrer].owner != address(0), "INVALID_REF");
            // console.log("ref done");

            (bool success, ) = domains[_referrer].owner.call{value: _domainPrice / 4}("");
            require(success, "SEND_BACK_FAILED");
            // console.log("ref done2: ", success);
        }
    }

    // send back remaining native tokens
    function _sendBackNativeToken(
        address _user,
        uint256 _domainPrice,
        uint256 _creditValue
    ) internal {
        if(msg.value + _creditValue > _domainPrice) {
            // console.log("prefix: ", (msg.value + _creditValue));
            // console.log("suffix: ", _domainPrice);
            (bool success, ) = _user.call{value: ((msg.value + _creditValue) - _domainPrice)}("");
            require(success, "SEND_BACK_FAILED");
        }
    }

    function mintDomain(
        string memory _domainName,
        string calldata _url
    ) external {
        address _user = _msgSender();
        _domainName = StringUtils.toLower(_domainName);
        require(tokenIdByDomain[_domainName] == 0, "ALREADY_MINTED");
        require(domains[_domainName].owner == _user, "NOT_DOMAIN_OWNER");

        _mintDomain(_user, _domainName, _url);
    }

    function _mintDomain(
        address _user,
        string memory _domainName,
        string calldata _url
    ) internal {
        _tokenIdCounter.increment();    // to start tokenId from 1
        uint256 tokenId = _tokenIdCounter.current();

        NftDetails memory nft = NftDetails({
            name: _domainName,
            url: _url
        });
        nfts[tokenId] = nft;
        tokenIdByDomain[_domainName] = tokenId;
        
        // _tokenIdCounter.increment();
        _safeMint(_user, tokenId);
        emit NftMinted(_user, _domainName, tokenId, _url);
    }

    function restoreDomains(
        address _user,
        string memory _tld,
        string memory _name
        // string calldata _url
    ) external onlyOwner {
        // console.log("msg.value2: ", msg.value);
        require(bytes(_tld).length > 0, "TLD_NA");   // TLD_NOT_AVAILABLE

        _tld = StringUtils.toLower(_tld);
        require(isTldOnSale[_tld], "NOT_ON_SALE");
        
        // length >= 3, [A-Z a-z 0-9]
        if(_msgSender() != owner())
            require(StringUtils.strlen(_name) >= 3, "MIN_3_CHARS");
        require(StringUtils.checkAlphaNumeric(_name), "ONLY_ALPHANUMERIC");

        _name = StringUtils.toLower(_name);
        string memory domain = StringUtils.concatenate(_name, _tld);
        Domain memory domainData = domains[domain];
        
        // should not be already registered for lifetime
        require(!domainData.isForLifetime, "ALREADY_REG_FOR_LT");

        // when domain is locked for next 30 days after expiry
        if(block.timestamp >= domainData.expiryTimestamp && block.timestamp < domainData.expiryTimestamp + gracePeriod)
            revert("LOCKED_DOMAIN");
        
        // when 1 year is not over since the domain is registered
        if(block.timestamp < domainData.expiryTimestamp && domainData.owner != address(0))
            revert("DOMAIN_UNAVAILABLE");

        uint256 expiryTimestamp = type(uint256).max;
        domains[domain] = Domain({
            tld: _tld,
            owner: _user,
            expiryTimestamp: type(uint256).max,
            isForLifetime: true
        });

        // console.log("tx done");
        emit NameRegistered(_user, domain, _name, _tld, true, "", ++domainsCount, expiryTimestamp);


        // require(tokenIdByDomain[domain] == 0, "ALREADY_MINTED");
        // require(domains[domain].owner == _user, "NOT_DOMAIN_OWNER");
        // _mintDomain(_user, domain, _url);
    }

    // function transferDomain(
    //     string memory _domain,
    //     address _from,
    //     address _to,
    //     // uint256 _tokenId,
    //     bool isOauthUser
    // ) external GasNotZero(_msgSender(), isOauthUser) {
    //     uint256 gasLeftInit = gasleft();

    //     _domain = StringUtils.toLower(_domain);
    //     require(domains[_domain].owner == _from, "FROM_NOT_OWNER");
    //     uint256 tokenId = tokenIdByDomain[_domain];
    //     require(tokenId != 0, "NOT_MINTED");

    //     safeTransferFrom(_from, _to, tokenId);
    //     domains[_domain].owner = _to;
        
    //     _updateGaslessData(gasLeftInit);
    // }

    // function transferDomain(
    //     address _from,
    //     address _to,
    //     uint256 _tokenId,
    //     bool isOauthUser
    // ) external GasNotZero(_msgSender(), isOauthUser) {
    //     uint256 gasLeftInit = gasleft();

    //     require(_tokenId != 0, "NOT_MINTED");
    //     string memory domain = nfts[_tokenId].name;

    //     safeTransferFrom(_from, _to, _tokenId);

    //     domains[domain].owner = _to;
    //     _updateGaslessData(gasLeftInit);
    // }

    function transferDomain(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId, /* firstTokenId */
        uint256 batchSize
    ) internal override {
        // not to be called while minting the domain
        if(from != address(0)) {
            require(tokenId != 0, "NOT_MINTED");
            string memory domain = nfts[tokenId].name;
            require(domains[domain].owner == from, "FROM_NOT_OWNER");
            domains[domain].owner = to;
        }

        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function updateOtherAccountTypes(
        uint256 _accountType,
        bool _status
    ) external onlyOwner {
        require(isAllowedAccount[_accountType] != _status, "UNCHANGED");
        isAllowedAccount[_accountType] = _status;
        emit UpdatedAllowedAccountType(_accountType, _status);
    }

    function updateOtherAccounts(
        string memory _domainName,
        uint256 _otherAccountType,
        string calldata _otherAccount
    ) external {
        address _user = _msgSender();

        _domainName = StringUtils.toLower(_domainName);
        require(domains[_domainName].owner == _user, "NOT_DOMAIN_OWNER");
        require(isAllowedAccount[_otherAccountType], "ACC_TYPE_NOT_SUPPORTED");

        otherAccounts[_domainName][_otherAccountType] = _otherAccount;

        emit UpdatedOtherAccounts(_user, _domainName, _otherAccountType, _otherAccount);
    }

    // function _concatenate(
    //     string memory _name,
    //     string memory _tld
    // ) internal pure returns (string memory) {
    //     return string(abi.encodePacked(_name, _tld));
    // }

    function _msgSender() internal view override(ContextUpgradeable, OwnableUpgradeable) returns (address) {
        return OwnableUpgradeable._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    function getBackNativeTokens(
        address payable _account
    ) external onlyOwner {
        (bool success, ) = _account.call{value: address(this).balance}("");
        require(success, "TRANSFER_FAILED");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return nfts[tokenId].url;
    }

    function updatetokenURI(
        uint256 _tokenId,
        string calldata _url
    ) external onlyOwner {
        nfts[_tokenId].url = _url;
        emit MetadataUpdated(_tokenId, _url);
    }

    receive() external payable {}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./modified/ERC721EnumerableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./interfaces/ISubscriptionModule.sol";
import "./libraries/StringUtils.sol";
import "./GasRestrictor.sol";
// import "hardhat/console.sol";

contract DappsDnsNewEnumerable is Initializable, ERC721EnumerableUpgradeable, OwnableUpgradeable {
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    struct NftDetails {
        string name;
        string url;
    }

    // tokenId => Nft
    mapping(uint256 => NftDetails) public nfts;

    // domain => tokenId
    mapping(string => uint256) public tokenIdByDomain;

    // struct Tld {
    //     string name;
    //     bool onSale;
    // }

    // mapping(bytes32 => Tld) public tlds; // top level domains
    mapping(string => bool) public isTldCreated;
    mapping(string => bool) public isTldOnSale;

    // type(1: btc, 2: polka, 3: tezos) => isAllowed
    mapping(uint256 => bool) public isAllowedAccount;

    struct Domain {
        // bytes32 dappId;
        string tld;
        address owner;
        uint256 expiryTimestamp;
        bool isForLifetime;
    }

    // name => owner
    mapping(string => Domain) public domains;

    // domain => type (1: btc, 2: polka, 3: tezos) => address
    mapping(string => mapping(uint256 => string)) public otherAccounts;

    // 1 credit = 1 wei
    mapping(address => uint256) public credits;

    uint256 public gracePeriod;

    // struct Record {
    //     string domain;
    //     string location;
    // }

    // struct MxRecord {
    //     string domain;
    //     string location;
    //     string priority;
    // }

    // struct DnsRecord {
    //     Record aRecord;
    //     Record cName;
    //     MxRecord mxRecord;
    //     Record txt;
    // }

    // // domain => dns record
    // mapping(string => DnsRecord) public records;

    // enum RecordType {
    //     A_RECORD,
    //     CNAME,
    //     MX,
    //     TXT
    // }

    struct DnsRecord {
        uint8 recordType;
        string domain;
        string location;
        uint256 priority;
    }

    uint256 public recordCount;

    // domain => index => dns record
    mapping(string => mapping(uint256 => DnsRecord)) public records;

    ISubscriptionModule public subsModule;

    GasRestrictor public gasRestrictor;

    uint256 public domainsCount;

    uint256 public annualPrice;

    uint256 public lifetimePrice;

    uint256 public tldCount;

    event TldUpdated(
        string tldName,
        bool onSale,
        uint256 count
    );

    event NameRegistered(
        address indexed account, 
        string domain,
        string name,
        string tld,
        bool isForLifetime,
        string referrerDomain,
        uint256 count
    );

    event NftMinted(
        address indexed account,
        string domain,
        uint256 tokenId,
        string metadataUrl
    );

    event UpdatedAllowedAccountType(
        uint256 accountType,
        bool status
    );
    
    event UpdatedOtherAccounts(
        address indexed user,
        string domainName,
        uint256 otherAccountType,
        string otherAccount
    );

    event DnsRecordUpdated(
        address indexed user,
        string name,               // web3 domain
        uint256 recordIndex,
        uint8 recordType,
        string domain,
        string location,
        uint256 priority
    );

    event DnsRecordDeleted(
        string domain,
        uint256 index
    );

     modifier GasNotZero(address user, bool isOauthUser) {
        _gasNotZero(user, isOauthUser);
        _;
    }

    function __DappsDns_init(
        address _subsModule,
        address _gasRestrictor,
        address _trustedForwarder,
        uint256 _annualPrice,
        uint256 _lifetimePrice
    ) public initializer {
        __ERC721_init("DappsDns", "DDNS");
        __Ownable_init(_trustedForwarder);
        subsModule = ISubscriptionModule(_subsModule);
        gasRestrictor = GasRestrictor(_gasRestrictor);
        gracePeriod = 30 days;
        annualPrice = _annualPrice;
        lifetimePrice = _lifetimePrice;
    }

    function updateAnnualPrice(uint256 _annualPrice) external onlyOwner {
        annualPrice = _annualPrice;
    }

    function updateLifetimePrice(uint256 _lifetimePrice) external onlyOwner {
        lifetimePrice = _lifetimePrice;
    }

    function updateGasRestrictor(
        GasRestrictor _gasRestrictor
    ) external onlyOwner {
        require(address(_gasRestrictor) != address(0), "ZERO_ADDRESS");
        gasRestrictor = _gasRestrictor;
    }

    function updateSubscriptionModule(
        ISubscriptionModule _subsModule
    ) external onlyOwner {
        require(address(_subsModule) != address(0), "ZERO_ADDRESS");
        subsModule = _subsModule;
    }

    function _gasNotZero(address user, bool isOauthUser) internal view {
        if (isTrustedForwarder[msg.sender]) {
            if (!isOauthUser) {
                if (
                    subsModule.getPrimaryFromSecondary(user) == address(0)
                ) {} else {
                    (, , uint256 u) = gasRestrictor.gaslessData(
                        subsModule.getPrimaryFromSecondary(user)
                    );
                    require(u != 0, "0_GASBALANCE");
                }
            } else {
                (, , uint256 u) = gasRestrictor.gaslessData(user);
                require(u != 0, "0_GASBALANCE");
            }
        }
    }

    function getDomainData(
        string memory _domain
    ) external view returns (Domain memory) {
        _domain = StringUtils.toLower(_domain);
        return domains[_domain];
    }

    function addTld( 
        string memory _tldName,
        bool _onSale
    ) external onlyOwner {
        require(bytes(_tldName).length > 0, "INVALID_TLD");
        _tldName = StringUtils.toLower(_tldName);
        require(!isTldCreated[_tldName], "TLD_EXISTS");
        isTldCreated[_tldName] = true;
        isTldOnSale[_tldName] = _onSale;
        emit TldUpdated(_tldName, _onSale, ++tldCount);
    }

    function updateTldSaleStatus(
        string memory _tld,
        bool _onSale
    ) external onlyOwner {
        require(bytes(_tld).length > 0, "INVALID_TLD");
        _tld = StringUtils.toLower(_tld);
        require(isTldOnSale[_tld] != _onSale, "UNCHANGED");
        isTldOnSale[_tld] = _onSale;
        emit TldUpdated(_tld, _onSale, tldCount);
    }

    // function setRecord(
    //     address _user,
    //     string calldata _name,      // web3 domain
    //     uint _recordType,
    //     string calldata _domain,
    //     string calldata _location,
    //     string memory _priority,
    //     bool isOauthUser
    // ) external GasNotZero(_msgSender(), isOauthUser) {
    //     uint256 gasLeftInit = gasleft();

    //     require(domains[_name].owner == _user, "NOT_DOMAIN_OWNER");

    //     if(_recordType == 1) {
    //         records[_name].aRecord = Record({
    //             domain: _domain,
    //             location: _location
    //         });
    //     }
    //     else if(_recordType == 2) {
    //         records[_name].cName = Record({
    //             domain: _domain,
    //             location: _location
    //         });
    //     }
    //     else if(_recordType == 3) {
    //         records[_name].mxRecord = MxRecord({
    //             domain: _domain,
    //             location: _location,
    //             priority: _priority
    //         });
    //     }
    //     else if(_recordType == 4) {
    //         records[_name].txt = Record({
    //             domain: _domain,
    //             location: _location
    //         });
    //     }

    //     _updateGaslessData(gasLeftInit);
    // }

    // function getRecords(string calldata _domain) external view returns (DnsRecord memory) {
    //     return records[_domain];
    // } 

    function setRecord(
        address _user,
        string memory _name,      // web3 domain
        uint256 _recordIndex,       // 0 if new record is to be added, otherwise the index to be updated
        uint8 _recordType,
        string calldata _domain,
        string calldata _location,
        uint256 _priority,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();

        _name = StringUtils.toLower(_name);
        require(domains[_name].owner == _user, "NOT_DOMAIN_OWNER");
        require(_recordType > 0 && _recordType < 5, "INVALID_TYPE");
        require(bytes(_domain).length > 0 && bytes(_location).length > 0, "INVALID_LEN");
        if(_recordIndex == 0)
            _recordIndex = ++recordCount;

        records[_name][_recordIndex] = DnsRecord({
            recordType: _recordType,
            domain: _domain,
            location: _location,
            priority: _priority
        });

        emit DnsRecordUpdated(_user, _name, _recordIndex, _recordType, _domain, _location, _priority);

        _updateGaslessData(gasLeftInit);
    }

    function deleteRecord(
        address _user,
        string memory _domain,    // web3 domain
        uint256 _index,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();

        _domain = StringUtils.toLower(_domain);
        require(domains[_domain].owner == _user, "NOT_DOMAIN_OWNER");
        require(records[_domain][_index].recordType != 0, "RECORD_NA");
        delete records[_domain][_index];
        emit DnsRecordDeleted(_domain, _index);

        _updateGaslessData(gasLeftInit);
    }

    function getRecord(
        string memory _domain,
        uint256 _index
    ) external view returns (DnsRecord memory) {
        _domain = StringUtils.toLower(_domain);
        return records[_domain][_index];
    } 

    function addCredits(
        address _user,
        uint256 _credits
    ) external onlyOwner {
        require(_credits > 0, "ZERO_VALUE");
        credits[_user] += _credits;
    }

    function registerDomain(
        address _user,
        string memory _tld,
        string calldata _name,
        bool _isForLifetime,
        string calldata _referrer,
        bool _isOauthUser
    ) external payable GasNotZero(_msgSender(), _isOauthUser) {
        uint256 gasLeftInit = gasleft();
        // console.log("msg.value1: ", msg.value);
        
        _registerDomain(_user, _tld, _name, _isForLifetime, _referrer);

        _updateGaslessData(gasLeftInit);
    }

    function _registerDomain(
        address _user,
        string memory _tld,
        string memory _name,
        bool _isForLifetime,
        string calldata _referrer
    ) internal {
        // console.log("msg.value2: ", msg.value);
        require(bytes(_tld).length > 0, "TLD_NA");   // TLD_NOT_AVAILABLE

        _tld = StringUtils.toLower(_tld);
        require(isTldOnSale[_tld], "NOT_ON_SALE");
        
        // length >= 3, [A-Z a-z 0-9]
        require(StringUtils.strlen(_name) >= 3, "MIN_3_CHARS");
        require(StringUtils.checkAlphaNumeric(_name), "ONLY_ALPHANUMERIC");

        _name = StringUtils.toLower(_name);
        string memory domain = StringUtils.concatenate(_name, _tld);
        Domain memory domainData = domains[domain];
        
        // should not be already registered for lifetime
        require(!domainData.isForLifetime, "ALREADY_REG_FOR_LT");

        // when domain is locked for next 30 days after expiry
        if(block.timestamp >= domainData.expiryTimestamp && block.timestamp < domainData.expiryTimestamp + gracePeriod)
            revert("LOCKED_DOMAIN");
        
        // when 1 year is not over since the domain is registered
        if(block.timestamp < domainData.expiryTimestamp && domainData.owner != address(0))
            revert("DOMAIN_UNAVAILABLE");


        if(_isForLifetime) {
            uint256 creditValue = _updateCreditValue(_user, lifetimePrice);
            _rewardReferrer(_referrer, lifetimePrice);
            domains[domain] = Domain({
                tld: _tld,
                owner: _user,
                expiryTimestamp: type(uint256).max,
                isForLifetime: true
            });
            
            _sendBackNativeToken(_user, lifetimePrice, creditValue);
        }
        else {
            uint256 creditValue = _updateCreditValue(_user, annualPrice);
            _rewardReferrer(_referrer, annualPrice);
            domains[domain] = Domain({
                tld: _tld,
                owner: _user,
                expiryTimestamp: block.timestamp + 365 days,    // register for 1 year
                isForLifetime: false
            });

            _sendBackNativeToken(_user, annualPrice, creditValue);
        }

        // console.log("tx done");
        emit NameRegistered(_user, domain, _name, _tld, _isForLifetime, _referrer, ++domainsCount);
    }

    function _updateCreditValue(
        address _user,
        uint256 _domainPrice
    ) internal returns (uint256) {
        // 80% of payment can be done using credit points 
        // Case I (lifetime) : 25 ether * 80 / 100 = 20 ether
        // Case II (one year) : 10 ether * 80 / 100 = 8 ether
        uint256 allowedCredits =  _domainPrice * 4 / 5;
        // console.log("allowedCredits: ", allowedCredits);
        uint256 creditValue;
        if(credits[_user] >= allowedCredits)
            creditValue = allowedCredits;
        else
            creditValue = credits[_user];

        credits[_user] -= creditValue;
        require((msg.value + creditValue) >= _domainPrice, "LESS_AMOUNT");

        // console.log("creditValue: ", creditValue);
        return creditValue;
    }

    function _rewardReferrer(
        string calldata _referrer,
        uint256 _domainPrice
    ) internal {
        if(bytes(_referrer).length > 0) {
            require(domains[_referrer].owner != address(0), "INVALID_REF");
            // console.log("ref done");

            (bool success, ) = domains[_referrer].owner.call{value: _domainPrice / 4}("");
            require(success, "SEND_BACK_FAILED");
            // console.log("ref done2: ", success);
        }
    }

    // send back remaining native tokens
    function _sendBackNativeToken(
        address _user,
        uint256 _domainPrice,
        uint256 _creditValue
    ) internal {
        if(msg.value + _creditValue > _domainPrice) {
            // console.log("prefix: ", (msg.value + _creditValue));
            // console.log("suffix: ", _domainPrice);
            (bool success, ) = _user.call{value: ((msg.value + _creditValue) - _domainPrice)}("");
            require(success, "SEND_BACK_FAILED");
        }
    }

    function mintDomain(
        address _user,
        string memory _domainName,
        string calldata _url,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();

        _domainName = StringUtils.toLower(_domainName);
        require(tokenIdByDomain[_domainName] == 0, "ALREADY_MINTED");
        require(domains[_domainName].owner == _user, "NOT_DOMAIN_OWNER");

        _mintDomain(_user, _domainName, _url);

        _updateGaslessData(gasLeftInit);
    }

    function _mintDomain(
        address _user,
        string memory _domainName,
        string calldata _url
    ) internal {
        _tokenIdCounter.increment();    // to start tokenId from 1
        uint256 tokenId = _tokenIdCounter.current();

        NftDetails memory nft = NftDetails({
            name: _domainName,
            url: _url
        });
        nfts[tokenId] = nft;
        tokenIdByDomain[_domainName] = tokenId;
        
        // _tokenIdCounter.increment();
        _safeMint(_user, tokenId);
        emit NftMinted(_user, _domainName, tokenId, _url);
    }

    function transferFrom(
        string memory _domain,
        address _from,
        address _to,
        // uint256 _tokenId,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();

        _domain = StringUtils.toLower(_domain);
        require(domains[_domain].owner == _from, "FROM_NOT_OWNER");
        uint256 tokenId = tokenIdByDomain[_domain];
        require(tokenId != 0, "NOT_MINTED");

        safeTransferFrom(_from, _to, tokenId);
        domains[_domain].owner = _to;
        
        _updateGaslessData(gasLeftInit);
    }

    function updateOtherAccountTypes(
        uint256 _accountType,
        bool _status
    ) external onlyOwner {
        require(isAllowedAccount[_accountType] != _status, "UNCHANGED");
        isAllowedAccount[_accountType] = _status;
        emit UpdatedAllowedAccountType(_accountType, _status);
    }

    function updateOtherAccounts(
        address _user,
        string memory _domainName,
        uint256 _otherAccountType,
        string calldata _otherAccount,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();

        _domainName = StringUtils.toLower(_domainName);
        require(domains[_domainName].owner == _user, "NOT_DOMAIN_OWNER");
        require(isAllowedAccount[_otherAccountType], "ACC_TYPE_NOT_SUPPORTED");

        otherAccounts[_domainName][_otherAccountType] = _otherAccount;

        emit UpdatedOtherAccounts(_user, _domainName, _otherAccountType, _otherAccount);
        _updateGaslessData(gasLeftInit);
    }

    // function _concatenate(
    //     string memory _name,
    //     string memory _tld
    // ) internal pure returns (string memory) {
    //     return string(abi.encodePacked(_name, _tld));
    // }

    function _updateGaslessData(uint256 _gasLeftInit) internal {
        if (isTrustedForwarder[msg.sender]) {
            gasRestrictor._updateGaslessData(_msgSender(), _gasLeftInit);
        }
    }

    function _msgSender() internal view override(ContextUpgradeable, OwnableUpgradeable) returns (address) {
        return OwnableUpgradeable._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, ERC2771ContextUpgradeable) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }

    function getBackNativeTokens(
        address payable _account
    ) external onlyOwner {
        (bool success, ) = _account.call{value: address(this).balance}("");
        require(success, "TRANSFER_FAILED");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return nfts[tokenId].url;
    }

    receive() external payable {}

}

// SPDX-License-Identifier: GPL-3.0-or-later

// OpenZeppelin Contracts v4.3.2 (metatx/ERC2771Context.sol)

pragma solidity ^0.8.4;

// import {Initializable} from "../proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


/**
 * @dev Context variant with ERC2771 support.
 */
// solhint-disable
abstract contract ERC2771ContextUpgradeable is Initializable {
    // address public trustedForwarder;
    mapping(address=>bool) public isTrustedForwarder;

    function __ERC2771ContextUpgradeable_init(address tForwarder) internal initializer {
        __ERC2771ContextUpgradeable_init_unchained(tForwarder);
    }

    function __ERC2771ContextUpgradeable_init_unchained(address tForwarder) internal {
        isTrustedForwarder[tForwarder] = true;
    }

    function addOrRemovetrustedForwarder(address _forwarder, bool status) public  virtual  {
        require( isTrustedForwarder[_forwarder] != status, "same satus");
        isTrustedForwarder[_forwarder] = status;
    }



    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder[msg.sender]) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder[msg.sender]) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// import "./sdkInterFace/subscriptionModulesI.sol";
import "./OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./SubscriptionModule.sol";
import "./GasRestrictor.sol";

contract Gamification is Initializable, OwnableUpgradeable {
 
    struct Reaction {
        string reactionName;
        uint256 count;
    }

    struct EbookDetails {
        string title;
        string summary;
        string assetFile;
        string assetSampleFile;
        string coverImage;
        bool isSendNotif;
        bool isShowApp;
        string aboutCompany;
        string aboutImage;
    }

    struct Message {
        address sender;
        bytes32 senderDappID; // encrypted using receiver's public key
        bytes32 receiverDappId;
        string textMessageEncryptedForReceiver; // encrypted using sender's public key
        string textMessageEncryptedForSender; // encrypted using sender's public key
        uint256 timestamp;
    }


    struct WelcomeMessage {
        string message;
        string cta;
        string buttonName;
    }

    struct EbookMessage {
        string message;
        string cta;
        string buttonName;
    }

    struct Token {
        bytes32 appId;
        address _tokenAddress;
        uint256 _tokenType; // ERC20, ERC721 (20, 721)
    }

    struct TokenNotif {
        bytes32 _id;
        string message;
        uint256 reactionCounts;
        address _token;
    }
    mapping(bytes32 => EbookMessage) public ebookMessage;
    mapping(bytes32 => WelcomeMessage) public welcomeMessage;

    // dappId => ebook
    mapping(bytes32 => EbookDetails) public ebooks;

    // from -> to -> messageID
    mapping(bytes32 => mapping(bytes32 => uint256)) public messageIdOfDapps; //
    uint256 public messageIdCount;
    mapping(uint256 => Message[]) public messages;

    mapping(address => bool) public isDappsContract;
    GasRestrictor public gasRestrictor;

    SubscriptionModule public subscriptionModule;

    mapping(address => uint256) public karmaPoints;
    //tokenNotifID => tokenNotif
    mapping(bytes32 => TokenNotif) public singleTokenNotif;
    // tokenNotifId=>react=>count
    mapping(bytes32 => mapping(string => uint256))
        public reactionsOfTokenNotifs;
    // tokenNotifId => user => reactionStatus;
    mapping(bytes32 => mapping(address => bool)) public reactionStatus;

    // string ReactionName => isValid bool
    mapping(string => bool) public isValidReaction;

    // appId => Tokens
    mapping(bytes32 => Token[]) public tokenOfVerifiedApp;
    // tokenAddress => tokenDetails
    mapping(address => Token) public tokenByTokenAddress;

    event NewTokenNotif(bytes32 appID, bytes32 _id, address token);

    event NewDappMessage(bytes32 from, bytes32 to, uint256 messageId);

    event EbookUpdated(bytes32 dappId);

    modifier GasNotZero(address user, bool isOauthUser) {
        _gasNotZero(user, isOauthUser);
        _;
    }

    modifier isDapp(address dapp) {
        require(isDappsContract[dapp] == true, "Not_registred_dapp");
        _;
    }
    modifier isValidApp(bytes32 dappId) {
        _isValidApp(dappId);
        _;
    }
    modifier onlySuperAdmin() {
        _onlySuperAdmin();
        _;
    }

    modifier superAdminOrDappAdmin(bytes32 appID) {
        _superAdminOrDappAdmin(appID);
        _;
    }

    modifier superAdminOrDappAdminOrAddedAdmin(bytes32 appID) {
        _superAdminOrDappAdminOrAddedAdmin(appID);
        _;
    }

    function init_Gamification(
        address _subscriptionModule,
        address _trustedForwarder,
        GasRestrictor _gasRestrictor
    ) public initializer {
        subscriptionModule = SubscriptionModule(_subscriptionModule);
        isDappsContract[_subscriptionModule] = true;
        __Ownable_init(_trustedForwarder);
        gasRestrictor = _gasRestrictor;
    }

    function _isValidApp(bytes32 _appId) internal view {
        address a = subscriptionModule.getDappAdmin(_appId);
        require(a != address(0), "INVALID_DAPP");
    }

    function _gasNotZero(address user, bool isOauthUser) internal view {
        if (isTrustedForwarder[msg.sender]) {
            if (!isOauthUser) {
                if (
                    subscriptionModule.getPrimaryFromSecondary(user) == address(0)
                ) {} else {
                    (, , uint256 u) = gasRestrictor.gaslessData(
                        subscriptionModule.getPrimaryFromSecondary(user)
                    );
                    require(u != 0, "0_GASBALANCE");
                }
            } else {
                (, , uint256 u) = gasRestrictor.gaslessData(user);
                require(u != 0, "0_GASBALANCE");
            }
        }
    }

    function _onlySuperAdmin() internal view {
        require(
            _msgSender() == owner() ||
                _msgSender() ==
                subscriptionModule.getSecondaryWalletAccount(owner()),
            "INVALID_SENDER"
        );
    }

    function _superAdminOrDappAdmin(bytes32 _appID) internal view {
        address appAdmin = subscriptionModule.getDappAdmin(_appID);
        require(
            _msgSender() == owner() ||
                _msgSender() ==
                subscriptionModule.getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() ==
                subscriptionModule.getSecondaryWalletAccount(appAdmin),
            "INVALID_SENDER"
        );
    }

    function _superAdminOrDappAdminOrAddedAdmin(bytes32 _appID) internal view {
        address appAdmin = subscriptionModule.getDappAdmin(_appID);
        require(
            _msgSender() == owner() ||
                _msgSender() ==
                subscriptionModule.getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() ==
                subscriptionModule.getSecondaryWalletAccount(appAdmin) ||
                subscriptionModule.accountRole(_msgSender(), _appID) == 2 ||
                subscriptionModule.accountRole(_msgSender(), _appID) == 3,
            "INVALID_SENDER"
        );
    }

    function addDapp(address dapp) external onlyOwner {
        isDappsContract[dapp] = true;
    }

    function addKarmaPoints(address _for, uint256 amount)
        public
        isDapp(msg.sender)
    {
        karmaPoints[_for] = karmaPoints[_for] + amount;
    }

    function removeKarmaPoints(address _for, uint256 amount)
        public
        isDapp(msg.sender)
    {
        require(karmaPoints[_for] > amount, "not enough karma points");
        karmaPoints[_for] = karmaPoints[_for] - amount;
    }

    function sendNotifTokenHolders(
        bytes32 _appID,
        string memory _message,
        address _tokenAddress,
        bool isOAuthUser
    )
        public
        GasNotZero(_msgSender(), isOAuthUser)
        superAdminOrDappAdmin(_appID)
    {
        uint256 gasLeftInit = gasleft();
        address _token = tokenByTokenAddress[_tokenAddress]._tokenAddress;
        require(_token != address(0), "NOT_VERIFIED");
        require(
            tokenByTokenAddress[_tokenAddress].appId == _appID,
            "Not Token Of App"
        );
        // check if msg.sender is tokenAdmin/superAdmin

        bytes32 _tokenNotifID;
        _tokenNotifID = keccak256(
            abi.encode(block.number, _msgSender(), block.timestamp)
        );

        singleTokenNotif[_tokenNotifID] = TokenNotif(
            _tokenNotifID,
            _message,
            0,
            _tokenAddress
        );

        emit NewTokenNotif(_appID, _tokenNotifID, _token);

        _updateGaslessData(gasLeftInit);
    }

    function reactToTokenNotif(bytes32 tokenNotifId, string memory reaction)
        external
    {
        require(singleTokenNotif[tokenNotifId]._id == tokenNotifId, "WRONG_ID");
        require(
            reactionStatus[tokenNotifId][_msgSender()] == false,
            "WRONG_ID"
        );
        require(isValidReaction[reaction] == true, "WRONG_R");
        uint256 gasLeftInit = gasleft();

        uint256 _type = tokenByTokenAddress[
            singleTokenNotif[tokenNotifId]._token
        ]._tokenType;
        address token = singleTokenNotif[tokenNotifId]._token;
        if (_type == 20 || _type == 721) {
            require(IERC20(token).balanceOf(_msgSender()) > 0);
        }

        reactionsOfTokenNotifs[tokenNotifId][reaction]++;
        singleTokenNotif[tokenNotifId].reactionCounts++;

        reactionStatus[tokenNotifId][_msgSender()] = true;

        _updateGaslessData(gasLeftInit);
    }

    function addValidReactions(string memory _reaction)
        external
        onlySuperAdmin
    {
        isValidReaction[_reaction] = true;
    }

    function updateDappToken(
        bytes32 _appId,
        address[] memory _tokens,
        uint256[] memory _types // bool _isOauthUser
    ) external superAdminOrDappAdmin(_appId) isValidApp(_appId) {
        // onlySuperAdmin
        uint256 gasLeftInit = gasleft();

        require(_tokens.length == _types.length, "INVALID_PARAM");

        for (uint256 i = 0; i < _tokens.length; i++) {
            Token memory _t = Token(_appId, _tokens[i], _types[i]);
            tokenOfVerifiedApp[_appId].push(_t);
            tokenByTokenAddress[_tokens[i]] = _t;
        }

        _updateGaslessData(gasLeftInit);
    }

    function deleteDappToken(bytes32 _appId)
        external
        superAdminOrDappAdmin(_appId)
        isValidApp(_appId)
    {
        require(tokenOfVerifiedApp[_appId].length != 0, "No Token");

        delete tokenOfVerifiedApp[_appId];
    }

    function updateWelcomeMessage(
        bytes32 _appId,
        string memory _message,
        string memory _cta,
        string memory _buttonName
    ) public superAdminOrDappAdmin(_appId) isValidApp(_appId) {
        welcomeMessage[_appId].message = _message;
        welcomeMessage[_appId].buttonName = _buttonName;
        welcomeMessage[_appId].cta = _cta;
    }

    function updateEbookMessage(
        bytes32 _appId,
        string memory _message,
        string memory _cta,
        string memory _buttonName
    ) public superAdminOrDappAdmin(_appId) isValidApp(_appId) {
        ebookMessage[_appId].message = _message;
        ebookMessage[_appId].buttonName = _buttonName;
        ebookMessage[_appId].cta = _cta;
    }

    function sendMessageToDapp(
        bytes32 appFrom,
        bytes32 appTo,
        string memory encMessageForReceiverDapp,
        string memory enMessageForSenderDapp,
        bool isOAuthUser
    )
        public
        superAdminOrDappAdmin(appFrom)
        isValidApp(appFrom)
        isValidApp(appTo)
        GasNotZero(_msgSender(), isOAuthUser)
    {
        bool isVerified = subscriptionModule.getDapp(appFrom).isVerifiedDapp;
        // check isVerified Dapp OR Not
        require(isVerified == true, "App Not Verified");

        Message memory message = Message({
            sender: _msgSender(),
            senderDappID: appFrom,
            receiverDappId: appTo,
            textMessageEncryptedForReceiver: encMessageForReceiverDapp,
            textMessageEncryptedForSender: enMessageForSenderDapp,
            timestamp: block.timestamp
        });

        uint256 messageId = messageIdOfDapps[appFrom][appTo];
        if (messageId == 0) {
            messageId = ++messageIdCount;
            messageIdOfDapps[appFrom][appTo] = messageId;
            messageIdOfDapps[appTo][appFrom] = messageId;
        }
        messages[messageId].push(message);

        emit NewDappMessage(appFrom, appTo, messageId);
    }


    function updateEbook(
        bytes32 _appId,
        EbookDetails memory _ebookDetails,
        bool _isAuthUser
    )
        external
        superAdminOrDappAdminOrAddedAdmin(_appId)
        GasNotZero(_msgSender(), _isAuthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(
            subscriptionModule.getDappAdmin(_appId) != address(0),
            "INVALID DAPP ID"
        );
        require(bytes(_ebookDetails.title).length != 0, "EMPTY_TITLE");
        EbookDetails memory ebookDetails = EbookDetails({
            title: _ebookDetails.title,
            summary: _ebookDetails.summary,
            assetFile: _ebookDetails.assetFile,
            assetSampleFile: _ebookDetails.assetSampleFile,
            coverImage: _ebookDetails.coverImage,
            isSendNotif: _ebookDetails.isSendNotif,
            isShowApp: _ebookDetails.isShowApp,
            aboutCompany: _ebookDetails.aboutCompany,
            aboutImage: _ebookDetails.aboutImage
        });
        ebooks[_appId] = ebookDetails;

        emit EbookUpdated(_appId);

        _updateGaslessData(gasLeftInit);
    }

  

    function getWelcomeMessage(bytes32 _appId) external view returns(string memory, string memory, string memory){

        if (ebooks[_appId].isSendNotif)
            return (ebookMessage[_appId].message, ebookMessage[_appId].cta, ebookMessage[_appId].buttonName);
        else             
            return (welcomeMessage[_appId].message, welcomeMessage[_appId].cta, welcomeMessage[_appId].buttonName);


    }

      function _updateGaslessData(uint256 _gasLeftInit) internal {
        if (isTrustedForwarder[msg.sender]) {
            gasRestrictor._updateGaslessData(_msgSender(), _gasLeftInit);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import {UnifarmAccountsUpgradeable} from "./UnifarmAccountsUpgradeable.sol";
import "./SubscriptionModule.sol";
contract GasRestrictor is Initializable, OwnableUpgradeable {
    uint256 public initialGasLimitInNativeCrypto; // i.e matic etc
    SubscriptionModule public subscriptionModule;
    struct GaslessData {
        address userSecondaryAddress;
        address userPrimaryAddress;
        uint256 gasBalanceInNativeCrypto;
    }

    // primary to gaslessData
    mapping(address => GaslessData) public gaslessData;

// mapping of contract address who are allowed to do changes
    mapping(address=>bool) public isDappsContract;

    
      modifier isDapp(address dapp) {
      
        require(
                isDappsContract[dapp] == true,
                "Not_registred_dapp"
        );
          _;

        
    }
   
    function init_Gasless_Restrictor(
        address _subscriptionModule,
        uint256 _gaslimit,
        address _trustedForwarder
    ) public initializer {
        initialGasLimitInNativeCrypto = _gaslimit;
        subscriptionModule = SubscriptionModule(_subscriptionModule);
        isDappsContract[_subscriptionModule] = true;
        __Ownable_init(_trustedForwarder);

    }
    

    function updateInitialGasLimit(uint256 _gaslimit) public onlyOwner {
        initialGasLimitInNativeCrypto = _gaslimit;
    }

    function getGaslessData(address _user) view virtual external returns(GaslessData memory) {
      return  gaslessData[_user];
    }

    function initUser(address primary, address secondary, bool isOauthUser) external isDapp(msg.sender){
        if(isOauthUser) {
        gaslessData[secondary].gasBalanceInNativeCrypto = initialGasLimitInNativeCrypto;
        gaslessData[secondary].userSecondaryAddress = secondary;
        }
        else {
        gaslessData[primary].gasBalanceInNativeCrypto = initialGasLimitInNativeCrypto;
        gaslessData[primary].userPrimaryAddress = primary;
        gaslessData[primary].userSecondaryAddress = secondary;
        }
      
    }

    function _updateGaslessData(address user, uint initialGasLeft) external isDapp(msg.sender){
      address primary = subscriptionModule.getPrimaryFromSecondary(user);
        if (primary == address(0)) {
            return;
        } else {
            gaslessData[primary].gasBalanceInNativeCrypto =
                gaslessData[primary].gasBalanceInNativeCrypto -
                (initialGasLeft - gasleft()) *
                tx.gasprice;
         
        }
    }

   function addDapp(address dapp) external onlyOwner {
    isDappsContract[dapp] = true;
   }

    function addGas(address userPrimaryAddress) external payable{ 
      require(msg.value> 0 , "gas should be more than 0");
      gaslessData[userPrimaryAddress].gasBalanceInNativeCrypto =   gaslessData[userPrimaryAddress].gasBalanceInNativeCrypto + msg.value;

    }

     function withdrawGasFunds(uint amount, address to) external onlyOwner {
     require(amount <= address(this).balance);
      payable(to).transfer(amount);
    }

    
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./OwnableUpgradeable.sol";

contract Greeter is OwnableUpgradeable {
mapping(address=> string) public greetings;
    constructor(string memory _greeting, address trustedForwarded) {
        console.log("Deploying a Greeter with greeting:", _greeting);
      __Ownable_init(trustedForwarded);
    }

    function greet() public view returns (string memory) {
        return greetings[_msgSender()];
    }

    function setGreeting(string memory _greeting) public {
        console.log("Changing greeting from '%s' to '%s'", _greeting);
        greetings[_msgSender()] = _greeting;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @dev Context variant with ERC2771 support.
 */
 contract ERC2771Context  {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view  returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender2() internal view  returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return tx.origin;
        }
    }

    function _msgData2() internal view   returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC2771Context.sol";
// import "./GasRestrictor.sol";

 contract UnifarmAccountsUpgradeableHedera is Ownable, Pausable, ERC2771Context {
  uint256 public chainId;
  uint256 public defaultCredits;
  uint256 public renewalPeriod;
  // GasRestrictor public gasRestrictor;

  // --------------------- DAPPS STORAGE -----------------------

  struct Role {
    bool sendNotificationRole;
    bool addAdminRole;
  }
  struct SecondaryWallet {
    address account;
    string encPvtKey;
    string publicKey;
  }

  struct Dapp {
    string appName;
    bytes32 appId;
    address appAdmin; //primary
    string appUrl;
    string appIcon;
    string appSmallDescription;
    string appLargeDescription;
    string appCoverImage;
    string[] appScreenshots; // upto 5
    string[] appCategory; // upto 7
    string[] appTags; // upto 7
    bool isVerifiedDapp; // true or false
    uint256 credits;
    uint256 renewalTimestamp;
  }

  struct Notification {
    bytes32 appID;
    address walletAddressTo; // primary
    string message;
    string buttonName;
    string cta;
    uint256 timestamp;
    bool isEncrypted;
  }
  mapping(bytes32 => Dapp) public dapps;

  // all dapps count
  uint256 public dappsCount;
  uint256 public verifiedDappsCount;

  mapping(address => Notification[]) public notificationsOf;
  // dappId => count
  mapping(bytes32 => uint256) public notificationsCount;

  // dappId => count
  mapping(bytes32 => uint256) public subscriberCount;

  // dappID => dapp

  // address => dappId  => role
  mapping(address => mapping(bytes32 => Role)) public roleOfAddress;

  // dappId => address => bool(true/false)
  mapping(bytes32 => mapping(address => bool)) public isSubscribed;

  // userAddress  => Wallet
  mapping(address => SecondaryWallet) public userWallets;
  // secondary to primary wallet mapping to get primary wallet from secondary
  mapping(address => address) public getPrimaryFromSecondary;

  modifier onlySuperAdmin() {
    require( _msgSender2() == owner() ||  _msgSender2() == getSecondaryWalletAccount(owner()), 'INVALID_SENDER');
    _;
  }
  modifier isValidSender(address from) {
    require( _msgSender2() == from ||  _msgSender2() == getSecondaryWalletAccount(from), 'INVALID_SENDER');
    _;
  }

  modifier superAdminOrDappAdminOrAddedAdmin(bytes32 appID) {
    address appAdmin = getDappAdmin(appID);
    require(
       _msgSender2() == owner() ||
         _msgSender2() == getSecondaryWalletAccount(owner()) ||
         _msgSender2() == appAdmin ||
         _msgSender2() == getSecondaryWalletAccount(appAdmin) ||
        roleOfAddress[ _msgSender2()][appID].addAdminRole == true,
      'INVALID_SENDER'
    );
    _;
  }
  modifier superAdminOrDappAdminOrSendNotifRole(bytes32 appID) {
    address appAdmin = getDappAdmin(appID);
    require(
       _msgSender2() == owner() ||
         _msgSender2() == getSecondaryWalletAccount(owner()) ||
         _msgSender2() == appAdmin ||
         _msgSender2() == getSecondaryWalletAccount(appAdmin) ||
        roleOfAddress[ _msgSender2()][appID].sendNotificationRole == true,
      'INVALID_SENDER'
    );
    _;
  }

  // modifier GasNotZero(address user) {
  //     if (getPrimaryFromSecondary[user] == address(0)) {
  //         _;
  //     } else {
  //         (, , uint256 u) = gasRestrictor.gaslessData(
  //             getPrimaryFromSecondary[user]
  //         );
  //         require(u != 0, "NOT_ENOUGH_GASBALANCE");
  //         _;
  //     }
  // }

  event NewAppRegistered(bytes32 appID, address appAdmin, string appName, uint256 dappCount);

  event AppAdmin(bytes32 appID, address appAdmin, address admin, uint8 role);

  event AppSubscribed(bytes32 appID, address subscriber, uint256 count);

  event AppUnSubscribed(bytes32 appID, address subscriber, uint256 count);

  event NewNotification(
    bytes32 appId,
    address walletAddress,
    string message,
    string buttonName,
    string cta,
    bool isEncrypted
  );

  // function __UnifarmAccounts_init(
  //     uint256 _chainId,
  //     uint256 _defaultCredits,
  //     uint256 _renewalPeriod,
  //     address _trustedForwarder
  // ) public initializer {
  //     chainId = _chainId;
  //     defaultCredits = _defaultCredits;
  //     renewalPeriod = _renewalPeriod;
  //     __Ownable_init(_trustedForwarder);
  // }

  constructor(
    uint256 _chainId,
    uint256 _defaultCredits,
    uint256 _renewalPeriod,
 address _trustedForwarder) ERC2771Context(_trustedForwarder)
  {
    chainId = _chainId;
    defaultCredits = _defaultCredits;
    renewalPeriod = _renewalPeriod;

  }

  // -------------------- DAPP FUNCTIONS ------------------------

  function addNewDapp(
    string memory _appName,
    address _appAdmin, //primary
    string memory _appUrl,
    string memory _appIcon,
    string memory _appCoverImage,
    string memory _appSmallDescription,
    string memory _appLargeDescription,
    string[] memory _appScreenshots,
    string[] memory _appCategory,
    string[] memory _appTags
  ) external {
    uint256 gasLeftInit = gasleft();
    require(_appAdmin != address(0), '0 address');
    require(_appScreenshots.length < 6, 'surpassed image limit');
    require(_appCategory.length < 8, 'surpassed image limit');
    require(_appTags.length < 8, 'surpassed image limit');

    _addNewDapp(
      _appName,
      _appAdmin,
      _appUrl,
      _appIcon,
      _appCoverImage,
      _appSmallDescription,
      _appLargeDescription,
      _appScreenshots,
      _appCategory,
      _appTags
    );
    dappsCount++;
    // if (msg.sender == trustedForwarder) {
    //     gasRestrictor._updateGaslessData( _msgSender2(), gasLeftInit);
    // }
  }

  function _addNewDapp(
    string memory _appName,
    address _appAdmin, //primary
    string memory _appUrl,
    string memory _appIcon,
    string memory _appCoverImage,
    string memory _appSmallDescription,
    string memory _appLargeDescription,
    string[] memory _appScreenshots,
    string[] memory _appCategory,
    string[] memory _appTags
  ) internal {
    bytes32 _appID;
    Dapp memory dapp = Dapp({
      appName: _appName,
      appId: _appID,
      appAdmin: _appAdmin,
      appUrl: _appUrl,
      appIcon: _appIcon,
      appCoverImage: _appCoverImage,
      appSmallDescription: _appSmallDescription,
      appLargeDescription: _appLargeDescription,
      appScreenshots: _appScreenshots,
      appCategory: _appCategory,
      appTags: _appTags,
      isVerifiedDapp: false,
      credits: defaultCredits,
      renewalTimestamp: block.timestamp
    });
    _appID = keccak256(abi.encode(dapp, block.number,  _msgSender2(), dappsCount, chainId));
    dapp.appId = _appID;

    dapps[_appID] = dapp;
    emit NewAppRegistered(_appID, _appAdmin, _appName, dappsCount++);
  }

  function subscribeToDapp(
    address user,
    bytes32 appID,
    bool subscriptionStatus
  ) external isValidSender(user) {
    uint256 gasLeftInit = gasleft();
    require(dapps[appID].appAdmin != address(0), 'INVALID DAPP ID');
    require(isSubscribed[appID][user] != subscriptionStatus, 'UNCHANGED');

    isSubscribed[appID][user] = subscriptionStatus;

    if (subscriptionStatus) {
      subscriberCount[appID] += 1;
      emit AppSubscribed(appID, user, subscriberCount[appID]);
    } else {
      subscriberCount[appID] -= 1;
      emit AppUnSubscribed(appID, user, subscriberCount[appID]);
    }
    if (address(0) != getSecondaryWalletAccount(user)) {
      isSubscribed[appID][getSecondaryWalletAccount(user)] = subscriptionStatus;
    }

    //    if(msg.sender == trustedForwarder) {
    // gasRestrictor._updateGaslessData( _msgSender2(), gasLeftInit);
    //    }
  }

  function appVerification(bytes32 appID, bool verificationStatus) external onlySuperAdmin {
    uint256 gasLeftInit = gasleft();

    require(dapps[appID].appAdmin != address(0), 'INVALID DAPP ID');
    // require(appID < dappsCount, "INVALID DAPP ID");
    if (dapps[appID].isVerifiedDapp != verificationStatus && verificationStatus) {
      verifiedDappsCount++;
      dapps[appID].isVerifiedDapp = verificationStatus;
    } else if (dapps[appID].isVerifiedDapp != verificationStatus && !verificationStatus) {
      verifiedDappsCount--;
      dapps[appID].isVerifiedDapp = verificationStatus;
    }

    // if (msg.sender == trustedForwarder) {
    //     gasRestrictor._updateGaslessData( _msgSender2(), gasLeftInit);
    // }
  }

  function getDappAdmin(bytes32 _dappId) public view returns (address) {
    return dapps[_dappId].appAdmin;
  }

  // -------------------- WALLET FUNCTIONS -----------------------

  function addAppAdmin(
    bytes32 appID,
    address admin, // primary address
    uint8 _role // 0 meaning only notif, 1 meaning only add admin, 2 meaning both
  ) external superAdminOrDappAdminOrAddedAdmin(appID) {
    uint256 gasLeftInit = gasleft();

    require(dapps[appID].appAdmin != address(0), 'INVALID DAPP ID');
    require(_role < 3, 'INAVLID ROLE');
    if (_role == 0) {
      roleOfAddress[admin][appID].addAdminRole = false;
      roleOfAddress[getSecondaryWalletAccount(admin)][appID].addAdminRole = false;
      roleOfAddress[admin][appID].sendNotificationRole = true;
      roleOfAddress[getSecondaryWalletAccount(admin)][appID].sendNotificationRole = true;
    } else if (_role == 1) {
      roleOfAddress[admin][appID].addAdminRole = true;
      roleOfAddress[getSecondaryWalletAccount(admin)][appID].addAdminRole = true;
      roleOfAddress[admin][appID].sendNotificationRole = false;
      roleOfAddress[getSecondaryWalletAccount(admin)][appID].sendNotificationRole = false;
    } else if (_role == 2) {
      roleOfAddress[admin][appID].addAdminRole = true;
      roleOfAddress[getSecondaryWalletAccount(admin)][appID].addAdminRole = true;
      roleOfAddress[admin][appID].sendNotificationRole = true;
      roleOfAddress[getSecondaryWalletAccount(admin)][appID].sendNotificationRole = true;
    }
    emit AppAdmin(appID, getDappAdmin(appID), admin, _role);
    // if (msg.sender == trustedForwarder) {
    //     gasRestrictor._updateGaslessData( _msgSender2(), gasLeftInit);
    // }
  }

  // primary wallet address.
  function sendAppNotification(
    bytes32 _appId,
    address walletAddress,
    string memory _message,
    string memory buttonName,
    string memory _cta,
    bool _isEncrypted
  ) external superAdminOrDappAdminOrSendNotifRole(_appId) {
    uint256 gasLeftInit = gasleft();

    require(dapps[_appId].appAdmin != address(0), 'INVALID DAPP ID');
    require(dapps[_appId].credits != 0, 'NOT_ENOUGH_CREDITS');
    require(isSubscribed[_appId][walletAddress] == true, 'NOT_SUBSCRIBED');
    Notification memory notif = Notification({
      appID: _appId,
      walletAddressTo: walletAddress,
      message: _message,
      buttonName: buttonName,
      cta: _cta,
      timestamp: block.timestamp,
      isEncrypted: _isEncrypted
    });

    notificationsOf[walletAddress].push(notif);
    notificationsCount[_appId] += 1;
    emit NewNotification(_appId, walletAddress, _message, buttonName, _cta, _isEncrypted);
    dapps[_appId].credits = dapps[_appId].credits - 1;

    // if (msg.sender == trustedForwarder) {
    //     gasRestrictor._updateGaslessData( _msgSender2(), gasLeftInit);
    // }
  }

  function createWallet(
    address _account,
    string calldata _encPvtKey,
    string calldata _publicKey
  ) external {
    require(userWallets[ _msgSender2()].account == address(0), 'ACCOUNT_ALREADY_EXISTS');
    SecondaryWallet memory wallet = SecondaryWallet({account: _account, encPvtKey: _encPvtKey, publicKey: _publicKey});
    userWallets[ _msgSender2()] = wallet;
    getPrimaryFromSecondary[_account] =  _msgSender2();

    // gasRestrictor.initUser( _msgSender2(), _account);
  }

  function getNotificationsOf(address user) external view returns (Notification[] memory) {
    return notificationsOf[user];
  }

  function getSecondaryWalletAccount(address _account) public view returns (address) {
    return userWallets[_account].account;
  }

  function uintToBytes32(uint256 num) public pure returns (bytes32) {
    return bytes32(num);
  }

  function getDapp(bytes32 dappId) public view returns (Dapp memory) {
    return dapps[dappId];
  }

  // function upgradeCreditsByAdmin( bytes32 dappId,uint amount ) external onlySuperAdmin() {
  //     dapps[dappId].credits = defaultCredits + amount;
  // }

  function renewCredits(bytes32 dappId) external superAdminOrDappAdminOrAddedAdmin(dappId) {
    uint256 gasLeftInit = gasleft();

    require(block.timestamp - dapps[dappId].renewalTimestamp == renewalPeriod, 'RENEWAL_PERIOD_NOT_COMPLETED');
    dapps[dappId].credits = defaultCredits;

    // if (msg.sender == trustedForwarder) {
    //     gasRestrictor._updateGaslessData( _msgSender2(), gasLeftInit);
    // }
  }

  function deleteWallet(address _account) external onlySuperAdmin {
    require(userWallets[ _msgSender2()].account != address(0), 'NO_ACCOUNT');
    delete userWallets[_account];
    delete getPrimaryFromSecondary[_account];
  }



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISubscriptionModule {
    
    function isSubscribed(
        bytes32 _dappId,
        uint256 listID,
        address _user
    ) external view returns (bool);

    function getDappAdmin(bytes32 _dappId) external view returns (address);

    function getPrimaryFromSecondary(address _account) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }

    function checkAlphaNumeric(string memory str) internal pure returns (bool) {
        bytes memory b = bytes(str);
        // if(b.length < 4) 
        //     return false;

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if(
                !(char >= 0x30 && char <= 0x39) &&  //9-0
                !(char >= 0x41 && char <= 0x5A) &&  //A-Z
                !(char >= 0x61 && char <= 0x7A) &&  //a-z
                !(char == 0x2D)                     // -
                // !(char == 0x2E) //.
            )
                return false;
        }
        return true;
    }

    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function concatenate(
        string memory _name,
        string memory _tld
    ) internal pure returns (string memory) {
        // for DappsDns
        // return string(abi.encodePacked(_name, _tld));
        // for DappsDnsNew
        return string(abi.encodePacked(_name, ".", _tld));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
// import "./ERC2771ContextUpgradeable.sol";
// import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./GasRestrictor.sol";

// import "./ERC2771ContextUpgradeable.sol";
import {UnifarmAccountsUpgradeable} from "./UnifarmAccountsUpgradeable.sol";

contract MessagingUpgradeable is Initializable, OwnableUpgradeable {
    bytes32 public dappId; // dappID for this decentralized messaging application (should be fixed)
    UnifarmAccountsUpgradeable public unifarmAccounts;
    GasRestrictor public gasRestrictor;

    // ---------------- ATTACHMENTS STORAGE ---------------

    struct Attachment {
        string location;
        string fileType;
        address receiver;
        string rsaKeyReceiver; // encrypted using receiver's public key
        string rsaKeySender; // encrypted using sender's public key
        bool isEncrypted;
    }

    // dataID => attachment
    mapping(uint256 => Attachment) public attachments;

    uint256 public dataIdsCount;

    mapping(address => uint256[]) public receiverAttachments; // to get all the files received by the user (gdrive analogy)

    // ------------------ MESSAGE STORAGE ------------------

    struct Message {
        address sender;
        string textMessageReceiver; // encrypted using receiver's public key
        string textMessageSender; // encrypted using sender's public key
        uint256[] attachmentIds;
        bool isEncrypted; // to check if the message has been encrypted
        uint256 timestamp;
    }

    // from => to => messageID
    mapping(address => mapping(address => uint256)) public messageIds;

    // to keep a count of all the 1 to 1 communication
    uint256 public messageIdCount;

    // messageID => messages[]
    mapping(uint256 => Message[]) public messages;

    // to keep a count of all the messages sent
    uint256 public messagesCount;

    // ------------------ WHITELISTING STORAGE ------------------

    mapping(address => bool) public isWhitelisting;

    // from => to => isWhitelisted
    mapping(address => mapping(address => bool)) public isWhitelisted;

    // ------------------ SPAM RPOTECTION STORAGE ------------------

    mapping(address => bool) public isSpamProtecting;

    address public ufarmToken;
    address public spamTokensAdmin;

    // set by dappAdmin
    address[] public spamProtectionTokens;

    struct SpamProtectionToken {
        address token;
        uint256 amount; // amount to pay in wei for message this user
    }

    // userAddress => tokens
    mapping(address => SpamProtectionToken[]) public userSpamTokens;

    struct TokenTransferMapping {
        address token;
        uint256 amount;
        uint256 startTimestamp;
    }

    // from => to => TokenTransferMapping
    mapping(address => mapping(address => TokenTransferMapping))
        public tokenTransferMappings;

    event MessageSent(
        address indexed from,
        address indexed to,
        uint256 indexed messageId,
        string textMessageReceiver,
        string textMessageSender,
        uint256[] attachmentIds,
        bool isEncrypted,
        uint256 timestamp,
        uint256 totalCount
    );

    event AddedToWhitelist(address indexed from, address indexed to);

    event RemovedFromWhitelist(address indexed from, address indexed to);

    modifier isValidSender(address _from) {
        _isValidSender(_from);
        _;
    }

    function _isValidSender(address _from) internal view {
        // _msgSender() should be either primary (_from) or secondary wallet of _from
        require(
            _msgSender() == _from ||
                _msgSender() ==
                unifarmAccounts.getSecondaryWalletAccount(_from),
            "INVALID_SENDER"
        );
    }

    modifier GasNotZero(address user) {
        if (unifarmAccounts.getPrimaryFromSecondary(user) == address(0)) {
            _;
        } else {
            address a;
            address b;
            uint256 u;
            (a, b, u) = gasRestrictor.gaslessData(
                unifarmAccounts.getPrimaryFromSecondary(user)
            );
            require(u != 0, "NOT_ENOUGH_GASBALANCE");
            _;
        }
    }

    function __Messaging_init(
        bytes32 _dappId,
        UnifarmAccountsUpgradeable _unifarmAccounts,
        GasRestrictor _gasRestrictor,
        address _ufarmToken,
        address _spamTokensAdmin,
        address _trustedForwarder
    ) public initializer {
        __Ownable_init(_trustedForwarder);

        // __Pausable_init();
        // __ERC2771ContextUpgradeable_init(_trustedForwarder);
        // _trustedForwarder = trustedForwarder;
        dappId = _dappId;
        unifarmAccounts = _unifarmAccounts;
        ufarmToken = _ufarmToken;
        spamTokensAdmin = _spamTokensAdmin;
        gasRestrictor = _gasRestrictor;
    }

    function addGasRestrictor(GasRestrictor _gasRestrictor) external onlyOwner {
        gasRestrictor = _gasRestrictor;
    }

    // ------------------ ATTACHMENT FUNCTIONS ----------------------

    function writeData(
        string memory _location,
        string memory _fileType,
        address _receiver,
        string memory _rsaKeyReceiver,
        string memory _rsaKeySender,
        bool _isEncrypted
    ) internal returns (uint256) {
        uint256 dataId = dataIdsCount++;
        Attachment memory attachment = Attachment({
            location: _location,
            fileType: _fileType,
            receiver: _receiver,
            rsaKeyReceiver: _rsaKeyReceiver,
            rsaKeySender: _rsaKeySender,
            isEncrypted: _isEncrypted
        });
        attachments[dataId] = attachment;
        receiverAttachments[_receiver].push(dataId);
        return dataId;
    }

    // -------------------- MESSAGE FUNCTIONS -----------------------

    // function to send message when receiver's spam protection is OFF
    function newMessage(
        address _from,
        address _to,
        string calldata _textMessageReceiver,
        string calldata _textMessageSender,
        Attachment[] calldata _attachments,
        bool _isEncrypted
    ) public isValidSender(_from) {
        uint256 gasLeftInit = gasleft();
        bool isSendWhitelisted = isWhitelisted[_from][_to];
        // bool isReceiveWhitelisted = isWhitelisted[_to][_msgSender()];

        // check if the receiver has whitelisting enabled and user is whitelisted by the receiver
        if (isWhitelisting[_to]) require(isSendWhitelisted, "NOT_WHITELISTED");

        _createMessageRecord(
            _from,
            _to,
            _textMessageReceiver,
            _textMessageSender,
            _attachments,
            _isEncrypted
        );

        _updateGaslessData(gasLeftInit);
    }

    // function to send message when receiver's spam protection is ON
    function newMessageOnSpamProtection(
        address _from,
        address _to,
        string calldata _textMessageReceiver,
        string calldata _textMessageSender,
        Attachment[] calldata _attachments,
        bool _isEncrypted,
        ERC20 _token
    ) public isValidSender(_from) {
        uint256 gasLeftInit = gasleft();

        bool isSendWhitelisted = isWhitelisted[_from][_to];

        // check if the receiver has whitelisting enabled and user is whitelisted by the receiver
        if (isWhitelisting[_to]) require(isSendWhitelisted, "NOT_WHITELISTED");

        // check if receiver has spam protection enabled
        if (isSpamProtecting[_to] && !isSendWhitelisted) {
            _createSpamRecord(_from, _to, _token);
        }

        _createMessageRecord(
            _from,
            _to,
            _textMessageReceiver,
            _textMessageSender,
            _attachments,
            _isEncrypted
        );
        _updateGaslessData(gasLeftInit);
    }

    function _createMessageRecord(
        address _from,
        address _to,
        string memory _textMessageReceiver,
        string memory _textMessageSender,
        Attachment[] memory _attachments,
        bool _isEncrypted
    ) internal {
        // to check if tokenTransferMappings record exists
        if (tokenTransferMappings[_to][_from].startTimestamp > 0) {
            TokenTransferMapping
                memory tokenTransferMapping = tokenTransferMappings[_to][_from];
            delete tokenTransferMappings[_to][_from];

            ERC20(tokenTransferMapping.token).transfer(
                _from,
                tokenTransferMapping.amount
            );
        }

        uint256 len = _attachments.length;
        uint256[] memory attachmentIds = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            uint256 dataId = writeData(
                _attachments[i].location,
                _attachments[i].fileType,
                _attachments[i].receiver,
                _attachments[i].rsaKeyReceiver,
                _attachments[i].rsaKeySender,
                _attachments[i].isEncrypted
            );
            attachmentIds[i] = dataId;
        }

        Message memory message = Message({
            sender: _from,
            textMessageReceiver: _textMessageReceiver,
            textMessageSender: _textMessageSender,
            isEncrypted: _isEncrypted,
            attachmentIds: attachmentIds,
            timestamp: block.timestamp
        });

        uint256 messageId = messageIds[_from][_to];
        if (messageId == 0) {
            messageId = ++messageIdCount;
            messageIds[_from][_to] = messageId;
            messageIds[_to][_from] = messageId;
            emit AddedToWhitelist(_from, _to);
            emit AddedToWhitelist(_to, _from);
        }
        messages[messageId].push(message);

        emit MessageSent(
            _from,
            _to,
            messageId,
            _textMessageReceiver,
            _textMessageSender,
            attachmentIds,
            _isEncrypted,
            block.timestamp,
            ++messagesCount
        );
    }

    function _createSpamRecord(
        address _from,
        address _to,
        ERC20 _token
    ) internal {
        uint256 amount = getTokenAmountToSend(_from, address(_token));
        require(amount > 0, "INVALID_TOKEN");
        uint256 adminAmount;
        if (address(_token) != ufarmToken) {
            adminAmount = amount / 5; // 20% goes to admin
            amount -= adminAmount;
            _token.transferFrom(_from, spamTokensAdmin, adminAmount);
        }
        _token.transferFrom(_from, address(this), amount);
        tokenTransferMappings[_from][_to] = TokenTransferMapping({
            token: address(_token),
            amount: amount,
            startTimestamp: block.timestamp
        });

        isWhitelisted[_from][_to] = true;
        emit AddedToWhitelist(_from, _to);

        isWhitelisted[_to][_from] = true;
        emit AddedToWhitelist(_to, _from);
    }

    function getTokenAmountToSend(address _account, address _token)
        public
        view
        returns (uint256)
    {
        SpamProtectionToken[] memory spamTokens = userSpamTokens[_account];
        for (uint256 i = 0; i < spamTokens.length; i++) {
            if (spamTokens[i].token == _token) return spamTokens[i].amount;
        }
        return 0;
    }

    // function getMessageForReceiver(
    //     address receiver,
    //     uint256 limit,
    //     uint256 offset
    // ) public view returns (Message[] memory) {
    //     uint startIndex = limit * offset;
    //     uint endIndex = startIndex + limit;
    //     uint len = userReceivedMessages[receiver].length;
    //     Message[] memory receivedMessages = new Message[](len);
    //     for (uint i = startIndex; i < endIndex && i < len; i++) {
    //         receivedMessages[i] = userReceivedMessages[receiver][i];
    //     }
    //     return receivedMessages;
    // }

    // function getMessageForSender(
    //     address sender,
    //     uint256 limit,
    //     uint256 offset
    // ) public view returns (Message[] memory) {
    //     uint startIndex = limit * offset;
    //     uint endIndex = startIndex + limit;
    //     uint len = userSentMessages[sender].length;
    //     Message[] memory sentMessages = new Message[](len);
    //     for (uint i = startIndex; i < endIndex && i < len; i++) {
    //         sentMessages[i] = userSentMessages[sender][i];
    //     }
    //     return sentMessages;
    // }

    function getCommunication(address _from, address _to)
        public
        view
        returns (Message[] memory)
    {
        uint256 messageId = messageIds[_from][_to];
        return messages[messageId];
    }

    // ------------------ SPAM RPOTECTION FUNCTIONS ------------------

    function adminAddPaymentToken(address _token) external {
        uint256 gasLeftInit = gasleft();
        require(
            _msgSender() == unifarmAccounts.getDappAdmin(dappId),
            "ONLY_DAPP_ADMIN"
        );
        require(_token != address(0), "INVALID_ADDRESS");

        uint256 len = spamProtectionTokens.length;
        for (uint256 i = 0; i < len; i++) {
            require(spamProtectionTokens[i] != _token, "TOKEN_ALREADY_EXISTS");
        }
        spamProtectionTokens.push(_token);

        _updateGaslessData(gasLeftInit);
    }

    function adminRemovePaymentToken(address _token) external {
        require(
            _msgSender() == unifarmAccounts.getDappAdmin(dappId),
            "ONLY_DAPP_ADMIN"
        );
        require(_token != address(0), "INVALID_ADDRESS");

        uint256 len = spamProtectionTokens.length;
        for (uint256 i = 0; i < len; i++) {
            if (spamProtectionTokens[i] == _token) {
                if (i < len - 1) {
                    spamProtectionTokens[i] = spamProtectionTokens[len - 1];
                }
                spamProtectionTokens.pop();
                return;
            }
        }
        revert("NO_TOKEN");
    }

    // to set spam protection tokens for user
    function updateUserSpamTokens(
        address _account,
        bool _isSpamProtecting,
        bool _isTokensUpdate,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) external isValidSender(_account) GasNotZero(_msgSender()) {
        uint gasLeftInit = gasleft();
        isSpamProtecting[_account] = _isSpamProtecting;

        if(_isTokensUpdate) {
            _updateUserSpamTokens(_account, _tokens, _amounts);
        }

        _updateGaslessData(gasLeftInit);
    }

    function _updateUserSpamTokens(
        address _account,
        address[] calldata _tokens,
        uint256[] calldata _amounts
    ) internal {
        require(_tokens.length > 0, "ZERO_LEN");
        require(_tokens.length == _amounts.length, "LEN_NOT_EQ");

        // uint len = spamProtectionTokens.length;
        uint len = _tokens.length;
        for(uint256 i = 0; i < len; i++) {
            uint8 count = 0;
            for (uint256 j = 0; j < spamProtectionTokens.length; j++) {
                // token should be allowed by the admin
                if(_tokens[i] == spamProtectionTokens[j]) {
                    count = 1;
                    break;
                }  
            }
            require(count == 1, "INVALID_TOKEN");
        }
        
        delete userSpamTokens[_account];

        for(uint256 i = 0; i < len; i++) {
            SpamProtectionToken memory token = SpamProtectionToken({
                token: _tokens[i],
                amount: _amounts[i]
            });
            userSpamTokens[_account].push(token);

            for(uint256 j = 0; j < i; j++) {
                // if token already exists then update its price and return
                if(_tokens[i] == userSpamTokens[_account][j].token) {
                    revert("TOKEN_EXISTS");
                }
            }
        }
    }

    // to add a new token or update the price of alreayd added token
    function addSpamProtectionToken(
        address _account,
        address _token,
        uint256 _amount
    ) external isValidSender(_account) {
        uint256 gasLeftInit = gasleft();
        require(_token != address(0), "INVALID_ADDRESS");
        require(_amount > 0, "ZERO_AMOUNT");

        uint256 len = spamProtectionTokens.length;
        uint8 count;
        for (uint256 i = 0; i < len; i++) {
            // token should be allowed by the admin
            if (spamProtectionTokens[i] == _token) {
                count = 1;
                break;
            }
        }
        require(count == 1, "INVALID_TOKEN");

        len = userSpamTokens[_account].length;
        for (uint256 i = 0; i < len; i++) {
            // if token already exists then update its price and return
            if (userSpamTokens[_account][i].token == _token) {
                userSpamTokens[_account][i].amount = _amount;
                return;
            }
        }

        // If token doesn't exist then add it
        SpamProtectionToken memory token = SpamProtectionToken({
            token: _token,
            amount: _amount
        });
        userSpamTokens[_account].push(token);

        _updateGaslessData(gasLeftInit);
    }

    function removeSpamProtectionToken(address _account, address _token)
        external
        isValidSender(_account)
    {
        require(_token != address(0), "INVALID_ADDRESS");

        uint256 len = userSpamTokens[_account].length;
        for (uint256 i = 0; i < len; i++) {
            if (userSpamTokens[_account][i].token == _token) {
                if (i < len - 1) {
                    userSpamTokens[_account][i] = userSpamTokens[_account][
                        len - 1
                    ];
                }
                userSpamTokens[_account].pop();
                return;
            }
        }
        revert("NO_TOKEN");
    }

    function setIsSpamProtecting(address _account, bool _isSpamProtecting)
        external
        isValidSender(_account)
    {
        uint256 gasLeftInit = gasleft();

        isSpamProtecting[_account] = _isSpamProtecting;

        _updateGaslessData(gasLeftInit);
    }

    function getRefund(address _user, address _to)
        external
        isValidSender(_user)
    {
        uint256 gasLeftInit = gasleft();
        // tokenTransferMappings record should exist
        require(
            tokenTransferMappings[_user][_to].startTimestamp > 0,
            "NO_RECORD"
        );
        // 7 days time must have passed
        require(
            block.timestamp >
                tokenTransferMappings[_user][_to].startTimestamp + 7 days,
            "TIME_PENDING"
        );

        TokenTransferMapping
            memory tokenTransferMapping = tokenTransferMappings[_user][_to];
        delete tokenTransferMappings[_user][_to];
        ERC20(tokenTransferMapping.token).transfer(
            _user,
            tokenTransferMapping.amount
        );

        _updateGaslessData(gasLeftInit);
    }

    // ------------------ WHITELISTING FUNCTIONS ------------------

    function setIsWhitelisting(address _account, bool _isWhitelisting)
        external
        isValidSender(_account)
    {
        isWhitelisting[_account] = _isWhitelisting;
    }

    function addWhitelist(address _user, address _account)
        external
        isValidSender(_user)
    {
        uint256 gasLeftInit = gasleft();
        isWhitelisted[_account][_user] = true;
        emit AddedToWhitelist(_account, _user);

        _updateGaslessData(gasLeftInit);
    }

    function removeWhitelist(address _user, address _account)
        external
        isValidSender(_user)
    {
        uint256 gasLeftInit = gasleft();

        isWhitelisted[_account][_user] = false;
        emit RemovedFromWhitelist(_account, _user);

        _updateGaslessData(gasLeftInit);
    }

    function _updateGaslessData(uint256 _gasLeftInit) internal {
        if (isTrustedForwarder[msg.sender]) {
            gasRestrictor._updateGaslessData(_msgSender(), _gasLeftInit);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic) payable {
        _upgradeToAndCall(_logic, "" , false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./lib/EIP712Base.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EIP712MetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));

    event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);
    mapping(address => uint256) private nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    constructor(string memory name, string memory version) public EIP712Base(name, version) {}

    function convertBytesToBytes4(bytes memory inBytes) internal returns (bytes4 outBytes4) {
        if (inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    function executeMetaTransaction(address userAddress,
        bytes memory functionSignature, bytes32 sigR, bytes32 sigS, uint8 sigV) public payable returns(bytes memory) {
        bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);
        require(destinationFunctionSig != msg.sig, "functionSignature can not be of executeMetaTransaction method");
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");
        nonces[userAddress] = nonces[userAddress].add(1);
        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(userAddress,payable(msg.sender), functionSignature);
        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            META_TRANSACTION_TYPEHASH,
            metaTx.nonce,
            metaTx.from,
            keccak256(metaTx.functionSignature)
        ));
    }

    function getNonce(address user) external view returns(uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(address user, MetaTransaction memory metaTx, bytes32 sigR, bytes32 sigS, uint8 sigV) internal view returns (bool) {
        address signer = ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        return signer == user;
    }

    function msgSender() internal view returns(address sender) {
        if(msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract EIP712Base {

    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"));

    bytes32 internal domainSeparator;

    constructor(string memory name, string memory version) public {
        domainSeparator = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            address(this),
            bytes32(getChainID())
        ));
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getDomainSeparator() private view returns(bytes32) {
        return domainSeparator;
    }

    /**
    * Accept message hash and returns hash message in EIP712 compatible form
    * So that it can be used to recover signer from signature signed using EIP712 formatted data
    * https://eips.ethereum.org/EIPS/eip-712
    * "\\x19" makes the encoding deterministic
    * "\\x01" is the version byte to make it compatible to EIP-191
    */
    function toTypedMessageHash(bytes32 messageHash) internal view returns(bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash));
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/MinimalForwarder.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";


contract MinimalForwarder2 is EIP712 {
    using ECDSA for bytes32;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) private _nonces;
    
    constructor() EIP712("MinimalForwarder", "0.0.1") {}

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }
    
    function verifySigner(ForwardRequest calldata req, bytes calldata signature) public view returns (address) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return  signer;
    }
    
    function execute(ForwardRequest calldata req, bytes calldata signature)
        public 
        payable 
        returns (bool, bytes memory)
    {   
        require(verify(req, signature), "MinimalForwarder: signature does not match request");
        _nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );
       require(success, "Failed to Execute MetaTxn");

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            /// @solidity memory-safe-assembly
            assembly {
                invalid()
            }
        }
        emit MetaTransactionExecuted(req.from,payable(msg.sender), signature);

    
        return (success, returndata);
    }


    function relayBatch(ForwardRequest[] calldata req, bytes[] calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {   
         
       require(req.length == signature.length, "X");
       unchecked {
           for (uint i = 0; i < signature.length; i++) { 
             execute(req[i], signature[i]);
               
           }

       }
        
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
    // function transferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) public virtual override {
    //     //solhint-disable-next-line max-line-length
    //     require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

    //     _transfer(from, to, tokenId);
    // }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
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
    ) internal virtual {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";

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

import "./IERC721Upgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

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
    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId,
    //     bytes calldata data
    // ) external;

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
    // function safeTransferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) external;

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
    // function transferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) external;

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

// SPDX-License-Identifier: GPL-3.0-or-later

// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity ^0.8.4;

import {ERC2771ContextUpgradeable} from "./ERC2771ContextUpgradeable.sol";
// import {Initializable} from "../proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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

abstract contract OwnableUpgradeable is Initializable, ERC2771ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init(address trustedForwarder) internal initializer {
        __Ownable_init_unchained();
        __ERC2771ContextUpgradeable_init(trustedForwarder);
    }

    function __Ownable_init_unchained() internal initializer {
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
        require(owner() == _msgSender(), "ONA");
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
        require(newOwner != address(0), "INA");
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

     function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder[msg.sender]) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


// interface sdk for using dapps through smart contract
interface SubscriptionModuleI {

    struct Dapp {
        string appName;
        bytes32 appId;
        address appAdmin; //primary
        string appUrl;
        string appIcon;
        string appSmallDescription;
        string appLargeDescription;
        string appCoverImage;
        string[] appScreenshots; // upto 5
        string[] appCategory; // upto 7
        string[] appTags; // upto 7
        string[] appSocial;
        bool isVerifiedDapp; // true or false
        uint256 credits;
        uint256 renewalTimestamp;  
        
         }

// function to check whether a user _user has subscribe a particular dapp with dapp id _dappId or not
  function isSubscribed(bytes32 _dappId, uint256 listID, address _user) view external returns (bool);

  function addNewDapp( Dapp memory _dapp, address _user)  external;
  
function subscribeWithPermit(
   address user,
        bytes32 appID,
        uint256[] memory _lists,
        bool subscriptionStatus,
        uint256 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
)  external;

  function subscribeToDapp(
         address user,
        bytes32 appID,
        bool subscriptionStatus,
        bool isOauthUser,
        uint256[] memory _lists)  external ;

   function sendAppNotification(
        bytes32 _appId,
        address walletAddress,
        string memory _message,
        string memory buttonName,
        string memory _cta,
        bool _isEncrypted,
        bool isOauthUser
    )
        external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface dappsSubscriptionI {


  function getPrimaryFromSecondary(address secondary) view external returns (address);



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../UnifarmAccountsUpgradeable.sol";

contract UnifarmSubscription is Initializable, OwnableUpgradeable {
    // --------------------- DAPPS  -----------------------
    UnifarmAccountsUpgradeable public unifarmAccounts;
    uint256 public dappId; // dappID for this decentralized messaging application (should be fixed)
    address public superAdmin; // dapps admin, has access to add or remove any dapp admin.

    struct Dapp {
        string appName;
        uint256 appId;
        address appAdmin; //primary
        string appIcon;
        string appSmallDescription;
        string appLargeDescription;
        string[] appScreenshots;
        string appCategory;
        string appTags;
        bool isVerifiedDapp; // true or false
    }


    struct Notification {
        uint appID;
        address walletAddressTo; // primary
        string message;
        string buttonName;
        string cta;
        uint timestamp;
    }
    // dappId => address => bool(true/false)
    mapping(uint256 => mapping(address => bool)) public isGovernor;

    // dappId => address => bool(true/false)
    mapping(uint256 => mapping(address => bool)) public isSubscribed;
    
    mapping(address => Notification[]) public notificationsOf; 
    // dappID => dapp
    mapping(uint256 => Dapp) public dapps;

    uint256 public dappsCount;
    uint256 public verifiedDappsCount;

     event newAppRegistered(
       uint256 appID, 
       address appAdmin, 
       string appName
    );

    event AppAdmin(
        uint256 appID, 
        address appAdmin, 
        address admin, 
        bool status
    );

    event AppSubscribed(
        uint256 appID, 
        address subscriber
    );
    event AppUnSubscribed(
        uint256 appID, 
        address subscriber
    );

    event newNotifiaction ( uint256 appId, address walletAddress,string message, string buttonName , string cta);
    

    modifier onlySuperAdmin() {
        require(
            _msgSender() == superAdmin ||
                _msgSender() ==
                unifarmAccounts.getSecondaryWalletAccount(superAdmin),
            "INVALID_SENDER"
        );
        _;
    }
    modifier superAdminOrDappAdmin(uint appID) {
        address appAdmin = getDappAdmin(appID);
        require(
            _msgSender() == superAdmin ||
            _msgSender() == unifarmAccounts.getSecondaryWalletAccount(superAdmin) || _msgSender() == appAdmin ||   _msgSender() == unifarmAccounts.getSecondaryWalletAccount(appAdmin)
        , "INVALID_SENDER");
        _;
    }

    

   modifier appAdminOrGovernorOrSuperAdmin(uint appID) {
        address appAdmin = getDappAdmin(appID);
        require(
            _msgSender() == superAdmin ||
            _msgSender() == unifarmAccounts.getSecondaryWalletAccount(superAdmin) || _msgSender() == appAdmin || 
            _msgSender() == unifarmAccounts.getSecondaryWalletAccount(appAdmin) ||  isGovernor[appID][_msgSender()] == true 
        , "INVALID_SENDER");
        _;
   }
    function __UnifarmSubscription_init(
        uint256 _dappId,
        UnifarmAccountsUpgradeable _unifarmAccounts,
        address _trustedForwarder,
        address _superAdmin
    ) public initializer {
        __Ownable_init(_trustedForwarder);
        unifarmAccounts = _unifarmAccounts;
        dappId = _dappId;
        superAdmin = _superAdmin;

        // __Pausable_init();
    }

    function _isGovernor(address _from, uint appId) internal view {
        // _msgSender() should be either primary (_from) or secondary wallet of _from
        require(
            isGovernor[appId][_from] == true,
            "INVALID_SENDER"
        );
    }

    // -------------------- DAPP FUNCTIONS ------------------------

    function addNewDapp(
        string memory _appName,
        address _appAdmin, //primary
        string memory _appIcon,
        string memory _appSmallDescription,
        string memory _appLargeDescription,
        string[] memory _appScreenshots,
        string memory _appCategory,
        string memory _appTags
    ) external {
        uint256 _appID = dappsCount;
        Dapp memory dapp = Dapp({
            appName: _appName,
            appId: _appID,
            appAdmin: _appAdmin,
            appIcon: _appIcon,
            appSmallDescription: _appSmallDescription,
            appLargeDescription: _appLargeDescription,
            appScreenshots: _appScreenshots,
            appCategory: _appCategory,
            appTags: _appTags,
            isVerifiedDapp: false
        });
        dapps[_appID] = dapp;

        emit newAppRegistered(_appID, _appAdmin, _appName);
        dappsCount++;
    }


    function subscribeToDapp(address user, uint appID, bool subscriptionStatus) external {
    require(appID <= dappsCount, "Invalid dapp id");
    require(dapps[appID].isVerifiedDapp == true, "unverified app");
     isSubscribed[appID][user] = subscriptionStatus;
     
     if(subscriptionStatus) {
         emit AppSubscribed(appID, user);

     }
     else {
         emit AppUnSubscribed(appID, user);
     }
    }

    function appVerification(uint256 appID, bool verificationStatus)
        external
        onlySuperAdmin
    {
        dapps[appID].isVerifiedDapp = verificationStatus;
        if (verificationStatus) {
            verifiedDappsCount++;
        } else {
            verifiedDappsCount--;
        }
    }

// newAdmin is primary wallet address
    function addAppAdmin(uint256 appID, address admin, bool status) external superAdminOrDappAdmin(appID) {
     
    isGovernor[appID][admin] = status; 
    isGovernor[appID][unifarmAccounts.getSecondaryWalletAccount(admin)] = status; 
    emit AppAdmin(appID, getDappAdmin(appID), admin, status);
     
    }


// primary wallet address. ?? 
    function sendAppNotification(uint _appId, address[] memory walletAddress, string memory _message, string memory buttonNAme, string memory _cta) external appAdminOrGovernorOrSuperAdmin(_appId)  {

        unchecked {
        for (uint i = 0; i < walletAddress.length; i++) {
    require(isSubscribed[_appId][walletAddress[i]] == true);       
    Notification memory notif = Notification({
    appID: _appId, 
    walletAddressTo: walletAddress[i],
    message: _message, 
    buttonName: buttonNAme, 
    cta: _cta,
    timestamp: block.timestamp
    });

    notificationsOf[walletAddress[i]].push(notif);
    emit newNotifiaction(_appId, walletAddress[i], _message,buttonNAme, _cta );
        }
         }
    }



    function getNotificationsOf(address user) external view returns(Notification[] memory){
        return notificationsOf[user];
    }

    function getDappAdmin(uint256 _dappId) public view returns (address) {
        return dapps[_dappId].appAdmin;
    }

    // -------------------- WALLET FUNCTIONS -----------------------
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./GasRestrictor.sol";
import "./Gamification.sol";
import "./WalletRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract SubscriptionModule is Initializable, OwnableUpgradeable {
    // uint256 public chainId;
    uint256 public defaultCredits;
    uint256 public renewalPeriod;
    GasRestrictor public gasRestrictor;
    Gamification public gamification;
    WalletRegistry public walletRegistry;
    // --------------------- DAPPS STORAGE -----------------------

    struct Dapp {
        string appName;
        bytes32 appId;
        address appAdmin; //primary
        string appUrl;
        string appIcon;
        string appSmallDescription;
        string appLargeDescription;
        string appCoverImage;
        string[] appScreenshots; // upto 5
        string[] appCategory; // upto 7
        string[] appTags; // upto 7
        string[] appSocial;
        bool isVerifiedDapp; // true or false
        uint256 credits;
        uint256 renewalTimestamp;    }

    struct Notification {
        bytes32 appID;
        address walletAddressTo; // primary
        string message;
        string buttonName;
        string cta;
        uint256 timestamp;
        bool isEncrypted;
    }

    struct List {
        uint256 listId;
        string listname;
    }

    mapping(bytes32 => mapping(uint256 => bool)) public isValidList;
    mapping(bytes32 => mapping(uint256 => uint256)) public listUserCount;
    mapping(bytes32 => uint256) public listsOfDappCount;
    mapping(bytes32 => mapping(uint256=> List)) public listsOfDapp;

    mapping(bytes32 => Dapp) public dapps;

    // all dapps count
    uint256 public dappsCount;
    uint256 public verifiedDappsCount;

    mapping(bytes32=>mapping(address=>bool)) hasPreviouslysubscribed;

    mapping(address => Notification[]) public notificationsOf;

    // dappId => count
    mapping(bytes32 => uint256) public notificationsCount;
    // dappId => listIndex => bool

    // dappId => count
    mapping(bytes32 => uint256) public subscriberCount;

    // user=>subscribeAppsCount
    mapping(address => uint256) public subscriberCountUser;
    mapping(address => uint256) public appCountUser;

    // account => dappId => role // 0 means no role, 1 meaning only notif, 2 meaning only add admin, 3 meaning both
    mapping(address => mapping(bytes32 => uint8)) public accountRole;

    // dappId =>list=> address => bool(true/false)
    mapping(bytes32 => mapping(uint256 => mapping(address => bool)))
        public isSubscribed;

    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant SUBSC_PERMIT_TYPEHASH =
        keccak256(
            "SubscPermit(address user,bytes32 appID,bool subscriptionStatus,uint256 nonce,uint256 deadline)"
        );
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public DOMAIN_SEPARATOR = keccak256(abi.encode(
    //     EIP712_DOMAIN_TYPEHASH,
    //     keccak256(bytes("Dapps")),
    //     keccak256(bytes("1")),
    //     chainId,
    //     address(this)
    // ));

    mapping(address => uint256) public nonce;

    uint256 public noOfSubscribers;
    uint256 public noOfNotifications;

    // dappId => dapp contract address => status
    mapping(bytes32 => mapping(address => bool)) public registeredDappContracts;
    
    // to keep a count of contracts that are using our sdk
    uint256 public regDappContractsCount;

    modifier onlySuperAdmin() {
        _onlySuperAdmin();
        _;
    }
    modifier isValidSenderOrRegDappContract(address from, bytes32 dappId) {
        _isValidSenderOrRegDappContract(from, dappId);
        _;
    }

    modifier superAdminOrDappAdmin(bytes32 appID) {
        _superAdminOrDappAdmin(appID);
        _;
    }

    modifier superAdminOrDappAdminOrAddedAdmin(bytes32 appID) {
        _superAdminOrDappAdminOrAddedAdmin(appID);
        _;
    }

    modifier superAdminOrDappAdminOrSendNotifRoleOrRegDappContract(bytes32 appID) {
        _superAdminOrDappAdminOrSendNotifRoleOrRegDappContract(appID);
        _;
    }

    modifier GasNotZero(address user, bool isOauthUser) {
        _gasNotZero(user, isOauthUser);
        _;
    }

    // modifier isRegisteredDappContract(
    //     bytes32 _dappId
    // ) {
    //     require(registeredDappContracts[_dappId][_msgSender()], "UNREGISTERED");
    //     _;
    // }

    event NewAppRegistered(
        bytes32 appID,
        address appAdmin,
        string appName,
        uint256 dappCount
    );

    event AppUpdated(bytes32 appID);

    event AppRemoved(bytes32 appID, uint256 dappCount);

    event AppAdmin(bytes32 appID, address appAdmin, address admin, uint8 role);

    event AppSubscribed(
        bytes32 appID,
        address subscriber,
        uint256 count,
        uint256 totalCount
    );

    event ListCreated(bytes32 appID, uint256 listId);

    event AppUnSubscribed(
        bytes32 appID,
        address subscriber,
        uint256 count,
        uint256 totalCount
    );

    event UserMovedFromList(
        bytes32 appID,
        address user,
        uint256 listIdFrom,
        uint256 listIdTo
    );
    event UserAddedToList(
        bytes32 appID,
        address user,
        uint256 listIdTo
    );
    event UserRemovedFromList(
        bytes32 appID,
        address user,
        uint256 listIdTo
    );

    event NewNotification(
        bytes32 appId,
        address walletAddress,
        string message,
        string buttonName,
        string cta,
        bool isEncrypted,
        uint256 count,
        uint256 totalCount
    );

    function __subscription_init(
        uint256 _defaultCredits,
        uint256 _renewalPeriod,
        address _trustedForwarder,
        WalletRegistry _wallet
    ) public initializer {
        walletRegistry = _wallet;
        defaultCredits = _defaultCredits;
        renewalPeriod = _renewalPeriod;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("Dapps")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        __Ownable_init(_trustedForwarder);
    }

    function _onlySuperAdmin() internal view {
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()),
            "INVALID_SENDER"
        );
    }

    function _superAdminOrDappAdmin(bytes32 _appID) internal view {
        address appAdmin = getDappAdmin(_appID);
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() == getSecondaryWalletAccount(appAdmin),
            "INVALID_SENDER"
        );
    }

    // function _superAdminOrDappAdminOrSendNotifRole(bytes32 _appID)
    //     internal
    //     view
    // {
    //     address appAdmin = getDappAdmin(_appID);
    //     require(
    //         _msgSender() == owner() ||
    //             _msgSender() == getSecondaryWalletAccount(owner()) ||
    //             _msgSender() == appAdmin ||
    //             _msgSender() == getSecondaryWalletAccount(appAdmin) ||
    //             accountRole[_msgSender()][_appID] == 1 ||
    //             accountRole[_msgSender()][_appID] == 3,
    //         "INVALID_SENDER"
    //     );
    // }

    function _superAdminOrDappAdminOrSendNotifRoleOrRegDappContract(bytes32 _appID)
        internal
        view
    {
        address appAdmin = getDappAdmin(_appID);
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() == getSecondaryWalletAccount(appAdmin) ||
                accountRole[_msgSender()][_appID] == 1 ||
                accountRole[_msgSender()][_appID] == 3 ||
                registeredDappContracts[_appID][_msgSender()],
            "INVALID_SENDER"
        );
    }

    function _superAdminOrDappAdminOrAddedAdmin(bytes32 _appID) internal view {
        address appAdmin = getDappAdmin(_appID);
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() == getSecondaryWalletAccount(appAdmin) ||
                accountRole[_msgSender()][_appID] == 2 ||
                accountRole[_msgSender()][_appID] == 3,
            "INVALID_SENDER"
        );
    }

    function _isValidSenderOrRegDappContract(address _from, bytes32 _dappId) internal view {
        require(
            _msgSender() == _from ||
                _msgSender() == getSecondaryWalletAccount(_from) ||
                registeredDappContracts[_dappId][_msgSender()],
            "INVALID_SENDER"
        );
    }

    function addGasRestrictorAndGamification(
        GasRestrictor _gasRestrictor,
        Gamification _gamification
    ) external onlyOwner {
        gasRestrictor = _gasRestrictor;
        gamification = _gamification;
    }

    function _gasNotZero(address user, bool isOauthUser) internal view {
        if (isTrustedForwarder[msg.sender]) {
            if (!isOauthUser) {
                if (getPrimaryFromSecondary(user) == address(0)) {} else {
                    (, , uint256 u) = gasRestrictor.gaslessData(
                        getPrimaryFromSecondary(user)
                    );
                    require(u != 0, "0_GASBALANCE");
                }
            } else {
                (, , uint256 u) = gasRestrictor.gaslessData(user);
                require(u != 0, "0_GASBALANCE");
            }
        }
    }

    // -------------------- DAPP FUNCTIONS ------------------------

    function addNewDapp(
        Dapp memory _dapp,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();
        require(_dapp.appAdmin != address(0), "ADMIN CAN'T BE 0 ADDRESS");
        require(_dapp.appScreenshots.length < 7, "SURPASSED IMAGE LIMIT");
        require(_dapp.appCategory.length < 8, "SURPASSED CATEGORY LIMIT");
        require(_dapp.appTags.length < 8, "SURPASSED TAG LIMIT");

        checkFirstApp();
        _addNewDapp(
            _dapp,
            false
        );

        _updateGaslessData(gasLeftInit);
    }

    function _addNewDapp(
        Dapp memory _dapp,
        bool _isAdmin
    ) internal {
        bytes32 _appID;
        Dapp memory dapp = Dapp({
            appName: _dapp.appName,
            appId: _appID,
            appAdmin: _dapp.appAdmin,
            appUrl: _dapp.appUrl,
            appIcon: _dapp.appIcon,
            appCoverImage: _dapp.appCoverImage,
            appSmallDescription: _dapp.appSmallDescription,
            appLargeDescription: _dapp.appLargeDescription,
            appScreenshots: _dapp.appScreenshots,
            appCategory: _dapp.appCategory,
            appTags: _dapp.appTags,
            appSocial: _dapp.appSocial,
            isVerifiedDapp: false,
            credits: defaultCredits,
            renewalTimestamp: block.timestamp
        });
        if(!_isAdmin)
            _appID = keccak256(
                abi.encode(dapp, block.number, _msgSender(), dappsCount, block.chainid)
            );
        else
            _appID = _dapp.appId;
        dapp.appId = _appID;

        dapps[_appID] = dapp;
        isValidList[_appID][listsOfDappCount[_appID]++] = true;
        emit NewAppRegistered(_appID, _dapp.appAdmin, _dapp.appName, ++dappsCount);
    }

    // function addNewDapp(
    //     bytes32 _appId,
    //     string memory _appName,
    //     address _appAdmin, //primary
    //     string memory _appUrl,
    //     string memory _appIcon,
    //     string memory _appCoverImage,
    //     string memory _appSmallDescription,
    //     string memory _appLargeDescription,
    //     string[] memory _appScreenshots,
    //     string[] memory _appCategory,
    //     string[] memory _appTags,
    //     string[] memory _appSocial
    // ) external onlyOwner {
    //     require(dapps[_appId].appAdmin == address(0), "DAPP EXISTS");
    //     require(_appAdmin != address(0), "ADMIN CAN'T BE 0 ADDRESS");
    //     require(_appScreenshots.length < 6, "SURPASSED IMAGE LIMIT");
    //     require(_appCategory.length < 8, "SURPASSED CATEGORY LIMIT");
    //     require(_appTags.length < 8, "SURPASSED TAG LIMIT");

    //     checkFirstApp();
    //     _addNewDapp(
    //         _appId,
    //         _appName,
    //         _appAdmin,
    //         _appUrl,
    //         _appIcon,
    //         _appCoverImage,
    //         _appSmallDescription,
    //         _appLargeDescription,
    //         _appScreenshots,
    //         _appCategory,
    //         _appTags,
    //         _appSocial
    //     );
    // }

    // function _addNewDapp(
    //     bytes32 _appId,
    //     string memory _appName,
    //     address _appAdmin, //primary
    //     string memory _appUrl,
    //     string memory _appIcon,
    //     string memory _appCoverImage,
    //     string memory _appSmallDescription,
    //     string memory _appLargeDescription,
    //     string[] memory _appScreenshots,
    //     string[] memory _appCategory,
    //     string[] memory _appTags,
    //     string[] memory _appSocial
    // ) internal {
    //     Dapp memory dapp = Dapp({
    //         appName: _appName,
    //         appId: _appId,
    //         appAdmin: _appAdmin,
    //         appUrl: _appUrl,
    //         appIcon: _appIcon,
    //         appCoverImage: _appCoverImage,
    //         appSmallDescription: _appSmallDescription,
    //         appLargeDescription: _appLargeDescription,
    //         appScreenshots: _appScreenshots,
    //         appCategory: _appCategory,
    //         appTags: _appTags,
    //         appSocial: _appSocial,
    //         isVerifiedDapp: false,
    //         credits: defaultCredits,
    //         renewalTimestamp: block.timestamp
    //     });

    //     dapps[_appId] = dapp;
    //     _initDappList(_appId);
    //     emit NewAppRegistered(_appId, _appAdmin, _appName, ++dappsCount);
    // }

    // function _initDappList(
    //     bytes32 _appId
    // ) internal {
    //     isValidList[_appId][listsOfDappCount[_appId]++] = true;
    // }

    function addNewDappOnNewChain(
        Dapp memory _dapp
    ) external onlySuperAdmin {
        // uint256 gasLeftInit = gasleft();
        require(_dapp.appAdmin != address(0), "ADMIN CAN'T BE 0 ADDRESS");
        require(_dapp.appScreenshots.length < 7, "SURPASSED IMAGE LIMIT");
        require(_dapp.appCategory.length < 8, "SURPASSED CATEGORY LIMIT");
        require(_dapp.appTags.length < 8, "SURPASSED TAG LIMIT");
        require(_dapp.appId != "", "INVALID_APP_ID");
        // checkFirstApp();
        _addNewDapp(
            _dapp,
            true
        );

        // _updateGaslessData(gasLeftInit);
    }

    function checkFirstApp() internal {
        address primary = getPrimaryFromSecondary(_msgSender());
        if (primary != address(0)) {
            if (appCountUser[primary] == 0) {
                // add 5 karma points of primarywallet
                gamification.addKarmaPoints(primary, 5);
            }
            appCountUser[primary]++;
        } else {
            if (appCountUser[_msgSender()] == 0) {
                // add 5 karma points of _msgSender()
                gamification.addKarmaPoints(_msgSender(), 5);
            }
            appCountUser[_msgSender()]++;
        }
    }

    function changeDappAdmin(
        bytes32 _appId,
        address _newAdmin,
        bool isOauthUser
    )
        external
        superAdminOrDappAdmin(_appId)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(dapps[_appId].appAdmin != address(0), "INVALID_DAPP");
        require(_newAdmin != address(0), "INVALID_OWNER");
        dapps[_appId].appAdmin = _newAdmin;

        // if (msg.sender == trustedForwarder)
        //     gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
        _updateGaslessData(gasLeftInit);
    }

    function updateDapp(
        bytes32 _appId,
        string memory _appName,
        string memory _appUrl,
        string[] memory _appImages, // [icon, cover_image]
        // string memory _appSmallDescription,
        // string memory _appLargeDescription,
        string[] memory _appDesc, // [small_desc, large_desc]
        string[] memory _appScreenshots,
        string[] memory _appCategory,
        string[] memory _appTags,
        string[] memory _appSocial, // [twitter_url]
        bool isOauthUser
    )
        external
        superAdminOrDappAdminOrAddedAdmin(_appId)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(_appImages.length == 2, "IMG_LIMIT_EXCEED");
        require(_appScreenshots.length < 6, "SS_LIMIT_EXCEED");
        require(_appCategory.length < 8, "CAT_LIMIT_EXCEED");
        require(_appTags.length < 8, "TAG_LIMIT_EXCEED");
        require(_appDesc.length == 2, "DESC_LIMIT_EXCEED");

        // _updateDappTextInfo(_appId, _appName, _appUrl, _appSmallDescription, _appLargeDescription, _appCategory, _appTags, _appSocial);
        _updateDappTextInfo(
            _appId,
            _appName,
            _appUrl,
            _appDesc,
            _appCategory,
            _appTags,
            _appSocial
        );
        _updateDappImageInfo(_appId, _appImages, _appScreenshots);

        // if(isTrustedForwarder(msg.sender)) {
        //     gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
        // }
        _updateGaslessData(gasLeftInit);
    }

    function _updateDappTextInfo(
        bytes32 _appId,
        string memory _appName,
        string memory _appUrl,
        // string memory _appSmallDescription,
        // string memory _appLargeDescription,
        string[] memory _appDesc,
        string[] memory _appCategory,
        string[] memory _appTags,
        string[] memory _appSocial
    ) internal {
        Dapp storage dapp = dapps[_appId];
        require(dapp.appAdmin != address(0), "INVALID_DAPP");
        if (bytes(_appName).length != 0) dapp.appName = _appName;
        if (bytes(_appUrl).length != 0) dapp.appUrl = _appUrl;
        if (bytes(_appDesc[0]).length != 0)
            dapp.appSmallDescription = _appDesc[0];
        if (bytes(_appDesc[1]).length != 0)
            dapp.appLargeDescription = _appDesc[1];
        // if(_appCategory.length != 0)
        dapp.appCategory = _appCategory;
        // if(_appTags.length != 0)
        dapp.appTags = _appTags;
        // if(_appSocial.length != 0)
        dapp.appSocial = _appSocial;
    }

    function _updateDappImageInfo(
        bytes32 _appId,
        string[] memory _appImages,
        string[] memory _appScreenshots
    ) internal {
        Dapp storage dapp = dapps[_appId];
        // if(bytes(_appImages[0]).length != 0)
        dapp.appIcon = _appImages[0];
        // if(bytes(_appImages[1]).length != 0)
        dapp.appCoverImage = _appImages[1];
        // if(_appScreenshots.length != 0)
        dapp.appScreenshots = _appScreenshots;

        emit AppUpdated(_appId);
    }

    function removeDapp(bytes32 _appId, bool isOauthUser)
        external
        superAdminOrDappAdmin(_appId)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(dapps[_appId].appAdmin != address(0), "INVALID_DAPP");
        if (dapps[_appId].isVerifiedDapp) --verifiedDappsCount;
        delete dapps[_appId];
        --dappsCount;

        emit AppRemoved(_appId, dappsCount);

        _updateGaslessData(gasLeftInit);
    }

    function createDappList(
        bytes32 appId,
        string memory listName,
        bool isOauthUser
    )
        public
        GasNotZero(_msgSender(), isOauthUser)
        superAdminOrDappAdminOrAddedAdmin(appId)
    {
        uint id = listsOfDappCount[appId];
        isValidList[appId][id] = true;
        listsOfDapp[appId][id] =  List(id, listName);
        emit ListCreated(appId, listsOfDappCount[appId]++);

    }


    function addOrRemoveSubscriberToList(
        bytes32 appId, 
        address subscriber, 
        uint listID, 
        bool addOrRemove, 
        bool isOauthUser
    ) public GasNotZero(_msgSender(), isOauthUser) superAdminOrDappAdminOrAddedAdmin(appId) {
        
        require(isSubscribed[appId][0][subscriber] == true, "address not subscribed");
        require(isValidList[appId][listID] == true, "not valid list");

        isSubscribed[appId][listID][subscriber] = addOrRemove;

        if(addOrRemove) {
            listUserCount[appId][listID]++;
            emit UserAddedToList(appId, subscriber, listID);
        }
        else {
            listUserCount[appId][listID]--;
             emit UserRemovedFromList(appId, subscriber, listID);

        }
    }

    function updateRegDappContract(
        bytes32 _dappId,
        address _dappContractAddress,
        bool _status
    ) external superAdminOrDappAdmin(_dappId) {
        require(registeredDappContracts[_dappId][_dappContractAddress] != _status, "UNCHANGED");
        registeredDappContracts[_dappId][_dappContractAddress] = _status;
        if(_status)
            ++regDappContractsCount;
        else
            --regDappContractsCount;
    }

    // function subscribeToDappByContract(
    //     address user,
    //     bytes32 appID,
    //     bool subscriptionStatus,
    //     uint256[] memory _lists
    // ) external 
    // isRegisteredDappContract(appID)
    // {
    //     _subscribeToDappInternal(user, appID, subscriptionStatus, _lists);
    // }

    // function _subscribeToDappInternal(
    //     address user,
    //     bytes32 appID,
    //     bool subscriptionStatus,
    //     uint256[] memory _lists
    // ) internal {
    //     require(dapps[appID].appAdmin != address(0), "INVALID DAPP ID");

    //     if (_lists.length == 0) {
    //         require(
    //             isSubscribed[appID][0][user] != subscriptionStatus,
    //             "UNCHANGED"
    //         );
    //         _subscribeToDapp(user, appID, 0, subscriptionStatus);
    //     } else {
    //         if (isSubscribed[appID][0][user] == false) {
    //             _subscribeToDapp(user, appID, 0, true);
    //         }

    //         for (uint256 i = 0; i < _lists.length; i++) {
    //             _subscribeToDapp(user, appID, _lists[i], subscriptionStatus);
    //         }
    //     }
    // }

    function subscribeToDapp(
        address user,
        bytes32 appID,
        bool subscriptionStatus,
        bool isOauthUser,
        uint256[] memory _lists
    ) external 
    isValidSenderOrRegDappContract(user, appID) 
    GasNotZero(_msgSender(), isOauthUser) 
    {
        uint256 gasLeftInit = gasleft();
        require(dapps[appID].appAdmin != address(0), "INVALID DAPP ID");

        if (_lists.length == 0) {
            require(
                isSubscribed[appID][0][user] != subscriptionStatus,
                "UNCHANGED"
            );
            _subscribeToDapp(user, appID, 0, subscriptionStatus);
        } else {
            if (isSubscribed[appID][0][user] == false) {
                _subscribeToDapp(user, appID, 0, true);
            }

            for (uint256 i = 0; i < _lists.length; i++) {
                _subscribeToDapp(user, appID, _lists[i], subscriptionStatus);
            }
        }
        // _subscribeToDappInternal(user, appID, subscriptionStatus, _lists);

        _updateGaslessData(gasLeftInit);
    }

    function _subscribeToDapp(
        address user,
        bytes32 appID,
        uint256 listID,
        bool subscriptionStatus
    ) internal {
        require(isValidList[appID][listID] == true, "not valid list");
        isSubscribed[appID][listID][user] = subscriptionStatus;

        address appAdmin = dapps[appID].appAdmin;

        if (listID == 0) {
            if (subscriptionStatus) {

                if (dapps[appID].isVerifiedDapp && !hasPreviouslysubscribed[appID][user] && dapps[appID].credits != 0) {
                    string memory message; 
                    string memory cta; 
                    string memory butonN;
                  
                        (message, cta, butonN) = gamification.getWelcomeMessage(appID);

                    // (string memory message,string memory cta, string memory butonN) = gamification.welcomeMessage(appID);
                    _sendAppNotification(
                        appID,
                        user,
                        message,
                        butonN,
                        cta,
                        false
                    );
                    hasPreviouslysubscribed[appID][user] = true;

                }
                uint256 subCountUser = ++subscriberCountUser[user];
                uint256 subCountDapp = ++subscriberCount[appID];
                emit AppSubscribed(
                    appID,
                    user,
                    subCountDapp,
                    ++noOfSubscribers
                );
                listUserCount[appID][0]++;
                subscriberCountUser[user]++;

                if (subCountDapp == 100) {
                    // add 10 karma point to app admin

                    gamification.addKarmaPoints(appAdmin, 10);
                } else if (subCountDapp == 500) {
                    // add 50 karma point to app admin
                    gamification.addKarmaPoints(appAdmin, 50);
                } else if (subCountDapp == 1000) {
                    // add 100 karma point to app admin

                    gamification.addKarmaPoints(appAdmin, 100);
                }

                if (subCountUser == 0) {
                    // add 1 karma point to subscriber
                    gamification.addKarmaPoints(user, 1);
                } else if (subCountUser == 5) {
                    // add 5 karma points to subscriber
                    gamification.addKarmaPoints(user, 5);
                }
            } else {
                listUserCount[appID][0]--;

                uint256 subCountUser = --subscriberCountUser[user];
                emit AppUnSubscribed(
                    appID,
                    user,
                    --subscriberCount[appID],
                    --noOfSubscribers
                );
                if (subCountUser == 0) {
                    // remove 1 karma point to app admin
                    gamification.removeKarmaPoints(user, 1);
                } else if (subCountUser == 4) {
                    // remove 5 karma points to app admin
                    gamification.removeKarmaPoints(user, 5);
                }
                // if (subCountDapp == 99) {
                //     // remove 10 karma point
                //     gamification.removeKarmaPoints(dapps[appID].appAdmin, 10);
                // } else if (subCountDapp == 499) {
                //     // remove 50 karma point
                //     gamification.removeKarmaPoints(dapps[appID].appAdmin, 50);
                // } else if (subCountDapp == 999) {
                //     // remove 100 karma point
                //     gamification.removeKarmaPoints(dapps[appID].appAdmin, 100);
                // }
            }
        } else {
            if (subscriptionStatus) {
                listUserCount[appID][listID]++;
            } else {
                listUserCount[appID][listID]--;
            }
        }

        // if (address(0) != getSecondaryWalletAccount(user)) {
        //     isSubscribed[appID][
        //         getSecondaryWalletAccount(user)
        //     ] = subscriptionStatus;
        // }
    }

    // function subscribeWithPermit(
    //     address user,
    //     bytes32 appID,
    //     uint256[] memory _lists,
    //     bool subscriptionStatus,
    //     uint256 deadline,
    //     bytes32 r,
    //     bytes32 s,
    //     uint8 v
    // ) external {
    //     require(dapps[appID].appAdmin != address(0), "INVALID DAPP ID");
    //     // require(isSubscribed[appID][user] != subscriptionStatus, "UNCHANGED");

    //     require(user != address(0), "ZERO_ADDRESS");
    //     require(deadline >= block.timestamp, "EXPIRED");

    //     bytes32 digest = keccak256(
    //         abi.encodePacked(
    //             "\x19\x01",
    //             DOMAIN_SEPARATOR,
    //             keccak256(
    //                 abi.encode(
    //                     SUBSC_PERMIT_TYPEHASH,
    //                     user,
    //                     appID,
    //                     subscriptionStatus,
    //                     nonce[user]++,
    //                     deadline
    //                 )
    //             )
    //         )
    //     );

    //     address recoveredUser = ecrecover(digest, v, r, s);
    //     require(
    //         recoveredUser != address(0) &&
    //             (recoveredUser == user ||
    //                 recoveredUser == getSecondaryWalletAccount(user)),
    //         "INVALID_SIGN"
    //     );

    //     if (_lists.length == 0) {
    //         require(
    //             isSubscribed[appID][0][user] != subscriptionStatus,
    //             "UNCHANGED"
    //         );
    //         _subscribeToDapp(user, appID, 0, subscriptionStatus);
    //     } else {
    //         if (isSubscribed[appID][0][user] == false) {
    //             _subscribeToDapp(user, appID, 0, true);
    //         }

    //         for (uint256 i = 0; i < _lists.length; i++) {
    //             _subscribeToDapp(user, appID, _lists[i], subscriptionStatus);
    //         }
    //     }
    // }

    function appVerification(
        bytes32 appID,
        bool verificationStatus,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) onlySuperAdmin {
        uint256 gasLeftInit = gasleft();

        require(dapps[appID].appAdmin != address(0), "INVALID DAPP ID");
        // require(appID < dappsCount, "INVALID DAPP ID");
        if (
            dapps[appID].isVerifiedDapp != verificationStatus &&
            verificationStatus
        ) {
            verifiedDappsCount++;
            dapps[appID].isVerifiedDapp = verificationStatus;
        } else if (
            dapps[appID].isVerifiedDapp != verificationStatus &&
            !verificationStatus
        ) {
            verifiedDappsCount--;
            dapps[appID].isVerifiedDapp = verificationStatus;
        }

        _updateGaslessData(gasLeftInit);
    }

    function getDappAdmin(bytes32 _dappId) public view returns (address) {
        return dapps[_dappId].appAdmin;
    }

    // -------------------- WALLET FUNCTIONS -----------------------
    function addAccountsRole(
        bytes32 appId,
        address account, // primary address
        uint8 _role, // 0 means no role, 1 meaning only notif, 2 meaning only add admin, 3 meaning both
        bool isOauthUser
    )
        external
        superAdminOrDappAdminOrAddedAdmin(appId)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(dapps[appId].appAdmin != address(0), "INVALID DAPP ID");
        require(dapps[appId].appAdmin != account, "IS_SUPERADMIN");
        require(_role < 4, "INVALID_ROLE");
        require(_role != accountRole[account][appId], "SAME_ROLE");

        accountRole[account][appId] = _role;
        accountRole[getSecondaryWalletAccount(account)][appId] = _role;

        emit AppAdmin(appId, getDappAdmin(appId), account, _role);

        _updateGaslessData(gasLeftInit);
    }

    // primary wallet address.
    function sendAppNotification(
        bytes32 _appId,
        address walletAddress,
        string memory _message,
        string memory buttonName,
        string memory _cta,
        bool _isEncrypted,
        bool isOauthUser
    )
        external
        superAdminOrDappAdminOrSendNotifRoleOrRegDappContract(_appId)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(dapps[_appId].appAdmin != address(0), "INVALID DAPP ID");
        require(dapps[_appId].credits != 0, "0_CREDITS");
        require(
            isSubscribed[_appId][0][walletAddress] == true,
            "NOT_SUBSCRIBED"
        );

        if (notificationsOf[walletAddress].length == 0) {
            // add 1 karma point
            gamification.addKarmaPoints(walletAddress, 1);
        }

        _sendAppNotification(
            _appId,
            walletAddress,
            _message,
            buttonName,
            _cta,
            _isEncrypted
        );

        _updateGaslessData(gasLeftInit);
    }

    function _sendAppNotification(
        bytes32 _appId,
        address walletAddress,
        string memory _message,
        string memory buttonName,
        string memory _cta,
        bool _isEncrypted
    ) internal {
        Notification memory notif = Notification({
            appID: _appId,
            walletAddressTo: walletAddress,
            message: _message,
            buttonName: buttonName,
            cta: _cta,
            timestamp: block.timestamp,
            isEncrypted: _isEncrypted
        });

        notificationsOf[walletAddress].push(notif);

        emit NewNotification(
            _appId,
            walletAddress,
            _message,
            buttonName,
            _cta,
            _isEncrypted,
            ++notificationsCount[_appId],
            ++noOfNotifications
        );
        --dapps[_appId].credits;
    }

    // function sendAppNotification(
    //     bytes32 _appId,
    //     address walletAddress,
    //     string memory _message,
    //     string memory buttonName,
    //     string memory _cta,
    //     bool _isEncrypted
    // ) external onlyOwner {
    //     require(dapps[_appId].appAdmin != address(0), "INVALID DAPP ID");
    //     require(dapps[_appId].credits != 0, "NOT_ENOUGH_CREDITS");
    //     // require(isSubscribed[_appId][walletAddress] == true, "NOT_SUBSCRIBED");

    //     _sendAppNotification(_appId, walletAddress, _message, buttonName, _cta, _isEncrypted);
    // }

    // function _sendAppNotification(
    //     bytes32 _appId,
    //     address walletAddress,
    //     string memory _message,
    //     string memory buttonName,
    //     string memory _cta,
    //     bool _isEncrypted
    // ) internal {
    //     Notification memory notif = Notification({
    //         appID: _appId,
    //         walletAddressTo: walletAddress,
    //         message: _message,
    //         buttonName: buttonName,
    //         cta: _cta,
    //         timestamp: block.timestamp,
    //         isEncrypted: _isEncrypted
    //     });

    //     notificationsOf[walletAddress].push(notif);
        
    //     emit NewNotification(
    //         _appId,
    //         walletAddress,
    //         _message,
    //         buttonName,
    //         _cta,
    //         _isEncrypted,
    //         ++notificationsCount[_appId],
    //         ++noOfNotifications
    //     );
    //     --dapps[_appId].credits;
    // }

    function getNotificationsOf(address user)
        external
        view
        returns (Notification[] memory)
    {
        return notificationsOf[user];
    }

    function getSecondaryWalletAccount(address _account)
        public
        view
        returns (address)
    {
        (address account, , ) = walletRegistry.userWallets(_account);

        return account;
    }

    function getPrimaryFromSecondary(address _account)
        public
        view
        returns (address)
    {
        return walletRegistry.getPrimaryFromSecondary(_account);
    }

    function getDapp(bytes32 dappId) public view returns (Dapp memory) {
        return dapps[dappId];
    }

    // function upgradeCreditsByAdmin( bytes32 dappId,uint amount ) external onlySuperAdmin() {
    //     dapps[dappId].credits = defaultCredits + amount;
    // }

    // function renewCredits(bytes32 dappId, bool isOauthUser)
    //     external
    //     superAdminOrDappAdminOrAddedAdmin(dappId)
    //     GasNotZero(_msgSender(), isOauthUser)
    // {
    //     uint256 gasLeftInit = gasleft();

    //     require(dapps[dappId].appAdmin != address(0), "INVALID_DAPP");
    //     require(
    //         block.timestamp - dapps[dappId].renewalTimestamp == renewalPeriod,
    //         "RPNC"
    //     ); // RENEWAL_PERIOD_NOT_COMPLETED
    //     dapps[dappId].credits = defaultCredits;

    //     _updateGaslessData(gasLeftInit);
    // }

    // function deleteWallet(address _account) external onlySuperAdmin {
    //     require(userWallets[_msgSender()].account != address(0), "NO_ACCOUNT");
    //     delete userWallets[_account];
    //     delete getPrimaryFromSecondary[_account];
    // }
    // ------------------------ TELEGRAM FUNCTIONS -----------------------------------

    // function getTelegramChatID(address userWallet) public view returns (string memory) {
    //     return telegramChatID[userWallet];
    // }

    // function setDomainSeparator() external onlyOwner {
    //     DOMAIN_SEPARATOR = keccak256(abi.encode(
    //         EIP712_DOMAIN_TYPEHASH,
    //         keccak256(bytes("Dapps")),
    //         keccak256(bytes("1")),
    //         chainId,
    //         address(this)
    //     ));
    // }

    function _updateGaslessData(uint256 _gasLeftInit) internal {
        if (isTrustedForwarder[msg.sender]) {
            gasRestrictor._updateGaslessData(_msgSender(), _gasLeftInit);
        }
    }

    //    function createWallet(
    //     address _account,
    //     string calldata _encPvtKey,
    //     string calldata _publicKey,
    //     string calldata oAuthEncryptedUserId,
    //     bool isOauthUser,
    //     address referer
    // ) external {

    // }

    // function userWallets(address _account)
    //     public
    //     view
    //     returns (address, string memory, string memory)
    // {
    //    (address account, string memory encPvKey,string memory pubKey) =  walletRegistry.userWallets(_account);

    //    return (account, encPvKey,pubKey );
    // }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract TestDapps {

    string public message;
    uint256 public dappsCount;

    event NewAppRegistered(
        bytes32 appID, 
        address appAdmin, 
        string appName,
        uint256 dappCount
    );

    event AppAdmin(
        bytes32 appID,
        address appAdmin,
        address admin,
        uint8 role
    );

    event AppSubscribed(bytes32 appID, address subscriber);

    event AppUnSubscribed(bytes32 appID, address subscriber);

    event NewNotification(
        bytes32 appId,
        address walletAddress,
        string message,
        string buttonName,
        string cta
    );

    constructor(string memory _message) {
        // console.log("Deploying a Greeter with message:", _message);
        message = _message;
    }

    function registerApp(
        address _appAdmin, 
        string memory _appName
    ) public {
        bytes32 appID = keccak256(abi.encode(block.number, _appName, dappsCount));
        emit NewAppRegistered(appID, _appAdmin, _appName, dappsCount++);
    }

    function addDappAdmin(
        bytes32 _appID,
        address _appAdmin,
        address _admin,
        uint8 _role
    ) public {
        emit AppAdmin(_appID, _appAdmin, _admin, _role);
    }

    function toggleSubscribe(
        bytes32 _appID, 
        address _subscriber,
        bool _isSubscribe
    ) public {
        if(_isSubscribe)
            emit AppSubscribed(_appID, _subscriber);
        else
            emit AppUnSubscribed(_appID, _subscriber);
    }

    function sendNotification(
        bytes32 _appId,
        address _walletAddress,
        string memory _message,
        string memory _buttonName,
        string memory _cta
    ) public {
        emit NewNotification(_appId, _walletAddress, _message, _buttonName, _cta);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./GasRestrictor.sol";
import "./Gamification.sol";

contract UnifarmAccountsUpgradeable is Initializable, OwnableUpgradeable {
    uint256 public chainId;
    uint256 public defaultCredits;
    uint256 public renewalPeriod;
    GasRestrictor public gasRestrictor;
    Gamification public gamification;



    // --------------------- DAPPS STORAGE -----------------------

    struct Role {
        bool sendNotificationRole;
        bool addAdminRole;
    }
    struct SecondaryWallet {
        address account;
        string encPvtKey;
        string publicKey;
    }

    struct Dapp {
        string appName;
        bytes32 appId;
        address appAdmin; //primary
        string appUrl;
        string appIcon;
        string appSmallDescription;
        string appLargeDescription;
        string appCoverImage;
        string[] appScreenshots; // upto 5
        string[] appCategory; // upto 7
        string[] appTags; // upto 7
        string[] appSocial;
        // string[] appTokens;
        bool isVerifiedDapp; // true or false
        uint256 credits;
        uint256 renewalTimestamp;
  
        
    }

//     struct reaction {
//         string reactionName;
//         uint count;
//     }

//     struct tokenNotif {
//     string message;
//     reaction[] reactions;
//     uint reactionCounts;
//     }
// // token address => tokenNotif 
//     mapping(address=>tokenNotif[]) public tokenNotifs;

    struct Notification {
        bytes32 appID;
        address walletAddressTo; // primary
        string message;
        string buttonName;
        string cta;
        uint256 timestamp;
        bool isEncrypted;
    }
    mapping(bytes32 => Dapp) public dapps;

    // all dapps count
    uint256 public dappsCount;
    uint256 public verifiedDappsCount;

    mapping(address => Notification[]) public notificationsOf;

    // dappId => count
    mapping(bytes32 => uint256) public notificationsCount;

    // dappId => count
    mapping(bytes32 => uint256) public subscriberCount;

    // user=>subscribeAppsCount
    mapping(address => uint256) public subscriberCountUser;
    mapping(address => uint256) public appCountUser;

    // address => dappId  => role
    mapping(address => mapping(bytes32 => Role)) public roleOfAddress;

    // dappId => address => bool(true/false)
    mapping(bytes32 => mapping(address => bool)) public isSubscribed;

    // userAddress  => Wallet
    mapping(address => SecondaryWallet) public userWallets;
    // string => userWallet for email users
    mapping(string => SecondaryWallet) public oAuthUserWallets;

    // secondary to primary wallet mapping to get primary wallet from secondary
    mapping(address => address) public getPrimaryFromSecondary;

    // dappID => telegram chatID
    mapping(address => string) public telegramChatID;

    bytes32 public constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant SUBSC_PERMIT_TYPEHASH =
        keccak256(
            "SubscPermit(address user,bytes32 appID,bool subscriptionStatus,uint256 nonce,uint256 deadline)"
        );
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public DOMAIN_SEPARATOR = keccak256(abi.encode(
    //     EIP712_DOMAIN_TYPEHASH,
    //     keccak256(bytes("Dapps")),
    //     keccak256(bytes("1")),
    //     chainId,
    //     address(this)
    // ));

    mapping(address => uint256) public nonce;

    uint256 public noOfWallets;
    uint256 public noOfSubscribers;
    uint256 public noOfNotifications;

  

    modifier onlySuperAdmin() {
        _onlySuperAdmin();
        _;
    }
    modifier isValidSender(address from) {
       _isValidSender(from);
        _;
    }


    modifier superAdminOrDappAdmin(bytes32 appID) {
       _superAdminOrDappAdmin(appID);
       _;
    }

    modifier superAdminOrDappAdminOrAddedAdmin(bytes32 appID) {
       _superAdminOrDappAdminOrAddedAdmin(appID);
        _;
    }

    modifier superAdminOrDappAdminOrSendNotifRole(bytes32 appID) {
       _superAdminOrDappAdminOrSendNotifRole(appID);
        _;
    }

    modifier GasNotZero(address user, bool isOauthUser) {
        _gasNotZero(user, isOauthUser);
        _;
    }

    event WalletCreated(
        address indexed account,
        address secondaryAccount,
        bool isOAuthUser,
        string oAuthEncryptedUserId,
        uint256 walletCount
    );

    event NewAppRegistered(
        bytes32 appID,
        address appAdmin,
        string appName,
        uint256 dappCount
    );

    event AppUpdated(bytes32 appID);

    event AppRemoved(bytes32 appID, uint256 dappCount);

    event AppAdmin(bytes32 appID, address appAdmin, address admin, uint8 role);

    event AppSubscribed(
        bytes32 appID,
        address subscriber,
        uint256 count,
        uint256 totalCount
    );

    event AppUnSubscribed(
        bytes32 appID,
        address subscriber,
        uint256 count,
        uint256 totalCount
    );

    event NewNotification(
        bytes32 appId,
        address walletAddress,
        string message,
        string buttonName,
        string cta,
        bool isEncrypted,
        uint256 count,
        uint256 totalCount
    );

    function __UnifarmAccounts_init(
        uint256 _chainId,
        uint256 _defaultCredits,
        uint256 _renewalPeriod,
        address _trustedForwarder
    ) public initializer {
        chainId = _chainId;
        defaultCredits = _defaultCredits;
        renewalPeriod = _renewalPeriod;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("Dapps")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        __Ownable_init(_trustedForwarder);
    }


  function _onlySuperAdmin() internal view {
         require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()),
            "INVALID_SENDER"
        );
    }

      function _superAdminOrDappAdmin(bytes32 _appID) internal view {
         address appAdmin = getDappAdmin(_appID);
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() == getSecondaryWalletAccount(appAdmin),
            "INVALID_SENDER"
        );
    }
      function _superAdminOrDappAdminOrSendNotifRole(bytes32 _appID) internal view {
      address appAdmin = getDappAdmin(_appID);
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() == getSecondaryWalletAccount(appAdmin) ||
                roleOfAddress[_msgSender()][_appID].sendNotificationRole == true,
            "INVALID_SENDER"
        );
    }
      function _superAdminOrDappAdminOrAddedAdmin(bytes32 _appID) internal view {
      address appAdmin = getDappAdmin(_appID);
        require(
            _msgSender() == owner() ||
                _msgSender() == getSecondaryWalletAccount(owner()) ||
                _msgSender() == appAdmin ||
                _msgSender() == getSecondaryWalletAccount(appAdmin) ||
                roleOfAddress[_msgSender()][_appID].addAdminRole == true,
            "INVALID_SENDER"
        );
    }

    function _isValidSender(address _from) internal view {
 require(
            _msgSender() == _from ||
                _msgSender() == getSecondaryWalletAccount(_from),
            "INVALID_SENDER"
        );
    }

    // function sendNotifTokenHolders() public {

    // }

    function addGasRestrictorAndGamification(
        GasRestrictor _gasRestrictor,
        Gamification _gamification
    ) external onlyOwner {
        gasRestrictor = _gasRestrictor;
        gamification = _gamification;
    }

    function _gasNotZero(address user, bool isOauthUser) internal view {
        if (isTrustedForwarder[msg.sender]) {
            if (!isOauthUser) {
                if (getPrimaryFromSecondary[user] == address(0)) {} else {
                    (, , uint256 u) = gasRestrictor.gaslessData(
                        getPrimaryFromSecondary[user]
                    );
                    require(u != 0, "NOT_ENOUGH_GASBALANCE");
                }
            } else {
                (, , uint256 u) = gasRestrictor.gaslessData(user);
                require(u != 0, "NOT_ENOUGH_GASBALANCE");
            }
        }
    }

    // -------------------- DAPP FUNCTIONS ------------------------

    function addNewDapp(
        Dapp memory _dapp,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();
        require(_dapp.appAdmin != address(0), "ADMIN CAN'T BE 0 ADDRESS");
        require(_dapp.appScreenshots.length < 6, "SURPASSED IMAGE LIMIT");
        require(_dapp.appCategory.length < 8, "SURPASSED CATEGORY LIMIT");
        require(_dapp.appTags.length < 8, "SURPASSED TAG LIMIT");

        checkFirstApp();
        _addNewDapp(
            _dapp,
            false
        );

        _updateGaslessData(gasLeftInit);
    }

    function _addNewDapp(
        Dapp memory _dapp,
        bool _isAdmin
    ) internal {
        bytes32 _appID;
        Dapp memory dapp = Dapp({
            appName: _dapp.appName,
            appId: _appID,
            appAdmin: _dapp.appAdmin,
            appUrl: _dapp.appUrl,
            appIcon: _dapp.appIcon,
            appCoverImage: _dapp.appCoverImage,
            appSmallDescription: _dapp.appSmallDescription,
            appLargeDescription: _dapp.appLargeDescription,
            appScreenshots: _dapp.appScreenshots,
            appCategory: _dapp.appCategory,
            appTags: _dapp.appTags,
            appSocial: _dapp.appSocial,
            isVerifiedDapp: false,
            credits: defaultCredits,
            renewalTimestamp: block.timestamp
        });
        if(!_isAdmin)
            _appID = keccak256(
                abi.encode(dapp, block.number, _msgSender(), dappsCount, chainId)
            );
        else
            _appID = _dapp.appId;
        dapp.appId = _appID;

        dapps[_appID] = dapp;
        emit NewAppRegistered(_appID, _dapp.appAdmin, _dapp.appName, ++dappsCount);
    }

    function addNewDappOnNewChain(
        Dapp memory _dapp
    ) external onlyOwner {
        // uint256 gasLeftInit = gasleft();
        require(_dapp.appAdmin != address(0), "ADMIN CAN'T BE 0 ADDRESS");
        require(_dapp.appScreenshots.length < 6, "SURPASSED IMAGE LIMIT");
        require(_dapp.appCategory.length < 8, "SURPASSED CATEGORY LIMIT");
        require(_dapp.appTags.length < 8, "SURPASSED TAG LIMIT");
        require(_dapp.appId != "", "INVALID_APP_ID");
        // checkFirstApp();
        _addNewDapp(
            _dapp,
            true
        );

        // _updateGaslessData(gasLeftInit);
    }

    // function addNewDapp(
    //     string memory _appName,
    //     address _appAdmin, //primary
    //     string memory _appUrl,
    //     string memory _appIcon,
    //     string memory _appCoverImage,
    //     string memory _appSmallDescription,
    //     string memory _appLargeDescription,
    //     string[] memory _appScreenshots,
    //     string[] memory _appCategory,
    //     string[] memory _appTags,
    //     string[] memory _appSocial,
    //     bool isOauthUser
    // ) external GasNotZero(_msgSender(), isOauthUser) {
    //     uint256 gasLeftInit = gasleft();
    //     require(_appAdmin != address(0), "ADMIN CAN'T BE 0 ADDRESS");
    //     require(_appScreenshots.length < 6, "SURPASSED IMAGE LIMIT");
    //     require(_appCategory.length < 8, "SURPASSED CATEGORY LIMIT");
    //     require(_appTags.length < 8, "SURPASSED TAG LIMIT");

    //     checkFirstApp();
    //     _addNewDapp(
    //         _appName,
    //         _appAdmin,
    //         _appUrl,
    //         _appIcon,
    //         _appCoverImage,
    //         _appSmallDescription,
    //         _appLargeDescription,
    //         _appScreenshots,
    //         _appCategory,
    //         _appTags,
    //         _appSocial
    //     );

    //     _updateGaslessData(gasLeftInit);
    // }

    // function _addNewDapp(
    //     string memory _appName,
    //     address _appAdmin, //primary
    //     string memory _appUrl,
    //     string memory _appIcon,
    //     string memory _appCoverImage,
    //     string memory _appSmallDescription,
    //     string memory _appLargeDescription,
    //     string[] memory _appScreenshots,
    //     string[] memory _appCategory,
    //     string[] memory _appTags,
    //     string[] memory _appSocial
    // ) internal {
    //     bytes32 _appID;
    //     Dapp memory dapp = Dapp({
    //         appName: _appName,
    //         appId: _appID,
    //         appAdmin: _appAdmin,
    //         appUrl: _appUrl,
    //         appIcon: _appIcon,
    //         appCoverImage: _appCoverImage,
    //         appSmallDescription: _appSmallDescription,
    //         appLargeDescription: _appLargeDescription,
    //         appScreenshots: _appScreenshots,
    //         appCategory: _appCategory,
    //         appTags: _appTags,
    //         appSocial: _appSocial,
    //         isVerifiedDapp: false,
    //         credits: defaultCredits,
    //         renewalTimestamp: block.timestamp
    //     });
    //     _appID = keccak256(
    //         abi.encode(dapp, block.number, _msgSender(), dappsCount, chainId)
    //     );
    //     dapp.appId = _appID;

    //     dapps[_appID] = dapp;
    //     emit NewAppRegistered(_appID, _appAdmin, _appName, ++dappsCount);
    // }

    function checkFirstApp() internal {
        address primary = getPrimaryFromSecondary[_msgSender()];
        if (primary != address(0)) {
            if (appCountUser[primary] == 0) {
                // add 5 karma points of primarywallet
                  gamification.addKarmaPoints(primary, 5);
            }
            appCountUser[primary]++;
        } else {
            if (appCountUser[_msgSender()] == 0) {
                // add 5 karma points of _msgSender()
                  gamification.addKarmaPoints(_msgSender(), 5);

            }
            appCountUser[_msgSender()]++;
        }
    }

    function changeDappAdmin(
        bytes32 _appId,
        address _newAdmin,
        bool isOauthUser
    )
        external
        superAdminOrDappAdmin(_appId)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(dapps[_appId].appAdmin != address(0), "INVALID_DAPP");
        require(_newAdmin != address(0), "INVALID_OWNER");
        dapps[_appId].appAdmin = _newAdmin;

        // if (msg.sender == trustedForwarder)
        //     gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
        _updateGaslessData(gasLeftInit);
    }

    function updateDapp(
        bytes32 _appId,
        string memory _appName,
        string memory _appUrl,
        string[] memory _appImages, // [icon, cover_image]
        // string memory _appSmallDescription,
        // string memory _appLargeDescription,
        string[] memory _appDesc, // [small_desc, large_desc]
        string[] memory _appScreenshots,
        string[] memory _appCategory,
        string[] memory _appTags,
        string[] memory _appSocial, // [twitter_url]
        bool isOauthUser
    )
        external
        superAdminOrDappAdminOrAddedAdmin(_appId)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(_appImages.length == 2, "IMG_LIMIT_EXCEED");
        require(_appScreenshots.length < 6, "SS_LIMIT_EXCEED");
        require(_appCategory.length < 8, "CAT_LIMIT_EXCEED");
        require(_appTags.length < 8, "TAG_LIMIT_EXCEED");
        require(_appDesc.length == 2, "DESC_LIMIT_EXCEED");

        // _updateDappTextInfo(_appId, _appName, _appUrl, _appSmallDescription, _appLargeDescription, _appCategory, _appTags, _appSocial);
        _updateDappTextInfo(
            _appId,
            _appName,
            _appUrl,
            _appDesc,
            _appCategory,
            _appTags,
            _appSocial
        );
        _updateDappImageInfo(_appId, _appImages, _appScreenshots);

      // if(isTrustedForwarder(msg.sender)) {
        //     gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
        // }
        _updateGaslessData(gasLeftInit);
    }

    function _updateDappTextInfo(
        bytes32 _appId,
        string memory _appName,
        string memory _appUrl,
        // string memory _appSmallDescription,
        // string memory _appLargeDescription,
        string[] memory _appDesc,
        string[] memory _appCategory,
        string[] memory _appTags,
        string[] memory _appSocial
    ) internal {
        Dapp storage dapp = dapps[_appId];
        require(dapp.appAdmin != address(0), "INVALID_DAPP");
        if (bytes(_appName).length != 0) dapp.appName = _appName;
        if (bytes(_appUrl).length != 0) dapp.appUrl = _appUrl;
        if (bytes(_appDesc[0]).length != 0)
            dapp.appSmallDescription = _appDesc[0];
        if (bytes(_appDesc[1]).length != 0)
            dapp.appLargeDescription = _appDesc[1];
        // if(_appCategory.length != 0)
        dapp.appCategory = _appCategory;
        // if(_appTags.length != 0)
        dapp.appTags = _appTags;
        // if(_appSocial.length != 0)
        dapp.appSocial = _appSocial;
    }

    function _updateDappImageInfo(
        bytes32 _appId,
        string[] memory _appImages,
        string[] memory _appScreenshots
    ) internal {
        Dapp storage dapp = dapps[_appId];
        // if(bytes(_appImages[0]).length != 0)
        dapp.appIcon = _appImages[0];
        // if(bytes(_appImages[1]).length != 0)
        dapp.appCoverImage = _appImages[1];
        // if(_appScreenshots.length != 0)
        dapp.appScreenshots = _appScreenshots;

        emit AppUpdated(_appId);
    }

    function removeDapp(bytes32 _appId, bool isOauthUser)
        external
        superAdminOrDappAdmin(_appId)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(dapps[_appId].appAdmin != address(0), "INVALID_DAPP");
        if (dapps[_appId].isVerifiedDapp) --verifiedDappsCount;
        delete dapps[_appId];
        --dappsCount;

        emit AppRemoved(_appId, dappsCount);

        _updateGaslessData(gasLeftInit);
    }

    function subscribeToDapp(
        address user,
        bytes32 appID,
        bool subscriptionStatus,
        bool isOauthUser
    ) external isValidSender(user) GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();
        require(dapps[appID].appAdmin != address(0), "INVALID DAPP ID");
        require(isSubscribed[appID][user] != subscriptionStatus, "UNCHANGED");

        _subscribeToDapp(user, appID, subscriptionStatus);

        // if(isTrustedForwarder(msg.sender)) {
        //     gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
        // }
        _updateGaslessData(gasLeftInit);
    }

    function _subscribeToDapp(
        address user,
        bytes32 appID,
        bool subscriptionStatus
    ) internal {
        isSubscribed[appID][user] = subscriptionStatus;

        if (subscriptionStatus) {
            emit AppSubscribed(
                appID,
                user,
                ++subscriberCount[appID],
                ++noOfSubscribers
            );

            if (subscriberCount[appID] == 100) {
                // add 10 karma point to app admin

                gamification.addKarmaPoints(dapps[appID].appAdmin, 10);

            } else if (subscriberCount[appID] == 500) {
                // add 50 karma point to app admin
                gamification.addKarmaPoints(dapps[appID].appAdmin, 50);

            } else if (subscriberCount[appID] == 1000) {
                // add 100 karma point to app admin

                gamification.addKarmaPoints(dapps[appID].appAdmin, 100);


            }

            if (subscriberCountUser[user] == 0) {
                // add 1 karma point to subscriber
                gamification.addKarmaPoints(user, 1);


            } else if (subscriberCountUser[user] == 5) {
                // add 5 karma points to subscriber
                gamification.addKarmaPoints(user, 5);
            }
            subscriberCountUser[user] = subscriberCountUser[user] + 1;
        } else {
            emit AppUnSubscribed(
                appID,
                user,
                --subscriberCount[appID],
                --noOfSubscribers
            );
            if (subscriberCountUser[user] == 0) {
                // remove 1 karma point to app admin
                gamification.removeKarmaPoints(user, 1);
            } else if (subscriberCountUser[user] == 4) {
                // remove 5 karma points to app admin
                gamification.removeKarmaPoints(user, 5);
            }

            if (subscriberCount[appID] == 99) {
                // remove 10 karma point
                gamification.removeKarmaPoints(dapps[appID].appAdmin, 10);
            } else if (subscriberCount[appID] == 499) {
                // remove 50 karma point
                gamification.removeKarmaPoints(dapps[appID].appAdmin, 50);
            } else if (subscriberCount[appID] == 999) {
                // remove 100 karma point
                gamification.removeKarmaPoints(dapps[appID].appAdmin, 100);
            }
        }

        if (address(0) != getSecondaryWalletAccount(user)) {
            isSubscribed[appID][
                getSecondaryWalletAccount(user)
            ] = subscriptionStatus;
        }
    }

    function subscribeWithPermit(
        address user,
        bytes32 appID,
        bool subscriptionStatus,
        uint256 deadline,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        require(dapps[appID].appAdmin != address(0), "INVALID DAPP ID");
        require(isSubscribed[appID][user] != subscriptionStatus, "UNCHANGED");

        require(user != address(0), "ZERO_ADDRESS");
        require(deadline >= block.timestamp, "EXPIRED");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        SUBSC_PERMIT_TYPEHASH,
                        user,
                        appID,
                        subscriptionStatus,
                        nonce[user]++,
                        deadline
                    )
                )
            )
        );

        address recoveredUser = ecrecover(digest, v, r, s);
        require(
            recoveredUser != address(0) &&
                (recoveredUser == user ||
                    recoveredUser == getSecondaryWalletAccount(user)),
            "INVALID_SIGN"
        );

        _subscribeToDapp(user, appID, subscriptionStatus);
    }

    function appVerification(
        bytes32 appID,
        bool verificationStatus,
        bool isOauthUser
    ) external GasNotZero(_msgSender(), isOauthUser) onlySuperAdmin {
        uint256 gasLeftInit = gasleft();

        require(dapps[appID].appAdmin != address(0), "INVALID DAPP ID");
        // require(appID < dappsCount, "INVALID DAPP ID");
        if (
            dapps[appID].isVerifiedDapp != verificationStatus &&
            verificationStatus
        ) {
            verifiedDappsCount++;
            dapps[appID].isVerifiedDapp = verificationStatus;
        } else if (
            dapps[appID].isVerifiedDapp != verificationStatus &&
            !verificationStatus
        ) {
            verifiedDappsCount--;
            dapps[appID].isVerifiedDapp = verificationStatus;
        }

        _updateGaslessData(gasLeftInit);
    }

    function getDappAdmin(bytes32 _dappId) public view returns (address) {
        return dapps[_dappId].appAdmin;
    }

    // -------------------- WALLET FUNCTIONS -----------------------

    function addAppAdmin(
        bytes32 appID,
        address admin, // primary address
        uint8 _role, // 0 meaning only notif, 1 meaning only add admin, 2 meaning both,
        bool isOauthUser
    )
        external
        superAdminOrDappAdminOrAddedAdmin(appID)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(dapps[appID].appAdmin != address(0), "INVALID DAPP ID");
        require(_role < 3, "INAVLID ROLE");
        if (_role == 0) {
            roleOfAddress[admin][appID].addAdminRole = false;
            roleOfAddress[getSecondaryWalletAccount(admin)][appID]
                .addAdminRole = false;
            roleOfAddress[admin][appID].sendNotificationRole = true;
            roleOfAddress[getSecondaryWalletAccount(admin)][appID]
                .sendNotificationRole = true;
        } else if (_role == 1) {
            roleOfAddress[admin][appID].addAdminRole = true;
            roleOfAddress[getSecondaryWalletAccount(admin)][appID]
                .addAdminRole = true;
            roleOfAddress[admin][appID].sendNotificationRole = false;
            roleOfAddress[getSecondaryWalletAccount(admin)][appID]
                .sendNotificationRole = false;
        } else if (_role == 2) {
            roleOfAddress[admin][appID].addAdminRole = true;
            roleOfAddress[getSecondaryWalletAccount(admin)][appID]
                .addAdminRole = true;
            roleOfAddress[admin][appID].sendNotificationRole = true;
            roleOfAddress[getSecondaryWalletAccount(admin)][appID]
                .sendNotificationRole = true;
        }
        emit AppAdmin(appID, getDappAdmin(appID), admin, _role);
        // if (msg.sender == trustedForwarder) {
        //     gasRestrictor._updateGaslessData(_msgSender(), gasLeftInit);
        // }
        _updateGaslessData(gasLeftInit);
    }

    // primary wallet address.
    function sendAppNotification(
        bytes32 _appId,
        address walletAddress,
        string memory _message,
        string memory buttonName,
        string memory _cta,
        bool _isEncrypted,
        bool isOauthUser
    )
        external
        superAdminOrDappAdminOrSendNotifRole(_appId)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(dapps[_appId].appAdmin != address(0), "INVALID DAPP ID");
        require(dapps[_appId].credits != 0, "NOT_ENOUGH_CREDITS");
        require(isSubscribed[_appId][walletAddress] == true, "NOT_SUBSCRIBED");

        if (notificationsOf[walletAddress].length == 0) {
            // add 1 karma point
            gamification.addKarmaPoints(walletAddress, 1);

        }

        _sendAppNotification(
            _appId,
            walletAddress,
            _message,
            buttonName,
            _cta,
            _isEncrypted
        );

        _updateGaslessData(gasLeftInit);
    }

    function _sendAppNotification(
        bytes32 _appId,
        address walletAddress,
        string memory _message,
        string memory buttonName,
        string memory _cta,
        bool _isEncrypted
    ) internal {
        Notification memory notif = Notification({
            appID: _appId,
            walletAddressTo: walletAddress,
            message: _message,
            buttonName: buttonName,
            cta: _cta,
            timestamp: block.timestamp,
            isEncrypted: _isEncrypted
        });

        notificationsOf[walletAddress].push(notif);

        emit NewNotification(
            _appId,
            walletAddress,
            _message,
            buttonName,
            _cta,
            _isEncrypted,
            ++notificationsCount[_appId],
            ++noOfNotifications
        );
        --dapps[_appId].credits;
    }

    function createWallet(
        address _account,
        string calldata _encPvtKey,
        string calldata _publicKey,
        string calldata oAuthEncryptedUserId,
        bool isOauthUser,
        address referer
    ) external {
        if (!isOauthUser) {
            require(
                userWallets[_msgSender()].account == address(0),
                "ACCOUNT_ALREADY_EXISTS"
            );
            SecondaryWallet memory wallet = SecondaryWallet({
                account: _account,
                encPvtKey: _encPvtKey,
                publicKey: _publicKey
            });
            userWallets[_msgSender()] = wallet;
            getPrimaryFromSecondary[_account] = _msgSender();

            gasRestrictor.initUser(_msgSender(), _account, false);

            // add 2 karma point for _msgSender()
               gamification.addKarmaPoints(_msgSender(), 2);

            if (
                referer != address(0) &&
                getSecondaryWalletAccount(referer) != address(0)
            ) {
                 
                // add 5 karma point for _msgSender()
                // add 5 karma point for referer
                gamification.addKarmaPoints(_msgSender(), 5);
                gamification.addKarmaPoints(referer, 5);
            }
        } else {
            require(
                oAuthUserWallets[oAuthEncryptedUserId].account == address(0),
                "ACCOUNT_ALREADY_EXISTS"
            );
            require(_msgSender() == _account, "Invalid_User");
            SecondaryWallet memory wallet = SecondaryWallet({
                account: _account,
                encPvtKey: _encPvtKey,
                publicKey: _publicKey
            });
            oAuthUserWallets[oAuthEncryptedUserId] = wallet;
            // getPrimaryFromSecondary[_account] = _msgSender();

            gasRestrictor.initUser(_msgSender(), _account, true);
        }

        emit WalletCreated(
            _msgSender(),
            _account,
            isOauthUser,
            oAuthEncryptedUserId,
            ++noOfWallets
        );
    }

    function getNotificationsOf(address user)
        external
        view
        returns (Notification[] memory)
    {
        return notificationsOf[user];
    }

    function getSecondaryWalletAccount(address _account)
        public
        view
        returns (address)
    {
        return userWallets[_account].account;
    }

    // function uintToBytes32(uint256 num) public pure returns (bytes32) {
    //     return bytes32(num);
    // }

    function getDapp(bytes32 dappId) public view returns (Dapp memory) {
        return dapps[dappId];
    }

    // function upgradeCreditsByAdmin( bytes32 dappId,uint amount ) external onlySuperAdmin() {
    //     dapps[dappId].credits = defaultCredits + amount;
    // }

    function renewCredits(bytes32 dappId, bool isOauthUser)
        external
        superAdminOrDappAdminOrAddedAdmin(dappId)
        GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();

        require(dapps[dappId].appAdmin != address(0), "INVALID_DAPP");
        require(
            block.timestamp - dapps[dappId].renewalTimestamp == renewalPeriod,
            "RPNC"
        ); // RENEWAL_PERIOD_NOT_COMPLETED
        dapps[dappId].credits = defaultCredits;

        _updateGaslessData(gasLeftInit);
    }

    // function deleteWallet(address _account) external onlySuperAdmin {
    //     require(userWallets[_msgSender()].account != address(0), "NO_ACCOUNT");
    //     delete userWallets[_account];
    //     delete getPrimaryFromSecondary[_account];
    // }
    // ------------------------ TELEGRAM FUNCTIONS -----------------------------------

    function addTelegramChatID(address user, string memory chatID)
        external
        // bool isOauthUser
        isValidSender(user)
    {
        uint256 gasLeftInit = gasleft();
        require(bytes(telegramChatID[user]).length == 0, "INVALID_TG_ID"); // INVALID_TELEGRAM_ID
        telegramChatID[user] = chatID;

        _updateGaslessData(gasLeftInit);
    }

    function updateTelegramChatID(
        address user,
        string memory chatID,
        bool isOauthUser
    ) external isValidSender(user) GasNotZero(_msgSender(), isOauthUser) {
        uint256 gasLeftInit = gasleft();
        require(bytes(telegramChatID[user]).length != 0, "INVALID_TG_IG"); // INVALID_TELEGRAM_ID
        telegramChatID[user] = chatID;

        _updateGaslessData(gasLeftInit);
    }

    // function getTelegramChatID(address userWallet) public view returns (string memory) {
    //     return telegramChatID[userWallet];
    // }

    // function setDomainSeparator() external onlyOwner {
    //     DOMAIN_SEPARATOR = keccak256(abi.encode(
    //         EIP712_DOMAIN_TYPEHASH,
    //         keccak256(bytes("Dapps")),
    //         keccak256(bytes("1")),
    //         chainId,
    //         address(this)
    //     ));
    // }

    function _updateGaslessData(uint256 _gasLeftInit) internal {
        if(isTrustedForwarder[msg.sender]) {
            gasRestrictor._updateGaslessData(_msgSender(), _gasLeftInit);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./GasRestrictor.sol";
import "./Gamification.sol";

contract WalletRegistry is Initializable, OwnableUpgradeable {
    GasRestrictor public gasRestrictor;
    Gamification public gamification;

    // userAddress => telegram chatID
    mapping(address => string) public telegramChatID;

    struct SecondaryWallet {
        address account;
        string encPvtKey;
        string publicKey;
    }

    // userAddress  => Wallet
    mapping(address => SecondaryWallet) public userWallets;
    // string => userWallet for email users
    mapping(string => SecondaryWallet) public oAuthUserWallets;

    // secondary to primary wallet mapping to get primary wallet from secondary
    mapping(address => address) public getPrimaryFromSecondary;

    uint256 public noOfWallets;

    //userAddress => WhatsApp 
    mapping(address => string) public whatsAppId;

    modifier isValidSender(address from) {
        _isValidSender(from);
        _;
    }

    modifier GasNotZero(address user, bool isOauthUser) {
        _gasNotZero(user, isOauthUser);
        _;
    }

    event WalletCreated(
        address indexed account,
        address secondaryAccount,
        bool isOAuthUser,
        string oAuthEncryptedUserId,
        uint256 walletCount
    );

    function __walletRegistry_init(address _trustedForwarder)
        public
        initializer
    {
        __Ownable_init(_trustedForwarder);
    }

    function _isValidSender(address _from) internal view {
        require(
            _msgSender() == _from ||
                _msgSender() == getSecondaryWalletAccount(_from),
            "INVALID_SENDER"
        );
    }

    function _gasNotZero(address user, bool isOauthUser) internal view {
        if (isTrustedForwarder[msg.sender]) {
            if (!isOauthUser) {
                if (getPrimaryFromSecondary[user] == address(0)) {} else {
                    (, , uint256 u) = gasRestrictor.gaslessData(
                        getPrimaryFromSecondary[user]
                    );
                    require(u != 0, "NOT_ENOUGH_GASBALANCE");
                }
            } else {
                (, , uint256 u) = gasRestrictor.gaslessData(user);
                require(u != 0, "NOT_ENOUGH_GASBALANCE");
            }
        }
    }

    function addGasRestrictorAndGamification(
        GasRestrictor _gasRestrictor,
        Gamification _gamification
    ) external onlyOwner {
        gasRestrictor = _gasRestrictor;
        gamification = _gamification;
    }

    function addTelegramChatID(
        address user, 
        string memory chatID,
        bool isOauthUser
    )
        external isValidSender(user) GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();
        require(bytes(telegramChatID[user]).length == 0, "INVALID_TG_ID"); // INVALID_TELEGRAM_ID
        telegramChatID[user] = chatID;

        _updateGaslessData(gasLeftInit);
    }

    function addWhatsAppId(
        address user, 
        string memory id,
        bool isOauthUser
    )
        external isValidSender(user) GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();
        require(bytes(whatsAppId[user]).length == 0, "Already_added"); // INVALID_TELEGRAM_ID
        whatsAppId[user] = id;

        _updateGaslessData(gasLeftInit);
    }

    function updateTelegramChatID(
        address user,
        string memory chatID,
        bool isOauthUser
    ) external isValidSender(user) GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();
        require(bytes(telegramChatID[user]).length != 0, "INVALID_TG_IG"); // INVALID_TELEGRAM_ID
        telegramChatID[user] = chatID;

        _updateGaslessData(gasLeftInit);
    }

    function updateWhatsAppId(
        address user,
        string memory id,
        bool isOauthUser
    ) external isValidSender(user) GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();
        require(bytes(whatsAppId[user]).length != 0, "Not_Added_already"); // Id Not added already
        whatsAppId[user] = id;

        _updateGaslessData(gasLeftInit);
    }


    function createWallet(
        address _account,
        string calldata _encPvtKey,
        string calldata _publicKey,
        string calldata oAuthEncryptedUserId,
        bool isOauthUser,
        address referer
    ) external {
        if (!isOauthUser) {
            require(
                userWallets[_msgSender()].account == address(0),
                "ACCOUNT_ALREADY_EXISTS"
            );
            SecondaryWallet memory wallet = SecondaryWallet({
                account: _account,
                encPvtKey: _encPvtKey,
                publicKey: _publicKey
            });
            userWallets[_msgSender()] = wallet;
            getPrimaryFromSecondary[_account] = _msgSender();

            gasRestrictor.initUser(_msgSender(), _account, false);

            // add 2 karma point for _msgSender()
            gamification.addKarmaPoints(_msgSender(), 2);


            if (
                referer != address(0) &&
                getSecondaryWalletAccount(referer) != address(0)
            ) {
                // add 5 karma point for _msgSender()
                // add 5 karma point for referer
                gamification.addKarmaPoints(_msgSender(), 5);
                gamification.addKarmaPoints(referer, 5);

            }
        } else {
            require(
                oAuthUserWallets[oAuthEncryptedUserId].account == address(0),
                "ACCOUNT_ALREADY_EXISTS"
            );
            require(_msgSender() == _account, "Invalid_User");
            SecondaryWallet memory wallet = SecondaryWallet({
                account: _account,
                encPvtKey: _encPvtKey,
                publicKey: _publicKey
            });
            oAuthUserWallets[oAuthEncryptedUserId] = wallet;
            // getPrimaryFromSecondary[_account] = _msgSender();

              // add 2 karma point for _msgSender()
            gamification.addKarmaPoints(_msgSender(), 2);

            if (
                referer != address(0) &&
                getSecondaryWalletAccount(referer) != address(0)
            ) {
                // add 5 karma point for _msgSender()
                // add 5 karma point for referer
                gamification.addKarmaPoints(_msgSender(), 5);
                gamification.addKarmaPoints(referer, 5);

            }

            gasRestrictor.initUser(_msgSender(), _account, true);
        }

        emit WalletCreated(
            _msgSender(),
            _account,
            isOauthUser,
            oAuthEncryptedUserId,
            ++noOfWallets
        );
    }

    // function createWallet(
    //     address _primaryAccount,
    //     address _account,
    //     string calldata _encPvtKey,
    //     string calldata _publicKey,
    //     string calldata oAuthEncryptedUserId
    // ) external onlyOwner {
    //     require(
    //         userWallets[_primaryAccount].account == address(0),
    //         "ACCOUNT_ALREADY_EXISTS"
    //     );
    //     SecondaryWallet memory wallet = SecondaryWallet({
    //         account: _account,
    //         encPvtKey: _encPvtKey,
    //         publicKey: _publicKey
    //     });
    //     userWallets[_primaryAccount] = wallet;
    //     getPrimaryFromSecondary[_account] = _primaryAccount;

    //     gasRestrictor.initUser(_primaryAccount, _account, false);

    //     // add 2 karma point for _msgSender()
    //     gamification.addKarmaPoints(_primaryAccount, 2);

    //     emit WalletCreated(_primaryAccount, _account, false, oAuthEncryptedUserId, ++noOfWallets);
    // }

    function getSecondaryWalletAccount(address _account)
        public
        view
        returns (address)
    {
        return userWallets[_account].account;
    }

    function _updateGaslessData(uint256 _gasLeftInit) internal {
        if (isTrustedForwarder[msg.sender]) {
            gasRestrictor._updateGaslessData(_msgSender(), _gasLeftInit);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}