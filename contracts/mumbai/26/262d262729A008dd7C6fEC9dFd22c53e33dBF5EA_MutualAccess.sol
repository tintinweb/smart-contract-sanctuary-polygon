// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./access/MarketplaceAccess1155IPFS.sol";
import "./lib/IterableAddressKeyToValueMap.sol";

contract MutualAccess is MarketplaceAccess1155IPFS, Ownable, ReentrancyGuard {
    using IterableAddressKeyToValueMap for IterableAddressKeyToValueMap.Map;

    uint256 private _anticDefaultPrimaryFeesPercent; // Global fee that Antic collects
    uint256 private _anticDefaultSecondaryFeesPercent;
    address public anticAddress; // Supervise the contract
    uint256 public contentCount; // Number of created contents

    uint16 private constant _PERCENTAGE_DIVIDER = 10000;
    uint16 private constant _MAX_RECIPIENTS = 10000;
    uint16 private constant _MAX_TICKET_TIERS = 1000;
    uint256 private constant _MAX_ANTIC_PRIMARY_FEES_PERCENTAGE = 5000;
    uint256 private constant _MAX_ANTIC_SECONDARY_FEES_PERCENTAGE = 1000;
    uint256 private constant _MAX_CREATOR_PRIMARY_FEES_PERCENTAGE = 9800;
    uint256 private constant _MAX_CREATOR_SECONDARY_FEES_PERCENTAGE = 1000;
    uint256 private constant _UINT256_MAX = type(uint256).max;

    /// Manager role identifier
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // Describe a fee recipient
    struct RoyaltyRecipient {
        address recipient;
        uint256 feePercentage; // 10000 -> 100.00%
    }

    struct FeePercents {
        // 10000 -> 100.00%
        uint256 primaryPercent;
        uint256 secondaryPercent;
    }

    struct TicketTier {
        uint256 ticketPrice;
        uint256 initialTicketSupply;
        uint256 currentTicketSupply;
    }

    struct TicketTierInput {
        uint256 ticketPrice;
        uint256 initialTicketSupply;
    }

    // Describe a content
    struct Content {
        TicketTier[] tickets;
        bool primarySaleEnded;
        address contentOwnerAddress;
        FeePercents royalties;
        FeePercents anticFees;
        RoyaltyRecipient[] royaltyRecipients;
    }

    // Maps content id + seller address to secondary ticket price
    IterableAddressKeyToValueMap.Map private _secondaryTicketPrices;
    // Maps content id to content
    mapping(uint256 => Content) private _content;

    /// Only the content creator can call this function
    error OnlyContentCreator();
    /// Failed due to the primary sale not ended
    error PrimarySaleNotEnded();
    /// The ticket is not for sale
    error TicketNotForSale();
    /// The caller/seller has an insufficient amount of tickets
    error InsufficientTickets();
    /// The caller has an insufficient amount of funds
    error InsufficientFunds();
    /// Called with an invalid argument
    error InvalidArgument();
    /// Ticket for the content already sold so cannot change the antic fee for the content
    error CannotReassignContentFees();
    /// ticket holder trying to purchase another ticket
    error UserAlreadyHoldsTicket();
    /// Only the owner or one of the managers can call this
    error OnlyOwnerOrManager();
    /// Only antic can call this
    error OnlyAntic();

    constructor(
        address owner,
        address antic,
        uint256 anticPrimaryFeesPercentage_,
        uint256 anticSecondaryFeesPercentage_,
        address[] memory managers,
        address[] memory marketplaces
    ) {
        transferOwnership(owner);

        anticAddress = antic;
        contentCount = 0;

        // Check that the Antic fees don't exceed the maximum allowed
        _illegalFeePercentageGuard(
            anticPrimaryFeesPercentage_,
            anticSecondaryFeesPercentage_,
            _MAX_ANTIC_PRIMARY_FEES_PERCENTAGE,
            _MAX_ANTIC_SECONDARY_FEES_PERCENTAGE
        );

        _anticDefaultPrimaryFeesPercent = anticPrimaryFeesPercentage_;
        _anticDefaultSecondaryFeesPercent = anticSecondaryFeesPercentage_;

        // Grant managers their role
        // Also give antic the manager role
        _grantRole(MANAGER_ROLE, managers);
        _grantRole(MANAGER_ROLE, antic);

        // Grant marketplaces their role
        _grantRole(MARKETPLACE_ROLE, marketplaces);

        // Grant Antic the default admin role
        _grantRole(DEFAULT_ADMIN_ROLE, antic);
    }

    modifier onlyContentOwner(uint256 contentId) {
        if (msg.sender != _content[contentId].contentOwnerAddress)
            revert OnlyContentCreator();
        _;
    }

    modifier onlyOwnerOrManager() {
        if (
            owner() != msg.sender && hasRole(MANAGER_ROLE, msg.sender) == false
        ) {
            revert OnlyOwnerOrManager();
        }
        _;
    }

    modifier onlyAntic() {
        if (msg.sender != anticAddress) {
            revert OnlyAntic();
        }
        _;
    }

    function getContentTickets(uint256 contentId)
        external
        view
        returns (TicketTier[] memory)
    {
        return _content[contentId].tickets;
    }

    function getTotalRemainingTicketSupply(uint256 contentId)
        public
        view
        returns (uint256 totalAmount)
    {
        totalAmount = 0;
        for (
            uint256 ticketIndex = 0;
            ticketIndex < _content[contentId].tickets.length;
            ticketIndex++
        ) {
            totalAmount += _content[contentId]
                .tickets[ticketIndex]
                .currentTicketSupply;
        }
    }

    function _getInitialTicketSupply(uint256 contentId)
        internal
        view
        returns (uint256 totalAmount)
    {
        totalAmount = 0;
        for (
            uint256 ticketIndex = 0;
            ticketIndex < _content[contentId].tickets.length;
            ticketIndex++
        ) {
            totalAmount += _content[contentId]
                .tickets[ticketIndex]
                .initialTicketSupply;
        }
    }

    function addNewContent(
        TicketTierInput[] calldata tickets,
        RoyaltyRecipient[] calldata royaltyRecipients,
        FeePercents calldata royalties,
        uint256 ipfsUri,
        address contentCreator
    ) external onlyOwnerOrManager {
        // Check that the content creator fees don't exceed the maximum allowed
        _illegalFeePercentageGuard(
            royalties.primaryPercent,
            royalties.secondaryPercent,
            _MAX_CREATOR_PRIMARY_FEES_PERCENTAGE,
            _MAX_CREATOR_SECONDARY_FEES_PERCENTAGE
        );

        if (tickets.length > _MAX_TICKET_TIERS) {
            revert InvalidArgument();
        }

        if (royaltyRecipients.length > _MAX_RECIPIENTS) {
            revert InvalidArgument();
        }

        if (
            _checkIllegalFeeAmount(
                royalties,
                _anticDefaultPrimaryFeesPercent,
                _anticDefaultSecondaryFeesPercent
            )
        ) {
            revert InvalidArgument();
        }

        contentCount++;
        uint256 newContentId = contentCount;

        // Verify that the fee percentages add up to 100%
        if (isFeeRecipientsValid(royaltyRecipients) == false)
            revert InvalidArgument();

        _setIpfsUri(newContentId, ipfsUri);
        _content[newContentId].primarySaleEnded = false;

        for (uint256 i = 0; i < royaltyRecipients.length; i++) {
            _content[newContentId].royaltyRecipients.push(royaltyRecipients[i]);
        }
        for (uint256 i = 0; i < tickets.length; i++) {
            TicketTier memory t;
            t.initialTicketSupply = tickets[i].initialTicketSupply;
            t.currentTicketSupply = tickets[i].initialTicketSupply;
            t.ticketPrice = tickets[i].ticketPrice;
            _content[newContentId].tickets.push(t);
        }

        // feeRecipientsMap[newContentId].length = new FeeRecipient[feeRecipients.length];
        _content[newContentId].contentOwnerAddress = contentCreator;
        _content[newContentId].royalties = royalties;
        _content[newContentId]
            .anticFees
            .primaryPercent = _anticDefaultPrimaryFeesPercent;
        _content[newContentId]
            .anticFees
            .secondaryPercent = _anticDefaultSecondaryFeesPercent;

        // Mint all the tickets to the creator
        _mint(
            contentCreator,
            newContentId,
            _getInitialTicketSupply(newContentId),
            ""
        );

        // Grant permission to contract to transfer the caller’s tokens
        if (this.isApprovedForAll(contentCreator, address(this)) == false) {
            _setApprovalForAll(contentCreator, address(this), true);
        }
    }

    // Set the content's owner
    // Must be called with the new desired content owner address and fee address
    // Note: Can only be called by the current content owner
    function setContentOwner(
        uint256 contentId,
        address contentOwnerAddress,
        RoyaltyRecipient[] calldata feeRecipients
    ) external onlyContentOwner(contentId) {
        if (_content[contentId].primarySaleEnded == false)
            revert PrimarySaleNotEnded();
        if (isFeeRecipientsValid(feeRecipients) == false)
            revert InvalidArgument();

        _content[contentId].contentOwnerAddress = contentOwnerAddress;
        delete _content[contentId].royaltyRecipients;
        for (uint256 i = 0; i < feeRecipients.length; i++) {
            _content[contentId].royaltyRecipients.push(feeRecipients[i]);
        }
    }

    // Returns the address of the current content owner
    function getContentOwnerAddress(uint256 contentId)
        public
        view
        returns (address contentOwnerAddress)
    {
        contentOwnerAddress = _content[contentId].contentOwnerAddress;
    }

    function setContentRoyaltyRecipients(
        uint256 contentId,
        RoyaltyRecipient[] calldata royaltyRecipients
    ) external onlyContentOwner(contentId) {
        if (isFeeRecipientsValid(royaltyRecipients) == false)
            revert InvalidArgument();

        delete _content[contentId].royaltyRecipients;
        for (uint256 i = 0; i < royaltyRecipients.length; i++) {
            _content[contentId].royaltyRecipients.push(royaltyRecipients[i]);
        }
    }

    function getContentRoyaltyRecipients(uint256 contentId)
        public
        view
        returns (RoyaltyRecipient[] memory royaltyRecipients)
    {
        royaltyRecipients = _content[contentId].royaltyRecipients;
    }

    function getContentRoyaltyRecipient(uint256 contentId, address ownerAddress)
        public
        view
        returns (uint256 percent)
    {
        RoyaltyRecipient[] memory royaltyRecipients = _content[contentId]
            .royaltyRecipients;
        percent = 0;
        for (uint256 i = 0; i < royaltyRecipients.length; i++) {
            if (royaltyRecipients[i].recipient == ownerAddress) {
                percent = royaltyRecipients[i].feePercentage;
            }
        }
    }

    // Returns true if access to the content is allowed, can return false for the following reasons:
    // accessAddress has no tickets
    // content's sale has not started or sale has ended
    function isAccessAllowed(uint256 contentId, address accessAddress)
        public
        view
        returns (bool accessAllowed)
    {
        accessAllowed = (balanceOf(accessAddress, contentId) > 0); // address has at least 1 ticket
    }

    // Sets the fee percentage that Antic collects
    // Note: Can only be called by governance
    function setDefaultAnticFees(
        uint256 primaryFeePercentage,
        uint256 secondaryFeePercentage
    ) external onlyRole(MANAGER_ROLE) {
        // Check that the Antic fees don't exceed the maximum allowed
        _illegalFeePercentageGuard(
            primaryFeePercentage,
            secondaryFeePercentage,
            _MAX_ANTIC_PRIMARY_FEES_PERCENTAGE,
            _MAX_ANTIC_SECONDARY_FEES_PERCENTAGE
        );

        if (
            primaryFeePercentage > _PERCENTAGE_DIVIDER ||
            secondaryFeePercentage > _PERCENTAGE_DIVIDER
        ) {
            revert InvalidArgument();
        }

        _anticDefaultPrimaryFeesPercent = primaryFeePercentage;
        _anticDefaultSecondaryFeesPercent = secondaryFeePercentage;
    }

    // Returns the fee percentage that Antic collects
    function getDefaultAnticFees()
        public
        view
        returns (uint256 primaryFee, uint256 secondaryFee)
    {
        primaryFee = _anticDefaultPrimaryFeesPercent;
        secondaryFee = _anticDefaultSecondaryFeesPercent;
    }

    function setContentAnticFees(
        uint256 contentId,
        uint256 primaryFeePercentage,
        uint256 secondaryFeePercentage
    ) external onlyRole(MANAGER_ROLE) {
        // Check that the Antic fees don't exceed the maximum allowed
        _illegalFeePercentageGuard(
            primaryFeePercentage,
            secondaryFeePercentage,
            _MAX_ANTIC_PRIMARY_FEES_PERCENTAGE,
            _MAX_ANTIC_SECONDARY_FEES_PERCENTAGE
        );

        if (
            primaryFeePercentage > _PERCENTAGE_DIVIDER ||
            secondaryFeePercentage > _PERCENTAGE_DIVIDER
        ) {
            revert InvalidArgument();
        }

        if (
            _checkIllegalFeeAmount(
                _content[contentId].royalties,
                primaryFeePercentage,
                secondaryFeePercentage
            )
        ) {
            revert InvalidArgument();
        }

        if (
            _getInitialTicketSupply(contentId) !=
            getTotalRemainingTicketSupply(contentId)
        ) {
            revert CannotReassignContentFees();
        }
        _content[contentId].anticFees.primaryPercent = primaryFeePercentage;
        _content[contentId].anticFees.secondaryPercent = secondaryFeePercentage;
    }

    // Returns the fee percentage that Multeez collects
    function getContentAnticFees(uint256 contentId)
        public
        view
        returns (uint256 primaryFee, uint256 secondaryFee)
    {
        primaryFee = _content[contentId].anticFees.primaryPercent;
        secondaryFee = _content[contentId].anticFees.secondaryPercent;
    }

    function setSecondaryTicketPrice(
        uint256 contentId,
        uint256 secondaryTicketPrice
    ) external {
        if (balanceOf(msg.sender, contentId) == 0) revert InsufficientTickets();

        // If the seller is updating the secondary ticket price,
        // we MUST remove it from the set, and add it again with the new price
        bool exist = _secondaryTicketPrices.contains(msg.sender, contentId);
        if (exist) {
            _secondaryTicketPrices.remove(msg.sender, contentId);
        }

        _secondaryTicketPrices.set(msg.sender, contentId, secondaryTicketPrice);

        // Grant permission to contract to transfer the caller’s tokens
        if (this.isApprovedForAll(msg.sender, address(this)) == false) {
            setApprovalForAll(address(this), true);
        }
    }

    function getSecondaryTicketPrice(uint256 contentId, address sellerAddress)
        public
        view
        returns (bool isForSale, uint256 ticketPrice)
    {
        (, ticketPrice) = _secondaryTicketPrices.tryGet(
            sellerAddress,
            contentId
        );

        isForSale = ticketPrice > 0;
    }

    function _getCurrentSaleFees(uint256 contentId)
        internal
        view
        returns (uint256 anticFeePercent, uint256 royaltiesPercent)
    {
        anticFeePercent = _content[contentId].primarySaleEnded
            ? _content[contentId].anticFees.secondaryPercent
            : _content[contentId].anticFees.primaryPercent;
        royaltiesPercent = _content[contentId].primarySaleEnded
            ? _content[contentId].royalties.secondaryPercent
            : _content[contentId].royalties.primaryPercent;
    }

    function getContentOwnerFees(uint256 contentId)
        external
        view
        returns (FeePercents memory)
    {
        return _content[contentId].royalties;
    }

    function getPrimaryTicketPrice(uint256 contentId)
        public
        view
        returns (uint256)
    {
        for (
            uint256 ticketIndex;
            ticketIndex < _content[contentId].tickets.length;
            ticketIndex++
        ) {
            if (
                _content[contentId].tickets[ticketIndex].currentTicketSupply > 0
            ) {
                return _content[contentId].tickets[ticketIndex].ticketPrice;
            }
        }

        return 0;
    }

    function _decrementTicketSupply(uint256 contentId) internal {
        for (
            uint256 ticketIndex;
            ticketIndex < _content[contentId].tickets.length;
            ticketIndex++
        ) {
            if (
                _content[contentId].tickets[ticketIndex].currentTicketSupply > 0
            ) {
                _content[contentId].tickets[ticketIndex].currentTicketSupply--;
                return;
            }
        }
    }

    function buyAccess(uint256 contentId, address payable ticketSeller)
        external
        payable
        nonReentrant
    {
        // revert if buyer already owns a ticket.
        if (balanceOf(msg.sender, contentId) > 0) {
            revert UserAlreadyHoldsTicket();
        }

        // Verify that the seller owns at least one ticket
        if (balanceOf(ticketSeller, contentId) == 0) {
            revert InsufficientTickets();
        }

        // Check if the seller tries to sell his ticket before
        // the primary sale has ended
        bool isSellerTriesToSellBeforePrimaryEnded = ticketSeller !=
            _content[contentId].contentOwnerAddress &&
            !_content[contentId].primarySaleEnded;

        if (isSellerTriesToSellBeforePrimaryEnded == true) {
            revert PrimarySaleNotEnded();
        }

        // get current (primary/secondary) ticket price
        uint256 ticketPrice = _getTicketPrice(contentId, ticketSeller);

        // Verify that the buyer sent enough Eth to buy the ticket
        if (ticketPrice > msg.value) revert InsufficientFunds();

        // Get the current sale (primary/secondary) fees
        (
            uint256 anticFeePercent,
            uint256 royaltiesPercent
        ) = _getCurrentSaleFees(contentId); // 5678 ==> 0.5678%

        // Calculate Multeez fees before the ticket fee
        uint256 anticFees = calculateTicketFees(ticketPrice, anticFeePercent);

        // pay royalties fee if exists
        uint256 ticketPriceAfterFees = _payTicketRoyalties(
            contentId,
            ticketPrice,
            royaltiesPercent
        );

        // Collect Antic fees
        uint256 ticketPriceAfterAnticFees = _payAnticFees(
            anticFees,
            ticketPriceAfterFees
        );

        // Send ticket price to the seller.
        _payTicketSeller(ticketPriceAfterAnticFees, ticketSeller);

        // Send the ticket to the buyer
        _sendTicketToBuyer(ticketSeller, msg.sender, contentId);

        // If the last primary sale ticket is being sold, end primary sale
        if (_content[contentId].primarySaleEnded == false) {
            // solhint-disable-next-line
            _content[contentId].primarySaleEnded =
                ticketSeller == _content[contentId].contentOwnerAddress &&
                balanceOf(ticketSeller, contentId) == 0;
        } else {
            // this ticket is no longer available on secondary
            _secondaryTicketPrices.remove(ticketSeller, contentId);
        }
    }

    function _getTicketPrice(uint256 contentId, address ticketSeller)
        internal
        returns (uint256 ticketPrice)
    {
        // If primary sale ended, check for secondary sale
        // and fetch secondary ticket price
        if (_content[contentId].primarySaleEnded == true) {
            (
                bool isForSale,
                uint256 secondaryTicketPrice
            ) = getSecondaryTicketPrice(contentId, ticketSeller);

            if (isForSale == false) revert TicketNotForSale();

            ticketPrice = secondaryTicketPrice;
        } else {
            // get current primary price, if sale is over = should be 0
            ticketPrice = getPrimaryTicketPrice(contentId);
            // if primary ticket sale reduce the amount left for ticket of that type by 1
            _decrementTicketSupply(contentId);
        }
    }

    function _payTicketRoyalties(
        uint256 contentId,
        uint256 ticketPrice,
        uint256 royaltiesPercent
    ) internal returns (uint256) {
        // if no royalties need to be payed, ticket price is unchanged
        if (royaltiesPercent == 0) {
            return ticketPrice;
        }

        uint256 ticketFee = calculateTicketFees(ticketPrice, royaltiesPercent);
        // Used to keep track of unpaid fees as a result of
        // fractional fees (1432.45)
        uint256 leftoverFees = ticketFee;

        // Each fee recipient gets his share of the collected ticket fee
        for (
            uint256 i = 0;
            i < _content[contentId].royaltyRecipients.length;
            i++
        ) {
            uint256 recipientFee = calculateTicketFees(
                ticketFee,
                _content[contentId].royaltyRecipients[i].feePercentage
            );

            payable(_content[contentId].royaltyRecipients[i].recipient)
                .transfer(recipientFee);

            leftoverFees -= recipientFee;
        }

        // Seller will receive the ticket price minus the ticket fee
        // plus the ticket fee leftover (if there are any)
        uint256 ticketPriceAfterFees = ticketPrice - ticketFee + leftoverFees;
        return ticketPriceAfterFees;
    }

    function _sendTicketToBuyer(
        address ticketSeller,
        address ticketBuyer,
        uint256 contentId
    ) internal {
        // Send the ticket to the buyer
        this.safeTransferFrom(ticketSeller, ticketBuyer, contentId, 1, "");
    }

    function _payAnticFees(uint256 anticFees, uint256 ticketPrice)
        internal
        returns (uint256)
    {
        payable(anticAddress).transfer(anticFees);
        uint256 ticketPriceAfterFees = ticketPrice - anticFees;
        return ticketPriceAfterFees;
    }

    function _payTicketSeller(uint256 ticketPrice, address payable ticketSeller)
        internal
    {
        ticketSeller.transfer(ticketPrice);
    }

    function createMoreTickets(
        uint256 contentId,
        TicketTierInput calldata additionalTicketInfo
    ) external onlyContentOwner(contentId) {
        if (_content[contentId].tickets.length + 1 > _MAX_TICKET_TIERS) {
            revert InvalidArgument();
        }
        // Primary sale must end before new tickets can be minted
        if (_content[contentId].primarySaleEnded == false)
            revert PrimarySaleNotEnded();
        TicketTier memory t;
        t.initialTicketSupply = additionalTicketInfo.initialTicketSupply;
        t.currentTicketSupply = additionalTicketInfo.initialTicketSupply;
        t.ticketPrice = additionalTicketInfo.ticketPrice;
        _content[contentId].tickets.push(t);

        _mint(
            msg.sender,
            contentId,
            additionalTicketInfo.initialTicketSupply,
            ""
        );
    }

    function isPrimarySaleComplete(uint256 contentId)
        public
        view
        returns (bool)
    {
        return _content[contentId].primarySaleEnded;
    }

    function calculateTicketFees(uint256 sellPrice, uint256 ticketFee)
        public
        pure
        returns (uint256 fee)
    {
        fee = (sellPrice * ticketFee) / _PERCENTAGE_DIVIDER;
    }

    // Returns true if all the fee percentages add to 100%, false otherwise
    function isFeeRecipientsValid(RoyaltyRecipient[] calldata feeRecipients)
        public
        pure
        returns (bool isValid)
    {
        uint256 feeSum = 0;
        for (uint256 i = 0; i < feeRecipients.length; i++) {
            feeSum += feeRecipients[i].feePercentage;
        }
        isValid = (feeSum == _PERCENTAGE_DIVIDER);
    }

    function setAntic(address antic) external onlyAntic {
        _revokeRole(MANAGER_ROLE, anticAddress);
        _revokeRole(DEFAULT_ADMIN_ROLE, anticAddress);

        anticAddress = antic;

        _grantRole(MANAGER_ROLE, antic);
        _grantRole(DEFAULT_ADMIN_ROLE, antic);
    }

    receive() external payable {}

    function emergencyWithdrawBalance() external onlyAntic nonReentrant {
        payable(anticAddress).transfer(address(this).balance);
    }

    function _checkIllegalFeeAmount(
        FeePercents memory royalty,
        uint256 anticFeePrimary,
        uint256 anticFeeSecondary
    ) internal pure returns (bool) {
        return (royalty.primaryPercent + anticFeePrimary >
            _PERCENTAGE_DIVIDER ||
            royalty.secondaryPercent + anticFeeSecondary > _PERCENTAGE_DIVIDER);
    }

    /// @dev Reverts with `InvalidArgument` if the primary/secondary
    /// percentages exceed `maxPercent`
    function _illegalFeePercentageGuard(
        uint256 primaryPercent,
        uint256 secondaryPercent,
        uint256 primaryMaxPercent,
        uint256 secondaryMaxPercent
    ) internal pure {
        bool isAboveMax = primaryPercent > primaryMaxPercent ||
            secondaryPercent > secondaryMaxPercent;

        if (isAboveMax) {
            revert InvalidArgument();
        }
    }

    function secondaryTicketLength() external view returns (uint256) {
        return _secondaryTicketPrices.size();
    }

    function secondaryTicketAt(uint256 index)
        external
        view
        returns (address seller, uint256 price)
    {
        (seller, , price) = _secondaryTicketPrices.at(index);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../access/ExtendedAccessControl.sol";

/// @author Amit Molek
/// @dev Provides a marketplace role to enforce access control.
/// Uses OpenZeppelin's access control
abstract contract BaseMarketplaceAccess is ExtendedAccessControl {
    /// Marketplace role identifier
    bytes32 public constant MARKETPLACE_ROLE = keccak256("MARKETPLACE_ROLE");

    /// This operator is unapproved
    error UnapprovedOperator();

    constructor() {
        // Grant the deployer the marketplace role
        _setupRole(MARKETPLACE_ROLE, address(this));
    }

    /// @dev Guard that checks that the operator is allowed
    function _checkAccessGuard(address operator, bool approved)
        internal
        virtual
    {
        bool isPermitted = hasRole(MARKETPLACE_ROLE, operator);

        // After the operator's marketplace role was revoked,
        // the user can only disallow it
        if (isPermitted == false && approved == true) {
            revert UnapprovedOperator();
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract ExtendedAccessControl is AccessControl {
    function _grantRole(bytes32 role, address[] memory accounts) internal {
        for (uint256 i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0), "Invalid address");

            _grantRole(role, accounts[i]);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ipfs/ERC1155IPFS.sol";
import "./BaseMarketplaceAccess.sol";

/// @author Amit Molek
/// @dev This contract overrides the setApprovalForAll for ERC1155IPFS
/// to only allow access for permitted marketplaces/operators
abstract contract MarketplaceAccess1155IPFS is
    ERC1155IPFS,
    BaseMarketplaceAccess
{
    /// @dev Overriding to allow only permitted marketplaces
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(ERC1155)
    {
        // Check that the operator is allowed
        _checkAccessGuard(operator, approved);

        ERC1155.setApprovalForAll(operator, approved);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../lib/Strings32.sol";
import "./IPFSEfficientUri.sol";

/// @title IPFS support for ERC1155
/// @author Amit Molek
contract ERC1155IPFS is ERC1155, IPFSEfficientUri {
    constructor() ERC1155("") {}

    /// @dev Deprecated. Please use IPFSEfficientUri's setIpfsUri
    function _setURI(string memory) internal virtual override {}

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return ipfsUri(tokenId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIPFSUri {
    function ipfsUri(uint256 tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IIPFSUri.sol";
import "../lib/Strings32.sol";

/// @title Support for IPFS URI for assets
/// @author Amit Molek
/// @notice This contract provides the ability to set an IPFS URI for a token.
/// The contract saves the uri efficiently in 256 bits! and not as string!
/// @dev The IPFS URI must be given in hex format without the leading 'f'
/// For example:
///     1. Upload a file to IPFS with CID version 1 and sha3-224 hash algo
///     File CID = bafkrohd2ky4pmh6gznp6pf2gqadfhorbgnk3svu2we626zhpwjpa
///     2. Convert to base-16 (hex):
///     f0155171c7a5638f61fc6cb5fe79746800653ba213355b9569ab13daf64efb25e
///     3. Remove leading 'f' and add "0x"
///     0x0155171c7a5638f61fc6cb5fe79746800653ba213355b9569ab13daf64efb25e
///
contract IPFSEfficientUri is IIPFSUri {
    using Strings32 for uint256;

    mapping(uint256 => uint256) private _uris;

    /// @notice Sets the IPFS URI for a token
    /// @dev The URI must be in hex format (Look at the contract doc for an example)
    /// @param tokenid The token id you want to set the URI for
    /// @param uri The IPFS URI you want to set represented as a uint256 number
    function _setIpfsUri(uint256 tokenid, uint256 uri) internal virtual {
        _uris[tokenid] = uri;
    }

    /// @notice Returns the IPFS URI for the given token
    /// For hex uri of: f0155171c3ab022d103004015f83f60599857ef7c8489e35e68c881b9694f1b18
    /// Returns: ipfs://bafkrohb2warncayaiak7qp3algmfp334qse6gxtizca3s2kpdmma
    /// @dev Explain to a developer any extra details
    /// @param tokenId The token id you want to get the IPFS URI of
    /// @return string IPFS URI string
    function ipfsUri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (_uris[tokenId] == 0) {
            return "";
        }

        return
            string(
                abi.encodePacked("ipfs://b", _uris[tokenId].toBase32String())
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title IterableAddressKeyToValueMap
/// @author Amit Molek
/// @notice This map provides mapping between [address & key] to a [value],
///         and also the ability to iterate over the map's items.
/// @dev The actual key used to index inside the map is the hash of address & key
library IterableAddressKeyToValueMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Item {
        address addr;
        uint256 key;
        uint256 value;
    }

    struct Map {
        // hash(address + key) = actual key
        EnumerableSet.Bytes32Set keys;
        mapping(bytes32 => Item) values;
    }

    /// @notice Set a value in the map.
    /// @dev
    /// @param map The map object you want to work on
    /// @param addr The address you want to set the value to
    /// @param key The key you want to set the value to
    /// @param value The value you want to set
    /// @return bool Returns true if the an iten was added to the map, false if the item already exists
    function set(
        Map storage map,
        address addr,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        bytes32 hash = keccak256(abi.encode(addr, key));

        map.values[hash].value = value;
        map.values[hash].addr = addr;
        map.values[hash].key = key;

        return map.keys.add(hash);
    }

    /// @notice Returns the item at index
    /// @dev Should not be called with invalid index (out of bounds).
    /// This map does'nt guarantee that item x will be always at index i,
    /// use tryGet to fetch items and use at to iterate over the map.
    /// @param map The map object you want to work on
    /// @param index The index you want to fetch the item from
    /// @return addr The address of the item
    /// @return key The key of the item
    /// @return value The value of the item
    function at(Map storage map, uint256 index)
        internal
        view
        returns (
            address addr,
            uint256 key,
            uint256 value
        )
    {
        bytes32 hash = map.keys.at(index);

        addr = map.values[hash].addr;
        key = map.values[hash].key;
        value = map.values[hash].value;
    }

    function _remove(Map storage map, bytes32 hash) private returns (bool) {
        delete map.values[hash];
        return map.keys.remove(hash);
    }

    /// @notice Removes an item from the map
    /// @param map The map object you want to remove from
    /// @param addr The address you want to remove the value from
    /// @param key The key you want to remove the value from
    /// @return bool Returns true if the item was removed, false if doesn't exist
    function remove(
        Map storage map,
        address addr,
        uint256 key
    ) internal returns (bool) {
        bytes32 hash = keccak256(abi.encode(addr, key));
        return _remove(map, hash);
    }

    /// @notice Clears all item from the map
    /// @param map The map object you want to clear
    function clear(Map storage map) internal {
        // Get the map length first, because
        // every time we removed an item from it, the length
        // decreases by 1
        uint256 length = map.keys.length();
        for (uint256 i = 0; i < length; i++) {
            // Always remove the item at index 0
            // because every iteration the map shrinks by 1
            // so we always remove the first item (n times)
            bytes32 hash = map.keys.at(0);
            _remove(map, hash);
        }
    }

    /// @notice Explain to an end user what this does
    /// @param map The map object you want work on
    /// @param addr The address you want to check if the map contains
    /// @param key The key you want to check if the map contains
    /// @return bool Returns true if the map contains the address & key, false otherwise
    function contains(
        Map storage map,
        address addr,
        uint256 key
    ) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encode(addr, key));
        return map.keys.contains(hash);
    }

    /// @notice The size of the map
    /// @param map The map object you want to check the size of
    /// @return uint256 Returns the size of the map (number of items)
    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length();
    }

    /// @notice Tries to get the item from the map
    /// @param map The map object you want to get the item from
    /// @param addr The address you want to get the value of
    /// @param key The key you want to get the value of
    /// @return bool Returns true if the item exist in the map, false otherwise
    /// @return uint256 The value of address & key
    function tryGet(
        Map storage map,
        address addr,
        uint256 key
    ) internal view returns (bool, uint256) {
        bytes32 hash = keccak256(abi.encode(addr, key));
        uint256 v = map.values[hash].value;

        if (v == 0) {
            return (contains(map, addr, key), 0);
        } else {
            return (true, v);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author Amit Molek
/// @dev Base32 string operations
library Strings32 {
    bytes private constant _ALPHABET = "abcdefghijklmnopqrstuvwxyz234567";

    /// @notice Converts `uint256` to ASCII `string` RFC-4648 base32 representation
    /// @param input `uint256` to convert
    /// @return string RFC-4648 base32 representation of the input uint256
    function toBase32String(uint256 input)
        internal
        pure
        returns (string memory)
    {
        uint256 temp = input;
        uint256 length = 0;
        bytes memory data;

        while (temp > 0) {
            data = abi.encodePacked(uint8(temp), data);
            length++;
            temp >>= 8;
        }

        return toBase32String(data);
    }

    /// @notice Converts `bytes` to ASCII `string` RFC-4648 base32 representation
    /// @param data `bytes` to convert
    /// @return string RFC-4648 base32 representation of the input bytes
    function toBase32String(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        uint32 bits = 0;
        uint32 value = 0;
        bytes memory output;

        for (uint256 i = 0; i < data.length; i++) {
            value = (value << 8) | uint8(data[i]);
            bits += 8;

            while (bits >= 5) {
                output = abi.encodePacked(
                    output,
                    _ALPHABET[(value >> (bits - 5)) & 31]
                );
                bits -= 5;
            }
        }

        if (bits > 0) {
            output = abi.encodePacked(
                output,
                _ALPHABET[(value << (5 - bits)) & 31]
            );
        }

        return string(output);
    }
}