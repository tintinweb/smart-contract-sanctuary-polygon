pragma solidity >=0.8.4;

interface ENS {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IABIResolver {
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);

    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(
        bytes32 node,
        uint256 contentTypes
    ) external view returns (uint256, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the new (multicoin) addr function.
 */
interface IAddressResolver {
    event AddressChanged(
        bytes32 indexed node,
        uint256 coinType,
        bytes newAddress
    );

    function addr(
        bytes32 node,
        uint256 coinType
    ) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the legacy (ETH-only) addr function.
 */
interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address a);

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address payable);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IContentHashResolver {
    event ContenthashChanged(bytes32 indexed node, bytes hash);

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDNSRecordResolver {
    // DNSRecordChanged is emitted whenever a given node/name/resource's RRSET is updated.
    event DNSRecordChanged(
        bytes32 indexed node,
        bytes name,
        uint16 resource,
        bytes record
    );
    // DNSRecordDeleted is emitted whenever a given node/name/resource's RRSET is deleted.
    event DNSRecordDeleted(bytes32 indexed node, bytes name, uint16 resource);

    /**
     * Obtain a DNS record.
     * @param node the namehash of the node for which to fetch the record
     * @param name the keccak-256 hash of the fully-qualified name for which to fetch the record
     * @param resource the ID of the resource as per https://en.wikipedia.org/wiki/List_of_DNS_record_types
     * @return the DNS record in wire format if present, otherwise empty
     */
    function dnsRecord(
        bytes32 node,
        bytes32 name,
        uint16 resource
    ) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDNSZoneResolver {
    // DNSZonehashChanged is emitted whenever a given node's zone hash is updated.
    event DNSZonehashChanged(
        bytes32 indexed node,
        bytes lastzonehash,
        bytes zonehash
    );

    /**
     * zonehash obtains the hash for the zone.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function zonehash(bytes32 node) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IExtendedResolver {
    function resolve(
        bytes memory name,
        bytes memory data
    ) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IInterfaceResolver {
    event InterfaceChanged(
        bytes32 indexed node,
        bytes4 indexed interfaceID,
        address implementer
    );

    /**
     * Returns the address of a contract that implements the specified interface for this name.
     * If an implementer has not been set for this interfaceID and name, the resolver will query
     * the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     * contract implements EIP165 and returns `true` for the specified interfaceID, its address
     * will be returned.
     * @param node The ENS node to query.
     * @param interfaceID The EIP 165 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(
        bytes32 node,
        bytes4 interfaceID
    ) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IPubkeyResolver {
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ITextResolver {
    event TextChanged(
        bytes32 indexed node,
        string indexed indexedKey,
        string key,
        string value
    );

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(
        bytes32 node,
        string calldata key
    ) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./profiles/IABIResolver.sol";
import "./profiles/IAddressResolver.sol";
import "./profiles/IAddrResolver.sol";
import "./profiles/IContentHashResolver.sol";
import "./profiles/IDNSRecordResolver.sol";
import "./profiles/IDNSZoneResolver.sol";
import "./profiles/IInterfaceResolver.sol";
import "./profiles/INameResolver.sol";
import "./profiles/IPubkeyResolver.sol";
import "./profiles/ITextResolver.sol";
import "./profiles/IExtendedResolver.sol";

/**
 * A generic resolver interface which includes all the functions including the ones deprecated
 */
interface Resolver is
    IERC165,
    IABIResolver,
    IAddressResolver,
    IAddrResolver,
    IContentHashResolver,
    IDNSRecordResolver,
    IDNSZoneResolver,
    IInterfaceResolver,
    INameResolver,
    IPubkeyResolver,
    ITextResolver,
    IExtendedResolver
{
    /* Deprecated events */
    event ContentChanged(bytes32 indexed node, bytes32 hash);

    function setABI(
        bytes32 node,
        uint256 contentType,
        bytes calldata data
    ) external;

    function setAddr(bytes32 node, address addr) external;

    function setAddr(bytes32 node, uint256 coinType, bytes calldata a) external;

    function setContenthash(bytes32 node, bytes calldata hash) external;

    function setDnsrr(bytes32 node, bytes calldata data) external;

    function setName(bytes32 node, string calldata _name) external;

    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external;

    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) external;

    function setInterface(
        bytes32 node,
        bytes4 interfaceID,
        address implementer
    ) external;

    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results);

    function multicallWithNodeCheck(
        bytes32 nodehash,
        bytes[] calldata data
    ) external returns (bytes[] memory results);

    /* Deprecated functions */
    function content(bytes32 node) external view returns (bytes32);

    function multihash(bytes32 node) external view returns (bytes memory);

    function setContent(bytes32 node, bytes32 hash) external;

    function setMultihash(bytes32 node, bytes calldata hash) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

error MustHaveCollectionRole(uint8 role);
error MustHaveTokenRole(uint256 tokenId, uint8 role);
error MustHaveAtLeastOneOwner();
error RoleAlreadySet();

contract FleekAccessControl is Initializable {
    /**
     * @dev All available collection roles.
     */
    enum CollectionRoles {
        Owner,
        Verifier
    }

    /**
     * @dev All available token roles.
     */
    enum TokenRoles {
        Controller
    }

    /**
     * @dev Emitted when a token role is changed.
     */
    event TokenRoleChanged(
        uint256 indexed tokenId,
        TokenRoles indexed role,
        address indexed toAddress,
        bool status,
        address byAddress
    );

    /**
     * @dev Emitted when token roles version is increased and all token roles are cleared.
     */
    event TokenRolesCleared(uint256 indexed tokenId, address byAddress);

    /**
     * @dev Emitted when a collection role is changed.
     */
    event CollectionRoleChanged(
        CollectionRoles indexed role,
        address indexed toAddress,
        bool status,
        address byAddress
    );

    /**
     * @dev _collectionRolesCounter[role] is the number of addresses that have the role.
     * This is prevent Owner role to go to 0.
     */
    mapping(CollectionRoles => uint256) private _collectionRolesCounter;

    /**
     * @dev _collectionRoles[role][address] is the mapping of addresses that have the role.
     */
    mapping(CollectionRoles => mapping(address => bool)) private _collectionRoles;

    /**
     * @dev _tokenRolesVersion[tokenId] is the version of the token roles.
     * The version is incremented every time the token roles are cleared.
     * Should be incremented every token transfer.
     */
    mapping(uint256 => uint256) private _tokenRolesVersion;

    /**
     * @dev _tokenRoles[tokenId][version][role][address] is the mapping of addresses that have the role.
     */
    mapping(uint256 => mapping(uint256 => mapping(TokenRoles => mapping(address => bool)))) private _tokenRoles;

    /**
     * @dev Initializes the contract by granting the `Owner` role to the deployer.
     */
    function __FleekAccessControl_init() internal onlyInitializing {
        _grantCollectionRole(CollectionRoles.Owner, msg.sender);
        _grantCollectionRole(CollectionRoles.Verifier, msg.sender);
    }

    /**
     * @dev Checks if the `msg.sender` has a certain role.
     */
    function _requireCollectionRole(CollectionRoles role) internal view {
        if (!hasCollectionRole(role, msg.sender)) revert MustHaveCollectionRole(uint8(role));
    }

    /**
     * @dev Checks if the `msg.sender` has the `Token` role for a certain `tokenId`.
     */
    function _requireTokenRole(uint256 tokenId, TokenRoles role) internal view {
        if (!hasTokenRole(tokenId, role, msg.sender)) revert MustHaveTokenRole(tokenId, uint8(role));
    }

    /**
     * @dev Returns `True` if a certain address has the collection role.
     */
    function hasCollectionRole(CollectionRoles role, address account) public view returns (bool) {
        return _collectionRoles[role][account];
    }

    /**
     * @dev Returns `True` if a certain address has the token role.
     */
    function hasTokenRole(uint256 tokenId, TokenRoles role, address account) public view returns (bool) {
        uint256 currentVersion = _tokenRolesVersion[tokenId];
        return _tokenRoles[tokenId][currentVersion][role][account];
    }

    /**
     * @dev Grants the collection role to an address.
     */
    function _grantCollectionRole(CollectionRoles role, address account) internal {
        if (hasCollectionRole(role, account)) revert RoleAlreadySet();

        _collectionRoles[role][account] = true;
        _collectionRolesCounter[role] += 1;

        emit CollectionRoleChanged(role, account, true, msg.sender);
    }

    /**
     * @dev Revokes the collection role of an address.
     */
    function _revokeCollectionRole(CollectionRoles role, address account) internal {
        if (!hasCollectionRole(role, account)) revert RoleAlreadySet();
        if (role == CollectionRoles.Owner && _collectionRolesCounter[role] == 1) revert MustHaveAtLeastOneOwner();

        _collectionRoles[role][account] = false;
        _collectionRolesCounter[role] -= 1;

        emit CollectionRoleChanged(role, account, false, msg.sender);
    }

    /**
     * @dev Grants the token role to an address.
     */
    function _grantTokenRole(uint256 tokenId, TokenRoles role, address account) internal {
        if (hasTokenRole(tokenId, role, account)) revert RoleAlreadySet();

        uint256 currentVersion = _tokenRolesVersion[tokenId];
        _tokenRoles[tokenId][currentVersion][role][account] = true;

        emit TokenRoleChanged(tokenId, role, account, true, msg.sender);
    }

    /**
     * @dev Revokes the token role of an address.
     */
    function _revokeTokenRole(uint256 tokenId, TokenRoles role, address account) internal {
        if (!hasTokenRole(tokenId, role, account)) revert RoleAlreadySet();

        uint256 currentVersion = _tokenRolesVersion[tokenId];
        _tokenRoles[tokenId][currentVersion][role][account] = false;

        emit TokenRoleChanged(tokenId, role, account, false, msg.sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    function _clearTokenRoles(uint256 tokenId) internal {
        _tokenRolesVersion[tokenId] += 1;
        emit TokenRolesCleared(tokenId, msg.sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {FleekStrings} from "./util/FleekStrings.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

error AccessPointNotExistent();
error AccessPointAlreadyExists();
error AccessPointScoreCannotBeLower();
error MustBeAccessPointOwner();
error InvalidTokenIdForAccessPoint();
error AccessPointCreationStatusAlreadySet();

abstract contract FleekAccessPoints is Initializable {
    using FleekStrings for FleekAccessPoints.AccessPoint;

    event NewAccessPoint(string apName, uint256 indexed tokenId, address indexed owner);
    event RemoveAccessPoint(string apName, uint256 indexed tokenId, address indexed owner);

    event ChangeAccessPointScore(string apName, uint256 indexed tokenId, uint256 score, address indexed triggeredBy);

    event ChangeAccessPointNameVerify(
        string apName,
        uint256 tokenId,
        bool indexed verified,
        address indexed triggeredBy
    );
    event ChangeAccessPointContentVerify(
        string apName,
        uint256 tokenId,
        bool indexed verified,
        address indexed triggeredBy
    );
    event ChangeAccessPointCreationStatus(
        string apName,
        uint256 tokenId,
        AccessPointCreationStatus status,
        address indexed triggeredBy
    );

    /**
     * Creation status enums for access points
     */
    enum AccessPointCreationStatus {
        DRAFT,
        APPROVED,
        REJECTED,
        REMOVED
    }

    /**
     * The stored data for each AccessPoint.
     */
    struct AccessPoint {
        uint256 tokenId;
        uint256 score;
        bool contentVerified;
        bool nameVerified;
        address owner;
        AccessPointCreationStatus status;
    }

    mapping(string => AccessPoint) private _accessPoints;

    mapping(uint256 => bool) private _autoApproval;

    /**
     * @dev Checks if the AccessPoint exists.
     */
    modifier requireAP(string memory apName) {
        if (_accessPoints[apName].owner == address(0)) revert AccessPointNotExistent();
        _;
    }

    /**
     * @dev A view function to gether information about an AccessPoint.
     * It returns a JSON string representing the AccessPoint information.
     */
    function getAccessPointJSON(string memory apName) public view requireAP(apName) returns (string memory) {
        AccessPoint storage _ap = _accessPoints[apName];
        return _ap.toString();
    }

    /**
     * @dev A view function to check if a AccessPoint is verified.
     */
    function isAccessPointNameVerified(string memory apName) public view requireAP(apName) returns (bool) {
        return _accessPoints[apName].nameVerified;
    }

    /**
     * @dev Increases the score of a AccessPoint registry.
     */
    function increaseAccessPointScore(string memory apName) public requireAP(apName) {
        _accessPoints[apName].score++;
        emit ChangeAccessPointScore(apName, _accessPoints[apName].tokenId, _accessPoints[apName].score, msg.sender);
    }

    /**
     * @dev Decreases the score of a AccessPoint registry if is greater than 0.
     */
    function decreaseAccessPointScore(string memory apName) public requireAP(apName) {
        if (_accessPoints[apName].score == 0) revert AccessPointScoreCannotBeLower();
        _accessPoints[apName].score--;
        emit ChangeAccessPointScore(apName, _accessPoints[apName].tokenId, _accessPoints[apName].score, msg.sender);
    }

    /**
     * @dev Add a new AccessPoint register for an app token.
     * The AP name should be a DNS or ENS url and it should be unique.
     */
    function _addAccessPoint(uint256 tokenId, string memory apName) internal {
        if (_accessPoints[apName].owner != address(0)) revert AccessPointAlreadyExists();

        emit NewAccessPoint(apName, tokenId, msg.sender);

        if (_autoApproval[tokenId]) {
            // Auto Approval is on.
            _accessPoints[apName] = AccessPoint(
                tokenId,
                0,
                false,
                false,
                msg.sender,
                AccessPointCreationStatus.APPROVED
            );

            emit ChangeAccessPointCreationStatus(apName, tokenId, AccessPointCreationStatus.APPROVED, msg.sender);
        } else {
            // Auto Approval is off. Should wait for approval.
            _accessPoints[apName] = AccessPoint(tokenId, 0, false, false, msg.sender, AccessPointCreationStatus.DRAFT);
            emit ChangeAccessPointCreationStatus(apName, tokenId, AccessPointCreationStatus.DRAFT, msg.sender);
        }
    }

    /**
     * @dev Remove an AccessPoint registry for an app token.
     * It will also remove the AP from the app token APs list.
     */
    function _removeAccessPoint(string memory apName) internal requireAP(apName) {
        if (msg.sender != _accessPoints[apName].owner) revert MustBeAccessPointOwner();
        _accessPoints[apName].status = AccessPointCreationStatus.REMOVED;
        uint256 tokenId = _accessPoints[apName].tokenId;
        emit ChangeAccessPointCreationStatus(apName, tokenId, AccessPointCreationStatus.REMOVED, msg.sender);
        emit RemoveAccessPoint(apName, tokenId, msg.sender);
    }

    /**
     * @dev Updates the `accessPointAutoApproval` settings on minted `tokenId`.
     */
    function _setAccessPointAutoApproval(uint256 tokenId, bool _apAutoApproval) internal {
        _autoApproval[tokenId] = _apAutoApproval;
    }

    /**
     * @dev Set approval settings for an access point.
     * It will add the access point to the token's AP list, if `approved` is true.
     */
    function _setApprovalForAccessPoint(uint256 tokenId, string memory apName, bool approved) internal {
        AccessPoint storage accessPoint = _accessPoints[apName];
        if (accessPoint.tokenId != tokenId) revert InvalidTokenIdForAccessPoint();
        if (accessPoint.status != AccessPointCreationStatus.DRAFT) revert AccessPointCreationStatusAlreadySet();

        if (approved) {
            // Approval
            accessPoint.status = AccessPointCreationStatus.APPROVED;
            emit ChangeAccessPointCreationStatus(apName, tokenId, AccessPointCreationStatus.APPROVED, msg.sender);
        } else {
            // Not Approved
            accessPoint.status = AccessPointCreationStatus.REJECTED;
            emit ChangeAccessPointCreationStatus(apName, tokenId, AccessPointCreationStatus.REJECTED, msg.sender);
        }
    }

    /**
     * @dev Set the content verification of a AccessPoint registry.
     */
    function _setAccessPointContentVerify(string memory apName, bool verified) internal requireAP(apName) {
        _accessPoints[apName].contentVerified = verified;
        emit ChangeAccessPointContentVerify(apName, _accessPoints[apName].tokenId, verified, msg.sender);
    }

    /**
     * @dev Set the name verification of a AccessPoint registry.
     */
    function _setAccessPointNameVerify(string memory apName, bool verified) internal requireAP(apName) {
        _accessPoints[apName].nameVerified = verified;
        emit ChangeAccessPointNameVerify(apName, _accessPoints[apName].tokenId, verified, msg.sender);
    }

    /**
     * @dev Get the AccessPoint token id.
     */
    function _getAccessPointTokenId(string memory apName) internal view requireAP(apName) returns (uint256) {
        return _accessPoints[apName].tokenId;
    }

    /**
     * @dev Get the Auto Approval setting for token id.
     */
    function _getAccessPointAutoApproval(uint256 tokenId) internal view returns (bool) {
        return _autoApproval[tokenId];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./util/FleekSVG.sol";
import "./util/NonBlockingLzApp.sol";
import "./FleekERC721.sol";

contract FleekApps is Initializable, ERC721Upgradeable, NonblockingLzApp {
    using Strings for address;
    using Base64 for bytes;

    /**
     * The metadata that is stored for each build.
     */
    struct Build {
        string commitHash;
        string gitRepository;
        string ipfsHash;
        string domain;
    }

    /**
     * The properties are stored as string to keep consistency with
     * other token contracts, we might consider changing for bytes32
     * in the future due to gas optimization.
     */
    struct Token {
        string name; // Name of the site
        string image; // Image
        string ipfsHash; // IPFS Hash
    }

    uint256 public bindCount;
    mapping(uint256 => Token) public bindings;

    // FleekERC721 main;
    address public main;
    
    uint16 destChainId; // destination chain is sepolia
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol, address mainCollection, address _lzEndpoint) public initializer {
        __ERC721_init(_name, _symbol);
        main = mainCollection;
        destChainId = 10161;
        trustedRemoteLookup[destChainId] = abi.encodePacked(mainCollection, address(this));
        NonblockingLzApp.initializeNonblockingLzApp(_lzEndpoint);
    }

    function setMain(address mainAddress) public {
        main = mainAddress;
        trustedRemoteLookup[destChainId] = abi.encodePacked(mainAddress, address(this));
    }

    // modifier _requireMainMinted(uint256 _tokenId) {
    //     require(main.ownerOf(_tokenId) != address(0), "Main token does not exist");
    //     _;
    // }

    function mint(address _to, uint256 _tokenId) public /**_requireMainMinted(_tokenId)*/ payable {
        _mint(_to, bindCount);
        // Call the main erc contract to add the metadata in this contract
        _lzSend(uint16(destChainId), abi.encode(_tokenId), payable(msg.sender), address(0x0), bytes(""), msg.value);
    }

    function _nonblockingLzReceive(uint16, bytes memory, uint64, bytes memory _payload) override internal {
        (string memory name, string memory ens, string memory logo, string memory color, string memory ipfsHash) = abi.decode(_payload, (string, string, string, string, string));
        bindings[bindCount] = Token (
            name,
            FleekSVG.generateBase64(name, ens, logo, color),
            ipfsHash
        );
        bindCount++;
    }

    function tokenURI(uint256 _bindId) public view virtual override(ERC721Upgradeable) returns (string memory) {
        Token memory token = bindings[_bindId];
        // prettier-ignore
        return string(abi.encodePacked(_baseURI(),
            abi.encodePacked('{',
                '"owner":"', ownerOf(_bindId).toHexString(), '",',
                '"name":"', token.name, '",',
                '"image":"', token.image, '",',
                '"external_url":"ipfs://', token.ipfsHash, '"',
            '}').encode()
        ));
    }

    /**
     * @dev Override of transfer of ERC721.
     * Transfer is disabled for NFA tokens.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        revert TransferIsDisabled();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "data:application/json;base64,";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

error RequiredPayment(uint requiredValue);

abstract contract FleekBilling is Initializable {
    /**
     * @dev Available billing values.
     */
    enum Billing {
        Mint,
        AddAccessPoint
    }

    /**
     * @dev Emitted when the billing value is changed.
     */
    event BillingChanged(Billing key, uint256 price);

    /**
     * @dev Emitted when contract is withdrawn.
     */
    event Withdrawn(uint256 value, address indexed byAddress);

    /**
     * @dev Mapping of billing values.
     */
    mapping(Billing => uint256) private _billings;

    /**
     * @dev Initializes the contract by setting default billing values.
     */
    function __FleekBilling_init(uint256[] memory initialBillings) internal onlyInitializing {
        for (uint256 i = 0; i < initialBillings.length; i++) {
            _setBilling(Billing(i), initialBillings[i]);
        }
    }

    /**
     * @dev Returns the billing value for a given key.
     */
    function getBilling(Billing key) public view returns (uint256) {
        return _billings[key];
    }

    /**
     * @dev Sets the billing value for a given key.
     */
    function _setBilling(Billing key, uint256 price) internal {
        _billings[key] = price;
        emit BillingChanged(key, price);
    }

    /**
     * @dev Internal function to require a payment value.
     */
    function _requirePayment(Billing key) internal {
        uint256 requiredValue = _billings[key];
        if (msg.value != _billings[key]) revert RequiredPayment(requiredValue);
    }

    /**
     * @dev Internal function to withdraw the contract balance.
     */
    function _withdraw() internal {
        address by = msg.sender;
        uint256 value = address(this).balance;

        payable(by).transfer(value);
        emit Withdrawn(value, by);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./FleekAccessControl.sol";
import "./FleekBilling.sol";
import "./FleekPausable.sol";
import "./FleekAccessPoints.sol";
import "./util/FleekENS.sol";
import "./util/FleekStrings.sol";
import "./IERCX.sol";
import "./util/NonBlockingLzApp.sol";

error MustBeTokenOwner(uint256 tokenId);
error MustBeTokenVerifier(uint256 tokenId);
error ThereIsNoTokenMinted();
error TransferIsDisabled();

contract FleekERC721 is
    NonblockingLzApp,
    IERCX,
    Initializable,
    ERC721Upgradeable,
    FleekAccessControl,
    FleekPausable,
    FleekBilling,
    FleekAccessPoints
{
    using Strings for uint256;
    using FleekStrings for FleekERC721.Token;
    using FleekStrings for string;
    using FleekStrings for uint24;

    event NewMint(
        uint256 indexed tokenId,
        string name,
        string description,
        string externalURL,
        string ENS,
        string commitHash,
        string gitRepository,
        string ipfsHash,
        string logo,
        uint24 color,
        bool accessPointAutoApproval,
        address indexed minter,
        address indexed owner,
        address verifier
    );

    event MetadataUpdate(uint256 indexed _tokenId, string key, address value, address indexed triggeredBy);

    uint256 private _appIds;
    mapping(uint256 => Token) private _apps;
    mapping(uint256 => address) private _tokenVerifier;
    mapping(uint256 => bool) private _tokenVerified;

    uint16 destChainId;

    /**
     * @dev This constructor sets the state of implementation contract to paused
     * and disable initializers, not allowing interactions with the implementation
     * contracts.
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _setPausable(true);
        _pause();
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256[] memory initialBillings,
        address _lzEndpoint
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __FleekAccessControl_init();
        __FleekBilling_init(initialBillings);
        __FleekPausable_init();
        NonblockingLzApp.initializeNonblockingLzApp(_lzEndpoint);
        destChainId = 10109; // destination chain is mumbai
    }

    /**
     * @dev Checks if caller is the verifier of the token.
     */
    modifier requireTokenVerifier(uint256 tokenId) {
        if (_tokenVerifier[tokenId] != msg.sender) revert MustBeTokenVerifier(tokenId);
        _;
    }

    /**
     * @dev Mints a token and returns a tokenId.
     *
     * If the `tokenId` has not been minted before, and the `to` address is not zero, emits a {Transfer} event.
     *
     * Requirements:
     *
     * - the caller must have ``collectionOwner``'s admin role.
     * - billing for the minting may be applied.
     * - the contract must be not paused.
     *
     */
    function mint(
        address to,
        string memory name,
        string memory description,
        string memory externalURL,
        string calldata ens,
        string memory commitHash,
        string memory gitRepository,
        string memory ipfsHash,
        string memory logo,
        uint24 color,
        bool accessPointAutoApproval,
        address verifier
    ) public payable requirePayment(Billing.Mint) returns (uint256) {
        if (!hasCollectionRole(CollectionRoles.Verifier, verifier))
            revert MustHaveCollectionRole(uint8(CollectionRoles.Verifier));
        if (bytes(ens).length > 0) FleekENS.requireENSOwner(ens);
        uint256 tokenId = _appIds;
        _mint(to, tokenId);

        _appIds += 1;

        Token storage app = _apps[tokenId];
        app.name = name;
        app.description = description;
        app.externalURL = externalURL;
        app.ENS = ens;
        app.logo = logo;
        app.color = color;

        // The mint interaction is considered to be the first build of the site. Updates from now on all increment the currentBuild by one and update the mapping.
        app.currentBuild = 0;
        app.builds[0] = Build(commitHash, gitRepository, ipfsHash, externalURL);

        emit NewMint(
            tokenId,
            name,
            description,
            externalURL,
            ens,
            commitHash,
            gitRepository,
            ipfsHash,
            logo,
            color,
            accessPointAutoApproval,
            msg.sender,
            to,
            verifier
        );

        _tokenVerifier[tokenId] = verifier;
        _tokenVerified[tokenId] = false;
        _setAccessPointAutoApproval(tokenId, accessPointAutoApproval);

        return tokenId;
    }

    /**
     * @dev Returns the token metadata associated with the `tokenId`.
     *
     * Returns a based64 encoded string value of the URI.
     *
     * Requirements:
     *
     * - the tokenId must be minted and valid.
     *
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721Upgradeable, IERCX) returns (string memory) {
        _requireMinted(tokenId);
        address owner = ownerOf(tokenId);
        bool accessPointAutoApproval = _getAccessPointAutoApproval(tokenId);
        bool verified = _tokenVerified[tokenId];
        Token storage app = _apps[tokenId];

        return string(abi.encodePacked(_baseURI(), app.toString(owner, accessPointAutoApproval, verified).toBase64()));
    }

    /**
     * @dev Returns the token metadata associated with the `tokenId`.
     *
     * Returns multiple string and uint values in relation to metadata fields of the App struct.
     *
     * Requirements:
     *
     * - the tokenId must be minted and valid.
     *
     */
    function getToken(
        uint256 tokenId
    )
        public
        view
        virtual
        returns (string memory, string memory, string memory, string memory, uint256, string memory, uint24)
    {
        _requireMinted(tokenId);
        Token storage app = _apps[tokenId];
        return (app.name, app.description, app.externalURL, app.ENS, app.currentBuild, app.logo, app.color);
    }

    function getAppData(
        uint256 tokenId
    ) public view returns (string memory, string memory, string memory, string memory, string memory) {
        _requireMinted(tokenId);
        Token storage app = _apps[tokenId];

        return (app.name, app.ENS, app.logo, app.color.toColorString(), app.builds[app.currentBuild].ipfsHash);
    }

    function _nonblockingLzReceive(uint16, bytes memory, uint64, bytes memory _payload) internal override {
        // Receives a tokenId from an app collection and sends metadata to the same collection
        uint256 tokenId = abi.decode(_payload, (uint256));
        _requireMinted(tokenId);
        Token storage app = _apps[tokenId];

        bytes memory payload = abi.encode(
            app.name,
            app.ENS,
            app.logo,
            app.color.toColorString(),
            app.builds[app.currentBuild].ipfsHash
        );
        _lzSend(destChainId, payload, payable(msg.sender), address(0x0), bytes(""), msg.value);
    }

    function trustAddress(address _appContract) public requireCollectionRole(CollectionRoles.Owner) {
        trustedRemoteLookup[destChainId] = abi.encodePacked(_appContract, address(this));
    }

    /**
     * @dev Returns the last minted tokenId.
     */
    function getLastTokenId() public view virtual returns (uint256) {
        uint256 current = _appIds;
        if (current == 0) revert ThereIsNoTokenMinted();
        return current - 1;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Override of _beforeTokenTransfer of ERC721.
     * Here it needs to update the token controller roles for mint, burn and transfer.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override whenNotPaused {
        if (from != address(0) && to != address(0)) {
            // Transfer
            _clearTokenRoles(tokenId);
        } else if (from == address(0)) {
            // Mint
            // TODO: set contract owner as controller
        } else if (to == address(0)) {
            // Burn
            _clearTokenRoles(tokenId);
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev Override of transfer of ERC721.
     * Transfer is disabled for NFA tokens.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual override whenNotPaused {
        revert TransferIsDisabled();
    }

    /**
     * @dev A baseURI internal function implementation to be called in the `tokenURI` function.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return "data:application/json;base64,";
    }

    /**
     * @dev Updates the `externalURL` metadata field of a minted `tokenId`.
     *
     * May emit a {NewTokenExternalURL} event.
     *
     * Requirements:
     *
     * - the tokenId must be minted and valid.
     * - the sender must have the `tokenController` role.
     *
     */
    function setTokenExternalURL(
        uint256 tokenId,
        string memory _tokenExternalURL
    ) public virtual requireTokenRole(tokenId, TokenRoles.Controller) {
        _requireMinted(tokenId);
        _apps[tokenId].externalURL = _tokenExternalURL;
        emit MetadataUpdate(tokenId, "externalURL", _tokenExternalURL, msg.sender);
    }

    /**
     * @dev Updates the `ENS` metadata field of a minted `tokenId`.
     *
     * May emit a {NewTokenENS} event.
     *
     * Requirements:
     *
     * - the tokenId must be minted and valid.
     * - the sender must have the `tokenController` role.
     *
     */
    function setTokenENS(
        uint256 tokenId,
        string calldata _tokenENS
    ) public virtual requireTokenRole(tokenId, TokenRoles.Controller) {
        FleekENS.requireENSOwner(_tokenENS);
        _requireMinted(tokenId);
        _apps[tokenId].ENS = _tokenENS;
        emit MetadataUpdate(tokenId, "ENS", _tokenENS, msg.sender);
    }

    /**
     * @dev Updates the `name` metadata field of a minted `tokenId`.
     *
     * May emit a {NewTokenName} event.
     *
     * Requirements:
     *
     * - the tokenId must be minted and valid.
     * - the sender must have the `tokenController` role.
     *
     */
    function setTokenName(
        uint256 tokenId,
        string memory _tokenName
    ) public virtual requireTokenRole(tokenId, TokenRoles.Controller) {
        _requireMinted(tokenId);
        _apps[tokenId].name = _tokenName;
        emit MetadataUpdate(tokenId, "name", _tokenName, msg.sender);
    }

    /**
     * @dev Updates the `description` metadata field of a minted `tokenId`.
     *
     * May emit a {NewTokenDescription} event.
     *
     * Requirements:
     *
     * - the tokenId must be minted and valid.
     * - the sender must have the `tokenController` role.
     *
     */
    function setTokenDescription(
        uint256 tokenId,
        string memory _tokenDescription
    ) public virtual requireTokenRole(tokenId, TokenRoles.Controller) {
        _requireMinted(tokenId);
        _apps[tokenId].description = _tokenDescription;
        emit MetadataUpdate(tokenId, "description", _tokenDescription, msg.sender);
    }

    /**
     * @dev Updates the `logo` metadata field of a minted `tokenId`.
     *
     * May emit a {NewTokenLogo} event.
     *
     * Requirements:
     *
     * - the tokenId must be minted and valid.
     * - the sender must have the `tokenController` role.
     *
     */
    function setTokenLogo(
        uint256 tokenId,
        string memory _tokenLogo
    ) public virtual requireTokenRole(tokenId, TokenRoles.Controller) {
        _requireMinted(tokenId);
        _apps[tokenId].logo = _tokenLogo;
        emit MetadataUpdate(tokenId, "logo", _tokenLogo, msg.sender);
    }

    /**
     * @dev Updates the `color` metadata field of a minted `tokenId`.
     *
     * May emit a {NewTokenColor} event.
     *
     * Requirements:
     *
     * - the tokenId must be minted and valid.
     * - the sender must have the `tokenController` role.
     *
     */
    function setTokenColor(
        uint256 tokenId,
        uint24 _tokenColor
    ) public virtual requireTokenRole(tokenId, TokenRoles.Controller) {
        _requireMinted(tokenId);
        _apps[tokenId].color = _tokenColor;
        emit MetadataUpdate(tokenId, "color", _tokenColor, msg.sender);
    }

    /**
     * @dev Updates the `logo` and `color` metadata fields of a minted `tokenId`.
     *
     * May emit a {NewTokenLogo} and a {NewTokenColor} event.
     *
     * Requirements:
     *
     * - the tokenId must be minted and valid.
     * - the sender must have the `tokenController` role.
     *
     */
    function setTokenLogoAndColor(uint256 tokenId, string memory _tokenLogo, uint24 _tokenColor) public virtual {
        setTokenLogo(tokenId, _tokenLogo);
        setTokenColor(tokenId, _tokenColor);
    }

    /**
     * @dev Adds a new build to a minted `tokenId`'s builds mapping.
     *
     * May emit a {NewBuild} event.
     *
     * Requirements:
     *
     * - the tokenId must be minted and valid.
     * - the sender must have the `tokenController` role.
     *
     */
    function setTokenBuild(
        uint256 tokenId,
        string memory _commitHash,
        string memory _gitRepository,
        string memory _ipfsHash,
        string memory _domain
    ) public virtual requireTokenRole(tokenId, TokenRoles.Controller) {
        _requireMinted(tokenId);
        _apps[tokenId].builds[++_apps[tokenId].currentBuild] = Build(_commitHash, _gitRepository, _ipfsHash, _domain);
        // Note from Nima: should we update the externalURL field with each new domain?
        emit MetadataUpdate(tokenId, "build", [_commitHash, _gitRepository, _ipfsHash, _domain], msg.sender);
    }

    /**
     * @dev Burns a previously minted `tokenId`.
     *
     * May emit a {Transfer} event.
     *
     * Requirements:
     *
     * - the tokenId must be minted and valid.
     * - the sender must be the owner of the token.
     * - the contract must be not paused.
     *
     */
    function burn(uint256 tokenId) public virtual requireTokenOwner(tokenId) {
        super._burn(tokenId);

        if (bytes(_apps[tokenId].externalURL).length != 0) {
            delete _apps[tokenId];
        }
    }

    /**
     * @dev Sets an address as verifier of a token.
     * The verifier must have `CollectionRoles.Verifier` role.
     *
     * May emit a {MetadataUpdate} event.
     *
     * Requirements:
     *
     * - the tokenId must be minted and valid.
     * - the sender must be the owner of the token.
     * - the verifier must have `CollectionRoles.Verifier` role.
     *
     */
    function setTokenVerifier(uint256 tokenId, address verifier) public requireTokenOwner(tokenId) {
        if (!hasCollectionRole(CollectionRoles.Verifier, verifier))
            revert MustHaveCollectionRole(uint8(CollectionRoles.Verifier));
        _requireMinted(tokenId);
        _tokenVerifier[tokenId] = verifier;
        emit MetadataUpdate(tokenId, "verifier", verifier, msg.sender);
    }

    /**
     * @dev Returns the verifier of a token.
     *
     * Requirements:
     *
     * - the tokenId must be minted and valid.
     *
     */
    function getTokenVerifier(uint256 tokenId) public view returns (address) {
        _requireMinted(tokenId);
        return _tokenVerifier[tokenId];
    }

    /**
     * @dev Sets the verification status of a token.
     *
     * May emit a {MetadataUpdate} event.
     *
     * Requirements:
     *
     * - the tokenId must be minted and valid.
     * - the sender must be the token verifier.
     * - the sender must have `CollectionRoles.Verifier` role.
     *
     */
    function setTokenVerified(
        uint256 tokenId,
        bool verified
    ) public requireCollectionRole(CollectionRoles.Verifier) requireTokenVerifier(tokenId) {
        _requireMinted(tokenId);
        _tokenVerified[tokenId] = verified;
        emit MetadataUpdate(tokenId, "verified", verified, msg.sender);
    }

    /**
     * @dev Returns the verification status of a token.
     *
     * Requirements:
     *
     * - the tokenId must be minted and valid.
     *
     */
    function isTokenVerified(uint256 tokenId) public view returns (bool) {
        _requireMinted(tokenId);
        return _tokenVerified[tokenId];
    }

    /*//////////////////////////////////////////////////////////////
        ACCESS POINTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Add a new AccessPoint register for an app token.
     * The AP name should be a DNS or ENS url and it should be unique.
     * Anyone can add an AP but it should requires a payment.
     *
     * May emit a {NewAccessPoint} event.
     *
     * Requirements:
     *
     * - the tokenId must be minted and valid.
     * - billing for add acess point may be applied.
     * - the contract must be not paused.
     *
     */
    function addAccessPoint(
        uint256 tokenId,
        string memory apName
    ) public payable whenNotPaused requirePayment(Billing.AddAccessPoint) {
        _requireMinted(tokenId);
        _addAccessPoint(tokenId, apName);
    }

    /**
     * @dev Remove an AccessPoint registry for an app token.
     * It will also remove the AP from the app token APs list.
     *
     * May emit a {RemoveAccessPoint} event.
     *
     * Requirements:
     *
     * - the AP must exist.
     * - must be called by the AP owner.
     * - the contract must be not paused.
     *
     */
    function removeAccessPoint(string memory apName) public whenNotPaused {
        _removeAccessPoint(apName);
    }

    /**
     * @dev Updates the `accessPointAutoApproval` settings on minted `tokenId`.
     *
     * May emit a {MetadataUpdate} event.
     *
     * Requirements:
     *
     * - the tokenId must be minted and valid.
     * - the sender must have the `tokenController` role.
     *
     */
    function setAccessPointAutoApproval(uint256 tokenId, bool _apAutoApproval) public requireTokenOwner(tokenId) {
        _requireMinted(tokenId);
        _setAccessPointAutoApproval(tokenId, _apAutoApproval);
        emit MetadataUpdate(tokenId, "accessPointAutoApproval", _apAutoApproval, msg.sender);
    }

    /**
     * @dev Set approval settings for an access point.
     * It will add the access point to the token's AP list, if `approved` is true.
     *
     * May emit a {ChangeAccessPointApprovalStatus} event.
     *
     * Requirements:
     *
     * - the tokenId must exist and be the same as the tokenId that is set for the AP.
     * - the AP must exist.
     * - must be called by a token controller.
     */
    function setApprovalForAccessPoint(
        uint256 tokenId,
        string memory apName,
        bool approved
    ) public requireTokenOwner(tokenId) {
        _setApprovalForAccessPoint(tokenId, apName, approved);
    }

    /**
     * @dev Set the content verification of a AccessPoint registry.
     *
     * May emit a {ChangeAccessPointContentVerify} event.
     *
     * Requirements:
     *
     * - the AP must exist.
     * - the sender must have the token controller role.
     *
     */
    function setAccessPointContentVerify(
        string memory apName,
        bool verified
    ) public requireCollectionRole(CollectionRoles.Verifier) requireTokenVerifier(_getAccessPointTokenId(apName)) {
        _setAccessPointContentVerify(apName, verified);
    }

    /**
     * @dev Set the name verification of a AccessPoint registry.
     *
     * May emit a {ChangeAccessPointNameVerify} event.
     *
     * Requirements:
     *
     * - the AP must exist.
     * - the sender must have the token controller role.
     *
     */
    function setAccessPointNameVerify(
        string memory apName,
        bool verified
    ) public requireCollectionRole(CollectionRoles.Verifier) requireTokenVerifier(_getAccessPointTokenId(apName)) {
        _setAccessPointNameVerify(apName, verified);
    }

    /*//////////////////////////////////////////////////////////////
        ACCESS CONTROL
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Requires caller to have a selected collection role.
     */
    modifier requireCollectionRole(CollectionRoles role) {
        _requireCollectionRole(role);
        _;
    }

    /**
     * @dev Requires caller to have a selected token role.
     */
    modifier requireTokenRole(uint256 tokenId, TokenRoles role) {
        if (ownerOf(tokenId) != msg.sender) _requireTokenRole(tokenId, role);
        _;
    }

    /**
     * @dev Requires caller to be selected token owner.
     */
    modifier requireTokenOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) revert MustBeTokenOwner(tokenId);
        _;
    }

    /**
     * @dev Grants the collection role to an address.
     *
     * Requirements:
     *
     * - the caller should have the collection role.
     *
     */
    function grantCollectionRole(
        CollectionRoles role,
        address account
    ) public whenNotPaused requireCollectionRole(CollectionRoles.Owner) {
        _grantCollectionRole(role, account);
    }

    /**
     * @dev Grants the token role to an address.
     *
     * Requirements:
     *
     * - the caller should have the token role.
     *
     */
    function grantTokenRole(
        uint256 tokenId,
        TokenRoles role,
        address account
    ) public whenNotPaused requireTokenOwner(tokenId) {
        _grantTokenRole(tokenId, role, account);
    }

    /**
     * @dev Revokes the collection role of an address.
     *
     * Requirements:
     *
     * - the caller should have the collection role.
     *
     */
    function revokeCollectionRole(
        CollectionRoles role,
        address account
    ) public whenNotPaused requireCollectionRole(CollectionRoles.Owner) {
        _revokeCollectionRole(role, account);
    }

    /**
     * @dev Revokes the token role of an address.
     *
     * Requirements:
     *
     * - the caller should have the token role.
     *
     */
    function revokeTokenRole(
        uint256 tokenId,
        TokenRoles role,
        address account
    ) public whenNotPaused requireTokenOwner(tokenId) {
        _revokeTokenRole(tokenId, role, account);
    }

    /*//////////////////////////////////////////////////////////////
        PAUSABLE
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Sets the contract to paused state.
     *
     * Requirements:
     *
     * - the sender must have the `controller` role.
     * - the contract must be pausable.
     * - the contract must be not paused.
     *
     */
    function pause() public requireCollectionRole(CollectionRoles.Owner) {
        _pause();
    }

    /**
     * @dev Sets the contract to unpaused state.
     *
     * Requirements:
     *
     * - the sender must have the `controller` role.
     * - the contract must be paused.
     *
     */
    function unpause() public requireCollectionRole(CollectionRoles.Owner) {
        _unpause();
    }

    /**
     * @dev Sets the contract to pausable state.
     *
     * Requirements:
     *
     * - the sender must have the `owner` role.
     * - the contract must be in the oposite pausable state.
     *
     */
    function setPausable(bool pausable) public requireCollectionRole(CollectionRoles.Owner) {
        _setPausable(pausable);
    }

    /*//////////////////////////////////////////////////////////////
        BILLING
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Modifier to require billing with a given key.
     */
    modifier requirePayment(Billing key) {
        _requirePayment(key);
        _;
    }

    /**
     * @dev Sets the billing value for a given key.
     *
     * May emit a {BillingChanged} event.
     *
     * Requirements:
     *
     * - the sender must have the `collectionOwner` role.
     *
     */
    function setBilling(Billing key, uint256 value) public requireCollectionRole(CollectionRoles.Owner) {
        _setBilling(key, value);
    }

    /**
     * @dev Withdraws all the funds from contract.
     *
     * May emmit a {Withdrawn} event.
     *
     * Requirements:
     *
     * - the sender must have the `collectionOwner` role.
     *
     */
    function withdraw() public requireCollectionRole(CollectionRoles.Owner) {
        _withdraw();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

error ContractIsPaused();
error ContractIsNotPaused();
error ContractIsNotPausable();
error PausableIsSetTo(bool state);

abstract contract FleekPausable is Initializable {
    /**
     * @dev Emitted when the pause is triggered by `account` and set to `isPaused`.
     */
    event PauseStatusChange(bool indexed isPaused, address account);

    /**
     * @dev Emitted when the pausable is triggered by `account` and set to `isPausable`.
     */
    event PausableStatusChange(bool indexed isPausable, address account);

    bool private _paused;
    bool private _canPause; // TODO: how should we verify if the contract is pausable or not?

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __FleekPausable_init() internal onlyInitializing {
        _paused = false;
        _canPause = true;
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
    function isPaused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Returns true if the contract is pausable, and false otherwise.
     */
    function isPausable() public view returns (bool) {
        return _canPause;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view {
        if (isPaused()) revert ContractIsPaused();
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view {
        if (!isPaused()) revert ContractIsNotPaused();
    }

    /**
     * @dev Throws if the contract is not pausable.
     */
    function _requirePausable() internal view {
        if (!isPausable()) revert ContractIsNotPausable();
    }

    /**
     * @dev Sets the contract to be pausable or not.
     * @param canPause true if the contract is pausable, and false otherwise.
     */
    function _setPausable(bool canPause) internal {
        if (canPause == _canPause) revert PausableIsSetTo(canPause);
        _canPause = canPause;
        emit PausableStatusChange(canPause, msg.sender);
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal whenNotPaused {
        _requirePausable();
        _paused = true;
        emit PauseStatusChange(false, msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal whenPaused {
        _paused = false;
        emit PauseStatusChange(false, msg.sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title ERCX Interface
 * @author
 * @notice
 *
 * ERCX is a standard for NFTs that represent websites. It is a standard that
 * allows for the storage of metadata about a website, and allows for the
 * storage of multiple builds of a website. This allows for the NFT to be
 * used as a way to store the history of a website.
 */
interface IERCX {
    /**
     * Event emitted when a token's metadata is updated.
     * @param _tokenId the updated token id.
     * @param key which metadata key was updated
     * @param value the new value of the metadata
     * @param triggeredBy the address that triggered the update
     */
    event MetadataUpdate(uint256 indexed _tokenId, string key, string value, address indexed triggeredBy);
    event MetadataUpdate(uint256 indexed _tokenId, string key, uint24 value, address indexed triggeredBy);
    event MetadataUpdate(uint256 indexed _tokenId, string key, string[4] value, address indexed triggeredBy);
    event MetadataUpdate(uint256 indexed _tokenId, string key, bool value, address indexed triggeredBy);

    /**
     * The metadata that is stored for each build.
     */
    struct Build {
        string commitHash;
        string gitRepository;
        string ipfsHash;
        string domain;
    }

    /**
     * The properties are stored as string to keep consistency with
     * other token contracts, we might consider changing for bytes32
     * in the future due to gas optimization.
     */
    struct Token {
        string name; // Name of the site
        string description; // Description about the site
        string externalURL; // Site URL
        string ENS; // ENS for the site
        string logo; // Branding logo
        uint24 color; // Branding color
        uint256 currentBuild; // The current build number (Increments by one with each change, starts at zero)
        mapping(uint256 => Build) builds; // Mapping to build details for each build number
    }

    /**
     * @dev Sets a minted token's external URL.
     */
    function setTokenExternalURL(uint256 tokenId, string memory _tokenExternalURL) external;

    /**
     * @dev Sets a minted token's ENS.
     */
    function setTokenENS(uint256 tokenId, string memory _tokenENS) external;

    /**
     * @dev Sets a minted token's name.
     */
    function setTokenName(uint256 tokenId, string memory _tokenName) external;

    /**
     * @dev Sets a minted token's description.
     */
    function setTokenDescription(uint256 tokenId, string memory _tokenDescription) external;

    /**
     * @dev Sets a minted token's logo.
     */
    function setTokenLogo(uint256 tokenId, string memory _tokenLogo) external;

    /**
     * @dev Sets a minted token's color.
     */
    function setTokenColor(uint256 tokenId, uint24 _tokenColor) external;

    /**
     * @dev Sets a minted token's build.
     */
    function setTokenBuild(
        uint256 tokenId,
        string memory commitHash,
        string memory gitRepository,
        string memory ipfsHash,
        string memory domain
    ) external;

    /**
     * @dev Returns the token metadata for a given tokenId.
     * It must return a valid JSON object in string format encoded in Base64.
     */
    function tokenURI(uint256 tokenId) external returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
    public
    pure
    returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
            tempBytes := mload(0x40)

        // Store the length of the first bytes array at the beginning of
        // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

        // Maintain a memory counter for the current write location in the
        // temp bytes array by adding the 32 bytes for the array length to
        // the starting location.
            let mc := add(tempBytes, 0x20)
        // Stop copying when the memory counter reaches the length of the
        // first bytes array.
            let end := add(mc, length)

            for {
            // Initialize a copy counter to the start of the _preBytes data,
            // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
            // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
            // Write the _preBytes data into the tempBytes memory 32 bytes
            // at a time.
                mstore(mc, mload(cc))
            }

        // Add the length of _postBytes to the current length of tempBytes
        // and store it as the new length in the first 32 bytes of the
        // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

        // Move the memory counter back from a multiple of 0x20 to the
        // actual end of the _preBytes data.
            mc := end
        // Stop copying when the memory counter reaches the new combined
        // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

        // Update the free-memory pointer by padding our last write location
        // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
        // next 32 byte block, then round down to the nearest multiple of
        // 32. If the sum of the length of the two arrays is zero then add
        // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
            add(add(end, iszero(add(length, mload(_preBytes)))), 31),
            not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) public {
        assembly {
        // Read the first 32 bytes of _preBytes storage, which is the length
        // of the array. (We don't need to use the offset into the slot
        // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
        // Arrays of 31 bytes or less have an even value in their slot,
        // while longer arrays have an odd value. The actual length is
        // the slot divided by two for odd values, and the lowest order
        // byte divided by two for even values.
        // If the slot is even, bitwise and the slot with 255 and divide by
        // two to get the length. If the slot is odd, bitwise and the slot
        // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
        // slength can contain both the length and contents of the array
        // if length < 32 bytes so let's prepare for that
        // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
            // Since the new array still fits in the slot, we just need to
            // update the contents of the slot.
            // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                _preBytes.slot,
                // all the modifications to the slot are inside this
                // next block
                add(
                // we can just add to the slot contents because the
                // bytes we want to change are the LSBs
                fslot,
                add(
                mul(
                div(
                // load the bytes from memory
                mload(add(_postBytes, 0x20)),
                // zero all bytes to the right
                exp(0x100, sub(32, mlength))
                ),
                // and now shift left the number of bytes to
                // leave space for the length in the slot
                exp(0x100, sub(32, newlength))
                ),
                // increase length by the double of the memory
                // bytes length
                mul(mlength, 2)
                )
                )
                )
            }
            case 1 {
            // The stored value fits in the slot, but the combined value
            // will exceed it.
            // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

            // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

            // The contents of the _postBytes array start 32 bytes into
            // the structure. Our first read should obtain the `submod`
            // bytes that can fit into the unused space in the last word
            // of the stored array. To get this, we read 32 bytes starting
            // from `submod`, so the data we read overlaps with the array
            // contents by `submod` bytes. Masking the lowest-order
            // `submod` bytes allows us to add that value directly to the
            // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                sc,
                add(
                and(
                fslot,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                ),
                and(mload(mc), mask)
                )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
            // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
            // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

            // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

            // Copy over the first `submod` bytes of the new data as in
            // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
    public
    pure
    returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
                tempBytes := mload(0x40)

            // The first word of the slice result is potentially a partial
            // word read from the original array. To read it, we calculate
            // the length of that partial word and start copying that many
            // bytes into the array. The first word we copy will start with
            // data we don't care about, but the last `lengthmod` bytes will
            // land at the beginning of the contents of the new array. When
            // we're done copying, we overwrite the full first word with
            // the actual length of the slice.
                let lengthmod := and(_length, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
            //zero out the 32 bytes slice we are about to return
            //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) public pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) public pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) public pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) public pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) public pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) public pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) public pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) public pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) public pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) public pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

        // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
            // cb is a circuit breaker in the for loop since there's
            //  no said feature for inline assembly loops
            // cb = 1 - don't breaker
            // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                    // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
            // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
    public
    view
    returns (bool)
    {
        bool success = true;

        assembly {
        // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
        // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

        // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                    // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                        // unsuccess:
                            success := 0
                        }
                    }
                    default {
                    // cb is a circuit breaker in the for loop since there's
                    //  no said feature for inline assembly loops
                    // cb = 1 - don't breaker
                    // cb = 0 - break
                        let cb := 1

                    // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                            // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
            // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK =
    0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) public returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
            _gas, // gas
            _target, // recipient
            0, // ether value
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) public view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
            _gas, // gas
            _target, // recipient
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf)
    public
    pure
    {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
        // load the first word of
            let _word := mload(add(_buf, 0x20))
        // mask out the top 4 bytes
        // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ENS} from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import {Resolver} from "@ensdomains/ens-contracts/contracts/resolvers/Resolver.sol";

error MustBeENSOwner();

library FleekENS {
    ENS internal constant _ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    /**
     * @dev Reverts if the sender is not the owner of the ENS node.
     */
    function requireENSOwner(string calldata name) internal view {
        if (_ens.owner(namehash(bytes(name), 0)) != msg.sender) revert MustBeENSOwner();
    }

    /**
     * @dev Processes the name and returns the ENS node hash.
     */
    function namehash(bytes calldata name, uint256 index) internal view returns (bytes32) {
        for (uint256 i = index; i < name.length; i++) {
            if (name[i] == ".") {
                return keccak256(abi.encodePacked(namehash(name, i + 1), keccak256(name[index:i])));
            }
        }
        return keccak256(abi.encodePacked(bytes32(0x0), keccak256(name[index:name.length])));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./FleekSVG.sol";
import "../IERCX.sol";
import "../FleekAccessPoints.sol";

library FleekStrings {
    using Strings for uint256;
    using Strings for uint160;
    using FleekStrings for bool;
    using FleekStrings for uint24;
    using Strings for uint24;

    /**
     * @dev Converts a boolean value to a string.
     */
    function toString(bool _bool) internal pure returns (string memory) {
        return _bool ? "true" : "false";
    }

    /**
     * @dev Converts a string to a base64 string.
     */
    function toBase64(string memory str) internal pure returns (string memory) {
        return Base64.encode(bytes(str));
    }

    /**
     * @dev Converts IERCX.Token to a JSON string.
     * It requires to receive owner address as a parameter.
     */
    function toString(
        IERCX.Token storage app,
        address owner,
        bool accessPointAutoApproval,
        bool verified
    ) internal view returns (string memory) {
        // prettier-ignore
        return string(abi.encodePacked(
            '{',
                '"name":"', app.name, '",',
                '"description":"', app.description, '",',
                '"owner":"', uint160(owner).toHexString(20), '",',
                '"external_url":"', app.externalURL, '",',
                '"image":"', FleekSVG.generateBase64(app.name, app.ENS, app.logo, app.color.toColorString()), '",',
                '"access_point_auto_approval":', accessPointAutoApproval.toString(),',',
                '"verified":',verified.toString(),',',
                '"attributes": [',
                    '{"trait_type": "ENS", "value":"', app.ENS,'"},',
                    '{"trait_type": "Commit Hash", "value":"', app.builds[app.currentBuild].commitHash,'"},',
                    '{"trait_type": "Repository", "value":"', app.builds[app.currentBuild].gitRepository,'"},',
                    '{"trait_type": "Version", "value":"', app.currentBuild.toString(),'"},',
                    '{"trait_type": "Color", "value":"', app.color.toColorString(),'"}',
                ']',
            '}'
        ));
    }

    /**
     * @dev Converts FleekAccessPoints.AccessPoint to a JSON string.
     */
    function toString(FleekAccessPoints.AccessPoint storage ap) internal view returns (string memory) {
        // prettier-ignore
        return string(abi.encodePacked(
            "{",
                '"tokenId":', ap.tokenId.toString(), ",",
                '"score":', ap.score.toString(), ",",
                '"nameVerified":', ap.nameVerified.toString(), ",",
                '"contentVerified":', ap.contentVerified.toString(), ",",
                '"owner":"', uint160(ap.owner).toHexString(20), '",',
                '"status":',uint(ap.status).toString(),
            "}"
        ));
    }

    /**
     * @dev Converts bytes3 to a hex color string.
     */
    function toColorString(uint24 color) internal pure returns (string memory) {
        bytes memory hexBytes = bytes(color.toHexString(3));
        bytes memory hexColor = new bytes(7);
        hexColor[0] = "#";
        for (uint256 i = 1; i < 7; i++) {
            hexColor[i] = hexBytes[i + 1];
        }
        return string(hexColor);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

library FleekSVG {
    /**
     * @dev Generates a SVG image.
     */
    function generateBase64(
        string memory name,
        string memory ENS,
        string memory logo,
        string memory color
    ) public pure returns (string memory) {
        return (
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '<svg width="1065" height="1065" viewBox="0 0 1065 1065" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                            // background
                            '<style type="text/css">@import url("https://fonts.googleapis.com/css2?family=Inter:[email protected];600");</style>',
                            '<rect width="1065" height="1065" fill="url(#background)" /><rect opacity="0.2" width="1065" height="1065" fill="url(#background-radial)" />',
                            // shadows
                            '<g filter="url(#diskette-shadow)"><path d="M857.231 279.712L902.24 286.675C910.547 287.96 917.915 292.721 922.5 299.768L938.894 324.964C942.249 330.12 943.311 336.437 941.827 342.406L937.798 358.615L924.049 356.65L919.416 374.084L934.068 376.24L791.947 922.152C788.109 936.896 773.694 946.308 758.651 943.893L179.636 850.928C162.318 848.147 151.215 830.987 155.776 814.051L160.478 796.59L704.315 879.574L857.231 279.712Z" fill="#050505" /></g>',
                            '<path d="M840.231 240.712L885.24 247.675C893.547 248.961 900.915 253.722 905.5 260.768L921.894 285.965C925.249 291.12 926.311 297.437 924.827 303.406L920.798 319.616L907.049 317.65L902.416 335.084L917.068 337.241L774.947 883.152C771.109 897.896 756.694 907.308 741.651 904.893L162.636 811.928C145.318 809.147 134.215 791.987 138.776 775.051L143.478 757.59L687.315 840.574L840.231 240.712Z" fill="url(#main)" />',
                            // diskette fill
                            '<path fill-rule="evenodd" clip-rule="evenodd" d="M319.847 161.502C310.356 160.007 300.674 166.326 298.221 175.616L138.724 779.758C136.271 789.048 141.977 797.79 151.468 799.285L740.061 891.973C749.553 893.467 759.235 887.148 761.687 877.858L902.405 344.854L889.158 342.768L898.872 305.972L912.119 308.059L913.733 301.946C914.837 297.762 914.309 293.476 912.251 289.927L893.484 257.569C891.153 253.549 887.063 250.823 882.221 250.061L828.205 241.554C822.224 240.613 815.869 242.783 811.427 247.284L805.686 253.103C804.205 254.603 802.087 255.326 800.093 255.013L783.611 252.417L734.3 439.196C731.439 450.035 720.143 457.407 709.07 455.663L328.847 395.788C317.774 394.045 311.117 383.845 313.978 373.007L366.528 173.962L366.533 173.941C367.234 171.24 365.572 168.702 362.81 168.267L319.847 161.502ZM369.392 174.414L368.652 177.217L316.843 373.458C314.39 382.748 320.096 391.49 329.587 392.985L709.81 452.86C719.301 454.354 728.983 448.035 731.436 438.745L780.747 251.966L783.245 242.504L783.985 239.701L369.392 174.414Z" fill="#131316" />',
                            '<path fill-rule="evenodd" clip-rule="evenodd" stroke="url(#main)" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" d="M319.847 161.502C310.356 160.007 300.674 166.326 298.221 175.616L138.724 779.758C136.271 789.048 141.977 797.79 151.468 799.285L740.061 891.973C749.553 893.467 759.235 887.148 761.687 877.858L902.405 344.854L889.158 342.768L898.872 305.972L912.119 308.059L913.733 301.946C914.837 297.762 914.309 293.476 912.251 289.927L893.484 257.569C891.153 253.549 887.063 250.823 882.221 250.061L828.205 241.554C822.224 240.613 815.869 242.783 811.427 247.284L805.686 253.103C804.205 254.603 802.087 255.326 800.093 255.013L783.611 252.417L734.3 439.196C731.439 450.035 720.143 457.407 709.07 455.663L328.847 395.788C317.774 394.045 311.117 383.845 313.978 373.007L366.528 173.962L366.533 173.941C367.234 171.24 365.572 168.702 362.81 168.267L319.847 161.502ZM369.392 174.414L368.652 177.217L316.843 373.458C314.39 382.748 320.096 391.49 329.587 392.985L709.81 452.86C719.301 454.354 728.983 448.035 731.436 438.745L780.747 251.966L783.245 242.504L783.985 239.701L369.392 174.414Z" fill="url(#diskette-gradient)" fill-opacity="0.2" />',
                            // arrows
                            '<path d="M335.38 208.113C335.922 208.198 336.417 207.686 336.283 207.179L330.39 184.795C330.249 184.261 329.529 184.148 329.129 184.597L312.358 203.411C311.978 203.838 312.174 204.458 312.716 204.544L317.962 205.37C318.357 205.432 318.595 205.796 318.493 206.183L314.7 220.551C314.597 220.938 314.835 221.302 315.231 221.364L324.539 222.83C324.935 222.893 325.338 222.629 325.44 222.242L329.233 207.875C329.336 207.488 329.739 207.224 330.135 207.286L335.38 208.113Z" fill="url(#main)" />',
                            '<path d="M319.282 269.087C319.824 269.173 320.319 268.661 320.186 268.154L314.292 245.77C314.151 245.236 313.431 245.123 313.031 245.572L296.261 264.386C295.88 264.812 296.076 265.433 296.618 265.518L301.864 266.344C302.259 266.407 302.497 266.771 302.395 267.158L298.602 281.526C298.5 281.913 298.737 282.277 299.133 282.339L308.441 283.805C308.837 283.867 309.24 283.604 309.343 283.217L313.136 268.849C313.238 268.462 313.641 268.199 314.037 268.261L319.282 269.087Z" fill="black" fill-opacity="0.5" />',
                            '<path d="M303.184 330.062C303.726 330.148 304.221 329.636 304.088 329.128L298.194 306.745C298.053 306.211 297.333 306.098 296.933 306.547L280.163 325.361C279.782 325.787 279.979 326.408 280.52 326.493L285.766 327.319C286.161 327.382 286.399 327.746 286.297 328.133L282.504 342.501C282.402 342.888 282.639 343.252 283.035 343.314L292.344 344.78C292.739 344.842 293.142 344.579 293.245 344.192L297.038 329.824C297.14 329.437 297.543 329.174 297.939 329.236L303.184 330.062Z" fill="black" fill-opacity="0.5" />',
                            // body
                            '<path stroke="url(#main)" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" d="M290.109 463.418C292.358 454.902 301.233 449.11 309.933 450.48L771.07 523.096C779.77 524.467 785 532.48 782.752 540.996L692.086 884.418L199.443 806.84L290.109 463.418Z" fill="black" fill-opacity="0.14" />',
                            // slider
                            '<path fill-rule="evenodd" clip-rule="evenodd" stroke="url(#main)" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" d="M787.589 237.349L460.354 185.818L406.325 390.469C403.872 399.759 409.578 408.501 419.069 409.996L711.934 456.114C721.425 457.609 731.107 451.29 733.56 442L787.589 237.349ZM660.269 245.01C655.523 244.263 650.682 247.423 649.456 252.068L607.386 411.418C606.16 416.063 609.013 420.434 613.759 421.181L682.499 432.006C687.245 432.753 692.086 429.594 693.312 424.949L735.382 265.599C736.608 260.954 733.755 256.583 729.01 255.835L660.269 245.01Z" fill="url(#main)" />',
                            // fleek logo
                            '<path fill-rule="evenodd" clip-rule="evenodd" d="M864.643 283.937C865.186 283.605 865.708 284.257 865.239 284.683L844.268 303.719C843.938 304.018 844.093 304.517 844.526 304.548L853.726 305.207C854.184 305.24 854.321 305.787 853.942 306.071L833.884 321.112C833.506 321.396 833.643 321.943 834.101 321.976L844.007 322.685C844.491 322.72 844.605 323.319 844.177 323.58L797.752 351.954C797.209 352.286 796.687 351.634 797.156 351.209L818.403 331.922C818.733 331.622 818.577 331.123 818.145 331.092L808.748 330.42C808.292 330.387 808.154 329.843 808.529 329.558L828.054 314.744C828.43 314.459 828.291 313.915 827.835 313.882L818.389 313.206C817.904 313.171 817.79 312.572 818.218 312.311L864.643 283.937Z" fill="white" />',
                            // text
                            '<g transform="matrix(0.987827 0.155557 -0.255261 0.966872 250 735)"><text font-family="Inter, sans-serif" font-weight="bold" font-size="42" fill="#E5E7F8">',
                            name,
                            '</text><text font-family="Inter, sans-serif" font-weight="normal" y="40" font-size="22" fill="#7F8192">',
                            ENS,
                            "</text></g>",
                            // logo
                            '<image width="167" height="167" transform="matrix(0.987827 0.155557 -0.255261 0.966872 444.117 524.17)" href="',
                            logo,
                            '" />',
                            // defs
                            "<defs>",
                            // shadow
                            '<filter id="diskette-shadow" x="70.7489" y="195.712" width="955.733" height="832.558" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" /><feBlend in="SourceGraphic" /><feGaussianBlur stdDeviation="42" /></filter>',
                            // bg
                            '<linearGradient id="background" x1="532.5" y1="0" x2="532.5" y2="1065" gradientUnits="userSpaceOnUse"><stop /><stop offset="1" stop-color="#131313" /></linearGradient>',
                            '<radialGradient id="background-radial" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(532.5 532.5) rotate(89.961) scale(735)"><stop stop-color="',
                            color,
                            '" /><stop offset="1" stop-color="',
                            color,
                            '" stop-opacity="0" /></radialGradient>',
                            // fill gradient
                            '<linearGradient id="diskette-gradient" x1="925.626" y1="256.896" x2="136.779" y2="800.203" gradientUnits="userSpaceOnUse"><stop stop-color="',
                            color,
                            '" /><stop offset="1" stop-color="#2C313F" /></linearGradient>',
                            // color
                            '<linearGradient id="main"><stop stop-color="',
                            color,
                            '" /></linearGradient>',
                            // end defs
                            "</defs>",
                            "</svg>"
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "../util/BytesLib.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    using BytesLib for bytes;

    // ua can not send payload larger than this by default, but it can be changed by the ua owner
    uint public constant DEFAULT_PAYLOAD_SIZE_LIMIT = 10000;

    ILayerZeroEndpoint public lzEndpoint;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => mapping(uint16 => uint)) public minDstGasLookup;
    mapping(uint16 => uint) public payloadSizeLimitLookup;
    address public precrime;

    event SetPrecrime(address precrime);
    event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
    event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
    event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint _minDstGas);

    // constructor(address _endpoint) {
    //     lzEndpoint = ILayerZeroEndpoint(_endpoint);
    // }

    function initializeLzApp(
        address _endpoint
    ) public {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(msg.sender == address(lzEndpoint), "LzApp: invalid endpoint caller");

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(
            _srcAddress.length == trustedRemote.length &&
                trustedRemote.length > 0 &&
                keccak256(_srcAddress) == keccak256(trustedRemote),
            "LzApp: invalid source sending contract"
        );

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams,
        uint _nativeFee
    ) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, "LzApp: destination chain is not a trusted source");
        _checkPayloadSize(_dstChainId, _payload.length);
        lzEndpoint.send{value: _nativeFee}(
            _dstChainId,
            trustedRemote,
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    function _checkGasLimit(
        uint16 _dstChainId,
        uint16 _type,
        bytes memory _adapterParams,
        uint _extraGas
    ) internal view virtual {
        uint providedGasLimit = _getGasLimit(_adapterParams);
        uint minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;
        require(minGasLimit > 0, "LzApp: minGasLimit not set");
        require(providedGasLimit >= minGasLimit, "LzApp: gas limit is too low");
    }

    function _getGasLimit(bytes memory _adapterParams) internal pure virtual returns (uint gasLimit) {
        require(_adapterParams.length >= 34, "LzApp: invalid adapterParams");
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    function _checkPayloadSize(uint16 _dstChainId, uint _payloadSize) internal view virtual {
        uint payloadSizeLimit = payloadSizeLimitLookup[_dstChainId];
        if (payloadSizeLimit == 0) {
            // use default if not set
            payloadSizeLimit = DEFAULT_PAYLOAD_SIZE_LIMIT;
        }
        require(_payloadSize <= payloadSizeLimit, "LzApp: payload size is too large");
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address,
        uint _configType
    ) external view returns (bytes memory) {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // _path = abi.encodePacked(remoteAddress, localAddress)
    // this function set the trusted path for the cross-chain communication
    function setTrustedRemote(uint16 _remoteChainId, bytes calldata _path) external {
        trustedRemoteLookup[_remoteChainId] = _path;
        emit SetTrustedRemote(_remoteChainId, _path);
    }

    function setTrustedRemoteAddress(uint16 _remoteChainId, bytes calldata _remoteAddress) external {
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(_remoteAddress, address(this));
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function getTrustedRemoteAddress(uint16 _remoteChainId) external view returns (bytes memory) {
        bytes memory path = trustedRemoteLookup[_remoteChainId];
        require(path.length != 0, "LzApp: no trusted path record");
        return path.slice(0, path.length - 20); // the last 20 bytes should be address(this)
    }

    function setPrecrime(address _precrime) external {
        precrime = _precrime;
        emit SetPrecrime(_precrime);
    }

    function setMinDstGas(uint16 _dstChainId, uint16 _packetType, uint _minGas) external {
        require(_minGas > 0, "LzApp: invalid minGas");
        minDstGasLookup[_dstChainId][_packetType] = _minGas;
        emit SetMinDstGas(_dstChainId, _packetType, _minGas);
    }

    // if the size is 0, it means default size limit
    function setPayloadSizeLimit(uint16 _dstChainId, uint _size) external {
        payloadSizeLimitLookup[_dstChainId] = _size;
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LzApp.sol";
import "./ExcessivelySafeCall.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
    using ExcessivelySafeCall for address;

    // constructor(address _endpoint) LzApp(_endpoint) {
    //     require(msg.sender == msg.sender);
    // }

    function initializeNonblockingLzApp(address _endpoint) public {
        LzApp.initializeLzApp(_endpoint);
    }

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload, bytes _reason);
    event RetryMessageSuccess(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes32 _payloadHash);

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual override {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(
            gasleft(),
            150,
            abi.encodeWithSelector(this.nonblockingLzReceive.selector, _srcChainId, _srcAddress, _nonce, _payload)
        );
        // try-catch all errors/exceptions
        if (!success) {
            _storeFailedMessage(_srcChainId, _srcAddress, _nonce, _payload, reason);
        }
    }

    function _storeFailedMessage(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload,
        bytes memory _reason
    ) internal virtual {
        failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
        emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, _reason);
    }

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public virtual {
        // only internal transaction
        require(msg.sender == address(this), "NonblockingLzApp: caller must be LzApp");
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function retryMessage(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "NonblockingLzApp: no stored message");
        require(keccak256(_payload) == payloadHash, "NonblockingLzApp: invalid payload");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
        emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
    }
}