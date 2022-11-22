// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/IENF.sol";
import "./interfaces/IENFVesting.sol";
import "./structs/StakingStructs.sol";

contract Staking is ReentrancyGuard, AccessControl, Pausable {
    uint16 public constant DENOMINATOR = 10_000;
    bytes32 public constant UPDATE_DESPOSIT_TYPE_ROLE = keccak256("UPDATE_DESPOSIT_TYPE_ROLE");
    bytes32 public constant OPERATIONAL_ROLE = keccak256("OPERATIONAL_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");

    IENF private _enf;

    IENFVesting private _vesting;

    uint256 private _rewardPool;

    DepositType[] private _depositTypes;

    mapping(address => mapping(uint256 => Deposit)) private _depositsByOwner;
    mapping(address => uint256) private _depositsNumberPerOwner;

    constructor(IENF newEnf) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPDATE_DESPOSIT_TYPE_ROLE, msg.sender);
        _grantRole(OPERATIONAL_ROLE, msg.sender);
        _grantRole(SETTER_ROLE, msg.sender);
        _enf = newEnf;
        _pause();
    }

    function stake(uint256 amount, uint256 depositTypeIndex) external whenNotPaused {
        if (amount == 0) {
            revert InvalidAmount();
        }

        if (depositTypeIndex >= _depositTypes.length) {
            revert InvalidDepositTypeIndex();
        }

        DepositType memory selectedDepositType = _depositTypes[depositTypeIndex];

        uint256 reward = (amount * selectedDepositType.apr) / DENOMINATOR;

        updateRewardPool(reward, false);

        _enf.transferFrom(msg.sender, address(this), amount);

        Deposit memory deposit = Deposit({
            id: _depositsNumberPerOwner[msg.sender],
            startTimestamp: uint32(block.timestamp),
            maturityTimestamp: uint32(block.timestamp) + selectedDepositType.duration,
            coolingTimestamp: 0,
            owner: msg.sender,
            amount: amount,
            reward: reward,
            depositType: selectedDepositType
        });

        _depositsByOwner[msg.sender][_depositsNumberPerOwner[msg.sender]++] = deposit;

        emit Stake(
            msg.sender,
            amount,
            uint40(block.timestamp),
            uint40(block.timestamp) + selectedDepositType.duration,
            selectedDepositType.apr,
            selectedDepositType.penalty,
            selectedDepositType.duration
        );
    }

    function unstake(uint256 depositId) public whenNotPaused {
        Deposit memory currentDeposit = _depositsByOwner[msg.sender][depositId];
        uint40 coolingTimestamp;
        if (currentDeposit.owner == address(0)) {
            revert InvalidDeposit();
        }

        if (currentDeposit.coolingTimestamp != 0) {
            revert DepositAlreadyUstaked();
        }

        if (currentDeposit.maturityTimestamp <= block.timestamp && currentDeposit.coolingTimestamp == 0) {
            delete _depositsByOwner[msg.sender][depositId];
            _enf.transfer(currentDeposit.owner, currentDeposit.amount + currentDeposit.reward);
            emit UnstakeOnMaturity(msg.sender, depositId, currentDeposit.amount, currentDeposit.reward);
        } else {
            if (!currentDeposit.depositType.canUnstakePriorMaturation) {
                revert CannotUnstakeAtThisTypeOfDeposit();
            }

            updateRewardPool(_depositsByOwner[msg.sender][depositId].reward, true);

            _depositsByOwner[msg.sender][depositId].reward = 0;
            coolingTimestamp = uint40(block.timestamp) + currentDeposit.depositType.coolingDuration;
            _depositsByOwner[msg.sender][depositId].coolingTimestamp = coolingTimestamp;
            emit UnstakePriorMaturity(msg.sender, depositId, coolingTimestamp);
        }
    }

    function claimCoolingDeposit(uint256 depositId) external whenNotPaused {
        uint256 penaltyAmount;

        Deposit memory currentDeposit = _depositsByOwner[msg.sender][depositId];
        if (currentDeposit.owner == address(0)) {
            revert InvalidDeposit();
        }

        if (currentDeposit.coolingTimestamp == 0) {
            revert InvalidCooldownDeposit();
        }

        delete _depositsByOwner[msg.sender][depositId];

        penaltyAmount = (currentDeposit.amount * currentDeposit.depositType.penalty) / DENOMINATOR;

        uint256 enfToOwner = currentDeposit.amount - penaltyAmount;

        _enf.transfer(currentDeposit.owner, enfToOwner);

        _enf.burn(address(this), penaltyAmount / 2);

        updateRewardPool(penaltyAmount / 2, true);

        emit ClaimCooldownDeposit(msg.sender, currentDeposit.amount, enfToOwner);
    }

    function updateRewardPool(uint256 amount, bool add) private {
        unchecked {
            if (add) {
                _rewardPool += amount;
            } else {
                if (_rewardPool < amount) {
                    revert InsufficientRewardAmountLeft();
                }
                _rewardPool -= amount;
            }
        }
    }

    function recoverEnf(address to, uint256 amount) external onlyRole(OPERATIONAL_ROLE) {
        if (amount > _rewardPool) {
            revert InvalidAmountToRecover();
        }
        updateRewardPool(amount, false);
        _enf.transfer(to, amount);
        emit TokenRecovered(address(_enf), to, amount);
    }

    function releaseENFVesting(bytes32 vestingScheduleId) external onlyRole(OPERATIONAL_ROLE) {
        _vesting.release(vestingScheduleId);
        uint256 addedRewardPool = _enf.balanceOf(address(this)) - _rewardPool;
        _rewardPool += addedRewardPool;

        emit ReleaseENF(_rewardPool, addedRewardPool);
    }

    function pause() external onlyRole(OPERATIONAL_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OPERATIONAL_ROLE) {
        _unpause();
    }

    // setters
    function setEnf(IENF newEnf) external onlyRole(SETTER_ROLE) {
        _enf = newEnf;
        emit SetEnf(address(newEnf));
    }

    function setVesting(IENFVesting newVesting) external onlyRole(SETTER_ROLE) {
        _vesting = newVesting;
        emit SetVesting(address(newVesting));
    }

    function updateDepositsType(
        uint256 index,
        uint16 apr,
        uint16 penalty,
        uint32 duration,
        string calldata name,
        uint32 coolingDuration,
        bool canUnstakePriorMaturation
    ) external onlyRole(UPDATE_DESPOSIT_TYPE_ROLE) {
        if (index < _depositTypes.length) {
            _depositTypes[index] = DepositType({
                apr: apr,
                penalty: penalty,
                duration: duration,
                name: name,
                coolingDuration: coolingDuration,
                canUnstakePriorMaturation: canUnstakePriorMaturation
            });
            emit DepositUpdated(index, apr, penalty, duration, name, coolingDuration, canUnstakePriorMaturation, false);
        } else {
            _depositTypes.push(
                DepositType({
                    apr: apr,
                    penalty: penalty,
                    duration: duration,
                    name: name,
                    coolingDuration: coolingDuration,
                    canUnstakePriorMaturation: canUnstakePriorMaturation
                })
            );
            emit DepositUpdated(index, apr, penalty, duration, name, coolingDuration, canUnstakePriorMaturation, true);
        }
    }

    // getters
    function enf() external view returns (IERC20) {
        return _enf;
    }

    function vesting() external view returns (IENFVesting) {
        return _vesting;
    }

    function depositTypes() external view returns (DepositType[] memory) {
        return _depositTypes;
    }

    function depositsNumberPerOwner(address owner) external view returns (uint256) {
        return _depositsNumberPerOwner[owner];
    }

    function depositsByOwner(address owner) external view returns (Deposit[] memory) {
        uint256 i;
        uint256 depositNumber;
        for (i; i < _depositsNumberPerOwner[owner]; ++i) {
            if (_depositsByOwner[owner][i].owner != address(0)) {
                depositNumber++;
            }
        }
        Deposit[] memory deposits = new Deposit[](depositNumber);
        for (i = 0; i < depositNumber; ++i) {
            deposits[i] = _depositsByOwner[owner][i];
        }
        return deposits;
    }

    function rewardPool() external view returns (uint256) {
        return _rewardPool;
    }

    // events
    event Stake(
        address owner,
        uint256 amount,
        uint40 startTimestamp,
        uint40 endTimestamp,
        uint16 apr,
        uint16 penalty,
        uint40 duration
    );
    event UnstakePriorMaturity(address owner, uint256 depositId, uint40 coolingTimestamp);
    event UnstakeOnMaturity(address owner, uint256 depositId, uint256 unstakedAmount, uint256 reward);
    event Claim(address owner, uint256 amount);
    event ClaimCooldownDeposit(address owner, uint256 amountOfDeposit, uint256 claimedAmount);
    event SetEnf(address newContract);
    event SetVesting(address newContract);
    event SetPenalty(uint16 penalty);
    event DepositUpdated(
        uint256 index,
        uint16 apr,
        uint16 penalty,
        uint32 duration,
        string name,
        uint32 coolingDuration,
        bool canUnstakePriorMaturation,
        bool added
    );
    event ReleaseENF(uint256 totalfRewardPool, uint256 addedReward);
    event TokenRecovered(address token, address to, uint256 amount);
}

error InvalidAmount();
error InvalidDepositTypeIndex();
error InvalidDeposit();
error DepositIsNotMature();
error Unauthorized();
error CannotUnstakeAtThisTypeOfDeposit();
error DepositAlreadyUstaked();
error InvalidCooldownDeposit();
error InsufficientRewardAmountLeft();
error CoolingDeposit();
error NotEnoughTokens();
error InvalidAmountToRecover();
error InvalidAmountToUpdateRewardPool();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IENF is IERC20 {
    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IENFVesting {
    function release(bytes32 vestingScheduleId) external;
}

struct Deposit {
    uint40 startTimestamp;
    uint40 maturityTimestamp;
    uint40 coolingTimestamp;
    address owner;
    uint256 amount;
    uint256 reward;
    uint256 id;
    DepositType depositType;
}

struct DepositType {
    uint16 apr;
    uint16 penalty;
    uint40 duration;
    uint40 coolingDuration;
    bool canUnstakePriorMaturation;
    string name;
}

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