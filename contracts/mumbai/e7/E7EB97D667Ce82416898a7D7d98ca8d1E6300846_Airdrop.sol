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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "../IAccessControlHolder.sol";
import "./IAirdrop.sol";
import "../WithFees.sol";
import "../ZeroAmountGuard.sol";
import "../ZeroAddressGuard.sol";
import "../TransferGuard.sol";
import "../ApproveGaurd.sol";
import "../vesting/ITokenVesting.sol";

/// @title Airdrop contract
/// @notice Handles distribution of airdrop tokens, allowing users to claim their allocated tokens
contract Airdrop is
    IAccessControlHolder,
    IAirdrop,
    WithFees,
    ZeroAmountGuard,
    ZeroAddressGuard,
    TransferGuard,
    ApproveGuard
{
    bytes32 public constant AIRDROP_MANAGER = keccak256("AIRDROP_MANAGER");
    uint256 public constant VESTING_DURATION = 30 days * 3;
    uint256 public constant SET_CLAIMABLE_MAX_LENGTH = 15;

    ISparta public immutable sparta;
    ITokenVesting public immutable vesting;
    uint256 public immutable claimStartTimestamp;
    ILockdropPhase2 public immutable lockdrop;
    uint256 public override burningStartTimestamp;
    uint256 public totalLocked;
    mapping(address => uint256) public claimableAmounts;
    mapping(address => uint256) public onLockdrop;

    /// @notice Ensures that the caller has the AIRDROP_MANAGER role.
    /// @dev If the caller does not have the AIRDROP_MANAGER role, the transaction is reverted with the OnlyAirdropManagerRole error.
    modifier onlyAirdropManagerRole() {
        if (!acl.hasRole(AIRDROP_MANAGER, msg.sender)) {
            revert OnlyAirdropManagerRole();
        }
        _;
    }

    /// @notice Ensures that the current time is after the burning start timestamp.
    /// @dev If the current time is not after the burning start timestamp, the transaction is reverted with the CannotBurnTokens error.
    modifier onlyAfterBurningTimestamp() {
        if (burningStartTimestamp > block.timestamp) {
            revert CannotBurnTokens();
        }
        _;
    }

    constructor(
        ISparta _sparta,
        uint256 _claimStartTimestamp,
        ILockdropPhase2 _lockdrop,
        ITokenVesting _vesting,
        IAccessControl _acl,
        uint256 _burningStartTimestamp,
        address _treasury,
        uint256 _value
    ) WithFees(_acl, _treasury, _value) {
        sparta = _sparta;
        if (block.timestamp > _claimStartTimestamp) {
            revert ClaimStartNotValid();
        }
        vesting = _vesting;
        claimStartTimestamp = _claimStartTimestamp;
        lockdrop = _lockdrop;
        burningStartTimestamp = _burningStartTimestamp;
    }

    /// @notice Sets claimable amounts for an array of users.
    /// @param users Array of user addresses.
    /// @param amounts Corresponding amounts claimable by each user.
    /// @dev Emits a WalletAdded event for each user.
    /// @dev If the arrays length is different, the function reverts with ArraysLengthNotSame error.
    /// @dev If the arrays length is bigger than SET_CLAIMABLE_MAX, the function reverts with MaxLengthExceeded error.
    /// @dev If the an one of the users is address(0), the function reverts with ZeroAddress.
    /// @dev If the an one tokens amount is 0, the function reverts with ZeroAmount.
    function setClaimableAmounts(
        address[] memory users,
        uint256[] memory amounts
    ) external override onlyAirdropManagerRole {
        if (users.length != amounts.length) {
            revert ArraysLengthNotSame();
        }

        uint256 length = users.length;
        if (length > SET_CLAIMABLE_MAX_LENGTH) {
            revert MaxLengthExceeded();
        }
        uint256 sum = 0;

        for (uint256 i = 0; i < length; ) {
            uint256 amount = amounts[i];
            _ensureIsNotZero(amount);
            address wallet = users[i];
            _ensureIsNotZeroAddress(wallet);
            sum += amount;
            claimableAmounts[wallet] += amount;
            unchecked {
                ++i;
            }
            emit WalletAdded(wallet, amount);
        }

        if (totalLocked + sum > sparta.balanceOf(address(this))) {
            revert BalanceTooSmall();
        }
    }

    /// @notice Allows a user to claim their tokens. A user needs to pay particular fee
    /// @dev Transfers the claimed amount to the user and emits a Claimed event.
    /// @dev If the timestamp is lower than claimStartTimestamp, the function reverts with BeforeReleaseTimestamp.
    /// @dev If the amount of tokens to claim is zero, the function revers with ZeroAmount error.
    function claimTokens() external payable override onlyWithFees {
        if (claimStartTimestamp > block.timestamp) {
            revert BeforeReleaseTimestamp();
        }

        uint256 amount = claimableAmounts[msg.sender];
        _ensureIsNotZero(amount);

        uint256 onLockdropPhase2 = onLockdrop[msg.sender];
        uint256 onLockdropPhase2Max = claimableAmounts[msg.sender] / 2;
        uint256 toSend = onLockdropPhase2Max - onLockdropPhase2;
        uint256 onVesting = amount - onLockdropPhase2Max;

        claimableAmounts[msg.sender] = 0;
        if (toSend > 0) {
            _transferERC20(sparta, msg.sender, toSend);
        }
        _allowErc20(sparta, address(vesting), onVesting);
        vesting.addVesting(
            msg.sender,
            claimStartTimestamp,
            VESTING_DURATION,
            onVesting
        );

        emit Claimed(msg.sender, amount);
    }

    /// @notice Allows a user to lock their tokens in the LockdropPhase2 contract.
    /// @param _amount Amount of tokens to lock.
    /// @dev Emits a LockedOnLockdropPhase2 event.
    /// @dev If the amount is equal 0, the funciton reverts with ZeroAmount.
    /// @dev If the already withdrawn tokens and current amount of tokens is bigger tan toAllocateMax, the function reverts with LimitExceeded.
    /// @dev If approving tokens access returns false, the function reverts with ApprovedFailed error.
    function lockOnLockdropPhase2(uint256 _amount) external override {
        _ensureIsNotZero(_amount);
        uint256 onLockdropAlready = onLockdrop[msg.sender];
        uint256 toAllocateMax = claimableAmounts[msg.sender] / 2;
        if (onLockdropAlready + _amount > toAllocateMax) {
            revert LimitExceeded();
        }
        _allowErc20(sparta, address(lockdrop), _amount);
        lockdrop.lockSparta(_amount, msg.sender);
        onLockdrop[msg.sender] += _amount;

        emit LockedOnLockdropPhase2(msg.sender, _amount);
    }

    /// @notice Burns unclaimed tokens
    /// @dev Can only be called by an address with the AIRDROP_MANAGER role and after the burning start timestamp
    function burnTokens()
        external
        override
        onlyAirdropManagerRole
        onlyAfterBurningTimestamp
    {
        sparta.burn(sparta.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "../lockdrop/ILockdropPhase2.sol";
import "../tokens/interfaces/ISparta.sol";

/// @title IAirdrop interface for the Airdrop contract
/// @notice Defines the functions and events for an Airdrop contract.
interface IAirdrop {
    /// @dev Errors that describe failures in the contract.
    error ArraysLengthNotSame();
    error BeforeReleaseTimestamp();
    error CannotWithdrawZeroTokens();
    error BalanceTooSmall();
    error OnlyAirdropManagerRole();
    error CannotBurnTokens();
    error ClaimStartNotValid();
    error MaxLengthExceeded();
    error LimitExceeded();

    /// @notice Emitted when a user claims their airdropped tokens.
    event Claimed(address indexed user, uint256 amount);

    /// @notice Emitted when a wallet is added to the airdrop.
    event WalletAdded(address indexed user, uint256 amount);

    /// @notice Emitted when tokens are locked on the LockdropPhase2 contract.
    event LockedOnLockdropPhase2(address indexed wallet, uint256 amount);

    /// @notice Allows to set claimable amounts for a list of users.
    /// @param users The array of user addresses.
    /// @param amounts The corresponding amounts of tokens that users can claim.
    function setClaimableAmounts(
        address[] memory users,
        uint256[] memory amounts
    ) external;

    /// @notice Allows users to claim their tokens.
    /// @dev The user has to have tokens assigned to claim.
    function claimTokens() external payable;

    /// @notice Returns the timestamp when tokens can start being burned.
    /// @return A uint256 timestamp when tokens can start being burned.
    function burningStartTimestamp() external view returns (uint256);

    /// @notice Burns the remaining tokens that weren't claimed after the claim period ends.
    function burnTokens() external;

    /// @notice Locks a certain amount of tokens on the LockdropPhase2 contract.
    /// @param _amount The amount of tokens to be locked.
    function lockOnLockdropPhase2(uint256 _amount) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./tokens/interfaces/IERC20Decimals.sol";

/// @title ApproveGuard
/// @dev This contract provides helper functions to handle ERC20 token allowance.
contract ApproveGuard {
    /// @dev Error that is thrown when approve is failed.
    error ApproveFailed();

    /// @dev Allows this contract to spend a specific amount of tokens on behalf of the owner.
    /// @param token_ The ERC20 token to allow.
    /// @param to_ The address to allow spending tokens.
    /// @param amount The amount of tokens to allow.
    /// @return Returns the allowed amount.
    /// @notice This function will revert with ApproveFailed error if the approval fails.
    function _allowErc20(
        IERC20 token_,
        address to_,
        uint256 amount
    ) internal returns (uint256) {
        if (!token_.approve(to_, amount)) {
            revert ApproveFailed();
        }

        return amount;
    }

    /// @dev Allows this contract to spend the maximum available amount of tokens on behalf of the owner.
    /// @param token_ The ERC20 token to allow.
    /// @param to_ The address to allow spending tokens.
    /// @return Returns the allowed amount.
    /// @notice This function will revert with ApproveFailed error if the approval fails.
    function _allowMaxErc20(
        IERC20 token_,
        address to_
    ) internal returns (uint256) {
        return _allowErc20(token_, to_, token_.balanceOf(address(this)));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

pragma solidity 0.8.18;

interface IUniswapV2Router01 {
    function factory() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    enum LockdropState {
        NOT_STARTED,
        TOKENS_ALLOCATION_ONGOING,
        TOKENS_ALLOCATION_FINISHED,
        REWARD_RATES_CALCULATED,
        SOURCE_LIQUDITY_EXCHANGED,
        TARGET_LIQUDITY_PROVIDED
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

pragma solidity 0.8.18;
import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    error Expired();
    error InsufficientAAmount();
    error InsufficientBAmount();
    error InsufficientOutputAmount();
    error InvalidPath();
    error ExcessiveInputAmount();

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "../dex/periphery/interfaces/IUniswapV2Router02.sol";
import "../dex/core/interfaces/IUniswapV2Pair.sol";

/// @title ILockdrop
/// @dev This is an interface for a lockdrop smart contract.
interface ILockdrop {
    /// @notice This error is thrown when a function expecting a certain AllocationState gets a different state.
    /// @param current The current allocation state.
    /// @param expected The expected allocation state.
    error WrongAllocationState(
        AllocationState current,
        AllocationState expected
    );

    /// @notice This error is thrown when timestamps for the lockdrop are incorrect.
    error TimestampsIncorrect();

    /// @notice The possible states of token allocation.
    enum AllocationState {
        NOT_STARTED, // Allocation has not started.
        ALLOCATION_ONGOING, // Tokens are currently being allocated.
        ALLOCATION_FINISHED // Token allocation has finished.
    }

    /// @notice Gets the SpartaDex V2 router.
    /// @return The SpartaDex V2 router.
    function spartaDexRouter() external view returns (IUniswapV2Router02);

    /// @notice Gets the timestamp for when the lockdrop starts.
    /// @return The starting timestamp.
    function lockingStart() external view returns (uint256);

    /// @notice Gets the timestamp for when the lockdrop ends.
    /// @return The ending timestamp.
    function lockingEnd() external view returns (uint256);

    /// @notice Gets the timestamp for when the unlocking period ends.
    /// @return The ending timestamp.
    function unlockingEnd() external view returns (uint256);

    /// @notice Gets the initial balance of LP tokens.
    /// @return The initial balance.
    function initialLpTokensBalance() external view returns (uint256);

    /// @notice Gets the total reward for the lockdrop.
    /// @return The total reward.
    function totalReward() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "../tokens/interfaces/IERC20Decimals.sol";
import "./ILockdrop.sol";

/// @title ILockdropPhase2
/// @notice This interface defines the operations available in the second phase of a lockdrop.
interface ILockdropPhase2 is ILockdrop {
    /// @dev Errors that describe failures in the contract.
    error RewardAlreadyTaken();
    error CannotUnlock();
    error NothingToClaim();
    error WrongLockdropState(LockdropState current, LockdropState expected);
    error OnlyLockdropPhase2ResolverAccess();

    /// @notice Emitted when a user locks tokens in the lockdrop.
    event Locked(
        address indexed by,
        address indexed beneficiary,
        IERC20 indexed token,
        uint256 amount
    );

    /// @notice Emitted when a user unlocks tokens from the lockdrop.
    event Unlocked(address indexed by, IERC20 indexed token, uint256 amount);

    /// @notice Emitted when a user withdraws a reward from the lockdrop.
    event RewardWitdhrawn(address indexed wallet, uint256 amount);

    /// @notice Emitted when a user claims tokens from the lockdrop.
    event TokensClaimed(address indexed wallet, uint256 amount);

    /// @notice Enumeration of the possible states of the lockdrop.
    enum LockdropState {
        NOT_STARTED,
        ALLOCATION_LOCKING_UNLOCKING_ONGOING,
        ALLOCATION_LOCKING_ONGOING_LOCKING_FINISHED,
        ALLOCATION_FINISHED,
        TOKENS_EXCHANGED
    }

    /// @notice Locks an amount of Sparta tokens in the lockdrop.
    function lockSparta(uint256 _amount, address _wallet) external;

    /// @notice Locks an amount of stable tokens in the lockdrop.
    function lockStable(uint256 _amount) external;

    /// @notice Unlocks an amount of stable tokens from the lockdrop.
    function unlockStable(uint256 _amount) external;

    /// @notice Returns the amount of Sparta tokens locked by a specific wallet.
    function walletSpartaLocked(
        address _wallet
    ) external view returns (uint256);

    /// @notice Returns the amount of stable tokens locked by a specific wallet.
    function walletStableLocked(
        address _wallet
    ) external view returns (uint256);

    /// @notice Exchanges tokens using the SpartaDex router.
    function exchangeTokens(
        IUniswapV2Router02 router_,
        uint256 spartaMinAmount_,
        uint256 stableMinAmount_,
        uint256 deadline_
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Decimals is IERC20 {
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./IERC20Decimals.sol";

interface ISparta is IERC20Decimals {
    function burn(uint256 amount) external;
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