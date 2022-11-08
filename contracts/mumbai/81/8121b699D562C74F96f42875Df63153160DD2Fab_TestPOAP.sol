// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
 
/// @author [email protected]

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";

import "../base/ERC721BaseByTier.sol";

contract TestPOAP is 
    ERC721BaseByTier,
    ERC2771Recipient,
    AccessControl,
    Ownable,
    Pausable {
        
    // `bytes32` identifier for admin role.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // `bytes32` identifier for token burner role.
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /**
     * @dev Constructor.
     */
    constructor(
        address _adminAddress,
        string memory _initBaseURI,
        uint16 _initMaxQuantity,
        uint256 _initStartTokenId,
        bool _isBaseURIFinal,
        bool _isTokenTransferable
    ) ERC721BaseByTier("Test Poap", "TPO"){
        // Setup roles.
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());   
        _setupRole(ADMIN_ROLE, _adminAddress);
        // Init collection.
        _setMaxQuantity(_initMaxQuantity);
        _setStartTokenId(_initStartTokenId);
        _setBaseURI(_initBaseURI, _isBaseURIFinal);
        _setTokenTransferState(_isTokenTransferable);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721BaseByTier, AccessControl) returns (bool) {
        return 
            ERC721BaseByTier.supportsInterface(interfaceId) || 
            AccessControl.supportsInterface(interfaceId) || 
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721BaseByTier-airdrop}.
     */
    function airdrop(address[] calldata receivers, uint16[] calldata quantity, uint16 tierId) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _airdropByTier(receivers, quantity, tierId);
    }

    /**
     * @dev See {IERC721BaseByTier-mint}.
     */
    function mint(address to, uint16 tierId, uint16 quantity) external onlyRole(ADMIN_ROLE) whenNotPaused {
       _mintBatchByTierToValidatedInput(to, tierId, quantity);
    }

    /**
     * @dev See {IERC721BaseByTier-addTierIds}.
     */
    function addTierIds(uint256[] calldata tierIds) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _addTierIds(tierIds);
    }

    /**
     * @dev See {IERC721BaseByTier-removeTierIds}.
     */
    function removeTierIds(uint256[] calldata tierIds) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _removeTierIds(tierIds);
    }

    /**
     * @dev See {IERC721BaseByTier-setMaxSupply}.
     */
    function setMaxSupplyPerTier(uint256[] calldata tierIds, uint256[] calldata updateMaxSupplyPerTier, bool defined) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _setMaxSupplyPerTier(tierIds, updateMaxSupplyPerTier, defined);
    }

    /**
     * @dev See {IERC721BaseByTier-setTokenTransferState}.
     */
    function setTokenTransferState(bool state) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _setTokenTransferState(state);
    }

    /**
     * @dev See {ICollectibleBase-setMaxQuantity}.
     */
    function setMaxQuantity(uint16 updateMaxQuantity) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _setMaxQuantity(updateMaxQuantity);
    }

    /**
     * @dev See {ICollectibleBase-setMaxNumberMinted}.
     */
    function setMaxNumberMinted(uint16 updateMaxNumberMinted, bool defined) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _setMaxNumberMinted(updateMaxNumberMinted, defined);
    }

    /**
     * @dev See {ICollectibleBase-initStartTokenId}.
     */
    function setStartTokenId(uint256 startTokenId) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _setStartTokenId(startTokenId);
    }

    /**
     * @dev See {ICollectibleBase-setBaseURI}.
     */
    function setBaseURI(string calldata updateBaseURI, bool finalized) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _setBaseURI(updateBaseURI, finalized);
    }

    /**
     * @dev See {ICollectibleBase-setTokenURISuffix}.
     */
    function setTokenURISuffix(string calldata updateTokenURISuffix) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _setTokenURISuffix(updateTokenURISuffix);
    }

    /**
     * @dev See {ICollectibleBurnable-burnByContract}.
     */
    function burnByContract(address owner, uint256 tokenIdOwned) external onlyRole(BURNER_ROLE) whenNotPaused {
        _burnTokenByContract(owner, tokenIdOwned);
    }

    /**
     * @dev See {ICollectibleBurnable-burn}.
     */
    function burn(address owner, uint256 tokenId) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _burnToken(owner, tokenId);
        _postBurnEvent(tokenId);
    }

    /**
     * @dev See {ICollectibleBurnable-setBaseBurnedURI}.
     */
    function setBaseBurnedURI(string memory updateBaseBurnedURI) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _setBaseBurnedURI(updateBaseBurnedURI);
    }

    /**
     * @dev See {ICollectibleBurnable-setTokenBurnByContractState}.
     */
    function setTokenBurnByContractState(bool state) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _setTokenBurnByContractState(state);
    }

    /**
     * @dev See {ICollectibleBurnable-setTokenBurnState}.
     */
    function setTokenBurnState(bool state) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _setTokenBurnState(state);
    }

    /**
     * @dev See {ICollectibleBurnable-setFutureContractAddress}.
     */
    function setFutureContractAddress(address futureContractAddress) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _setFutureContractAddress(futureContractAddress);
        // Grant `futureContractAddress` as BURNER_ROLE.
        _grantRole(BURNER_ROLE, futureContractAddress);
    }

    /**
     * @dev See {ERC2771Recipient-_setTrustedForwarder}.
     */

    function setTrustedForwarder(address forwarder) external onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        _setTrustedForwarder(forwarder);
    }

    /**
     * @dev See {Pausable-_pause}.
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev See {Pausable-_unpause}.
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// The following functions are overrideN required by {ERC2771Recipient}.
    function _msgSender() internal view override(ERC2771Recipient, Context) returns (address ret) {
        ret = ERC2771Recipient._msgSender();
    }

    function _msgData() internal view override(ERC2771Recipient, Context) returns (bytes calldata ret) {
        ret = ERC2771Recipient._msgData();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @author [email protected]

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IERC721BaseByTier.sol";
import "./CollectibleBase.sol";

abstract contract ERC721BaseByTier is ERC721, CollectibleBase, IERC721BaseByTier {
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;
    using Strings for uint256;

     // Tier ID tracker.
    EnumerableSet.UintSet private _tierIds;

    // Mapping of token ID (contract) to tier ID.
    mapping(uint256 => uint256) public tierID;

    // Mapping of tier ID to maximum supply per tier ID.
    mapping(uint256 => uint256) public maxSupplyPerTier;

    // Mapping of tier ID to total tokens minted per tier ID.
    mapping(uint256 => uint256) public totalMintedPerTier;

    // Mapping of tier ID to total tokens burned per tier ID.
    mapping(uint256 => uint256) public totalBurnedPerTier;

    // Mapping of token ID (contract) to index on tier ID.
    mapping(uint256 => uint256) public indexByTier;

    // Mapping of recent state of maximum supply per tier ID state. Returns `true` if is defined. `false` otherwise.
    mapping(uint256 => bool) public isMaxSupplyPerTierDefined;

    // Recent state of token transfer mechanism. Returns `true` if is allowed. `false` otherwise.
    bool public isTokenTransferable = true;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) { }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, CollectibleBase, IERC165) returns (bool) {
        return
            interfaceId == type(ICollectibleBase).interfaceId || 
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the total quantity of minted tokens minus burned tokens in the contract.
     */
    function totalSupply() public view virtual returns (uint256) {
        unchecked {
            return totalMinted() - totalBurned();
        } 
    }

    /**
     * @dev Returns the total quantity of tokens minted minus tokens burned per `tierId`.
     */
    function totalSupplyPerTier(uint256 tierId) public view virtual returns (uint256) {
        unchecked {
            return totalMintedPerTier[tierId] - totalBurnedPerTier[tierId];
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * @notice {tokenURI} is overriden to facilitate base burned URI if the `tokenId` is burned
     * and return base URI based on tier ID if the `tokenId` does exist.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        // Cache variable and getter functions.
        string memory baseURI = _baseURI();
        string memory baseBurnedURI = _baseBurnedURI();
        string memory tokenURISuffix = _tokenURISuffix;
        // Init metadata.
        string memory metadata;
        // Check istokenIDBurned state.
        if (_isTokenIdBurned[tokenId]) {
            return metadata = string(abi.encodePacked(baseBurnedURI));
        }
        // Check token ID existance.
        if (!_exists(tokenId)) {
            revert TokenIdDoesNotExist();
        } else {
            /// Example
            /// if tierID = 1 and indexByTier = 10, will return:
            /// baseURI/1/10 (if tokenURISuffix is undefined)
            /// baseURI/1/10.json (if tokenURISuffix is defined)
            return metadata = string.concat(
                baseURI, "/", tierID[tokenId].toString(), "/", indexByTier[tokenId].toString(), tokenURISuffix
            );
        }
    }

    /**
     * @notice Internal Functions.
     */

    /**
     * @dev Mint batch of `quantity` of tokens based on specific `tierId` to `receivers`.
     */
    function _airdropByTier(address[] calldata receivers, uint16[] calldata quantity, uint16 tierId) internal virtual {
        // Check lengths.
        if (receivers.length == 0) revert InvalidLength();
        if (receivers.length != quantity.length) revert InvalidLength();
        // Repeat the logic based on receivers length.
        for (uint256 i = 0; i < receivers.length;) {
            // Call _mintBatchByTierToValidatedInput.
            _mintBatchByTierToValidatedInput(receivers[i], tierId, quantity[i]);
            // Unchecked iteration.
            unchecked {
                ++i;
            }
        }
        // Emits the event.
        emit TokenIdByTierDropped(_msgSender(), receivers, quantity, tierId);
    }

    /**
     * @dev Mint batch of `quantity` of tokens from specific `tierId` to `to` with validated mint input.
     */
    function _mintBatchByTierToValidatedInput(address to, uint16 tierId, uint16 quantity) internal virtual {
        // Validate quantity.
        _validateMintInputByTier(to, tierId, quantity);
        // Call _mintBatchByTierTo function.
        _mintBatchByTierTo(to, tierId, quantity);
    }

    /**
     * @dev Validate mint input for `to` with specific `tierId` and `quantity` of tokens to be minted.
     */
    function _validateMintInputByTier(address to, uint16 tierId, uint16 quantity) internal view {
        // Check tier ID.
        if (!_tierIds.contains(tierId)) revert TierIdDoesNotExist();
        // Check quantity.
        if (quantity == 0 || quantity > _maxQuantity ) revert InvalidQuantity();
        // Check max number minted state.
        if (isMaxNumberMintedDefined) {
            // Check quantity plus total number minted over max number minted per address.
            if (quantity + numberMinted[to] > _maxNumberMintedPerAddress) revert ExceedMaxNumberMintedPerAddress();
        }
        // Check max supply per tier state.
        if (isMaxSupplyPerTierDefined[tierId]) {
            // Check quantity plus total minted per tier ID over max supply per tier ID.
            if (quantity + totalMintedPerTier[tierId] > maxSupplyPerTier[tierId]) revert ExceedMaxSupplyPerTier();
        }
    }

    /**
     * @dev Mint batch of `quantity` of tokens from specific `tierId` to `to`.
     */
    function _mintBatchByTierTo(address to, uint16 tierId, uint16 quantity) internal virtual returns (uint256[] memory tokenIds) {
        // Cache next token ID to be minted as the first index of tokenIds.
        uint256 _firstIndex = nextTokenId();
        // Allocate memory arrays for tokenIds with `quantity` as length.
        tokenIds = new uint256[](quantity);
        // Repeat the logic based on tokenIds length.
        for (uint256 i = 0; i < tokenIds.length;) {
            // Assign incremented _firstIndex to tokenIds.
            tokenIds[i] = _firstIndex++;
            // Call _mintByTierTo.
            _mintByTierTo(to, tierId);
            // Unchecked iteration.
            unchecked {
                ++i;
            }
        }
        // Emits the event.
        emit TokenIdByTierMinted(_msgSender(), to, tierId, quantity, tokenIds);
        // Assign `quantity` to `to` for numberMinted.
        numberMinted[to] += quantity;
    }

    /**
     * @dev Mints next token ID from specific `tierId` to `to`.
     */
    function _mintByTierTo(address to, uint16 tierId) internal virtual {
        // Cache next token ID to be minted.
        uint256 _nextTokenId = nextTokenId();
        // Cache total minted per tier ID.
        uint256 _totalMintedPerTier = totalMintedPerTier[tierId];
        // Increment total minted per tier.
        unchecked {
            ++_totalMintedPerTier;
        }
        // Map incremented total minted per tier to `tierId` for totalMintedPerTier.
        totalMintedPerTier[tierId] = _totalMintedPerTier;
        // Map `tierId` to next token ID (contract) to be minted for tierID.
        tierID[_nextTokenId] = tierId;
        // Map incremented total minted per tier to next token ID (contract) to be minted for indexByTier.
        indexByTier[_nextTokenId] = _totalMintedPerTier;
        // Increment current index.
        _currentIndex.increment();
        // Increment mint counter.
        unchecked {
            ++_mintCounter;
        }
        // Call _mint from {ERC721}.
        ERC721._mint(to, _nextTokenId);
    }

    /**
     * @dev Update mapping totalBurnedPerTier after token burn event.
     */
    function _postBurnEvent(uint256 tokenId) internal virtual returns (uint256 tierId) {
        // Cache the value of tier ID from the token ID (contract).
        tierId = tierID[tokenId];
        // Assign +1 to tierId for totalBurnedPerTier.
        totalBurnedPerTier[tierId] += 1;
    }

    /**
     * @dev See {IERC721BaseByTier-addTierIds}.
     */
    function _addTierIds(uint256[] calldata tierIds) internal virtual {
        // Repeat the logic based on tierIds length.
        for (uint256 i = 0; i < tierIds.length;) {
            // Check tier ID existance.
            if (_tierIds.contains(tierIds[i])) revert TierIdExist();
            // Add tierIds to _tierIds.
            _tierIds.add(tierIds[i]);
            // Unchecked iteration.
            unchecked {
                ++i;
            }
        }
        // Emits the event.
        emit TierIdsAdded(_msgSender(), tierIds);
    }

    /**
     * @dev {IERC721BaseByTier-removeTierIds}.
     */
    function _removeTierIds(uint256[] calldata tierIds) internal virtual {
        // Repeat the logic based on tierIds length.
        for (uint256 i = 0; i < tierIds.length;) {
            // Check tier ID existance.
            if (!_tierIds.contains(tierIds[i])) revert TierIdDoesNotExist();
            // Check total minted per tier ID.
            if (totalMintedPerTier[tierIds[i]] != 0) revert TotalMintedPerTierExist();
            // Remove tierIds from _tierIds.
            _tierIds.remove(tierIds[i]);
            // Unchecked iteration.
            unchecked {
                ++i;
            }
        }
        // Emits the event.
        emit TierIdsRemoved(_msgSender(), tierIds);
    }

    /**
     * @dev See {IERC721BaseByTier-setMaxSupplyPerTier}.
     */
    function _setMaxSupplyPerTier(uint256[] calldata tierIds, uint256[] calldata updateMaxSupplyPerTier, bool defined) internal virtual {
        // Check state.
        if (!defined) {
            revert InvalidUpdateState();
        } else {
            // Check params length.
            if (tierIds.length != updateMaxSupplyPerTier.length) revert InvalidLength();
            // Repeat the logic based on tierIds length.
            for (uint256 i = 0; i < tierIds.length;) {
                // Check tier ID existance.
                if (!_tierIds.contains(tierIds[i])) revert TierIdDoesNotExist();
                // Check total minted per tier ID.
                if (updateMaxSupplyPerTier[i] < totalMintedPerTier[tierIds[i]]) revert InvalidUpdateValue();
                // Update max supply per tier ID.
                maxSupplyPerTier[tierIds[i]] = updateMaxSupplyPerTier[i];
                // Update state per tier ID.
                isMaxSupplyPerTierDefined[tierIds[i]] = true;
                // Unchecked iteration.
                unchecked {
                    ++i;
                }
            }
        }
        // Emits the event.
        emit MaxSupplyPerTierUpdated(_msgSender(), tierIds, updateMaxSupplyPerTier);
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override(ERC721, CollectibleBase) returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override{
        // Check token transfer mechanism state.
        if (!isTokenTransferable) {
            // If `from` and `to` are non-zero address.
            if (from != address(0) && to != address(0)) revert TokenIdIsNotTransferable();
        } else {
            super._beforeTokenTransfer(from, to, tokenId);
        }
    }

    /**
     * @dev See IERC71BaseByTier-setTokenTransferState}.
     */
    function _setTokenTransferState(bool state) internal virtual {
        // Update state.
        isTokenTransferable = state;
        // Emits the event.
        emit TokenTransferState(_msgSender(), state);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IERC2771Recipient.sol";

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Implementation
 *
 * @notice Note that this contract was called `BaseRelayRecipient` in the previous revision of the GSN.
 *
 * @notice A base contract to be inherited by any contract that want to receive relayed transactions.
 *
 * @notice A subclass must use `_msgSender()` instead of `msg.sender`.
 */
abstract contract ERC2771Recipient is IERC2771Recipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @notice Method is not a required method to allow Recipients to trust multiple Forwarders. Not recommended yet.
     * @return forwarder The address of the Forwarder contract that is being used.
     */
    function getTrustedForwarder() public virtual view returns (address forwarder){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
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

pragma solidity ^0.8.13;

/// @author [email protected]

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../extensions/CollectibleBurnable.sol";

import "./ICollectibleBase.sol";

abstract contract CollectibleBase is ERC721, CollectibleBurnable, ICollectibleBase {
    using Counters for Counters.Counter;
    using Strings for uint256;
    
    // Initialize current index counter.
    Counters.Counter internal _currentIndex;

    // Maximum quantity of tokens can be minted in one transaction.
    uint16 internal _maxQuantity;

    // Maximum quantity of tokens can be minted in one address.
    uint16 internal _maxNumberMintedPerAddress;

    // Initialize minted token counter.
    uint256 internal _mintCounter;

    // The starting token ID.
    uint256 internal _startTokenID;

    // base URI of the collection.
    string internal _baseTokenURI;

    // URI suffix of the token URI.
    string internal _tokenURISuffix;

    // Mapping of address to total tokens minted.
    mapping(address => uint16) public numberMinted;

    // Recent state of maximum number minted per wallet address state. Returns `true` if is declared. `false` otherwise.
    bool public isMaxNumberMintedDefined;

    // Recent state of latest base URI. Returns `true` if is final. `false` otherwise.
    bool public isMetadataFinal;

    /**
     * @notice Public Functions.
     */

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, CollectibleBurnable, IERC165) returns (bool) {
        return 
            interfaceId == type(ICollectibleBase).interfaceId || 
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the total quantity of minted tokens in the contract.
     */
    function totalMinted() public view virtual returns (uint256) {
        return _mintCounter;
    }

    /**
     * @dev Returns the next token ID to be minted in the contract.
     */
    function nextTokenId() public view virtual returns (uint256) {
        unchecked {
            return _startTokenId() + _currentIndex.current();
        }
    }

    /**
     * @notice Internal Functions.
     */

    /**
     * @dev See {ICollectibleBase-setMaxQuantity}.
     */
    function _setMaxQuantity(uint16 updateMaxQuantity) internal virtual {
        // Check value.
        if (updateMaxQuantity == 0 && updateMaxQuantity == _maxQuantity ) revert InvalidUpdateValue();
        // Update max quantity.
        _maxQuantity = updateMaxQuantity;
        // Emits the event.
        emit MaxQuantityUpdated(_msgSender(), updateMaxQuantity);
    }

    /**
     * @dev See {ICollectibleBase-setMaxNumberMintedPerAddress}.
     */
    function _setMaxNumberMinted(uint16 updateMaxNumberMinted, bool defined) internal virtual {
        // Check update state.
        if (!defined) {
            revert InvalidUpdateState();
        } else {
            // Check value.
            if (updateMaxNumberMinted == 0 && updateMaxNumberMinted == _maxNumberMintedPerAddress) revert InvalidUpdateValue();
            // Update value.
            _maxNumberMintedPerAddress = updateMaxNumberMinted;
            // Update state.
            isMaxNumberMintedDefined = true;
        }
        // Emits the event.
        emit MaxNumberMintedUpdated(_msgSender(), updateMaxNumberMinted);
    }

    /**
     * @dev Starting token ID to be minted. Default value is 0 (zero). 
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return _startTokenID;
    }

    /**
     * @dev See {ICollectibleBase-initStartTokenId}.
     */
    function _setStartTokenId(uint256 startTokenId) internal virtual {
        // Check value.
        if (totalMinted() != 0 && startTokenId == 0) revert InvalidUpdateValue();
        // Update start token ID.
        _startTokenID = startTokenId;
        // Emits the event.
        emit StartTokenIdUpdated(_msgSender(),  startTokenId);
    }

    /**
     * @dev See {ERC721Upgradeable-_baseURI} 
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {IERC721BaseMetadata-setBaseURI}.
     */
    function _setBaseURI(string memory updateBaseURI, bool finalized) internal virtual {
        // Check state.
        if (isMetadataFinal) revert InvalidUpdateValue();
        // Update base token URI.
        _baseTokenURI = updateBaseURI;
        // Update state.
        isMetadataFinal = finalized;
        // Emits the event.
        emit BaseTokenURIUpdated(_msgSender(), updateBaseURI, finalized);
    }

    /**
     * @dev See IERC721BaseMetadata-setURISuffix}.
     */
    function _setTokenURISuffix(string calldata updateTokenURISuffix) internal virtual {
        // Update tokenURI suffix.
        _tokenURISuffix = updateTokenURISuffix;
        // Emits the event.
        emit TokenURISuffixUpdated(_msgSender(), updateTokenURISuffix);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @author [email protected]

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC721BaseByTier is IERC165 {
    /**
     * @notice Events to be emitted.
     */

    /**
     * @dev Emitted when `tokenId` from specific `tierId` is minted from `from` to `to`.
     */
    event TokenIdByTierMinted(address indexed from, address indexed to, uint256 indexed tierId, uint16 quantity,uint256[] tokenIds);

    /**
     * @dev Emitted when `tokenId` from specific `tierId` is minted from `from` to `receivers`.
     */
    event TokenIdByTierDropped(address indexed from, address[] receivers, uint16[] quantity, uint256 indexed tierId);

    /**
     * @dev Emitted when `caller` add `tierIds`.
     */
    event TierIdsAdded(address indexed caller, uint256[] addedTierIds);

    /**
     * @dev Emitted when `caller` remove `tierIds`.
     */
    event TierIdsRemoved(address indexed caller, uint256[] removedTierIds);

    /**
     * @dev Emitted when `caller` update maximum supply of tokens can be minted per tier ID.
     */
    event MaxSupplyPerTierUpdated(address indexed caller, uint256[] tierIds, uint256[] updatedMaxSupplyPerTier);

    /**
     * @dev Emitted when `caller` register `tierId` can be minted by check or burn previous balance from the previous contract.
     */
    event TierIdAllowedToMintUpdated(address indexed caller, uint256 indexed tierId, bool state);

    /**
     * @dev Emitted when `caller` update state of token transfer mechanism.
     */
    event TokenTransferState(address indexed caller, bool state);

    /**
     * @notice Error handlings.
     */

    /**
     * @dev The `tierId` does exist.
     */
    error TierIdExist();

    /**
     * @dev The `tierId` does not exist.
     */
    error TierIdDoesNotExist();

    /**
     * @dev The `tierId` is not allowed to mint by check or burn previous balance from the previous contract.
     */
    error TierIdIsNotAllowedToMint();

    /**
     * @dev Total minter per `tierId` does exist.
     */
    error TotalMintedPerTierExist();

    /**
     * @dev The quantity of tokens to be minted must be greater than 0 (zero) or maximum equal to maximum quantity.
     */
    error InvalidQuantity();

    /**
     * @dev The length of each dynamically-sized array based params must have at least one length and have the same length.
     */
    error InvalidLength();

    /**
     * @dev The total quantity of tokens to be minted plus recent total minted tokens must be less than total maximum supply per tier ID.
     */
    error ExceedMaxSupplyPerTier();

    /**
     * @dev The total quantity of tokens to be minted exceed maximum number of tokens can be minted per wallet address.
     */
    error ExceedMaxNumberMintedPerAddress();

    /**
     * @notice External functions.
     */

    /**
     * @dev Mints `quantity` of tokens from specific `tierId` and transfers them to `receivers`.
     *
     * Requirements:
     *
     * @param receivers multi-element array of addresses and each of them can not be the zero address.
     * @param quantity multi-element array of quantity and each of them must be greater than 0 (zero) or maximum equal to maximum quantity.
     * @param tierId must exist.
     * 
     * - `receivers` and `quantity` must have the same length.
     */
    function airdrop(address[] calldata receivers, uint16[] calldata quantity, uint16 tierId) external;

    /**
     * @dev Mints `quantity` of tokens from specific `tierId` and transfers them to `to`.
     *
     * Requirements:
     *
     * @param to can not be the zero address.
     * @param tierId must exist.
     * @param quantity must be greater than 0 (zero) or maximum equal to maximum quantity.
     */
    function mint(address to, uint16 tierId, uint16 quantity) external;

    /**
     * @dev Add `tierIds`.
     * 
     * Requirements:
     * 
     * @param tierIds must not exist.
     */
    function addTierIds(uint256[] calldata tierIds) external;

    /**
     * @dev Remove existing `tierIds`.
     * 
     * Requirements:
     * 
     * @param tierIds must exist.
     */
    function removeTierIds(uint256[] calldata tierIds) external;

    /**
     * @dev Update maximum supply per tier ID.
     * 
     * Requirements:
     * 
     * @param tierIds must exist.
     * @param updateMaxSupplyPerTier can not be less than recent total minted per `tierIds`.
     * @param defined must set to `true` to be marked as `defined`.
     * 
     * - `tierIds` and `updateMaxSupplyPerTier` must have the same length.
     */
    function setMaxSupplyPerTier(uint256[] calldata tierIds, uint256[] calldata updateMaxSupplyPerTier, bool defined) external;

    /**
     * @dev Set token transfer mechanism.
     *
     * Requirements:
     * 
     * @param state is a boolean value.
     * - Set to `true` if token transfer mechanism is allowed.
     * - Set to `false` if token transfer mechanism is not allowed.
     */
    function setTokenTransferState(bool state) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
library Counters {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @author [email protected]

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ICollectibleBase is IERC165 {
    /**
     * @notice Events to be emitted.
     */

    /**
     * @dev Emitted when `caller` update maximum quantity of tokens can be minted in one transaction.
     */
    event MaxQuantityUpdated(address indexed caller, uint16 indexed updatedMaxQuantity);

    /**
     * @dev Emitted when `caller` update maximum quantity of tokens can be minted in one address.
     */
    event MaxNumberMintedUpdated(address indexed caller, uint16 indexed updatedMaxNumberMinted);

    /**
     * @dev Emitted when `caller` initiate value of `startTokenId` to be minted.
     */
    event StartTokenIdUpdated(address indexed caller, uint256 indexed startTokenId);

    /**
     * @dev Emitted when `caller` update base URI of the collection.
     */
    event BaseTokenURIUpdated(address indexed caller, string updatedBaseTokenURI, bool isFrozen);

    /**
     * @dev Emitted when `caller` update token URI Suffix for computing {tokenURI}.
     */
    event TokenURISuffixUpdated(address indexed caller, string updatedTokenURISuffix);

    /**
     * @notice Error handlings.
     */

    /**
     * @dev The `tokenId` does not exist.
     */
    error TokenIdDoesNotExist();

    /**
     * @dev The `tokenId` is not transferable.
     */
    error TokenIdIsNotTransferable();

    /**
     * @dev New value is invalid.
     */
    error InvalidUpdateValue();

    /**
     * @dev New state is invalid.
     */
    error InvalidUpdateState();

    /**
     * @notice External functions.
     */

    /**
     * @dev Update maximum quantity of tokens to be minted per one transaction.
     *
     * Requirements:
     *
     * @param updateMaxQuantity must be greater than 0 (zero) and can not be equal with the recent maximum quantity.
     */
    function setMaxQuantity(uint16 updateMaxQuantity) external;

    /**
     * @dev Update maximum quantity of tokens to be minted per one address.
     *
     * Requirements:
     *
     * @param updateMaxNumberMinted must be greater than 0 (zero) and can not be equal with the recent maximum number minted per address.
     * @param defined must set to `true` to be marked as `defined`.
     */
    function setMaxNumberMinted(uint16 updateMaxNumberMinted, bool defined) external;

    /**
     * @dev Initialize starting value of token ID to be minted.
     *
     * Requirements:
     *
     * @param startTokenId must be greater than the default value (zero).
     * 
     * - Can not be called if there is at least 1 (one) minted token.
     */
    function setStartTokenId(uint256 startTokenId) external;

     /**
     * @dev Set base URI for computing {tokenURI} with no extension.
     *
     * Requirements:
     * 
     * @param updateBaseURI must refer to where the base of collection metadata is located (e.g "ipfs://..." or "ar://..." ).
     * @param finalized is a boolean value.
     * - Set to `true` if `updateBaseURI` is final.
     * - Set to `false` if `updateBaseURI` is not final.
     */
    function setBaseURI(string memory updateBaseURI, bool finalized) external;

    /**
     * @dev Set token URI suffix for computing {tokenURI}.
     *
     * Requirements:
     * 
     * @param updateTokenURISuffix is an extension for {tokenURI} and it is is optional. (e.g ".json").
     */
    function setTokenURISuffix(string calldata updateTokenURISuffix) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @author [email protected]

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./ICollectibleBurnable.sol";

abstract contract CollectibleBurnable is ERC721, ICollectibleBurnable {
    using Address for address;

    // Initialize a contract would be deployed in the future.
    address public futureContract;

    // Initialize burned token counter.
    uint256 internal _burnCounter;

    // base URI of burned token ID.
    string internal _baseBurnedTokenURI;

    // Mapping of address to total tokens burned.
    mapping(address => uint16) public numberBurned;

    // Tracker for burned token ID.
    mapping (uint256 => bool) internal _isTokenIdBurned;

    // Recent state of token burn mechanism. Returns `true` if is allowed. `false` otherwise.
    bool public isBurnAllowed;

    // Recent state of token burn by future contract mechanism. Returns `true` if is allowed. `false` otherwise.
    bool public isBurnByContractAllowed;

    /**
     * @notice Public Functions.
     */

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return 
            interfaceId == type(ICollectibleBurnable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the total quantity of burned tokens in the contract.
     */
    function totalBurned() public view virtual returns (uint256) {
        return _burnCounter;
    }

    /**
     * @notice Internal Functions.
     */

    /**
     * @dev Burns ``owner``'s `tokenId` by the future contract.
     */
    function _burnTokenByContract(address owner, uint256 tokenId) internal virtual {
        // Check token burn by contract mechanism state.
        if (!isBurnByContractAllowed) revert TokenIdIsNotBurnable();
        // Check value of future contract address.
        if (futureContract == address(0)) revert InvalidFutureContract();
        // Check the caller.
        if (_msgSender() != futureContract) revert InvalidCaller();
        // Call _burnToken.
        _burnToken(owner, tokenId);
        // Emits the event.
        emit TokenIdBurnedByContract(futureContract, address(this), tokenId);
    }

    /**
     * @dev Burns ``owner``'s `tokenId`.
     */
    function _burnToken(address owner, uint256 tokenId) internal virtual {
        // Check token burn mechanism state.
        if (!isBurnAllowed) revert TokenIdIsNotBurnable();
        // Check if the caller is owner or approved.
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert InvalidOwnerOrApproved();
        // Increment burn counter.
        unchecked {
            _burnCounter++;
        }
        // Call _burn from {ERC721}.
        ERC721._burn(tokenId);
        // Emits the event.
        emit TokenIdBurned(_msgSender(), owner, address(0), tokenId);
        /// Post burn token event.
        // Assign +1 to owner for numberBurned.
        numberBurned[owner] += 1;
        // Assign `true` to `tokenId` for isTokenIdBurned.
        _isTokenIdBurned[tokenId] = true;
    }

    /**
     * @dev Base URI for computing burned {tokenURI}. 
     */
    function _baseBurnedURI() internal view virtual returns (string memory) {
        return _baseBurnedTokenURI;
    }

    /**
     * @dev See {ICollectibleBurnable-setBaseBurnedURI}.
     */
    function _setBaseBurnedURI(string memory updateBaseBurnedURI) internal virtual {
        // Update base token burned URI.
        _baseBurnedTokenURI = updateBaseBurnedURI;
        // Emits the event.
        emit BaseBurnedTokenURIUpdated(_msgSender(), updateBaseBurnedURI);
    }
    
    /**
     * @dev See {ICollectibleBurnable-setTokenBurnByContractState}.
     */
    function _setTokenBurnByContractState(bool state) internal virtual {
        // Check token burn activation state.
        if (!isBurnAllowed) {
            // Update token burn mechanism state to `true`.
            isBurnAllowed = true;
        }
        // Update state.
        isBurnByContractAllowed = state;
        // Emits the event.
        emit TokenBurnByContractState(_msgSender(), state);
    }

    /**
     * @dev See {ICollectibleBurnable-setTokenBurnState}.
     */
    function _setTokenBurnState(bool state) internal virtual {
        // Update state.
        isBurnAllowed = state;
        // Emits the event.
        emit TokenBurnState(_msgSender(), state);
    }

    /**
     * @dev See {ICollectibleBurnable-setFutureContractAddress}.
     */
    function _setFutureContractAddress(address futureContractAddress) internal virtual {
        // Check address value.
        if (!futureContractAddress.isContract()) revert InvalidAddress();
        // Update future contract address.
        futureContract = futureContractAddress;
        // Emits the event.
        emit FutureContractAddressRegistered(_msgSender(), futureContractAddress);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
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
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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

pragma solidity ^0.8.13;

/// @author [email protected]

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ICollectibleBurnable is IERC165 {
    /**
     * @notice Events to be emitted.
     */

    /**
     * @dev Emitted when `tokenId` from `targetAddress` (previous contract) is burned by `burnerAddress` (future contract).
     */
    event TokenIdBurnedByContract(address indexed burnerAddress, address indexed targetAddress, uint256 indexed tokenId);

    /**
     * @dev Emitted when `tokenId` is burned from `operator` to `to`.
     */
    event TokenIdBurned(address indexed operator, address indexed owner, address indexed to, uint256 tokenId);

    /**
     * @dev Emitted when `caller` update base URI for burned tokens of the collection.
     */
    event BaseBurnedTokenURIUpdated(address indexed caller, string updatedBaseTokenBurnedURI);

    /**
     * @dev Emitted when `caller` update state of token burn by (future) contract activation.
     */
    event TokenBurnByContractState(address indexed caller, bool state);

    /**
     * @dev Emitted when `caller` update state of token burn activation.
     */
    event TokenBurnState(address indexed caller, bool state);

    /**
     * @dev Emitted when `caller` register the future contract address.
     */
    event FutureContractAddressRegistered(address indexed caller, address indexed updatedFutureContract);

    /**
     * @dev Emitted when `caller` register the previous contract address.
     */
    event PreviousContractAddressRegistered(address indexed caller, address indexed updatedPreviousContract);

    /**
     * @notice Error handlings.
     */

    /**
     * @dev The `tokenId` is not burnable.
     */
    error TokenIdIsNotBurnable();

    /**
     * @dev The future contract has not been updated.
     */
    error InvalidFutureContract();

    /**
     * @dev The `caller` must be the registered future contract.
     */
    error InvalidCaller();

    /**
     * @dev The `owner` must be the owner or approved of the `tokenId`.
     */
    error InvalidOwnerOrApproved();

    /**
     * @dev The `to` must have at least 1 (one) `tokenId` from the previous contract.
     */
    error InvalidBalanceFromPreviousContract();

    /**
     * @dev The address value must be a contract.
     */
    error InvalidAddress();

    /**
     * @notice External functions.
     */

    /**
     * @dev Burns `tokenId` by `owner` or an approved operator.
     *
     * Requirements:
     *
     * @param owner must be the owner of the `tokenId`.
     * @param tokenId must exist and owned by `to`.
     * 
     * - Token burn state must return `true`.
     */
    function burn(address owner, uint256 tokenId) external;

    /**
     * @dev Burns `tokenId` by the future contract.
     *
     * Requirements:
     *
     * @param owner must be the owner of the `tokenId`.
     * @param tokenIdOwned must exist and owned by `to`.
     * 
     * - The caller must be an approved operator (future contract).
     * - Token burn by contract state must return `true`.
     */
    function burnByContract(address owner, uint256 tokenIdOwned) external;

    /**
     * @dev Set base URI for computing burned {tokenURI}.
     *
     * @param updateBaseBurnedURI must refer to where the base of metadata collection is located.
     */
    function setBaseBurnedURI(string memory updateBaseBurnedURI) external;

    /**
     * @dev Set token burn by contract state.
     *
     * Requirements:
     *
     * @param state is a boolean value.
     * - Set to `true` if token burn by future contract mechanism is allowed.
     * - Set to `false` if token burn by future contract mechanism is not allowed.
     */
    function setTokenBurnByContractState(bool state) external;

    /**
     * @dev Set token burn state.
     *
     * Requirements:
     *
     * @param state is a boolean value.
     * - Set to `true` if token burn mechanism is allowed.
     * - Set to `false` if token burn mechanism is not allowed.
     */
    function setTokenBurnState(bool state) external;

    /**
     * @dev Set future contract address.
     *
     * @param futureContractAddress must be a contract.
     */
    function setFutureContractAddress(address futureContractAddress) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * @title The ERC-2771 Recipient Base Abstract Class - Declarations
 *
 * @notice A contract must implement this interface in order to support relayed transaction.
 *
 * @notice It is recommended that your contract inherits from the ERC2771Recipient contract.
 */
abstract contract IERC2771Recipient {

    /**
     * :warning: **Warning** :warning: The Forwarder can have a full control over your Recipient. Only trust verified Forwarder.
     * @param forwarder The address of the Forwarder contract that is being used.
     * @return isTrustedForwarder `true` if the Forwarder is trusted to forward relayed transactions by this Recipient.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * @notice Use this method the contract anywhere instead of msg.sender to support relayed transactions.
     * @return sender The real sender of this call.
     * For a call that came through the Forwarder the real sender is extracted from the last 20 bytes of the `msg.data`.
     * Otherwise simply returns `msg.sender`.
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * @notice Use this method in the contract instead of `msg.data` when difference matters (hashing, signature, etc.)
     * @return data The real `msg.data` of this call.
     * For a call that came through the Forwarder, the real sender address was appended as the last 20 bytes
     * of the `msg.data` - so this method will strip those 20 bytes off.
     * Otherwise (if the call was made directly and not through the forwarder) simply returns `msg.data`.
     */
    function _msgData() internal virtual view returns (bytes calldata);
}