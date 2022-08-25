// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../../interfaces/IWETH.sol';
import '../BaseAdapter.sol';

contract WETHAdapter is BaseAdapter {
  using SafeMath for uint;

  function deposit(uint _amount) external payable {
    HousecatManagement mgmt = _getMgmt();
    IWETH(mgmt.weth()).deposit{value: _amount}();
  }

  function withdraw(uint _amount) external payable {
    HousecatManagement mgmt = _getMgmt();
    IWETH(mgmt.weth()).withdraw(_amount);
  }

  function withdrawUntil(uint _targetBalance) external payable {
    HousecatManagement mgmt = _getMgmt();
    IWETH weth = IWETH(mgmt.weth());
    uint currentBalance = weth.balanceOf(address(this));
    require(_targetBalance <= currentBalance, 'WETHAdapter: no enough balance');
    uint amount = currentBalance.sub(_targetBalance);
    weth.withdraw(amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IWETH is IERC20 {
  function deposit() external payable;

  function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import '../core/HousecatPool.sol';
import '../core/HousecatManagement.sol';

contract BaseAdapter {
  function _getPool() internal view returns (HousecatPool) {
    return HousecatPool(payable(address(this)));
  }

  function _getMgmt() internal view returns (HousecatManagement) {
    HousecatPool pool = _getPool();
    return HousecatManagement(pool.management());
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {UserSettings, PoolTransaction, MirrorSettings, RebalanceSettings, WalletContent, TokenData, TokenMeta, PoolState} from './structs.sol';
import {HousecatQueries} from './HousecatQueries.sol';
import {HousecatFactory} from './HousecatFactory.sol';
import {HousecatManagement} from './HousecatManagement.sol';

contract HousecatPool is HousecatQueries, ERC20, ReentrancyGuard {
  using SafeMath for uint;

  HousecatFactory public factory;
  HousecatManagement public management;
  address public mirrored;
  bool public suspended;
  uint public rebalanceCheckpoint;
  uint public cumulativeSlippage;
  uint public managementFeeCheckpoint;
  uint public performanceFeeHighWatermark;
  string private tokenName;
  string private tokenSymbol;
  bool private initialized;

  modifier whenNotPaused() {
    require(!management.paused(), 'HousecatPool: paused');
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == management.owner(), 'HousecatPool: only owner');
    _;
  }

  event TransferPoolToken(address indexed from, address indexed to, uint amount, uint value);
  event RebalancePool();
  event ManagementFeeCheckpointUpdated(uint secondsPassed);
  event ManagementFeeSettled(uint amountToMirrored, uint amountToTreasury);
  event PerformanceFeeHighWatermarkUpdated(uint newValue);
  event PerformanceFeeSettled(uint amountToMirrored, uint amountToTreasury);
  event RebalanceRewardCollected(uint amountToBeneficiary, uint amountToTreasury);

  constructor() ERC20('Housecat Pool Base', 'HCAT-Base') {}

  receive() external payable {}

  function initialize(
    address _factory,
    address _management,
    address _mirrored,
    uint _poolIdx
  ) external {
    require(!initialized, 'HousecatPool: already initialized');
    factory = HousecatFactory(payable(_factory));
    management = HousecatManagement(_management);
    mirrored = _mirrored;
    suspended = false;
    tokenName = string(abi.encodePacked('Housecat Pool ', Strings.toString(_poolIdx)));
    tokenSymbol = 'HCAT-PP';
    rebalanceCheckpoint = 0;
    cumulativeSlippage = 0;
    managementFeeCheckpoint = block.timestamp;
    performanceFeeHighWatermark = 0;
    initialized = true;
  }

  function name() public view override(ERC20) returns (string memory) {
    return tokenName;
  }

  function symbol() public view override(ERC20) returns (string memory) {
    return tokenSymbol;
  }

  function getPoolContent() public view returns (WalletContent memory) {
    TokenData memory assets = _getAssetData();
    TokenData memory loans = _getLoanData();
    return _getContent(address(this), assets, loans, false);
  }

  function getMirroredContent() external view returns (WalletContent memory) {
    TokenData memory assets = _getAssetData();
    TokenData memory loans = _getLoanData();
    return _getContent(mirrored, assets, loans, true);
  }

  function getWeightDifference() external view returns (uint) {
    TokenData memory assets = _getAssetData();
    TokenData memory loans = _getLoanData();
    return
      _getWeightDifference(
        _getContent(address(this), assets, loans, false),
        _getContent(mirrored, assets, loans, true)
      );
  }

  function getCumulativeSlippage() external view returns (uint, uint) {
    uint secondsSincePreviousRebalance = block.timestamp.sub(rebalanceCheckpoint);
    return (cumulativeSlippage, secondsSincePreviousRebalance);
  }

  function getAccruedManagementFee() external view returns (uint) {
    uint feePercentage = factory.getUserSettings(mirrored).managementFee;
    return _getAccruedManagementFee(feePercentage);
  }

  function getAccruedPerformanceFee() external view returns (uint) {
    uint poolValue = getPoolContent().netValue;
    uint feePercentage = factory.getUserSettings(mirrored).performanceFee;
    return _getAccruedPerformanceFee(poolValue, feePercentage);
  }

  function isRebalanceLocked() external view returns (bool) {
    RebalanceSettings memory settings = management.getRebalanceSettings();
    return _isRebalanceLocked(settings);
  }

  function deposit(address _to, PoolTransaction[] calldata _transactions) external payable whenNotPaused nonReentrant {
    require(!suspended, 'HousecatPool: suspended');

    MirrorSettings memory mirrorSettings = management.getMirrorSettings();

    // execute transactions and get pool states before and after
    (PoolState memory poolStateBefore, PoolState memory poolStateAfter) = _executeTransactions(
      _transactions,
      mirrorSettings
    );

    // require eth balance did not change
    require(poolStateAfter.ethBalance == poolStateBefore.ethBalance, 'HousecatPool: ETH balance changed');

    // require weight difference did not increase
    _validateWeightDifference(mirrorSettings, poolStateBefore, poolStateAfter);

    // require pool value did not decrease
    require(poolStateAfter.netValue >= poolStateBefore.netValue, 'HousecatPool: pool value reduced');

    uint depositValue = poolStateAfter.netValue.sub(poolStateBefore.netValue);

    // settle accrued fees
    _settleFees(poolStateBefore.netValue);

    // add deposit value to performance fee high watermark
    _updatePerformanceFeeHighWatermark(performanceFeeHighWatermark.add(depositValue));

    // mint pool tokens an amount based on the deposit value
    uint amountMint = depositValue;
    if (totalSupply() > 0) {
      require(poolStateBefore.netValue > 0, 'HousecatPool: pool netValue 0');
      amountMint = totalSupply().mul(depositValue).div(poolStateBefore.netValue);
    }
    _mint(_to, amountMint);
    emit TransferPoolToken(address(0), _to, amountMint, depositValue);
  }

  function withdraw(address _to, PoolTransaction[] calldata _transactions) external whenNotPaused nonReentrant {
    MirrorSettings memory mirrorSettings = management.getMirrorSettings();

    // execute transactions and get pool states before and after
    (PoolState memory poolStateBefore, PoolState memory poolStateAfter) = _executeTransactions(
      _transactions,
      mirrorSettings
    );

    // require eth balance did not decrease
    require(poolStateAfter.ethBalance >= poolStateBefore.ethBalance, 'HousecatPool: ETH balance decreased');

    // require weight difference did not increase
    _validateWeightDifference(mirrorSettings, poolStateBefore, poolStateAfter);

    // settle accrued fees
    _settleFees(poolStateBefore.netValue);

    uint withdrawValue = poolStateBefore.netValue.sub(poolStateAfter.netValue);

    // require withdraw value does not exceed what the withdtawer owns
    uint shareInPool = this.balanceOf(msg.sender).mul(PERCENT_100).div(totalSupply());
    uint maxWithdrawValue = poolStateBefore.netValue.mul(shareInPool).div(PERCENT_100);
    require(maxWithdrawValue >= withdrawValue, 'HousecatPool: balance exceeded');

    // reduce withdraw value from performance fee high watermark
    _updatePerformanceFeeHighWatermark(performanceFeeHighWatermark.sub(withdrawValue));

    // burn pool tokens an amount based on the withdrawn value
    uint amountBurn = totalSupply().mul(withdrawValue).div(poolStateBefore.netValue);
    if (maxWithdrawValue.sub(withdrawValue) < ONE_USD.div(20)) {
      // if the remaining value is less than 0.05 USD burn the rest
      amountBurn = this.balanceOf(msg.sender);
    }
    _burn(msg.sender, amountBurn);
    emit TransferPoolToken(msg.sender, address(0), amountBurn, withdrawValue);

    // send the received ETH to the withdrawer
    uint amountEthToSend = poolStateAfter.ethBalance.sub(poolStateBefore.ethBalance);
    (bool sent, ) = _to.call{value: amountEthToSend}('');
    require(sent, 'HousecatPool: sending ETH failed');
  }

  function rebalance(address _rewardsTo, PoolTransaction[] calldata _transactions) external whenNotPaused nonReentrant {
    require(!suspended, 'HousecatPool: suspended');

    RebalanceSettings memory rebalanceSettings = management.getRebalanceSettings();
    require(!_isRebalanceLocked(rebalanceSettings), 'HousecatPool: rebalance locked');
    if (rebalanceSettings.rebalancers.length > 0) {
      require(management.isRebalancer(msg.sender), 'HousecatPool: only rebalancer');
    }

    MirrorSettings memory mirrorSettings = management.getMirrorSettings();

    // execute transactions and get pool states before and after
    (PoolState memory poolStateBefore, PoolState memory poolStateAfter) = _executeTransactions(
      _transactions,
      mirrorSettings
    );

    // require eth balance did not change
    require(poolStateAfter.ethBalance == poolStateBefore.ethBalance, 'HousecatPool: ETH balance changed');

    // require pool value did not decrease more than slippage limit
    uint slippage = poolStateAfter.netValue >= poolStateBefore.netValue
      ? 0
      : poolStateBefore.netValue.sub(poolStateAfter.netValue).mul(PERCENT_100).div(poolStateBefore.netValue);

    _updateCumulativeSlippage(rebalanceSettings, slippage);

    _validateSlippage(rebalanceSettings, mirrorSettings, poolStateBefore.weightDifference, slippage);

    // require weight difference did not increase
    _validateWeightDifference(mirrorSettings, poolStateBefore, poolStateAfter);

    // mint trade tax based on how much the weight difference reduced
    _collectRebalanceReward(rebalanceSettings, poolStateBefore, poolStateAfter, _rewardsTo);

    rebalanceCheckpoint = block.timestamp;
    emit RebalancePool();
  }

  function settleManagementFee() external whenNotPaused nonReentrant {
    uint feePercentage = factory.getUserSettings(mirrored).managementFee;
    address treasury = management.treasury();
    _settleManagementFee(feePercentage, treasury);
  }

  function settlePerformanceFee() external whenNotPaused nonReentrant {
    uint poolValue = getPoolContent().netValue;
    uint feePercentage = factory.getUserSettings(mirrored).performanceFee;
    address treasury = management.treasury();
    _settlePerformanceFee(poolValue, feePercentage, treasury);
  }

  function setSuspended(bool _value) external onlyOwner {
    suspended = _value;
  }

  function _transfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal virtual override {
    super._transfer(_from, _to, _amount);
    uint poolValue = getPoolContent().netValue;
    uint transferValue = poolValue.mul(_amount).div(totalSupply());
    emit TransferPoolToken(_from, _to, _amount, transferValue);
  }

  function _getAssetData() private view returns (TokenData memory) {
    (address[] memory assets, TokenMeta[] memory assetsMeta) = management.getAssetsWithMeta();
    return _getTokenData(assets, assetsMeta);
  }

  function _getLoanData() private view returns (TokenData memory) {
    (address[] memory loans, TokenMeta[] memory loansMeta) = management.getLoansWithMeta();
    return _getTokenData(loans, loansMeta);
  }

  function _executeTransactions(PoolTransaction[] calldata _transactions, MirrorSettings memory _mirrorSettings)
    private
    returns (PoolState memory, PoolState memory)
  {
    TokenData memory assets = _getAssetData();
    TokenData memory loans = _getLoanData();

    // get state before
    WalletContent memory poolContentBefore = _getContent(address(this), assets, loans, false);
    WalletContent memory targetContent = _getContent(mirrored, assets, loans, true);
    if (targetContent.totalValue < _mirrorSettings.minMirroredValue) {
      targetContent = poolContentBefore;
    }
    uint weightDifferenceBefore = _getWeightDifference(poolContentBefore, targetContent);
    PoolState memory poolStateBefore = PoolState({
      ethBalance: address(this).balance.sub(msg.value),
      totalValue: poolContentBefore.totalValue,
      netValue: poolContentBefore.netValue,
      weightDifference: weightDifferenceBefore
    });

    // execute transactions
    for (uint i = 0; i < _transactions.length; i++) {
      require(management.isAdapter(_transactions[i].adapter), 'HousecatPool: unsupported adapter');
      (bool success, bytes memory result) = _transactions[i].adapter.delegatecall(_transactions[i].data);
      require(success, string(result));
    }

    // get state after
    WalletContent memory poolContentAfter = _getContent(address(this), assets, loans, false);
    uint weightDifferenceAfter = _getWeightDifference(poolContentAfter, targetContent);
    PoolState memory poolStateAfter = PoolState({
      ethBalance: address(this).balance,
      totalValue: poolContentAfter.totalValue,
      netValue: poolContentAfter.netValue,
      weightDifference: weightDifferenceAfter
    });

    return (poolStateBefore, poolStateAfter);
  }

  function _combineWeights(WalletContent memory _content) private pure returns (uint[] memory) {
    uint[] memory combinedWeights = new uint[](_content.assetWeights.length + _content.loanWeights.length);
    if (_content.totalValue != 0) {
      for (uint i = 0; i < _content.assetWeights.length; i++) {
        combinedWeights[i] = _content.assetWeights[i].mul(_content.assetValue).div(_content.totalValue);
      }
      for (uint i = 0; i < _content.loanWeights.length; i++) {
        combinedWeights[i + _content.assetWeights.length] = _content.loanWeights[i].mul(_content.loanValue).div(
          _content.totalValue
        );
      }
    }
    return combinedWeights;
  }

  function _getWeightDifference(WalletContent memory _poolContent, WalletContent memory _targetContent)
    private
    pure
    returns (uint)
  {
    uint[] memory poolWeights = _combineWeights(_poolContent);
    uint[] memory targetWeights = _combineWeights(_targetContent);
    uint totalDiff;
    for (uint i; i < poolWeights.length; i++) {
      totalDiff += poolWeights[i] > targetWeights[i]
        ? poolWeights[i].sub(targetWeights[i])
        : targetWeights[i].sub(poolWeights[i]);
    }
    return totalDiff;
  }

  function _isRebalanceLocked(RebalanceSettings memory _rebalanceSettings) internal view returns (bool) {
    uint secondsSincePreviousRebalance = block.timestamp.sub(rebalanceCheckpoint);
    return secondsSincePreviousRebalance < _rebalanceSettings.minSecondsBetweenRebalances;
  }

  function _validateWeightDifference(
    MirrorSettings memory _mirrorSettings,
    PoolState memory _before,
    PoolState memory _after
  ) private pure {
    if (
      _after.weightDifference > _mirrorSettings.maxWeightDifference && _after.totalValue > _mirrorSettings.minPoolValue
    ) {
      require(_after.weightDifference <= _before.weightDifference, 'HousecatPool: weight diff increased');
    }
  }

  function _validateSlippage(
    RebalanceSettings memory _rebalanceSettings,
    MirrorSettings memory _mirrorSettings,
    uint _initialWeightDifference,
    uint _slippage
  ) private view {
    if (_slippage > 0) {
      require(_initialWeightDifference > _mirrorSettings.maxWeightDifference, 'HousecatPool: already balanced');
    }
    require(_slippage <= _rebalanceSettings.maxSlippage, 'HousecatPool: slippage exceeded');
    require(cumulativeSlippage <= _rebalanceSettings.maxCumulativeSlippage, 'HousecatPool: cum. slippage exceeded');
  }

  function _getAccruedManagementFee(uint _annualFeePercentage) private view returns (uint) {
    uint secondsSinceLastSettlement = block.timestamp.sub(managementFeeCheckpoint);
    return _annualFeePercentage.mul(totalSupply()).mul(secondsSinceLastSettlement).div(365 days).div(PERCENT_100);
  }

  function _getAccruedPerformanceFee(uint _poolValue, uint _performanceFeePercentage) private view returns (uint) {
    if (_poolValue > performanceFeeHighWatermark) {
      uint profitPercentage = _poolValue.sub(performanceFeeHighWatermark).mul(PERCENT_100).div(
        performanceFeeHighWatermark
      );
      uint accruedFeePercentage = profitPercentage.mul(_performanceFeePercentage).div(PERCENT_100);
      return totalSupply().mul(accruedFeePercentage).div(PERCENT_100);
    }
    return 0;
  }

  function _updateCumulativeSlippage(RebalanceSettings memory _rebalanceSettings, uint _slippage) private {
    if (_rebalanceSettings.cumulativeSlippagePeriodSeconds == 0) {
      cumulativeSlippage = 0;
    } else {
      uint secondsSincePreviousRebalance = block.timestamp.sub(rebalanceCheckpoint);
      uint reduction = secondsSincePreviousRebalance.mul(_rebalanceSettings.maxCumulativeSlippage).div(
        _rebalanceSettings.cumulativeSlippagePeriodSeconds
      );
      if (reduction > cumulativeSlippage) {
        cumulativeSlippage = 0;
      } else {
        cumulativeSlippage = cumulativeSlippage.sub(reduction);
      }
    }
    cumulativeSlippage = cumulativeSlippage.add(_slippage);
  }

  function _updateManagementFeeCheckpoint() private {
    uint secondsSinceLastSettlement = block.timestamp.sub(managementFeeCheckpoint);
    managementFeeCheckpoint = block.timestamp;
    emit ManagementFeeCheckpointUpdated(secondsSinceLastSettlement);
  }

  function _updatePerformanceFeeHighWatermark(uint _poolValue) private {
    performanceFeeHighWatermark = _poolValue;
    emit PerformanceFeeHighWatermarkUpdated(_poolValue);
  }

  function _mintFee(
    uint _feeAmount,
    uint _taxPercent,
    address _treasury
  ) private returns (uint, uint) {
    uint amountToTreasury = _feeAmount.mul(_taxPercent).div(PERCENT_100);
    uint amountToMirrored = _feeAmount.sub(amountToTreasury);
    _mint(mirrored, amountToMirrored);
    _mint(_treasury, amountToTreasury);
    return (amountToMirrored, amountToTreasury);
  }

  function _settleManagementFee(uint _managementFeePercentage, address _treasury) private {
    uint feeAmount = _getAccruedManagementFee(_managementFeePercentage);
    if (feeAmount > 0) {
      (uint amountToMirrored, uint amountToTreasury) = _mintFee(
        feeAmount,
        management.getManagementFee().protocolTax,
        _treasury
      );
      emit ManagementFeeSettled(amountToMirrored, amountToTreasury);
    }
    _updateManagementFeeCheckpoint();
  }

  function _settlePerformanceFee(
    uint _poolValue,
    uint _performanceFeePercentage,
    address _treasury
  ) private {
    uint feeAmount = _getAccruedPerformanceFee(_poolValue, _performanceFeePercentage);
    if (feeAmount > 0) {
      (uint amountToMirrored, uint amountToTreasury) = _mintFee(
        feeAmount,
        management.getPerformanceFee().protocolTax,
        _treasury
      );
      emit PerformanceFeeSettled(amountToMirrored, amountToTreasury);
    }
    if (_poolValue > performanceFeeHighWatermark) {
      _updatePerformanceFeeHighWatermark(_poolValue);
    }
  }

  function _settleFees(uint _poolValue) internal {
    address treasury = management.treasury();
    UserSettings memory userSettings = factory.getUserSettings(mirrored);
    _settleManagementFee(userSettings.managementFee, treasury);
    _settlePerformanceFee(_poolValue, userSettings.performanceFee, treasury);
  }

  function _collectRebalanceReward(
    RebalanceSettings memory _settings,
    PoolState memory _before,
    PoolState memory _after,
    address _beneficiary
  ) private {
    if (_after.weightDifference < _before.weightDifference) {
      uint change = _before.weightDifference.sub(_after.weightDifference);
      uint rewardAmount = totalSupply().mul(change).mul(_settings.reward).div(PERCENT_100**2);
      if (rewardAmount > 0) {
        uint amountToTreasury = rewardAmount.mul(_settings.protocolTax).div(PERCENT_100);
        uint amountToBeneficiary = rewardAmount.sub(amountToTreasury);
        _mint(management.treasury(), amountToTreasury);
        _mint(_beneficiary, amountToBeneficiary);
        emit RebalanceRewardCollected(amountToBeneficiary, amountToTreasury);
      }
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import {Constants} from './Constants.sol';
import {TokenMeta, FeeSettings, MirrorSettings, RebalanceSettings} from './structs.sol';

contract HousecatManagement is Constants, Ownable, Pausable {
  using SafeMath for uint;

  address public treasury;
  address public weth;
  uint public minInitialDepositAmount = 1 ether;
  uint public userSettingsTimeLockSeconds = 60 * 60 * 24;
  mapping(address => bool) private adapters;
  mapping(address => bool) private supportedIntegrations;
  address[] private supportedAssets;
  address[] private supportedLoans;
  mapping(address => TokenMeta) private tokenMeta;

  MirrorSettings private mirrorSettings =
    MirrorSettings({
      minPoolValue: ONE_USD.mul(100),
      minMirroredValue: ONE_USD.mul(100),
      maxWeightDifference: SafeCast.toUint32(PERCENT_100.div(20))
    });

  RebalanceSettings private rebalanceSettings =
    RebalanceSettings({
      reward: SafeCast.toUint32(PERCENT_100.mul(25).div(10000)),
      protocolTax: SafeCast.toUint32(PERCENT_100.mul(25).div(100)),
      maxSlippage: SafeCast.toUint32(PERCENT_100.div(100)),
      maxCumulativeSlippage: SafeCast.toUint32(PERCENT_100.mul(3).div(100)),
      cumulativeSlippagePeriodSeconds: 60 * 60 * 24 * 7,
      minSecondsBetweenRebalances: 60 * 15,
      rebalancers: new address[](0)
    });

  FeeSettings private managementFee =
    FeeSettings({
      maxFee: SafeCast.toUint32(PERCENT_100.mul(25).div(100)),
      defaultFee: SafeCast.toUint32(PERCENT_100.div(100)),
      protocolTax: SafeCast.toUint32(PERCENT_100.mul(25).div(100))
    });

  FeeSettings private performanceFee =
    FeeSettings({
      maxFee: SafeCast.toUint32(PERCENT_100.mul(25).div(100)),
      defaultFee: SafeCast.toUint32(PERCENT_100.div(10)),
      protocolTax: SafeCast.toUint32(PERCENT_100.mul(25).div(100))
    });

  event UpdateTreasury(address treasury);
  event UpdateWETH(address weth);
  event UpdateMinInitialDeposit(uint minInitialDepositAmount);
  event UpdateUserSettingsTimeLock(uint userSettingsTimeLockSeconds);
  event SetAdapter(address adapter, bool enabled);
  event SetIntegration(address integration, bool enabled);
  event SetSupportedAssets(address[] _tokens);
  event SetSupportedLoans(address[] _tokens);
  event UpdateMirrorSettings(MirrorSettings mirrorSettings);
  event UpdateRebalanceSettings(RebalanceSettings rebalanceSettings);
  event UpdateManagementFee(FeeSettings managementFee);
  event UpdatePerformanceFee(FeeSettings performanceFee);
  event SetTokenMeta(address token, TokenMeta _tokenMeta);

  constructor(address _treasury, address _weth) {
    treasury = _treasury;
    weth = _weth;
  }

  function emergencyPause() external onlyOwner {
    _pause();
  }

  function emergencyUnpause() external onlyOwner {
    _unpause();
  }

  function updateTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
    emit UpdateTreasury(_treasury);
  }

  function updateWETH(address _weth) external onlyOwner {
    weth = _weth;
    emit UpdateWETH(_weth);
  }

  function updateMinInitialDepositAmount(uint _minInitialDepositAmount) external onlyOwner {
    minInitialDepositAmount = _minInitialDepositAmount;
    emit UpdateMinInitialDeposit(_minInitialDepositAmount);
  }

  function updateUserSettingsTimeLock(uint _userSettingsTimeLockSeconds) external onlyOwner {
    userSettingsTimeLockSeconds = _userSettingsTimeLockSeconds;
    emit UpdateUserSettingsTimeLock(_userSettingsTimeLockSeconds);
  }

  function isAdapter(address _adapter) external view returns (bool) {
    return adapters[_adapter];
  }

  function setAdapter(address _adapter, bool _enabled) external onlyOwner {
    adapters[_adapter] = _enabled;
    emit SetAdapter(_adapter, _enabled);
  }

  function getSupportedAssets() external view returns (address[] memory) {
    return supportedAssets;
  }

  function getSupportedLoans() external view returns (address[] memory) {
    return supportedLoans;
  }

  function getTokenMeta(address _token) external view returns (TokenMeta memory) {
    return tokenMeta[_token];
  }

  function getAssetsWithMeta() external view returns (address[] memory, TokenMeta[] memory) {
    TokenMeta[] memory meta = new TokenMeta[](supportedAssets.length);
    for (uint i = 0; i < supportedAssets.length; i++) {
      meta[i] = tokenMeta[supportedAssets[i]];
    }
    return (supportedAssets, meta);
  }

  function getLoansWithMeta() external view returns (address[] memory, TokenMeta[] memory) {
    TokenMeta[] memory meta = new TokenMeta[](supportedLoans.length);
    for (uint i = 0; i < supportedLoans.length; i++) {
      meta[i] = tokenMeta[supportedLoans[i]];
    }
    return (supportedLoans, meta);
  }

  function isIntegrationSupported(address _integration) external view returns (bool) {
    return supportedIntegrations[_integration];
  }

  function isAssetSupported(address _token, bool _excludeDelisted) external view returns (bool) {
    return _isTokenSupported(_token, supportedAssets, _excludeDelisted);
  }

  function isLoanSupported(address _token, bool _excludeDelisted) external view returns (bool) {
    return _isTokenSupported(_token, supportedLoans, _excludeDelisted);
  }

  function getMirrorSettings() external view returns (MirrorSettings memory) {
    return mirrorSettings;
  }

  function getRebalanceSettings() external view returns (RebalanceSettings memory) {
    return rebalanceSettings;
  }

  function isRebalancer(address _account) external view returns (bool) {
    RebalanceSettings memory settings = rebalanceSettings;
    for (uint i = 0; i < settings.rebalancers.length; i++) {
      if (_account == settings.rebalancers[i]) {
        return true;
      }
    }
    return false;
  }

  function getManagementFee() external view returns (FeeSettings memory) {
    return managementFee;
  }

  function getPerformanceFee() external view returns (FeeSettings memory) {
    return performanceFee;
  }

  function setSupportedAssets(address[] memory _tokens) external onlyOwner {
    supportedAssets = _tokens;
    emit SetSupportedAssets(_tokens);
  }

  function setSupportedLoans(address[] memory _tokens) external onlyOwner {
    supportedLoans = _tokens;
    emit SetSupportedLoans(_tokens);
  }

  function setTokenMeta(address _token, TokenMeta memory _tokenMeta) external onlyOwner {
    _setTokenMeta(_token, _tokenMeta);
  }

  function setTokenMetaMany(address[] memory _tokens, TokenMeta[] memory _tokensMeta) external onlyOwner {
    require(_tokens.length == _tokensMeta.length, 'HousecatManagement: array size mismatch');
    for (uint i = 0; i < _tokens.length; i++) {
      _setTokenMeta(_tokens[i], _tokensMeta[i]);
    }
  }

  function setSupportedIntegration(address _integration, bool _value) external onlyOwner {
    supportedIntegrations[_integration] = _value;
    emit SetIntegration(_integration, _value);
  }

  function updateMirrorSettings(MirrorSettings memory _mirrorSettings) external onlyOwner {
    _validateMirrorSettings(_mirrorSettings);
    mirrorSettings = _mirrorSettings;
    emit UpdateMirrorSettings(_mirrorSettings);
  }

  function updateRebalanceSettings(RebalanceSettings memory _rebalanceSettings) external onlyOwner {
    _validateRebalanceSettings(_rebalanceSettings);
    rebalanceSettings = _rebalanceSettings;
    emit UpdateRebalanceSettings(_rebalanceSettings);
  }

  function updateManagementFee(FeeSettings memory _managementFee) external onlyOwner {
    _validateFeeSettings(_managementFee);
    managementFee = _managementFee;
    emit UpdateManagementFee(_managementFee);
  }

  function updatePerformanceFee(FeeSettings memory _performanceFee) external onlyOwner {
    _validateFeeSettings(_performanceFee);
    performanceFee = _performanceFee;
    emit UpdatePerformanceFee(_performanceFee);
  }

  function _isTokenSupported(
    address _token,
    address[] memory _supportedTokens,
    bool _excludeDelisted
  ) private view returns (bool) {
    for (uint i = 0; i < _supportedTokens.length; i++) {
      if (_supportedTokens[i] == _token) {
        if (_excludeDelisted && tokenMeta[_token].delisted) {
          return false;
        }
        return true;
      }
    }
    return false;
  }

  function _setTokenMeta(address _token, TokenMeta memory _tokenMeta) private {
    require(_token != address(0), 'HousecatManagement: zero address');
    tokenMeta[_token] = _tokenMeta;
    emit SetTokenMeta(_token, _tokenMeta);
  }

  function _validateMirrorSettings(MirrorSettings memory _settings) private pure {
    require(_settings.maxWeightDifference <= PERCENT_100, 'maxWeightDifference > 100%');
  }

  function _validateRebalanceSettings(RebalanceSettings memory _settings) private pure {
    require(_settings.maxSlippage <= PERCENT_100.div(2), 'maxSlippage > 50%');
    require(_settings.reward <= PERCENT_100.mul(50).div(10000), 'reward > 0.50%');
    require(_settings.protocolTax <= PERCENT_100, 'protocolTax > 100%');
  }

  function _validateFeeSettings(FeeSettings memory _settings) private pure {
    require(_settings.maxFee <= PERCENT_100, 'maxFee too large');
    require(_settings.defaultFee <= _settings.maxFee, 'defaultFee > maxFee');
    require(_settings.protocolTax <= PERCENT_100.div(2), 'protocolTax > 50%');
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

struct FeeSettings {
  uint32 maxFee;
  uint32 defaultFee;
  uint32 protocolTax;
}

struct PoolTransaction {
  address adapter;
  bytes data;
}

struct MirrorSettings {
  uint minPoolValue;
  uint minMirroredValue;
  uint32 maxWeightDifference;
}

struct RebalanceSettings {
  uint32 reward;
  uint32 protocolTax;
  uint32 maxSlippage;
  uint32 maxCumulativeSlippage;
  uint32 cumulativeSlippagePeriodSeconds;
  uint32 minSecondsBetweenRebalances;
  address[] rebalancers;
}

struct TokenData {
  address[] tokens;
  uint[] decimals;
  uint[] prices;
  bool[] delisted;
}

struct TokenMeta {
  address priceFeed;
  uint8 decimals;
  bool delisted;
}

struct UserSettings {
  uint createdAt;
  uint32 managementFee;
  uint32 performanceFee;
}

struct WalletContent {
  uint[] assetBalances;
  uint[] loanBalances;
  uint[] assetWeights;
  uint[] loanWeights;
  uint assetValue;
  uint loanValue;
  uint totalValue;
  uint netValue;
}

struct PoolState {
  uint ethBalance;
  uint totalValue;
  uint netValue;
  uint weightDifference;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';
import {AggregatorV3Interface} from '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import {Constants} from './Constants.sol';
import {TokenMeta} from './structs.sol';
import {TokenData} from './structs.sol';
import {WalletContent} from './structs.sol';

contract HousecatQueries is Constants {
  using SafeMath for uint;

  function getTokenPrices(address[] memory _priceFeeds) external view returns (uint[] memory) {
    return _getTokenPrices(_priceFeeds);
  }

  function getTokenBalances(address _account, address[] memory _tokens) external view returns (uint[] memory) {
    return _getTokenBalances(_account, _tokens);
  }

  function getTokenWeights(
    uint[] memory _balances,
    uint[] memory _tokenPrices,
    uint[] memory _tokenDecimals
  ) external pure returns (uint[] memory, uint) {
    return _getTokenWeights(_balances, _tokenPrices, _tokenDecimals);
  }

  function getTokenValue(
    uint _balance,
    uint _price,
    uint _decimals
  ) external pure returns (uint) {
    return _getTokenValue(_balance, _price, _decimals);
  }

  function getTotalValue(
    uint[] memory _balances,
    uint[] memory _tokenPrices,
    uint[] memory _tokenDecimals
  ) external pure returns (uint) {
    return _getTotalValue(_balances, _tokenPrices, _tokenDecimals);
  }

  function getTokenAmounts(
    uint[] memory _weights,
    uint _totalValue,
    uint[] memory _tokenPrices,
    uint[] memory _tokenDecimals
  ) external pure returns (uint[] memory) {
    return _getTokenAmounts(_weights, _totalValue, _tokenPrices, _tokenDecimals);
  }

  function getTokenData(address[] memory _tokens, TokenMeta[] memory _tokensMeta)
    external
    view
    returns (TokenData memory)
  {
    return _getTokenData(_tokens, _tokensMeta);
  }

  function getContent(
    address _account,
    TokenData memory _assetData,
    TokenData memory _loanData,
    bool _excludeDelisted
  ) external view returns (WalletContent memory) {
    return _getContent(_account, _assetData, _loanData, _excludeDelisted);
  }

  function _getTokenPrices(address[] memory _priceFeeds) internal view returns (uint[] memory) {
    uint[] memory prices = new uint[](_priceFeeds.length);
    for (uint i; i < _priceFeeds.length; i++) {
      AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeeds[i]);
      (, int price, , , ) = priceFeed.latestRoundData();
      prices[i] = SafeCast.toUint256(price).mul(ONE_USD).div(10**priceFeed.decimals());
    }
    return prices;
  }

  function _getTokenBalances(address _account, address[] memory _tokens) internal view returns (uint[] memory) {
    uint[] memory balances = new uint[](_tokens.length);
    for (uint i = 0; i < _tokens.length; i++) {
      balances[i] = IERC20(_tokens[i]).balanceOf(_account);
    }
    return balances;
  }

  function _getTokenValue(
    uint _balance,
    uint _price,
    uint _decimals
  ) internal pure returns (uint) {
    return _balance.mul(_price).div(10**_decimals);
  }

  function _getTokenAmount(
    uint _value,
    uint _price,
    uint _decimals
  ) internal pure returns (uint) {
    return _value.mul(10**_decimals).div(_price);
  }

  function _getTotalValue(
    uint[] memory _balances,
    uint[] memory _tokenPrices,
    uint[] memory _tokenDecimals
  ) internal pure returns (uint) {
    uint totalValue;
    for (uint i = 0; i < _balances.length; i++) {
      uint value = _getTokenValue(_balances[i], _tokenPrices[i], _tokenDecimals[i]);
      totalValue = totalValue.add(value);
    }
    return totalValue;
  }

  function _getTokenWeights(
    uint[] memory _balances,
    uint[] memory _tokenPrices,
    uint[] memory _tokenDecimals
  ) internal pure returns (uint[] memory, uint) {
    uint totalValue = _getTotalValue(_balances, _tokenPrices, _tokenDecimals);
    uint[] memory weights = new uint[](_balances.length);
    if (totalValue > 0) {
      for (uint i = 0; i < _balances.length; i++) {
        uint value = _getTokenValue(_balances[i], _tokenPrices[i], _tokenDecimals[i]);
        weights[i] = value.mul(PERCENT_100).div(totalValue);
      }
    }
    return (weights, totalValue);
  }

  function _getTokenAmounts(
    uint[] memory _weights,
    uint _totalValue,
    uint[] memory _tokenPrices,
    uint[] memory _tokenDecimals
  ) internal pure returns (uint[] memory) {
    uint[] memory amounts = new uint[](_weights.length);
    for (uint i = 0; i < _weights.length; i++) {
      uint value = _totalValue.mul(_weights[i]).div(PERCENT_100);
      amounts[i] = _getTokenAmount(value, _tokenPrices[i], _tokenDecimals[i]);
    }
    return amounts;
  }

  function _mapTokensMeta(TokenMeta[] memory _tokensMeta)
    internal
    pure
    returns (
      address[] memory,
      uint[] memory,
      bool[] memory
    )
  {
    address[] memory priceFeeds = new address[](_tokensMeta.length);
    uint[] memory decimals = new uint[](_tokensMeta.length);
    bool[] memory delisted = new bool[](_tokensMeta.length);
    for (uint i; i < _tokensMeta.length; i++) {
      priceFeeds[i] = _tokensMeta[i].priceFeed;
      decimals[i] = _tokensMeta[i].decimals;
      delisted[i] = _tokensMeta[i].delisted;
    }
    return (priceFeeds, decimals, delisted);
  }

  function _getTokenData(address[] memory _tokens, TokenMeta[] memory _tokensMeta)
    internal
    view
    returns (TokenData memory)
  {
    (address[] memory priceFeeds, uint[] memory decimals, bool[] memory delisted) = _mapTokensMeta(_tokensMeta);
    uint[] memory prices = _getTokenPrices(priceFeeds);
    return TokenData({tokens: _tokens, decimals: decimals, prices: prices, delisted: delisted});
  }

  function _getTokenContent(
    address _account,
    TokenData memory _tokenData,
    bool _excludeDelisted
  )
    private
    view
    returns (
      uint[] memory,
      uint[] memory,
      uint
    )
  {
    uint[] memory tokenBalances = _getTokenBalances(_account, _tokenData.tokens);
    if (_excludeDelisted) {
      for (uint i = 0; i < tokenBalances.length; i++) {
        if (_tokenData.delisted[i]) {
          tokenBalances[i] = 0;
        }
      }
    }
    (uint[] memory tokenWeights, uint tokenValue) = _getTokenWeights(
      tokenBalances,
      _tokenData.prices,
      _tokenData.decimals
    );
    return (tokenBalances, tokenWeights, tokenValue);
  }

  function _getContent(
    address _account,
    TokenData memory _assetData,
    TokenData memory _loanData,
    bool _excludeDelisted
  ) internal view returns (WalletContent memory) {
    (uint[] memory assetBalances, uint[] memory assetWeights, uint assetValue) = _getTokenContent(
      _account,
      _assetData,
      _excludeDelisted
    );
    (uint[] memory loanBalances, uint[] memory loanWeights, uint loanValue) = _getTokenContent(
      _account,
      _loanData,
      _excludeDelisted
    );
    uint netValue = assetValue > loanValue ? assetValue.sub(loanValue) : 0;
    return
      WalletContent({
        assetBalances: assetBalances,
        loanBalances: loanBalances,
        assetWeights: assetWeights,
        loanWeights: loanWeights,
        assetValue: assetValue,
        loanValue: loanValue,
        totalValue: assetValue.add(loanValue),
        netValue: netValue
      });
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {HousecatManagement} from './HousecatManagement.sol';
import {HousecatPool} from './HousecatPool.sol';
import {UserSettings, PoolTransaction} from './structs.sol';

contract HousecatFactory {
  using SafeMath for uint;

  address private managementContract;
  address private poolTemplateContract;
  address[] private pools;
  mapping(address => address) private mirroredPool;
  mapping(address => bool) public isPool;
  mapping(address => UserSettings) private pendingUserSettings;
  mapping(address => UserSettings) private userSettings;
  modifier whenNotPaused() {
    HousecatManagement housecatManagement = HousecatManagement(managementContract);
    require(!housecatManagement.paused(), 'HousecatFactory: paused');
    _;
  }

  event InitiateUpdateUserSettings(address user, UserSettings userSettings);
  event UpdateUserSettings(address user, UserSettings userSettings);

  constructor(address _managementContract, address _poolTemplateContract) {
    managementContract = _managementContract;
    poolTemplateContract = _poolTemplateContract;
  }

  receive() external payable {}

  function createPool(address _mirrored, PoolTransaction[] calldata _transactions) external payable whenNotPaused {
    require(mirroredPool[_mirrored] == address(0), 'HousecatFactory: already mirrored');
    require(!isPool[_mirrored], 'HousecatFactory: mirrored is pool');
    require(
      msg.value >= HousecatManagement(managementContract).minInitialDepositAmount(),
      'HousecatFactory: insuff. initial deposit'
    );
    address poolAddress = Clones.clone(poolTemplateContract);
    HousecatPool pool = HousecatPool(payable(poolAddress));
    pool.initialize(address(this), managementContract, _mirrored, pools.length + 1);
    pools.push(poolAddress);
    mirroredPool[_mirrored] = poolAddress;
    isPool[poolAddress] = true;
    if (userSettings[_mirrored].createdAt == 0) {
      UserSettings memory defaultUserSettings = _getDefaultUserSettings();
      pendingUserSettings[_mirrored] = defaultUserSettings;
      userSettings[_mirrored] = defaultUserSettings;
    }
    if (msg.value > 0) {
      pool.deposit{value: msg.value}(msg.sender, _transactions);
    }
  }

  function initiateUpdateUserSettings(UserSettings memory _userSettings) external whenNotPaused {
    _userSettings.createdAt = block.timestamp;
    _validateUserSettings(_userSettings);
    pendingUserSettings[msg.sender] = _userSettings;
    emit InitiateUpdateUserSettings(msg.sender, _userSettings);
  }

  function updateUserSettings() external whenNotPaused {
    if (mirroredPool[msg.sender] != address(0)) {
      HousecatPool pool = HousecatPool(payable(mirroredPool[msg.sender]));
      _validateUpdateUserSettings(pool);
      pool.settleManagementFee();
      pool.settlePerformanceFee();
    }
    userSettings[msg.sender] = pendingUserSettings[msg.sender];
    emit UpdateUserSettings(msg.sender, userSettings[msg.sender]);
  }

  function getPoolByMirrored(address _mirrored) external view returns (address) {
    return mirroredPool[_mirrored];
  }

  function getNPools() external view returns (uint) {
    return pools.length;
  }

  function getPools(uint _fromIdx, uint _toIdx) external view returns (address[] memory) {
    address[] memory pools_ = new address[](_toIdx.sub(_fromIdx));
    for (uint i = 0; i < pools_.length; i++) {
      pools_[i] = pools[i];
    }
    return pools_;
  }

  function getPendingUserSettings(address _mirrored) external view returns (UserSettings memory) {
    return pendingUserSettings[_mirrored];
  }

  function getUserSettings(address _mirrored) external view returns (UserSettings memory) {
    return userSettings[_mirrored];
  }

  function _getDefaultUserSettings() internal view returns (UserSettings memory) {
    HousecatManagement management = HousecatManagement(managementContract);
    return
      UserSettings({
        createdAt: block.timestamp,
        managementFee: management.getManagementFee().defaultFee,
        performanceFee: management.getPerformanceFee().defaultFee
      });
  }

  function _validateUserSettings(UserSettings memory _userSettings) private view {
    HousecatManagement management = HousecatManagement(managementContract);
    require(
      _userSettings.managementFee <= management.getManagementFee().maxFee,
      'HousecatFactory: managementFee too high'
    );
    require(
      _userSettings.performanceFee <= management.getPerformanceFee().maxFee,
      'HousecatFactory: performanceFee too high'
    );
  }

  function _validateUpdateUserSettings(HousecatPool _pool) private view {
    if (_pool.totalSupply() == 0) {
      return;
    }
    UserSettings memory oldSettings = userSettings[msg.sender];
    UserSettings memory newSettings = pendingUserSettings[msg.sender];
    if (
      newSettings.managementFee <= oldSettings.managementFee && newSettings.performanceFee <= oldSettings.performanceFee
    ) {
      return;
    }
    HousecatManagement management = HousecatManagement(managementContract);
    require(
      block.timestamp - pendingUserSettings[msg.sender].createdAt > management.userSettingsTimeLockSeconds(),
      'HousecatFactory: user settings locked'
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

contract Constants {
  uint internal constant PERCENT_100 = 1e8;
  uint internal constant PRICE_DECIMALS = 18;
  uint internal constant ONE_USD = 10**PRICE_DECIMALS;

  function getPercent100() external pure returns (uint) {
    return PERCENT_100;
  }

  function getPriceDecimals() external pure returns (uint) {
    return PRICE_DECIMALS;
  }

  function getOneUSD() external pure returns (uint) {
    return ONE_USD;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}