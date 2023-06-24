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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library HomoraMath {
    using SafeMath for uint;

    function divCeil(uint lhs, uint rhs) internal pure returns (uint) {
        return lhs.add(rhs).sub(1) / rhs;
    }

    function fmul(uint lhs, uint rhs) internal pure returns (uint) {
        return lhs.mul(rhs) / (2 ** 112);
    }

    function fdiv(uint lhs, uint rhs) internal pure returns (uint) {
        return lhs.mul(2 ** 112) / rhs;
    }

    // implementation from https://github.com/Uniswap/uniswap-lib/commit/99f3f28770640ba1bb1ff460ac7c5292fb8291a0
    // original implementation: https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint x) internal pure returns (uint) {
        if (x == 0) return 0;
        uint xx = x;
        uint r = 1;

        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }

        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }

        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint r1 = x / r;
        return (r < r1 ? r : r1);
    }
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

import "../dex/core/interfaces/IUniswapV2Pair.sol";
import "../dex/periphery/interfaces/IUniswapV2Router02.sol";
import "../vesting/ITokenVesting.sol";
import "./ILockdropPhase2.sol";

interface ILockdropPhase1 {
    /// @dev Errors that describe failures in the contract.
    error WrongLockdropState(LockdropState current, LockdropState expected);
    error ToEarlyAllocationState(LockdropState current, LockdropState atLeast);
    error SourceLiquidityAlreadyRemoved();
    error RewardRatesAlreadyCalculated();
    error TargetLiquidityAlreadyProvided();
    error TokenAllocationAlreadyTaken();
    error CannotUnlockTokensBeforeUnlockTime();
    error MaxRewardExceeded();
    error SpartaDexNotInitialized();
    error AllocationDoesNotExist();
    error AllocationCanceled();
    error NotEnoughToWithdraw();
    error OnlyLockdropPhase1ResolverAccess();
    error Phase2NotFinished();
    error NotDefinedExpirationTimestamp();
    error WrongExpirationTimestamps();
    error RewardNotCalculated();
    error CannotCalculateRewardForChunks();
    error AlreadyCalculated();
    error MaxLengthExceeded();
    error LockingTokenNotExists();
    error WalletDidNotTakePartInLockdrop();

    /// @dev Emitted when a user locks the tokens.
    event LiquidityProvided(
        address indexed by,
        IUniswapV2Pair indexed pair,
        uint32 indexed durationIndex,
        uint256 value,
        uint256 points
    );
    /// @dev Emitted when a user locks part of his reward on LockdropPhase2.
    event RewardLockedOnLockdropPhase2(address indexed by, uint256 value);

    /// @dev Emitted when a user releases his reward.
    event RewardWithdrawn(address indexed by, uint256 amount);

    /// @dev Emitted when a user sends parts of his reward on the vesting contract.
    event RewardSentOnVesting(address indexed by, uint256 amount);

    /// @dev Emitted when a user unlocks part of the tokens from an allocation.
    event LiquidityUnlocked(
        address indexed by,
        uint256 indexed allocationIndex,
        uint256 value
    );

    /// @dev Struct represents the one allocation of a wallet.
    /// @param taken Defines a wallet withdrawn tokens in the form of exchanged pair.
    /// @param token Address of the pair that tokens were allocated on the contract.
    /// @param unlockTimestampIndex Index of the timestamp the wallet has decided to lock the tokens for.
    /// @param value Amount of locked tokens.
    /// @param boost Number of boost points added to the points value.
    /// @param points Amount of points that the user got after allocation value.
    struct UserAllocation {
        bool taken;
        IUniswapV2Pair token;
        uint32 unlockTimestampIndex;
        uint256 value;
        uint256 boost;
        uint256 points;
    }

    /// @notice Enumeration of the possible states of the lockdrop.
    enum LockdropState {
        NOT_STARTED,
        TOKENS_ALLOCATION_UNLOCKING_ONGOING,
        TOKENS_ALLOCATION_ONGOING_UNLOCKING_FINISHED,
        TOKENS_ALLOCATION_FINISHED,
        SOURCE_LIQUIDITY_EXCHANGED,
        TARGET_LIQUIDITY_PROVIDED
    }

    /// @dev Struct represents the parameters of the tokens defining a pair.
    /// @param tokenAToken Address of the tokenA.
    /// @param tokenBToken Address of the tokenB.
    /// @param tokenAPrice price of the tokenA.
    /// @param tokenBPrice price of the tokenB.
    struct TokenParams {
        address tokenAToken;
        address tokenBToken;
        uint256 tokenAPrice;
        uint256 tokenBPrice;
    }

    /// @dev Struct parameters of the reward.
    /// @param rewardToken Address of the token that will be distributed as reward.
    /// @param rewardAmount Amount of the tokes used as reward.
    struct RewardParams {
        IERC20 rewardToken;
        uint256 rewardAmount;
    }

    /// @dev Struct parameters the pair.
    /// @param token Address of the token the lockdrop supports.
    /// @param router Address of the Uniswap V2 router that the tokens comes from.
    struct LockingToken {
        IUniswapV2Pair token;
        IUniswapV2Router02 router;
    }

    /// @notice Locks tokens.
    /// @param _tokenIndex The index of the token to be locked.
    /// @param _value The amount of tokens to be locked.
    /// @param _lockingExpirationTimestampIndex The expiration timestamp index for locking.
    function lock(
        uint256 _tokenIndex,
        uint256 _value,
        uint32 _lockingExpirationTimestampIndex
    ) external;

    /// @notice Unlocks tokens.
    /// @param _allocationIndex The index of the allocation to be unlocked.
    /// @param _value The amount of tokens to be unlocked.
    function unlock(uint256 _allocationIndex, uint256 _value) external;


    /// @notice Retrieves rewards and sends them on vesting.
    function getRewardAndSendOnVesting() external;

    /// @notice Withdraws exchanged tokens.
    /// @param allocationsIds The ids of the allocations to be withdrawn.
    function withdrawExchangedTokens(
        uint256[] calldata allocationsIds
    ) external;

    /// @notice Allocates reward on Lockdrop Phase 2.
    /// @param _amount The amount of reward to be allocated.
    function allocateRewardOnLockdropPhase2(uint256 _amount) external;

    /// @notice Adds target liquidity to the SpartaDEX Router.
    /// @param _router The Sparta Dex router.
    /// @param _tokenAMin The minimum amount of token A.
    /// @param _tokenBMin The minimum amount of token B.
    /// @param _deadline The deadline for providing liquidity.
    function addTargetLiquidity(
        IUniswapV2Router02 _router,
        uint256 _tokenAMin,
        uint256 _tokenBMin,
        uint256 _deadline
    ) external;

    /// @notice Calculates total reward.
    /// @param _wallet The address of the wallet which allocated tokens.
    /// @return The total reward earned by the wallet.
    function calculateTotalReward(
        address _wallet
    ) external view returns (uint256);

    /// @notice Calculates and stores total reward in chunks. Chunks are a number of allocations that will be used to calculate reward.
    /// @param _wallet The address of the wallet.
    /// @param _chunks The number of chunks.
    /// @return The total reward.
    function calculateAndStoreTotalRewardInChunks(
        address _wallet,
        uint256 _chunks
    ) external returns (uint256);

    /// @notice Gets the current state of the lockdrop.
    /// @return The current state of the lockdrop.
    function state() external view returns (LockdropState);

    /// @notice Gets the reward token. The token will be distributed to all wallets that took part in the lockdrop.
    /// @return The reward token.
    function rewardToken() external view returns (IERC20);

    /// @notice Gets the vesting contract.
    /// @dev Part of the reward should be allocated on the lockdrop.
    /// @return The vesting contract.
    function vesting() external view returns (ITokenVesting);

    /// @notice Gets the Lockdrop Phase 2 contract.
    /// @return The Lockdrop Phase 2 contract.
    function phase2() external view returns (ILockdropPhase2);

    /// @notice Gets the address of token A.
    /// @return The address of token A.
    function tokenAAddress() external view returns (address);

    /// @notice Gets the address of token B.
    /// @return The address of token B.
    function tokenBAddress() external view returns (address);

    /// @notice Gets the price of token A.
    /// @return The price of token A.
    function tokenAPrice() external view returns (uint256);

    /// @notice Gets the price of token B.
    /// @return The price of token B.
    function tokenBPrice() external view returns (uint256);

    /// @notice Gets the locking tokens.
    /// @return The locking tokens.
    function getLockingTokens() external view returns (LockingToken[] memory);
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

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "../tokens/interfaces/IERC20Decimals.sol";
import "./ILockdrop.sol";
import "../IAccessControlHolder.sol";
import "../dex/core/interfaces/IUniswapV2Pair.sol";
import "../ZeroAddressGuard.sol";
import "../ZeroAmountGuard.sol";
import "../TransferGuard.sol";
import "../ApproveGaurd.sol";

/// @title Lockdrop
/// @dev This contract is used to manage a lockdrop event.
abstract contract Lockdrop is
    ILockdrop,
    IAccessControlHolder,
    ZeroAddressGuard,
    ZeroAmountGuard,
    TransferGuard,
    ApproveGuard
{
    /// @notice Router used for DEX interactions.
    IUniswapV2Router02 public override spartaDexRouter;

    /// @notice Access control contract.
    IAccessControl public immutable override acl;

    /// @notice Initial balance of LP tokens.
    uint256 public override initialLpTokensBalance;

    /// @notice The timestamp for when the lockdrop starts.
    uint256 public immutable override lockingStart;

    /// @notice The timestamp for when the lockdrop ends.
    uint256 public immutable override lockingEnd;

    /// @notice The timestamp for when the unlocking period ends.
    uint256 public immutable override unlockingEnd;

    /// @dev Verifies that the current allocation state equals the expected state.
    modifier onlyOnAllocationState(AllocationState expected) {
        AllocationState current = _allocationState();
        if (current != expected) {
            revert WrongAllocationState(current, expected);
        }
        _;
    }

    /// @notice Constructs the contract.
    /// @param _acl The access control list contract.
    /// @param _lockingStart The starting timestamp for the lockdrop.
    /// @param _lockingEnd The ending timestamp for the lockdrop.
    /// @param _unlockingEnd The ending timestamp for the unlocking period.
    constructor(
        IAccessControl _acl,
        uint256 _lockingStart,
        uint256 _lockingEnd,
        uint256 _unlockingEnd
    ) notZeroAddress(address(_acl)) {
        acl = _acl;
        if (_lockingStart > _unlockingEnd || _unlockingEnd > _lockingEnd) {
            revert TimestampsIncorrect();
        }
        lockingStart = _lockingStart;
        lockingEnd = _lockingEnd;
        unlockingEnd = _unlockingEnd;
    }

    /// @notice Gets the exchange pair for the lockdrop.
    /// @return The exchange pair.
    function exchangedPair() public view virtual returns (IUniswapV2Pair);

    /// @notice Transfers tokens from an ERC20 pair.
    function _transferFromERC20Pair(
        IUniswapV2Pair token,
        address from,
        address to,
        uint256 value
    ) internal {
        _transferFromERC20(IERC20(address(token)), from, to, value);
    }

    /// @notice Transfers tokens to an ERC20 pair.
    function _transferERC20Pair(
        IUniswapV2Pair token,
        address to,
        uint256 value
    ) internal {
        _transferERC20(IERC20(address(token)), to, value);
    }

    /// @notice Gets the tokens of the pairs of the lockdrop.
    /// @return The ERC20 tokens.
    function _tokens() internal view virtual returns (address, address);

    /// @notice Gets the current allocation state.
    /// @return The allocation state.
    function _allocationState() internal view returns (AllocationState) {
        if (block.timestamp >= lockingEnd) {
            return AllocationState.ALLOCATION_FINISHED;
        } else if (block.timestamp >= lockingStart) {
            return AllocationState.ALLOCATION_ONGOING;
        }

        return AllocationState.NOT_STARTED;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "../dex/core/interfaces/IUniswapV2Factory.sol";
import "./ILockdropPhase1.sol";
import "./Lockdrop.sol";
import "../dex/libs/HomarMath.sol";

/// @title LockdropPhase1
/// @notice The contract was created to provide liquidity on a newly created Sparta Dex. The contract gives the users possibility to lock the particular pair from different DEX that will be exchanged and then added as liquidity to the SpartaDex router contract.
contract LockdropPhase1 is ILockdropPhase1, Lockdrop {
    using HomoraMath for uint;
    using SafeMath for uint;

    uint256 public constant MAX_LOCKING_TOKENS = 5;
    uint256 public constant MAX_EXPIRATION_TIMESTAMPS = 7;
    uint256 public constant MAX_ALLOCATIAON_TO_WITHDRAW = 7;
    bytes32 public constant LOCKDROP_PHASE_1_RESOLVER =
        keccak256("LOCKDROP_PHASE_1_RESOLVER");

    uint256 internal constant VESTING_DURATION = 365 days / 2;
    uint8 internal removedLiquidityCounter_;
    IERC20 public immutable override rewardToken;
    ITokenVesting public immutable override vesting;

    ILockdropPhase2 public immutable override phase2;
    address public immutable override tokenAAddress;
    address public immutable override tokenBAddress;

    uint256 public immutable override tokenAPrice;
    uint256 public immutable override tokenBPrice;
    uint256 public override totalReward;

    uint256[] public lockingExpirationTimestamps_;

    LockingToken[] internal lockingTokens;
    uint256 internal removingLiqudityCounter;
    mapping(uint256 => uint256) public totalPointsInRound;
    mapping(address => uint256) public userAllocationsCount;
    mapping(address => mapping(uint256 => UserAllocation))
        internal userAllocations;
    mapping(uint256 => uint256) public totalRewardInTimeRange;
    mapping(address => uint256) public userRewardWithdrawn;
    mapping(address => uint256) internal _totalRewardPerWallet;
    mapping(address => uint256) public totalRewardCalculatedToAllocationId;

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
     * @notice Modifier created to check if the current state of lockdrop is as at least as defined one.
     * @dev Contract reverts with ToEarlyAllocationState, when the current state is less than expected.
     * @param expected LockdropState we should (at least) currently be in.
     */
    modifier atLeastTheLockdropState(LockdropState expected) {
        LockdropState current = state();
        if (current < expected) {
            revert ToEarlyAllocationState(current, expected);
        }
        _;
    }

    /**
     * @notice Modifier created to check the msg.sender of the transaction has rights to execute guarded functions in the contract.
     * @dev Contract reverts with OnlyLockdropPhase1ResolverAccess, when a signer does not have the role.
     */
    modifier onlyLockdropPhase1Resolver() {
        if (!acl.hasRole(LOCKDROP_PHASE_1_RESOLVER, msg.sender)) {
            revert OnlyLockdropPhase1ResolverAccess();
        }
        _;
    }
    /**
     * @notice Modifier created to check the given index of the token exist in the stored lockingTokens array.
     * @dev Contract reverts with LockingTokenNotExists, when the tokenIndex is bigger than length of the tokens.
     * @param _tokenIndex The index of the token.
     */
    modifier lockingTokenExists(uint256 _tokenIndex) {
        if (_tokenIndex >= lockingTokens.length) {
            revert LockingTokenNotExists();
        }
        _;
    }

    /**
     * @notice Function checks a wallet took part in the lockdrop.
     * @dev Function reverts with WalletDidNotTakePartInLockdrop, when the wallet did not part in the lockdrop.
     * @param _wallet Address of the wallet.
     */
    modifier userTookPartInLockdrop(address _wallet) {
        if (userAllocationsCount[_wallet] == 0) {
            revert WalletDidNotTakePartInLockdrop();
        }
        _;
    }

    constructor(
        ILockdropPhase2 _phase2,
        ITokenVesting _vesting,
        IAccessControl _acl,
        uint256 _lockingStart,
        uint256 _unlockingEnd,
        uint256 _lockingEnd,
        RewardParams memory _rewardParams,
        TokenParams memory _tokenParams,
        LockingToken[] memory _lockingTokens,
        uint32[] memory _lockingExpirationTimestamps
    )
        Lockdrop(_acl, _lockingStart, _lockingEnd, _unlockingEnd)
        notZeroAmount(_tokenParams.tokenAPrice)
        notZeroAmount(_tokenParams.tokenBPrice)
        notZeroAmount(_rewardParams.rewardAmount)
    {
        tokenAPrice = _tokenParams.tokenAPrice;
        tokenBPrice = _tokenParams.tokenBPrice;
        tokenAAddress = _tokenParams.tokenAToken;
        tokenBAddress = _tokenParams.tokenBToken;
        phase2 = _phase2;
        vesting = _vesting;
        rewardToken = _rewardParams.rewardToken;
        totalReward = _rewardParams.rewardAmount;

        _assingLockingTokens(_lockingTokens);
        _assingExpirationTimestamps(_lockingExpirationTimestamps);
    }

    /**
     * @notice Function allows a wallet to lock his tokens on the contract.
     * @param _tokenIndex Index of the token from lockingTokens array.
     * @param _value Number of tokens the user wants to lock.
     * @param _lockingExpirationTimestampIndex The timestamp index to which the wallet wants to lock its tokens.
     */
    function lock(
        uint256 _tokenIndex,
        uint256 _value,
        uint32 _lockingExpirationTimestampIndex
    )
        external
        override
        onlyOnAllocationState(AllocationState.ALLOCATION_ONGOING)
        lockingTokenExists(_tokenIndex)
        notZeroAmount(_value)
    {
        uint256 basePoints = _getPoints(_tokenIndex, _value);
        uint256 boost = calculateBoost(basePoints);
        uint256 points = boost + basePoints;

        if (
            _lockingExpirationTimestampIndex >
            lockingExpirationTimestamps_.length - 1
        ) {
            revert NotDefinedExpirationTimestamp();
        }
        IUniswapV2Pair token = lockingTokens[_tokenIndex].token;
        for (
            uint32 stampId = 0;
            stampId <= _lockingExpirationTimestampIndex;

        ) {
            totalPointsInRound[stampId] += points;
            unchecked {
                ++stampId;
            }
        }
        _transferFromERC20Pair(token, msg.sender, address(this), _value);
        uint256 nextWalletAllocations = ++userAllocationsCount[msg.sender];
        userAllocations[msg.sender][nextWalletAllocations] = UserAllocation({
            taken: false,
            value: _value,
            boost: boost,
            token: token,
            unlockTimestampIndex: _lockingExpirationTimestampIndex,
            points: points
        });

        emit LiquidityProvided(
            msg.sender,
            token,
            _lockingExpirationTimestampIndex,
            _value,
            points
        );
    }

    /**
     * @notice Function allows a wallet to unclock already locked tokens.
     * @param _allocationIndex Id of the allocation a wallet wants to take part tokens from.
     * @param _value Amount of tokens.
     */
    function unlock(
        uint256 _allocationIndex,
        uint256 _value
    )
        external
        onlyOnLockdropState(LockdropState.TOKENS_ALLOCATION_UNLOCKING_ONGOING)
        notZeroAmount(_value)
    {
        if (_allocationIndex > userAllocationsCount[msg.sender]) {
            revert AllocationDoesNotExist();
        }
        UserAllocation storage allocation = userAllocations[msg.sender][
            _allocationIndex
        ];
        IUniswapV2Pair token = allocation.token;
        if (_value > allocation.value) {
            revert NotEnoughToWithdraw();
        }
        _transferERC20Pair(token, msg.sender, _value);

        uint256 totalPointsToRemove = (_value * allocation.points) /
            allocation.value;
        allocation.boost =
            allocation.boost -
            ((_value * allocation.boost) / allocation.value);
        allocation.points -= totalPointsToRemove;
        allocation.value -= _value;

        for (uint32 stampId = 0; stampId <= allocation.unlockTimestampIndex; ) {
            totalPointsInRound[stampId] -= totalPointsToRemove;
            unchecked {
                ++stampId;
            }
        }

        emit LiquidityUnlocked(msg.sender, _allocationIndex, _value);
    }

    /**
     * @notice
     * @dev     .
     */
    function getRewardAndSendOnVesting()
        external
        override
        userTookPartInLockdrop(msg.sender)
    {
        if (phase2.lockingEnd() > block.timestamp) {
            revert Phase2NotFinished();
        }

        if (!isRewardCalculated(msg.sender)) {
            revert RewardNotCalculated();
        }

        uint256 reward = _totalRewardPerWallet[msg.sender];
        uint256 alreadyWithdrawn = userRewardWithdrawn[msg.sender];

        if (_rewardClaimed(alreadyWithdrawn, reward)) {
            revert MaxRewardExceeded();
        }
        uint256 toSendOnVesting = reward / 2;
        uint256 remainingReward = toSendOnVesting - alreadyWithdrawn;

        userRewardWithdrawn[msg.sender] = reward;

        if (remainingReward > 0) {
            _transferERC20(rewardToken, msg.sender, remainingReward);
        }

        vesting.addVesting(
            msg.sender,
            lockingEnd,
            VESTING_DURATION,
            _allowErc20(rewardToken, address(vesting), toSendOnVesting)
        );

        emit RewardWithdrawn(msg.sender, remainingReward);
        emit RewardSentOnVesting(msg.sender, toSendOnVesting);
    }

    function allocateRewardOnLockdropPhase2(
        uint256 _amount
    ) external userTookPartInLockdrop(msg.sender) {
        if (!isRewardCalculated(msg.sender)) {
            revert RewardNotCalculated();
        }

        uint256 walletTotalReward = _totalRewardPerWallet[msg.sender];
        uint256 toAllocateOnPhase2Max = walletTotalReward / 2;

        if (_amount + userRewardWithdrawn[msg.sender] > toAllocateOnPhase2Max) {
            revert MaxRewardExceeded();
        }

        _allowErc20(rewardToken, address(phase2), _amount);
        phase2.lockSparta(_amount, msg.sender);
        userRewardWithdrawn[msg.sender] += _amount;

        emit RewardLockedOnLockdropPhase2(msg.sender, _amount);
    }

    function removeSourceLiquidity(
        uint256 minToken0,
        uint256 minToken1,
        uint256 deadline_
    )
        external
        onlyOnLockdropState(LockdropState.TOKENS_ALLOCATION_FINISHED)
        onlyLockdropPhase1Resolver
    {
        uint256 lockingTokensLength = lockingTokens.length;

        if (removedLiquidityCounter_ == lockingTokensLength) {
            revert SourceLiquidityAlreadyRemoved();
        }

        uint256 balance = lockingTokens[removedLiquidityCounter_]
            .token
            .balanceOf(address(this));

        if (balance != 0) {
            _allowErc20(
                IERC20(address(lockingTokens[removedLiquidityCounter_].token)),
                address(lockingTokens[removedLiquidityCounter_].router),
                balance
            );
            (address token0, address token1) = _tokens();
            lockingTokens[removedLiquidityCounter_].router.removeLiquidity(
                token0,
                token1,
                balance,
                minToken0,
                minToken1,
                address(this),
                deadline_
            );
        }

        removedLiquidityCounter_++;
    }

    function addTargetLiquidity(
        IUniswapV2Router02 _router,
        uint256 tokenAMin,
        uint256 tokenBMin,
        uint256 _deadline
    )
        external
        onlyLockdropPhase1Resolver
        onlyOnLockdropState(LockdropState.SOURCE_LIQUIDITY_EXCHANGED)
    {
        if (address(spartaDexRouter) != address(0)) {
            revert TargetLiquidityAlreadyProvided();
        }

        spartaDexRouter = _router;
        address spartaDexRouterAddress = address(spartaDexRouter);

        (, , initialLpTokensBalance) = _router.addLiquidity(
            tokenAAddress,
            tokenBAddress,
            _allowMaxErc20(IERC20(tokenAAddress), spartaDexRouterAddress),
            _allowMaxErc20(IERC20(tokenBAddress), spartaDexRouterAddress),
            tokenAMin,
            tokenBMin,
            address(this),
            _deadline
        );
    }

    function withdrawExchangedTokens(
        uint256[] calldata allocationsIds
    ) external onlyOnLockdropState(LockdropState.TARGET_LIQUIDITY_PROVIDED) {
        uint256 totalLpToTransfer = 0;
        uint256 allocationsIdsLength = allocationsIds.length;
        if (allocationsIdsLength > MAX_ALLOCATIAON_TO_WITHDRAW) {
            revert MaxLengthExceeded();
        }
        for (
            uint256 allocationIndex = 0;
            allocationIndex < allocationsIdsLength;

        ) {
            UserAllocation memory allocation = userAllocations[msg.sender][
                allocationsIds[allocationIndex]
            ];
            if (allocation.taken) {
                revert TokenAllocationAlreadyTaken();
            }
            uint256 unlockTime = lockingExpirationTimestamps_[
                allocation.unlockTimestampIndex
            ];
            if (unlockTime > block.timestamp) {
                revert CannotUnlockTokensBeforeUnlockTime();
            }
            uint256 reward = calculateRewardFromAllocation(allocation);
            uint256 tokensToWithdraw = (reward * initialLpTokensBalance) /
                totalReward;

            totalLpToTransfer += tokensToWithdraw;
            userAllocations[msg.sender][allocationIndex].taken = true;

            unchecked {
                allocationIndex++;
            }
        }

        _transferERC20Pair(exchangedPair(), msg.sender, totalLpToTransfer);
    }

    function getLockingExpirationTimestamps()
        external
        view
        returns (uint256[] memory)
    {
        uint256 length = lockingExpirationTimestamps_.length;
        uint256[] memory timestamps = new uint256[](
            lockingExpirationTimestamps_.length
        );
        for (uint i = 0; i < length; ) {
            timestamps[i] = lockingExpirationTimestamps_[i];
            unchecked {
                ++i;
            }
        }

        return timestamps;
    }

    function calculateRewardFromAllocation(
        UserAllocation memory allocation
    ) public view returns (uint256) {
        uint256 reward = 0;
        uint32 unlockTimestampIndex = allocation.unlockTimestampIndex;
        for (uint32 timeIndex = 0; timeIndex <= unlockTimestampIndex; ) {
            reward +=
                (totalRewardInTimeRange[timeIndex] * allocation.points) /
                totalPointsInRound[timeIndex];

            unchecked {
                timeIndex++;
            }
        }

        return reward;
    }

    function calculateTotalReward(
        address _wallet
    ) external view returns (uint256) {
        uint256 reward = 0;
        uint256 allocationsLength = userAllocationsCount[_wallet];
        for (uint256 allocationId = 1; allocationId <= allocationsLength; ) {
            UserAllocation memory allocation = userAllocations[_wallet][
                allocationId
            ];
            uint32 unlockTimestampIndex = allocation.unlockTimestampIndex;
            for (uint32 timeIndex = 0; timeIndex <= unlockTimestampIndex; ) {
                reward +=
                    (totalRewardInTimeRange[timeIndex] * allocation.points) /
                    totalPointsInRound[timeIndex];

                unchecked {
                    timeIndex++;
                }
            }

            unchecked {
                allocationId++;
            }
        }

        return reward;
    }

    function getUserAllocations(
        address _wallet
    ) external view returns (UserAllocation[] memory) {
        uint256 count = userAllocationsCount[_wallet];
        UserAllocation[] memory allocations = new UserAllocation[](count);
        for (uint i = 0; i < count; ) {
            allocations[i] = userAllocations[_wallet][i + 1];
            unchecked {
                i++;
            }
        }

        return allocations;
    }

    function totalRewardCalculated(
        address _wallet
    ) external view userTookPartInLockdrop(_wallet) returns (uint256) {
        if (!isRewardCalculated(_wallet)) {
            revert RewardNotCalculated();
        }

        return _totalRewardPerWallet[_wallet];
    }

    function getLockingTokens()
        external
        view
        override
        returns (LockingToken[] memory)
    {
        uint256 length = lockingTokens.length;

        LockingToken[] memory _lockingTokens = new LockingToken[](
            lockingTokens.length
        );

        for (uint256 i = 0; i < length; ) {
            _lockingTokens[i] = lockingTokens[i];
            unchecked {
                ++i;
            }
        }

        return _lockingTokens;
    }

    function calculateAndStoreTotalRewardInChunks(
        address _wallet,
        uint256 _chunksAmount
    )
        public
        override
        atLeastTheLockdropState(LockdropState.TOKENS_ALLOCATION_FINISHED)
        userTookPartInLockdrop(_wallet)
        returns (uint256)
    {
        uint256 count = userAllocationsCount[_wallet];
        uint256 lastCalcuated = totalRewardCalculatedToAllocationId[_wallet];
        uint256 diff = count - lastCalcuated;

        if (_chunksAmount > diff) {
            revert CannotCalculateRewardForChunks();
        }

        uint256 reward = 0;
        uint256 stop = lastCalcuated + _chunksAmount;
        uint256 start = lastCalcuated + 1;

        for (uint allocationId = start; allocationId <= stop; ) {
            UserAllocation memory allocation = userAllocations[_wallet][
                allocationId
            ];

            uint32 unlockTimestampIndex = allocation.unlockTimestampIndex;
            for (uint32 timeIndex = 0; timeIndex <= unlockTimestampIndex; ) {
                reward +=
                    (totalRewardInTimeRange[timeIndex] * allocation.points) /
                    totalPointsInRound[timeIndex];

                unchecked {
                    timeIndex++;
                }
            }

            unchecked {
                allocationId++;
            }
        }

        totalRewardCalculatedToAllocationId[_wallet] += _chunksAmount;
        _totalRewardPerWallet[_wallet] += reward;

        return reward;
    }

    /**
     * @notice function checks the user has already calculated the reward.
     * @param _wallet address the .
     * @return  bool  .
     */
    function isRewardCalculated(address _wallet) public view returns (bool) {
        return
            userAllocationsCount[_wallet] != 0
                ? totalRewardCalculatedToAllocationId[_wallet] ==
                    userAllocationsCount[_wallet]
                : false;
    }

    /**
     * @notice function calculates the reward form the allocations of the particular wallet.
     * @dev if the index is bigger than max count, the function reverts with AllocationDoesNotExist.
     * @param _wallet the address of the wallet.
     * @param _allocations arrays of the ids of allocations.
     * @return uint256 totalReward earned by wallet.
     */
    function calculateRewardFromAllocations(
        address _wallet,
        uint256[] calldata _allocations
    ) public view returns (uint256) {
        uint256 reward = 0;
        uint256 allocationsLength = _allocations.length;
        uint256 maxId = userAllocationsCount[_wallet];

        for (uint256 allocationId = 0; allocationId < allocationsLength; ) {
            uint256 currentAllocation = _allocations[allocationId];
            if (currentAllocation > maxId) {
                revert AllocationDoesNotExist();
            }
            UserAllocation memory allocation = userAllocations[_wallet][
                currentAllocation
            ];
            uint32 unlockTimestampIndex = allocation.unlockTimestampIndex;
            for (uint32 timeIndex = 0; timeIndex <= unlockTimestampIndex; ) {
                reward +=
                    (totalRewardInTimeRange[timeIndex] * allocation.points) /
                    totalPointsInRound[timeIndex];

                unchecked {
                    timeIndex++;
                }
            }

            unchecked {
                allocationId++;
            }
        }

        return reward;
    }

    function exchangedPair() public view override returns (IUniswapV2Pair) {
        if (address(spartaDexRouter) == address(0)) {
            revert SpartaDexNotInitialized();
        }
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
     * @notice funciton returns curren state of the lockdrop.
     * @return  LockdropState current state from the LockdropPhase1 state machine.
     */
    function state() public view returns (LockdropState) {
        AllocationState allocationState = _allocationState();
        if (allocationState == AllocationState.NOT_STARTED) {
            return LockdropState.NOT_STARTED;
        } else if (allocationState == AllocationState.ALLOCATION_ONGOING) {
            if (block.timestamp > unlockingEnd) {
                return
                    LockdropState.TOKENS_ALLOCATION_ONGOING_UNLOCKING_FINISHED;
            }
            return LockdropState.TOKENS_ALLOCATION_UNLOCKING_ONGOING;
        } else {
            if (address(spartaDexRouter) != address(0)) {
                return LockdropState.TARGET_LIQUIDITY_PROVIDED;
            } else if (lockingTokens.length == removedLiquidityCounter_) {
                return LockdropState.SOURCE_LIQUIDITY_EXCHANGED;
            }
        }

        return LockdropState.TOKENS_ALLOCATION_FINISHED;
    }

    /**
     * @notice function used to calculate the price of one of locking tokens.
     * @dev
     * @param _tokenIndex index of the token from the locking tokens array..
     * @return uint256 the price defined as the amount of ETH * 2**112.
     */
    function getLPTokenPrice(
        uint256 _tokenIndex
    ) public view lockingTokenExists(_tokenIndex) returns (uint256) {
        IUniswapV2Pair pair = lockingTokens[_tokenIndex].token;

        uint totalSupply = pair.totalSupply();
        (uint r0, uint r1, ) = pair.getReserves();
        (uint px0, uint px1) = pair.token0() == tokenAAddress
            ? (tokenAPrice, tokenBPrice)
            : (tokenBPrice, tokenAPrice);
        uint sqrtK = HomoraMath.sqrt(r0.mul(r1)).fdiv(totalSupply);
        return
            sqrtK
                .mul(2)
                .mul(HomoraMath.sqrt(px0))
                .div(2 ** 56)
                .mul(HomoraMath.sqrt(px1))
                .div(2 ** 56);
    }

    /**
     * @notice funciton calcualte the boost from the base calculated points.
     * @param _basePoints base points calculated by _getPoints function.
     * @return uint256 boost calculated from the base points amount.
     */
    function calculateBoost(uint256 _basePoints) public view returns (uint256) {
        AllocationState allocationState = _allocationState();
        if (allocationState == AllocationState.ALLOCATION_ONGOING) {
            uint256 numerator = _basePoints *
                150 *
                (lockingEnd - block.timestamp);
            uint256 denominator = (lockingEnd - lockingStart) * 1000;
            return numerator / denominator;
        }

        return 0;
    }

    /**
     * @notice function validates and assigns the lockingTokens to the storage.
     * @dev function reverts with MaxLengthExceeded if the length of the given tokens is bigger than max.
     * @dev function reverts with MaxLengthExceeded if the length of the given tokens is bigger than max.
     * @param _lockingTokens the array of locking tokens.
     */
    function _assingLockingTokens(
        LockingToken[] memory _lockingTokens
    ) internal {
        uint256 lokingTokensLength = _lockingTokens.length;
        if (lokingTokensLength > MAX_LOCKING_TOKENS) {
            revert MaxLengthExceeded();
        }
        for (
            uint256 lockingTokenId = 0;
            lockingTokenId < lokingTokensLength;

        ) {
            lockingTokens.push(_lockingTokens[lockingTokenId]);
            {
                unchecked {
                    ++lockingTokenId;
                }
            }
        }
    }

    /**
     * @notice utils function which checks the reward is already fully withdrawn.
     * @param alreadyWithdrawn amount of already withdrawn tokens.
     * @param reward number of reward tokens.
     * @return bool alreadyWitdrawn reward is greater or equal the total reward..
     */
    function _rewardClaimed(
        uint256 alreadyWithdrawn,
        uint256 reward
    ) internal pure returns (bool) {
        return alreadyWithdrawn >= reward;
    }

    /**
     * @notice function validates the expiration timestamps before assigning they to the storage.
     * @dev function reverts with MaxLengthExceeded if the number of timestamps is bigger than the max length.
     * @dev function reverts with WrongExpirationTimestamps if the array is not sorted, or the first element is smaller than the locking end timestamp.
     * @param _lockingExpirationTimestamps array of timestamps.
     */
    function _assingExpirationTimestamps(
        uint32[] memory _lockingExpirationTimestamps
    ) internal {
        uint256 expirationTimestampsLength = _lockingExpirationTimestamps
            .length;
        if (expirationTimestampsLength > MAX_EXPIRATION_TIMESTAMPS) {
            revert MaxLengthExceeded();
        }
        uint256 prev = lockingEnd;
        uint256 lockdropDuration = (_lockingExpirationTimestamps[
            _lockingExpirationTimestamps.length - 1
        ] - lockingEnd);
        for (uint256 i = 0; i < expirationTimestampsLength; ) {
            uint256 current = _lockingExpirationTimestamps[i];
            if (prev >= current) {
                revert WrongExpirationTimestamps();
            }
            uint256 currentDuration = current - prev;
            totalRewardInTimeRange[i] =
                (totalReward * currentDuration) /
                lockdropDuration;
            prev = current;
            unchecked {
                ++i;
            }
        }
        lockingExpirationTimestamps_ = _lockingExpirationTimestamps;
    }

    /**
     * @notice function returns amount of points corresponding to the number of tokens from particualr index.
     * @param _tokenIndex index of the token from lockingTokens array.
     * @param _amount number of tokens.
     * @return uint256 points corresponding to the number of tokens form the index.
     */
    function _getPoints(
        uint256 _tokenIndex,
        uint256 _amount
    ) internal view lockingTokenExists(_tokenIndex) returns (uint256) {
        return (getLPTokenPrice(_tokenIndex) * _amount) / (2 ** 112);
    }

    /**
     * @notice function returns sorted addresses of the tokens.
     * @return address token with "lower" address.
     * @return address token with "bigger" address.
     */
    function _tokens() internal view override returns (address, address) {
        return
            tokenAAddress < tokenBAddress
                ? (tokenAAddress, tokenBAddress)
                : (tokenBAddress, tokenAAddress);
    }

    /**
     * @notice function returns the number of tokens realsed in one second.
     * @return uint256 amount of tokens in seconds.
     */
    function rewardRate() public view returns (uint256) {
        return
            totalReward /
            (lockingExpirationTimestamps_[
                lockingExpirationTimestamps_.length - 1
            ] - lockingEnd);
    }
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