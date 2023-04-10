// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../functions/PerpetualWithdrawFunctions.sol";
import "./../interfaces/IPerpetualWithdrawManager.sol";
import "./../interfaces/IFunctionList.sol";
import "../../interface/ISpotOracle.sol";
import "../../libraries/Utils.sol";

contract PerpetualWithdrawManager is
    PerpetualWithdrawFunctions,
    IFunctionList,
    IPerpetualWithdrawManager
{
    using ABDKMath64x64 for int128;

    /**
     * @dev     Withdraw margin from the trader's account of the perpetual. The trader's cash will decrease.
     *          Trader must be initial margin safe in the perpetual after withdrawing.
     *          To avoid dust position, the minimal resulting cash amount is set to the referall rebate size.
     *          There is no relation between referallRebateSize and a margin deposit,
     *          however referallRebateSize is a small collateral currency amount that can serve
     *          as minimal withdrawal amount.
     *          Deactivate the perpetual for the trader if the account in the perpetual is empty after withdrawing.
     *          Empty means cash and position are zero.
     *
     * @param   _iPerpetualId   The id of the perpetual in the liquidity pool
     * @param   _fAmount        The amount of collateral to withdraw
     */
    function withdraw(
        uint24 _iPerpetualId,
        int128 _fAmount,
        bytes[] calldata _updateData,
        uint64[] calldata _publishTimes
    ) external payable override nonReentrant {
        _getUpdateLogic().updatePriceFeeds{ value: msg.value }(
            _iPerpetualId,
            _updateData,
            _publishTimes,
            0
        );
        _withdraw(_iPerpetualId, _fAmount);
    }

    function _withdraw(uint24 _iPerpetualId, int128 _fAmount)
        internal
        updateFundingAndPrices(_iPerpetualId, perpetualPoolIds[_iPerpetualId])
    {
        address traderAddr = msg.sender;
        PerpetualData storage perpetual = _getPerpetual(_iPerpetualId);
        MarginAccount storage account = marginAccounts[_iPerpetualId][traderAddr];
        int128 fNewCash = account.fCashCC.sub(_fAmount);
        if (account.fPositionBC == 0 && fNewCash < perpetual.fReferralRebateCC) {
            // resulting cash position very small,
            // set withdrawal amount to available cash
            _fAmount = account.fCashCC;
        }
        _validateInputDataWithdraw(perpetual, _fAmount);

        _rebalanceAndWithdraw(perpetual, traderAddr, _fAmount);
    }

    function getFunctionList() external pure virtual override returns (bytes4[] memory, bytes32) {
        bytes32 moduleName = Utils.stringToBytes32("PerpetualWithdrawManager");
        bytes4[] memory functionList = new bytes4[](1);
        functionList[0] = this.withdraw.selector;
        return (functionList, moduleName);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library Utils {
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface ISpotOracle {
    /**
     * @dev The market is closed if the market is not in its regular trading period.
     */
    function isMarketClosed() external view returns (bool);

    function setMarketClosed(bool _marketClosed) external;

    /**
     * @dev The oracle service was shutdown and never online again.
     */
    function isTerminated() external view returns (bool);

    function setTerminated(bool _terminated) external;

    /**
     *  Spot price.
     */
    function getSpotPrice() external view returns (int128, uint256);

    /**
     * Get base currency symbol.
     */
    function getBaseCurrency() external view returns (bytes4);

    /**
     * Get quote currency symbol.
     */
    function getQuoteCurrency() external view returns (bytes4);

    /**
     * Price Id
     */
    function priceId() external view returns (bytes32);

    /**
     * Address of the underlying feed.
     */
    function priceFeed() external view returns (address);

    /**
     * Conservative update period of this feed in seconds.
     */
    function feedPeriod() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPerpetualWithdrawManager {
    function withdraw(
        uint24 _iPerpetualId,
        int128 _fAmount,
        bytes[] calldata _updateData,
        uint64[] calldata _publishTimes
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFunctionList {
    function getFunctionList()
        external
        pure
        returns (bytes4[] memory functionSignatures, bytes32 moduleName);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../interface/ISpotOracle.sol";
import "./PerpetualRebalanceFunctions.sol";

contract PerpetualWithdrawFunctions is PerpetualRebalanceFunctions {
    using ABDKMath64x64 for int128;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /**
     * @dev Transfer funds from a perpetual to a given trader, performing first a rebalance of the pool.
     */
    function _rebalanceAndWithdraw(
        PerpetualData storage _perpetual,
        address _traderAddr,
        int128 _fAmount
    ) internal {
        _getRebalanceLogic().rebalance(_perpetual.id);
        _withdraw(_perpetual, _traderAddr, _fAmount);
        LiquidityPoolData storage liqPool = liquidityPools[_perpetual.poolId];
        address marginTokenAddr = liqPool.marginTokenAddress;
        _transferFromVaultToUser(marginTokenAddr, _traderAddr, _fAmount);
        emit TokensWithdrawn(_perpetual.id, _traderAddr, _fAmount);
    }

    /**
     * @dev Transfer funds fro ma perpetual to a given trader. It does not perform a rebalance,
     * but performs all necessary checks for the transfer to be performed.
     */
    function _withdraw(
        PerpetualData storage _perpetual,
        address _traderAddr,
        int128 _fAmount
    ) internal {
        uint24 perpId = _perpetual.id;
        _updateTraderMargin(_perpetual, _traderAddr, _fAmount.neg());
        require(
            _getMarginViewLogic().isInitialMarginSafe(perpId, _traderAddr),
            "margin is unsafe after withdrawal"
        );
        bool isEmptyAccount = _isEmptyAccount(_perpetual, _traderAddr);
        if (isEmptyAccount && _traderAddr != address(this)) {
            activeAccounts[perpId].remove(_traderAddr);
        }
    }

    /**
     * @dev Ensures a given perpetual is in a state that allows fund withdrawals.
     */
    function _validateInputDataWithdraw(PerpetualData storage _perpetual, int128 _fAmount)
        internal
        view
    {
        require(
            _perpetual.state == PerpetualState.NORMAL ||
                _perpetual.state == PerpetualState.CLEARED,
            "should be in NORMAL/CLEARED state"
        );
        require(_fAmount > 0, "invalid amount");
        //it will fail if account.fCashCC >= _fAmount with error: if margin is unsafe after withdrawal
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./PerpetualBaseFunctions.sol";
import "../interfaces/IPerpetualTradeLogic.sol";
import "../interfaces/IPerpetualGetter.sol";
import "../interfaces/IPerpetualMarginLogic.sol";
import "../interfaces/IPerpetualMarginViewLogic.sol";

contract PerpetualRebalanceFunctions is PerpetualBaseFunctions {
    using ABDKMath64x64 for int128;
    // using ConverterDec18 for int128;
    int128 internal constant NINETY_FIVE_PERCENT = 0xf333333333333333;
    uint16 internal constant FUND_TRANSFER_CONVERGENCE_HOURS = 24; // reference time delta for DF -> AMM transfers; each pool defines its own fMaxTransferPerConvergencePeriod parameter

    /**
     * @dev     Modifier can be called with a 0 perpId.
     *
     * @param   _iPerpetualId   perpetual id
     * @param   _iPoolIdx       pool index of that perpetual
     */
    modifier updateFundingAndPrices(uint24 _iPerpetualId, uint8 _iPoolIdx) {
        // choose 'random' second perpetual in pool
        uint24 otherPerpId;
        (_iPerpetualId, otherPerpId) = _selectPerpetualIds(_iPerpetualId, _iPoolIdx);
        _getUpdateLogic().updateFundingAndPricesBefore(_iPerpetualId, otherPerpId);
        _;
        _getUpdateLogic().updateFundingAndPricesAfter(_iPerpetualId, otherPerpId);
    }

    /**
     * @dev     To re-balance the AMM margin to the initial margin.
     *          Transfer margin between the perpetual and the various cash pools, then
     *          update the AMM's cash in perpetual margin account.
     *
     * @param   _perpetual The perpetual in the liquidity pool
     */
    function _rebalance(PerpetualData storage _perpetual) internal {
        if (_perpetual.state != PerpetualState.NORMAL) {
            return;
        }
        _equalizeAMMMargin(_perpetual);
        _rebalanceToTarget(_perpetual);
        // updating the mark price changes the markprice that is
        // used for margin calculation and hence the AMM initial
        // margin will not be exactly at initial margin rate
        _updateMarkPrice(_perpetual);

        // update trade size that minimizes AMM risk
        _updateKStar(_perpetual);
    }

    /**
     * @dev     To re-balance the AMM pool to the target size.
     *          This aims that the AMM pool size is funded enough so prices and slippage are reasonable.
     *          Transfers collateral perpetual and the various cash pools.
     *
     * @param   _perpetual The perpetual in the liquidity pool
     */
    function _rebalanceToTarget(PerpetualData storage _perpetual) internal {
        int128 fBaselineTarget = _getUpdatedTargetAMMFundSize(
            _perpetual,
            _perpetual.eCollateralCurrency,
            true
        );
        // cases: stress target S, baseline target B (B>S), current AMM fund cash C
        // 1)  S...B...C
        // 2)  S...C...B
        // 3)  C...S...B
        LiquidityPoolData storage pool = liquidityPools[_perpetual.poolId];
        // if we are above baseline target, we update the stored target and make sure the target is baseline
        // 1) S...B...C: set baseline target
        // set target in liquidity pool and AMM data:
        bool isBaselineTarget = (_perpetual.fAMMFundCashCC > fBaselineTarget);
        int128 fStressTarget = isBaselineTarget
            ? int128(0)
            : _getUpdatedTargetAMMFundSize(_perpetual, _perpetual.eCollateralCurrency, false);
        // if !isBaselineTarget, we are below baseline target, two options (2) and (3)
        // 2) S...C...B
        //    set target in liquidity pool and AMM data:
        isBaselineTarget = isBaselineTarget || _perpetual.fAMMFundCashCC > fStressTarget;

        if (isBaselineTarget) {
            if (pool.fDefaultFundCashCC < pool.fTargetDFSize) {
                fStressTarget = _getUpdatedTargetAMMFundSize(
                    _perpetual,
                    _perpetual.eCollateralCurrency,
                    false
                );
                fBaselineTarget = fStressTarget.add(
                    pool.fDefaultFundCashCC.mul(fBaselineTarget.sub(fStressTarget)).div(
                        pool.fTargetDFSize
                    )
                );
            }
            _getUpdateLogic().updateAMMTargetFundSize(_perpetual.id, fBaselineTarget);
            _perpetual.iLastDefaultFundTransfer = 0;
            return;
        }
        if (_perpetual.iLastDefaultFundTransfer == uint64(0)) {
            // we are about to transfer fund into the AMM pool - reset counter
            _perpetual.iLastDefaultFundTransfer = uint64(block.timestamp);
        }
        // 3) C...S...B: set stress target
        _getUpdateLogic().updateAMMTargetFundSize(_perpetual.id, fStressTarget);

        // we use the default and pnl participation funds to fill up to 75% of the gap
        // draw funds in relation to available size from default fund
        // If default fund is funded we withdraw at most 75%
        int128 fGap = fStressTarget.sub(_perpetual.fAMMFundCashCC).mul(CEIL_AMT_FUND_WITHDRAWAL);
        int128 fMaxTransfer = pool.fDefaultFundCashCC.mul(CEIL_AMT_FUND_WITHDRAWAL);
        int128 fGapFillDF = (fGap > fMaxTransfer) ? fMaxTransfer : fGap;

        // adjust amount transferred from DF according to time elapsed
        if (uint64(block.timestamp) <= _perpetual.iLastDefaultFundTransfer) {
            // already transferred this block
            fGapFillDF = 0;
            fGap = 0;
        } else {
            // if we are here the transfer amount will be positive (gap > 0 and time scaling > 0)
            // first get the scaling factor according to time elapsed
            fMaxTransfer = ABDKMath64x64
                .fromUInt(block.timestamp - uint256(_perpetual.iLastDefaultFundTransfer))
                .div(ABDKMath64x64.fromUInt(uint256(FUND_TRANSFER_CONVERGENCE_HOURS) * 3600));
            // scale can't be more than 100%
            fMaxTransfer = fMaxTransfer > ONE_64x64 ? ONE_64x64 : fMaxTransfer;
            // apply scale to absolute max to get the actual max transfer amount
            fMaxTransfer = fMaxTransfer.mul(pool.fMaxTransferPerConvergencePeriod);
            // down-scale if underfunded pool
            if (pool.fDefaultFundCashCC < pool.fTargetDFSize) {
                fMaxTransfer = fMaxTransfer.mul(pool.fDefaultFundCashCC.div(pool.fTargetDFSize));
            }
            // cap to smaller between target size (total size, not gap) and max total transfer in period
            fMaxTransfer = fStressTarget > fMaxTransfer ? fMaxTransfer : fStressTarget;
            // we record the ratio between actual and requested funds
            int128 fRatio = ONE_64x64;
            if (fGapFillDF > fMaxTransfer) {
                // requested fGapFill but only got fMaxTransfer - we record this to apply to PnL fund contribution
                fRatio = fMaxTransfer.div(fGapFillDF);
                fGapFillDF = fMaxTransfer;
            }
            // transfer this amount
            _decreaseDefaultFundCash(pool, fGapFillDF);
            // decrease gap and scale down
            fGap = fGap.sub(fGapFillDF).mul(fRatio);
        }
        // draw funds from pnl participants who don't otherwise contribute to the default fund
        int128 maxPnlPart = pool.fPnLparticipantsCashCC.mul(CEIL_AMT_FUND_WITHDRAWAL);
        int128 fGapFillPnlPart = (fGap > maxPnlPart) ? maxPnlPart : fGap;
        if (fGapFillPnlPart > 0) {
            _decreasePoolCash(pool, fGapFillPnlPart);
        }
        // contribution to AMM pool is recorded in perpetual and the aggregated amount in the liq-pool
        int128 fAmountFromPools = fGapFillPnlPart.add(fGapFillDF);
        pool.fAMMFundCashCC = pool.fAMMFundCashCC.add(fAmountFromPools);
        _perpetual.fAMMFundCashCC = _perpetual.fAMMFundCashCC.add(fAmountFromPools);
        emit UpdateAMMFundCash(_perpetual.id, _perpetual.fAMMFundCashCC, pool.fAMMFundCashCC);
    }

    /**
     * @dev Brings the AMM margin acount back to its initial margin by
     * transferring funds to or from the AMM and PnL participation pools
     */
    function _equalizeAMMMargin(PerpetualData storage _perpetual) internal {
        int128 fMarginBalance;
        int128 fInitialBalance;
        (fMarginBalance, fInitialBalance) = _getRebalanceMargin(_perpetual);
        if (fMarginBalance > fInitialBalance) {
            // from margin to pool
            _transferFromAMMMarginToPool(_perpetual, fMarginBalance.sub(fInitialBalance));
        } else {
            // from pool to margin
            // It's possible that there are not enough funds to draw from
            // in this case not the full margin will be replenished
            // (and emergency state is raised)
            _transferFromPoolToAMMMargin(
                _perpetual,
                fInitialBalance.sub(fMarginBalance),
                fMarginBalance
            );
        }
    }

    /**
     * @dev Update k*, the trade that would minimize the AMM risk.
     * Set 0 in quanto case.
     * @param _perpetual  The reference of perpetual storage.
     */
    function _updateKStar(PerpetualData storage _perpetual) internal {
        AMMPerpLogic.CollateralCurrency ccy = _perpetual.eCollateralCurrency;
        MarginAccount storage AMMMarginAcc = marginAccounts[_perpetual.id][address(this)];
        int128 K2 = AMMMarginAcc.fPositionBC.neg();
        if (ccy == AMMPerpLogic.CollateralCurrency.BASE) {
            // M2 = perpetual.fAMMFundCashCC
            _perpetual.fkStar = _perpetual.fAMMFundCashCC.sub(K2);
        } else if (ccy == AMMPerpLogic.CollateralCurrency.QUOTE) {
            _perpetual.fkStar = K2.neg();
        } else {
            // M3 = perpetual.fAMMFundCashCC
            int128 s2 = _getSafeOraclePriceS2(_perpetual);
            int128 s3 = _getSafeOraclePriceS3(_perpetual);
            int128 nominator = (int128(_perpetual.fRho23) << 35)
                .mul(int128(_perpetual.fSigma2) << 35)
                .mul(int128(_perpetual.fSigma3) << 35)
                .exp()
                .sub(ONE_64x64);
            int128 denom = (int128(_perpetual.fSigma2) << 35)
                .mul(int128(_perpetual.fSigma2) << 35)
                .exp()
                .sub(ONE_64x64);
            _perpetual.fkStar = s3
                .div(s2)
                .mul(nominator.div(denom))
                .mul(_perpetual.fAMMFundCashCC)
                .sub(K2);
        }
    }

    /**
     * @dev Get the margin to rebalance the AMM in the perpetual.
     * Margin to rebalance = margin - initial margin
     * @param   _perpetual The perpetual in the liquidity pool
     * @return  The margin to rebalance in the perpetual
     */
    function _getRebalanceMargin(PerpetualData storage _perpetual)
        internal
        view
        returns (int128, int128)
    {
        int128 fInitialMargin = _getMarginViewLogic().getInitialMargin(
            _perpetual.id,
            address(this)
        );
        int128 fMarginBalance = _getMarginViewLogic().getMarginBalance(
            _perpetual.id,
            address(this)
        );
        return (fMarginBalance, fInitialMargin);
    }

    /**
     * @dev Transfer a given amount from the AMM margin account to the
     * liq pools (AMM pool, participation fund).
     * @param   _perpetual   The reference of perpetual storage.
     * @param   _fAmount            signed 64.64-bit fixed point number.
     */
    function _transferFromAMMMarginToPool(PerpetualData storage _perpetual, int128 _fAmount)
        internal
    {
        if (_fAmount == 0) {
            return;
        }
        require(_fAmount > 0, "transferFromAMMMgnToPool >0");
        LiquidityPoolData storage pool = liquidityPools[_perpetual.poolId];
        // update margin of AMM
        _updateTraderMargin(_perpetual, address(this), _fAmount.neg());

        int128 fPnLparticipantAmount;
        int128 fAmmAmount;
        // split amount ensures only available amount of participation pool is counted
        (fPnLparticipantAmount, fAmmAmount) = _splitAmount(pool, _fAmount, false);
        _increasePoolCash(pool, fPnLparticipantAmount);
        // increase AMM fund cash, and if AMM fund full then send to default fund
        _increaseAMMFundCashForPerpetual(_perpetual, fAmmAmount);
    }

    /**
     * @dev Transfer a given amount from the liquidity pools (AMM+PnLparticipant) into the AMM margin account.
     * Margin to rebalance = margin - initial margin
     * @param   _perpetual   The reference of perpetual storage.
     * @param   _fAmount     Amount to transfer. Signed 64.64-bit fixed point number.
     * @return  The amount that could be drawn from the pools.
     */
    function _transferFromPoolToAMMMargin(
        PerpetualData storage _perpetual,
        int128 _fAmount,
        int128 _fMarginBalance
    ) internal returns (int128) {
        // transfer from pool to AMM: amount >= 0
        if (_fAmount == 0) {
            return 0;
        }
        require(_fAmount > 0, "transferFromPoolToAMM>0");

        // perpetual state cannot be normal with 0 cash
        LiquidityPoolData storage pool = liquidityPools[_perpetual.poolId];
        require(
            _perpetual.fAMMFundCashCC > 0 ||
                pool.fPnLparticipantsCashCC > 0 ||
                _perpetual.state != PerpetualState.NORMAL,
            "state abnormal: 0 AMM Cash"
        );

        // perp funds =  {this perp's AMM fund + available PnL part fund}
        int128 fPnLParticipantCash = _getCollateralTokenAmountForPricing(pool);
        fPnLParticipantCash = fPnLParticipantCash.mul(
            _perpetual.fFundAllocationWeightCC.div(pool.fFundAllocationNormalizationCC)
        );

        int128 fMaxAmount = _perpetual.fAMMFundCashCC.add(fPnLParticipantCash);

        if (_fMarginBalance.add(fMaxAmount) < 0) {
            // the perp is insolvent, set emergency state, all funds need to be transferred
            _getUpdateLogic().setEmergencyState(_perpetual.id);
        } else {
            // set max amount to transfer to this perp's margin to 95% (0xf333333333333333) of its funds
            // The consequence is that we don't default if the Default Fund is still well stocked.
            fMaxAmount = fMaxAmount.mul(NINETY_FIVE_PERCENT);
        }

        int128 fAmountFromDefFund;

        if (_fAmount > fMaxAmount) {
            // draw from default fund
            fAmountFromDefFund = _fAmount.sub(fMaxAmount);
            // amount to withdraw from pools
            _fAmount = fMaxAmount;
            if (fAmountFromDefFund > pool.fDefaultFundCashCC) {
                // not enough cash in default fund
                // margin cannot be replenished fully
                fAmountFromDefFund = pool.fDefaultFundCashCC;
                // emergency state for the whole liquidity pool
                _setLiqPoolEmergencyState(pool);
            }
            _decreaseDefaultFundCash(pool, fAmountFromDefFund);
        }

        int128 fAmmAmount;
        // split amount ensures only available amount of participation pool is counted
        // takes care if not enough funds in one of the pots, total must be<=sum of funds
        (fPnLParticipantCash, fAmmAmount) = _splitAmount(pool, _fAmount, true);

        _decreaseAMMFundCashForPerpetual(_perpetual, fAmmAmount);

        _decreasePoolCash(pool, fPnLParticipantCash);

        // update margin
        int128 fFeasibleMargin = _fAmount.add(fAmountFromDefFund);
        _updateTraderMargin(_perpetual, address(this), fFeasibleMargin);
        return fFeasibleMargin;
    }

    /**
     * @dev Split amount in relation to pool sizes.
     * If withdrawing and ratio cannot be met, funds are withdrawn from the other pool.
     * Precondition: (_fAmount<available PnLparticipantCash+ammcash)|| !_isWithdrawn
     * @param   _liquidityPool    reference to liquidity pool
     * @param   _fAmount          Signed 64.64-bit fixed point number. The amount to be split
     * @param   _isWithdrawn      If true, the function re-distributes the amounts so that the pool
     *                            funds remain non-negative.
     * @return  Signed 64.64-bit fixed point number x 2. Amounts for PnL participants and AMM
     */
    function _splitAmount(
        LiquidityPoolData storage _liquidityPool,
        int128 _fAmount,
        bool _isWithdrawn
    ) internal view returns (int128, int128) {
        if (_fAmount == 0) {
            return (0, 0);
        }
        int128 fPnLCash = _getCollateralTokenAmountForPricing(_liquidityPool);
        int128 fAvailCash = fPnLCash.add(_liquidityPool.fAMMFundCashCC);
        require(_fAmount > 0, ">0 amount expected");
        require(!_isWithdrawn || fAvailCash >= _fAmount, "pre-cond not met");
        int128 fWeightPnLparticipants = fPnLCash.div(
            fAvailCash.add(_liquidityPool.fDefaultFundCashCC)
        );
        // ceiling for PnL participant share of PnL
        if (fWeightPnLparticipants > CEIL_PNL_SHARE) {
            fWeightPnLparticipants = CEIL_PNL_SHARE;
        }
        int128 fAmountPnLparticipants = fWeightPnLparticipants.mul(_fAmount);
        int128 fAmountAMM = _fAmount.sub(fAmountPnLparticipants);

        // ensure we have have non-negative funds when withdrawing
        // re-distribute otherwise
        if (_isWithdrawn) {
            // pre-condition: _fAmount<available PnLparticipantCash+ammcash
            // because of CEIL_PNL_SHARE we might allocate too much too AMM funds
            // fix this here
            int128 fSpillover = _liquidityPool.fAMMFundCashCC.sub(fAmountAMM);
            if (fSpillover < 0) {
                fSpillover = fSpillover.neg();
                fAmountAMM = fAmountAMM.sub(fSpillover);
                fAmountPnLparticipants = fAmountPnLparticipants.add(fSpillover);
            }
        }

        return (fAmountPnLparticipants, fAmountAMM);
    }

    /**
     * @dev Increase the participation fund's cash(collateral).
     * @param   _liquidityPool reference to liquidity pool data
     * @param   _fAmount     Signed 64.64-bit fixed point number. The amount of cash(collateral) to increase.
     */
    function _increasePoolCash(LiquidityPoolData storage _liquidityPool, int128 _fAmount)
        internal
    {
        require(_fAmount >= 0, "inc neg pool cash");
        _liquidityPool.fPnLparticipantsCashCC = _liquidityPool.fPnLparticipantsCashCC.add(
            _fAmount
        );

        emit UpdateParticipationFundCash(
            _liquidityPool.id,
            _fAmount,
            _liquidityPool.fPnLparticipantsCashCC
        );
    }

    /**
     * Decrease the participation fund pool's cash(collateral).
     * @param   _pool reference to liquidity pool data
     * @param   _fAmount     Signed 64.64-bit fixed point number. The amount of cash(collateral) to decrease.
     *                       Will not decrease to negative
     */
    function _decreasePoolCash(LiquidityPoolData storage _pool, int128 _fAmount) internal {
        require(_fAmount >= 0, "dec neg pool cash");
        _pool.fPnLparticipantsCashCC = _pool.fPnLparticipantsCashCC.sub(_fAmount);
        emit UpdateParticipationFundCash(_pool.id, _fAmount.neg(), _pool.fPnLparticipantsCashCC);
    }

    /**
     * @dev Increase the AMM's cash(collateral).
     * The perpetuals cash and the total liquidity pool AMM cash needs to be updated
     * @param   _perpetual   PerpetualData struct
     * @param   _fAmount     Signed 64.64-bit fixed point number. The amount of cash(collateral) to decrease.
     *                       Will not decrease total AMM liq pool to negative
     */
    function _increaseAMMFundCashForPerpetual(PerpetualData storage _perpetual, int128 _fAmount)
        internal
    {
        require(_fAmount >= 0, "inc neg pool cash");
        LiquidityPoolData storage liqPool = liquidityPools[_perpetual.poolId];
        require(liqPool.fTargetAMMFundSize > 0, "AMM target! gt 0");
        require(liqPool.fTargetDFSize > 0, "DF target ! gt 0");

        int128 ammContribution = _perpetual.fTargetAMMFundSize.sub(_perpetual.fAMMFundCashCC);

        if (ammContribution > _fAmount) {
            // AMM gap is larger than cash being distributed -> AMM pool receives all the cash
            ammContribution = _fAmount;
        } else if (ammContribution < 0) {
            // AMM is full, all cash goes to the default fund
            ammContribution = int128(0);
        }
        // otherwise AMM receives enough to fill the gap, and the rest goes to the default fund
        _fAmount = _fAmount.sub(ammContribution);
        // increase pool cash
        _perpetual.fAMMFundCashCC = _perpetual.fAMMFundCashCC.add(ammContribution);
        liqPool.fAMMFundCashCC = liqPool.fAMMFundCashCC.add(ammContribution);
        require(liqPool.fAMMFundCashCC > 0, "AMM Cash st 0");
        emit UpdateAMMFundCash(_perpetual.id, _perpetual.fAMMFundCashCC, liqPool.fAMMFundCashCC);

        // send remaining funds to default fund
        if (_fAmount > 0) {
            liqPool.fDefaultFundCashCC = liqPool.fDefaultFundCashCC.add(_fAmount);
            emit UpdateDefaultFundCash(liqPool.id, _fAmount, liqPool.fDefaultFundCashCC);
        }
    }

    /**
     * @dev Decrease the AMM's fund cash (not the margin).
     * The perpetuals cash and the total liquidity pool cash needs to be updated
     * @param   _perpetual  PerpetualData struct
     * @param   _fAmount     Signed 64.64-bit fixed point number. The amount of cash(collateral) to increase.
     */
    function _decreaseAMMFundCashForPerpetual(PerpetualData storage _perpetual, int128 _fAmount)
        internal
    {
        require(_fAmount >= 0, "dec neg pool cash");

        // adjust total pool amount
        liquidityPools[_perpetual.poolId].fAMMFundCashCC = (
            liquidityPools[_perpetual.poolId].fAMMFundCashCC
        ).sub(_fAmount);
        // adjust perpetual's individual pool
        _perpetual.fAMMFundCashCC = _perpetual.fAMMFundCashCC.sub(_fAmount);
        emit UpdateAMMFundCash(
            _perpetual.id,
            _perpetual.fAMMFundCashCC.neg(),
            liquidityPools[_perpetual.poolId].fAMMFundCashCC
        );
    }

    /**
     * @dev     Decrease default fund cash
     * @param   _liquidityPool reference to liquidity pool data
     * @param   _fAmount     Signed 64.64-bit fixed point number. The amount of cash(collateral) to decrease.
     */
    function _decreaseDefaultFundCash(LiquidityPoolData storage _liquidityPool, int128 _fAmount)
        internal
    {
        require(_fAmount >= 0, "dec neg pool cash");
        _liquidityPool.fDefaultFundCashCC = _liquidityPool.fDefaultFundCashCC.sub(_fAmount);
        require(_liquidityPool.fDefaultFundCashCC >= 0, "DF cash cannot be <0");
        emit UpdateDefaultFundCash(
            _liquidityPool.id,
            _fAmount.neg(),
            _liquidityPool.fDefaultFundCashCC
        );
    }

    /**
     * @dev Loop through perpetuals of the liquidity pool and set
     * to emergency state
     * @param _liqPool reference to liquidity pool
     */
    function _setLiqPoolEmergencyState(LiquidityPoolData storage _liqPool) internal {
        uint256 length = _liqPool.iPerpetualCount;
        for (uint256 i = 0; i < length; i++) {
            uint24 idx = perpetualIds[_liqPool.id][i];
            PerpetualData storage perpetual = perpetuals[_liqPool.id][idx];
            if (perpetual.state != PerpetualState.NORMAL) {
                continue;
            }
            _getUpdateLogic().setEmergencyState(perpetual.id);
        }
    }

    /**
     * @dev     Check if the trader has opened position in the trade.
     *          Example: 2, 1 => true; 2, -1 => false; -2, -3 => true
     * @param   _fNewPos    The position of the trader after the trade
     * @param   fDeltaPos   The size of the trade
     * @return  True if the trader has opened position in the trade
     */
    function _hasOpenedPosition(int128 _fNewPos, int128 fDeltaPos) internal pure returns (bool) {
        if (_fNewPos == 0) {
            return false;
        }
        return _hasTheSameSign(_fNewPos, fDeltaPos);
    }

    /**
     * @dev Check if Trader is maintenance margin safe in the perpetual,
     * need to rebalance before checking.
     * @param   _perpetual   Reference to the perpetual
     * @param   _traderAddr  The address of the trader
     * @param   _hasOpened   True if the trader opens, false if they close
     * @return  True if Trader is maintenance margin safe in the perpetual.
     */
    function _isTraderMarginSafe(
        PerpetualData storage _perpetual,
        address _traderAddr,
        bool _hasOpened
    ) internal view returns (bool) {
        return
            _hasOpened
                ? _getMarginViewLogic().isInitialMarginSafe(_perpetual.id, _traderAddr)
                : _getMarginViewLogic().isMarginSafe(_perpetual.id, _traderAddr);
    }

    /**
     * @dev Update mark premium
     * Computes and sets the mark premium given the current AMM and market state
     * @param _perpetual Perpetual storage reference
     */
    function _updateMarkPrice(PerpetualData storage _perpetual) internal {
        int128 fCurrentPremiumRate = _calcInsurancePremium(_perpetual);
        _updatePremiumMarkPrice(_perpetual, fCurrentPremiumRate);
        _perpetual.premiumRatesEMA = int72(
            _ema(
                _perpetual.premiumRatesEMA,
                fCurrentPremiumRate,
                int128(_perpetual.fMarkPriceEMALambda) << 35
            )
        );
    }

    /**
     * Update the EMA of insurance premium used for the mark price
     * @param   _perpetual   The reference of perpetual storage.
     */
    function _updatePremiumMarkPrice(PerpetualData storage _perpetual, int128 _fCurrentPremiumRate)
        internal
    {
        uint64 iCurrentTimeSec = uint64(block.timestamp);
        if (
            _perpetual.currentMarkPremiumRate.time != iCurrentTimeSec &&
            _perpetual.state == PerpetualState.NORMAL
        ) {
            // no update of mark-premium rate if we are in emergency state (we want the mark-premium to be frozen)
            // update mark-price if we are in a new block
            // now set the mark price to the last block EMA
            _perpetual.currentMarkPremiumRate.time = iCurrentTimeSec;
            // assign last EMA of previous block
            _perpetual.currentMarkPremiumRate.fPrice = _perpetual.premiumRatesEMA;
            emit UpdateMarkPrice(
                _perpetual.id,
                _fCurrentPremiumRate,
                _perpetual.currentMarkPremiumRate.fPrice,
                _getSafeOraclePriceS2(_perpetual)
            );
        }
    }

    /*
     * Update the mid-price for the insurance premium. This is used for EMA of perpetual prices
     * (mark-price used in funding payments and rebalance)
     * @param   _perpetual   The reference of perpetual storage.
     * @return current premium rate (=signed relative diff to index price)
     */
    function _calcInsurancePremium(PerpetualData storage _perpetual)
        internal
        view
        returns (int128)
    {
        // prepare data
        AMMPerpLogic.AMMVariables memory ammState;
        AMMPerpLogic.MarketVariables memory marketState;

        (ammState, marketState) = _prepareAMMAndMarketData(_perpetual, true);

        // mid price has no minimal spread
        // mid-price parameter obtained using amount k=0
        int128 px_premium = _getAMMPerpLogic().calculatePerpetualPrice(
            ammState,
            marketState,
            0,
            0,
            0
        );
        px_premium = px_premium.sub(marketState.fIndexPriceS2).div(marketState.fIndexPriceS2);
        return px_premium;
    }

    /**
     * Recalculate the target size for the AMM liquidity pool for the given perpetual using
     * the current 'LockedInValue' and 'AMMExposure' (=K in whitepaper)
     * The AMM target fund size will not go below _perpetual.fAMMMinSizeCC
     *
     * @param   _perpetual      Reference to perpetual
     * @param   _ccy            Currency of collateral enum {QUOTE, BASE, QUANTO}
     * @param   _isBaseline     calculate fund size based on baseline or stress target?
     * @return  Target size in required currency (64.64 fixed point number)
     */
    function _getUpdatedTargetAMMFundSize(
        PerpetualData storage _perpetual,
        AMMPerpLogic.CollateralCurrency _ccy,
        bool _isBaseline
    ) internal view returns (int128) {
        // loop through perpetuals of this pool and update the
        // pool size
        AMMPerpLogic.MarketVariables memory mv;
        mv.fIndexPriceS2 = _getSafeOraclePriceS2(_perpetual);
        mv.fSigma2 = int128(_perpetual.fSigma2) << 35;
        int128 fMStar;
        int128 fK = marginAccounts[_perpetual.id][address(this)].fPositionBC.neg();
        int128 fLockedIn = marginAccounts[_perpetual.id][address(this)].fLockedInValueQC.neg();
        // adjust current K and L for EMA trade size:
        // kStarSide = kStar > 0 ? 1 : -1;
        if (_perpetual.fkStar < 0) {
            fK = fK.add(_perpetual.fCurrentTraderExposureEMA);
            fLockedIn = fLockedIn.add(_perpetual.fCurrentTraderExposureEMA.mul(mv.fIndexPriceS2));
        } else {
            fK = fK.sub(_perpetual.fCurrentTraderExposureEMA);
            fLockedIn = fLockedIn.sub(_perpetual.fCurrentTraderExposureEMA.mul(mv.fIndexPriceS2));
        }

        uint256 index = _isBaseline ? 0 : 1;
        if (_ccy == AMMPerpLogic.CollateralCurrency.BASE) {
            // get target collateral for current AMM exposure
            if (fK == 0 || fLockedIn == 0) {
                fMStar = _perpetual.fAMMMinSizeCC;
            } else {
                fMStar = _getAMMPerpLogic().getTargetCollateralM2(
                    fK,
                    fLockedIn,
                    mv,
                    _perpetual.fAMMTargetDD[index]
                );
            }
        } else if (_ccy == AMMPerpLogic.CollateralCurrency.QUANTO) {
            if (fK == 0) {
                fMStar = _perpetual.fAMMMinSizeCC;
            } else {
                // additional parameters
                mv.fSigma3 = int128(_perpetual.fSigma3) << 35;
                mv.fRho23 = int128(_perpetual.fRho23) << 35;
                mv.fIndexPriceS3 = _getSafeOraclePriceS3(_perpetual);
                // get target collateral for current AMM exposure
                fMStar = _getAMMPerpLogic().getTargetCollateralM3(
                    fK,
                    fLockedIn,
                    mv,
                    _perpetual.fAMMTargetDD[index]
                );
            }
        } else {
            assert(_ccy == AMMPerpLogic.CollateralCurrency.QUOTE);
            if (fK == 0) {
                fMStar = _perpetual.fAMMMinSizeCC;
            } else {
                // get target collateral for conservative negative AMM exposure
                fMStar = _getAMMPerpLogic().getTargetCollateralM1(
                    fK,
                    fLockedIn,
                    mv,
                    _perpetual.fAMMTargetDD[index]
                );
            }
        }
        if (fMStar < _perpetual.fAMMMinSizeCC) {
            fMStar = _perpetual.fAMMMinSizeCC;
        }
        // account for cash outside the AMM fund: M = AMM pool + AMM margin + LPs
        int128 fBaseLevel = marginAccounts[_perpetual.id][address(this)].fCashCC;
        {
            LiquidityPoolData storage pool = liquidityPools[_perpetual.poolId];
            if (pool.fPnLparticipantsCashCC > 0) {
                fBaseLevel = fBaseLevel.add(_getCollateralTokenAmountForPricing(pool));
            }
        }
        // AMM pool + Base level >= M* and AMM >= 5% M*
        fMStar = fMStar.mul(NINETY_FIVE_PERCENT) > fBaseLevel
            ? fMStar.sub(fBaseLevel)
            : fMStar.mul(ONE_64x64.sub(NINETY_FIVE_PERCENT));

        return fMStar;
    }

    function _getMarginLogic() internal view returns (IPerpetualMarginLogic) {
        return IPerpetualMarginLogic(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "../interfaces/IPerpetualOrder.sol";

interface IPerpetualTradeLogic {
    function executeTrade(
        uint24 _iPerpetualId,
        address _traderAddr,
        int128 _fTraderPos,
        int128 _fTradeAmount,
        int128 _fPrice,
        bool _isClose
    ) external returns (int128);

    function preTrade(uint24 _iPerpetualId, IPerpetualOrder.Order memory _order)
        external
        returns (int128, int128);

    function distributeFeesLiquidation(
        uint24 _iPerpetualId,
        address _traderAddr,
        int128 _fDeltaPositionBC
    ) external returns (int128);

    function distributeFees(IPerpetualOrder.Order memory _order, bool _hasOpened)
        external
        returns (int128);

    function validateStopPrice(
        bool _isLong,
        int128 _fMarkPrice,
        int128 _fTriggerPrice
    ) external pure;

    function getMaxSignedOpenTradeSizeForPos(
        uint24 _perpetualId,
        int128 _fCurrentTraderPos,
        bool _isBuy
    ) external view returns (int128);

    function queryPerpetualPrice(
        uint24 _iPerpetualId,
        int128 _fTradeAmountBC,
        int128[2] calldata _fIndexPrice
    ) external view returns (int128);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../core/PerpStorage.sol";
import "../interfaces/ILibraryEvents.sol";
import "../../libraries/ConverterDec18.sol";
import "../../libraries/EnumerableSetUpgradeable.sol";
import "../interfaces/IPerpetualRebalanceLogic.sol";
import "../interfaces/IPerpetualBrokerFeeLogic.sol";
import "../interfaces/IPerpetualUpdateLogic.sol";
import "../interfaces/IPerpetualMarginViewLogic.sol";
import "../interfaces/IPerpetualTradeLogic.sol";
import "../interfaces/IPerpetualTreasury.sol";
import "../interfaces/IPerpetualGetter.sol";
import "../../oracle/OracleFactory.sol";

contract PerpetualBaseFunctions is PerpStorage, ILibraryEvents {
    using ABDKMath64x64 for int128;
    using ConverterDec18 for int128;
    using ConverterDec18 for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    uint64 internal constant WITHDRAWAL_DELAY_TIME_SEC = 2 * 86400; // 2 days

    /**
     * @dev Get LiquidityPool storage reference corresponding to a given perpetual id
     * @param _iPerpetualId Perpetual id, unique across liquidity pools
     * @return LiquidityPoolData
     */
    function _getLiquidityPoolFromPerpetual(uint24 _iPerpetualId)
        internal
        view
        returns (LiquidityPoolData storage)
    {
        uint8 poolId = perpetualPoolIds[_iPerpetualId];
        return liquidityPools[poolId];
    }

    /**
     * @dev Get id of the LiquidityPool corresponding to a given perpetual id
     * @param _iPerpetualId Perpetual id, unique across liquidity pools
     * @return Liquidity Pool id
     */
    function _getPoolIdFromPerpetual(uint24 _iPerpetualId) internal view returns (uint8) {
        return perpetualPoolIds[_iPerpetualId];
    }

    /**
     * @dev Get perpetual reference from its 'globally' unique id
     * @param _iPerpetualId Perpetual id, unique across liquidity pools
     * @return PerpetualData
     */
    function _getPerpetual(uint24 _iPerpetualId) internal view returns (PerpetualData storage) {
        uint8 poolId = perpetualPoolIds[_iPerpetualId];
        require(poolId > 0, "perp not found");

        return perpetuals[poolId][_iPerpetualId];
    }

    /**
     * @dev Check if the account of the trader is empty in the perpetual, which means fCashCC = 0 and fPositionBC = 0
     * @param _perpetual The perpetual object
     * @param _traderAddr The address of the trader
     * @return True if the account of the trader is empty in the perpetual
     */
    function _isEmptyAccount(PerpetualData storage _perpetual, address _traderAddr)
        internal
        view
        returns (bool)
    {
        MarginAccount storage account = marginAccounts[_perpetual.id][_traderAddr];
        return account.fCashCC == 0 && account.fPositionBC == 0;
    }

    /**
     * @dev Update the trader's cash in the margin account (trader can also be the AMM)
     * The 'cash' is denominated in collateral currency.
     * @param _perpetual   The perpetual struct
     * @param _traderAddr The address of the trader
     * @param _fDeltaCash signed 64.64-bit fixed point number.
     *                    Change of trader margin in collateral currency.
     */
    function _updateTraderMargin(
        PerpetualData storage _perpetual,
        address _traderAddr,
        int128 _fDeltaCash
    ) internal {
        if (_fDeltaCash == 0) {
            return;
        }
        MarginAccount storage account = marginAccounts[_perpetual.id][_traderAddr];
        account.fCashCC = account.fCashCC.add(_fDeltaCash);
    }

    /**
     * @dev Transfer from the user to the vault account.
     * @param   _marginTknAddr  Margin token address
     * @param   _userAddr       The address of the account
     * @param   _fAmount        The amount of erc20 token to transfer in ABDK64x64 format.
     */
    function _transferFromUserToVault(
        address _marginTknAddr,
        address _userAddr,
        int128 _fAmount
    ) internal {
        if (_fAmount <= 0) {
            return;
        }
        uint256 ufAmountD18 = _fAmount.toUDec18();
        address vault = address(this);
        IERC20Upgradeable marginToken = IERC20Upgradeable(_marginTknAddr);
        uint256 previousBalance = marginToken.balanceOf(vault);
        marginToken.safeTransferFrom(_userAddr, vault, ufAmountD18);
        uint256 postBalance = marginToken.balanceOf(vault);
        require(postBalance > previousBalance, "bal incorrect");
    }

    /**
     * What is the current amount of collateral that we can
     * consider as borrowed?
     * Linear interpolation between prevBlock and nextBlock
     * @param _pool reference to liquidity pool
     * @return collateral amount in ABDK 64.64 format
     */
    function _getCollateralTokenAmountForPricing(LiquidityPoolData storage _pool)
        internal
        view
        returns (int128)
    {
        if (_pool.totalSupplyShareToken == 0) {
            return 0;
        }
        int128 pnlPartCash = _pool.fPnLparticipantsCashCC;
        uint256 shareProportion = (uint256(_getShareTokenAmountForPricing(_pool)) * 10**18) /
            uint256(_pool.totalSupplyShareToken);
        return int256(shareProportion).fromDec18().mul(pnlPartCash);
    }

    /**
     * to simplify testing we write an internal function
     * @return delay for withdrawing
     */
    function _getDelay() internal pure virtual returns (uint64) {
        return WITHDRAWAL_DELAY_TIME_SEC;
    }

    /**
     * Internal implementation of getShareTokenAmountForPricing
     * @param _pool  reference of liquidity pool
     * @return share token number
     */
    function _getShareTokenAmountForPricing(LiquidityPoolData storage _pool)
        internal
        view
        returns (uint128)
    {
        uint64 thisTs = uint64(block.timestamp);
        if (thisTs >= _pool.prevAnchor + _getDelay()) {
            return _pool.nextTokenAmount;
        }
        uint128 ratioDec100 = ((thisTs - _pool.prevAnchor) * 100) / (_getDelay());
        return
            _pool.nextTokenAmount > _pool.prevTokenAmount
                ? _pool.prevTokenAmount +
                    (ratioDec100 * (_pool.nextTokenAmount - _pool.prevTokenAmount)) /
                    100
                : _pool.prevTokenAmount -
                    (ratioDec100 * (_pool.prevTokenAmount - _pool.nextTokenAmount)) /
                    100;
    }

    /**
     * Transfer from the vault to the user account.
     * @param   _marginTknAddr Margin token address
     * @param   _traderAddr    The address of the account
     * @param   _fAmount       The amount of erc20 token to transfer
     */
    function _transferFromVaultToUser(
        address _marginTknAddr,
        address _traderAddr,
        int128 _fAmount
    ) internal {
        if (_fAmount <= 0) {
            return;
        }
        uint256 ufAmountD18 = _fAmount.toUDec18();
        address vault = address(this);
        IERC20Upgradeable marginToken = IERC20Upgradeable(_marginTknAddr);
        uint256 previousBalance = marginToken.balanceOf(vault);
        // transfer the margin token to the user
        marginToken.safeTransfer(_traderAddr, ufAmountD18);

        uint256 postBalance = marginToken.balanceOf(vault);
        require(previousBalance > postBalance, "bal incorrect");
    }

    /**
     * @dev Get safe Oracle price of the base index S2 of a given perpetual
     */
    function _getSafeOraclePriceS2(PerpetualData storage _perpetual)
        internal
        view
        returns (int128)
    {
        return
            _getSafeOraclePrice(
                _perpetual.S2BaseCCY,
                _perpetual.S2QuoteCCY,
                _perpetual.fSettlementS2PriceData
            );
    }

    /**
     * @dev Get safe Oracle price of the quanto index S3 of a given perpetual
     * @param _perpetual Perpetual storage reference
     */
    function _getSafeOraclePriceS3(PerpetualData storage _perpetual)
        internal
        view
        returns (int128)
    {
        return
            _getSafeOraclePrice(
                _perpetual.S3BaseCCY,
                _perpetual.S3QuoteCCY,
                _perpetual.fSettlementS3PriceData
            );
    }

    /**
     * @dev Get safe oracle price for a given currency pair and fallback price
     * The fallback or settlement price is used when the market is closed (oracle returns 0 price)
     * @param base Base currency
     * @param quote Quote currency
     * @param _fSettlement Settlement price to default to when markets close
     */
    function _getSafeOraclePrice(
        bytes4 base,
        bytes4 quote,
        int128 _fSettlement
    ) internal view returns (int128) {
        OracleFactory factory = OracleFactory(oracleFactoryAddress);
        (int128 fPrice, ) = factory.getSpotPrice(base, quote);
        if (fPrice == 0) {
            // return settlement price
            return _fSettlement;
        }
        return fPrice;
    }

    /**
     * @dev Get oracle price for a given currency pair
     * Not safe in the sense that it could return 0 if markets are closed
     * @param _baseQuote Currency pair
     */
    function _getOraclePrice(bytes4[2] memory _baseQuote) internal view returns (int128) {
        OracleFactory factory = OracleFactory(oracleFactoryAddress);
        (int128 fPrice, ) = factory.getSpotPrice(_baseQuote[0], _baseQuote[1]);
        return fPrice;
    }

    /**
     * Get the multiplier that converts <base> into
     * the value of <collateralcurrency>
     * Hence 1 if collateral currency = base currency
     * If the state of the perpetual is not "NORMAL",
     * use the settlement price
     * @param   _perpetual           The reference of perpetual storage.
     * @param   _isMarkPriceRequest  If true, get the conversion for the mark-price. If false for spot.
     * @return  The index price of the collateral for the given perpetual.
     */
    function _getBaseToCollateralConversionMultiplier(
        PerpetualData storage _perpetual,
        bool _isMarkPriceRequest
    ) internal view returns (int128) {
        AMMPerpLogic.CollateralCurrency ccy = _perpetual.eCollateralCurrency;
        /*
        Quote: Pos * markprice --> quote currency
        Base: Pos * markprice / indexprice; E.g., 0.1 BTC * 36500 / 36000
        Quanto: Pos * markprice / index3price. E.g., 0.1 BTC * 36500 / 2000 = 1.83 ETH
        where markprice is replaced by indexprice if _isMarkPriceRequest=FALSE
        */
        int128 fPx2;
        int128 fPxIndex2;
        if (_perpetual.state != PerpetualState.NORMAL) {
            fPxIndex2 = _perpetual.fSettlementS2PriceData;
            require(fPxIndex2 > 0, "settl px S2 not set");
        } else {
            fPxIndex2 = _getSafeOraclePriceS2(_perpetual);
        }

        if (_isMarkPriceRequest) {
            fPx2 = _getPerpetualMarkPrice(_perpetual);
        } else {
            fPx2 = fPxIndex2;
        }

        if (ccy == AMMPerpLogic.CollateralCurrency.BASE) {
            // equals ONE if _isMarkPriceRequest=FALSE
            return fPx2.div(fPxIndex2);
        }
        if (ccy == AMMPerpLogic.CollateralCurrency.QUANTO) {
            // Example: 0.5 contracts of ETHUSD paid in BTC
            //  the rate is ETHUSD * 1/BTCUSD
            //  BTCUSD = 31000 => 0.5/31000 = 0.00003225806452 BTC
            return
                _perpetual.state == PerpetualState.NORMAL
                    ? fPx2.div(_getSafeOraclePriceS3(_perpetual))
                    : fPx2.div(_perpetual.fSettlementS3PriceData);
        } else {
            // Example: 0.5 contracts of ETHUSD paid in USD
            //  the rate is ETHUSD
            //  ETHUSD = 2000 => 0.5 * 2000 = 1000
            require(ccy == AMMPerpLogic.CollateralCurrency.QUOTE, "unknown state");
            return fPx2;
        }
    }

    /**
     * Get the mark price of the perpetual. If the state of the perpetual is not "NORMAL",
     * return the settlement price
     * @param   _perpetual The perpetual in the liquidity pool
     * @return  markPrice  The mark price of current perpetual.
     */
    function _getPerpetualMarkPrice(PerpetualData storage _perpetual)
        internal
        view
        returns (int128)
    {
        int128 fPremiumRate = _perpetual.currentMarkPremiumRate.fPrice;
        int128 markPrice = _perpetual.state == PerpetualState.NORMAL
            ? (_getSafeOraclePriceS2(_perpetual)).mul(ONE_64x64.add(fPremiumRate))
            : (_perpetual.fSettlementS2PriceData).mul(ONE_64x64.add(fPremiumRate));
        return markPrice;
    }

    /**
     * Get the multiplier that converts <collateralcurrency> into
     * the value of <quotecurrency>
     * Hence 1 if collateral currency = quote currency
     * If the state of the perpetual is not "NORMAL",
     * use the settlement price
     * @param   _perpetual           The reference of perpetual storage.
     * @return  The index price of the collateral for the given perpetual.
     */
    function _getCollateralToQuoteConversionMultiplier(PerpetualData storage _perpetual)
        internal
        view
        returns (int128)
    {
        AMMPerpLogic.CollateralCurrency ccy = _perpetual.eCollateralCurrency;
        /*
            Quote: 1
            Base: S2, e.g. we hold 1 BTC -> 36000 USD
            Quanto: S3, e.g., we hold 1 ETH -> 2000 USD
        */
        if (ccy == AMMPerpLogic.CollateralCurrency.BASE) {
            return
                _perpetual.state == PerpetualState.NORMAL
                    ? _getSafeOraclePriceS2(_perpetual)
                    : _perpetual.fSettlementS2PriceData;
        }
        if (ccy == AMMPerpLogic.CollateralCurrency.QUANTO) {
            return
                _perpetual.state == PerpetualState.NORMAL
                    ? _getSafeOraclePriceS3(_perpetual)
                    : _perpetual.fSettlementS3PriceData;
        } else {
            return ONE_64x64;
        }
    }

    /**
     * Prepare data for pricing functions (AMMPerpModule)
     * Can revert "market is closed" if price 0
     * @param   _perpetual    The reference of perpetual storage.
     * @param   _useFallback Should a fallback price be used in case the oracle price is not current?
     */
    function _prepareAMMAndMarketData(PerpetualData storage _perpetual, bool _useFallback)
        internal
        view
        returns (AMMPerpLogic.AMMVariables memory, AMMPerpLogic.MarketVariables memory)
    {
        // prepare data
        AMMPerpLogic.AMMVariables memory ammState;
        AMMPerpLogic.MarketVariables memory marketState;

        marketState.fIndexPriceS2 = _useFallback
            ? _getSafeOraclePriceS2(_perpetual)
            : _getOraclePrice([_perpetual.S2BaseCCY, _perpetual.S2QuoteCCY]);
        require(marketState.fIndexPriceS2 > 0, "market is closed");
        marketState.fSigma2 = int128(_perpetual.fSigma2) << 35;
        MarginAccount storage AMMMarginAcc = marginAccounts[_perpetual.id][address(this)];
        // get current locked-in value
        ammState.fLockedValue1 = AMMMarginAcc.fLockedInValueQC.neg();

        // get current position of all traders (= - AMM position)
        ammState.fAMM_K2 = AMMMarginAcc.fPositionBC.neg();
        // get cash from PnL fund that we can use when pricing
        int128 fPricingPnLCashCC;
        {
            LiquidityPoolData storage _pool = liquidityPools[_perpetual.poolId];
            if (_pool.fPnLparticipantsCashCC > 0) {
                fPricingPnLCashCC = _getCollateralTokenAmountForPricing(_pool);
                fPricingPnLCashCC = fPricingPnLCashCC.mul(
                    _perpetual.fFundAllocationWeightCC.div(_pool.fFundAllocationNormalizationCC)
                );
            }
        }
        // get cash from AMM margin account
        fPricingPnLCashCC = fPricingPnLCashCC.add(AMMMarginAcc.fCashCC);
        AMMPerpLogic.CollateralCurrency ccy = _perpetual.eCollateralCurrency;
        if (ccy == AMMPerpLogic.CollateralCurrency.BASE) {
            ammState.fPoolM2 = _perpetual.fAMMFundCashCC.add(fPricingPnLCashCC);
        } else if (ccy == AMMPerpLogic.CollateralCurrency.QUANTO) {
            ammState.fPoolM3 = _perpetual.fAMMFundCashCC.add(fPricingPnLCashCC);
            // additional parameters for quanto case
            int128 fPx = _useFallback
                ? _getSafeOraclePriceS3(_perpetual)
                : _getOraclePrice([_perpetual.S3BaseCCY, _perpetual.S3QuoteCCY]);
            require(fPx > 0, "market is closed");
            marketState.fIndexPriceS3 = fPx;
            marketState.fSigma3 = int128(_perpetual.fSigma3) << 35;
            marketState.fRho23 = int128(_perpetual.fRho23) << 35;
        } else {
            assert(ccy == AMMPerpLogic.CollateralCurrency.QUOTE);
            ammState.fPoolM1 = _perpetual.fAMMFundCashCC.add(fPricingPnLCashCC);
        }
        ammState.fCurrentTraderExposureEMA = _perpetual.fCurrentTraderExposureEMA;
        return (ammState, marketState);
    }

    /**
     * @dev     Select current perpetual and a "random" other perpetual that will
     *          be processed
     *
     * @param   _iPerpetualId   perpetual id
     * @param   _iPoolIdx       pool index of that perpetual
     */
    function _selectPerpetualIds(uint24 _iPerpetualId, uint8 _iPoolIdx)
        internal
        view
        returns (uint24, uint24)
    {
        require(_iPoolIdx > 0, "pool not found");
        LiquidityPoolData storage liquidityPool = liquidityPools[_iPoolIdx];
        require(liquidityPool.iPerpetualCount > 0, "no perp in pool");
        uint16 idx = uint16(block.timestamp % uint64(liquidityPool.iPerpetualCount));
        uint24 otherPerpId = perpetualIds[liquidityPool.id][idx];
        // function can be called with a 0 perpId, if so, choose a
        // perpetual
        if (_iPerpetualId == uint24(0)) {
            idx = (idx + 1) % liquidityPool.iPerpetualCount;
            _iPerpetualId = perpetualIds[liquidityPool.id][idx];
        }
        return (_iPerpetualId, otherPerpId);
    }

    /*
     * Check if two numbers have the same sign. Zero has the same sign with any number
     * @param   _fX 64.64 fixed point number
     * @param   _fY 64.64 fixed point number
     * @return  True if the numbers have the same sign or one of them is zero.
     */
    function _hasTheSameSign(int128 _fX, int128 _fY) internal pure returns (bool) {
        if (_fX == 0 || _fY == 0) {
            return true;
        }
        return (_fX ^ _fY) >> 127 == 0;
    }

    /**
     * Calculate Exponentially Weighted Moving Average.
     * Returns updated EMA based on
     * _fEMA = _fLambda * _fEMA + (1-_fLambda)* _fCurrentObs
     * @param _fEMA signed 64.64-bit fixed point number
     * @param _fCurrentObs signed 64.64-bit fixed point number
     * @param _fLambda signed 64.64-bit fixed point number
     * @return fNewEMA updated EMA, signed 64.64-bit fixed point number
     */
    function _ema(
        int128 _fEMA,
        int128 _fCurrentObs,
        int128 _fLambda
    ) internal pure returns (int128 fNewEMA) {
        require(_fLambda > 0, "EMALambda must be gt 0");
        require(_fLambda < ONE_64x64, "EMALambda must be st 1");
        // result must be between the two values _fCurrentObs and _fEMA, so no overflow
        fNewEMA = ABDKMath64x64.add(
            _fEMA.mul(_fLambda),
            ABDKMath64x64.mul(ONE_64x64.sub(_fLambda), _fCurrentObs)
        );
    }

    function _getTradeLogic() internal view returns (IPerpetualTradeLogic) {
        return IPerpetualTradeLogic(address(this));
    }

    function _getTreasuryLogic() internal view returns (IPerpetualTreasury) {
        return IPerpetualTreasury(address(this));
    }

    function _getAMMPerpLogic() internal view returns (IAMMPerpLogic) {
        return IAMMPerpLogic(address(ammPerpLogic));
    }

    function _getRebalanceLogic() internal view returns (IPerpetualRebalanceLogic) {
        return IPerpetualRebalanceLogic(address(this));
    }

    function _getBrokerFeeLogic() internal view returns (IPerpetualBrokerFeeLogic) {
        return IPerpetualBrokerFeeLogic(address(this));
    }

    function _getUpdateLogic() internal view returns (IPerpetualUpdateLogic) {
        return IPerpetualUpdateLogic(address(this));
    }

    function _getMarginViewLogic() internal view returns (IPerpetualMarginViewLogic) {
        return IPerpetualMarginViewLogic(address(this));
    }

    function _getPerpetualGetter() internal view returns (IPerpetualGetter) {
        return IPerpetualGetter(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IPerpetualOrder.sol";

interface IPerpetualMarginViewLogic is IPerpetualOrder {
    function calcMarginForTargetLeverage(
        uint24 _iPerpetualId,
        int128 _fTraderPos,
        int128 _fPrice,
        int128 _fTradeAmountBC,
        int128 _fTargetLeverage,
        address _traderAddr,
        bool _ignorePosBalance
    ) external view returns (int128);

    function getMarginBalance(uint24 _iPerpetualId, address _traderAddr)
        external
        view
        returns (int128);

    function isMaintenanceMarginSafe(uint24 _iPerpetualId, address _traderAddr)
        external
        view
        returns (bool);

    function getAvailableMargin(
        uint24 _iPerpetualId,
        address _traderAddr,
        bool _isInitialMargin
    ) external view returns (int128);

    function isInitialMarginSafe(uint24 _iPerpetualId, address _traderAddr)
        external
        view
        returns (bool);

    function getInitialMargin(uint24 _iPerpetualId, address _traderAddr)
        external
        view
        returns (int128);

    function getMaintenanceMargin(uint24 _iPerpetualId, address _traderAddr)
        external
        view
        returns (int128);

    function isMarginSafe(uint24 _iPerpetualId, address _traderAddr) external view returns (bool);

    function getAvailableCash(uint24 _iPerpetualId, address _traderAddr)
        external
        view
        returns (int128);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../core/PerpStorage.sol";
import "../../interface/IShareTokenFactory.sol";

interface IPerpetualGetter {
    struct PerpetualStaticInfo {
        uint24 id;
        address limitOrderBookAddr;
        int128 fInitialMarginRate;
        int128 fMaintenanceMarginRate;
        uint8 perpetualState;
        AMMPerpLogic.CollateralCurrency collCurrencyType;
        bytes4 S2BaseCCY; //base currency of S2
        bytes4 S2QuoteCCY; //quote currency of S2
        bytes4 S3BaseCCY; //base currency of S3
        bytes4 S3QuoteCCY; //quote currency of S3
        int128 fLotSizeBC;
        int128 fReferralRebateCC;
        bytes32[] priceIds;
        bool[] isPyth;
    }

    function getPoolCount() external view returns (uint8);

    function getPerpetualId(uint8 _poolId, uint8 _perpetualIndex) external view returns (uint24);

    function getLiquidityPool(uint8 _poolId)
        external
        view
        returns (PerpStorage.LiquidityPoolData memory);

    function getLiquidityPools(uint8 _poolIdFrom, uint8 _poolIdTo)
        external
        view
        returns (PerpStorage.LiquidityPoolData[] memory);

    function getPoolIdByPerpetualId(uint24 _perpetualId) external view returns (uint8);

    function getPerpetual(uint24 _perpetualId)
        external
        view
        returns (PerpStorage.PerpetualData memory);

    function getPerpetuals(uint24[] calldata perpetualIds)
        external
        view
        returns (PerpStorage.PerpetualData[] memory);

    function queryMidPrices(uint24[] calldata perpetualIds, int128[] calldata idxPriceDataPairs)
        external
        view
        returns (int128[] memory);

    function getMarginAccount(uint24 _perpetualId, address _traderAddress)
        external
        view
        returns (PerpStorage.MarginAccount memory);

    function isActiveAccount(uint24 _perpetualId, address _traderAddress)
        external
        view
        returns (bool);

    function getAMMPerpLogic() external view returns (address);

    function getShareTokenFactory() external view returns (IShareTokenFactory);

    function getActivePerpAccounts(uint24 _perpetualId) external view returns (address[] memory);

    function getPerpetualCountInPool(uint8 _poolId) external view returns (uint8);

    function getAMMState(uint24 _perpetualId, int128[2] calldata _fIndexPrice)
        external
        view
        returns (int128[15] memory);

    function getTraderState(
        uint24 _perpetualId,
        address _traderAddress,
        int128[2] calldata _fIndexPrice
    ) external view returns (int128[11] memory);

    function getActivePerpAccountsByChunks(
        uint24 _perpetualId,
        uint256 _from,
        uint256 _to
    ) external view returns (address[] memory);

    function isTraderMaintenanceMarginSafe(uint24 _perpetualId, address _traderAddress)
        external
        view
        returns (bool);

    function countActivePerpAccounts(uint24 _perpetualId) external view returns (uint256);

    function getOraclePrice(bytes4[2] memory _baseQuote) external view returns (int128 fPrice);

    function getOracleFactory() external view returns (address);

    function getTreasuryAddress() external view returns (address);

    function getOrderBookFactoryAddress() external view returns (address);

    function getOrderBookAddress(uint24 _perpetualId) external view returns (address);

    function isMarketClosed(bytes4 _baseCurrency, bytes4 _quoteCurrency)
        external
        view
        returns (bool);

    function isPerpMarketClosed(uint24 _perpetualId) external view returns (bool isClosed);

    function getPriceInfo(uint24 _perpetualId)
        external
        view
        returns (bytes32[] memory, bool[] memory);

    function getPoolStaticInfo(uint8 _poolFromIdx, uint8 _poolToIdx)
        external
        view
        returns (
            uint24[][] memory,
            address[] memory,
            address[] memory,
            address _oracleFactoryAddress
        );

    function getPerpetualStaticInfo(uint24[] calldata perpetualIds)
        external
        view
        returns (PerpetualStaticInfo[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IPerpetualOrder.sol";

interface IPerpetualMarginLogic is IPerpetualOrder {
    function depositMarginForOpeningTrade(
        uint24 _iPerpetualId,
        int128 _fDepositRequired,
        Order memory _order
    ) external returns (bool);

    function withdrawDepositFromMarginAccount(uint24 _iPerpetualId, address _traderAddr) external;

    function reduceMarginCollateral(
        uint24 _iPerpetualId,
        address _traderAddr,
        int128 _fAmountToWithdraw
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPerpetualOrder {
    //     iPerpetualId          global id for perpetual
    //     traderAddr            address of trader
    //     brokerSignature       signature of broker (or 0)
    //     brokerFeeTbps         broker can set their own fee
    //     fAmount               amount in base currency to be traded
    //     fLimitPrice           limit price
    //     fTriggerPrice         trigger price. Non-zero for stop orders.
    //     iDeadline             deadline for price (seconds timestamp)
    //     traderMgnTokenAddr    address of the compatible margin token the user likes to use,
    //                           0 if same token as liquidity pool's margin token
    //     flags                 trade flags
    struct Order {
        uint32 flags;
        uint24 iPerpetualId;
        uint16 brokerFeeTbps;
        address traderAddr;
        address brokerAddr;
        address referrerAddr;
        bytes brokerSignature;
        int128 fAmount;
        int128 fLimitPrice;
        int128 fTriggerPrice;
        int128 fLeverage; // 0 if deposit and trade separate
        uint64 iDeadline;
        uint64 createdTimestamp;
        uint64 submittedTimestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ABDKMath64x64.sol";

library ConverterDec18 {
    using ABDKMath64x64 for int128;
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    int256 private constant DECIMALS = 10**18;

    int128 private constant ONE_64x64 = 0x010000000000000000;

    int128 public constant HALF_TBPS = 92233720368548; //1e-5 * 0.5 * 2**64

    // convert tenth of basis point to dec 18:
    uint256 public constant TBPSTODEC18 = 0x9184e72a000; // hex(10^18 * 10^-5)=(10^13)
    // convert tenth of basis point to ABDK 64x64:
    int128 public constant TBPSTOABDK = 0xa7c5ac471b48; // hex(2^64 * 10^-5)

    function tbpsToDec18(uint16 Vtbps) internal pure returns (uint256) {
        return TBPSTODEC18 * uint256(Vtbps);
    }

    function tbpsToABDK(uint16 Vtbps) internal pure returns (int128) {
        return int128(uint128(TBPSTOABDK) * uint128(Vtbps));
    }

    function ABDKToTbps(int128 Vabdk) internal pure returns (uint16) {
        // add 0.5 * 1e-5 to ensure correct rounding to tenth of bps
        return uint16(uint128(Vabdk.add(HALF_TBPS) / TBPSTOABDK));
    }

    function fromDec18(int256 x) internal pure returns (int128) {
        int256 result = (x * ONE_64x64) / DECIMALS;
        require(x >= MIN_64x64 && x <= MAX_64x64, "result out of range");
        return int128(result);
    }

    function toDec18(int128 x) internal pure returns (int256) {
        return (int256(x) * DECIMALS) / ONE_64x64;
    }

    function toUDec18(int128 x) internal pure returns (uint256) {
        require(x >= 0, "negative value");
        return uint256(toDec18(x));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: idx out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function enumerate(
        AddressSet storage set,
        uint256 start,
        uint256 count
    ) internal view returns (address[] memory output) {
        uint256 end = start + count;
        require(end >= start, "addition overflow");
        uint256 len = length(set);
        end = len < end ? len : end;
        if (end == 0 || start >= end) {
            return output;
        }

        output = new address[](end - start);
        for (uint256 i; i < end - start; i++) {
            output[i] = at(set, i + start);
        }
        return output;
    }

    function enumerateAll(AddressSet storage set) internal view returns (address[] memory output) {
        return enumerate(set, 0, length(set));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythErrors.sol";
import "../libraries/ABDKMath64x64.sol";
import "./SpotOracle.sol";

contract OracleFactory is Ownable, OracleInterfaceID {
    using ERC165Checker for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ABDKMath64x64 for int128;

    int128 constant ONE_64x64 = 0x10000000000000000; // 2^64

    uint256 private immutable MAX_FEED_TIME_GAP_SEC;

    address public pyth;

    struct OracleData {
        address oracle;
        bool isInverse;
    }

    // baseCurrency => quoteCurrency => oracles' addresses
    mapping(bytes4 => mapping(bytes4 => OracleData[])) routes;
    // price Id => address of spot oracle with that id
    mapping(bytes32 => address) oracles;

    event OracleCreated(bytes4 baseCurrency, bytes4 quoteCurrency, address oracle);
    event OracleAdded(bytes4 baseCurrency, bytes4 quoteCurrency, address oracle);
    event ShortRouteAdded(bytes4 baseCurrency, bytes4 quoteCurrency, address oracle);
    event RouteAdded(
        bytes4 baseCurrency,
        bytes4 quoteCurrency,
        address[] oracle,
        bool[] isInverse
    );
    event RouteRemoved(bytes4 baseCurrency, bytes4 quoteCurrency);

    /**
     * @param _maxFeedTimeGapSec Maximum time difference between two feed updates until they are considered out of sync
     */
    constructor(uint256 _maxFeedTimeGapSec) {
        require(_maxFeedTimeGapSec > 0, "max feed time> 0");
        MAX_FEED_TIME_GAP_SEC = _maxFeedTimeGapSec;
    }

    function setPythProxy(address _pythAddress) external onlyOwner {
        pyth = _pythAddress;
    }

    /**
     * @notice Deploys Oracle contract for currency pair.
     * @dev The route for the given pair will be set (overwritten if it was already set).
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     * @param   _tradingBreakMins delay after which we consider mkt closed
     */
    function createOracle(
        bytes4 _baseCurrency,
        bytes4 _quoteCurrency,
        uint16 _tradingBreakMins,
        address _feedAddress,
        bytes32 _priceId,
        uint256 _feedPeriod
    ) external virtual onlyOwner returns (address) {
        require(_baseCurrency != "", "invalid base currency");
        require(_quoteCurrency != 0, "invalid quote currency");
        require(_baseCurrency != _quoteCurrency, "base and quote should differ");

        address oracle = address(
            new SpotOracle(
                _baseCurrency,
                _quoteCurrency,
                _tradingBreakMins,
                _feedAddress,
                _priceId,
                _feedPeriod
            )
        );
        oracles[_priceId] = oracle;
        SpotOracle(oracle).transferOwnership(msg.sender);
        _setRoute(_baseCurrency, _quoteCurrency, oracle);

        //checks that price can be calculated
        _getSpotPrice(_baseCurrency, _quoteCurrency);

        emit OracleCreated(_baseCurrency, _quoteCurrency, oracle);

        return oracle;
    }

    /**
     * @notice Sets Oracle contract for currency pair.
     * @dev The route for the given pair will be set (overwritten if it was already set).
     *
     * @param   _oracle   The Oracle contract (should implement ISpotOracle interface).
     */
    function addOracle(address _oracle) external onlyOwner {
        require(_oracle.supportsInterface(_getOracleInterfaceID()), "invalid oracle");

        bytes4 baseCurrency = ISpotOracle(_oracle).getBaseCurrency();
        bytes4 quoteCurrency = ISpotOracle(_oracle).getQuoteCurrency();
        _setRoute(baseCurrency, quoteCurrency, _oracle);

        //checks that price can be calculated
        _getSpotPrice(baseCurrency, quoteCurrency);
        emit OracleAdded(baseCurrency, quoteCurrency, _oracle);
    }

    /**
     * @notice Sets Oracle as a shortest route for the given currency pair.
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     * @param   _oracle         The Oracle contract (should implement ISpotOracle interface).
     */
    function _setRoute(
        bytes4 _baseCurrency,
        bytes4 _quoteCurrency,
        address _oracle
    ) internal {
        delete routes[_baseCurrency][_quoteCurrency];
        delete oracles[ISpotOracle(_oracle).priceId()];
        routes[_baseCurrency][_quoteCurrency].push(OracleData(address(_oracle), false));
        oracles[ISpotOracle(_oracle).priceId()] = _oracle;
        emit ShortRouteAdded(_baseCurrency, _quoteCurrency, _oracle);
    }

    /**
     * @notice Sets the given array of oracles as a route for the given currency pair.
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     * @param   _oracles        The array Oracle contracts.
     * @param   _isInverse      The array of flags whether price is inverted.
     */
    function addRoute(
        bytes4 _baseCurrency,
        bytes4 _quoteCurrency,
        address[] calldata _oracles,
        bool[] calldata _isInverse
    ) external onlyOwner {
        _validateRoute(_baseCurrency, _quoteCurrency, _oracles, _isInverse);

        uint256 length = _oracles.length;
        delete routes[_baseCurrency][_quoteCurrency];
        for (uint256 i = 0; i < length; i++) {
            routes[_baseCurrency][_quoteCurrency].push(OracleData(_oracles[i], _isInverse[i]));
            oracles[ISpotOracle(_oracles[i]).priceId()] = _oracles[i];
        }

        //checks that price can be calculated
        _getSpotPrice(_baseCurrency, _quoteCurrency);

        emit RouteAdded(_baseCurrency, _quoteCurrency, _oracles, _isInverse);
    }

    /**
     * @notice Validates the given array of oracles as a route for the given currency pair.
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     * @param   _oracles        The array Oracle contracts.
     * @param   _isInverse      The array of flags whether price is inverted.
     */
    function _validateRoute(
        bytes4 _baseCurrency,
        bytes4 _quoteCurrency,
        address[] calldata _oracles,
        bool[] calldata _isInverse
    ) internal view {
        uint256 length = _oracles.length;
        require(length > 0, "no oracles");
        require(length == _isInverse.length, "arrays mismatch");

        bytes4 srcCurrency;
        bytes4 destCurrency;
        require(_oracles[0].supportsInterface(_getOracleInterfaceID()), "invalid oracle [1]");
        if (!_isInverse[0]) {
            srcCurrency = ISpotOracle(_oracles[0]).getBaseCurrency();
            require(_baseCurrency == srcCurrency, "invalid route [1]");
            destCurrency = ISpotOracle(_oracles[0]).getQuoteCurrency();
        } else {
            srcCurrency = ISpotOracle(_oracles[0]).getQuoteCurrency();
            require(_baseCurrency == srcCurrency, "invalid route [2]");
            destCurrency = ISpotOracle(_oracles[0]).getBaseCurrency();
        }
        for (uint256 i = 1; i < length; i++) {
            require(_oracles[i].supportsInterface(_getOracleInterfaceID()), "invalid oracle [1]");
            bytes4 oracleBaseCurrency = ISpotOracle(_oracles[i]).getBaseCurrency();
            bytes4 oracleQuoteCurrency = ISpotOracle(_oracles[i]).getQuoteCurrency();
            if (!_isInverse[i]) {
                require(destCurrency == oracleBaseCurrency, "invalid route [3]");
                destCurrency = oracleQuoteCurrency;
            } else {
                require(destCurrency == oracleQuoteCurrency, "invalid route [4]");
                destCurrency = oracleBaseCurrency;
            }
        }
        require(_quoteCurrency == destCurrency, "invalid route [5]");
    }

    /**
     * @notice Removes a route for the given currency pair.
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     */
    function removeRoute(bytes4 _baseCurrency, bytes4 _quoteCurrency) external onlyOwner {
        OracleData[] storage route = routes[_baseCurrency][_quoteCurrency];
        for (uint256 i = 0; i < route.length; i++) {
            delete oracles[ISpotOracle(route[i].oracle).priceId()];
        }
        delete routes[_baseCurrency][_quoteCurrency];
        emit RouteRemoved(_baseCurrency, _quoteCurrency);
    }

    /**
     * @notice Returns the route for the given currency pair.
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     */
    function getRoute(bytes4 _baseCurrency, bytes4 _quoteCurrency)
        external
        view
        returns (OracleData[] memory)
    {
        return routes[_baseCurrency][_quoteCurrency];
    }

    /**
     * @notice Calculates spot price.
     *
     * @param   _baseCurrency   The base currency symbol.
     * @param   _quoteCurrency  The quote currency symbol.
     */
    function getSpotPrice(bytes4 _baseCurrency, bytes4 _quoteCurrency)
        external
        view
        returns (int128, uint256)
    {
        return _getSpotPrice(_baseCurrency, _quoteCurrency);
    }

    /**
     * @notice Determines if any oracle along a route is terminated.
     *
     * @param _baseCurrency The base currency symbol.
     * @param _quoteCurrency The quote currency symbol.
     */
    function isRouteTerminated(bytes4 _baseCurrency, bytes4 _quoteCurrency)
        external
        view
        returns (bool)
    {
        OracleData[] storage oracleChain = routes[_baseCurrency][_quoteCurrency];
        uint256 numLinks = oracleChain.length;
        bool isChainBroken;
        for (uint256 i = 0; i < numLinks && !isChainBroken; i++) {
            OracleData storage oracleData = oracleChain[i];
            isChainBroken = isChainBroken || ISpotOracle(oracleData.oracle).isTerminated();
        }
        return isChainBroken;
    }

    /**
     * @notice Determines if a route from _baseCurrency to _quoteCurrency exists
     * @param _baseCurrency The base currency symbol
     * @param _quoteCurrency The quote currency symbol
     */
    function existsRoute(bytes4 _baseCurrency, bytes4 _quoteCurrency)
        external
        view
        returns (bool)
    {
        OracleData[] storage routeOracles = routes[_baseCurrency][_quoteCurrency];
        return routeOracles.length > 0;
    }

    /**
     * @notice Returns the spot price of one _baseCurrency in _quoteCurrency.
     *
     * @dev Price can be zero which needs to be captured outside this function
     * @param _baseCurrency in bytes4 representation
     * @param _quoteCurrency in bytes4 representation
     * @return fPrice Oracle price
     * @return timestamp Oracle timestamp
     */
    function _getSpotPrice(bytes4 _baseCurrency, bytes4 _quoteCurrency)
        internal
        view
        returns (int128 fPrice, uint256 timestamp)
    {
        OracleData[] storage routeOracles = routes[_baseCurrency][_quoteCurrency];
        uint256 length = routeOracles.length;
        bool isInverse;
        if (length == 0) {
            routeOracles = routes[_quoteCurrency][_baseCurrency];
            length = routeOracles.length;
            require(length > 0, "route not found");
            isInverse = true;
        }

        fPrice = ONE_64x64;
        int128 oraclePrice;
        uint256 oracleTimestamp;
        for (uint256 i = 0; i < length; i++) {
            OracleData storage oracleData = routeOracles[i];
            (oraclePrice, oracleTimestamp) = ISpotOracle(oracleData.oracle).getSpotPrice();
            timestamp = oracleTimestamp < timestamp || timestamp == 0
                ? oracleTimestamp
                : timestamp;
            if (oraclePrice == 0) {
                //e.g. market closed
                return (0, timestamp);
            }
            if (!oracleData.isInverse) {
                fPrice = fPrice.mul(oraclePrice);
            } else {
                fPrice = fPrice.div(oraclePrice);
            }
        }
        if (isInverse) {
            fPrice = ONE_64x64.div(fPrice);
        }
    }

    /**
     * @notice Returns the ids used to determine the price of a given currency pair
     * @param _baseQuote Currency pair
     */
    function getRouteIds(bytes4[2] calldata _baseQuote)
        external
        view
        returns (bytes32[] memory, bool[] memory)
    {
        // try direct route first
        OracleData[] storage route = routes[_baseQuote[0]][_baseQuote[1]];
        uint256 numFeeds = route.length;
        if (numFeeds == 0) {
            // inverse
            route = routes[_baseQuote[1]][_baseQuote[0]];
            numFeeds = route.length;
        }
        // slice
        bytes32[] memory id = new bytes32[](numFeeds);
        bool[] memory isPyth = new bool[](numFeeds);
        for (uint256 i = 0; i < numFeeds; i++) {
            address oracle = route[i].oracle;
            id[i] = ISpotOracle(oracle).priceId();
            isPyth[i] = ISpotOracle(oracle).priceFeed() == pyth;
        }
        return (id, isPyth);
    }

    /**
     * @notice Update price feeds.
     *
     * @dev Reverts if update is invalid, not paid for, or unnecessary.
     * 1) if _blockAge is zero, publish times only need to be compatible with the price feed requirements,
     * 2) if _blockAge > 0, the update data should not be older than the given age based on the minimal blocktime:
     *     publish TS + maximum age >= current TS
     * 3) publish TSs must be close to each other (within 2 blocktimes)
     * @param _updateData Update data
     * @param _priceIds Ids of the feeds to update
     * @param _publishTimes Timestamps of each update
     * @param _maxAcceptableFeedAge maximal age that the caller of this function would accept (in seconds) can be
     *  overriden to an older age by ISpotOracle(oracle).feedPeriod()
     */
    function updatePriceFeeds(
        bytes[] calldata _updateData,
        bytes32[] calldata _priceIds,
        uint64[] calldata _publishTimes,
        uint256 _maxAcceptableFeedAge
    ) external payable {
        require(_updateData.length > 0, "no data");
        require(
            _priceIds.length == _updateData.length && _updateData.length == _publishTimes.length,
            "array mismatch"
        );
        // feed's max age
        // - has to newer than the latest
        uint256 maxAgeSec;
        {
            // feed's max age set by Oracle
            maxAgeSec = IPyth(pyth).getValidTimePeriod();
            // caller's required feed age in seconds
            // choose feed's age if _maxAcceptableFeedAge not given (0), else use _maxAcceptableFeedAge capped at feed's valid age
            maxAgeSec = _maxAcceptableFeedAge == 0 || _maxAcceptableFeedAge > maxAgeSec
                ? maxAgeSec
                : _maxAcceptableFeedAge;
        }
        uint256 oldest = _publishTimes[0];
        uint256 latest = _publishTimes[0];

        for (uint256 i = 1; i < _publishTimes.length; i++) {
            oldest = oldest < _publishTimes[i] ? oldest : _publishTimes[i];
            latest = latest > _publishTimes[i] ? latest : _publishTimes[i];
            // check minmax here
            address oracle = oracles[_priceIds[i]];
            require(oracle != address(0), "no oracle for price id");
            // some feeds (e.g. USDC) might be updating slower than requested,
            // hence maxAgeSec can be overruled by the slower time from the feed
            uint256 overrideAge = ISpotOracle(oracle).feedPeriod();
            overrideAge = maxAgeSec < overrideAge ? overrideAge : maxAgeSec;
            require(_publishTimes[i] + overrideAge >= block.timestamp, "updt too old");
        }
        require(latest <= oldest + MAX_FEED_TIME_GAP_SEC, "not in sync");

        // TODO: case where some ids are pyth and some aren't - for now we assume they're all pyth
        try
            IPyth(pyth).updatePriceFeedsIfNecessary{ value: msg.value }(
                _updateData,
                _priceIds,
                _publishTimes
            )
        {
            return;
        } catch (bytes memory _err) {
            if (PythErrors.NoFreshUpdate.selector == bytes32(_err)) {
                // reverted because no update is needed
                revert("not needed");
            } else if (PythErrors.InsufficientFee.selector == bytes32(_err)) {
                // we notify of this error separately since it's informative
                revert("insufficient fee");
            } else {
                // something wrong with the update sent
                revert("invalid updt");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../../interface/IShareTokenFactory.sol";
import "../../libraries/ABDKMath64x64.sol";
import "./../functions/AMMPerpLogic.sol";
import "../../libraries/EnumerableSetUpgradeable.sol";
import "../../libraries/EnumerableBytes4Set.sol";
import "../../governance/Maintainable.sol";

contract PerpStorage is Maintainable, ReentrancyGuard {
    using ABDKMath64x64 for int128;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableBytes4Set for EnumerableBytes4Set.Bytes4Set; // enumerable map of bytes4 or addresses
    /**
     * @notice  Perpetual state:
     *          - INVALID:      Uninitialized or not non-existent perpetual.
     *          - INITIALIZING: Only when LiquidityPoolData.isRunning == false. Traders cannot perform operations.
     *          - NORMAL:       Full functional state. Traders are able to perform all operations.
     *          - EMERGENCY:    Perpetual is unsafe and the perpetual needs to be settled.
     *          - CLEARED:      All margin accounts are cleared. Traders can withdraw remaining margin balance.
     */
    enum PerpetualState {
        INVALID,
        INITIALIZING,
        NORMAL,
        EMERGENCY,
        CLEARED
    }

    // margin and liquidity pool are held in 'collateral currency' which can be either of
    // quote currency, base currency, or quanto currency

    int128 internal constant ONE_64x64 = 0x10000000000000000; // 2^64
    int128 internal constant FUNDING_INTERVAL_SEC = 0x70800000000000000000; //3600 * 8 * 0x10000000000000000 = 8h in seconds scaled by 2^64 for ABDKMath64x64
    int128 internal constant CEIL_PNL_SHARE = 0xc000000000000000; //=0.75: participants get PnL proportional to min[PFund/(PFund+allAMMFundSizes), 75%]
    int128 internal constant CEIL_AMT_FUND_WITHDRAWAL = 0xc000000000000000; //=0.75: maximal relative amount we withdraw from the default fund and stakers in rebalance
    int128 internal constant MIN_NUM_LOTS_PER_POSITION = 0x0a0000000000000000; // 10, minimal position size in number of lots
    // at target, 1% of missing amount is transferred
    // at every rebalance
    uint8 internal iPoolCount;
    // delay required for trades to mitigate oracle front-running in seconds
    uint8 internal iTradeDelaySec;
    address internal ammPerpLogic;

    IShareTokenFactory internal shareTokenFactory;

    //pool id (incremental index, starts from 1) => pool data
    mapping(uint8 => LiquidityPoolData) internal liquidityPools;

    //bytes32 id = keccak256(abi.encodePacked(poolId, perpetualIndex));
    //perpetual id (hash(poolId, perpetualIndex)) => pool id
    mapping(uint24 => uint8) internal perpetualPoolIds;

    address orderBookFactory;

    /**
     * @notice  Data structure to store oracle price data.
     */
    struct OraclePriceData {
        int128 fPrice;
        uint64 time;
    }

    /**
     * @notice  Data structure to store user margin information.
     */
    struct MarginAccount {
        int128 fLockedInValueQC; // unrealized value locked-in when trade occurs in
        int128 fCashCC; // cash in collateral currency (base, quote, or quanto)
        int128 fPositionBC; // position in base currency (e.g., 1 BTC for BTCUSD)
        int128 fUnitAccumulatedFundingStart; // accumulated funding rate
        uint64 iLastOpenTimestamp; // timestamp in seconds when the position was last opened/increased
        uint16 feeTbps; // exchange fee in tenth of a basis point
        uint16 brokerFeeTbps; // broker fee in tenth of a basis point
        bytes16 positionId; // unique id for the position (for given trader, and perpetual). Current position, zero otherwise.
    }

    /**
     * @notice  Store information for a given perpetual market.
     */
    struct PerpetualData {
        // ------
        uint8 poolId;
        uint24 id;
        int32 fInitialMarginRate; //parameter: initial margin
        int32 fMaintenanceMarginRate; // parameter: maintenance margin
        int32 fSigma2; // parameter: volatility of base-quote pair
        uint64 iLastFundingTime; //timestamp since last funding rate payment
        uint64 iLastSettlementPriceUpdateTimestamp; // timestamp when last price was observed happened
        // ------
        PerpetualState state; // Perpetual AMM state
        AMMPerpLogic.CollateralCurrency eCollateralCurrency; //parameter: in what currency is the collateral held?
        uint16 minimalSpreadTbps; //parameter: minimal spread between long and short perpetual price
        uint16 incentiveSpreadTbps; //parameter: maximum spread added to the PD
        uint16 jumpSpreadTbps; // spread that is adjusted based on price jumps
        uint16 liquidationPenaltyRateTbps; //parameter: penalty if AMM closes the position and not the trader
        int32 fSigma3; // parameter: volatility of quanto-quote pair
        bytes4 S2BaseCCY; //base currency of S2
        bytes4 S2QuoteCCY; //quote currency of S2
        bytes4 S3BaseCCY; //base currency of S3
        bytes4 S3QuoteCCY; //quote currency of S3
        //-------
        OraclePriceData currentMarkPremiumRate; //relative diff to index price EMA, used for markprice.
        //-------
        int128[2] fDFLambda; // parameter: EMA lambda for AMM and trader exposure K,k: EMA*lambda + (1-lambda)*K. 0 regular lambda, 1 if current value exceeds past
        int128[2] fCurrentAMMExposureEMA; // 0: negative aggregated exposure (storing negative value), 1: positive
        int128[2] fAMMTargetDD; // parameter: target distance to default (=inverse of default probability), [0] baseline [1] stress
        int128[2] fStressReturnS2; // parameter: negative and positive stress returns for base-quote asset
        int128[2] fStressReturnS3; // parameter: negative and positive stress returns for quanto-quote asset
        //-------
        int128 premiumRatesEMA; // EMA of premium rate
        int128 fTargetDFSize; // target default fund size
        //-------
        int128 fFundAllocationWeightCC; // state: current unnormalized weight for this perpetual during allocation of funds from the PnL pool
        int128 fOpenInterest; //open interest is the amount of long positions in base currency or, equiv., the amount of short positions.
        //-------
        int128 fTargetAMMFundSize; //target AMM fund size
        int128 fCurrentTraderExposureEMA; // trade amounts (storing absolute value)
        //-------
        int128 fCurrentFundingRate; // current instantaneous funding rate
        int128 fUnitAccumulatedFunding; //accumulated funding in collateral currency
        //-------
        int128 fLotSizeBC; //parameter: minimal trade unit (in base currency) to avoid dust positions
        int128 fkStar; // signed trade size that minimizes the AMM risk
        //-------
        int128 fAMMFundCashCC; // fund-cash in this perpetual - not margin
        int128 fAMMMinSizeCC; // parameter: minimal size of AMM pool, regardless of current exposure
        //-------
        int128 fMinimalTraderExposureEMA; // parameter: minimal value for fCurrentTraderExposureEMA that we don't want to undershoot
        int128 fMinimalAMMExposureEMA; // parameter: minimal value for fCurrentTraderExposureEMA that we don't want to undershoot
        //-------
        //-------
        int128 fTotalMarginBalance; //calculated for settlement, in collateral currency
        int128 fSettlementS3PriceData; //quanto index
        //-------
        int128 fReferralRebateCC; //parameter: referall rebate in collateral currency
        int128 fSettlementS2PriceData; //base-quote pair. Used as last price in normal state.
        //-------
        uint64 iLastPriceJumpTimestamp; // timestamp when last price jump happened
        uint64 iLastDefaultFundTransfer; // state: timestamp in seconds. Last time we transferred from the DF into this perp's AMM pool
        uint64 iLastTargetPoolSizeTime; //timestamp (seconds) since last update of fTargetDFSize and fTargetAMMFundSize
        int32 fMarkPriceEMALambda; // parameter: Lambda parameter for EMA used in mark-price for funding rates
        int32 fFundingRateClamp; // parameter: funding rate clamp between which we charge 1bps
        //-------
        int32 fMaximalTradeSizeBumpUp; // parameter: >1, users can create a maximal position of size fMaximalTradeSizeBumpUp*fCurrentAMMExposureEMA
        int32 fRho23; // parameter: correlation of quanto/base returns
        int32 fDFCoverNRate; // parameter: cover-n rule for default fund. E.g., fDFCoverNRate=0.05 -> we try to cover 5% of active accounts with default fund
        // -----
    }

    address internal oracleFactoryAddress;

    // users
    mapping(uint24 => EnumerableSetUpgradeable.AddressSet) internal activeAccounts; //perpetualId => traderAddressSet
    // accounts
    mapping(uint24 => mapping(address => MarginAccount)) internal marginAccounts;

    // broker maps: poolId -> brokeraddress-> lots contributed
    // contains non-zero entries for brokers. Brokers pay default fund contributions.
    mapping(uint8 => mapping(address => uint32)) internal brokerMap;

    struct LiquidityPoolData {
        bool isRunning; // state
        uint8 iPerpetualCount; // state
        uint8 id; // parameter: index, starts from 1
        uint16 iTargetPoolSizeUpdateTime; //parameter: timestamp in seconds. How often we update the pool's target size
        address marginTokenAddress; //parameter: address of the margin token
        // -----
        int128 fFundAllocationNormalizationCC; // state: sum of all perpetual weights during fund allocation (cheaper than re-normalizing w/each trade)
        int128 fDefaultFundCashCC; // state: profit/loss
        // -----
        uint64 prevAnchor; // state: keep track of timestamp since last withdrawal was initiated
        int32 fRedemptionRate; // state: used for settlement in case of AMM default
        address shareTokenAddress; // parameter
        // -----
        int128 fPnLparticipantsCashCC; // state: addLiquidity/withdrawLiquidity + profit/loss - rebalance
        int128 fAMMFundCashCC; // state: profit/loss - rebalance (sum of cash in individual perpetuals)
        // -----
        int128 fTargetAMMFundSize; // state: target AMM pool size for all perpetuals in pool (sum)
        int128 fTargetDFSize; // state: target default fund size for all perpetuals in pool
        // -----
        int128 fMaxTransferPerConvergencePeriod; // param: how many funds can be transferred in FUND_TRANSFER_CONVERGENCE_HOURS hours
        int128 fBrokerCollateralLotSize; // param:how much collateral do brokers deposit when providing "1 lot" (not trading lot)
        // -----
        uint128 prevTokenAmount; // state
        uint128 nextTokenAmount; // state
        // -----
        uint128 totalSupplyShareToken; // state
    }

    address treasuryAddress; // address for the protocol treasury

    //pool id => perpetual id list
    mapping(uint8 => uint24[]) internal perpetualIds;

    //pool id => perpetual id => data
    mapping(uint8 => mapping(uint24 => PerpetualData)) internal perpetuals;

    /// @dev flag whether MarginTradeOrder was already executed
    mapping(bytes32 => bool) internal executedOrders;

    /// @dev flag whether MarginTradeOrder was canceled
    mapping(bytes32 => bool) internal canceledOrders;

    //proxy
    mapping(bytes32 => EnumerableBytes4Set.Bytes4Set) internal moduleActiveFuncSignatureList;
    mapping(bytes32 => address) internal moduleNameToAddress;
    mapping(address => bytes32) internal moduleAddressToModuleName;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./IPerpetualOrder.sol";

/**
 * @notice  The libraryEvents defines events that will be raised from modules (contract/modules).
 * @dev     DO REMEMBER to add new events in modules here.
 */
interface ILibraryEvents {
    // PerpetualModule
    event Clear(uint24 indexed perpetualId, address indexed trader);
    event Settle(uint24 indexed perpetualId, address indexed trader, int256 amount);
    event SetNormalState(uint24 indexed perpetualId);
    event SetEmergencyState(
        uint24 indexed perpetualId,
        int128 fSettlementMarkPremiumRate,
        int128 fSettlementS2Price,
        int128 fSettlementS3Price
    );
    event SetClearedState(uint24 indexed perpetualId);
    event UpdateUnitAccumulatedFunding(uint24 perpetualId, int128 unitAccumulativeFunding);

    // Participation pool
    event LiquidityAdded(
        uint64 indexed poolId,
        address indexed user,
        uint256 tokenAmount,
        uint256 shareAmount
    );
    event LiquidityRemoved(
        uint64 indexed poolId,
        address indexed user,
        uint256 tokenAmount,
        uint256 shareAmount
    );
    event LiquidityWithdrawalInitiated(
        uint64 indexed poolId,
        address indexed user,
        uint256 shareAmount
    );
    event PricingLiquidityUpdated(
        uint64 indexed poolId,
        int128 pricingLiquidity,
        int128 totalLiquidity
    );

    // setters
    // oracles
    event SetOracles(uint24 indexed perpetualId, bytes4[2] baseQuoteS2, bytes4[2] baseQuoteS3);
    // perp parameters
    event SetPerpetualBaseParameters(uint24 indexed perpetualId, int128[7] baseParams);
    event SetPerpetualRiskParameters(
        uint24 indexed perpetualId,
        int128[5] underlyingRiskParams,
        int128[13] defaultFundRiskParams
    );
    event SetParameter(uint24 indexed perpetualId, string name, int128 value);
    event SetParameterPair(uint24 indexed perpetualId, string name, int128 value1, int128 value2);
    // pool parameters
    event SetPoolParameter(uint8 indexed poolId, string name, int128 value);

    event TransferAddressTo(string name, address oldOBFactory, address newOBFactory); // only governance
    event SetBlockDelay(uint8 delay);

    // fee structure parameters
    event SetBrokerDesignations(uint32[] designations, uint16[] fees);
    event SetBrokerTiers(uint256[] tiers, uint16[] feesTbps);
    event SetTraderTiers(uint256[] tiers, uint16[] feesTbps);
    event SetTraderVolumeTiers(uint256[] tiers, uint16[] feesTbps);
    event SetBrokerVolumeTiers(uint256[] tiers, uint16[] feesTbps);
    event SetUtilityToken(address tokenAddr);

    event BrokerLotsTransferred(
        uint8 indexed poolId,
        address oldOwner,
        address newOwner,
        uint32 numLots
    );
    event BrokerVolumeTransferred(
        uint8 indexed poolId,
        address oldOwner,
        address newOwner,
        int128 fVolume
    );

    // funds
    event UpdateAMMFundCash(
        uint24 indexed perpetualId,
        int128 fNewAMMFundCash,
        int128 fNewLiqPoolTotalAMMFundsCash
    );
    event UpdateParticipationFundCash(
        uint8 indexed poolId,
        int128 fDeltaAmountCC,
        int128 fNewFundCash
    );
    event UpdateDefaultFundCash(uint8 indexed poolId, int128 fDeltaAmountCC, int128 fNewFundCash);

    // brokers
    event UpdateBrokerAddedCash(uint8 indexed poolId, uint32 iLots, uint32 iNewBrokerLots);

    // TradeModule

    event Trade(
        uint24 indexed perpetualId,
        address indexed trader,
        bytes16 indexed positionId,
        IPerpetualOrder.Order order,
        bytes32 orderDigest,
        int128 newPositionSizeBC,
        int128 price,
        int128 fFeeCC,
        int128 fPnlCC
    );

    event UpdateMarginAccount(
        uint24 indexed perpetualId,
        address indexed trader,
        bytes16 indexed positionId,
        int128 fPositionBC,
        int128 fCashCC,
        int128 fLockedInValueQC,
        int128 fFundingPaymentCC,
        int128 fOpenInterestBC
    );

    event Liquidate(
        uint24 perpetualId,
        address indexed liquidator,
        address indexed trader,
        bytes16 indexed positionId,
        int128 amountLiquidatedBC,
        int128 liquidationPrice,
        int128 newPositionSizeBC,
        int128 fFeeCC,
        int128 fPnlCC
    );

    event TransferFeeToReferrer(
        uint24 indexed perpetualId,
        address indexed trader,
        address indexed referrer,
        int128 referralRebate
    );
    event TransferFeeToBroker(uint24 indexed perpetualId, address indexed broker, int128 feeCC);

    event PerpetualLimitOrderCancelled(uint24 indexed perpetualId, bytes32 indexed orderHash);
    event DistributeFees(
        uint8 indexed poolId,
        uint24 indexed perpetualId,
        address indexed trader,
        int128 protocolFeeCC,
        int128 participationFundFeeCC
    );

    // PerpetualManager/factory
    event RunLiquidityPool(uint8 _liqPoolID);
    event LiquidityPoolCreated(
        uint8 id,
        address marginTokenAddress,
        address shareTokenAddress,
        uint16 iTargetPoolSizeUpdateTime,
        int128 fMaxTransferPerConvergencePeriod,
        int128 fBrokerCollateralLotSize
    );
    event PerpetualCreated(
        uint8 poolId,
        uint24 id,
        int128[7] baseParams,
        int128[5] underlyingRiskParams,
        int128[13] defaultFundRiskParams,
        uint256 eCollateralCurrency
    );

    // emit tokenAddr==0x0 if the token paid is the aggregated token, otherwise the address of the token
    event TokensDeposited(uint24 indexed perpetualId, address indexed trader, int128 amount);
    event TokensWithdrawn(uint24 indexed perpetualId, address indexed trader, int128 amount);

    event UpdateMarkPrice(
        uint24 indexed perpetualId,
        int128 fMidPricePremium,
        int128 fMarkPricePremium,
        int128 fSpotIndexPrice
    );

    event UpdateFundingRate(uint24 indexed perpetualId, int128 fFundingRate);

    event UpdateAMMFundTargetSize(
        uint24 indexed perpetualId,
        uint8 indexed liquidityPoolId,
        int128 fAMMFundCashCCInPerpetual,
        int128 fTargetAMMFundSizeInPerpetual,
        int128 fAMMFundCashCCInPool,
        int128 fTargetAMMFundSizeInPool
    );

    event UpdateDefaultFundTargetSize(
        uint8 indexed liquidityPoolId,
        int128 fDefaultFundCashCC,
        int128 fTargetDFSize
    );

    event UpdateReprTradeSizes(
        uint24 indexed perpetualId,
        int128 fCurrentTraderExposureEMA,
        int128 fCurrentAMMExposureEMAShort,
        int128 fCurrentAMMExposureEMALong
    );

    event TransferEarningsToTreasury(uint8 _poolId, int128 fEarnings, int128 newDefaultFundSize);

    event UpdateFundAllocationWeight(
        uint8 poolId,
        uint24 indexed perpetualId,
        int128 fNormalizedPerpetualWeight
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "../interfaces/IPerpetualOrder.sol";
import "../../interface/ISpotOracle.sol";

interface IPerpetualBrokerFeeLogic {
    function determineExchangeFee(IPerpetualOrder.Order memory _order)
        external
        view
        returns (uint16);

    function updateVolumeEMAOnNewTrade(
        uint24 _iPerpetualId,
        address _traderAddr,
        address _brokerAddr,
        int128 _tradeAmountBC
    ) external;

    function queryExchangeFee(
        uint8 _poolId,
        address _traderAddr,
        address _brokerAddr
    ) external view returns (uint16);

    function splitProtocolFee(uint16 fee) external pure returns (int128, int128);

    function setFeesForDesignation(uint32[] calldata _designations, uint16[] calldata _fees)
        external;

    function getLastPerpetualBaseToUSDConversion(uint24 _iPerpetualId)
        external
        view
        returns (int128);

    function getFeeForTraderVolume(uint8 _poolId, address _traderAddr)
        external
        view
        returns (uint16);

    function getFeeForBrokerVolume(uint8 _poolId, address _brokerAddr)
        external
        view
        returns (uint16);

    function setOracleForPerpetual(uint24 _iPerpetualId, address _oracleAddr) external;

    function setBrokerTiers(uint256[] calldata _tiers, uint16[] calldata _feesTbps) external;

    function setTraderTiers(uint256[] calldata _tiers, uint16[] calldata _feesTbps) external;

    function setTraderVolumeTiers(uint256[] calldata _tiers, uint16[] calldata _feesTbps) external;

    function setBrokerVolumeTiers(uint256[] calldata _tiers, uint16[] calldata _feesTbps) external;

    function setUtilityTokenAddr(address tokenAddr) external;

    function getBrokerInducedFee(uint8 _poolId, address _brokerAddr)
        external
        view
        returns (uint16);

    function getBrokerDesignation(uint8 _poolId, address _brokerAddr)
        external
        view
        returns (uint32);

    function getFeeForBrokerDesignation(uint32 _brokerDesignation) external view returns (uint16);

    function getFeeForBrokerStake(address brokerAddr) external view returns (uint16);

    function getFeeForTraderStake(address traderAddr) external view returns (uint16);

    function getCurrentTraderVolume(uint8 _poolId, address _traderAddr)
        external
        view
        returns (int128);

    function getCurrentBrokerVolume(uint8 _poolId, address _brokerAddr)
        external
        view
        returns (int128);

    function transferBrokerLots(
        uint8 _poolId,
        address _transferToAddr,
        uint32 _lots
    ) external;

    function transferBrokerOwnership(uint8 _poolId, address _transferToAddr) external;

    function setInitialVolumeForFee(
        uint8 _poolId,
        address _brokerAddr,
        uint16 _feeTbps
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPerpetualRebalanceLogic {
    function rebalance(uint24 _iPerpetualId) external;

    function decreasePoolCash(uint8 _iPoolIdx, int128 _fAmount) external;

    function increasePoolCash(uint8 _iPoolIdx, int128 _fAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPerpetualUpdateLogic {
    function updateAMMTargetFundSize(uint24 _iPerpetualId, int128 fTargetFundSize) external;

    function updateDefaultFundTargetSizeRandom(uint8 _iPoolIndex) external;

    function updateDefaultFundTargetSize(uint24 _iPerpetualId) external;

    function updateFundingAndPricesBefore(uint24 _iPerpetualId0, uint24 _iPerpetualId1) external;

    function updateFundingAndPricesAfter(uint24 _iPerpetualId0, uint24 _iPerpetualId1) external;

    function setNormalState(uint24 _iPerpetualId) external;

    function setInitialFundAllocationWeight(uint24 _iPerpetualId) external;

    /**
     * Set emergency state
     * @param _iPerpetualId Perpetual id
     */
    function setEmergencyState(uint24 _iPerpetualId) external;

    /**
     * @notice Set external treasury (DAO)
     * @param _treasury treasury address
     */
    function setTreasury(address _treasury) external;

    /**
     * @notice Set order book factory (DAO)
     * @param _orderBookFactory order book factory address
     */
    function setOrderBookFactory(address _orderBookFactory) external;

    /**
     * @notice Set oracle factory (DAO)
     * @param _oracleFactory oracle factory address
     */
    function setOracleFactory(address _oracleFactory) external;

    /**
     * @notice Set delay for trades to be executed
     * @param _delay    delay in number of blocks
     */
    function setBlockDelay(uint8 _delay) external;

    /**
     * @notice Submits price updates to the feeds used by a given perpetual.
     * @dev Reverts if the submission does not match the perpetual or
     * if the feed rejects it for a reason other than being unnecessary.
     * If this function returns false, sender is not charged msg.value.
     * @param _perpetualId Perpetual Id
     * @param _updateData Data to send to price feeds
     * @param _publishTimes Publish timestamps
     * @param _maxAcceptableFeedAge Maximum age of update in seconds
     */
    function updatePriceFeeds(
        uint24 _perpetualId,
        bytes[] calldata _updateData,
        uint64[] calldata _publishTimes,
        uint256 _maxAcceptableFeedAge
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPerpetualTreasury {
    function addLiquidity(uint8 _iPoolIndex, uint256 _tokenAmount) external;

    function addAMMLiquidityToPerpetual(uint24 _iPerpetualId, int128 _fTokenAmount) external;

    function withdrawLiquidity(uint8 _iPoolIndex, uint256 _shareAmount) external;

    function executeLiquidityWithdrawal(uint8 _poolId) external;

    function getCollateralTokenAmountForPricing(uint8 _poolId) external view returns (int128);

    function getTokenAmountToReturn(uint8 _poolId, uint256 _shareAmount)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity 0.8.17;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt(int256 x) internal pure returns (int128) {
        require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF, "ABDK.fromInt");
        return int128(x << 64);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt(int128 x) internal pure returns (int64) {
        return int64(x >> 64);
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        require(x <= 0x7FFFFFFFFFFFFFFF, "ABDK.fromUInt");
        return int128(int256(x << 64));
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        require(x >= 0, "ABDK.toUInt");
        return uint64(uint128(x >> 64));
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function from128x128(int256 x) internal pure returns (int128) {
        int256 result = x >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.from128x128");
        return int128(result);
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 128.128 fixed point number
     */
    function to128x128(int128 x) internal pure returns (int256) {
        return int256(x) << 64;
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function add(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) + y;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.add");
        return int128(result);
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sub(int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) - y;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.sub");
        return int128(result);
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        int256 result = (int256(x) * y) >> 64;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.mul");
        return int128(result);
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y signed 256-bit integer number
     * @return signed 256-bit integer number
     */
    function muli(int128 x, int256 y) internal pure returns (int256) {
        if (x == MIN_64x64) {
            require(
                y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
                    y <= 0x1000000000000000000000000000000000000000000000000,
                "ABDK.muli-1"
            );
            return -y << 63;
        } else {
            bool negativeResult = false;
            if (x < 0) {
                x = -x;
                negativeResult = true;
            }
            if (y < 0) {
                y = -y;
                // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint256 absoluteResult = mulu(x, uint256(y));
            if (negativeResult) {
                require(
                    absoluteResult <=
                        0x8000000000000000000000000000000000000000000000000000000000000000,
                    "ABDK.muli-2"
                );
                return -int256(absoluteResult);
                // We rely on overflow behavior here
            } else {
                require(
                    absoluteResult <=
                        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                    "ABDK.muli-3"
                );
                return int256(absoluteResult);
            }
        }
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) return 0;

        require(x >= 0, "ABDK.mulu-1");

        uint256 lo = (uint256(int256(x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
        uint256 hi = uint256(int256(x)) * (y >> 128);

        require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "ABDK.mulu-2");
        hi <<= 64;

        require(
            hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo,
            "ABDK.mulu-3"
        );
        return hi + lo;
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function div(int128 x, int128 y) internal pure returns (int128) {
        require(y != 0, "ABDK.div-1");
        int256 result = (int256(x) << 64) / y;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.div-2");
        return int128(result);
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
     * @param y signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divi(int256 x, int256 y) internal pure returns (int128) {
        require(y != 0, "ABDK.divi-1");

        bool negativeResult = false;
        if (x < 0) {
            x = -x;
            // We rely on overflow behavior here
            negativeResult = true;
        }
        if (y < 0) {
            y = -y;
            // We rely on overflow behavior here
            negativeResult = !negativeResult;
        }
        uint128 absoluteResult = divuu(uint256(x), uint256(y));
        if (negativeResult) {
            require(absoluteResult <= 0x80000000000000000000000000000000, "ABDK.divi-2");
            return -int128(absoluteResult);
            // We rely on overflow behavior here
        } else {
            require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "ABDK.divi-3");
            return int128(absoluteResult);
            // We rely on overflow behavior here
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        require(y != 0, "ABDK.divu-1");
        uint128 result = divuu(x, y);
        require(result <= uint128(MAX_64x64), "ABDK.divu-2");
        return int128(result);
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function neg(int128 x) internal pure returns (int128) {
        require(x != MIN_64x64, "ABDK.neg");
        return -x;
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs(int128 x) internal pure returns (int128) {
        require(x != MIN_64x64, "ABDK.abs");
        return x < 0 ? -x : x;
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function inv(int128 x) internal pure returns (int128) {
        require(x != 0, "ABDK.inv-1");
        int256 result = int256(0x100000000000000000000000000000000) / x;
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.inv-2");
        return int128(result);
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function avg(int128 x, int128 y) internal pure returns (int128) {
        return int128((int256(x) + int256(y)) >> 1);
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        int256 m = int256(x) * int256(y);
        require(m >= 0, "ABDK.gavg-1");
        require(
            m < 0x4000000000000000000000000000000000000000000000000000000000000000,
            "ABDK.gavg-2"
        );
        return int128(sqrtu(uint256(m)));
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y uint256 value
     * @return signed 64.64-bit fixed point number
     */
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        bool negative = x < 0 && y & 1 == 1;

        uint256 absX = uint128(x < 0 ? -x : x);
        uint256 absResult;
        absResult = 0x100000000000000000000000000000000;

        if (absX <= 0x10000000000000000) {
            absX <<= 63;
            while (y != 0) {
                if (y & 0x1 != 0) {
                    absResult = (absResult * absX) >> 127;
                }
                absX = (absX * absX) >> 127;

                if (y & 0x2 != 0) {
                    absResult = (absResult * absX) >> 127;
                }
                absX = (absX * absX) >> 127;

                if (y & 0x4 != 0) {
                    absResult = (absResult * absX) >> 127;
                }
                absX = (absX * absX) >> 127;

                if (y & 0x8 != 0) {
                    absResult = (absResult * absX) >> 127;
                }
                absX = (absX * absX) >> 127;

                y >>= 4;
            }

            absResult >>= 64;
        } else {
            uint256 absXShift = 63;
            if (absX < 0x1000000000000000000000000) {
                absX <<= 32;
                absXShift -= 32;
            }
            if (absX < 0x10000000000000000000000000000) {
                absX <<= 16;
                absXShift -= 16;
            }
            if (absX < 0x1000000000000000000000000000000) {
                absX <<= 8;
                absXShift -= 8;
            }
            if (absX < 0x10000000000000000000000000000000) {
                absX <<= 4;
                absXShift -= 4;
            }
            if (absX < 0x40000000000000000000000000000000) {
                absX <<= 2;
                absXShift -= 2;
            }
            if (absX < 0x80000000000000000000000000000000) {
                absX <<= 1;
                absXShift -= 1;
            }

            uint256 resultShift;
            while (y != 0) {
                require(absXShift < 64, "ABDK.pow-1");

                if (y & 0x1 != 0) {
                    absResult = (absResult * absX) >> 127;
                    resultShift += absXShift;
                    if (absResult > 0x100000000000000000000000000000000) {
                        absResult >>= 1;
                        resultShift += 1;
                    }
                }
                absX = (absX * absX) >> 127;
                absXShift <<= 1;
                if (absX >= 0x100000000000000000000000000000000) {
                    absX >>= 1;
                    absXShift += 1;
                }

                y >>= 1;
            }

            require(resultShift < 64, "ABDK.pow-2");
            absResult >>= 64 - resultShift;
        }
        int256 result = negative ? -int256(absResult) : int256(absResult);
        require(result >= MIN_64x64 && result <= MAX_64x64, "ABDK.pow-3");
        return int128(result);
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sqrt(int128 x) internal pure returns (int128) {
        require(x >= 0, "ABDK.sqrt");
        return int128(sqrtu(uint256(int256(x)) << 64));
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        require(x > 0, "ABDK.log_2");

        int256 msb;
        int256 xc = x;
        if (xc >= 0x10000000000000000) {
            xc >>= 64;
            msb += 64;
        }
        if (xc >= 0x100000000) {
            xc >>= 32;
            msb += 32;
        }
        if (xc >= 0x10000) {
            xc >>= 16;
            msb += 16;
        }
        if (xc >= 0x100) {
            xc >>= 8;
            msb += 8;
        }
        if (xc >= 0x10) {
            xc >>= 4;
            msb += 4;
        }
        if (xc >= 0x4) {
            xc >>= 2;
            msb += 2;
        }
        if (xc >= 0x2) msb += 1;
        // No need to shift xc anymore

        int256 result = (msb - 64) << 64;
        uint256 ux = uint256(int256(x)) << uint256(127 - msb);
        for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
            ux *= ux;
            uint256 b = ux >> 255;
            ux >>= 127 + b;
            result += bit * int256(b);
        }

        return int128(result);
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0, "ABDK.ln");

            return
                int128(
                    int256((uint256(int256(log_2(x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128)
                );
        }
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2(int128 x) internal pure returns (int128) {
        require(x < 0x400000000000000000, "ABDK.exp_2-1");
        // Overflow

        if (x < -0x400000000000000000) return 0;
        // Underflow

        uint256 result = 0x80000000000000000000000000000000;

        if (x & 0x8000000000000000 > 0)
            result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
        if (x & 0x4000000000000000 > 0)
            result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
        if (x & 0x2000000000000000 > 0)
            result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
        if (x & 0x1000000000000000 > 0)
            result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
        if (x & 0x800000000000000 > 0)
            result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
        if (x & 0x400000000000000 > 0)
            result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
        if (x & 0x200000000000000 > 0)
            result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
        if (x & 0x100000000000000 > 0)
            result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
        if (x & 0x80000000000000 > 0)
            result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
        if (x & 0x40000000000000 > 0)
            result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
        if (x & 0x20000000000000 > 0)
            result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
        if (x & 0x10000000000000 > 0)
            result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
        if (x & 0x8000000000000 > 0)
            result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
        if (x & 0x4000000000000 > 0)
            result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
        if (x & 0x2000000000000 > 0)
            result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
        if (x & 0x1000000000000 > 0)
            result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
        if (x & 0x800000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
        if (x & 0x400000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
        if (x & 0x200000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
        if (x & 0x100000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
        if (x & 0x80000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
        if (x & 0x40000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
        if (x & 0x20000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
        if (x & 0x10000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
        if (x & 0x8000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
        if (x & 0x4000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
        if (x & 0x2000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
        if (x & 0x1000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
        if (x & 0x800000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
        if (x & 0x400000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
        if (x & 0x200000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
        if (x & 0x100000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
        if (x & 0x80000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
        if (x & 0x40000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
        if (x & 0x20000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
        if (x & 0x10000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
        if (x & 0x8000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
        if (x & 0x4000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
        if (x & 0x2000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
        if (x & 0x1000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
        if (x & 0x800000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
        if (x & 0x400000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
        if (x & 0x200000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
        if (x & 0x100000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
        if (x & 0x80000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
        if (x & 0x40000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
        if (x & 0x20000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
        if (x & 0x10000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
        if (x & 0x8000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
        if (x & 0x4000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
        if (x & 0x2000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
        if (x & 0x1000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
        if (x & 0x800 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
        if (x & 0x400 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
        if (x & 0x200 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
        if (x & 0x100 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
        if (x & 0x80 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
        if (x & 0x40 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
        if (x & 0x20 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
        if (x & 0x10 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
        if (x & 0x8 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
        if (x & 0x4 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
        if (x & 0x2 > 0) result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
        if (x & 0x1 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;

        result >>= uint256(int256(63 - (x >> 64)));
        require(result <= uint256(int256(MAX_64x64)), "ABDK.exp_2-2");

        return int128(int256(result));
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp(int128 x) internal pure returns (int128) {
        require(x < 0x400000000000000000, "ABDK.exp");
        // Overflow

        if (x < -0x400000000000000000) return 0;
        // Underflow

        return exp_2(int128((int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128));
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu(uint256 x, uint256 y) private pure returns (uint128) {
        require(y != 0, "ABDK.divuu-1");

        uint256 result;

        if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) result = (x << 64) / y;
        else {
            uint256 msb = 192;
            uint256 xc = x >> 192;
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1;
            // No need to shift xc anymore

            result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "ABDK.divuu-2");

            uint256 hi = result * (y >> 128);
            uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 xh = x >> 192;
            uint256 xl = x << 64;

            if (xl < lo) xh -= 1;
            xl -= lo;
            // We rely on overflow behavior here
            lo = hi << 128;
            if (xl < lo) xh -= 1;
            xl -= lo;
            // We rely on overflow behavior here

            assert(xh == hi >> 128);

            result += xl / y;
        }

        require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, "ABDK.divuu-3");
        return uint128(result);
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu(uint256 x) private pure returns (uint128) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
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
            r = (r + x / r) >> 1;
            // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128(r < r1 ? r : r1);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "./AbstractOracle.sol";
import "../libraries/ConverterDec18.sol";

/**
 *  Spot oracle has different states:
 *  - is terminated. Price might be returned. In this case the perpetuals will be settled
 *  - market is closed: if explicitely set, the price returns 0
 *  - the price can return 0 at any point in time. This is considered as "market closed" and
 *    must be handled outside the oracle
 */
contract SpotOracle is AbstractOracle {
    using ConverterDec18 for int256;
    using ERC165Checker for address;

    bytes4 private immutable baseCurrency;
    bytes4 private immutable quoteCurrency;

    // @dev either pyth or on-demand, not both at the same time
    address public immutable priceFeed;
    bytes32 public immutable priceId;
    uint256 public immutable feedPeriod;

    uint64 private timestampClosed;

    // if a price is older than tradingBreakMins, the market is considered
    // closed and the price returns zero.
    // For example, if equities trade weekdays from 9am to 5pm, the trading break
    // is 16 hours (from 5pm to 9am) and we could set _tradingBreakMins
    // to 8 hours * 60. For crypto that trades 24/7 we could set it to 1h.
    uint16 private immutable tradingBreakMins;

    bool private marketClosed;
    bool private terminated;

    constructor(
        bytes4 _baseCurrency,
        bytes4 _quoteCurrency,
        uint16 _tradingBreakMins,
        address _priceFeed,
        bytes32 _priceId,
        uint256 _period
    ) {
        require(_tradingBreakMins > 1, "too small");
        require(_priceFeed != address(0), "invalid price feed");
        require(_period < 60 * _tradingBreakMins, "period too long");
        baseCurrency = _baseCurrency;
        quoteCurrency = _quoteCurrency;
        tradingBreakMins = _tradingBreakMins;
        priceFeed = _priceFeed;
        priceId = _priceId;
        feedPeriod = _period;
    }

    /**
     * @dev Sets the market is closed flag.
     */
    function setMarketClosed(bool _marketClosed) external override onlyOwner {
        marketClosed = _marketClosed;
        timestampClosed = uint64(block.timestamp);
    }

    /**
     * @dev The market is closed if the market is not in its regular trading period.
     */
    function isMarketClosed() external view override returns (bool) {
        (int128 price, ) = getSpotPrice();
        return price == 0;
    }

    /**
     * @dev Sets terminated flag.
     */
    function setTerminated(bool _terminated) external override onlyOwner {
        terminated = _terminated;
    }

    /**
     * @dev The oracle service was shutdown and never online again.
     */
    function isTerminated() external view override returns (bool) {
        return terminated;
    }

    /**
     *  Spot price.
     *  Returns 0 if market is closed
     */
    function getSpotPrice() public view virtual override returns (int128 fPrice, uint256 ts) {
        if (marketClosed) {
            return (0, timestampClosed);
        }
        PythStructs.Price memory pythPrice = IPyth(priceFeed).getPriceUnsafe(priceId);
        ts = pythPrice.publishTime;
        // price is zero unless the market on break and feed price is not positive
        if (pythPrice.price > 0 && ts + tradingBreakMins * 60 >= block.timestamp) {
            // price = pythPrice.price * 10 ^ pythPrice.expo;
            int256 priceDec18 = int256(pythPrice.price) * int256(10**uint32(pythPrice.expo + 18));
            fPrice = priceDec18.fromDec18();
        }
    }

    /**
     * Get base currency symbol.
     */
    function getBaseCurrency() external view override returns (bytes4) {
        return baseCurrency;
    }

    /**
     * Get quote currency symbol.
     */
    function getQuoteCurrency() external view override returns (bytes4) {
        return quoteCurrency;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

library PythErrors {
    // Function arguments are invalid (e.g., the arguments lengths mismatch)
    error InvalidArgument();
    // Update data is coming from an invalid data source.
    error InvalidUpdateDataSource();
    // Update data is invalid (e.g., deserialization error)
    error InvalidUpdateData();
    // Insufficient fee is paid to the method.
    error InsufficientFee();
    // There is no fresh update, whereas expected fresh updates.
    error NoFreshUpdate();
    // There is no price feed found within the given range or it does not exists.
    error PriceFeedNotFoundWithinRange();
    // Price feed not found or it is not pushed on-chain yet.
    error PriceFeedNotFound();
    // Requested price is stale.
    error StalePrice();
    // Given message is not a valid Wormhole VAA.
    error InvalidWormholeVaa();
    // Governance message is invalid (e.g., deserialization error).
    error InvalidGovernanceMessage();
    // Governance message is not for this contract.
    error InvalidGovernanceTarget();
    // Governance message is coming from an invalid data source.
    error InvalidGovernanceDataSource();
    // Governance message is old.
    error OldGovernanceMessage();
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interface/ISpotOracle.sol";
import "./OracleInterfaceID.sol";

abstract contract AbstractOracle is Ownable, ERC165Storage, OracleInterfaceID, ISpotOracle {
    constructor() {
        _registerInterface(_getOracleInterfaceID());
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interface/ISpotOracle.sol";

contract OracleInterfaceID {
    function _getOracleInterfaceID() internal pure returns (bytes4) {
        ISpotOracle i;
        return
            i.isMarketClosed.selector ^
            i.isTerminated.selector ^
            i.getSpotPrice.selector ^
            i.getBaseCurrency.selector ^
            i.getQuoteCurrency.selector ^
            i.priceFeed.selector ^
            i.priceId.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

pragma solidity 0.8.17;

interface IShareTokenFactory {
    function createShareToken() external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
// D8X, 2022

pragma solidity ^0.8.17;

/**
 * This is a modified version of the OpenZeppelin ownable contract
 * Modifications
 * - instead of an owner, we have two actors: maintainer and governance
 * - maintainer can have certain priviledges but cannot transfer maintainer mandate
 * - governance can exchange maintainer and exchange itself
 * - renounceOwnership is removed
 *
 *
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
abstract contract Maintainable {
    address private _maintainer;
    address private _governance;

    event MaintainerTransferred(address indexed previousMaintainer, address indexed newMaintainer);
    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);

    /**
     * @dev Initializes the contract setting the deployer as the initial maintainer.
     */
    constructor() {
        _transferMaintainer(msg.sender);
        _transferGovernance(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function maintainer() public view virtual returns (address) {
        return _maintainer;
    }

    /**
     * @dev Returns the address of the governance.
     */
    function governance() public view virtual returns (address) {
        return _governance;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyMaintainer() {
        require(maintainer() == msg.sender, "only maintainer");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGovernance() {
        require(governance() == msg.sender, "only governance");
        _;
    }

    /**
     * @dev Transfers maintainer mandate of the contract to a new account (`newMaintainer`).
     * Can only be called by the governance.
     */
    function transferMaintainer(address newMaintainer) public virtual {
        require(msg.sender == _governance, "only governance");
        require(newMaintainer != address(0), "zero address");
        _transferMaintainer(newMaintainer);
    }

    /**
     * @dev Transfers governance mandate of the contract to a new account (`newGovernance`).
     * Can only be called by the governance.
     */
    function transferGovernance(address newGovernance) public virtual {
        require(msg.sender == _governance, "only governance");
        require(newGovernance != address(0), "zero address");
        _transferGovernance(newGovernance);
    }

    /**
     * @dev Transfers maintainer of the contract to a new account (`newMaintainer`).
     * Internal function without access restriction.
     */
    function _transferMaintainer(address newMaintainer) internal virtual {
        address oldM = _maintainer;
        _maintainer = newMaintainer;
        emit MaintainerTransferred(oldM, newMaintainer);
    }

    /**
     * @dev Transfers governance of the contract to a new account (`newGovernance`).
     * Internal function without access restriction.
     */
    function _transferGovernance(address newGovernance) internal virtual {
        address oldG = _governance;
        _governance = newGovernance;
        emit GovernanceTransferred(oldG, newGovernance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title Library for managing loan sets.
 *
 * @notice Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * Include with `using EnumerableBytes4Set for EnumerableBytes4Set.Bytes4Set;`.
 * */
library EnumerableBytes4Set {
    struct Bytes4Set {
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes4 => uint256) index;
        bytes4[] values;
    }

    /**
     * @notice Add an address value to a set. O(1).
     *
     * @param set The set of values.
     * @param addrvalue The address to add.
     *
     * @return False if the value was already in the set.
     */
    function addAddress(Bytes4Set storage set, address addrvalue) internal returns (bool) {
        bytes4 value;
        assembly {
            value := addrvalue
        }
        return addBytes4(set, value);
    }

    /**
     * @notice Add a value to a set. O(1).
     *
     * @param set The set of values.
     * @param value The new value to add.
     *
     * @return False if the value was already in the set.
     */
    function addBytes4(Bytes4Set storage set, bytes4 value) internal returns (bool) {
        if (!contains(set, value)) {
            set.values.push(value);
            set.index[value] = set.values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Remove an address value from a set. O(1).
     *
     * @param set The set of values.
     * @param addrvalue The address to remove.
     *
     * @return False if the address was not present in the set.
     */
    function removeAddress(Bytes4Set storage set, address addrvalue) internal returns (bool) {
        bytes4 value;
        assembly {
            value := addrvalue
        }
        return removeBytes4(set, value);
    }

    /**
     * @notice Remove a value from a set. O(1).
     *
     * @param set The set of values.
     * @param value The value to remove.
     *
     * @return False if the value was not present in the set.
     */
    function removeBytes4(Bytes4Set storage set, bytes4 value) internal returns (bool) {
        if (contains(set, value)) {
            uint256 toDeleteIndex = set.index[value] - 1;
            uint256 lastIndex = set.values.length - 1;

            /// If the element we're deleting is the last one,
            /// we can just remove it without doing a swap.
            if (lastIndex != toDeleteIndex) {
                bytes4 lastValue = set.values[lastIndex];

                /// Move the last value to the index where the deleted value is.
                set.values[toDeleteIndex] = lastValue;

                /// Update the index for the moved value.
                set.index[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            }

            /// Delete the index entry for the deleted value.
            delete set.index[value];

            /// Delete the old entry for the moved value.
            set.values.pop();

            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Find out whether a value exists in the set.
     *
     * @param set The set of values.
     * @param value The value to find.
     *
     * @return True if the value is in the set. O(1).
     */
    function contains(Bytes4Set storage set, bytes4 value) internal view returns (bool) {
        return set.index[value] != 0;
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function containsAddress(Bytes4Set storage set, address addrvalue)
        internal
        view
        returns (bool)
    {
        bytes4 value;
        assembly {
            value := addrvalue
        }
        return set.index[value] != 0;
    }

    /**
     * @notice Get all set values.
     *
     * @param set The set of values.
     * @param start The offset of the returning set.
     * @param count The limit of number of values to return.
     *
     * @return output An array with all values in the set. O(N).
     *
     * @dev Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * WARNING: This function may run out of gas on large sets: use {length} and
     * {get} instead in these cases.
     */
    function enumerate(
        Bytes4Set storage set,
        uint256 start,
        uint256 count
    ) internal view returns (bytes4[] memory output) {
        uint256 end = start + count;
        require(end >= start, "addition overflow");
        end = set.values.length < end ? set.values.length : end;
        if (end == 0 || start >= end) {
            return output;
        }

        output = new bytes4[](end - start);
        for (uint256 i; i < end - start; i++) {
            output[i] = set.values[i + start];
        }
        return output;
    }

    /**
     * @notice Get the legth of the set.
     *
     * @param set The set of values.
     *
     * @return the number of elements on the set. O(1).
     */
    function length(Bytes4Set storage set) internal view returns (uint256) {
        return set.values.length;
    }

    /**
     * @notice Get an item from the set by its index.
     *
     * @dev Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     *
     * @param set The set of values.
     * @param index The index of the value to return.
     *
     * @return the element stored at position `index` in the set. O(1).
     */
    function get(Bytes4Set storage set, uint256 index) internal view returns (bytes4) {
        return set.values[index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../libraries/ABDKMath64x64.sol";
import "../../libraries/ConverterDec18.sol";
import "../../perpetual/interfaces/IAMMPerpLogic.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AMMPerpLogic is Ownable, IAMMPerpLogic {
    using ABDKMath64x64 for int128;

    int128 internal constant ONE_64x64 = 0x10000000000000000; // 2^64
    int128 internal constant TWO_64x64 = 0x20000000000000000; // 2*2^64
    int128 internal constant FOUR_64x64 = 0x40000000000000000; //4*2^64
    int128 internal constant HALF_64x64 = 0x8000000000000000; //0.5*2^64
    int128 internal constant TWENTY_64x64 = 0x140000000000000000; //20*2^64
    int128 private constant CDF_CONST_0 = 0x023a6ce358298c;
    int128 private constant CDF_CONST_1 = -0x216c61522a6f3f;
    int128 private constant CDF_CONST_2 = 0xc9320d9945b6c3;
    int128 private constant CDF_CONST_3 = -0x01bcfd4bf0995aaf;
    int128 private constant CDF_CONST_4 = -0x086de76427c7c501;
    int128 private constant CDF_CONST_5 = 0x749741d084e83004;
    int128 private constant CDF_CONST_6 = 0xcc42299ea1b28805;
    int128 private constant CDF_CONST_7 = 0x0281b263fec4e0a007;

    enum CollateralCurrency {
        QUOTE,
        BASE,
        QUANTO
    }

    struct AMMVariables {
        // all variables are
        // signed 64.64-bit fixed point number
        int128 fLockedValue1; // L1 in quote currency
        int128 fPoolM1; // M1 in quote currency
        int128 fPoolM2; // M2 in base currency
        int128 fPoolM3; // M3 in quanto currency
        int128 fAMM_K2; // AMM exposure (positive if trader long)
        int128 fCurrentTraderExposureEMA; // current average unsigned trader exposure
    }

    struct MarketVariables {
        int128 fIndexPriceS2; // base index
        int128 fIndexPriceS3; // quanto index
        int128 fSigma2; // standard dev of base currency
        int128 fSigma3; // standard dev of quanto currency
        int128 fRho23; // correlation base/quanto currency
    }

    /**
     * Calculate Exponentially Weighted Moving Average.
     * Returns updated EMA based on
     * _fEMA = _fLambda * _fEMA + (1-_fLambda)* _fCurrentObs
     * @param _fEMA signed 64.64-bit fixed point number
     * @param _fCurrentObs signed 64.64-bit fixed point number
     * @param _fLambda signed 64.64-bit fixed point number
     * @return updated EMA, signed 64.64-bit fixed point number
     */
    function ema(
        int128 _fEMA,
        int128 _fCurrentObs,
        int128 _fLambda
    ) external pure virtual override returns (int128) {
        require(_fLambda > 0, "EMALambda must be gt 0");
        require(_fLambda < ONE_64x64, "EMALambda must be st 1");
        // result must be between the two values _fCurrentObs and _fEMA, so no overflow
        int128 fEWMANew = ABDKMath64x64.add(
            _fEMA.mul(_fLambda),
            ABDKMath64x64.mul(ONE_64x64.sub(_fLambda), _fCurrentObs)
        );
        return fEWMANew;
    }

    /**
     * Calculate a half-spread that depends on past jumps
     * @dev if more than 30 seconds the function returns minimal spread.
     * Accuracy of this is obviously parametrization dependent
     * @param _jumpTbps    jump spread based on return of oracle price
     * @param _MinimalSpreadTbps   minimal spread the EMA converges to
     * @param _numSecSinceJump    time passed since jump
     * @param _fLambda   convergence
     * @return fHalfSpread (int128)
     */
    function volatilitySpread(
        uint16 _jumpTbps,
        uint16 _MinimalSpreadTbps,
        uint256 _numSecSinceJump,
        int128 _fLambda
    ) external pure returns (int128) {
        // v0 = (1-L**numBlocksSinceJump) * minimalSpread
        // v1 = jump*L**numBlocksSinceJump
        // return v0+v1
        if (_numSecSinceJump > 30) {
            return ConverterDec18.tbpsToABDK(_MinimalSpreadTbps);
        }
        return _emaWithTimeJumps(_MinimalSpreadTbps, _jumpTbps, _fLambda, _numSecSinceJump);
    }

    /**
     * Calculate the penalty for closing a position before the holding period is satisfied
     * @dev The penalty is 8 bps for same second and decreases exponentially to 0 at 32 seconds
     * @param _secondsSinceLastOpen how much time passed since the position was opened
     * @param _fLambda lambda for the exponential decay: penalty_nSeconds ~ lambda ^ nSeconds
     * @return penalty Penalty in tbps
     */
    function holdingPeriodPenalty(uint256 _secondsSinceLastOpen, int128 _fLambda)
        external
        pure
        returns (uint16 penalty)
    {
        if (_secondsSinceLastOpen > 32) {
            return 0;
        }
        penalty = ConverterDec18.ABDKToTbps(
            _emaWithTimeJumps(0, 80, _fLambda, _secondsSinceLastOpen)
        );
    }

    /**
     * Calculate a EWMA when the last observation happened n periods ago
     * @dev Given is x_t = (1 - lambda) * mean + lambda * x_t-1, and x_0 = _newObs
     * it returns the value of x_deltaTime
     * @param _mean long term mean
     * @param _newObs observation deltaTime periods ago
     * @param _fLambda lambda of the EWMA
     * @param _deltaTime number of periods elapsed
     * @return result EWMA at deltaPeriods
     */
    function _emaWithTimeJumps(
        uint16 _mean,
        uint16 _newObs,
        int128 _fLambda,
        uint256 _deltaTime
    ) internal pure returns (int128 result) {
        _fLambda = _fLambda.pow(_deltaTime);
        result = ConverterDec18.tbpsToABDK(_mean).mul(ONE_64x64.sub(_fLambda));
        result = result.add(_fLambda.mul(ConverterDec18.tbpsToABDK(_newObs)));
    }

    /**
     *  Calculate the normal CDF value of _fX, i.e.,
     *  k=P(X<=_fX), for X~normal(0,1)
     *  The approximation is of the form
     *  Phi(x) = 1 - phi(x) / (x + exp(p(x))),
     *  where p(x) is a polynomial of degree 6
     *  @param _fX signed 64.64-bit fixed point number
     *  @return fY approximated normal-cdf evaluated at X
     */
    function _normalCDF(int128 _fX) internal pure returns (int128 fY) {
        bool isNegative = _fX < 0;
        if (isNegative) {
            _fX = _fX.neg();
        }
        if (_fX > FOUR_64x64) {
            fY = int128(0);
        } else {
            fY = _fX.mul(CDF_CONST_0).add(CDF_CONST_1);
            fY = _fX.mul(fY).add(CDF_CONST_2);
            fY = _fX.mul(fY).add(CDF_CONST_3);
            fY = _fX.mul(fY).add(CDF_CONST_4);
            fY = _fX.mul(fY).add(CDF_CONST_5).mul(_fX).neg().exp();
            fY = fY.mul(CDF_CONST_6).add(_fX);
            fY = _fX.mul(_fX).mul(HALF_64x64).neg().exp().div(CDF_CONST_7).div(fY);
        }
        if (!isNegative) {
            fY = ONE_64x64.sub(fY);
        }
        return fY;
    }

    /**
     *  Calculate the target size for the default fund
     *
     *  @param _fK2AMM       signed 64.64-bit fixed point number, Conservative negative[0]/positive[1] AMM exposure
     *  @param _fk2Trader    signed 64.64-bit fixed point number, Conservative (absolute) trader exposure
     *  @param _fCoverN      signed 64.64-bit fixed point number, cover-n rule for default fund parameter
     *  @param fStressRet2   signed 64.64-bit fixed point number, negative[0]/positive[1] stress returns for base/quote pair
     *  @param fStressRet3   signed 64.64-bit fixed point number, negative[0]/positive[1] stress returns for quanto/quote currency
     *  @param fIndexPrices  signed 64.64-bit fixed point number, spot price for base/quote[0] and quanto/quote[1] pairs
     *  @param _eCCY         enum that specifies in which currency the collateral is held: QUOTE, BASE, QUANTO
     *  @return approximated normal-cdf evaluated at X
     */
    function calculateDefaultFundSize(
        int128[2] calldata _fK2AMM,
        int128 _fk2Trader,
        int128 _fCoverN,
        int128[2] calldata fStressRet2,
        int128[2] calldata fStressRet3,
        int128[2] calldata fIndexPrices,
        AMMPerpLogic.CollateralCurrency _eCCY
    ) external pure override returns (int128) {
        require(_fK2AMM[0] < 0, "_fK2AMM[0] must be negative");
        require(_fK2AMM[1] > 0, "_fK2AMM[1] must be positive");
        require(_fk2Trader > 0, "_fk2Trader must be positive");

        int128[2] memory fEll;
        // downward stress scenario
        fEll[0] = (_fK2AMM[0].abs().add(_fk2Trader.mul(_fCoverN))).mul(
            ONE_64x64.sub((fStressRet2[0].exp()))
        );
        // upward stress scenario
        fEll[1] = (_fK2AMM[1].abs().add(_fk2Trader.mul(_fCoverN))).mul(
            (fStressRet2[1].exp().sub(ONE_64x64))
        );
        int128 fIstar;
        if (_eCCY == AMMPerpLogic.CollateralCurrency.BASE) {
            fIstar = fEll[0].div(fStressRet2[0].exp());
            int128 fI2 = fEll[1].div(fStressRet2[1].exp());
            if (fI2 > fIstar) {
                fIstar = fI2;
            }
        } else if (_eCCY == AMMPerpLogic.CollateralCurrency.QUANTO) {
            fIstar = fEll[0].div(fStressRet3[0].exp());
            int128 fI2 = fEll[1].div(fStressRet3[1].exp());
            if (fI2 > fIstar) {
                fIstar = fI2;
            }
            fIstar = fIstar.mul(fIndexPrices[0].div(fIndexPrices[1]));
        } else {
            assert(_eCCY == AMMPerpLogic.CollateralCurrency.QUOTE);
            if (fEll[0] > fEll[1]) {
                fIstar = fEll[0].mul(fIndexPrices[0]);
            } else {
                fIstar = fEll[1].mul(fIndexPrices[0]);
            }
        }
        return fIstar;
    }

    /**
     *  Calculate the risk neutral Distance to Default (Phi(DD)=default probability) when
     *  there is no quanto currency collateral.
     *  We assume r=0 everywhere.
     *  The underlying distribution is log-normal, hence the log below.
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param fSigma2 current Market variables (price&params)
     *  @param _fSign signed 64.64-bit fixed point number, sign of denominator of distance to default
     *  @return _fThresh signed 64.64-bit fixed point number, number for which the log is the unnormalized distance to default
     */
    function _calculateRiskNeutralDDNoQuanto(
        int128 fSigma2,
        int128 _fSign,
        int128 _fThresh
    ) internal pure returns (int128) {
        require(_fThresh > 0, "argument to log must be >0");
        int128 _fLogTresh = _fThresh.ln();
        int128 fSigma2_2 = fSigma2.mul(fSigma2);
        int128 fMean = fSigma2_2.div(TWO_64x64).neg();
        int128 fDistanceToDefault = ABDKMath64x64.sub(_fLogTresh, fMean).div(fSigma2);
        // because 1-Phi(x) = Phi(-x) we change the sign if _fSign<0
        // now we would like to get the normal cdf of that beast
        if (_fSign < 0) {
            fDistanceToDefault = fDistanceToDefault.neg();
        }
        return fDistanceToDefault;
    }

    /**
     *  Calculate the standard deviation for the random variable
     *  evolving when quanto currencies are involved.
     *  We assume r=0 everywhere.
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param _mktVars current Market variables (price&params)
     *  @param _fC3 signed 64.64-bit fixed point number current AMM/Market variables
     *  @param _fC3_2 signed 64.64-bit fixed point number, squared fC3
     *  @return fSigmaZ standard deviation, 64.64-bit fixed point number
     */
    function _calculateStandardDeviationQuanto(
        MarketVariables memory _mktVars,
        int128 _fC3,
        int128 _fC3_2
    ) internal pure returns (int128 fSigmaZ) {
        int128 fVarA;
        {
            // fVarA = (exp(sigma2^2) - 1)
            int128 fSigma2_2 = _mktVars.fSigma2.mul(_mktVars.fSigma2);
            fVarA = ABDKMath64x64.sub(fSigma2_2.exp(), ONE_64x64);
        }
        int128 fVarB;
        {
            // fVarB1 = exp(sigma2*sigma3*rho)
            int128 fVarB1 = (_mktVars.fSigma2.mul(_mktVars.fSigma3).mul(_mktVars.fRho23)).exp();
            // fVarB = 2*(exp(sigma2*sigma3*rho) - 1)
            fVarB = ABDKMath64x64.sub(fVarB1, ONE_64x64).mul(TWO_64x64);
        }
        int128 fVarC;
        {
            // fVarC = exp(sigma3^2) - 1
            int128 fSigma3_2 = _mktVars.fSigma3.mul(_mktVars.fSigma3);
            fVarC = ABDKMath64x64.sub(fSigma3_2.exp(), ONE_64x64);
        }
        // sigmaZ = fVarA*C^2 + fVarB*C + fVarC
        fSigmaZ = ABDKMath64x64.add(fVarA.mul(_fC3_2), fVarB.mul(_fC3)).add(fVarC);
        fSigmaZ = fSigmaZ.sqrt();
        return fSigmaZ;
    }

    /**
     *  Calculate the risk neutral Distance to Default (Phi(DD)=default probability) when
     *  presence of quanto currency collateral.
     *
     *  We approximate the distribution with a normal distribution
     *  We assume r=0 everywhere.
     *  All variables are 64.64-bit fixed point number
     *  @param _ammVars current AMM/Market variables
     *  @param _mktVars current Market variables (price&params)
     *  @param _fSign 64.64-bit fixed point number, current AMM/Market variables
     *  @return _fLambdasigned 64.64-bit fixed point number
     */
    function _calculateRiskNeutralDDWithQuanto(
        AMMVariables memory _ammVars,
        MarketVariables memory _mktVars,
        int128 _fSign,
        int128 _fThresh
    ) internal pure returns (int128) {
        require(_fSign > 0, "no sign distinction in quanto case");
        // 1) Calculate C3
        int128 fC3 = _mktVars.fIndexPriceS2.mul(_ammVars.fPoolM2.sub(_ammVars.fAMM_K2)).div(
            _ammVars.fPoolM3.mul(_mktVars.fIndexPriceS3)
        );
        int128 fC3_2 = fC3.mul(fC3);

        // 2) Calculate Variance
        int128 fSigmaZ = _calculateStandardDeviationQuanto(_mktVars, fC3, fC3_2);

        // 3) Calculate mean
        int128 fMean = ABDKMath64x64.add(fC3, ONE_64x64);
        // 4) Distance to default
        int128 fDistanceToDefault = ABDKMath64x64.sub(_fThresh, fMean).div(fSigmaZ);
        return fDistanceToDefault;
    }

    function calculateRiskNeutralPD(
        AMMVariables memory _ammVars,
        MarketVariables calldata _mktVars,
        int128 _fTradeAmount,
        bool _withCDF
    ) external view virtual override returns (int128, int128) {
        return _calculateRiskNeutralPD(_ammVars, _mktVars, _fTradeAmount, _withCDF);
    }

    /**
     *  Calculate the risk neutral default probability (>=0).
     *  Function decides whether pricing with or without quanto CCY is chosen.
     *  We assume r=0 everywhere.
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param _ammVars         current AMM variables.
     *  @param _mktVars         current Market variables (price&params)
     *  @param _fTradeAmount    Trade amount (can be 0), hence amounts k2 are not already factored in
     *                          that is, function will set K2:=K2+k2, L1:=L1+k2*s2 (k2=_fTradeAmount)
     *  @param _withCDF         bool. If false, the normal-cdf is not evaluated (in case the caller is only
     *                          interested in the distance-to-default, this saves calculations)
     *  @return (default probabilit, distance to default) ; 64.64-bit fixed point numbers
     */
    function _calculateRiskNeutralPD(
        AMMVariables memory _ammVars,
        MarketVariables calldata _mktVars,
        int128 _fTradeAmount,
        bool _withCDF
    ) internal pure returns (int128, int128) {
        int128 dL = _fTradeAmount.mul(_mktVars.fIndexPriceS2);
        int128 dK = _fTradeAmount;
        _ammVars.fLockedValue1 = _ammVars.fLockedValue1.add(dL);
        _ammVars.fAMM_K2 = _ammVars.fAMM_K2.add(dK);
        // -L1 - k*s2 - M1
        int128 fNumerator = (_ammVars.fLockedValue1.neg()).sub(_ammVars.fPoolM1);
        // s2*(M2-k2-K2) if no quanto, else M3 * s3
        int128 fDenominator = _ammVars.fPoolM3 == 0
            ? (_ammVars.fPoolM2.sub(_ammVars.fAMM_K2)).mul(_mktVars.fIndexPriceS2)
            : _ammVars.fPoolM3.mul(_mktVars.fIndexPriceS3);

        // handle cases when denominator close to zero
        // or when we have opposite signs (to avoid ln(-|value|))
        // when M3 > 0, denominator is always > 0
        int128 fThresh = fDenominator == 0 ? int128(0) : fNumerator.div(fDenominator);
        if (fThresh <= 0 && _ammVars.fPoolM3 == 0) {
            if (fNumerator <= 0 || (fThresh == 0 && fDenominator > 0)) {
                return (int128(0), TWENTY_64x64.neg());
            } else {
                return (int128(ONE_64x64), TWENTY_64x64);
            }
        }
        // sign tells us whether we consider norm.cdf(f(threshold)) or 1-norm.cdf(f(threshold))
        // we recycle fDenominator to store the sign since it's no longer used
        fDenominator = fDenominator < 0 ? ONE_64x64.neg() : ONE_64x64;
        int128 dd = _ammVars.fPoolM3 == 0
            ? _calculateRiskNeutralDDNoQuanto(_mktVars.fSigma2, fDenominator, fThresh)
            : _calculateRiskNeutralDDWithQuanto(_ammVars, _mktVars, fDenominator, fThresh);

        int128 q;
        if (_withCDF) {
            q = _normalCDF(dd);
        }
        // undo changing the struct
        return (q, dd);
    }

    function calculateBoundedSlippage(AMMVariables calldata _ammVars, int128 _fTradeAmount)
        external
        view
        virtual
        override
        returns (int128)
    {
        return _calculateBoundedSlippage(_ammVars, _fTradeAmount);
    }

    /**
     *  Calculate additional/non-risk based slippage.
     *  Ensures slippage is bounded away from zero for small trades,
     *  and plateaus for larger-than-average trades, so that price becomes risk based.
     *
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param _ammVars current AMM variables - we need the current average exposure per trader
     *  @param _fTradeAmount 64.64-bit fixed point number, signed size of trade
     *  @return 64.64-bit fixed point number, a number between minus one and one
     */
    function _calculateBoundedSlippage(AMMVariables calldata _ammVars, int128 _fTradeAmount)
        internal
        pure
        returns (int128)
    {
        int128 fTradeSizeEMA = _ammVars.fCurrentTraderExposureEMA;
        int128 fSlippageSize = ONE_64x64;
        if (_fTradeAmount.abs() < fTradeSizeEMA) {
            fSlippageSize = fSlippageSize.sub(_fTradeAmount.abs().div(fTradeSizeEMA));
            fSlippageSize = ONE_64x64.sub(fSlippageSize.mul(fSlippageSize));
        }
        return _fTradeAmount > 0 ? fSlippageSize : fSlippageSize.neg();
    }

    /**
     *  Calculate AMM price.
     *
     *  All variables are 64.64-bit fixed point number (or struct thereof)
     *  @param _ammVars current AMM variables.
     *  @param _mktVars current Market variables (price&params)
     *                 Trader amounts k2 must already be factored in
     *                 that is, K2:=K2+k2, L1:=L1+k2*s2
     *  @param _fTradeAmount 64.64-bit fixed point number, signed size of trade
     *  @param _fHBidAskSpread half bid-ask spread, 64.64-bit fixed point number
     *  @return 64.64-bit fixed point number, AMM price
     */
    function calculatePerpetualPrice(
        AMMVariables calldata _ammVars,
        MarketVariables calldata _mktVars,
        int128 _fTradeAmount,
        int128 _fHBidAskSpread,
        int128 _fIncentiveSpread
    ) external view virtual override returns (int128) {
        // add minimal spread in quote currency
        _fHBidAskSpread = _fTradeAmount > 0 ? _fHBidAskSpread : _fHBidAskSpread.neg();
        if (_fTradeAmount == 0) {
            _fHBidAskSpread = 0;
        }
        // get risk-neutral default probability (always >0)
        {
            int128 fQ;
            int128 dd;
            int128 fkStar = _ammVars.fPoolM2.sub(_ammVars.fAMM_K2);
            (fQ, dd) = _calculateRiskNeutralPD(_ammVars, _mktVars, _fTradeAmount, true);
            if (_ammVars.fPoolM3 != 0) {
                // amend K* (see whitepaper)
                int128 nominator = _mktVars.fRho23.mul(_mktVars.fSigma2);
                nominator = nominator.mul(_mktVars.fSigma3).exp().sub(ONE_64x64);
                int128 denom = (_mktVars.fSigma2).mul(_mktVars.fSigma2).exp().sub(ONE_64x64);
                int128 h = nominator.div(denom).mul(_ammVars.fPoolM3);
                h = h.mul(_mktVars.fIndexPriceS3).div(_mktVars.fIndexPriceS2);
                fkStar = fkStar.add(h);
            }
            // decide on sign of premium
            if (_fTradeAmount < fkStar) {
                fQ = fQ.neg();
            }
            _fHBidAskSpread = _fHBidAskSpread.add(fQ);
        }
        // get additional slippage
        if (_fTradeAmount != 0) {
            _fIncentiveSpread = _fIncentiveSpread.mul(
                _calculateBoundedSlippage(_ammVars, _fTradeAmount)
            );
            _fHBidAskSpread = _fHBidAskSpread.add(_fIncentiveSpread);
        }
        // s2*(1 + sign(qp-q)*q + sign(k)*minSpread)
        return _mktVars.fIndexPriceS2.mul(ONE_64x64.add(_fHBidAskSpread));
    }

    /**
     *  Calculate target collateral M1 (Quote Currency), when no M2, M3 is present
     *  The targeted default probability is expressed using the inverse
     *  _fTargetDD = Phi^(-1)(targetPD)
     *  _fK2 in absolute terms must be 'reasonably large'
     *  sigma3, rho23, IndexpriceS3 not relevant.
     *  @param _fK2 signed 64.64-bit fixed point number, !=0, EWMA of actual K.
     *  @param _fL1 signed 64.64-bit fixed point number, >0, EWMA of actual L.
     *  @param  _mktVars contains 64.64 values for fIndexPriceS2*, fIndexPriceS3, fSigma2*, fSigma3, fRho23
     *  @param _fTargetDD signed 64.64-bit fixed point number
     *  @return M1Star signed 64.64-bit fixed point number, >0
     */
    function getTargetCollateralM1(
        int128 _fK2,
        int128 _fL1,
        MarketVariables calldata _mktVars,
        int128 _fTargetDD
    ) external pure virtual override returns (int128) {
        assert(_fK2 != 0);
        assert(_mktVars.fSigma3 == 0);
        assert(_mktVars.fIndexPriceS3 == 0);
        assert(_mktVars.fRho23 == 0);
        int128 fMu2 = HALF_64x64.neg().mul(_mktVars.fSigma2).mul(_mktVars.fSigma2);
        int128 ddScaled = _fK2 < 0
            ? _mktVars.fSigma2.mul(_fTargetDD)
            : _mktVars.fSigma2.mul(_fTargetDD).neg();
        int128 A1 = ABDKMath64x64.exp(fMu2.add(ddScaled));
        return _fK2.mul(_mktVars.fIndexPriceS2).mul(A1).sub(_fL1);
    }

    /**
     *  Calculate target collateral *M2* (Base Currency), when no M1, M3 is present
     *  The targeted default probability is expressed using the inverse
     *  _fTargetDD = Phi^(-1)(targetPD)
     *  _fK2 in absolute terms must be 'reasonably large'
     *  sigma3, rho23, IndexpriceS3 not relevant.
     *  @param _fK2 signed 64.64-bit fixed point number, EWMA of actual K.
     *  @param _fL1 signed 64.64-bit fixed point number, EWMA of actual L.
     *  @param _mktVars contains 64.64 values for fIndexPriceS2, fIndexPriceS3, fSigma2, fSigma3, fRho23
     *  @param _fTargetDD signed 64.64-bit fixed point number
     *  @return M2Star signed 64.64-bit fixed point number
     */
    function getTargetCollateralM2(
        int128 _fK2,
        int128 _fL1,
        MarketVariables calldata _mktVars,
        int128 _fTargetDD
    ) external pure virtual override returns (int128) {
        assert(_fK2 != 0);
        assert(_mktVars.fSigma3 == 0);
        assert(_mktVars.fIndexPriceS3 == 0);
        assert(_mktVars.fRho23 == 0);
        int128 fMu2 = HALF_64x64.mul(_mktVars.fSigma2).mul(_mktVars.fSigma2).neg();
        int128 ddScaled = _fL1 < 0
            ? _mktVars.fSigma2.mul(_fTargetDD)
            : _mktVars.fSigma2.mul(_fTargetDD).neg();
        int128 A1 = ABDKMath64x64.exp(fMu2.add(ddScaled)).mul(_mktVars.fIndexPriceS2);
        return _fK2.sub(_fL1.div(A1));
    }

    /**
     *  Calculate target collateral M3 (Quanto Currency), when no M1, M2 not present
     *
     *  @param _fK2 signed 64.64-bit fixed point number. EWMA of actual K.
     *  @param _fL1 signed 64.64-bit fixed point number.  EWMA of actual L.
     *  @param  _mktVars contains 64.64 values for
     *           fIndexPriceS2, fIndexPriceS3, fSigma2, fSigma3, fRho23 - all required
     *  @param _fTargetDD signed 64.64-bit fixed point number
     *  @return M2Star signed 64.64-bit fixed point number
     */
    function getTargetCollateralM3(
        int128 _fK2,
        int128 _fL1,
        MarketVariables calldata _mktVars,
        int128 _fTargetDD
    ) external pure override returns (int128) {
        assert(_fK2 != 0);
        assert(_mktVars.fSigma3 != 0);
        assert(_mktVars.fIndexPriceS3 != 0);
        assert(_mktVars.fRho23 != 0);
        // we solve the quadratic equation A x^2 + Bx + C = 0
        // B = 2 * [X + Y * target_dd^2 * (exp(rho*sigma2*sigma3) - 1) ]
        // C = X^2  - Y^2 * target_dd^2 * (exp(sigma2^2) - 1)
        // where:
        // X = L1 / S3 - Y and Y = K2 * S2 / S3
        // we re-use L1 for X and K2 for Y to save memory since they don't enter the equations otherwise
        _fK2 = _fK2.mul(_mktVars.fIndexPriceS2).div(_mktVars.fIndexPriceS3); // Y
        _fL1 = _fL1.div(_mktVars.fIndexPriceS3).sub(_fK2); // X
        // we only need the square of the target DD
        _fTargetDD = _fTargetDD.mul(_fTargetDD);
        // and we only need B/2
        int128 fHalfB = _fL1.add(
            _fK2.mul(
                _fTargetDD.mul(
                    _mktVars.fRho23.mul(_mktVars.fSigma2).mul(_mktVars.fSigma3).exp().sub(
                        ONE_64x64
                    )
                )
            )
        );
        int128 fC = _fL1.mul(_fL1).sub(
            _fK2.mul(_fK2).mul(_fTargetDD).mul(
                _mktVars.fSigma2.mul(_mktVars.fSigma2).exp().sub(ONE_64x64)
            )
        );
        // A = 1 - (exp(sigma3^2) - 1) * target_dd^2
        int128 fA = ONE_64x64.sub(
            _mktVars.fSigma3.mul(_mktVars.fSigma3).exp().sub(ONE_64x64).mul(_fTargetDD)
        );
        // we re-use C to store the discriminant: D = (B/2)^2 - A * C
        fC = fHalfB.mul(fHalfB).sub(fA.mul(fC));
        if (fC < 0) {
            // no solutions -> AMM is in profit, probability is smaller than target regardless of capital
            return int128(0);
        }
        // we want the larger of (-B/2 + sqrt((B/2)^2-A*C)) / A and (-B/2 - sqrt((B/2)^2-A*C)) / A
        // so it depends on the sign of A, or, equivalently, the sign of sqrt(...)/A
        fC = ABDKMath64x64.sqrt(fC).div(fA);
        fHalfB = fHalfB.div(fA);
        return fC > 0 ? fC.sub(fHalfB) : fC.neg().sub(fHalfB);
    }

    /**
     *  Calculate the required deposit for a new position
     *  of size _fPosition+_fTradeAmount and leverage _fTargetLeverage,
     *  having an existing position with balance fBalance0 and size _fPosition.
     *  This is the amount to be added to the margin collateral and can be negative (hence remove).
     *  Fees not factored-in.
     *  @param _fPosition0   signed 64.64-bit fixed point number. Position in base currency
     *  @param _fBalance0   signed 64.64-bit fixed point number. Current balance.
     *  @param _fTradeAmount signed 64.64-bit fixed point number. Trade amt in base currency
     *  @param _fTargetLeverage signed 64.64-bit fixed point number. Desired leverage
     *  @param _fPrice signed 64.64-bit fixed point number. Price for the trade of size _fTradeAmount
     *  @param _fS2Mark signed 64.64-bit fixed point number. Mark-price
     *  @param _fS3 signed 64.64-bit fixed point number. Collateral 2 quote conversion
     *  @return signed 64.64-bit fixed point number. Required cash_cc
     */
    function getDepositAmountForLvgPosition(
        int128 _fPosition0,
        int128 _fBalance0,
        int128 _fTradeAmount,
        int128 _fTargetLeverage,
        int128 _fPrice,
        int128 _fS2Mark,
        int128 _fS3
    ) external pure override returns (int128) {
        int128 fPnL = _fTradeAmount.mul(_fS2Mark.sub(_fPrice));
        fPnL = fPnL.div(_fS3);
        int128 fLvgFrac = _fPosition0.add(_fTradeAmount).abs().mul(_fS2Mark);
        fLvgFrac = fLvgFrac.div(_fS3).div(_fTargetLeverage);
        return _fBalance0.add(fPnL).sub(fLvgFrac).neg();
    }

    /**
     * Computes the total absolute fee corresponding to a trade size and relative fees
     * @param _fDeltaPosCC Trade size, could be signed
     * @param _fTreasuryFeeRate Treasury fee rate
     * @param _fPnLPartRate PnL Participation fund fee rate
     * @param _fReferralRebate Referal rebate (absolute fee)
     * @param _referrerAddr Address of the referrer
     * @return Fee paid to the treasury (the AMM fund), in collateral currency
     * @return Fee paid to the PnL participation fund, in collateral currency
     * @return Fee paid to the referrer, in collateral currency
     */
    function relativeFeeToCCAmount(
        int128 _fDeltaPosCC,
        int128 _fTreasuryFeeRate,
        int128 _fPnLPartRate,
        int128 _fReferralRebate,
        address _referrerAddr
    )
        external
        pure
        returns (
            int128,
            int128,
            int128
        )
    {
        int128 fDeltaPos = _fDeltaPosCC.abs();
        int128 fTreasuryFee = fDeltaPos.mul(_fTreasuryFeeRate);
        int128 fPnLparticipantFee = fDeltaPos.mul(_fPnLPartRate);
        int128 fReferralRebate = _referrerAddr != address(0) ? _fReferralRebate : int128(0);
        return (fTreasuryFee, fPnLparticipantFee, fReferralRebate);
    }
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
pragma solidity 0.8.17;

import "../functions/AMMPerpLogic.sol";

interface IAMMPerpLogic {
    function ema(
        int128 _fEMA,
        int128 _fCurrentObs,
        int128 _fLambda
    ) external pure returns (int128);

    function volatilitySpread(
        uint16 _jumpTbps,
        uint16 _MinimalSpreadTbps,
        uint256 _numBlockSinceJump,
        int128 _fLambda
    ) external pure returns (int128);

    function holdingPeriodPenalty(uint256 _numBlockSinceLastOpen, int128 _fLambda)
        external
        pure
        returns (uint16);

    function calculateDefaultFundSize(
        int128[2] calldata _fK2AMM,
        int128 _fk2Trader,
        int128 _fCoverN,
        int128[2] calldata fStressRet2,
        int128[2] calldata fStressRet3,
        int128[2] calldata fIndexPrices,
        AMMPerpLogic.CollateralCurrency _eCCY
    ) external pure returns (int128);

    function calculateRiskNeutralPD(
        AMMPerpLogic.AMMVariables memory _ammVars,
        AMMPerpLogic.MarketVariables calldata _mktVars,
        int128 _fTradeAmount,
        bool _withCDF
    ) external view returns (int128, int128);

    function calculateBoundedSlippage(
        AMMPerpLogic.AMMVariables memory _ammVars,
        int128 _fTradeAmount
    ) external view returns (int128);

    function calculatePerpetualPrice(
        AMMPerpLogic.AMMVariables calldata _ammVars,
        AMMPerpLogic.MarketVariables calldata _mktVars,
        int128 _fTradeAmount,
        int128 _fBidAskSpread,
        int128 _fIncentiveSpread
    ) external view returns (int128);

    function getTargetCollateralM1(
        int128 _fK2,
        int128 _fL1,
        AMMPerpLogic.MarketVariables calldata _mktVars,
        int128 _fTargetDD
    ) external pure returns (int128);

    function getTargetCollateralM2(
        int128 _fK2,
        int128 _fL1,
        AMMPerpLogic.MarketVariables calldata _mktVars,
        int128 _fTargetDD
    ) external pure returns (int128);

    function getTargetCollateralM3(
        int128 _fK2,
        int128 _fL1,
        AMMPerpLogic.MarketVariables calldata _mktVars,
        int128 _fTargetDD
    ) external pure returns (int128);

    function getDepositAmountForLvgPosition(
        int128 _fPosition0,
        int128 _fBalance0,
        int128 _fTradeAmount,
        int128 _fTargetLeverage,
        int128 _fPrice,
        int128 _fS2Mark,
        int128 _fS3
    ) external pure returns (int128);

    function relativeFeeToCCAmount(
        int128 _fDeltaPos,
        int128 _fTreasuryFeeRate,
        int128 _fPnLPartRate,
        int128 _fReferralRebate,
        address _referrerAddr
    )
        external
        pure
        returns (
            int128,
            int128,
            int128
        );
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