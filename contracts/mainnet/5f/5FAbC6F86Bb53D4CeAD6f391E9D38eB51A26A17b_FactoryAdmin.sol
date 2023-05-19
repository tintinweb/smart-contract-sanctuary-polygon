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
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
pragma solidity 0.8.10;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "contracts/index/IIndex.sol";
import "../partnerProgram/IPartnerProgram.sol";
import "./IFactory.sol";
import "../index/IIndexAdmin.sol";

/// @title The factory contract issues indexes.
/// * The factory is made on the basis of EIP1167
contract FactoryAdmin is AccessControl, IFactory {
    bytes32 public constant DAO_ADMIN_ROLE = keccak256("DAO_ADMIN_ROLE");
    // stores index addresses
    address[] private _indexes;
    // address of the implementation contract
    address private _indexMaster;
    // address of the DAO contract
    address private _DAOAddress;
    address private _validator;
    address private _acceptToken;
    address private _adapter;
    address private _tresuare;
    uint256 private _rebalancePeriod;
    IPartnerProgram private _ipartnerProgram;

    /// @param implementation Implementation address (master index)
    /// @param DAOAddr DAO_ADMIN address
    /// @param validator  Validator address. Has access to rebalancing the index
    /// @param acceptToken token for payment
    /// @param adapter DEX adapter
    /// @param rebalancePeriod The time after which rebalancing occurs (seconds)
    /// @param tresuare Tresuare address
    /// @param partnerProgram PartnerProgram address
    constructor(
        address implementation,
        address DAOAddr,
        address validator,
        address acceptToken,
        address adapter,
        uint256 rebalancePeriod,
        address tresuare,
        address partnerProgram
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DAO_ADMIN_ROLE, DAOAddr);

        _indexMaster = implementation;
        _DAOAddress = DAOAddr;
        _validator = validator;
        _acceptToken = acceptToken;
        _adapter = adapter;
        _rebalancePeriod = rebalancePeriod;
        _tresuare = tresuare;
        _ipartnerProgram = IPartnerProgram(partnerProgram);
    }

    /// @notice Creating an index
    /// @param startPrice Start price
    /// @param newAssets Assets in the index
    /// @param nameIndex Index name
    function mint(
        uint256 startPrice,
        address[] memory newAssets,
        string memory nameIndex
    ) external onlyRole(DAO_ADMIN_ROLE) {
        address instance = Clones.clone(_indexMaster);
        IIndexAdmin(instance).initialize(
            _DAOAddress,
            _validator,
            _acceptToken,
            _adapter,
            startPrice,
            _rebalancePeriod,
            newAssets,
            _tresuare,
            address(_ipartnerProgram),
            nameIndex
        );
        _indexes.push(instance);
        _ipartnerProgram.setupRoleIndex(instance);

        emit Mint(instance);
    }

    /// @notice Change the implementation address
    function changeIndexMaster(
        address newIndexMaster
    ) external onlyRole(DAO_ADMIN_ROLE) {
        emit ChangeIndexMaster(_indexMaster, newIndexMaster);
        _indexMaster = newIndexMaster;
    }

    /// @notice Change the main factory parameters
    /// @param DAOAddress DAO_ADMIN address
    /// @param validator  Validator address. Has access to rebalancing the index
    /// @param acceptToken token for payment
    /// @param adapter DEX adapter
    /// @param tresuare Tresuare address
    /// @param rebalancePeriod The time after which rebalancing occurs (seconds)
    function changeMainParam(
        address DAOAddress,
        address validator,
        address acceptToken,
        address adapter,
        address tresuare,
        uint256 rebalancePeriod
    ) external onlyRole(DAO_ADMIN_ROLE) {
        _DAOAddress = DAOAddress;
        _validator = validator;
        _acceptToken = acceptToken;
        _adapter = adapter;
        _rebalancePeriod = rebalancePeriod;
        _tresuare = tresuare;

        emit ChangeMainParam(
            DAOAddress,
            validator,
            acceptToken,
            adapter,
            tresuare,
            rebalancePeriod
        );
    }

    /// @notice Return the main parameters
    function getMainParam()
        external
        view
        returns (
            address indexMaster,
            address DAOAddress,
            address validator,
            address USD,
            address adapter,
            address tresuare,
            uint256 rebalancePeriod,
            address ipartnerProgram
        )
    {
        return (
            _indexMaster,
            _DAOAddress,
            _validator,
            _acceptToken,
            _adapter,
            _tresuare,
            _rebalancePeriod,
            address(_ipartnerProgram)
        );
    }

    /// @notice Return a list of indexes created through the factory
    function getIndexes() external view returns (address[] memory) {
        return _indexes;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IFactory).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

interface IFactory {
    event ChangeIndexMaster(address oldIndexMaster, address newIndexMaster);
    event Mint(address instance);
    event ChangeMainParam(
        address DAOAddress,
        address validator,
        address USD,
        address adapter,
        address tresuare,
        uint256 rebalancePeriod
    );
    event ChangeMainParamCommunity(
        address DAOAdminAddress,
        address DAOCommunityAddress,
        address validator,
        address USD,
        address adapter,
        address tresuare,
        uint256 rebalancePeriod
    );

    /// @notice Creating an index
    /// @param startPrice Start price
    /// @param newAssets Assets in the index
    /// @param nameIndex Index name
    function mint(
        uint256 startPrice,
        address[] memory newAssets,
        string memory nameIndex
    ) external;

    /// @notice Change the implementation address
    function changeIndexMaster(address newIndexMaster) external;

    /// @notice Return a list of indexes created through the factory
    function getIndexes() external view returns (address[] memory);

    /// @notice Return the main parameters
    function getMainParam()
        external
        view
        returns (
            address indexMaster,
            address DAOAddress,
            address validator,
            address USD,
            address adapter,
            address tresuare,
            uint256 rebalancePeriod,
            address ipartnerProgram
        );
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

interface IIndex {
    event Initialize(address adminDAO, address admin, address USD, address lp);
    event Rebalance(Asset[] assets, uint256 oldPrice, uint256 newPrice);
    event Init(Asset[] assets, uint256 indexPrice);
    event Stake(address indexed account, uint256 amountUSD, uint256 amountLP);
    event Unstake(address indexed account, uint256 amountLP);
    event SetRebalancePeriod(uint256 period);

    event SetFeeUnStake(uint256 newFee);
    event SetSlippage(uint256 newSlippage);
    event SetFeeStake(uint256 newFee);
    event SetActualToken(address newActualToken);
    event SetName(string name);

    error ZeroAmount();
    error InvalidStake();
    error Initializer();
    error RebalancePrice(uint256 priceAdmin, uint256 priceSM);
    error InvalidMinAmount(uint256 minAmount, uint256 amount);

    error InvalidAsset(address asset);

    struct Asset {
        address asset;
        address[] path;
        uint256 fixedAmount;
        uint256 totalAmount;
        uint256 share;
    }
    struct AssetData {
        address asset;
        address[] path;
        uint256 share;
    }

    /**
     * @notice Stops the work of the contract.
     * Blocks a call to the "stake" method.
     * Users can withdraw their funds
     */
    function setPause() external;

    /**
     * @notice  Set a new index name
     */
    function setNameIndex(string memory name) external;

    /**
     * @notice  Set a new commission
     * @dev Enter data taking into account precision
     */
    function setFeeStake(uint256 fee) external;

    /**
     * @notice  Set a new commission
     * @dev Enter data taking into account precision
     */
    function setFeeUnStake(uint256 fee) external;

    /**
     * @notice Sets the new address of the token. Used to pay for the index
     * changes will take effect after rebalancing
     */
    function setActualToken(address newToken) external;

    /**
     * @notice Setting the initial assets in the index
     */
    function init(AssetData[] memory newAssets) external;

    /**
     * @notice  Reconfiguring the index
     * @param newAssets - New assets that will be included in the index after rebalancing
     * @param path - Specify the path to exchange "_actualAcceptToken" to "_newAcceptToken".
     * The exchange will take place on quickSwap
     */
    function rebalance(
        AssetData[] memory newAssets,
        address[] memory path,
        uint256 calculatedPrice
    ) external;

    /**
     * @notice Buying an index
     * @param amountLP - The number of indexes that will be purchased
     * @param amountUSD - Number of tokens spent
     */
    function stake(uint256 amountLP, uint256 amountUSD) external;

    /**
     * @notice Buying an index for ETH
     * @param amountLP The number of indexes that will be purchased
     */
    function stakeETH(uint256 amountLP) external payable;

    /**
     * @notice Selling the index
     */
    function unstake(uint256 amountLP, uint256 minAmount) external;

    /// @notice Returns the pause state
    /// @return status True - means that the operation of functions using the "isPause" modifier is stopped
    /// * False- means that the functions using the "isPause" modifier are working
    function getStatusPause() external view returns (bool status);

    /**
     * @notice Returns the index name
     */
    function getNameIndex() external view returns (string memory nameIndex);

    /**
     * @notice Returns the timestamp of the last rebalance
     */
    function getLastRebalance() external view returns (uint256);

    /**
     * @notice Returns a list of assets that will be included in the index after rebalancing
     */
    function getNewAssets() external view returns (address[] memory newAssets);

    /**
     * @notice Returns information about the index
     * @param indexLP LP token address
     * @param maxShare The maximum share of an asset in the index
     * @param rebalancePeriod The time after which the rebalancing takes place
     * @param startPriceIndex Initial index price
     */
    function getDataIndex()
        external
        view
        returns (
            address indexLP,
            uint256 maxShare,
            uint256 rebalancePeriod,
            uint256 startPriceIndex
        );

    /**
     * @notice Returns an array of assets included in the index
     * @return assets An array of assets included in the index with all information about them
     */
    function getActiveAssets() external view returns (Asset[] memory assets);

    /**
     * @notice Returns the LP price
     */
    function getCostLP(
        uint256 amountLP
    ) external view returns (uint256 amountUSD);

    /**
     * @notice Returns commissions
     */
    function getFees()
        external
        view
        returns (uint256 feeStake, uint256 feeUnstake);

    /**
     * @notice Returns the address of the token accepted as payment
     */
    function getAcceptToken()
        external
        view
        returns (address actualAddress, address newAddress);

    /**
     * @notice Returns the number of assets in the rebalancing queue
     */
    function lengthNewAssets() external view returns (uint256 len);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

interface IIndexAdmin {
    /// @notice Initialization of the main parameters
    /// @param adminDAO The address that has the right to call functions with the "DAO_ADMIN_ROLE" role
    /// @param admin The address that has the right to call functions with the "ADMIN_ROLE" role
    /// @param acceptToken The token in which the payment is accepted
    /// @param adapter Adapter DEX
    /// @param startPrice Initial index price
    /// @param rebalancePeriod The time after which rebalancing occurs (seconds)
    /// @param newAssets Array with asset addresses
    /// @param tresuare A commission will be sent to this address
    /// @param partnerProgram Partner Program
    /// @param nameIndex Name Index
    function initialize(
        address adminDAO,
        address admin,
        address acceptToken,
        address adapter,
        uint256 startPrice,
        uint256 rebalancePeriod,
        address[] memory newAssets,
        address tresuare,
        address partnerProgram,
        string memory nameIndex
    ) external;

    /// @notice Set the maximum index share
    function setMaxShare(uint256 maxShare) external;

    /// @notice Set Rebalance period
    function setRebalancePeriod(uint256 period) external;

    /// @notice Sets a new list of assets after rebalancing
    function newIndexComposition(address[] calldata assets) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IPartnerProgram {
    function setupRoleIndex(address index) external;

    function distributeTheReward(
        address referral,
        uint256 amount,
        address token
    ) external returns (uint256 amountWithoutTax);

    /// @notice set the referrer
    /// @param referrer rspecify the referrer address
    function setReferrer(address referrer) external;

    /// @notice Sets the amount of the reward and the number of levels in the referral program
    /// @dev The number of levels depends on the size of the array.
    /// * the data inside the array shows the percentage of reward at each level
    /// * Can only be called by a user with the right DAO_ADMIN_ROLE
    /// @param percentReward the data must be specified taking into account the precission
    /// * the amount of data inside the array is equal to the number of levels
    /// * example [10000000, 5000000] equal first level =10%, second level = 5%
    function setPercentReward(uint256[] memory percentReward) external;
}