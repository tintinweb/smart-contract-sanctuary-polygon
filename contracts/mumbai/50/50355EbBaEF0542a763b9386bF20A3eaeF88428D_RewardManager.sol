/**
 *Submitted for verification at polygonscan.com on 2022-07-02
*/

//SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File contracts/RewardManager/interface/IRewardManager.sol

pragma solidity =0.8.15;

interface IRewardManager {
    struct Lender {
        uint deposit;
        bool registered;
    }

    /**
     * @notice Emitted when RewardManger has started
     * @dev Emitted when RewardManger has started (can be called only by owner)
     * @param startTime, starting time (timestamp)
     */
    event RewardManagerStarted(uint40 startTime);

    /**
     * @notice `startRewardManager` registers the `RewardManager`
     * @dev It can be called by LENDER_POOL only
     */
    function startRewardManager() external;

    /**
     * @notice `registerUser` registers the user to the current `RewardManager`
     * @dev It copies the user information from previous `RewardManager`.
     * @param lender, address of the lender
     */
    function registerUser(address lender) external;

    /**
     * @notice `claimRewardsFor` claims reward for the lender.
     * @dev All the reward are transferred to the lender.
     * @dev It can by only called by `LenderPool`.
     * @param lender, address of the lender
     */
    function claimAllRewardsFor(address lender) external;

    /**
     * @notice `increaseDeposit` increases the amount deposited by lender.
     * @dev It calls the `deposit` function of all the rewards in `RewardManager`.
     * @dev It can by only called by `LenderPool`.
     * @param lender, address of the lender
     * @param amount, amount deposited by the lender
     */
    function increaseDeposit(address lender, uint amount) external;

    /**
     * @notice `withdrawDeposit` decrease the amount deposited by the lender.
     * @dev It calls the `withdraw` function of all the rewards in `RewardManager`
     * @dev It can by only called by `LenderPool`.
     * @param lender, address of the lender
     * @param amount, amount withdrawn by the lender
     */
    function withdrawDeposit(address lender, uint amount) external;

    /**
     * @notice `resetRewards` sets the reward for all the tokens to 0
     */
    function resetRewards() external;

    /**
     * @notice `claimRewardFor` transfer all the `token` reward to the `user`
     * @dev It can be called by LENDER_POOL only.
     * @param lender, address of the lender
     * @param token, address of the token
     */
    function claimRewardFor(address lender, address token) external;

    /**
     * @notice `rewardOf` returns array of reward for the lender
     * @dev It returns array of number, where each element is a reward
     * @dev For example - [stable reward, trade reward 1, trade reward 2]
     */
    function rewardOf(address lender, address token)
        external
        view
        returns (uint);

    /**
     * @notice `getDeposit` returns the total amount deposited by the lender
     * @dev If this RewardManager is not the current and user has registered then this value will not be updated
     * @param lender, address of the lender
     * @return total amount deposited by the lender
     */
    function getDeposit(address lender) external view returns (uint);
}


// File contracts/Reward/interface/IReward.sol

pragma solidity =0.8.15;

interface IReward {
    struct Lender {
        uint16 round;
        uint40 startPeriod;
        uint pendingRewards;
        uint deposit;
        bool registered;
    }

    struct RoundInfo {
        uint16 apy;
        uint40 startTime;
        uint40 endTime;
    }

    /**
     * @notice Emitted after `reward` is updated by OWNER.
     * @param oldReward, value of the old reward.
     * @param newReward, value of the new reward.
     */
    event NewReward(uint16 oldReward, uint16 newReward);

    /**
     * @notice Emitted after Reward is transferred to user.
     * @param lender, address of the lender.
     * @param amount, amount transferred to lender.
     */
    event RewardClaimed(address lender, uint amount);

    function registerUser(
        address lender,
        uint deposited,
        uint40 startPeriod
    ) external;

    /**
     * @notice `deposit` increases the `lender` deposit by `amount`
     * @dev It can be called by only REWARD_MANAGER.
     * @param lender, address of the lender
     * @param amount, amount deposited by lender
     *
     * Requirements:
     * - `amount` should be greater than 0
     *
     */
    function deposit(address lender, uint amount) external;

    /**
     * @notice `withdraw` withdraws the `amount` from `lender`
     * @dev It can be called by only REWARD_MANAGER.
     * @param lender, address of the lender
     * @param amount, amount requested by lender
     *
     * - `amount` should be greater than 0
     * - `amount` should be greater than deposited by the lender
     *
     */
    function withdraw(address lender, uint amount) external;

    /**
     * @notice `claimReward` send reward to lender.
     * @dev It calls `_updatePendingReward` function and sets pending reward to 0.
     * @dev It can be called by only REWARD_MANAGER.
     * @param lender, address of the lender.
     *
     * Emits {RewardClaimed} event
     */
    function claimReward(address lender) external;

    /**
     * @notice `setReward` updates the value of reward.
     * @dev For example - APY in case of tStable, trade per year per stable in case of trade reward.
     * @dev It can be called by only OWNER.
     * @param newReward, current reward offered by the contract.
     *
     * Emits {NewReward} event
     */
    function setReward(uint16 newReward) external;

    /**
     * @notice `pauseReward` sets the apy to 0.
     * @dev It is called after `RewardManager` is discontinued.
     * @dev It can be called by only REWARD_MANAGER.
     *
     * Emits {NewReward} event
     */
    function resetReward() external;

    /**
     * @notice `rewardOf` returns the total pending reward of the lender
     * @dev It calculates reward of lender upto current time.
     * @param lender, address of the lender
     * @return returns the total pending reward
     */
    function rewardOf(address lender) external view returns (uint);

    /**
     * @notice `getReward` returns the total reward.
     * @return returns the total reward.
     */
    function getReward() external view returns (uint16);

    /**
     * @notice `getRewardToken` returns the address of the reward token
     * @return address of the reward token
     */
    function getRewardToken() external view returns (address);
}


// File @openzeppelin/contracts/access/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
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


// File contracts/RewardManager/RewardManager.sol

pragma solidity =0.8.15;



/**
 * @author Polytrade
 * @title Reward Manager V2
 */
contract RewardManager is IRewardManager, AccessControl {
    IReward public stable;
    IReward public trade;
    address public prevRewardManager;
    bytes32 public constant LENDER_POOL = keccak256("LENDER_POOL");

    uint40 public startTime;

    mapping(address => Lender) private _lender;

    constructor(
        address _stable,
        address _trade,
        address _prevRewardManager
    ) {
        stable = IReward(_stable);
        trade = IReward(_trade);
        prevRewardManager = _prevRewardManager;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice `registerUser` registers the user to the current `RewardManager`
     * @dev It copies the user information from previous `RewardManager`.
     * @param lender, address of the lender
     */
    function registerUser(address lender) external onlyRole(LENDER_POOL) {
        require(startTime > 0, "Not initialized yet");
        require(!_lender[lender].registered, "Already registered");
        require(lender != address(0), "Should not be address(0)");
        if (prevRewardManager != address(0)) {
            uint lenderBalance = IRewardManager(prevRewardManager).getDeposit(
                lender
            );
            if (lenderBalance > 0) {
                _lender[lender].deposit += lenderBalance;
                stable.registerUser(lender, lenderBalance, startTime);
                trade.registerUser(lender, lenderBalance, startTime);
                _lender[lender].registered = true;
            }
        }
    }

    /**
     * @notice `startRewardManager` starts the `RewardManager`
     * @dev It can only be called by LENDER_POOL
     */
    function startRewardManager() external onlyRole(LENDER_POOL) {
        require(startTime == 0, "Already started");
        startTime = uint40(block.timestamp);
        emit RewardManagerStarted(startTime);
    }

    /**
     * @notice `startRewardManager` starts the `RewardManager`
     * @dev It can only be called by DEFAULT_ADMIN_ROLE
     * @dev grant LENDER_POOL role
     */
    function startRewardManager(address _lenderPool)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(startTime == 0, "Already started");
        _grantRole(LENDER_POOL, _lenderPool);
        startTime = uint40(block.timestamp);
        emit RewardManagerStarted(startTime);
    }

    /**
     * @notice `increaseDeposit` increases the amount deposited by lender.
     * @dev It calls the `deposit` function of all the rewards in `RewardManager`.
     * @dev Can be called only by the `LenderPool`.
     * @param lender, address of the lender
     * @param amount, amount deposited by the lender
     */
    function increaseDeposit(address lender, uint amount)
        external
        onlyRole(LENDER_POOL)
    {
        require(lender != address(0), "Should not be address(0)");

        _lender[lender].deposit += amount;
        trade.deposit(lender, amount);
        stable.deposit(lender, amount);
    }

    /**
     * @notice `withdrawDeposit` decrease the amount deposited by the lender.
     * @dev It calls the `withdraw` function of all the rewards in `RewardManager`
     * @dev Can be called only by the `LenderPool`.
     * @param lender, address of the lender
     * @param amount, amount withdrawn by the lender
     */
    function withdrawDeposit(address lender, uint amount)
        external
        onlyRole(LENDER_POOL)
    {
        require(lender != address(0), "Should not be address(0)");

        _lender[lender].deposit -= amount;
        trade.withdraw(lender, amount);
        stable.withdraw(lender, amount);
    }

    /**
     * @notice `claimRewardsFor` claims reward for the lender.
     * @dev All the reward are transferred to the lender.
     * @dev Can be called only by the `LenderPool`.
     * @param lender, address of the lender
     */
    function claimAllRewardsFor(address lender) external onlyRole(LENDER_POOL) {
        require(lender != address(0), "Should not be address(0)");

        stable.claimReward(lender);
        trade.claimReward(lender);
    }

    /**
     * @notice `claimRewardFor` transfer all the `token` reward to the `user`
     * @dev It can only be called by LENDER_POOL.
     * @param lender, address of the lender
     * @param token, address of the token
     */
    function claimRewardFor(address lender, address token)
        external
        onlyRole(LENDER_POOL)
    {
        require(
            lender != address(0) && token != address(0),
            "Should not be address(0)"
        );

        if (stable.getRewardToken() == token) {
            stable.claimReward(lender);
        } else if (trade.getRewardToken() == token) {
            trade.claimReward(lender);
        }
    }

    /**
     * @notice `resetRewards` sets the reward for all the tokens to 0
     */
    function resetRewards() external onlyRole(LENDER_POOL) {
        stable.resetReward();
        trade.resetReward();
    }

    /**
     * @notice `rewardOf` returns array of reward for the lender
     * @dev It returns array of number, where each element is a reward
     * @dev For example - [stable reward, trade reward 1, trade reward 2]
     */
    function rewardOf(address lender, address token)
        external
        view
        returns (uint)
    {
        if (stable.getRewardToken() == token) {
            return stable.rewardOf(lender);
        } else if (trade.getRewardToken() == token) {
            return trade.rewardOf(lender);
        } else {
            return 0;
        }
    }

    /**
     * @notice `getDeposit` returns the total amount deposited by the lender
     * @dev If this RewardManager is not the current and user has registered then this value will not be updated
     * @param lender, address of the lender
     * @return total amount deposited by the lender
     */
    function getDeposit(address lender) external view returns (uint) {
        return _lender[lender].deposit;
    }
}