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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IAccessControlHolder {
    function acl() external view returns (IAccessControl);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

interface IWithFees {
    error OnlyFeesManagerAccess();
    error OnlyWithFees();
    error ETHTransferFailed();

    function treasury() external view returns (address);

    function value() external view returns (uint256);

    function transfer() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

interface ITokenVesting {
    error InvalidScheduleID();
    error VestingNotStarted();
    error AllTokensClaimed();
    error ZeroTokens();
    error ZeroDuration();
    error TransferFailed();
    error NothingToClaim();

    event VestingAdded(
        address indexed beneficiary,
        uint256 indexed allocationId,
        uint256 startTime,
        uint256 endTime,
        uint256 amount
    );

    event TokenWithdrawn(
        address indexed beneficiary,
        uint256 indexed allocationId,
        uint256 value
    );

    struct Vesting {
        uint256 startTime;
        uint256 endTime;
        uint256 totalAmount;
        uint256 claimedAmount;
    }

    function addVesting(
        address beneficiary,
        uint256 startTime,
        uint256 duration,
        uint256 amount
    ) external;

    function claim(uint256[] calldata scheduleIds) external payable;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITokenVesting.sol";
import "../WithFees.sol";

contract TokenVesting is ITokenVesting, WithFees {
    IERC20 public immutable token;
    mapping(address => Vesting[]) public vestingSchedules;

    constructor(
        IERC20 _token,
        IAccessControl _acl,
        address _treasury,
        uint256 _value
    ) WithFees(_acl, _treasury, _value) {
        token = _token;
    }

    function addVesting(
        address beneficiary,
        uint256 startTime,
        uint256 duration,
        uint256 amount
    ) public {
        if (amount == 0) {
            revert ZeroTokens();
        }
        if (duration == 0) {
            revert ZeroDuration();
        }

        if (!token.transferFrom(msg.sender, address(this), amount)) {
            revert TransferFailed();
        }

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

    function claim(uint256[] calldata scheduleIds) public payable onlyWithFees {
        uint256 claimableAmount = 0;
        Vesting[] storage schedules = vestingSchedules[msg.sender];
        uint256 scheduleIdsLength = scheduleIds.length;

        for (uint256 i = 0; i < scheduleIdsLength; i++) {
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

            uint256 elapsedTime = block.timestamp - vestingSchedule.startTime;
            uint256 vestingDuration = vestingSchedule.endTime -
                vestingSchedule.startTime;
            if (elapsedTime > vestingDuration) {
                elapsedTime = vestingDuration;
            }
            uint256 vestedAmount = (vestingSchedule.totalAmount * elapsedTime) /
                vestingDuration;
            uint256 unclaimedAmount = vestedAmount -
                vestingSchedule.claimedAmount;

            if (unclaimedAmount > 0) {
                vestingSchedule.claimedAmount = vestedAmount;
                claimableAmount += unclaimedAmount;

                emit TokenWithdrawn(msg.sender, id, unclaimedAmount);
            }
        }

        if (claimableAmount == 0) {
            revert NothingToClaim();
        }
        if (!token.transfer(msg.sender, claimableAmount)) {
            revert TransferFailed();
        }
    }

    function getUserAllocations(
        address _wallet
    ) external view returns (Vesting[] memory) {
        uint256 length = vestingSchedules[_wallet].length;
        Vesting[] memory vestings = new Vesting[](length);
        for (uint i = 0; i < length; ++i) {
            vestings[i] = vestingSchedules[_wallet][i];
        }

        return vestings;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./IAccessControlHolder.sol";
import "./IWithFees.sol";

contract WithFees is IAccessControlHolder, IWithFees {
    address public immutable override treasury;
    uint256 public immutable override value;
    IAccessControl public immutable override acl;

    bytes32 public constant FEES_MANAGER = keccak256("FEES_MANAGER");

    constructor(IAccessControl _acl, address _treasury, uint256 _value) {
        acl = _acl;
        treasury = _treasury;
        value = _value;
    }

    function transfer() external onlyFeesManagerAccess {
        (bool sent, ) = treasury.call{value: address(this).balance}("");
        if (!sent) {
            revert ETHTransferFailed();
        }
    }

    modifier onlyWithFees() {
        if (value > msg.value) {
            revert OnlyWithFees();
        }
        _;
    }

    modifier onlyFeesManagerAccess() {
        if (!acl.hasRole(FEES_MANAGER, msg.sender)) {
            revert OnlyFeesManagerAccess();
        }
        _;
    }
}