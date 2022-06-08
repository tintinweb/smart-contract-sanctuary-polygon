// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

interface ICarbonicShareRewardPool {
    function operator() external view returns (address);
    function tshare() external view returns (address);
    function treasury() external view returns (address);

    function poolInfo(uint256 _pid) external view returns (address, uint256, uint256, uint256, bool, uint256);
    function userInfo(uint256 _pid, address user) external view returns (uint256, uint256, uint256);
    function contracts(address _contract) external view returns (bool);
    function feeExcluded(address _contract) external view returns (bool);

    function totalAllocPoint() external view returns (uint256);
    function poolStartTime() external view returns (uint256);
    function poolEndTime() external view returns (uint256);

    function tSharePerSecond() external view returns (uint256);
    function runningTime() external view returns (uint256);
    function feeDecreaseInterval() external view returns (uint256);
    function feeDecreaseAmount() external view returns (uint256);
    function TOTAL_REWARDS() external view returns (uint256);
    function MAX_WITHDRAW_FEE() external view returns (uint256);

    function add(
        uint256 _allocPoint,
        address _token,
        bool _withUpdate,
        uint256 _lastRewardTime,
        uint256 withdrawFee
    ) external;
    function set(uint256 _pid, uint256 _allocPoint, uint256 withdrawFee) external;

    function getGeneratedReward(uint256 _fromTime, uint256 _toTime) external view returns (uint256);
    function pendingShare(uint256 _pid, address _user) external view returns (uint256);
    function massUpdatePools() external;
    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;

    function setOperator(address _operator) external;
    function allowContract(address _contract) external;
    function denyContract(address _contract) external;
    function setFeeExcluded(address _contract) external;
    function removeFeeExcluded(address _contract) external;
    function setFeeDecreaseInterval(uint256 value) external;
    function setFeeDecrease(uint256 value) external;
    function setTreasury(address _treasury) external;

    function governanceRecoverUnsupported(address _token, uint256 amount, address to) external;
}

interface ICarbonicZap {
    function setZapToken(address token, address pool) external;
    function zapMATIC(address token, uint256 minLiquidity) external payable;
    function zapBCT(address token, uint256 amount, uint256 minLiquidity) external;
}

contract CarbonicCompound is Ownable {
    struct UserInfo {
        uint256 shares;
        uint256 lastWithdraw;
    }

    struct PoolInfo {
        uint256 totalShares;
        uint256 sharePrice;
        address compoundToken;
        bool isLP;
        bool isActive;
    }

    address public Pool;
    address public Zap;
    address public BCT = 0x2F800Db0fdb5223b3C3f354886d907A671414A7F;
    address public SCO2;
    address public Router = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    uint256[] public activePools;
    mapping(uint256 => PoolInfo) public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    mapping(uint256 => address[]) public swapPaths;
    uint256 public rewardFee = 1000;
    uint256 public MAX_REWARD_FEE = 2000;

    modifier poolActive(uint256 pid) {
        require(poolInfo[pid].isActive, "CarbonicZap: pool not active");
        _;
    }

    constructor(address pool, address zap) {
        Pool = pool;
        Zap = zap;
        SCO2 = ICarbonicShareRewardPool(pool).tshare();
    }

    function add(uint256 pid, address compoundToken, bool isLP) external onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        pool.compoundToken = compoundToken;
        pool.isLP = isLP;
        pool.isActive = true;
        activePools.push(pid);
    }

    function set(uint256 pid, address compoundToken, bool isLP, bool isActive) external onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        pool.compoundToken = compoundToken;
        pool.isLP = isLP;
        pool.isActive = isActive;
    }

    function deactivate(uint256 pid) external onlyOwner {
        poolInfo[pid].isActive = false;
        uint256 length = activePools.length;
        for (uint256 i = 0; i < length; i ++) {
            if (activePools[i] == pid) {
                activePools[i] = activePools[length - 1];
                activePools.pop();
                break;
            }
        }
    }

    function setSwapPath(uint256 pid, address[] calldata path) external onlyOwner {
        swapPaths[pid] = path;
    }

    function setRewardFee(uint256 fee) external onlyOwner {
        require(fee <= MAX_REWARD_FEE, "CarbonicCompound: fee too high");
        rewardFee = fee;
    }

    function deposit(uint256 pid, uint256 amount) external poolActive(pid) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        (address token,,,,,) = ICarbonicShareRewardPool(Pool).poolInfo(pid);
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(Pool, amount);
        ICarbonicShareRewardPool(Pool).deposit(pid, amount);
        uint256 shares = amount * 1e18 / pool.sharePrice;
        if (user.shares == 0) {
            user.lastWithdraw = block.timestamp;
        }
        user.shares += shares;
        pool.totalShares += shares;
    }

    function withdraw(uint256 pid, uint256 amount) external {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.shares >= amount, "CarbonicZap: insufficient deposit");
        user.shares -= amount;
        pool.totalShares -= amount;
        (address token,,,,, uint256 withdrawFee) = ICarbonicShareRewardPool(Pool).poolInfo(pid);
        uint256 tokens = amount * pool.sharePrice / 1e18;
        ICarbonicShareRewardPool(Pool).withdraw(pid, tokens);
        uint256 fee = tokens * _calcWithdrawFee(withdrawFee, user.lastWithdraw) / 10000;
        if (fee > 0) {
            IERC20(token).transfer(ICarbonicShareRewardPool(Pool).treasury(), fee);
        }
        IERC20(token).transfer(msg.sender, tokens - fee);
    }

    function compound(uint256 pid) external {
        address treasury = ICarbonicShareRewardPool(Pool).treasury();
        uint256 fee = rewardFee;
        _compound(pid, treasury, fee);
    }

    function compoundAll() external {
        address treasury = ICarbonicShareRewardPool(Pool).treasury();
        uint256 fee = rewardFee;
        uint256 length = activePools.length;
        for (uint256 i = 0; i < length; i ++) {
            _compound(activePools[i], treasury, fee);
        }
    }

    function _compound(uint256 pid, address treasury, uint256 fee) internal poolActive(pid) {
        PoolInfo storage pool = poolInfo[pid];
        (address token,,,,,) = ICarbonicShareRewardPool(Pool).poolInfo(pid);
        ICarbonicShareRewardPool(Pool).withdraw(pid, 0);
        uint256 amountOut = _sellRewards();
        uint256 feeAmount = amountOut * fee / 10000;
        if (feeAmount > 0) {
            IERC20(BCT).transfer(treasury, feeAmount);
        }
        uint256 amount = amountOut - feeAmount;
        if (pool.isLP) {
            IERC20(BCT).approve(Zap, amount);
            ICarbonicZap(Zap).zapBCT(pool.compoundToken, amount, 1);
        } else {
            IERC20(BCT).approve(Router, amount);
            IUniswapV2Router02(Router).swapExactTokensForTokens(
                amount,
                1,
                swapPaths[pid],
                address(this),
                block.timestamp
            );
        }
        uint256 compoundAmount = IERC20(token).balanceOf(address(this));
        pool.sharePrice += compoundAmount * 1e18 / pool.totalShares;
        IERC20(token).approve(Pool, compoundAmount);
        ICarbonicShareRewardPool(Pool).deposit(pid, compoundAmount);
    }

    function _sellRewards() internal returns (uint256) {
        uint256 amount = IERC20(SCO2).balanceOf(address(this));
        IERC20(SCO2).approve(Router, amount);
        address[] memory path = new address[](2);
        path[0] = SCO2;
        path[1] = BCT;
        uint256[] memory amounts = IUniswapV2Router02(Router).swapExactTokensForTokens(
            amount,
            1,
            path,
            address(this),
            block.timestamp
        );
        return amounts[amounts.length - 1];
    }
 
    function _calcWithdrawFee(uint256 baseFee, uint256 lastWithdraw) internal view returns (uint256 fee) {
        uint256 feeDecreaseInterval = ICarbonicShareRewardPool(Pool).feeDecreaseInterval();
        uint256 feeDecreaseAmount = ICarbonicShareRewardPool(Pool).feeDecreaseAmount();
        uint256 subtractAmount = ((block.timestamp - lastWithdraw) / feeDecreaseInterval) * feeDecreaseAmount;
        if (subtractAmount < baseFee) {
            fee = baseFee - subtractAmount;
        } else {
            fee = 0;
        }
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