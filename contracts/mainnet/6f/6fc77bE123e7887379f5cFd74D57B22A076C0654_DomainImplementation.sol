/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import {DataStructs} from "./libraries/DataStructs.sol";
import {MintInformation} from "./libraries/MintInformation.sol";
import {BurnInformation} from "./libraries/BurnInformation.sol";
import {ExtensionInformation} from "./libraries/ExtensionInformation.sol";

import {Domain} from "./libraries/Domain.sol";
import {Destroyable} from "./Destroyable.sol";
import {ICustodian} from "./interfaces/ICustodian.sol";
import {IDomain} from "./interfaces/IDomain.sol";

/// @title Domain Token implementation
/// @notice Domain Token implementation
contract DomainImplementation is ERC721Enumerable, Destroyable, IDomain, Initializable {
  using Domain for DataStructs.Domain;
  ICustodian public custodian;
  mapping(uint256 => DataStructs.Domain) public domains;
  string private _name;
  string private _symbol;
  string private NAME_SEPARATOR = " ";
  string private SYMBOL_SEPARATOR = "-";

  mapping(uint256 => uint256) public mintingTimestamp;
  uint256 public withdrawLockWindow = 90 * 24 * 3600; // 90 days

  modifier onlyCustodian() {
    require(msg.sender == address(custodian) || custodian.isOperator(msg.sender), "only custodian");
    _;
  }

  constructor() ERC721Enumerable() ERC721("DOMAIN", "Domains") {}

  function initialize(
    address custodian_,
    string memory symbol_,
    string memory name_,
    string memory nameSeparator_,
    string memory symbolSeparator_
  ) public initializer {
    custodian = ICustodian(custodian_);
    _name = name_;
    _symbol = symbol_;
    NAME_SEPARATOR = nameSeparator_;
    SYMBOL_SEPARATOR = symbolSeparator_;
  }

  function _baseURI() internal view override returns (string memory) {
    return custodian.baseUrl();
  }

  /// @notice Sets domain name and symbol configuration
  /// @dev can be called only by contract owner
  /// @param name_ The name of the token
  /// @param symbol_ The symbol of the token
  /// @param nameSeparator_ The separator used to separate the custodian name and the token name
  /// @param symbolSeparator_ The separator used to separate the custodian name and the token symbol
  function setNameSymbolAndSeparators(
    string memory name_,
    string memory symbol_,
    string memory nameSeparator_,
    string memory symbolSeparator_
  ) public onlyOwner {
    _name = name_;
    _symbol = symbol_;
    NAME_SEPARATOR = nameSeparator_;
    SYMBOL_SEPARATOR = symbolSeparator_;
  }

  /// @notice Get the token name
  /// @dev The token name is constructed using the custodian name and the token name separated by the NAME_SEPARATOR
  /// @return The token name
  function name() public view override returns (string memory) {
    return string(abi.encodePacked(custodian.name(), NAME_SEPARATOR, _name));
  }

  /// @notice Get the token symbol
  /// @dev The token symbol is constructed using the custodian name and the token symbol separated by the SYMBOL_SEPARATOR
  /// @return The token symbol
  function symbol() public view override returns (string memory) {
    return string(abi.encodePacked(_symbol, SYMBOL_SEPARATOR, custodian.name()));
  }

  /// @notice Set custodian contract address
  /// @dev can be called only by contract owner
  /// @param _custodian The address of the custodian contract
  function setCustodian(address _custodian) external override onlyOwner {
    custodian = ICustodian(_custodian);
  }

  function _isValidTokenId(DataStructs.Information memory info) internal pure returns (bool) {
    return uint256(keccak256(abi.encode(info.domainName))) == info.tokenId;
  }

  /// @notice Check if the tokenId exists
  /// @param tokenId The tokenId to check
  /// @return True if the tokenId exists, false otherwise
  function exists(uint256 tokenId) external view override returns (bool) {
    return _exists(tokenId);
  }

  function setWithdrawLockWindow(uint256 _withdrawLockWindow) external onlyOwner {
    withdrawLockWindow = _withdrawLockWindow;
  }

  /// @notice Set new expiration time for a domain
  /// @dev can be called only by custodian
  /// @dev emits DomainExtended event on success
  /// @param info Extension information
  function extend(DataStructs.Information memory info) external override onlyCustodian {
    require(_exists(info.tokenId), "Token does not exist");

    require(ExtensionInformation.isValidInfo(info), "Is not valid info");

    domains[info.tokenId].updateExpiry(info.expiry);

    emit DomainExtended(
      info.tokenId,
      ownerOf(info.tokenId),
      domains[info.tokenId].expiry,
      domains[info.tokenId].name
    );
  }

  /// @notice Mint a new tokenId
  /// @dev can be called only by custodian
  /// @dev will mint the tokenId associated to the domain name if it was not previosly minted
  /// @dev emits DomainMinted event on success
  function mint(DataStructs.Information memory info)
    external
    override
    onlyCustodian
    returns (uint256)
  {
    require(!_exists(info.tokenId), "Token Exists");
    require(MintInformation.isValidInfo(info), "Is not valid info");
    require(_isValidTokenId(info), "Is Not Valid Token Id");

    DataStructs.Domain memory domain = DataStructs.Domain({
      name: info.domainName,
      expiry: info.expiry,
      locked: block.timestamp,
      frozen: 0
    });

    domains[info.tokenId] = domain;

    _mint(info.owner, info.tokenId);
    emit DomainMinted(info.tokenId, info.owner, info.expiry, domains[info.tokenId].name);

    return info.tokenId;
  }

  /// @notice Burn a tokenId
  /// @dev can be called only by custodian
  /// @dev will emit DomainBurned event on success
  function burn(DataStructs.Information memory info) external override onlyCustodian {
    require(_exists(info.tokenId), "Token does not exist");
    require(BurnInformation.isValidInfo(info), "Is not valid info");
    require(domains[info.tokenId].isNotLocked(), "Domain Locked");

    emit DomainBurned(info.tokenId, domains[info.tokenId].expiry, domains[info.tokenId].name);

    delete domains[info.tokenId];
    delete mintingTimestamp[info.tokenId];

    _burn(info.tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override {
    super._beforeTokenTransfer(from, to, tokenId);
    /// @dev a domain token can not be transferred if it is locked, frozen or expired
    if (to != address(0) && from != address(0) && !custodian.isOperator(msg.sender)) {
      require(domains[tokenId].isNotLocked(), "Domain is locked");
      require(domains[tokenId].isNotFrozen(), "Domain is frozen");
      require(domains[tokenId].isNotExpired(), "Domain is expired");
    }
    // set timestamp of domain token minting
    if (from == address(0)) {
      mintingTimestamp[tokenId] = block.timestamp;
    }
  }
  /// @notice Custodian can force transfer any domain token to any other address due to disputes or other reasons
  /// @dev can be called only by custodian
  /// @param to The destination address
  /// @param tokenId The tokenId to transfer
  function adminTransferFrom(address to, uint256 tokenId) external override onlyCustodian {
    require(_exists(tokenId), "Token does not exist");
    _transfer(ownerOf(tokenId), to, tokenId);
  }

  /// @notice Custodian can change minting timestamp of a domain token
  /// @dev can be called only by custodian
  /// @param tokenId The tokenId to change the minting timestamp
  /// @param newMintTime The new minting timestamp
  function adminChangeMintTime(uint256 tokenId, uint256 newMintTime) external override onlyCustodian {
    require(_exists(tokenId), "Token does not exist");
    mintingTimestamp[tokenId] = newMintTime;
  }

  /// @notice Owner of a token can set Lock status. While locked a domain can not be transferred to another address.
  /// @dev can be called only by owner of the token. Emits DomainLocked event on success
  /// @param tokenId The tokenId to set the lock status
  /// @param status True if the domain is locked, false otherwise
  function setLock(uint256 tokenId, bool status) external override {
    require(_exists(tokenId), "token does not exist");
    require(ownerOf(tokenId) == msg.sender, "not owner of domain");
    domains[tokenId].setLock(status);
    emit DomainLock(tokenId, domains[tokenId].locked);
  }

  /// @notice Set freeze status of a domain token. While frozen a domain can not be transferred to another address.
  /// @dev Can only be called by custodian. Emits DomainFreez event on success
  /// @param tokenId The tokenId to set the freeze status
  /// @param status True if the domain is frozen, false otherwise
  function setFreeze(uint256 tokenId, bool status) external override onlyCustodian {
    require(_exists(tokenId), "Domain does not exist");
    domains[tokenId].setFreeze(status);
    emit DomainFreeze(tokenId, domains[tokenId].frozen);
  }
  /// @notice Check if a withdraw request can be issued
  /// @param tokenId The tokenId to check
  /// @return True if the withdraw request can be issued, false otherwise
  function canWithdraw(uint256 tokenId) public view override returns (bool) {
    require(_exists(tokenId), "Domain does not exist");
    return block.timestamp >= mintingTimestamp[tokenId] + withdrawLockWindow;
  }

  /// @notice Request to withdraw the token from custodian.
  /// @dev only the owner or approved address can request to withdraw the domain name
  /// @dev will emit WithdrawRequest event on success
  /// @dev the token must be transferrable
  /// @param tokenId The tokenId to withdraw
  function withdraw(uint256 tokenId) external override {
    require(_exists(tokenId), "Domain does no exist");
    require(_isApprovedOrOwner(msg.sender, tokenId), "not owner of domain");
    require(canWithdraw(tokenId), "Domain can not be withdrawn");
    require(domains[tokenId].isNotLocked(), "Domain is locked");
    require(domains[tokenId].isNotFrozen(), "Domain is frozen");
    require(domains[tokenId].isNotExpired(), "Domain is expired");
    domains[tokenId].setFreeze(true);
    emit WithdrawRequest(tokenId, ownerOf(tokenId));
  }

  /// @notice Get the domain information for a token id
  /// @param tokenId The tokenId to get the information for
  /// @return The domain information
  function getDomainInfo(uint256 tokenId)
    external
    view
    override
    returns (DataStructs.Domain memory)
  {
    return domains[tokenId];
  }

  /// @notice Check if the domain token is locked
  /// @param tokenId The tokenId to check
  /// @return True if the token is locked, false otherwise
  function isLocked(uint256 tokenId) external view override returns (bool) {
    return !domains[tokenId].isNotLocked();
  }

  /// @notice Check if the domain token is frozen
  /// @param tokenId The tokenId to check
  /// @return True if the token is frozen, false otherwise
  function isFrozen(uint256 tokenId) external view override returns (bool) {
    return !domains[tokenId].isNotFrozen();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
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
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

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
        uint256 length = ERC721.balanceOf(to);
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

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

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
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DataStructs {
  /// @notice Information required for minting, extending or burning a domain token.
  struct Information {
    // Each type of domain action minting,extending and burning is assigned an unique indetifier which is defined in the library that handles functionality for the specific action.
    uint256 messageType;
    // the custodian contract address
    address custodian;
    // the tokenId
    uint256 tokenId;
    // owner of the token
    address owner;
    // domain name of the token
    string domainName;
    // expiry timestamp of the token
    uint256 expiry;
  }

  /// @notice Domain information attached to a token
  struct Domain {
    // The domain name of the token
    string name;
    // the expiry timestamp of the token
    uint256 expiry;
    // timestamp of when the token was locked. Will be 0 if not locked.
    uint256 locked;
    // timestamp of when the token was frozen. A token can be frozen by custodian in case of emergency or disputes. Will be 0 if not frozen.
    uint256 frozen;
  }

  /// @notice Type of acquisition manager orders
  enum OrderType {
    UNDEFINED, // not used
    REGISTER, // register a new domain
    IMPORT, // import a domain from another registrar
    EXTEND // extend the expiration date of a domain token
  }
  enum OrderStatus {
    UNDEFINED, // not used
    OPEN, // order has been placed by customer
    INITIATED, // order has been acknowledged by custodian
    SUCCESS, // order has been completed successfully
    FAILED, // order has failed
    REFUNDED // order has been refunded
  }

  /// @notice Order information when initiating an order with acquisition manager
  struct OrderInfo {
    OrderType orderType;
    // The domain token id
    uint256 tokenId;
    // number of registration years
    uint256 numberOfYears;
    // desired payment token. address(0) for native asset payments.
    address paymentToken;
    // tld of the domain in clear text
    string tld;
    // pgp encrypted order data with custodian pgp public key.
    // It is important for the data to be encrypted and not in plain text for security purposes.
    // The message that is encrypted is in json format and contains the order information e.g. { "domainName": "example.com", "transferCode": "authC0d3" }. More information on custodian website.
    string data;
  }

  /// @notice Order information stored in acquisition manager
  struct Order {
    // The order id
    uint256 id;
    // The customer who requested the order
    address customer;
    // Type of order
    OrderType orderType;
    // Status of order
    OrderStatus status;
    // The domain token id
    uint256 tokenId;
    // number of registration years
    uint256 numberOfYears;
    // payment token address
    address paymentToken;
    // payment amount
    uint256 paymentAmount;
    // Open timestamp of the order
    uint256 openTime;
    // Open window before order is considered expired
    uint256 openWindow;
    // when was the order settled
    uint256 settled;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataStructs} from "./DataStructs.sol";

/// @title Mint Information functions
/// @notice Provides functions for checking mint information
library MintInformation {
  /// @notice constant value defining the mint message type
  /// @dev uint256 converted keccak256 hash of encoded "dnt.domain.messagetype.mint" string
  /// @return message type id
  function MESSAGE_TYPE() internal pure returns (uint256) {
    return uint256(keccak256(abi.encode("dnt.domain.messagetype.mint")));
  }

  /// @notice Encoded and hash information to be used for signature checking
  /// @param info The mint information
  /// @return keccak256 hash of the encoded information
  function encode(DataStructs.Information memory info) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          MESSAGE_TYPE(),
          info.custodian,
          info.owner,
          info.tokenId,
          info.domainName,
          info.expiry
        )
      );
  }

  /// @notice Check if the information is valid
  /// @dev Checks tokenId to be the correct one for domain name
  /// @dev Expiry timestamp must be in the future
  /// @dev owner can not be the zeroo address
  /// @dev messageType must be the Mint Message Type
  /// @param info The mint information
  /// @return true if the information is valid, false otherwise
  function isValidInfo(DataStructs.Information memory info) internal view returns (bool) {
    return
      info.tokenId == uint256(keccak256(abi.encode(info.domainName))) &&
      info.expiry > block.timestamp &&
      info.owner != address(0) &&
      info.messageType == MESSAGE_TYPE();
  }

  /// @notice Checks if the information contains the correct custodian address
  /// @param info The mint information
  /// @param expectedCustodian The custodian address
  /// @return true if the custodian is correct, false otherwise
  function isValidCustodian(DataStructs.Information memory info, address expectedCustodian)
    internal
    pure
    returns (bool)
  {
    return expectedCustodian == info.custodian;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataStructs} from "./DataStructs.sol";

/// @title Burn Information functions
/// @notice Provides functions for checking burn information
library BurnInformation {
  /// @notice constant value defining the burn message type
  /// @dev uint256 converted keccak256 hash of encoded "dnt.domain.messagetype.burn" string
  /// @return message type id
  function MESSAGE_TYPE() internal pure returns (uint256) {
    return uint256(keccak256(abi.encode("dnt.domain.messagetype.burn")));
  }

  /// @notice Encoded and hash information to be used for signature checking
  /// @param info The burn information
  /// @return keccak256 hash of the encoded information
  function encode(DataStructs.Information memory info) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(info.messageType, info.custodian, info.tokenId, info.domainName, info.expiry)
      );
  }

  /// @notice Checks if the burn information is valid
  /// @param info The burn information
  /// @return true if the information is valid, false otherwise
  function isValidInfo(DataStructs.Information memory info) internal view returns (bool) {
    return
      info.tokenId == uint256(keccak256(abi.encode(info.domainName))) &&
      info.expiry > block.timestamp &&
      info.messageType == MESSAGE_TYPE();
  }

  /// @notice Checks if the information contains the correct custodian address
  /// @param info The information
  /// @param expectedCustodian The custodian address
  /// @return true if the custodian is correct, false otherwise
  function isValidCustodian(DataStructs.Information memory info, address expectedCustodian)
    internal
    pure
    returns (bool)
  {
    return expectedCustodian == info.custodian;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataStructs} from "./DataStructs.sol";

/// @title Mint Information functions
/// @notice Provides functions for checking token expiration extension information
library ExtensionInformation {
  /// @notice constant value defining the extension message type
  /// @dev uint256 converted keccak256 hash of encoded "dnt.domain.messagetype.extension" string
  /// @return message type id
  function MESSAGE_TYPE() internal pure returns (uint256) {
    return uint256(keccak256(abi.encode("dnt.domain.messagetype.extension")));
  }

  /// @notice Encoded and hash information to be used for signature checking
  /// @param info The extension information
  /// @return keccak256 hash of the encoded information
  function encode(DataStructs.Information memory info) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(MESSAGE_TYPE(), info.custodian, info.tokenId, info.domainName, info.expiry)
      );
  }

  /// @notice Checks if the extension information is valid
  /// @dev Token id must be the correct one for domain name
  /// @dev Expiry timestamp must be in the future
  /// @dev messageType must be the ExtensionInformation message type
  /// @param info The extension information
  /// @return true if the information is valid, false otherwise
  function isValidInfo(DataStructs.Information memory info) internal view returns (bool) {
    return
      info.tokenId == uint256(keccak256(abi.encode(info.domainName))) &&
      info.expiry > block.timestamp &&
      info.messageType == MESSAGE_TYPE();
  }

  /// @notice Checks if the information contains the correct custodian address
  /// @param info The extension information
  /// @param expectedCustodian The custodian address
  /// @return true if the custodian is correct, false otherwise
  function isValidCustodian(DataStructs.Information memory info, address expectedCustodian)
    internal
    pure
    returns (bool)
  {
    return expectedCustodian == info.custodian;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataStructs} from "./DataStructs.sol";

/// @title Domain functionality
/// @notice Provides functions for checking and setting domain information
library Domain {
  /// @notice Compiles the tokenId of a given domainName
  /// @dev The tokenId is the keccak256 hash of the encoded domainName converted to uint256
  /// @param domainName The domain name to be compiled
  /// @return The tokenId of the domainName
  function domainNameToId(string memory domainName) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(domainName)));
  }

  /// @notice Get the keccak256 hash of the domain
  /// param domain The domain storage slot
  /// @return The keccak256 hash of the encoded domain name
  function domainHash(DataStructs.Domain storage domain) internal view returns (bytes32) {
    return keccak256(abi.encode(domain.name));
  }

  /// @notice Get the tokenId of a domain
  /// @dev The tokenId is the keccak256 hash of the encoded domainName converted to uint256
  /// @param domain The domain storage slot
  /// @return The tokenId of the domain
  function getTokenId(DataStructs.Domain storage domain) internal view returns (uint256) {
    return uint256(keccak256(abi.encode(domain.name)));
  }

  /// @notice Checks if the domain is not locked
  /// @param domain The domain storage slot
  /// @return True if the domain is not locked, false otherwise
  function isNotLocked(DataStructs.Domain storage domain) internal view returns (bool) {
    return domain.locked == 0;
  }

  /// @notice Checks if the domain is not expired
  /// @param domain The domain storage slot
  /// @return True if the domain is not expired, false otherwise
  function isNotExpired(DataStructs.Domain storage domain) internal view returns (bool) {
    return domain.expiry > block.timestamp;
  }

  /// @notice Checks if the domain is not frozen
  /// @param domain The domain storage slot
  /// @return True if the domain is not frozen, false otherwise
  function isNotFrozen(DataStructs.Domain storage domain) internal view returns (bool) {
    return domain.frozen == 0;
  }

  /// @notice Checks if the domain can be transferred
  /// @dev A domain token can be transferred to another owner if is not frozen, expired or locked
  /// @param domain The domain storage slot
  /// @return True if the domain can be transferred, false otherwise
  function canTransfer(DataStructs.Domain storage domain) internal view returns (bool) {
    return isNotFrozen(domain) && isNotExpired(domain) && isNotLocked(domain);
  }

  /// @notice Updates expiration date of a domain
  /// @param domain The domain storage slot
  /// @param expiry The new expiration date
  function updateExpiry(DataStructs.Domain storage domain, uint256 expiry) internal {
    domain.expiry = expiry;
  }

  /// @notice Set the lock status of a domain
  /// @param domain The domain storage slot
  /// @param status The new lock status. True for Locked, false for Unlocked
  function setLock(DataStructs.Domain storage domain, bool status) internal {
    if (status) {
      domain.locked = block.timestamp;
    } else {
      domain.locked = 0;
    }
  }

  /// @notice Set the freeze status of a domain
  /// @param domain The domain storage slot
  /// @param status The new freeze status. True for Frozen, false for Unfrozen
  function setFreeze(DataStructs.Domain storage domain, bool status) internal {
    if (status) {
      domain.frozen = block.timestamp;
    } else {
      domain.frozen = 0;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Destroyable is Ownable {
  constructor() {}

  function _beforeDestroy() internal virtual {}

  function destroy() external onlyOwner {
    _beforeDestroy();
    selfdestruct(payable(msg.sender));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICustodian {
  event OperatorAdded(address indexed operator);
  event OperatorRemoved(address indexed operator);

  function setCustodianInfo(string memory, string memory) external;

  function setPgpPublicKey(string memory) external;

  function name() external view returns (string memory);

  function baseUrl() external view returns (string memory);

  function addOperator(address) external;

  function removeOperator(address) external;

  function getOperators() external returns (address[] memory);

  function isOperator(address) external view returns (bool);

  function checkSignature(bytes32, bytes memory) external view returns (bool);

  function _nonce(bytes32) external view returns (uint256);

  function externalCall(address, bytes memory) external payable returns (bytes memory);

  function externalCallWithPermit(
    address _contract,
    bytes memory data,
    bytes memory signature,
    bytes32 signatureNonceGroup,
    uint256 signatureNonce
  ) external payable returns (bytes memory);

  function enableTlds(string[] memory) external;

  function disableTlds(string[] memory) external;

  function getTlds() external view returns (string[] memory);

  function isTldEnabled(string memory) external view returns (bool);

  function isTldEnabled(bytes32) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataStructs} from "../libraries/DataStructs.sol";

/// @title IDomain
/// @notice Interface for the domain token
interface IDomain {
  /// @notice Emitted when a domain token is burned
  /// @param tokenId The token ID of the domain token that was burned
  /// @param expiry The expiry date of the domain token that was burned
  /// @param domainName The name of the domain token that was burned
  event DomainBurned(uint256 tokenId, uint256 expiry, string domainName);

  /// @notice Emitted when a domain token was minted
  /// @param tokenId The token ID of the domain token that was minted
  /// @param owner The owner of the domain token that was minted
  /// @param expiry The expiry date of the domain token that was minted
  /// @param domainName The name of the domain token that was minted
  event DomainMinted(uint256 tokenId, address owner, uint256 expiry, string domainName);

  /// @notice Emitted when a domain token was extended
  /// @param tokenId The token ID of the domain token that was extended
  /// @param owner The owner of the domain token that was extended
  /// @param expiry The expiry date of the domain token that was extended
  /// @param domainName the name of the domain token that was extended
  event DomainExtended(uint256 tokenId, address owner, uint256 expiry, string domainName);

  /// @notice Emitted when a domain token frozen status has changed
  /// @param tokenId The token ID of the domain token that was frozen
  /// @param status The new frozen status of the domain token
  event DomainFreeze(uint256 tokenId, uint256 status);

  /// @notice Emitted when a domain token lock status has changed
  /// @param tokenId The token ID of the domain token that was locked
  /// @param status The new lock status of the domain token
  event DomainLock(uint256 tokenId, uint256 status);

  /// @notice Emitted a withdraw request was made
  /// @param tokenId The token ID of the domain token that was locked
  /// @param owner The owner of the domain token
  event WithdrawRequest(uint256 tokenId, address owner);

  function exists(uint256 tokenId) external view returns (bool);

  function mint(DataStructs.Information memory) external returns (uint256);

  function extend(DataStructs.Information memory) external;

  function burn(DataStructs.Information memory) external;

  function getDomainInfo(uint256) external view returns (DataStructs.Domain memory);

  function setFreeze(uint256, bool) external;

  function setLock(uint256, bool) external;

  function setCustodian(address) external;

  function isLocked(uint256) external view returns (bool);

  function isFrozen(uint256) external view returns (bool);

  function withdraw(uint256) external;

  function adminTransferFrom(address,uint256) external;

  function adminChangeMintTime(uint256,uint256) external;

  function canWithdraw(uint256) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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