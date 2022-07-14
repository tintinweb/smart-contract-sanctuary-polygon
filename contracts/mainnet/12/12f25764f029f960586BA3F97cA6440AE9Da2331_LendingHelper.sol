// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {SafeMath} from './library/SafeMath.sol';
import {SafeERC20} from './library/SafeERC20.sol';
import {Address} from './library/Address.sol';
import {ERC20} from './library/ERC20.sol';
import {Math} from './library/Math.sol';
import {FullMath} from './library/FullMath.sol';

import {VaultAPI} from '../interfaces/IVault.sol';

import {IAaveOracle} from '../interfaces/IAaveOracle.sol';
import {IERC20} from '../interfaces/IERC20.sol';
import {IPDataProvider} from '../interfaces/IProtocolDataProvider.sol';
import {ILendingPool} from '../interfaces/ILendingPool.sol';
import {IAToken, IVariableDebtToken} from '../interfaces/IAaveTokens.sol';
import {IStrategy} from '../interfaces/IStrategy.sol';

/**
 * @title Epsylon Uniswap V3 Liquidity Provisioning Strategy.
 * @author Jake Fleming & 0xCross
 * @notice This strategy interacts with the Uniswap-v3 pool contracts directly,
 *         like their NFT wrapper does.
 *         The strategy will maintain a single position which is rebalanced over time,
 *         according an Epsylon mathematical model.
 */

contract LendingHelper {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Constants
    uint256 internal constant basisOne = 10000;
    uint256 internal constant MAX = type(uint256).max; // For uint256
    uint256 internal transferSlippage = 50;

    // Only set this to true externally when we want to trigger our keepers to harvest for us
    uint256 public wantDust = 1e4;
    uint256 public wethDust = 1e12;

    // OPS State Variables in bps
    uint256 private constant DEFAULT_COLLAT_MAX_MARGIN = 1000;

    address public want;
    address public wETH = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // Matic

    IStrategy public strategy;
    VaultAPI vault;

    uint256 public maxBorrowCollatRatio; // The maximum the aave protocol will let us borrow
    uint256 public targetCollatRatio = 5833; // The LTV we are levering up to
    uint256 public maxCollatRatio; // Closest to liquidation we'll risk

    uint256 public minRatio = 50;
    uint256 public lendingRatio = 3000; // In bps 100% of total want will be placed as collateral

    uint256 internal minRebalanceRatio = 5000; // If Matic price goes down we do not rebalance unless we are out of range
    uint256 internal maxRebalanceRatio = 7000; // If Matic price goes up we rebalance if the matic in principal is less than the borrowed

    // Supply and borrow tokens
    IAToken public aToken; // 0x1a13F4Ca1d028320A707D99520AbFefca3998b7F
    IVariableDebtToken public debtToken; // 0xeDe17e9d79fc6f9fF9250D9EEfbdB88Cc18038b5

    // AAVE protocol address
    IPDataProvider private constant dataProvider = IPDataProvider(0x7551b5D2763519d4e37e8B81929D336De671d46d);
    ILendingPool private constant lendingPool = ILendingPool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);
    IAaveOracle public constant aaveOracle = IAaveOracle(0xb023e699F5a33916Ea823A16485e259257cA8Bd1);

    constructor(address _vault) public {
        vault = VaultAPI(_vault);
        want = vault.token();

        // Set AAVE tokens
        (address _aToken, , ) = dataProvider.getReserveTokensAddresses(want);
        aToken = IAToken(_aToken);
        (, , address _debtToken) = dataProvider.getReserveTokensAddresses(wETH);
        debtToken = IVariableDebtToken(_debtToken);

        // Set collateral targets
        (uint256 ltv, uint256 liquidationThreshold) = getCollatRatios(want);
        maxCollatRatio = liquidationThreshold.sub(DEFAULT_COLLAT_MAX_MARGIN); // 8500 - 2000 = 6500 -> 65%
        maxBorrowCollatRatio = ltv.sub(DEFAULT_COLLAT_MAX_MARGIN); // 8000 - 1000 = 7000 -> 70%

        _approve();
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                                      Modifiers                                            //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    /**
     * Resolve governance address from Vault contract, used to make assertions on Strategy protected functions.
     */
    function governance() internal view returns (address) {
        return vault.governance();
    }

    function strategist() internal view returns (address) {
        return strategy.getStrategist();
    }

    // TODO Added strategist too.
    modifier onlyAuthorized() {
        require(
            msg.sender == governance() || msg.sender == strategist() || msg.sender == address(strategy),
            '!authorized'
        );
        _;
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                                   Public  Getters                                         //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    function name() external pure returns (string memory) {
        return 'Strategy Lending Helper v0.3';
    }

    function strategyWantBalance() public view returns (uint256) {
        return IERC20(want).balanceOf(address(strategy));
    }

    function balanceOfWantMaxForLend() public view returns (uint256) {
        return strategy.estimatedTotalAssets().mul(lendingRatio).div(basisOne);
    }

    function balanceOfAToken() public view returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    function balanceOfDebtToken() public view returns (uint256) {
        return debtToken.balanceOf(address(this));
    }

    function balanceOfWeth() public view returns (uint256) {
        return IERC20(wETH).balanceOf(address(this));
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function getCollatRatios(address token) public view returns (uint256 ltv, uint256 liquidationThreshold) {
        (, ltv, liquidationThreshold, , , , , , , ) = dataProvider.getReserveConfigurationData(token); // In bps ltv = 8000 & liquidationThreshold = 8500 for USDC
    }

    function getBorrowFromDepositInWant(uint256 deposit, uint256 collatRatio) public pure returns (uint256) {
        return deposit.mul(collatRatio).div(basisOne);
    }

    function getDepositFromBorrow(uint256 borrow, uint256 collatRatio) public pure returns (uint256) {
        return borrow.mul(basisOne).div(collatRatio);
    }

    function getCurrentPositionInWant() public view returns (uint256 deposits, uint256 borrows) {
        deposits = balanceOfAToken();
        borrows = _wethToWant(balanceOfDebtToken()); // Conversion needed to want
    }

    function netPositionInWant() public view returns (uint256) {
        // (uint256 deposits, uint256 borrows) = getCurrentPositionInWant();
        // return deposits.sub(borrows);
        uint256 deposits = balanceOfAToken();
        uint256 borrows = strategy.wethToWant(balanceOfDebtToken(), false);
        return deposits.sub(borrows);
    }

    function getCurrentCollatRatio() public view returns (uint256 currentCollatRatio) {
        (uint256 deposits, uint256 borrows) = getCurrentPositionInWant();
        if (deposits > 0) {
            currentCollatRatio = borrows.mul(basisOne).div(deposits);
        }
    }

    function triggerLend() public view returns (bool) {
        uint256 currentCollatRatio = getCurrentCollatRatio();
        // if (currentCollatRatio != 0 && currentCollatRatio < minRebalanceRatio) return true; NOTE In bearish not needed
        if (currentCollatRatio > maxRebalanceRatio) return true;
        if (currentCollatRatio >= maxBorrowCollatRatio) return true; // 7000 currently (redundant but who knows)
    }

    function summary()
        public
        view
        returns (
            uint256 collatRatio,
            uint256 collateral,
            uint256 debtInEth,
            uint256 debtInWant,
            uint256 lendRatio,
            uint256 netPosInWant
        )
    {
        (collateral, debtInWant) = getCurrentPositionInWant();
        collatRatio = getCurrentCollatRatio();
        debtInEth = balanceOfDebtToken();
        lendRatio = lendingRatio;
        netPosInWant = netPositionInWant();
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                          External Aave Operations  (protected)                            //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    /**
     * @dev Deposits -> how much money do we have as Collateral.
     */
    function balanceLending() external onlyAuthorized {
        // currentCollAmount = Deposits on Aave
        (uint256 currentCollAmount, ) = getCurrentPositionInWant();
        // Deposit available want as collateral as much as possible but always below max for lend
        uint256 targetCollAmount = balanceOfWantMaxForLend();

        if (targetCollAmount > currentCollAmount) {
            // Deposit more want as Collateral on Lending protocol.
            uint256 wantToDeposit = targetCollAmount.sub(currentCollAmount);
            uint256 collToDeposit = Math.min(strategyWantBalance(), wantToDeposit);
            if (collToDeposit > wantDust) {
                _depositCollateral(collToDeposit);
            }
        } else {
            _withdrawCollateral(currentCollAmount.sub(targetCollAmount));
        }
        _rebalanceLoan();
        _sendFundsToStrategy();
    }

    function rebalanceLoan() external onlyAuthorized {
        _rebalanceLoan();
        _sendFundsToStrategy(); /// @dev transfer is internally added here
    }

    function liquidateAllLend() external onlyAuthorized returns (uint256 _amountFree) {
        uint256 balanceOfDebtTokenInWant = strategy.wethToWant(balanceOfDebtToken(), false);
        if (strategy.balanceOfWethInWant() < balanceOfDebtTokenInWant) {
            uint256 dif = balanceOfDebtTokenInWant.sub(strategy.balanceOfWethInWant());
            strategy.swapToWeth(dif);
        }
        uint256 repayAmountInWeth = balanceOfDebtToken();
        _repayWeth(repayAmountInWeth);
        _withdrawCollateral(balanceOfAToken());
        _amountFree = balanceOfWant();
        _sendFundsToStrategy();
    }

    /**
     * @dev This is called from the _withdrawSome on the strategy.
     *      And it is used to remove some funds from the lending while maintaining the collateral ratio.
     * @notice Adjusts position down according an amount that needs to be freed.
     */
    function freeFunds(uint256 _amountToFree) external onlyAuthorized {
        if (_amountToFree == 0) return;
        _unwindPartialPosition(_wantToWeth(_amountToFree));
        // Repay required amount
        _sendFundsToStrategy();
    }

    function repayWeth(uint256 amount) external onlyAuthorized returns (uint256) {
        _repayWeth(amount);
    }

    function unwindPosition(uint256 _repayAmount) external onlyAuthorized {
        _repayWeth(_repayAmount);
        uint256 collatToWithdraw =
            strategy.wethToWant(_repayAmount, true).mul(basisOne).div(targetCollatRatio);
        _withdrawCollateral(collatToWithdraw);
    }

    function withdrawExcessCollateral(uint256 collatRatio) external onlyAuthorized returns (uint256 amount) {
        return _withdrawExcessCollateral(collatRatio);
    }

    function depositCollateral(uint256 amount) external onlyAuthorized {
        _depositCollateral(amount);
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                                   Internal  func                                          //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    function _rebalanceLoan() internal {
        // Check Collateral Ratio and if the delta is above the minimum required
        uint256 currColRatio = getCurrentCollatRatio();
        // If the delta is too small do not rebalance (minRatio)
        if (currColRatio < targetCollatRatio) {
            if (targetCollatRatio.sub(currColRatio) > minRatio) {
                _borrow();
            }
        } else if (currColRatio.sub(targetCollatRatio) > minRatio) {
            (uint256 deposits, uint256 borrows) = getCurrentPositionInWant();
            uint256 newBorrow = getBorrowFromDepositInWant(deposits, targetCollatRatio);
            // newBorrow is smaller than the old borrow, since we re reducing the position
            uint256 deltaBorrow = _wantToWeth(borrows.sub(newBorrow));
            _unwindPartialPosition(deltaBorrow);
        }
    }

    /// @notice Borrows up an amount according to the targetCollatRatio.
    function _borrow() internal returns (uint256) {
        (uint256 deposits, uint256 borrows) = getCurrentPositionInWant();
        uint256 newBorrow = getBorrowFromDepositInWant(deposits, targetCollatRatio);
        if (newBorrow <= borrows) return 0;

        uint256 totalAmountToBorrow = newBorrow.sub(borrows);
        if (totalAmountToBorrow < wantDust) return 0;

        // Borrow desired amount according to our targetCollatRatio
        _borrowWeth(_wantToWeth(totalAmountToBorrow));
        return totalAmountToBorrow;
    }

    function _unwindPartialPosition(uint256 _amountInWeth) internal {
        uint256 availableWeth = strategy.balanceOfWeth();
        if (strategy.balanceOfWeth() < _amountInWeth) {
            uint256 dif = _amountInWeth.sub(availableWeth);
            strategy.swapToWeth(dif);
        }
        uint256 toRepayInWeth = Math.min(_amountInWeth, strategy.balanceOfWeth());
        if (toRepayInWeth > wethDust) {
            _repayWeth(toRepayInWeth);
            // In this case is withdraw till the targetCollatRatio,
            _withdrawExcessCollateral(targetCollatRatio);
        }
    }

    function _repayWeth(uint256 amount) internal onlyAuthorized returns (uint256) {
        if (amount == 0) return 0;
        // Get funds from the strategy to repay loan
        _transferWethFromStrat(amount);
        uint256 toRepay = Math.min(amount, balanceOfWeth());
        return lendingPool.repay(address(wETH), toRepay, 2, address(this));
    }

    function _depositCollateral(uint256 amount) internal returns (uint256) {
        if (amount == 0) return 0;
        _transferWantFromStrat(amount);
        lendingPool.deposit(want, amount, address(this), 0); // 0 for referral
        return amount;
    }

    function _withdrawExcessCollateral(uint256 collatRatio) internal returns (uint256 amount) {
        (uint256 deposits, uint256 borrows) = getCurrentPositionInWant();
        uint256 theoDeposits = getDepositFromBorrow(borrows, collatRatio);
        if (deposits > theoDeposits) {
            uint256 toWithdraw = deposits.sub(theoDeposits);
            amount = _withdrawCollateral(toWithdraw);
        }
        _sendFundsToStrategy();
    }

    function _withdrawCollateral(uint256 amount) internal returns (uint256) {
        if (amount == 0) return 0;
        uint256 borrowCollValue = _wethToWant(balanceOfDebtToken()).mul(basisOne).div(targetCollatRatio);
        uint256 maxCollValue = Math.min(borrowCollValue, balanceOfAToken());
        uint256 maxWithdraw = balanceOfAToken().sub(maxCollValue);
        if (maxWithdraw == 0) return 0;
        uint256 toWithdraw = Math.min(maxWithdraw, amount);
        lendingPool.withdraw(want, toWithdraw, address(this));
        return toWithdraw;
    }

    function _borrowWeth(uint256 amount) internal returns (uint256) {
        if (amount == 0) return 0;
        lendingPool.borrow(address(wETH), amount, 2, 0, address(this)); // 2 for variable rate & 0 for referral
        return amount;
    }

    function _wantToWeth(uint256 _wantAmount) internal view returns (uint256) {
        if (_wantAmount == 0) return 0;
        return _wantAmount.mul(1e18).div(_wethPrice());
    }

    function _wethToWant(uint256 _wethAmount) internal view returns (uint256) {
        if (_wethAmount == 0) return 0;
        return _wethPrice().mul(_wethAmount).div(1e18);
    }

    function _wethPrice() internal view returns (uint256) {
        return aaveOracle.getAssetPrice(address(wETH)).div(100);
    }

    function _approve() internal {
        IERC20(want).safeApprove(address(lendingPool), MAX);
        IERC20(address(wETH)).safeApprove(address(lendingPool), MAX);
        IERC20(address(aToken)).safeApprove(address(lendingPool), MAX);
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                                 Internal Transfers                                        //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    function _transferWethFromStrat(uint256 amount) internal {
        uint256 wethBal = balanceOfWeth();
        uint256 stratWethBal = strategy.balanceOfWeth();
        if (wethBal < amount) {
            uint256 toTransfer = Math.min(amount.sub(wethBal), stratWethBal);
            IERC20(wETH).safeTransferFrom(address(strategy), address(this), toTransfer);
            _receiveFundsCheck(stratWethBal, strategy.balanceOfWeth(), balanceOfWeth(), wethBal, toTransfer);
        }
    }

    function _transferWantFromStrat(uint256 amount) internal {
        uint256 wantBal = balanceOfWant();
        uint256 stratWantBal = strategy.balanceOfWant();
        if (wantBal < amount) {
            uint256 toTransfer = Math.min(amount.sub(wantBal), stratWantBal);
            IERC20(want).safeTransferFrom(address(strategy), address(this), toTransfer);
            _receiveFundsCheck(stratWantBal, strategy.balanceOfWant(), balanceOfWant(), wantBal, toTransfer);
        }
    }

    function _sendFundsToStrategy() internal {
        uint256 wantBal = balanceOfWant();
        uint256 wethBal = balanceOfWeth();
        uint256 stratWethBal = strategy.balanceOfWeth();
        uint256 stratWantBal = strategy.balanceOfWant();
        if (wantBal > 0) {
            IERC20(want).safeTransfer(address(strategy), wantBal);
        }
        if (wethBal > 0) {
            IERC20(wETH).safeTransfer(address(strategy), wethBal);
        }
        _sendFundsCheck(stratWantBal, strategy.balanceOfWant(), balanceOfWant(), wantBal);
        _sendFundsCheck(stratWethBal, strategy.balanceOfWeth(), balanceOfWeth(), wethBal);
    }

    function _sendFundsCheck(
        uint256 _stratBefore,
        uint256 _stratNow,
        uint256 _current,
        uint256 _before
    ) internal pure {
        uint256 contractDelta = _before.sub(_current);
        uint256 stratDelta = _stratNow.sub(_stratBefore);
        require(stratDelta == contractDelta && stratDelta == _before, '!TransferSanity');
        // NOTE: added check to make sure this is the same as the transferred amount
    }

    function _receiveFundsCheck(
        uint256 _stratBefore,
        uint256 _stratNow,
        uint256 _current,
        uint256 _before,
        uint256 _amount
    ) internal pure {
        uint256 contractDelta = _current.sub(_before);
        uint256 stratDelta = _stratBefore.sub(_stratNow);
        require(stratDelta == contractDelta && stratDelta == _amount, '!TransferSanity');
        // NOTE: added check to make sure this is the same as the transferred amount
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                                       Setters                                             //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    function setCollateralTargets(
        uint256 _targetCollatRatio,
        uint256 _maxCollatRatio,
        uint256 _maxBorrowCollatRatio
    ) external onlyAuthorized {
        (uint256 ltv, uint256 liquidationThreshold) = getCollatRatios(want);

        require(_targetCollatRatio < liquidationThreshold);
        require(_maxCollatRatio < liquidationThreshold);
        require(_targetCollatRatio < _maxCollatRatio);
        require(_maxBorrowCollatRatio < ltv);

        targetCollatRatio = _targetCollatRatio;
        maxCollatRatio = _maxCollatRatio;
        maxBorrowCollatRatio = _maxBorrowCollatRatio;
    }

    function setDust(uint256 _wantDust, uint256 _wethDust) external onlyAuthorized {
        wantDust = _wantDust;
        wethDust = _wethDust;
    }

    function setStrategy(address _strategy) external onlyAuthorized {
        strategy = IStrategy(_strategy);
    }

    function setTransferSlippage(uint256 _transferSlippage) external onlyAuthorized {
        transferSlippage = _transferSlippage;
    }

    function setMinsAndMaxs(uint256 _minRatio, uint256 _lendingRatio) external onlyAuthorized {
        require(_minRatio < maxBorrowCollatRatio);
        minRatio = _minRatio;

        require(_lendingRatio < basisOne);
        lendingRatio = _lendingRatio;
    }

    function setRebalanceRatios(uint256 _minRebalanceRatio, uint256 _maxRebalanceRatio)
        external
        onlyAuthorized
    {
        require(_minRebalanceRatio < _maxRebalanceRatio);
        minRebalanceRatio = _minRebalanceRatio;
        maxRebalanceRatio = _maxRebalanceRatio;
    }

    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//
    //                         External Helpers Only Authorized                                  //
    //-------------------------------------------------------------------------------------------//
    //-------------------------------------------------------------------------------------------//

    // Emergency function that we can use to deleverage manually if something is broken
    function manualDeleverageInWant(uint256 amountI, uint256 amountII) external onlyAuthorized {
        _repayWeth(_wantToWeth(amountI));
        _withdrawCollateral(amountII);
    }

    // Emergency function that we can use to deleverage manually if something is broken
    function manualDeleverageWant(uint256 amount) external onlyAuthorized {
        uint256 borrow = getBorrowFromDepositInWant(amount, targetCollatRatio);
        _repayWeth(_wantToWeth(borrow));
        _withdrawCollateral(amount);
    }

    // Emergency function that we can use to deleverage manually if something is broken
    function deleverageWithCollateral(uint256 _collatRatio) external onlyAuthorized {
        // Max up to ltv (8250), just only because we are repaying right away
        uint256 amountWithdraw = _withdrawExcessCollateral(_collatRatio); // NOTE sendFundsToStrat already included there
        strategy.swapToWeth(amountWithdraw);
        _repayWeth(_wantToWeth(amountWithdraw));
    }

    // Emergency function that we can use to release want if something is broken
    function manualReleaseWant(uint256 amount) external onlyAuthorized {
        _withdrawCollateral(amount);
    }

    // Emergency function that send funds to the strategy after a manual function
    function manualSendFundsToStrategy() external onlyAuthorized {
        _sendFundsToStrategy();
    }
}

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
		require(c >= a, 'SafeMath: addition overflow');

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
		return sub(a, b, 'SafeMath: subtraction overflow');
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	 * overflow (when the result is negative).
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
		require(b <= a, errorMessage);
		uint256 c = a - b;

		return c;
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
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, 'SafeMath: multiplication overflow');

		return c;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts on
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
		return div(a, b, 'SafeMath: division by zero');
	}

	/**
	 * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
		require(b > 0, errorMessage);
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold

		return c;
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts when dividing by zero.
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
		return mod(a, b, 'SafeMath: modulo by zero');
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * Reverts with custom message when dividing by zero.
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
		require(b != 0, errorMessage);
		return a % b;
	}
}

import { SafeMath } from './SafeMath.sol';
import { Address } from './Address.sol';
import { IERC20 } from '../../interfaces/IERC20.sol';

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

	function safeTransfer(
		IERC20 token,
		address to,
		uint256 value
	) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
	}

	function safeTransferFrom(
		IERC20 token,
		address from,
		address to,
		uint256 value
	) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
	}

	/**
	 * @dev Deprecated. This function has issues similar to the ones found in
	 * {IERC20-approve}, and its usage is discouraged.
	 *
	 * Whenever possible, use {safeIncreaseAllowance} and
	 * {safeDecreaseAllowance} instead.
	 */
	function safeApprove(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		// safeApprove should only be called when setting an initial allowance,
		// or when resetting it to zero. To increase and decrease it, use
		// 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
		// solhint-disable-next-line max-line-length
		require(
			(value == 0) || (token.allowance(address(this), spender) == 0),
			'SafeERC20: approve from non-zero to non-zero allowance'
		);
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
	}

	function safeIncreaseAllowance(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		uint256 newAllowance = token.allowance(address(this), spender).add(value);
		_callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
	}

	function safeDecreaseAllowance(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		uint256 newAllowance =
			token.allowance(address(this), spender).sub(value, 'SafeERC20: decreased allowance below zero');
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

		bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
		if (returndata.length > 0) {
			// Return data is optional
			// solhint-disable-next-line max-line-length
			require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
		}
	}
}

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
		// According to EIP-1052, 0x0 is the value returned for not-yet created accounts
		// and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
		// for accounts without code, i.e. `keccak256('')`
		bytes32 codehash;
		bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
		// solhint-disable-next-line no-inline-assembly
		assembly {
			codehash := extcodehash(account)
		}
		return (codehash != accountHash && codehash != 0x0);
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
		require(address(this).balance >= amount, 'Address: insufficient balance');

		// solhint-disable-next-line avoid-low-level-calls, avoid-call-value
		(bool success, ) = recipient.call{ value: amount }('');
		require(success, 'Address: unable to send value, recipient may have reverted');
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
		return functionCall(target, data, 'Address: low-level call failed');
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
	 * `errorMessage` as a fallback revert reason when `target` reverts.
	 *
	 * _Available since v3.1._
	 */
	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return _functionCallWithValue(target, data, 0, errorMessage);
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
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
	}

	/**
	 * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
	 * with `errorMessage` as a fallback revert reason when `target` reverts.
	 *
	 * _Available since v3.1._
	 */
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(address(this).balance >= value, 'Address: insufficient balance for call');
		return _functionCallWithValue(target, data, value, errorMessage);
	}

	function _functionCallWithValue(
		address target,
		bytes memory data,
		uint256 weiValue,
		string memory errorMessage
	) private returns (bytes memory) {
		require(isContract(target), 'Address: call to non-contract');

		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

import { Context } from './Context.sol';
import { SafeMath } from './SafeMath.sol';
import { Address } from './Address.sol';
import { IERC20 } from '../../interfaces/IERC20.sol';

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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

contract ERC20 is Context, IERC20 {
	using SafeMath for uint256;
	using Address for address;

	mapping(address => uint256) private _balances;

	mapping(address => mapping(address => uint256)) private _allowances;

	uint256 private _totalSupply;

	string private _name;
	string private _symbol;
	uint8 private _decimals;

	/**
	 * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
	 * a default value of 18.
	 *
	 * To select a different value for {decimals}, use {_setupDecimals}.
	 *
	 * All three of these values are immutable: they can only be set once during
	 * construction.
	 */
	constructor(string memory name, string memory symbol) public {
		_name = name;
		_symbol = symbol;
		_decimals = 18;
	}

	/**
	 * @dev Returns the name of the token.
	 */
	function name() public view returns (string memory) {
		return _name;
	}

	/**
	 * @dev Returns the symbol of the token, usually a shorter version of the
	 * name.
	 */
	function symbol() public view returns (string memory) {
		return _symbol;
	}

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 * For example, if `decimals` equals `2`, a balance of `505` tokens should
	 * be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * Tokens usually opt for a value of 18, imitating the relationship between
	 * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
	 * called.
	 *
	 * NOTE: This information is only used for _display_ purposes: it in
	 * no way affects any of the arithmetic of the contract, including
	 * {IERC20-balanceOf} and {IERC20-transfer}.
	 */
	function decimals() public view returns (uint8) {
		return _decimals;
	}

	/**
	 * @dev See {IERC20-totalSupply}.
	 */
	function totalSupply() public view override returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @dev See {IERC20-balanceOf}.
	 */
	function balanceOf(address account) public view override returns (uint256) {
		return _balances[account];
	}

	/**
	 * @dev See {IERC20-transfer}.
	 *
	 * Requirements:
	 *
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
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
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 */
	function approve(address spender, uint256 amount) public virtual override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	/**
	 * @dev See {IERC20-transferFrom}.
	 *
	 * Emits an {Approval} event indicating the updated allowance. This is not
	 * required by the EIP. See the note at the beginning of {ERC20};
	 *
	 * Requirements:
	 * - `sender` and `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 * - the caller must have allowance for ``sender``'s tokens of at least
	 * `amount`.
	 */
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(
			sender,
			_msgSender(),
			_allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
		);
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
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
		_approve(
			_msgSender(),
			spender,
			_allowances[_msgSender()][spender].sub(subtractedValue, 'ERC20: decreased allowance below zero')
		);
		return true;
	}

	/**
	 * @dev Moves tokens `amount` from `sender` to `recipient`.
	 *
	 * This is internal function is equivalent to {transfer}, and can be used to
	 * e.g. implement automatic token fees, slashing mechanisms, etc.
	 *
	 * Emits a {Transfer} event.
	 *
	 * Requirements:
	 *
	 * - `sender` cannot be the zero address.
	 * - `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 */
	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal virtual {
		require(sender != address(0), 'ERC20: transfer from the zero address');
		require(recipient != address(0), 'ERC20: transfer to the zero address');

		_beforeTokenTransfer(sender, recipient, amount);

		_balances[sender] = _balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
	}

	/** @dev Creates `amount` tokens and assigns them to `account`, increasing
	 * the total supply.
	 *
	 * Emits a {Transfer} event with `from` set to the zero address.
	 *
	 * Requirements
	 *
	 * - `to` cannot be the zero address.
	 */
	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), 'ERC20: mint to the zero address');

		_beforeTokenTransfer(address(0), account, amount);

		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	/**
	 * @dev Destroys `amount` tokens from `account`, reducing the
	 * total supply.
	 *
	 * Emits a {Transfer} event with `to` set to the zero address.
	 *
	 * Requirements
	 *
	 * - `account` cannot be the zero address.
	 * - `account` must have at least `amount` tokens.
	 */
	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), 'ERC20: burn from the zero address');

		_beforeTokenTransfer(account, address(0), amount);

		_balances[account] = _balances[account].sub(amount, 'ERC20: burn amount exceeds balance');
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}

	/**
	 * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
	 *
	 * This is internal function is equivalent to `approve`, and can be used to
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
		require(owner != address(0), 'ERC20: approve from the zero address');
		require(spender != address(0), 'ERC20: approve to the zero address');

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	/**
	 * @dev Sets {decimals} to a value other than the default one of 18.
	 *
	 * WARNING: This function should only be called from the constructor. Most
	 * applications that interact with token contracts will not expect
	 * {decimals} to ever change, and may work incorrectly if it does.
	 */
	function _setupDecimals(uint8 decimals_) internal {
		_decimals = decimals_;
	}

	/**
	 * @dev Hook that is called before any transfer of tokens. This includes
	 * minting and burning.
	 *
	 * Calling conditions:
	 *
	 * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
	 * will be to transferred to `to`.
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
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
	/**
	 * @dev Returns the largest of two numbers.
	 */
	function max(uint256 a, uint256 b) internal pure returns (uint256) {
		return a >= b ? a : b;
	}

	/**
	 * @dev Returns the smallest of two numbers.
	 */
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	/**
	 * @dev Returns the average of two numbers. The result is rounded towards
	 * zero.
	 */
	function average(uint256 a, uint256 b) internal pure returns (uint256) {
		// (a + b) / 2 can overflow, so we distribute
		return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
	}
}

// SPDX-License-Identifier: MIT

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the preconditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

pragma experimental ABIEncoderV2;

import { IERC20 } from './IERC20.sol';

struct StrategyParams {
	uint256 performanceFee;
	uint256 activation;
	uint256 debtRatio;
	uint256 minDebtPerHarvest;
	uint256 maxDebtPerHarvest;
	uint256 lastReport;
	uint256 totalDebt;
	uint256 totalGain;
	uint256 totalLoss;
}

interface VaultAPI is IERC20 {
	function name() external view returns (string calldata);

	function symbol() external view returns (string calldata);

	function decimals() external view returns (uint256);

	function apiVersion() external pure returns (string memory);

	function permit(
		address owner,
		address spender,
		uint256 amount,
		uint256 expiry,
		bytes calldata signature
	) external returns (bool);

	// NOTE: Vyper produces multiple signatures for a given function with "default" args
	function deposit() external returns (uint256);

	function deposit(uint256 amount) external returns (uint256);

	function deposit(uint256 amount, address recipient) external returns (uint256);

	// NOTE: Vyper produces multiple signatures for a given function with "default" args
	function withdraw() external returns (uint256);

	function withdraw(uint256 maxShares) external returns (uint256);

	function withdraw(uint256 maxShares, address recipient) external returns (uint256);

	function token() external view returns (address);

	function strategies(address _strategy) external view returns (StrategyParams memory);

	function pricePerShare() external view returns (uint256);

	function totalAssets() external view returns (uint256);

	function depositLimit() external view returns (uint256);

	function maxAvailableShares() external view returns (uint256);

	/**
	 * View how much the Vault would increase this Strategy's borrow limit,
	 * based on its present performance (since its last report). Can be used to
	 * determine expectedReturn in your Strategy.
	 */
	function creditAvailable() external view returns (uint256);

	/**
	 * View how much the Vault would like to pull back from the Strategy,
	 * based on its present performance (since its last report). Can be used to
	 * determine expectedReturn in your Strategy.
	 */
	function debtOutstanding() external view returns (uint256);

	/**
	 * View how much the Vault expect this Strategy to return at the current
	 * block, based on its present performance (since its last report). Can be
	 * used to determine expectedReturn in your Strategy.
	 */
	function expectedReturn() external view returns (uint256);

	/**
	 * This is the main contact point where the Strategy interacts with the
	 * Vault. It is critical that this call is handled as intended by the
	 * Strategy. Therefore, this function will be called by BaseStrategy to
	 * make sure the integration is correct.
	 */
	function report(
		uint256 _gain,
		uint256 _loss,
		uint256 _debtPayment
	) external returns (uint256);

	/**
	 * This function should only be used in the scenario where the Strategy is
	 * being retired but no migration of the positions are possible, or in the
	 * extreme scenario that the Strategy needs to be put into "Emergency Exit"
	 * mode in order for it to exit as quickly as possible. The latter scenario
	 * could be for any reason that is considered "critical" that the Strategy
	 * exits its position as fast as possible, such as a sudden change in
	 * market conditions leading to losses, or an imminent failure in an
	 * external dependency.
	 */
	function revokeStrategy() external;

	/**
	 * View the governance address of the Vault to assert privileged functions
	 * can only be called by governance. The Strategy serves the Vault, so it
	 * is subject to governance defined by the Vault.
	 */
	function governance() external view returns (address);

	/**
	 * View the management address of the Vault to assert privileged functions
	 * can only be called by management. The Strategy serves the Vault, so it
	 * is subject to management defined by the Vault.
	 */
	function management() external view returns (address);

	/**
	 * View the guardian address of the Vault to assert privileged functions
	 * can only be called by guardian. The Strategy serves the Vault, so it
	 * is subject to guardian defined by the Vault.
	 */
	function guardian() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0

interface IAaveOracle {
    function getAssetPrice(address asset) external view returns (uint256);
}

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: AGPL-3.0

interface IPDataProvider {
    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );

    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );
}

// SPDX-License-Identifier: AGPL-3.0
pragma experimental ABIEncoderV2;

interface ILendingPool {
    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
import {IERC20} from './IERC20.sol';

interface IScaledBalanceToken {
    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user) external view returns (uint256);

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return The scaled total supply
     **/
    function scaledTotalSupply() external view returns (uint256);
}

interface IAToken is IERC20, IScaledBalanceToken {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param value The amount being
     * @param index The new liquidity index of the reserve
     **/
    event Mint(address indexed from, uint256 value, uint256 index);

    /**
     * @dev Mints `amount` aTokens to `user`
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @dev Emitted after aTokens are burned
     * @param from The owner of the aTokens, getting them burned
     * @param target The address that will receive the underlying
     * @param value The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param value The amount being transferred
     * @param index The new liquidity index of the reserve
     **/
    event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

    /**
     * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @param user The owner of the aTokens, getting them burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;

    /**
     * @dev Mints aTokens to the reserve treasury
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     */
    function mintToTreasury(uint256 amount, uint256 index) external;

    /**
     * @dev Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
     * @param from The address getting liquidated, current owner of the aTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external;

    /**
     * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
     * assets in borrow(), withdraw() and flashLoan()
     * @param user The recipient of the underlying
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

    /**
     * @dev Invoked to execute actions on the aToken side after a repayment.
     * @param user The user executing the repayment
     * @param amount The amount getting repaid
     **/
    function handleRepayment(address user, uint256 amount) external;

    /**
     * @dev Returns the address of the incentives controller contract
     **/
    // function getIncentivesController() external view returns (IAaveIncentivesController);

    /**
     * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
     **/
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

/**
 * @title IVariableDebtToken
 * @author Aave
 * @notice Defines the basic interface for a variable debt token.
 **/
interface IVariableDebtToken is IERC20, IScaledBalanceToken {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param onBehalfOf The address of the user on which behalf minting has been performed
     * @param value The amount to be minted
     * @param index The last index of the reserve
     **/
    event Mint(address indexed from, address indexed onBehalfOf, uint256 value, uint256 index);

    /**
     * @dev Mints debt token to the `onBehalfOf` address
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt being minted
     * @param index The variable debt index of the reserve
     * @return `true` if the the previous balance of the user is 0
     **/
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @dev Emitted when variable debt is burnt
     * @param user The user which debt has been burned
     * @param amount The amount of debt being burned
     * @param index The index of the user
     **/
    event Burn(address indexed user, uint256 amount, uint256 index);

    /**
     * @dev Burns user variable debt
     * @param user The user which debt is burnt
     * @param index The variable debt index of the reserve
     **/
    function burn(
        address user,
        uint256 amount,
        uint256 index
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IStrategy {
    function balanceOfWant() external view returns (uint256);

    function balanceOfWeth() external view returns (uint256);

    function wantDust() external view returns (uint256);

    function wethDust() external view returns (uint256);

    function wethToWant(uint256 _wethAmount, bool _oracle) external view returns (uint256);

    function wantToWeth(uint256 _wantAmount, bool _oracle) external view returns (uint256);

    function estimatedTotalAssetsSafe() external view returns (uint256);

    function balanceOfWethInWantOracle() external view returns (uint256);

    function balanceOfWethInWant() external view returns (uint256);

    function swapToWeth(uint256 _amountIn) external;

    function getTotalInvestedAssets() external view returns (uint256, uint256);

    function strategyDebt() external view returns (uint256);

    function estimatedTotalAssets() external view returns (uint256);

    function getStrategist() external view returns (address);
}

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