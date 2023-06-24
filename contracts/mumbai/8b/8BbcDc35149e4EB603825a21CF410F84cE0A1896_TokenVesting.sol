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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IAccessControlHolder {
    function acl() external view returns (IAccessControl);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

/// @title IWithFees interface
/// @notice This interface describes the functions for managing fees in a contract.
interface IWithFees {
    error OnlyFeesManagerAccess();
    error OnlyWithFees();
    error ETHTransferFailed();

    /// @notice Returns the treasury address where fees are collected.
    /// @return The address of the treasury.
    function treasury() external view returns (address);

    /// @notice Returns the value of the fees.
    /// @return The value of the fees.
    function value() external view returns (uint256);

    /// @notice Transfers the collected fees to the treasury address.
    function transfer() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Decimals is IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./tokens/interfaces/IERC20Decimals.sol";

/// @title TransferGuard
/// @notice This contract provides functionality to safely transfer and transferFrom ERC20 tokens.
contract TransferGuard {
    /// @dev Error that is thrown when transfer function returns
    error TransferFailed();

    /// @notice Transfers tokens from one address to another using the transferFrom function of the ERC20 token.
    /// @dev If the transferFrom function of the ERC20 token returns false, the transaction is reverted with a TransferFailed error.
    /// @param token The ERC20 token to transfer.
    /// @param from The address to transfer tokens from.
    /// @param to The address to transfer tokens to.
    /// @param amount The amount of tokens to transfer.
    function _transferFromERC20(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (!token.transferFrom(from, to, amount)) {
            revert TransferFailed();
        }
    }

    /// @notice Transfers tokens to an address using the transfer function of the ERC20 token.
    /// @dev If the transfer function of the ERC20 token returns false, the transaction is reverted with a TransferFailed error.
    /// @param token The ERC20 token to transfer.
    /// @param to The address to transfer tokens to.
    /// @param amount The amount of tokens to transfer.
    function _transferERC20(IERC20 token, address to, uint256 amount) internal {
        if (!token.transfer(to, amount)) {
            revert TransferFailed();
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

/// @title ITokenVesting
/// @notice This is an interface for token vesting. It includes functionalities for adding vesting schedules and claiming vested tokens.
interface ITokenVesting {
    /// @dev Errors that describe failures in the contract.
    error InvalidScheduleID();
    error VestingNotStarted();
    error AllTokensClaimed();
    error NothingToClaim();
    error OnlyVestingManagerAccess();

    /// @notice Emitted when a new vesting schedule is added for a beneficiary.
    /// @param beneficiary Address of the beneficiary.
    /// @param allocationId Identifier of the vesting schedule.
    /// @param startTime Start time of the vesting schedule.
    /// @param endTime End time of the vesting schedule.
    /// @param amount Total amount of tokens to be vested.
    event VestingAdded(
        address indexed beneficiary,
        uint256 indexed allocationId,
        uint256 startTime,
        uint256 endTime,
        uint256 amount
    );

    /// @notice Emitted when a beneficiary withdraws vested tokens.
    /// @param beneficiary Address of the beneficiary.
    /// @param allocationId Identifier of the vesting schedule.
    /// @param value Amount of tokens withdrawn.
    event TokenWithdrawn(
        address indexed beneficiary,
        uint256 indexed allocationId,
        uint256 value
    );

    /// @notice Struct for vesting schedule details.
    struct Vesting {
        uint256 startTime; // Start time of the vesting schedule.
        uint256 endTime; // End time of the vesting schedule.
        uint256 totalAmount; // Total amount of tokens to be vested.
        uint256 claimedAmount; // Amount of tokens already claimed by the beneficiary.
    }

    /// @notice Adds a vesting schedule for a beneficiary.
    /// @param beneficiary Address of the beneficiary.
    /// @param startTime Start time of the vesting schedule.
    /// @param duration Duration of the vesting schedule.
    /// @param amount Total amount of tokens to be vested.
    function addVesting(
        address beneficiary,
        uint256 startTime,
        uint256 duration,
        uint256 amount
    ) external;

    /// @notice Allows a beneficiary to claim vested tokens.
    /// @param scheduleIds Array of identifiers for the vesting schedules.
    function claim(uint256[] calldata scheduleIds) external payable;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./ITokenVesting.sol";
import "../WithFees.sol";
import "../ZeroAddressGuard.sol";
import "../ZeroAmountGuard.sol";
import "../TransferGuard.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title TokenVesting
/// @notice This contract is used for creating vesting schedules for token allocations and allowing beneficiaries to claim their vested tokens.
/// @dev It includes role-based access control for a vesting manager and incorporates various guards to prevent invalid operations.
contract TokenVesting is
    ITokenVesting,
    WithFees,
    ZeroAddressGuard,
    ZeroAmountGuard,
    TransferGuard
{
    /// @dev Hash of the string "VESTING_MANAGER".
    bytes32 public constant VESTING_MANAGER = keccak256("VESTING_MANAGER");

    /// @dev Hash of the string "MAX_SCHEDULES".
    bytes32 public constant MAX_SCHEDULES = keccak256("MAX_SCHEDULES");

    /// @notice The ERC20 token used for vesting.
    IERC20 public immutable token;

    /// @notice Mapping from beneficiary addresses to arrays of their vesting schedules.
    mapping(address => Vesting[]) public vestingSchedules;

    /// @dev Modifier that allows only the vesting manager to call a function.
    modifier onlyVestingManagerAccess() {
        if (!acl.hasRole(VESTING_MANAGER, msg.sender)) {
            revert OnlyVestingManagerAccess();
        }
        _;
    }

    /// @notice Creates a new TokenVesting contract.
    /// @param _token The ERC20 token used for vesting.
    /// @param _acl The address of the access control contract.
    /// @param _treasury The address of the treasury.
    /// @param _value The value of the contract.
    constructor(
        IERC20 _token,
        IAccessControl _acl,
        address _treasury,
        uint256 _value
    ) WithFees(_acl, _treasury, _value) {
        token = _token;
    }

    /// @notice Adds a new vesting schedule for a beneficiary.
    /// @dev The tokens for the vesting schedule are transferred from the sender to this contract.
    /// @param beneficiary The address of the beneficiary.
    /// @param startTime The start time of the vesting schedule.
    /// @param duration The duration of the vesting schedule.
    /// @param amount The total amount of tokens to be vested.
    function addVesting(
        address beneficiary,
        uint256 startTime,
        uint256 duration,
        uint256 amount
    )
        external
        onlyVestingManagerAccess
        notZeroAddress(beneficiary)
        notZeroAmount(duration)
        notZeroAmount(amount)
    {
        _transferFromERC20(token, msg.sender, address(this), amount);
        uint256 endTime = startTime + duration;
        vestingSchedules[beneficiary].push(
            Vesting({
                startTime: startTime,
                endTime: endTime,
                totalAmount: amount,
                claimedAmount: 0
            })
        );

        emit VestingAdded(
            beneficiary,
            vestingSchedules[beneficiary].length - 1,
            startTime,
            endTime,
            amount
        );
    }

    /// @notice Allows a beneficiary to claim their vested tokens
    /// @param scheduleIds The IDs of the vesting schedules to claim tokens from
    /// @dev if a scheduleId is bigger than last index of the schedules, the function reverts with InvalidScheduleID
    /// @dev if the timestamp is lower than vesting start, the function reverts with VestingNotStarted.
    /// @dev if a user has already withdrawn all tokens, the funciton reverts with AllTokensClaimed.
    /// @dev if the transfer function returns bool, the function reverts with error TransferFailed.
    function claim(
        uint256[] calldata scheduleIds
    ) external payable onlyWithFees {
        uint256 claimableAmount = 0;
        Vesting[] storage schedules = vestingSchedules[msg.sender];
        uint256 scheduleIdsLength = scheduleIds.length;

        for (uint256 i = 0; i < scheduleIdsLength; ) {
            uint256 id = scheduleIds[i];

            if (id >= schedules.length) {
                revert InvalidScheduleID();
            }

            Vesting storage vestingSchedule = schedules[id];

            if (block.timestamp < vestingSchedule.startTime) {
                revert VestingNotStarted();
            }

            if (vestingSchedule.totalAmount <= vestingSchedule.claimedAmount) {
                revert AllTokensClaimed();
            }

            uint256 vestingDuration = vestingSchedule.endTime -
                vestingSchedule.startTime;
            uint256 elapsedTime = block.timestamp > vestingSchedule.endTime
                ? vestingDuration
                : block.timestamp - vestingSchedule.startTime;

            uint256 vestedAmount = (vestingSchedule.totalAmount * elapsedTime) /
                vestingDuration;
            uint256 unclaimedAmount = vestedAmount -
                vestingSchedule.claimedAmount;

            vestingSchedule.claimedAmount = vestedAmount;
            claimableAmount += unclaimedAmount;

            emit TokenWithdrawn(msg.sender, id, unclaimedAmount);

            unchecked {
                ++i;
            }
        }

        _transferERC20(token, msg.sender, claimableAmount);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./IAccessControlHolder.sol";
import "./IWithFees.sol";

/// @title Contract for handling Fees
/// @notice This contract is responsible for managing, calculating and transferring fees
contract WithFees is IAccessControlHolder, IWithFees {
    /// @notice Treasury address where fees are transferred to
    address public immutable override treasury;

    /// @notice The value of fees charged
    uint256 public immutable override value;

    /// @notice The Access Control List contract instance
    IAccessControl public immutable override acl;

    /// @notice Identifier for the FEES_MANAGER role
    bytes32 public constant FEES_MANAGER = keccak256("FEES_MANAGER");

    /// @notice Modifier to allow only function calls that are accompanied by the required fee
    modifier onlyWithFees() {
        if (value > msg.value) {
            revert OnlyWithFees();
        }
        _;
    }

    /// @notice Modifier to allow only accounts with FEES_MANAGER role
    modifier onlyFeesManagerAccess() {
        if (!acl.hasRole(FEES_MANAGER, msg.sender)) {
            revert OnlyFeesManagerAccess();
        }
        _;
    }

    /// @dev Constructor to initialize the WithFees contract
    /// @param _acl IAccessControl instance
    /// @param _treasury The treasury address
    /// @param _value The fee value
    constructor(IAccessControl _acl, address _treasury, uint256 _value) {
        acl = _acl;
        treasury = _treasury;
        value = _value;
    }

    /// @notice Transfers the balance of the contract to the treasury
    /// @dev Only accessible by an account with the FEES_MANAGER role
    function transfer() external onlyFeesManagerAccess {
        (bool sent, ) = treasury.call{value: address(this).balance}("");
        if (!sent) {
            revert ETHTransferFailed();
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

/// @title ZeroAddressGuard
/// @notice This contract is responsible for ensuring that a given address is not a zero address.
contract ZeroAddressGuard {
    /// @dev Error that is thrown when zero address is given.
    error ZeroAddress();

    /// @notice Modifier to make a function callable only when the provided address is non-zero.
    /// @param _addr Address to be checked.
    /// @dev If the address is a zero address, the function reverts with ZeroAddress error.
    modifier notZeroAddress(address _addr) {
        _ensureIsNotZeroAddress(_addr);
        _;
    }

    /// @notice Checks if a given address is a zero address and reverts if it is.
    /// @param _addr Address to be checked.
    /// @dev If the address is a zero address, the function reverts with ZeroAddress error.
    function _ensureIsNotZeroAddress(address _addr) internal pure {
        if (_addr == address(0)) {
            revert ZeroAddress();
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

/// @title ZeroAmountGuard
/// @notice This contract provides a modifier to guard against zero values in a transaction.
contract ZeroAmountGuard {
    /// @dev Error that is thrown when an amount of zero is given.
    error ZeroAmount();

    /// @notice Ensures the amount provided is not zero.
    /// @param _amount The amount to check.
    /// @dev If the amount is zero, the function reverts with a ZeroAmount error.
    modifier notZeroAmount(uint256 _amount) {
        _ensureIsNotZero(_amount);
        _;
    }

    /// @notice Verifies that the given amount is not zero.
    /// @param _amount The amount to check.
    /// @dev If the amount is zero, the function reverts with a ZeroAmount error.
    function _ensureIsNotZero(uint256 _amount) internal pure {
        if (_amount == 0) {
            revert ZeroAmount();
        }
    }
}