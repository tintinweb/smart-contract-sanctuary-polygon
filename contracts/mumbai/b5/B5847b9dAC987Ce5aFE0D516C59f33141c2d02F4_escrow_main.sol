// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _roles[role].members[account];
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
    function getRoleAdmin(bytes32 role)
        public
        view
        virtual
        override
        returns (bytes32)
    {
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
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract escrow_main is Ownable, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;

    IERC20 public USDT;
    IERC20 public USDC;
    IERC20 public DAI;
    IERC20[] public tokens;

    uint256 public _gigCounter = 0;

    uint256 public platformFee;
    address public platformFeeAccount;

    struct gig {
        address seller;
        address buyer;
        bool approvedBySeller;
        bool approvedByBuyer;
        bool gigActive;
        uint256 numberOfMilestones;
        string milestonesDetail;
        uint256 gigCreationTime;
        uint256 gigDeadlineTime;
        string title;
        string category;
        string description;
        IERC20 currency;
    }

    struct dispute {
        address disputedBy;
        string role;
        uint256 time;
    }

    mapping(uint256 => gig) public gigMap;

    mapping(address => uint256[]) public userMap;
    mapping (uint => bool ) public isCompletedGig; 

    mapping(uint256 => uint256[]) public pricePerMilestone;
    mapping(uint256 => mapping(uint256 => bool)) public milestoneApprovedByBuyer; // gig id => milestone id => (true/false)
    mapping(uint256 => bool) public disputed;
    mapping(uint256 => dispute) public disputeDetails;

    mapping ( uint => uint) public mileStoneApprovedLatest;

    event GigCreatedBySeller(uint256 gigIndex, address indexed seller,address indexed buyer,uint256 creationTime);
    event GigCreatedByBuyer(uint256 gigIndex,address indexed seller,address indexed buyer, uint256 creationTime);
    event GigApprovedBySeller(uint amount, gig gigData,uint256 gigIndex,address indexed approvedBySeller);
    event GigApprovedByBuyer(uint amount, gig gigData, uint256 gigIndex, address indexed approvedByBuyer);
    event GigStatusChanged(uint256 gigIndex, bool activeStatus);
    event MilestoneApproved(uint256 gigIndex,address indexed approvedBy,uint256 milestone);

    event disputeCreated(bool isDisputed, uint disputeTime,uint gigId );
    event Status( uint gigIndex, string status );


    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);

        platformFee = 10; // 1%
        platformFeeAccount = msg.sender;
    }

    function setValues(
        IERC20 _USDT,
        IERC20 _USDC,
        IERC20 _DAI
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        USDT = _USDT;
        USDC = _USDC;
        DAI = _DAI;
        tokens = [
            _USDT,
            _USDC,
            _DAI,
            IERC20(address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE))
        ];
    }

    function set_platformFeePercentage(uint256 _platformFee)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        platformFee = _platformFee;
    }

    function set_platformFeeAccount(address _platformFeeAccount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        platformFeeAccount = _platformFeeAccount;
        _setupRole(DEFAULT_ADMIN_ROLE, _platformFeeAccount);
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }

    /*
        --------- FLOW : Seller MAKING A GIG ---------
    */

    function seller_makeGig(
        uint256 _choose,
        string memory _title,
        string memory _category,
        string memory _description,
        address _buyer,
        string memory _milestones,
        uint256[] memory _pricePerMilestone,
        uint256 deadLineTimeInSeconds) public returns (uint256) {
        _gigCounter++;
        gigMap[_gigCounter] = gig(
            msg.sender,
            _buyer,
            true,
            false,
            true,
            _pricePerMilestone.length,
            _milestones,
            block.timestamp,
            deadLineTimeInSeconds,
            _title,
            _category,
            _description,
            tokens[_choose]
        );
        pricePerMilestone[_gigCounter] = _pricePerMilestone;

        userMap[msg.sender].push(_gigCounter);

        emit GigCreatedBySeller(
            _gigCounter,
            msg.sender,
            _buyer,
            block.timestamp
        );

        uint256 toReturn = _gigCounter;
        return toReturn;
    }

    function seller_flipGigStatus(uint256 _id) public {
        require(gigMap[_id].seller == msg.sender, "Not a seller of this Gig");
        require(
            gigMap[_id].approvedByBuyer == false,
            "Cannot change Status. Buyer accepted Gig"
        );

        gigMap[_id].gigActive = !gigMap[_id].gigActive;

        emit GigStatusChanged(_id, gigMap[_id].gigActive);
    }

    function buyer_approveGig(uint256 _id) public payable nonReentrant {
        require(gigMap[_id].buyer == msg.sender, "Not a buyer of this Gig");
        require(gigMap[_id].gigActive == true, "Gig is cancelled by seller");
        require(
            gigMap[_id].approvedByBuyer == false,
            "Already Approved by buyer"
        );
        require(
            gigMap[_id].approvedBySeller == true,
            "Gig not Approved by Seller"
        );

        uint256 totalFee = 0;
        for (uint256 i = 0; i < gigMap[_id].numberOfMilestones; i++) {
            totalFee = totalFee.add((pricePerMilestone[_id][i]));
        }
        uint256 _platformFee = totalFee.mul(platformFee).div(1000);

        if (gigMap[_id].currency == tokens[tokens.length - 1]) {
            // in the case when payment in ETH
            require(msg.value >= totalFee, "Send Correct Value");
            payable(address(this)).transfer(totalFee.sub(_platformFee));
            payable(platformFeeAccount).transfer(_platformFee);
        } else {
            require(
                gigMap[_id].currency.allowance(msg.sender, address(this)) >=
                    totalFee,
                "Allowance not given"
            );
            gigMap[_id].currency.transferFrom(
                msg.sender,
                address(this),
                totalFee.sub(_platformFee)
            );
            gigMap[_id].currency.transferFrom(
                msg.sender,
                platformFeeAccount,
                _platformFee
            );
        }
       uint[] memory amounts =  pricePerMilestone[_id];
        uint amount;
       for (uint i; i<amounts.length; i++){
        amount+=amounts [i];
       }
        gigMap[_id].approvedByBuyer = true;
        gigMap[_id].gigDeadlineTime = block.timestamp +gigMap[_id].gigDeadlineTime;
        emit GigApprovedByBuyer(amount, gigMap[_id], _id, msg.sender);
        
        emit Status (_id,  "In Progress" ) ;
    }

    /*
    --------- FLOW : Buyer MAKING A GIG ---------
    */

    function buyer_makeGig(
        uint256 _choose,
        string memory _title,
        string memory _cateogry,
        string memory _description,
        address _seller,
        string memory _milestones,
        uint256[] memory _pricePerMilestone,
        uint256 deadLineTimeInSeconds
    ) public payable nonReentrant returns (uint256) {
        require(_choose < 4, "Choose correct Payment Method");
        _gigCounter++;

        gigMap[_gigCounter] = gig(
            _seller,
            msg.sender,
            false,
            true,
            true,
            _pricePerMilestone.length,
            _milestones,
            block.timestamp,
            deadLineTimeInSeconds,
            _title,
            _cateogry,
            _description,
            tokens[_choose]
        );

        pricePerMilestone[_gigCounter] = _pricePerMilestone;

        uint256 _id = _gigCounter;
        uint256 totalFee = 0;

        // if (gigMap[_id].feePaidByBuyer) {
        for (uint256 i = 0; i < gigMap[_id].numberOfMilestones; i++) {
            totalFee = totalFee.add((pricePerMilestone[_id][i]));
        }
        // uint256 _platformFee = totalFee.mul(platformFee).div(1000);
        if (_choose < 3) {
            require(
                gigMap[_id].currency.allowance(msg.sender, address(this)) >=
                    totalFee,
                "Allowance not given"
            );
            gigMap[_id].currency.transferFrom(
                msg.sender,
                address(this),
                totalFee
            ); // Taking money into Escrow
            // gigMap[_id].currency.transferFrom(msg.sender,platformFeeAccount, platformFee);
        } else {
            require(msg.value >= totalFee, "Send Correct Eth Value");
            payable(address(this)).transfer(totalFee);
            // payable(platformFeeAccount).transfer(platformFee);
        }

        userMap[msg.sender].push(_gigCounter);
        emit GigCreatedByBuyer(
            _gigCounter,
            _seller,
            msg.sender,
            block.timestamp
        );
        uint256 toReturn = _gigCounter;
        return toReturn;
    }

    function buyer_flipGigStatus(uint256 _id) public {
        require(gigMap[_id].buyer == msg.sender, "Not a buyer of this Gig");
        require(
            gigMap[_id].approvedBySeller == false,
            "Cannot change Status. Seller accepted Gig"
        );

        gigMap[_id].gigActive = !gigMap[_id].gigActive;

        emit GigStatusChanged(_id, gigMap[_id].gigActive);
    }

    function seller_approveGig(uint256 _id) public nonReentrant {
        require(gigMap[_id].seller == msg.sender, "Not a buyer of this Gig");
        require(gigMap[_id].gigActive == true, "Gig is cancelled by Buyer");
        require(
            gigMap[_id].approvedByBuyer == true,
            "Gig not Approved by Buyer"
        );
        require(
            gigMap[_id].approvedBySeller == false,
            "Already apporved by Seller"
        );

        gigMap[_id].approvedBySeller = true;

        gigMap[_id].gigDeadlineTime =
            block.timestamp +
            gigMap[_id].gigDeadlineTime;

        uint256 totalFee = 0;

        for (uint256 i = 0; i < gigMap[_id].numberOfMilestones; i++) {
            totalFee = totalFee.add((pricePerMilestone[_id][i]));

            // uint256 _platformFeeTemp = pricePerMilestone[_id][i]
            //     .mul(platformFee)
            //     .div(1000);
            // pricePerMilestone[_id][i] -= _platformFeeTemp;
        }

        uint256 _platformFee = totalFee.mul(platformFee).div(1000);
        if (gigMap[_id].currency == tokens[tokens.length - 1]) {
            payable(platformFeeAccount).transfer(_platformFee);
        } else {
            (gigMap[_id].currency).transfer(platformFeeAccount, _platformFee);
            // Taking platform Fee from escrow
        }
        uint[] memory amounts = pricePerMilestone[_id] ;
        uint amount;
        for (uint i; i<amounts.length; i++){
         amount+=amounts [i];
        }
        emit GigApprovedBySeller( amount, gigMap[_id], _id, msg.sender);
        emit Status ( _id, "In Progress" ) ;
    }

    /*
    --------- FLOW : Seller Delivers Milestone and Buyer approved Milestone ---------
    */

    function buyer_approveMilestone(uint256 _gigId, uint256 _milestoneId)
        public
        nonReentrant
        notDisputed(_milestoneId)
    {
        require(gigMap[_gigId].buyer == msg.sender, "Not a buyer of this Gig");
        require(
            milestoneApprovedByBuyer[_gigId][_milestoneId] == false,
            "Milstone already approved"
        );
        require(
            _milestoneId >= 0 &&
                _milestoneId < gigMap[_gigId].numberOfMilestones,
            "Undefined milstone id"
        );
        require(
            gigMap[_gigId].approvedByBuyer == true,
            "Gig not Approved by buyer"
        );
        require(
            gigMap[_gigId].approvedBySeller == true,
            "Gig not Approved by Seller"
        );

        milestoneApprovedByBuyer[_gigId][_milestoneId] = true;
        // giving milestone money to Seller

        uint fee = pricePerMilestone[_gigId][_milestoneId].mul(platformFee).div(1000);
        if (gigMap[_gigId].currency == tokens[tokens.length - 1]) {
            payable(gigMap[_gigId].seller).transfer(
                pricePerMilestone[_gigId][_milestoneId]-fee
            );
        } else {
            (gigMap[_gigId].currency).transfer(
                gigMap[_gigId].seller,
                pricePerMilestone[_gigId][_milestoneId]-fee
            );
        }
        emit MilestoneApproved(_gigId, msg.sender, _milestoneId);
        mileStoneApprovedLatest[_gigId]+=1;
        if(_milestoneId == gigMap[_gigId].numberOfMilestones-1 ){
            emit Status( _gigId, "Completed");
        }
    }

    function getPriceOfMilestonesOfGig(uint256 _id)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _price = pricePerMilestone[_id];
        return _price;
    }

    function cancelGigOfSeller(uint256 _id) public {
        require(gigMap[_id].seller == msg.sender, "Not a seller of this Gig");
        require(gigMap[_id].approvedByBuyer == false, "Gig Approved by Buyer");
        require(
            gigMap[_id].approvedBySeller == true,
            "Already apporved by Seller"
        );

        gigMap[_id] = gig(
            address(0),
            address(0),
            false,
            false,
            false,
            0,
            "",
            0,
            0,
            "",
            "",
            "DELETED",
            IERC20(address(0))
        );
    }

    function cancelGigOfBuyer(uint256 _id) public {
        require(gigMap[_id].buyer == msg.sender, "Not a buyer of this Gig");
        require(
            gigMap[_id].approvedByBuyer == true,
            "Already apporved by Buyer"
        );
        require(
            gigMap[_id].approvedBySeller == false,
            "Gig Not Approved by Buyer"
        );

        uint256 totalFee = 0;

        // if (gigMap[_id].feePaidByBuyer) {
            for (uint256 i = 0; i < gigMap[_id].numberOfMilestones; i++) {
                totalFee = totalFee.add(pricePerMilestone[_id][i]);
            }

            if (gigMap[_id].currency == tokens[tokens.length - 1]){
                payable(msg.sender).transfer(totalFee);
            }
            else{
                gigMap[_id].currency.transfer(msg.sender, totalFee); // Taking platform Fee from escrow
            }

            // uint256 _platformFee = totalFee.mul(platformFee).div(1000);
            // totalFee = totalFee.add(_platformFee);

        // } else {
            // for (uint256 i = 0; i < gigMap[_id].numberOfMilestones; i++) {
            //     totalFee = totalFee.add(pricePerMilestone[_id][i]);
            // }

            // (gigMap[_id].currency).transfer(msg.sender, totalFee); // Taking platform Fee from escrow
        // }

        gigMap[_id] = gig(
            address(0),
            address(0),
            false,
            false,
            false,
            0,
            "",
            0,
            0,
            "",
            "",
            "DELETED",
            IERC20(address(0))
        );
    }

    function raiseDispute(uint256 _id) public {
        require(disputed[_id] == false, "Already Dispute Raised");
        require( gigMap[_id].seller == msg.sender || gigMap[_id].buyer == msg.sender, "Unauthorized to cause a dispute");

        string memory disputor;

        if (msg.sender == gigMap[_id].buyer) {
            disputor = "buyer";
        } else if (msg.sender == gigMap[_id].seller) {
            disputor = "seller";
        }

        disputeDetails[_id] = dispute(msg.sender, disputor, block.timestamp);

        disputed[_id] = true;

        emit disputeCreated(true , block.timestamp , _id );
        emit Status( _id, "Disputed");
    }

    function resolveDispute(
        uint256 _id,
        bool buyer,
        bool seller
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(disputed[_id] == true, "Gig Not in Dispute");

        require(
            !(buyer == true && seller == true),
            "Only send payTo one role either buyer or seller"
        );

        uint256 totalFee = 0;

        for (uint256 i = 0; i < gigMap[_id].numberOfMilestones; i++) {
            if (milestoneApprovedByBuyer[_id][i] == false) {
                totalFee = totalFee.add(pricePerMilestone[_id][i]);
            }
        }

        uint _fee = totalFee.mul(platformFee).div(1000);

        if (buyer) {
            // pay to buyer
            if (gigMap[_id].currency == tokens[tokens.length - 1]) {
                payable(gigMap[_id].buyer).transfer(totalFee - _fee);
            } else {
                gigMap[_id].currency.transfer(gigMap[_id].buyer, totalFee - _fee);
            }
            
        } else if (seller) {
            // pay to seller
            uint currentMileStone = mileStoneApprovedLatest[_id] ;

           uint toReturnAmount=  pricePerMilestone[_id][currentMileStone];

           uint fee= toReturnAmount.mul(platformFee).div(1000);

            if (gigMap[_id].currency == tokens[tokens.length - 1]) {
                payable(gigMap[_id].seller).transfer(toReturnAmount - fee);
            } else {
                gigMap[_id].currency.transfer(gigMap[_id].seller, toReturnAmount - fee);
            }

            disputeDetails[_id] = dispute(address(0), "", 0);
        }
        disputeDetails[_id] = dispute(address(0), "", 0);
        gigMap[_id] = gig(
        address(0),
        address(0),
        false,
        false,
        false,
        0,
        "",
        0,
        0,
        "",
        "",
        "DELETED",
        IERC20(address(0))
    );

        disputed[_id] = false;
        emit disputeCreated(false , block.timestamp , _id );
        emit Status(_id, "Completed");
    }

    receive() external payable {}

    modifier notDisputed(uint256 _id) {
        require(disputed[_id] == false, "Disputed gig currently paused!");
        _;
    }
}