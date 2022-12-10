// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./utils/IBalanceVaultV2.sol";

/**
 * @dev Use for stake token and distribute reward.
 * Has a function to add reward to staking pool.
 * Has a function to update reward per token per hour according to contract state variables.
 * Has a function to set user withdraw delay for participating in other contract event.
 * Has functions to stake, withdraw and claim reward.
 * Has functions to calculate stake level refer to setted milestone and time value.
 * Has functions to retrieve pool, user and time relate information.
 * @notice Is pausable to prevent malicious behavior.
 */
contract StakingLevel is Ownable, AccessControl, ReentrancyGuard, Pausable {
    struct UserInfo {
        uint256 currentStakeAmount;
        uint256 currentStakeLevelValidTime;
        uint256 lastValidStakeLevelAmount;
        uint256 lastClaimTime;
        uint256 withdrawDelay;
    }

    bytes32 public constant WORKER = keccak256("WORKER");
    uint256 public constant REWARDPRECISION = 10000000000;
    uint256 public constant DAYEPOCH = 86400;
    uint256 public constant HOUREPOCH = 3600;

    IBalanceVaultV2 public balanceVault;

    mapping(address => UserInfo) public userInfo;
    uint256 public totalPoolStake;
    uint256 public totalPoolReward;
    uint256 public rewardPerTokenPerHour;
    uint256 public rewardCapTime;
    uint256 public stakeLevelDelay;
    uint256[] public stakeLevelRange;

    event UpOnlyStaked(address indexed userAddress, uint256 upoAmount);
    event WithdrawnUpOnly(address indexed userAddress, uint256 upoAmount);
    event RewardClaimed(address indexed userAddress, uint256 upoAmount);
    event PoolRewardAdded(uint256 upoAmount);
    event RewardUpdated(uint256 rewardPerTokenPerHour);
    event WithdrawDelayUpdated(address indexed userAddress, uint256 endDate);
    event RewardCapTimeUpdated(uint256 rewardCapTime);
    event StakeLevelDelayUpdated(uint256 day);
    event StakeLevelRangeUpdated(uint256[] stakeLevelRange);
    event BalanceVaultAddressUpdated(address balanceVaultAddress);

    constructor(
        address _balanceVaultAddress,
        uint256 _rewardCapTime,
        uint256 _stakeLevelDelay,
        uint256[] memory _stakeLevelRange
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(WORKER, msg.sender);

        setBalanceVaultAddress(_balanceVaultAddress);
        setRewardCapTime(_rewardCapTime);
        setStakeLevelDelay(_stakeLevelDelay);
        setStakeLevelRange(_stakeLevelRange);
    }

    /**
     * @dev Revert receive and fallback functions.
     */
    receive() external payable {
        revert("[StakingLevel] Revert receive function");
    }

    fallback() external payable {
        revert("[StakingLevel] Revert fallback function");
    }

    function increaseUserTime(address _userAddress, uint256 _time) external {
        UserInfo storage user = userInfo[_userAddress];
        user.currentStakeLevelValidTime -= _time;
        user.lastClaimTime -= _time;
        user.withdrawDelay -= _time;
    }

    /**
     * @dev Set staking level in to pause and unpause state.
     */
    function pauseStakingLevel() external onlyOwner {
        _pause();
    }

    function unpauseStakingLevel() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Add staking pool reward.
     * @param _upoAmount - upo amount to be added.
     */
    function addPoolReward(address _userAddress, uint256 _upoAmount)
        external
        whenNotPaused
        onlyRole(WORKER)
    {
        balanceVault.payWithUpo(_userAddress, _upoAmount);
        totalPoolReward += _upoAmount;

        emit PoolRewardAdded(_upoAmount);
    }

    /**
     * @dev Update new reward per hour.
     * Using calculation formula: reward per token / 24 hours / multiplier
     * @param _multiplier - calculated from distribute duration * spare multiplier.
     */
    function updateRewardPerTokenPerHour(uint256 _multiplier)
        external
        whenNotPaused
        onlyRole(WORKER)
    {
        // case: _multiplier = 60 && rewardCapTime = 30
        // ex1. this reward could be distribute for 60 day on normal case
        // ex2. this reward could be distribute for 30 day if user stacked reward to max and claim at reward updated day.
        // ex3. this reward could be distribute for 30 day if there is new stake amount equal to 2 time of existing amount.
        // ex4. this reward could be distribute for 15 day if user stacked reward to max and claim at reward updated day and there is new stake amount equal to 2 time of existing amount.
        if (totalPoolStake == 0) {
            rewardPerTokenPerHour = 0;
        } else {
            rewardPerTokenPerHour =
                (REWARDPRECISION * totalPoolReward) /
                totalPoolStake /
                24 /
                _multiplier;
        }

        emit RewardUpdated(rewardPerTokenPerHour);
    }

    /**
     * @dev Set delay before user can withdraw.
     * Should be called by other contract function.
     * @param _userAddress - user address to delay withdraw time.
     * @param _endDate - end of withdraw delay.
     */
    function setWithdrawDelay(address _userAddress, uint256 _endDate)
        external
        whenNotPaused
        onlyRole(WORKER)
    {
        UserInfo storage user = userInfo[_userAddress];
        if (_endDate > user.withdrawDelay) {
            user.withdrawDelay = _endDate;

            emit WithdrawDelayUpdated(_userAddress, _endDate);
        }
    }

    /**
     * @dev Stake token and force claim remaining reward.
     */
    function stakeUpOnly(uint256 _upoAmount) external whenNotPaused {
        UserInfo storage user = userInfo[msg.sender];
        (, uint256 unclaimAmount) = getUserUnclaimInfo(msg.sender);
        if (unclaimAmount != 0) {
            _claimReward();
        }
        // Reset claim time
        user.lastClaimTime = block.timestamp;

        // Update last valid amount to current amount if new user/not pending
        if (user.currentStakeLevelValidTime < block.timestamp) {
            user.lastValidStakeLevelAmount = user.currentStakeAmount;
        }
        user.currentStakeAmount += _upoAmount;
        user.currentStakeLevelValidTime = block.timestamp + stakeLevelDelay;
        totalPoolStake += _upoAmount;
        balanceVault.payWithUpo(msg.sender, _upoAmount);

        emit UpOnlyStaked(msg.sender, _upoAmount);
    }

    /**
     * @dev Withdraw staked token and force claim remaining reward.
     */
    function withdrawUpOnly(uint256 _upoAmount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(
            _upoAmount <= user.currentStakeAmount,
            "[StakingLevel.withdrawaUpOnly] Withdraw amount exceed stake amount."
        );
        require(
            user.withdrawDelay <= block.timestamp,
            "[StakingLevel.withdrawaUpOnly] In withdraw delay period."
        );
        (, uint256 unclaimAmount) = getUserUnclaimInfo(msg.sender);
        if (unclaimAmount != 0) {
            _claimReward();
        }
        // Reset claim time
        user.lastClaimTime = block.timestamp;

        // Remove pending status if currently pending and level decrease(new amount is less than last valid amount)
        if (
            user.currentStakeLevelValidTime >= block.timestamp &&
            (user.currentStakeAmount - _upoAmount) <
            user.lastValidStakeLevelAmount
        ) {
            user.currentStakeLevelValidTime = block.timestamp;
        }
        totalPoolStake -= _upoAmount;
        user.currentStakeAmount -= _upoAmount;
        balanceVault.transferUpoToAddress(msg.sender, _upoAmount);

        emit WithdrawnUpOnly(msg.sender, _upoAmount);
    }

    /**
     * @dev Retrieve user infomation including stake and time record detail.
     * @param _userAddress - user address.
     */
    function getUserInfo(address _userAddress)
        external
        view
        returns (
            uint256 stakeAmount,
            uint256 stakeLevelValidTime,
            uint256 stakeLevel,
            uint256 lastClaimTime,
            uint256 validClaimHour,
            uint256 unclaimAmount,
            uint256 withdrawDelay
        )
    {
        UserInfo storage user = userInfo[_userAddress];
        stakeAmount = user.currentStakeAmount;
        stakeLevelValidTime = user.currentStakeLevelValidTime;
        stakeLevel = getUserStakeLevel(_userAddress);
        lastClaimTime = user.lastClaimTime;
        (validClaimHour, unclaimAmount) = getUserUnclaimInfo(_userAddress);
        withdrawDelay = user.withdrawDelay;
    }

    /**
     * @dev Retrieve size of stake level range array.
     */
    function getStakeLevelRangeSize() external view returns (uint256) {
        return stakeLevelRange.length;
    }

    /**
     * @dev Function for update reward cap time.
     * @param _rewardCapTime - reward cap time.
     */
    function setRewardCapTime(uint256 _rewardCapTime)
        public
        whenNotPaused
        onlyOwner
    {
        rewardCapTime = _rewardCapTime;

        emit RewardCapTimeUpdated(_rewardCapTime);
    }

    /**
     * @dev Set delay before stake level is active after stake.
     * @param _stakeLevelDelay - stake level delay.
     */
    function setStakeLevelDelay(uint256 _stakeLevelDelay)
        public
        whenNotPaused
        onlyOwner
    {
        stakeLevelDelay = _stakeLevelDelay;

        emit StakeLevelDelayUpdated(_stakeLevelDelay);
    }

    /**
     * @dev Set stake level milestone array for stake level calculation.
     * @param _stakeLevelRange - stake level range array.
     */
    function setStakeLevelRange(uint256[] memory _stakeLevelRange)
        public
        whenNotPaused
        onlyOwner
    {
        stakeLevelRange = _stakeLevelRange;

        emit StakeLevelRangeUpdated(_stakeLevelRange);
    }

    /**
     * @dev Set new address for balance vault using specify address.
     * @param _balanceVaultAddress - New address of balance vault.
     */
    function setBalanceVaultAddress(address _balanceVaultAddress)
        public
        onlyOwner
    {
        balanceVault = IBalanceVaultV2(_balanceVaultAddress);

        emit BalanceVaultAddressUpdated(_balanceVaultAddress);
    }

    /**
     * @dev Claim reward for external call adding non reentrant.
     */
    function claimReward() external nonReentrant {
        _claimReward();
    }

    /**
     * @dev Retrieve current user stake level.
     * @param _userAddress - user address.
     */
    function getUserStakeLevel(address _userAddress)
        public
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_userAddress];
        uint256 validAmount;

        if (user.currentStakeLevelValidTime < block.timestamp) {
            validAmount = user.currentStakeAmount;
        } else {
            validAmount = user.lastValidStakeLevelAmount;
        }
        return getStakeLevel(validAmount);
    }

    /**
     * @dev Calculate user stake level from input amount.
     * @param _stakeAmount - amount to be used for stake level calculation.
     */
    function getStakeLevel(uint256 _stakeAmount) public view returns (uint256) {
        uint256 stakeLevel = 1;
        for (uint256 i = stakeLevelRange.length - 1; i > 0; i--) {
            if (_stakeAmount > stakeLevelRange[i]) {
                stakeLevel = (i + 1);
                break;
            }
        }
        return stakeLevel;
    }

    /**
     * @dev Retrieve user valid claim hour and unclaim amount.
     * @param _userAddress - user address.
     */
    function getUserUnclaimInfo(address _userAddress)
        public
        view
        returns (uint256 validClaimHour, uint256 unclaimAmount)
    {
        UserInfo storage user = userInfo[_userAddress];
        uint256 timeFromLastClaim = block.timestamp - user.lastClaimTime;
        uint256 validClaimTime = timeFromLastClaim > rewardCapTime
            ? rewardCapTime
            : timeFromLastClaim;
        validClaimHour =
            (validClaimTime - (validClaimTime % HOUREPOCH)) /
            HOUREPOCH;
        unclaimAmount =
            (validClaimHour * user.currentStakeAmount * rewardPerTokenPerHour) /
            REWARDPRECISION;
    }

    /**
     * @dev Claim all remaining staking reward to user wallet.
     */
    function _claimReward() internal {
        UserInfo storage user = userInfo[msg.sender];
        (uint256 validClaimHour, uint256 unclaimAmount) = getUserUnclaimInfo(
            msg.sender
        );

        require(
            unclaimAmount > 0,
            "[StakingLevel.claimReward] No claimable reward."
        );
        require(
            totalPoolReward > unclaimAmount,
            "[StakingLevel.claimReward] Pool reward underflow"
        );

        // reset last claim time if user claim at maxed reward
        if (validClaimHour == (rewardCapTime / HOUREPOCH)) {
            user.lastClaimTime = block.timestamp;
        } else {
            user.lastClaimTime += (validClaimHour * HOUREPOCH);
        }
        totalPoolReward -= unclaimAmount;
        balanceVault.transferUpoToAddress(msg.sender, unclaimAmount);

        emit RewardClaimed(msg.sender, unclaimAmount);
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
pragma solidity ^0.8.7;

interface IBalanceVaultV2 {
    // UPO
    function getBalance(address _userAddress) external view returns (uint256);
    function depositUpo(uint256 _upoAmount) external;
    function withdrawUpo(uint256 _upoAmount) external;
    function increaseBalance(address _userAddress, uint256 _upoAmount) external;
    function decreaseBalance(address _userAddress, uint256 _upoAmount) external;
    function payWithUpo(address _userAddress, uint256 _upoAmount) external;
    function transferUpoToAddress(address _userAddress, uint256 _upoAmount) external;

    // Token
    function getTokenBalance(address _userAddress, address _tokenAddress) external view returns (uint256);
    function depositToken(address _tokenAddress, uint256 _tokenAmount) external;
    function withdrawToken(address _tokenAddress, uint256 _tokenAmount) external;
    function increaseTokenBalance(address _userAddress, address _tokenAddress, uint256 _upoAmount) external;
    function decreaseTokenBalance(address _userAddress, address _tokenAddress, uint256 _upoAmount) external;
    function payWithToken(address _userAddress, address _tokenAddress, uint256 _upoAmount) external;
    function transferTokenToAddress(address _userAddress, address _tokenAddress, uint256 _tokenAmount) external;
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