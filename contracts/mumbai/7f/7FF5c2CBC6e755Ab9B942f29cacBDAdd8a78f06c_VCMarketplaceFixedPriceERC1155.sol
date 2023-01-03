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
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
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
pragma solidity ^0.8.9;

import "./IFeeBeneficiary.sol";

/**
 * @title FeeBeneficiary
 * @dev Base contract that contains the logic to manage and split user, project and market fees
 */
contract FeeBeneficiary is IFeeBeneficiary, FeeManager, CanWithdrawERC20 {
    /// @notice The Marketplace currency
    IERC20 public currency;

    /// @notice The admin of this contract is the VCMarketManager contract
    address public admin;

    /// @notice The VC Pool contract address
    address public pool;

    /// @notice The VC Starter contract address
    address public starter;

    /// @notice The minimum fee in basis points to distribute amongst VC Pool and VC Starter Projects
    uint256 public minPoolFeeBps;

    /// @notice The VC Marketplace fee in basis points
    uint256 public marketplaceFeeBps;

    /// @notice The maximum amount of projects a token seller can support
    uint96 public maxBeneficiaryProjects;

    /**
     * @dev Maps a token and seller to its TokenFeesData struct.
     */
    mapping(uint256 => mapping(address => TokenFeesData)) _tokenFeesData;

    /**
     * @dev Constructor
     * @param _admin Admin wallet for this contract
     * @param _minPoolFeeBps Minimum basis points fee that is required for pool
     * @param _marketplaceFeeBps VC Marketplace fee in basis points
     * @param _maxBeneficiaryProjects The maximum amount of projects a token seller can support
     */
    constructor(address _admin, uint256 _minPoolFeeBps, uint256 _marketplaceFeeBps, uint96 _maxBeneficiaryProjects) {
        _setAdmin(_admin);
        _setMinPoolFeeBps(_minPoolFeeBps);
        _setMarketplaceFeeBps(_marketplaceFeeBps);
        _setMaxBeneficiaryProjects(_maxBeneficiaryProjects);
    }

    /**
     * @dev See {IFeeBeneficiary-setAdmin}.
     */
    function setAdmin(address _admin) external {
        _onlyAdmin();
        _setAdmin(_admin);
    }

    /**
     * @dev See {IFeeBeneficiary-setPool}.
     */
    function setPool(address _pool) external {
        _onlyAdmin();
        _checkAddress(_pool);

        _setTo(_pool);
        pool = _pool;
    }

    /**
     * @dev See {IFeeBeneficiary-setStarter}.
     */
    function setStarter(address _starter) external {
        _onlyAdmin();
        _checkAddress(_starter);

        starter = _starter;
    }

    /**
     * @notice Allow admin to set the minimum valid basis points fee for VC Pool
     * @param _minPoolFeeBps the new minimum fee
     */
    function setMinPoolFeeBps(uint96 _minPoolFeeBps) external {
        _onlyAdmin();

        _setMinPoolFeeBps(_minPoolFeeBps);
    }

    /**
     * @notice Allow admin to set the marketplace fee in basis points
     * @param _marketplaceFee the new marketplace fee
     */
    function setMarketplaceFeeBps(uint256 _marketplaceFee) external {
        _onlyAdmin();

        _setMarketplaceFeeBps(_marketplaceFee);
    }

    /**
     * @notice Allow admin to set the max amount of beneficiary projects
     * @param _maxBeneficiaryProjects the new max amount
     */
    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) public {
        _onlyAdmin();

        maxBeneficiaryProjects = _maxBeneficiaryProjects;
    }

    /**
     * @dev See {IFeeBeneficiary-setCurrency}.
     */
    function setCurrency(IERC20 _currency) external {
        _onlyAdmin();

        currency = _currency;
        emit MktCurrencySet(address(currency), address(_currency));
    }

    /**
     * @dev See {IFeeBeneficiary-getFeesData}.
     */
    function getFeesData(uint256 _tokenId, address _seller) public view returns (TokenFeesData memory result) {
        return _tokenFeesData[_tokenId][_seller];
    }

    /**
     * @dev Constructs a `TokenFeesData` struct which stores the total fees in
     * bips that will be transferred to both the pool and the starter smart
     * contracts.
     *
     * @param _tokenId NFT token ID
     * @param _poolFeeBps Basis points fee that will be transferred to the pool on each purchase
     * @param _projects Array of Project addresses to support
     * @param _projectFeesBps Array of fees to support each project ID
     */
    function _setFees(
        uint256 _tokenId,
        uint256 _poolFeeBps,
        address[] calldata _projects,
        uint256[] calldata _projectFeesBps
    ) internal returns (uint256) {
        if (_projects.length != _projectFeesBps.length || _projects.length > maxBeneficiaryProjects) {
            revert MktFeesDataError();
        }

        uint256 starterFeeBps;
        for (uint256 i = 0; i < _projectFeesBps.length; i++) {
            starterFeeBps += _projectFeesBps[i];
        }

        uint256 totalFeeBps = _poolFeeBps + starterFeeBps;

        if (_poolFeeBps < minPoolFeeBps || totalFeeBps > FEE_DENOMINATOR) {
            revert MktTotalFeeError();
        }

        _tokenFeesData[_tokenId][msg.sender] = TokenFeesData(_poolFeeBps, starterFeeBps, _projects, _projectFeesBps);

        return totalFeeBps;
    }

    /**
     * @dev Computes and transfers fees to the Pool and projects.
     *
     * @param _tokenId Non-fungible token identifier
     * @param _seller The seller of the token used to get fees data from the storage
     * @param _buyer The address that bought the token
     * @param _price Token price
     * @param _starterFee The starter fee set on token listing
     * @param  _poolFee The pool fee set on token listing
     * @param _mktFee The market fee set on token listing
     *
     * NOTE: Transfer fee from contract (Marketplace) itself.
     * FIXME: The use of _starterFee here is just to validate if something will be transferred to projects
     * Maybe we could replace that with just a bool since we are already iterating over all the projects here
     */
    function _transferFee(
        uint256 _tokenId,
        address _seller,
        address _buyer,
        uint256 _price,
        uint256 _starterFee,
        uint256 _poolFee,
        uint256 _mktFee
    ) internal returns (uint256 extraToPool) {
        if (_starterFee > 0) {
            TokenFeesData storage feesData = _tokenFeesData[_tokenId][_seller];
            extraToPool = _fundProjects(_seller, feesData, _price);
            _poolFee += extraToPool;
        }

        if (!currency.transfer(pool, _mktFee + _poolFee)) {
            revert MktPoolTransferFailedError();
        }
        emit MktPoolFunded(_buyer, currency, _mktFee);
        emit MktPoolFunded(_seller, currency, _poolFee);
    }

    /**
     * @dev Computes individual fees for each beneficiary project and performs
     * the pertinent accounting at the Starter smart contract.
     * @param _seller The seller of the listed token
     * @param _feesData The fee data structure
     * @param _listPrice The listed price
     */
    function _fundProjects(
        address _seller,
        TokenFeesData storage _feesData,
        uint256 _listPrice
    ) internal returns (uint256 toPool) {
        bool[] memory activeProjects = IVCStarter(starter).areActiveProjects(_feesData.projects);

        for (uint256 i = 0; i < activeProjects.length; i++) {
            uint256 amount = _toFee(_listPrice, _feesData.projectFeesBps[i]);
            if (amount > 0) {
                if (activeProjects[i] == true) {
                    currency.approve(starter, amount);
                    IVCStarter(starter).fundProjectOnBehalf(_seller, _feesData.projects[i], amount);
                } else {
                    toPool += amount;
                }
            }
        }
    }

    /**
     * @dev Check that the address is a valid one
     * @param _address Address to check
     */
    function _checkAddress(address _address) internal view {
        if (_address == address(this) || _address == address(0)) {
            revert MktUnexpectedAddressError();
        }
    }

    /**
     * @dev internal function to set min pool fee in basis points
     */
    function _setMinPoolFeeBps(uint256 _minPoolFeeBps) private {
        minPoolFeeBps = _minPoolFeeBps;
    }

    /**
     * @dev internal function to set the marketplace fee in basis points
     */
    function _setMarketplaceFeeBps(uint256 _marketplaceFeeBps) private {
        marketplaceFeeBps = _marketplaceFeeBps;
    }

    /**
     * @dev internal function to set the max allowed amount of beneficiary projects
     */
    function _setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) private {
        maxBeneficiaryProjects = _maxBeneficiaryProjects;
    }

    /**
     * @dev internal function to set the admin of this contract
     */
    function _setAdmin(address _admin) internal {
        _checkAddress(_admin);
        admin = _admin;
    }

    /**
     * @dev Splits an amount into fees for both Pool and Starter smart
     * contracts and a resulting amount to be transferred to the token
     * owner (i.e. the token seller).
     * @param _feesData the fee data structure
     * @param _listPrice the listing price for the token
     */
    function _splitListPrice(
        TokenFeesData memory _feesData,
        uint256 _listPrice
    ) internal pure returns (uint256 starterFee, uint256 poolFee, uint256 resultingAmount) {
        starterFee = _toFee(_listPrice, _feesData.starterFeeBps);
        poolFee = _toFee(_listPrice, _feesData.poolFeeBps);
        resultingAmount = _listPrice - starterFee - poolFee;
    }

    /**
     * @dev internal function to validate that the sender of the tx is the admin
     */
    function _onlyAdmin() internal view {
        if (msg.sender != admin) {
            revert MktOnlyAdminAllowedError();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../utils/FeeManager.sol";
import "../utils/CanWithdrawERC20.sol";
import "../starter/IVCStarter.sol";

interface IFeeBeneficiary {
    error MktFeesDataError();
    error MktTotalFeeError();
    error MktUnexpectedAddressError();
    error MktOnlyAdminAllowedError();
    error MktPoolTransferFailedError();

    struct TokenFeesData {
        uint256 poolFeeBps;
        uint256 starterFeeBps;
        address[] projects;
        uint256[] projectFeesBps;
    }

    struct ListingFeeData {
        uint256 marketFee;
        uint256 starterFee;
        uint256 poolFee;
        address[] projects;
        uint256[] projectFeesBps;
    }

    struct ListingData {
        uint256 tokenId;
        uint256 price;
        address[] projects;
        uint256[] projectFeesBps;
    }

    event MktCurrencySet(address indexed oldCurrency, address indexed newCurrency);
    event MktPoolFunded(address indexed user, IERC20 indexed currency, uint256 amount);
    event MktProjectFunded(address indexed project, address indexed user, IERC20 indexed currency, uint256 amount);

    /**
     * @dev Sets the Marketplace admin.
     *
     * @notice Allow admin to transfer admin access to another wallet
     *
     * @param _admin: The admin address
     */
    function setAdmin(address _admin) external;

    /**
     * @dev Sets the Marketplace VCPool.
     *
     * @notice Allow admin to set or update the VC Pool contract address
     *
     * @param _pool: The VCPool address
     */
    function setPool(address _pool) external;

    /**
     * @dev Sets the Marketplace VCStarter.
     *
     * @notice Allow admin to set the address for VC Starter Contract
     *
     * @param _starter: The VCStarter address
     */
    function setStarter(address _starter) external;

    function setMinPoolFeeBps(uint96 _minPoolFeeBps) external;

    function setMarketplaceFeeBps(uint256 _marketplaceFee) external;

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external;

    /**
     * @dev Sets the Marketplace currency.
     *
     * @param _currency: The new currency address to set.
     */
    function setCurrency(IERC20 _currency) external;

    /**
     * @dev Returns the struct TokenFeesData corresponding to the _token and _tokenId
     *
     * @notice Fees data for a specified user and tokenId
     *
     * @param _tokenId Non-fungible token identifier
     * @param _seller The fees corresponding to the seller for the specified token
     */
    function getFeesData(uint256 _tokenId, address _seller) external view returns (TokenFeesData memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IFeeBeneficiary.sol";
import "./IVCMarketplaceBase.sol";
import "../utils/CanWithdrawERC20.sol";
import "../tokens/IPoCNft.sol";
import "../tokens/ArtNft1155/IArtNftERC1155.sol";
import "../tokens/ArtNft721/IArtNftERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCMarketManager {
    error MktMgrUnexpectedAddressError();
    error MktMgrOnlyAdminAllowedError();
    error MktNoRoyaltiesError();
    error MktMgrOnlyMarketplaceAllowedError();
    error MktMgrInvalidPoolAmountError();
    error MktMgrFailedToClaimError();
    error MktMgrCallContractFailedError();

    event MktRoyaltiesAccrued(address indexed creator, uint256 amount);
    event MktRoyaltiesClaimed(
        address indexed creator,
        address indexed receiver,
        uint256 receiverAmount,
        uint256 poolAmount
    );
    event MktTransfersApproved(address indexed user);

    enum ListStatus {
        NOT_LISTED,
        FIXED_PRICE,
        AUCTION
    }

    /**
     * @notice Set currency in all marketplaces contracts
     * @param _currency The new currency
     */
    function setCurrency(IERC20 _currency) external; // onlyAdmin

    /**
     * @notice Update POC NFT address
     * @param _pocNft The new poc address
     */
    function setPoCNft(address _pocNft) external; // onlyAdmin

    /**
     * @notice Allow admin to transfer admin access to another wallet
     * @param _admin the new admin address
     */
    function setAdmin(address _admin) external; // onlyAdmin

    /**
     * @notice Allow admin to set or update the VC Pool contract address on all marketplaces
     * @param _pool the new pool address
     */
    function setPool(address _pool) external; // onlyAdmin

    /**
     * @notice Allow admin to set or update the VC Starter contract address on all marketplaces
     * @param _starter the new starter address
     */
    function setStarter(address _starter) external; // onlyAdmin

    /**
     * @notice Allow admin to set or update the reference to the ERC721 fixed price marketplace
     * @param _marketplaceFixedPriceERC721 the new marketplace address
     */
    function setMarketplaceFixedPriceERC721(address _marketplaceFixedPriceERC721) external; // onlyAdmin

    /**
     * @notice Allow admin to set or update the reference to the auction marketplace
     * @param _marketplaceAuctionERC721 the new marketplace address
     */
    function setMarketplaceAuctionERC721(address _marketplaceAuctionERC721) external; // onlyAdmin

    /**
     * @notice Allow admin to set or update the reference to the ERC1155 fixed price marketplace
     * @param _marketplaceFixedPriceERC1155 the new marketplace address
     */
    function setMarketplaceFixedPriceERC1155(address _marketplaceFixedPriceERC1155) external; // onlyAdmin

    /**
     * @notice Allow admin to set or update the reference to the POC fixed price marketplace
     * @param _marketplaceFixedPricePocNft the new marketplace address
     */
    function setMarketplaceFixedPricePocNft(address _marketplaceFixedPricePocNft) external; // onlyAdmin

    /**
     * @notice Allow admin to set or update the reference to the POC auction marketplace
     * @param _marketplaceAuctionPocNft the new marketplace address
     */
    function setMarketplaceAuctionPocNft(address _marketplaceAuctionPocNft) external; // onlyAdmin

    /**
     * @notice Allow admin to set or update the reference to the ERC721 Art NFT Contract
     * @param _artNftERC721 the new artNft address
     */
    function setArtNftERC721(address _artNftERC721) external; // onlyAdmin

    /**
     * @notice Allow admin to set or update the reference to the ERC1155 Art NFT Contract
     * @param _artNftERC1155 the new artNft address
     */
    function setArtNftERC1155(address _artNftERC1155) external; // onlyAdmin

    /**
     * @notice Set min basis points fee allowed for pool
     * @param _minPoolFeeBps minimum fee bps
     */
    function setMinPoolFeeBps(uint96 _minPoolFeeBps) external; // onlyAdmin

    /**
     * @notice Set marketplace fee in basis points
     * @param _marketplaceFeeBps marketplace fee
     */
    function setMarketplaceFeeBps(uint256 _marketplaceFeeBps) external; // onlyAdmin

    /**
     * @notice Set max amount of beneficiary projects
     * @param _maxBeneficiaryProjects max amount of beneficiary projects
     */
    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external; // onlyAdmin

    /**
     * @notice Set list status for specified tokenId
     * @param _tokenId token id
     * @param listed flag to identify if the token is listed or not
     */
    function setListStatusERC721(uint256 _tokenId, bool listed) external; // only ERC721 marketplaces

    /**
     * @notice Allow admin to replace the current manager with a new one on all marketplaces
     * @param _mktManager the new market manager address
     */
    function changeMarketManager(address _mktManager) external; // onlyAdmin

    /**
     * @notice Increase the received royalties for the specified address
     * @param _receiver address of the royalties receiver
     * @param _royaltyAmount Amount of currency to be received
     */
    function accrueRoyalty(address _receiver, uint256 _royaltyAmount) external; //onlyMarketplaces

    /**
     * @notice Withdraw sender royalties to the specified address
     * @param _to Address of the receiver
     * @param _poolAmount Amount of currency to donate to the pool from royalties
     * Design:
     * - at each purchase or settlement, update a mapping here, mapping(address => uint256) royalties;
     * - send from either buyer or marketplace the amount to this smart contract
     * - remove claimRoyalty from each market
     */
    function claimRoyalties(address _to, uint256 _poolAmount) external;

    /**
     * @notice Allow marketplaces to spend ArtNfts in name of the sender.
     * This is required to allow listing and purchasing NFTs
     */
    function approveForAllMarketplaces() external;

    /**
     * @notice Allow admin to execute a contract call to any other deployed smart contract
     * @param _contract Address of the contract to call
     * @param _data data for the contract call
     */
    function callContract(address _contract, bytes calldata _data) external; // onlyAdmin

    /**
     * @notice External function to get the list of marketplaces' addresses
     * @return marketplaces array of marketplaces addresses
     */
    function getMarketplaces() external view returns (address[5] memory marketplaces);

    /**
     * @notice Get list status for the specified token id
     * @param _tokenId Token id
     */
    function getListStatusERC721(uint256 _tokenId) external view returns (ListStatus);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./FeeBeneficiary.sol";
import "./IVCMarketManager.sol";
import "../tokens/IPoCNft.sol";

interface IVCMarketplaceBase {
    error MktCallerNotSellerError();
    error MktTokenNotListedError();
    error MktAccrRoyaltiesFailedError();
    error MktSettleFailedError();
    error MktPurchaseFailedError();
    error MktAlreadyListedOnAuctionError();
    error MktAlreadyListedOnFixedPriceError();

    event MktPoCNftSet(address indexed oldPoCNft, address indexed newPoCNft);

    /**
     * @dev Pauses or unpauses the Marketplace
     */
    function pause(bool _paused) external;

    /**
     * @dev Sets the Proof of Collaboration Non-Fungible Token.
     * @param _pocNft new POC address
     */
    function setPoCNft(address _pocNft) external;

    /**
     * @notice Computes the royalty amount for the given tokenId and its price.
     *
     * @param _tokenId: Non-fungible token identifier
     * @param _amount: A pertinent amount used to compute the royalty.
     */
    function checkRoyalties(uint256 _tokenId, uint256 _amount) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./VCMarketplaceBase.sol";
import "../tokens/ArtNft1155/IArtNftERC1155.sol";

interface IVCMarketplaceFixedPriceERC1155 {
    error MktNotEnoughTokens();

    struct FixedPriceListing {
        bool minted;
        address seller;
        uint256 amount;
        uint256 price;
        uint256 marketFee;
        uint256 starterFee;
        uint256 poolFee;
        address royaltyReceiver;
        uint256 royaltyAmount;
    }

    event MktListedFixedPrice(
        address indexed token,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 amount,
        uint256 listPrice,
        FeeBeneficiary.ListingFeeData fees,
        address royaltyReceiver,
        uint256 royaltyAmount
    );
    event MktUpdatedFixedPrice(
        address indexed token,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 amount,
        uint256 listPrice,
        uint256 marketFee,
        uint256 starterFee,
        uint256 poolFee,
        address royaltyReceiver,
        uint256 royaltyAmount
    );
    event MktUnlistedFixedPrice(address indexed token, uint256 indexed tokenId, address indexed seller, uint256 amount);
    event MktPurchased(
        address indexed buyer,
        address indexed token,
        uint256 indexed tokenId,
        address seller,
        uint256 listPrice,
        uint256 marketFee,
        uint256 starterFee,
        uint256 poolFee,
        address royaltyReceiver,
        uint256 royaltyAmount
    );

    /**
     * @dev Allows a token owner, i.e. msg.sender, to list an amount of ERC1155 artNfts with a given fixed price to the
     * Marketplace. It can also be used to update a listing, such as its price, amount, fees and/or royalty data.
     *
     * @param _tokenId the token identifier
     * @param _listPrice the listing price
     * @param _amount the amount of tokens to list
     * @param _poolFeeBps the fee transferred to the VC Pool on purchases
     * @param _projects Array of project addresses to support on purchases
     * @param _projectFeesBps Array of project fees in basis points on purchases
     */
    function listFixedPrice(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _listPrice,
        uint256 _poolFeeBps,
        address[] calldata _projects,
        uint256[] calldata _projectFeesBps
    ) external;

    /**
     * @dev Allows the seller, i.e. msg.sender, to remove a specific amount of token from being listed at the Marketplace.
     *
     * @param _tokenId the token identifier
     * @param _amount amount of tokens to unlist
     */
    function unlistFixedPrice(uint256 _tokenId, uint256 _amount) external;

    /**
     * @dev Allows a buyer, i.e. msg.sender, to purchase a token at a fixed price in the Marketplace. Tokens must be
     * purchased for the price set by the seller plus the market fee.
     *
     * @param _tokenId the token identifier
     * @param _seller address of the seller of the token
     */
    function purchase(uint256 _tokenId, address _seller) external;

    /**
     * @notice verifies that the seller argument is the one selling the specified token
     *
     * @param _tokenId token id
     * @param seller seller address
     * @return bool indicating if the address is selling the token id
     */
    function listed(uint256 _tokenId, address seller) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IVCMarketplaceBase.sol";

abstract contract VCMarketplaceBase is IVCMarketplaceBase, FeeBeneficiary, Pausable {
    /// @notice The Viral(Cure) Proof of Collaboration Non-Fungible Token
    IPoCNft public pocNft;

    /// @notice The Viral(Cure) Art Non-Fungible Token
    address public artNft;

    /**
     * @dev Sets the whitelisted tokens to be traded at the Marketplace.
     */
    constructor(address _artNft) {
        artNft = _artNft;
    }

    /**
     * @dev See {IVCMarketplaceBase-pause}.
     */
    function pause(bool _paused) public {
        _onlyAdmin();

        if (_paused) _pause();
        else _unpause();
    }

    /**
     * @dev See {IVCMarketplaceBase-setPoCNft}.
     */
    function setPoCNft(address _pocNft) external {
        _onlyAdmin();

        pocNft = IPoCNft(_pocNft);
        emit MktPoCNftSet(address(pocNft), _pocNft);
    }

    /**
     * @dev See {IVCMarketplaceBase-checkRoyalties}.
     */
    function checkRoyalties(
        uint256 _tokenId,
        uint256 _amount
    ) public view returns (address receiver, uint256 royaltyAmount) {
        (receiver, royaltyAmount) = IERC2981(artNft).royaltyInfo(_tokenId, _amount);
    }

    /**
     * @dev Set fees and check royalties
     *
     * @param _tokenId token id
     * @param _poolFeeBps basis points fee for pool
     * @param _projects list of projects to support
     * @param _projectFeesBps basis points fees for each beneficiary projects
     */
    function _setFeesAndCheckRoyalty(
        uint256 _tokenId,
        uint256 _poolFeeBps,
        address[] calldata _projects,
        uint256[] calldata _projectFeesBps
    ) internal {
        uint256 totalFeeBps = _setFees(_tokenId, _poolFeeBps, _projects, _projectFeesBps);
        (, uint256 royaltyBps) = checkRoyalties(_tokenId, FEE_DENOMINATOR); // It should be _feeDenominator() instead of FEE_DENOMINATOR
        if (totalFeeBps + royaltyBps > FEE_DENOMINATOR) {
            //revert MktTotalFeeTooHigh();
            revert MktTotalFeeError();
        }
    }

    /**
     * @dev settles an auction listing
     *
     * @param _tokenId token id
     * @param _seller token's seller
     * @param _highestBidder bidder of the highest bid
     * @param _highestBid highest bid amount
     * @param _marketFee marker fee
     * @param _starterFee starter fee
     * @param _poolFee pool fee
     * @param _royaltyReceiver royalty receiver
     * @param _royaltyAmount royalty amount
     */
    function _settle(
        uint256 _tokenId,
        address _seller,
        address _highestBidder,
        uint256 _highestBid,
        uint256 _marketFee,
        uint256 _starterFee,
        uint256 _poolFee,
        address _royaltyReceiver,
        uint256 _royaltyAmount
    ) internal returns (uint256 extraToPool) {
        extraToPool = _transferFee(_tokenId, _seller, _highestBidder, _highestBid, _starterFee, _poolFee, _marketFee);
        uint256 amountToSeller = _highestBid - _starterFee - _poolFee;

        address marketManager = admin;
        if (_royaltyReceiver != address(0) && _royaltyAmount != 0) {
            if (!currency.transfer(marketManager, _royaltyAmount)) {
                revert MktAccrRoyaltiesFailedError();
            }
            IVCMarketManager(marketManager).accrueRoyalty(_royaltyReceiver, _royaltyAmount);
            amountToSeller -= _royaltyAmount;
        }
        if (!currency.transfer(_seller, amountToSeller)) {
            revert MktSettleFailedError();
        }
    }

    /**
     * @dev process the purchase of a listed token
     *
     * @param _tokenId token id
     * @param _seller seller of the token
     * @param _listPrice listed price
     * @param _marketFee market fee
     * @param _starterFee starter fee
     * @param _poolFee pool fee
     * @param _royaltyReceiver royalty receiver
     * @param _royaltyAmount royalty amount
     */
    function _purchase(
        uint256 _tokenId,
        address _seller,
        uint256 _listPrice,
        uint256 _marketFee,
        uint256 _starterFee,
        uint256 _poolFee,
        address _royaltyReceiver,
        uint256 _royaltyAmount
    ) internal returns (uint256 extraToPool) {
        if (!currency.transferFrom(msg.sender, address(this), _listPrice + _marketFee)) {
            revert MktPurchaseFailedError();
        }
        extraToPool = _transferFee(_tokenId, _seller, msg.sender, _listPrice, _starterFee, _poolFee, _marketFee);
        uint256 amountToSeller = _listPrice - _starterFee - _poolFee;

        address marketManager = admin;
        if (_royaltyReceiver != address(0) && _royaltyAmount != 0) {
            if (!currency.transfer(marketManager, _royaltyAmount)) {
                revert MktAccrRoyaltiesFailedError();
            }
            IVCMarketManager(marketManager).accrueRoyalty(_royaltyReceiver, _royaltyAmount);
            amountToSeller -= _royaltyAmount;
        }
        if (!currency.transfer(_seller, amountToSeller)) {
            revert MktPurchaseFailedError();
        }
    }

    /**
     * @dev check if address is the null address
     *
     * @param _address address to check
     */
    function _checkAddressZero(address _address) internal pure {
        if (_address == address(0)) {
            revert MktTokenNotListedError();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IVCMarketplaceFixedPriceERC1155.sol";

contract VCMarketplaceFixedPriceERC1155 is IVCMarketplaceFixedPriceERC1155, VCMarketplaceBase, ERC1155Holder {
    /// @notice Maps a token Id and seller to its listing
    mapping(uint256 => mapping(address => FixedPriceListing)) public fixedPriceListings;

    /**
     * Constructor
     * @param _artNft Art NFT address
     * @param _admin Admin address
     * @param _minPoolFeeBps Min allowed basis points fee for pool
     * @param _marketplaceFee Marketplace fee
     * @param _maxBeneficiaryProjects max amount of beneficiary projects
     */
    constructor(
        address _artNft,
        address _admin,
        uint256 _minPoolFeeBps,
        uint256 _marketplaceFee,
        uint96 _maxBeneficiaryProjects
    ) VCMarketplaceBase(_artNft) FeeBeneficiary(_admin, _minPoolFeeBps, _marketplaceFee, _maxBeneficiaryProjects) {}

    /**
     * @dev See {IVCMarketplaceFixedPriceERC1155-listFixedPrice}.
     */
    function listFixedPrice(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _listPrice,
        uint256 _poolFeeBps,
        address[] calldata _projects,
        uint256[] calldata _projectFeesBps
    ) external whenNotPaused {
        _setFeesAndCheckRoyalty(_tokenId, _poolFeeBps, _projects, _projectFeesBps);
        if (!listed(_tokenId, msg.sender)) {
            _newList(ListingData(_tokenId, _listPrice, _projects, _projectFeesBps), _amount);
        } else {
            _updateList(_tokenId, _amount, _listPrice);
        }
    }

    /**
     * @dev See {IVCMarketplaceFixedPriceERC1155-unlistFixedPrice}.
     */
    function unlistFixedPrice(uint256 _tokenId, uint256 _amount) external {
        FixedPriceListing memory listing = fixedPriceListings[_tokenId][msg.sender];

        if (listing.seller != msg.sender) {
            revert MktCallerNotSellerError();
        }

        _updateFixedPriceListing(_tokenId, msg.sender, _amount);

        if (listing.minted) {
            IArtNftERC1155(address(artNft)).safeTransferFrom(address(this), listing.seller, _tokenId, _amount, "");
        }

        emit MktUnlistedFixedPrice(address(artNft), _tokenId, msg.sender, _amount);
    }

    /**
     * @dev See {IVCMarketplaceFixedPriceERC1155-purchase}.
     */
    function purchase(uint256 _tokenId, address _seller) external whenNotPaused {
        FixedPriceListing memory listing = fixedPriceListings[_tokenId][_seller];

        _checkAddressZero(listing.seller);
        _updateFixedPriceListing(_tokenId, _seller, 1);

        uint256 extraToPool = _purchase(
            _tokenId,
            listing.seller,
            listing.price,
            listing.marketFee,
            listing.starterFee,
            listing.poolFee,
            listing.royaltyReceiver,
            listing.royaltyAmount
        );

        listing.poolFee += extraToPool;
        listing.starterFee -= extraToPool;

        _minting(listing, _tokenId);

        emit MktPurchased(
            msg.sender,
            address(artNft),
            _tokenId,
            listing.seller,
            listing.price,
            listing.marketFee,
            listing.starterFee,
            listing.poolFee,
            listing.royaltyReceiver,
            listing.royaltyAmount
        );
    }

    /**
     * @dev See {IVCMarketplaceFixedPriceERC1155-listed}.
     */
    function listed(uint256 _tokenId, address seller) public view returns (bool) {
        return fixedPriceListings[_tokenId][seller].seller != address(0);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev initialize a new listing
     * FIXME: Params
     */
    function _newList(ListingData memory data, uint256 _amount) internal {
        bool minted = IArtNftERC1155(artNft).exists(data.tokenId);
        if (!minted) {
            IArtNftERC1155(artNft).requireCanRequestMint(msg.sender, data.tokenId, _amount);
        } else {
            IArtNftERC1155(artNft).safeTransferFrom(msg.sender, address(this), data.tokenId, _amount, "");
        }

        (
            uint256 marketFee,
            uint256 starterFee,
            uint256 poolFee,
            address royaltyReceiver,
            uint256 royaltyAmount
        ) = _getFeesAndRoyalty(data.tokenId, data.price);

        fixedPriceListings[data.tokenId][msg.sender] = FixedPriceListing(
            minted,
            msg.sender,
            _amount,
            data.price,
            marketFee,
            starterFee,
            poolFee,
            royaltyReceiver,
            royaltyAmount
        );

        emit MktListedFixedPrice(
            address(artNft),
            data.tokenId,
            msg.sender,
            _amount,
            data.price,
            ListingFeeData(marketFee, starterFee, poolFee, data.projects, data.projectFeesBps),
            royaltyReceiver,
            royaltyAmount
        );
    }

    /**
     * @dev updates a listing
     *
     * @param _tokenId token id to list
     * @param _amount updated amount of token copies to update
     * @param _listPrice updated list fixed price
     */
    function _updateList(uint256 _tokenId, uint256 _amount, uint256 _listPrice) internal {
        (
            uint256 marketFee,
            uint256 starterFee,
            uint256 poolFee,
            address royaltyReceiver,
            uint256 royaltyAmount
        ) = _getFeesAndRoyalty(_tokenId, _listPrice);

        FixedPriceListing memory listing = fixedPriceListings[_tokenId][msg.sender];
        listing.price = _listPrice;
        listing.marketFee = marketFee;
        listing.starterFee = starterFee;
        listing.poolFee = poolFee;
        listing.royaltyReceiver = royaltyReceiver;
        listing.royaltyAmount = royaltyAmount;
        listing.amount += _amount;
        fixedPriceListings[_tokenId][msg.sender] = listing;

        if (!listing.minted) {
            IArtNftERC1155(address(artNft)).requireCanRequestMint(msg.sender, _tokenId, listing.amount);
        } else {
            IArtNftERC1155(address(artNft)).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        }

        emit MktUpdatedFixedPrice(
            address(artNft),
            _tokenId,
            msg.sender,
            _amount,
            _listPrice,
            marketFee,
            starterFee,
            poolFee,
            royaltyReceiver,
            royaltyAmount
        );
    }

    /**
     * @dev Get royalties and fees for the specified list
     *
     * @param _tokenId token id
     * @param _listPrice list price
     * @return marketFee market fee amount
     * @return starterFee starter fee amount
     * @return poolFee pool fee amount
     * @return royaltyReceiver receiver of the royalties
     * @return royaltyAmount royalties amount
     */
    function _getFeesAndRoyalty(
        uint256 _tokenId,
        uint256 _listPrice
    )
        internal
        view
        returns (uint256 marketFee, uint256 starterFee, uint256 poolFee, address royaltyReceiver, uint256 royaltyAmount)
    {
        marketFee = _toFee(_listPrice, marketplaceFeeBps);
        TokenFeesData memory feesData = _tokenFeesData[_tokenId][msg.sender];
        (starterFee, poolFee, ) = _splitListPrice(feesData, _listPrice);
        (royaltyReceiver, royaltyAmount) = IERC2981(address(artNft)).royaltyInfo(_tokenId, _listPrice);
    }

    /**
     * @dev decrease tokens for sale on a fixed price listing
     *
     * @param _tokenId token id to list
     * @param _seller the seller of the token
     * @param _amount updated amount of token copies to update
     */
    function _updateFixedPriceListing(uint256 _tokenId, address _seller, uint256 _amount) internal {
        FixedPriceListing memory listing = fixedPriceListings[_tokenId][_seller];

        if (listing.amount == _amount) {
            delete fixedPriceListings[_tokenId][_seller];
        } else if (listing.amount > _amount) {
            fixedPriceListings[_tokenId][_seller].amount -= _amount;
        } else {
            revert MktNotEnoughTokens();
        }
    }

    /**
     * @dev mint listed token if not yet minted and Poc NFTs
     *
     * @param listing listing information for the token
     * @param _tokenId token id
     */
    function _minting(FixedPriceListing memory listing, uint256 _tokenId) internal {
        if (!listing.minted) {
            IArtNftERC1155(address(artNft)).mintTo(_tokenId, address(this), listing.amount);
            fixedPriceListings[_tokenId][listing.seller].minted = true;
        }
        IArtNftERC1155(address(artNft)).safeTransferFrom(address(this), msg.sender, _tokenId, 1, "");
        pocNft.mint(msg.sender, listing.marketFee, true);
        pocNft.mint(listing.seller, listing.poolFee, true);

        if (listing.starterFee > 0) {
            pocNft.mint(listing.seller, listing.starterFee, false);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCProject {
    error ProjOnlyStarterError();
    error ProjBalanceIsZeroError();
    error ProjCampaignNotActiveError();
    error ProjERC20TransferError();
    error ProjZeroAmountToWithdrawError();
    error ProjCannotTransferUnclaimedFundsError();
    error ProjCampaignNotNotFundedError();
    error ProjCampaignNotFundedError();
    error ProjUserCannotMintError();
    error ProjResultsCannotBePublishedError();
    error ProjCampaignCannotStartError();
    error ProjBackerBalanceIsZeroError();
    error ProjAlreadyClosedError();
    error ProjBalanceIsNotZeroError();
    error ProjLastCampaignNotClosedError();

    struct CampaignData {
        uint256 target;
        uint256 softTarget;
        uint256 startTime;
        uint256 endTime;
        uint256 backersDeadline;
        uint256 raisedAmount;
        bool resultsPublished;
    }

    enum CampaignStatus {
        NOTCREATED,
        ACTIVE,
        NOTFUNDED,
        FUNDED,
        SUCCEEDED,
        DEFEATED
    }

    /**
     * @dev The initialization function required to init a new VCProject contract that VCStarter deploys using
     * Clones.sol (no constructor is invoked).
     *
     * @notice This function can be invoked at most once because uses the {initializer} modifier.
     *
     * @param starter The VCStarter contract address.
     * @param pool The VCPool contract address.
     * @param lab The address of the laboratory/researcher who owns this project.
     * @param poolFeeBps Pool fee in basis points. Any project/campaign donation is subject to a fee which is
     * transferred to VCPool.
     * @param currency The protocol {_currency} ERC20 contract address, which is used for all donations.
     * Donations in any other ERC20 currecy or of any other type are not allowed.
     */
    function init(
        address starter,
        address pool,
        address lab,
        uint256 poolFeeBps,
        IERC20 currency
    ) external;

    /**
     * @dev Allows to fund the project directly, i.e. the contribution received is not linked to any campaign.
     * The donation is made in the protocol ERC20 {_currency}, which is set at the time of deployment of the
     * VCProject contract.
     *
     * @notice Only VCStarter can invoke this function. Users must invoke the homonymum function of VCStarter.
     *
     * @param _amount The amount of the donation.
     */
    function fundProject(uint256 _amount) external;

    /**
     * @dev Allows the lab owner to close the project. A closed project cannot start new campaigns nor receive
     * new contributions.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @notice Only VCProjects with a zero balance (the lab ownwer must have previously withdrawn all funds) and
     * non-active campaigns can be closed.
     */
    function closeProject() external;

    /**
     * @dev Allows the lab owner of the project to start a new campaign.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @param _target The maximum amount of ERC20 {_currency} expected to be raised.
     * @param _softTarget The minimum amount of ERC20 {_currency} expected to be raised.
     * @param _startTime The starting date of the campaign in seconds since the epoch.
     * @param _endTime The end date of the campaign in seconds since the epoch.
     * @param _backersDeadline The deadline date (in seconds since the epoch) for backers to withdraw funds
     * in case the campaign turns out to be NOT FUNDED. After that date, unclaimed funds can only be transferred
     * to VCPool and backers can mint a PoCNFT for their contributions.
     *
     * @return currentId The Id of the started campaign.
     */
    function startCampaign(
        uint256 _target,
        uint256 _softTarget,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _backersDeadline
    ) external returns (uint256 currentId);

    /**
     * @dev Allows the lab owner of the project to publish the results of their research achievements
     * related to their latest SUCCEEDED campaign.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @notice Lab owner must do this before starting a new campaign or closing the project.
     */
    function publishCampaignResults() external;

    /**
     * @dev Allows a user to fund the last running campaign, only when it is ACTIVE.
     *
     * @notice Only VCStarter can invoke this function. Users must invoke the homonymum function of VCStarter.
     *
     * @param _user The address of the user who makes the dontation.
     * @param _amount The amount of ERC20 {_currency} donated by the user.
     */
    function fundCampaign(address _user, uint256 _amount) external;

    /**
     * @dev Checks if {_user} can mint a PoCNFT for their contribution to a given campaign, and also
     * registers the mintage to forbid a user from claiming multiple PoCNFTs for the same contribution.
     *
     * @notice Only VCStarter can invoke this function. Users must invoke the function {backerMintPoCNft} of
     * VCStarter.
     *
     * @notice Two PoCNFTs are minted: one for the contribution to the Project and the other one for
     * the contribution to VCPool (fee).
     *
     * @param _campaignId The campaign Id for which {_user} claims the PoCNFTs.
     * @param _user The address of the user who claims the PoCNFTs.
     *
     * @return poolAmount The amount of the donation corresponding to VCPool.
     * @return starterAmount The amount of the donation corresponding to the Project.
     */
    function validateMint(uint256 _campaignId, address _user)
        external
        returns (uint256 poolAmount, uint256 starterAmount);

    /**
     * @dev Allows a user to withdraw funds previously contributed to the last running campaign, only when NOT
     * FUNDED.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @param _user The address of the user who is withdrawing funds.
     *
     * @return currentCampaignId The Id of the last running campaign.
     * @return backerBalance The amount of ERC20 {_currency} donated by the user.
     * @return statusDefeated It is set to true only when the campaign balance reaches zero, indicating that all
     * backers have already withdrawn their funds.
     */
    function backerWithdrawDefeated(address _user)
        external
        returns (
            uint256 currentCampaignId,
            uint256 backerBalance,
            bool statusDefeated
        );

    /**
     * @dev Allows the lab owner of the project to withdraw the raised funds of the last running campaign, only
     * when FUNDED.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @return currentCampaignId The Id of the last running campaign.
     * @return withdrawAmount The withdrawn amount (raised funds minus pool fee).
     * @return poolAmount The fee amount transferred to VCPool.
     */
    function labCampaignWithdraw()
        external
        returns (
            uint256 currentCampaignId,
            uint256 withdrawAmount,
            uint256 poolAmount
        );

    /**
     * @dev Allows the lab owner of the project to withdraw funds raised from direct contributions.
     *
     * @notice Only VCStarter can invoke this function. The lab owner must invoke the homonymum function of
     * VCStarter.
     *
     * @return amountToWithdraw The amount withdrawn, which corresponds to the total available project balance
     * excluding the balance raised from campaigns.
     */
    function labProjectWithdraw() external returns (uint256 amountToWithdraw);

    /**
     * @dev Users can send any ERC20 asset to this contract simply by interacting with the 'transfer' method of
     * the corresponding ERC20 contract. The funds received in this way do not count for the Project balance,
     * and are allocated to VCPool. This function allows any user to transfer these funds to VCPool.
     *
     * @notice Only VCStarter can invoke this function. Users must invoke the homonymum function of VCStarter.
     *
     * @param currency The ERC20 currency of the funds to be transferred to VCPool.
     *
     * @return amountAvailable The transferred amount of ERC20 {currency}.
     */
    function withdrawToPool(IERC20 currency) external returns (uint256 amountAvailable);

    /**
     * @dev Allows any user to transfer unclaimed campaign funds to VCPool after {_backersDeadline} date, only
     * when NOT FUNDED.
     *
     * @notice Only VCStarter can invoke this function. Users must invoke the homonymum function of VCStarter.
     *
     * @return currentCampaignId The Id of the last running campaign.
     * @return amountToPool The amount of ERC20 {currency} transferred to VCPool.
     */
    function transferUnclaimedFunds() external returns (uint256 currentCampaignId, uint256 amountToPool);

    /**
     * @dev Returns the total number of campaigns created by this Project.
     *
     * @return numbOfCampaigns
     */
    function getNumberOfCampaigns() external view returns (uint256);

    /**
     * @dev Returns the current campaign status of any given campaign.
     *
     * @param _campaignId The campaign Id.
     *
     * @return currentStatus
     */
    function getCampaignStatus(uint256 _campaignId) external view returns (CampaignStatus currentStatus);

    /**
     * @dev Determines if the {_amount} contributed to the last running campaign exceeds the amount needed to
     * reach the campaign's target. In that case, the additional funds are allocated to VCPool.
     *
     * @notice Only VCStarter can invoke this function.
     *
     * @param _amount The amount of ERC20 {_currency} contributed by the backer.
     *
     * @return currentCampaignId The Id of the last running campaign.
     * @return amountToCampaign The portion of the {_amount} contributed that is allocated to the campaign.
     * @return amountToPool The (possible) additional funds allocated to VCPool.
     * @return isFunded This boolean parameter is set to true only when the amount donated exceeds or equals the
     *  amount needed to reach the campaign's target, indicating that the campaign is now FUNDED.
     */
    function getFundingAmounts(uint256 _amount)
        external
        view
        returns (
            uint256 currentCampaignId,
            uint256 amountToCampaign,
            uint256 amountToPool,
            bool isFunded
        );

    /**
     * @dev Returns the project status.
     *
     * @return prjctStatus True = active, false = closed.
     */
    function projectStatus() external view returns (bool prjctStatus);

    /**
     * @dev Returns the balance of the last created campaign.
     *
     * @notice Previous campaigns allways have a zero balance, because a laboratory is not allowed to start a new
     * campaign before withdrawing the balance of the last executed campaign.
     *
     * @return lastCampaignBal
     */
    function lastCampaignBalance() external view returns (uint256 lastCampaignBal);

    /**
     * @dev Returns the portion of project balance corresponding to direct contributions not linked to any campaign.
     *
     * @return outsideCampaignsBal
     */
    function outsideCampaignsBalance() external view returns (uint256 outsideCampaignsBal);

    /**
     * @dev Gives the raised amount of ERC20 {_currency} in a given campaign.
     *
     * @param _campaignId The campaign Id.
     *
     * @return campaignRaisedAmnt
     */
    function campaignRaisedAmount(uint256 _campaignId) external view returns (uint256 campaignRaisedAmnt);

    /**
     * @dev Returns true only when the lab that owns the project has already published the results of their
     * research achievements related to a given campaign.
     *
     * @param _campaignId The campaign Id.
     *
     * @return campaignResultsPub
     */
    function campaignResultsPublished(uint256 _campaignId) external view returns (bool campaignResultsPub);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IVCProject.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCStarter {
    error SttrNotAdminError();
    error SttrNotWhitelistedLabError();
    error SttrNotLabOwnerError();
    error SttrNotCoreTeamError();
    error SttrLabAlreadyWhitelistedError();
    error SttrLabAlreadyBlacklistedError();
    error SttrFundingAmountIsZeroError();
    error SttrMinCampaignDurationError();
    error SttrMaxCampaignDurationError();
    error SttrMinCampaignTargetError();
    error SttrMaxCampaignTargetError();
    error SttrSoftTargetBpsError();
    error SttrLabCannotFundOwnProjectError();
    error SttrBlacklistedLabError();
    error SttrCampaignTargetError();
    error SttrCampaignDurationError();
    error SttrERC20TransferError();
    error SttrExistingProjectRequestError();
    error SttrNonExistingProjectRequestError();
    error SttrInvalidSignatureError();
    error SttrProjectIsNotActiveError();
    error SttrResultsCannotBePublishedError();

    event SttrWhitelistedLab(address indexed lab);
    event SttrBlacklistedLab(address indexed lab);
    event SttrSetMinCampaignDuration(uint256 minCampaignDuration);
    event SttrSetMaxCampaignDuration(uint256 maxCampaignDuration);
    event SttrSetMinCampaignTarget(uint256 minCampaignTarget);
    event SttrSetMaxCampaignTarget(uint256 maxCampaignTarget);
    event SttrSetSoftTargetBps(uint256 softTargetBps);
    event SttrPoCNftSet(address indexed poCNft);
    event SttrCampaignStarted(
        address indexed lab,
        address indexed project,
        uint256 indexed campaignId,
        uint256 startTime,
        uint256 endTime,
        uint256 backersDeadline,
        uint256 target,
        uint256 softTarget
    );
    event SttrCampaignFunding(
        address indexed lab,
        address indexed project,
        uint256 indexed campaignId,
        address user,
        uint256 amount,
        bool campaignFunded
    );
    event SttrLabCampaignWithdrawal(
        address indexed lab,
        address indexed project,
        uint256 indexed campaignId,
        uint256 amount
    );
    event SttrLabWithdrawal(address indexed lab, address indexed project, uint256 amount);
    event SttrWithdrawToPool(address indexed project, IERC20 indexed currency, uint256 amount);
    event SttrBackerMintPoCNft(address indexed lab, address indexed project, uint256 indexed campaign, uint256 amount);
    event SttrBackerWithdrawal(
        address indexed lab,
        address indexed project,
        uint256 indexed campaign,
        uint256 amount,
        bool campaignDefeated
    );
    event SttrUnclaimedFundsTransferredToPool(
        address indexed lab,
        address indexed project,
        uint256 indexed campaign,
        uint256 amount
    );
    event SttrProjectFunded(address indexed lab, address indexed project, address indexed backer, uint256 amount);
    event SttrProjectClosed(address indexed lab, address indexed project);
    event SttrProjectRequest(address indexed lab);
    event SttrCreateProject(address indexed lab, address indexed project, bool accepted);
    event SttrCampaignResultsPublished(address indexed lab, address indexed project, uint256 campaignId);
    event SttrPoolFunded(address indexed user, uint256 amount);

    /**
     * @dev Allows to set/change the admin of this contract.
     *
     * @notice Only the current {_admin} can invoke this function.
     *
     * @notice The VCAdmin smart contract is supposed to be the {_admin} of this contract.
     *
     * @param admin The address of the new admin.
     */
    function setAdmin(address admin) external;

    /**
     * @dev Allows to set/change the VCPool address for this contract.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @notice Already deployed VCProject contracts will retain the former VCPool address.
     *
     * @param pool The address of the new VCPool contract.
     */
    function setPool(address pool) external;

    /**
     * @dev Allows to set/change the VCProject template contract address.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @notice Newly created projects will clone the new VCProject template, while already deployed projects
     * will retain the former VCProject template.
     *
     * @param newProjectTemplate The address of the newly deployed VCProject contract.
     */
    function setProjectTemplate(address newProjectTemplate) external;

    /**
     * @dev Allows to set/change the Core-Team address. The Core-Team account has special roles in this contract,
     * like whitelist/blacklist a laboratory and appove/reject new projects.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param newCoreTeam The address of the new Core-Team account.
     */
    function setCoreTeam(address newCoreTeam) external;

    /**
     * @dev Allows to set/change the Tx-Validator address. The Tx-Validator is a special account, whose pk is
     * hardcoded in the VC Backend and is used to automate some project/campaign related processes: start a new
     * campaign, publish campaign results, and close project.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param newTxValidator The address of the new Tx-Validator account.
     */
    function setTxValidator(address newTxValidator) external;

    /**
     * @dev Allows to set/change the ERC20 {_currency} address for this contract.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @notice Already deployed VCProject contracts will retain the former ERC20 {_currency} address.
     *
     * @param currency The address of the new ERC20 currency contract.
     */
    function setCurrency(IERC20 currency) external;

    /**
     * @dev Allows to set/change backers timeout.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @notice The amount of time backers have to withdraw their contribution if the campaign fails.
     *
     * @param newBackersTimeout The amount of time in seconds.
     */
    function setBackersTimeout(uint256 newBackersTimeout) external;

    /**
     * @dev Allows to set/change the VCPool fee. Any project/campaign donation is subject to a fee, which is
     * eventually transferred to VCPool.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @notice Already deployed VCProject contracts will retain the former VCPool fee.
     *
     * @param newPoolFeeBps The VCPool fee in basis points.
     */
    function setPoolFeeBps(uint256 newPoolFeeBps) external;

    /**
     * @dev Allows to set an account (address) as a whitelisted lab.
     *
     * @notice Only {_coreTeam} can invoke this function.
     *
     * @notice Initially, all accounts are set as blacklisted.
     *
     * @param lab The lab to whitelist.
     */
    function whitelistLab(address lab) external;

    /**
     * @dev Allows to set an account (address) as a blacklisted lab.
     *
     * @notice Only {_coreTeam} can invoke this function.
     *
     * @notice Initially, all accounts are set as blacklisted.
     *
     * @param lab The lab to blacklist.
     */
    function blacklistLab(address lab) external;

    /**
     * @dev The are special accounts (e.g. VCPool, marketplaces) whose donations are not subject to any VCPool
     * fee. This function allows to mark addresses as 'no fee accounts'.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param accounts An array of account/contract addresses to be marked as 'no fee accounts'.
     */
    function addNoFeeAccounts(address[] memory accounts) external;

    /**
     * @dev Allows to set/change the minimum duration of a campaign.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param minCampaignDuration The minimum duration of a campaign in seconds.
     */
    function setMinCampaignDuration(uint256 minCampaignDuration) external;

    /**
     * @dev Allows to set/change the maximum duration of a campaign.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param maxCampaignDuration The maximum duration of a campaign in seconds.
     */
    function setMaxCampaignDuration(uint256 maxCampaignDuration) external;

    /**
     * @dev Allows to set/change the minimum target of a campaign.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param minCampaignTarget The minimum target of a campaign in ERC20 {_currency}.
     */
    function setMinCampaignTarget(uint256 minCampaignTarget) external;

    /**
     * @dev Allows to set/change the maximum target of a campaign.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param maxCampaignTarget The maximum target of a campaign in ERC20 {_currency}.
     */
    function setMaxCampaignTarget(uint256 maxCampaignTarget) external;

    /**
     * @dev Allows to set/change the soft target basis points. Then, the 'soft-target' of a campaign is computed
     * as target * {_softTargetBps}. The 'soft-target' is the minimum amount a campaign must raise in order to be
     * declared as FUNDED.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param softTargetBps The soft target percentage in basis points
     */
    function setSoftTargetBps(uint256 softTargetBps) external;

    /**
     * @dev Allows to set/change the VCPoCNft address for this contract.
     *
     * @notice Only {_admin} can invoke this function.
     *
     * @param pocNft The address of the new VCPoCNft contract.
     */
    function setPoCNft(address pocNft) external;

    /**
     * @dev Allows the {_coreTeam} to approve or reject the creation of a new project. The (whitelisted) lab had
     * to previously request the creation of the project, using 'createProjectRequest'.
     *
     * @notice Only {_coreTeam} can invoke this function.
     *
     * @param lab The address of the lab who had requested the creation of a new project.
     * @param accepted True = accepted, false = rejected.
     *
     * @return newProject The address of the created (and deployed) project.
     */
    function createProject(address lab, bool accepted) external returns (address newProject);

    /**
     * @dev Allows a whitelist lab to request the creation of a project. The project will be effetively created
     * after the Core-Team accepts it.
     *
     * @notice Only whitelisted labs can invoke this function.
     */
    function createProjectRequest() external;

    /**
     * @dev Allows to fund a project directly, i.e. the contribution received is not linked to any of its
     * campaigns. The donation is made in the protocol ERC20 {_currency}. The donator recieves a PoCNFT for their
     * contribution.
     *
     * @param project The address of the project beneficiary of the donation.
     * @param amount The amount of the donation.
     */
    function fundProject(address project, uint256 amount) external;

    /**
     * @dev Allows to fund a project directly (the contribution received is not linked to any of its campaigns)
     * on behalf of another user/contract. The donation is made in the protocol ERC20 {_currency}. The donator
     * does not receive a PoCNFT for their contribution.
     *
     * @param user The address of the user on whose behalf the donation is made.
     * @param project The address of the project beneficiary of the donation.
     * @param amount The amount of the donation.
     */
    function fundProjectOnBehalf(address user, address project, uint256 amount) external;

    /**
     * @dev Allows the lab owner of a project to close it. A closed project cannot start new campaigns nor receive
     * new contributions. The Tx-Validator has to 'approve' this operation by providing a signed message.
     *
     * @notice Only the lab owner of the project can invoke this function.
     *
     * @notice Only VCProjects with a zero balance (the lab owner must have previously withdrawn all funds) and
     * non-active campaigns can be closed.
     *
     * @param project The address of the project to be closed.
     * @param sig The ECDSA secp256k1 signature performed by the Tx-Validador.
     *
     * The signed message {_sig} can be constructed using ethers JSON by doing:
     *
     * const message = ethers.utils.solidityKeccak256(["address", "address"], [labAddress, projectAddress]);
     * _sig = await txValidator.signMessage(ethers.utils.arrayify(message));
     */
    function closeProject(address project, bytes memory sig) external;

    /**
     * @dev Allows the lab owner of a project to start a new campaign.
     *
     * @notice Only the lab owner of the project can invoke this function.
     *
     * @param project The address of the project.
     * @param target The amount of ERC20 {_currency} expected to be raised.
     * @param duration The duration of the campaign in seconds.
     * @param sig The ECDSA secp256k1 signature performed by the Tx-Validador.
     *
     * The signed message {_sig} can be constructed using ethers JSON by doing:
     *
     * const message = ethers.utils.solidityKeccak256( ["address","address","uint256","uint256","uint256"],
     *    [labAddress, projectAddress, numberOfCampaigns, target, duration]);
     * _sig = await txValidator.signMessage(ethers.utils.arrayify(message));
     */
    function startCampaign(
        address project,
        uint256 target,
        uint256 duration,
        bytes memory sig
    ) external returns (uint256 campaignId);

    /**
     * @dev Allows the lab owner of the project to publish the results of their research achievements
     * related to their latest SUCCEEDED campaign.
     *
     * @notice Only the lab owner of the project can invoke this function.
     *
     * @param project The address of the project.
     * @param sig The ECDSA secp256k1 signature performed by the Tx-Validador.
     *
     * The signed message {_sig} can be constructed using ethers JSON by doing:
     *
     * const message = ethers.utils.solidityKeccak256(["address","address","uint256"],
     *      [labAddress, projectAddress, campaignId]);
     * _sig = await txValidator.signMessage(ethers.utils.arrayify(message));
     */
    function publishCampaignResults(address project, bytes memory sig) external;

    /**
     * @dev Allows a user to fund the last running campaign, only when it is ACTIVE.
     *
     * @param project The address of the project.
     * @param amount The amount of ERC20 {_currency} donated by the user.
     */
    function fundCampaign(address project, uint256 amount) external;

    /**
     * @dev Allows a backer to mint a PoCO NFT in return for their contribution to a campaign. The campaign must
     * be FUNDED, or NOT_FUNDED and claming_time > {_backersDeadline} time.
     *
     * @param project The address of the project to which the campaign belongs.
     * @param campaignId The id of the campaign.
     */
    function backerMintPoCNft(address project, uint256 campaignId) external;

    /**
     * @dev Allows a user to withdraw funds previously contributed to the last running campaign, only when NOT
     * FUNDED.
     *
     * @param project The address of the project to which the campaign belongs.
     */
    function backerWithdrawDefeated(address project) external;

    /**
     * @dev Allows the lab owner of the project to withdraw the raised funds of the last running campaign, only
     * when FUNDED.
     *
     * @notice Only the lab owner of the project can invoke this function.
     *
     * @param project The address of the project to which the campaign belongs.
     */
    function labCampaignWithdraw(address project) external;

    /**
     * @dev Allows the lab owner of the project to withdraw funds raised from direct contributions.
     *
     * @notice Only the lab owner of the project can invoke this function.
     *
     * @param project The address of the project to which the campaign belongs.
     */
    function labProjectWithdraw(address project) external;

    /**
     * @dev Allows any user to transfer unclaimed campaign funds to VCPool after {_backersDeadline} date, only
     * when NOT FUNDED.
     *
     * @param _project The address of the project to which the campaign belongs.
     */
    function transferUnclaimedFunds(address _project) external;

    /**
     * @dev Users can send any ERC20 asset to this contract simply by interacting with the 'transfer' method of
     * the corresponding ERC20 contract. The funds received in this way do not count for the Project balance
     * and are allocated to VCPool. This function allows any user to transfer these funds to VCPool.
     *
     * @param project The address of the project.
     * @param currency The ERC20 currency of the funds to be transferred to VCPool.
     */
    function withdrawToPool(address project, IERC20 currency) external;

    /**
     * @dev Returns the Pool Fee in Basis Points
     */
    function poolFeeBps() external view returns (uint256);

    /**
     * @dev Returns Min Campaing duration in seconds.
     */
    function minCampaignDuration() external view returns (uint256);

    /**
     * @dev Returns Max Campaing duration in seconds.
     */
    function maxCampaignDuration() external view returns (uint256);

    /**
     * @dev Returns Min Campaign target in USD.
     */
    function minCampaignTarget() external view returns (uint256);

    /**
     * @dev Returns Max Campaign target is USD.
     */
    function maxCampaignTarget() external view returns (uint256);

    /**
     * @dev Returns Soft Target in basis points.
     */
    function softTargetBps() external view returns (uint256);

    /**
     * @dev Returns Fee Denominator in basis points.
     */
    function feeDenominator() external view returns (uint256);

    /**
     * @dev Returns the address of VCStarter {_admin}.
     *
     * @notice The admin of this contract is supposed to be the VCAdmin smart contract.
     */
    function getAdmin() external view returns (address);

    /**
     * @dev Returns the address of this contract ERC20 {_currency}.
     */
    function getCurrency() external view returns (address);

    /**
     * @dev Returns the campaign status of a given project.
     *
     * @param project The address of the project to which the campaign belongs.
     * @param campaignId The id of the campaign.
     *
     * @return currentStatus
     */
    function getCampaignStatus(
        address project,
        uint256 campaignId
    ) external view returns (IVCProject.CampaignStatus currentStatus);

    /**
     * @dev Checks if a given project (address) belongs to a given lab.
     *
     * @param lab The address of the lab.
     * @param project The address of the project.
     *
     * @return True if {_lab} is the owner of {_project}, false otherwise.
     */
    function isValidProject(address lab, address project) external view returns (bool);

    /**
     * @dev Checks if a certain laboratory (address) is whitelisted.
     *
     * @notice Only whitelisted labs can create projects and start new campaigns.
     *
     * @param lab The address of the lab.
     *
     * @return True if {_lab} is whitelisted, False otherwise.
     */
    function isWhitelistedLab(address lab) external view returns (bool);

    /**
     * @dev Checks if certain addresses correspond to active projects.
     *
     * @param projects An array of addresses.
     *
     * @return An array of booleans of the same length as {_projects}, where its ith position is set to true if
     * and only if {projects[i]} correspondes to an active project.
     */
    function areActiveProjects(address[] memory projects) external view returns (bool[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IArtNftERC1155 is IERC1155 {
    /// @notice A batch represents a collection of assets, each one with a given number of copies (i.e. `totalSupplies`)
    struct Batch {
        string cid;
        string name;
        address creator;
        uint256 firstTokenId;
        uint256[] totalSupplies;
    }

    struct LazyMintBatchArgs {
        address creator;
        string cid;
        string name;
        uint256[] totalSupplies;
        address receiver;
        uint96 royaltyFeeBps;
    }

    struct LazyMintBatchNoCreatorArgs {
        string cid;
        string name;
        uint256[] totalSupplies;
        address receiver;
        uint96 royaltyFeeBps;
    }

    error ArtNftOnlyAdminAllowedError();
    error ArtOnlyCreatorCanRequestError();
    error ArtNftUnexpectedAdminAddressError();
    error ArtBatchSizeError();
    error ArtExceededMaxRoyaltyError();
    error ArtAlreadyMintedError();
    error ArtExceededTotalSupplyError();
    error ArtTokenNotYetCreatedError();
    error ArtTokenAlreadyMintedError();
    error ArtTotalSupplyZeroError();
    error ArtRoyaltyBeneficaryZeroAddressError();

    event BatchCreated(address indexed creator, uint256 batchId, Batch batch, uint96 royaltyBps);

    function setAdmin(address admin) external; // onlyAdmin

    function setMinterRole(address minter, bool grant) external; // onlyAdmin

    function setApproverRole(address approver, bool grant) external; // onlyAdmin

    function setLazyMinterRole(address lazyMinter, bool grant) external; // onlyAdmin

    function setMaxRoyalty(uint256 maxRoyaltyBps) external; // onlyAdmin

    function setMaxBatchSize(uint256 maxBatchSize) external; // onlyAdmin

    function setApprovalForAllCustom(address caller, address operator, bool approved) external; // only(APPROVER_ROLE)

    function lazyMintBatchOnBehalf(LazyMintBatchArgs memory args) external; // only(LAZY_MINTER_ROLE)

    function lazyMintBatch(LazyMintBatchNoCreatorArgs memory args) external;

    function requireCanRequestMint(address _by, uint256 _tokenId, uint256 _amount) external view;

    function lazyTotalSupply(uint256 tokenId) external view returns (uint256);

    function mintTo(uint256 tokenId, address to, uint256 amount) external; // only(MINTER_ROLE)

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function creatorOf(uint256 _tokenId) external view returns (address);

    function setTokenRoyaltyReceiver(uint256 _tokenId, address _receiver) external; // onlyTokenCreator

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function exists(uint256 id) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IArtNftERC721 is IERC721 {
    /// @notice A batch represents a collection of assets, each one with only one copy
    struct Batch {
        string cid;
        string name;
        address creator;
        uint256 firstTokenId;
        uint256 size;
    }

    struct LazyMintBatchArgs {
        address creator;
        string cid;
        string batchName;
        uint256 batchSize;
        address receiver;
        uint96 royaltyFeeBps;
    }

    struct LazyMintBatchNoCreatorArgs {
        string cid;
        string batchName;
        uint256 batchSize;
        address receiver;
        uint96 royaltyFeeBps;
    }

    error ArtNftOnlyAdminAllowedError();
    error ArtOnlyCreatorCanRequestError();
    error ArtNftUnexpectedAdminAddressError();
    error ArtBatchSizeError();
    error ArtExceededMaxRoyaltyError();
    error ArtAlreadyMintedError();
    error ArtTokenNotYetCreatedError();
    error ArtRoyaltyBeneficaryZeroAddressError();
    error ArtERC20TransferError();

    event BatchCreated(address indexed creator, uint256 batchId, Batch batch, uint96 royaltyBps);
    event ArtWithdrawal(IERC20 indexed _currency, address _to, uint256 amount);

    function setAdmin(address _admin) external; // onlyAdmin

    function setMinterRole(address minter, bool grant) external; // onlyAdmin

    function setApproverRole(address approver, bool grant) external; // onlyAdmin

    function setLazyMinterRole(address lazyMinter, bool grant) external; // onlyAdmin

    function setMaxRoyalty(uint256 _maxRoyaltyBps) external; // onlyAdmin

    function setMaxBatchSize(uint256 _maxBatchSize) external; // onlyAdmin

    function setApprovalForAllCustom(
        address caller,
        address operator,
        bool approved
    ) external; // only(APPROVER_ROLE)

    function lazyMintBatch(LazyMintBatchNoCreatorArgs memory args) external;

    function lazyMintBatchOnBehalf(LazyMintBatchArgs memory args) external; // only(LAZY_MINT_ROLE)

    function requireCanRequestMint(address _by, uint256 _tokenId) external view;

    function mintTo(uint256 _tokenId, address _to) external; // only(MINTER_ROLE)

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function creatorOf(uint256 _tokenId) external view returns (address);

    function setTokenRoyaltyReceiver(uint256 _tokenId, address _receiver) external; // onlyTokenCreator

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function exists(uint256 _tokenId) external view returns (bool);

    function withdrawTo(IERC20 _currency, address _to) external; // onlyAdmin
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPoCNft is IERC721 {
    struct Contribution {
        uint256 amount;
        uint256 timestamp;
    }

    struct Range {
        uint240 maxDonation;
        uint16 maxBps;
    }

    event PoCNFTMinted(address indexed user, uint256 amount, uint256 tokenId, bool isPool);
    event PoCBoostRangesChanged(Range[]);

    error PoCUnexpectedAdminAddress();
    error PoCOnlyAdminAllowed();
    error PoCUnexpectedBoostDuration();
    error PoCInvalidBoostRangeParameters();

    function setAdmin(address newAdmin) external; // onlyAdmin

    function grantMinterRole(address _address) external; // onlyAdmin

    function revokeMinterRole(address _address) external; // onlyAdmin

    function grantApproverRole(address _approver) external; // onlyAdmin

    function revokeApproverRole(address _approver) external; // onlyAdmin

    function setPool(address pool) external; // onlyAdmin

    function changeBoostDuration(uint256 newBoostDuration) external; // onlyAdmin

    function changeBoostRanges(Range[] calldata newBoostRanges) external; // onlyAdmin

    function setApprovalForAllCustom(
        address caller,
        address operator,
        bool approved
    ) external; // only(APPROVER_ROLE)

    //function supportsInterface(bytes4 interfaceId) external view override returns (bool);

    function exists(uint256 tokenId) external returns (bool);

    function votingPowerBoost(address _user) external view returns (uint256);

    function denominator() external pure returns (uint256);

    function getContribution(uint256 tokenId) external view returns (Contribution memory);

    function mint(
        address _user,
        uint256 _amount,
        bool isPool
    ) external; // only(MINTER_ROLE)

    function transfer(address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract CanWithdrawERC20 {
    error ERC20WithdrawalFailed();
    event ERC20Withdrawal(address indexed to, IERC20 indexed token, uint256 amount);

    address _to = 0x000000000000000000000000000000000000dEaD;
    mapping(IERC20 => uint256) _balanceNotWithdrawable;

    constructor() {}

    function withdraw(IERC20 _token) external {
        uint256 balanceWithdrawable = _token.balanceOf(address(this)) - _balanceNotWithdrawable[_token];

        if (balanceWithdrawable == 0 || !_token.transfer(_to, balanceWithdrawable)) {
            revert ERC20WithdrawalFailed();
        }
        emit ERC20Withdrawal(_to, _token, balanceWithdrawable);
    }

    function _setTo(address to) internal {
        _to = to;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract FeeManager {
    /// @notice Used to translate from basis points to amounts
    uint96 public constant FEE_DENOMINATOR = 10_000;

    /**
     * @dev Translates a fee in basis points to a fee amount.
     */
    function _toFee(uint256 _amount, uint256 _feeBps) internal pure returns (uint256) {
        return (_amount * _feeBps) / FEE_DENOMINATOR;
    }
}