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

import "./tokens/interfaces/IERC20Decimals.sol";

/**
 * @title ApproveGuard.
 * @dev This contract provides helper functions to handle ERC20 token allowance.
 */
contract ApproveGuard {
    error ApproveFailed();

    /**
     * @notice This function will revert with ApproveFailed error if the approval fails.
     * @dev Allows this contract to spend a specific amount of tokens on behalf of the owner.
     * @param token_ The ERC20 token to allow.
     * @param to_ The address to allow spending tokens.
     * @param amount The amount of tokens to allow.
     * @return uint256 Returns the allowed amount.
     */
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

    /**
     * @notice This function will revert with ApproveFailed error if the approval fails.
     * @dev Allows this contract to spend the maximum available amount of tokens on behalf of the owner.
     * @param token_ The ERC20 token to allow.
     * @param to_ The address to allow spending tokens.
     * @return uint256 This function will revert with ApproveFailed error if the approval fails.
     */
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
pragma solidity ^0.8.1;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
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

/**
 * @title IAccessControlHolder
 * @notice Interface created to store reference to the access control.
 */
interface IAccessControlHolder {
    /**
     * @notice Function returns reference to IAccessControl.
     * @return IAccessControl reference to access control.
     */
    function acl() external view returns (IAccessControl);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "../dex/periphery/interfaces/IUniswapV2Router02.sol";
import "../dex/core/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ILockdrop
 * @notice  The purpose of the lockdrop contract is to provide liquidity to the newly created dex by collecting funds from users
 */
interface ILockdrop {
    error WrongAllocationState(
        AllocationState current,
        AllocationState expected
    );

    error TimestampsIncorrect();

    enum AllocationState {
        NOT_STARTED,
        ALLOCATION_ONGOING,
        ALLOCATION_FINISHED
    }

    /**
     * @notice Function returns the newly created SpartaDexRouter.
     * @return IUniswapV2Router02 Address of the router.
     */
    function spartaDexRouter() external view returns (IUniswapV2Router02);

    /**
     * @notice Function returns the timestamp for when the lockdrop starts.
     * @return uint256 Start timestamp.
     */
    function lockingStart() external view returns (uint256);

    /**
     * @notice Function returns the timestamp for when the lockdrop ends.
     * @return uint256 End Timestamp.
     */
    function lockingEnd() external view returns (uint256);

    /**
     * @notice Function returns the timestamp for when the unlocking period ends.
     * @return uint256 The ending timestamp.
     */
    function unlockingEnd() external view returns (uint256);

    /**
     * @notice Function returns the amount of the tokens that correspond to the provided liquidity on SpartaDex.
     * @return uint256 Amount of LP tokens.
     */
    function initialLpTokensBalance() external view returns (uint256);

    /**
     * @notice Function returns the total reward for the lockdrop.
     * @return uint256 Total amount of reward.
     */
    function totalReward() external view returns (uint256);

    /**
     * @notice Function returns the exchange pair for the lockdrop.
     * @return IUniswapV2Pair Address of token created on the target DEX.
     */
    function exchangedPair() external view returns (IUniswapV2Pair);

    /**
     * @notice Return the reward of the lockdrop
     * @return IERC20 Address of reward token.
     */
    function rewardToken() external view returns (IERC20);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "../tokens/interfaces/IERC20Decimals.sol";
import "./ILockdrop.sol";

/**
 * @title ILockdropPhase2
 * @notice  The goal of LockdropPhase2 is to collect SPARTA tokens and StableCoin, which will be used to create the corresponding pair on SpartaDex.
 */
interface ILockdropPhase2 is ILockdrop {
    error RewardAlreadyTaken();
    error CannotUnlock();
    error NothingToClaim();
    error WrongLockdropState(LockdropState current, LockdropState expected);
    error OnlyLockdropPhase2ResolverAccess();

    event Locked(
        address indexed by,
        address indexed beneficiary,
        IERC20 indexed token,
        uint256 amount
    );

    event Unlocked(address indexed by, IERC20 indexed token, uint256 amount);

    event RewardWitdhrawn(address indexed wallet, uint256 amount);

    event TokensClaimed(address indexed wallet, uint256 amount);

    enum LockdropState {
        NOT_STARTED,
        TOKENS_ALLOCATION_LOCKING_UNLOCKING_ONGOING,
        TOKENS_ALLOCATION_LOCKING_ONGOING_UNLOCKING_FINISHED,
        TOKENS_ALLOCATION_FINISHED,
        TOKENS_EXCHANGED
    }

    /**
     * @notice Function allows user to lock the certain amount of SPARTA tokens.
     * @param _amount Amount of tokens to lock.
     * @param _wallet Address of the wallet to which the blocked tokens will be assigned.
     */
    function lockSparta(uint256 _amount, address _wallet) external;

    /**
     * @notice Function allows user to lock the certain amount of StableCoin tokens.
     * @param _amount Amount of tokens to lock.
     */
    function lockStable(uint256 _amount) external;

    /**
     * @notice Function allows user to unlock already allocated StableCoin.
     * @param _amount  Amount of tokens the user want to unlock.
     */
    function unlockStable(uint256 _amount) external;

    /**
     * @notice Function returns the amount of SPARTA tokens locked by the wallet.
     * @param _wallet Address for which we want to check the amount of allocated SPARTA.
     * @return uint256 Number of SPARTA tokens locked on the contract.
     */
    function walletSpartaLocked(
        address _wallet
    ) external view returns (uint256);

    /**
     * @notice Function returns the amount of Stable tokens locked by the wallet.
     * @param _wallet Address for which we want to check the amount of allocated Stable.
     * @return uint256 Number of locked Stable coins.
     */
    function walletStableLocked(
        address _wallet
    ) external view returns (uint256);

    /**
     * @notice Funcion allows authorized wallet to add liquidity on SpartaDEX router.
     * @param router_ Address of SpartaDexRouter.
     * @param spartaMinAmount_ Minimal acceptable amount of Sparta tokens.
     * @param stableMinAmount_ Minimal acceptable amount of StableCoin tokens.
     * @param deadline_ Deadline by which liquidity should be added.
     */
    function exchangeTokens(
        IUniswapV2Router02 router_,
        uint256 spartaMinAmount_,
        uint256 stableMinAmount_,
        uint256 deadline_
    ) external;

    /**
     * @notice Function allows user to take the corresponding amount of SPARTA/StableCoin LP token from the contract.
     */
    function claimTokens() external;

    /**
     * @notice Function allows user to witdraw the earned reward.
     */
    function getReward() external;

    /**
     * @notice Function calculates the amount of sparta a user will get after staking particular amount of tokens.
     * @param  stableAmount Amount of StableCoin tokens.
     * @return uint256 Reward corresponding to the number of StableCoin tokens.
     */
    function calculateRewardForStable(
        uint256 stableAmount
    ) external view returns (uint256);

    /**
     * @notice Function calculates the amount of sparta a user will get after staking particular amount of tokens.
     * @param  spartaAmount Amount of SPARTA tokens.
     * @return uint256 Reward corresponding to the number of SPARTA tokens.
     */
    function calculateRewardForSparta(
        uint256 spartaAmount
    ) external view returns (uint256);

    /**
     * @notice Function calculates the reward for the given amounts of the SPARTA and the StableCoin tokens.
     * @param spartaAmount Amount of SPARTA tokens.
     * @param stableAmount Amount of StableCoin tokens.
     * @return uint256 Total reward corresponding to the amount of SPARTA and the amount of STABLE tokens.
     */
    function calculateRewardForTokens(
        uint256 spartaAmount,
        uint256 stableAmount
    ) external view returns (uint256);

    /**
     * @notice Function returns the total reward earned by the wallet.
     * @param wallet_ Address of the wallet the reward we want to check.
     * @return uint256 Total reward earned by the wallet.
     */
    function calculateReward(address wallet_) external view returns (uint256);

    /**
     * @notice Funtion returns the current state of the lockdrop.
     * @return LockdropState State of the lockdrop.
     */
    function state() external view returns (LockdropState);

    /**
     * @notice Function calculates the amount of SPARTA/StableCoin LP tokens the user can get after providing liquidity on the SPARTA dex.
     * @param _wallet Address of the wallet of the user to whom we want to check the amount of the reward.
     * @return uint256 Amount of SPARTA/StableCoin LP tokens corresponding to the wallet.
     */
    function availableToClaim(address _wallet) external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "../tokens/interfaces/IERC20Decimals.sol";
import "./ILockdrop.sol";
import "../IAccessControlHolder.sol";
import "../dex/core/interfaces/IUniswapV2Pair.sol";
import "../ZeroAddressGuard.sol";
import "../ZeroAmountGuard.sol";
import "../TransferGuard.sol";
import "../ApproveGuard.sol";

/**
 * @title Lockdrop
 * @notice This contract is base implementation of common lockdrop functionalities.
 */
abstract contract Lockdrop is
    ILockdrop,
    IAccessControlHolder,
    ZeroAddressGuard,
    ZeroAmountGuard,
    TransferGuard,
    ApproveGuard
{
    IUniswapV2Router02 public override spartaDexRouter;
    IAccessControl public immutable override acl;
    IERC20 public immutable override rewardToken;
    uint256 public override initialLpTokensBalance;
    uint256 public immutable override lockingStart;
    uint256 public immutable override lockingEnd;
    uint256 public immutable override unlockingEnd;
    uint256 public immutable override totalReward;

    /**
     * @notice Modifier verifies that the current allocation state equals the expected state.
     * @dev Modifier reverts with WrongAllocationState, when the current state is different than expected.
     * @param expected Expected state of lockdrop.
     */
    modifier onlyOnAllocationState(AllocationState expected) {
        AllocationState current = _allocationState();
        if (current != expected) {
            revert WrongAllocationState(current, expected);
        }
        _;
    }

    constructor(
        IAccessControl _acl,
        IERC20 _rewardToken,
        uint256 _lockingStart,
        uint256 _lockingEnd,
        uint256 _unlockingEnd,
        uint256 _totalReward
    ) notZeroAmount(_totalReward) {
        acl = _acl;
        if (_lockingStart > _unlockingEnd || _unlockingEnd > _lockingEnd) {
            revert TimestampsIncorrect();
        }
        lockingStart = _lockingStart;
        lockingEnd = _lockingEnd;
        unlockingEnd = _unlockingEnd;
        totalReward = _totalReward;
        rewardToken = _rewardToken;
    }

    /**
     * @notice Function automatically coverts LP token pair to IERC20 and transfer the tokens.
     * @dev Function reverts with TransferFailed, if transfer function returns false.
     * @param token Address from which tokens were transported.
     * @param from Address from which tokens were transported.
     * @param to Address to which tokens were transported.
     * @param value Number of tokens to transfer.
     */
    function _transferFromERC20Pair(
        IUniswapV2Pair token,
        address from,
        address to,
        uint256 value
    ) internal {
        _transferFromERC20(IERC20(address(token)), from, to, value);
    }

    /**
     * @notice Function automatically coverts LP token pair to IERC20 and transfer the tokens.
     * @dev Function reverts with TransferFailed, if transfer function returns false.
     * @param token Address from which tokens were transported.
     * @param to Address to which tokens were transported.
     * @param value Number of tokens to transfer.
     */
    function _transferERC20Pair(
        IUniswapV2Pair token,
        address to,
        uint256 value
    ) internal {
        _transferERC20(IERC20(address(token)), to, value);
    }

    /**
     * @notice Function returns the sorted tokens unsed in the lockdrop.
     * @return (address, address) Sorted addresses of tokens.
     */
    function _tokens() internal view virtual returns (address, address);

    /**
     * @notice Function returns the current allocation state.
     * @return AllocationState Current AllocationState.
     */
    function _allocationState() internal view returns (AllocationState) {
        if (block.timestamp >= lockingEnd) {
            return AllocationState.ALLOCATION_FINISHED;
        } else if (block.timestamp >= lockingStart) {
            if (rewardToken.balanceOf(address(this)) >= totalReward) {
                return AllocationState.ALLOCATION_ONGOING;
            }
        }

        return AllocationState.NOT_STARTED;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "../dex/core/interfaces/IUniswapV2Factory.sol";
import "./ILockdropPhase2.sol";
import "./Lockdrop.sol";

/**
 * @title LockdropPhase2
 * @notice The contract was created to raise funds in the form of Stable and SPARTA tokens,
 * which will be used to provide liquidity on Sparta DEX.
 * Users who choose to deposit a portion of their funds will be rewarded with a proportional amount of SPARTA token.
 * In addition, the user will receive a portion of the newly created liquidity tokens (proportionally to the funds deposited),
 * which will be paid out in a linear fashion over 6 months.
 */
contract LockdropPhase2 is ILockdropPhase2, Lockdrop {
    uint256 internal constant LP_CLAIMING_DURATION = 26 * 7 days;
    bytes32 public constant LOCKDROP_PHASE_2_RESOLVER =
        keccak256("LOCKDROP_PHASE_2_RESOLVER");

    IERC20 public immutable sparta;
    IERC20 public immutable stable;

    uint256 public spartaTotalLocked;
    uint256 public stableTotalLocked;

    mapping(address => uint256) public override walletSpartaLocked;
    mapping(address => uint256) public override walletStableLocked;
    mapping(address => bool) public rewardTaken;
    mapping(address => uint256) public lpClaimed;

    /**
     * @notice Modifier created to check if the current state of lockdrop is as expected.
     * @dev Contract reverts with WrongLockdropState, when the state is different than expected.
     * @param expected LockdropState we should currently be in.
     */
    modifier onlyOnLockdropState(LockdropState expected) {
        LockdropState current = state();
        if (current != expected) {
            revert WrongLockdropState(current, expected);
        }
        _;
    }

    /**
     * @notice Modifier checks the signer of the message has the LOCKDROP_PHASE_2_RESOLVER role.
     * @dev Modifier reverts with OnlyLockdropPhase2ResolverAccess if the signer does not have the role.
     */
    modifier onlyLockdropPhase2Resolver() {
        if (!acl.hasRole(LOCKDROP_PHASE_2_RESOLVER, msg.sender)) {
            revert OnlyLockdropPhase2ResolverAccess();
        }
        _;
    }

    constructor(
        IAccessControl acl_,
        IERC20 sparta_,
        IERC20 stable_,
        uint256 lockingStart_,
        uint256 lockingEnd_,
        uint256 unlockingEnd_,
        uint256 totalReward_
    )
        Lockdrop(
            acl_,
            sparta_,
            lockingStart_,
            lockingEnd_,
            unlockingEnd_,
            totalReward_
        )
    {
        sparta = sparta_;
        stable = stable_;
    }

    /**
     * @inheritdoc ILockdropPhase2
     * @notice User can lock its tokens from the airdrop or reward from LockdropPhase1.
     * @dev Function reverts with WrongAllocationState if a user tries to lock the tokens before or after locking period.
     * @dev Function reverts ZeroAmount if someone tries to lock zero tokens.
     * @dev Function reverts ZeroAddress if someone tries to tokens for zero address.
     * @dev Function reverts TransferFailed if transfer function of the token return false.
     */
    function lockSparta(
        uint256 _amount,
        address _wallet
    )
        external
        onlyOnAllocationState(AllocationState.ALLOCATION_ONGOING)
        notZeroAmount(_amount)
        notZeroAddress(_wallet)
    {
        _transferFromERC20(sparta, msg.sender, address(this), _amount);
        spartaTotalLocked += _amount;
        walletSpartaLocked[_wallet] += _amount;

        emit Locked(msg.sender, _wallet, sparta, _amount);
    }

    /**
     * @inheritdoc ILockdropPhase2
     * @notice User can lock tokens directly on the contract.
     * @dev Function reverts with WrongAllocationState if a user tries to lock the tokens before or after the locking period.
     * @dev Function reverts ZeroAmount if someone tries to lock zero tokens.
     * @dev Function reverts TransferFailed if transfer function of the token return false.
     */
    function lockStable(
        uint256 _amount
    )
        external
        override
        onlyOnAllocationState(AllocationState.ALLOCATION_ONGOING)
        notZeroAmount(_amount)
    {
        _transferFromERC20(stable, msg.sender, address(this), _amount);
        stableTotalLocked += _amount;
        walletStableLocked[msg.sender] += _amount;

        emit Locked(msg.sender, msg.sender, stable, _amount);
    }

    /**
     * @inheritdoc ILockdropPhase2
     * @dev Function reverts with WrongLockdropState if a user tries to unlock the tokens before or after the unlocking period.
     * @dev Function reverts with CannotUnlock if a user tries to unlock more tokens than already locked.
     * @dev Function reverts TransferFailed if transfer function of the token return false.
     */
    function unlockStable(
        uint256 _amount
    )
        external
        override
        onlyOnLockdropState(
            LockdropState.TOKENS_ALLOCATION_LOCKING_ONGOING_UNLOCKING_FINISHED
        )
    {
        uint256 locked = walletStableLocked[msg.sender];
        if (_amount > locked) {
            revert CannotUnlock();
        }

        stableTotalLocked -= _amount;
        walletStableLocked[msg.sender] -= _amount;
        _transferERC20(stable, msg.sender, _amount);

        emit Unlocked(msg.sender, stable, _amount);
    }

    /**
     * @inheritdoc ILockdropPhase2
     * @dev Function reverts with WrongLockdropState if a wallet tries to the provide liqudity before lockdrop end.
     */
    function exchangeTokens(
        IUniswapV2Router02 router_,
        uint256 spartaMinAmount_,
        uint256 stableMinAmount_,
        uint256 deadline_
    )
        external
        override
        onlyOnLockdropState(LockdropState.TOKENS_ALLOCATION_FINISHED)
        onlyLockdropPhase2Resolver
    {
        //TODO: change to provide the percentage
        (, , initialLpTokensBalance) = router_.addLiquidity(
            address(sparta),
            address(stable),
            _allowErc20(sparta, address(router_), spartaTotalLocked),
            _allowMaxErc20(stable, address(router_)),
            spartaMinAmount_,
            stableMinAmount_,
            address(this),
            deadline_
        );

        spartaDexRouter = router_;
    }

    /**
     * @inheritdoc ILockdropPhase2
     * @dev Function reverts with WrongLockdropState if a user tries to get tokens before the liqudity providing.
     * @dev Function reverts NothingToClaim if the sender does not have any SPARTA/StableCoin tokens to withdraw.
     */
    function claimTokens()
        external
        override
        onlyOnLockdropState(LockdropState.TOKENS_EXCHANGED)
    {
        uint256 toClaim = availableToClaim(msg.sender);
        if (toClaim == 0) {
            revert NothingToClaim();
        }
        _transferERC20Pair(exchangedPair(), msg.sender, toClaim);
        lpClaimed[msg.sender] += toClaim;

        emit TokensClaimed(msg.sender, toClaim);
    }

    /**
     * @inheritdoc ILockdropPhase2
     * @dev Function reverts with WrongLockdropState if a user tries to get the reward before the lockdrop end.
     * @dev Function reverts TransferFailed if transfer function of the token return false.
     * @dev Function reverts NothingToClaim if the sender does not have any reward to withdraw.
     */
    function getReward()
        external
        onlyOnLockdropState(LockdropState.TOKENS_EXCHANGED)
    {
        if (rewardTaken[msg.sender]) {
            revert RewardAlreadyTaken();
        }
        uint256 reward = calculateReward(msg.sender);
        if (reward == 0) {
            revert NothingToClaim();
        }
        _transferERC20(sparta, msg.sender, reward);
        rewardTaken[msg.sender] = true;
    }

    /**
     * @inheritdoc ILockdropPhase2
     */
    function calculateRewardForStable(
        uint256 stableAmount
    ) public view returns (uint256) {
        if (stableTotalLocked == 0) {
            return 0;
        }
        uint256 forSpartaReward = totalReward / 2;
        uint256 forStableReward = totalReward - forSpartaReward;
        return (forStableReward * stableAmount) / stableTotalLocked;
    }

    /**
     * @inheritdoc ILockdropPhase2
     */
    function calculateRewardForSparta(
        uint256 spartaAmount
    ) public view returns (uint256) {
        if (spartaTotalLocked == 0) {
            return 0;
        }
        uint256 forSpartaReward = totalReward / 2;
        return (forSpartaReward * spartaAmount) / spartaTotalLocked;
    }

    /**
     * @inheritdoc ILockdropPhase2
     */
    function calculateRewardForTokens(
        uint256 spartaAmount,
        uint256 stableAmount
    ) public view returns (uint256) {
        return
            calculateRewardForSparta(spartaAmount) +
            calculateRewardForStable(stableAmount);
    }

    /**
     * @inheritdoc ILockdropPhase2
     */
    function state() public view returns (LockdropState) {
        AllocationState allocationState = _allocationState();
        if (allocationState == AllocationState.NOT_STARTED) {
            return LockdropState.NOT_STARTED;
        } else if (allocationState == AllocationState.ALLOCATION_ONGOING) {
            if (block.timestamp > unlockingEnd) {
                return
                    LockdropState
                        .TOKENS_ALLOCATION_LOCKING_ONGOING_UNLOCKING_FINISHED;
            }
            return LockdropState.TOKENS_ALLOCATION_LOCKING_UNLOCKING_ONGOING;
        } else if (address(spartaDexRouter) == address(0)) {
            return LockdropState.TOKENS_ALLOCATION_FINISHED;
        }

        return LockdropState.TOKENS_EXCHANGED;
    }

    /**
     * @inheritdoc ILockdropPhase2
     */
    function calculateReward(
        address wallet_
    ) public view override returns (uint256) {
        return
            calculateRewardForTokens(
                walletSpartaLocked[wallet_],
                walletStableLocked[wallet_]
            );
    }

    /**
     * @inheritdoc ILockdrop
     */
    function exchangedPair()
        public
        view
        override
        onlyOnLockdropState(LockdropState.TOKENS_EXCHANGED)
        returns (IUniswapV2Pair)
    {
        (address token0_, address token1_) = _tokens();

        return
            IUniswapV2Pair(
                IUniswapV2Factory(spartaDexRouter.factory()).getPair(
                    token0_,
                    token1_
                )
            );
    }

    /**
     * @inheritdoc ILockdropPhase2
     */
    function availableToClaim(
        address _wallet
    )
        public
        view
        onlyOnLockdropState(LockdropState.TOKENS_EXCHANGED)
        returns (uint256)
    {
        uint256 reward = calculateReward(_wallet);
        if (reward == 0) {
            return 0;
        }
        uint256 timeElapsedFromLockdropEnd = block.timestamp - lockingEnd;
        uint256 duration = timeElapsedFromLockdropEnd > LP_CLAIMING_DURATION
            ? LP_CLAIMING_DURATION
            : timeElapsedFromLockdropEnd;
        uint256 releasedFromVesting = (reward *
            initialLpTokensBalance *
            duration) / (totalReward * LP_CLAIMING_DURATION);
        return releasedFromVesting - lpClaimed[_wallet];
    }

    /**
     * @notice Function returns the sorted address of the SPARTA and StableCoin tokens.
     * @return (address, address) Sorted addresses of StableCoin and SPARTA tokens.
     */
    function _tokens() internal view override returns (address, address) {
        (address spartaAddress, address stableAddress) = (
            address(sparta),
            address(stable)
        );
        return
            spartaAddress < stableAddress
                ? (spartaAddress, stableAddress)
                : (stableAddress, spartaAddress);
    }

    function foo() internal {}
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

/**
 * @title TransferGuard.
 * @notice This contract provides functionality to safely transfer and transferFrom ERC20 tokens.
 */
contract TransferGuard {
    error TransferFailed();

    /**
     * @notice Transfers tokens from one address to another using the transferFrom function of the ERC20 token.
     * @dev If the transferFrom function of the ERC20 token returns false, the transaction is reverted with a TransferFailed error.
     * @param token The ERC20 token to transfer.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     */
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

    /**
     * @notice Transfers tokens to an address using the transfer function of the ERC20 token.
     * @dev If the transfer function of the ERC20 token returns false, the transaction is reverted with a TransferFailed error.
     * @param token The ERC20 token to transfer.
     * @param to The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     */
    function _transferERC20(IERC20 token, address to, uint256 amount) internal {
        if (!token.transfer(to, amount)) {
            revert TransferFailed();
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

/**
 * @title ZeroAddressGuard.
 * @notice This contract is responsible for ensuring that a given address is not a zero address.
 */

contract ZeroAddressGuard {
    error ZeroAddress();

    /**
     * @notice Modifier to make a function callable only when the provided address is non-zero.
     * @dev If the address is a zero address, the function reverts with ZeroAddress error.
     * @param _addr Address to be checked..
     */
    modifier notZeroAddress(address _addr) {
        _ensureIsNotZeroAddress(_addr);
        _;
    }

    /// @notice Checks if a given address is a zero address and reverts if it is.
    /// @param _addr Address to be checked.
    /// @dev If the address is a zero address, the function reverts with ZeroAddress error.
    /**
     * @notice Checks if a given address is a zero address and reverts if it is.
     * @dev     .
     * @param   _addr  .
     */
    function _ensureIsNotZeroAddress(address _addr) internal pure {
        if (_addr == address(0)) {
            revert ZeroAddress();
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

/**
 * @title ZeroAmountGuard
 * @notice This contract provides a modifier to guard against zero values in a transaction.
 */
contract ZeroAmountGuard {
    error ZeroAmount();

    /**
     * @notice Modifier ensures the amount provided is not zero.
     * param _amount The amount to check.
     * @dev If the amount is zero, the function reverts with a ZeroAmount error.
     */
    modifier notZeroAmount(uint256 _amount) {
        _ensureIsNotZero(_amount);
        _;
    }

    /**
     * @notice Function verifies that the given amount is not zero.
     * @param _amount The amount to check.
     */
    function _ensureIsNotZero(uint256 _amount) internal pure {
        if (_amount == 0) {
            revert ZeroAmount();
        }
    }
}