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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
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
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";
import "./math/SignedMathUpgradeable.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "../lib/StavmeSaBetProvider.sol";
import "../lib/utils/Registry.sol";

contract StavmeSaBetProviderAllowlist is StavmeSaBetProvider, Registry {
    using StringsUpgradeable for uint256;

    struct InitializeDTO {
        string name;
        string symbol;
        address owner;
        string baseUri;
        string fallbackUri;
        uint8 betProviderFeePercentage;
        uint8 eventProviderFeePercentage;
        uint256 minimumBet;
        uint48 maximumSettlementTime;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        InitializeDTO calldata initializeDto
    ) external payable initializer {
        __Pausable_init(false);
        __Ownable_init(initializeDto.owner);
        __URIStorage_init(initializeDto.baseUri, initializeDto.fallbackUri);
        __ERC721_init(initializeDto.name, initializeDto.symbol);
        __StavmeSaBetProvider_init(
            initializeDto.betProviderFeePercentage,
            initializeDto.eventProviderFeePercentage,
            initializeDto.minimumBet,
            initializeDto.maximumSettlementTime
        );
    }

    function registerEventProvider(IStavmeSaEventProvider provider) external payable onlyOwner(msg.sender) {
        _addEntry(address(provider));
    }

    function unregisterEventProvider(IStavmeSaEventProvider provider) external payable onlyOwner(msg.sender) {
        _removeEntry(address(provider));
    }

    function isEventProviderRegistered(IStavmeSaEventProvider provider) external view returns (bool) {
        return _isRegistered(address(provider));
    }

    function _requireCanPlaceBet(
        address initiator,
        EventDTO memory eventDto,
        EventResult result,
        uint256 value
    ) internal view override returns (bool) {
        _requireRegistered(address(eventDto.eventProvider));

        return super._requireCanPlaceBet(initiator, eventDto, result, value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

import "./IStavmeSaEventProvider.sol";

/**
 * IStavmeSaBetProvider is an ERC721 collection whose tokens represent
 * individual bets on results of an event from an event provider contract
 *
 * @title IStavmeSaBetProvider
 */
interface IStavmeSaBetProvider is IERC165Upgradeable {
    //
    //
    // Errors
    //
    //

    error NotAllowed();
    error InvalidEvent(EventDTO eventDto, EventResult result);
    error InsuffcientValue(uint256 value);
    error EventAlreadyStarted(EventDTO eventDto);
    error BetAlreadyRedeemed(uint256 betId);
    error NotAWinningResult(EventResult result, EventResult actualResult);

    //
    //
    // Types
    //
    //

    struct BetDTO {
        EventDTO eventDto;
        EventResult result;
        uint256 value;
    }

    struct EventDTO {
        IStavmeSaEventProvider eventProvider;
        uint256 eventId;
    }

    //
    //
    // Events
    //
    //

    event BetPlaced(
        uint256 indexed betId,
        address indexed beneficiary,
        EventDTO indexed eventDto,
        EventResult result,
        uint256 value,
        bytes data
    );

    event BetCancelled(
        uint256 indexed betId,
        address indexed beneficiary,
        EventDTO indexed eventDto,
        uint256 value
    );

    event BetRedeemed(
        uint256 indexed betId,
        address indexed beneficiary,
        EventDTO indexed eventDto,
        EventResult result,
        uint256 reward,
        uint256 betProviderFee,
        uint256 eventProviderFee
    );

    event MinimumBetAmountSet(uint256 minimumBet);
    event MaximumSettlementTimeSet(uint48 maximumSettlementTime);

    /**
     * Get the minimum bet amount the user needs to put down in order to participate in a bet.
     *
     * This is decided on the contract level and represents on of the selling points
     * of the bet provider.
     */
    function getMinimumBetAmount() external view returns (uint256 betAmount);

    /**
     * Get the maximum time given to an event provider to settle an event once it has ended
     * 
     * After this period all bets placed an an event can be cancelled.
     */
    function getMaximumSettlementTime() external view returns (uint48 maximumSettlementTime);

    // 
    // 
    // Bet check methods
    // 
    // 

    function canPlaceBet(address initiator, EventDTO calldata eventDto, EventResult result, uint256 value) external view returns (bool);

    function canCancelBet(address initiator, uint256 betId) external view returns (bool);

    function canRedeemBet(address initiator, uint256 betId) external view returns (bool);

    // 
    // 
    // Bet management methods
    // 
    // 

    function placeBet(
        EventDTO calldata eventDto,
        EventResult result,
        bytes calldata data
    ) external payable returns (uint256 betId);

    function cancelBet(uint256 betId) external payable;

    function redeemBet(uint256 betId) external payable;

    // 
    // 
    // Bet introspection methods
    // 
    //

    function estimateBetReward(
        EventDTO calldata eventDto,
        EventResult result,
        uint256 value
    ) external view returns (uint256 reward);

    function hasBet(uint256 betId) external view returns (bool);

    function getBet(uint256 betId) external view returns (BetDTO memory);

    function isBetRedeemed(uint betId) external view returns (bool);

    function getBetReward(
        uint256 betId
    ) external view returns (uint256 reward);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IStavmeSaBetProviderFees {
    error InvalidPercentageValue(uint8 percentage);
    error InvalidTotalFees(uint8 fees);

    event BetProviderFeePercentageSet(uint8 percentage);
    event EventProviderFeePercentageSet(uint8 percentage);

    /**
     * Get the percentage (0 - 100) of the win that goes to the bet provider.
     */
    function getBetProviderFeePercentage()
        external
        view
        returns (uint8 percentage);

    /**
     * Get the percentage (0 - 100) of the win that goes to the event provider.
     */
    function getEventProviderFeePercentage()
        external
        view
        returns (uint8 percentage);

    function getFeesAccrued() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./IStavmeSaEventProvider.sol";

interface IStavmeSaBetProviderValuePlaced {
    function getValuePlaced() external view returns (uint256);

    function getValuePlaced(IStavmeSaEventProvider eventProvider) external view returns (uint256);
    
    function getValuePlaced(IStavmeSaEventProvider eventProvider, uint256 eventId) external view returns (uint256);
    
    function getValuePlaced(IStavmeSaEventProvider eventProvider, uint256 eventId, EventResult result) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IStavmeSaERC721 is IERC721Upgradeable {
    error ERC721MustNotBeABatchTransfer(uint256 tokenId, uint256 batchSize);
    error MustBeTokenOwner(uint256 tokenId, address user);
    error MustExist(uint256 tokenId);

    function withdraw(address payable to, uint256 value) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

type EventResult is bytes32;

/**
 * IStavmeSaEventProvider encapsulates the basic functionality of an
 * event provider - an ERC721 collection whose tokens represent individual events that can be used as subjects of bets
 *
 * @title IStavmeSaEventProvider
 */
interface IStavmeSaEventProvider is IERC165Upgradeable {

    //
    //
    // Errors
    //
    //

    error MustHaveAtLeastOneResult();
    error MustBeValidEventResult(uint256 eventId, EventResult result);
    error MustNotHaveStarted(uint256 eventId, uint48 startTime);
    error MustHaveEnded(uint256 eventId, uint48 endTime);
    error MustBeCancelled(uint256 eventId);
    error MustNotBeCancelled(uint256 eventId);
    error MustBeSettled(uint256 eventId);
    error MustNotBeSettled(uint256 eventId);
    error MustStartInFuture(uint48 startTime);
    error MustStartBeforeItEnds(uint48 startTime, uint48 endTime);

    //
    //
    // Events
    //
    //

    event EventCreated(
        uint256 indexed eventId,
        address indexed owner,
        uint48 startTime,
        uint48 endTime,
        bytes data
    );

    event EventCancelled(
        uint256 indexed eventId,
        bytes data
    );

    event EventSettled(
        uint256 indexed eventId,
        EventResult result,
        bytes data
    );

    //
    //
    // Methods
    //
    //

    function hasEvent(uint256 eventId) external view returns (bool);

    function isPossibleEventResult(
        uint256 eventId,
        EventResult result
    ) external view returns (bool);

    function getAllPossibleEventResults(
        uint256 eventId
    ) external view returns (EventResult[] memory);

    function getEventResult(
        uint256 eventId
    ) external view returns (EventResult);

    function getEventStartAndEndTime(uint256 eventId) external view returns (uint48 startTime, uint48 endTime);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./utils/Pausable.sol";

import "./IStavmeSaBetProvider.sol";
import "./IStavmeSaBetProviderFees.sol";
import "./IStavmeSaBetProviderValuePlaced.sol";
import "./IStavmeSaEventProvider.sol";

import "./StavmeSaERC721.sol";

abstract contract StavmeSaBetProvider is
    IStavmeSaBetProvider,
    IStavmeSaBetProviderFees,
    IStavmeSaBetProviderValuePlaced,
    StavmeSaERC721,
    Pausable
{
    //
    //
    // Storage
    //
    //

    struct EventProviderStats {
        uint256 valuePlaced;
        mapping(uint256 => EventStats) eventStats;
    }

    struct EventStats {
        uint256 valuePlaced;
        mapping(EventResult => EventResultStats) eventResultStats;
    }

    struct EventResultStats {
        uint256 valuePlaced;
    }

    // Minimum value for a bet
    uint256 private __minimumBetAmount;

    // Time after which a bet can be redeemed if the event provider fails to settle an event
    uint48 private __maximumSettlementTime;

    // The percentage of the win that stays in the bet provider
    uint8 private __betProviderFeePercentage;

    // The percentage of the win that goes to event provider
    uint8 private __eventProviderFeePercentage;

    // The value this contract has accrued collecting fees
    uint256 private __feesAccrued;

    // The total combined value of the bets
    uint256 private __valuePlaced;

    // BetID -> BetDTO
    mapping(uint256 => BetDTO) private __betsByBetId;

    // BetID -> Is bet redeemed
    mapping(uint256 => bool) private __betRedemptionsByBetId;

    // Nested information about values locked at different levels
    mapping(IStavmeSaEventProvider => EventProviderStats)
        private __eventProviderStats;

    /**
     * Since we are using minimal proxies to deploy,
     * we'll use this function to initialize the contract
     */
    function __StavmeSaBetProvider_init(
        uint8 betProviderFeePercentage,
        uint8 eventProviderFeePercentage,
        uint256 minimumBetAmount,
        uint48 maximumSettlementTime
    ) internal onlyInitializing {
        _setBetProviderFeePercentage(betProviderFeePercentage);
        _setEventProviderFeePercentage(eventProviderFeePercentage);
        _setMinimumBetAmount(minimumBetAmount);
        _setMaximumSettlementTime(maximumSettlementTime);
    }

    //
    //
    // IStavmeSaBetProvider methods
    //
    //

    function placeBet(
        EventDTO calldata eventDto,
        EventResult result,
        bytes calldata data
    ) external payable returns (uint256 betId) {
        _placeBet(msg.sender, eventDto, result, msg.value, data);
    }

    function cancelBet(uint256 betId) external payable {
        _cancelBet(msg.sender, betId);
    }

    function redeemBet(uint256 betId) external payable {
        _redeemBet(msg.sender, betId);
    }

    function getMinimumBetAmount()
        external
        view
        override
        returns (uint256 betAmount)
    {
        return _getMinimumBetAmount();
    }

    function setMinimumBetAmount(
        uint256 minimumBetAmount
    ) external payable onlyOwner(msg.sender) {
        _setMinimumBetAmount(minimumBetAmount);
    }

    function getMaximumSettlementTime()
        external
        view
        override
        returns (uint48 maximumSettlementTime)
    {
        return _getMaximumSettlementTime();
    }

    function setMaximumSettlementTime(
        uint48 maxiumumSettlementTime
    ) external payable onlyOwner(msg.sender) {
        _setMaximumSettlementTime(maxiumumSettlementTime);
    }

    /**
     * This function should always return true or revert with a specific error
     */
    function canPlaceBet(
        address initiator,
        EventDTO calldata eventDto,
        EventResult result,
        uint256 value
    ) external view override returns (bool) {
        return _requireCanPlaceBet(initiator, eventDto, result, value);
    }

    /**
     * This function should always return true or revert with a specific error
     */
    function canCancelBet(
        address initiator,
        uint256 betId
    ) external view override returns (bool) {
        return _requireCanCancelBet(initiator, betId);
    }

    /**
     * This function should always return true or revert with a specific error
     */
    function canRedeemBet(
        address initiator,
        uint256 betId
    ) external view override returns (bool) {
        return _requireCanRedeemBet(initiator, betId);
    }

    function hasBet(uint256 betId) external view override returns (bool) {
        return _exists(betId);
    }

    function isBetRedeemed(
        uint betId
    ) external view override onlyIfExists(betId) returns (bool) {
        return _isBetRedeemed(betId);
    }

    function getBet(
        uint256 betId
    ) external view onlyIfExists(betId) returns (BetDTO memory bet) {
        bet = __betsByBetId[betId];
    }

    function getBetReward(
        uint256 betId
    ) external view onlyIfExists(betId) returns (uint256 reward) {
        BetDTO storage bet = __betsByBetId[betId];
        EventDTO storage eventDto = bet.eventDto;

        (reward, , ) = _estimateBetReward(
            eventDto.eventProvider,
            eventDto.eventId,
            bet.result,
            bet.value,
            0
        );
    }

    //
    //
    // Estimation methods
    //
    //

    function estimateBetReward(
        EventDTO calldata eventDto,
        EventResult result,
        uint256 value
    ) external view override returns (uint256 reward) {
        (reward, , ) = _estimateBetReward(
            eventDto.eventProvider,
            eventDto.eventId,
            result,
            0,
            value
        );
    }

    //
    //
    // Pausable methods
    //
    //

    function setPaused(bool _paused) external onlyOwner(msg.sender) {
        _setPaused(_paused);
    }

    //
    //
    // StavmeSaBetProviderFees methods
    //
    //

    function getFeesAccrued() external view override returns (uint256) {
        return __feesAccrued;
    }

    function getBetProviderFeePercentage()
        external
        view
        override
        returns (uint8)
    {
        return _getBetProviderFeePercentage();
    }

    function getEventProviderFeePercentage()
        external
        view
        override
        returns (uint8)
    {
        return _getEventProviderFeePercentage();
    }

    function setBetProviderFeePercentage(
        uint8 percentage
    ) external payable onlyOwner(msg.sender) {
        _setBetProviderFeePercentage(percentage);
    }

    function setEventProviderFeePercentage(
        uint8 percentage
    ) external payable onlyOwner(msg.sender) {
        _setEventProviderFeePercentage(percentage);
    }

    function withdrawFees(
        address payable to
    ) external payable onlyOwner(msg.sender) {
        _send(to, __feesAccrued);

        __feesAccrued = 0;

        // TODO Emit an event maybe
    }

    //
    //
    // IStavmeSaBetProviderValuePlaced methods
    //
    //

    function getValuePlaced() external view override returns (uint256) {
        return __valuePlaced;
    }

    function getValuePlaced(
        IStavmeSaEventProvider eventProvider
    ) external view override returns (uint256) {
        return __eventProviderStats[eventProvider].valuePlaced;
    }

    function getValuePlaced(
        IStavmeSaEventProvider eventProvider,
        uint256 eventId
    ) external view override returns (uint256) {
        return
            __eventProviderStats[eventProvider].eventStats[eventId].valuePlaced;
    }

    function getValuePlaced(
        IStavmeSaEventProvider eventProvider,
        uint256 eventId,
        EventResult result
    ) external view override returns (uint256) {
        return
            __eventProviderStats[eventProvider]
                .eventStats[eventId]
                .eventResultStats[result]
                .valuePlaced;
    }

    function _placeBet(
        address initiator,
        EventDTO calldata eventDto,
        EventResult result,
        uint256 value,
        bytes calldata data
    ) internal returns (uint256 betId) {
        // Make sure we can place the bet
        //
        // This needs to include all the checks including pausable status, value etc etc
        _requireCanPlaceBet(initiator, eventDto, result, value);

        // Create the bet ID
        betId = _createTokenId();

        // Mint the bet token
        _safeMint(initiator, betId);

        // Use storage variables to avoid repetitive access
        EventProviderStats storage eventProviderStats = __eventProviderStats[
            eventDto.eventProvider
        ];
        EventStats storage eventStats = eventProviderStats.eventStats[
            eventDto.eventId
        ];
        EventResultStats storage eventResultStats = eventStats.eventResultStats[
            result
        ];

        // Increase the values locked
        //
        // This can be unchecked unless you're very rich
        // and this contract is very popular
        unchecked {
            __valuePlaced += value;
            eventProviderStats.valuePlaced += value;
            eventStats.valuePlaced += value;
            eventResultStats.valuePlaced += value;
        }

        emit BetPlaced(betId, initiator, eventDto, result, value, data);
    }

    function _cancelBet(address initiator, uint256 betId) internal {
        // This needs to include all checks including ownership,
        // bet redemption status, event status etc etc
        _requireCanCancelBet(initiator, betId);

        // Get bet information
        BetDTO storage bet = __betsByBetId[betId];
        EventDTO storage eventDto = bet.eventDto;
        uint256 value = bet.value;

        // Burn the ERC721 token associated with the bet
        _burn(betId);

        // Delete the bet definition and the mapping
        delete __betsByBetId[betId];

        EventProviderStats storage eventProviderStats = __eventProviderStats[
            eventDto.eventProvider
        ];
        EventStats storage eventStats = eventProviderStats.eventStats[
            eventDto.eventId
        ];
        EventResultStats storage eventResultStats = eventStats.eventResultStats[
            bet.result
        ];

        // Decrease values locked
        unchecked {
            __valuePlaced -= value;
            eventProviderStats.valuePlaced -= value;
            eventStats.valuePlaced -= value;
            eventResultStats.valuePlaced -= value;
        }

        // Send moneys back to the user
        _send(initiator, value);

        emit BetCancelled(betId, initiator, eventDto, value);
    }

    function _redeemBet(address initiator, uint256 betId) internal {
        // This needs to include all checks including ownership,
        // bet redemption status, event status etc etc
        _requireCanRedeemBet(initiator, betId);

        // We'll create variables for the struct members accessed more times
        BetDTO storage bet = __betsByBetId[betId];
        EventDTO storage eventDto = bet.eventDto;
        IStavmeSaEventProvider eventProvider = eventDto.eventProvider;
        uint256 eventId = eventDto.eventId;
        EventResult result = bet.result;

        // Now let's get the reward and fees
        (
            uint256 reward,
            uint256 betProviderFee,
            uint256 eventProviderFee
        ) = _estimateBetReward(eventProvider, eventId, result, bet.value, 0);

        // Send the win & the event provider fee
        _send(initiator, reward);
        _send(address(eventProvider), eventProviderFee);

        // Store the information about how much is safe to withdraw from this contract
        unchecked {
            __feesAccrued += betProviderFee;
        }

        // Store the information about bet redemption
        __betRedemptionsByBetId[betId] = true;

        emit BetRedeemed(
            betId,
            initiator,
            eventDto,
            result,
            reward,
            betProviderFee,
            eventProviderFee
        );
    }

    /**
     * Estimate the reward and the fees from bet put on a particular result.
     *
     * The marginalValue parameter represents a not-yet-placed bet value
     * and can be used to estimate the rewards for a future bet. For getting rewards of an existing bet,
     * this should be kept 0.
     */
    function _estimateBetReward(
        IStavmeSaEventProvider eventProvider,
        uint256 eventId,
        EventResult result,
        uint256 value,
        uint256 marginalValue
    )
        internal
        view
        returns (
            uint256 reward,
            uint256 betProviderFee,
            uint256 eventProviderFee
        )
    {
        // betValue combines an already placed bet value with a not-yet-placed marginal value
        //
        // This represents the final bet value after the marginal value has been placed
        // and allows for reward estimation on a nonexisting bet
        uint256 betValue = value + marginalValue;

        // Getting the values locked for event & result
        //
        // TODO Better names would be good - it says value locked but it only decreases
        // when bets are placed or cancelled. When a bet is redeemed, this values stay the same
        EventStats storage eventStats = __eventProviderStats[eventProvider]
            .eventStats[eventId];
        EventResultStats storage eventResultStats = eventStats.eventResultStats[
            result
        ];

        // Now let's calculate the rewards
        //
        // This is the total value placed on a particular event plus the marginal value
        uint256 totalBetValue = eventStats.valuePlaced + marginalValue;

        // This is the total value placed on the result plus the marginal value
        uint256 totalRewards = eventResultStats.valuePlaced + marginalValue;

        // This is the sum of the values placed on losing results
        uint256 totalValueToDistribute = totalBetValue - totalRewards;

        // This is the share of the win that belongs to the user
        //
        // value / totalRewards is the fraction of the reward, then multiplied
        // by totalValueToDistribute makes for the actual win amount
        uint256 totalReward = (totalValueToDistribute * betValue) /
            totalRewards;

        // Now calculate the fees
        betProviderFee = (totalReward * _getBetProviderFeePercentage()) / 100;
        eventProviderFee =
            (totalReward * _getEventProviderFeePercentage()) /
            100;
        reward = totalReward - betProviderFee - eventProviderFee;
    }

    function _requireCanPlaceBet(
        address initiator,
        EventDTO memory eventDto,
        EventResult result,
        uint256 value
    ) internal view virtual returns (bool) {
        // First let's make sure we're not paused
        _requireNotPaused();

        // Check that the value is at least the minimum bet value
        if (value < _getMinimumBetAmount()) {
            revert InsuffcientValue(value);
        }

        IStavmeSaEventProvider eventProvider = eventDto.eventProvider;
        uint256 eventId = eventDto.eventId;

        // Check that the event & the result exist
        //
        // If this throws then we're good - transaction will revert,
        // albeit with a possibly strange error
        if (!eventProvider.isPossibleEventResult(eventId, result)) {
            revert InvalidEvent(eventDto, result);
        }

        // Now let's check that the event has not started yet
        (uint startTime, ) = eventProvider.getEventStartAndEndTime(eventId);
        if (startTime < block.timestamp) {
            revert EventAlreadyStarted(eventDto);
        }
    }

    function _requireCanCancelBet(
        address initiator,
        uint256 betId
    ) internal view virtual returns (bool) {
        // This method does not check for paused state - users should be able to cancel
        // even if the contract is paused

        // First let's make sure the bet is owner by initiator
        //
        // As described in StavmeSaERC721, this will pass if the bet does not
        // exist and the initiator is 0x0 - in which case it's fine since
        // it would be quite difficult to send a transaction from 0x0
        _requireOwnedBy(betId, initiator);

        // This one is obvious
        _requireNotRedeemed(betId);

        BetDTO storage bet = __betsByBetId[betId];
        EventDTO storage eventDto = bet.eventDto;
        IStavmeSaEventProvider eventProvider = eventDto.eventProvider;
        uint256 eventId = eventDto.eventId;

        // Bets on invalid events can always be cancelled
        //
        // This covers a case in which a rogue event provider would
        // remove an event result (or if an event was cancelled)
        try eventProvider.isPossibleEventResult(eventId, bet.result) returns (
            bool isPosibleResult
        ) {
            if (!isPosibleResult) return true;
        } catch {
            // If the above throws, we'll consider the event invalid and allow the bet to be cancelled
            return true;
        }

        // Check whether the event has expired or has not started yet
        try
            eventDto.eventProvider.getEventStartAndEndTime(eventDto.eventId)
        returns (uint48 startTime, uint48 endTime) {
            // If the maximum settlement time has passed and the event has not been settled,
            // allow for the bet to be cancelled
            if (endTime <= block.timestamp + __maximumSettlementTime)
                return true;

            // Otherwise only allow bets to be cancelled if the event has not started yet
            if (startTime <= block.timestamp) {
                revert EventAlreadyStarted(eventDto);
            }
        } catch {
            // If the above throws, we'll consider the event invalid and allow the bet to be cancelled
            return true;
        }
    }

    function _requireCanRedeemBet(
        address initiator,
        uint256 betId
    ) internal view virtual returns (bool) {
        // This method does not check for paused state - users should be able to redeem
        // even if the contract is paused

        // First let's make sure the bet is owner by initiator
        //
        // As described in StavmeSaERC721, this will pass if the bet does not
        // exist and the initiator is 0x0 - in which case it's fine since
        // it would be quite difficult to send a transaction from 0x0
        _requireOwnedBy(betId, initiator);

        // This one is obvious
        _requireNotRedeemed(betId);

        BetDTO storage bet = __betsByBetId[betId];
        EventDTO storage eventDto = bet.eventDto;

        EventResult result = eventDto.eventProvider.getEventResult(
            eventDto.eventId
        );
        if (EventResult.unwrap(result) != EventResult.unwrap(bet.result)) {
            revert NotAWinningResult(bet.result, result);
        }

        return true;
    }

    function _getMinimumBetAmount() internal view returns (uint256) {
        return __minimumBetAmount;
    }

    function _setMinimumBetAmount(uint256 minimumBetAmount) internal {
        __minimumBetAmount = minimumBetAmount;

        emit MinimumBetAmountSet(minimumBetAmount);
    }

    function _getMaximumSettlementTime() internal view returns (uint48) {
        return __maximumSettlementTime;
    }

    function _setMaximumSettlementTime(uint48 maximumSettlementTime) internal {
        __maximumSettlementTime = maximumSettlementTime;

        emit MaximumSettlementTimeSet(maximumSettlementTime);
    }

    function _getBetProviderFeePercentage() internal view returns (uint8) {
        return __betProviderFeePercentage;
    }

    function _setBetProviderFeePercentage(uint8 percentage) internal {
        _requireValidPercentage(percentage);

        __betProviderFeePercentage = percentage;

        emit BetProviderFeePercentageSet(percentage);
    }

    function _getEventProviderFeePercentage() internal view returns (uint8) {
        return __eventProviderFeePercentage;
    }

    function _setEventProviderFeePercentage(uint8 percentage) internal {
        _requireValidPercentage(percentage);

        __eventProviderFeePercentage = percentage;

        emit EventProviderFeePercentageSet(percentage);
    }

    function _isBetRedeemed(uint256 betId) internal view returns (bool) {
        return __betRedemptionsByBetId[betId];
    }

    function _requireNotRedeemed(uint256 betId) internal view {
        if (_isBetRedeemed(betId)) {
            revert BetAlreadyRedeemed(betId);
        }
    }

    function _requireValidPercentage(uint8 percentage) private pure {
        if (percentage > 100) {
            revert InvalidPercentageValue(percentage);
        }
    }

    function _requireValidTotalFees(uint8 fees) private pure {
        if (fees >= 100) {
            revert InvalidTotalFees(fees);
        }
    }

    //
    //
    // IERC165
    //
    //

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(StavmeSaERC721, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IStavmeSaBetProvider).interfaceId ||
            interfaceId == type(IStavmeSaBetProviderFees).interfaceId ||
            interfaceId == type(IStavmeSaBetProviderValuePlaced).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./utils/Ownable.sol";
import "./utils/URIStorage.sol";
import "./utils/Valuable.sol";

import "./IStavmeSaERC721.sol";

abstract contract StavmeSaERC721 is
    IStavmeSaERC721,
    ERC721Upgradeable,
    Ownable,
    Valuable,
    URIStorage
{
    // Required for turning uint256 to string
    using StringsUpgradeable for uint256;

    uint256 private __lastTokenId;

    function setBaseURI(string memory baseUri) external payable onlyOwner(msg.sender) {
        _setBaseURI(baseUri);
    }

    function setFallbackURI(string memory fallbackUri) external payable onlyOwner(msg.sender) {
        _setFallbackURI(fallbackUri);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override onlyIfExists(tokenId) returns (string memory) { 
        return _objectUri(tokenId);
    }

    // 
    // 
    // Withdrawal methods
    // 
    // 

    function withdraw(address payable to, uint256 value) external payable override onlyOwner(msg.sender) {
        _send(to, value);
    }

    //
    //
    // Internal helpers
    //
    //

    function _createTokenId() internal returns (uint256 tokenId) {
        unchecked {
            tokenId = ++__lastTokenId;
        }
    }

    //
    //
    // ERC721Upgradeable hooks
    //
    //

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override {
        if (batchSize > 1) {
            revert ERC721MustNotBeABatchTransfer(firstTokenId, batchSize);
        }

        return super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    //
    //
    // ERC165 methods
    //
    //

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IStavmeSaERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    //
    //
    // Overrides
    //
    //

    function _requireMinted(uint256 tokenId) internal view virtual override {
        // We'll override this one so that we get the nice solidity errors
        // instead of string reverts
        if (!_exists(tokenId)) {
            revert MustExist(tokenId);
        }
    }

    function _requireOwnedBy(uint256 tokenId, address user) internal view virtual {
        // This function has a quirk (not a bug, not a feature, just a quirk)
        // 
        // It will not check whether a token has been minted - i.e.
        // non-existent tokens will pass this check with 0x0 address
        if (_ownerOf(tokenId) != user) {
            revert MustBeTokenOwner(tokenId, user);
        }
    }

    function _objectURIPath(uint256 tokenId) internal view override returns (string memory) {
        this;

        return tokenId.toString();
    }

    //
    //
    // Helpers
    //
    //

    modifier onlyIfExists(uint256 tokenId) {
        _requireMinted(tokenId);

        _;
    }

    modifier onlyIfTokenOwner(uint256 tokenId, address user) {
        _requireOwnedBy(tokenId, user);

        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Ownable is Initializable {
  address private __owner;
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  error OwnableUserMustBeOwner(address user);

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner(address user) {
    if (_owner() != user) {
      revert OwnableUserMustBeOwner(user);
    }

    _;
  }

  function __Ownable_init(address newOwner) internal onlyInitializing {
    _setOwner(newOwner);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view virtual returns (address) {
    return _owner();
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function _owner() internal view virtual returns (address) {
    return __owner;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _setOwner(address newOwner) internal virtual returns (address oldOwner) {
    oldOwner = __owner;
    __owner = newOwner;

    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

abstract contract Pausable is Initializable {
    event SetPaused(bool paused);

    error PausableMustBePaused();
    error PausableMustNotBePaused();

    bool private __paused;

    function __Pausable_init(bool _paused) initializer internal {
        _setPaused(_paused);
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

    function paused() public view virtual returns (bool) {
        return __paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (__paused) {
            revert PausableMustNotBePaused();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!__paused) {
            revert PausableMustBePaused();
        }
    }

    function _setPaused(bool _paused) internal virtual {
        if (__paused == _paused) return;

        __paused = _paused;

        emit SetPaused(__paused);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Registry is Initializable {
  error NotRegistered(address entry);

  event RegistryEntryAdded(address entry);
  event RegistryEntryRemoved(address entry);

  mapping(address => bool) __registered;

  function _isRegistered(address entry) internal view returns (bool) {
    return __registered[entry];
  }

  function _addEntry(address entry) internal {
    if (__registered[entry]) return;

    __registered[entry] = true;

    emit RegistryEntryAdded(entry);
  }

  function _removeEntry(address entry) internal {
    if (!__registered[entry]) return;

    __registered[entry] = false;

    emit RegistryEntryRemoved(entry);
  }

  function _requireRegistered(address entry) internal view {
    if (!__registered[entry]) {
      revert NotRegistered(entry);
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

abstract contract URIStorage is Initializable {
    event BaseURIChanged(string baseUri);
    event FallbackURIChanged(string defaultUri);
    event ObjectURIChanged(uint256 indexed objectId, string objectUri);

    string private __baseUri;

    string private __fallbackUri;

    mapping(uint256 => string) private __objectPaths;

    function __URIStorage_init(
        string memory baseUri,
        string memory fallbackUri
    ) internal initializer {
        _setBaseURI(baseUri);
        _setFallbackURI(fallbackUri);
    }

    function _objectURIPath(uint256 objectId) internal view virtual returns (string memory) {
        return __objectPaths[objectId];
    }

    function _objectUri(uint256 objectId) internal view virtual returns (string memory) {
        string memory objectUriPath = _objectURIPath(objectId);
        if (bytes(objectUriPath).length == 0) {
            return _getFallbackURI();
        }

        string memory baseUri = _getBaseURI();
        if (bytes(baseUri).length == 0) {
            return objectUriPath;
        }

        return string(abi.encodePacked(_getBaseURI(), objectUriPath));
    }

    function _setFallbackURI(string memory fallbackUri) internal {
        __fallbackUri = fallbackUri;

        emit FallbackURIChanged(fallbackUri);
    }

    function _getFallbackURI() internal view returns (string memory) {
        return __fallbackUri;
    }

    function _setBaseURI(string memory baseUri) internal {
        __baseUri = baseUri;

        emit BaseURIChanged(baseUri);
    }

    function _getBaseURI() internal view returns (string memory) {
        return __baseUri;
    }

    function _setObjectURIPath(
        uint256 objectId,
        string memory objectUriPath
    ) internal {
        __objectPaths[objectId] = objectUriPath;

        emit ObjectURIChanged(objectId, _objectUri(objectId));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

abstract contract Valuable {

    error MustHaveSufficientBalance(uint256 value, uint256 balance);
    error MustReceiveValue(address beneficiary, uint256 value, bytes data);

    function _send(address to, uint256 value) internal {
        uint256 balance = address(this).balance;
        if (value > address(this).balance) {
            revert MustHaveSufficientBalance(value, balance);
        }

        (bool sent, bytes memory data) = to.call{value: value}("");
        if (!sent) {
            revert MustReceiveValue(to, value, data);
        }
    }

    fallback() external payable {}

    receive() external payable {}

}