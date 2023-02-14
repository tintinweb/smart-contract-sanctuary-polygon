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
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

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

    enum SaleType {
        PRIMARY,
        SECONDARY
    }

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo internal _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    error ERC2981RoyaltyFeeExceedsSalePrice();
    error ERC2981InvalidReceiver();


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
        if(feeNumerator > _feeDenominator()) revert ERC2981RoyaltyFeeExceedsSalePrice();
        
        if(receiver == address(0)) revert ERC2981InvalidReceiver();

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
        if(feeNumerator > _feeDenominator()) revert ERC2981RoyaltyFeeExceedsSalePrice();
        
        if(receiver == address(0)) revert ERC2981InvalidReceiver();

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
// Creator: Chiru Labs

// Fork of ERC721A.sol (it's not the same one as on npm package erc721a because this one has extension methods removed)

pragma solidity ^0.8.15;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex times
        unchecked {
            return _currentIndex - _burnCounter;    
        }
    }

     /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        if (index >= balanceOf(owner)) revert OwnerIndexOutOfBounds();
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        // Execution should never reach this point.
        revert();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (!ownership.burned) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        revert TokenIndexOutOfBounds();
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
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[owner].numberMinted);
    }

    function _numberBurned(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BurnedQueryForZeroAddress();
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant: 
                    // There will always be an ownership that has an address and is not burned 
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? 
            string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : 
            '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        safeTransferFrom(from, to, tokenId, '');
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
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe && !_checkOnERC721Received(address(0), to, updatedIndex, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
                updatedIndex++;
            }

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
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
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        _beforeTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[prevOwnership.addr].balance -= 1;
            _addressData[prevOwnership.addr].numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            _ownerships[tokenId].addr = prevOwnership.addr;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
            _ownerships[tokenId].burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(prevOwnership.addr, address(0), tokenId);
        _afterTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked { 
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721ReceiverImplementer();
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
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import './ERC721AOperator.sol';
import './interfaces/IERC721AMarketplace.sol';

abstract contract ERC721AMarketplace is IERC721AMarketplace, ERC721AOperator {

    address public paymentToken;

    uint256 public offersCount;

    /** BuyOffer variables */
    //in the form of offerId => Offer;
    mapping(uint256 => BuyOffer) private _buyOffers;

    //in the form of buyer => offerIds
    mapping(address => uint256[]) private _buyOffersByBuyer;

    //in the form of tokenId => offerIds
    mapping(uint256 => uint256[]) private _buyOffersByEntryPos;

    /** SellOffer variables */
    // in the form of tokenId => paymentPrice, only for saleOffers
    mapping(uint256 => uint256) public priceByToken;

    /// @inheritdoc IERC721AMarketplace
    function versionERC721AMarketplace() external pure virtual override returns (string memory) {
        return '1.0.0-beta.0+fob.rsv.iERC721AMarketplace';
    }

    /***** SELL OFFERS */
    /** Seller */
    /// @inheritdoc IERC721AMarketplace
    function setSellingPrice(uint256[] memory tokenIds, uint256[] memory sellPrices) external virtual override {
        if (tokenIds.length != sellPrices.length) revert ERC721AMKInvalidBatchLengths();
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 sellPrice = sellPrices[i];

            if (ownerOf(tokenId) != _msgSender()) revert ERC721AMKNotTokenOwner();

            priceByToken[tokenId] = sellPrice;
            emit SetSellPrice(tokenId, sellPrice);
        }
    }

    /** Buyer */
    /// @inheritdoc IERC721AMarketplace
    function buyBatch(uint256[] memory tokenIds) external virtual override {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 buyPrice = priceByToken[tokenId];
            if (buyPrice == 0) revert ERC721AMKTokenNotForSale();
            address buyer = _msgSender();
            address seller = ownerOf(tokenId);
            _transferTokens(tokenId, seller, buyer, buyPrice, paymentToken);

            emit Sell(buyer, seller, tokenId, buyPrice);
        }
    }

    /// @inheritdoc IERC721AMarketplace
    function getSellOffers(uint256 entryPos) external view virtual override returns (uint256[] memory, uint256[] memory) {
        uint256[] memory tickets = getTicketsByEntry(entryPos);
        uint256 ticketsAmount = tickets.length;

        uint256[] memory res = new uint256[](ticketsAmount);

        for (uint256 i; i < ticketsAmount; i++) {
            res[i] = priceByToken[tickets[i]];
        }

        return (tickets, res);
    }


    /************************************************************************************************************************ */

    /******* BUY OFFERS */
    /** Buyer sets Offer for an amount defined in an entryPos*/
    /// @inheritdoc IERC721AMarketplace
    function setOffer(
        uint256 entryPos,
        uint256 amount,
        uint256 pricePerToken,
        uint256 deadline
    ) external virtual override {
        if (entryPos == 0 || entryPos > entriesCount) revert ERC721AMKInvalidEntryPos();
        if (deadline <= block.timestamp) revert ERC721AMKWrongDeadline();
        if (pricePerToken == 0) revert ERC721AMKInvalidOfferPrice();

        BuyOffer memory buyOffer = BuyOffer(
            entryPos,
            amount,
            pricePerToken,
            deadline,
            _msgSender(),
            new uint256[](0),
            new address[](0)
        );

        uint256 offerId = offersCount += 1;
        _buyOffers[offerId] = buyOffer;
        _buyOffersByBuyer[_msgSender()].push(offerId);
        _buyOffersByEntryPos[entryPos].push(offerId);
        emit NewBuyOffer(_msgSender(), entryPos, offerId, amount);
    }

    /** Seller */
    /// @inheritdoc IERC721AMarketplace
    function acceptBuyOffer(uint256 offerId, uint256[] memory tokenIds) external virtual override {
        if (offerId > offersCount) revert ERC721AMKUnexistentOffer();

        BuyOffer storage buyOffer = _buyOffers[offerId];

        if (buyOffer.deadline < block.timestamp) revert ERC721AMKOfferDeadlineOver();

        if (buyOffer.amount == buyOffer.sellers.length) revert ERC721AMKOfferFulfilled();

        uint256 availableToSell = buyOffer.amount - buyOffer.sellers.length;
        uint256 amountToSell = tokenIds.length;

        if(amountToSell > availableToSell) revert ERC721AMKTooManyTokensToSell();

        uint256 entryPos = buyOffer.entryPos;

        for (uint256 i; i < amountToSell; i++) {
            uint256 tokenId = tokenIds[i];
            if (_entryByTokenId[tokenId] != entryPos) revert ERC721AMKInvalidToken();
            if (ownerOf(tokenId) != _msgSender()) revert ERC721AMKNotTokenOwner();

            buyOffer.sellers.push(_msgSender());
            buyOffer.tokensBought.push(tokenId);

            _transferTokens(tokenId, _msgSender(), buyOffer.buyer, buyOffer.pricePerToken, paymentToken);
        }
        emit AcceptOffer(offerId, amountToSell); 
    }

    /** Buyer */
    /// @inheritdoc IERC721AMarketplace
    function cancelOffer(uint256 offerId) external virtual override {
        BuyOffer storage offer = _buyOffers[offerId];
        address buyer = offer.buyer;
        if (buyer != _msgSender()) revert ERC721AMKNotOfferOwner();
        _buyOffers[offerId].deadline = 0;
        emit CancelOffer(offerId);
    }

    /** Getters */
    /// @inheritdoc IERC721AMarketplace
    function getOffersByEntry(
        uint256 entryPos,
        bool active,
        bool expired,
        bool fulfilled
    ) external view virtual override returns (uint256[] memory) {
        uint256[] memory offersByEntry = _buyOffersByEntryPos[entryPos];
        return _activeOffers(offersByEntry, active, expired, fulfilled);
    }

    /// @inheritdoc IERC721AMarketplace
    function getOffersByBuyer(
        address buyer,
        bool active,
        bool expired,
        bool fulfilled
    ) external view virtual override returns (uint256[] memory) {
        uint256[] memory offersByBuyerCount = _buyOffersByBuyer[buyer];
        return _activeOffers(offersByBuyerCount, active, expired, fulfilled);
    }

    /// @inheritdoc IERC721AMarketplace
    function getOffer(uint256 offerId) external view virtual override returns (BuyOffer memory) {
        return _buyOffers[offerId];
    }

    function _activeOffers(
        uint256[] memory offers_,
        bool active,
        bool expired,
        bool fulfilled
    ) private view returns (uint256[] memory tempOffers) {
        tempOffers = new uint256[](offers_.length);
        for (uint256 i; i < offers_.length; i++) {
            BuyOffer memory offer = _buyOffers[offers_[i]];
            bool isFulfilled = offer.sellers.length == offer.amount;
            if(fulfilled && isFulfilled) {
                tempOffers[i] = offers_[i];
            } else if (
                (offer.deadline > block.timestamp && active && !isFulfilled) 
                || 
                (offer.deadline < block.timestamp && expired)
            ) {
                tempOffers[i] = offers_[i];
            }
        }
    }


    function _beforeTokenTransfers(
        address from,
        address /* to */,
        uint256 startTokenId,
        uint256 /* quantity */
    ) internal virtual override {
        if (from != address(0)) {
            priceByToken[startTokenId] = 0;
        }

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721AOperator) returns (bool) {
        return interfaceId == type(IERC721AMarketplace).interfaceId || super.supportsInterface(interfaceId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './ERC721ARoyalty.sol';
import './interfaces/IERC721AOperator.sol';

abstract contract ERC721AOperator is IERC721AOperator, ERC721ARoyalty {
    
    address internal _secondarySalesRoyaltyReceiver;
    uint96 internal _secondarySalesRoyaltyFeeDenominator;

    uint256 public entriesCount; //starts from 1

    // tokenId => entryTypePos
    mapping(uint256 => uint256) internal _entryByTokenId;

    mapping(uint256 => uint256[]) internal _tokensByEntry;

    /// @inheritdoc IERC721AOperator
    function versionERC721AOperator() external pure virtual override returns (string memory) {
        return '1.0.0-beta.0+fob.rsv.iERC721AOperator';
    }

    function _saveTickets(
        uint256 currentIndex,
        uint256 amount,
        uint256 entryPos
    ) internal {
        uint256 nextTokenId = currentIndex;
        for (uint256 i; i < amount; i++) {
            uint256 tokenId = nextTokenId + i;
            _entryByTokenId[tokenId] = entryPos;
            _tokensByEntry[entryPos].push(tokenId);
            _setTokenRoyalty(tokenId, _secondarySalesRoyaltyReceiver, _secondarySalesRoyaltyFeeDenominator);
        }
    }

    function _transferTokens(
        uint256 tokenId,
        address seller,
        address buyer,
        uint256 sellPrice,
        address paymentToken
    ) internal {
        (address receiver, uint256 amount) = royaltyInfo(tokenId, sellPrice);
        IERC20 token = IERC20(paymentToken);
        token.transferFrom(buyer, receiver, amount);
        token.transferFrom(buyer, ownerOf(tokenId), sellPrice - amount);
        ERC721A._approve(buyer, tokenId, seller);
        ERC721A.transferFrom(seller, buyer, tokenId);
    }

    /// @inheritdoc IERC721AOperator
    function getTicketsByEntry(uint256 entryPos) public view virtual override returns (uint256[] memory) {
        return _tokensByEntry[entryPos];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721ARoyalty) returns (bool) {
        return interfaceId == type(IERC721AOperator).interfaceId || super.supportsInterface(interfaceId);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./ERC721A.sol";
import "./ERC2981.sol";

abstract contract ERC721ARoyalty is ERC2981, ERC721A {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function _getDefaultRoyaltyBatch(uint256 amount) internal view returns(address, uint256) {
        RoyaltyInfo memory info = _defaultRoyaltyInfo;
        uint256 royaltyAmount = (amount * info.royaltyFraction) / _feeDenominator();
        return (info.receiver, royaltyAmount);
    }

    
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import './ERC721FactoryWide.sol';
import '../interfaces/IERC721EFactory.sol';

import '../nfts/ERC721E.sol';
import '../OwnedByReserv.sol';


/// @notice Deploys most simple ERC721 Event contract
contract ERC721EFactory is ERC721FactoryWide, IERC721EFactory, OwnedByReserv {

    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 private constant forwarderVersion = keccak256(bytes('1.0.0-beta.0+fob.rsv.iForwarder'));
    
    constructor(address forwarder, address reservOwnerContract) OwnedByReserv(reservOwnerContract) {
        _forwarder = forwarder;
    }

    /// @inheritdoc IERC721EFactory
    function versionERC721Factory() external pure virtual override returns (string memory) {
        return '1.0.0-beta.0+fob.rsv.iERC721EFactory';
    }

    /// @inheritdoc IERC721EFactory
    function setTrustedForwarer(address forwarder) external virtual override onlyReserv {
        _setTrustedForwarer(forwarder);
    }

    /// @inheritdoc IERC721EFactory
    function deploy(
        string memory name,
        string memory symbol,
        address venue,
        bytes memory data
    ) external virtual override returns (address) {
        if (!isTrustedForwarder(_msgSender())) revert ERC721EFactoryInvalidForwarder();

        ERC721E erc721E = new ERC721E(name, symbol, venue, reservOwnerContract(), data);

        address contractAddress = address(erc721E);
        _eventsByVenue[venue].add(contractAddress);

        emit EventDeployed(venue, owner(), block.number);
        return contractAddress;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721EFactory).interfaceId || super.supportsInterface(interfaceId);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../interfaces/IReservForwarder.sol";
import "../interfaces/IERC721FactoryWide.sol";

abstract contract ERC721FactoryWide is IERC721FactoryWide, Context {
    using EnumerableSet for EnumerableSet.AddressSet;

    address internal _forwarder;

    mapping(address => EnumerableSet.AddressSet) internal _eventsByVenue;

    /// @inheritdoc IERC721FactoryWide
    function versionERC721FactoryWide()
        external
        pure
        virtual
        override
        returns (string memory)
    {
        return "1.0.0-beta.0+fob.rsv.iERC721FactoryWide";
    }

    /// @inheritdoc IERC721FactoryWide
    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _forwarder == forwarder;
    }

    function _setTrustedForwarer(address forwarder) internal {
        if(!IERC165(forwarder).supportsInterface(type(IReservForwarder).interfaceId)) revert ERC721EFactoryWideInvalidForwarderInterface();
       
        _forwarder = forwarder;
    }

    /// @inheritdoc IERC721FactoryWide
    function removeEvent(address venue, address _event)
        external
        virtual
        override
    {
        if(!isTrustedForwarder(_msgSender())) revert ERC721EFactoryWideInvalidForwarder();
        
        if(!_eventsByVenue[venue].contains(_event)) revert ERC721EFactoryWideEventNotFound();
        
        _eventsByVenue[venue].remove(_event);

        emit EventRemoved(venue, _event);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return interfaceId == type(IERC721FactoryWide).interfaceId;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IERC721AMarketplace {
    event Sell(address indexed buyer, address indexed seller, uint256 indexed tokenId, uint256 sellprice);
    event SetSellPrice(uint256 tokenId, uint256 sellPrice);

    event NewBuyOffer(address indexed buyer, uint256 indexed entryPos, uint256 indexed offerId, uint256 amount);
    event AcceptOffer(uint256 indexed offerId, uint256 amountSold);
    event CancelOffer(uint256 indexed offerId);

    error ERC721AMKWrongDeadline();
    error ERC721AMKUnexistentOffer();
    error ERC721AMKNotTokenOwner();
    error ERC721AMKOfferDeadlineOver();
    error ERC721AMKNotOfferOwner();
    error ERC721AMKInvalidOfferPrice();
    error ERC721AMKTokenNotForSale();
    error ERC721AMKInvalidBatchLengths();
    error ERC721AMKInvalidEntryPos();
    error ERC721AMKOfferFulfilled();
    error ERC721AMKInvalidToken();
    error ERC721AMKTooManyTokensToSell();

    struct BuyOffer {
        uint256 entryPos;
        uint256 amount;
        uint256 pricePerToken;
        uint256 deadline;
        address buyer;
        uint256[] tokensBought;
        address[] sellers;
    }

    function versionERC721AMarketplace() external pure returns (string memory);

    function setSellingPrice(uint256[] memory tokenIds, uint256[] memory sellPrices) external;

    function buyBatch(uint256[] memory tokenIds) external;

    function getSellOffers(uint256 entryPos) external view returns (uint256[] memory, uint256[] memory);

    function setOffer(
        uint256 entryPos,
        uint256 amount,
        uint256 pricePerToken,
        uint256 deadline
    ) external;

    function acceptBuyOffer(uint256 offerId, uint256[] memory tokenIds) external;

    function cancelOffer(uint256 offerId) external;

    function getOffersByEntry(
        uint256 entryPos,
        bool active,
        bool expired,
        bool fulfilled
    ) external view returns (uint256[] memory);

    function getOffersByBuyer(
        address buyer,
        bool active,
        bool expired,
        bool fulfilled
    ) external view returns (uint256[] memory);

    function getOffer(uint256 offerId) external view returns (BuyOffer memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC721AOperator {

    function versionERC721AOperator() external pure returns (string memory);

     function getTicketsByEntry(uint256 entryPos) external view returns(uint256[] memory);

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IERC721Wide.sol";

interface IERC721E is IERC721Wide {

    event NewEntry(uint256 indexed pos, string name, uint256 indexed price, uint256 maxSupply, uint256 saleEnd);
    event MintTickets(address indexed buyer, uint256 indexed userId, uint256 indexed entryType, uint256 amount);
    
    struct EntryType {
        string name;
        uint256 price;
        uint256 maxSupply;
        uint256 maxBuy;
        uint256 sold;
        uint256 saleEnd;
    }

    /// @dev create ticket entry type, i.e VIP 2000USDC 100
    /// @param name VIP, PLATINUM, TABLE....
    /// @param price price per token/ticket
    /// @param maxSupply max number of tokens/tickets that can be sold
    /// @param maxBuy max number of tokens/tickets sender can buy
    /// @param saleEnd ticket sale deadline
    function createEntry(
        string memory name,
        uint256 price,
        uint256 maxSupply,
        uint256 maxBuy,
        uint256 saleEnd
    ) external;

    /// @dev mints/buys tokens/tickets for defined EntrType
    /// @param receiver token receiver
    /// @param userId user id
    /// @param entryPos location of EntryType
    /// @param amount amount of tokens/tickets to mint/buy
    function buyTickets(
        address receiver,
        uint256 userId,
        uint256 entryPos,
        uint256 amount
    ) external;

    function getTicketInfo(uint256 tokenId) external view returns (EntryType memory);

    function getEntry(uint256 pos) external view returns(EntryType memory);



}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC721EFactory {

    error ERC721EFactoryInvalidForwarder();

    function versionERC721Factory() external pure returns (string memory);

    function setTrustedForwarer(address forwarder) external;

    // /// @dev only forwarder can perform this operation
    // /// @param paymentToken USDC Token
    // /// @param venue Venue Address
    // /// @param owner Owner of the ERC721, which case would be Forwarder's owner
    // /// @param constructorData ERC721 Constructor data
    // /// @param royaltyData Royalty data for primary and secondary sales
    // /// @param extraData encoded data to be passed to the Factory
    function deploy(
        string memory name,
        string memory symbol,
        address venue,
        bytes memory data
    ) external returns(address);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC721FactoryWide {

    event EventDeployed(address indexed venue, address indexed _event, uint256 indexed blockNumber);
    event EventRemoved(address indexed venue, address indexed _event);

    error ERC721EFactoryWideInvalidForwarderInterface();
    error ERC721EFactoryWideInvalidForwarder();
    error ERC721EFactoryWideEventNotFound();
    
    function versionERC721FactoryWide() external pure returns (string memory);

    function isTrustedForwarder(address forwarder) external view returns (bool) ;

    function removeEvent(address venue, address _event) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC721Wide {

    error ERC721WrongPrice();
    error ERC721WrongMaxSupply();
    error ERC721ReachedMaxSupply();
    error ERC721TooManyTickets();
    error ERC721NonExistentToken();
    error ERC721WrongEntryPos();
    error ERC721WrongEventDate();
    error ERC721WrongSaleEnd();
    error ERC721SaleEnded();   

    function setBaseURI(string memory baseUri) external;

    function editEntryName(uint256 entryPos, string memory name) external;
    function editEntryPrice(uint256 entryPos, uint256 price) external;
    function editEntryMaxSupply(uint256 entryPos, uint256 maxSupply) external;
    function editEntryMaxBuy(uint256 entryPos, uint256 maxSupply) external;
    function editEntrySaleEnd(uint256 entryPos, uint256 saleEnd) external;
    function setEventDate(uint256 _eventDate) external;

    function versionERC721() external pure returns (string memory);

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IReservForwarder {

    event NewFactory(uint256 factoriesCount, address indexed factory);
    event DeprecateFactory(address indexed factory, bool indexed deprecate);
    event Deployment(address indexed venue, address indexed factory, address indexed deployed);
    event Removed(address indexed venue, address indexed factory, address indexed _event);

    error ForwarderFactoryAddressZero();
    error ForwarderUnableToRetrieveFactryInterface();
    error ForwarderNotSupportedInterface();
    error ForwarderUnexistentFactory();
    error ForwarderDeprecatedFactory();
    error ForwarderUnknownVenue();
    error ForwarderErrorDeploying();
    error ForwarderErrorRemoving();
    error ForwarderFactoryAlreadyAdded();
    error ForwarderNotDeprecatedFactory();

    function versionForwarder() external pure returns (string memory);

    /// @dev must be called by forwarder owner
    /// @param factory must implement IERC721FactoryWide Interface
    function addfactory(address factory) external;

    /// @dev must be called by forwarder owner
    function deprecateFactory(address factory, bool deprecate) external;

    function deploy(
        uint256 typeOf,
        string memory name,
        string memory symbol,
        bytes memory mainData
    ) external returns (address);

    function removeEvent(address _event, uint256 typeOf) external;

    function getFactoryAt(uint256 position) external view returns(address);

    function getFactoryPosition(address factory) external view returns(uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IReservOwner {

    error NotReserv();
    error NotSuperOwner();

    function transferSuperOwnership(address newSuperOwner) external;
    function addManager(address newManager) external;
    function removeManager(address manager) external;
    function setRepresentative(address newRepresentative) external;
    function setTreasury(address newTreasury) external;
    function addCardPayee(address newPayee) external;
    function removeCardPayee(address payee) external;
    function clearCardPayees() external;
    function clearManagers() external;

    function isManager(address manager) external view returns (bool);
    function isCardPayee(address payee) external view returns (bool);
    function isSuperOwner(address owner) external view returns (bool);

    function superOwner() external view returns (address);
    function representative() external view returns (address);
    function treasury() external view returns (address);
    function cardPayees() external view returns (address[] memory);
    function managers() external view returns (address[] memory);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IVenueSBT {

    event NewEvent(address indexed _event, uint256 indexed tokenId, uint256 indexed blockNumber);
    event BurnEvent(address indexed _event, uint256 indexed tokenId);

    error VenueInvalidRoyaltyReceiver();
    error VenueInvalidRoyaltyFeeNumerator();
    error VenueFailedDeployingEvent();
    error VenueUnableToBurn();
    error VenueFailedForwardingCall();
    error VenueSBTNonTransferable();
    error VenueUnexistentToken();
    error VenueWrongPaymentToken();
    error VenueFailedToTransferETH();
    error VenueSecondarySalesAlreadySet();
    error ForwarderErrorUnableGettingBalance();
    error VenuePaymasterBalanceTooLow();
    error VenuePaymasterNotEnoughFunds();
    error SenderIsNotVenueOwner();

    function versionVenueSBT() external pure returns (string memory);

    /// @dev only VenueRegistar owner can call this function
    function setRoyaltyInfo(address royaltyReceiver, uint96 royaltyFeeNumerator) external;
    function setRoyaltyInfoSecondarySales(address royaltyReceiver, uint96 royaltyFeeNumerator) external;

    function mint(
        uint256 typeOf,
        string memory name,
        string memory symbol,
        string memory baseUri,
        address paymentToken,
        bytes memory extraData
    ) external payable;

    /// @dev only can burn if totalSupply of ERC721 where tokenId points to is 0
    function burn(uint256 tokenId) external;

    function setBaseURI(string memory baseUri) external;

    function isEvent(address _event) external returns(bool);

    function getEvents() external view returns (address[] memory);

    function getVenueRegistar() external view returns(address);

    function withdrawToken(address token) external;

    function withdrawETH() external;

    function setRoyaltyReceiverSecondarySales(address royaltyReceiverSecondarySales) external;

    function withdrawFromPaymaster(uint256 amount) external;

    function isVenueManager(address addr) external view returns(bool);

    function venueOwner() external view returns(address);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../ERC721A.sol';

import '../interfaces/IERC721E.sol';
import '../ERC721AMarketplace.sol';
import "../OwnedByReserv.sol";
import "../interfaces/IVenueSBT.sol";

contract ERC721E is IERC721E, ERC721AMarketplace, OwnedByReserv {

    address public venue;
    address public manager;

    string internal _baseUri;

    uint256 public eventDate; //epoch

    mapping(uint256 => EntryType) private _entryByPos;

    //in the form of userId => (entryPos => amountOfTickets)
    mapping(uint256 => mapping(uint256 => uint256)) private _userTicketsBought;

    modifier onlyManagers() {
        if (!IVenueSBT(venue).isVenueManager(_msgSender())) revert SenderIsNotAuthorized();
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address venue_,
        address reservOwnerContract,
        bytes memory data
    ) ERC721A(name, symbol) OwnedByReserv(reservOwnerContract) {
        venue = venue_;
        (
            string memory baseUri,
            address paymentToken_,
            address royaltyReceiver,
            address secondarySalesRoyaltyReceiver,
            uint96 royaltyFeeNumerator,
            uint96 secondarySalesRoyaltyFeeDenominator,
            bytes memory extraData
        ) = abi.decode(data, (string, address, address, address, uint96, uint96, bytes));

        _baseUri = baseUri;
        paymentToken = paymentToken_;
        
        _secondarySalesRoyaltyReceiver = secondarySalesRoyaltyReceiver;
        _secondarySalesRoyaltyFeeDenominator = secondarySalesRoyaltyFeeDenominator;
        _setDefaultRoyalty(royaltyReceiver, royaltyFeeNumerator);

        eventDate = abi.decode(extraData, (uint256));
        if (eventDate <= block.timestamp) revert ERC721WrongEventDate();
    }

    /// @inheritdoc IERC721Wide
    function versionERC721() external pure virtual override returns (string memory) {
        return '1.0.0-beta.0+fob.rsv.iERC721E';
    }

    /// @inheritdoc IERC721Wide
    function setBaseURI(string memory baseUri) external virtual override onlyManagers {
        _baseUri = baseUri;
    }

    /// @dev override base uri. It will be combined with token ID
    /// @inheritdoc ERC721A
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    /// @inheritdoc IERC721E
    function createEntry(
        string memory name,
        uint256 price,
        uint256 maxSupply,
        uint256 maxBuy,
        uint256 saleEnd
    ) external virtual override onlyManagers {
        // TODO: not for production
        // if (price == 0) revert ERC721EWrongPrice(); 
        if (saleEnd < block.timestamp) revert ERC721WrongSaleEnd();
        if (maxSupply == 0) revert ERC721WrongMaxSupply();
        entriesCount += 1;
        uint256 pos = entriesCount;
        _entryByPos[pos] = EntryType(name, price, maxSupply, maxBuy, 0, saleEnd);
        emit NewEntry(pos, name, price, maxSupply, saleEnd);
    }

    /// @inheritdoc IERC721Wide
    function setEventDate(uint256 _eventDate) external virtual override onlyManagers {
        if (_eventDate <= block.timestamp) revert ERC721WrongEventDate();
        eventDate = _eventDate;
    }

    /// @inheritdoc IERC721Wide
    function editEntryName(uint256 entryPos, string memory name) external virtual override onlyManagers {
        if (entryPos > entriesCount) revert ERC721WrongEntryPos();
        EntryType storage entry = _entryByPos[entryPos];
        entry.name = name;
    }

    /// @inheritdoc IERC721Wide
    function editEntryPrice(uint256 entryPos, uint256 price) external virtual override onlyManagers {
        if (entryPos > entriesCount) revert ERC721WrongEntryPos();
        // TODO: not for production
        // if (price == 0) revert ERC721EWrongPrice();
        EntryType storage entry = _entryByPos[entryPos];
        entry.price = price;
    }

    /// @inheritdoc IERC721Wide
    function editEntryMaxSupply(uint256 entryPos, uint256 maxSupply) external virtual override onlyManagers {
        if (entryPos > entriesCount) revert ERC721WrongEntryPos();
        EntryType storage entry = _entryByPos[entryPos];
        if (maxSupply < entry.sold) revert ERC721WrongMaxSupply();
        entry.maxSupply = maxSupply;
    }

    /// @inheritdoc IERC721Wide
    function editEntryMaxBuy(uint256 entryPos, uint256 maxBuy) external virtual override onlyManagers {
        if (entryPos > entriesCount) revert ERC721WrongEntryPos();
        EntryType storage entry = _entryByPos[entryPos];
        entry.maxBuy = maxBuy;
    }

    /// @inheritdoc IERC721Wide
    function editEntrySaleEnd(uint256 entryPos, uint256 saleEnd) external virtual override onlyManagers {
        if (entryPos > entriesCount) revert ERC721WrongEntryPos();
        if (saleEnd < block.timestamp) revert ERC721WrongSaleEnd();
        EntryType storage entry = _entryByPos[entryPos];
        entry.saleEnd = saleEnd;
    }

    /// @inheritdoc IERC721E
    function buyTickets(
        address receiver,
        uint256 userId,
        uint256 entryPos,
        uint256 amount
    ) external virtual override {
        EntryType memory entryType = _entryByPos[entryPos];

        if (entryType.saleEnd < block.timestamp) revert ERC721SaleEnded();

        uint256 soldTickets = entryType.sold;
        uint256 maxSupply = entryType.maxSupply;
        if (soldTickets + amount > maxSupply) revert ERC721ReachedMaxSupply();

        uint256 maxBuy = entryType.maxBuy;
        if (_userTicketsBought[userId][entryPos] + amount > maxBuy) revert ERC721TooManyTickets();

        uint256 price = entryType.price;

        entryType.sold += amount;
        _entryByPos[entryPos] = entryType;

        _saveTickets(_currentIndex, amount, entryPos);
        _userTicketsBought[userId][entryPos] += amount;

        // Implement royalties
        if (price > 0 && !isReservCardPayee(_msgSender())) { 
            uint256 totalPrice = amount * price;
            (address receiverRoyalty, uint256 amountRoyalty) = _getDefaultRoyaltyBatch(totalPrice);
            IERC20(paymentToken).transferFrom(_msgSender(), venue, totalPrice - amountRoyalty);
            IERC20(paymentToken).transferFrom(_msgSender(), receiverRoyalty, amountRoyalty);
        }

        _safeMint(receiver, amount);
        emit MintTickets(receiver, userId, entryPos, amount);
    }

    /// @inheritdoc IERC721E
    function getTicketInfo(uint256 tokenId) external view virtual override returns (EntryType memory) {
        if (!_exists(tokenId)) revert ERC721NonExistentToken();
        uint256 entryPos = _entryByTokenId[tokenId];
        return _entryByPos[entryPos];
    } 

    function getUserTicketsBought(uint256 userId) external view virtual returns (uint256[] memory) {
        uint256[] memory tickets = new uint256[](entriesCount);
        for(uint256 i = 0; i < entriesCount; i++) {
            tickets[i] = _userTicketsBought[userId][i + 1];
        }
        return tickets;
    }

    /// @inheritdoc IERC721E
    function getEntry(uint256 pos) external view virtual override returns (EntryType memory) {
        return _entryByPos[pos];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AMarketplace)
        returns (bool)
    {
        return
            interfaceId == type(IERC721E).interfaceId ||
            interfaceId == type(IERC721Wide).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./interfaces/IReservOwner.sol";
import "./OwnedByReservAbstract.sol";

contract OwnedByReserv is OwnedByReservAbstract {
    constructor(address ownerContract_) {
        ownerContract = ownerContract_;
    }    
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./interfaces/IReservOwner.sol";

contract OwnedByReservAbstract  {
    error SenderIsNotReserv();
    error SenderIsNotReservSuperOwner();
    error SenderIsNotAuthorized();

    address public ownerContract;

    modifier onlyReservSuperOwner(){
        if(!IReservOwner(ownerContract).isSuperOwner(msg.sender)) revert SenderIsNotReservSuperOwner();
        _;
    }

    modifier onlyReserv() {
        if(!isReserv(msg.sender)) revert SenderIsNotReserv();
        _;
    }

    modifier onlyOwnerOrReserv() {
        if (!isOwnerOrReserv(msg.sender) ) revert SenderIsNotAuthorized();
        _;
    }


    function isOwnerOrReserv(address addr) public view returns (bool) {
        return addr == owner() || isReserv(addr) ;
    }

    function owner() public view returns(address) {
        return IReservOwner(ownerContract).representative();
    }
    
    function isReservSuperOwner(address addr) public view returns (bool) {
        return IReservOwner(ownerContract).isSuperOwner(addr);
    }

    function isReserv(address addr) public view returns (bool) {
        return IReservOwner(ownerContract).isManager(addr) || isReservSuperOwner(addr);
    }

    function isReservCardPayee(address addr) public view returns (bool) {
        return IReservOwner(ownerContract).isCardPayee(addr);
    }

    function reservTreasury() public view returns (address) {
        return IReservOwner(ownerContract).treasury();
    }

    function reservOwnerContract() public view returns (address) {
        return ownerContract;
    }

}