// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./VestingStructs.sol";

/**
 * @author Softbinator Technologies
 * @notice Contract with Vesting functionality over ENF token
 * @notice The vesting has multiple types:
 * @notice TEAM - maxAmount: 20.000.000, cliff: 24 months, vesting: 52 months
 * @notice MARKETING/DEVELOPMENT - maxAmount: 30.000.000, cliff: 1 months, vesting: 100 months
 * @notice SEED SALE - maxAmount: 10.000.000, cliff: 4 months, vesting: 36 months, tgePercent: 5%
 * @notice PRIVATE SALE - maxAmount: 25.000.000, cliff: 2 months, vesting: 34 months, tgePercent: 5%
 * @notice EARLY ADOPTERS - maxAmount: 15.000.000, cliff: 2 months, vesting: 16 months, tgePercent: 6%
 * @notice IDO - maxAmount: 2.000.000, cliff: 0 months, vesting: 4 months, tgePercent: 5%
 * @notice ADVISORS - maxAmount: 10.000.000, cliff: 12 months, vesting: 52 months
 * @notice LIQUIDITY/MARKET MAKING - maxAmount: 8.000.000, cliff: 5 months, vesting: 7 months, tgePercent: 10%
 * @notice STAKING REWARDS - maxAmount: 80.000.000, cliff: 0 months, vesting: 0 months
 */
contract ENFVesting is AccessControl, ReentrancyGuard {
    bytes32 public constant CREATE_VESTING_SCHEDULE_ROLE = keccak256("CREATE_VESTING_SCHEDULE_ROLE");
    uint128 public constant DENOMINATOR = 10_000;
    uint128 private _vestingContractStartingDate;
    IERC20 private _token;

    mapping(uint256 => VestingDetails) private _vestingDetails;
    mapping(bytes32 => VestingSchedule) private _vestings;
    mapping(address => uint256) private _addressVestingCount;

    constructor(IERC20 tokenAddress) {
        _token = tokenAddress;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CREATE_VESTING_SCHEDULE_ROLE, msg.sender);

        _vestingDetails[0] = VestingDetails("TEAM", 20_000_000 * 1e18, 24 * 30 days, 52 * 30 days, 0, 0);
        _vestingDetails[1] = VestingDetails("MARKETING/DEVELOPMENT", 30_000_000 * 1e18, 30 days, 100 * 30 days, 0, 0);
        _vestingDetails[2] = VestingDetails("SEED SALE", 10_000_000 * 1e18, 4 * 30 days, 36 * 30 days, 500, 0);
        _vestingDetails[3] = VestingDetails("PRIVATE SALE", 25_000_000 * 1e18, 2 * 30 days, 34 * 30 days, 500, 0);
        _vestingDetails[4] = VestingDetails("EARLY ADOPTERS", 15_000_000 * 1e18, 2 * 30 days, 16 * 30 days, 600, 0);
        _vestingDetails[5] = VestingDetails("IDO", 2_000_000 * 1e18, 0 * 30 days, 4 * 30 days, 500, 0);
        _vestingDetails[6] = VestingDetails("ADVISORS", 10_000_000 * 1e18, 12 * 30 days, 52 * 30 days, 0, 0);
        _vestingDetails[7] = VestingDetails(
            "LIQUIDITY / MARKET MAKING",
            8_000_000 * 1e18,
            5 * 30 days,
            7 * 30 days,
            1_000,
            0
        );
        _vestingDetails[8] = VestingDetails("STAKING REWARDS", 80_000_000 * 1e18, 0 * 30 days, 0 * 30 days, 0, 0);
    }

    /**
     * @notice Create a vesting schedule for an address with one of the predefined types of vesting plans.
     * @notice this function is accesible only to addresses with special role: CREATE_VESTING_SCHEDULE_ROLE
     * @param beneficiary the address of the vesting schedule that can claim the tokens
     * @param vestingDetailsIndex index of the vesting types. Btw 0-9
     * @param amount amount that is locked according to the vesting type
     */
    function createVestingSchedule(
        address beneficiary,
        uint256 vestingDetailsIndex,
        uint256 amount
    ) private {
        if (beneficiary == address(0)) {
            revert InvalidBeneficiary();
        }
        /// @dev check if vesting type exists
        if (_vestingDetails[vestingDetailsIndex].totalAmount == 0) {
            revert InvalidVestingIndexPlan();
        }
        /// @dev check if vesting type can accept more funds
        if (
            amount + _vestingDetails[vestingDetailsIndex].currentAmount >
            _vestingDetails[vestingDetailsIndex].totalAmount
        ) {
            revert InvalidAmountForVestingPlan();
        }

        _vestingDetails[vestingDetailsIndex].currentAmount += amount;

        bytes32 id = computeNextVestingIdForHolder(beneficiary);

        _vestings[id] = VestingSchedule(beneficiary, amount, 0, _vestingDetails[vestingDetailsIndex]);
        ++_addressVestingCount[beneficiary];

        emit CreateVestingSchedule(beneficiary, vestingDetailsIndex, amount, _addressVestingCount[beneficiary] - 1);
    }

    /**
     * @notice Create a vesting schedules for an array of addresses with predefined types of vesting plans.
     * @notice this function is accesible only to addresses with special role: CREATE_VESTING_SCHEDULE_ROLE
     * @param beneficiaries array of addresses of the vesting schedule that can claim the tokens
     * @param vestingDetailsIndexes arary of indexes of the vesting types. Btw 0-9
     * @param amounts array of amounts that are locked according to the vesting type
     */
    function createVestingSchedules(
        address[] calldata beneficiaries,
        uint256[] calldata vestingDetailsIndexes,
        uint256[] memory amounts
    ) external onlyRole(CREATE_VESTING_SCHEDULE_ROLE) {
        uint256 i;
        if (beneficiaries.length != vestingDetailsIndexes.length || beneficiaries.length != amounts.length) {
            revert WrongParam();
        }
        for (i; i < beneficiaries.length; ++i) {
            createVestingSchedule(beneficiaries[i], vestingDetailsIndexes[i], amounts[i]);
        }
    }

    /**
     * @notice Claim released tokens. Can be called only by the beneficiary of the vesting schedule
     * @param vestingScheduleId represents the computed id of a vesting schedule. It is computed from beneficiary address and index of vestingSchedule
     */
    function release(bytes32 vestingScheduleId) external nonReentrant {
        VestingSchedule storage vest = _vestings[vestingScheduleId];

        /// @dev check if selected vesting exists
        if (vest.vestedAmount == 0) {
            revert InvalidVestingScheduleId();
        }

        if (msg.sender != vest.beneficiary) {
            revert RelaseCanBeExecutedOnlyByOwnerOfTokens();
        }

        uint256 releaseToSend = getReleaseAmount(vestingScheduleId);

        vest.releasedAmount += releaseToSend;

        if (vest.releasedAmount > vest.vestedAmount) {
            releaseToSend = vest.vestedAmount - (vest.releasedAmount - releaseToSend);
            vest.releasedAmount = vest.vestedAmount;
            emit ReleaseIssue(vest.beneficiary, releaseToSend);
        }

        bool success = _token.transfer(vest.beneficiary, releaseToSend);
        if (!success) {
            revert TransferFailed();
        }
        emit Release(vest.beneficiary, releaseToSend);
    }

    /**
     * @notice View function for calculating releasable tokens
     * @param vestingScheduleId represents the computed id of a vesting schedule. It is computed from beneficiary address and index of vestingSchedule
     * @return vestedAmount current amount that can be claimed by beneficiary.
     */
    function getReleaseAmount(bytes32 vestingScheduleId) public view returns (uint256) {
        if (_vestingContractStartingDate == 0) {
            return 0;
        }
        VestingSchedule memory vestingSchedule = _vestings[vestingScheduleId];
        if (vestingSchedule.vestedAmount == 0) {
            revert InvalidVestingScheduleId();
        }
        uint256 currentTime = block.timestamp;
        uint256 vestingStartDate = _vestingContractStartingDate + vestingSchedule.vestingDetails.cliff;
        uint256 tgeAmount;

        if (currentTime < _vestingContractStartingDate) {
            return 0;
        }
        if (currentTime < vestingStartDate) {
            if (vestingSchedule.vestingDetails.tgePercent <= 0) {
                return 0;
            }

            tgeAmount =
                (vestingSchedule.vestedAmount * vestingSchedule.vestingDetails.tgePercent) /
                DENOMINATOR -
                vestingSchedule.releasedAmount;
            return tgeAmount;
        } else if (currentTime >= vestingStartDate + vestingSchedule.vestingDetails.duration) {
            return vestingSchedule.vestedAmount - vestingSchedule.releasedAmount;
        } else {
            if (vestingSchedule.vestingDetails.tgePercent != 0) {
                tgeAmount = (vestingSchedule.vestedAmount * vestingSchedule.vestingDetails.tgePercent) / DENOMINATOR;
            }

            uint256 vestedPeriod = currentTime - vestingStartDate;
            uint256 vestedAmount = ((vestingSchedule.vestedAmount - tgeAmount) * vestedPeriod) /
                vestingSchedule.vestingDetails.duration;
            vestedAmount = vestedAmount + tgeAmount - vestingSchedule.releasedAmount;
            return vestedAmount;
        }
    }

    function setVestingContractStartingDate(uint128 newVestingContractStartingDate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_vestingContractStartingDate != 0) {
            revert VestingDateWasSetted();
        }
        _vestingContractStartingDate = newVestingContractStartingDate;
        emit SetVestingDate(newVestingContractStartingDate);
    }

    function vestingContractStartingDate() external view returns (uint128) {
        return _vestingContractStartingDate;
    }

    function computeNextVestingIdForHolder(address holder) public view returns (bytes32) {
        return computeVestingIdForAddressAndIndex(holder, _addressVestingCount[holder]);
    }

    function computeVestingIdForAddressAndIndex(address to, uint256 index) public pure returns (bytes32) {
        return keccak256(abi.encode(to, index));
    }

    /**
     * @notice View function to get all vesting schedule ids for an address
     * @param beneficiary the address for which it is searched
     * @return ids array with ids. The lenght is given by _addressVestingCount[_beneficiary]
     */
    function getVestingSchedulesIds(address beneficiary) public view returns (bytes32[] memory) {
        uint256 count = _addressVestingCount[beneficiary];
        bytes32[] memory ids = new bytes32[](count);
        uint256 i;
        for (i; i < count; ++i) {
            ids[i] = computeVestingIdForAddressAndIndex(beneficiary, i);
        }
        return ids;
    }

    function vestings(bytes32 vestingId) external view returns (VestingSchedule memory) {
        return _vestings[vestingId];
    }

    function vestingDetails(uint256 index) external view returns (VestingDetails memory) {
        return _vestingDetails[index];
    }

    function addressVestingCount(address beneficiary) external view returns (uint256) {
        return _addressVestingCount[beneficiary];
    }

    function token() external view returns (IERC20) {
        return _token;
    }

    function setToken(IERC20 newToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _token = newToken;
        emit SetToken(newToken);
    }

    function calculateTgeAmount(bytes32 vestingScheduleId) external view returns (uint256) {
        VestingSchedule memory vest = _vestings[vestingScheduleId];
        return (vest.vestedAmount * vest.vestingDetails.tgePercent) / DENOMINATOR;
    }

    function endOfCliff(bytes32 vestingScheduleId) external view returns (uint256) {
        VestingSchedule memory vest = _vestings[vestingScheduleId];
        return _vestingContractStartingDate + vest.vestingDetails.cliff;
    }

    function endOfVesting(bytes32 vestingScheduleId) external view returns (uint256) {
        VestingSchedule memory vest = _vestings[vestingScheduleId];
        return _vestingContractStartingDate + vest.vestingDetails.cliff + vest.vestingDetails.duration;
    }

    event CreateVestingSchedule(
        address indexed beneficiary,
        uint256 indexed vestingDetailsIndex,
        uint256 amount,
        uint256 currentNumberOfVestedSchedules
    );
    event Release(address indexed beneficiary, uint256 releaseToSend);
    event ReleaseIssue(address indexed account, uint256 amount);
    event SetToken(IERC20 newAddress);
    event SetVestingDate(uint128 newVestingDate);

    error InvalidBeneficiary();
    error InvalidVestingIndexPlan();
    error InvalidAmountForVestingPlan();
    error InvalidVestingScheduleId();
    error RelaseCanBeExecutedOnlyByOwnerOfTokens();
    error TransferFailed();
    error InvalidReleasedAmount();
    error WrongParam();
    error VestingDateWasSetted();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

struct VestingDetails {
    string name;
    uint256 totalAmount;
    uint256 cliff;
    uint256 duration;
    // percent meaning 1000 = 10%
    uint256 tgePercent;
    uint256 currentAmount;
}

struct VestingSchedule {
    address beneficiary;
    uint256 vestedAmount;
    uint256 releasedAmount;
    VestingDetails vestingDetails;
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