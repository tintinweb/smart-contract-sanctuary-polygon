// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
pragma solidity ^0.8.18;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }
    function hash(Part memory part) internal pure returns (bytes32){
        return keccak256(abi.encode(TYPE_HASH, part.account,  part.value));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
pragma abicoder v2;

import "./LibPart.sol";

interface RoyaltiesV2 {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory);
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//import "jarvix-solidity-utils/contracts/WhitelistUtils.sol";
import "./TokenData.sol";
import "./Royalties.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "jarvix-solidity-utils/contracts/SecurityUtils.sol";

/** Cannot mint more than max cap */
error JVX_ERC721_CapExceeded();
/** Cannot find token with given ID */
error JVX_ERC721_NonexistentToken(uint256 tokenID);
/** Cannot mint token with given ID */
error JVX_ERC721_ExistentToken(uint256 tokenID);
/** User not allowed to burn a specific token */
error JVX_ERC721_BurnNotAllowed(address user, uint256 tokenID);
/** Cannot automatically mint when mint is not ready */
error JVX_ERC721_MintIsNotReady();
error JVX_ERC721_WrongParams();
/** Cannot transfer a soul bound token */
error JVX_ERC721_Soulbound();

/**
 * @title This is the Jarvix ERC721 token contract.
 * @dev Implementation is using ERC721URIStorage as an example but does not extends it as it does not fulfill requested
 * behavior and cannot be overridden in such a way. URI storage management will be delegated to TokenDataHandler contract
 * @author tazous
 */
abstract contract BaseJarvixERC721Token is TokenDataHandlerProxy, RoyaltyImplementerProxy, ERC721Enumerable, PausableImpl
{
    /** Role definition necessary to be able to mint NFTs */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /** Role definition necessary to be able to burn NFTs */
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /** @dev Total amount of burned NFTs */
    uint256 public burnedSupply = 0;
    /** @dev NFTs max cap (maximum total supply including already burnt NFTs) */
    uint256 public immutable cap;

    /** Are the NFT soulbound tokens (ie forever linked with their minter account) or not */
    bool public immutable soulbound;

    /**
     * @dev Initializes the NTF collection contract.
     * @param name_ Name of the collection
     * @param symbol_ Symbol of the collection
     * @param cap_ Collection max cap (maximum total supply including already burnt NFTs)
     * @param soulbound_ Are the NFT soulbound tokens (ie forever linked with their minter account) or not
     * @param proxyHubAddress_ Address of the proxy hub contract that will reference following handlers for current "diamond"
     * @param dataHandlerAddress_ Address of the contract handling tokens data
     * @param royaltyHandlerAddress_ Address of the contract handling royalty data & process
     */
    constructor(string memory name_, string memory symbol_, uint256 cap_, bool soulbound_,
                address proxyHubAddress_, address dataHandlerAddress_, address royaltyHandlerAddress_)
    ERC721(name_, symbol_) ProxyDiamond(proxyHubAddress_) TokenDataHandlerProxy(dataHandlerAddress_) RoyaltyImplementerProxy(royaltyHandlerAddress_)
    {
        cap = cap_ == 0 ? type(uint256).max : cap_;
        soulbound = soulbound_;
    }

    /**
     * @dev Returns the available supply still free to mint (taking into account already burnt NFTs).
     */
    function mintableSupply() public view virtual returns (uint256)
    {
        return cap - (totalSupply() + burnedSupply);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     * Tokens start existing when they are minted (`_mint`), and stop existing when they are burned (`_burn`).
     */
    function exists(uint256 tokenID) external view returns (bool)
    {
        return _exists(tokenID);
    }
    /**
     * @dev See {IERC721Metadata-tokenURI}. Will get token URI from linked data handler
     */
    function tokenURI(uint256 tokenID) public view virtual override returns (string memory)
    {
        if(!_exists(tokenID)) revert JVX_ERC721_NonexistentToken(tokenID);
        return getTokenDataHandler().getFullTokenURI(tokenID);
    }

    /**
     * @dev This is the method to use in order to burn an NFT. Caller should be granted BURNER_ROLE or be the NFT owner
     * in order to be allowed to burn selected NFT
     * @param tokenID ID of the token about to be burnt
     */
    function burn(uint256 tokenID) external
    {
        if(!hasRole(BURNER_ROLE, _msgSender()) && _msgSender() != ownerOf(tokenID))
        {
            revert JVX_ERC721_BurnNotAllowed(_msgSender(), tokenID);
        }
        _burn(tokenID);
    }

    /**
     * @dev Redefine low-level _mint function if order to validate maximum cap
     */
    function _mint(address to, uint256 tokenID) internal virtual override
    {
        if(mintableSupply() == 0) revert JVX_ERC721_CapExceeded();
        super._mint(to, tokenID);
    }
    /**
     * @dev Redefine low-level _burn function if order to increase burnt token counter and to clear data handler from related
     * URI
     */
    function _burn(uint256 tokenID) internal virtual override
    {
        super._burn(tokenID);
        // Update state variables
        burnedSupply++;
        getTokenDataHandler().setTokenURI(tokenID, "");
    }

    /**
     * @dev Token transfer should not be available when contract is paused, and should apply royalties enforcement
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenID)
    internal virtual override whenNotPaused() onlyAllowedOperator(from)
    {
        if(soulbound && from != address(0) && to != address(0)) revert JVX_ERC721_Soulbound();
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenID);
    }

    function supportsInterface(bytes4 interfaceId)
    public view virtual override(AccessControlEnumerable, ERC721Enumerable, ProxyDiamond, RoyaltyImplementerProxy) returns (bool)
    {
        return AccessControlEnumerable.supportsInterface(interfaceId) ||
               ERC721Enumerable.supportsInterface(interfaceId) ||
               RoyaltyImplementerProxy.supportsInterface(interfaceId);
    }
}
interface IERC721Auto is IERC721
{
    function safeMint(address to, uint256 amount) external;
}
contract JarvixERC721TokenAuto is BaseJarvixERC721Token, IERC721Auto
{
    /** IERC721Auto interface ID definition */
    bytes4 public constant IERC721AutoInterfaceId = type(IERC721Auto).interfaceId;

    /** @dev Checksum of the list of initial tokens URI that can be used as a proof that everything was uploaded before
    the mint started and not changed since */
    bytes32 public immutable checksumProof4InitialTokensURI;

    /** @dev Enumerable set used to reference every NFT tokenIDs to be minted */
    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet private _tokenIDs2Mint;

    /**
     * @dev Initializes the NTF collection contract.
     * @param name_ Name of the collection
     * @param symbol_ Symbol of the collection
     * @param cap_ Collection max cap (maximum total supply including already burnt NFTs)
     * @param soulbound_ Are the NFT soulbound tokens (ie forever linked with their minter account) or not
     * @param checksumProof4InitialTokensURI_ Checksum of the list of initial tokens URI that can be used as a proof that
     * everything was uploaded before the mint started and not changed since
     * @param proxyHubAddress_ Address of the proxy hub contract that will reference following handlers for current "diamond"
     * @param dataHandlerAddress_ Address of the contract handling tokens data
     * @param royaltyHandlerAddress_ Address of the contract handling royalty data & process
     */
    constructor(string memory name_, string memory symbol_, uint256 cap_, bool soulbound_, bytes32 checksumProof4InitialTokensURI_,
                address proxyHubAddress_, address dataHandlerAddress_, address royaltyHandlerAddress_)
    BaseJarvixERC721Token(name_, symbol_, cap_, soulbound_, proxyHubAddress_, dataHandlerAddress_, royaltyHandlerAddress_)
    {
        checksumProof4InitialTokensURI = checksumProof4InitialTokensURI_;
    }

    /**
     * This is the method to use to declare tokenIDs to be automatically minted. It will revert if mint was already started
     * manually
     * @param tokenIDs ID of the tokens that will be eligible for automatic mint
     */
    function addTokenIDs2Mint(uint256[] memory tokenIDs) public onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for(uint256 i = 0 ; i < tokenIDs.length ; i++)
        {
            uint256 tokenID = tokenIDs[i];
            // Token ID already added, nothing to be done
            if(_tokenIDs2Mint.contains(tokenID)) continue;
            // Cannot add more token ID
            if(_tokenIDs2Mint.length() >= mintableSupply()) revert JVX_ERC721_CapExceeded();
            // Add token ID to the "to be minted" list
            _tokenIDs2Mint.add(tokenID);
        }
    }
    /**
     * @dev This method returns the number of ERC721 token IDs defined to be minted by this contract.
     * Can be used together with {getToken} to enumerate all token IDs defined to be minted by this contract.
     */
    function getTokenID2MintCount() public view returns (uint256)
    {
        return _tokenIDs2Mint.length();
    }
    /**
     * @dev This method returns one of the ERC721 token IDs defined to be minted by this contract.
     * `index` must be a value between 0 and {getTokenIDCount}, non-inclusive.
     * Token IDs are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getTokenID} and {getTokenIDCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getTokenID2Mint(uint256 index) public view returns (uint256)
    {
        return _tokenIDs2Mint.at(index);
    }

    /**
     * @dev This method is to be used in order to mint NFT "automatically", ie randomly chosen inside a predefined list
     * of token IDs to be minted. This list should be considered complete before the first mint
     * @param to Address of the future owner of the NFT(s) about to be randomly chosen and minted
     * @param amount Amount of NFT(s) about to be randomly chosen and minted
     */
    function safeMint(address to, uint256 amount) external onlyRole(MINTER_ROLE)
    {
        // Available NFTs total number
        uint256 nftsNb = _tokenIDs2Mint.length();
        // Not all token IDs have been added
        if(nftsNb != mintableSupply()) revert JVX_ERC721_MintIsNotReady();
        // Not any NFT requested to be minted
        if(amount == 0)  return;
        // Not enough NFT to be minted
        if(nftsNb < amount) revert JVX_ERC721_CapExceeded();
        // Mint requested NFTs
        while(amount != 0)
        {
            // Index of the NFTs to be minted 'randomly' chosen
            uint256 index = nextNFT(nftsNb - 1, nftsNb);
            // NFTs to be minted 'randomly' chosen
            uint256 tokenID = _tokenIDs2Mint.at(index);
            // Decrease counters
            nftsNb--;
            amount--;
            // Finally mint the NFT
            _safeMint(to, tokenID);
        }
    }
    /**
     * @dev Redefine low-level _mint function if order to check that the token ID is one of the defined IDs to be minted
     */
    function _mint(address to, uint256 tokenID) internal virtual override
    {
        // NFT about to be minted should be removed from the predefined list of available ones
        if(!_tokenIDs2Mint.remove(tokenID)) revert JVX_ERC721_NonexistentToken(tokenID);
        super._mint(to, tokenID);
    }

    /**
     * @dev Return next NFT index to be minted. It is based on a 'simple' random calculation function without using chainlink
     * oracle because NTF IDs should already be added randomly offchain and corresponding metadata not accessible from outside
     * before being minted so it cannot be hacked to choose a specific NFT. As reveal should be done continuously with NFT
     * mint, there is no way to determine rarity before the whole collection is released
     * @param max Maximum index to be selected (index to be selected will be between 0 and max included)
     * @param seed Seed to be used for random generation
     */
    function nextNFT(uint256 max, uint256 seed) internal view returns (uint256)
    {
        if(max <= 1)
        {
            return max;
        }
        return nextRandom(seed) % max;
    }
    /**
     * @dev Simple random calculation method. Be sure to use it in a 'safe & protected' context as solidity contracts are
     * deterministic and then can be 'hacked' in order to produce a desire response
     * see https://stackoverflow.com/questions/48848948/how-to-generate-a-random-number-in-solidity
     * @param seed Seed to be used for random generation
     */
    function nextRandom(uint256 seed) internal view returns (uint256)
    {
         // block.difficulty has be replaced by block.prevrandao during "the merge" by ethereum deployment
        return uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, msg.sender, seed)));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(BaseJarvixERC721Token, IERC165) returns (bool)
    {
        return super.supportsInterface(interfaceId) ||
               interfaceId == IERC721AutoInterfaceId;
    }
}

interface IERC721Manual is IERC721
{
    function safeMint(address[] memory to, uint256[] memory tokenIDs) external;
    function safeMintAndDefine(address[] memory to, uint256[] memory tokenIDs, string[] memory tokenURIs) external;
}
contract JarvixERC721TokenManual is BaseJarvixERC721Token, IERC721Manual
{
    /** IERC721Manual interface ID definition */
    bytes4 public constant IERC721ManualInterfaceId = type(IERC721Manual).interfaceId;

    /**
     * @dev Initializes the NTF collection contract.
     * @param name_ Name of the collection
     * @param symbol_ Symbol of the collection
     * @param cap_ Collection max cap (maximum total supply including already burnt NFTs)
     * @param soulbound_ Are the NFT soulbound tokens (ie forever linked with their minter account) or not
     * @param proxyHubAddress_ Address of the proxy hub contract that will reference following handlers for current "diamond"
     * @param dataHandlerAddress_ Address of the contract handling tokens data
     * @param royaltyHandlerAddress_ Address of the contract handling royalty data & process
     */
    constructor(string memory name_, string memory symbol_, uint256 cap_, bool soulbound_,
                address proxyHubAddress_, address dataHandlerAddress_, address royaltyHandlerAddress_)
    BaseJarvixERC721Token(name_, symbol_, cap_, soulbound_, proxyHubAddress_, dataHandlerAddress_, royaltyHandlerAddress_)
    { }

    /**
     * @dev This method is to be used to mint NFTs "manually", ie explicitly chosen by the caller.
     * @param to Addresses of the future owners of the NFTs about to be manually chosen and minted
     * @param tokenIDs IDs of the tokens about to be minted
     */
    function safeMint(address[] memory to, uint256[] memory tokenIDs) public onlyRole(MINTER_ROLE)
    {
        _safeMint(to, tokenIDs);
    }
    /**
     * @dev This method is to be used to mint NFTs "manually", ie explicitly chosen by the caller, associated to their
     * applicable URIs
     * @param to Addresses of the future owners of the NFTs about to be manually chosen and minted
     * @param tokenIDs IDs of the tokens about to be minted
     * @param tokenURIs URIs of the tokens about to be minted
     */
    function safeMintAndDefine(address[] memory to, uint256[] memory tokenIDs, string[] memory tokenURIs) public onlyRole(MINTER_ROLE)
    {
        if(to.length != tokenURIs.length) revert JVX_ERC721_WrongParams();
        getTokenDataHandler().setTokenURIs(tokenIDs, tokenURIs);
        _safeMint(to, tokenIDs);
    }
    /**
     * @dev This is the internal method used to mint NFT "manually", ie explicitly chosen by the caller
     * @param to Addresses of the future owners of the NFTs about to be manually chosen and minted
     * @param tokenIDs IDs of the tokens about to be minted
     */
    function _safeMint(address[] memory to, uint256[] memory tokenIDs) internal virtual
    {
        if(to.length != tokenIDs.length) revert JVX_ERC721_WrongParams();
        for(uint256 i = 0 ; i < to.length ; i++)
        {
            _safeMint(to[i], tokenIDs[i]);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(BaseJarvixERC721Token, IERC165) returns (bool)
    {
        return super.supportsInterface(interfaceId) ||
               interfaceId == IERC721ManualInterfaceId;
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "jarvix-solidity-utils/contracts/SecurityUtils.sol";
import "jarvix-solidity-utils/contracts/NumberUtils.sol";
// import "jarvix-solidity-utils/contracts/testlib.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
// Cannot use Rarible provided npm package as it is compiled using below 0.8.0 solidity version compliance
import "./@rarible/royalties/contracts/RoyaltiesV2.sol";
// Needed by Opensea Creator Earnings Enforcement
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION, CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "operator-filter-registry/src/lib/Constants.sol";
import "jarvix-solidity-utils/contracts/ProxyUtils.sol";


/**
 * @title  UpdatableDefaultOperatorFilterer
 * @notice Inherits from UpdatableOperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * Note that OpenSea will disable creator earnings enforcement if filtered operators begin fulfilling orders on-chain,
 * eg, if the registry is revoked or bypassed.
 */
abstract contract UpdatableDefaultOperatorFilterer is UpdatableOperatorFilterer
{
    /// @dev The constructor that is called when the contract is being deployed.
    constructor() UpdatableOperatorFilterer(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS, CANONICAL_CORI_SUBSCRIPTION, true)
    {}
}

interface IRoyalty
{
    function getRoyalty() external view returns(DecimalsType.Number_uint32 memory rate);
    function royaltyInfo(address receiver_, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
    function getRaribleV2Royalties(address receiver_) external view returns (LibPart.Part[] memory);
}

/**
 * @title This is the Jarvix royalty management contract.
 * @dev This is the contract to import/extends if you want to your NFT collection to apply royalties when an NTF is sold
 * on participating market places:
 * For Opensea, the behavior is to provided collection owner using `Ownable` and use the owner to connect onto their platform
 * and manage the collection when royalty can be defined
 * For Rarible/Mintable, implementing RoyaltiesV2/IERC2981 is requested in order to return applicable royalty rate/amount.
 * Royalty receiver will also be the owner of the contract in order to be consistent with opensea implementation
 * see: https://cryptomarketpool.com/erc721-contract-that-supports-sales-royalties/
 * @author tazous
 */
contract RoyaltyHandler is IRoyalty, AccessControlImpl
{
    /** Role definition necessary to be able to manage prices */
    bytes32 public constant PRICES_ADMIN_ROLE = keccak256("PRICES_ADMIN_ROLE");
    /** IRoyalty interface ID definition */
    bytes4 public constant IRoyaltyInterfaceId = type(IRoyalty).interfaceId;

    using DecimalsInt for uint256;
    using DecimalsInt for uint32;
    using DecimalsInt for DecimalsType.Number_uint256;
    using DecimalsInt for DecimalsType.Number_uint32;
    /** @dev Royalty rate applicable on participating market places in %, which mean that {"value":250, "decimals":2}
     * for instance should be understood as 2.5% */
    DecimalsType.Number_uint32 private _rate;

    /**
     * @dev Event emitted whenever royalty is changed
     * 'admin' Address of the administrator that changed royalty
     * 'rate' New applicable royalty rate in %, which mean that {"value":250, "decimals":2} for instance should be
     * understood as 2.5%
     */
    event RoyaltyChanged(address indexed admin, DecimalsType.Number_uint32 rate);

    /**
     * @dev Contract constructor
     * @param rate_ Royalty rate applicable on participating market places in %, which mean that {"value":250, "decimals":2}
     * for instance should be understood as 2.5%
     * @param decimals_ Royalty rate applicable decimals
     */
    constructor(uint32 rate_, uint8 decimals_)
    {
        _setRoyalty(rate_.to_uint32(decimals_));
    }

    /**
     * Getter of the royalty rate. Royalty rate is in %, which mean that if returned value is {"value":250, "decimals":2} for instance,
     * this should be understood as 2.5%
     */
    function getRoyalty() external view returns(DecimalsType.Number_uint32 memory rate)
    {
        return _rate;
    }
    /**
     * Setter of the royalty rate and applicable decimals in %, which mean that {"value":250, "decimals":2} for instance should
     * be understood as 2.5%
     */
    function setRoyalty(uint32 rate, uint8 decimals) external onlyRole(PRICES_ADMIN_ROLE)
    {
        _setRoyalty(rate.to_uint32(decimals));
    }
    /**
     * Setter of the royalty rate in %, which mean that {"value":250, "decimals":2} for instance should be understood as 2.5%
     */
    function _setRoyalty(DecimalsType.Number_uint32 memory rate) internal
    {
        if(rate.value == 0)
        {
            rate.decimals = 0;
        }
        _rate = rate;
        emit RoyaltyChanged(msg.sender, _rate);
    }
    /**
     * @dev Method derivated from the one in IERC2981 to get royalty amount and receiver for a token ID & a sale price.
     * This implementation will use defined royalty rate to apply it on given sale price whatever the token ID might be
     * (which is why it is not provided as parameter) and calculate royalty amount
     * @param receiver_ Expected receiver of the royalty
     * @param salePrice Sale price to be used to calculated royalty amount
     */
    function royaltyInfo(address receiver_, uint256 salePrice) public view returns (address receiver, uint256 royaltyAmount)
    {
        if(_rate.value == 0 || receiver_ == address(0))
        {
            return (address(0), 0);
        }
        return (receiver_, salePrice.to_uint256(0).mul(_rate.to_uint256()).div(DecimalsType.Number_uint256(100, 0), 0).value);
    }
    /**
     * @dev Method derivated from the one in RoyaltiesV2 to get applicable royalty percentage basis points and receiver
     * for a token ID. This implementation will use defined royalty rate whatever the token ID might be (which is why it
     * is not available as parameter)
     * @param receiver_ Expected receiver of the royalty
     */
    function getRaribleV2Royalties(address receiver_) public view returns (LibPart.Part[] memory royalties)
    {
        royalties = new LibPart.Part[](1);
        if(_rate.value == 0 || receiver_ == address(0))
        {
            return royalties;
        }
        royalties[0].account = payable(receiver_);
        royalties[0].value = _rate.toPrecision(2).value;
        return royalties;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)
    {
        return AccessControlEnumerable.supportsInterface(interfaceId) ||
               interfaceId == IRoyaltyInterfaceId;
    }
}

/**
 * @dev Base royalty contract external implementer, ie will externalize behavior into another contract (ie a deployed
 * RoyaltyHandler), acting as a proxy. Will declare itself as royalty manager for most participating market places:
 * 
 * For Opensea, the behavior is to provided collection owner using `Ownable` and use the owner to connect onto their platform
 * and manage the collection when royalty can be defined.
 * 
 * After 2023/01/01, OpenSea will enforce royalties management, by using RoyaltyRegistry to get royalties to be applied on an NFT,
 * and by checking that transfer is not allowed if initiated by platforms that don't apply creator's royalties on sells. That is
 * why it is mandatory for implementing contracts to block any transfer using onlyAllowedOperator modifier 
 * 
 * For Rarible/Mintable, implementing RoyaltiesV2/RoyaltiesV2 is requested in order to return applicable royalty rate/amount.
 * Royalty receiver will also be the owner of the contract in order to be consistent with opensea implementation
 * see: https://cryptomarketpool.com/erc721-contract-that-supports-sales-royalties/
 */
abstract contract RoyaltyImplementerProxy is ProxyDiamond, Ownable, IERC2981, RoyaltiesV2, UpdatableDefaultOperatorFilterer
{
    /**
     * @dev Contract constructor. For final implementers, do not forget to call ProxyDiamond constructor first in order
     * to initialize address of the ProxyHub used to reference proxies
     * @param royaltyHandlerAddress_ Address of the contract handling royalty data & process
     */
    constructor(address royaltyHandlerAddress_)
    {
        _setRoyaltyHandlerProxy(royaltyHandlerAddress_);
    }

    /**
     * Getter of the contract handling royalty data & process
     */
    function getRoyaltyHandler() internal view returns(RoyaltyHandler)
    {
        return RoyaltyHandler(getProxyAddress(type(IRoyalty).interfaceId));
    }
    /**
     * Setter of address of the contract handling royalty data & process
     */
    function _setRoyaltyHandlerProxy(address royaltyHandlerAddress_) virtual internal
    {
        _setProxy(type(IRoyalty).interfaceId, royaltyHandlerAddress_, type(IRoyalty).interfaceId, false, true, true);
    }

    /**
     * Getter of the royalty rate and applicable decimals in %, which mean that {"value":250, "decimals":2}
     * for instance should be understood as 2.5%
     */
    function getRoyalty() external view returns(DecimalsType.Number_uint32 memory)
    {
        return getRoyaltyHandler().getRoyalty();
    }
    /**
     * @dev Method from IERC2981 to get royalty amount and receiver for a token ID & a sale price. This implementation
     * will use defined royalty rate to apply it on sale price whatever the token ID is and get royalty amount. Receiver
     * will be the current owner of the contract. First parameter aka 'tokenId' is needed by IERC2981 interface inherited
     * method but meaningless in our implementation
     * @param salePrice Sale price to be used to calculated royalty amount
     */
    function royaltyInfo(uint256 , uint256 salePrice) override external view returns (address receiver, uint256 royaltyAmount)
    {
        return getRoyaltyHandler().royaltyInfo(owner(), salePrice);
    }
    /**
     * @dev Method from RoyaltiesV2 to get royalty applicable percentage basis points and receiver for a token ID. This
     * implementation will use defined royalty rate whatever the token ID is. Receiver will be the current owner of the
     * contract. First parameter aka 'tokenId' is needed by RoyaltiesV2 interface inherited method but meaningless in our
     * implementation
     */
    function getRaribleV2Royalties(uint256) override external view returns (LibPart.Part[] memory)
    {
        return getRoyaltyHandler().getRaribleV2Royalties(owner());
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ProxyDiamond, IERC165) returns (bool)
    {
        return super.supportsInterface(interfaceId) ||
               interfaceId == type(IERC2981).interfaceId || // = 0x2a55205a Interface ID for Royalties from IERC2981, 0x2a55205a=bytes4(keccak256("royaltyInfo(uint256,uint256)"))
               interfaceId == type(RoyaltiesV2).interfaceId;// = 0xcad96cca Interface ID for Royalties from Rarible RoyaltiesV2, 0xcad96cca=bytes4(keccak256("getRaribleV2Royalties(uint256)"))
    }
    
    function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address)
    {
        return Ownable.owner();
    }
}

/**
 * @dev Base royalty contract internal implementer, ie will directly extend RoyaltyHandler contract. Will declare itself as royalty
 * manager for most participating market places:
 * 
 * For Opensea, the behavior is to provided collection owner using `Ownable` and use the owner to connect onto their platform
 * and manage the collection when royalty can be defined.
 * 
 * After 2023/01/01, OpenSea will enforce royalties management, by using RoyaltyRegistry to get royalties to be applied on an NFT,
 * and by checking that transfer is not allowed if initiated by platforms that don't apply creator's royalties on sells. That is
 * why it is mandatory for implementing contracts to block any transfer using onlyAllowedOperator modifier 
 * 
 * For Rarible/Mintable, implementing RoyaltiesV2/RoyaltiesV2 is requested in order to return applicable royalty rate/amount.
 * Royalty receiver will also be the owner of the contract in order to be consistent with opensea implementation
 * see: https://cryptomarketpool.com/erc721-contract-that-supports-sales-royalties/
 */
abstract contract RoyaltyImplementerDirect is RoyaltyHandler, Ownable, IERC2981, RoyaltiesV2, UpdatableDefaultOperatorFilterer
{

    /**
     * @dev Contract constructor
     * @param rate_ Royalty rate applicable on participating market places
     * @param decimals_ Royalty rate applicable decimals
     */
    constructor(uint32 rate_, uint8 decimals_) RoyaltyHandler(rate_, decimals_)
    {
    }

    /**
     * @dev Method from IERC2981 to get royalty amount and receiver for a token ID & a sale price. This implementation
     * will use defined royalty rate to apply it on sale price whatever the token ID is and get royalty amount. Receiver
     * will be the current owner of the contract. First parameter aka 'tokenId' is needed by IERC2981 interface inherited
     * method but meaningless in our implementation
     * @param salePrice Sale price to be used to calculated royalty amount
     */
    function royaltyInfo(uint256 , uint256 salePrice) override external view returns (address receiver, uint256 royaltyAmount)
    {
        return royaltyInfo(owner(), salePrice);
    }
    /**
     * @dev Method from RoyaltiesV2 to get royalty applicable percentage basis points and receiver for a token ID. This
     * implementation will use defined royalty rate whatever the token ID is. Receiver will be the current owner of the
     * contract. First parameter aka 'tokenId' is needed by RoyaltiesV2 interface inherited method but meaningless in our
     * implementation
     */
    function getRaribleV2Royalties(uint256) override external view returns (LibPart.Part[] memory)
    {
        return getRaribleV2Royalties(owner());
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(RoyaltyHandler, IERC165) returns (bool)
    {
        return RoyaltyHandler.supportsInterface(interfaceId) ||
               interfaceId == type(IERC2981).interfaceId || // = 0x2a55205a Interface ID for Royalties from IERC2981, 0x2a55205a=bytes4(keccak256("royaltyInfo(uint256,uint256)"))
               interfaceId == type(RoyaltiesV2).interfaceId; // = 0xcad96cca Interface ID for Royalties from Rarible RoyaltiesV2, 0xcad96cca=bytes4(keccak256("getRaribleV2Royalties(uint256)"))
    }
    
    function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address)
    {
        return Ownable.owner();
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "jarvix-solidity-utils/contracts/SecurityUtils.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "jarvix-solidity-utils/contracts/ProxyUtils.sol";

interface ITokenData
{
    function getFullTokenURI(uint256 tokenID) external view returns (string memory);
    function getTokenURI(uint256 tokenID) external view returns (string memory);
    function setTokenURI(uint256 tokenID_, string memory tokenURI_) external;
    function setTokenURIs(uint256[] memory tokenIDs, string[] memory tokenURIs) external;
}

error TokenDataHandler_WrongParams();

/**
 * @title This is the Jarvix token data contract.
 * @dev This is the contract to import/extends if you want to ease your NFT collection management of its data
 * @author tazous
 */
contract TokenDataHandler is ITokenData, AccessControlImpl
{
    using Strings for uint256;

    /** Role definition necessary to be able to manage token URI policy */
    bytes32 public constant POLICY_ADMIN_ROLE = keccak256("POLICY_ADMIN_ROLE");
    /** Role definition necessary to be able to manage token data */
    bytes32 public constant DATA_ADMIN_ROLE = keccak256("DATA_ADMIN_ROLE");
    /** ITokenData interface ID definition */
    bytes4 public constant ITokenDataInterfaceId = type(ITokenData).interfaceId;

    /** @dev URI to be used as base whenever data and policy requires it */
    string private _baseURI;
    /** @dev Immutability status of a token URI */
//    mapping(uint256 => bool) private _immutability;
    /** @dev Optional mapping for token specific URIs */
    mapping(uint256 => string) private _tokenURIs;
    /** @dev Enumerable set used to reference every token ID with specific URI defined */
    using EnumerableSet for EnumerableSet.UintSet;
    EnumerableSet.UintSet private _tokenIDs;
    /** @dev Is optional token specific URI absolute or not (ie if absolute, base URI will not apply if specific URI is provided) */
    bool private _absoluteTokenURI;
    /** @dev Is token URI based on its ID if token specific URI not provided or not absolute  */
    bool private _idBasedTokenURI;

    /**
     * @dev Event emitted whenever policy for token URI is changed
     * 'admin' Address of the administrator that changed policy for token URI
     * 'baseURI' New URI to be used as base whenever data and policy requires it
     * 'absoluteTokenURI' New mapping for token specific URIs
     * 'idBasedTokenURI' New flag for token URI based on its ID or not
     */
    event Policy4TokenURIChanged(address indexed admin, string baseURI, bool absoluteTokenURI, bool idBasedTokenURI);
    /**
     * @dev Event emitted whenever one token URI is changed
     * 'admin' Address of the administrator that changed the token URI
     * 'tokenID' ID of the token for which URI as been changed
     * 'tokenURI' New URI for given token ID (unless hidden is requested to keep it protected)
     */
    event TokenURIChanged(address indexed admin, uint256 indexed tokenID, string tokenURI);

    /**
     * @dev Contract constructor
     * @param baseURI_ defines URI to be used as base whenever data and policy requires it
     * @param absoluteTokenURI_ defines if optional token specific URI is absolute or not (ie if absolute, base URI will
     * not apply if specific URI is provided)
     * @param idBasedTokenURI_ defines if token URI is based on its ID if token specific URI is not provided or not absolute
     */
    constructor(string memory baseURI_, bool absoluteTokenURI_, bool idBasedTokenURI_)
    {
        _setPolicy4TokenURI(baseURI_, absoluteTokenURI_, idBasedTokenURI_);
    }

    /**
     * @dev Get applicable token URI policy, ie a tuple (baseURI, absoluteTokenURI, idBasedTokenURI) where
     * `baseURI` is used whenever data and policy requires it
     * `absoluteTokenURI` defines if optional token specific URI is absolute or not (ie if absolute, base URI will not apply
     * if specific URI is provided)
     * `idBasedTokenURI` defines if token URI is based on its ID if token specific URI is not provided or not absolute
     */
    function getPolicy4TokenURI() external view returns (string memory baseURI, bool absoluteTokenURI, bool idBasedTokenURI)
    {
        return (_baseURI, _absoluteTokenURI, _idBasedTokenURI);
    }
    /**
     * @dev Set applicable token URI policy
     * @param baseURI_ defines URI to be used as base whenever data and policy requires it
     * @param absoluteTokenURI_ defines if optional token specific URI is absolute or not (ie if absolute, base URI will
     * not apply if specific URI is provided)
     * @param idBasedTokenURI_ defines if token URI is based on its ID if token specific URI is not provided or not absolute
     */
    function setPolicy4TokenURI(string memory baseURI_, bool absoluteTokenURI_, bool idBasedTokenURI_) external onlyRole(POLICY_ADMIN_ROLE)
    {
        _setPolicy4TokenURI(baseURI_, absoluteTokenURI_, idBasedTokenURI_);
    }
    /**
     * @dev Set applicable token URI policy
     * @param baseURI_ defines URI to be used as base whenever data and policy requires it
     * @param absoluteTokenURI_ defines if optional token specific URI is absolute or not (ie if absolute, base URI will
     * not apply if specific URI is provided)
     * @param idBasedTokenURI_ defines if token URI is based on its ID if token specific URI is not provided or not absolute
     */
    function _setPolicy4TokenURI(string memory baseURI_, bool absoluteTokenURI_, bool idBasedTokenURI_) internal
    {
        _baseURI = baseURI_;
        _absoluteTokenURI = absoluteTokenURI_;
        _idBasedTokenURI = idBasedTokenURI_;
        // Send corresponding event
        emit Policy4TokenURIChanged(msg.sender, baseURI_, absoluteTokenURI_, idBasedTokenURI_);
    }

    /**
     * @dev Get applicable base URI for given token ID. Will apply token URI policy regarding ID based URI for returned
     * value calculation
     * @param tokenID Token ID for which to get applicable base URI
     */
    function _getBaseURI(uint256 tokenID) internal view returns (string memory)
    {
        // No need to complete base URI with token ID
        if(!_idBasedTokenURI || bytes(_baseURI).length == 0)
        {
            return _baseURI;
        }
        // Complete base URI with token ID
        return string(abi.encodePacked(_baseURI, tokenID.toString()));
    }
    /**
     * Get applicable full URI for given token ID. Will apply full token URI policy for its calculation ie :
     * - If there is no specific token URI, return default base URI behavior
     * - If specific token URI is set AND (Token URI is absolute OR there is no base URI), return the specific token URI.
     * - Otherwise build the full token URI using base URI, token ID if policy require it AND token specific URI
     * @param tokenID ID of the token for which to get the full URI
     */
    function getFullTokenURI(uint256 tokenID) public virtual view returns (string memory)
    {
        string memory tokenURI_ = _tokenURIs[tokenID];
        // If there is no specific token URI, return default base URI behavior
        if(bytes(tokenURI_).length == 0)
        {
            // Apply chosen behavior (Should Token ID be used when building URI or not)
            return _getBaseURI(tokenID);
        }
        // If specific token URI is set, apply chosen behavior
        // 1 - Token URI is absolute OR there is no base URI, return the specific token URI.
        if(_absoluteTokenURI || bytes(_baseURI).length == 0)
        {
            return tokenURI_;
        }
        // 2 - Token URI is NOT absolute when provided AND there is a base URI, apply chosen behavior (Should Token ID be
        // used when building URI or not)
        return string(abi.encodePacked(_getBaseURI(tokenID), tokenURI_));
    }
    /**
     * Get applicable specific URI for given token ID. Depending on policy, should be computed with base URI and token ID
     * to build the full token URI
     * @param tokenID ID of the token for which to get the specific URI
     */
    function getTokenURI(uint256 tokenID) external virtual view returns (string memory)
    {
        return _tokenURIs[tokenID];
    }
    /**
     * Set applicable specific URI for given token ID. Depending on policy, it will have to be computed with base URI and
     * token ID to build the full token URI
     * @param tokenID_ ID of the token for which to set the specific URI
     * @param tokenURI_ New specific URI for given token ID
     */
    function setTokenURI(uint256 tokenID_, string memory tokenURI_) external onlyRole(DATA_ADMIN_ROLE)
    {
        _setTokenURI(tokenID_, tokenURI_);
    }
    /**
     * Set applicable specific URIs for given token IDs. Depending on policy, it will have to be computed with base URI
     * and token IDs to build the full token URIs
     * @param tokenIDs IDs of the tokens for which to set the specific URIs
     * @param tokenURIs New specific URIs for given tokens ID
     */
    function setTokenURIs(uint256[] memory tokenIDs, string[] memory tokenURIs) external onlyRole(DATA_ADMIN_ROLE)
    {
        if(tokenIDs.length != tokenURIs.length) revert TokenDataHandler_WrongParams();
        for(uint256 i = 0 ; i < tokenIDs.length ; i++)
        {
            _setTokenURI(tokenIDs[i], tokenURIs[i]);
        }
    }
    /**
     * Set applicable specific URI for given token ID. Depending on policy, it will have to be computed with base URI and
     * token ID to build the full token URI
     * @param tokenID_ ID of the token for which to set the specific URI
     * @param tokenURI_ New specific URI for given token ID
     */
    function _setTokenURI(uint256 tokenID_, string memory tokenURI_) internal
    {
        // No token URI update
        if(keccak256(abi.encodePacked(tokenURI_)) == keccak256(abi.encodePacked(_tokenURIs[tokenID_])))
        {
            return;
        }
        // Token should not have any specific URI anymore
        if(bytes(tokenURI_).length == 0)
        {
            // Remove any previous specific URI reference
            delete _tokenURIs[tokenID_];
            _tokenIDs.remove(tokenID_);
        }
        // Define new specific URI
        else
        {
            _tokenURIs[tokenID_] = tokenURI_;
            _tokenIDs.add(tokenID_);
        }
        // Send corresponding event
        emit TokenURIChanged(msg.sender, tokenID_, tokenURI_);
    }

    /**
     * Get the number of token IDs for which specific URI is defined
     */
    function getTokenIDCount() external view returns (uint256)
    {
        return _tokenIDs.length();
    }
    /**
     * Get the token ID for which specific URI is defined at given index
     * @param index Index of the token ID for which specific URI is defined
     */
    function getTokenID(uint256 index) external view returns (uint256)
    {
        return _tokenIDs.at(index);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)
    {
        return super.supportsInterface(interfaceId) ||
               interfaceId == ITokenDataInterfaceId;
    }
}

/**
 * @dev Base token data proxy implementation, ie will externalize behavior into another contract (ie a deployed TokenDataHandler),
 * acting as a proxy
 */
abstract contract TokenDataHandlerProxy is ProxyDiamond
{
    /**
     * @dev Contract constructor. For final implementers, do not forget to call ProxyDiamond constructor first in order
     * to initialize address of the proxy hub used to reference proxies
     * @param tokenDataHandlerAddress_ Address of the contract handling token data & process
     */
    constructor(address tokenDataHandlerAddress_)
    {
        _setTokenDataHandlerProxy(tokenDataHandlerAddress_);
    }

    /**
     * Getter of the contract handling token data & process
     */
    function getTokenDataHandler() internal view returns(TokenDataHandler)
    {
        return TokenDataHandler(getProxyAddress(type(ITokenData).interfaceId));
    }
    function _setTokenDataHandlerProxy(address tokenDataHandlerAddress_) virtual internal
    {
        _setProxy(type(ITokenData).interfaceId, tokenDataHandlerAddress_, type(ITokenData).interfaceId, false, true, true);
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./JarvixERC721Token.sol";
import "jarvix-solidity-utils/contracts/SecuredComplex.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Definition of a process that can be secured through token gated mechanism
 */
interface ITokenGated
{
    struct Gate
    {
        bytes4 name;
        address tokenAddress;
    }

    function getGate(bytes4 whitelistName) external view returns (Gate memory);
    function createGate(bytes4 whitelistName, address tokenAddress) external;
    function updateGate(bytes4 whitelistName, address tokenAddress) external;
}

abstract contract BaseTokenGated is BaseWhitelistHandler, ITokenGated
{
    /** ITokenGated interface ID definition */
    bytes4 public constant ITokenGatedInterfaceId = type(ITokenGated).interfaceId;

    function getGate(bytes4 whitelistName) public view returns (Gate memory)
    {
        return _toGate(getWhitelist(whitelistName));
    }
    function _toGate(Whitelist memory whitelist) internal pure returns (Gate memory)
    {
        return Gate(whitelist.name, address(bytes20(whitelist.whitelisterRole)));
    }
    /**
     * @dev This method is the entrypoint to create a new gate definition. User should be granted WL_ADMIN_ROLE role
     * in order to use it. Will revert if a whitelist with exact same name is already defined or if provided address
     * does not correspond to a token contract
     * @param whitelistName Name of the gate protected whitelist to be created
     * @param tokenAddress TODO
     */
    function createGate(bytes4 whitelistName, address tokenAddress) external onlyRole(WL_ADMIN_ROLE)
    {
        _createWhitelist(whitelistName, bytes20(tokenAddress));
    }
    function updateGate(bytes4 whitelistName, address tokenAddress) external onlyRole(WL_ADMIN_ROLE)
    {
        _updateWhitelist(whitelistName, bytes20(tokenAddress));
    }

    function isWhitelisted(address address_, bytes4 whitelistName, bytes memory additionalData) public view virtual override
    returns (bool whitelisted, Whitelist memory whitelistDef)
    {
        whitelistDef = getWhitelist(whitelistName);
        address tokenAddress = _toGate(whitelistDef).tokenAddress;
        if(additionalData.length == 0)
        {
            whitelisted = IERC721(tokenAddress).balanceOf(address_) > 0;
        }
        else
        {
            (uint256 tokenID) = abi.decode(additionalData, (uint256));
            whitelisted = IERC721(tokenAddress).ownerOf(tokenID) == address_;
        }
    }
    function _setWhitelisted(address[] memory, bytes4[] memory, bytes[] memory, bool) internal view virtual override
    returns (bool[] memory whitelisted, Whitelist[] memory whitelistDef)
    {
        // Make it fail "nicely". If explicitly reverted, a warning "Unreachable code" would be launched at compilation because _setWhitelisted
        // for single address is using it and would then always revert without reaching its end. Attempts of overriding both functions were
        // made without any success
        _checkRole(0x0, address(0x0));
        whitelisted = new bool[](0);
        whitelistDef = new Whitelist[](0);
    }
    function getWhitelistedCount(bytes4 whitelistName) public view virtual override returns (uint256)
    {
        if(!hasWhitelist(whitelistName))
        {
            return 0;
        }
        return IERC721Enumerable(_toGate(getWhitelist(whitelistName)).tokenAddress).totalSupply();
    }
    function getWhitelistedAt(bytes4 whitelistName, uint256 index) public view virtual onlyRole(WL_ADMIN_ROLE) returns (address)
    {
        IERC721Enumerable erc721 = IERC721Enumerable(_toGate(getWhitelist(whitelistName)).tokenAddress);
        return erc721.ownerOf(erc721.tokenByIndex(index));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)
    {
        return super.supportsInterface(interfaceId) ||
               interfaceId == ITokenGatedInterfaceId;
    }
}
abstract contract BaseTokenGatedAllowance is BaseTokenGated, BaseWhitelistedAllowance
{
    function checkProcess(bytes4 name, address address_, uint256 amount, bytes memory data2Process) public view virtual override(BaseWhitelistedAllowance, BaseWhitelistHandler)
    {
        BaseWhitelistedAllowance.checkProcess(name, address_, amount, data2Process);
    }
    function doProcess(bytes4 name, address address_, uint256 amount, bytes memory data2Process) public virtual override(BaseWhitelistedAllowance, BaseWhitelistHandler)
    {
        BaseWhitelistedAllowance.doProcess(name, address_, amount, data2Process);
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(BaseTokenGated, BaseWhitelistedAllowance) returns (bool)
    {
        return BaseTokenGated.supportsInterface(interfaceId) ||
               BaseWhitelistedAllowance.supportsInterface(interfaceId);
    }
}

contract TokenGatedHandler is BaseTokenGated, WhitelistHandler
{
    function hasWhitelist(bytes4 name) public view override(BaseWhitelistHandler, WhitelistHandler) returns (bool)
    {
        return WhitelistHandler.hasWhitelist(name);
    }
    function getWhitelist(bytes4 name) public view override(BaseWhitelistHandler, WhitelistHandler) returns (Whitelist memory)
    {
        return WhitelistHandler.getWhitelist(name);
    }
    function isWhitelisted(address address_, bytes4 whitelistName, bytes memory additionalData) public view override(BaseTokenGated, WhitelistHandler)
    returns (bool whitelisted, Whitelist memory whitelistDef)
    {
        return BaseTokenGated.isWhitelisted(address_, whitelistName, additionalData);
    }
    function _setWhitelisted(address[] memory addresses, bytes4[] memory whitelistNames, bytes[] memory additionalData, bool doWhitelist) internal view override(BaseTokenGated, WhitelistHandler)
    returns (bool[] memory whitelisted, Whitelist[] memory whitelistDef)
    {
        return BaseTokenGated._setWhitelisted(addresses, whitelistNames, additionalData, doWhitelist);
    }

    function getWhitelistedCount(bytes4 whitelistName) public view override(BaseTokenGated, WhitelistHandler) returns (uint256)
    {
        return BaseTokenGated.getWhitelistedCount(whitelistName);
    }
    function getWhitelistedAt(bytes4 whitelistName, uint256 index) public view override(BaseTokenGated, WhitelistHandler) returns (address)
    {
        return BaseTokenGated.getWhitelistedAt(whitelistName, index);
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(BaseTokenGated, BaseWhitelistHandler) returns (bool)
    {
        return BaseWhitelistHandler.supportsInterface(interfaceId) ||
               BaseTokenGated.supportsInterface(interfaceId);
    }
}

contract TokenGatedAllowanceHandler is BaseTokenGatedAllowance, WhitelistedAllowanceHandler
{
    function hasWhitelist(bytes4 name) public view override(BaseWhitelistHandler, WhitelistHandler) returns (bool)
    {
        return WhitelistHandler.hasWhitelist(name);
    }
    function getWhitelist(bytes4 name) public view override(BaseWhitelistHandler, WhitelistHandler) returns (Whitelist memory)
    {
        return WhitelistHandler.getWhitelist(name);
    }
    function isWhitelisted(address address_, bytes4 whitelistName, bytes memory additionalData) public view override(BaseTokenGated, WhitelistHandler, BaseWhitelistHandler)
    returns (bool whitelisted, Whitelist memory whitelistDef)
    {
        return BaseTokenGated.isWhitelisted(address_, whitelistName, additionalData);
    }
    function _setWhitelisted(address[] memory addresses, bytes4[] memory whitelistNames, bytes[] memory additionalData, bool doWhitelist) internal view override(BaseTokenGated, BaseWhitelistHandler, WhitelistHandler)
    returns (bool[] memory whitelisted, Whitelist[] memory whitelistDef)
    {
        return BaseTokenGated._setWhitelisted(addresses, whitelistNames, additionalData, doWhitelist);
    }
    function getWhitelistedCount(bytes4 whitelistName) public view override(BaseTokenGated, WhitelistHandler, IWhitelist) returns (uint256)
    {
        return BaseTokenGated.getWhitelistedCount(whitelistName);
    }
    function getWhitelistedAt(bytes4 whitelistName, uint256 index) public view override(BaseTokenGated, WhitelistHandler) returns (address)
    {
        return BaseTokenGated.getWhitelistedAt(whitelistName, index);
    }
    
    function _findAllowance(address, bytes4 bucketName, bytes memory additionalData) internal view override returns (uint256 allowance)
    {
        (uint256 tokenID) = abi.decode(additionalData, (uint256));
        allowance = super._findAllowance(address(bytes20(uint160(tokenID))), bucketName, additionalData);
    }
    function _setAllowance(address, bytes4 bucketName, bytes memory additionalData, uint256 allowance) internal override
    {
        (uint256 tokenID) = abi.decode(additionalData, (uint256));
        super._setAllowance(address(bytes20(uint160(tokenID))), bucketName, additionalData, allowance);
    }
    function _addOrUseAllowance(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData, bool add) internal override(WhitelistedAllowanceHandler, BaseWhitelistedAllowance)
    returns (uint256 allowance, Bucket memory bucket)
    {
        return WhitelistedAllowanceHandler._addOrUseAllowance(address_, bucketName, amount, additionalData, add);
    }

    function checkProcess(bytes4 name, address address_, uint256 amount, bytes memory data2Process) public view virtual override(BaseTokenGatedAllowance, WhitelistedAllowanceHandler)
    {
        BaseTokenGatedAllowance.checkProcess(name, address_, amount, data2Process);
    }
    function doProcess(bytes4 name, address address_, uint256 amount, bytes memory data2Process) public virtual override(BaseTokenGatedAllowance, WhitelistedAllowanceHandler)
    {
        BaseTokenGatedAllowance.doProcess(name, address_, amount, data2Process);
    }
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(BaseTokenGatedAllowance, WhitelistedAllowanceHandler) returns (bool)
    {
        return BaseTokenGatedAllowance.supportsInterface(interfaceId) ||
               WhitelistedAllowanceHandler.supportsInterface(interfaceId);
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Interface that lists decimals types definitions.
 * @author tazous
 */
library DecimalsType
{
    /**
     * @dev Decimal number structure, based on a uint256 value and its applicable decimals number
     */
    struct Number_uint256
    {
        uint256 value;
        uint8 decimals;
    }
    /**
     * @dev Decimal number structure, based on a uint32 value and its applicable decimals number
     */
    struct Number_uint32
    {
        uint32 value;
        uint8 decimals;
    }
}

/**
 * @title Decimals library to be used internally by contracts.
 * @author tazous
 */
library DecimalsInt
{

    function to_uint32(uint32 value, uint8 decimals) internal pure returns(DecimalsType.Number_uint32 memory)
    {
        return DecimalsType.Number_uint32(value, decimals);
    }
    function to_uint32(DecimalsType.Number_uint32 memory number) internal pure returns(DecimalsType.Number_uint32 memory)
    {
        return DecimalsType.Number_uint32(number.value, number.decimals);
    }
    function to_uint32(DecimalsType.Number_uint256 memory number) internal pure returns(DecimalsType.Number_uint32 memory)
    {
        return DecimalsType.Number_uint32(uint32(number.value), number.decimals);
    }
    function to_uint256(uint256 value, uint8 decimals) internal pure returns(DecimalsType.Number_uint256 memory)
    {
        return DecimalsType.Number_uint256(value, decimals);
    }
    function to_uint256(DecimalsType.Number_uint32 memory number) internal pure returns(DecimalsType.Number_uint256 memory)
    {
        return DecimalsType.Number_uint256(number.value, number.decimals);
    }
    function to_uint256(DecimalsType.Number_uint256 memory number) internal pure returns(DecimalsType.Number_uint256 memory)
    {
        return DecimalsType.Number_uint256(number.value, number.decimals);
    }

    function round(DecimalsType.Number_uint256 memory number, uint8 precision) internal pure returns(DecimalsType.Number_uint256 memory)
    {
        if(number.decimals > precision)
        {
            number.value = number.value / 10**(number.decimals - precision);
            number.decimals = precision;
        }
        return number;
    }
    function round(DecimalsType.Number_uint32 memory number, uint8 precision) internal pure returns(DecimalsType.Number_uint32 memory)
    {
        return to_uint32(round(to_uint256(number), precision));
    }
    function toPrecision(DecimalsType.Number_uint256 memory number, uint8 precision) internal pure returns(DecimalsType.Number_uint256 memory)
    {
        if(number.decimals < precision)
        {
            number.value = number.value * 10**(precision - number.decimals);
            number.decimals = precision;
        }
        else if(number.decimals > precision)
        {
            number = round(number, precision);
        }
        return number;
    }
    function toPrecision(DecimalsType.Number_uint32 memory number, uint8 precision) internal pure returns(DecimalsType.Number_uint32 memory)
    {
        return to_uint32(toPrecision(to_uint256(number), precision));
    }

    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros(DecimalsType.Number_uint256 memory number) internal pure returns(DecimalsType.Number_uint256 memory)
    {
        if(number.value == 0)
        {
            return to_uint256(0, 0);
        }
        while(number.decimals > 0 && number.value % 10 == 0)
        {
            number.decimals--;
            number.value = number.value/10;
        }
        return number;
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros(DecimalsType.Number_uint32 memory number) internal pure returns(DecimalsType.Number_uint32 memory)
    {
        return to_uint32(cleanFromTrailingZeros(to_uint256(number)));
    }

    function alignDecimals(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2) internal pure
    returns(DecimalsType.Number_uint256 memory result1, DecimalsType.Number_uint256 memory result2)
    {
        // First reduce values while they both have trailing zeros
        while(number1.decimals > 0 && number1.value % 10 == 0 && number2.decimals > 0 && number2.value % 10 == 0)
        {
            number1.decimals--;
            number1.value = number1.value/10;
            number2.decimals--;
            number2.value = number2.value/10;
        }
        // Then reduce decimals nb if one has trailing zeros and more decimals than the other
        while(number1.decimals > 0 && number1.value % 10 == 0 && number1.decimals > number2.decimals)
        {
            number1.decimals--;
            number1.value = number1.value/10;
        }
        while(number2.decimals > 0 && number2.value % 10 == 0 && number2.decimals > number1.decimals)
        {
            number2.decimals--;
            number2.value = number2.value/10;
        }
        // Finally add decimals to the one that as the least
        if(number1.decimals < number2.decimals)
        {
            number1 = toPrecision(number1, number2.decimals);
        }
        else if(number2.decimals < number1.decimals)
        {
            number2 = toPrecision(number2, number1.decimals);
        }
        return (number1, number2);
    }
    function alignDecimals(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2) internal pure
    returns(DecimalsType.Number_uint32 memory result1, DecimalsType.Number_uint32 memory result2)
    {
        (DecimalsType.Number_uint256 memory result1_, DecimalsType.Number_uint256 memory result2_) = alignDecimals(to_uint256(number1), to_uint256(number2));
        return (to_uint32(result1_), to_uint32(result2_));
    }

    function add(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2) internal pure
    returns(DecimalsType.Number_uint256 memory)
    {
        (number1, number2) = alignDecimals(number1, number2);
        return cleanFromTrailingZeros(to_uint256(number1.value+number2.value, number1.decimals));
    }
    function add(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2) internal pure
    returns(DecimalsType.Number_uint32 memory)
    {
        (number1, number2) = alignDecimals(number1, number2);
        return cleanFromTrailingZeros(to_uint32(number1.value+number2.value, number1.decimals));
    }
    function sub(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2) internal pure
    returns(DecimalsType.Number_uint256 memory)
    {
        (number1, number2) = alignDecimals(number1, number2);
        return cleanFromTrailingZeros(to_uint256(number1.value-number2.value, number1.decimals));
    }
    function sub(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2) internal pure
    returns(DecimalsType.Number_uint32 memory)
    {
        (number1, number2) = alignDecimals(number1, number2);
        return cleanFromTrailingZeros(to_uint32(number1.value-number2.value, number1.decimals));
    }
    function mul(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2) internal pure
    returns(DecimalsType.Number_uint256 memory)
    {
        number1 = cleanFromTrailingZeros(number1);
        number2 = cleanFromTrailingZeros(number2);
        return cleanFromTrailingZeros(to_uint256(number1.value*number2.value, number1.decimals+number2.decimals));
    }
    function mul(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2) internal pure
    returns(DecimalsType.Number_uint32 memory)
    {
        number1 = cleanFromTrailingZeros(number1);
        number2 = cleanFromTrailingZeros(number2);
        return cleanFromTrailingZeros(to_uint32(number1.value*number2.value, number1.decimals+number2.decimals));
    }
    
    function div(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2, uint8 precision) internal pure
    returns(DecimalsType.Number_uint256 memory)
    {
        (number1, number2) = alignDecimals(number1, number2);
        uint256 result = number1.value / number2.value;
        uint8 decimals = 0;
        uint256 mod = number1.value % number2.value;
        while(mod != 0 && decimals < precision)
        {
            result = result * 10;
            mod = mod * 10;
            decimals++;
            result+= mod/number2.value;
            mod = mod % number2.value;
        }
        return cleanFromTrailingZeros(to_uint256(result, decimals));
    }
    function div(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2, uint8 precision) internal pure
    returns(DecimalsType.Number_uint32 memory)
    {
        return to_uint32(div(to_uint256(number1), to_uint256(number2), precision));
    }
}
/**
 * @title Decimals library to be linked externally by contracts.
 * @author tazous
 */
library DecimalsExt
{
    using DecimalsInt for uint256;
    using DecimalsInt for uint32;
    using DecimalsInt for DecimalsType.Number_uint256;
    using DecimalsInt for DecimalsType.Number_uint32;

    function to_uint32(uint32 value, uint8 decimals) external pure returns(DecimalsType.Number_uint32 memory)
    {
        return value.to_uint32(decimals);
    }
    function to_uint32(DecimalsType.Number_uint32 memory number) external pure returns(DecimalsType.Number_uint32 memory)
    {
        return number.to_uint32();
    }
    function to_uint32(DecimalsType.Number_uint256 memory number) external pure returns(DecimalsType.Number_uint32 memory)
    {
        return number.to_uint32();
    }
    function to_uint256(uint256 value, uint8 decimals) external pure returns(DecimalsType.Number_uint256 memory)
    {
        return value.to_uint256(decimals);
    }
    function to_uint256(DecimalsType.Number_uint32 memory number) external pure returns(DecimalsType.Number_uint256 memory)
    {
        return number.to_uint256();
    }
    function to_uint256(DecimalsType.Number_uint256 memory number) external pure returns(DecimalsType.Number_uint256 memory)
    {
        return number.to_uint256();
    }

    function round(DecimalsType.Number_uint256 memory number, uint8 precision) external pure returns(DecimalsType.Number_uint256 memory)
    {
        return number.round(precision);
    }
    function round(DecimalsType.Number_uint32 memory number, uint8 precision) external pure returns(DecimalsType.Number_uint32 memory)
    {
        return number.round(precision);
    }
    function toPrecision(DecimalsType.Number_uint256 memory number, uint8 precision) external pure returns(DecimalsType.Number_uint256 memory)
    {
        return number.toPrecision(precision);
    }
    function toPrecision(DecimalsType.Number_uint32 memory number, uint8 precision) external pure returns(DecimalsType.Number_uint32 memory)
    {
        return number.toPrecision(precision);
    }

    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros(DecimalsType.Number_uint256 memory number) external pure returns(DecimalsType.Number_uint256 memory)
    {
        return number.cleanFromTrailingZeros();
    }
    /**
     * @dev Utility methods that allows to clean unnecessary trailing zeros to reduce size of values
     */
    function cleanFromTrailingZeros(DecimalsType.Number_uint32 memory number) external pure returns(DecimalsType.Number_uint32 memory)
    {
        return number.cleanFromTrailingZeros();
    }

    function alignDecimals(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2) external pure
    returns(DecimalsType.Number_uint256 memory result1, DecimalsType.Number_uint256 memory result2)
    {
        return number1.alignDecimals(number2);
    }
    function alignDecimals(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2) external pure
    returns(DecimalsType.Number_uint32 memory result1, DecimalsType.Number_uint32 memory result2)
    {
        return number1.alignDecimals(number2);
    }

    function add(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2) external pure
    returns(DecimalsType.Number_uint256 memory)
    {
        return number1.add(number2);
    }
    function add(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2) external pure
    returns(DecimalsType.Number_uint32 memory)
    {
        return number1.add(number2);
    }
    function sub(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2) external pure
    returns(DecimalsType.Number_uint256 memory)
    {
        return number1.sub(number2);
    }
    function sub(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2) external pure
    returns(DecimalsType.Number_uint32 memory)
    {
        return number1.sub(number2);
    }
    function mul(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2) external pure
    returns(DecimalsType.Number_uint256 memory)
    {
        return number1.mul(number2);
    }
    function mul(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2) external pure
    returns(DecimalsType.Number_uint32 memory)
    {
        return number1.mul(number2);
    }
    
    function div(DecimalsType.Number_uint256 memory number1, DecimalsType.Number_uint256 memory number2, uint8 precision) external pure
    returns(DecimalsType.Number_uint256 memory)
    {
        return number1.div(number2, precision);
    }
    function div(DecimalsType.Number_uint32 memory number1, DecimalsType.Number_uint32 memory number2, uint8 precision) external pure
    returns(DecimalsType.Number_uint32 memory)
    {
        return number1.div(number2, precision);
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./SecurityUtils.sol";

error ProxyHub_ContractIsNull();
error ProxyHub_ContractIsInvalid(bytes4 interfaceId);
error ProxyHub_KeyNotDefined(address user, bytes4 key);
error ProxyHub_NotUpdatable();
error ProxyHub_NotAdminable();
error ProxyHub_CanOnlyBeRestricted();
error ProxyHub_CanOnlyBeAdminableIfUpdatable();

/**
 * @dev As solidity contracts are size limited, and in order to ease modularity and potential upgrades, contracts could/should
 * be divided into smaller contracts in charge of specific functional processes. Links between those contracts and their "users"
 * can be seen as 'proxies', a way to call and delegate part of a treatment. Instead of having every user contract referencing
 * and managing links to those proxies, this part has been delegated to following ProxyHub. User contract might then declare
 * themselves as ProxyDiamond to easily store and access their own proxies
 */
contract ProxyHub is PausableImpl
{
    struct ProxyEntry
    {
        address user;
        bytes4 key;
    }
    /**
     * @dev Proxy definition data structure
     * 'proxyAddress' Address of the proxied contract
     * 'interfaceId' ID of the interface the proxied contract should comply to (ERC165)
     * 'nullable' Can the proxied address be null
     * 'updatable' Can the proxied address be updated by its user
     * 'adminable' Can the proxied address be updated by a proxy hub administrator
     * 'adminRole' Role that proxy hub administrator should be granted if adminable is activated
     */
    struct Proxy
    {
        address proxyAddress;
        bytes4 interfaceId;
        bool nullable;
        bool updatable;
        bool adminable;
        bytes32 adminRole;
    }
    /** @dev Proxies defined for users on keys */
    mapping(address => mapping(bytes4 => Proxy)) private _proxies;
    /** @dev Enumerable set used to reference every defined users */
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _users;
    /** @dev Enumerable sets used to reference every defined keys by users */
    using EnumerableSet for EnumerableSet.Bytes32Set;
    mapping(address => EnumerableSet.Bytes32Set) private _keys;

    /**
     * @dev Event emitted whenever a proxy is defined
     * 'admin' Address of the administrator that defined the proxied contract (will be the user if directly managed)
     * 'user' Address of the of the user for which a proxy was defined
     * 'key' Key by which the proxy was defined and referenced
     * 'proxyAddress' Address of the proxied contract
     * 'nullable' Can the proxied address be null
     * 'updatable' Can the proxied address be updated by its user
     * 'adminable' Can the proxied address be updated by a proxy hub administrator
     * 'adminRole' Role that proxy hub administrator should be granted if adminable is activated
     */
    event ProxyDefined(address indexed admin, address indexed user, bytes4 indexed key, address proxyAddress,
                       bytes4 interfaceId, bool nullable, bool updatable, bool adminable, bytes32 adminRole);

    /**
     * @dev Default constructor
     */
    constructor() {}

    /**
     * @dev Search for the existing proxy defined by given user on provided key
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by given user on provided key
     */
    function findProxyFor(address user, bytes4 key) public view returns (Proxy memory)
    {
        return _proxies[user][key];
    }
    /**
     * @dev Search for the existing proxy defined by caller on provided key
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by caller on provided key
     */
    function findProxy(bytes4 key) public view returns (Proxy memory)
    {
        return findProxyFor(msg.sender, key);
    }
    /**
     * @dev Search for the existing proxy address defined by given user on provided key
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by given user on provided key
     */
    function findProxyAddressFor(address user, bytes4 key) external view returns (address)
    {
        return findProxyFor(user, key).proxyAddress;
    }
    /**
     * @dev Search for the existing proxy address defined by caller on provided key
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by caller on provided key
     */
    function findProxyAddress(bytes4 key) external view returns (address)
    {
        return findProxy(key).proxyAddress;
    }
    /**
     * @dev Search if proxy has been defined by given user on provided key
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return True if proxy has been defined by given user on provided key, false otherwise
     */
    function isKeyDefinedFor(address user, bytes4 key) public view returns (bool)
    {
        // A proxy can have only been initialized whether with a null address AND nullable value set to true OR a not null
        // address (When a structure has not yet been initialized, all boolean value are false)
        return _proxies[user][key].proxyAddress != address(0) || _proxies[user][key].nullable;
    }
    /**
     * @dev Check if proxy has been defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined if not
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     */
    function checkKeyIsDefinedFor(address user, bytes4 key) internal view
    {
        if(!isKeyDefinedFor(user, key)) revert ProxyHub_KeyNotDefined(user, key);
    }
    /**
     * @dev Get the existing proxy defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined if not
     * found
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by given user on provided key
     */
    function getProxyFor(address user, bytes4 key) public view returns (Proxy memory)
    {
        checkKeyIsDefinedFor(user, key);
        return _proxies[user][key];
    }
    /**
     * @dev Get the existing proxy defined by caller on provided key. Will revert with ProxyHub_KeyNotDefined if not found
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy defined by caller on provided key
     */
    function getProxy(bytes4 key) public view returns (Proxy memory)
    {
        return getProxyFor(msg.sender, key);
    }
    /**
     * @dev Get the existing proxy address defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined
     * if not found
     * @param user User that should have defined the proxy being searched for
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by given user on provided key
     */
    function getProxyAddressFor(address user, bytes4 key) public view returns (address)
    {
        return getProxyFor(user, key).proxyAddress;
    }
    /**
     * @dev Get the existing proxy address defined by caller on provided key. Will revert with ProxyHub_KeyNotDefined if
     * not found
     * @param key Key by which the proxy being searched for should have been defined
     * @return Found existing proxy address defined by caller on provided key
     */
    function getProxyAddress(bytes4 key) external view virtual returns (address)
    {
        return getProxy(key).proxyAddress;
    }

    /**
     * @dev Set already existing proxy defined by given user on provided key. Will revert with ProxyHub_KeyNotDefined if
     * not found, with ProxyHub_NotAdminable if not allowed to be modified by administrator, with ProxyHub_CanOnlyBeRestricted
     * if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull when given address is null
     * and null not allowed
     * @param user User that should have defined the proxy being modified
     * @param key Key by which the proxy being modified should have been defined
     * @param proxyAddress Address of the proxy being defined
     * @param interfaceId ID of the interface the proxy being defined should comply to (ERC165)
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     */
    function setProxyFor(address user, bytes4 key, address proxyAddress, bytes4 interfaceId,
                         bool nullable, bool updatable, bool adminable) public
    {
        _setProxy(msg.sender, user, key, proxyAddress, interfaceId, nullable, updatable, adminable, DEFAULT_ADMIN_ROLE);
    }
    /**
     * @dev Define proxy for caller on provided key. Will revert with ProxyHub_NotUpdatable if not allowed to be modified,
     * with ProxyHub_CanOnlyBeRestricted if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull
     * when given address is null and null not allowed
     * @param key Key by which the proxy should be defined for the caller
     * @param proxyAddress Address of the proxy being defined
     * @param interfaceId ID of the interface the proxy being defined should comply to (ERC165)
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     * @param adminRole Role that proxy hub administrator should be granted if adminable is activated
     */
    function setProxy(bytes4 key, address proxyAddress, bytes4 interfaceId,
                      bool nullable, bool updatable, bool adminable, bytes32 adminRole) external
    {
        _setProxy(msg.sender, msg.sender, key, proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
    }

    function _setProxy(address admin, address user, bytes4 key, address proxyAddress, bytes4 interfaceId,
                       bool nullable, bool updatable, bool adminable, bytes32 adminRole) internal whenNotPaused()
    {
        if(!updatable && adminable) revert ProxyHub_CanOnlyBeAdminableIfUpdatable();
        // Check if we are in update mode and perform updatability validation
        if(isKeyDefinedFor(user, key))
        {
            Proxy memory proxy = _proxies[user][key];
            // Proxy is being updated directly by its user
            if(admin == user)
            {
                if(!proxy.updatable) revert ProxyHub_NotUpdatable();
            }
            // Proxy is being updated "externally" by an administrator
            else
            {
                if(!proxy.adminable && admin != user) revert ProxyHub_NotAdminable();
                _checkRole(proxy.adminRole, admin);
                // Admin role is never given in that case, should then be retrieved
                adminRole = _proxies[user][key].adminRole;
            }
            if(proxy.interfaceId != interfaceId || proxy.adminRole != adminRole) revert ProxyHub_CanOnlyBeRestricted();
            // No update to be performed
            if(proxy.proxyAddress == proxyAddress && proxy.nullable == nullable &&
               proxy.updatable == updatable && proxy.adminable == adminable)
            {
                return;
            }
            if((!_proxies[user][key].nullable && nullable) ||
               (!_proxies[user][key].updatable && updatable) ||
               (!_proxies[user][key].adminable && adminable))
            {
                revert ProxyHub_CanOnlyBeRestricted();
            }
        }
        // Proxy cannot be initiated by administration
        else if(admin != user) revert ProxyHub_KeyNotDefined(user, key);
        // Proxy reference is being created
        else
        {
            _users.add(user);
            _keys[user].add(key);
        }
        // Check Proxy depending on its address
        if(proxyAddress == address(0))
        {
            // Proxy address cannot be set to null
            if(!nullable) revert ProxyHub_ContractIsNull();
        }
        // Interface ID is defined
        else if(interfaceId != 0x00)
        {
            // Proxy should support requested interface
            if(!ERC165(proxyAddress).supportsInterface(interfaceId)) revert ProxyHub_ContractIsInvalid(interfaceId);
        }

        _proxies[user][key] = Proxy(proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
        emit ProxyDefined(admin, user, key, proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
    }

    /**
     * @dev This method returns the number of users defined in this contract.
     * Can be used together with {getUserAt} to enumerate all users defined in this contract.
     */
    function getUserCount() public view returns (uint256)
    {
        return _users.length();
    }
    /**
     * @dev This method returns one of the users defined in this contract.
     * `index` must be a value between 0 and {getUserCount}, non-inclusive.
     * Users are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getUserAt} and {getUserCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     * @param index Index at which to search for the user
     */
    function getUserAt(uint256 index) public view returns (address)
    {
        return _users.at(index);
    }
    /**
     * @dev This method returns the number of keys defined in this contract for a user.
     * Can be used together with {getKeyAt} to enumerate all keys defined in this contract for a user.
     * @param user User for which to get defined number of keys
     */
    function getKeyCount(address user) public view returns (uint256)
    {
        return _keys[user].length();
    }
    /**
     * @dev This method returns one of the keys defined in this contract for a user.
     * `index` must be a value between 0 and {getKeyCount}, non-inclusive.
     * Keys are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getKeyAt} and {getKeyCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     * @param user User for which to get key at defined index
     * @param index Index at which to search for the key of defined user
     */
    function getKeyAt(address user, uint256 index) public view returns (bytes4)
    {
        return bytes4(_keys[user].at(index));
    }

    function getProxies() public view returns (ProxyEntry[] memory proxyEntries, Proxy[] memory proxies)
    {
        uint256 userCount = getUserCount();
        for(uint256 i = 0 ; i < userCount ; i++)
        {
            address user = getUserAt(i);
            uint256 keyCount = getKeyCount(user);
            if(i == 0)
            {
                proxyEntries = new ProxyEntry[](keyCount);
            }
            else
            {
                ProxyEntry[] memory __proxyEntries = proxyEntries;
                proxyEntries = new ProxyEntry[](keyCount + __proxyEntries.length);
                for(uint256 j = 0 ; j < __proxyEntries.length ; j++)
                {
                    proxyEntries[j] = __proxyEntries[j];
                }
            }
            for(uint256 j = 0 ; j < keyCount ; j++)
            {
                proxyEntries[proxyEntries.length - (keyCount-j)] = ProxyEntry(user, getKeyAt(user, j));
            }
        }
        proxies = new Proxy[](proxyEntries.length);
        for(uint256 i = 0 ; i < proxyEntries.length ; i++)
        {
            proxies[i] = getProxyFor(proxyEntries[i].user, proxyEntries[i].key);
        }
    }
}

/**
 * @title Simple proxy diamond interface.
 * @author tazous
 */
interface IProxyDiamond
{
    /**
     * @dev Should return the address of the proxy defined by current proxy diamond on provided key. Should revert with ProxyHub_KeyNotDefined
     * if not found
     * @param key Key on which searched proxied address should be defined by diamond
     * @return Found existing proxy address defined by diamond on provided key
     */
    function getProxyAddress(bytes4 key) external view returns (address);
}

/**
 * @dev This is the contract to extend in order to easily store and access a proxy. Does not directly implement
 * ERC165 to prevent further linearization of inheritance issues
 */
contract ProxyDiamond is IProxyDiamond
{
    /** @dev Address of the Hub where proxies are stored */
    address public immutable proxyHubAddress;
    /** IProxyDiamond interface ID definition */
    bytes4 public constant IProxyDiamondInterfaceId = type(IProxyDiamond).interfaceId;

    /**
     * @dev Default constructor
     * @param proxyHubAddress_ Address of the Hub where proxies are stored
     */
    constructor(address proxyHubAddress_)
    {
        proxyHubAddress = proxyHubAddress_;
    }

    /**
     * @dev Returns the address of the proxy defined by current proxy diamond on provided key. Will revert with ProxyHub_KeyNotDefined
     * if not found
     * @param key Key on which searched proxied address should be defined by diamond
     * @return Found existing proxy address defined by diamond on provided key
     */
    function getProxyAddress(bytes4 key) public virtual view returns (address)
    {
        return ProxyHub(proxyHubAddress).getProxyAddress(key);
    }
    /**
     * @dev Define proxy for diamond on provided key. Will revert with ProxyHub_NotUpdatable if not allowed to be modified,
     * with ProxyHub_CanOnlyBeRestricted if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull
     * when given address is null and null not allowed
     * @param key Key by which the proxy should be defined for the caller
     * @param proxyAddress Address of the proxy being defined
     * @param interfaceId ID of the interface the proxy being defined should comply to (ERC165)
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     * @param adminRole Role that proxy hub administrator should be granted if adminable is activated
     */
    function _setProxy(bytes4 key, address proxyAddress, bytes4 interfaceId,
                       bool nullable, bool updatable, bool adminable, bytes32 adminRole) internal virtual
    {
        ProxyHub(proxyHubAddress).setProxy(key, proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
    }
    /**
     * @dev Define proxy for diamond on provided key. Will revert with ProxyHub_NotUpdatable if not allowed to be modified,
     * with ProxyHub_CanOnlyBeRestricted if given options are less restrictive that existing ones and with ProxyHub_ContractIsNull
     * when given address is null and null not allowed. Administrator role will be the default one returned by getProxyAdminRole()
     * @param key Key by which the proxy should be defined for the caller
     * @param proxyAddress Address of the proxy being defined
     * @param interfaceId ID of the interface the proxy being defined should comply to (ERC165)
     * @param nullable Can the proxied address be null
     * @param updatable Can the proxied address be updated by its user
     * @param adminable Can the proxied address be updated by a proxy hub administrator
     */
    function _setProxy(bytes4 key, address proxyAddress, bytes4 interfaceId,
                       bool nullable, bool updatable, bool adminable) internal virtual
    {
        _setProxy(key, proxyAddress, interfaceId, nullable, updatable, adminable, getProxyAdminRole());
    }
    /**
     * @dev Default proxy hub administrator role
     */
    function getProxyAdminRole() public virtual returns (bytes32)
    {
        return 0x00;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
    {
        return interfaceId == IProxyDiamondInterfaceId;
    }
}


contract ProxyDiamondInternalHub is ProxyDiamond, ProxyHub
{
    constructor() ProxyDiamond(address(0)){}

    function getProxyAddress(bytes4 key) public view virtual override (ProxyDiamond, ProxyHub) returns (address)
    {
        return ProxyHub.getProxyAddressFor(address(this), key);
    }
    function _setProxy(bytes4 key, address proxyAddress, bytes4 interfaceId,
                       bool nullable, bool updatable, bool adminable, bytes32 adminRole) internal virtual override
    {
        ProxyHub._setProxy(address(this), address(this), key, proxyAddress, interfaceId, nullable, updatable, adminable, adminRole);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override (ProxyDiamond, AccessControlEnumerable) returns (bool)
    {
        return ProxyDiamond.supportsInterface(interfaceId) ||
               AccessControlEnumerable.supportsInterface(interfaceId);
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./SecuredProcess.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Definition of a process that can be secured through allowance mechanism
 */
interface IAllowance is ISecuredProcess
{
    /**
     * @dev Bucket definition data structure
     * 'name' Name of the bucket
     * 'allowanceCap' Allowance cap defined on the bucket. If zero, allowance should explicitly be added to user and will
     * be decremented when used. Otherwise, a counter will be incremented when used until cap is reached
     * 'creditorRole' Role that user should be granted in order to credit allowance on the bucket
     * 'debitorRole' Role that user should be granted in order to debit allowance on the bucket
     */
    struct Bucket
    {
        bytes4 name;
        uint256 allowanceCap;
        bytes32 creditorRole;
        bytes32 debitorRole;
    }

    /**
     * @dev This method should return the number of allowance buckets defined in this contract.
     * Can be used together with {getBucketAt} to enumerate all allowance buckets defined in this contract.
     */
    function getBucketCount() external view returns (uint256);
    /**
     * @dev This method should return one of the allowance bucket defined in this contract.
     * `index` must be a value between 0 and {getBucketCount}, non-inclusive.
     * Allowance buckets are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getBucketAt} and {getBucketCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getBucketAt(uint256 index) external view returns (Bucket memory);
    /**
     * @dev This method should return the allowance bucket defined in this contract by given name
     * @param name Name of the allowance bucket to be retrieved
     */
    function getBucket(bytes4 name) external view returns (Bucket memory);
    /**
     * @dev This method should create allowance bucket corresponding to given arguments
     * @param name Name of the allowance bucket
     * @param allowanceCap Allowance cap defined on the bucket. If zero, allowance should explicitly be added to user and
     * will be decremented when used. Otherwise, a counter will be incremented when used until cap is reached
     * @param creditorRole Role that user should be granted in order to credit allowance on the bucket
     * @param debitorRole Role that user should be granted in order to debit allowance on the bucket
     */
    function createBucket(bytes4 name, uint256 allowanceCap, bytes32 creditorRole, bytes32 debitorRole) external;

    /**
     * @dev Getter of the available allowance for a user on a given bucket. Should return the available allowance for a
     * user alongside its applicable bucket definition
     * @param address_ Address of the user for which allowance should be retrieved
     * @param bucketName Bucket name for which allowance should be retrieved
     */
    function getAllowance(address address_, bytes4 bucketName, bytes memory additionalData) external view returns (uint256 allowance, Bucket memory bucket);
    /**
     * @dev Should check the available allowance for a user on a given bucket. Should revert if available allowance is lower
     * than requested one or if bucket is not defined. Should return the available allowance for a user alongside its applicable
     * bucket definition
     * @param address_ Address of the user for which allowance should be checked
     * @param bucketName Bucket name for which allowance should be checked
     * @param amount Minimal amount of allowance expected
     */
    function checkAllowance(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData) external view returns (uint256 allowance, Bucket memory bucket);
    /**
     * @dev Should add allowances for users on given buckets. Should revert if added amount exceeds allowance cap or if
     * provided arrays do not have the same sizes or if one of given bucket names is not defined. Caller should be granted
     * every bucket's defined creditor roles for the call to be allowed
     * @param addresses Address of the users for which allowances should be added
     * @param bucketNames Buckets name for which allowances should be added
     * @param amounts Amounts of allowance to be added
     */
    function addAllowances(address[] memory addresses, bytes4[] memory bucketNames, uint256[] memory amounts, bytes[] memory additionalData) external returns (uint256[] memory allowances, Bucket[] memory buckets);
    /**
     * @dev Should add allowance for a user on a given bucket. Should revert if added amount exceeds allowance cap or if
     * given bucket name is not defined. Caller should be granted bucket's defined creditor role for the call to be allowed
     * @param address_ Address of the user for which allowance should be added
     * @param bucketName Bucket name for which allowance should be added
     * @param amount Amount of allowance to be added
     */
    function addAllowance(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData) external returns (uint256 allowance, Bucket memory bucket);
    /**
     * @dev Should use allowance of a user on a given bucket. Should revert if used amount exceeds available allowance
     * or if given bucket name is not defined. Caller should be granted bucket's defined debitor role for the call to be allowed
     * @param address_ Address of the user from which allowance should be used
     * @param bucketName Bucket name from which allowance should be used
     * @param amount Amount of allowance to be used
     */
    function useAllowance(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData) external returns (uint256 allowance, Bucket memory bucket);
}

error AllowanceHandler_AmountExceeded(uint256 requestedAmount, uint256 available);
error AllowanceHandler_WrongParams();
error AllowanceHandler_ForbiddenRole(bytes32 role);
error AllowanceHandler_BucketNotDefined(bytes4 name);
error AllowanceHandler_BucketAlreadyDefined(bytes4 name);

/**
 * @dev Base implementation for secured allowance mechanism
 */
abstract contract BaseAllowanceHandler is IAllowance, PausableImpl
{
    /** Role definition necessary to be able to manage buckets */
    bytes32 public constant ALLOWANCE_ADMIN_ROLE = keccak256("ALLOWANCE_ADMIN_ROLE");
    /** IAllowance interface ID definition */
    bytes4 public constant IAllowanceInterfaceId = type(IAllowance).interfaceId;

    /**
     * @dev This method is the entrypoint to create a new bucket definition. User should be granted ALLOWANCE_ADMIN_ROLE
     * role in order to use it. Will revert if a bucket with exact same name is already defined or if chosen roles are
     * DEFAULT_ADMIN_ROLE or ALLOWANCE_ADMIN_ROLE
     * @param name Name of the bucket to be created
     * @param allowanceCap Allowance cap of the bucket to be created. If zero, allowance should explicitly be defined by
     * user and will be decremented when used. Otherwise, a counter will be incremented when used until cap is reached
     * @param creditorRole Role that user should be granted in order to credit allowance on the created bucket
     * @param debitorRole Role that user should be granted in order to debit allowance on the created bucket
     */
    function createBucket(bytes4 name, uint256 allowanceCap, bytes32 creditorRole, bytes32 debitorRole) external onlyRole(ALLOWANCE_ADMIN_ROLE)
    {
        _createBucket(name, allowanceCap, creditorRole, debitorRole);
    }
    /**
     * @dev Internal method to create a new bucket definition. Will revert if a bucket with exact same name is already defined
     * or if chosen roles are DEFAULT_ADMIN_ROLE or ALLOWANCE_ADMIN_ROLE
     * @param name Name of the bucket to be created
     * @param allowanceCap Allowance cap of the bucket to be created. If zero, allowance should explicitly be defined by
     * user and will be decremented when used. Otherwise, a counter will be incremented when used until cap is reached
     * @param creditorRole Role that user should be granted in order to credit allowance on the created bucket
     * @param debitorRole Role that user should be granted in order to debit allowance on the created bucket
     */
    function _createBucket(bytes4 name, uint256 allowanceCap, bytes32 creditorRole, bytes32 debitorRole) internal virtual;
    /**
     * @dev Getter of the available allowance for a user on a given bucket.
     * Will return the available allowance for a user alongside its applicable bucket definition or revert with AllowanceHandler_BucketNotDefined
     * if none can be found
     * @param address_ Address of the user for which allowance should be retrieved
     * @param bucketName Bucket name for which allowance should be retrieved
     */
    function getAllowance(address address_, bytes4 bucketName, bytes memory additionalData) public virtual view returns (uint256 allowance, Bucket memory bucket);
    /**
     * @dev Check the available allowance for a user on a given bucket. Will revert with AllowanceHandler_AmountExceeded
     * if available allowance is lower than requested one or with AllowanceHandler_BucketNotDefined if bucket is not defined.
     * Will return the available allowance for a user alongside its applicable bucket definition
     * @param address_ Address of the user for which allowance should be checked
     * @param bucketName Bucket name for which allowance should be checked
     * @param amount Minimal amount of allowance expected
     */
    function checkAllowance(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData) public view returns (uint256 allowance, Bucket memory bucket)
    {
        // Get current allowance
        (uint256 allowance_, Bucket memory bucket_) = getAllowance(address_, bucketName, additionalData);
        // Revert if user's allowance is not sufficient
        if(allowance_ < amount) revert AllowanceHandler_AmountExceeded(amount, allowance_);
        return (allowance_, bucket_);
    }
    /** @dev Internal method that checks given address against provided bucket definition's creditor/debitor role or default
     * ALLOWANCE_ADMIN_ROLE
     * @param address_ Address to be checked for
     * @param bucket_ Bucket definition for which to check for creditor/debitor role
     * @param credit Should check for creditor role if true, or debitor role otherwise
     */
    function _checkAllower(address address_, Bucket memory bucket_, bool credit) internal view
    {
        // If address is not a full allowance admin, check creditor/debitor role
        if(!hasRole(ALLOWANCE_ADMIN_ROLE, address_))
        {
            // Check allowance role depending on whether allowance has to be credited or debited
            _checkRole(credit ? bucket_.creditorRole : bucket_.debitorRole, address_);
        }
    }
    /**
     * @dev Add allowances for users on given buckets. Will revert with AllowanceHandler_AmountExceeded if added amount
     * exceeds allowance cap or with AllowanceHandler_WrongParams if provided array does not have the same sizes or with
     * AllowanceHandler_BucketNotDefined if one of given bucket names is not defined. Caller should be granted every
     * bucket's defined creditor roles for the call to be allowed
     * @param addresses Address of the users for which allowances should be added
     * @param bucketNames Buckets name for which allowances should be added
     * @param amounts Amounts of allowance to be added
     */
    function addAllowances(address[] memory addresses, bytes4[] memory bucketNames, uint256[] memory amounts, bytes[] memory additionalData) external
    returns (uint256[] memory allowances, Bucket[] memory buckets)
    {
        allowances = new uint256[](addresses.length);
        buckets = new Bucket[](addresses.length);
        if(addresses.length != bucketNames.length ||
           addresses.length != amounts.length ||
           (addresses.length != additionalData.length && additionalData.length != 0))
           revert AllowanceHandler_WrongParams();
        for(uint256 i = 0 ; i < addresses.length ; i++)
        {
            (allowances[i], buckets[i]) = _addOrUseAllowance(
                addresses[i], bucketNames[i], amounts[i],
                additionalData.length == 0 ? new bytes(0) : additionalData[i], true);
        }
        return (allowances, buckets);
    }
    /**
     * @dev Add allowance for a user on a given bucket. Will revert with AllowanceHandler_AmountExceeded if added amount
     * exceeds allowance cap or with AllowanceHandler_BucketNotDefined if given bucket name is not defined. Caller should
     * be granted bucket's defined creditor role for the call to be allowed
     * @param address_ Address of the user for which allowance should be added
     * @param bucketName Bucket name for which allowance should be added
     * @param amount Amount of allowance to be added
     */
    function addAllowance(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData) external
    returns (uint256 allowance, Bucket memory bucket)
    {
        return _addOrUseAllowance(address_, bucketName, amount, additionalData, true);
    }
    /**
     * @dev Use allowance of a user on a given bucket. Will revert with AllowanceHandler_AmountExceeded if used amount
     * exceeds available allowance or with AllowanceHandler_BucketNotDefined if given bucket name is not defined. Caller
     * should be granted bucket's defined debitor role for the call to be allowed
     * @param address_ Address of the user from which allowance should be used
     * @param bucketName Bucket name from which allowance should be used
     * @param amount Amount of allowance to be used
     */
    function useAllowance(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData) public
    returns (uint256 allowance, Bucket memory bucket)
    {
        return _addOrUseAllowance(address_, bucketName, amount, additionalData, false);
    }
    /**
     * Internal method used to add or use allowance for a user on a given bucket. It insures that no allowance change can
     * be done while contract is paused and will revert with AllowanceHandler_BucketNotDefined if given bucket name is not
     * defined or with AllowanceHandler_AmountExceeded if attempting to add more that possible/use more than available allowance.
     * User should be granted corresponding creditor/debitor (when allowance should be added or removed) role found in given
     * allowance definition in order to use it
     * @param address_ Address of the user for which allowance should be set
     * @param bucketName Bucket name for which allowance should be set
     * @param amount Amount of allowance to add or use for defined user on a given bucket
     * @param add Should the amount of allowance added or user for defined user on a given bucket
     */
    function _addOrUseAllowance(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData, bool add) internal virtual
    returns (uint256 allowance, Bucket memory bucket);

    /**
     * Check process for an allowance secured mechanism consists of checking allowance rights
     */
    function checkProcess(bytes4 bucketName, address address_, uint256 amount, bytes memory data2Process) public virtual view
    {
        checkAllowance(address_, bucketName, amount, data2Process);
    }
    /**
     * Execute process for an allowance secured mechanism consists of using allowance rights
     */
    function doProcess(bytes4 bucketName, address address_, uint256 amount, bytes memory data2Process) public virtual
    {
        useAllowance(address_, bucketName, amount, data2Process);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)
    {
        return super.supportsInterface(interfaceId) ||
               interfaceId == IAllowanceInterfaceId ||
               interfaceId == type(ISecuredProcess).interfaceId;
    }
}

/**
 * @dev This is the default contract implementation for allowance management.
 */
contract AllowanceHandler is BaseAllowanceHandler
{
    /** @dev Allowances defined for users on buckets */
    mapping(bytes4 => mapping(address => uint256)) private _allowances;

    /** @dev Buckets defined on this contract */
    mapping(bytes4 => Bucket) private _buckets;
    /** @dev Enumerable set used to reference every defined buckets name */
    using EnumerableSet for EnumerableSet.Bytes32Set;
    EnumerableSet.Bytes32Set private _bucketNames;

    /**
     * @dev Event emitted whenever some allowances are added for a user on a specific bucket
     * 'admin' Address of the administrator that added allowances
     * 'beneficiary' Address of the user for which allowances were added
     * 'bucket' Bucket definition in which allowances were added
     * 'amount' Amount of added allowances
     * 'allowance' Amount of available allowances for the user on the bucket after addition
     */
    event AllowanceAdded(address indexed admin, address indexed beneficiary, bytes4 indexed bucket, bytes additionalData, uint256 amount, uint256 allowance);
    /**
     * @dev Event emitted whenever some allowances are used for a user on a specific bucket
     * 'consumer' Address of the consumer that used allowances
     * 'beneficiary' Address of the user for which allowances were used
     * 'bucket' Bucket definition in which allowances were used
     * 'amount' Amount of used allowances
     * 'allowance' Amount of available allowances for the user on the bucket after usage
     */
    event AllowanceUsed(address indexed consumer, address indexed beneficiary, bytes4 indexed bucket, bytes additionalData, uint256 amount, uint256 allowance);

    /**
     * @dev Default constructor
     */
    constructor() {}

    /**
     * @dev This method returns the number of buckets defined in this contract.
     * Can be used together with {getBucketAt} to enumerate all buckets defined in this contract.
     */
    function getBucketCount() external view returns (uint256)
    {
        return _bucketNames.length();
    }
    /**
     * @dev This method returns one of the buckets defined in this contract.
     * `index` must be a value between 0 and {getBucketCount}, non-inclusive.
     * Buckets are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getBucketAt} and {getBucketCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getBucketAt(uint256 index) external view returns (Bucket memory)
    {
        return _buckets[bytes4(_bucketNames.at(index))];
    }
    /**
     * @dev This method returns the bucket defined in this contract by given name and will revert with AllowanceHandler_BucketNotDefined
     * if none can be found
     * @param name Name of the bucket definition to be found
     */
    function getBucket(bytes4 name) public view returns (Bucket memory)
    {
        if(!_bucketNames.contains(name)) revert AllowanceHandler_BucketNotDefined(name);
        return _buckets[name];
    }
    /**
     * @dev Internal method to create a new bucket definition. Will revert if a bucket with exact same name is already defined
     * or if chosen roles are DEFAULT_ADMIN_ROLE or ALLOWANCE_ADMIN_ROLE
     * @param name Name of the bucket to be created
     * @param allowanceCap Allowance cap of the bucket to be created. If zero, allowance should explicitly be defined by
     * user and will be decremented when used. Otherwise, a counter will be incremented when used until cap is reached
     * @param creditorRole Role that user should be granted in order to credit allowance on the created bucket
     * @param debitorRole Role that user should be granted in order to debit allowance on the created bucket
     */
    function _createBucket(bytes4 name, uint256 allowanceCap, bytes32 creditorRole, bytes32 debitorRole) internal override
    {
        // Check bucket name existence
        if(_bucketNames.contains(name)) revert AllowanceHandler_BucketAlreadyDefined(name);
        // Check for forbidden roles
        if(creditorRole == DEFAULT_ADMIN_ROLE || creditorRole == ALLOWANCE_ADMIN_ROLE) revert AllowanceHandler_ForbiddenRole(creditorRole);
        if(debitorRole == DEFAULT_ADMIN_ROLE || debitorRole == ALLOWANCE_ADMIN_ROLE) revert AllowanceHandler_ForbiddenRole(debitorRole);
        _buckets[name] = Bucket(name, allowanceCap, creditorRole, debitorRole);
        _bucketNames.add(name);
    }

    /**
     * @dev Getter of the available allowance for a user on a given bucket.
     * Will return the available allowance for a user alongside its applicable bucket definition or revert with AllowanceHandler_BucketNotDefined
     * if none can be found
     * @param address_ Address of the user for which allowance should be retrieved
     * @param bucketName Bucket name for which allowance should be retrieved
     */
    function getAllowance(address address_, bytes4 bucketName, bytes memory additionalData) public override view returns (uint256 allowance, Bucket memory bucket)
    {
        Bucket memory bucket_ = getBucket(bucketName);
        // Allowance is specifically defined by user
        if(bucket_.allowanceCap == 0)
        {
            return (_findAllowance(address_, bucketName, additionalData), bucket_);
        }
        // Allowance is capped and fully granted until used
        return (bucket_.allowanceCap - _findAllowance(address_, bucketName, additionalData), bucket_);
    }
    function _findAllowance(address address_, bytes4 bucketName, bytes memory /*additionalData*/) internal virtual view returns (uint256 allowance)
    {
        return _allowances[bucketName][address_];
    }
    function _setAllowance(address address_, bytes4 bucketName, bytes memory /*additionalData*/, uint256 allowance) internal virtual
    {
        _allowances[bucketName][address_] = allowance;
    }
    /**
     * Internal method used to add or use allowance for a user on a given bucket. It insures that no allowance change can
     * be done while contract is paused and will revert with AllowanceHandler_BucketNotDefined if given bucket name is not
     * defined or with AllowanceHandler_AmountExceeded if attempting to add more that possible/use more than available allowance.
     * User should be granted corresponding creditor/debitor (when allowance should be added or removed) role found in given
     * allowance definition in order to use it
     * @param address_ Address of the user for which allowance should be set
     * @param bucketName Bucket name for which allowance should be set
     * @param amount Amount of allowance to add or use for defined user on a given bucket
     * @param add Should the amount of allowance added or user for defined user on a given bucket
     */
    function _addOrUseAllowance(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData, bool add) internal virtual override whenNotPaused()
    returns (uint256 allowance, Bucket memory bucket)
    {
        // Get or check allowance depending on if some have to be added or used
        (uint256 allowance_, Bucket memory bucket_) = add ? getAllowance(address_, bucketName, additionalData) :
                                                            checkAllowance(address_, bucketName, amount, additionalData);
        // Nothing to add/use
        if(amount == 0) return (allowance_, bucket_);
        // Check allowance role depending on whether if some have to be added or used
        _checkAllower(_msgSender(), bucket_, add);
        // Allowance is specifically defined by user
        if(bucket_.allowanceCap == 0)
        {
            // Add/use allowance
            _setAllowance(address_, bucketName, additionalData, add ? allowance_ + amount : allowance_ - amount);
        }
        // Allowance is capped and fully granted until used
        else
        {
            // If allowance should be added, cap should not be exceeded (cannot add more than the number already used
            uint256 usedAllowance = bucket_.allowanceCap - allowance_;
            if(add && amount > usedAllowance) revert AllowanceHandler_AmountExceeded(amount, usedAllowance);
            // Add/use allowance
            _setAllowance(address_, bucketName, additionalData, add ? usedAllowance - amount : usedAllowance + amount);
        }
        (allowance_, ) = getAllowance(address_, bucketName, additionalData);
        // Emit corresponding event
        if(add)
        {
            emit AllowanceAdded(msg.sender, address_, bucketName, additionalData, amount, allowance_);
        }
        else
        {
            emit AllowanceUsed(msg.sender, address_, bucketName, additionalData, amount, allowance_);
        }
        return (allowance_, bucket_);
    }
}

/**
 * @dev Base allowance proxy implementation that will externalize behavior into another contract (ie a deployed AllowanceHandler),
 * acting as a proxy
 */
abstract contract AllowanceProxy is ProxyDiamond, BaseAllowanceHandler
{
    /**
     * @dev Contract constructor. For final implementers, do not forget to call ProxyDiamond constructor first in order
     * to initialize address of the proxy hub used to reference proxies
     * @param allowanceProxyAddress_ Address of the contract handling allowance process
     */
    constructor(address allowanceProxyAddress_, bool nullable, bool updatable, bool adminable)
    {
        _setAllowanceProxy(allowanceProxyAddress_, nullable, updatable, adminable);
    }

    function getBucketCount() external view returns (uint256)
    {
        return getAllowanceProxy().getBucketCount();
    }
    function getBucketAt(uint256 index) external view returns (Bucket memory)
    {
        return getAllowanceProxy().getBucketAt(index);
    }
    function getBucket(bytes4 name) external view returns (Bucket memory)
    {
        return getAllowanceProxy().getBucket(name);
    }
    function _createBucket(bytes4 name, uint256 allowanceCap, bytes32 creditorRole, bytes32 debitorRole) internal override
    {
        return getAllowanceProxy().createBucket(name, allowanceCap, creditorRole, debitorRole);
    }

    function getAllowance(address address_, bytes4 bucketName, bytes memory additionalData) public override view returns (uint256 allowance, Bucket memory bucket)
    {
        return getAllowanceProxy().getAllowance(address_, bucketName, additionalData);
    }
    function _addOrUseAllowance(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData, bool add) internal virtual override whenNotPaused()
    returns (uint256 allowance, Bucket memory bucket)
    {
        (uint256 allowance_, Bucket memory bucket_) = add ? getAllowanceProxy().addAllowance(address_, bucketName, amount, additionalData) :
                                                            getAllowanceProxy().useAllowance(address_, bucketName, amount, additionalData);
        // Amount was added or used, role has to be checked against caller's ones
        if(amount != 0) {
            _checkAllower(_msgSender(), bucket_, add);
        }
        return (allowance_, bucket_);
    }

    /**
     * Getter of the contract handling allowances process
     */
    function getAllowanceProxy() internal view returns (IAllowance)
    {
        return IAllowance(getProxyAddress(IAllowanceInterfaceId));
    }
    function _setAllowanceProxy(address allowanceProxyAddress_, bool nullable, bool updatable, bool adminable) internal
    {
        _setProxy(IAllowanceInterfaceId, allowanceProxyAddress_, IAllowanceInterfaceId, nullable, updatable, adminable);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ProxyDiamond, BaseAllowanceHandler) returns (bool)
    {
        return ProxyDiamond.supportsInterface(interfaceId) ||
               BaseAllowanceHandler.supportsInterface(interfaceId);
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./SecuredAllowance.sol";
import "./SecuredWhitelist.sol";

/**
 * @dev This is the base contract for whitelisted allowance management
 */
abstract contract BaseWhitelistedAllowance is BaseWhitelistHandler, BaseAllowanceHandler
{
    function _addOrUseAllowance(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData, bool add) internal virtual override
    returns (uint256 allowance, Bucket memory bucket)
    {
        checkWhitelisted(address_, bucketName, additionalData);
        return _addOrUseAllowanceSuper(address_, bucketName, amount, additionalData, add);
    }
    function _addOrUseAllowanceSuper(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData, bool add) internal virtual
    returns (uint256 allowance, Bucket memory bucket);


    function checkProcess(bytes4 name, address address_, uint256 amount, bytes memory data2Process) public virtual view override(BaseWhitelistHandler, BaseAllowanceHandler)
    {
        BaseWhitelistHandler.checkProcess(name, address_, amount, data2Process);
        BaseAllowanceHandler.checkProcess(name, address_, amount, data2Process);
    }
    function doProcess(bytes4 name, address address_, uint256 amount, bytes memory data2Process) public virtual override(BaseWhitelistHandler, BaseAllowanceHandler)
    {
        // BaseWhitelistHandler process checking is done by _addOrUseAllowance overriding
        BaseAllowanceHandler.doProcess(name, address_, amount, data2Process);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(BaseWhitelistHandler, BaseAllowanceHandler) returns (bool) {
        return BaseWhitelistHandler.supportsInterface(interfaceId) ||
               BaseAllowanceHandler.supportsInterface(interfaceId);
    }
}
/**
 * @dev This is a contract for whitelisted allowance management. It is based on underlying proxied IWhitelist & IAllowance
 * implementations which means that every whitelists defined will need their own buckets from which to get allowance from
 */
contract WhitelistedAllowanceProxy is BaseWhitelistedAllowance, WhitelistProxy, AllowanceProxy
{
    /**
     * @dev Default constructor
     */
    constructor(address proxyHubAddress_, address whitelistProxyAddress_, address allowanceProxyAddress_, bool updatable, bool adminable)
    ProxyDiamond(proxyHubAddress_) WhitelistProxy(whitelistProxyAddress_, false, updatable, adminable)
                                   AllowanceProxy(allowanceProxyAddress_, false, updatable, adminable)
    {}

    function _addOrUseAllowance(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData, bool add) internal override(BaseWhitelistedAllowance, AllowanceProxy)
    returns (uint256 allowance, Bucket memory bucket)
    {
        return BaseWhitelistedAllowance._addOrUseAllowance(address_, bucketName, amount, additionalData, add);
    }
    function _addOrUseAllowanceSuper(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData, bool add) internal override
    returns (uint256 allowance, Bucket memory bucket)
    {
        return AllowanceProxy._addOrUseAllowance(address_, bucketName, amount, additionalData, add);
    }


    function checkProcess(bytes4 name, address address_, uint256 amount, bytes memory data2Process) public virtual view override(BaseWhitelistedAllowance, BaseWhitelistHandler, BaseAllowanceHandler)
    {
        BaseWhitelistedAllowance.checkProcess(name, address_, amount, data2Process);
    }
    function doProcess(bytes4 name, address address_, uint256 amount, bytes memory data2Process) public virtual override(BaseWhitelistedAllowance, BaseWhitelistHandler, BaseAllowanceHandler)
    {
        BaseWhitelistedAllowance.doProcess(name, address_, amount, data2Process);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(BaseWhitelistedAllowance, WhitelistProxy, AllowanceProxy) returns (bool)
    {
        return BaseWhitelistedAllowance.supportsInterface(interfaceId);
    }
}
contract WhitelistedAllowanceHandler is BaseWhitelistedAllowance, WhitelistHandler, AllowanceHandler
{
    /**
     * @dev Default constructor
     */
    constructor() {}

    function _addOrUseAllowance(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData, bool add) internal virtual override(BaseWhitelistedAllowance, AllowanceHandler)
    returns (uint256 allowance, Bucket memory bucket)
    {
        return BaseWhitelistedAllowance._addOrUseAllowance(address_, bucketName, amount, additionalData, add);
    }
    function _addOrUseAllowanceSuper(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData, bool add) internal override
    returns (uint256 allowance, Bucket memory bucket)
    {
        return AllowanceHandler._addOrUseAllowance(address_, bucketName, amount, additionalData, add);
    }

    function checkProcess(bytes4 name, address address_, uint256 amount, bytes memory data2Process) public virtual view override(BaseWhitelistedAllowance, BaseWhitelistHandler, BaseAllowanceHandler)
    {
        BaseWhitelistedAllowance.checkProcess(name, address_, amount, data2Process);
    }
    function doProcess(bytes4 name, address address_, uint256 amount, bytes memory data2Process) public virtual override(BaseWhitelistedAllowance, BaseWhitelistHandler, BaseAllowanceHandler)
    {
        BaseWhitelistedAllowance.doProcess(name, address_, amount, data2Process);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(BaseWhitelistedAllowance, BaseWhitelistHandler, BaseAllowanceHandler) returns (bool)
    {
        return BaseWhitelistedAllowance.supportsInterface(interfaceId);
    }
}
contract WhitelistedHandlerAllowanceProxy is BaseWhitelistedAllowance, WhitelistHandler, AllowanceProxy
{
    /**
     * @dev Default constructor
     */
    constructor(address proxyHubAddress_, address allowanceProxyAddress_, bool updatable, bool adminable)
    ProxyDiamond(proxyHubAddress_) AllowanceProxy(allowanceProxyAddress_, false, updatable, adminable)
    {}

    function _addOrUseAllowance(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData, bool add) internal override(BaseWhitelistedAllowance, AllowanceProxy)
    returns (uint256 allowance, Bucket memory bucket)
    {
        return BaseWhitelistedAllowance._addOrUseAllowance(address_, bucketName, amount, additionalData, add);
    }
    function _addOrUseAllowanceSuper(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData, bool add) internal override
    returns (uint256 allowance, Bucket memory bucket)
    {
        return AllowanceProxy._addOrUseAllowance(address_, bucketName, amount, additionalData, add);
    }


    function checkProcess(bytes4 name, address address_, uint256 amount, bytes memory data2Process) public virtual view override(BaseWhitelistedAllowance, BaseWhitelistHandler, BaseAllowanceHandler)
    {
        BaseWhitelistedAllowance.checkProcess(name, address_, amount, data2Process);
    }
    function doProcess(bytes4 name, address address_, uint256 amount, bytes memory data2Process) public virtual override(BaseWhitelistedAllowance, BaseWhitelistHandler, BaseAllowanceHandler)
    {
        BaseWhitelistedAllowance.doProcess(name, address_, amount, data2Process);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(BaseWhitelistedAllowance, BaseWhitelistHandler, AllowanceProxy) returns (bool)
    {
        return BaseWhitelistedAllowance.supportsInterface(interfaceId);
    }
}
contract WhitelistedProxyAllowanceHandler is BaseWhitelistedAllowance, WhitelistProxy, AllowanceHandler
{
    /**
     * @dev Default constructor
     */
    constructor(address proxyHubAddress_, address whitelistProxyAddress_, bool updatable, bool adminable)
    ProxyDiamond(proxyHubAddress_) WhitelistProxy(whitelistProxyAddress_, false, updatable, adminable)
    {}

    function _addOrUseAllowance(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData, bool add) internal override(BaseWhitelistedAllowance, AllowanceHandler)
    returns (uint256 allowance, Bucket memory bucket)
    {
        return BaseWhitelistedAllowance._addOrUseAllowance(address_, bucketName, amount, additionalData, add);
    }
    function _addOrUseAllowanceSuper(address address_, bytes4 bucketName, uint256 amount, bytes memory additionalData, bool add) internal override
    returns (uint256 allowance, Bucket memory bucket)
    {
        return AllowanceHandler._addOrUseAllowance(address_, bucketName, amount, additionalData, add);
    }


    function checkProcess(bytes4 name, address address_, uint256 amount, bytes memory data2Process) public virtual view override(BaseWhitelistedAllowance, BaseWhitelistHandler, BaseAllowanceHandler)
    {
        BaseWhitelistedAllowance.checkProcess(name, address_, amount, data2Process);
    }
    function doProcess(bytes4 name, address address_, uint256 amount, bytes memory data2Process) public virtual override(BaseWhitelistedAllowance, BaseWhitelistHandler, BaseAllowanceHandler)
    {
        BaseWhitelistedAllowance.doProcess(name, address_, amount, data2Process);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(BaseWhitelistedAllowance, WhitelistProxy, BaseAllowanceHandler) returns (bool)
    {
        return BaseWhitelistedAllowance.supportsInterface(interfaceId);
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ProxyUtils.sol";

/**
 * @title Secured process interface. It allows to define a process to be secured (referred to as processName) and check and/or process
 * it for a specific address on a defined amount
 * @author tazous
 */
interface ISecuredProcess
{
    /**
     * Should check wether process name should revert or not for given amount on specified address
     * @param processName Name of the process to secure
     * @param address2Process Address for which the check should be done
     * @param amount2Process Amount for which the check should be done
     * @param data2Process Additional data for which the check should be done
     */
    function checkProcess(bytes4 processName, address address2Process, uint256 amount2Process, bytes memory data2Process) external view;
    /**
     * Should check & "execute" security related behavior of process name for given amount on specified address (ie decrement/increment
     * a counter, validate corresponding amount/level of something else)
     * @param processName Name of the process to secure
     * @param address2Process Address for which the check & security related behavior should be done
     * @param amount2Process Amount for which the check & security related behavior should be done
     * @param data2Process Additional data for which the check & security related behavior should be done
     */
    function doProcess(bytes4 processName, address address2Process, uint256 amount2Process, bytes memory data2Process) external;
}

/**
 * @title Simple secured process diamond implementation.
 * @author tazous
 */
abstract contract SecuredProcessProxy is ProxyDiamond
{
    /** ISecuredProcess interface ID definition */
    bytes4 public constant ISecuredProcessInterfaceId = type(ISecuredProcess).interfaceId;

    /**
     * @dev Contract constructor. For final implementers, do not forget to call ProxyDiamond constructor first in order
     * to initialize address of the proxy hub used to reference proxies
     * @param securedProcessAddress_ Address of the contract handling secured process
     */
    constructor(address securedProcessAddress_, bool nullable, bool updatable, bool adminable/*, bytes4 defaultProcessName_*/)
    {
        //_defaultProcessName = defaultProcessName_ == 0x00 ? bytes32(uint256(uint160(address(this))) << 96) : defaultProcessName_;//abi.encodePacked(address(this));
        _setSecuredProcessProxy(securedProcessAddress_, nullable, updatable, adminable);
    }

    /**
     * Checks wether process name should revert or not for given amount on specified address. It is public as there is no need to protect
     * its usage
     * @param processName Name of the process to secure
     * @param address2Process Address for which the check should be done
     * @param amount2Process Amount for which the check should be done
     * @param data2Process Additional data for which the check should be done
     */
    function checkProcess(bytes4 processName, address address2Process, uint256 amount2Process, bytes memory data2Process) public view virtual
    {
        address securedProcessAddress = getProxyAddress(ISecuredProcessInterfaceId);
        if(securedProcessAddress != address(0)) {
            ISecuredProcess(securedProcessAddress).checkProcess(processName, address2Process, amount2Process, data2Process);
        }
    }
    /**
     * Checks & "executes" security related behavior of process name for given amount on specified address (ie decrement/increment
     * a counter, validate corresponding amount/level of something else). It is internal as its usage might have to be protected
     * as well (for instance, making sure that only authorized account are using it)
     * @param processName Name of the process to secure
     * @param address2Process Address for which the check & security related behavior should be done
     * @param amount2Process Amount for which the check & security related behavior should be done
     * @param data2Process Additional data for which the check & security related behavior should be done
     */
    function _doProcess(bytes4 processName, address address2Process, uint256 amount2Process, bytes memory data2Process) internal virtual
    {
        address securedProcessAddress = getProxyAddress(ISecuredProcessInterfaceId);
        if(securedProcessAddress != address(0))
        {
            ISecuredProcess(securedProcessAddress).doProcess(processName, address2Process, amount2Process, data2Process);
        }
    }

    function _setSecuredProcessProxy(address securedProcessAddress_, bool nullable, bool updatable, bool adminable) internal
    {
        _setProxy(ISecuredProcessInterfaceId, securedProcessAddress_, ISecuredProcessInterfaceId, nullable, updatable, adminable);
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./SecuredProcess.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @dev Definition of a process that can be secured through whitelisting mechanism
 */
interface IWhitelist is ISecuredProcess
{
    /**
     * @dev Whitelist definition data structure
     * 'name' Name of the whitelist
     * 'whitelisterRole' Role that user should be granted in order to allow/revoke user on/from the whitelist
     */
    struct Whitelist
    {
        bytes4 name;
        bytes32 whitelisterRole;
    }

    /**
     * @dev This method should return the number of whitelists defined in this contract.
     * Can be used together with {getWhitelistAt} to enumerate all whitelists defined in this contract.
     */
    function getWhitelistCount() external view returns (uint256);
    /**
     * @dev This method should return one of the whitelist defined in this contract.
     * `index` must be a value between 0 and {getWhitelistCount}, non-inclusive.
     * Whitelists are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getWhitelistAt} and {getWhitelistCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getWhitelistAt(uint256 index) external view returns (Whitelist memory);
    function hasWhitelist(bytes4 name) external view returns (bool);
    /**
     * @dev This method should return the whitelist defined in this contract by given name
     * @param name Name of the whitelist to be retrieved
     */
    function getWhitelist(bytes4 name) external view returns (Whitelist memory);
    /**
     * @dev This method should create whitelist definition corresponding to given arguments
     * @param name Name of the whitelist
     * @param whitelisterRole Role that user should be granted in order to allow/revoke user on/from the whitelist
     */
    function createWhitelist(bytes4 name, bytes32 whitelisterRole) external;
    /**
     * @dev This method should update whitelist definition corresponding to given arguments
     * @param name Name of the whitelist
     * @param whitelisterRole Role that user should be granted in order to allow/revoke user on/from the whitelist
     */
    function updateWhitelist(bytes4 name, bytes32 whitelisterRole) external;

    /**
     * @dev Getter of the whitelisting status of an address for given whitelist name. Should return true if given address
     * has been whitelisted for given whitelist name, false otherwise, alongside its applicable whitelist definition
     * @param address_ Address for which whitelisting status should be retrieved
     * @param whitelistName Name of the whitelist for which user's whitelisting status should be retrieved
     */
    function isWhitelisted(address address_, bytes4 whitelistName, bytes memory additionalData) external view returns (bool whitelisted, Whitelist memory whitelistDef);
    /**
     * @dev Should check the the whitelisting status of an address for given whitelist name. Should revert if address has
     * not been whitelisted or if whitelist is not defined. Should return applicable whitelist definition
     * @param address_ Address of the user for which whitelisting status should be checked
     * @param whitelistName Name of the whitelist for which user's whitelisting status should be checked
     */
    function checkWhitelisted(address address_, bytes4 whitelistName, bytes memory additionalData) external view returns (Whitelist memory whitelistDef);
    /**
     * @dev Should allow given addresses on corresponding whitelists. Should revert if provided arrays do not have the
     * same sizes or if one of given whitelist names is not defined. User should be granted corresponding whitelister roles
     * found in all given whitelist definition in order to use it
     * @param addresses Addresses to be whitelisted
     * @param whitelistNames Names of the whitelists to which given addresses should be allowed
     */
    function whitelistAll(address[] memory addresses, bytes4[] memory whitelistNames, bytes[] memory additionalData) external returns (bool[] memory whitelistedStatuses, Whitelist[] memory whitelistDefs);
    /**
     * @dev Should allow given address on corresponding whitelist. Should revert if given whitelist name is not defined.
     * User should be granted corresponding whitelister role found in whitelist definition in order to use it
     * @param address_ Address to be whitelisted
     * @param whitelistName Name of the whitelist to which given address should be allowed
     */
    function whitelist(address address_, bytes4 whitelistName, bytes memory additionalData) external returns (bool whitelisted, Whitelist memory whitelistDef);
    /**
     * @dev Should revoke given addresses from corresponding whitelists. Should revert if provided arrays do not have the
     * same sizes or if one of given whitelist name is not defined. User should be granted corresponding whitelister roles
     * found in all given whitelist definition in order to use it
     * @param addresses Addresses to be unwhitelisted
     * @param whitelistNames Names of the whitelists from which given addresses should be revoked
     */
    function unwhitelistAll(address[] memory addresses, bytes4[] memory whitelistNames, bytes[] memory additionalData) external returns (bool[] memory whitelistedStatuses, Whitelist[] memory whitelistDefs);
    /**
     * @dev Should revoke given address from corresponding whitelist. Should revert if given whitelist name is not defined.
     * User should be granted corresponding whitelister role found in whitelist definition in order to use it
     * @param address_ Address to be unwhitelisted
     * @param whitelistName Name of the whitelist from which given addresses should be revoked
     */
    function unwhitelist(address address_, bytes4 whitelistName, bytes memory additionalData) external returns (bool whitelisted, Whitelist memory whitelistDef);
    /**
     * @dev This method should return the number of addresses allowed on given whitelist defined in this contract
     * @param whitelistName Name of the whitelist from which to get whitelisted count
     */
    function getWhitelistedCount(bytes4 whitelistName) external view returns (uint256);
}

error WhitelistHandler_NotWhitelisted();
error WhitelistHandler_WrongParams();
error WhitelistHandler_ForbiddenRole(bytes32 role);
error WhitelistHandler_WhitelistNotDefined(bytes4 name);
error WhitelistHandler_WhitelistAlreadyDefined(bytes4 name);

/**
 * @dev Base implementation for secured whitelisting mechanism
 */
abstract contract BaseWhitelistHandler is IWhitelist, PausableImpl
{
    /** Role definition necessary to be able to manage whitelists */
    bytes32 public constant WL_ADMIN_ROLE = keccak256("WL_ADMIN_ROLE");
    /** IWhitelist interface ID definition */
    bytes4 public constant IWhitelistInterfaceId = type(IWhitelist).interfaceId;

    function hasWhitelist(bytes4 name) public view virtual returns (bool);
    function getWhitelist(bytes4 name) public view virtual returns (Whitelist memory);
    /**
     * @dev This method is the entrypoint to create a new whitelist definition. User should be granted WL_ADMIN_ROLE role
     * in order to use it. Will revert if a whitelist with exact same name is already defined or if chosen role is
     * DEFAULT_ADMIN_ROLE or WL_ADMIN_ROLE
     * @param name Name of the whitelist to be created
     * @param whitelisterRole Role that user should be granted in order to allow/revoke user to/from the whitelist
     */
    function createWhitelist(bytes4 name, bytes32 whitelisterRole) external onlyRole(WL_ADMIN_ROLE)
    {
        _createWhitelist(name, whitelisterRole);
    }
    /**
     * @dev Internal method to create a new whitelist definition. Will revert if a whitelist with exact same name is already
     * defined or if chosen role is DEFAULT_ADMIN_ROLE or ALLOWANCE_ADMIN_ROLE
     * @param name Name of the whitelist to be created
     * @param whitelisterRole Role that user should be granted in order to allow/revoke user to/from the whitelist
     */
    function _createWhitelist(bytes4 name, bytes32 whitelisterRole) internal virtual;
    /**
     * @dev This method is the entrypoint to update an existing whitelist definition. User should be granted WL_ADMIN_ROLE role
     * in order to use it. Will revert if no whitelist with exact same name is already defined or if chosen role is
     * DEFAULT_ADMIN_ROLE or WL_ADMIN_ROLE
     * @param name Name of the whitelist to be updated
     * @param whitelisterRole Role that user should be granted in order to allow/revoke user to/from the whitelist
     */
    function updateWhitelist(bytes4 name, bytes32 whitelisterRole) external onlyRole(WL_ADMIN_ROLE)
    {
        _updateWhitelist(name, whitelisterRole);
    }
    /**
     * @dev Internal method to update an existing whitelist definition. Will revert if no whitelist with exact same name is already
     * defined or if chosen role is DEFAULT_ADMIN_ROLE or ALLOWANCE_ADMIN_ROLE
     * @param name Name of the whitelist to be updated
     * @param whitelisterRole Role that user should be granted in order to allow/revoke user to/from the whitelist
     */
    function _updateWhitelist(bytes4 name, bytes32 whitelisterRole) internal virtual;
    /**
     * @dev Getter of the whitelisting status of an address for given whitelist name.
     * Will return true if given address has been whitelisted for given whitelist name, false otherwise, alongside its
     * applicable whitelist definition or revert with WhitelistHandler_WhitelistNotDefined if none can be found
     * @param address_ Address for which whitelisting status should be retrieved
     * @param whitelistName Name of the whitelist for which user's whitelisting status should be retrieved
     */
    function isWhitelisted(address address_, bytes4 whitelistName, bytes memory additionalData) public virtual view returns (bool whitelisted, Whitelist memory whitelistDef);
    /**
     * @dev Check the the whitelisting status of an address for given whitelist name. Will revert with WhitelistHandler_NotWhitelisted
     * if address has not been whitelisted or with WhitelistHandler_WhitelistNotDefined if whitelist is not defined.
     * Will return applicable whitelist definition
     * @param address_ Address of the user for which whitelisting status should be checked
     * @param whitelistName Name of the whitelist for which user's whitelisting status should be checked
     */
    function checkWhitelisted(address address_, bytes4 whitelistName, bytes memory additionalData) public view returns (Whitelist memory whitelistDef)
    {
        // Get current whitelisting status
        (bool whitelisted, Whitelist memory whitelist_) = isWhitelisted(address_, whitelistName, additionalData);
        // Revert if user is not whitelisted
        if(!whitelisted) revert WhitelistHandler_NotWhitelisted();
        return whitelist_;
    }
    /** @dev Internal method that checks given address against provided whitelist definition's whitelister role or default
     * WL_ADMIN_ROLE
     * @param address_ Address to be checked for
     * @param whitelist_ Whitelist definition for which to check for whitelister role
     */
    function _checkWhitelister(address address_, Whitelist memory whitelist_) internal view
    {
        // If address is not a full whitelist admin, check whitelister role
        if(!hasRole(WL_ADMIN_ROLE, address_))
        {
            _checkRole(whitelist_.whitelisterRole, address_);
        }
    }
    /**
     * @dev Allow given addresses on corresponding whitelists. Will revert with WhitelistHandler_WrongParams if provided
     * arrays do not have the same sizes or with WhitelistHandler_WhitelistNotDefined if one of given whitelist names is not
     * defined. User should be granted corresponding whitelister roles found in all given whitelist definition in order to
     * use it
     * @param addresses Addresses to be whitelisted
     * @param whitelistNames Names of the whitelists to which given addresses should be allowed
     */
    function whitelistAll(address[] memory addresses, bytes4[] memory whitelistNames, bytes[] memory additionalData) external
    returns (bool[] memory whitelistedStatuses, Whitelist[] memory whitelistDefs)
    {
        return _setWhitelisted(addresses, whitelistNames, additionalData, true);
    }
    /**
     * @dev Allow given address on corresponding whitelist. Will revert with WhitelistHandler_WhitelistNotDefined if given
     * whitelist name is not defined. User should be granted corresponding whitelister role found in whitelist definition
     * in order to use it
     * @param address_ Address to be whitelisted
     * @param whitelistName Name of the whitelist to which given address should be allowed
     */
    function whitelist(address address_, bytes4 whitelistName, bytes memory additionalData) external returns (bool whitelisted, Whitelist memory whitelistDef)
    {
        return _setWhitelisted(address_, whitelistName, additionalData, true);
    }
    /**
     * @dev Revoke given addresses from corresponding whitelists. Will revert with WhitelistHandler_WrongParams if provided
     * arrays do not have the same sizes or with WhitelistHandler_WhitelistNotDefined if one of given whitelist names is not
     * defined. User should be granted corresponding whitelister roles found in all given whitelist definition in order to
     * use it
     * @param addresses Addresses to be unwhitelisted
     * @param whitelistNames Names of the whitelists from which given addresses should be revoked
     */
    function unwhitelistAll(address[] memory addresses, bytes4[] memory whitelistNames, bytes[] memory additionalData) external
    returns (bool[] memory whitelistedStatuses, Whitelist[] memory whitelistDefs)
    {
        return _setWhitelisted(addresses, whitelistNames, additionalData, false);
    }
    /**
     * @dev Revoke given address from corresponding whitelist. Will revert with WhitelistHandler_WhitelistNotDefined if
     * given whitelist name is not defined. User should be granted corresponding whitelister role found in whitelist definition
     * in order to use it
     * @param address_ Address to be unwhitelisted
     * @param whitelistName Name of the whitelist from which given addresses should be revoked
     */
    function unwhitelist(address address_, bytes4 whitelistName, bytes memory additionalData) external returns (bool whitelisted, Whitelist memory whitelistDef)
    {
        return _setWhitelisted(address_, whitelistName, additionalData, false);
    }
    /**
     * @dev Setter of the whitelisting status of addresses for given whitelist names. Will revert with WhitelistHandler_WrongParams
     * if provided arrays does not have the same sizes or with WhitelistHandler_WhitelistNotDefined if one of given whitelist
     * name is not defined. User should be granted corresponding whitelister role found in all given whitelist definition
     * in order to use it
     * @param addresses Addresses for which whitelisting status should be set
     * @param whitelistNames Names of the whitelists for which user's whitelisting status should be set
     * @param doWhitelist Should new whitelisting status be on or off
     */
    function _setWhitelisted(address[] memory addresses, bytes4[] memory whitelistNames, bytes[] memory additionalData, bool doWhitelist) internal virtual
    returns (bool[] memory whitelisted, Whitelist[] memory whitelistDef);
    /**
     * @dev Setter of the whitelisting status of address for given whitelist name. Will revert with WhitelistHandler_WhitelistNotDefined
     * if given whitelist name is not defined. User should be granted corresponding whitelister role found in whitelist
     * definition in order to use it
     * @param address_ Address for which whitelisting status should be set
     * @param whitelistName Name of the whitelist for which user's whitelisting status should be set
     * @param doWhitelist Should new whitelisting status be on or off
     */
    function _setWhitelisted(address address_, bytes4 whitelistName, bytes memory additionalData, bool doWhitelist) internal
    returns (bool whitelisted, Whitelist memory whitelistDef)
    {
        address[] memory addresses = new address[](1);
        bytes4[] memory whitelistNames = new bytes4[](1);
        bytes[] memory additionalData_ = new bytes[](1);
        addresses[0] = address_;
        whitelistNames[0] = whitelistName;
        additionalData_[0] = additionalData;
        (bool[] memory whitelisted_, Whitelist[] memory whitelistDef_) = _setWhitelisted(addresses, whitelistNames, additionalData_, doWhitelist);
        return (whitelisted_[0], whitelistDef_[0]);
    }

    /**
     * Check process for a whitelisting secured mechanism consists of checking whitelisting status
     */
    function checkProcess(bytes4 whitelistName, address address_, uint256, bytes memory data2Process) public virtual view
    {
        checkWhitelisted(address_, whitelistName, data2Process);
    }
    /**
     * Execute process for a whitelisting secured mechanism also consists of checking whitelisting status
     */
    function doProcess(bytes4 whitelistName, address address_, uint256, bytes memory data2Process) public virtual
    {
        checkWhitelisted(address_, whitelistName, data2Process);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)
    {
        return super.supportsInterface(interfaceId) ||
               interfaceId == IWhitelistInterfaceId ||
               interfaceId == type(ISecuredProcess).interfaceId;
    }
}

/**
 * @dev This is the default contract implementation for whitelisting management.
 */
contract WhitelistHandler is BaseWhitelistHandler
{
    /** @dev Whitelistings status for users on defined whitelists */
    mapping(address => mapping(bytes4 => bool)) private _whitelistings;

    /** @dev Whitelists defined on this contract */
    mapping(bytes4 => Whitelist) private _whitelists;
    /** @dev Enumerable set used to reference every defined whitelist names */
    using EnumerableSet for EnumerableSet.Bytes32Set;
    EnumerableSet.Bytes32Set private _whitelistNames;
    /** @dev Map of enumerable set used to reference every whitelisted address */
    using EnumerableSet for EnumerableSet.AddressSet;
    mapping(bytes4 => EnumerableSet.AddressSet) private whitelistedAddresses;

    /**
     * @dev Event emitted whenever an address is allowed on a specific whitelist
     * 'admin' Address of the administrator that whitelisted the new address
     * 'whitelisted' Newly whitelisted address
     * 'whitelist' Whitelist name in which address was added
     */
    event Whitelisted(address indexed admin, address indexed whitelisted, bytes4 indexed whitelist, bytes additionalData);
    /**
     * @dev Event emitted whenever an address is revoked from a specific whitelist
     * 'admin' Address of the administrator that unwhitelisted the address
     * 'unwhitelisted' Unwhitelisted address
     * 'bucket' Whitelist name from which address was removed
     */
    event Unwhitelisted(address indexed admin, address indexed unwhitelisted, bytes4 indexed whitelist, bytes additionalData);

    /**
     * @dev Default constructor
     */
    constructor() {}

    /**
     * @dev This method returns the number of whitelists defined in this contract.
     * Can be used together with {getWhitelistAt} to enumerate all whitelists defined in this contract.
     */
    function getWhitelistCount() external view returns (uint256)
    {
        return _whitelistNames.length();
    }
    /**
     * @dev This method returns one of the whitelists defined in this contract.
     * `index` must be a value between 0 and {getWhitelistCount}, non-inclusive.
     * Whitelists are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getWhitelistAt} and {getWhitelistCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getWhitelistAt(uint256 index) external view returns (Whitelist memory)
    {
        return _whitelists[bytes4(_whitelistNames.at(index))];
    }
    function hasWhitelist(bytes4 name) public view virtual override returns (bool)
    {
        return _whitelistNames.contains(name);
    }
    /**
     * @dev This method returns the whitelist defined in this contract by given name and will revert with WhitelistHandler_WhitelistNotDefined
     * if none can be found
     * @param name Name of the whitelist definition to be found
     */
    function getWhitelist(bytes4 name) public view virtual override returns (Whitelist memory)
    {
        if(!hasWhitelist(name)) revert WhitelistHandler_WhitelistNotDefined(name);
        return _whitelists[name];
    }
    /**
     * @dev Internal method to create a new whitelist definition. Will revert if a whitelist with exact same name is already
     * defined or if chosen role is DEFAULT_ADMIN_ROLE or ALLOWANCE_ADMIN_ROLE
     * @param name Name of the whitelist to be created
     * @param whitelisterRole Role that user should be granted in order to allow/revoke user to/from the whitelist
     */
    function _createWhitelist(bytes4 name, bytes32 whitelisterRole) internal override
    {
        // Check whitelist name existence
        if(hasWhitelist(name)) revert WhitelistHandler_WhitelistAlreadyDefined(name);
        // Check for forbidden roles
        if(whitelisterRole == DEFAULT_ADMIN_ROLE || whitelisterRole == WL_ADMIN_ROLE) revert WhitelistHandler_ForbiddenRole(whitelisterRole);
        _whitelists[name] = Whitelist(name, whitelisterRole);
        _whitelistNames.add(name);
    }
    /**
     * @dev Internal method to update an existing whitelist definition. Will revert if no whitelist with exact same name is already
     * defined or if chosen role is DEFAULT_ADMIN_ROLE or ALLOWANCE_ADMIN_ROLE
     * @param name Name of the whitelist to be updated
     * @param whitelisterRole Role that user should be granted in order to allow/revoke user to/from the whitelist
     */
    function _updateWhitelist(bytes4 name, bytes32 whitelisterRole) internal override
    {
        // Check whitelist name existence
        if(hasWhitelist(name)) revert WhitelistHandler_WhitelistNotDefined(name);
        // Check for forbidden roles
        if(whitelisterRole == DEFAULT_ADMIN_ROLE || whitelisterRole == WL_ADMIN_ROLE) revert WhitelistHandler_ForbiddenRole(whitelisterRole);
        _whitelists[name].whitelisterRole = whitelisterRole;
    }

    /**
     * @dev Getter of the whitelisting status of an address for given whitelist name.
     * Will return true if given address has been whitelisted for given whitelist name, false otherwise, alongside its
     * applicable whitelist definition or revert with WhitelistHandler_WhitelistNotDefined if none can be found
     * @param address_ Address for which whitelisting status should be retrieved
     * @param whitelistName Name of the whitelist for which user's whitelisting status should be retrieved
     */
    function isWhitelisted(address address_, bytes4 whitelistName, bytes memory /*additionalData*/) public view virtual override returns (bool whitelisted, Whitelist memory whitelistDef)
    {
        Whitelist memory whitelist_ = getWhitelist(whitelistName);
        return (_whitelistings[address_][whitelistName], whitelist_);
    }
    /**
     * @dev Setter of the whitelisting status of addresses for given whitelist names. Will revert with WhitelistHandler_WrongParams
     * if provided arrays does not have the same sizes or with WhitelistHandler_WhitelistNotDefined if one of given whitelist
     * name is not defined. User should be granted corresponding whitelister role found in all given whitelist definition
     * in order to use it
     * @param addresses Addresses for which whitelisting status should be set
     * @param whitelistNames Names of the whitelists for which user's whitelisting status should be set
     * @param doWhitelist Should new whitelisting status be on or off
     */
    function _setWhitelisted(address[] memory addresses, bytes4[] memory whitelistNames, bytes[] memory additionalData, bool doWhitelist) internal virtual override whenNotPaused()
    returns (bool[] memory whitelisted, Whitelist[] memory whitelistDef)
    {
        if(addresses.length != whitelistNames.length ||
           (addresses.length != additionalData.length && additionalData.length != 0))
           revert WhitelistHandler_WrongParams();
        whitelisted = new bool[](addresses.length);
        whitelistDef = new Whitelist[](addresses.length);
        for(uint256 i = 0 ; i < addresses.length ; i++)
        {
            // Get current whitelisting status
            bytes memory additionalData_ = additionalData.length == 0 ? new bytes(0) : additionalData[i];
            (bool isWhitelisted_, Whitelist memory whitelist_) = isWhitelisted(
                addresses[i], whitelistNames[i], additionalData_);
            whitelisted[i] = isWhitelisted_;
            whitelistDef[i] = whitelist_;
            // Nothing to update
            if(doWhitelist == isWhitelisted_) continue;
            // Check whitelister role
            _checkWhitelister(_msgSender(), whitelist_);
            // Update whitelisting status
            _whitelistings[addresses[i]][whitelistNames[i]] = doWhitelist;
            // Emit corresponding event
            if(doWhitelist)
            {
                whitelistedAddresses[whitelistNames[i]].add(addresses[i]);
                emit Whitelisted(msg.sender, addresses[i], whitelistNames[i], additionalData_);
            }
            else
            {
                whitelistedAddresses[whitelistNames[i]].remove(addresses[i]);
                emit Unwhitelisted(msg.sender, addresses[i], whitelistNames[i], additionalData_);
            }
        }
        return (whitelisted, whitelistDef);
    }

    /**
     * @dev This method returns the number of addresses allowed on given whitelist defined in this contract.
     * Can be used together with {getWhitelistedAt} to enumerate all addresses allowed on given whitelist defined in this contract.
     * @param whitelistName Name of the whitelist from which to get whitelisted count
     */
    function getWhitelistedCount(bytes4 whitelistName) external view virtual returns (uint256)
    {
        return whitelistedAddresses[whitelistName].length();
    }
    /**
     * @dev This method returns one of the addresses allowed on given whitelist defined in this contract.
     * `index` must be a value between 0 and {getWhitelistedCount}, non-inclusive.
     * Whitelisted addresses are not sorted in any particular way, and their ordering may change at any point.
     * WARNING: When using {getWhitelistedAt} and {getWhitelistedCount}, make sure you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getWhitelistedAt(bytes4 whitelistName, uint256 index) external view virtual onlyRole(WL_ADMIN_ROLE) returns (address)
    {
        return whitelistedAddresses[whitelistName].at(index);
    }
}

/**
 * @dev Base whitelist proxy implementation that will externalize behavior into another contract (ie a deployed WhitelistHandler),
 * acting as a proxy
 */
abstract contract WhitelistProxy is ProxyDiamond, BaseWhitelistHandler
{
    /**
     * @dev Contract constructor. For final implementers, do not forget to call ProxyDiamond constructor first in order
     * to initialize address of the proxy hub used to reference proxies
     * @param whitelistProxyAddress_ Address of the contract handling whitelisting process
     */
    constructor(address whitelistProxyAddress_, bool nullable, bool updatable, bool adminable)
    {
        _setWhitelistProxy(whitelistProxyAddress_, nullable, updatable, adminable);
    }

    function getWhitelistCount() external view returns (uint256)
    {
        return getWhitelistProxy().getWhitelistCount();
    }
    function getWhitelistAt(uint256 index) external view returns (Whitelist memory)
    {
        return getWhitelistProxy().getWhitelistAt(index);
    }
    function hasWhitelist(bytes4 name) public view override returns (bool)
    {
        return getWhitelistProxy().hasWhitelist(name);
    }
    function getWhitelist(bytes4 name) public view override returns (Whitelist memory)
    {
        return getWhitelistProxy().getWhitelist(name);
    }
    function _createWhitelist(bytes4 name, bytes32 whitelisterRole) internal override
    {
        getWhitelistProxy().createWhitelist(name, whitelisterRole);
    }
    function _updateWhitelist(bytes4 name, bytes32 whitelisterRole) internal override
    {
        getWhitelistProxy().updateWhitelist(name, whitelisterRole);
    }

    function isWhitelisted(address address_, bytes4 whitelistName, bytes memory additionalData) public override view returns (bool whitelisted, Whitelist memory whitelistDef)
    {
        return getWhitelistProxy().isWhitelisted(address_, whitelistName, additionalData);
    }
    function _setWhitelisted(address[] memory addresses, bytes4[] memory whitelistNames, bytes[] memory additionalData, bool doWhitelist) internal override whenNotPaused()
    returns (bool[] memory whitelisted, Whitelist[] memory whitelistDef)
    {
        (whitelisted, whitelistDef) = doWhitelist ? getWhitelistProxy().whitelistAll(addresses, whitelistNames, additionalData) :
                                                    getWhitelistProxy().unwhitelistAll(addresses, whitelistNames, additionalData);
        for(uint256 i = 0 ; i < whitelisted.length ; i++)
        {
            // Address whitelisting status has changed, role has to be checked against caller's ones
            if(whitelisted[i] != doWhitelist)
            {
                _checkWhitelister(_msgSender(), whitelistDef[i]);
            }
        }
        return (whitelisted, whitelistDef);
    }
    function getWhitelistedCount(bytes4 whitelistName) external view returns (uint256)
    {
        return getWhitelistProxy().getWhitelistedCount(whitelistName);
    }

    /**
     * Getter of the contract handling whitelisting process
     */
    function getWhitelistProxy() internal view returns (IWhitelist)
    {
        return IWhitelist(getProxyAddress(IWhitelistInterfaceId));
    }
    function _setWhitelistProxy(address whitelistProxyAddress_, bool nullable, bool updatable, bool adminable) internal
    {
        _setProxy(IWhitelistInterfaceId, whitelistProxyAddress_, IWhitelistInterfaceId, nullable, updatable, adminable);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ProxyDiamond, BaseWhitelistHandler) returns (bool)
    {
        return ProxyDiamond.supportsInterface(interfaceId) ||
               BaseWhitelistHandler.supportsInterface(interfaceId);
    }
}

//         ╩╝                                  ▓╝
//         ╥╕   ,╓[email protected]@╥,     ╓[email protected]@╥, ╓╥       ╥  ╥² =╥      ╥∞
//         ╟▌  ▓╝²    ╙▓⌐  ▓╩    ▓@ ▐▓    ,▓╝  ▓P   ▐@  g▓`
//         ╟▌ ╞▓       ▐▓ j▓         ▐▓  ,▓╜   ▓P    ]▓▓Ç
//         ╟▌  ▓W     ╓▓▓ j▓          ▐▓,▓`    ▓P  ,@╝  ╚▓,
//         ╟▌   ╙╙╩Ñ╩╝`╘╨ "╨           ╙╨`     ╨ⁿ *╨      ╙*
//        ,▓M
//       ╙╙         ***** WEB3 CREATORS STUDIO *****
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

error AccessControl_MissingRole(address account, bytes32 role);
error AccessControl_EmptyRole();
error AccessControl_NotEmptyRole();
error AccessControl_NoMoreAdminRole();

/**
 * @dev Default implementation to use when role based access control is requested. It extends openzeppelin implementation
 * in order to use 'error' instead of 'string message' when checking roles and to be able to attribute admin role for each
 * defined role (and not rely exclusively on the DEFAULT_ADMIN_ROLE)
 */
abstract contract AccessControlImpl is AccessControlEnumerable
{
    /** Role that will not be able to be granted to anyone. To be used to block/burn any existing role */
    bytes32 public constant NO_MORE_ADMIN_ROLE = 0x9999999999999999999999999999999999999999999999999999999999999999;
    
    /**
     * @dev Default constructor
     */
    constructor()
    {
        // To be done at initialization otherwise it will never be accessible again
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Block NO_MORE_ADMIN_ROLE so it can never be granted to anyone
        blockRole(NO_MORE_ADMIN_ROLE);
    }

    /**
     * @dev Should return true if given role is forever blocked, ie no more role granting/revoking or admin role update
     * @param role Role for which blocked status should be checked
     */
    function isRoleBlocked(bytes32 role) public view returns (bool)
    {
        return getRoleAdmin(role) == NO_MORE_ADMIN_ROLE;
    }
    /**
     * @dev Should return true if given role is considered forever burnt, ie blocked without any member granted to
     * @param role Role for which burnt status should be checked
     */
    function isRoleBurnt(bytes32 role) public view returns (bool)
    {
        return isRoleBlocked(role) && getRoleMemberCount(role) == 0;
    }
    /**
     * @dev Revert with AccessControl_MissingRole error if `account` is missing `role` instead of a string generated message
     */
    function _checkRole(bytes32 role, address account) internal view virtual override
    {
        if(!hasRole(role, account)) revert AccessControl_MissingRole(account, role);
    }
    /**
     * @dev Should check if given account is an admin for provided Revert with AccessControl_MissingRole error if `account` is missing
     * `role`'s admin role or DEFAULT_ADMIN_ROLE
     * @param role Role for which admin role should be checked
     * @param account Account to be checked against given role's admin role
     */
    function _checkRoleAdmin(bytes32 role, address account) internal view virtual
    {
        // Should be an admin of given role
        if(!hasRole(getRoleAdmin(role), account) && !hasRole(DEFAULT_ADMIN_ROLE, account))
        {
            revert AccessControl_MissingRole(account, getRoleAdmin(role));
        }
    }
    /**
     * @dev Prevent from emptying DEFAULT_ADMIN_ROLE. 
     */
    function _revokeRole(bytes32 role, address account) internal virtual override
    {
        super._revokeRole(role, account);
        // Cannot empty default admin role
        if(role == DEFAULT_ADMIN_ROLE && getRoleMemberCount(role) == 0)
        {
            revert AccessControl_EmptyRole();
        }
    }
    /**
     * @dev Sets `adminRole` as `role`'s admin role. Revert with AccessControl_NoMoreAdminRole if it somehow implies NO_MORE_ADMIN_ROLE
     * or with AccessControl_MissingRole error if message sender is missing current `role`'s admin role or DEFAULT_ADMIN_ROLE
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) public
    {
        // NO_MORE_ADMIN_ROLE should not be implied in any way. No need to also directly test role or adminRole as if equals
        // to NO_MORE_ADMIN_ROLE, their admin role would also be NO_MORE_ADMIN_ROLE
        if(isRoleBlocked(role) || isRoleBlocked(adminRole))
        {
            revert AccessControl_NoMoreAdminRole();
        }
        // Should be an admin to define new admin role
        _checkRoleAdmin(role, _msgSender());
        _setRoleAdmin(role, adminRole);
    }
    /**
     * @dev This method should be used to forever block a role from any more update (role granting or revoking or admin role update)
     * @param role Role to be forever blocked
     */
    function blockRole(bytes32 role) public
    {
        // NO_MORE_ADMIN_ROLE is already applied
        if(isRoleBlocked(role)) return;
        // Should be an admin to block a role
        _checkRoleAdmin(role, _msgSender());
        // Define non manageable new admin role to block given role from any new administration (granting/revoking roles or defining a
        // new admin role)
        _setRoleAdmin(role, NO_MORE_ADMIN_ROLE);
    }
    /**
     * @dev This method should be used to forever "burn" a role from any more update (role granting or revoking or admin role update).
     * A burnt role is a blocked role without any user granted to it
     * @param role Role to be forever burnt
     */
    function burnRole(bytes32 role) public
    {
        // Role should be empty to be considered burnt
        if(getRoleMemberCount(role) != 0)
        {
            revert AccessControl_NotEmptyRole();
        }
        blockRole(role);
    }
}

/**
 * @dev Default implementation to use when contract should be pausable (role based access control is then requested in order
 * to grant access to pause/unpause actions). It extends openzeppelin implementation in order to define publicly accessible
 * and role protected pause/unpause methods
 */
abstract contract PausableImpl is AccessControlImpl, Pausable
{
    /** Role definition necessary to be able to pause contract */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Default constructor
     */
    constructor() {}

    /**
     * @dev Pause the contract if message sender has PAUSER_ROLE role. Action protected with whenNotPaused() or with
     * _requireNotPaused() will not be available anymore until contract is unpaused again
     */
    function pause() public onlyRole(PAUSER_ROLE)
    {
        _pause();
    }
    /**
     * @dev Unpause the contract if message sender has PAUSER_ROLE role. Action protected with whenPaused() or with
     * _requirePaused() will not be available anymore until contract is paused again
     */
    function unpause() public onlyRole(PAUSER_ROLE)
    {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

/**
 * @title  UpdatableOperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry. This contract allows the Owner to update the
 *         OperatorFilterRegistry address via updateOperatorFilterRegistryAddress, including to the zero address,
 *         which will bypass registry checks.
 *         Note that OpenSea will still disable creator earnings enforcement if filtered operators begin fulfilling orders
 *         on-chain, eg, if the registry is revoked or bypassed.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract UpdatableOperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);
    /// @dev Emitted when someone other than the owner is trying to call an only owner function.
    error OnlyOwner();

    event OperatorFilterRegistryAddressUpdated(address newRegistry);

    IOperatorFilterRegistry public operatorFilterRegistry;

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address _registry, address subscriptionOrRegistrantToCopy, bool subscribe) {
        IOperatorFilterRegistry registry = IOperatorFilterRegistry(_registry);
        operatorFilterRegistry = registry;
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(registry).code.length > 0) {
            if (subscribe) {
                registry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    registry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    registry.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if the operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if the operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be bypassed. OnlyOwner.
     */
    function updateOperatorFilterRegistryAddress(address newRegistry) public virtual {
        if (msg.sender != owner()) {
            revert OnlyOwner();
        }
        operatorFilterRegistry = IOperatorFilterRegistry(newRegistry);
        emit OperatorFilterRegistryAddressUpdated(newRegistry);
    }

    /**
     * @dev Assume the contract has an owner, but leave specific Ownable implementation up to inheriting contract.
     */
    function owner() public view virtual returns (address);

    /**
     * @dev A helper function to check if the operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry) != address(0) && address(registry).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}