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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

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
        require(account != address(0), "ERC1155: address zero is not a valid owner");
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
            "ERC1155: caller is not token owner or approved"
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
            "ERC1155: caller is not token owner or approved"
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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
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

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
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

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
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

    /**
     * @dev Hook that is called after any token transfer. This includes minting
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
    function _afterTokenTransfer(
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
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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

pragma solidity ^0.8.13;

/// @title 
/// @author [email protected]
/// @notice

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import "../extensions/BaseURIStorage.sol";
import "../extensions/NFTSupplyStorage.sol";
import "../extensions/NFTLifeCycle.sol";
import "../extensions/NFTRoyalties.sol";

import "./IERC1155ById.sol";

abstract contract ERC1155ById is
    ERC1155,
    BaseURIStorage,
    NFTSupplyStorage,
    NFTLifeCycle,
    NFTRoyalties,
    IERC1155ById
{
    // Token name.
    string private _name;

    // Token symbol.
    string private _symbol;

    // Mapping token type `id` to total supply.
    mapping (uint256 => uint256) private _totalSupply;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC1155("") {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, BaseURIStorage, NFTSupplyStorage, NFTLifeCycle, NFTRoyalties, IERC165)
        returns (bool) 
    {
        return
            interfaceId == type(IERC1155ById).interfaceId || 
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BaseURIStorage-getBaseURI}.
     */
    function getBaseURI(uint256 id) public view virtual override returns (string memory) {
        if (bytes(_baseURIByIndex[id]).length == 0) revert IdDoesNotExist();

        return BaseURIStorage.getBaseURI(id);
    }

    /**
     * @dev See {NFTSupplyStorage-getMaxSupply}.
     */
    function getMaxSupply(uint256 id) public view virtual override returns (uint256) {
        if (bytes(_baseURIByIndex[id]).length == 0) revert IdDoesNotExist();

        return NFTSupplyStorage.getMaxSupply(id);
    }

    /**
     * @dev See {NFTLifeCycle-getNFTLifeCycle}.
     */
    function getNFTLifeCycle(uint256 id) public view virtual override returns (string memory) {
        if (bytes(_baseURIByIndex[id]).length == 0) revert IdDoesNotExist();

        return NFTLifeCycle.getNFTLifeCycle(id);
    }

    /**
     * @dev See {NFTRoyalties-royaltyInfo}.
     */
    function royaltyInfo(uint256 id, uint256 salePrice) public view virtual override returns (address, uint256) {
        if (bytes(_baseURIByIndex[id]).length == 0) revert IdDoesNotExist();

        return NFTRoyalties.royaltyInfo(id, salePrice);
    }

    /**
     * @dev Returns total amounts of token type `id`.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     */
    function uri(uint256 id) public view virtual override returns (string memory) {
        if (totalSupply(id) == 0) revert TotalSupplyByIdDoesNotExist();

        // Get base URI by `id`.
        string memory _baseURIById = getBaseURI(id);

        return bytes(_baseURIById).length > 0 ?
            string(abi.encodePacked(_baseURIById))
            : "";
    }

    /**
     * @dev Mints validated `amounts` tokens of token type `id` to `receivers`.
     */
    function _airdrop(
        address[] calldata receivers,
        uint256 id,
        uint256[] calldata amounts
    ) internal virtual {
        uint256 receiversLength = receivers.length;

        if (receiversLength != amounts.length) revert InvalidLength();
        
        for (uint256 i = 0; i < receiversLength;) {
            address _receivers = receivers[i];
            uint256 _amounts = amounts[i];

            // Call _validateMintInput.
            _validateMintInput(id, _amounts);

            // Call _mint.
            _mint(_receivers, id, _amounts);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Mints validated `amounts` tokens of token type `ids` to `receivers`.
     */
    function _airdropBatch(
        address[] calldata receivers,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal virtual {
        uint256 receiversLength = receivers.length;

        if (receiversLength != amounts.length || receiversLength != ids.length || amounts.length != ids.length) revert InvalidLength();

        for (uint256 i = 0; i < receiversLength;) {
            address _receivers = receivers[i];

            // Call _validateMintInputBatch.
            _validateMintBatchInput(ids, amounts);

            // Call _mintBatch.
            _mintBatch(_receivers, ids, amounts);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Mints `amount` tokens of token type `id` to `to`.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual {
        // Call _mint from {ERC1155}.
        ERC1155._mint(to, id, amount, "");

        // Update total supply by `id`.
        unchecked {
            _totalSupply[id] += amount;
        }
        
        emit AmountOfIdMinted(_msgSender(), to, id, amount);
    }

    /**
     * @dev Mints `amounts` tokens of token type `ids` to `to`.
     */
    function _mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal virtual {
        // Call _mintBatch from {ERC1155}.
        ERC1155._mintBatch(to, ids, amounts, "");

        uint256 idsLength = ids.length;

        for (uint256 i = 0; i < idsLength;) {
            uint256 _ids = ids[i];
            uint256 _amounts = amounts[i];

            // Update total supply by `ids`.
            unchecked {
                _totalSupply[_ids] += _amounts;
            }
        
            unchecked {
                ++i;
            }
        }

        emit AmountsOfIdsMinted(_msgSender(), to, ids, amounts);
    }

    /**
     * @dev Validates `amounts` tokens of token type `ids`.
     */
    function _validateMintBatchInput(uint256[] calldata ids, uint256[] calldata amounts) internal virtual {
        uint256 idsLength = ids.length;

        for (uint256 i = 0; i < idsLength;) {
            uint256 _ids = ids[i];
            uint256 _amounts = amounts[i];

            // Call _validateMintInput.
            _validateMintInput(_ids, _amounts);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Validates `amount` tokens of token type `id`.
     */
    function _validateMintInput(uint256 id, uint256 amount) internal virtual {
        // Check base URI by `id`.
        if (bytes(getBaseURI(id)).length == 0) revert("ID does not exist.");

        // Check amount.
        if (amount == 0 || amount > _maxQuantity) revert InvalidAmount();

        // Check max supply by `id`.
        if (_isMaxSupplyByIndexDefined[id]) {
            if (amount + totalSupply(id) > _maxSupplyByIndex[id]) revert ExceedMaxSupplyById();
        }
    }

    /**
     * @dev Burns `amount` tokens of token type `id` from `owner`.
     */
    function _burn(
        address owner,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        _validateBurnInput(id);

        // Call _burn from {ERC1155}.
        ERC1155._burn(owner, id, amount);

        // Update total supply by `id`.
        unchecked {
            _totalSupply[id] -= amount;
        }
        
        emit AmountOfIdBurned(_msgSender(), owner, id, amount);
    }

    /**
     * @dev Burns `amounts` tokens of token type `ids` from `owner`.
     */
    function _burnBatch(
        address owner,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        _validateBurnBatchInput(ids);

        // Call _burnBatch from {ERC1155}.
        ERC1155._burnBatch(owner, ids, amounts);

        uint256 idsLength = ids.length;

        for (uint256 i = 0; i < idsLength;) {
            uint256 _ids = ids[i];
            uint256 _amounts = amounts[i];

            // Update total supply by `ids`.
            unchecked {
                _totalSupply[_ids] -= _amounts;
            }
            
            unchecked {
                ++i;
            }
        }

        emit AmountsOfIdsBurned(_msgSender(), owner, ids, amounts);
    }

    /**
     * @dev Validates NFT life cycle state of token type `ids`.
     */
    function _validateBurnBatchInput(uint256[] memory ids) internal virtual {
        uint256 idsLength = ids.length;

        for (uint256 i = 0; i < idsLength;) {
            uint256 _ids = ids[i];

            // Call _validateBurnInput.
            _validateBurnInput(_ids);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Validates NFT life cycle state of token type `id`.
     */
    function _validateBurnInput(uint256 id) internal virtual {
        // Check NFT life cycle state by `id`.
        if (_lifeCycleStateByIndex[id] != NFTLifeCycleState.TRANSFERABLE_BURNABLE) revert IdIsNotBurnable();
    }

    /**
     * @dev Check {ERC1155-balanceOf} of token type `id` from `owners`.
     */
    function _balanceOfOwners(address[] calldata owners, uint256 id) internal view {
        uint256 ownersLength = owners.length;

            for (uint256 i = 0; i < ownersLength;) {
                address _owners = owners[i];

                // Call _balanceOf.
                _balanceOfOwner(_owners, id);

                unchecked {
                    ++i;
                }
            }
    }

    /**
     * @dev Check {ERC1155-balanceOf} of token type `id` from `owner`.
     */
    function _balanceOfOwner(address owner, uint256 id) internal view {
        // Check base URI by `id`.
        if (bytes(getBaseURI(id)).length == 0) revert("ID does not exist.");

        // Check total supply of `id`.
        if (totalSupply(id) == 0) revert TotalSupplyByIdDoesNotExist();

        // If {balanceOf} of `id` is zero (0).
        if (ERC1155.balanceOf(owner, id) == 0) revert BalanceOfIdIsZero();
    }

    /**
     * @dev Sets base URI by mapping `baseURI` to `ids`.
     * 
     * See {BaseURIStorage-_setBaseURIByIndex}.
     */
    function _setBaseURIById(uint256[] calldata ids, string[] memory baseURI) internal virtual {
        uint256 idsLength = ids.length;

        if (idsLength != baseURI.length) revert InvalidLength();

        for (uint256 i = 0; i < idsLength;) {
            uint256 _ids = ids[i];
            string memory _baseURI = baseURI[i];

            // Call _setBaseURIByIndex from {BaseURIStorage}.
            _setBaseURIByIndex(_ids, _baseURI);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Sets maximum supply by mapping `maxSupply` to `ids` and `defined` as `true` or `false`.
     * 
     * See {NFTLifeCycle-_setNFTLifeCycleState}.
     */
    function _setMaxSupplyById(
        uint256[] calldata ids,
        uint256[] calldata maxSupply,
        bool defined
    ) internal virtual {
        uint256 idsLength = ids.length;

        if (idsLength != maxSupply.length) revert InvalidLength();

        for (uint256 i = 0; i < idsLength;) {
            uint256 _ids = ids[i];
            uint256 _maxSupply = maxSupply[i];

            // If total supply of `ids` exist, maximum supply can not be reset.
            if (_maxSupply == 0 && !defined && (totalSupply(_ids) > 0)) revert TotalSupplyByIdExist();

            // `maxSupply` can not be less than current total supply of `ids`.
            if ((_maxSupply < totalSupply(_ids)) && defined) revert MaximumSupplyLessThanCurrentTotalSupply();

            // Call _setMaxSupplyByIndex from {NFTSupplyStorage}.
            _setMaxSupplyByIndex(_ids, _maxSupply, defined);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Sets NFT life cycle state by mapping `stateValue` to `ids`.
     * 
     * See {NFTLifeCycle-_setNFTLifeCycleState}.
     */
    function _setNFTLifeCycleById(uint256[] calldata ids, uint8[] calldata stateValue) internal virtual {
        uint256 idsLength = ids.length;

        if (idsLength != stateValue.length) revert InvalidLength();

        for (uint256 i = 0; i < idsLength;) {
            uint256 _ids = ids[i];
            uint8 _stateValue = stateValue[i];

            // Call _setNFTLifeCycleState from {NFTLifeCycle}.
            _setNFTLifeCycleState(_ids, _stateValue);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Sets royalty information by mapping `recipient` and `basisPoints` to `ids`.
     * 
     * See {NFTRoyalties-_setRoyaltyInfoByIndex}.
     */
    function _setRoyaltyInfoById(
        address recipient,
        uint256[] calldata ids,
        uint16[] calldata basisPoints
    ) internal virtual {
        uint256 idsLength = ids.length;

        if (idsLength != basisPoints.length) revert InvalidLength();

        for (uint256 i = 0; i < idsLength;) {
            uint256 _ids = ids[i];
            uint16 _basisPoints = basisPoints[i];

            // Call _setRoyaltyInfoByIndex from {NFTRoyalties}.
            _setRoyaltyByIndex(_ids, recipient, _basisPoints);
            
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Override _beforeTokenTransfer hook to facilitate non-transferable `ids`.
     * 
     * See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        uint256 idsLength = ids.length;

        for (uint256 i = 0; i < idsLength;) {
            uint256 _ids = ids[i];
            
            // If `ids` nft life cycle are neither transferable nor burnable.
            if (_lifeCycleStateByIndex[_ids] == NFTLifeCycleState.NOT_TRANSFERABLE_NOT_BURNABLE) {
                // If `from` and `to` are non-zero address.
                if (from != address(0) && to != address(0)) revert IdIsNotTransferable();
            }

            super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @title 
/// @author [email protected]
/// @notice

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC1155ById is IERC165 {
    /**
     * @notice Events to be emitted.
     */

    /**
     * @dev Emitted when `amount` tokens of token type `id` are minted from `from` to `to`.
     */
    event AmountOfIdMinted(
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    /**
     * @dev Emitted when `amounts` tokens of token type `ids` are minted from `from` to `to`.
     */
    event AmountsOfIdsMinted(
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    /**
     * @dev Emitted when `amount` tokens of token type `id` from `owner` were burned by `from`.
     */
    event AmountOfIdBurned(
        address indexed from,
        address indexed owner,
        uint256 id,
        uint256 amount
    );

    /**
     * @dev Emitted when `amounts` tokens of token type `ids` from `owner` were burned by `from`.
     */
    event AmountsOfIdsBurned(
        address indexed from,
        address indexed owner,
        uint256[] ids,
        uint256[] amounts
    );

    /**
     * @notice Error handlings.
     */

    /**
     * @dev The balance of token type `id` from `owner` is 0 (zero).
     */
    error BalanceOfIdIsZero();

    /**
     * @dev The total amount of tokens to be minted plus recent total supply exceed maximum supply by `id`.
     */
    error ExceedMaxSupplyById();

    /**
     * @dev The `id` does not exist.
     */
    error IdDoesNotExist();

    /**
     * @dev The `id` is not burnable.
     */
    error IdIsNotBurnable();

    /**
     * @dev The `id` is not transferable.
     */
    error IdIsNotTransferable();

    /**
     * @dev The `amount` tokens of token type `id` to be minted must be greater than 0 (zero) or maximum equal to maximum amount.
     */
    error InvalidAmount();

    /**
     * @dev The length of each dynamically-sized array based params must have the same length.
     */
    error InvalidLength();

    /**
     * @dev Maximum supply of `id` can not be less than current total supply of `id`.
     */
    error MaximumSupplyLessThanCurrentTotalSupply();

    /**
     * @dev Total amount of tokens in with a given id does not exist.
     */
    error TotalSupplyByIdDoesNotExist();

    /**
     * @dev Total amount of tokens in with a given id exist.
     */
    error TotalSupplyByIdExist();

    /**
     * @notice External functions.
     */

    /**
     * @dev Mints `amounts` tokens of token type `id` and transfers them to `receivers`.
     *
     * Requirements:
     *
     * @param receivers is multi-element array of address and can not be the zero address.
     * @param id is refer to index value from base uri by index.
     * @param amounts is multi-element array of amount and must be greater than 0 (zero) or maximum equal to maximum amount.
     * 
     * - `receivers` and `quantity` must have the same length.
     * - index value from base uri by index correspond to `id` must exist.
     */
    function airdrop(
        address[] calldata receivers,
        uint256 id,
        uint256[] calldata amounts
    ) external;

    /**
     * @dev Mints `amount` tokens of token type `id` and transfers them to `to`.
     *
     * Requirements:
     *
     * @param to can not be the zero address.
     * @param id is refer to index value from base uri by index.
     * @param amount must be greater than 0 (zero) or maximum equal to maximum quantity.
     * 
     * - index value from base uri by index correspond to `id` must exist.
     */
    function mint(address to, uint256 id, uint256 amount) external;

    /**
     * @dev Burns `amount` tokens of token type `id` from `owner` and transfers them to zero address.
     *
     * Requirements:
     *
     * @param owner can not be the zero address.
     * @param id is refer to index value from base uri by index.
     * @param amount must be lesser or equal to `owner``s balance of `id`.
     * 
     * - index value from base uri by index correspond to `id` must exist.
     */
    function burn(address owner, uint256 id, uint256 amount) external;

    /**
     * @dev Sets `baseURI` by `ids`. See {BaseURIStorage-_setBaseURIByIndex}.
     *
     * Requirements:
     *
     * @param ids is refer to index value from base uri by index.
     * @param baseURI must refer to where the base token URI per index is located (e.g "ipfs://..." or "https://...").
     * 
     * - index value from base uri by index correspond to `ids` must exist.
     */
    function setBaseURIById(uint256[] calldata ids, string[] memory baseURI) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @author [email protected]

import "@openzeppelin/contracts/utils/Context.sol";

import "./IBaseURIStorage.sol";

abstract contract BaseURIStorage is Context, IBaseURIStorage {
    // Initialize total base URI.
    uint256 private _totalBaseURI;

    // Mapping from index to base URI by index.
    mapping(uint256 => string) internal _baseURIByIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IBaseURIStorage).interfaceId;
    }

    /**
     * @dev Returns total base URI by index.
     */
    function getTotalBaseURI() public view returns (uint256) {
        return _totalBaseURI;
    }

    /**
     * @dev Returns base URI by `index`.
     */
    function getBaseURI(uint256 index) public view virtual returns (string memory) {
        return _baseURIByIndex[index];
    }

    /**
     * @dev Sets base URI by `index`.
     *
     * Requirements:
     * 
     * @param index is the index of base URI.
     * @param baseURI must refer to where the base token URI per index is located (e.g "ipfs://..." or "https://...").
     */
    function _setBaseURIByIndex(uint256 index, string memory baseURI) internal virtual {
        if (bytes(baseURI).length == 0) {
            // Remove `baseURI` by `index`.
            delete _baseURIByIndex[index];
            // Assign -= 1 to totalBaseURI.
            _totalBaseURI -= 1;
        }

        if (bytes(baseURI).length != 0) {
            // Assign `baseURI` to `index`
            _baseURIByIndex[index] = baseURI;
            // Assign += 1 to totalBaseURI.
            _totalBaseURI += 1;
        }

        // Emits the event.
        emit BaseURIByIndexUpdated(_msgSender(), index, baseURI);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @author [email protected]

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IBaseURIStorage is IERC165 {
    /**
     * @notice Events to be emitted.
     */

    /**
     * @dev Emitted when `caller` update base URI per tier ID of the collection.
     */
    event BaseURIByIndexUpdated(address indexed caller, uint256 index, string baseURI);

    /**
     * @notice Error handlings.
     */

    /**
     * @notice Functions.
     */

    /**
     * @dev Returns the base URI by `index`.
     *
     * Requirements:
     * 
     * @param index is the index of base URI.
     */
    function getBaseURI(uint256 index) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @title 
/// @author [email protected]
/// @notice

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface INFTLifeCycle is IERC165 {
    /**
     * @notice Events to be emitted.
     */

    /**
     * @dev Emitted when the `caller` update NFT life cycle state by index.
     */
    event NFTLifeCycleStateByIndexUpdated(address indexed caller, uint256 index, uint8 updatedStateValue);

    /**
     * @notice Error handlings.
     */

    /**
     * @dev State value is invalid.
     */
    error InvalidStateValue();

    /**
     * @notice Functions.
     */

    /**
     * @dev Returns the NFT life cycle state of the `id`.
     * 
     * Requirements:
     * 
     * @param index is `id` or `tier` from derived contract which correspond to index value from base uri by index.
     * 
     * - index value from base uri by index correspond to `id` must exist.
     */
    function getNFTLifeCycle(uint256 index) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @title 
/// @author [email protected]
/// @notice

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface INFTRoyalties is IERC165 {
    /**
     * @notice Events to be emitted.
     */

    /**
     * @dev Emitted when the `caller` update default royalty information.
     */
    event DefaultRoyaltyInfoUpdated(
        address indexed caller,
        address indexed royaltyRecipient,
        uint16 updatedBasisPoints
    );

    /**
     * @dev Emitted when the `caller` update default royalty information.
     */
    event RoyaltyByIndexUpdated(
        address indexed caller,
        address indexed royaltyRecipient,
        uint256 index,
        uint16 updatedBasisPoints
    );

    /**
     * @notice Error handlings.
     */

    /**
     * @dev Basis points is invalid.
     */
    error InvalidBasisPoints();

    /**
     * @dev Royalty recipient address is invalid.
     */
    error InvalidRoyaltyRecipientAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @title 
/// @author [email protected]
/// @notice

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface INFTSupplyStorage is IERC165 {
    /**
     * @notice Events to be emitted.
     */

    /**
     * @dev Emitted when `caller` update maximum quantity of `tokenId` (ERC721) or
     * maximum `amount` tokens of token type `id` (ERC1155) can be minted in one transaction.
     */
    event MaxQuantityUpdated(address indexed caller, uint256 updatedMaxQuantity);

    /**
     * @dev Emitted when `caller` update maximum supply by index.
     */
    event MaxSupplyByIndexUpdated(address indexed caller, uint256 index, uint256 updatedMaxSupply, bool isDefined);

    /**
     * @notice Error handlings.
     */

    /**
     * @dev Update maximum quantity is invalid.
     */
    error InvalidMaximumQuantity();

    /**
     * @dev Update maximum supply is invalid.
     */
    error InvalidMaximumSupply();

    /**
     * @dev Maximum supply by index is not defined.
     */
    error MaximumSupplyByIndexIsNotDefined();

    /**
     * @notice Functions.
     */

    /**
     * @dev Returns maximum supply by `index`.
     * 
     * Requirements:
     * 
     * @param index correspond to `id` or `tier` from derived contract which correspond to index value from base uri by index.
     * 
     * - index value from base uri by index correspond to `id` must exist.
     * - maximum supply by `index` must be defined as `true`.
     */
    function getMaxSupply(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @title 
/// @author [email protected]
/// @notice

import "@openzeppelin/contracts/utils/Context.sol";

import "./INFTLifeCycle.sol";

abstract contract NFTLifeCycle is Context, INFTLifeCycle {
    // Initialize enums type representing NFT life cycle state after mint event.
    enum NFTLifeCycleState {
        TRANSFERABLE_NOT_BURNABLE,
        TRANSFERABLE_BURNABLE,
        NOT_TRANSFERABLE_NOT_BURNABLE
    }

    // Mapping of index to NFT life cycle state.
    mapping (uint256 => NFTLifeCycleState) internal _lifeCycleStateByIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(INFTLifeCycle).interfaceId;
    }

    /**
     * @dev See {INFTLifeCycle-getNFTLifeCycle}.
     */
    function getNFTLifeCycle(uint256 index) public view virtual returns (string memory) {
        return _getNFTLifeCycleStateElement(_lifeCycleStateByIndex[index]);
    }

    /**
     * @dev Sets NFT life cycle state by store `stateValue`(value) to `index`(key).
     * 
     * Requirements:
     * 
     * @param index is refer to `id` or `tier` from derived contract which correspond to index value from base URI by index.
     * @param stateValue is uint8 value correspond to the index of element from NFTLifeCycleState enum.
     * 
     * Requirements:
     * 
     * - minimal or default value for `stateValue` is 0 (zero) which correspond to "TRANSFERABLE_NOT_BURNABLE" state.
     * - maximum value for `stateValue` is 2 (two) which correspond to "NOT_TRANSFERABLE_NOT_BURNABLE" state.
     */
    function _setNFTLifeCycleState(uint256 index, uint8 stateValue) internal virtual {
        // Throw error instead of panic in case the value from `stateValue` is out of scope.
        if (stateValue > uint8(type(NFTLifeCycleState).max)) revert InvalidStateValue();

        _lifeCycleStateByIndex[index] = NFTLifeCycleState(stateValue);

        emit NFTLifeCycleStateByIndexUpdated(_msgSender(), index, stateValue);
    }

    /**
     * @dev Returns an element from NFT life cycle state enum based on recent `state`.
     */
    function _getNFTLifeCycleStateElement(NFTLifeCycleState state) private pure returns (string memory) {
        if (NFTLifeCycleState.TRANSFERABLE_NOT_BURNABLE == state) return "TRANSFERABLE_NOT_BURNABLE";
        if (NFTLifeCycleState.TRANSFERABLE_BURNABLE == state) return "TRANSFERABLE_BURNABLE";
        else return "NOT_TRANSFERABLE_NOT_BURNABLE";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @title 
/// @author [email protected]
/// @notice

import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "./INFTRoyalties.sol";

abstract contract NFTRoyalties is IERC2981, INFTRoyalties {
    // Initialize struct type for royalty info.
    struct RoyaltyInfo {
        address recipient;      // Init value: address(0)
        uint16 basisPoints;     // Init value: 0
    }

    // Initialize default royalty info.
    RoyaltyInfo internal _defaultRoyaltyInfo;

    // Mapping index to royalty info.
    mapping(uint256 => RoyaltyInfo) internal _royaltyInfoByIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return 
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(INFTRoyalties).interfaceId;
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 index, uint256 salePrice) public view virtual returns (address, uint256) {
        RoyaltyInfo memory royalty = _royaltyInfoByIndex[index];

        // If recipient address not set.
        if (royalty.recipient == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (salePrice * royalty.basisPoints) / _maxBasisPoints();

        return (royalty.recipient, royaltyAmount);
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - @param recipient cannot be the zero address.
     * - @param basisPoints cannot be greater than the maximum basis points.
     */
    function _setDefaultRoyaltyInfo(address recipient, uint16 basisPoints) internal virtual {
        _validateRoyaltyInfoInput(recipient, basisPoints);
        _defaultRoyaltyInfo = RoyaltyInfo(recipient, basisPoints);
    }

    /**
     * @dev Reset default royalty information to default value.
     */
    function _resetDefaultRoyaltyInfo() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id or id overriding the global default.
     *
     * Requirements:
     *
     * @param index is token id or id from child contract.
     * @param recipient cannot be the zero address.
     * @param basisPoints cannot be greater than the maximum basis points.
     */
    function _setRoyaltyByIndex(
        uint256 index,
        address recipient,
        uint16 basisPoints
    ) internal virtual {
        _validateRoyaltyInfoInput(recipient, basisPoints);
        _royaltyInfoByIndex[index] = RoyaltyInfo(recipient, basisPoints);
    }

    /**
     * @dev Resets royalty information for the token id or id back to the global default.
     */
    function _resetRoyaltyInfoByIndex(uint256 index) internal virtual {
        delete _royaltyInfoByIndex[index];
    }

    /**
     * @dev Validates royalty info input for `address` and `basisPoints`.
     */
    function _validateRoyaltyInfoInput(address recipient, uint16 basisPoints) internal virtual {
        // If basis points larger than maximum basis points.
        if (basisPoints >= _maxBasisPoints()) revert InvalidBasisPoints();
        // If recipient is zero address.
        if (recipient == address(0)) revert InvalidRoyaltyRecipientAddress();
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setDefaultRoyaltyInfo} and {_setRoyaltyByIndex} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _maxBasisPoints() internal pure virtual returns (uint16) {
        return 10000;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @title 
/// @author [email protected]
/// @notice

import "@openzeppelin/contracts/utils/Context.sol";

import "./INFTSupplyStorage.sol";

abstract contract NFTSupplyStorage is Context, INFTSupplyStorage {
    // Maximum quantity of token IDs (ERC721) or amount of IDs (ERC1155) can be minted in one transaction.
    uint256 internal _maxQuantity;

    // Mapping from `id` or `tier` from derived contract to maximum supply by index.
    mapping (uint256 => uint256) internal _maxSupplyByIndex;

    // Mapping returning a boolean stating if the maximum supply by index is defined given the `id` or `tier`.
    // Returns `true` if is defined. `false` otherwise.
    mapping (uint256 => bool) internal _isMaxSupplyByIndexDefined;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(INFTSupplyStorage).interfaceId;
    }

    /**
     * @dev Returns maximum supply by `index`.
     */
    function getMaxSupply(uint256 index) public view virtual returns (uint256) {
        if (!_isMaxSupplyByIndexDefined[index]) revert MaximumSupplyByIndexIsNotDefined();

        return _maxSupplyByIndex[index];
    }

    /**
     * @dev Sets maximum quantity of token IDs (ERC721) or amount of IDs (ERC1155) can be minted in one transaction.
     *
     * Requirements:
     *
     * @param maxQuantity must be greater than 0 (zero) and can not be equal with the recent maximum quantity.
     */
    function _setMaxQuantity(uint256 maxQuantity) internal virtual {
        // Check input param argument value.
        if (maxQuantity == 0 && maxQuantity == _maxQuantity) revert InvalidMaximumQuantity();
        
        _maxQuantity = maxQuantity;

        emit MaxQuantityUpdated(_msgSender(), maxQuantity);
    }

    /**
     * @dev Sets maximum supply by index by store `maxSupply`(value) to `index`(key).
     *
     * Requirements:
     *
     * @param index is refer to `id` or `tier` from derived contract which correspond to index value from base URI by index.
     * @param maxSupply is total token IDs or amount of IDs can be minted per `index`.
     * @param defined is a boolean type value. Set to `true` to define maximum supply by index. Otherwise, set to `false`.
     * 
     * - `maxSupply` can not be equal with the recent maximum supply by index.
     * - `maxSupply` can not be set to 0 (zero) and `defined` as `true`.
     * - `maxSupply` can not be set to non-zero and `defined` as `false`.
     * - `maxSupply` can be set to 0 (zero) and `defined` as `false`. It will delete `maxSupply` from `index`.
     */
    function _setMaxSupplyByIndex(
        uint256 index,
        uint256 maxSupply,
        bool defined
    ) internal virtual {
        if ((maxSupply == _maxSupplyByIndex[index]) || (maxSupply == 0 && defined) || (maxSupply != 0 && !defined)) revert InvalidMaximumSupply();

        if (maxSupply == 0 && !defined) {
            delete _maxSupplyByIndex[index];
            _isMaxSupplyByIndexDefined[index] = defined;
        }

        _maxSupplyByIndex[index] = maxSupply;
        _isMaxSupplyByIndexDefined[index] = defined;
        
        // Emits the event.
        emit MaxSupplyByIndexUpdated(_msgSender(), index, maxSupply, defined);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @title 
/// @author [email protected]
/// @notice

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

import "../base/ERC1155ById.sol";

contract ERC1155ByIdImplementation_Mock is 
    ERC1155ById,
    RevokableDefaultOperatorFilterer,
    ERC2771Recipient,
    AccessControl,
    Ownable,
    Pausable {

    // `bytes32` identifier for admin role.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // `bytes32 identifier for burner role.
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // `bytes32 identifier for minter role.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Constructor.
     */
    constructor(
        string memory name,
        string memory symbol,
        address _initMinter,
        address _initOwner,
        address _initRoyaltyRecipient,
        uint16 _initFeeBasisPoints,
        uint256 _initMaxAmount
    ) ERC1155ById(name, symbol) {
        // Setup roles.
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _initMinter);
        
        // Init collection.
        NFTSupplyStorage._setMaxQuantity(_initMaxAmount);
        NFTRoyalties._setDefaultRoyaltyInfo(_initRoyaltyRecipient, _initFeeBasisPoints);

        // Init owner.
        if (_initOwner != _msgSender()) {
            Ownable.transferOwnership(_initOwner);
        }
    }
    
    /**
     * @dev See {IERC1155ById-airdrop}.
     */
    function airdrop(
        address[] calldata receivers,
        uint256 id,
        uint256[] calldata amounts
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        _airdrop(receivers, id, amounts);
    }

    /**
     * @dev
     */
    function airdropByBalance(
        address[] calldata receivers,
        uint256 id,
        uint256[] calldata amounts,
        uint256 ownedId
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        _balanceOfOwners(receivers, ownedId);
        _airdrop(receivers, id, amounts);
    }

    /**
     * @dev
     */
    function airdropBatch(
        address[] calldata receivers,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        _airdropBatch(receivers, ids, amounts);
    }

    /**
     * @dev See {IERC1155ById-mint}.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        _validateMintInput(id, amount);
        _mint(to, id, amount);
    }

    /**
     * @dev 
     */
    function mintByBalance(
        address to,
        uint256 id,
        uint256 amount,
        uint256 ownedId
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        _balanceOfOwner(to, ownedId);
        _validateMintInput(id, amount);
        _mint(to, id, amount);
    }

    /**
     * @dev 
     */
    function mintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        _validateMintBatchInput(ids, amounts);
        _mintBatch(to, ids, amounts);
    }

    /**
     * @dev See {IERC1155ById-burn}.
     */
    function burn(
        address ownerId,
        uint256 id,
        uint256 amount
    ) external onlyRole(BURNER_ROLE) whenNotPaused {
        _burn(ownerId, id, amount);
    }

    /**
     * @dev
     */
    function burnBatch(
        address ownerIds,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyRole(BURNER_ROLE) whenNotPaused {
        _burnBatch(ownerIds, ids, amounts);
    }

    /**
     * @dev See {IERC1155ById-_setBaseURIById}.
     */
    function setBaseURIById(uint256[] calldata ids, string[] memory updateBaseURI) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _setBaseURIById(ids, updateBaseURI);
    }

    /**
     * @dev See {ERC1155ById-_setMaxSupplyById}.
     */
    function setMaxSupplyById(
        uint256[] calldata ids,
        uint256[] calldata updateMaxSupply,
        bool defined
    ) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _setMaxSupplyById(ids, updateMaxSupply, defined);
    }

    /**
     * @dev See {NFTSupplyStorage-_setMaxQuantity}.
     */
    function setMaxAmount(uint256 updateMaxAmount) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _setMaxQuantity(updateMaxAmount);
    }

    /**
     * @dev See {ERC1155ById-_setNFTLifeCycleById}.
     */
    function setNFTLifeCycleById(uint256[] calldata ids, uint8[] calldata updateStateValue) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _setNFTLifeCycleById(ids, updateStateValue);
    }

    /**
     * @dev See {NFTRoyalties-_setDefaultRoyaltyInfo}.
     */
    function setDefaultRoyaltyInfo(address updateRecipient, uint16 feeBasisPoints) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _setDefaultRoyaltyInfo(updateRecipient, feeBasisPoints);
    }

    /**
     * @dev 
     */
    function resetDefaultRoyaltyInfo() external onlyRole(ADMIN_ROLE) whenNotPaused {
        _resetDefaultRoyaltyInfo();
    }

    /**
     * @dev See {ERC1155ById-_setRoyaltyInfoById}.
     */
    function setRoyaltyInfoById(address updateRecipient, uint256[] calldata ids, uint16[] calldata feeBasisPoints) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _setRoyaltyInfoById(updateRecipient, ids, feeBasisPoints);
    }

    /**
     * @dev 
     */
    function resetRoyaltyInfoById(uint256 id) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _resetRoyaltyInfoByIndex(id);
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

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155ById, AccessControl) returns (bool) {
        return 
            ERC1155ById.supportsInterface(interfaceId) || 
            AccessControl.supportsInterface(interfaceId) || 
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev The following functions are overriden required by {DefaultOperatorFilterer}.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function owner() public view virtual override (Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    /**
     * @dev The following internal functions are overriden required by {ERC2771Recipient}.
     */
    function _msgSender() internal view override(ERC2771Recipient, Context) returns (address ret) {
        ret = ERC2771Recipient._msgSender();
    }

    function _msgData() internal view override(ERC2771Recipient, Context) returns (bytes calldata ret) {
        ret = ERC2771Recipient._msgData();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {RevokableOperatorFilterer} from "./RevokableOperatorFilterer.sol";

/**
 * @title  RevokableDefaultOperatorFilterer
 * @notice Inherits from RevokableOperatorFilterer and automatically subscribes to the default OpenSea subscription.
 *         Note that OpenSea will disable creator fee enforcement if filtered operators begin fulfilling orders
 *         on-chain, eg, if the registry is revoked or bypassed.
 */
abstract contract RevokableDefaultOperatorFilterer is RevokableOperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() RevokableOperatorFilterer(0x000000000000AAeB6D7670E522A718067333cd4E, DEFAULT_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {UpdatableOperatorFilterer} from "./UpdatableOperatorFilterer.sol";
import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

/**
 * @title  RevokableOperatorFilterer
 * @notice This contract is meant to allow contracts to permanently skip OperatorFilterRegistry checks if desired. The
 *         Registry itself has an "unregister" function, but if the contract is ownable, the owner can re-register at
 *         any point. As implemented, this abstract contract allows the contract owner to permanently skip the
 *         OperatorFilterRegistry checks by calling revokeOperatorFilterRegistry. Once done, the registry
 *         address cannot be further updated.
 *         Note that OpenSea will still disable creator fee enforcement if filtered operators begin fulfilling orders
 *         on-chain, eg, if the registry is revoked or bypassed.
 */
abstract contract RevokableOperatorFilterer is UpdatableOperatorFilterer {
    error RegistryHasBeenRevoked();
    error InitialRegistryAddressCannotBeZeroAddress();

    bool public isOperatorFilterRegistryRevoked;

    constructor(address _registry, address subscriptionOrRegistrantToCopy, bool subscribe)
        UpdatableOperatorFilterer(_registry, subscriptionOrRegistrantToCopy, subscribe)
    {
        // don't allow creating a contract with a permanently revoked registry
        if (_registry == address(0)) {
            revert InitialRegistryAddressCannotBeZeroAddress();
        }
    }

    function _checkFilterOperator(address operator) internal view virtual override {
        if (address(operatorFilterRegistry) != address(0)) {
            super._checkFilterOperator(operator);
        }
    }

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be permanently bypassed, and the address cannot be updated again. OnlyOwner.
     */
    function updateOperatorFilterRegistryAddress(address newRegistry) public override {
        if (msg.sender != owner()) {
            revert OnlyOwner();
        }
        // if registry has been revoked, do not allow further updates
        if (isOperatorFilterRegistryRevoked) {
            revert RegistryHasBeenRevoked();
        }

        operatorFilterRegistry = IOperatorFilterRegistry(newRegistry);
    }

    /**
     * @notice Revoke the OperatorFilterRegistry address, permanently bypassing checks. OnlyOwner.
     */
    function revokeOperatorFilterRegistry() public {
        if (msg.sender != owner()) {
            revert OnlyOwner();
        }
        // if registry has been revoked, do not allow further updates
        if (isOperatorFilterRegistryRevoked) {
            revert RegistryHasBeenRevoked();
        }

        // set to zero address to bypass checks
        operatorFilterRegistry = IOperatorFilterRegistry(address(0));
        isOperatorFilterRegistryRevoked = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

/**
 * @title  UpdatableOperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry. This contract allows the Owner to update the
 *         OperatorFilterRegistry address via updateOperatorFilterRegistryAddress, including to the zero address,
 *         which will bypass registry checks.
 *         Note that OpenSea will still disable creator fee enforcement if filtered operators begin fulfilling orders
 *         on-chain, eg, if the registry is revoked or bypassed.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract UpdatableOperatorFilterer {
    error OperatorNotAllowed(address operator);
    error OnlyOwner();

    IOperatorFilterRegistry public operatorFilterRegistry;

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

    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

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
    }

    /**
     * @dev assume the contract has an owner, but leave specific Ownable implementation up to inheriting contract
     */
    function owner() public view virtual returns (address);

    function _checkFilterOperator(address operator) internal view virtual {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry) != address(0) && address(registry).code.length > 0) {
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}