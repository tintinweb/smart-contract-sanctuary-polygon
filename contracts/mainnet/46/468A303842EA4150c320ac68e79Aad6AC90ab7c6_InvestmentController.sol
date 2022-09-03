pragma solidity ^0.6.12;

import "./interfaces/IInvestmentController.sol";
import "./Operator.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IInvestmentController.sol";
import "./interfaces/IAssetController.sol";
import "./interfaces/IGeneralStrategy.sol";
import "./interfaces/IMultiAssetTreasury.sol";

contract InvestmentController is IInvestmentController, Operator {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Strategy {
        address contractAddress; // Smart contract of strategy
        address rewardToken; // Each strategy will be accounted profit in 1 token
        uint256 assetId; // Each Strategy can manage only 1 collateral of 1 asset
        uint256 investedAmount; // Amount invested for Strategy
        uint256 receivedReward; // Profits that received from Strategy
        uint256 totalDistributedReward; // Profits that distributed
        bool paused;// Total Profits that acquired to
    }

    Strategy[] strategies;

    //TODO function add strategy

    //Collateral reserve threshold
    mapping(uint256 => uint256) assetCrt; // asset collateral reserve threshold (crt = collateralReserve / target collateral)
    uint256 public MINIMUM_CRT = 250000; // Minimum crt is 25%, if crt < 25%, collateral will be sent from strategy to collateral fund
    uint256 public RATIO_PRECISION = 100000;
    uint256 private constant PRICE_PRECISION = 1e6;

    address public treasury;
    address public assetController;
    address public daoFund;
    address public collateralFund;
    address public rewardDistributor;

    bool initialized = false;

    function initializing(
        address _treasury,
        address _assetController,
        address _daoFund,
        address _collateralFund
    ) public onlyOperator {
        require(!initialized, "Already initialized");
        require(_treasury != address(0), "Invalid Address");
        require(_assetController != address(0), "Invalid Address");
        require(_daoFund != address(0), "Invalid Address");
        require(_collateralFund != address(0), "Invalid Address");
        treasury = _treasury;
        assetController = _assetController;
        daoFund = _daoFund;
        collateralFund = _collateralFund;
        initialized = true;
    }

    function tokenBalance(address _token) public view returns (uint256 _balance) {
        _balance = IERC20(_token).balanceOf(address(this));
    }

    function calcCrt(uint256 _assetId) public view returns (uint256 _crt, bool _isUnderThreshold, uint256 _underAmount) {
        address _collateral = IAssetController(assetController).getCollateral(_assetId);
        address _asset = IAssetController(assetController).getAsset(_assetId);

        uint256 _current_collateral_reserve = IERC20(_collateral).balanceOf(collateralFund);
        uint256 _asset_total_supply = IERC20(_asset).totalSupply();
        (,,,uint256 _asset_tcr,,,,) = IMultiAssetTreasury(treasury).info(_assetId);
        uint256 _target_collateral_reserve = _asset_tcr.mul(_asset_total_supply).div(PRICE_PRECISION);
        //crt = collateral reserved / target collateral
        _crt = _current_collateral_reserve.mul(RATIO_PRECISION).div(_target_collateral_reserve);
        _isUnderThreshold = _crt < MINIMUM_CRT;
        _underAmount = 0;
        if (_isUnderThreshold) {
            _underAmount = _target_collateral_reserve.mul(MINIMUM_CRT).div(RATIO_PRECISION).sub(_current_collateral_reserve);
        }
    }

    function refreshCrt() public {
        uint256 asset_count = IAssetController(assetController).assetCount();
        for (uint256 aid; aid < asset_count; aid++) {
            (uint256 _crt, ,) = calcCrt(aid);
            assetCrt[aid] = _crt;
        }
    }

    function coverCollateralThreshold(uint256 _assetId, uint256 _strategyId) public override onlyOperator {
        (, bool _isUnderCrt, uint256 _underAmount) = calcCrt(_assetId);
        require(_isUnderCrt, "No need to cover collateral threshold");
        require(strategies[_strategyId].investedAmount >= _underAmount, "Strategy not enough balance to retrieve");
        address _strategy_to_retrieve_investment = strategies[_strategyId].contractAddress;
        IGeneralStrategy(_strategy_to_retrieve_investment).coverCollateralThreshold(_underAmount);
    }

    function getUnDistributedReward(uint256 _sid) public override view returns (uint256 _unDistributedReward, address _rewardToken) {
        Strategy storage strategy = strategies[_sid];
        _unDistributedReward = strategy.receivedReward;
        _rewardToken = strategy.rewardToken;
    }

    function getStrategyUnclaimedReward(uint256 _sid) public override view returns (uint256 _unclaimedReward) {
        Strategy storage strategy = strategies[_sid];
        _unclaimedReward = IGeneralStrategy(strategy.contractAddress).getTotalEstimateReward();
    }

    function getInvestedAmount(address _strategyContract) public override view returns (uint256 _investedAmount) {
        (uint256 sid, bool hasPool) = getStrategyByContract(_strategyContract);
        _investedAmount = 0;
        if (hasPool) {
            _investedAmount = strategies[sid].investedAmount;
        }
    }

    // Calculated Collateral Has been transferred to invest
    function collateralBalance(uint256 _assetId) public override view returns (uint256 _collateralBalance) {
        _collateralBalance = 0;
        address collateral = IAssetController(assetController).getCollateral(_assetId);
        for (uint256 _sid; _sid < strategies.length; _sid++) {
            Strategy memory strategy = strategies[_sid];
            if (strategy.assetId == _assetId) {
                _collateralBalance = _collateralBalance.add(strategy.investedAmount).sub(strategy.receivedReward);
            }
        }
        _collateralBalance = _collateralBalance.add(IERC20(collateral).balanceOf(address(this)));
    }

    function invest(uint256 _strategyId, uint256 _amount) public override onlyOperator {
        require(_strategyId < strategies.length, "Strategy not existed");
        require(!strategies[_strategyId].paused, "Strategy paused");
        Strategy storage strategy = strategies[_strategyId];
        uint256 _assetId = strategy.assetId;
        address _collateral = IAssetController(assetController).getCollateral(_assetId);
        require(_amount < tokenBalance(_collateral), "Exceed current balance");
        IERC20(_collateral).safeTransfer(strategy.contractAddress, _amount);
        strategy.investedAmount = strategy.investedAmount.add(_amount);
        // add event
    }

    function recollateralized(uint256 _amount) public override {
        (uint256 _sid, bool _hasPool) = getStrategyByContract(msg.sender);
        require(_hasPool, "!strategy");
        Strategy storage strategy = strategies[_sid];
        strategy.investedAmount = strategy.investedAmount.sub(_amount);
        //add event
    }

    function exitStrategy(uint256 _sid) public override onlyOperator {
        require(_sid < strategies.length, "Strategy Not Existed");
        Strategy storage strategy = strategies[_sid];

        strategy.investedAmount = 0;
        IGeneralStrategy(strategy.contractAddress).exitStrategy();
    }

    function claimReward(uint256 _sid, uint256 _amount) public override onlyOperator {
        require(_sid < strategies.length, "Strategy Not Existed");
        Strategy storage strategy = strategies[_sid];

        IGeneralStrategy(strategy.contractAddress).sendRewardToController(_amount);
        strategy.receivedReward = strategy.receivedReward.add(_amount);
    }

    function distributeReward(uint256 _sid, uint256 _amount) public override onlyOperator {
        require(_sid < strategies.length, "Strategy Not Existed");
        Strategy storage strategy = strategies[_sid];
        require(_amount <= strategy.receivedReward, "exceed current reward");
        strategy.receivedReward = strategy.receivedReward.sub(_amount);
        strategy.totalDistributedReward = strategy.totalDistributedReward.add(_amount);

        IERC20(strategy.rewardToken).safeTransfer(rewardDistributor, _amount);
        // add event
    }

    function getStrategyByContract(address _contractAddress) internal view returns (uint256 _strategyId, bool _hasPool) {
        _strategyId = 0;
        _hasPool = false;
        for (uint256 _sid = 0; _sid < strategies.length; _sid++) {
            if (strategies[_sid].contractAddress == msg.sender) {
                _strategyId = _sid;
                _hasPool = true;
                break;
            }
        }
    }

    function addStrategy(
        address _strategy_address,
        address _reward_token,
        uint256 _assetId,
        bool _paused
    ) public onlyOperator {
        require(_strategy_address != address(0), "Invalid Address");
        require(_reward_token != address(0), "Invalid Address");
        uint256 _asset_count = IAssetController(assetController).assetCount();
        require(_assetId < _asset_count, "Asset not existed");

        strategies.push(Strategy({
        contractAddress : _strategy_address,
        rewardToken : _reward_token,
        assetId : _assetId,
        investedAmount : 0,
        receivedReward : 0,
        totalDistributedReward : 0,
        paused : _paused
        }));
        //add event
    }

    function toggleStrategy(uint256 _sid) public onlyOperator {
        Strategy storage strategy = strategies[_sid];
        strategy.paused = !strategy.paused;
    }

    function setTreasury(address _treasury) public onlyOperator {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
    }

    function setAssetController(address _assetController) public onlyOperator {
        require(_assetController != address(0), "Invalid address");
        assetController = _assetController;
    }

    function setDaoFund(address _daoFund) public onlyOperator {
        require(_daoFund != address(0), "Invalid address");
        daoFund = _daoFund;
    }

    function setCollateralFund(address _collateralFund) public onlyOperator {
        require(_collateralFund != address(0), "Invalid address");
        collateralFund = _collateralFund;
    }

    function setRewardDistributor(address _rewardDistributor) public onlyOperator {
        require(_rewardDistributor != address(0), "Invalid address");
        rewardDistributor = _rewardDistributor;
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

interface IAssetController {
    function assetCount() external view returns(uint256);

    function getAssetInfo(uint256 _assetId) external view returns (
        address _asset,
        address _collateral,
        address _oracle,
        bool _isStable
    );

    function getAsset(uint256 _assetId) external view returns(address);

    function getCollateral(uint256 _assetId) external view returns(address);

    function getOracle(uint256 _assetId) external view returns (address);

    function isAssetStable(uint256 _assetId) external view returns(bool);

    function getAssetPrice(uint256 _assetId) external view returns (uint256);

    function getXSharePrice() external view returns (uint256);

    function getAssetTotalSupply(uint256 _assetId) external view returns (uint256);

    function getCollateralPriceInDollar(uint256 _assetId) external view returns (uint);

    function updateOracle(uint256 _assetId) external;
}

pragma solidity ^0.6.12;

abstract contract IGeneralStrategy {
    function getInvestedByController() external view virtual returns (uint256);

    function exitStrategy() external virtual;

    function sendRewardToController(uint256 _amount) external virtual;

    function getTotalEstimateReward() external virtual view  returns (uint256);

    function coverCollateralThreshold(uint256 _amount) external virtual;
}

pragma solidity >=0.6.12;

interface IMultiAssetTreasury {
    function addCollateralPolicy(uint256 _aid, uint256 _price_band, uint256 _missing_decimals, uint256 _init_tcr, uint256 _init_ecr) external;

    function setMissingDecimals(uint256 _missing_decimals, uint256 _assetId) external;

    function hasPool(address _address) external view returns (bool);

    function collateralFund() external view returns (address);

    function globalCollateralBalance(uint256 _assetId) external view returns (uint256);

    function collateralValue(uint256 _assetId) external view returns (uint256);

    function buyback(uint256 _collateral_amount, uint256 _min_share_amount,uint256 _min_asset_out,uint256 _assetId) external;

    function recollateralize(uint256 _share_amount, uint256 _min_collateral_amount, uint256 _assetId) external;

    function requestTransfer(
        address token,
        address receiver,
        uint256 amount
    ) external;

    function info(uint256 _assetId)
    external
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );
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