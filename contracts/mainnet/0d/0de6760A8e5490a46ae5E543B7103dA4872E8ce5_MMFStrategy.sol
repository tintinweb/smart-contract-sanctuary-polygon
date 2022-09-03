pragma solidity ^0.6.12;

import "./interfaces/IMmfStrategy.sol";
import "./interfaces/IMmfRewardPool.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./interfaces/IInvestmentController.sol";
import "./interfaces/IUniswapV2Router01.sol";
import "./Operator.sol";

contract MMFStrategy is IMmfStrategy, Operator {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public mmf = address(0x22a31bD4cB694433B6de19e0aCC2899E553e9481);
    uint256 public mmfRewardPoolId = 0; // If MasterChef change pid then dev can also modify it
    address public refferal;
    address public collateralFund;
    address public investmentController;
    address public mmfRouter = address(0x51aBA405De2b25E5506DeA32A6697F450cEB1a17);

    bool initialized = false;

    struct RewardPool {
        address masterChef;
        address earnToken;
        uint256 staked;
        uint256 earned;
    }

    function initializing(
        address _collateralFund,
        address _investmentController
    ) public onlyOperator {
        require(!initialized, "Already initialized");
        require(_collateralFund != address(0), "Invalid address");
        require(_investmentController != address(0), "Invalid address");
        collateralFund = _collateralFund;
        investmentController = _investmentController;
        initialized = true;
    }

    RewardPool[] rewardPools;

    uint256 public totalMmfReward;

    modifier onlyInvestmentController() {
        require(msg.sender == investmentController, "!investmentController");
        _;
    }

    modifier onlyOperatorOrInvestmentController {
        require(msg.sender == operator() || msg.sender == investmentController, "!investmentController or !operator");
        _;
    }

    function getInvestedByController() public override view returns (uint256 _totalInvestedInStrategy) {
        _totalInvestedInStrategy = IInvestmentController(investmentController).getInvestedAmount(address(this));
    }

    function getPoolRewardInfo(uint256 _rwPid) public view returns (
        address _masterChef,
        address _earnToken,
        uint256 _mmfStaked,
        uint256 _earned
    ) {
        RewardPool memory pool = rewardPools[_rwPid];
        _masterChef = pool.masterChef;
        _earned = pool.earned;
        _earnToken = pool.earnToken;
        _mmfStaked = pool.staked;
    }

    function getTotalMmfStaked() public view returns (uint256 _totalMmfStaked) {
        _totalMmfStaked = 0;
        for (uint256 rwPid = 0; rwPid < rewardPools.length; rwPid++) {
            _totalMmfStaked = _totalMmfStaked.add(rewardPools[rwPid].staked);
        }
    }

    function getStakedInPool(uint256 _rwPid) public view returns (uint256 _stakedAmount) {
        RewardPool memory pool = rewardPools[_rwPid];
        _stakedAmount = pool.staked;
    }

    function getEarned(uint256 _rwPid) public view returns (uint256 _earned, address _earnToken) {
        RewardPool memory pool = rewardPools[_rwPid];
        _earnToken = pool.earnToken;
        _earned = pool.earned;
    }

    function getTotalEstimateReward() public override view returns (uint256 _totalMmfReward) {
        _totalMmfReward = 0;
        for (uint256 _rwPid = 0; _rwPid < rewardPools.length; _rwPid++) {
            RewardPool memory pool = rewardPools[_rwPid];
            if (pool.earnToken == mmf) {
                _totalMmfReward = _totalMmfReward.add(pool.earned);
            } else if (pool.earned > 0) {
                address[] memory _path = new address[](2);
                _path[0] = pool.earnToken;
                _path[1] = mmf;
                uint256[] memory estimate_out_amounts = IUniswapV2Router01(mmfRouter).getAmountsOut(pool.earned, _path);
                uint256 _mmf_out = estimate_out_amounts[estimate_out_amounts.length - 1];
                _totalMmfReward = _totalMmfReward.add(_mmf_out);
            }
        }
    }

    // Use for Pool Stake MMF => earn ALTs
    //TODO fix deposit functions
    function deposit(uint256 _amount, uint256 _rwPid) public override onlyOperator {
        require(_rwPid < rewardPools.length, "Invalid Reward Pool");
        uint256 maxDeposit = getInvestedByController();
        // Strategy can not deposit exceed invested amount that were accounted in Investment Controller;
        require(_amount.add(getTotalMmfStaked()) <= maxDeposit, "Exceed Invest Quota");
        RewardPool storage pool = rewardPools[_rwPid];
        address _pool_address = pool.masterChef;
        address _earnToken = pool.earnToken;

        IERC20(mmf).approve(_pool_address, 0);
        IERC20(mmf).approve(_pool_address, _amount);
        updateReward(_rwPid);
        if (_earnToken == mmf) {
            IMmfRewardPool(_pool_address).deposit(mmfRewardPoolId, _amount, refferal);
        } else {
            IMmfRewardPool(_pool_address).deposit(_amount);
        }
        pool.staked = pool.staked.add(_amount);

    }

    //If amount = 0 => withdraw reward, if amount > 0 it will withdraw from pool and claim reward
    function withdraw(uint256 _amount, uint256 _rwPid) public override onlyOperator {
        require(_rwPid < rewardPools.length, "Invalid Reward Pool");
        require(_amount <= getStakedInPool(_rwPid), "Exceed Staked Amount");
        withdrawOperation(_rwPid, _amount);
    }

    function returnToCollateralFund(uint256 _amount, uint256 _rwPid) public override onlyOperator {
        require(_rwPid < rewardPools.length, "Invalid Reward Pool");
        require(_amount <= getStakedInPool(_rwPid), "Exceed staked in pool");

        withdrawOperation(_rwPid, _amount);

        IERC20(mmf).safeTransfer(collateralFund, _amount);

        IInvestmentController(investmentController).recollateralized(_amount);
        // add event
    }

    function exitStrategy() public override onlyInvestmentController {

        for (uint256 _rwPid = 0; _rwPid < rewardPools.length; _rwPid++) {
            uint256 _stakedAmount = getStakedInPool(_rwPid);
            if (_stakedAmount > 0) {
                withdrawOperation(_rwPid, _stakedAmount);
            }
        }

        uint256 totalInvested = getInvestedByController();
        IERC20(mmf).safeTransfer(collateralFund, totalInvested);
        // add event
    }

    function addRewardPool(
        address _master_chef,
        address _earnToken
    ) public onlyOperator {
        require(_master_chef != address(0), "Invalid Address");
        require(_earnToken != address(0), "Invalid Address");

        rewardPools.push(RewardPool({
        masterChef : _master_chef,
        earnToken : _earnToken,
        staked : 0,
        earned : 0
        }));
        // add event
    }

    function updateReward(uint256 _rwPid) internal {
        RewardPool storage pool = rewardPools[_rwPid];
        uint256 pendingReward = 0;

        if (pool.earnToken == mmf) {
            pendingReward = IMmfRewardPool(pool.masterChef).pendingMeerkat(0, address(this));
        } else {
            pendingReward = IMmfRewardPool(pool.masterChef).pendingReward(address(this));
        }

        if (pendingReward > 0) {
            pool.earned = pool.earned.add(pendingReward);
        }
    }

    // TODO fix bugs
    function convertReward(uint256 _rwPid) public override onlyOperator {
        RewardPool storage pool = rewardPools[_rwPid];
        require(pool.earned > 0, "No Reward to convert");
        uint256 mmfReceived = 0;
        if (pool.earnToken != mmf) {
            mmfReceived = _swap(pool.earnToken, mmf, pool.earned, 9900);
        } else {
            mmfReceived = pool.earned;
        }
        pool.earned = 0;
        totalMmfReward = totalMmfReward.add(mmfReceived);
        // add event
    }

    function sendRewardToController(uint256 _amount) public override onlyInvestmentController {
        require(totalMmfReward > 0, "No Reward to distribute");
        require(_amount < totalMmfReward, "Exceed current mmf reward");
        IERC20(mmf).safeTransfer(investmentController, _amount);
        totalMmfReward = totalMmfReward.sub(_amount);
        // add event
    }

    function coverCollateralThreshold(uint256 _amount) public override onlyInvestmentController {
        require(_amount <= getInvestedByController(), "Exceed invested amount");
        //Using idle balance first to cover
        uint256 mmfBalance = IERC20(mmf).balanceOf(address(this));
        if (mmfBalance >= _amount) {
            IERC20(mmf).safeTransfer(collateralFund, _amount);
        } else {
            uint256 mmf_lacked_amount = _amount.sub(mmfBalance);
            for (uint256 rwPid = 0; rwPid < rewardPools.length; rwPid++) {
                uint256 pool_staked = getStakedInPool(rwPid);
                if (pool_staked >= mmf_lacked_amount) {
                    withdrawOperation(rwPid, mmf_lacked_amount);
                    break;
                } else {
                    withdrawOperation(rwPid, pool_staked);
                    mmf_lacked_amount = mmf_lacked_amount.sub(pool_staked);
                }
            }
        }

        IERC20(mmf).safeTransfer(collateralFund, _amount);
        IInvestmentController(investmentController).recollateralized(_amount);

        // add event
    }

    function withdrawOperation(uint256 _rwPid, uint256 _amount) internal {
        RewardPool storage pool = rewardPools[_rwPid];
        pool.staked = pool.staked.sub(_amount);
        updateReward(_rwPid);
        if (pool.earnToken == mmf) {
            IMmfRewardPool(pool.masterChef).withdraw(mmfRewardPoolId, _amount);
        } else {
            IMmfRewardPool(pool.masterChef).withdraw(_amount);
        }
    }

    function _swap(address inputToken, address outputToken, uint256 inputAmount, uint256 slip) public onlyOperator returns (uint256) {
        address[] memory _path = new address[](2);
        _path[0] = inputToken;
        _path[1] = outputToken;
        IERC20(inputToken).approve(mmfRouter, 0);
        IERC20(inputToken).approve(mmfRouter, inputAmount);
        uint256[] memory estimate_out_amounts = IUniswapV2Router01(mmfRouter).getAmountsOut(inputAmount, _path);
        uint256 outputAmount = estimate_out_amounts[estimate_out_amounts.length - 1];
        uint256 outputAmountMin = outputAmount.mul(slip).div(10000);
        uint256[] memory out_amounts = IUniswapV2Router01(mmfRouter).swapExactTokensForTokens(inputAmount, outputAmountMin, _path, address(this), now.add(1800));
        return out_amounts[out_amounts.length - 1];
    }


    function setMmfRewardPoolId(uint256 _pid) public onlyOperator {
        mmfRewardPoolId = _pid;
    }

    function setCollateralFund(address _collateralFund) public onlyOperator {
        require(_collateralFund != address(0), "Invalid address");
        collateralFund = _collateralFund;
    }

    function setInvestmentController(address _investmentController) public onlyOperator {
        require(_investmentController != address(0), "Invalid address");
        investmentController = _investmentController;
    }

    function setMmfRouter(address _mmfRouter) public onlyOperator {
        require(_mmfRouter != address(0), "Invalid address");
        mmfRouter = _mmfRouter;
    }

    function setRefferal(address _refferal) public onlyOperator {
        require(_refferal != address(0), "Invalid address");
        refferal = _refferal;
    }

    function transferToken(address _token, uint256 _amount) public onlyOperator {
        IERC20(_token).transfer(collateralFund, _amount);
    }

    function approve(address _token, address _spender) public onlyOperator {
        IERC20(_token).approve(_spender, 10000000000 ether);
    }

}

pragma solidity ^0.6.12;

import "./IGeneralStrategy.sol";

abstract contract IMmfStrategy is IGeneralStrategy {

    function deposit(uint256 _amount, uint256 _rwPid) external virtual;

    function withdraw(uint256 _amount, uint256 _rwPid) external virtual;

    function returnToCollateralFund(uint256 _amount, uint256 _rwPid) external virtual;

    function convertReward(uint256 _rwPid) external virtual;
}

pragma solidity ^0.6.12;

abstract contract IMmfRewardPool {

    //Interface for pool stake MMF => earn MMF
    function pendingMeerkat(uint256 _pid, address _user) external view virtual returns (uint256);

    function deposit(uint256 _pid, uint256 _amount, address _referrer) external virtual;

    function withdraw(uint256 _pid, uint256 _amount) external virtual;

    function userInfo(uint256 _pid, address _user) external view virtual returns (uint256, uint256);

    // Interface for pool Stake MMF => earn ALTs
    function pendingReward(address _user) external view virtual returns (uint256);

    function deposit(uint256 _amount) external virtual;

    function withdraw(uint256 _amount) external virtual;

    function userInfo(uint256 _user) external view virtual returns (uint256, uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity >=0.6.12;

abstract contract IInvestmentController {
    function collateralBalance(uint256 _assetId) external view virtual returns (uint256);

    function getUnDistributedReward(uint256 _strategyId) external view virtual returns (uint256, address);

    function getStrategyUnclaimedReward(uint256 _strategyId) external view virtual returns (uint256);

    function getInvestedAmount(address _strategyContract) external view virtual returns (uint256);

    function invest(uint256 _strategyId, uint256 _amount) external virtual;

    function recollateralized(uint256 _amount) external virtual;

    function claimReward(uint256 _strategyId, uint256 _amount) external virtual;

    function exitStrategy(uint256 _strategyId) external virtual;

    function distributeReward(uint256 _strategyId, uint256 _amount) external virtual;

    function coverCollateralThreshold(uint256 _assetId, uint256 _strategyId) external virtual;
}

pragma solidity >=0.6.12;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() internal {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

pragma solidity ^0.6.12;

abstract contract IGeneralStrategy {
    function getInvestedByController() external view virtual returns (uint256);

    function exitStrategy() external virtual;

    function sendRewardToController(uint256 _amount) external virtual;

    function getTotalEstimateReward() external virtual view  returns (uint256);

    function coverCollateralThreshold(uint256 _amount) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}