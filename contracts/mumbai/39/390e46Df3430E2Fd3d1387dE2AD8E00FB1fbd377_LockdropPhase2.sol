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

interface IAccessControlHolder {
    function acl() external view returns (IAccessControl);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "../dex/periphery/interfaces/IUniswapV2Router02.sol";
import "../dex/core/interfaces/IUniswapV2Pair.sol";

interface ILockdrop {
    error WrongAllocationState(
        AllocationState current,
        AllocationState expected
    );

    enum AllocationState {
        NOT_STARTED,
        ALLOCATION_ONGOING,
        ALLOCATION_FINISHED
    }
    error ZeroTokens();
    error ZeroAddress();
    error TransferFailed();
    error ApproveFailed();
    error TimestampsIncorrect();

    function spartaDexRouter() external view returns (IUniswapV2Router02);

    function lockingStart() external view returns (uint256);

    function lockingEnd() external view returns (uint256);

    function unlockingEnd() external view returns (uint256);

    function initialLpTokensBalance() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "../tokens/interfaces/IERC20Decimals.sol";
import "./ILockdrop.sol";

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
        ALLOCATION_LOCKING_UNLOCKING_ONGOING,
        ALLOCATION_LOCKING_ONGOING_LOCKING_FINISHED,
        ALLOCATION_FINISHED,
        TOKENS_EXCHANGED
    }

    function lockSparta(uint256 _amount, address _wallet) external;

    function lockStable(uint256 _amount) external;

    function unlockStable(uint256 _amount) external;

    function walletSpartaLocked(
        address _wallet
    ) external view returns (uint256);

    function walletStableLocked(
        address _wallet
    ) external view returns (uint256);

    function exchangeTokens(
        IUniswapV2Router02 router_,
        uint256 spartaMinAmount_,
        uint256 stableMinAmount_,
        uint256 deadline_
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "../tokens/interfaces/IERC20Decimals.sol";
import "./ILockdrop.sol";
import "../IAccessControlHolder.sol";
import "../dex/core/interfaces/IUniswapV2Pair.sol";

abstract contract Lockdrop is ILockdrop, IAccessControlHolder {
    IUniswapV2Router02 public override spartaDexRouter;
    IAccessControl public immutable override acl;
    uint256 public override initialLpTokensBalance;
    uint256 public immutable override lockingStart;
    uint256 public immutable override lockingEnd;
    uint256 public immutable override unlockingEnd;

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

    function exchangedPair() external view virtual returns (IUniswapV2Pair);

    function _tokens() internal view virtual returns (address, address);

    modifier notZeroTokens(uint256 _value) {
        if (_value == 0) {
            revert ZeroTokens();
        }
        _;
    }

    function _allocationState() internal view returns (AllocationState) {
        if (block.timestamp >= lockingEnd) {
            return AllocationState.ALLOCATION_FINISHED;
        } else if (block.timestamp >= lockingStart) {
            return AllocationState.ALLOCATION_ONGOING;
        }

        return AllocationState.NOT_STARTED;
    }

    function _allowMaxErc20(
        IERC20 token_,
        address to_
    ) internal returns (uint256) {
        return _allowErc20(token_, to_, token_.balanceOf(address(this)));
    }

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

    modifier onlyOnAllocationState(AllocationState expected) {
        AllocationState current = _allocationState();
        if (current != expected) {
            revert WrongAllocationState(current, expected);
        }
        _;
    }

    modifier notZeroAddress(address _wallet) {
        if (_wallet == address(0)) {
            revert ZeroAddress();
        }
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "../dex/core/interfaces/IUniswapV2Factory.sol";
import "./ILockdropPhase2.sol";
import "./Lockdrop.sol";

contract LockdropPhase2 is ILockdropPhase2, Lockdrop {
    uint256 internal constant LP_CLAIMING_DURATION = 26 * 7 days;
    bytes32 public constant LOCKDROP_PHASE_2_RESOLVER =
        keccak256("LOCKDROP_PHASE_2_RESOLVER");

    IERC20 public immutable sparta;
    IERC20 public immutable stable;

    uint256 public spartaTotalLocked;
    uint256 public stableTotalLocked;
    uint256 public immutable totalReward;

    mapping(address => uint256) public override walletSpartaLocked;
    mapping(address => uint256) public override walletStableLocked;
    mapping(address => bool) public rewardTaken;
    mapping(address => uint256) public lpClaimed;

    constructor(
        IAccessControl acl_,
        IERC20 sparta_,
        IERC20 stable_,
        uint256 lockingStart_,
        uint256 lockingEnd_,
        uint256 unlockingEnd_,
        uint256 totalReward_
    )
        Lockdrop(acl_, lockingStart_, lockingEnd_, unlockingEnd_)
        notZeroAddress(address(sparta_))
        notZeroAddress(address(stable_))
        notZeroTokens(totalReward_)
    {
        sparta = sparta_;
        stable = stable_;
        totalReward = totalReward_;
    }

    function lockSparta(
        uint256 _amount,
        address _wallet
    )
        external
        onlyOnAllocationState(AllocationState.ALLOCATION_ONGOING)
        notZeroTokens(_amount)
        notZeroAddress(_wallet)
    {
        if (!sparta.transferFrom(msg.sender, address(this), _amount)) {
            revert TransferFailed();
        }

        spartaTotalLocked += _amount;
        walletSpartaLocked[_wallet] += _amount;

        emit Locked(msg.sender, _wallet, sparta, _amount);
    }

    function lockStable(
        uint256 _amount
    )
        external
        onlyOnAllocationState(AllocationState.ALLOCATION_ONGOING)
        notZeroTokens(_amount)
    {
        if (!stable.transferFrom(msg.sender, address(this), _amount)) {
            revert TransferFailed();
        }

        stableTotalLocked += _amount;
        walletStableLocked[msg.sender] += _amount;

        emit Locked(msg.sender, msg.sender, stable, _amount);
    }

    function unlockStable(
        uint256 _amount
    )
        external
        override
        onlyOnLockdropState(LockdropState.ALLOCATION_LOCKING_UNLOCKING_ONGOING)
    {
        uint256 locked = walletStableLocked[msg.sender];
        if (_amount > locked) {
            revert CannotUnlock();
        }

        stableTotalLocked -= _amount;
        walletStableLocked[msg.sender] -= _amount;

        if (!stable.transfer(msg.sender, _amount)) {
            revert TransferFailed();
        }

        emit Unlocked(msg.sender, stable, _amount);
    }

    function calculateRewardForSparta(
        uint256 spartaAmount
    ) public view returns (uint256) {
        if (spartaTotalLocked == 0) {
            return 0;
        }
        uint256 forSpartaReward = totalReward / 2;
        return (forSpartaReward * spartaAmount) / spartaTotalLocked;
    }

    function calculateRewardForStable(
        uint256 stableAmount
    ) public view returns (uint256) {
        if (stableTotalLocked == 0) {
            return 0;
        }
        uint256 forSpartaReward = totalReward / 2;
        return (forSpartaReward * stableAmount) / stableTotalLocked;
    }

    function calculateRewardForTokens(
        uint256 spartaAmount,
        uint256 stableAmount
    ) public view returns (uint256) {
        return
            calculateRewardForSparta(spartaAmount) +
            calculateRewardForStable(stableAmount);
    }

    function calculateReward(address wallet_) public view returns (uint256) {
        return
            calculateRewardForTokens(
                walletSpartaLocked[wallet_],
                walletStableLocked[wallet_]
            );
    }

    function getReward()
        external
        onlyOnLockdropState(LockdropState.TOKENS_EXCHANGED)
    {
        if (rewardTaken[msg.sender]) {
            revert RewardAlreadyTaken();
        }
        uint256 reward = calculateReward(msg.sender);
        if (!sparta.transfer(msg.sender, reward)) {
            revert TransferFailed();
        }
        rewardTaken[msg.sender] = true;
    }

    function availableToClaim(address _wallet) public view returns (uint256) {
        if (state() != LockdropState.TOKENS_EXCHANGED) {
            return 0;
        }
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

    function claimTokens()
        external
        onlyOnLockdropState(LockdropState.TOKENS_EXCHANGED)
    {
        uint256 toClaim = availableToClaim(msg.sender);
        if (toClaim == 0) {
            revert NothingToClaim();
        }

        if (!exchangedPair().transfer(msg.sender, toClaim)) {
            revert TransferFailed();
        }

        lpClaimed[msg.sender] += toClaim;
        emit TokensClaimed(msg.sender, toClaim);
    }

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

    function exchangeTokens(
        IUniswapV2Router02 router_,
        uint256 spartaMinAmount_,
        uint256 stableMinAmount_,
        uint256 deadline_
    )
        external
        onlyOnLockdropState(LockdropState.ALLOCATION_FINISHED)
        onlyLockdropPhase2Resolver
    {
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

    function state() public view returns (LockdropState) {
        AllocationState allocationState = _allocationState();
        if (allocationState == AllocationState.NOT_STARTED) {
            return LockdropState.NOT_STARTED;
        } else if (allocationState == AllocationState.ALLOCATION_ONGOING) {
            if (block.timestamp > unlockingEnd) {
                return
                    LockdropState.ALLOCATION_LOCKING_ONGOING_LOCKING_FINISHED;
            }
            return LockdropState.ALLOCATION_LOCKING_UNLOCKING_ONGOING;
        } else if (address(spartaDexRouter) == address(0)) {
            return LockdropState.ALLOCATION_FINISHED;
        }

        return LockdropState.TOKENS_EXCHANGED;
    }

    modifier onlyOnLockdropState(LockdropState expected) {
        LockdropState current = state();
        if (current != expected) {
            revert WrongLockdropState(current, expected);
        }
        _;
    }

    modifier onlyLockdropPhase2Resolver() {
        if (!acl.hasRole(LOCKDROP_PHASE_2_RESOLVER, msg.sender)) {
            revert OnlyLockdropPhase2ResolverAccess();
        }
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Decimals is IERC20 {
    function decimals() external view returns (uint8);
}