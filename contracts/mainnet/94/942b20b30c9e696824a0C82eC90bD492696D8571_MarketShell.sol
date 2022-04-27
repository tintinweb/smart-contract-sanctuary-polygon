/**
 *Submitted for verification at polygonscan.com on 2022-04-27
*/

// SPDX-License-Identifier: MIT

// File: interfaces/IMarketAdmin.sol


pragma solidity ^0.8.11;

interface IMarketAdmin {
    function canBuyAmount(address _user, address _tokenAddress, uint256 _tokenId, uint256 _amount) view external returns(bool);
    function increaseUserPurchasedAmount(address _user, address _tokenAddress, uint256 _tokenId, uint256 _amount) external;
    
    function checkWhitelist(address _user) view external returns(bool);
    function checkBlacklist(address _user) view external returns(bool);
}
// File: interfaces/IMarket.sol


pragma solidity ^0.8.3;

interface IMarket {
    function buy_ar(uint256 itemId, address buyer) external payable;
}

// File: utils/Strings.sol


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

// File: utils/Context.sol


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

// File: access/IAccessControl.sol


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

// File: access/IAccessControlEnumerable.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;


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

// File: ERC2981/SplitPayment.sol


pragma solidity ^0.8.11;

abstract contract SplitPayment {
    mapping(uint256 => address payable[]) internal _tokenRoyaltyReceivers;
    mapping(uint256 => uint16[]) internal _tokenRoyaltyBPS;

    event RoyaltiesUpdated(uint256 indexed tokenId, address payable[] receivers, uint16[] basisPoints);

    constructor() {}

    function _setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint16[] calldata basisPoints) internal {
        require(receivers.length == basisPoints.length, "Invalid input");
        uint256 totalBasisPoints;
        for (uint i = 0; i < basisPoints.length; i++) {
            totalBasisPoints += basisPoints[i];
        }
        require(totalBasisPoints == 10_000, "Invalid total royalties");
        _tokenRoyaltyReceivers[tokenId] = receivers;
        _tokenRoyaltyBPS[tokenId] = basisPoints;
        emit RoyaltiesUpdated(tokenId, receivers, basisPoints);
    }

    function getRoyalties(uint256 tokenId) view public returns (address payable[] memory, uint16[] memory) {
        return (_tokenRoyaltyReceivers[tokenId], _tokenRoyaltyBPS[tokenId]);
    }

    function share(uint256 amount, uint16 fee) public pure returns(uint256) 
    {
        return amount * uint256(fee) / 10_000;
    }
}
// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: PaymentAccount/IPaymentAccount.sol


pragma solidity ^0.8.7;

interface IPaymentAccount {
    function getPlatformRecipient()
    view
    external
    returns(address payable);

    function getPrimaryPlatformFee()
    view
    external
    returns(uint16);

    function getSecondaryPlatformFee()
    view
    external
    returns(uint16);

    function getCreatorFee()
    view
    external
    returns(uint16);
}
// File: interfaces/IERC20.sol




pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// File: interfaces/IERC165.sol


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

// File: access/AccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;





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
abstract contract AccessControl is Context, IAccessControl, IERC165 {
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
        return interfaceId == type(IAccessControl).interfaceId;
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

// File: interfaces/IMarketItemCollection.sol


pragma solidity ^0.8.3;


struct ItemInfo {
    uint256 itemId;
    address tokenAddress;
    uint256 tokenId;
    address erc20Address;
    uint256 price;
    address owner;
    uint256 amount;
    uint256 reserved;
}

interface IMarketItemCollection is IERC165 {
    function addItem(address _itemOwner, address _tokenAddress, uint256 _tokenId, address _erc20Address, uint256 _price, uint256 amount) external returns (uint256);
    function removeItem(uint256 _itemId) external;
    function removeItem(uint256 _itemId, address _sender) external;
    function getItemIdByTokenId(address tokenAddress, uint256 tokenId) view external returns (uint256);
    function getItem(uint256 itemId) view external returns (ItemInfo memory);
    function getAllItemsId(address user) external view returns (uint256[] memory);
    function itemBy(uint256 itemId) view external returns (ItemInfo memory, uint256);
    function changePrice(uint256 itemId, address itemOwner, uint256 _newPrice) external;
    function changeItemAmount(uint256 itemId, uint256 amount) external;
}
// File: interfaces/IWhitelist.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


interface IWhitelist is IERC165 {
    function whitelistCheck(address _address) view external returns(bool);
}
// File: interfaces/ISystemWideRoyalties.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


interface ISystemWideRoyalties is IERC165 {

    function sellerRoyaltyInfo(address seller, uint256 tokenId, uint256 value) view external returns (address receiver, uint256 royaltyAmount);

    function creatorRoyaltyInfo(address seller, uint256 tokenId, uint256 value) view external returns (address receiver, uint256 royaltyAmount);

    function platformRoyaltyInfo(address seller, uint256 tokenId, uint256 value) view external returns (address receiver, uint256 royaltyAmount);
}


// File: interfaces/IERC2981.sol


pragma solidity ^0.8.11;


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
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: ERC2981/SystemWideRoyalties_ERC1155.sol


pragma solidity ^0.8.11;





/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens

abstract contract SystemWideRoyalties_ERC1155 is ISystemWideRoyalties, IERC2981, SplitPayment {
    IPaymentAccount _platform;

    uint256 internal _royaltyFee = 1500;
    address internal _royaltyReceiver;
    bool internal _royaltyToCreator;

    constructor(address _address)
    {
        _updatePlatform(_address);
        _royaltyReceiver = _platform.getPlatformRecipient();
    }

    function _updatePlatform(address _address) internal {
        require(IERC165(_address).supportsInterface(type(IPaymentAccount).interfaceId), "Invalid IPaymentAccount address");
        _platform = IPaymentAccount(_address);
    }

    function getCreatorAddress(uint256 tokenId) internal view virtual returns (address);

    function getPrimaryPlatformFee() view private returns(uint16) {
        return _platform.getPrimaryPlatformFee();
    }

    function getSecondaryPlatformFee() view private returns(uint16) {
        return _platform.getSecondaryPlatformFee();
    }

    function getCreatorFee() view private returns(uint16) {
        return _platform.getCreatorFee();
    }

    function _getSellerShare(bool isPrimary) view private returns(uint16) {
        uint16 share;
        if (isPrimary) {
            share = 10_000 - getPrimaryPlatformFee();
        } else {
            share = 10_000 - getSecondaryPlatformFee() - getCreatorFee();
        }
        require(share >= 0 && share <= 10_000, "Invalid fee value");
        return share;
    }

    function sellerRoyaltyInfo(address seller, uint256 tokenId, uint256 value)
        view 
        external
        returns (address receiver, uint256 royaltyAmount) {
        bool _isPrimary = getCreatorAddress(tokenId) == seller;

        receiver = seller;
        uint16 sellerFee = _getSellerShare(_isPrimary);
        royaltyAmount = (value * uint256(sellerFee)) / 10_000;
    }

    function creatorRoyaltyInfo(address seller, uint256 tokenId, uint256 value) 
        view 
        external
        returns (address receiver, uint256 royaltyAmount) {
        receiver = getCreatorAddress(tokenId);
        // royalties from the first sale will be transferred to the platform 

        bool _isPrimary = receiver == seller;
        if (_isPrimary) {
            return (receiver, 0);
        }
        uint256 fee = getCreatorFee();
        royaltyAmount = (value * fee) / 10_000;
    }

    function platformRoyaltyInfo(address seller, uint256 tokenId, uint256 value)
        view 
        external
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _platform.getPlatformRecipient();
        bool _isPrimary = getCreatorAddress(tokenId) == seller;

        uint256 fee = uint256(_isPrimary ?
                          getPrimaryPlatformFee() :
                         getSecondaryPlatformFee());
        royaltyAmount = (value * fee) / 10_000;
    }

    /// @dev IERC2981
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 fee;
        if (_royaltyToCreator) {
            receiver = getCreatorAddress(tokenId); 
            fee = getCreatorFee();
        } else {
            receiver = _royaltyReceiver;
            fee = _royaltyFee;
        }
        royaltyAmount = (value * fee) / 10_000;
    }

    /// @dev IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(ISystemWideRoyalties).interfaceId;
    }
}
// File: interfaces/IMarketAdvance.sol


pragma solidity ^0.8.11;


interface IMarketAdvance {
    function getAdvance(address user) external view returns(uint256);
    function setAdvance(address user, uint256 value) external;
}
// File: interfaces/IMYS_ERC1155.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


interface IMYS_ERC1155 is IERC165 {
    function mint(
        address to,
        string memory uri,
        uint256 amount,
        address payable[] calldata receivers,
        uint16[] calldata basisPoints,
        uint256 releaseDate,
        bytes memory data
    ) external returns(uint256);

    function mintBatch(
        address to,
        string[] memory uris,
        uint256[] memory amounts,
        address payable[] calldata receivers,
        uint16[] calldata basisPoints,
        uint256 releaseDate,
        bytes memory data
    ) external returns (uint256[] memory);

    function isTokenReleased(uint256 _tokenId) view external returns(bool);
}
// File: interfaces/IERC721.sol



pragma solidity ^0.8.0;


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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}
// File: interfaces/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: libraries/EnumerableSet.sol


pragma solidity ^0.8.3;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}
// File: access/AccessControlEnumerable.sol


// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;




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

// File: Market/MarketShell.sol


pragma solidity ^0.8.3;
















interface IMarketOffer {
    function buy(uint256 itemId, address _buyer) external;
}

contract MarketShell is AccessControlEnumerable, IMarket {
    event SoldItem(uint256 indexed itemId, address indexed tokenAddress, address buyer, uint256 tokenId, uint256 price, uint256 count);
    event AddItemToCollection(uint256 indexed itemId, address indexed tokenAddress, address owner, uint256 tokenId, uint256 price);
    event RemoveItemFromCollection(uint256 indexed itemId, address sender);
    event MintedToken(uint256 indexed tokenId, address tokenAddress, address indexed owner);
    event MintingAvailable(bool available, address sender);
    event PriceChanged(uint256 indexed itemId, uint256 _newPrice, address sender);

    IPaymentAccount private _paymentAccount;
    IMYS_ERC1155 private _mys_nft;
    IMarketAdvance private _marketAdvance;
    IWhitelist private _whitelistCollectors;
    IMarketItemCollection private _itemCollection;
    IMarketAdmin private _marketAdmin;

    bool private _canMint = true;

    string public constant VERSION = "1";

     constructor(address _paymentAccount_address, address _mys_address, address _advance_address, address _whitelist_address, address _itemCollection_address, address _marketAdmin_address) {
         _paymentAccount = IPaymentAccount(_paymentAccount_address);
         _mys_nft = IMYS_ERC1155(_mys_address);
         _marketAdvance = IMarketAdvance(_advance_address);
         _whitelistCollectors = IWhitelist(_whitelist_address);
         _itemCollection = IMarketItemCollection(_itemCollection_address);
         _marketAdmin = IMarketAdmin(_marketAdmin_address);

         _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function updateAddresses(address paymentAccount, address mys_nft, address marketAdvance, address whitelist, address itemCollection, address marketAdmin) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (paymentAccount != address(0)) {
            _paymentAccount = IPaymentAccount(_paymentAccount);
        }

        if (mys_nft != address(0)) {
            _mys_nft = IMYS_ERC1155(mys_nft);
        }

        if (marketAdvance != address(0)) {
            _marketAdvance = IMarketAdvance(marketAdvance);
        }

        if (whitelist != address(0)) {
            _whitelistCollectors = IWhitelist(whitelist);
        }

        if (itemCollection != address(0)) {
            _itemCollection = IMarketItemCollection(itemCollection);
        }

        if (marketAdmin != address(0)) {
            _marketAdmin = IMarketAdmin(marketAdmin);
        }
    }

    function canMint(bool _mint) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _canMint = _mint;
        emit MintingAvailable(_mint, _msgSender());
    }

    function mint(string calldata _uri, uint256 _amount, address payable[] calldata receivers, uint16[] calldata basisPoints, uint256 releaseDate) public {
        require(_canMint, "Minting not available");
        uint256 tokenId = _mys_nft.mint(msg.sender, _uri, _amount, receivers, basisPoints, releaseDate, "0x00");
        emit MintedToken(tokenId, address(_mys_nft), msg.sender);
    }

    function changePrice(uint256 itemId, uint256 _newPrice) public {
         if (hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            (ItemInfo memory item, ) = _itemBy(itemId);
            _itemCollection.changePrice(itemId, item.owner, _newPrice); 
         } else {
            _itemCollection.changePrice(itemId, msg.sender, _newPrice);
         }

        emit PriceChanged(itemId, _newPrice, msg.sender);
    }

    function changeItemAmount(uint256 itemId, uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _itemCollection.changeItemAmount(itemId, _amount);
    }

    function addToken(address _tokenAddress, uint256 _tokenId, uint256 _price, address erc20, uint256 amount) public returns (uint256) {
        require(amount > 0, "Amount value must be > 0");
        if (IERC165(_tokenAddress).supportsInterface(type(IERC1155).interfaceId)) {
            return _add_erc_1155(_tokenAddress, _tokenId, _price, erc20, msg.sender, amount);

        } else if (IERC165(_tokenAddress).supportsInterface(type(IERC721).interfaceId)) {
            require(amount == 1, "ERC721: amount must be = 1");
            return _add_erc_721(_tokenAddress, _tokenId, _price, erc20, msg.sender);
        }
        revert("Market: Invalid NFT address");
    }

    function removeItem(uint256 itemId) public {
        _itemCollection.removeItem(itemId, msg.sender);
    }

    function buyERC20(uint256 itemId) public {
        (ItemInfo memory item, ) = _itemBy(itemId);
        require (IERC20(item.erc20Address).allowance(_msgSender(), address(this)) >= item.price, "Market: allowance too low");
        userPurchaseAbilityCheck(_msgSender(), item, 1);
        _buy(item, _msgSender(), 1, item.price);
    }

    function buy(uint256 itemId) public payable {
        (ItemInfo memory item, ) = _itemBy(itemId);
        require(item.erc20Address == address(0), "Market: Invalid currency");
        require(msg.value == item.price, "Market: Insufficient funds");
        userPurchaseAbilityCheck(_msgSender(), item, 1);
        _buy(item, _msgSender(), 1, msg.value);
    }

    function userPurchaseAbilityCheck(address user, ItemInfo memory item, uint256 count) private {
        require(!_marketAdmin.checkBlacklist(user), "MarketAdmin: Blacklisted user");

        if (!_marketAdmin.checkWhitelist(user)) {
            require(_marketAdmin.canBuyAmount(user, item.tokenAddress, item.tokenId, count), "MarketAdmin: max number of tokens has been reached");
        }
        _marketAdmin.increaseUserPurchasedAmount(user, item.tokenAddress, item.tokenId, count);
    }

    function buyTokens(uint256 itemId, uint256 amount) public payable {
        (ItemInfo memory item, ) = _itemBy(itemId);
        require(item.erc20Address == address(0), "Market: Invalid currency");
        require(amount > 0 && amount <= item.amount, "Incorrect amount value");
        require(msg.value == item.price * amount, "Insufficient funds");
        userPurchaseAbilityCheck(_msgSender(), item, amount);
        _buy(item, msg.sender, amount, msg.value);
    }

    function buy_ar(uint256 itemId, address buyer) external payable onlyRole(DEFAULT_ADMIN_ROLE) {
        (ItemInfo memory item, ) = _itemBy(itemId);
         userPurchaseAbilityCheck(buyer, item, 1);
        _buy(item, buyer, 1, msg.value);
    }

    function _buy(ItemInfo memory item, address _sender, uint256 _tokenCount, uint256 _amount) private {
        // (ItemInfo memory item, ) = _itemBy(_itemId);
        require(item.amount >= _tokenCount, "Not enough tokens");

        if (IERC165(item.tokenAddress).supportsInterface(type(IMYS_ERC1155).interfaceId)) {
            _buy_MYS_ERC_1155(item, IERC1155(item.tokenAddress), _amount, _tokenCount, _sender);
        } else if (IERC165(item.tokenAddress).supportsInterface(type(IERC1155).interfaceId)) {
            _buy_ERC1155(item, IERC1155(item.tokenAddress), _amount, _tokenCount, _sender);
        } else if (IERC165(item.tokenAddress).supportsInterface(type(IERC721).interfaceId)) {
            require(item.price <= _amount, "Too low price");
            _buy_ERC721(item, IERC721(item.tokenAddress), _amount, _sender);
        } else {
            revert("Unsupported token");
        }
    }

    function calculateAndUpdateAdvance(address user, uint256 amount) private returns (uint256 toPlatform, uint256 toUser) {
        uint256 advance = _marketAdvance.getAdvance(user);
        if (advance == 0) {
            return (0, amount);
        }

        if (advance < amount) {
            uint256 maticToUser = amount - advance;
            _marketAdvance.setAdvance(user, 0);
            return (advance, maticToUser);
        }
        _marketAdvance.setAdvance(user, advance - amount);
        return (amount, 0);
    }

    function _buy_ERC721(ItemInfo memory item, IERC721 nft, uint256 _amount, address _buyer) private {
        address payable platformAddress =  _paymentAccount.getPlatformRecipient();
        uint256 platformFee = _amount * uint256(_paymentAccount.getPrimaryPlatformFee()) / 10_000;
        uint256 amountWithoutFee = _amount - platformFee;

        (uint256 toPlatform, uint256 toUser) = calculateAndUpdateAdvance(_buyer, amountWithoutFee);
        // (bool platformSent, ) = platformAddress.call {value: toPlatform + platformFee}("");
        // require(platformSent, "Platform: Failed to send Ether");
        payment(item, _buyer, platformAddress, toPlatform + platformFee, "Market: Platform - failed to send ETH");

        if (toUser > 0) {
            // (bool ownerSent, ) = payable(nft.ownerOf(item.tokenId)).call {value: toUser}("");
            // require(ownerSent, "Owner: Failed to send Ether");
            payment(item, _buyer, payable(nft.ownerOf(item.tokenId)), toUser, "Market: Seller - failed to send ETH");
        }
      
         nft.transferFrom(item.owner, _buyer, item.tokenId);
        _removeItem(item.itemId, item.owner);

        emit SoldItem(item.itemId, item.tokenAddress, _buyer, item.tokenId, _amount, 1);
    }

    function _buy_ERC1155(ItemInfo memory item, IERC1155 nft, uint256 _amount, uint256 _tokenCount, address _buyer) private {
        address payable platformAddress =  _paymentAccount.getPlatformRecipient();
        uint256 platformFee = _amount * uint256(_paymentAccount.getPrimaryPlatformFee()) / 10_000;
        uint256 amountWithoutFee = _amount - platformFee;

        (uint256 toPlatform, uint256 toUser) = calculateAndUpdateAdvance(_buyer, amountWithoutFee);
        // (bool platformSent, ) = platformAddress.call {value: toPlatform + platformFee}("");
        // require(platformSent, "Platform: Failed to send Ether");
        payment(item, _buyer, platformAddress, toPlatform + platformFee, "Market: Platform - failed to send ETH");
      
        if (toUser > 0) {
            // (bool ownerSent, ) = payable(item.owner).call {value: toUser}("");
            // require(ownerSent, "Owner: Failed to send Ether");
            payment(item, _buyer, payable(item.owner), toUser, "Market: Seller - failed to send ETH");
        }
     
        uint256 balance = nft.balanceOf(item.owner, item.tokenId);
        require(balance >= _tokenCount, "ERC1155: insufficient funds");
        _itemCollection.changeItemAmount(item.itemId, item.amount - _tokenCount);

        nft.safeTransferFrom(item.owner, _buyer, item.tokenId, _tokenCount, "0x00");
        emit SoldItem(item.itemId, item.tokenAddress, _buyer, item.tokenId, _amount, _tokenCount);
    }
    
    function _buy_MYS_ERC_1155(ItemInfo memory item, IERC1155 nft, uint256 _amount, uint256 _tokenCount, address _buyer) private {
        if (!IMYS_ERC1155(item.tokenAddress).isTokenReleased(item.tokenId)) {
            require(_whitelistCollectors.whitelistCheck(_buyer), "The buyer is not a whitelist collector");
        }
        
        (, uint256 platformRoyaltyAmount) = SystemWideRoyalties_ERC1155(item.tokenAddress).platformRoyaltyInfo(item.owner, item.tokenId, _amount);
        uint256 amountWithoutFee = _amount - platformRoyaltyAmount;

        (uint256 toPlatform, uint256 toUser) = calculateAndUpdateAdvance(item.owner, amountWithoutFee);    

        // (bool platformSent, ) = _paymentAccount.getPlatformRecipient().call {value: toPlatform + platformRoyaltyAmount}("");
        // require(platformSent, "Platform: Failed to send Ether");
        payment(item, _buyer, _paymentAccount.getPlatformRecipient(), toPlatform + platformRoyaltyAmount, "Market: Platform - failed to send ETH");

        if (toUser > 0) {
            _mysteriousPaymentShareOut(item, SystemWideRoyalties_ERC1155(item.tokenAddress), toUser, _buyer);
        }
        
        uint256 balance = nft.balanceOf(item.owner, item.tokenId);
        require(balance >= _tokenCount, "insufficient funds");

        nft.safeTransferFrom(item.owner, _buyer, item.tokenId, _tokenCount, "0x00");
        _itemCollection.changeItemAmount(item.itemId, item.amount - _tokenCount);
    
        emit SoldItem(item.itemId, item.tokenAddress, _buyer, item.tokenId, _amount, _tokenCount);
    }

    function payment(ItemInfo memory item, address from, address payable to, uint256 value, string memory message) private {
        if (item.erc20Address == address(0)) {
            (bool sent, ) = to.call{value: value}("");
             require(sent, message);
        } else {
            require(IERC20(item.erc20Address).transferFrom(from, to, value), message);
        }
    }

    function _mysteriousPaymentShareOut(ItemInfo memory item, SystemWideRoyalties_ERC1155 nft, uint256 amount, address _buyer) private 
    {
        (address sellerReceiver, ) = nft.sellerRoyaltyInfo(item.owner, item.tokenId, amount);
        (address creatorReceiver, uint256 creatorRoyaltyAmount) = nft.creatorRoyaltyInfo(item.owner, item.tokenId, amount);

        if (sellerReceiver == creatorReceiver) {
            _paymentShareOutBetweenMembers(item, nft, amount, _buyer);
        } else {
            if (creatorRoyaltyAmount > 0) {
                _paymentShareOutBetweenMembers(item, nft, creatorRoyaltyAmount, _buyer);
            }
            uint256 sellerRoyalty = amount - creatorRoyaltyAmount;
            if (sellerRoyalty > 0) {
                // (bool sellerSent, ) = payable(sellerReceiver).call {value: sellerRoyalty}("");
                // require(sellerSent, "Seller: Failed to send Ether");
                payment(item, _buyer, payable(sellerReceiver), sellerRoyalty, "Market: Seller - failed to send ETH");
            }
        }
    }

    function _paymentShareOutBetweenMembers(ItemInfo memory item, SystemWideRoyalties_ERC1155 nft, uint256 amount, address _buyer) private 
    {
        (address payable[] memory receivers, uint16[] memory bps) = nft.getRoyalties(item.tokenId);
        for (uint16 i; i < receivers.length; i++) {
            uint256 shareAmount = nft.share(amount, bps[i]);
            if (shareAmount > 0) {

                payment(item, _buyer, receivers[i], shareAmount, "Market: MemberShare - failed to send ETH");
                // (bool memberShareSent, ) = receivers[i].call {value: shareAmount}("");
                // require(memberShareSent, "MemberShare: Failed to send Ether");
            }
        }
    }

    function getItemIdByTokenId(address tokenAddress, uint256 tokenId) view public returns (uint256) {
        return _itemCollection.getItemIdByTokenId(tokenAddress, tokenId);
    }

    function getItem(uint256 itemId) view public returns (ItemInfo memory) {
        (ItemInfo memory item, ) = _itemBy(itemId);
        return item;
    }

    function getAllItemsId(address user) public view returns (uint256[] memory) {
        return _itemCollection.getAllItemsId(user);
    }

    function _itemBy(uint256 itemId) private view returns (ItemInfo memory, uint256) {
        return _itemCollection.itemBy(itemId);
    }

    function _removeItem(uint256 _itemId, address _sender) private {
       _itemCollection.removeItem(_itemId, _sender);
        emit RemoveItemFromCollection(_itemId, _sender);        
    }

     function _add_erc_1155(address _tokenAddress, uint256 _tokenId, uint256 _price, address erc20, address sender, uint256 amount) private returns (uint256) {
        IERC1155 nft = IERC1155(_tokenAddress);

        require(nft.isApprovedForAll(sender, address(this)), "ERC1155: isApprovedForAll error");
        require(nft.balanceOf(sender, _tokenId) >= amount, "ERC1155: Insufficient funds");

        return _addItem(sender, _tokenAddress, _tokenId, _price, erc20, amount);
    }

    function _add_erc_721(address _tokenAddress, uint256 _tokenId, uint256 _price, address erc20, address sender) private returns (uint256) {
        IERC721 nft = IERC721(_tokenAddress);
        require(nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "ERC721: not owner nor approved");
        return _addItem(sender, _tokenAddress, _tokenId, _price, erc20, 1);
    }

    function _addItem(address sender, address _tokenAddress, uint256 _tokenId, uint256 _price, address erc20, uint256 amount) private returns (uint256) {
        uint256 itemId = _itemCollection.addItem(sender, _tokenAddress, _tokenId, erc20, _price, amount);
        emit AddItemToCollection(itemId, _tokenAddress, sender, _tokenId, _price);
        return itemId;
    }

    function addAdmin(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setupRole(DEFAULT_ADMIN_ROLE, account);
    }

    function removeAdmin(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        uint256 balance = getBalance();
        require(balance > 0, "No matic left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function getBalance() view public onlyRole(DEFAULT_ADMIN_ROLE) returns(uint256) {
        return address(this).balance;
    }
}