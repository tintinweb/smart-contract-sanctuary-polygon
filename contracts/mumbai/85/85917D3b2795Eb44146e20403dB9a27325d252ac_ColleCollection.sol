// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

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
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
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
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
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
                        Strings.toHexString(account),
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC4906.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./IERC721.sol";

/// @title EIP-721 Metadata Update Extension
interface IERC4906 is IERC165, IERC721 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

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
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../interfaces/IERC4906.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is IERC4906, ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Emits {MetadataUpdate}.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;

        emit MetadataUpdate(tokenId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
library SignedMath {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {ERC721URIStorage, ERC721, IERC721, IERC165} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SignatureValidator} from "../../utils/SignatureValidator.sol";
import {IColleCollection} from "./IColleCollection.sol";
import {MarketHubRegistrar, AccessControl} from "../MarketHubRegistrar.sol";

/**
 * @title ColleCollection
 * @notice This contract represents a collection of unique tokens (NFTs) which mirror physical assets and extends ERC721 with additional functionality.
 * @dev The contract is using OpenZeppelin contracts for most of the ERC721 functionality and has extra functions for additional needs.
 */
contract ColleCollection is IColleCollection, SignatureValidator, ERC721URIStorage, MarketHubRegistrar {
    using Address for address;

    uint256 public nextTokenId;

    mapping(uint256 => string) private tokenSaleMetadataIPFS;

    /**
     * @notice Construct a new NFT collection contract.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     */
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        __SignatureValidator_init(_name, "v0.3");
    }

    /**
     * @notice Guards ERC721 transfers to the token owner (EOA or contract), approved EOA or approved Vault.
     * @dev Restricts approved non-vault contracts from transferring tokens to break 3rd party transfers of mirrored assets.
     * @param _tokenId The token id to guard against.
     */
    modifier onlyOwnerApprovedEOAOrVault(uint256 _tokenId) {
        bool isVault = address(marketHub) != address(0) && msg.sender == address(marketHub.getVault());
        bool validCaller = msg.sender == ownerOf(_tokenId) || isVault || !msg.sender.isContract();
        require(
            validCaller && _isApprovedOrOwner(msg.sender, _tokenId),
            "Only owner, approved EOA or approved Vault can transfer"
        );
        _;
    }

    /**
     * @notice Mints a new token.
     * @dev This function can only be called by a Colle.
     * @param _uri The token URI.
     * @param _receiver The address that will receive the minted token.
     */
    function mint(string memory _uri, address _receiver) public override onlyRelayer {
        _mint(_receiver, nextTokenId);
        _setTokenURI(nextTokenId, _uri);
        emit PermanentURI(tokenURI(nextTokenId), nextTokenId);
        nextTokenId++;
    }

    /**
     * @notice Updates the sale metadata for a token.
     * @dev This function can only be called by a Colle or the owner of the token.
     * @param _tokenId The ID of the token to update.
     * @param _ipfsHash The new IPFS hash for the token metadata.
     */
    function updateSaleMetadata(uint256 _tokenId, string memory _ipfsHash) public override {
        require(
            isRelayer(msg.sender) || ownerOf(_tokenId) == msg.sender,
            "Only Colle or token owner can update metadata"
        );
        tokenSaleMetadataIPFS[_tokenId] = _ipfsHash;
        emit SecondaryMetadataIPFS(_ipfsHash, _tokenId);
    }

    /**
     * @notice Returns the sale metadata for a token.
     * @param _tokenId The ID of the token to query.
     * @return The IPFS hash of the sale metadata.
     */
    function getSaleMetadata(uint256 _tokenId) public view override returns (string memory) {
        return tokenSaleMetadataIPFS[_tokenId];
    }

    /**
     * @notice Checks if sale metadata is set for a token.
     * @param _tokenId The ID of the token to check.
     * @return True if the token has sale metadata set, false otherwise.
     */
    function isSaleMetadataSet(uint256 _tokenId) public view override returns (bool) {
        return keccak256(bytes(tokenSaleMetadataIPFS[_tokenId])) != keccak256(bytes(""));
    }

    /**
     * @notice Approves an address to transfer a specific token.
     * @param _from The current owner of the token.
     * @param _to The address to approve.
     * @param _tokenId The ID of the token to approve.
     * @param _deadline The time at which the approval will expire.
     * @param _signature The signature of the approved address.
     */
    function permitApprove(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _deadline,
        bytes memory _signature
    )
        public
        override
        isValidSignature(_from, _getPermitApproveHash(_from, _to, _tokenId, _deadline), _deadline, _signature)
    {
        address owner = ERC721.ownerOf(_tokenId);
        require(_to != owner, "ERC721: approval to current owner");
        require(
            _from == owner || isApprovedForAll(owner, _from),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(_to, _tokenId);
    }

    /**
     * @notice Transfers a token from one address to another, verifying the validity of a signature.
     * @param _from The current owner of the token.
     * @param _to The address to receive the token.
     * @param _tokenId The ID of the token to transfer.
     * @param _deadline The time at which the transfer will expire.
     * @param _signature The signature of the owner of the token.
     */
    function permitSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _deadline,
        bytes memory _signature
    )
        public
        override
        isValidSignature(_from, _getPermitSafeTransferHash(_from, _to, _tokenId, _deadline), _deadline, _signature)
    {
        _safeTransfer(_from, _to, _tokenId, "");
    }

    /**
     * @notice Returns the ID of the next token that will be minted.
     * @return The ID of the next token.
     */
    function getNextTokenId() public view returns (uint256) {
        return nextTokenId;
    }

    /**
     * @notice Checks if the contract implements an interface.
     * @param _interfaceId The ID of the interface.
     * @return True if the contract implements the interface, false otherwise.
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(AccessControl, IERC165, ERC721URIStorage) returns (bool) {
        return
            _interfaceId == type(IColleCollection).interfaceId ||
            ERC721URIStorage.supportsInterface(_interfaceId) ||
            AccessControl.supportsInterface(_interfaceId);
    }

    /**
     * @notice Transfers a token from one address to another.
     * @dev In order to prevent mirrored assets from being traded on 3rd party markets, only direct transfer or Marketplace vault transfer cause call transferFrom.
     * @param _from The current owner of the token.
     * @param _to The address to receive the token.
     * @param _tokenId The ID of the token to transfer.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override(ERC721, IERC721) onlyOwnerApprovedEOAOrVault(_tokenId) {
        _transfer(_from, _to, _tokenId);
    }

    /**
     * @notice Safely transfers a token from one address to another.
     * @dev In order to prevent mirrored assets from being traded on 3rd party markets, only direct transfer or Marketplace vault transfer cause call safeTransferFrom.
     * @param _from The current owner of the token.
     * @param _to The address to receive the token.
     * @param _tokenId The ID of the token to transfer.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override(ERC721, IERC721) onlyOwnerApprovedEOAOrVault(_tokenId) {
        _safeTransfer(_from, _to, _tokenId, "");
    }

    /**
     * @notice Safely transfers a token from one address to another.
     * @dev In order to prevent mirrored assets from being traded on 3rd party markets, only direct transfer or Marketplace vault transfer cause call safeTransferFrom.
     * @param _from The current owner of the token.
     * @param _to The address to receive the token.
     * @param _tokenId The ID of the token to transfer.
     * @param _data Additional data with no specified format.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual override(ERC721, IERC721) onlyOwnerApprovedEOAOrVault(_tokenId) {
        _safeTransfer(_from, _to, _tokenId, _data);
    }

    /**
     * @dev Internal function to get the expected EIP-712 signed hash to permit approving a token transfer
     * @param _from The current owner of the token.
     * @param _to The address to approve.
     * @param _tokenId The ID of the token to approve.
     * @param _deadline The deadline for the permit.
     */
    function _getPermitApproveHash(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _deadline
    ) private view returns (bytes32) {
        uint256 nonce = nonces(_from);
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01", // EIP191: Indicates EIP712
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Approve(address from,address to,uint256 tokenId,uint256 deadline,uint256 nonce)"
                            ),
                            _from,
                            _to,
                            _tokenId,
                            _deadline,
                            nonce
                        )
                    )
                )
            );
    }

    /**
     * @dev Internal function to get the expected EIP-712 signed hash to permit transfering a token
     * @param _from The current owner of the token.
     * @param _to The address to transfer to.
     * @param _tokenId The ID of the token to transfer.
     * @param _deadline The deadline for the permit.
     */
    function _getPermitSafeTransferHash(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _deadline
    ) private view returns (bytes32) {
        uint256 nonce = nonces(_from);
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01", // EIP191: Indicates EIP712
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            keccak256(
                                "SafeTransfer(address from,address to,uint256 tokenId,uint256 deadline,uint256 nonce)"
                            ),
                            _from,
                            _to,
                            _tokenId,
                            _deadline,
                            nonce
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IMarketHubRegistrar} from "../IMarketHubRegistrar.sol";

/// @title Interface for ColleCollection
/// @notice This interface includes the necessary methods for managing ColleCollection NFTs.
interface IColleCollection is IMarketHubRegistrar, IERC721 {
    /**
     * @dev Emitted when a token is minted, we freeze the URI per OpenSea's metadata standard.
     */
    event PermanentURI(string _value, uint256 indexed _id);

    /**
     * @dev Emitted when the off-chain metadata for a token has been updated.
     */
    event SecondaryMetadataIPFS(string _ipfsHash, uint256 indexed _id);

    /// @notice Mints a new NFT.
    /// @param _uri The URI of the NFT's metadata.
    /// @param _receiver The address to receive the minted NFT.
    function mint(string memory _uri, address _receiver) external;

    /// @notice Updates the sale metadata of a specific NFT.
    /// @param _tokenId The ID of the NFT to update.
    /// @param _uri The new URI of the sale metadata.
    function updateSaleMetadata(uint256 _tokenId, string memory _uri) external;

    /// @notice Gets the sale metadata of a specific NFT.
    /// @param _tokenId The ID of the NFT to query.
    /// @return The URI of the sale metadata.
    function getSaleMetadata(uint256 _tokenId) external view returns (string memory);

    /// @notice Checks if the sale metadata of a specific NFT is set.
    /// @param _tokenId The ID of the NFT to query.
    /// @return True if the sale metadata is set, false otherwise.
    function isSaleMetadataSet(uint256 _tokenId) external view returns (bool);

    /// @notice Allows a signer to approve a transfer on their behalf using a signature.
    /// @param _from The owner address of the NFT to approve.
    /// @param _to The approved address.
    /// @param _tokenId The ID of the NFT to approve.
    /// @param _deadline The time until the approval is valid.
    /// @param _signature The signature proving the signer's intent.
    function permitApprove(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _deadline,
        bytes memory _signature
    ) external;

    /// @notice Allows a signer to transfer a NFT on their behalf using a signature.
    /// @param _from The current owner address of the NFT.
    /// @param _to The address to receive the NFT.
    /// @param _tokenId The ID of the NFT to transfer.
    /// @param _deadline The time until the transfer is valid.
    /// @param _signature The signature proving the signer's intent.
    function permitSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _deadline,
        bytes memory _signature
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IColleCollection} from "./IColleCollection.sol";

/// @title ICollectionRegistry
/// @notice Interface for the CollectionRegistry contract.
/// @dev This interface lists all the external functions implemented in the CollectionRegistry contract.
interface ICollectionRegistry {
    /**
     * @dev Emitted when a collection is registered.
     */
    event RegisteredCollection(address collection);

    /**
     * @dev Emitted when a collection is unregistered.
     */
    event UnregisteredCollection(address collection);

    /// @notice Registers a new collection.
    /// @param _collection The address of the collection to register.
    function registerCollection(address _collection) external;

    /// @notice Unregisters an existing collection.
    /// @param _collection The address of the collection to unregister.
    function unregisterCollection(address _collection) external;

    /// @notice Checks if a collection is registered.
    /// @param _collection The address of the collection to check.
    /// @return A boolean indicating whether the collection is registered or not.
    function isERC721Registered(address _collection) external view returns (bool);

    /// @notice Returns the collection interface for a registered collection.
    /// @param _collection The address of the collection.
    /// @return The interface of the registered collection.
    function getCollection(address _collection) external view returns (IColleCollection);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {MarketHubRegistrar, AccessControl} from "../MarketHubRegistrar.sol";
import {ICurrency, IERC20, IERC165} from "./ICurrency.sol";

/// @title BaseCurrency
/// @notice This contract is an abstraction for any ERC20 token to convert any value to a USDC equivalency for market calculations.
abstract contract BaseCurrency is ICurrency, MarketHubRegistrar {
    // The ERC20 token to be used as the currency
    IERC20 internal immutable erc20;

    /// @notice Constructor sets the address for the ERC20 token.
    /// @param _erc20 The address of the ERC20 token to be used as the currency.
    constructor(address _erc20) {
        erc20 = IERC20(_erc20);
    }

    /// @notice Returns the ERC20 token that is being used as the currency.
    /// @return The ERC20 token being used as the currency.
    function getERC20() public view returns (IERC20) {
        return erc20;
    }

    /**
     * @notice Checks if the contract implements an interface.
     * @param _interfaceId The ID of the interface.
     * @return True if the contract implements the interface, false otherwise.
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(AccessControl, IERC165) returns (bool) {
        return
            _interfaceId == type(ICurrency).interfaceId ||
            _interfaceId == type(IERC165).interfaceId ||
            AccessControl.supportsInterface(_interfaceId);
    }

    /// @notice Returns the estimated value in USDC of an amount of the currency.
    /// @dev This function is virtual and must be implemented in child contracts.
    /// @param _amount The amount of currency to estimate the value of.
    /// @return The estimated value in USDC of the specified amount of currency.
    function getEstimatedUSDCValue(uint256 _amount) public view virtual returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title ICurrency
/// @notice This interface represents an abstraction for any ERC20 token to convert any value to a USDC equivalency for market calculations.
interface ICurrency is IERC165 {
    /// @notice Returns the ERC20 token that is being used as the currency.
    /// @return The ERC20 token being used as the currency.
    function getERC20() external view returns (IERC20);

    /// @notice Returns the estimated value in USDC of an amount of the currency.
    /// @dev This function is virtual and must be implemented in child contracts.
    /// @param _amount The amount of currency to estimate the value of.
    /// @return The estimated value in USDC of the specified amount of currency.
    function getEstimatedUSDCValue(uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {BaseCurrency} from "./BaseCurrency.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ICurrencyRegistry
/// @notice This is the interface for the Currency Registry contract.
interface ICurrencyRegistry {
    /**
     * @dev Emitted when a currency is registered.
     */
    event RegisteredCurrency(address currency, address erc20);

    /**
     * @dev Emitted when a currency is unregistered.
     */
    event UnregisteredCurrency(address currency, address erc20);

    /// @notice Registers an ERC20 token as a base currency.
    /// @param _currency The address of the BaseCurrency contract associated with the ERC20 token.
    function registerERC20(address _currency) external;

    /// @notice Unregisters an ERC20 token from being a base currency.
    /// @param _currency The address of the BaseCurrency contract associated with the ERC20 token.
    function unregisterERC20(address _currency) external;

    /// @notice Retrieves the BaseCurrency contract associated with a specific ERC20 token.
    /// @param _erc20 The address of the ERC20 token.
    /// @return The BaseCurrency contract associated with the ERC20 token.
    function getCurrencyByERC20(address _erc20) external view returns (BaseCurrency);

    /// @notice Retrieves the ERC20 token associated with a specific BaseCurrency contract.
    /// @param _currency The address of the BaseCurrency contract.
    /// @return The ERC20 token associated with the BaseCurrency contract.
    function getERC20ByCurrency(address _currency) external view returns (IERC20);

    /// @notice Checks if an ERC20 token is registered as a base currency.
    /// @param _erc20 The address of the ERC20 token.
    /// @return true if the ERC20 token is registered, false otherwise.
    function isERC20Registered(address _erc20) external view returns (bool);

    /// @notice Gets all registered ERC20 tokens.
    /// @return An array of addresses of the registered ERC20 tokens.
    function getERC20s() external view returns (address[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IMarketHubRegistrar} from "../IMarketHubRegistrar.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IEscrow
 * @notice This interface outlines the functions necessary for an escrow system in a marketplace trading ERC721 and ERC20 tokens.
 * @dev Any contract implementing this interface can act as an escrow in the marketplace.
 */
interface IEscrow is IMarketHubRegistrar, IERC165 {
    /**
     * @dev Emitted when a sale is created.
     */
    event CreateSale(
        uint256 saleId,
        State state,
        address buyer,
        address spender,
        address erc20,
        uint256 price,
        address seller,
        address erc721,
        uint256 tokenId,
        string metadata
    );

    /**
     * @dev Emitted when a sale's state is updated.
     */
    event UpdateSale(uint256 saleId, State newState);

    /**
     * @dev Emitted when a royalty is paid out.
     */
    event RoyaltyPayout(uint256 saleId, address receiver, uint256 amount);

    /**
     * @dev Emitted when a commission is paid out.
     */
    event CommissionPayout(uint256 saleId, address receiver, uint256 amount);

    /**
     * @dev Emitted when a sale is complete.
     */
    event SaleComplete(uint256 saleId, uint256 payoutAmount);

    /**
     * @dev Emitted when a sale is cancelled.
     */
    event SaleCancelled(uint256 saleId, address erc20ReturnedTo, address erc721ReturnedTo);

    /**
     * @dev Emitted when the challenge window for buyers is changed.
     */
    event BuyerChallengeWindowChanged(uint256 numberOfHours);

    /**
     * @dev Emitted when the funding window for a sale is changed.
     */
    event SaleFundingWindowChanged(uint256 numberOfHours);

    /**
     * @notice Represents the different states a sale can be in.
     */
    enum State {
        AwaitingSettlement,
        AwaitingERC20Deposit,
        PendingSale,
        ProcessingSale,
        ShippingToBuyer,
        Received,
        ShippingToColleForAuthentication,
        ColleProcessingSale,
        ShippingToColleForDispute,
        IssueWithDelivery,
        IssueWithProduct,
        SaleCancelled,
        SaleSuccess
    }

    /**
     * @notice Represents a sale.
     */
    struct Sale {
        uint256 id;
        address buyer;
        address spender;
        address erc20;
        uint256 price;
        address seller;
        address erc721;
        uint256 tokenId;
        State state;
        uint256 createdTimestamp;
        uint256 receivedTimestamp;
    }

    /**
     * @notice Sets the time window during which buyers can challenge a sale.
     * @param _hours The new challenge window in hours.
     */
    function setBuyerChallengeWindow(uint256 _hours) external;

    /**
     * @notice Returns the current challenge window for buyers.
     * @return uint256 The challenge window in hours.
     */
    function buyerChallengeWindow() external view returns (uint256);

    /**
     * @notice Sets the time window during which a sale can be funded.
     * Can only be called by the colle.
     * @param _hours The new funding window in hours.
     */
    function setSaleFundingWindow(uint256 _hours) external;

    /**
     * @notice Returns the current funding window for buyers.
     * @return uint256 The funding window in hours.
     */
    function saleFundingWindow() external view returns (uint256);

    /**
     * @notice Creates a new sale.
     * @param _buyer The buyer's address.
     * @param _spender The address spending the ERC20 tokens.
     * @param _erc20 The address of the ERC20 token being used as currency.
     * @param _price The price in ERC20 tokens.
     * @param _seller The seller's address.
     * @param _erc721 The address of the ERC721 token being sold.
     * @param _tokenId The id of the ERC721 token being sold.
     * @param _payNow Whether the buyer pays immediately or not.
     */
    function createSale(
        address _buyer,
        address _spender,
        address _erc20,
        uint256 _price,
        address _seller,
        address _erc721,
        uint256 _tokenId,
        bool _payNow
    ) external;

    /**
     * @notice Returns details of a sale.
     * @param _saleId The id of the sale.
     * @return Sale The details of the sale.
     */
    function getSale(uint256 _saleId) external view returns (Sale memory);

    /**
     * @notice Checks if a particular ERC721 token is currently part of an active sale.
     * @param _erc721 The address of the ERC721 token.
     * @param _tokenId The id of the ERC721 token.
     * @return bool Whether the token is part of an active sale or not.
     */
    function hasActiveSale(address _erc721, uint256 _tokenId) external view returns (bool);

    /**
     * @notice Updates the state of a sale.
     * @param _saleId The id of the sale.
     * @param _newState The new state of the sale.
     */
    function updateSale(uint256 _saleId, State _newState) external;

    /**
     * @notice Allows a signer to permit the update of a sale's state.
     * @param _signer The address of the signer.
     * @param _saleId The id of the sale.
     * @param _newState The new state of the sale.
     * @param _deadline The time by which the update must be done.
     * @param _signature The signer's signature.
     */
    function permitUpdateSale(
        address _signer,
        uint256 _saleId,
        State _newState,
        uint256 _deadline,
        bytes memory _signature
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IEscrow} from "./IEscrow.sol";

/**
 * @title IEscrowRegistry
 * @notice Interface for fetching the market's Escrow contract
 */
interface IEscrowRegistry {
    /**
     * @dev Emitted when a escrow is registered.
     */
    event RegisteredEscrow(address escrow);

    /**
     * @notice Returns the market's Escrow contract
     * @return The market's Escrow contract
     */
    function getEscrow() external view returns (IEscrow);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IMarketRegistry} from "./markets/IMarketRegistry.sol";
import {ICurrencyRegistry} from "./currencies/ICurrencyRegistry.sol";
import {IRoyaltyRegistry} from "./royalties/IRoyaltyRegistry.sol";
import {IKYCRegistry} from "./kycs/IKYCRegistry.sol";
import {IVaultRegistry} from "./vaults/IVaultRegistry.sol";
import {IEscrowRegistry} from "./escrow/IEscrowRegistry.sol";
import {IUpgradeGatekeeper} from "./upgrade-gatekeeper/IUpgradeGatekeeper.sol";
import {ICollectionRegistry} from "./collections/ICollectionRegistry.sol";

/**
 * @title IMarketHub
 * @dev The IMarketHub contract provides an interface that encompasses
 * various other registries like Market, Currency, Royalty, KYC, Vault, Escrow, Collection
 * and some additional functionalities specifically for managing the MarketHub.
 */
interface IMarketHub is
    IMarketRegistry,
    ICurrencyRegistry,
    IRoyaltyRegistry,
    IKYCRegistry,
    IVaultRegistry,
    IEscrowRegistry,
    ICollectionRegistry
{
    /**
     * @dev Emitted when a upgradeGatekeeper is registered.
     */
    event RegisteredUpgradeGatekeeper(address upgradeGatekeeper);

    /**
     * @dev Emitted when the minimum price is changed.
     */
    event MinimumPriceChanged(uint256 _minUSDCPrice);

    /**
     * @dev Notifies that a particular sale for a ERC721 has closed (i.e. successfully sold, fault/not as described, or lost/damaged in shipment)
     * @param _saleId The id of the sale that has closed.
     */
    function notifySaleClosed(uint256 _saleId) external;

    /**
     * @dev Sets the minimum price in USDC for an asset.
     * @param _minUSDCPrice Minimum price in USDC.
     */
    function setMinUSDCPrice(uint256 _minUSDCPrice) external;

    /**
     * @dev Returns the current minimum price in USDC for an asset.
     * @return Minimum price in USDC.
     */
    function getMinUSDCPrice() external view returns (uint256);

    /**
     * @dev Returns the address of the Upgrade Gatekeeper contract.
     * @return Address of the Upgrade Gatekeeper.
     */
    function getUpgradeGatekeeper() external view returns (IUpgradeGatekeeper);

    /**
     * @dev Checks if new sales are allowed in the market.
     * @return Boolean value representing if new sales are allowed.
     */
    function allowNewSales() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

/**
 * @title IMarketHubRegistrar
 * @dev This contract defines the interface for registering and unregistering to the MarketHub.
 */
interface IMarketHubRegistrar {
    /**
     * @dev Emitted when a marketHub is registered.
     */
    event RegisteredMarketHub(address marketHub);

    /**
     * @dev Emitted when a marketHub is registered.
     */
    event UnregisteredMarketHub(address marketHub);

    /**
     * @dev Register the calling contract to the MarketHub.
     * Only contracts that meet certain criteria may successfully register.
     */
    function register() external;

    /**
     * @dev Unregister the calling contract from the MarketHub.
     * Only contracts that are currently registered can successfully unregister.
     */
    function unregister() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

enum AccountStatus {
    ACTIVE,
    HAULTED,
    BANNED
}

struct Account {
    address account;
    bytes32 tier; // e.g. keccak("Black"), keccak("Gold"), keccak("Platinum"), keccak("Green")
    AccountStatus status;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Account, AccountStatus} from "./Account.sol";

/// @title KYC Registry interface
/// @dev This interface includes all the functions to manage KYC verified accounts.
interface IKYCRegistry {
    /**
     * @dev Emitted when a account is registered.
     */
    event RegisteredAccount(address account, bytes32 tier);

    /**
     * @dev Emitted when a account's tier is updated
     */
    event UpdatedAccountTier(address account, bytes32 tier);

    /**
     * @dev Emitted when a account's status is updated
     */
    event UpdatedAccountStatus(address account, AccountStatus status);

    /// @notice Register a new account for KYC process
    /// @dev Register a new account and associate it with a tier
    /// @param _account The address of the account to register
    /// @param _tier The tier level of the account
    function registerAccount(address _account, bytes32 _tier) external;

    /// @notice Update the tier level of an existing account
    /// @dev Updates the tier level of a registered account
    /// @param _account The address of the account to update
    /// @param _tier The new tier level of the account
    function updateTier(address _account, bytes32 _tier) external;

    /// @notice Temporarily disable an account
    /// @dev Temporarily haults an account
    /// @param _account The address of the account to hault
    function haultAccount(address _account) external;

    /// @notice Reactivate a temporarily disabled account
    /// @dev Unhaults a haulted account
    /// @param _account The address of the account to unhault
    function unhaultAccount(address _account) external;

    /// @notice Permanently ban an account
    /// @dev Bans an account from the system
    /// @param _account The address of the account to ban
    function banAccount(address _account) external;

    /// @notice Unban a previously banned account
    /// @dev Unbans a banned account
    /// @param _account The address of the account to unban
    function unbanAccount(address _account) external;

    /// @notice Get the details of an account
    /// @dev Fetches the Account details for the given account address
    /// @param _account The address of the account
    /// @return The Account struct containing account details
    function getAccount(address _account) external view returns (Account memory);

    /// @notice Checks if an account is registered
    /// @dev Checks the registry if an account address is registered
    /// @param _account The address of the account
    /// @return A boolean value indicating if the account is registered
    function isAccountRegistered(address _account) external view returns (bool);

    /// @notice Checks if an account is active
    /// @dev Checks the status of an account if it is active
    /// @param _account The address of the account
    /// @return A boolean value indicating if the account is active
    function isAccountActive(address _account) external view returns (bool);

    /// @notice Checks if an account is haulted
    /// @dev Checks the status of an account if it is haulted
    /// @param _account The address of the account
    /// @return A boolean value indicating if the account is haulted
    function isAccountHaulted(address _account) external view returns (bool);

    /// @notice Checks if an account is banned
    /// @dev Checks the status of an account if it is banned
    /// @param _account The address of the account
    /// @return A boolean value indicating if the account is banned
    function isAccountBanned(address _account) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IMarketHub} from "./IMarketHub.sol";
import {MarketAccess, AccessControl} from "../utils/MarketAccess.sol";
import {IMarketHubRegistrar} from "./IMarketHubRegistrar.sol";

/**
 * @title MarketHubRegistrar
 * @dev This contract provides the functionality to register and unregister to the MarketHub.
 * Contracts that inherit from this contract can be registered and unregistered from the MarketHub.
 */
contract MarketHubRegistrar is IMarketHubRegistrar, MarketAccess {
    // The instance of the MarketHub that the contract is registered to
    IMarketHub public marketHub;

    /**
     * @dev Modifier to allow only the MarketHub contract to perform certain actions.
     */
    modifier onlyMarketHub() {
        require(msg.sender == address(marketHub), "Only MarketHub can call this function");
        _;
    }

    /**
     * @dev Registers the calling contract to the MarketHub.
     * Reverts if the contract is already registered.
     */
    function register() public virtual {
        require(address(marketHub) == address(0), "Market already registered");
        emit RegisteredMarketHub(msg.sender);
        marketHub = IMarketHub(msg.sender);
    }

    /**
     * @dev Unregisters the calling contract from the MarketHub.
     * Reverts if the contract is not registered.
     */
    function unregister() public virtual onlyMarketHub {
        emit UnregisteredMarketHub(address(marketHub));
        marketHub = IMarketHub(address(0));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IMarketHubRegistrar} from "../IMarketHubRegistrar.sol";

/// @title Market Interface
/// @dev Interface for the functionality of a market contract
interface IMarket is IMarketHubRegistrar, IERC165 {
    /**
     * @notice Handles when a token is no longer available
     * @dev Notifies that a particular sale for a ERC721 has closed (i.e. successfully sold, fault/not as described, or lost/damaged in shipment)
     * @param _saleId The id of the sale that has closed.
     */
    function handleSaleClosed(uint256 _saleId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IMarket} from "./IMarket.sol";

/// @title Market Registry interface
/// @dev An interface that defines the methods for the Market Registry
interface IMarketRegistry {
    /**
     * @dev Emitted when a market is registered.
     */
    event RegisteredMarket(address market, bytes32 name);

    /**
     * @dev Emitted when a market is unregistered.
     */
    event UnregisteredMarket(address market, bytes32 name);

    /// @notice Registers a new market
    /// @dev Adds the market to the registry
    /// @param _marketAddress The address of the market to register
    /// @param _marketName The name of the market
    function registerMarket(address _marketAddress, bytes32 _marketName) external;

    /// @notice Unregisters a market
    /// @dev Removes the market from the registry
    /// @param _marketAddress The address of the market to unregister
    /// @param _marketName The name of the market
    function unregisterMarket(address _marketAddress, bytes32 _marketName) external;

    /// @notice Retrieves the address of a market
    /// @dev Finds the market in the registry by its name
    /// @param _marketName The name of the market
    /// @return The address of the market
    function getMarket(bytes32 _marketName) external view returns (address);

    /// @notice Retrieves the names of all markets
    /// @dev Gets a list of all market names in the registry
    /// @return An array of market names
    function getMarketNames() external view returns (bytes32[] memory);

    /// @notice Checks if an address is a registered market
    /// @dev Looks up if a market is in the registry by its address
    /// @param _marketAddress The address of the market
    /// @return A boolean indicating if the market is registered
    function isMarket(address _marketAddress) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {MarketHubRegistrar, AccessControl} from "../MarketHubRegistrar.sol";
import {IRoyalty, IERC165} from "./IRoyalty.sol";

/**
 * @title BaseRoyalty
 * @dev Abstract contract for managing royalties. This contract provides the basis for creating
 * custom royalties models by enabling the derivation of subclasses.
 */
abstract contract BaseRoyalty is IRoyalty, MarketHubRegistrar {
    /**
     * @dev Calculates the basis points for the royalty pool
     * @param _erc20 The address of the ERC20 token
     * @param _totalAmount The total amount of tokens
     * @return royaltyPoolBasisPoints The calculated basis points for the royalty pool
     */
    function getRoyaltyPoolBasisPoints(
        address _erc20,
        uint256 _totalAmount
    ) external view virtual returns (uint256 royaltyPoolBasisPoints);

    /**
     * @dev Calculates the commission basis points
     * @param _erc20 The address of the ERC20 token
     * @param _totalAmount The total amount of tokens
     * @return commissionBasisPoints The calculated commission basis points
     */
    function getCommissionBasisPoints(
        address _erc20,
        uint256 _totalAmount
    ) external view virtual returns (uint256 commissionBasisPoints);

    /**
     * @dev Calculates the royalty and commission amounts
     * @param _erc20 The address of the ERC20 token
     * @param _totalAmount The total amount of tokens
     * @return _royaltyPoolAmount The calculated amount for the royalty pool
     * @return _comissionAmount The calculated commission amount
     */
    function getRoyaltyBreakdown(
        address _erc20,
        uint256 _totalAmount
    ) public view returns (uint256 _royaltyPoolAmount, uint256 _comissionAmount) {
        uint256 royaltyPoolBasisPoints = this.getRoyaltyPoolBasisPoints(_erc20, _totalAmount);
        uint256 commissionBasisPoints = this.getCommissionBasisPoints(_erc20, _totalAmount);

        // We never intend to come close to these numbers
        // but we needed to guard to ensure basis points never exceed 100%
        // If the guard is required, we might as well make it a reasonable-ish number
        // rather than just guard that its under 100% fees
        require(royaltyPoolBasisPoints <= 1000, "Royalty pool basis points cannot be greater than 10%");
        require(commissionBasisPoints <= 2500, "Commission basis points cannot be greater than 25%");

        _royaltyPoolAmount = (_totalAmount * royaltyPoolBasisPoints) / 10000;
        _comissionAmount = (_totalAmount * commissionBasisPoints) / 10000;
    }

    /**
     * @notice Checks if the contract implements an interface.
     * @param _interfaceId The ID of the interface.
     * @return True if the contract implements the interface, false otherwise.
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(AccessControl, IERC165) returns (bool) {
        return
            _interfaceId == type(IRoyalty).interfaceId ||
            _interfaceId == type(IERC165).interfaceId ||
            AccessControl.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IRoyalty
 * @dev Interface for managing royalties. This interface provides the basis for creating
 * custom royalties models by enabling the derivation of subclasses.
 */
interface IRoyalty is IERC165 {
    /**
     * @dev Calculates the basis points for the royalty pool
     * @param _erc20 The address of the ERC20 token
     * @param _totalAmount The total amount of tokens
     * @return royaltyPoolBasisPoints The calculated basis points for the royalty pool
     */
    function getRoyaltyPoolBasisPoints(
        address _erc20,
        uint256 _totalAmount
    ) external view returns (uint256 royaltyPoolBasisPoints);

    /**
     * @dev Calculates the commission basis points
     * @param _erc20 The address of the ERC20 token
     * @param _totalAmount The total amount of tokens
     * @return commissionBasisPoints The calculated commission basis points
     */
    function getCommissionBasisPoints(
        address _erc20,
        uint256 _totalAmount
    ) external view returns (uint256 commissionBasisPoints);

    /**
     * @dev Calculates the royalty and commission amounts
     * @param _erc20 The address of the ERC20 token
     * @param _totalAmount The total amount of tokens
     * @return _royaltyPoolAmount The calculated amount for the royalty pool
     * @return _comissionAmount The calculated commission amount
     */
    function getRoyaltyBreakdown(
        address _erc20,
        uint256 _totalAmount
    ) external view returns (uint256 _royaltyPoolAmount, uint256 _comissionAmount);

    /**
     * @dev Determines whether a product sold through this royalty tier requires manual authentication or not
     * @return True if the product requires manual authentication, false otherwise
     */
    function requiresManualAuthentication() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IRoyaltyPool
 * @dev Interface for managing a pool of previous owners to pay royalties to. The pool includes an initial owner and recent owners.
 */
interface IRoyaltyPool is IERC165 {
    /**
     * @notice Emitted when the weight initial owners get in the pool is updated
     */
    event InitialOwnerWeight(uint weight);

    /**
     * @notice Emitted when the initial owner or recent owners updates for a token
     */
    event PoolUpdated(address indexed _erc721, uint256 indexed _tokenId, address initialOwner, address[4] recentOwners);

    /**
     * @dev Set initial owner's weight
     * @param _weight New weight to set for initial owner
     */
    function setInitialOwnerWeight(uint _weight) external;

    /**
     * @dev Tracks a new owner of a token
     * @param _erc721 The address of the token
     * @param _tokenId The ID of the token
     * @param _owner The address of the new owner
     */
    function trackNewOwner(address _erc721, uint256 _tokenId, address _owner) external;

    /**
     * @dev Returns the weight of the initial owner
     */
    function getInitialOwnerWeight() external view returns (uint);

    /**
     * @dev Returns the initial owner of a given token
     * @param _erc721 The address of the token
     * @param _tokenId The ID of the token
     */
    function getInitialOwner(address _erc721, uint256 _tokenId) external view returns (address);

    /**
     * @dev Returns the recent owners of a given token
     * @param _erc721 The address of the token
     * @param _tokenId The ID of the token
     */
    function getRecentOwners(address _erc721, uint256 _tokenId) external view returns (address[4] memory);

    /**
     * @dev Returns the total pool shares for a given token
     * @param _erc721 The address of the token
     * @param _tokenId The ID of the token
     */
    function totalPoolShares(address _erc721, uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {BaseRoyalty} from "./BaseRoyalty.sol";
import {RoyaltyPool} from "./RoyaltyPool.sol";

/**
 * @title IRoyaltyRegistry
 * @dev This interface describes the functions exposed by the royalty registry.
 */
interface IRoyaltyRegistry {
    /**
     * @dev Emitted when a royalty is registered.
     */
    event RegisteredRoyalty(address royalty, bytes32 accountTier);

    /**
     * @dev Emitted when a royalty is unregistered.
     */
    event UnregisteredRoyalty(address royalty, bytes32 accountTier);

    /**
     * @dev Emitted when a royalty pool is registered.
     */
    event RegisteredRoyaltyPool(address royaltyPool);

    /**
     * @dev Emitted when the comission payout address has been updated.
     */
    event UpdatedColleComissions(address colleComission);

    /**
     * @dev Register a new royalty.
     * @param _accountTier The tier of the account for which to register the royalty.
     * @param _royalty The address of the royalty contract.
     */
    function registerRoyalty(bytes32 _accountTier, address _royalty) external;

    /**
     * @dev Unregister an existing royalty.
     * @param _accountTier The tier of the account for which to unregister the royalty.
     */
    function unregisterRoyalty(bytes32 _accountTier) external;

    /**
     * @dev Register a new royalty pool.
     * @param _royaltyPool The address of the royalty pool contract.
     */
    function registerRoyaltyPool(address _royaltyPool) external;

    /**
     * @dev Register a new colleCommissions.
     * @param _colleCommissions The address of the colleCommissions contract.
     */
    function registerColleCommissions(address _colleCommissions) external;

    /**
     * @dev Get the royalty of a specific account tier.
     * @param _accountTier The tier of the account for which to get the royalty.
     * @return The royalty contract of the specified account tier.
     */
    function getRoyalty(bytes32 _accountTier) external view returns (BaseRoyalty);

    /**
     * @dev Get the royalty pool.
     * @return The royalty pool contract.
     */
    function getRoyaltyPool() external view returns (RoyaltyPool);

    /**
     * @dev Get the colleComissions.
     * @return The address of the colleComissions contract.
     */
    function getColleComissions() external view returns (address);

    /**
     * @dev Check if a royalty is registered for a specific account tier.
     * @param _accountTier The tier of the account for which to check the royalty.
     * @return True if a royalty is registered for the specified account tier, false otherwise.
     */
    function isRoyaltyRegistered(bytes32 _accountTier) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {MarketHubRegistrar, AccessControl} from "../MarketHubRegistrar.sol";
import {IRoyaltyPool, IERC165} from "./IRoyaltyPool.sol";

/**
 * @title RoyaltyPool
 * @dev Contract for managing a pool of previous owners to pay royalties to. The pool includes an initial owner and recent owners.
 */
contract RoyaltyPool is IRoyaltyPool, MarketHubRegistrar {
    // Structure representing a Pool with initial owner and recent owners
    struct Pool {
        address initialOwner;
        address[4] recentOwners;
    }

    // Mapping from token address to token Id to Pool
    mapping(address => mapping(uint256 => Pool)) private pools;
    uint private initialOwnerWeight;

    /**
     * @dev Sets initial owner weight as 1 upon contract creation
     */
    constructor() {
        initialOwnerWeight = 1;
        emit InitialOwnerWeight(initialOwnerWeight);
    }

    modifier onlyEscrow() {
        require(msg.sender == address(marketHub.getEscrow()), "Caller is not the escrow");
        _;
    }

    /**
     * @dev Set initial owner's weight
     * @param _weight New weight to set for initial owner
     */
    function setInitialOwnerWeight(uint _weight) external onlyAdmin {
        initialOwnerWeight = _weight;
        emit InitialOwnerWeight(_weight);
    }

    /**
     * @dev Tracks a new owner of a token
     * @param _erc721 The address of the token
     * @param _tokenId The ID of the token
     * @param _owner The address of the new owner
     */
    function trackNewOwner(address _erc721, uint256 _tokenId, address _owner) external onlyEscrow {
        if (pools[_erc721][_tokenId].initialOwner == address(0)) {
            pools[_erc721][_tokenId].initialOwner = _owner;
            emit PoolUpdated(
                _erc721,
                _tokenId,
                pools[_erc721][_tokenId].initialOwner,
                pools[_erc721][_tokenId].recentOwners
            );
            return;
        }

        // If there is no one else in the pool AND the owner is the initialOwner, do not track them as a new owner
        if (pools[_erc721][_tokenId].initialOwner == _owner && pools[_erc721][_tokenId].recentOwners[3] == address(0)) {
            return;
        }

        // Shift the array to the left
        for (uint i = 0; i < 3; i++) {
            pools[_erc721][_tokenId].recentOwners[i] = pools[_erc721][_tokenId].recentOwners[i + 1];
        }
        // Add the new owner to the end
        pools[_erc721][_tokenId].recentOwners[3] = _owner;
        emit PoolUpdated(
            _erc721,
            _tokenId,
            pools[_erc721][_tokenId].initialOwner,
            pools[_erc721][_tokenId].recentOwners
        );
    }

    /**
     * @dev Returns the weight of the initial owner
     */
    function getInitialOwnerWeight() external view returns (uint) {
        return initialOwnerWeight;
    }

    /**
     * @dev Returns the initial owner of a given token
     * @param _erc721 The address of the token
     * @param _tokenId The ID of the token
     */
    function getInitialOwner(address _erc721, uint256 _tokenId) external view returns (address) {
        return pools[_erc721][_tokenId].initialOwner;
    }

    /**
     * @dev Returns the recent owners of a given token
     * @param _erc721 The address of the token
     * @param _tokenId The ID of the token
     */
    function getRecentOwners(address _erc721, uint256 _tokenId) external view returns (address[4] memory) {
        return pools[_erc721][_tokenId].recentOwners;
    }

    /**
     * @dev Returns the total pool shares for a given token
     * @param _erc721 The address of the token
     * @param _tokenId The ID of the token
     */
    function totalPoolShares(address _erc721, uint256 _tokenId) external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < 4; i++) {
            if (pools[_erc721][_tokenId].recentOwners[i] != address(0)) {
                count++;
            }
        }
        return count + initialOwnerWeight;
    }

    /**
     * @notice Checks if the contract implements an interface.
     * @param _interfaceId The ID of the interface.
     * @return True if the contract implements the interface, false otherwise.
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(AccessControl, IERC165) returns (bool) {
        return
            _interfaceId == type(IRoyaltyPool).interfaceId ||
            _interfaceId == type(IERC165).interfaceId ||
            AccessControl.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IUpgradeGatekeeper
 * @dev Interface for the Upgrade Gatekeeper, which manages upgrade targets for contract proxies.
 */
interface IUpgradeGatekeeper is IERC165 {
    /**
     * @dev Emitted when an upgrade target is set for a specific proxy.
     * @param _proxy The address of the proxy.
     * @param _target The address of the upgrade target.
     */
    event UpgradeTargetSet(address indexed _proxy, address indexed _target);

    /**
     * @dev Sets an upgrade target for a specific proxy.
     * @param _proxy The address of the proxy.
     * @param _target The address of the upgrade target.
     */
    function setUpgradeTarget(address _proxy, address _target) external;

    /**
     * @dev Retrieves the current upgrade target for a specific proxy.
     * @param _proxy The address of the proxy.
     * @return The address of the upgrade target.
     */
    function getUpgradeTarget(address _proxy) external view returns (address);

    /**
     * @dev Resets the upgrade target.
     */
    function resetUpgradeTarget() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IMarketHubRegistrar} from "../IMarketHubRegistrar.sol";

/**
 * @title IVault
 * @dev IVault interface defines the functions for managing ERC20 and ERC721 assets.
 * @notice It includes events that are emitted for each function that alters the state of the contract.
 */
interface IVault is IMarketHubRegistrar, IERC165 {
    /**
     * @dev Emitted when an ERC20 token is deposited into the vault.
     */
    event DepositedERC20(address indexed erc20, uint256 amount);

    /**
     * @dev Emitted when an ERC20 token is withdrawn from the vault.
     */
    event WithdrawERC20(address indexed erc20, uint256 amount);

    /**
     * @dev Emitted when an ERC721 token is deposited into the vault.
     */
    event DepositERC721(address indexed erc721, uint256 tokenId);

    /**
     * @dev Emitted when an ERC721 token is withdrawn from the vault.
     */
    event WithdrawERC721(address indexed erc721, uint256 tokenId);

    /**
     * @dev Deposits ERC20 token into the vault.
     * @param _erc20 Address of the ERC20 token.
     * @param _amount Amount of the ERC20 token.
     * @param _sender Address of the sender.
     */
    function depositERC20(address _erc20, uint256 _amount, address _sender) external;

    /**
     * @dev Deposits ERC721 token into the vault.
     * @param _erc721 Address of the ERC721 token.
     * @param _tokenId Token Id of the ERC721 token.
     * @param _sender Address of the sender.
     */
    function depositColleNFT(address _erc721, uint256 _tokenId, address _sender) external;

    /**
     * @dev Withdraws ERC20 token from the vault.
     * @param _erc20 Address of the ERC20 token.
     * @param _amount Amount of the ERC20 token.
     * @param _receiver Address of the receiver.
     */
    function withdrawERC20(address _erc20, uint256 _amount, address _receiver) external;

    /**
     * @dev Withdraws ERC721 token from the vault.
     * @param _erc721 Address of the ERC721 token.
     * @param _tokenId Token Id of the ERC721 token.
     * @param _receiver Address of the receiver.
     */
    function withdrawColleNFT(address _erc721, uint256 _tokenId, address _receiver) external;

    /**
     * @dev Checks the balance of ERC20 token in the vault.
     * @param _erc20 Address of the ERC20 token.
     * @return Returns the balance of the ERC20 token.
     */
    function erc20Balances(address _erc20) external view returns (uint256);

    /**
     * @dev Checks if an ERC721 token is in the vault.
     * @param _erc721 Address of the ERC721 token.
     * @param _tokenId Token Id of the ERC721 token.
     * @return Returns true if the ERC721 token is in the vault, otherwise false.
     */
    function erc721Balances(address _erc721, uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IVault} from "./IVault.sol";

/**
 * @title IVaultRegistry
 * @dev This interface defines a function to get the instance of the deployed vault contract.
 * @notice This registry provides the address of the Vault contract which manages the ERC20 and ERC721 assets.
 */
interface IVaultRegistry {
    /**
     * @dev Emitted when a vault is registered.
     */
    event RegisteredVault(address vault);

    /**
     * @dev Returns the instance of the deployed vault contract.
     * @return Returns the instance of the IVault.
     */
    function getVault() external view returns (IVault);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title MarketAccess
/// @dev This contract provides a role-based access control for the marketplace.
/// It extends OpenZeppelin's AccessControl for role management.
contract MarketAccess is AccessControl {
    /// @notice Role identifier for Relayer role
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    /// @notice Sets the deployer as the initial admin
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Checks if an address is assigned the Relayer role
    /// @param _address The address to check
    /// @return bool Returns true if the address has the Relayer role, false otherwise.
    function isRelayer(address _address) internal view returns (bool) {
        return hasRole(RELAYER_ROLE, _address);
    }

    /// @notice Modifier to restrict the access to only addresses with the Relayer role
    modifier onlyRelayer() {
        require(hasRole(RELAYER_ROLE, msg.sender), "Caller is not a relayer");
        _;
    }

    /// @notice Modifier to restrict the access to only addresses with the Relayer role
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not a admin");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title SignatureValidator
/// @dev This contract validates the signatures associated with EIP-712 typed structures.
contract SignatureValidator {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    // @dev Each address has a nonce that is incremented after each use.
    mapping(address => Counters.Counter) private _nonces;

    // @dev Domain name and version for EIP712 signatures
    // solhint-disable-next-line var-name-mixedcase
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    string private name_;
    string private version_;

    /// @notice Initializes the `DOMAIN_SEPARATOR` value.
    /// @dev The function is meant to be called in the constructor of the contract implementing this logic.
    // solhint-disable-next-line func-name-mixedcase
    function __SignatureValidator_init(string memory _name, string memory _version) internal {
        name_ = _name;
        version_ = _version;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(_name)),
                keccak256(bytes(_version)),
                block.chainid,
                address(this)
            )
        );
    }

    /// @notice Validates a signature.
    /// @dev This modifier checks if the signature associated with a `_permitHash` is valid.
    /// @param _signer The signer's address.
    /// @param _permitHash The permit hash.
    /// @param _deadline The deadline after which the permit is no longer valid.
    /// @param _signature The permit's signature.
    modifier isValidSignature(
        address _signer,
        bytes32 _permitHash,
        uint256 _deadline,
        bytes memory _signature
    ) {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp <= _deadline, "Expired deadline");
        address verifiedSigner = _permitHash.recover(_signature);
        require(verifiedSigner == _signer, "Invalid signature");
        Counters.Counter storage nonce = _nonces[_signer];
        nonce.increment();
        _;
    }

    /// @notice Returns the nonce associated with a user.
    /// @dev The nonce is incremented after each use.
    /// @param _user The user's address.
    /// @return Returns the current nonce value.
    function nonces(address _user) public view returns (uint256) {
        return _nonces[_user].current();
    }

    /// @notice Returns the EIP712 domain separator components.
    /// @dev This can be used to verify the domain of the EIP712 signature.
    /// @return name The domain name.
    /// @return version The domain version.
    /// @return chainId The current chain ID.
    /// @return verifyingContract The address of the verifying contract.
    function eip712Domain()
        public
        view
        virtual
        returns (string memory name, string memory version, uint256 chainId, address verifyingContract)
    {
        return (name_, version_, block.chainid, address(this));
    }
}