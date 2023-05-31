// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
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
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC1155Upgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155BurnableUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155Burnable_init_unchained();
    }

    function __ERC1155Burnable_init_unchained() internal initializer {
    }
    function burn(address account, uint256 id, uint256 value) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155ReceiverUpgradeable.sol";
import "../../introspection/ERC165Upgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
        _registerInterface(
            ERC1155ReceiverUpgradeable(address(0)).onERC1155Received.selector ^
            ERC1155ReceiverUpgradeable(address(0)).onERC1155BatchReceived.selector
        );
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155MetadataURIUpgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../introspection/ERC165Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal initializer {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
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
    function uri(uint256) external view virtual override returns (string memory) {
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
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
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
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
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
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
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
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
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
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
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
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable(to).onERC1155Received.selector) {
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
    )
        private
    {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived.selector) {
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
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {

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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721BurnableUpgradeable is Initializable, ContextUpgradeable, ERC721Upgradeable {
    function __ERC721Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Burnable_init_unchained();
    }

    function __ERC721Burnable_init_unchained() internal initializer {
    }
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC721ReceiverUpgradeable.sol";
import "../../proxy/Initializable.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "../../introspection/ERC165Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/EnumerableSetUpgradeable.sol";
import "../../utils/EnumerableMapUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;
    using StringsUpgradeable for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSetUpgradeable.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMapUpgradeable.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
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

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721Upgradeable.isApprovedForAll(owner, _msgSender()),
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
        require(operator != _msgSender(), "ERC721: approve to caller");

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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
        return _tokenOwners.contains(tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721Upgradeable.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721ReceiverUpgradeable(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId); // internal owner
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMapUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library EnumerableSetUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
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
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../access/Ownable.sol";
import "./TransparentUpgradeableProxy.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(TransparentUpgradeableProxy proxy, address implementation, bytes memory data) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IBeacon.sol";
import "../access/Ownable.sol";
import "../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) public {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC1155Receiver.sol";
import "../../utils/Context.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) public {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
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
    function uri(uint256) external view virtual override returns (string memory) {
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
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
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
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
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
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
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
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
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
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
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
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
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
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC1155.sol";

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

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
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
    )
        external
        returns(bytes4);

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
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
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

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
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
        require(operator != _msgSender(), "ERC721: approve to caller");

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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
        return _tokenOwners.contains(tokenId);
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
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
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
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

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

pragma solidity >=0.6.0 <0.8.0;

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/proxy/IBeacon.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "../interfaces/ITransferGatekeeper.sol";
import "../interfaces/IRoyaltyAwareNFT.sol";
import "../interfaces/IExternalVerifiedMinting.sol";
import "../utils/MintNFTEvent.sol";

/// @title BaseEnigmaNFT1155
///
/// @dev This contract is a ERC1155 burnable and upgradable based in openZeppelin v3.4.0.
///         Be careful when upgrade, you must respect the same storage.

abstract contract BaseEnigmaNFT1155 is
    IRoyaltyAwareNFT,
    ERC1155BurnableUpgradeable,
    OwnableUpgradeable,
    MintNFTEvent,
    IExternalVerifiedMinting
{
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;
    using StringsUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;

    /* Storage */
    // mapping from token ID to account balances.
    // FIXME: It doesn make much sense for the user one. Check if it can be removed without breaking storage layout
    mapping(uint256 => address) internal creators;
    //mapping for token royaltyFee
    mapping(uint256 => uint256) private _royaltyFee;
    //mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    //mapping for token owners
    EnumerableMapUpgradeable.UintToAddressMap private _tokenOwners;

    //tokens base uri
    string public tokenURIPrefix;

    string private _name;

    string private _symbol;

    //token id counter, increase by 1 for each new mint
    uint256 public newItemId;

    // Transfer Gatekeeper with logic to allow token transfers
    IBeacon public transferGatekeeperBeacon;

    //mapping for token rights holder, the ones that will receive royalties
    mapping(uint256 => address) private rightsHolders_;

    mapping(address => bool) private externalVerifiers_;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /* events */
    event TokenBaseURI(string value);
    event SetExternalAuthorized(address externalVerifiers_, bool isAuthorized_);

    /* functions */

    modifier onlyExternalVerifier() {
        require(isExternalVerifier(msg.sender), "BaseEnigmaNFT1155: Not external verifier");
        _;
    }

    /**
     * @notice Initialize NFT1155 contract.
     *
     * @param name_ the token name
     * @param symbol_ the token symbol
     * @param tokenURIPrefix_ the toke base uri
     */
    function _initialize(
        string memory name_,
        string memory symbol_,
        string memory tokenURIPrefix_
    ) internal initializer {
        __ERC1155_init(tokenURIPrefix_);
        __ERC1155Burnable_init();
        __Ownable_init();

        _name = name_;
        _symbol = symbol_;
        newItemId = 1;
        _setTokenURIPrefix(tokenURIPrefix_);
        _registerInterface(_INTERFACE_ID_ERC2981);
    }

    /// oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line
    constructor() initializer {}

    function name() external view virtual returns (string memory) {
        return _name;
    }

    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId_ uint256 ID of the token to set its URI
     * @param tokenURI_ string URI to assign
     */
    function _setTokenURI(uint256 tokenId_, string memory tokenURI_) internal {
        _tokenURIs[tokenId_] = tokenURI_;
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (rightsHolder(_tokenId), _salePrice.mul(_royaltyFee[_tokenId]).div(1000));
    }

    /**
     * @notice Get the rights holder (the one to receive royalties) of given tokenID.
     * @param tokenId ID of the Token.
     * @return right holder of given ID.
     */
    function rightsHolder(uint256 tokenId) public view virtual override returns (address) {
        address _rightsHolder = rightsHolders_[tokenId];
        return _rightsHolder == address(0x0) ? this.getCreator(tokenId) : _rightsHolder;
    }

    /**
     * @notice Updates the rights holder for a specific tokenId
     * @param tokenId ID of the Token.
     * @param newRightsHolder new rights holder of given ID.
     * @dev Rights holder should only be set by the token creator
     */
    function setRightsHolder(uint256 tokenId, address newRightsHolder) external override {
        require(msg.sender == this.getCreator(tokenId), "Only creator");
        rightsHolders_[tokenId] = newRightsHolder;
    }

    /**
     * @dev Internal function to set the token URI for all the tokens.
     * @param _tokenURIPrefix string memory _tokenURIPrefix of the tokens.
     */
    function _setTokenURIPrefix(string memory _tokenURIPrefix) internal {
        tokenURIPrefix = _tokenURIPrefix;
        emit TokenBaseURI(_tokenURIPrefix);
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC1155Metadata: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = tokenURIPrefix;

        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view override returns (string memory) {
        return tokenURI(id);
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @notice Get the balance of an account's Tokens.
     * @param account The address of the token holder
     * @param tokenId ID of the Token
     * @return The owner's balance of the Token type requested
     */

    function balanceOf(address account, uint256 tokenId) public view override returns (uint256) {
        require(_exists(tokenId), "ERC1155Metadata: balance query for nonexistent token");
        return super.balanceOf(account, tokenId);
    }

    /**
     * @notice call transfer fucntion after check transfer gatekeeper allowance
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        bytes memory allData = abi.encode("1155", tokenId, amount, data);
        ITransferGatekeeper transferGatekeeper = ITransferGatekeeper(transferGatekeeperBeacon.implementation());
        require(transferGatekeeper.canTransfer(from, to, _msgSender(), allData), "Transfer not approved");
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @notice call transfer fucntion after check transfer gatekeeper allowance
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        bytes memory allData = abi.encode("1155_batch", ids, amounts, data);
        ITransferGatekeeper transferGatekeeper = ITransferGatekeeper(transferGatekeeperBeacon.implementation());
        require(transferGatekeeper.canTransfer(from, to, _msgSender(), allData), "Batch transfer not approved");
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param tokenURI_ string memory URI of the token to be minted
     * @param fee_ uint256 royalty of the token to be minted
     * @param rightsHolder_ account that will be marked as the creator
     * @param recipient account that will receive the tokens
     * @param nonce ID that identifies the action of creation
     * @param creator_ account that will receive the royalties
     * @param tokenId_ id of the token to be created, it should be 0 if autoId is true
     * @param supply_ uint256 supply of the token to be minted
     */
    function _mintNew(
        string memory tokenURI_,
        uint256 fee_,
        address rightsHolder_,
        address recipient,
        uint256 nonce,
        address creator_,
        uint256 tokenId_,
        uint256 supply_
    ) internal virtual returns (uint256) {
        require(!_exists(tokenId_), "ERC1155: token already minted");

        require(_tokenOwners.set(tokenId_, recipient), "ERC1155: token already minted");
        require(supply_ != 0, "Supply should be positive");
        require(bytes(tokenURI_).length > 0, "uri should be set");

        _mint(recipient, tokenId_, supply_, "");
        _setTokenURI(tokenId_, tokenURI_);
        emit URI(tokenURI_, tokenId_);
        emit MintNewNFT(tokenId_, creator_, recipient, tokenURI_, supply_, fee_, rightsHolder_, nonce);

        _royaltyFee[tokenId_] = fee_;
        rightsHolders_[tokenId_] = rightsHolder_;

        return tokenId_;
    }

    /**
     * @dev Internal function to mint more of an existing token.
     * Reverts if the given token does NOT exist.
     * @param to account that will receive the tokens
     * @param tokenId id of the token to be created, it should be 0 if autoId is true
     * @param amount amount of tokens to be minted
     * @param nonce number that identifies the order of creation
     */
    function _mintExistingNFT(
        uint256 tokenId,
        address to,
        uint256 amount,
        uint256 nonce
    ) internal {
        require(_exists(tokenId), "BaseEnigmaNFT1155: TokenId does not exist");
        super._mint(to, tokenId, amount, "");
        emit MintExistingNFT(tokenId, to, amount, nonce);
    }

    function _increaseNextId() internal returns (uint256) {
        uint256 tokenCounter = newItemId;
        newItemId = newItemId + 1;
        return tokenCounter;
    }

    /**
     * @notice call burn function after check that token exists
     */
    function _burn(
        address account,
        uint256 tokenId,
        uint256 amount
    ) internal virtual override {
        require(_exists(tokenId), "ERC1155Metadata: burn query for nonexistent token");
        super._burn(account, tokenId, amount);
    }

    /**
     * @notice burn tokens to msg.sender
     */
    function burn(uint256 tokenId, uint256 amount) external {
        _burn(msg.sender, tokenId, amount);
    }

    /**
     * @dev external function to set the token URI for all the tokens.
     * @param baseURI_ string memory _tokenURIPrefix of the tokens.
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setTokenURIPrefix(baseURI_);
    }

    /**
     * @notice Set a transferGatekeeperBeacon that points to the gatekeeper implementation
     * @param transferGatekeeperBeacon_ The IBeacon instance
     */
    function setTransferGatekeeperBeacon(IBeacon transferGatekeeperBeacon_) external onlyOwner {
        transferGatekeeperBeacon = transferGatekeeperBeacon_;
    }

    /**
     * @notice Allows to batchUpdate the royalty fees for several tokens
     * @dev This function doesn't perform any checks to make it cheaper, be careful when invoking it
     * @param tokenIds Tokens to update royalty from
     * @param newRoyaltyFees New royalty fees. They must match with the tokenIds
     */
    function batchUpdateRoyaltyFees(uint256[] calldata tokenIds, uint256[] calldata newRoyaltyFees) external onlyOwner {
        uint256 length = tokenIds.length;

        for (uint256 index; index < length; ) {
            _royaltyFee[tokenIds[index]] = newRoyaltyFees[index];
            ++index;
        }
    }

    /**
     * @notice Kind of like an initializer for the upgrade where we support ERC2981
     * @dev This is left unprotected as it is idempotent and it has no parameters
     */
    function declareERC2981Interface() external override {
        _registerInterface(_INTERFACE_ID_ERC2981);
    }

    /**
     * @notice Add or remove an external authorizer
     * @dev This function is idempotent and unprotected.
     */
    function setExternalVerifier(address externalVerifier_, bool isAuthorized_) external override onlyOwner {
        externalVerifiers_[externalVerifier_] = isAuthorized_;
        emit SetExternalAuthorized(externalVerifier_, isAuthorized_);
    }

    /**
     * @notice Add or remove an external authorizer
     * @dev This function is idempotent and unprotected.
     */
    function isExternalVerifier(address externalVerifier_) public view override returns (bool) {
        return externalVerifiers_[externalVerifier_];
    }

    /**
     * @notice mint function that should be used by a well known contract that authorizes a verifies in a different way
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     * @param rightsHolder_ account that will receive royalties
     * @param to_ address of the first receiver
     * @param nonce nonce of signature
     * @param verifiedCreator_ address of the authorizer of the token creation
     * @param tokenId_ This is expected to be 0. As the tokenIds are autogenerated
     * @param supply_ tokens amount to be minted, not used if 721
     * @return Id of the newly created token
     */
    function mintNewExternalVerifier(
        string memory tokenURI_,
        uint256 fee_,
        address rightsHolder_,
        address to_,
        uint256 nonce,
        address verifiedCreator_,
        uint256 tokenId_,
        uint256 supply_
    ) public virtual returns (uint256);

    /**
     * @notice mint function that should be used by a well known contract that verifies a minter in a different way
     * @param tokenId_ id of the tokens to be minted, must be an existing token
     * @param supply_ tokens amount to be minted
     * @param to_ address of the first receiver
     * will fail if it's not authorized to min
     * @param nonce nonce of signature
     * @return Id of the newly created token
     */
    function mintExistingExternalVerifier(
        uint256 tokenId_,
        uint256 supply_,
        address to_,
        address,
        uint256 nonce
    ) external virtual returns (uint256);

    uint256[49] private __gap;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./BaseEnigmaNFT1155.sol";
import "../utils/AuthorizedMintingNFT.sol";
import "../utils/AuthorizationBitmap.sol";

/// @title EnigmaNFT1155
///
/// @dev This contract extends from BaseEnigmaNFT1155

contract EnigmaNFT1155 is BaseEnigmaNFT1155, AuthorizedMintingNFT {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToAddressMap;

    AuthorizationBitmap.Bitmap internal processedNonces; // Struct to check that an authorization was not used yet

    // Though the TradeV4 contract is upgradeable, we still have to initialize the implementation through the
    // constructor. This is because we chose to import the non upgradeable EIP712 as it does not have storage
    // variable(which actually makes it upgradeable) as it only uses immmutable variables. This has several advantages:
    // - We can import it without worrying the storage layout
    // - Is more efficient as there is no need to read from the storage
    // Note: The cache mechanism will NOT be used here as the address will differ from the one calculated in the
    // constructor due to the fact that when the contract is operating we will be using delegatecall, meaningn
    // that the address will be the one from the proxy as opposed to the implementation's during the
    // constructor execution
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory version) AuthorizedMintingNFT(name, version) {}

    /**
     * @notice Initialize NFT1155 contract.
     *
     * @param name_ the token name
     * @param symbol_ the token symbol
     * @param tokenURIPrefix_ the toke base uri
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory tokenURIPrefix_
    ) external initializer {
        super._initialize(name_, symbol_, tokenURIPrefix_);
    }

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param supply_ tokens amount to be minted
     * @param fee_ uint256 royalty of the token to be minted.
     * @param nonce nonce of signature
     * @param sign_ bytes that authorize the minting of this token
     */
    function mintNew(
        string memory tokenURI_,
        uint256 supply_,
        uint256 fee_,
        uint256 nonce,
        bytes memory sign_
    ) external {
        mintNewCustomized(tokenURI_, supply_, fee_, msg.sender, msg.sender, nonce, sign_);
    }

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param supply_ tokens amount to be minted
     * @param fee_ uint256 royalty of the token to be minted.
     * @param rightsHolder_ address that will receive the royalties
     * @param to_ address of the first receiver
     * @param nonce nonce of signature
     * @param sign_ bytes that authorize the minting of this token
     */
    function mintNewCustomized(
        string memory tokenURI_,
        uint256 supply_,
        uint256 fee_,
        address rightsHolder_,
        address to_,
        uint256 nonce,
        bytes memory sign_
    ) public returns (uint256) {
        require(
            !AuthorizationBitmap.isAuthProcessed(processedNonces, nonce),
            "EnigmaNFT1155: Nonce for NFTMintingVoucher already used"
        );
        verifySign(tokenURI_, msg.sender, supply_, nonce, sign_, owner());
        AuthorizationBitmap.setAuthProcessed(processedNonces, nonce);
        uint256 tokenId = _mintNew(tokenURI_, fee_, rightsHolder_, to_, nonce, msg.sender, _increaseNextId(), supply_);
        creators[tokenId] = msg.sender;
        return tokenId;
    }

    function getCreator(uint256 tokenId) external view virtual override returns (address) {
        return creators[tokenId];
    }

    /**
     * @notice mint function that should be used by a well known contract that authorizes a verifies in a different way
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     * @param rightsHolder_ account that will receive royalties
     * @param to_ address of the first receiver
     * @param nonce nonce of signature
     * @param verifiedCreator_ address of the authorizer of the token creation
     * @param tokenId_ This is expected to be 0. As the tokenIds are autogenerated
     * @param supply_ tokens amount to be minted, not used if 721
     * @return Id of the newly created token
     */
    function mintNewExternalVerifier(
        string memory tokenURI_,
        uint256 fee_,
        address rightsHolder_,
        address to_,
        uint256 nonce,
        address verifiedCreator_,
        uint256 tokenId_,
        uint256 supply_
    ) public virtual override onlyExternalVerifier returns (uint256) {
        require(tokenId_ == 0, "EnigmaNFT1155: TokenId is not zero");
        uint256 tokenId = _increaseNextId();
        _mintNew(tokenURI_, fee_, rightsHolder_, to_, nonce, verifiedCreator_, tokenId, supply_);
        creators[tokenId] = verifiedCreator_;
        return tokenId;
    }

    /**
     * @notice mint function that should be used by a well known contract that verifies a minter in a different way
     * @param tokenId_ id of the tokens to be minted, must be an existing token
     * @param supply_ tokens amount to be minted
     * @param to_ address of the first receiver
     * will fail if it's not authorized to min
     * @param verifiedCreator_ verified address of the original operation to mint
     * @param nonce nonce of signature
     * @return Id of the newly created token
     */
    function mintExistingExternalVerifier(
        uint256 tokenId_,
        uint256 supply_,
        address to_,
        address verifiedCreator_,
        uint256 nonce
    ) external virtual override onlyExternalVerifier returns (uint256) {
        _mintExistingNFT(tokenId_, to_, supply_, nonce);
        require(creators[tokenId_] == verifiedCreator_, "EnigmaNFT1155: verifiedCreator is not Token Creator");
        return tokenId_;
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./BaseEnigmaNFT1155.sol";
import "../vault/Vault.sol";

/// @title EnigmaUserToken1155
///
/// @dev This contract extends from BaseEnigmaNFT1155
contract EnigmaUserToken1155 is BaseEnigmaNFT1155 {
    address public operator;
    bool public autoId;
    address public bundledItemsRecipient;

    event OperatorChanged(address indexed newOperator);
    event BundledItemsRecipientChanged(address indexed newBundledItemsrecipient);
    event ItemsBundled(uint256 amountOfTokensCreated, uint256[] ids, uint256[] amounts);

    struct MintItem {
        uint256 tokenId;
        bool mintNew;
        address recipient;
        uint256 amount;
        uint256 fee;
        string uri;
    }

    struct MintItemWithRightsHolder {
        MintItem basicMintItem;
        address rightsHolder;
    }

    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner() || msg.sender == operator, "Not owner nor operator");
        _;
    }

    /// oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line
    constructor() initializer {}

    /**
     * @notice Initialize NFT1155 contract.
     *
     * @param name_ the token name
     * @param symbol_ the token symbol
     * @param tokenURIPrefix_ the token base uri
     * @param operator_ that will be able to mint tokens on behalf the owner
     * @param transferGatekeeperBeacon_ TransferGatekeeper beacon
     * @param autoId_ True if token id will be automatically assigned when minting
     * @param bundledItemsRecipient_ Adress that will receive the tokens to be bundled. This ideally should lock them.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory tokenURIPrefix_,
        address operator_,
        address transferGatekeeperBeacon_,
        bool autoId_,
        address bundledItemsRecipient_
    ) external initializer {
        super._initialize(name_, symbol_, tokenURIPrefix_);
        operator = operator_;
        transferGatekeeperBeacon = IBeacon(transferGatekeeperBeacon_);
        autoId = autoId_;
        bundledItemsRecipient = bundledItemsRecipient_;
    }

    function batchMint(MintItem[] calldata toMint) public onlyOwnerOrOperator {
        uint256 length = toMint.length;
        address rightsHolder_ = owner();

        for (uint256 index = 0; index < length; index++) {
            _mintItem(toMint[index], rightsHolder_);
        }
    }

    function batchMintWithRightsHolder(MintItemWithRightsHolder[] calldata toMint) public onlyOwnerOrOperator {
        uint256 length = toMint.length;

        for (uint256 index = 0; index < length; index++) {
            _mintItem(toMint[index].basicMintItem, toMint[index].rightsHolder);
        }
    }

    /**
     * @notice This function bundles (exchanges) some tokens in exchange for a new one. All the tokens
     *         must belong to the same collection (this one)
     * @dev This operation can only be performed by the owner or the operator.
     *
     * @param tokensOwner The one the tokens are going to be taken from
     * @param ids TokenIds to be locked in exchange for the new one
     * @param amounts For each token to be exchanged
     * @param toMint new tokens to be generated and minted with the owner set as right holder
     */
    function bundle(
        address tokensOwner,
        uint256[] memory ids,
        uint256[] memory amounts,
        MintItem[] calldata toMint
    ) external onlyOwnerOrOperator {
        super.safeBatchTransferFrom(tokensOwner, bundledItemsRecipient, ids, amounts, "");
        batchMint(toMint);
        emit ItemsBundled(toMint.length, ids, amounts);
    }

    /**
     * @notice This function bundles (exchanges) some tokens in exchange for a new one. All the tokens
     *         must belong to the same collection (this one)
     * @dev This operation can only be performed by the owner or the operator.
     *
     * @param tokensOwner The one the tokens are going to be taken from
     * @param ids TokenIds to be locked in exchange for the new one
     * @param amounts For each token to be exchanged
     * @param toMint new token to be generated and minted to the owner
     */
    function bundleWithRightsHolder(
        address tokensOwner,
        uint256[] memory ids,
        uint256[] memory amounts,
        MintItemWithRightsHolder[] calldata toMint
    ) external onlyOwnerOrOperator {
        super.safeBatchTransferFrom(tokensOwner, bundledItemsRecipient, ids, amounts, "");
        batchMintWithRightsHolder(toMint);
        emit ItemsBundled(toMint.length, ids, amounts);
    }

    /**
     * @dev Mints a new NFT if it doesn't exist otherwise uses the existing one
     */
    function _mintItem(MintItem calldata item, address rightsHolder_) internal {
        if (item.mintNew) {
            _mintNew(item.uri, item.fee, rightsHolder_, item.recipient, 0, owner(), item.tokenId, item.amount);
        } else {
            _mintExistingNFT(item.tokenId, item.recipient, item.amount, 0);
        }
    }

    /**
     * @notice Checks if operator contract has registered the passed signer address as a valid signer
     * @dev If Vault were to get refactored to avoid using an ACL then we wouldn't need to
     * get the SIGNER_ROLE hash, because we would assume that is the only possible role
     * @param signer address of the sellOrder signer.
     * @return Boolean representing if signer is registered as valid or not
     */
    function _hasOperatorPermission(address signer) internal view returns (bool) {
        if (operator == address(0)) return false;
        Vault operator_ = Vault(operator);
        bytes32 signerRole = operator_.SIGNER_ROLE();
        return operator_.hasRole(signerRole, signer);
    }

    /**
     * @notice For compatibility reasons this method is kept although it always returns the contract owner
     */
    function getCreator(uint256) external view virtual override returns (address) {
        return owner();
    }

    /**
     * @notice Let's the owner to update the operator
     * @param newOperator to set
     */
    function setOperator(address newOperator) external onlyOwner {
        operator = newOperator;
        emit OperatorChanged(newOperator);
    }

    /**
     * @notice Allows changing the bundled NFTs recipient to another address
     * @param bundledItemsRecipient_ New recipient. Cannot be 0x0 address otherwise will fail when transfering
     */
    function setBundledItemsRecipient(address bundledItemsRecipient_) external onlyOwnerOrOperator {
        require(bundledItemsRecipient_ != address(0x0), "Cannot be 0x0 address");
        bundledItemsRecipient = bundledItemsRecipient_;
        emit BundledItemsRecipientChanged(bundledItemsRecipient);
    }

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param supply_ tokens amount to be minted
     * @param fee_ uint256 royalty of the token to be minted.
     * @param tokenId_ id of the token to be created, it should be 0 if autoId is true
     */
    function mintNew(
        string memory tokenURI_,
        uint256 supply_,
        uint256 fee_,
        uint256 tokenId_
    ) external onlyOwnerOrOperator {
        _mintNew(tokenURI_, fee_, msg.sender, msg.sender, 0, owner(), tokenId_, supply_);
    }

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param supply_ tokens amount to be minted
     * @param fee_ uint256 royalty of the token to be minted.
     * @param rightsHolder_ address that will receive the royalties
     * @param to_ address of the first receiver
     * @param tokenId_ id of the token to be created, it should be 0 if autoId is true
     */
    function mintNewCustomized(
        string memory tokenURI_,
        uint256 supply_,
        uint256 fee_,
        address rightsHolder_,
        address to_,
        uint256 tokenId_
    ) external onlyOwnerOrOperator returns (uint256) {
        return _mintNew(tokenURI_, fee_, rightsHolder_, to_, 0, owner(), tokenId_, supply_);
    }

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param supply_ tokens amount to be minted
     * @param fee_ uint256 royalty of the token to be minted.
     * @param rightsHolder_ address that will receive the royalties
     * @param recipient address of the first receiver
     * @param tokenId_ id of the token to be created, it should be 0 if autoId is true
     */
    function _mintNew(
        string memory tokenURI_,
        uint256 fee_,
        address rightsHolder_,
        address recipient,
        uint256 nonce,
        address creator_,
        uint256 tokenId_,
        uint256 supply_
    ) internal virtual override returns (uint256) {
        // TODO Change this for a ternary
        if (autoId) {
            require(tokenId_ == 0, "EnigmaUserToken1155: New token id specified but autoId is active");
        } else {
            require(!super._exists(tokenId_), "EnigmaUserToken1155: TokenId exists already");
        }
        uint256 tokenId = autoId ? _increaseNextId() : tokenId_;
        super._mintNew(tokenURI_, fee_, rightsHolder_, recipient, nonce, creator_, tokenId, supply_);
        return tokenId;
    }

    /**
     * @notice mint function that should be used by a well known contract that authorizes a verifies in a different way
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     * @param rightsHolder_ account that will receive royalties
     * @param to_ address of the first receiver
     * @param nonce nonce of signature
     * @param verifiedCreator_ address of the authorizer of the token creation
     * @param tokenId_ This is expected to be 0. As the tokenIds are autogenerated
     * @param supply_ tokens amount to be minted, not used if 721
     * @return Id of the newly created token
     */
    function mintNewExternalVerifier(
        string memory tokenURI_,
        uint256 fee_,
        address rightsHolder_,
        address to_,
        uint256 nonce,
        address verifiedCreator_,
        uint256 tokenId_,
        uint256 supply_
    ) public virtual override onlyExternalVerifier returns (uint256) {
        // If verifiedCreator (order signer) is the owner address, operator address, or has permission by Vault
        // then they can mint
        require(
            verifiedCreator_ == owner() || verifiedCreator_ == operator || _hasOperatorPermission(verifiedCreator_),
            "EnigmaUserToken1155: Not authorized to mint"
        );
        return _mintNew(tokenURI_, fee_, rightsHolder_, to_, nonce, verifiedCreator_, tokenId_, supply_);
    }

    /**
     * @notice mint function that should be used by a well known contract that verifies a minter in a different way
     * @param tokenId_ id of the tokens to be minted, must be an existing token
     * @param supply_ tokens amount to be minted
     * @param to_ address of the first receiver
     * will fail if it's not authorized to min
     * @param verifiedCreator_ verified address of the original operation to mint
     * @param nonce nonce of signature
     * @return Id of the newly created token
     */
    function mintExistingExternalVerifier(
        uint256 tokenId_,
        uint256 supply_,
        address to_,
        address verifiedCreator_,
        uint256 nonce
    ) external virtual override onlyExternalVerifier returns (uint256) {
        // If verifiedCreator (order signer) is the owner address, operator address, or has permission by Vault
        // then they can mint
        require(
            verifiedCreator_ == owner() || verifiedCreator_ == operator || _hasOperatorPermission(verifiedCreator_),
            "EnigmaUserToken1155: Not authorized to mint"
        );
        _mintExistingNFT(tokenId_, to_, supply_, nonce);
        return tokenId_;
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/IBeacon.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";

import "../interfaces/ITransferGatekeeper.sol";
import "../interfaces/IRoyaltyAwareNFT.sol";
import "../interfaces/IExternalVerifiedMinting.sol";
import "../utils/MintNFTEvent.sol";

/// @title BaseEnigmaNFT721
///
/// @dev This contract is a ERC721 burnable and upgradable based in openZeppelin v3.4.0.
///         Be careful when upgrade, you must respect the same storage.

abstract contract BaseEnigmaNFT721 is
    IRoyaltyAwareNFT,
    ERC721BurnableUpgradeable,
    OwnableUpgradeable,
    MintNFTEvent,
    IExternalVerifiedMinting
{
    using SafeMathUpgradeable for uint256;

    /* Storage */
    //mapping for token royaltyFee
    mapping(uint256 => uint256) private _royaltyFee;

    //mapping for token creator
    mapping(uint256 => address) internal _creator;

    //token id counter, increase by 1 for each new mint
    uint256 public tokenCounter;

    // Transfer Gatekeeper with logic to allow token transfers
    IBeacon public transferGatekeeperBeacon;

    //mapping for token rights holder, the ones that will receive royalties
    mapping(uint256 => address) private _rightsHolders;

    mapping(address => bool) private externalVerifiers_;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /* events */
    event URI(string value, uint256 indexed id);
    event TokenBaseURI(string value);

    event SetExternalAuthorized(address externalVerifiers_, bool isAuthorized_);

    /* functions */

    modifier onlyExternalVerifier() {
        require(isExternalVerifier(msg.sender), "BaseEnigmaNFT721: Not external verifier");
        _;
    }

    /**
     * @notice Initialize NFT721 contract.
     *
     * @param name_ the token name
     * @param symbol_ the token symbol
     * @param tokenURIPrefix_ the toke base uri
     */
    function _initialize(
        string memory name_,
        string memory symbol_,
        string memory tokenURIPrefix_
    ) internal initializer {
        __ERC721_init(name_, symbol_);
        __ERC721Burnable_init();
        __Ownable_init();

        tokenCounter = 1;
        _setBaseURI(tokenURIPrefix_);
        _registerInterface(_INTERFACE_ID_ERC2981);
    }

    /// oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line
    constructor() initializer {}

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (rightsHolder(_tokenId), _salePrice.mul(_royaltyFee[_tokenId]).div(1000));
    }

    /**
     * @notice Get the creator of given tokenID.
     * @param tokenId ID of the Token.
     * @return creator of given ID.
     */
    function getCreator(uint256 tokenId) public view virtual override returns (address) {
        return _creator[tokenId];
    }

    /**
     * @notice Get the rights holder (the one to receive royalties) of given tokenID.
     * @param tokenId ID of the Token.
     * @return creator of given ID.
     */
    function rightsHolder(uint256 tokenId) public view virtual override returns (address) {
        address rightsHolder_ = _rightsHolders[tokenId];
        return rightsHolder_ == address(0x0) ? getCreator(tokenId) : rightsHolder_;
    }

    /**
     * @notice Updates the rights holder for a specific tokenId
     * @param tokenId ID of the Token.
     * @param newRightsHolder new rights holderof given ID.
     * @dev Rights holder should only be set by the token creator
     */
    function setRightsHolder(uint256 tokenId, address newRightsHolder) external override {
        require(msg.sender == this.getCreator(tokenId), "Only creator");
        _rightsHolders[tokenId] = newRightsHolder;
    }

    /**
     * @notice Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     * @param baseURI_ the new base uri
     */
    function _setBaseURI(string memory baseURI_) internal virtual override {
        super._setBaseURI(baseURI_);
        emit TokenBaseURI(baseURI_);
    }

    /**
     * @notice Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param _tokenURI string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual override {
        super._setTokenURI(tokenId, _tokenURI);
        emit URI(_tokenURI, tokenId);
    }

    /**
     * @notice call safe mint function and set token creator and royalty fee
     */
    function _safeMint(
        address to_,
        uint256 tokenId_,
        uint256 fee_,
        address rightsHolder_
    ) internal virtual {
        _royaltyFee[tokenId_] = fee_;
        _rightsHolders[tokenId_] = rightsHolder_;
        super._safeMint(to_, tokenId_, "");
    }

    /**
     * @notice call transfer fucntion after check transferGatekeeper allowance
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        bytes memory allData = abi.encode("721", tokenId);

        ITransferGatekeeper transferGatekeeper = ITransferGatekeeper(transferGatekeeperBeacon.implementation());
        require(transferGatekeeper.canTransfer(from, to, _msgSender(), allData), "Transfer not approved");
        super._transfer(from, to, tokenId);
    }

    /**
     * @notice external function to set the base URI for all token IDs
     * @param baseURI_ the new base uri
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    /**
     * @notice Set a transferGatekeeperBeacon that points to the gatekeeper implementation
     * @param transferGatekeeperBeacon_ The IBeacon instance
     */
    function setTransferGatekeeperBeacon(IBeacon transferGatekeeperBeacon_) external onlyOwner {
        transferGatekeeperBeacon = transferGatekeeperBeacon_;
    }

    /**
     * @notice Allows to batchUpdate the royalty fees for several tokens
     * @dev This function doesn't perform any checks to make it cheaper, be careful when invoking it
     * @param tokenIds Tokens to update royalty from
     * @param newRoyaltyFees New royalty fees. They must match with the tokenIds
     */
    function batchUpdateRoyaltyFees(uint256[] calldata tokenIds, uint256[] calldata newRoyaltyFees) external onlyOwner {
        uint256 length = tokenIds.length;

        for (uint256 index; index < length; ) {
            _royaltyFee[tokenIds[index]] = newRoyaltyFees[index];
            ++index;
        }
    }

    /**
     * @notice Kind of like an initializer for the upgrade where we support ERC2981
     * @dev This is left unprotected as it is idempotent and it has no parameters
     */
    function declareERC2981Interface() external override {
        _registerInterface(_INTERFACE_ID_ERC2981);
    }

    /**
     * @notice Add or remove an external authorizer
     * @dev This function is idempotent and unprotected.
     */
    function setExternalVerifier(address externalVerifier_, bool isAuthorized_) external override onlyOwner {
        externalVerifiers_[externalVerifier_] = isAuthorized_;
        emit SetExternalAuthorized(externalVerifier_, isAuthorized_);
    }

    /**
     * @notice Add or remove an external authorizer
     * @dev This function is idempotent and unprotected.
     */
    function isExternalVerifier(address externalVerifier_) public view override returns (bool) {
        return externalVerifiers_[externalVerifier_];
    }

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     * @param rightsHolder_ account that will receive royalties
     * @param to_ address of the first receiver
     * @param nonce nonce of signature
     * @param to_ address of the creator of the token
     * @return id of the token
     */
    function _mintNew(
        string memory tokenURI_,
        uint256 fee_,
        address rightsHolder_,
        address to_,
        uint256 nonce,
        address creator_
    ) internal returns (uint256) {
        uint256 newItemId = tokenCounter;
        tokenCounter = tokenCounter + 1;
        _safeMint(to_, newItemId, fee_, rightsHolder_);
        _setTokenURI(newItemId, tokenURI_);
        emit MintNewNFT(newItemId, creator_, to_, tokenURI_, 1, fee_, rightsHolder_, nonce);
        return newItemId;
    }

    /**
     * @notice mint function that should be used by a well known contract that authorizes a minter in a different way
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     * @param rightsHolder_ account that will receive royalties
     * @param to_ address of the first receiver
     * @param verifiedCreator_ actual sender of the mint operation(creator), verified by the external verifier
     * @param nonce nonce of signature
     * @return Id of the newly created token
     */
    function mintNewExternalVerifier(
        string memory tokenURI_,
        uint256 fee_,
        address rightsHolder_,
        address to_,
        address verifiedCreator_,
        uint256 nonce
    ) public virtual onlyExternalVerifier returns (uint256) {
        return _mintNew(tokenURI_, fee_, rightsHolder_, to_, nonce, verifiedCreator_);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./BaseEnigmaNFT721.sol";
import "../utils/AuthorizedMintingNFT.sol";
import "../utils/AuthorizationBitmap.sol";

/// @title EnigmaNFT721
///
/// @dev This contract extends from BaseEnigmaNFT721

contract EnigmaNFT721 is BaseEnigmaNFT721, AuthorizedMintingNFT {
    AuthorizationBitmap.Bitmap internal processedNonces; // Struct to check that an authorization was not used yet

    // Though the TradeV4 contract is upgradeable, we still have to initialize the implementation through the
    // constructor. This is because we chose to import the non upgradeable EIP712 as it does not have storage
    // variable(which actually makes it upgradeable) as it only uses immmutable variables. This has several advantages:
    // - We can import it without worrying the storage layout
    // - Is more efficient as there is no need to read from the storage
    // Note: The cache mechanism will NOT be used here as the address will differ from the one calculated in the
    // constructor due to the fact that when the contract is operating we will be using delegatecall, meaningn
    // that the address will be the one from the proxy as opposed to the implementation's during the
    // constructor execution
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory version) AuthorizedMintingNFT(name, version) {}

    /**
     * @notice Initialize NFT1155 contract.
     *
     * @param name_ the token name
     * @param symbol_ the token symbol
     * @param tokenURIPrefix_ the toke base uri
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory tokenURIPrefix_
    ) external initializer {
        super._initialize(name_, symbol_, tokenURIPrefix_);
    }

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     * @param nonce nonce of signature
     * @param sign_ bytes that authorize the minting of this token
     */
    function mintNew(
        string memory tokenURI_,
        uint256 fee_,
        uint256 nonce,
        bytes memory sign_
    ) external returns (uint256) {
        return mintNewCustomized(tokenURI_, fee_, msg.sender, msg.sender, nonce, sign_);
    }

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     * @param rightsHolder_ account that will receive royalties
     * @param to_ address of the first receiver
     * @param nonce nonce of signature
     * @param sign_ bytes that authorize the minting of this token
     */
    function mintNewCustomized(
        string memory tokenURI_,
        uint256 fee_,
        address rightsHolder_,
        address to_,
        uint256 nonce,
        bytes memory sign_
    ) public returns (uint256) {
        require(
            !AuthorizationBitmap.isAuthProcessed(processedNonces, nonce),
            "EnigmaNFT721: Nonce for NFTMintingVoucher already used"
        );
        verifySign(tokenURI_, msg.sender, 1, nonce, sign_, owner());
        AuthorizationBitmap.setAuthProcessed(processedNonces, nonce);
        uint256 tokenId = _mintNew(tokenURI_, fee_, rightsHolder_, to_, nonce, msg.sender);
        _creator[tokenId] = msg.sender;
        return tokenId;
    }

    /**
     * @notice mint function that should be used by a well known contract that authorizes a minter in a different way
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     * @param rightsHolder_ account that will receive royalties
     * @param to_ address of the first receiver
     * @param verifiedAccount_ actual sender of the mint operation, verified by the external verifier
     * @param nonce nonce of signature
     * @return Id of the newly created token
     */
    function mintNewExternalVerifier(
        string memory tokenURI_,
        uint256 fee_,
        address rightsHolder_,
        address to_,
        address verifiedAccount_,
        uint256 nonce
    ) public virtual override returns (uint256) {
        uint256 tokenId = super.mintNewExternalVerifier(tokenURI_, fee_, rightsHolder_, to_, verifiedAccount_, nonce);
        _creator[tokenId] = verifiedAccount_;
        return tokenId;
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

import "./EnigmaUserToken721.sol";

contract EnigmaTicketCollection721 is EnigmaUserToken721 {
    uint256 private _disableTransfersStartDate;
    uint256 private _disableTransfersEndDate;
    mapping(uint256 => bool) public isTokenDisabled;

    /**
     * @notice Initialize TicketCollection NFT721 contract.
     *
     * @param name_ the token name
     * @param symbol_ the token symbol
     * @param tokenURIPrefix_ the token base uri
     * @param operator_ that will be able to mint tokens on behalf the owner
     * @param transferGatekeeperBeacon_ TransferGatekeeper beacon
     * @param disableTransfersStartDate_ the date transfers are no longer allowed
     * @param disableTransfersEndDate_ the date transfers are resumed
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory tokenURIPrefix_,
        address operator_,
        address transferGatekeeperBeacon_,
        uint256 disableTransfersStartDate_,
        uint256 disableTransfersEndDate_
    ) public initializer {
        super.initialize(name_, symbol_, tokenURIPrefix_, operator_, transferGatekeeperBeacon_);
        _disableTransfersStartDate = disableTransfersStartDate_;
        _disableTransfersEndDate = disableTransfersEndDate_;
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./BaseEnigmaNFT721.sol";
import "../vault/Vault.sol";

/// @title EnigmaUserToken721
///
/// @dev This contract extends from BaseEnigmaNFT721

contract EnigmaUserToken721 is BaseEnigmaNFT721 {
    address public operator;

    event OperatorChanged(address indexed newOperator);

    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner() || msg.sender == operator, "Not owner nor operator");
        _;
    }

    /// oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line
    constructor() initializer {}

    /**
     * @notice Initialize NFT721 contract.
     *
     * @param name_ the token name
     * @param symbol_ the token symbol
     * @param tokenURIPrefix_ the token base uri
     * @param operator_ that will be able to mint tokens on behalf the owner
     * @param transferGatekeeperBeacon_ TransferGatekeeper beacon
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory tokenURIPrefix_,
        address operator_,
        address transferGatekeeperBeacon_
    ) public initializer {
        super._initialize(name_, symbol_, tokenURIPrefix_);
        operator = operator_;
        transferGatekeeperBeacon = IBeacon(transferGatekeeperBeacon_);
    }

    /**
     * @notice For compatibility reasons this method is kept although it always returns the contract owner
     */
    function getCreator(uint256) public view virtual override returns (address) {
        return owner();
    }

    /**
     * @notice Let's the owner to update the operator
     * @param newOperator to set
     */
    function setOperator(address newOperator) external onlyOwner {
        operator = newOperator;
        emit OperatorChanged(newOperator);
    }

    /**
     * @notice Checks if operator contract has registered the passed signer address as a valid signer
     * @dev If Vault were to get refactored to avoid using an ACL then we wouldn't need to
     * get the SIGNER_ROLE hash, because we would assume that is the only possible role
     * @param signer address of the sellOrder signer.
     * @return Boolean representing if signer is registered as valid or not
     */
    function _hasOperatorPermission(address signer) internal view returns (bool) {
        if (operator == address(0)) return false;
        Vault operator_ = Vault(operator);
        bytes32 signerRole = operator_.SIGNER_ROLE();
        return operator_.hasRole(signerRole, signer);
    }

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     */
    function mintNew(string memory tokenURI_, uint256 fee_) external onlyOwnerOrOperator returns (uint256) {
        _mintNew(tokenURI_, fee_, msg.sender, msg.sender, 0, msg.sender);
    }

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     * @param rightsHolder_ account that will receive royalties
     * @param to_ address of the first receiver
     */
    function mintNewCustomized(
        string memory tokenURI_,
        uint256 fee_,
        address rightsHolder_,
        address to_
    ) public onlyOwnerOrOperator returns (uint256) {
        _mintNew(tokenURI_, fee_, rightsHolder_, to_, 0, msg.sender);
    }

    /**
     * @notice mint function that should be used by a well known contract that authorizes a minter in a different way
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     * @param rightsHolder_ account that will receive royalties
     * @param to_ address of the first receiver
     * @param verifiedAccount_ actual sender of the mint operation, verified by the external verifier
     * @param nonce nonce of signature
     * @return Id of the newly created token
     */
    function mintNewExternalVerifier(
        string memory tokenURI_,
        uint256 fee_,
        address rightsHolder_,
        address to_,
        address verifiedAccount_,
        uint256 nonce
    ) public virtual override onlyExternalVerifier returns (uint256) {
        // If verifiedAccount (order signer) is the owner address, operator address, or has permission by Vault
        // then they can mint
        require(
            owner() == verifiedAccount_ || verifiedAccount_ == operator || _hasOperatorPermission(verifiedAccount_),
            "EnigmaUserToken721: Not authorized to mint"
        );
        return super.mintNewExternalVerifier(tokenURI_, fee_, rightsHolder_, to_, verifiedAccount_, nonce);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 is IERC165Upgradeable {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

abstract contract IExternalVerifiedMinting {
    /**
     * @notice Add or remove an external authorizer
     * @dev This function is idempotent and unprotected.
     */
    function setExternalVerifier(address externalVerifier_, bool isAuthorized_) external virtual;

    /**
     * @notice Add or remove an external authorizer
     * @dev This function is idempotent and unprotected.
     */
    function isExternalVerifier(address externalVerifier_) public view virtual returns (bool);
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./IERC2981.sol";

interface IRoyaltyAwareNFT is IERC2981 {
    /**
     * @notice Get the creator of given tokenID.
     * @param tokenId ID of the Token.
     * @return creator of given ID.
     */
    function getCreator(uint256 tokenId) external view virtual returns (address);

    /**
     * @notice Get the rights holder (the one to receive royalties) of given tokenID.
     * @param tokenId ID of the Token.
     * @return rights holder of given ID.
     */
    function rightsHolder(uint256 tokenId) external view virtual returns (address);

    /**
     * @notice Updates the rights holder for a specific tokenId
     * @param tokenId ID of the Token.
     * @param newRightsHolder new rights holderof given ID.
     * @dev Rights holder should only be set by the token creator
     */
    function setRightsHolder(uint256 tokenId, address newRightsHolder) external virtual;

    /**
     * @notice Kind of like an initializer for the upgrade where we support ERC2981
     */
    function declareERC2981Interface() external virtual;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/// @title ITransferGatekeeper
/// @notice an interface that allows an asset transfer to be guard.

interface ITransferGatekeeper {
    /**
     * @param _from the address that owns what's being transfered
     * @param _to the address that would receive what's being transfered
     * @param _proxy the address that wants to transfer
     * @param _data any other aditional data that might be relevant to allow/block the transfer
     * @dev Returns true if this transfer is allowed under current context
     */
    function canTransfer(
        address _from,
        address _to,
        address _proxy,
        bytes memory _data
    ) external view returns (bool);
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

interface ITransferProxy {
    function erc721safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external;

    function erc1155safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function erc20safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) external;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/// All the whitelists logics that want to be used in the NFTs contracts must implement this interface.
///
/// By implementing this interface, can be transfered.
///

interface IWhitelist {
    /**
     * @param _who the address that wants to transfer a NFT
     * @dev Returns true if address has permission to transfer a NFT
     */
    function canTransfer(address _who) external view returns (bool);
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;
import "./IWhitelist.sol";

/// @title IWhitelistHandler

interface IWhitelistHandler {
    /**
     * @param _whitelist the contract that implements IWhitelist
     */
    function setWhitelist(IWhitelist _whitelist) external;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title IWyvernProxyRegistry
 * @author Wyvern Protocol Developers
 */
interface IWyvernProxyRegistry {
    /**
     * Returns The Wyvern Proxy for the given owner
     * @param owner the owner of the Proxy
     * @dev based on Apr '22 https://github.com/wyvernprotocol/wyvern-v3
     */
    function proxies(address owner) external view returns (address);
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721HolderUpgradeable.sol";
import "../interfaces/ITransferProxy.sol";
import "./NFTMarketReserveAuction.sol";
import "./TradeV4.sol";

/// @title EnigmaMarket
///
/// @dev This contract is a Transparent Upgradable based in openZeppelin v3.4.0.
///         Be careful when upgrade, you must respect the same storage.

contract EnigmaMarket is
    TradeV4, // Direct sales
    ERC721HolderUpgradeable, // Make sure the contract is able to use its
    NFTMarketReserveAuction
{
    // Though the TradeV4 contract is upgradeable, we still have to initialize the implementation through the
    // constructor. This is because we chose to import the non upgradeable EIP712 as it does not have storage
    // variable(which actually makes it upgradeable) as it only uses immmutable variables. This has several advantages:
    // - We can import it without worrying the storage layout
    // - Is more efficient as there is no need to read from the storage
    // Note: The cache mechanism will NOT be used here as the address will differ from the one calculated in the
    // constructor due to the fact that when the contract is operating we will be using delegatecall, meaningn
    // that the address will be the one from the proxy as opposed to the implementation's during the
    // constructor execution
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory version) TradeV4(name, version) {}

    /**
     * @notice Called once to configure the contract after the initial proxy deployment.
     * @dev This farms the initialize call out to inherited contracts as needed to initialize mutable variables.
     * @param _transferProxy the proxy from wich all NFT transfers are gonna be processed from.
     * @param _enigmaNFT721Address Enigma ERC721 NFT proxy.
     * @param _enigmaNFT1155Address Enigma ERC1155 NFT proxy.
     * @param _custodialAddress The address on wich NFTs are gonna be kept during Fiat Trades.
     * @param _minDuration The min duration for auctions, in seconds.
     * @param _maxDuration The max duration for auctions, in seconds.
     * @param _minIncrementPermille The minimum required when making an offer or placing a bid. Ej: 100 => 0.1 => 10%
     */
    function fullInitialize(
        ITransferProxy _transferProxy,
        address _enigmaNFT721Address,
        address _enigmaNFT1155Address,
        address _custodialAddress,
        uint256 _minDuration,
        uint256 _maxDuration,
        uint16 _minIncrementPermille
    ) external initializer {
        initializeTradeV4(_transferProxy, _enigmaNFT721Address, _enigmaNFT1155Address, _custodialAddress);
        __Ownable_init();
        __ReentrancyGuard_init();
        _initializeNFTMarketAuction();
        _initializeNFTMarketReserveAuction(_minDuration, _maxDuration);
        _initializeNFTMarketCore(_minIncrementPermille);
    }

    /**
     * @notice Called once to configure the contract after the initial proxy deployment.
     * @dev as we are updating an already deployed contracts, legacy vars don't need init.
     * @param _minDuration The min duration for auctions, in seconds.
     * @param _maxDuration The max duration for auctions, in seconds.
     */
    function upgradeInitialize(uint256 _minDuration, uint256 _maxDuration) external onlyOwner {
        _initializeNFTMarketAuction();
        _initializeNFTMarketReserveAuction(_minDuration, _maxDuration);
    }

    function getPlatformTreasury() public view returns (address payable) {
        // TODO: review if we don't need a new field for collecting fees
        return payable(owner());
    }

    /**
     * @inheritdoc NFTMarketCore
     */
    function _transferFromEscrow(
        address nftContract,
        uint256 tokenId,
        address recipient
    ) internal virtual override {
        // As we are transfering through our own market, there's no need to go by transferProxy
        IERC721(nftContract).transferFrom(address(this), recipient, tokenId);
    }

    /**
     * @inheritdoc NFTMarketCore
     */
    function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual override {
        safeTransferFrom(AssetType.ERC721, msg.sender, address(this), nftContract, tokenId, 1);
    }

    /**
     * @dev Be careful when invoking this function as reentrancy guard should be put in place
     */
    // slither-disable-next-line reentrancy-eth
    function _distFunds(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        address payable seller,
        uint256 sellerFeesPerMille,
        uint256 buyerFeesPerMille
    )
        internal
        override
        returns (
            uint256 platformFee,
            uint256 royaltyFee,
            uint256 assetFee
        )
    {
        // Disable slither warning because it's only invoked from functions with nonReentrant checks
        FeeDistributionData memory feeDistributionData =
            getFees(amount, nftContract, tokenId, sellerFeesPerMille, buyerFeesPerMille, seller);
        _sendValueWithFallbackWithdraw(
            getPlatformTreasury(),
            feeDistributionData.fees.platformFee,
            SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT
        );

        if (feeDistributionData.toRightsHolder > 0) {
            _sendValueWithFallbackWithdraw(
                payable(feeDistributionData.rightsHolder),
                feeDistributionData.toRightsHolder,
                SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT
            );
        }

        if (feeDistributionData.toSeller > 0) {
            _sendValueWithFallbackWithdraw(seller, feeDistributionData.toSeller, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
        }

        return (
            feeDistributionData.fees.platformFee,
            feeDistributionData.fees.royaltyFee,
            feeDistributionData.fees.assetFee
        );
    }

    /**
     * @notice Creates an auction for the given NFT.
     * The NFT is held in escrow until the auction is finalized or canceled.
     * buyer and seller fees are locked at creation time
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param duration seconds for how long an auction lasts for once the first bid has been received.
     * @param reservePrice The initial reserve price for the auction.
     */
    function createReserveAuctionFor(
        address nftContract,
        uint256 tokenId,
        uint256 duration,
        uint256 reservePrice,
        uint256 amount,
        PlatformFees calldata platformFees
    ) internal override {
        verifyPlatformFeesSignature(platformFees, owner());
        NFTMarketReserveAuction.createReserveAuctionFor(
            nftContract,
            tokenId,
            duration,
            reservePrice,
            amount,
            platformFees
        );
    }

    /*********************
     ** PUBLIC FUNCTIONS *
     *********************/

    /**
     * @notice Creates an auction for the given NFT.
     * The NFT is held in escrow until the auction is finalized or canceled.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param duration seconds for how long an auction lasts for once the first bid has been received.
     * @param reservePrice The initial reserve price for the auction.
     */
    function createReserveAuction(
        address nftContract,
        uint256 tokenId,
        uint256 duration,
        uint256 reservePrice,
        PlatformFees calldata platformFees
    ) external nonReentrant onlyValidAuctionConfig(reservePrice) {
        // get the amount, including buyer fees for this reserve price
        uint256 amount = applyBuyerFee(reservePrice, platformFees.buyerFeePermille);
        createReserveAuctionFor(nftContract, tokenId, duration, reservePrice, amount, platformFees);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.6;

/// @dev Taken from https://github.com/f8n/fnd-protocol/tree/v2.0.3

/**
 * @title An abstraction layer for auctions.
 * @dev This contract can be expanded with reusable calls and data as more auction types are added.
 */
abstract contract NFTMarketAuction {
    /**
     * @dev A global id for auctions of any type.
     */
    uint256 private nextAuctionId;

    /**
     * @notice Called once to configure the contract after the initial proxy deployment.
     * @dev This sets the initial auction id to 1, making the first auction cheaper
     * and id 0 represents no auction found.
     */
    function _initializeNFTMarketAuction() internal {
        nextAuctionId = 1;
    }

    /**
     * @notice Returns id to assign to the next auction.
     */
    function _getNextAndIncrementAuctionId() internal returns (uint256) {
        // AuctionId cannot overflow 256 bits.
        return nextAuctionId++;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.7.6;

/// @dev Taken from https://github.com/f8n/fnd-protocol/tree/v2.0.3

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "./TradeV4.sol";

/**
 * @title A place for common modifiers and functions used by various NFTMarket mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 */
abstract contract NFTMarketCore is OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    /// @notice Emitted when owner has updated the minIncrementPermille
    event MinIncrementPermilleUpdated(uint16 prevValue, uint16 newValue);

    /// @dev The minimum required when making an offer or placing a bid. Ej: 100 => 0.1 => 10%
    uint16 public minIncrementPermille;

    /**
     * @param _minIncrementPermille The increment to outbid. Ej: 100 => 0.1 => 10%
     */
    function _initializeNFTMarketCore(uint16 _minIncrementPermille) internal {
        minIncrementPermille = _minIncrementPermille;
    }

    function setMinIncrementPermille(uint16 _minIncrementPermille) external onlyOwner {
        emit MinIncrementPermilleUpdated(minIncrementPermille, _minIncrementPermille);
        minIncrementPermille = _minIncrementPermille;
    }

    /**
     * @notice Transfers the NFT from escrow and clears any state tracking this escrowed NFT.
     */
    function _transferFromEscrow(
        address nftContract,
        uint256 tokenId,
        address recipient
    ) internal virtual;

    /**
     * @notice Transfers an NFT into escrow
     */
    function _transferToEscrow(address nftContract, uint256 tokenId) internal virtual;

    /**
     * @notice Applies fees and distributes funds for a finalized market operation.
     * For all creator, platforma and seller.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param amount Reserve price, plus buyerFee.
     * @param seller The address of the seller.
     * @return platformFee Platform share total from the sale, both taken from the buyer and seller
     * @return royaltyFee Rayalty fee distributed to owner/s
     * @return assetFee Total received bu the saller
     */
    function _distFunds(
        address nftContract,
        uint256 tokenId,
        uint256 amount,
        address payable seller,
        uint256 sellerFeesPerMille,
        uint256 buyerFeesPerMille
    )
        internal
        virtual
        returns (
            uint256 platformFee,
            uint256 royaltyFee,
            uint256 assetFee
        );

    /**
     * @notice For a given price and fee, it returns the total amount a buyer must provide to cover for both
     * @param _price the target price
     * @param _buyerFeePermille the fee taken from the buyer, expressed in *1000 (ej: 10% = 0.1 => 100)
     * @return amount the buyer must sent to comply to this price and fees
     */
    function applyBuyerFee(uint256 _price, uint8 _buyerFeePermille) internal pure returns (uint256 amount) {
        if (_buyerFeePermille == 0) {
            amount = _price;
        } else {
            amount = _price.add(_price.mul(_buyerFeePermille).div(1000));
        }
    }

    /**
     * @dev Determines the minimum amount when increasing an existing offer or bid.
     */
    function _getMinIncrement(uint256 currentAmount) internal view returns (uint256) {
        uint256 minIncrement = currentAmount.mul(minIncrementPermille).div(1000);
        if (minIncrement == 0) {
            // Since minIncrement reduces from the currentAmount, this cannot overflow.
            // The next amount must be at least 1 wei greater than the current.
            return currentAmount + 1;
        }

        return minIncrement + currentAmount;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/// @dev Taken from https://github.com/f8n/fnd-protocol/tree/v2.0.3

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "./NFTMarketAuction.sol";
import "./NFTMarketCore.sol";
import "./SendValueWithFallbackWithdraw.sol";

// The gas limit to send ETH to a single recipient, enough for a contract with a simple receiver.
uint256 constant SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT = 20000;

// solhint-disable max-line-length
string constant ReserveAuction_Already_Listed = "ReserveAuction_Already_Listed";
string constant ReserveAuction_Bid_Must_Be_At_Least_Min_Amount = "ReserveAuction_Bid_Must_Be_At_Least_Min_Amount";
string constant ReserveAuction_Cannot_Admin_Cancel_Without_Reason = "ReserveAuction_Cannot_Admin_Cancel_Without_Reason";
string constant ReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price = "ReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price";
string constant ReserveAuction_Cannot_Bid_On_Ended_Auction = "ReserveAuction_Cannot_Bid_On_Ended_Auction";
string constant ReserveAuction_Cannot_Bid_On_Nonexistent_Auction = "ReserveAuction_Cannot_Bid_On_Nonexistent_Auction";
string constant ReserveAuction_Cannot_Cancel_Nonexistent_Auction = "ReserveAuction_Cannot_Cancel_Nonexistent_Auction";
string constant ReserveAuction_Cannot_Finalize_Already_Settled_Auction = "ReserveAuction_Cannot_Finalize_Already_Settled_Auction";
string constant ReserveAuction_Cannot_Finalize_Auction_In_Progress = "ReserveAuction_Cannot_Finalize_Auction_In_Progress";
string constant ReserveAuction_Cannot_Rebid_Over_Outstanding_Bid = "ReserveAuction_Cannot_Rebid_Over_Outstanding_Bid";
string constant ReserveAuction_Cannot_Update_Auction_In_Progress = "ReserveAuction_Cannot_Update_Auction_In_Progress";
string constant ReserveAuction_Subceeds_Min_Duration = "ReserveAuction_Subceeds_Min_Duration";
string constant ReserveAuction_Exceeds_Max_Duration = "ReserveAuction_Exceeds_Max_Duration";
string constant ReserveAuction_Less_Than_Extension_Duration = "ReserveAuction_Less_Than_Extension_Duration";
string constant ReserveAuction_Must_Set_Non_Zero_Reserve_Price = "ReserveAuction_Must_Set_Non_Zero_Reserve_Price";
string constant ReserveAuction_Not_Matching_Bidder = "ReserveAuction_Not_Matching_Bidder";
string constant ReserveAuction_Only_Owner_Can_Update_Auction = "ReserveAuction_Only_Owner_Can_Update_Auction";
string constant ReserveAuction_Price_Already_Set = "ReserveAuction_Price_Already_Set";

// solhint-enable max-line-length

/**
 * @title Allows the owner of an NFT to list it in auction.
 * @notice NFTs in auction are escrowed in the market contract.
 */
abstract contract NFTMarketReserveAuction is
    ReentrancyGuardUpgradeable,
    NFTMarketCore,
    NFTMarketAuction,
    SendValueWithFallbackWithdraw
{
    // Stores the auction configuration for a specific NFT.
    struct ReserveAuction {
        // The address of the NFT contract.
        address nftContract;
        // The id of the NFT.
        uint256 tokenId;
        // The owner of the NFT which listed it in auction.
        address payable seller;
        // The duration for this auction.
        uint256 duration;
        // The extension window for this auction.
        uint256 extensionDuration;
        // The time at which this auction will not accept any new bids.
        // @dev This is `0` until the first bid is placed.
        uint256 endTime;
        // The current highest bidder in this auction.
        // @dev This is `address(0)` until the first bid is placed.
        address payable bidder;
        // The latest amount locked in for this auction. Includes buyerFee.
        // @dev This is set to the reserve price + buyerFee, and then to the highest bid once the auction has started.
        uint256 amount;
        // The buyerFee at the moment the auction was created. Expressed as x1000 (ej: 100 => 10% = 0.1)
        uint8 buyerFeePermille;
        // The sellerFee at the moment the auction was created. Expressed as x1000 (ej: 100 => 10% = 0.1)
        uint8 sellerFeePermille;
    }

    /// @dev The auction configuration for a specific auction id.
    mapping(address => mapping(uint256 => uint256)) internal nftContractToTokenIdToAuctionId;

    /// @dev The auction id for a specific NFT.
    /// @dev This is deleted when an auction is finalized or canceled.
    mapping(uint256 => ReserveAuction) internal auctionIdToAuction;

    /// @dev Minimal value for how long an auction can lasts for once the first bid has been received.
    uint256 internal minDuration;

    /// @dev Maximal value for how long an auction can lasts for once the first bid has been received.
    uint256 internal maxDuration;

    /// @dev The window for auction extensions, any bid placed in the final 15 minutes
    /// of an auction will reset the time remaining to 15 minutes.
    uint256 internal constant EXTENSION_DURATION = 15 minutes;

    /// @dev Caps the max duration that may be configured so that overflows will not occur.
    uint256 internal constant MAX_MAX_DURATION = 1000 days;

    /**
     * @notice Emitted when a bid is placed.
     * @param auctionId The id of the auction this bid was for.
     * @param bidder The address of the bidder.
     * @param amount The amount of the bid.
     * @param endTime The new end time of the auction (which may have been set or extended by this bid).
     */
    event ReserveAuctionBidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 endTime);
    /**
     * @notice Emitted when an auction is cancelled.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was cancelled.
     */
    event ReserveAuctionCanceled(uint256 indexed auctionId);
    /**
     * @notice Emitted when an auction is canceled by a Enigma admin.
     * @dev When this occurs, the highest bidder (if there was a bid) is automatically refunded.
     * @param auctionId The id of the auction that was cancelled.
     * @param reason The reason for the cancellation.
     */
    event ReserveAuctionCanceledByAdmin(uint256 indexed auctionId, string reason);
    /**
     * @notice Emitted when an NFT is listed for auction.
     * @param seller The address of the seller.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param duration The duration of the auction (always 24-hours).
     * @param extensionDuration The duration of the auction extension window (always 15-minutes).
     * @param reservePrice The reserve price to kick off the auction.
     * @param bidAmount Reserve price, plus buyerFee. Min amount required to win this auction.
     * @param auctionId The id of the auction that was created.
     */
    event ReserveAuctionCreated(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 duration,
        uint256 extensionDuration,
        uint256 reservePrice,
        uint256 bidAmount,
        uint256 auctionId
    );
    /**
     * @notice Emitted when an auction that has already ended is finalized,
     * indicating that the NFT has been transferred and revenue from the sale distributed.
     * @dev The amount of the highest bid / final sale price for this auction is `f8nFee` + `creatorFee` + `ownerRev`.
     * @param auctionId The id of the auction that was finalized.
     * @param seller The address of the seller.
     * @param bidder The address of the highest bidder that won the NFT.
     * @param platformFee The amount of ETH that was sent to Enigma for this sale.
     * @param royaltyFee The amount of ETH that was sent to the creator for this sale.
     * @param sellerRev The amount of ETH that was sent to the sellet for this NFT.
     */
    event ReserveAuctionFinalized(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed bidder,
        uint256 platformFee,
        uint256 royaltyFee,
        uint256 sellerRev
    );
    /**
     * @notice Emitted when the auction's reserve price is changed.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was updated.
     * @param reservePrice The new reserve price for the auction.
     */
    event ReserveAuctionUpdated(uint256 indexed auctionId, uint256 reservePrice);

    /// @notice Confirms that the reserve price is not zero.
    modifier onlyValidAuctionConfig(uint256 reservePrice) {
        if (reservePrice == 0) {
            revert(ReserveAuction_Must_Set_Non_Zero_Reserve_Price);
        }
        _;
    }

    /// oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line
    constructor() {}

    /**
     * @notice Configures the duration for auctions.
     * @param _minDuration The min duration for auctions, in seconds.
     * @param _maxDuration The max duration for auctions, in seconds.
     */
    function _initializeNFTMarketReserveAuction(uint256 _minDuration, uint256 _maxDuration) internal {
        if (_maxDuration > MAX_MAX_DURATION) {
            // This ensures that math in this file will not overflow due to a huge duration.
            revert(ReserveAuction_Exceeds_Max_Duration);
        }
        if (_minDuration < EXTENSION_DURATION) {
            // The auction duration configuration must be greater than the extension window of 15 minutes
            revert(ReserveAuction_Less_Than_Extension_Duration);
        }
        minDuration = _minDuration;
        maxDuration = _maxDuration;
    }

    /**
     * @notice Creates an auction for the given NFT.
     * The NFT is held in escrow until the auction is finalized or canceled.
     * buyer and seller fees are locked at creation time
     * @dev IMPORTANT! The platform fees are assumed to be authenticated, otherwise this may cause security issues
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param duration seconds for how long an auction lasts for once the first bid has been received.
     * @param reservePrice The initial reserve price for the auction.
     */
    function createReserveAuctionFor(
        address nftContract,
        uint256 tokenId,
        uint256 duration,
        uint256 reservePrice,
        uint256 amount,
        PlatformFees calldata platformFees
    ) internal virtual {
        uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
        if (auctionId == 0) {
            // NFT is not in auction
            // If the `msg.sender` is not the owner of the NFT, transferring into escrow should fail.
            _transferToEscrow(nftContract, tokenId);
        } else {
            // Using storage saves gas since most of the data is not needed
            ReserveAuction storage auction = auctionIdToAuction[auctionId];
            if (auction.endTime == 0) {
                revert(ReserveAuction_Already_Listed);
            } else {
                // Auction in progress, confirm the highest bidder is a match
                if (auction.bidder != msg.sender) {
                    revert(ReserveAuction_Not_Matching_Bidder);
                }

                // Finalize auction but leave NFT in escrow, reverts if the auction has not ended
                _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: true });
            }
        }
        // Get the new Id
        auctionId = _getNextAndIncrementAuctionId();

        // This checks if duration is between acceptable
        if (minDuration > duration) {
            revert(ReserveAuction_Subceeds_Min_Duration);
        }
        if (duration > maxDuration) {
            revert(ReserveAuction_Exceeds_Max_Duration);
        }

        // Store the auction details
        nftContractToTokenIdToAuctionId[nftContract][tokenId] = auctionId;
        auctionIdToAuction[auctionId] = ReserveAuction(
            nftContract,
            tokenId,
            payable(msg.sender),
            duration,
            EXTENSION_DURATION,
            0, // endTime is only known once the reserve price is met
            payable(0), // bidder is only known once a bid has been placed
            amount,
            platformFees.buyerFeePermille, // fees are locked-in at create time
            platformFees.sellerFeePermille
        );

        emit ReserveAuctionCreated(
            msg.sender,
            nftContract,
            tokenId,
            duration,
            EXTENSION_DURATION,
            reservePrice,
            amount,
            auctionId
        );
    }

    /**
     * @notice Once the countdown has expired for an auction, anyone can settle the auction.
     * This will send the NFT to the highest bidder and distribute revenue for this sale.
     * @param auctionId The id of the auction to settle.
     */
    function finalizeReserveAuction(uint256 auctionId) external nonReentrant {
        if (auctionIdToAuction[auctionId].endTime == 0) {
            revert(ReserveAuction_Cannot_Finalize_Already_Settled_Auction);
        }
        _finalizeReserveAuction({ auctionId: auctionId, keepInEscrow: false });
    }

    /**
     * @notice Settle an auction that has already ended.
     * This will send the NFT to the highest bidder and distribute revenue for this sale.
     * @param keepInEscrow If true, the NFT will be kept in escrow to save gas by avoiding
     * redundant transfers if the NFT should remain in escrow, such as when the new owner
     * sets a buy price or lists it in a new auction.
     */
    function _finalizeReserveAuction(uint256 auctionId, bool keepInEscrow) internal {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];

        if (auction.endTime >= block.timestamp) {
            revert(ReserveAuction_Cannot_Finalize_Auction_In_Progress);
        }

        // Remove the auction.
        delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
        delete auctionIdToAuction[auctionId];

        if (!keepInEscrow) {
            // The seller was authorized when the auction was originally created
            _transferFromEscrow(auction.nftContract, auction.tokenId, auction.bidder);
        }

        // Distribute revenue for this sale.
        (uint256 platformFee, uint256 royaltyFee, uint256 assetFee) = _distAuctionFunds(auction);

        emit ReserveAuctionFinalized(auctionId, auction.seller, auction.bidder, platformFee, royaltyFee, assetFee);
    }

    function _distAuctionFunds(ReserveAuction memory auction)
        internal
        returns (
            uint256 platformFee,
            uint256 royaltyFee,
            uint256 assetFee
        )
    {
        return
            _distFunds(
                auction.nftContract,
                auction.tokenId,
                auction.amount,
                auction.seller,
                auction.sellerFeePermille,
                auction.buyerFeePermille
            );
    }

    /**
     * @notice Allows Enigma to cancel an auction, refunding the bidder and returning the NFT to
     * the seller (if not active buy price set).
     * This should only be used for extreme cases such as DMCA takedown requests.
     * @param auctionId The id of the auction to cancel.
     * @param reason The reason for the cancellation (a required field).
     */
    function adminCancelReserveAuction(uint256 auctionId, string calldata reason) external onlyOwner nonReentrant {
        if (bytes(reason).length == 0) {
            revert(ReserveAuction_Cannot_Admin_Cancel_Without_Reason);
        }
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        if (auction.amount == 0) {
            revert(ReserveAuction_Cannot_Cancel_Nonexistent_Auction);
        }

        delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
        delete auctionIdToAuction[auctionId];

        // Return the NFT to the owner.
        _transferFromEscrow(auction.nftContract, auction.tokenId, auction.seller);

        if (auction.bidder != address(0)) {
            // Refund the highest bidder if any bids were placed in this auction.
            _sendValueWithFallbackWithdraw(auction.bidder, auction.amount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
        }

        emit ReserveAuctionCanceledByAdmin(auctionId, reason);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
     * @dev The NFT is transferred back to the owner unless there is still a buy price set.
     * @param auctionId The id of the auction to cancel.
     */
    function cancelReserveAuction(uint256 auctionId) external nonReentrant {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        if (auction.amount == 0) {
            revert(ReserveAuction_Cannot_Cancel_Nonexistent_Auction);
        }
        if (auction.seller != msg.sender) {
            revert(ReserveAuction_Only_Owner_Can_Update_Auction);
        }
        if (auction.endTime != 0) {
            revert(ReserveAuction_Cannot_Update_Auction_In_Progress);
        }

        // Remove the auction.
        delete nftContractToTokenIdToAuctionId[auction.nftContract][auction.tokenId];
        delete auctionIdToAuction[auctionId];

        // Transfer the NFT.
        _transferFromEscrow(auction.nftContract, auction.tokenId, auction.seller);

        emit ReserveAuctionCanceled(auctionId);
    }

    /**
     * @notice Place a bid in an auction.
     * A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
     * If this is the first bid on the auction, the countdown will begin.
     * If there is already an outstanding bid, the previous bidder will be refunded at this time
     * and if the bid is placed in the final moments of the auction, the countdown may be extended.
     * @param auctionId The id of the auction to bid on.
     */
    /* solhint-disable-next-line code-complexity */
    function placeBid(uint256 auctionId) external payable nonReentrant {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];

        if (auction.amount == 0) {
            // No auction found
            revert(ReserveAuction_Cannot_Bid_On_Nonexistent_Auction);
        }

        uint256 endTime = auction.endTime;
        if (endTime == 0) {
            // This is the first bid, kicking off the auction.

            if (msg.value < auction.amount) {
                // The bid must be >= the reserve price.
                revert(ReserveAuction_Cannot_Bid_Lower_Than_Reserve_Price);
            }

            // Store the bid details.
            auction.amount = msg.value;
            auction.bidder = payable(msg.sender);

            // On the first bid, set the endTime to now + duration.
            // Duration is always less than MAX MAX, so the below can't overflow.
            endTime = block.timestamp + auction.duration;

            auction.endTime = endTime;
        } else {
            if (endTime < block.timestamp) {
                // The auction has already ended.
                revert(ReserveAuction_Cannot_Bid_On_Ended_Auction);
            } else if (auction.bidder == msg.sender) {
                // We currently do not allow a bidder to increase their bid unless another user has outbid them first.
                revert(ReserveAuction_Cannot_Rebid_Over_Outstanding_Bid);
            } else {
                uint256 minIncrement = _getMinIncrement(auction.amount);
                if (msg.value < minIncrement) {
                    // If this bid outbids another, it must be at least 10% greater than the last bid.
                    revert(ReserveAuction_Bid_Must_Be_At_Least_Min_Amount);
                }
            }

            // Cache and update bidder state
            uint256 originalAmount = auction.amount;
            address payable originalBidder = auction.bidder;
            auction.amount = msg.value;
            auction.bidder = payable(msg.sender);

            // When a bid outbids another, check to see if a time extension should apply.
            // We confirmed that the auction has not ended, so endTime is always >= the current timestamp.
            // Current time plus extension duration (always 15 mins) cannot overflow.
            uint256 endTimeWithExtension = block.timestamp + EXTENSION_DURATION;
            if (endTime < endTimeWithExtension) {
                endTime = endTimeWithExtension;
                auction.endTime = endTime;
            }
            // Refund the previous bidder
            _sendValueWithFallbackWithdraw(originalBidder, originalAmount, SEND_VALUE_GAS_LIMIT_SINGLE_RECIPIENT);
        }
        emit ReserveAuctionBidPlaced(auctionId, msg.sender, msg.value, endTime);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the reservePrice may be
     * changed by the seller.
     * @param auctionId The id of the auction to change.
     * @param reservePrice The new reserve price for this auction.
     */
    function updateReserveAuction(uint256 auctionId, uint256 reservePrice)
        external
        onlyValidAuctionConfig(reservePrice)
    {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        if (auction.seller != msg.sender) {
            revert(ReserveAuction_Only_Owner_Can_Update_Auction);
        } else if (auction.endTime != 0) {
            revert(ReserveAuction_Cannot_Update_Auction_In_Progress);
        }

        // get the amount, including buyer fee for this reserve price
        uint256 amount = applyBuyerFee(reservePrice, auction.buyerFeePermille);
        if (auction.amount == amount) revert(ReserveAuction_Price_Already_Set);

        // Update the current reserve price.
        auction.amount = amount;

        emit ReserveAuctionUpdated(auctionId, reservePrice);
    }

    /**
     * @notice Returns the minimum amount a bidder must spend to participate in an auction.
     * Bids must be greater than or equal to this value or they will revert.
     * @param auctionId The id of the auction to check.
     * @return minimum The minimum amount for a bid to be accepted.
     */
    function getMinBidAmount(uint256 auctionId) external view returns (uint256 minimum) {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        if (auction.endTime == 0) {
            return auction.amount;
        }
        return _getMinIncrement(auction.amount);
    }

    /**
     * @notice Returns auction details for a given auctionId.
     * @param auctionId The id of the auction to lookup.
     * @return auction The auction details.
     */
    function getReserveAuction(uint256 auctionId) external view returns (ReserveAuction memory auction) {
        return auctionIdToAuction[auctionId];
    }

    /**
     * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
     * @dev If an auction is canceled, it will not be returned. However the auction may be over
     *  and pending finalization.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @return auctionId The id of the auction, or 0 if no auction is found.
     */
    function getReserveAuctionIdFor(address nftContract, uint256 tokenId) external view returns (uint256 auctionId) {
        auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

/// @dev Taken from https://github.com/f8n/fnd-protocol/tree/v2.0.3

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

pragma solidity ^0.7.6;

/**
 * @title A mixin for sending ETH with a fallback withdraw mechanism.
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * in the pendingWithdrawals for future withdrawal instead.
 */
abstract contract SendValueWithFallbackWithdraw is OwnableUpgradeable {
    /// @dev Tracks the amount of ETH that is stored in escrow for future withdrawal.
    mapping(address => uint256) internal pendingWithdrawals;

    /**
     * @notice Emitted when escrowed funds are withdrawn.
     * @param executor The account which has withdrawn ETH, either the owner or an Admin.
     * @param owner The owner whose ETH has been withdrawn from.
     * @param recipient The address where the funds were transfered to.
     * @param amount The amount of ETH which has been withdrawn.
     */
    event PendingWithdrawalCompleted(
        address indexed executor,
        address indexed owner,
        address recipient,
        uint256 amount
    );

    /**
     * @notice Emitted when escrowed funds are deposite into pending Withdrawals.
     * @param owner The owner whose ETH has been deposit.
     * @param amount The amount of ETH which has been deposit.
     */
    event PendingWithdrawalDeposit(address indexed owner, uint256 amount);

    /**
     * @dev Attempt to send a user or contract ETH and
     * if it fails store the amount owned for later withdrawal .
     *  @dev This function doesn't check for reentrancy issues so be careful when invoking
     */
    function _sendValueWithFallbackWithdraw(
        address payable user,
        uint256 amount,
        uint256 gasLimit
    ) internal {
        if (amount == 0) {
            return;
        }
        // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = user.call{ value: amount, gas: gasLimit }("");
        if (!success) {
            // Store the funds that failed to send for the user pendingWithdrawals list
            pendingWithdrawals[user] += amount;
            emit PendingWithdrawalDeposit(user, amount);
        }
    }

    function _withdrawTo(address from, address payable recipient) internal {
        uint256 pendingAmount = pendingWithdrawals[from];
        if (pendingAmount != 0) {
            // No reentrancy is possible
            pendingWithdrawals[from] = 0;
            (bool success, ) = recipient.call{ value: pendingAmount }("");
            require(success, "withdrawal failed");
            emit PendingWithdrawalCompleted(msg.sender, from, recipient, pendingAmount);
        }
    }

    /**
     * @notice Allows owner to widthawl pending funds (on failed sale send).
     * @param recipient The address to sent the locked funds to.
     */
    function withdrawTo(address payable recipient) public {
        _withdrawTo(msg.sender, recipient);
    }

    /**
     * @notice Allows Enigma to widthawl pending funds (on failed sale send) on behalf of a user.
     * This should only be used for extreme cases when the user has prove unintended funds locked up.
     * @param fundsOwner The user address holding the pending funds.
     * @param recipient The address to sent the locked funds to.
     */
    function adminWithdrawTo(address fundsOwner, address payable recipient) external onlyOwner {
        _withdrawTo(fundsOwner, recipient);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[500] private __gap;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";
import "./utils/TradeSignaturesVerifier.sol";
import "../utils/AuthorizationBitmap.sol";
import "../utils/Types.sol";
import "../interfaces/ITransferProxy.sol";
import "../interfaces/IRoyaltyAwareNFT.sol";
import "../ERC721/BaseEnigmaNFT721.sol";
import "../ERC1155/BaseEnigmaNFT1155.sol";

/// @title TradeV4
///
/// @dev This contract is a Transparent Upgradable based in openZeppelin v3.4.0.
///         Be careful when upgrade, you must respect the same storage.

abstract contract TradeV4 is ReentrancyGuardUpgradeable, OwnableUpgradeable, TradeSignaturesVerifier {
    using SafeMathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    event SellerFee(uint8 sellerFee);
    event BuyerFee(uint8 buyerFee);
    event CustodialAddressChanged(address prevAddress, address newAddress);
    event BuyAsset(
        address indexed assetOwner,
        address paymentReceiver,
        address indexed tokenReceiver,
        address paymentSender,
        address assetAddress,
        AssetType assetType,
        uint256 indexed tokenId,
        uint256 quantity,
        uint256 nonce,
        bool mintTokens
    );
    event ExecuteBid(address indexed assetOwner, uint256 indexed tokenId, uint256 quantity, address indexed buyer);
    event TokenWithdraw(address indexed assetOwner, uint256 indexed nonce, uint256 indexed tokenId, uint256 quantity);

    /// @dev deprecated
    uint8 internal _buyerFeePermille;
    /// @dev deprecated
    uint8 internal _sellerFeePermille;
    ITransferProxy public transferProxy;
    address public enigmaNFT721Address;
    address public enigmaNFT1155Address;
    // Address that acts as custodial for platform hold NFTs,
    address public custodialAddress;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // This is a packed array of booleans, to track processed authorizations
    mapping(uint256 => uint256) internal processedAuthorizationsBitMap;

    // This mapping uses as input the address of the seller and the nonce
    // to avoid an order being oversold in multiple sells.
    // It is assumed that the user will for every order use a different order
    // If it does not, it will create an undefined behaviour over its own tokens
    // meaning that even in the worst case scenario, it will only sell its own tokens
    mapping(address => mapping(uint256 => uint256)) internal amountSold;

    // This tracks the id of an order to mintAndSell(lazy mint).
    // It uses the seller and the nonce as input to avoid overlapping multiple sales
    mapping(address => mapping(uint256 => uint256)) internal mintOrderTokenId;

    struct FeeDistributionData {
        uint256 toRightsHolder; // Amount of tokens/ethers that will be sent to the rights holder(royalty receiver)
        uint256 toSeller; // Amount of tokens/ethers that will be sent to the seller
        address rightsHolder; // Rights holder address(tipically the creator, or a smart contract that splits the fees)
        Fees fees;
    }

    /// @notice Struct that contains all the fees of a given sale
    struct Fees {
        uint256 platformFee; // Sum of buyerFee + sellerFee, this is what the platform charges for a sale
        // Amount sent - royalty - platformFee, this is what is left after fees are
        // taken(usually goes to the seller unless this is a primary sale)
        uint256 assetFee;
        uint256 royaltyFee; // Royalty fee (could be split or not), it is intended to go to the artist/creator
        uint256 price; // Amount sent - buyerFee, it should be the price that the seller set on the asset
    }

    // Though the TradeV4 contract is upgradeable, we still have to initialize the implementation through the
    // constructor. This is because we chose to import the non upgradeable EIP712 as it does not have storage
    // variable(which actually makes it upgradeable) as it only uses immmutable variables. This has several advantages:
    // - We can import it without worrying the storage layout
    // - Is more efficient as there is no need to read from the storage
    // Note: The cache mechanism will NOT be used here as the address will differ from the one calculated in the
    // constructor due to the fact that when the contract is operating we will be using delegatecall, meaningn
    // that the address will be the one from the proxy as opposed to the implementation's during the
    // constructor execution
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory version) TradeSignaturesVerifier(name, version) {}

    function initializeTradeV4(
        ITransferProxy _transferProxy,
        address _enigmaNFT721Address,
        address _enigmaNFT1155Address,
        address _custodialAddress
    ) internal initializer {
        transferProxy = _transferProxy;
        enigmaNFT721Address = _enigmaNFT721Address;
        enigmaNFT1155Address = _enigmaNFT1155Address;
        custodialAddress = _custodialAddress;
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function setCustodialAddress(address _custodialAddress) external onlyOwner returns (bool) {
        emit CustodialAddressChanged(custodialAddress, _custodialAddress);
        custodialAddress = _custodialAddress;
        return true;
    }

    /**
     * @notice Calculates fees of an operation from the paymentAmount as well as ask for the royalty fees receiver
     * because it is part of the ERC2981 standard
     * @param paymentAmt Amount that the user sent(NOT the price, it is the price + buyer fee)
     * @param buyingAssetAddress the token symbol
     * @param tokenId Token id of the token being sold
     * @param sellerFeePermille Seller fee in Permille(unit per thousand of the total)
     * @param buyerFeePermille Buyer fee in Permille(unit per thousand of the total)
     */
    function calculateFees(
        uint256 paymentAmt,
        address buyingAssetAddress,
        uint256 tokenId,
        uint256 sellerFeePermille,
        uint256 buyerFeePermille
    ) internal view virtual returns (address, Fees memory) {
        Fees memory fees;
        address royaltyFeeReceiver;
        // TODO maybe this could be improved if the price is sent instead of being calculated
        uint256 price = paymentAmt.mul(1000).div((1000 + buyerFeePermille));
        uint256 buyerFee = paymentAmt.sub(price);
        uint256 sellerFee = price.mul(sellerFeePermille).div((1000));
        fees.platformFee = buyerFee.add(sellerFee);

        bool success = IERC165Upgradeable(buyingAssetAddress).supportsInterface(_INTERFACE_ID_ERC2981);
        if (success) {
            (royaltyFeeReceiver, fees.royaltyFee) = IERC2981(buyingAssetAddress).royaltyInfo(tokenId, price);
        } else {
            fees.royaltyFee = 0;
        }
        fees.assetFee = price.sub(sellerFee).sub(fees.royaltyFee);
        fees.price = price;
        return (royaltyFeeReceiver, fees);
    }

    /**
     * @notice Calculates fees of an operation from the paymentAmount and to whom we should distribute it too
     *
     * @param paymentAmt Amount that the user sent(NOT the price, it is the price + buyer fee)
     * @param buyingAssetAddress the token symbol
     * @param tokenId Token id of the token being sold
     * @param sellerFeePermille Seller fee in Permille(unit per thousand of the total)
     * @param buyerFeePermille Buyer fee in Permille(unit per thousand of the total)
     * @param seller Address of the seller
     */
    function getFees(
        uint256 paymentAmt,
        address buyingAssetAddress,
        uint256 tokenId,
        uint256 sellerFeePermille,
        uint256 buyerFeePermille,
        address seller
    ) internal view virtual returns (FeeDistributionData memory) {
        (address royaltyFeesReceiver, Fees memory fees) =
            calculateFees(paymentAmt, buyingAssetAddress, tokenId, sellerFeePermille, buyerFeePermille);
        uint256 toRightsHolder = 0;
        uint256 toSeller = 0;
        bool isPrimarySale;

        try IRoyaltyAwareNFT(buyingAssetAddress).getCreator(tokenId) returns (address creator) {
            isPrimarySale = creator == seller;
        } catch {
            // We are not sure as this is probably an external token. We will take the safe path here
            isPrimarySale = false;
        }

        if (isPrimarySale) {
            toRightsHolder = fees.royaltyFee.add(fees.assetFee);
            // seller receives 0 in this case as all of it is split using the rightsHolder
        } else {
            toSeller = fees.assetFee;
            toRightsHolder = fees.royaltyFee; // This might be 0
        }

        return
            FeeDistributionData({
                toRightsHolder: toRightsHolder,
                toSeller: toSeller,
                rightsHolder: royaltyFeesReceiver,
                fees: fees
            });
    }

    function tradeNFT(Order memory order) internal virtual {
        safeTransferFrom(
            order.nftType,
            order.seller,
            order.tokenReceiver,
            order.nftAddress,
            order.tokenId,
            order.quantity
        );
    }

    function _mintExistingNFT(Order memory order, uint256 tokenId) internal returns (uint256) {
        BaseEnigmaNFT1155(order.nftAddress).mintExistingExternalVerifier(
            tokenId,
            order.quantity,
            order.tokenReceiver,
            order.seller,
            order.nonce
        );
        return tokenId;
    }

    function _mintNFT(Order memory order, TokenData memory tokenData) internal virtual returns (uint256) {
        uint256 tokenId;
        if (order.nftType == AssetType.ERC721) {
            tokenId = BaseEnigmaNFT721(order.nftAddress).mintNewExternalVerifier(
                tokenData.tokenURI,
                tokenData.royaltyFee,
                tokenData.rightsHolder,
                order.tokenReceiver,
                order.seller,
                order.nonce
            );
        } else {
            tokenId = mintOrderTokenId[order.seller][order.nonce];
            if (tokenId == 0) {
                tokenId = BaseEnigmaNFT1155(order.nftAddress).mintNewExternalVerifier(
                    tokenData.tokenURI,
                    tokenData.royaltyFee,
                    tokenData.rightsHolder,
                    order.tokenReceiver,
                    order.nonce,
                    order.seller,
                    order.tokenId,
                    order.quantity
                );
                mintOrderTokenId[order.seller][order.nonce] = tokenId;
            } else {
                _mintExistingNFT(order, tokenId);
            }
        }
        return tokenId;
    }

    function safeTransferFrom(
        AssetType nftType,
        address from,
        address to,
        address nftAddress,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual {
        nftType == AssetType.ERC721
            ? transferProxy.erc721safeTransferFrom(nftAddress, from, to, tokenId)
            : transferProxy.erc1155safeTransferFrom(nftAddress, from, to, tokenId, quantity, "");
    }

    /**
     * @dev Disable slither warning because there is a nonReentrant check and the address are known
     * https://github.com/crytic/slither/wiki/Detector-Documentation#functions-that-send-ether-to-arbitrary-destinations
     */
    function tradeETH(
        Order memory order,
        address royaltyReceiver,
        Fees memory fees
    ) internal virtual {
        bool singleReceiver = royaltyReceiver == order.paymentReceiver;
        if (fees.platformFee > 0) {
            // slither-disable-next-line arbitrary-send
            (bool platformSuccess, ) = owner().call{ value: fees.platformFee }("");
            require(platformSuccess, "sending ETH to owner failed");
        }

        if (!singleReceiver && fees.royaltyFee > 0) {
            // slither-disable-next-line arbitrary-send
            (bool royaltySuccess, ) = royaltyReceiver.call{ value: fees.royaltyFee }("");
            require(royaltySuccess, "sending ETH to creator failed");
        }

        if (singleReceiver || fees.assetFee > 0) {
            uint256 amountToTransfer = singleReceiver ? fees.assetFee.add(fees.royaltyFee) : fees.assetFee;
            // slither-disable-next-line arbitrary-send
            (bool sellerSuccess, ) = order.paymentReceiver.call{ value: amountToTransfer }("");
            require(sellerSuccess, "sending ETH to seller failed");
        }
    }

    function _buyAssetWithETH(
        Order memory order,
        PlatformFeesBase calldata platformFees,
        // this might be differen from the tokenId of the order
        // (if we are creating a new token, the order's tokenId should be 0 in most cases)
        uint256 tokenId,
        bool mintTokens
    ) internal {
        require(order.timeLimit >= block.timestamp, "TradeV4: Order expired");
        require(platformFees.timeLimit >= block.timestamp, "TradeV4: Platform fees expired");
        // This is repeating code for the moment being but it is an ongoing effort to refactor
        // the distribution of fees to remove primary sale from the logic of the contract
        (address royaltyReceiver, Fees memory fees) =
            calculateFees(
                msg.value,
                order.nftAddress,
                tokenId,
                platformFees.sellerFeePermille,
                platformFees.buyerFeePermille
            );
        require((fees.price >= order.unitPrice * order.quantity), "Paid invalid amount");
        // Instead of an explicit check for equality, we check that the signature
        // was created using those values
        verifyDirectSalePlatformFeesSignature(platformFees, order, mintTokens, owner());
        // Using the one sent here saves some checks as we need to make sure the same seller fees
        // where included in both singatures, no need for an extra param or assertion
        require(
            order.nftType == AssetType.ERC1155 || order.limitAmountToSell == 1,
            "TradeV4: Limit amount to sell has to be 1 for ERC721"
        );

        // Seller could be overselling its balance by signing an order too large, we allow that
        // In that scenario the seller could be allowing users to buy tokens bought into the future at the current price
        // This is not recommended but as it could only harm the seller, this is not enforced
        uint256 totalAmountSold = amountSold[order.seller][order.nonce].add(order.quantity);
        require(totalAmountSold <= order.limitAmountToSell, "TradeV4: Order oversold");
        amountSold[order.seller][order.nonce] = totalAmountSold;

        tradeETH(order, royaltyReceiver, fees);
    }

    /*********************
     ** PUBLIC FUNCTIONS *
     *********************/

    function buyAssetWithETH(
        Order memory order,
        bytes memory signature, // seller signature
        PlatformFeesBase calldata platformFees
    ) external payable nonReentrant returns (bool) {
        // Using the one sent here saves some checks as we need to make sure the same seller fees
        // where included in both singatures, no need for an extra param or assertion
        verifySellerSignature(order, platformFees.sellerFeePermille, signature);
        _buyAssetWithETH(order, platformFees, order.tokenId, false);
        if (order.tokenReceiver != order.seller) tradeNFT(order);
        emit BuyAsset(
            order.seller,
            order.paymentReceiver,
            order.tokenReceiver,
            msg.sender,
            order.nftAddress,
            order.nftType,
            order.tokenId,
            order.quantity,
            order.nonce,
            false
        );
        return true;
    }

    function mintNewAndBuyAssetWithETH(
        Order memory order,
        TokenData memory tokenData,
        bytes memory signature, // seller signature
        PlatformFeesBase calldata platformFees
    ) external payable nonReentrant returns (bool) {
        // Using the one sent here saves some checks as we need to make sure the same seller fees
        // where included in both singatures, no need for an extra param or assertion
        verifyMintNewSignature(order, tokenData, platformFees.sellerFeePermille, signature);
        uint256 tokenId = _mintNFT(order, tokenData);
        _buyAssetWithETH(order, platformFees, tokenId, true);
        emit BuyAsset(
            order.seller,
            order.paymentReceiver,
            order.tokenReceiver,
            msg.sender,
            order.nftAddress,
            order.nftType,
            tokenId,
            order.quantity,
            order.nonce,
            true
        );
        return true;
    }

    function mintExistingAndBuyAssetWithETH(
        Order memory order,
        bytes memory signature, // seller signature
        PlatformFeesBase calldata platformFees
    ) external payable nonReentrant returns (bool) {
        require(order.nftType == AssetType.ERC1155, "TradeV4: Cannot mint an existing 721");

        // Using the one sent here saves some checks as we need to make sure the same seller fees
        // where included in both singatures, no need for an extra param or assertion
        verifyMintExistingSignature(order, platformFees.sellerFeePermille, signature);
        uint256 tokenId = _mintExistingNFT(order, order.tokenId);
        _buyAssetWithETH(order, platformFees, tokenId, true);
        emit BuyAsset(
            order.seller,
            order.paymentReceiver,
            order.tokenReceiver,
            msg.sender,
            order.nftAddress,
            order.nftType,
            tokenId,
            order.quantity,
            order.nonce,
            true
        );
        return true;
    }

    /**
     * @notice Verifies and executes a safe Token withdraw for this sender, if authorized by the custodial
     * @param wr struct with the withdraw information. What asset and how much of it
     * @param signature asset custodial authorization signature
     */
    function withdrawToken(WithdrawRequest memory wr, bytes memory signature) external returns (bool) {
        require(wr.timeLimit >= block.timestamp, "TradeV4: Withdraw voucher expired");
        require(
            !AuthorizationBitmap.isAuthProcessed(processedAuthorizationsBitMap, wr.nonce),
            "Authorization signature already processed"
        );
        address assetOwner = msg.sender;
        // Verifies that this asset custodial, is actually authorizing this user withdraw
        verifyWithdrawSignature(custodialAddress, assetOwner, wr, signature);
        AuthorizationBitmap.setAuthProcessed(processedAuthorizationsBitMap, wr.nonce);
        safeTransferFrom(wr.assetType, custodialAddress, assetOwner, wr.assetAddress, wr.tokenId, wr.quantity);
        emit TokenWithdraw(assetOwner, wr.nonce, wr.tokenId, wr.quantity);
        return true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

     */
    uint256[999] private __gap;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";
import "../../utils/EIP712.sol";

enum AssetType { ERC1155, ERC721 }

struct PlatformFees {
    address assetAddress;
    uint256 tokenId;
    uint8 buyerFeePermille;
    uint8 sellerFeePermille;
    bytes signature;
}

struct PlatformFeesBase {
    uint8 buyerFeePermille;
    uint8 sellerFeePermille;
    bytes signature;
    uint256 timeLimit;
}

struct WithdrawRequest {
    uint256 nonce; // Unique id for this withdraw authorization
    address assetAddress;
    AssetType assetType;
    uint256 tokenId;
    uint256 quantity;
    uint256 timeLimit;
}

struct Order {
    address seller; // defined by seller - current owner of the tokens - signer of the sell order
    address tokenReceiver; // defined by buyer - new owner of the tokens
    address erc20Address; // defined by seller
    address nftAddress; // defined by seller
    AssetType nftType; // defined by seller
    uint256 unitPrice; // defined by seller
    uint256 tokenId; // defined by seller
    uint256 quantity; // defined by buyer
    uint256 limitAmountToSell; // defined by seller
    uint256 nonce; // defined by seller
    address paymentReceiver; // defined by seller
    uint256 timeLimit; // defined by seller
}

struct TokenData {
    string tokenURI;
    uint256 royaltyFee;
    address rightsHolder;
}

contract TradeSignaturesVerifier is EIP712 {
    bytes32 private constant PLATFORM_FEES_TYPE_HASH =
        keccak256("PlatformFees(address assetAddress,uint256 tokenId,uint8 buyerFeePermille,uint8 sellerFeePermille)");

    bytes32 private constant DIRECT_SALE_PLATFORM_FEES_TYPE_HASH =
        // solhint-disable max-line-length
        keccak256(
            "DirectSalePlatformFees(address assetAddress,address seller,uint256 tokenId,uint256 limitAmountToSell,uint256 sellOrderNonce,uint8 buyerFeePermille,uint8 sellerFeePermille,bool mintTokens,uint256 timeLimit)"
        );

    bytes32 private constant SELL_ORDER_TYPE_HASH =
        keccak256(
            // solhint-disable max-line-length
            "SellOrder(address assetAddress,uint256 tokenId,address paymentAssetAddress,uint256 unitPrice,uint256 limitAmountToSell,uint8 sellerFeePermille,uint256 nonce,uint256 timeLimit,address paymentReceiver)"
        );

    bytes32 private constant TOKEN_DATA_TYPE_HASH =
        keccak256("TokenData(string tokenURI,uint256 royaltyFee,address rightsHolder)");

    bytes32 private constant MINT_NEW_AND_SELL_ORDER_TYPE_HASH =
        keccak256(
            // solhint-disable max-line-length
            "MintNewAndSellOrder(SellOrder sellOrder,TokenData tokenData)SellOrder(address assetAddress,uint256 tokenId,address paymentAssetAddress,uint256 unitPrice,uint256 limitAmountToSell,uint8 sellerFeePermille,uint256 nonce,uint256 timeLimit,address paymentReceiver)TokenData(string tokenURI,uint256 royaltyFee,address rightsHolder)"
        );

    bytes32 private constant MINT_EXISTING_AND_SELL_ORDER_TYPE_HASH =
        keccak256(
            // solhint-disable max-line-length
            "MintExistingAndSellOrder(SellOrder sellOrder)SellOrder(address assetAddress,uint256 tokenId,address paymentAssetAddress,uint256 unitPrice,uint256 limitAmountToSell,uint8 sellerFeePermille,uint256 nonce,uint256 timeLimit,address paymentReceiver)"
        );

    bytes32 private constant WITHDRAW_VOUCHER_TYPE_HASH =
        keccak256(
            // solhint-disable max-line-length
            "WithdrawVoucher(address assetOwner,uint256 nonce,address assetAddress,uint8 assetType,uint256 tokenId,uint256 quantity,uint256 timeLimit)"
        );

    // Though the TradeV4 contract is upgradeable, we still have to initialize the implementation through the
    // constructor. This is because we chose to import the non upgradeable EIP712 as it does not have storage
    // variable(which actually makes it upgradeable) as it only uses immmutable variables. This has several advantages:
    // - We can import it without worrying the storage layout
    // - Is more efficient as there is no need to read from the storage
    // Note: The cache mechanism will NOT be used here as the address will differ from the one calculated in the
    // constructor due to the fact that when the contract is operating we will be using delegatecall, meaningn
    // that the address will be the one from the proxy as opposed to the implementation's during the
    // constructor execution
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory version) EIP712(name, version) {}

    /**
     * @notice Internal function to verify a sign to mint tokens
     * Reverts if the sign verification fails.
     * @param platformFees Struct that has information about platform fees
     * @param authorizer address of the wallet that authorizes minters
     */
    function verifyPlatformFeesSignature(PlatformFees calldata platformFees, address authorizer) internal view {
        bytes32 digest =
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        PLATFORM_FEES_TYPE_HASH,
                        platformFees.assetAddress,
                        platformFees.tokenId,
                        platformFees.buyerFeePermille,
                        platformFees.sellerFeePermille
                    )
                )
            );

        address signer = ECDSAUpgradeable.recover(digest, platformFees.signature);
        require(authorizer == signer, "fees sign verification failed");
    }

    /**
     * @notice Internal function to verify a sign to mint tokens
     * Reverts if the sign verification fails.
     * @param platformFees Struct that has information about platform fees
     * @param buyOrder struct with buy order data
     * @param authorizer address of the wallet that authorizes minters
     */
    function verifyDirectSalePlatformFeesSignature(
        PlatformFeesBase calldata platformFees,
        Order memory buyOrder,
        bool mintTokens,
        address authorizer
    ) internal view {
        bytes32 digest =
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        DIRECT_SALE_PLATFORM_FEES_TYPE_HASH,
                        buyOrder.nftAddress,
                        buyOrder.seller,
                        buyOrder.tokenId,
                        buyOrder.limitAmountToSell,
                        buyOrder.nonce,
                        platformFees.buyerFeePermille,
                        platformFees.sellerFeePermille,
                        mintTokens,
                        platformFees.timeLimit
                    )
                )
            );

        address signer = ECDSAUpgradeable.recover(digest, platformFees.signature);
        require(authorizer == signer, "TradeSignatureVerifier: direct sale fees sign corrupted");
    }

    /**
     * @notice Verifies the seller authorization to sell a token
     * @param buyOrder struct with buy order data
     * @param sellerFeePermille sellerFee that is authorized by the seller(this is used in order to
     */
    function _hashSellOrder(Order memory buyOrder, uint8 sellerFeePermille) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SELL_ORDER_TYPE_HASH,
                    buyOrder.nftAddress,
                    buyOrder.tokenId,
                    address(0), // For the moment being we do not support ERC20 payments
                    buyOrder.unitPrice,
                    buyOrder.limitAmountToSell,
                    sellerFeePermille,
                    buyOrder.nonce,
                    buyOrder.timeLimit,
                    buyOrder.paymentReceiver
                )
            );
    }

    /**
     * @notice Verifies the seller authorization to sell a token
     * @param buyOrder struct with buy order data
     * @param sellerFeePermille sellerFee that is authorized by the seller(this is used in order to
     * @param signature bytes that represent the signature
     */
    function verifySellerSignature(
        Order memory buyOrder,
        uint8 sellerFeePermille,
        bytes memory signature
    ) internal view {
        bytes32 digest = _hashTypedDataV4(_hashSellOrder(buyOrder, sellerFeePermille));
        address signer = ECDSAUpgradeable.recover(digest, signature);
        require(buyOrder.seller == signer, "seller sign verification failed");
    }

    /**
     * @notice Verifies the seller authorization to sell a token
     * @param buyOrder struct with buy order data
     * @param tokenData struct with data to mint new token
     * @param sellerFeePermille sellerFee that is authorized by the seller(this is used in order to
     * @param signature bytes that represent the signature
     */
    function verifyMintNewSignature(
        Order memory buyOrder,
        TokenData memory tokenData,
        uint8 sellerFeePermille,
        bytes memory signature
    ) internal view {
        bytes32 digest =
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        MINT_NEW_AND_SELL_ORDER_TYPE_HASH,
                        _hashSellOrder(buyOrder, sellerFeePermille),
                        keccak256(
                            abi.encode(
                                TOKEN_DATA_TYPE_HASH,
                                keccak256(bytes(tokenData.tokenURI)),
                                tokenData.royaltyFee,
                                tokenData.rightsHolder
                            )
                        )
                    )
                )
            );
        address signer = ECDSAUpgradeable.recover(digest, signature);
        require(buyOrder.seller == signer, "TradeSignatureVerifier: minter/seller signature is corrupted");
    }

    /**
     * @notice Verifies the seller authorization to sell a token
     * @param buyOrder struct with buy order data
     * @param sellerFeePermille sellerFee that is authorized by the seller(this is used in order to
     * @param signature bytes that represent the signature
     */
    function verifyMintExistingSignature(
        Order memory buyOrder,
        uint8 sellerFeePermille,
        bytes memory signature
    ) internal view {
        bytes32 digest =
            _hashTypedDataV4(
                keccak256(
                    abi.encode(MINT_EXISTING_AND_SELL_ORDER_TYPE_HASH, _hashSellOrder(buyOrder, sellerFeePermille))
                )
            );
        address signer = ECDSAUpgradeable.recover(digest, signature);
        require(buyOrder.seller == signer, "TradeSignatureVerifier: minter/seller signature is corrupted");
    }

    /**
     * @notice Verifies the custodial authorization for this withdraw for this assetOwner
     * @param assetCustodial current asset holder
     * @param assetOwner real asset owner address
     * @param wr struct with the withdraw information. What asset and how much of it
     * @param signature bytes that represent the signature
     */
    function verifyWithdrawSignature(
        address assetCustodial,
        address assetOwner,
        WithdrawRequest memory wr,
        bytes memory signature
    ) internal view {
        bytes32 digest =
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        WITHDRAW_VOUCHER_TYPE_HASH,
                        assetOwner,
                        wr.nonce,
                        wr.assetAddress,
                        wr.assetType,
                        wr.tokenId,
                        wr.quantity,
                        wr.timeLimit
                    )
                )
            );
        address signer = ECDSAUpgradeable.recover(digest, signature);
        require(assetCustodial == signer, "TradeSignaturesVerifier: withdraw signature corrupted");
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

// Importing this file so it get compiled and get the artifact to deploy
import "@openzeppelin/contracts/proxy/ProxyAdmin.sol";

/// @title ProxyAdmin

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

// Importing this file so it get compiled and get the artifact to deploy
import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

/// @title TransparentUpgradeableProxy
///
/// @dev This contract implements the transparent proxy by openZeppelin that is upgradeable by an admin.
///         The proxy admin can update the implementation logic

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../market/EnigmaMarket.sol";
import "../ERC721/EnigmaNFT721.sol";

/// @title TestEnigmaMarket
///
/// @dev This contract extends from Trade Series for upgradeablity testing

contract TestEnigmaMarket is EnigmaMarket {
    uint256 public aNewValue;

    // Though the TradeV4 contract is upgradeable, we still have to initialize the implementation through the
    // constructor. This is because we chose to import the non upgradeable EIP712 as it does not have storage
    // variable(which actually makes it upgradeable) as it only uses immmutable variables. This has several advantages:
    // - We can import it without worrying the storage layout
    // - Is more efficient as there is no need to read from the storage
    // Note: The cache mechanism will NOT be used here as the address will differ from the one calculated in the
    // constructor due to the fact that when the contract is operating we will be using delegatecall, meaningn
    // that the address will be the one from the proxy as opposed to the implementation's during the
    // constructor execution
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory version) EnigmaMarket(name, version) {}

    /// @dev makes internal storage visible
    function getMaxDuration() external view returns (uint256) {
        return maxDuration;
    }

    /// @dev makes internal storage visible
    function getMinDuration() external view returns (uint256) {
        return minDuration;
    }

    /// @dev Check that fees add up without increasing costs in productive scenario
    function getFees(
        uint256 paymentAmt,
        address buyingAssetAddress,
        uint256 tokenId,
        uint256 sellerFeePermille,
        uint256 buyerFeePermille,
        address seller
    ) internal view virtual override returns (FeeDistributionData memory) {
        FeeDistributionData memory feeDistributionData =
            super.getFees(paymentAmt, buyingAssetAddress, tokenId, sellerFeePermille, buyerFeePermille, seller);
        // Amount of "fees" sums up to the paid amount
        assert(
            feeDistributionData.fees.assetFee +
                feeDistributionData.fees.royaltyFee +
                feeDistributionData.fees.platformFee ==
                paymentAmt
        );
        // Outgoing transfers is the same as incoming one

        assert(
            feeDistributionData.toRightsHolder + feeDistributionData.toSeller + feeDistributionData.fees.platformFee ==
                paymentAmt
        );
        return feeDistributionData;
    }
}

contract TestAuctionSeller {
    bool public doFail;

    function doApprove(
        address enigmaNFT721,
        address transferProxy,
        uint256 tokenId
    ) public {
        EnigmaNFT721(enigmaNFT721).approve(transferProxy, tokenId);
    }

    function doCreateReserveAuction(
        address market,
        address nftContract,
        uint256 tokenId,
        uint256 duration,
        uint256 reservePrice,
        PlatformFees calldata platformFees
    ) public {
        doFail = true;
        TestEnigmaMarket(market).createReserveAuction(nftContract, tokenId, duration, reservePrice, platformFees);
    }

    function doWithdrawTo(address market, address payable user) public {
        doFail = false;
        TestEnigmaMarket(market).withdrawTo(user);
    }

    function setDoFail(bool _doFail) public {
        doFail = _doFail;
    }

    /// receive fails on purpose to test this scenario
    receive() external payable {
        if (doFail) revert("test only");
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../ERC1155/EnigmaNFT1155.sol";

/// @title TestEnigmaNFT1155
///
/// @dev This contract extends from BaseEnigmaNFT1155 for upgradeablity testing

contract TestEnigmaNFT1155 is EnigmaNFT1155 {
    event CollectibleCreated(uint256 tokenId);

    // Though the TradeV4 contract is upgradeable, we still have to initialize the implementation through the
    // constructor. This is because we chose to import the non upgradeable EIP712 as it does not have storage
    // variable(which actually makes it upgradeable) as it only uses immmutable variables. This has several advantages:
    // - We can import it without worrying the storage layout
    // - Is more efficient as there is no need to read from the storage
    // Note: The cache mechanism will NOT be used here as the address will differ from the one calculated in the
    // constructor due to the fact that when the contract is operating we will be using delegatecall, meaningn
    // that the address will be the one from the proxy as opposed to the implementation's during the
    // constructor execution
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory version) EnigmaNFT1155(name, version) {}

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param supply_ tokens amount to be minted
     * @param fee_ uint256 royalty of the token to be minted.
     */
    function mintNew(
        string memory tokenURI_,
        uint256 supply_,
        uint256 fee_
    ) external {
        uint256 tokenId = _mintNew(tokenURI_, fee_, msg.sender, msg.sender, 0, msg.sender, _increaseNextId(), supply_);
        creators[tokenId] = msg.sender;
        emit CollectibleCreated(tokenId);
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../ERC721/BaseEnigmaNFT721.sol";

/// @title TestEnigmaNFT721
///
/// @dev This contract extends from BaseEnigmaNFT721 for upgradeablity testing

contract TestEnigmaNFT721 is BaseEnigmaNFT721 {
    event CollectibleCreated(uint256 tokenId);

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     */
    function mintNew(string memory tokenURI_, uint256 fee_) external returns (uint256) {
        uint256 newItemId = tokenCounter;
        tokenCounter = tokenCounter + 1;
        emit CollectibleCreated(newItemId);
        _creator[newItemId] = msg.sender;
        _safeMint(msg.sender, newItemId, fee_, msg.sender);
        _setTokenURI(newItemId, tokenURI_);
        return newItemId;
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract TestERC1155 is ERC1155 {
    constructor() ERC1155("https://testERC1155/") {
        _mint(msg.sender, 1, 10, "");
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestERC721 is ERC721 {
    constructor() ERC721("TestERC721", "TEST") {
        _safeMint(msg.sender, 1);
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IWyvernProxyRegistry.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

contract TestsWyvernProxy {
    function proxyType() public pure returns (uint256 proxyTypeId) {
        return 2;
    }

    function erc721TransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external {
        IERC721Upgradeable(token).transferFrom(from, to, tokenId);
    }

    function erc1155TransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 value,
        bytes memory data
    ) external {
        IERC1155Upgradeable(token).safeTransferFrom(from, to, tokenId, value, data);
    }

    function erc1155BatchTransferFrom(
        address token,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        IERC1155Upgradeable(token).safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}

contract TestsWyvernProxyRegistry {
    /* Authenticated proxies by user. */
    mapping(address => TestsWyvernProxy) public proxies;

    function registerProxy() public returns (TestsWyvernProxy proxy) {
        require(address(proxies[msg.sender]) == address(0), "Proxy mast not me initilized already");
        proxy = new TestsWyvernProxy();
        proxies[msg.sender] = proxy;
        return proxy;
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _mint(msg.sender, 1e10);
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../market/EnigmaMarket.sol";

/// @title TestTradeV4
///
/// @dev This contract extends from Trade Series for upgradeablity testing

contract TestTradeV4 is TradeV4 {
    // Though the TradeV4 contract is upgradeable, we still have to initialize the implementation through the
    // constructor. This is because we chose to import the non upgradeable EIP712 as it does not have storage
    // variable(which actually makes it upgradeable) as it only uses immmutable variables. This has several advantages:
    // - We can import it without worrying the storage layout
    // - Is more efficient as there is no need to read from the storage
    // Note: The cache mechanism will NOT be used here as the address will differ from the one calculated in the
    // constructor due to the fact that when the contract is operating we will be using delegatecall, meaningn
    // that the address will be the one from the proxy as opposed to the implementation's during the
    // constructor execution
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory version) TradeV4(name, version) {}

    function initialize(
        ITransferProxy _transferProxy,
        address _enigmaNFT721Address,
        address _enigmaNFT1155Address,
        address _custodialAddress
    ) external initializer {
        initializeTradeV4(_transferProxy, _enigmaNFT721Address, _enigmaNFT1155Address, _custodialAddress);
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/ITransferGatekeeper.sol";

/// @title TestTransferGatekeeper

contract TestTransferGatekeeper is ITransferGatekeeper {
    string public encodeType;
    bytes public data;
    uint256[2] public tokenIds;
    uint256[2] public amounts;

    function canTransfer(
        address,
        address,
        address,
        bytes memory encodedData
    ) external view override returns (bool) {
        if (bytes(encodeType).length != 0) {
            string memory _encodeType = abi.decode(encodedData, (string));
            if (keccak256(bytes(_encodeType)) == keccak256(bytes("721"))) {
                (, uint256 _tokenId) = abi.decode(encodedData, (string, uint256));
                return tokenIds[0] == _tokenId;
            }
            if (keccak256(bytes(_encodeType)) == keccak256(bytes("1155"))) {
                (, uint256 _tokenId, uint256 _amount, bytes memory _data) =
                    abi.decode(encodedData, (string, uint256, uint256, bytes));
                return (tokenIds[0] == _tokenId &&
                    amounts[0] == _amount &&
                    keccak256(bytes(data)) == keccak256(bytes(_data)));
            }
            if (keccak256(bytes(_encodeType)) == keccak256(bytes("1155_batch"))) {
                (, uint256[] memory _tokenIds, uint256[] memory _amounts, bytes memory _data) =
                    abi.decode(encodedData, (string, uint256[], uint256[], bytes));
                return (tokenIds[0] == _tokenIds[0] &&
                    tokenIds[1] == _tokenIds[1] &&
                    amounts[0] == _amounts[0] &&
                    amounts[1] == _amounts[1] &&
                    keccak256(bytes(data)) == keccak256(bytes(_data)));
            }
        }
        return false;
    }

    function set721Data(uint256 _tokenId) public {
        encodeType = "721";
        tokenIds[0] = _tokenId;
    }

    function set1155Data(
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) public {
        encodeType = "1155";
        tokenIds[0] = _tokenId;
        amounts[0] = _amount;
        data = _data;
    }

    function set1155BatchData(
        uint256 _tokenId,
        uint256 _amount,
        bytes memory _data
    ) public {
        encodeType = "1155_batch";
        tokenIds[1] = _tokenId;
        amounts[1] = _amount;
        data = _data;
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IWhitelist.sol";

/* solhint-disable */

///This whitelist is for test updating whitelistProxy to allow any address to transfer
contract TestWhitelist is IWhitelist {
    function canTransfer(address) external pure override returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IWhitelist.sol";

/// @title AccessControlBasedWhitelist
///
/// @dev This contract is based in OpenZeppelin AccessControl that allows to implement role-based access

contract AccessControlBasedWhitelist is IWhitelist, AccessControl {
    // Create a new role identifier for the transfer role
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    constructor(address _trader) {
        require(_trader != address(0), "invalid address");
        // Grant the transfer role to a specified account
        _setupRole(TRANSFER_ROLE, _trader);
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @param _who the address that wants to transfer a NFT
     * @dev Returns true if address has permission to transfer a NFT
     */
    function canTransfer(address _who) external view override returns (bool) {
        return hasRole(TRANSFER_ROLE, _who);
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/proxy/UpgradeableBeacon.sol";

contract TransferGatekeeperBeacon is UpgradeableBeacon {
    // solhint-disable-next-line
    constructor(address implementation) public UpgradeableBeacon(implementation) {}
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ITransferGatekeeper.sol";
import "../interfaces/IWhitelist.sol";
import "../interfaces/IWhitelistHandler.sol";
import "../interfaces/IWyvernProxyRegistry.sol";

/// @title TransferGatekeeper
///
/// @dev This contract abstracts the transfer gatekeeping implementation to the caller, ie, ERC721 & ERC1155 tokens
///			 The logic can be replaced and the `canTransfer` will invoke the proper target function. It's important
///			 to mention that no storage is shared between this contract and the corresponding implementation
///			 call is used instead of delegate call to avoid different implementations storage compatibility.
contract TransferGatekeeper is ITransferGatekeeper, IWhitelistHandler, Ownable {
    event WhitelistChanged(address indexed _oldImplementation, address indexed _newImplementation);
    event RegistryChanged(address indexed _oldImplementation, address indexed _newImplementation);

    // The address of the whitelist implementation
    IWhitelist public whitelist;

    // The Wyvern compatible registry on wich to very user-proxy
    IWyvernProxyRegistry public registry;

    // Allowd the owner to enable/disable the registry
    bool public useRegistry;

    constructor(IWhitelist _whitelist) {
        require(address(_whitelist) != address(0), "invalid address");
        whitelist = _whitelist;
        useRegistry = false;
    }

    /**
        @notice Legacy function to support retrocompatibility on migration
                from WhitelistProxy to TransferGatekeeper
     */
    function canTransfer(address _proxy) external view returns (bool) {
        return whitelist.canTransfer(_proxy);
    }

    /**
     * @inheritdoc ITransferGatekeeper
     */
    function canTransfer(
        address _from,
        address,
        address _proxy,
        bytes memory
    ) external view override returns (bool) {
        return
            _from == _proxy || // the owner is executing the transfer
            whitelist.canTransfer(_proxy) || // the executor is whitelisted
            canTransferFromProxy(_from, _proxy); // the executor is an authorized proxy
    }

    function canTransferFromProxy(address _from, address _proxy) internal view returns (bool) {
        if (!useRegistry || address(registry) == address(0)) return false;
        address registryProxy = registry.proxies(_from);
        return address(registryProxy) == _proxy;
    }

    /**
     * @notice Sets the new address on wich to check whitelisting and enables its use
     * @param _registry the address of the new proxy registry implementation
     */
    function setRegistry(IWyvernProxyRegistry _registry) external onlyOwner {
        require(address(_registry) != address(0), "setRegistry: invalid address");
        emit RegistryChanged(address(registry), address(_registry));
        registry = _registry;
        setUseRegistry(true);
    }

    /**
     * @notice Enables/disable the registry use
     * @param _useRegistry true if you want to enable it
     */
    function setUseRegistry(bool _useRegistry) public onlyOwner {
        require(address(registry) != address(0), "Cannot change registry use with empty address");
        useRegistry = _useRegistry;
    }

    /**
     * @notice Sets the new address on wich to check whitelisting
     * @param _whitelist the address of the new whitelist implementation
     */
    function setWhitelist(IWhitelist _whitelist) external override onlyOwner {
        require(address(_whitelist) != address(0), "updateWhitelist: invalid address");
        emit WhitelistChanged(address(whitelist), address(_whitelist));
        whitelist = _whitelist;
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ITransferProxy.sol";

contract TransferProxy is ITransferProxy {
    event OperatorChanged(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public owner;
    address public operator;

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "OperatorRole: caller does not have the Operator role");
        _;
    }

    /** change the OperatorRole from contract creator address to trade contractaddress
            @param _operator :trade address 
        */

    function changeOperator(address _operator) external onlyOwner returns (bool) {
        require(_operator != address(0), "Operator: new operator is the zero address");
        emit OperatorChanged(operator, _operator);
        operator = _operator;
        return true;
    }

    /** change the Ownership from current owner to newOwner address
        @param newOwner : newOwner address */

    function ownerTransfership(address newOwner) external onlyOwner returns (bool) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function erc721safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) external override onlyOperator {
        IERC721Upgradeable(token).safeTransferFrom(from, to, tokenId);
    }

    function erc1155safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 value,
        bytes calldata data
    ) external override onlyOperator {
        IERC1155Upgradeable(token).safeTransferFrom(from, to, tokenId, value, data);
    }

    function erc20safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) external override onlyOperator {
        require(IERC20(token).transferFrom(from, to, value), "failure while transferring");
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

/**
 * @dev This implementation is similar to the OZ one but due to the fact we are using an old version
 *			we weren't able to import it.
 */
library AuthorizationBitmap {
    struct Bitmap {
        mapping(uint256 => uint256) map_;
    }

    function isAuthProcessed(Bitmap storage bitmap, uint256 index) internal view returns (bool) {
        return isAuthProcessed(bitmap.map_, index);
    }

    function setAuthProcessed(Bitmap storage bitmap, uint256 index) internal {
        setAuthProcessed(bitmap.map_, index);
    }

    /**
     * @notice Verifies if this authorization index has already been processed
     * @param _index of the Authorization signature you want to know it's been processed
     */
    function isAuthProcessed(mapping(uint256 => uint256) storage _map, uint256 _index) internal view returns (bool) {
        uint256 wordIndex = _index / 256;
        uint256 bitIndex = _index % 256;
        uint256 processedWord = _map[wordIndex];
        uint256 mask = (1 << bitIndex);
        return processedWord & mask == mask;
    }

    /**
     * @notice Sets this authorization index as processed
     * @param _index of the Authorization signature you want to mark as processed
     */
    function setAuthProcessed(mapping(uint256 => uint256) storage _map, uint256 _index) internal {
        uint256 wordIndex = _index / 256;
        uint256 bitIndex = _index % 256;
        _map[wordIndex] = _map[wordIndex] | (1 << bitIndex);
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/// @title EnigmaNFT721
///
import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";
import "../utils/EIP712.sol";

contract AuthorizedMintingNFT is EIP712 {
    using ECDSAUpgradeable for bytes32;
    bytes32 private constant NFT_MINTING_VOUCHER_TYPE_HASH =
        keccak256("NFTMintingVoucher(string tokenURI,address minter,uint256 supply,uint256 nonce)");

    // Though the TradeV4 contract is upgradeable, we still have to initialize the implementation through the
    // constructor. This is because we chose to import the non upgradeable EIP712 as it does not have storage
    // variable(which actually makes it upgradeable) as it only uses immmutable variables. This has several advantages:
    // - We can import it without worrying the storage layout
    // - Is more efficient as there is no need to read from the storage
    // Note: The cache mechanism will NOT be used here as the address will differ from the one calculated in the
    // constructor due to the fact that when the contract is operating we will be using delegatecall, meaningn
    // that the address will be the one from the proxy as opposed to the implementation's during the
    // constructor execution
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory version) EIP712(name, version) {}

    /**
     * @notice Internal function to verify a sign to mint tokens
     * Reverts if the sign verification fails.
     * @param tokenURI string memory URI of the token to be minted.
     * @param signature signature that authorizes the user to mint these tokens
     * @param minter Address authorized to mint
     * @param nonce nonce of the authorization
     * @param supply amount of tokens to be minted
     * @param authorizer address of the wallet that authorizes minters
     */
    function verifySign(
        string memory tokenURI,
        address minter,
        uint256 supply,
        uint256 nonce,
        bytes memory signature,
        address authorizer
    ) internal view {
        bytes32 digest =
            _hashTypedDataV4(
                keccak256(abi.encode(NFT_MINTING_VOUCHER_TYPE_HASH, keccak256(bytes(tokenURI)), minter, supply, nonce))
            );
        address signer = ECDSAUpgradeable.recover(digest, signature);
        require(authorizer == signer, "Owner sign verification failed");
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable

pragma solidity >=0.6.0 <0.8.0;

/**
 * NOTE: This is a slighltly modified version of the EIP712 implementation by OpenZeppelin. It was copy pasted to
 * remove the caching mechanism that is not needed and it breaks things because we are using proxies.
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) internal {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash =
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view virtual returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 name,
        bytes32 version
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, name, version, _getChainId(), address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

/// @title MintNFTEventEmitter

interface MintNFTEvent {
    event MintNewNFT(
        uint256 tokenId,
        address creator,
        address receiver,
        string tokenURI,
        uint256 quantity,
        uint256 royaltyFees,
        address rightsHolder,
        uint256 nonce
    );

    event MintExistingNFT(uint256 tokenId, address to, uint256 amount, uint256 nonce);
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

/* An ECDSA signature. */
struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";
import "../utils/EIP712.sol";
import "../utils/AuthorizationBitmap.sol";
import "../utils/Types.sol";

/// @notice A RBAC based Vault contract:
///             - Requires a signed payload
///             - If signature is ok, the transaction will be forwarded using call
/// @dev This contract was inspired by
///      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/MinimalForwarder.sol
contract Vault is AccessControlUpgradeable, ERC1155HolderUpgradeable, ERC721HolderUpgradeable, EIP712 {
    using AuthorizationBitmap for AuthorizationBitmap.Bitmap;

    bytes32 public constant ADMIN_ROLE = 0x00;
    bytes32 public constant SIGNER_ROLE = bytes32(uint256(0x01));

    AuthorizationBitmap.Bitmap private authorizationBitmap;
    bytes32 private constant FORWARD_REQUEST_TYPE_HASH =
        keccak256(
            // solhint-disable max-line-length
            "ForwardRequest(address to,uint256 value,uint256 nonce,bytes data,uint256 timeLimit)"
        );

    struct ForwardRequest {
        address to;
        uint256 value;
        uint256 nonce;
        bytes data;
        uint256 timeLimit;
    }

    // Though the TradeV4 contract is upgradeable, we still have to initialize the implementation through the
    // constructor. This is because we chose to import the non upgradeable EIP712 as it does not have storage
    // variable(which actually makes it upgradeable) as it only uses immmutable variables. This has several advantages:
    // - We can import it without worrying the storage layout
    // - Is more efficient as there is no need to read from the storage
    // Note: The cache mechanism will NOT be used here as the address will differ from the one calculated in the
    // constructor due to the fact that when the contract is operating we will be using delegatecall, meaningn
    // that the address will be the one from the proxy as opposed to the implementation's during the
    // constructor execution
    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name, string memory version) EIP712(name, version) {}

    function initialize(address admin, address[] calldata signers) public initializer {
        __AccessControl_init();
        __ERC1155Holder_init();
        __ERC721Holder_init();
        _setupRole(ADMIN_ROLE, admin);
        // Setup signers
        uint256 signersLength = signers.length;
        for (uint256 i = 0; i < signersLength; i++) {
            _setupRole(SIGNER_ROLE, signers[i]);
        }
    }

    /// @notice Signature verification function.
    /// @param req request to be checked against the signature
    /// @param signature signature that authorizes the msg.sender to execute req
    /// @dev signature payload is made by req.to + req.value + req.nonce + keccak256(req.data) + the domain
    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        require(!authorizationBitmap.isAuthProcessed(req.nonce), "Vault: already processed");
        bytes32 digest =
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        FORWARD_REQUEST_TYPE_HASH,
                        req.to,
                        req.value,
                        req.nonce,
                        keccak256(req.data),
                        req.timeLimit
                    )
                )
            );
        address signer = ECDSAUpgradeable.recover(digest, signature);
        return hasRole(SIGNER_ROLE, signer);
    }

    /// @notice Executes a transaction if the provided signature was made by someone whose role is SIGNER_ROLE.
    ///         - It will use this contract as msg.sender (ie. execute a call)
    ///         - Requests can only be executed once so they cannot be replayed
    ///         - It doesn't care who the signer is as long as the signature is ok
    /// @param req Request to be executed
    /// @param signature Signature made by a SIGNER that matches the req
    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        require(verify(req, signature), "Vault: signature does not match request");
        require(req.timeLimit >= block.timestamp, "Vault: forward request expired");
        authorizationBitmap.setAuthProcessed(req.nonce);

        (bool success, bytes memory returndata) =
            // All the gas is forwarded as this is going to be used by Enigma and not the users
            // This is not a relayer as GSN
            req.to.call{ value: req.value }(req.data);

        require(success, _getRevertMsg(returndata));
        return (success, returndata);
    }

    /// @dev https://ethereum.stackexchange.com/a/83577
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        // solhint-disable-next-line
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}