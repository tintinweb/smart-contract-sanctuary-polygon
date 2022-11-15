// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {
    DLPair__BrokenSwapSafetyCheck,
    DLPair__InsufficientAmounts,
    DLPair__FlashLoanCallbackFailed,
    DLPair__FlashLoanInvalidBalance,
    DLPair__FlashLoanInvalidToken
} from "../../DLErrors.sol";
import {IDLFactory} from "../../interfaces/IDLFactory.sol";
import {IDLFlashLoanCallback} from "../../interfaces/IDLFlashLoanCallback.sol";
import {FeeDistributionHelper, FeeHelper} from "../../libraries/FeeDistributionHelper.sol";
import {Constants} from "../../libraries/Constants.sol";
import {Oracle} from "../../libraries/Oracle.sol";
import {SafeCast} from "../../libraries/SafeCast.sol";
import {SafeMath} from "../../libraries/SafeMath.sol";
import {SwapHelper} from "../../libraries/SwapHelper.sol";
import {TokenHelper} from "../../libraries/TokenHelper.sol";
import {TreeMath} from "../../libraries/TreeMath.sol";
import {DLPairToken, IERC20} from "./DLPairToken.sol";

/// @title Discretized Liquidity Pair
/// @author Bentoswap
/// @notice The implementation of Discretized Liquidity Pair that also acts as the receipt token for liquidity positions
contract DLPair is DLPairToken {
    using FeeDistributionHelper for FeeHelper.FeesDistribution;
    using FeeHelper for FeeHelper.FeeParameters;
    using Oracle for bytes32[65_535];
    using SafeCast for uint256;
    using SafeMath for uint256;
    using TokenHelper for IERC20;
    using TreeMath for mapping(uint256 => uint256)[3];
    using SwapHelper for Bin;

    /// @notice Set the factory address
    /// @param _factory The address of the factory
    constructor(IDLFactory _factory) DLPairToken(_factory) { }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- EXTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @notice Performs a low level swap, this needs to be called from a contract which performs important safety checks
    /// and transfer the amount of token  (either tokenX or tokenY, not both at the same time or they might be lost)
    /// @dev Will swap the full amount that this contract received of token X or Y
    /// @param _swapForY whether the token sent was Y (true) or X (false)
    /// @param _to The address of the recipient
    /// @return amountXOut The amount of token X sent to `_to`
    /// @return amountYOut The amount of token Y sent to `_to`
    function swap(bool _swapForY, address _to)
        external
        override
        nonReentrant
        returns (uint256 amountXOut, uint256 amountYOut)
    {
        PairInformation memory _pair = _pairInformation;

        uint256 _amountIn = _swapForY
            ? tokenX.received(_pair.reserveX, _pair.feesX.total)
            : tokenY.received(_pair.reserveY, _pair.feesY.total);

        if (_amountIn == 0) revert DLPair__InsufficientAmounts();

        FeeHelper.FeeParameters memory _fp = _feeParameters;

        uint256 _startId = _pair.activeId;
        _fp.updateVariableFeeParameters(_startId);

        uint256 _amountOut;
        // Performs the actual swap, bin per bin
        // It uses the findFirstBin function to make sure the bin we're currently looking at
        // has liquidity in it.
        while (true) {
            Bin memory _bin = _bins[_pair.activeId];
            if ((!_swapForY && _bin.reserveX != 0) || (_swapForY && _bin.reserveY != 0)) {
                (uint256 _amountInToBin, uint256 _amountOutOfBin, FeeHelper.FeesDistribution memory _fees) = _bin
                    .getAmounts(_fp, _pair.activeId, _swapForY, _amountIn);

                _bin.updateFees(_swapForY ? _pair.feesX : _pair.feesY, _fees, _swapForY, totalSupply(_pair.activeId));

                _bin.updateReserves(_pair, _swapForY, _amountInToBin.safe112(), _amountOutOfBin.safe112());

                _amountIn -= _amountInToBin + _fees.total;
                _amountOut += _amountOutOfBin;

                _bins[_pair.activeId] = _bin;

                if (_swapForY) {
                    emit Swap(
                        msg.sender,
                        _to,
                        _pair.activeId,
                        _amountInToBin,
                        0,
                        0,
                        _amountOutOfBin,
                        _fp.volatilityAccumulated,
                        _fees.total,
                        0
                    );
                } else {
                    emit Swap(
                        msg.sender,
                        _to,
                        _pair.activeId,
                        0,
                        _amountInToBin,
                        _amountOutOfBin,
                        0,
                        _fp.volatilityAccumulated,
                        0,
                        _fees.total
                    );
                }
            }

            if (_amountIn != 0) {
                _pair.activeId = _tree.findFirstBin(_pair.activeId, _swapForY);
            } else {
                break;
            }
        }

        if (_amountOut == 0) revert DLPair__BrokenSwapSafetyCheck(); // Safety check

        // We use oracleSize so it can start filling empty slot that were added recently
        uint256 _updatedOracleId = _oracle.update(
            _pair.oracleSize,
            _pair.oracleSampleLifetime,
            _pair.oracleLastTimestamp,
            _pair.oracleId,
            _pair.activeId,
            _fp.volatilityAccumulated,
            _startId.absSub(_pair.activeId)
        );

        // We update the oracleId and lastTimestamp if the sample write on another slot
        if (_updatedOracleId != _pair.oracleId || _pair.oracleLastTimestamp == 0) {
            // Can't overflow as the updatedOracleId < oracleSize
            _pair.oracleId = uint16(_updatedOracleId);
            _pair.oracleLastTimestamp = block.timestamp.safe40();

            // We increase the activeSize if the updated sample is written in a new slot
            // Can't overflow as _updatedOracleId < maxSize = 2**16-1
            unchecked {
                if (_updatedOracleId == _pair.oracleActiveSize) ++_pair.oracleActiveSize;
            }
        }

        _feeParameters = _fp;
        _pairInformation = _pair;

        if (_swapForY) {
            amountYOut = _amountOut;
            tokenY.safeTransfer(_to, _amountOut);
        } else {
            amountXOut = _amountOut;
            tokenX.safeTransfer(_to, _amountOut);
        }
    }

    /// @notice Perform a flashloan on one of the tokens of the pair. The flashloan will call the `_receiver` contract
    /// to perform the desired operations. The `_receiver` contract is expected to transfer the `amount + fee` of the
    /// token to this contract.
    /// @param _receiver The contract that will receive the flashloan and execute the callback
    /// @param _token The address of the token to flashloan
    /// @param _amount The amount of token to flashloan
    /// @param _data The call data that will be forwarded to the `_receiver` contract during the callback
    function flashLoan(
        IDLFlashLoanCallback _receiver,
        IERC20 _token,
        uint256 _amount,
        bytes calldata _data
    ) external override nonReentrant {
        IERC20 _tokenX = tokenX;
        if ((_token != _tokenX && _token != tokenY)) revert DLPair__FlashLoanInvalidToken();

        uint256 _totalFee = _getFlashLoanFee(_amount);

        FeeHelper.FeesDistribution memory _fees = FeeHelper.FeesDistribution({
            total: _totalFee.safe128(),
            protocol: uint128((_totalFee * _feeParameters.protocolShare) / Constants.BASIS_POINT_MAX)
        });

        uint256 _balanceBefore = _token.balanceOf(address(this));

        _token.safeTransfer(address(_receiver), _amount);

        if (
            _receiver.DLFlashLoanCallback(msg.sender, _token, _amount, _fees.total, _data) != Constants.CALLBACK_SUCCESS
        ) revert DLPair__FlashLoanCallbackFailed();

        uint256 _balanceAfter = _token.balanceOf(address(this));

        if (_balanceAfter != _balanceBefore + _fees.total) revert DLPair__FlashLoanInvalidBalance();

        uint256 _activeId = _pairInformation.activeId;
        uint256 _totalSupply = totalSupply(_activeId);

        if (_totalFee > 0) {
            if (_token == _tokenX) {
                (uint128 _feesXTotal, , uint128 _feesXProtocol, ) = _getGlobalFees();

                _setFees(_pairInformation.feesX, _feesXTotal + _fees.total, _feesXProtocol + _fees.protocol);
                _bins[_activeId].accTokenXPerShare += _fees.getTokenPerShare(_totalSupply);
            } else {
                (, uint128 _feesYTotal, , uint128 _feesYProtocol) = _getGlobalFees();

                _setFees(_pairInformation.feesY, _feesYTotal + _fees.total, _feesYProtocol + _fees.protocol);
                _bins[_activeId].accTokenYPerShare += _fees.getTokenPerShare(_totalSupply);
            }
        }

        emit FlashLoan(msg.sender, _receiver, _token, _amount, _fees.total);
    }

    function getReservesAndId()
        external
        view
        override
        returns (
            uint256 reserveX,
            uint256 reserveY,
            uint256 activeId
        )
    {
        return _getReservesAndId();
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- ORACLE -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>


    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- LP TOKEN -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function mint(
        uint256[] calldata _ids,
        uint256[] calldata _distributionX,
        uint256[] calldata _distributionY,
        address _to
    )
        external
        override
        nonReentrant
        returns (
            uint256,
            uint256,
            uint256[] memory liquidityMinted
        )
    {
        return _mint(_ids, _distributionX, _distributionY, _to);
    }

    function burn(
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        address _to
    ) external override nonReentrant returns (uint256 amountX, uint256 amountY) {
        return _burn(_ids, _amounts, _to);
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //       -'~'-.,__,.-'~'-.,__,.- BINS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function getBin(uint24 _id) external view override returns (uint256 reserveX, uint256 reserveY) {
        return _getBin(_id);
    }

    function findFirstNonEmptyBinId(uint24 _id, bool _swapForY) external view override returns (uint24) {
        return _tree.findFirstBin(_id, _swapForY);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/** DLRouter errors */

error DLRouter__SenderIsNotWCT();
error DLRouter__PairNotCreated(address tokenX, address tokenY, uint256 binStep);
error DLRouter__WrongAmounts(uint256 amount, uint256 reserve);
error DLRouter__SwapOverflows(uint256 id);
error DLRouter__BrokenSwapSafetyCheck();
error DLRouter__NotFactoryOwner();
error DLRouter__TooMuchTokensIn(uint256 excess);
error DLRouter__BinReserveOverflows(uint256 id);
error DLRouter__MissingBinStepForPair(address tokenX, address tokenY);
error DLRouter__IdOverflows(int256 id);
error DLRouter__LengthsMismatch();
error DLRouter__WrongTokenOrder();
error DLRouter__IdSlippageCaught(uint256 activeIdDesired, uint256 idSlippage, uint256 activeId);
error DLRouter__AmountSlippageCaught(uint256 amountXMin, uint256 amountX, uint256 amountYMin, uint256 amountY);
error DLRouter__IdDesiredOverflows(uint256 idDesired, uint256 idSlippage);
error DLRouter__FailedToSendCT(address recipient, uint256 amount);
error DLRouter__DeadlineExceeded(uint256 deadline, uint256 currentTimestamp);
error DLRouter__AmountSlippageBPTooBig(uint256 amountSlippage);
error DLRouter__InsufficientAmountOut(uint256 amountOutMin, uint256 amountOut);
error DLRouter__MaxAmountInExceeded(uint256 amountInMax, uint256 amountIn);
error DLRouter__InvalidTokenPath(address wrongToken);
error DLRouter__InvalidVersion(uint256 version);
error DLRouter__WrongWCTLiquidityParameters(
    address tokenX,
    address tokenY,
    uint256 amountX,
    uint256 amountY,
    uint256 msgValue
);

/** DLToken errors */

error DLToken__SpenderNotApproved(address owner, address spender);
error DLToken__TransferFromOrToAddress0();
error DLToken__MintToAddress0();
error DLToken__BurnFromAddress0();
error DLToken__BurnExceedsBalance(address from, uint256 id, uint256 amount);
error DLToken__LengthMismatch(uint256 accountsLength, uint256 idsLength);
error DLToken__SelfApproval(address owner);
error DLToken__TransferExceedsBalance(address from, uint256 id, uint256 amount);
error DLToken__TransferToSelf();
error DLToken__NotSupported();

/** DLFactory errors */

error DLFactory__IdenticalAddresses(IERC20 token_);
error DLFactory__QuoteAssetNotWhitelisted(IERC20 quoteAsset_);
error DLFactory__QuoteAssetAlreadyWhitelisted(IERC20 quoteAsset_);
error DLFactory__AddressZero();
error DLFactory__DLPairAlreadyExists(IERC20 tokenX_, IERC20 tokenY_, uint256 binStep_);
error DLFactory__DLPairNotCreated(IERC20 tokenX_, IERC20 tokenY_, uint256 binStep_);
error DLFactory__DecreasingPeriods(uint16 filterPeriod_, uint16 decayPeriod_);
error DLFactory__ReductionFactorOverflows(uint16 reductionFactor_, uint256 max_);
error DLFactory__VariableFeeControlOverflows(uint16 variableFeeControl, uint256 max_);
error DLFactory__BaseFeesBelowMin(uint256 baseFees_, uint256 minBaseFees_);
error DLFactory__FeesAboveMax(uint256 fees_, uint256 maxFees_);
error DLFactory__FlashLoanFeeAboveMax(uint256 fees_, uint256 maxFees_);
error DLFactory__BinStepRequirementsBreached(uint256 lowerBound_, uint16 binStep_, uint256 higherBound_);
error DLFactory__ProtocolShareOverflows(uint16 protocolShare_, uint256 max_);
error DLFactory__FunctionIsLockedForUsers(address user_);
error DLFactory__FactoryLockIsAlreadyInTheSameState();
error DLFactory__FactoryQuoteAssetRestrictedIsAlreadyInTheSameState();
error DLFactory__DLPairIgnoredIsAlreadyInTheSameState();
error DLFactory__BinStepHasNoPreset(uint256 binStep_);
error DLFactory__SameFeeRecipient(address feeRecipient_);
error DLFactory__SameFlashLoanFee(uint256 flashLoanFee_);
error DLFactory__DLPairSafetyCheckFailed(address DLPairImplementation_);
error DLFactory__SameImplementation(address DLPairImplementation_);
error DLFactory__ImplementationNotSet();

/** DLPair errors */

error DLPair__InsufficientAmounts();
error DLPair__AddressZero();
error DLPair__AddressZeroOrThis();
error DLPair__BrokenSwapSafetyCheck();
error DLPair__CompositionFactorFlawed(uint256 id_);
error DLPair__InsufficientLiquidityMinted(uint256 id_);
error DLPair__InsufficientLiquidityBurned(uint256 id_);
error DLPair__WrongLengths();
error DLPair__OnlyStrictlyIncreasingId();
error DLPair__OnlyFactory();
error DLPair__DistributionsOverflow();
error DLPair__OnlyFeeRecipient(address feeRecipient_, address sender_);
error DLPair__OracleNotEnoughSample();
error DLPair__FlashLoanCallbackFailed();
error DLPair__FlashLoanInvalidBalance();
error DLPair__FlashLoanInvalidToken();
error DLPair__AlreadyInitialized();
error DLPair__NewSizeTooSmall(uint256 newSize_, uint256 oracleSize_);

/** BinHelper errors */

error BinHelper__BinStepOverflows(uint256 bp_);
error BinHelper__IdOverflows();

/** FeeDistributionHelper errors */

error FeeDistributionHelper__FlashLoanWrongFee(uint256 receivedFee_, uint256 expectedFee_);

/** Math128x128 errors */

error Math128x128__PowerUnderflow(uint256 x_, int256 y_);
error Math128x128__LogUnderflow();

/** Math512Bits errors */

error Math512Bits__MulDivOverflow(uint256 prod1_, uint256 denominator_);
error Math512Bits__ShiftDivOverflow(uint256 prod1_, uint256 denominator_);
error Math512Bits__MulShiftOverflow(uint256 prod1_, uint256 offset_);
error Math512Bits__OffsetOverflows(uint256 offset_);

/** Oracle errors */

error Oracle__AlreadyInitialized(uint256 index_);
error Oracle__LookUpTimestampTooOld(uint256 minTimestamp_, uint256 lookUpTimestamp_);
error Oracle__NotInitialized();

/** PendingOwnable errors */

error PendingOwnable__NotOwner();
error PendingOwnable__NotPendingOwner();
error PendingOwnable__PendingOwnerAlreadySet();
error PendingOwnable__NoPendingOwner();
error PendingOwnable__AddressZero();

/** ReentrancyGuardUpgradeable errors */

error ReentrancyGuardUpgradeable__ReentrantCall();
error ReentrancyGuardUpgradeable__AlreadyInitialized();

/** SafeCast errors */

error SafeCast__Exceeds256Bits(uint256 x_);
error SafeCast__Exceeds248Bits(uint256 x_);
error SafeCast__Exceeds240Bits(uint256 x_);
error SafeCast__Exceeds232Bits(uint256 x_);
error SafeCast__Exceeds224Bits(uint256 x_);
error SafeCast__Exceeds216Bits(uint256 x_);
error SafeCast__Exceeds208Bits(uint256 x_);
error SafeCast__Exceeds200Bits(uint256 x_);
error SafeCast__Exceeds192Bits(uint256 x_);
error SafeCast__Exceeds184Bits(uint256 x_);
error SafeCast__Exceeds176Bits(uint256 x_);
error SafeCast__Exceeds168Bits(uint256 x_);
error SafeCast__Exceeds160Bits(uint256 x_);
error SafeCast__Exceeds152Bits(uint256 x_);
error SafeCast__Exceeds144Bits(uint256 x_);
error SafeCast__Exceeds136Bits(uint256 x_);
error SafeCast__Exceeds128Bits(uint256 x_);
error SafeCast__Exceeds120Bits(uint256 x_);
error SafeCast__Exceeds112Bits(uint256 x_);
error SafeCast__Exceeds104Bits(uint256 x_);
error SafeCast__Exceeds96Bits(uint256 x_);
error SafeCast__Exceeds88Bits(uint256 x_);
error SafeCast__Exceeds80Bits(uint256 x_);
error SafeCast__Exceeds72Bits(uint256 x_);
error SafeCast__Exceeds64Bits(uint256 x_);
error SafeCast__Exceeds56Bits(uint256 x_);
error SafeCast__Exceeds48Bits(uint256 x_);
error SafeCast__Exceeds40Bits(uint256 x_);
error SafeCast__Exceeds32Bits(uint256 x_);
error SafeCast__Exceeds24Bits(uint256 x_);
error SafeCast__Exceeds16Bits(uint256 x_);
error SafeCast__Exceeds8Bits(uint256 x_);

/** TreeMath errors */

error TreeMath__ErrorDepthSearch();

/** TokenHelper errors */

error TokenHelper__NonContract();
error TokenHelper__CallFailed();
error TokenHelper__TransferFailed();

/** DLQuoter errors */

error DLQuoter_InvalidLength();

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {IDLPair} from "./IDLPair.sol";
import {IPendingOwnable} from "./IPendingOwnable.sol";

/// @title Discretized Liquidity Factory Interface
/// @author Bentoswap
/// @notice Required interface of DLFactory contract
interface IDLFactory is IPendingOwnable {

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //   -'~'-.,__,.-'~'-.,__,.- STRUCTS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @dev Structure to store the DLPair information, such as:
    /// - binStep: The bin step of the DLPair
    /// - dlPair: The address of the DLPair
    /// - createdByOwner: Whether the pair was created by the owner of the factory
    /// - ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
    struct DLPairInformation {
        uint16 binStep;
        IDLPair dlPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    /// @dev Structure of the packed factory preset information for each binStep
    /// @param binStep The bin step in basis point, used to calculate log(1 + binStep)
    /// @param baseFactor The base factor, used to calculate the base fee, baseFee = baseFactor * binStep
    /// @param filterPeriod The period where the accumulator value is untouched, prevent spam
    /// @param decayPeriod The period where the accumulator value is halved
    /// @param reductionFactor The reduction factor, used to calculate the reduction of the accumulator
    /// @param variableFeeControl The variable fee control, used to control the variable fee, can be 0 to disable it
    /// @param protocolShare The share of the fees received by the protocol
    /// @param maxVolatilityAccumulated The max value of the volatility accumulated
    /// @param sampleLifetime The lifetime of an oracle's sample
    struct FactoryFeeParamsPreset {
        uint16 binStep;
        uint16 baseFactor;
        uint16 filterPeriod;
        uint16 decayPeriod;
        uint16 reductionFactor;
        uint24 variableFeeControl;
        uint16 protocolShare;
        uint24 maxVolatilityAccumulated;
        uint16 sampleLifetime;
    }

    /// @dev Structure of the packed factory preset information for each binStep
    /// @param binStep The bin step in basis point, used to calculate log(1 + binStep)
    /// @param baseFactor The base factor, used to calculate the base fee, baseFee = baseFactor * binStep
    /// @param filterPeriod The period where the accumulator value is untouched, prevent spam
    /// @param decayPeriod The period where the accumulator value is halved
    /// @param reductionFactor The reduction factor, used to calculate the reduction of the accumulator
    /// @param variableFeeControl The variable fee control, used to control the variable fee, can be 0 to disable it
    /// @param protocolShare The share of the fees received by the protocol
    /// @param maxVolatilityAccumulated The max value of the volatility accumulated
    struct FactoryFeeParams {
        uint16 binStep;
        uint16 baseFactor;
        uint16 filterPeriod;
        uint16 decayPeriod;
        uint16 reductionFactor;
        uint24 variableFeeControl;
        uint16 protocolShare;
        uint24 maxVolatilityAccumulated;
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //    -'~'-.,__,.-'~'-.,__,.- EVENTS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    event DLPairCreated(
        IERC20 indexed _tokenX,
        IERC20 indexed _tokenY,
        uint256 indexed binStep,
        IDLPair _dlPair,
        uint256 _pid
    );

    event FeeRecipientSet(address _oldRecipient, address _newRecipient);

    event FlashLoanFeeSet(uint256 _oldFlashLoanFee, uint256 _newFlashLoanFee);

    event FeeParametersSet(
        address indexed _sender,
        IDLPair indexed _dlPair,
        FactoryFeeParams _feeParams
    );

    event FactoryLockedStatusUpdated(bool _locked);

    event FactoryQuoteAssetRestrictedStatusUpdated(bool _restricted);

    event DLPairImplementationSet(address _oldDLPairImplementation, address _dlPairImplementation);

    event DLPairIgnoredStateChanged(IDLPair indexed _dlPair, bool _ignored);

    event PresetSet(
        uint256 indexed _binStep,
        FactoryFeeParamsPreset _preset
    );

    event PresetRemoved(uint256 indexed _binStep);

    event QuoteAssetAdded(IERC20 indexed _quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed _quoteAsset);

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //  -'~'-.,__,.-'~'-.,__,.- CONSTANTS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function MAX_FEE() external pure returns (uint256);

    function MIN_BIN_STEP() external pure returns (uint256);

    function MAX_BIN_STEP() external pure returns (uint256);

    function MAX_PROTOCOL_SHARE() external pure returns (uint256);

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- VARS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function dlPairImplementation() external view returns (address);

    function feeRecipient() external view returns (address);

    function flashLoanFee() external view returns (uint256);

    function isCreationLocked() external view returns (bool);

    function isQuoteAssetRestricted() external view returns (bool);

    function allDLPairs(uint256 idx) external returns (IDLPair);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //      -'~'-.,__,.-'~'-.,__,.- CREATE -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function createDLPair(
        IERC20 _tokenX,
        IERC20 _tokenY,
        uint24 _activeId,
        uint16 _binStep
    ) external returns (IDLPair pair_);

    function addQuoteAsset(IERC20 _quoteAsset) external;

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //      -'~'-.,__,.-'~'-.,__,.- DELETE -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function removePreset(uint16 _binStep) external;

    function removeQuoteAsset(IERC20 _quoteAsset) external;

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //       -'~'-.,__,.-'~'-.,__,.- MISC -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function forceDecayOnPair(IDLPair _dlPair) external;

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //      -'~'-.,__,.-'~'-.,__,.- GETTER -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAsset(uint256 _index) external view returns (IERC20);

    function getNumberOfDLPairs() external view returns (uint256);

    function getDLPairInformation(
        IERC20 _tokenX,
        IERC20 _tokenY,
        uint256 _binStep
    ) external view returns (DLPairInformation memory);

    function getPreset(uint16 _binStep)
        external
        view
        returns (
            FactoryFeeParamsPreset memory preset_
        );

    function getAllBinStepsFromPresets() external view returns (uint256[] memory presetsBinStep_);

    function getAllDLPairs(IERC20 _tokenX, IERC20 _tokenY)
        external
        view
        returns (DLPairInformation[] memory dlPairsBinStep_);

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //      -'~'-.,__,.-'~'-.,__,.- SETTER -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    function setDLPairImplementation(address _dlPairImplementation) external;

    function setDLPairIgnored(
        IERC20 _tokenX,
        IERC20 _tokenY,
        uint256 _binStep,
        bool _ignored
    ) external;

    function setPreset(
        FactoryFeeParamsPreset calldata _preset
    ) external;

    function setFeesParametersOnPair(
        IERC20 _tokenX,
        IERC20 _tokenY,
        FactoryFeeParams calldata _feeParams
    ) external;

    function setFeeRecipient(address _feeRecipient) external;

    function setFlashLoanFee(uint256 _flashLoanFee) external;

    function setFactoryLockedState(bool _locked) external;

    function setFactoryQuoteAssetRestrictedState(bool _restricted) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/// @title Discretized Liquidity Flashloan Callback Interface
/// @author Bentoswap
/// @notice Required interface to interact with DL flashloans
interface IDLFlashLoanCallback {
    function DLFlashLoanCallback(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {FeeDistributionHelper__FlashLoanWrongFee} from "../DLErrors.sol";
import {Constants} from "./Constants.sol";
import {FeeHelper} from "./FeeHelper.sol";
import {SafeCast} from "./SafeCast.sol";
import {TokenHelper} from "./TokenHelper.sol";

/// @title Discretized Liquidity Fee Distribution Helper Library
/// @author Bentoswap
/// @notice Helper contract used for fees distribution calculations
library FeeDistributionHelper {
    using TokenHelper for IERC20;
    using SafeCast for uint256;

    /// @notice Checks that the flash loan was done accordingly and update fees
    /// @param _fees The fees received by the pair
    /// @param _pairFees The fees of the pair
    /// @param _token The address of the token received
    /// @param _reserve The stored reserve of the current bin
    function flashLoanHelper(
        FeeHelper.FeesDistribution memory _fees,
        FeeHelper.FeesDistribution storage _pairFees,
        IERC20 _token,
        uint256 _reserve
    ) internal {
        uint128 _totalFees = _pairFees.total;
        uint256 _amountReceived = _token.received(_reserve, _totalFees);

        if (_amountReceived != _fees.total)
            revert FeeDistributionHelper__FlashLoanWrongFee(_amountReceived, _fees.total);

        _fees.total = _amountReceived.safe128();

        _pairFees.total = _totalFees + _fees.total;
        // unsafe math is fine because total >= protocol
        unchecked {
            _pairFees.protocol += _fees.protocol;
        }
    }

    /// @notice Calculate the tokenPerShare when fees are added
    /// @param _fees The fees received by the pair
    /// @param _totalSupply the total supply of a specific bin
    function getTokenPerShare(FeeHelper.FeesDistribution memory _fees, uint256 _totalSupply)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            // This can't overflow as `totalFees >= protocolFees`,
            // shift can't overflow as we shift fees that are a uint128, by 128 bits.
            // The result will always be smaller than max(uint256)
            return ((uint256(_fees.total) - _fees.protocol) << Constants.SCALE_OFFSET) / _totalSupply;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Discretized Liquidity Constants Library
/// @author Bentoswap
/// @notice Set of constants for Discretized Liquidity contracts
library Constants {
    uint256 internal constant SCALE_OFFSET = 128;
    uint256 internal constant SCALE = 1 << SCALE_OFFSET; // type(uint128).max + 1

    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant BASIS_POINT_MAX = 10_000;

    /// @dev The expected return after a successful flash loan
    bytes32 internal constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {
    Oracle__LookUpTimestampTooOld,
    Oracle__NotInitialized
} from "../DLErrors.sol";
import {Buffer} from "./Buffer.sol";
import {Samples} from "./Samples.sol";

/// @title Discretized Liquidity Oracle Library
/// @author Bentoswap
/// @notice Helper contract for oracle
library Oracle {
    using Samples for bytes32;
    using Buffer for uint256;

    struct Sample {
        uint256 timestamp;
        uint256 cumulativeId;
        uint256 cumulativeVolatilityAccumulated;
        uint256 cumulativeBinCrossed;
    }

    /// @notice View function to get the oracle's sample at `_ago` seconds
    /// @dev Return a linearized sample, the weighted average of 2 neighboring samples
    /// @param _oracle The oracle storage pointer
    /// @param _activeSize The size of the oracle (without empty data)
    /// @param _activeId The active index of the oracle
    /// @param _lookUpTimestamp The looked up date
    /// @return timestamp The timestamp of the sample
    /// @return cumulativeId The weighted average cumulative id
    /// @return cumulativeVolatilityAccumulated The weighted average cumulative volatility accumulated
    /// @return cumulativeBinCrossed The weighted average cumulative bin crossed
    function getSampleAt(
        bytes32[65_535] storage _oracle,
        uint256 _activeSize,
        uint256 _activeId,
        uint256 _lookUpTimestamp
    )
        internal
        view
        returns (
            uint256 timestamp,
            uint256 cumulativeId,
            uint256 cumulativeVolatilityAccumulated,
            uint256 cumulativeBinCrossed
        )
    {
        if (_activeSize == 0) revert Oracle__NotInitialized();

        // Oldest sample
        uint256 _nextId;
        assembly {
            _nextId := addmod(_activeId, 1, _activeSize)
        }
        bytes32 _sample = _oracle[_nextId];
        timestamp = _sample.timestamp();
        if (timestamp > _lookUpTimestamp) revert Oracle__LookUpTimestampTooOld(timestamp, _lookUpTimestamp);

        // Most recent sample
        if (_activeSize != 1) {
            _sample = _oracle[_activeId];
            timestamp = _sample.timestamp();

            if (timestamp > _lookUpTimestamp) {
                bytes32 _next;
                (_sample, _next) = binarySearch(_oracle, _activeId, _lookUpTimestamp, _activeSize);

                if (_sample != _next) {
                    uint256 _weightPrev = _next.timestamp() - _lookUpTimestamp; // _next.timestamp() - _sample.timestamp() - (_lookUpTimestamp - _sample.timestamp())
                    uint256 _weightNext = _lookUpTimestamp - _sample.timestamp(); // _next.timestamp() - _sample.timestamp() - (_next.timestamp() - _lookUpTimestamp)
                    uint256 _totalWeight = _weightPrev + _weightNext; // _next.timestamp() - _sample.timestamp()

                    cumulativeId =
                        (_sample.cumulativeId() * _weightPrev + _next.cumulativeId() * _weightNext) /
                        _totalWeight;
                    cumulativeVolatilityAccumulated =
                        (_sample.cumulativeVolatilityAccumulated() *
                            _weightPrev +
                            _next.cumulativeVolatilityAccumulated() *
                            _weightNext) /
                        _totalWeight;
                    cumulativeBinCrossed =
                        (_sample.cumulativeBinCrossed() * _weightPrev + _next.cumulativeBinCrossed() * _weightNext) /
                        _totalWeight;
                    return (_lookUpTimestamp, cumulativeId, cumulativeVolatilityAccumulated, cumulativeBinCrossed);
                }
            }
        }

        timestamp = _sample.timestamp();
        cumulativeId = _sample.cumulativeId();
        cumulativeVolatilityAccumulated = _sample.cumulativeVolatilityAccumulated();
        cumulativeBinCrossed = _sample.cumulativeBinCrossed();
    }

    /// @notice Function to update a sample
    /// @param _oracle The oracle storage pointer
    /// @param _size The size of the oracle (last ids can be empty)
    /// @param _sampleLifetime The lifetime of a sample, it accumulates information for up to this timestamp
    /// @param _lastTimestamp The timestamp of the creation of the oracle's latest sample
    /// @param _lastIndex The index of the oracle's latest sample
    /// @param _activeId The active index of the pair during the latest swap
    /// @param _volatilityAccumulated The volatility accumulated of the pair during the latest swap
    /// @param _binCrossed The bin crossed during the latest swap
    /// @return updatedIndex The oracle updated index, it is either the same as before, or the next one
    function update(
        bytes32[65_535] storage _oracle,
        uint256 _size,
        uint256 _sampleLifetime,
        uint256 _lastTimestamp,
        uint256 _lastIndex,
        uint256 _activeId,
        uint256 _volatilityAccumulated,
        uint256 _binCrossed
    ) internal returns (uint256 updatedIndex) {
        bytes32 _updatedPackedSample = _oracle[_lastIndex].update(_activeId, _volatilityAccumulated, _binCrossed);

        if (block.timestamp - _lastTimestamp >= _sampleLifetime && _lastTimestamp != 0) {
            assembly {
                updatedIndex := addmod(_lastIndex, 1, _size)
            }
        } else updatedIndex = _lastIndex;

        _oracle[updatedIndex] = _updatedPackedSample;
    }

    /// @notice Initialize the sample
    /// @param _oracle The oracle storage pointer
    /// @param _index The index to initialize
    function initialize(bytes32[65_535] storage _oracle, uint256 _index) internal {
        _oracle[_index] |= bytes32(uint256(1));
    }

    /// @notice Binary search on oracle samples and return the 2 samples (as bytes32) that surrounds the `lookUpTimestamp`
    /// @dev The oracle needs to be in increasing order `{_index + 1, _index + 2 ..., _index + _activeSize} % _activeSize`.
    /// The sample that aren't initialized yet will be skipped as _activeSize only contains the samples that are initialized.
    /// This function works only if `timestamp(_oracle[_index + 1 % _activeSize] <= _lookUpTimestamp <= timestamp(_oracle[_index]`.
    /// The edge cases needs to be handled before
    /// @param _oracle The oracle storage pointer
    /// @param _index The current index of the oracle
    /// @param _lookUpTimestamp The looked up timestamp
    /// @param _activeSize The size of the oracle (without empty data)
    /// @return prev The last sample with a timestamp lower than the lookUpTimestamp
    /// @return next The first sample with a timestamp greater than the lookUpTimestamp
    function binarySearch(
        bytes32[65_535] storage _oracle,
        uint256 _index,
        uint256 _lookUpTimestamp,
        uint256 _activeSize
    ) private view returns (bytes32 prev, bytes32 next) {
        // The sample with the lowest timestamp is the one right after _index
        uint256 _low = 1;
        uint256 _high = _activeSize;

        uint256 _middle;
        uint256 _id;

        bytes32 _sample;
        uint256 _sampleTimestamp;
        while (_high >= _low) {
            unchecked {
                _middle = (_low + _high) >> 1;
                assembly {
                    _id := addmod(_middle, _index, _activeSize)
                }
                _sample = _oracle[_id];
                _sampleTimestamp = _sample.timestamp();
                if (_sampleTimestamp < _lookUpTimestamp) {
                    _low = _middle + 1;
                } else if (_sampleTimestamp > _lookUpTimestamp) {
                    _high = _middle - 1;
                } else {
                    return (_sample, _sample);
                }
            }
        }
        if (_sampleTimestamp < _lookUpTimestamp) {
            assembly {
                _id := addmod(_id, 1, _activeSize)
            }
            (prev, next) = (_sample, _oracle[_id]);
        } else (prev, next) = (_oracle[_id.before(_activeSize)], _sample);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {
    SafeCast__Exceeds248Bits,
    SafeCast__Exceeds240Bits,
    SafeCast__Exceeds232Bits,
    SafeCast__Exceeds224Bits,
    SafeCast__Exceeds216Bits,
    SafeCast__Exceeds208Bits,
    SafeCast__Exceeds200Bits,
    SafeCast__Exceeds192Bits,
    SafeCast__Exceeds184Bits,
    SafeCast__Exceeds176Bits,
    SafeCast__Exceeds168Bits,
    SafeCast__Exceeds160Bits,
    SafeCast__Exceeds152Bits,
    SafeCast__Exceeds144Bits,
    SafeCast__Exceeds136Bits,
    SafeCast__Exceeds128Bits,
    SafeCast__Exceeds120Bits,
    SafeCast__Exceeds112Bits,
    SafeCast__Exceeds104Bits,
    SafeCast__Exceeds96Bits,
    SafeCast__Exceeds88Bits,
    SafeCast__Exceeds80Bits,
    SafeCast__Exceeds72Bits,
    SafeCast__Exceeds64Bits,
    SafeCast__Exceeds56Bits,
    SafeCast__Exceeds48Bits,
    SafeCast__Exceeds40Bits,
    SafeCast__Exceeds32Bits,
    SafeCast__Exceeds24Bits,
    SafeCast__Exceeds16Bits,
    SafeCast__Exceeds8Bits
} from "../DLErrors.sol";

/// @title Discretized Liquidity Safe Cast Library
/// @author Bentoswap
/// @notice Helper contract used for converting uint values safely
library SafeCast {
    /// @notice Returns x on uint248 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint248
    function safe248(uint256 x) internal pure returns (uint248 y) {
        if ((y = uint248(x)) != x) revert SafeCast__Exceeds248Bits(x);
    }

    /// @notice Returns x on uint240 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint240
    function safe240(uint256 x) internal pure returns (uint240 y) {
        if ((y = uint240(x)) != x) revert SafeCast__Exceeds240Bits(x);
    }

    /// @notice Returns x on uint232 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint232
    function safe232(uint256 x) internal pure returns (uint232 y) {
        if ((y = uint232(x)) != x) revert SafeCast__Exceeds232Bits(x);
    }

    /// @notice Returns x on uint224 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint224
    function safe224(uint256 x) internal pure returns (uint224 y) {
        if ((y = uint224(x)) != x) revert SafeCast__Exceeds224Bits(x);
    }

    /// @notice Returns x on uint216 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint216
    function safe216(uint256 x) internal pure returns (uint216 y) {
        if ((y = uint216(x)) != x) revert SafeCast__Exceeds216Bits(x);
    }

    /// @notice Returns x on uint208 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint208
    function safe208(uint256 x) internal pure returns (uint208 y) {
        if ((y = uint208(x)) != x) revert SafeCast__Exceeds208Bits(x);
    }

    /// @notice Returns x on uint200 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint200
    function safe200(uint256 x) internal pure returns (uint200 y) {
        if ((y = uint200(x)) != x) revert SafeCast__Exceeds200Bits(x);
    }

    /// @notice Returns x on uint192 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint192
    function safe192(uint256 x) internal pure returns (uint192 y) {
        if ((y = uint192(x)) != x) revert SafeCast__Exceeds192Bits(x);
    }

    /// @notice Returns x on uint184 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint184
    function safe184(uint256 x) internal pure returns (uint184 y) {
        if ((y = uint184(x)) != x) revert SafeCast__Exceeds184Bits(x);
    }

    /// @notice Returns x on uint176 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint176
    function safe176(uint256 x) internal pure returns (uint176 y) {
        if ((y = uint176(x)) != x) revert SafeCast__Exceeds176Bits(x);
    }

    /// @notice Returns x on uint168 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint168
    function safe168(uint256 x) internal pure returns (uint168 y) {
        if ((y = uint168(x)) != x) revert SafeCast__Exceeds168Bits(x);
    }

    /// @notice Returns x on uint160 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint160
    function safe160(uint256 x) internal pure returns (uint160 y) {
        if ((y = uint160(x)) != x) revert SafeCast__Exceeds160Bits(x);
    }

    /// @notice Returns x on uint152 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint152
    function safe152(uint256 x) internal pure returns (uint152 y) {
        if ((y = uint152(x)) != x) revert SafeCast__Exceeds152Bits(x);
    }

    /// @notice Returns x on uint144 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint144
    function safe144(uint256 x) internal pure returns (uint144 y) {
        if ((y = uint144(x)) != x) revert SafeCast__Exceeds144Bits(x);
    }

    /// @notice Returns x on uint136 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint136
    function safe136(uint256 x) internal pure returns (uint136 y) {
        if ((y = uint136(x)) != x) revert SafeCast__Exceeds136Bits(x);
    }

    /// @notice Returns x on uint128 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint128
    function safe128(uint256 x) internal pure returns (uint128 y) {
        if ((y = uint128(x)) != x) revert SafeCast__Exceeds128Bits(x);
    }

    /// @notice Returns x on uint120 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint120
    function safe120(uint256 x) internal pure returns (uint120 y) {
        if ((y = uint120(x)) != x) revert SafeCast__Exceeds120Bits(x);
    }

    /// @notice Returns x on uint112 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint112
    function safe112(uint256 x) internal pure returns (uint112 y) {
        if ((y = uint112(x)) != x) revert SafeCast__Exceeds112Bits(x);
    }

    /// @notice Returns x on uint104 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint104
    function safe104(uint256 x) internal pure returns (uint104 y) {
        if ((y = uint104(x)) != x) revert SafeCast__Exceeds104Bits(x);
    }

    /// @notice Returns x on uint96 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint96
    function safe96(uint256 x) internal pure returns (uint96 y) {
        if ((y = uint96(x)) != x) revert SafeCast__Exceeds96Bits(x);
    }

    /// @notice Returns x on uint88 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint88
    function safe88(uint256 x) internal pure returns (uint88 y) {
        if ((y = uint88(x)) != x) revert SafeCast__Exceeds88Bits(x);
    }

    /// @notice Returns x on uint80 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint80
    function safe80(uint256 x) internal pure returns (uint80 y) {
        if ((y = uint80(x)) != x) revert SafeCast__Exceeds80Bits(x);
    }

    /// @notice Returns x on uint72 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint72
    function safe72(uint256 x) internal pure returns (uint72 y) {
        if ((y = uint72(x)) != x) revert SafeCast__Exceeds72Bits(x);
    }

    /// @notice Returns x on uint64 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint64
    function safe64(uint256 x) internal pure returns (uint64 y) {
        if ((y = uint64(x)) != x) revert SafeCast__Exceeds64Bits(x);
    }

    /// @notice Returns x on uint56 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint56
    function safe56(uint256 x) internal pure returns (uint56 y) {
        if ((y = uint56(x)) != x) revert SafeCast__Exceeds56Bits(x);
    }

    /// @notice Returns x on uint48 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint48
    function safe48(uint256 x) internal pure returns (uint48 y) {
        if ((y = uint48(x)) != x) revert SafeCast__Exceeds48Bits(x);
    }

    /// @notice Returns x on uint40 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint40
    function safe40(uint256 x) internal pure returns (uint40 y) {
        if ((y = uint40(x)) != x) revert SafeCast__Exceeds40Bits(x);
    }

    /// @notice Returns x on uint32 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint32
    function safe32(uint256 x) internal pure returns (uint32 y) {
        if ((y = uint32(x)) != x) revert SafeCast__Exceeds32Bits(x);
    }

    /// @notice Returns x on uint24 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint24
    function safe24(uint256 x) internal pure returns (uint24 y) {
        if ((y = uint24(x)) != x) revert SafeCast__Exceeds24Bits(x);
    }

    /// @notice Returns x on uint16 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint16
    function safe16(uint256 x) internal pure returns (uint16 y) {
        if ((y = uint16(x)) != x) revert SafeCast__Exceeds16Bits(x);
    }

    /// @notice Returns x on uint8 and check that it does not overflow
    /// @param x The value as an uint256
    /// @return y The value as an uint8
    function safe8(uint256 x) internal pure returns (uint8 y) {
        if ((y = uint8(x)) != x) revert SafeCast__Exceeds8Bits(x);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Discretized Liquidity Safe Math Helper Library
/// @author Bentoswap
/// @notice Helper contract used for calculating absolute value safely
library SafeMath {
    /// @notice absSub, can't underflow or overflow
    /// @param x The first value
    /// @param y The second value
    /// @return The result of abs(x - y)
    function absSub(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            return x > y ? x - y : y - x;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {BinHelper} from "./BinHelper.sol";
import {Constants} from "./Constants.sol";
import {FeeDistributionHelper} from "./FeeDistributionHelper.sol";
import {FeeHelper} from "./FeeHelper.sol";
import {Math512Bits} from "./Math512Bits.sol";
import {SafeMath} from "./SafeMath.sol";
import {IDLPair} from "../interfaces/IDLPair.sol";

/// @title Discretized Liquidity Swap Helper Library
/// @author Bentoswap
/// @notice Helper contract used for calculating swaps, fees and reserves changes
library SwapHelper {
    using Math512Bits for uint256;
    using FeeHelper for FeeHelper.FeeParameters;
    using SafeMath for uint256;
    using FeeDistributionHelper for FeeHelper.FeesDistribution;

    /// @notice Returns the swap amounts in the current bin
    /// @param bin The bin information
    /// @param fp The fee parameters
    /// @param activeId The active id of the pair
    /// @param swapForY Whether you've swapping token X for token Y (true) or token Y for token X (false)
    /// @param amountIn The amount sent by the user
    /// @return amountInToBin The amount of token that is added to the bin without the fees
    /// @return amountOutOfBin The amount of token that is removed from the bin
    /// @return fees The swap fees
    function getAmounts(
        IDLPair.Bin memory bin,
        FeeHelper.FeeParameters memory fp,
        uint256 activeId,
        bool swapForY,
        uint256 amountIn
    )
        internal
        pure
        returns (
            uint256 amountInToBin,
            uint256 amountOutOfBin,
            FeeHelper.FeesDistribution memory fees
        )
    {
        uint256 _price = BinHelper.getPriceFromId(activeId, fp.binStep);

        uint256 _reserve;
        uint256 _maxAmountInToBin;
        if (swapForY) {
            _reserve = bin.reserveY;
            _maxAmountInToBin = _reserve.shiftDivRoundUp(Constants.SCALE_OFFSET, _price);
        } else {
            _reserve = bin.reserveX;
            _maxAmountInToBin = _price.mulShiftRoundUp(_reserve, Constants.SCALE_OFFSET);
        }

        fp.updateVolatilityAccumulated(activeId);
        fees = fp.getFeeAmountDistribution(fp.getFeeAmount(_maxAmountInToBin));

        if (_maxAmountInToBin + fees.total <= amountIn) {
            amountInToBin = _maxAmountInToBin;
            amountOutOfBin = _reserve;
        } else {
            fees = fp.getFeeAmountDistribution(fp.getFeeAmountFrom(amountIn));
            amountInToBin = amountIn - fees.total;
            amountOutOfBin = swapForY
                ? _price.mulShiftRoundDown(amountInToBin, Constants.SCALE_OFFSET)
                : amountInToBin.shiftDivRoundDown(Constants.SCALE_OFFSET, _price);
            // Safety check in case rounding returns a higher value than expected
            if (amountOutOfBin > _reserve) amountOutOfBin = _reserve;
        }
    }

    /// @notice Update the fees of the pair and accumulated token per share of the bin
    /// @param bin The bin information
    /// @param pairFees The current fees of the pair information
    /// @param fees The fees amounts added to the pairFees
    /// @param swapForY whether the token sent was Y (true) or X (false)
    /// @param totalSupply The total supply of the token id
    function updateFees(
        IDLPair.Bin memory bin,
        FeeHelper.FeesDistribution memory pairFees,
        FeeHelper.FeesDistribution memory fees,
        bool swapForY,
        uint256 totalSupply
    ) internal pure {
        pairFees.total += fees.total;
        // unsafe math is fine because total >= protocol
        unchecked {
            pairFees.protocol += fees.protocol;
        }

        if (swapForY) {
            bin.accTokenXPerShare += fees.getTokenPerShare(totalSupply);
        } else {
            bin.accTokenYPerShare += fees.getTokenPerShare(totalSupply);
        }
    }

    /// @notice Update reserves
    /// @param bin The bin information
    /// @param pair The pair information
    /// @param swapForY whether the token sent was Y (true) or X (false)
    /// @param amountInToBin The amount of token that is added to the bin without fees
    /// @param amountOutOfBin The amount of token that is removed from the bin
    function updateReserves(
        IDLPair.Bin memory bin,
        IDLPair.PairInformation memory pair,
        bool swapForY,
        uint112 amountInToBin,
        uint112 amountOutOfBin
    ) internal pure {
        if (swapForY) {
            bin.reserveX += amountInToBin;

            unchecked {
                bin.reserveY -= amountOutOfBin;
                pair.reserveX += uint136(amountInToBin);
                pair.reserveY -= uint136(amountOutOfBin);
            }
        } else {
            bin.reserveY += amountInToBin;

            unchecked {
                bin.reserveX -= amountOutOfBin;
                pair.reserveX -= uint136(amountOutOfBin);
                pair.reserveY += uint136(amountInToBin);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {
    TokenHelper__TransferFailed,
    TokenHelper__NonContract,
    TokenHelper__CallFailed
} from "../DLErrors.sol";

/// @title Safe Transfer
/// @author Bentoswap
/// @notice Wrappers around ERC20 operations that throw on failure (when the token
/// contract returns false). Tokens that return no value (and instead revert or
/// throw on failure) are also supported, non-reverting calls are assumed to be
/// successful.
/// To use this library you can add a `using TokenHelper for IERC20;` statement to your contract,
/// which allows you to call the safe operation as `token.safeTransfer(...)`
library TokenHelper {
    /// @notice Transfers token only if the amount is greater than zero
    /// @param token The address of the token
    /// @param owner The owner of the tokens
    /// @param recipient The address of the recipient
    /// @param amount The amount to send
    function safeTransferFrom(
        IERC20 token,
        address owner,
        address recipient,
        uint256 amount
    ) internal {
        if (amount != 0) {
            bytes memory data = abi.encodeWithSelector(token.transferFrom.selector, owner, recipient, amount);

            bytes memory returnData = _callAndCatchError(address(token), data);

            if (returnData.length > 0 && !abi.decode(returnData, (bool))) revert TokenHelper__TransferFailed();
        }
    }

    /// @notice Transfers token only if the amount is greater than zero
    /// @param token The address of the token
    /// @param recipient The address of the recipient
    /// @param amount The amount to send
    function safeTransfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) internal {
        if (amount != 0) {
            bytes memory data = abi.encodeWithSelector(token.transfer.selector, recipient, amount);

            bytes memory returnData = _callAndCatchError(address(token), data);

            if (returnData.length > 0 && !abi.decode(returnData, (bool))) revert TokenHelper__TransferFailed();
        }
    }

    /// @notice Returns the amount of token received by the pair
    /// @param token The address of the token
    /// @param reserve The total reserve of token
    /// @param fees The total fees of token
    /// @return The amount received by the pair
    function received(
        IERC20 token,
        uint256 reserve,
        uint256 fees
    ) internal view returns (uint256) {
        uint256 _internalBalance;
        unchecked {
            _internalBalance = reserve + fees;
        }
        return token.balanceOf(address(this)) - _internalBalance;
    }

    /// @notice Private view function to perform a low level call on `target`
    /// @dev Revert if the call doesn't succeed
    /// @param target The address of the account
    /// @param data The data to execute on `target`
    /// @return returnData The data returned by the call
    function _callAndCatchError(address target, bytes memory data) private returns (bytes memory) {
        (bool success, bytes memory returnData) = target.call(data);

        if (success) {
            if (returnData.length == 0 && !_isContract(target)) revert TokenHelper__NonContract();
        } else {
            if (returnData.length == 0) revert TokenHelper__CallFailed();
            else {
                // Look for revert reason and bubble it up if present
                assembly {
                    revert(add(32, returnData), mload(returnData))
                }
            }
        }
        return returnData;
    }

    /// @notice Private view function to return if an address is a contract
    /// @dev It is unsafe to assume that an address for which this function returns
    /// false is an externally-owned account (EOA) and not a contract.
    ///
    /// Among others, `isContract` will return false for the following
    /// types of addresses:
    ///  - an externally-owned account
    ///  - a contract in construction
    ///  - an address where a contract will be created
    ///  - an address where a contract lived, but was destroyed
    /// @param account The address of the account
    /// @return Whether the account is a contract (true) or not (false)
    function _isContract(address account) private view returns (bool) {
        return account.code.length > 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {TreeMath__ErrorDepthSearch} from "../DLErrors.sol";
import {BitMath} from "./BitMath.sol";

/// @title Discretized Liquidity Tree Math Library
/// @author Bentoswap
/// @notice Helper contract used for finding closest bin with liquidity
library TreeMath {
    using BitMath for uint256;

    /// @notice Returns the first id that is non zero, corresponding to a bin with
    /// liquidity in it
    /// @param _tree The storage slot of the tree
    /// @param _binId the binId to start searching
    /// @param _rightSide Whether we're searching in the right side of the tree (true) or the left side (false)
    /// for the closest non zero bit on the right or the left
    /// @return The closest non zero bit on the right (or left) side of the tree
    function findFirstBin(
        mapping(uint256 => uint256)[3] storage _tree,
        uint24 _binId,
        bool _rightSide
    ) internal view returns (uint24) {
        unchecked {
            uint256 current;
            uint256 bit;

            (_binId, bit) = _getIdsFromAbove(_binId);

            // Search in depth 2
            if ((_rightSide && bit != 0) || (!_rightSide && bit != 255)) {
                current = _tree[2][_binId];
                bit = current.closestBit(uint8(bit), _rightSide);

                if (bit != type(uint256).max) {
                    return _getBottomId(_binId, uint24(bit));
                }
            }

            (_binId, bit) = _getIdsFromAbove(_binId);

            // Search in depth 1
            if ((_rightSide && bit != 0) || (!_rightSide && bit != 255)) {
                current = _tree[1][_binId];
                bit = current.closestBit(uint8(bit), _rightSide);

                if (bit != type(uint256).max) {
                    _binId = _getBottomId(_binId, uint24(bit));
                    current = _tree[2][_binId];

                    return _getBottomId(_binId, current.significantBit(_rightSide));
                }
            }

            // Search in depth 0
            current = _tree[0][0];
            bit = current.closestBit(uint8(_binId), _rightSide);
            if (bit == type(uint256).max) revert TreeMath__ErrorDepthSearch();

            current = _tree[1][bit];
            _binId = _getBottomId(uint24(bit), current.significantBit(_rightSide));

            current = _tree[2][_binId];
            return _getBottomId(_binId, current.significantBit(_rightSide));
        }
    }

    function addToTree(mapping(uint256 => uint256)[3] storage _tree, uint256 _id) internal {
        // add 1 at the right indices
        uint256 _idDepth2 = _id >> 8;
        uint256 _idDepth1 = _id >> 16;

        _tree[2][_idDepth2] |= 1 << (_id & 255);
        _tree[1][_idDepth1] |= 1 << (_idDepth2 & 255);
        _tree[0][0] |= 1 << _idDepth1;
    }

    function removeFromTree(mapping(uint256 => uint256)[3] storage _tree, uint256 _id) internal {
        unchecked {
            // removes 1 at the right indices
            uint256 _idDepth2 = _id >> 8;
            // Optimization of `_tree[2][_idDepth2] & (type(uint256).max - (1 << (_id & 255)))`
            uint256 _newLeafValue = _tree[2][_idDepth2] & (type(uint256).max ^ (1 << (_id & 255)));
            _tree[2][_idDepth2] = _newLeafValue;
            if (_newLeafValue == 0) {
                uint256 _idDepth1 = _id >> 16;
                // Optimization of `_tree[1][_idDepth1] & (type(uint256).max - (1 << (_idDepth2 & 255)))`
                _newLeafValue = _tree[1][_idDepth1] & (type(uint256).max ^ (1 << (_idDepth2 & 255)));
                _tree[1][_idDepth1] = _newLeafValue;
                if (_newLeafValue == 0) {
                    // Optimization of `type(uint256).max - (1 << _idDepth1)`
                    _tree[0][0] &= type(uint256).max ^ (1 << _idDepth1);
                }
            }
        }
    }

    /// @notice Private pure function to return the ids from above
    /// @param _id The current id
    /// @return The branch id from above
    /// @return The leaf id from above
    function _getIdsFromAbove(uint24 _id) private pure returns (uint24, uint24) {
        // Optimization of `(_id / 256, _id % 256)`
        return (_id >> 8, _id & 255);
    }

    /// @notice Private pure function to return the bottom id
    /// @param _branchId The branch id
    /// @param _leafId The leaf id
    /// @return The bottom branchId
    function _getBottomId(uint24 _branchId, uint24 _leafId) private pure returns (uint24) {
        // Optimization of `_branchId * 256 + _leafId`
        // Can't overflow as _leafId would fit in uint8, but kept as uint24 to optimize castings
        unchecked {
            return (_branchId << 8) + _leafId;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {
    DLPair__CompositionFactorFlawed,
    DLPair__DistributionsOverflow,
    DLPair__InsufficientLiquidityBurned,
    DLPair__InsufficientLiquidityMinted,
    DLPair__WrongLengths
} from "../../DLErrors.sol";
import {BinHelper} from "../../libraries/BinHelper.sol";
import {Constants} from "../../libraries/Constants.sol";
import {FeeHelper} from "../../libraries/FeeHelper.sol";
import {Math512Bits} from "../../libraries/Math512Bits.sol";
import {SafeCast} from "../../libraries/SafeCast.sol";
import {SwapHelper} from "../../libraries/SwapHelper.sol";
import {TokenHelper, IERC20} from "../../libraries/TokenHelper.sol";
import {TreeMath} from "../../libraries/TreeMath.sol";
import {DLPairOracle, IDLFactory} from "./DLPairOracle.sol";

/// @title Discretized Liquidity Pair
/// @author Bentoswap
/// @notice Contract used to manage the receipt token portion of the pair contract
abstract contract DLPairToken is DLPairOracle {
    using FeeHelper for FeeHelper.FeeParameters;
    using Math512Bits for uint256;
    using SafeCast for uint256;
    using SwapHelper for Bin;
    using TokenHelper for IERC20;
    using TreeMath for mapping(uint256 => uint256)[3];

    /// @notice Set the factory address
    /// @param _factory The address of the factory
    constructor(IDLFactory _factory) DLPairOracle(_factory) { }

    /// @notice Performs a low level add, this needs to be called from a contract which performs important safety checks
    /// and transfer the amounts of tokens (can be tokenX and/or tokenY)
    /// @dev Will refund any tokenX or tokenY amount sent in excess to `_to`
    /// @param _ids The list of ids to add liquidity
    /// @param _distributionX The distribution of tokenX with sum(_distributionX) = 1e18 (100%) or 0 (0%)
    /// @param _distributionY The distribution of tokenY with sum(_distributionY) = 1e18 (100%) or 0 (0%)
    /// @param _to The address of the recipient
    /// @return The amount of token X that was added to the pair
    /// @return The amount of token Y that was added to the pair
    /// @return liquidityMinted Amount of DLToken minted
    function _mint(
        uint256[] calldata _ids,
        uint256[] calldata _distributionX,
        uint256[] calldata _distributionY,
        address _to
    )
        internal
        returns (
            uint256,
            uint256,
            uint256[] memory liquidityMinted
        )
    {
        if (_ids.length == 0 || _ids.length != _distributionX.length || _ids.length != _distributionY.length)
            revert DLPair__WrongLengths();

        PairInformation memory _pair = _pairInformation;

        FeeHelper.FeeParameters memory _fp = _feeParameters;

        MintInfo memory _mintInfo;

        _mintInfo.amountXIn = tokenX.received(_pair.reserveX, _pair.feesX.total).safe128();
        _mintInfo.amountYIn = tokenY.received(_pair.reserveY, _pair.feesY.total).safe128();

        liquidityMinted = new uint256[](_ids.length);

        unchecked {
            for (uint256 i; i < _ids.length; ++i) {
                _mintInfo.id = _ids[i].safe24();
                Bin memory _bin = _bins[_mintInfo.id];

                if (_bin.reserveX == 0 && _bin.reserveY == 0) _tree.addToTree(_mintInfo.id);

                _mintInfo.distributionX = _distributionX[i];
                _mintInfo.distributionY = _distributionY[i];

                if (
                    _mintInfo.distributionX > Constants.PRECISION ||
                    _mintInfo.distributionY > Constants.PRECISION ||
                    (_mintInfo.totalDistributionX += _mintInfo.distributionX) > Constants.PRECISION ||
                    (_mintInfo.totalDistributionY += _mintInfo.distributionY) > Constants.PRECISION
                ) revert DLPair__DistributionsOverflow();

                // Can't overflow as amounts are uint128 and distributions are smaller or equal to 1e18
                _mintInfo.amountX = (_mintInfo.amountXIn * _mintInfo.distributionX) / Constants.PRECISION;
                _mintInfo.amountY = (_mintInfo.amountYIn * _mintInfo.distributionY) / Constants.PRECISION;

                uint256 _price = BinHelper.getPriceFromId(_mintInfo.id, _fp.binStep);
                if (_mintInfo.id >= _pair.activeId) {
                    if (_mintInfo.id == _pair.activeId) {
                        uint256 _totalSupply = totalSupply(_mintInfo.id);

                        uint256 _receivedX;
                        uint256 _receivedY;
                        {
                            uint256 _userL = _price.mulShiftRoundDown(_mintInfo.amountX, Constants.SCALE_OFFSET) +
                                _mintInfo.amountY;

                            uint256 _supply = _totalSupply + _userL;
                            _receivedX = (_userL * (uint256(_bin.reserveX) + _mintInfo.amountX)) / _supply;
                            _receivedY = (_userL * (uint256(_bin.reserveY) + _mintInfo.amountY)) / _supply;
                        }

                        _fp.updateVariableFeeParameters(_mintInfo.id);

                        if (_mintInfo.amountX > _receivedX) {
                            FeeHelper.FeesDistribution memory _fees = _fp.getFeeAmountDistribution(
                                _fp.getFeeAmountForC(_mintInfo.amountX - _receivedX)
                            );

                            _mintInfo.amountX -= _fees.total;
                            _mintInfo.activeFeeX += _fees.total;

                            _bin.updateFees(_pair.feesX, _fees, true, _totalSupply);

                            emit CompositionFee(msg.sender, _to, _mintInfo.id, _fees.total, 0);
                        }
                        if (_mintInfo.amountY > _receivedY) {
                            FeeHelper.FeesDistribution memory _fees = _fp.getFeeAmountDistribution(
                                _fp.getFeeAmountForC(_mintInfo.amountY - _receivedY)
                            );

                            _mintInfo.amountY -= _fees.total;
                            _mintInfo.activeFeeY += _fees.total;

                            _bin.updateFees(_pair.feesY, _fees, false, _totalSupply);

                            emit CompositionFee(msg.sender, _to, _mintInfo.id, 0, _fees.total);
                        }
                    } else if (_mintInfo.amountY != 0) revert DLPair__CompositionFactorFlawed(_mintInfo.id);
                } else if (_mintInfo.amountX != 0) revert DLPair__CompositionFactorFlawed(_mintInfo.id);

                uint256 _liquidity = _price.mulShiftRoundDown(_mintInfo.amountX, Constants.SCALE_OFFSET) +
                    _mintInfo.amountY;

                if (_liquidity == 0) revert DLPair__InsufficientLiquidityMinted(_mintInfo.id);

                liquidityMinted[i] = _liquidity;

                // The addition can't overflow as the amounts are checked to be uint128 and the reserves are uint112
                _bin.reserveX = (_mintInfo.amountX + _bin.reserveX).safe112();
                _bin.reserveY = (_mintInfo.amountY + _bin.reserveY).safe112();

                // The addition or the cast can't overflow as it would have reverted during the L568 and L569 if amounts were greater than uint112
                _pair.reserveX += uint112(_mintInfo.amountX);
                _pair.reserveY += uint112(_mintInfo.amountY);

                _mintInfo.amountXAddedToPair += _mintInfo.amountX;
                _mintInfo.amountYAddedToPair += _mintInfo.amountY;

                _bins[_mintInfo.id] = _bin;
                _mint(_to, _mintInfo.id, _liquidity);

                emit LiquidityAdded(
                    msg.sender,
                    _to,
                    _mintInfo.id,
                    _liquidity,
                    _mintInfo.amountX,
                    _mintInfo.amountY,
                    _mintInfo.distributionX,
                    _mintInfo.distributionY
                );
            }

            _pairInformation = _pair;

            uint256 _amountAddedPlusFee = _mintInfo.amountXAddedToPair + _mintInfo.activeFeeX;
            // If user sent too much tokens, We send them back the excess
            if (_mintInfo.amountXIn > _amountAddedPlusFee) {
                tokenX.safeTransfer(_to, _mintInfo.amountXIn - _amountAddedPlusFee);
            }

            _amountAddedPlusFee = _mintInfo.amountYAddedToPair + _mintInfo.activeFeeY;
            if (_mintInfo.amountYIn > _amountAddedPlusFee) {
                tokenY.safeTransfer(_to, _mintInfo.amountYIn - _amountAddedPlusFee);
            }
        }

        return (_mintInfo.amountXAddedToPair, _mintInfo.amountYAddedToPair, liquidityMinted);
    }

    /// @notice Performs a low level remove, this needs to be called from a contract which performs important safety checks
    /// and transfer the amounts of DLTokens to burn (only the ids that are in `_ids` or they might be lost)
    /// @param _ids The IDs for which the user wants to remove his liquidity
    /// @param _amounts The amount of token to burn
    /// @param _to The address of the recipient
    /// @return amountX The amount of token X sent to `_to`
    /// @return amountY The amount of token Y sent to `_to`
    function _burn(
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        address _to
    ) internal returns (uint256 amountX, uint256 amountY) {
        if (_ids.length == 0 || _ids.length != _amounts.length) revert DLPair__WrongLengths();

        (uint256 _pairReserveX, uint256 _pairReserveY, uint256 _activeId) = _getReservesAndId();
        unchecked {
            for (uint256 i; i < _ids.length; ++i) {
                uint24 _id = _ids[i].safe24();
                uint256 _amountToBurn = _amounts[i];

                if (_amountToBurn == 0) revert DLPair__InsufficientLiquidityBurned(_id);

                (uint256 _reserveX, uint256 _reserveY) = _getBin(_id);

                uint256 _totalSupply = totalSupply(_id);

                uint256 _amountX;
                uint256 _amountY;

                if (_id <= _activeId) {
                    _amountY = _amountToBurn.mulDivRoundDown(_reserveY, _totalSupply);

                    amountY += _amountY;
                    _reserveY -= _amountY;
                    _pairReserveY -= _amountY;
                }
                if (_id >= _activeId) {
                    _amountX = _amountToBurn.mulDivRoundDown(_reserveX, _totalSupply);

                    amountX += _amountX;
                    _reserveX -= _amountX;
                    _pairReserveX -= _amountX;
                }

                if (_reserveX == 0 && _reserveY == 0) _tree.removeFromTree(_id);

                _saveBinReserves(_id, _reserveX, _reserveY);

                _burn(address(this), _id, _amountToBurn);

                emit LiquidityRemoved(msg.sender, _to, _id, _amountToBurn, _amountX, _amountY);
            }
        }

        // Optimization to do only 2 sstore
        _pairInformation.reserveX = uint136(_pairReserveX);
        _pairInformation.reserveY = uint136(_pairReserveY);

        tokenX.safeTransfer(_to, amountX);
        tokenY.safeTransfer(_to, amountY);
    }

    /** Internal Functions **/

    /// @notice Collect and update fees before any token transfer, mint or burn
    /// @param _from The address of the owner of the token
    /// @param _to The address of the recipient of the  token
    /// @param _id The id the token being transferred
    /// @param _amount The amount of the token type being transferred
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount
    ) internal override {
        unchecked {
            super._beforeTokenTransfer(_from, _to, _id, _amount);

            if (_from != _to) {
                Bin memory _bin = _bins[_id];
                if (_from != address(0) && _from != address(this)) {
                    uint256 _balanceFrom = balanceOf(_from, _id);

                    _cacheFees(_bin, _from, _id, _balanceFrom, _balanceFrom - _amount);
                }

                if (_to != address(0) && _to != address(this)) {
                    uint256 _balanceTo = balanceOf(_to, _id);

                    _cacheFees(_bin, _to, _id, _balanceTo, _balanceTo + _amount);
                }
            }
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

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {FeeHelper} from "../libraries/FeeHelper.sol";
import {IDLFactory} from "./IDLFactory.sol";
import {IDLFlashLoanCallback} from "./IDLFlashLoanCallback.sol";

/// @title Discretized Liquidity Pair Interface
/// @author Bentoswap
/// @notice Required interface of DLPair contract
interface IDLPair {
    /// @dev Structure to store the reserves of bins:
    /// - reserveX: The current reserve of tokenX of the bin
    /// - reserveY: The current reserve of tokenY of the bin
    struct Bin {
        uint112 reserveX;
        uint112 reserveY;
        uint256 accTokenXPerShare;
        uint256 accTokenYPerShare;
    }

    /// @dev Structure to store the information of the pair such as:
    /// slot0:
    /// - activeId: The current id used for swaps, this is also linked with the price
    /// - reserveX: The sum of amounts of tokenX across all bins
    /// slot1:
    /// - reserveY: The sum of amounts of tokenY across all bins
    /// - oracleSampleLifetime: The lifetime of an oracle sample
    /// - oracleSize: The current size of the oracle, can be increase by users
    /// - oracleActiveSize: The current active size of the oracle, composed only from non empty data sample
    /// - oracleLastTimestamp: The current last timestamp at which a sample was added to the circular buffer
    /// - oracleId: The current id of the oracle
    /// slot2:
    /// - feesX: The current amount of fees to distribute in tokenX (total, protocol)
    /// slot3:
    /// - feesY: The current amount of fees to distribute in tokenY (total, protocol)
    struct PairInformation {
        uint24 activeId;
        uint136 reserveX;
        uint136 reserveY;
        uint16 oracleSampleLifetime;
        uint16 oracleSize;
        uint16 oracleActiveSize;
        uint40 oracleLastTimestamp;
        uint16 oracleId;
        FeeHelper.FeesDistribution feesX;
        FeeHelper.FeesDistribution feesY;
    }

    /// @dev Structure to store the debts of users
    /// - debtX: The tokenX's debt
    /// - debtY: The tokenY's debt
    struct Debts {
        uint256 debtX;
        uint256 debtY;
    }

    /// @dev Structure to store fees:
    /// - tokenX: The amount of fees of token X
    /// - tokenY: The amount of fees of token Y
    struct Fees {
        uint128 tokenX;
        uint128 tokenY;
    }

    /// @dev Structure to minting informations:
    /// - amountXIn: The amount of token X sent
    /// - amountYIn: The amount of token Y sent
    /// - amountXAddedToPair: The amount of token X that have been actually added to the pair
    /// - amountYAddedToPair: The amount of token Y that have been actually added to the pair
    /// - activeFeeX: Fees X currently generated
    /// - activeFeeY: Fees Y currently generated
    /// - totalDistributionX: Total distribution of token X. Should be 1e18 (100%) or 0 (0%)
    /// - totalDistributionY: Total distribution of token Y. Should be 1e18 (100%) or 0 (0%)
    /// - id: Id of the current working bin when looping on the distribution array
    /// - amountX: The amount of token X deposited in the current bin
    /// - amountY: The amount of token Y deposited in the current bin
    /// - distributionX: Distribution of token X for the current working bin
    /// - distributionY: Distribution of token Y for the current working bin
    struct MintInfo {
        uint256 amountXIn;
        uint256 amountYIn;
        uint256 amountXAddedToPair;
        uint256 amountYAddedToPair;
        uint256 activeFeeX;
        uint256 activeFeeY;
        uint256 totalDistributionX;
        uint256 totalDistributionY;
        uint256 id;
        uint256 amountX;
        uint256 amountY;
        uint256 distributionX;
        uint256 distributionY;
    }

    event Swap(
        address indexed sender,
        address indexed recipient,
        uint24 indexed id,
        uint256 amountXIn,
        uint256 amountYIn,
        uint256 amountXOut,
        uint256 amountYOut,
        uint256 volatilityAccumulated,
        uint256 feesX,
        uint256 feesY
    );

    event FlashLoan(
        address indexed sender,
        IDLFlashLoanCallback indexed receiver,
        IERC20 token,
        uint256 amount,
        uint256 fee
    );

    event LiquidityAdded(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        uint256 minted,
        uint256 amountX,
        uint256 amountY,
        uint256 distributionX,
        uint256 distributionY
    );

    event CompositionFee(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        uint256 feesX,
        uint256 feesY
    );

    event LiquidityRemoved(
        address indexed sender,
        address indexed recipient,
        uint256 indexed id,
        uint256 burned,
        uint256 amountX,
        uint256 amountY
    );

    event FeesCollected(address indexed sender, address indexed recipient, uint256 amountX, uint256 amountY);

    event ProtocolFeesCollected(address indexed sender, address indexed recipient, uint256 amountX, uint256 amountY);

    event OracleSizeIncreased(uint256 previousSize, uint256 newSize);

    function tokenX() external view returns (IERC20);

    function tokenY() external view returns (IERC20);

    function factory() external view returns (IDLFactory);

    function getReservesAndId()
        external
        view
        returns (
            uint256 reserveX,
            uint256 reserveY,
            uint256 activeId
        );

    function getGlobalFees()
        external
        view
        returns (
            uint128 feesXTotal,
            uint128 feesYTotal,
            uint128 feesXProtocol,
            uint128 feesYProtocol
        );

    function getOracleParameters()
        external
        view
        returns (
            uint256 oracleSampleLifetime,
            uint256 oracleSize,
            uint256 oracleActiveSize,
            uint256 oracleLastTimestamp,
            uint256 oracleId,
            uint256 min,
            uint256 max
        );

    function getOracleSampleFrom(uint256 timeDelta)
        external
        view
        returns (
            uint256 cumulativeId,
            uint256 cumulativeAccumulator,
            uint256 cumulativeBinCrossed
        );

    function feeParameters() external view returns (FeeHelper.FeeParameters memory);

    function findFirstNonEmptyBinId(uint24 id_, bool sentTokenY) external view returns (uint24 id);

    function getBin(uint24 id) external view returns (uint256 reserveX, uint256 reserveY);

    function pendingFees(address account, uint256[] memory ids)
        external
        view
        returns (uint256 amountX, uint256 amountY);

    function swap(bool sentTokenY, address to) external returns (uint256 amountXOut, uint256 amountYOut);

    function flashLoan(
        IDLFlashLoanCallback receiver,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external;

    function mint(
        uint256[] calldata ids,
        uint256[] calldata distributionX,
        uint256[] calldata distributionY,
        address to
    )
        external
        returns (
            uint256 amountXAddedToPair,
            uint256 amountYAddedToPair,
            uint256[] memory liquidityMinted
        );

    function burn(
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address to
    ) external returns (uint256 amountX, uint256 amountY);

    function increaseOracleLength(uint16 newSize) external;

    function collectFees(address account, uint256[] calldata ids) external returns (uint256 amountX, uint256 amountY);

    function collectProtocolFees() external returns (uint128 amountX, uint128 amountY);

    function setFeesParameters(bytes32 packedFeeParameters) external;

    function forceDecay() external;

    function initialize(
        IERC20 tokenX,
        IERC20 tokenY,
        uint24 activeId,
        uint16 sampleLifetime,
        bytes32 packedFeeParameters
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Discretized Liquidity Pending Ownable Interface
/// @author Bentoswap
/// @notice Required interface of Pending Ownable contract used for DLFactory
interface IPendingOwnable {
    event PendingOwnerSet(address indexed pendingOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address pendingOwner) external;

    function revokePendingOwner() external;

    function becomeOwner() external;

    function renounceOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Constants} from "./Constants.sol";
import {SafeCast} from "./SafeCast.sol";
import {SafeMath} from "./SafeMath.sol";

/// @title Discretized Liquidity Fee Helper Library
/// @author Bentoswap
/// @notice Helper contract used for fees calculation
library FeeHelper {
    using SafeCast for uint256;
    using SafeMath for uint256;

    /// @dev Structure to store the protocol fees:
    /// - binStep: The bin step
    /// - baseFactor: The base factor
    /// - filterPeriod: The filter period, where the fees stays constant
    /// - decayPeriod: The decay period, where the fees are halved
    /// - reductionFactor: The reduction factor, used to calculate the reduction of the accumulator
    /// - variableFeeControl: The variable fee control, used to control the variable fee, can be 0 to disable them
    /// - protocolShare: The share of fees sent to protocol
    /// - maxVolatilityAccumulated: The max value of volatility accumulated
    /// - volatilityAccumulated: The value of volatility accumulated
    /// - volatilityReference: The value of volatility reference
    /// - indexRef: The index reference
    /// - time: The last time the accumulator was called
    struct FeeParameters {
        // 144 lowest bits in slot
        uint16 binStep;
        uint16 baseFactor;
        uint16 filterPeriod;
        uint16 decayPeriod;
        uint16 reductionFactor;
        uint24 variableFeeControl;
        uint16 protocolShare;
        uint24 maxVolatilityAccumulated;
        // 112 highest bits in slot
        uint24 volatilityAccumulated;
        uint24 volatilityReference;
        uint24 indexRef;
        uint40 time;
    }

    /// @dev Structure used during swaps to distributes the fees:
    /// - total: The total amount of fees
    /// - protocol: The amount of fees reserved for protocol
    struct FeesDistribution {
        uint128 total;
        uint128 protocol;
    }

    /// @notice Update the value of the volatility accumulated
    /// @param _fp The current fee parameters
    /// @param _activeId The current active id
    function updateVariableFeeParameters(FeeParameters memory _fp, uint256 _activeId) internal view {
        uint256 _deltaT = block.timestamp - _fp.time;

        if (_deltaT >= _fp.filterPeriod || _fp.time == 0) {
            _fp.indexRef = uint24(_activeId);
            if (_deltaT < _fp.decayPeriod) {
                unchecked {
                    // This can't overflow as `reductionFactor <= BASIS_POINT_MAX`
                    _fp.volatilityReference = uint24(
                        (uint256(_fp.reductionFactor) * _fp.volatilityAccumulated) / Constants.BASIS_POINT_MAX
                    );
                }
            } else {
                _fp.volatilityReference = 0;
            }
        }

        _fp.time = (block.timestamp).safe40();

        updateVolatilityAccumulated(_fp, _activeId);
    }

    /// @notice Update the volatility accumulated
    /// @param _fp The fee parameter
    /// @param _activeId The current active id
    function updateVolatilityAccumulated(FeeParameters memory _fp, uint256 _activeId) internal pure {
        uint256 volatilityAccumulated = (_activeId.absSub(_fp.indexRef) * Constants.BASIS_POINT_MAX) +
            _fp.volatilityReference;
        _fp.volatilityAccumulated = volatilityAccumulated > _fp.maxVolatilityAccumulated
            ? _fp.maxVolatilityAccumulated
            : uint24(volatilityAccumulated);
    }

    /// @notice Returns the base fee added to a swap, with 18 decimals
    /// @param _fp The current fee parameters
    /// @return The fee with 18 decimals precision
    function getBaseFee(FeeParameters memory _fp) internal pure returns (uint256) {
        unchecked {
            return uint256(_fp.baseFactor) * _fp.binStep * 1e10;
        }
    }

    /// @notice Returns the variable fee added to a swap, with 18 decimals
    /// @param _fp The current fee parameters
    /// @return variableFee The variable fee with 18 decimals precision
    function getVariableFee(FeeParameters memory _fp) internal pure returns (uint256 variableFee) {
        if (_fp.variableFeeControl != 0) {
            // Can't overflow as the max value is `max(uint24) * (max(uint24) * max(uint16)) ** 2 < max(uint104)`
            // It returns 18 decimals as:
            // decimals(variableFeeControl * (volatilityAccumulated * binStep)**2 / 100) = 4 + (4 + 4) * 2 - 2 = 18
            unchecked {
                uint256 _prod = uint256(_fp.volatilityAccumulated) * _fp.binStep;
                variableFee = (_prod * _prod * _fp.variableFeeControl + 99) / 100;
            }
        }
    }

    /// @notice Return the amount of fees from an amount
    /// @dev Rounds amount up, follows `amount = amountWithFees - getFeeAmountFrom(fp, amountWithFees)`
    /// @param _fp The current fee parameter
    /// @param _amountWithFees The amount of token sent
    /// @return The fee amount from the amount sent
    function getFeeAmountFrom(FeeParameters memory _fp, uint256 _amountWithFees) internal pure returns (uint256) {
        return (_amountWithFees * getTotalFee(_fp) + Constants.PRECISION - 1) / (Constants.PRECISION);
    }

    /// @notice Return the fees to add to an amount
    /// @dev Rounds amount up, follows `amountWithFees = amount + getFeeAmount(fp, amount)`
    /// @param _fp The current fee parameter
    /// @param _amount The amount of token sent
    /// @return The fee amount to add to the amount
    function getFeeAmount(FeeParameters memory _fp, uint256 _amount) internal pure returns (uint256) {
        uint256 _fee = getTotalFee(_fp);
        uint256 _denominator = Constants.PRECISION - _fee;
        return (_amount * _fee + _denominator - 1) / _denominator;
    }

    /// @notice Return the fees added when an user adds liquidity and change the ratio in the active bin
    /// @dev Rounds amount up
    /// @param _fp The current fee parameter
    /// @param _amountWithFees The amount of token sent
    /// @return The fee amount
    function getFeeAmountForC(FeeParameters memory _fp, uint256 _amountWithFees) internal pure returns (uint256) {
        uint256 _fee = getTotalFee(_fp);
        uint256 _denominator = Constants.PRECISION * Constants.PRECISION;
        return (_amountWithFees * _fee * (_fee + Constants.PRECISION) + _denominator - 1) / _denominator;
    }

    /// @notice Return the fees distribution added to an amount
    /// @param _fp The current fee parameter
    /// @param _fees The fee amount
    /// @return fees The fee distribution
    function getFeeAmountDistribution(FeeParameters memory _fp, uint256 _fees)
        internal
        pure
        returns (FeesDistribution memory fees)
    {
        fees.total = _fees.safe128();
        // unsafe math is fine because total >= protocol
        unchecked {
            fees.protocol = uint128((_fees * _fp.protocolShare) / Constants.BASIS_POINT_MAX);
        }
    }

    /// @notice Return the total fee, i.e. baseFee + variableFee
    /// @param _fp The current fee parameter
    /// @return The total fee, with 18 decimals
    function getTotalFee(FeeParameters memory _fp) private pure returns (uint256) {
        unchecked {
            return getBaseFee(_fp) + getVariableFee(_fp);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Discretized Liquidity Buffer Library
/// @author Bentoswap
/// @notice Helper contract used for modulo calculation
library Buffer {
    /// @notice Internal function to do positive (x - 1) % n
    /// @param x The value
    /// @param n The modulo value
    /// @return result The result
    function before(uint256 x, uint256 n) internal pure returns (uint256 result) {
        assembly {
            if gt(n, 0) {
                switch x
                case 0 {
                    result := sub(n, 1)
                }
                default {
                    result := mod(sub(x, 1), n)
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Decoder} from "./Decoder.sol";
import {Encoder} from "./Encoder.sol";

/// @title Discretized Liquidity Sample Helper Library
/// @author Bentoswap
/// @notice Helper contract used for oracle samples operations
library Samples {
    using Encoder for uint256;
    using Decoder for bytes32;

    ///  [ cumulativeBinCrossed | cumulativeVolatilityAccumulated | cumulativeId | timestamp | initialized ]
    ///  [        uint87        |              uint64             |    uint64    |   uint40  |    bool1    ]
    /// MSB                                                                                               LSB

    uint256 private constant _OFFSET_INITIALIZED = 0;
    uint256 private constant _MASK_INITIALIZED = 1;

    uint256 private constant _OFFSET_TIMESTAMP = 1;
    uint256 private constant _MASK_TIMESTAMP = type(uint40).max;

    uint256 private constant _OFFSET_CUMULATIVE_ID = 41;
    uint256 private constant _MASK_CUMULATIVE_ID = type(uint64).max;

    uint256 private constant _OFFSET_CUMULATIVE_VolatilityAccumulated = 105;
    uint256 private constant _MASK_CUMULATIVE_VolatilityAccumulated = type(uint64).max;

    uint256 private constant _OFFSET_CUMULATIVE_BIN_CROSSED = 169;
    uint256 private constant _MASK_CUMULATIVE_BIN_CROSSED = 0x7fffffffffffffffffffff;

    /// @notice Function to update a sample
    /// @param _lastSample The latest sample of the oracle
    /// @param _activeId The active index of the pair during the latest swap
    /// @param _volatilityAccumulated The volatility accumulated of the pair during the latest swap
    /// @param _binCrossed The bin crossed during the latest swap
    /// @return packedSample The packed sample as bytes32
    function update(
        bytes32 _lastSample,
        uint256 _activeId,
        uint256 _volatilityAccumulated,
        uint256 _binCrossed
    ) internal view returns (bytes32 packedSample) {
        uint256 _deltaTime = block.timestamp - timestamp(_lastSample);

        // cumulative can overflow without any issue as what matter is the delta cumulative.
        // It would be an issue if 2 overflows would happen but way too much time should elapsed for it to happen.
        // The delta calculation needs to be unchecked math to allow for it to overflow again.
        unchecked {
            uint256 _cumulativeId = cumulativeId(_lastSample) + _activeId * _deltaTime;
            uint256 _cumulativeVolatilityAccumulated = cumulativeVolatilityAccumulated(_lastSample) +
                _volatilityAccumulated *
                _deltaTime;
            uint256 _cumulativeBinCrossed = cumulativeBinCrossed(_lastSample) + _binCrossed * _deltaTime;

            return pack(_cumulativeBinCrossed, _cumulativeVolatilityAccumulated, _cumulativeId, block.timestamp, 1);
        }
    }

    /// @notice Function to pack cumulative values
    /// @param _cumulativeBinCrossed The cumulative bin crossed
    /// @param _cumulativeVolatilityAccumulated The cumulative volatility accumulated
    /// @param _cumulativeId The cumulative index
    /// @param _timestamp The timestamp
    /// @param _initialized The initialized value
    /// @return packedSample The packed sample as bytes32
    function pack(
        uint256 _cumulativeBinCrossed,
        uint256 _cumulativeVolatilityAccumulated,
        uint256 _cumulativeId,
        uint256 _timestamp,
        uint256 _initialized
    ) internal pure returns (bytes32 packedSample) {
        return
            _cumulativeBinCrossed.encode(_MASK_CUMULATIVE_BIN_CROSSED, _OFFSET_CUMULATIVE_BIN_CROSSED) |
            _cumulativeVolatilityAccumulated.encode(
                _MASK_CUMULATIVE_VolatilityAccumulated,
                _OFFSET_CUMULATIVE_VolatilityAccumulated
            ) |
            _cumulativeId.encode(_MASK_CUMULATIVE_ID, _OFFSET_CUMULATIVE_ID) |
            _timestamp.encode(_MASK_TIMESTAMP, _OFFSET_TIMESTAMP) |
            _initialized.encode(_MASK_INITIALIZED, _OFFSET_INITIALIZED);
    }

    /// @notice View function to return the initialized value
    /// @param _packedSample The packed sample
    /// @return The initialized value
    function initialized(bytes32 _packedSample) internal pure returns (uint256) {
        return _packedSample.decode(_MASK_INITIALIZED, _OFFSET_INITIALIZED);
    }

    /// @notice View function to return the timestamp value
    /// @param _packedSample The packed sample
    /// @return The timestamp value
    function timestamp(bytes32 _packedSample) internal pure returns (uint256) {
        return _packedSample.decode(_MASK_TIMESTAMP, _OFFSET_TIMESTAMP);
    }

    /// @notice View function to return the cumulative id value
    /// @param _packedSample The packed sample
    /// @return The cumulative id value
    function cumulativeId(bytes32 _packedSample) internal pure returns (uint256) {
        return _packedSample.decode(_MASK_CUMULATIVE_ID, _OFFSET_CUMULATIVE_ID);
    }

    /// @notice View function to return the cumulative volatility accumulated value
    /// @param _packedSample The packed sample
    /// @return The cumulative volatility accumulated value
    function cumulativeVolatilityAccumulated(bytes32 _packedSample) internal pure returns (uint256) {
        return _packedSample.decode(_MASK_CUMULATIVE_VolatilityAccumulated, _OFFSET_CUMULATIVE_VolatilityAccumulated);
    }

    /// @notice View function to return the cumulative bin crossed value
    /// @param _packedSample The packed sample
    /// @return The cumulative bin crossed value
    function cumulativeBinCrossed(bytes32 _packedSample) internal pure returns (uint256) {
        return _packedSample.decode(_MASK_CUMULATIVE_BIN_CROSSED, _OFFSET_CUMULATIVE_BIN_CROSSED);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {Constants} from "./Constants.sol";
import {
    BinHelper__BinStepOverflows,
    BinHelper__IdOverflows
} from "../DLErrors.sol";
import {Math128x128} from "./Math128x128.sol";

/// @title Discretized Liquidity Bin Helper Library
/// @author Bentoswap
/// @notice Contract used to convert bin ID to price and back
library BinHelper {
    using Math128x128 for uint256;

    int256 private constant REAL_ID_SHIFT = 1 << 23;

    /// @notice Returns the id corresponding to the given price
    /// @dev The id may be inaccurate due to rounding issues, always trust getPriceFromId rather than
    /// getIdFromPrice
    /// @param _price The price of y per x as a 128.128-binary fixed-point number
    /// @param _binStep The bin step
    /// @return The id corresponding to this price
    function getIdFromPrice(uint256 _price, uint256 _binStep) internal pure returns (uint24) {
        unchecked {
            uint256 _binStepValue = _getBPValue(_binStep);

            // can't overflow as `2**23 + log2(price) < 2**23 + 2**128 < max(uint256)`
            int256 _id = REAL_ID_SHIFT + _price.log2() / _binStepValue.log2();

            if (_id < 0 || uint256(_id) > type(uint24).max) revert BinHelper__IdOverflows();
            return uint24(uint256(_id));
        }
    }

    /// @notice Returns the price corresponding to the given ID, as a 128.128-binary fixed-point number
    /// @dev This is the trusted function to link id to price, the other way may be inaccurate
    /// @param _id The id
    /// @param _binStep The bin step
    /// @return The price corresponding to this id, as a 128.128-binary fixed-point number
    function getPriceFromId(uint256 _id, uint256 _binStep) internal pure returns (uint256) {
        if (_id > uint256(type(uint24).max)) revert BinHelper__IdOverflows();
        unchecked {
            int256 _realId = int256(_id) - REAL_ID_SHIFT;

            return _getBPValue(_binStep).power(_realId);
        }
    }

    /// @notice Returns the (1 + bp) value as a 128.128-decimal fixed-point number
    /// @param _binStep The bp value in [1; 100] (referring to 0.01% to 1%)
    /// @return The (1+bp) value as a 128.128-decimal fixed-point number
    /// Example: SCALE = 340282366920938463463374607431768211456, _binStep = 25 (0.25%)
    /// _binStepFP = _binStep << Constants.SCALE_OFFSET = 8507059173023461586584365185794205286400 (25 in 128.128 FP)
    /// SCALE + (_binStepFP / 10_000) = 341133072838240809622033043950347631984 = 1.0025 in 128.128 FP
    function _getBPValue(uint256 _binStep) internal pure returns (uint256) {
        if (_binStep == 0 || _binStep > Constants.BASIS_POINT_MAX) revert BinHelper__BinStepOverflows(_binStep);

        unchecked {
            // can't overflow as `max(result) = 2**128 + 10_000 << 128 / 10_000 < max(uint256)`
            return Constants.SCALE + (_binStep << Constants.SCALE_OFFSET) / Constants.BASIS_POINT_MAX;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {
    Math512Bits__MulDivOverflow,
    Math512Bits__MulShiftOverflow,
    Math512Bits__OffsetOverflows
} from "../DLErrors.sol";
import {BitMath} from "./BitMath.sol";

/// @title Discretized Liquidity Math Helper Library
/// @author Bentoswap
/// @notice Helper contract used for full precision calculations
library Math512Bits {
    using BitMath for uint256;

    /// @notice Calculates floor(x*y÷denominator) with full precision
    /// The result will be rounded down
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    ///
    /// Requirements:
    /// - The denominator cannot be zero
    /// - The result must fit within uint256
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers
    ///
    /// @param x The multiplicand as an uint256
    /// @param y The multiplier as an uint256
    /// @param denominator The divisor as an uint256
    /// @return result The result as an uint256
    function mulDivRoundDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        (uint256 prod0, uint256 prod1) = _getMulProds(x, y);

        return _getEndOfDivRoundDown(x, y, denominator, prod0, prod1);
    }

    /// @notice Calculates x * y >> offset with full precision
    /// The result will be rounded down
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    ///
    /// Requirements:
    /// - The offset needs to be strictly lower than 256
    /// - The result must fit within uint256
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers
    ///
    /// @param x The multiplicand as an uint256
    /// @param y The multiplier as an uint256
    /// @param offset The offset as an uint256, can't be greater than 256
    /// @return result The result as an uint256
    function mulShiftRoundDown(
        uint256 x,
        uint256 y,
        uint256 offset
    ) internal pure returns (uint256 result) {
        if (offset > 255) revert Math512Bits__OffsetOverflows(offset);

        (uint256 prod0, uint256 prod1) = _getMulProds(x, y);

        if (prod0 != 0) result = prod0 >> offset;
        if (prod1 != 0) {
            // Make sure the result is less than 2^256.
            if (prod1 >= 1 << offset) revert Math512Bits__MulShiftOverflow(prod1, offset);

            unchecked {
                result += prod1 << (256 - offset);
            }
        }
    }

    /// @notice Calculates x * y >> offset with full precision
    /// The result will be rounded up
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    ///
    /// Requirements:
    /// - The offset needs to be strictly lower than 256
    /// - The result must fit within uint256
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers
    ///
    /// @param x The multiplicand as an uint256
    /// @param y The multiplier as an uint256
    /// @param offset The offset as an uint256, can't be greater than 256
    /// @return result The result as an uint256
    function mulShiftRoundUp(
        uint256 x,
        uint256 y,
        uint256 offset
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulShiftRoundDown(x, y, offset);
            if (mulmod(x, y, 1 << offset) != 0) result += 1;
        }
    }

    /// @notice Calculates x << offset / y with full precision
    /// The result will be rounded down
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    ///
    /// Requirements:
    /// - The offset needs to be strictly lower than 256
    /// - The result must fit within uint256
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers
    ///
    /// @param x The multiplicand as an uint256
    /// @param offset The number of bit to shift x as an uint256
    /// @param denominator The divisor as an uint256
    /// @return result The result as an uint256
    function shiftDivRoundDown(
        uint256 x,
        uint256 offset,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        if (offset > 255) revert Math512Bits__OffsetOverflows(offset);
        uint256 prod0;
        uint256 prod1;

        prod0 = x << offset; // Least significant 256 bits of the product
        unchecked {
            prod1 = x >> (256 - offset); // Most significant 256 bits of the product
        }

        return _getEndOfDivRoundDown(x, 1 << offset, denominator, prod0, prod1);
    }

    /// @notice Calculates x << offset / y with full precision
    /// The result will be rounded up
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    ///
    /// Requirements:
    /// - The offset needs to be strictly lower than 256
    /// - The result must fit within uint256
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers
    ///
    /// @param x The multiplicand as an uint256
    /// @param offset The number of bit to shift x as an uint256
    /// @param denominator The divisor as an uint256
    /// @return result The result as an uint256
    function shiftDivRoundUp(
        uint256 x,
        uint256 offset,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = shiftDivRoundDown(x, offset, denominator);
        unchecked {
            if (mulmod(x, 1 << offset, denominator) != 0) result += 1;
        }
    }

    /// @notice Helper function to return the result of `x * y` as 2 uint256
    /// @param x The multiplicand as an uint256
    /// @param y The multiplier as an uint256
    /// @return prod0 The least significant 256 bits of the product
    /// @return prod1 The most significant 256 bits of the product
    function _getMulProds(uint256 x, uint256 y) private pure returns (uint256 prod0, uint256 prod1) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }
    }

    /// @notice Helper function to return the result of `x * y / denominator` with full precision
    /// @param x The multiplicand as an uint256
    /// @param y The multiplier as an uint256
    /// @param denominator The divisor as an uint256
    /// @param prod0 The least significant 256 bits of the product
    /// @param prod1 The most significant 256 bits of the product
    /// @return result The result as an uint256
    function _getEndOfDivRoundDown(
        uint256 x,
        uint256 y,
        uint256 denominator,
        uint256 prod0,
        uint256 prod1
    ) private pure returns (uint256 result) {
        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
        } else {
            // Make sure the result is less than 2^256. Also prevents denominator == 0
            if (prod1 >= denominator) revert Math512Bits__MulDivOverflow(prod1, denominator);

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1
            // See https://cs.stackexchange.com/q/138556/92363
            unchecked {
                // Does not overflow because the denominator cannot be zero at this stage in the function
                uint256 lpotdod = denominator & (~denominator + 1);
                assembly {
                    // Divide denominator by lpotdod.
                    denominator := div(denominator, lpotdod)

                    // Divide [prod1 prod0] by lpotdod.
                    prod0 := div(prod0, lpotdod)

                    // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one
                    lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
                }

                // Shift in bits from prod1 into prod0
                prod0 |= prod1 * lpotdod;

                // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
                // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
                // four bits. That is, denominator * inv = 1 mod 2^4
                uint256 inverse = (3 * denominator) ^ 2;

                // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
                // in modular arithmetic, doubling the correct bits in each step
                inverse *= 2 - denominator * inverse; // inverse mod 2^8
                inverse *= 2 - denominator * inverse; // inverse mod 2^16
                inverse *= 2 - denominator * inverse; // inverse mod 2^32
                inverse *= 2 - denominator * inverse; // inverse mod 2^64
                inverse *= 2 - denominator * inverse; // inverse mod 2^128
                inverse *= 2 - denominator * inverse; // inverse mod 2^256

                // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
                // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
                // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
                // is no longer required.
                result = prod0 * inverse;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Discretized Liquidity Bit Math Library
/// @author Bentoswap
/// @notice Helper contract used for bit calculations
library BitMath {
    /// @notice Returns the closest non-zero bit of `integer` to the right (of left) of the `bit` bits that is not `bit`
    /// @param _integer The integer as a uint256
    /// @param _bit The bit index
    /// @param _rightSide Whether we're searching in the right side of the tree (true) or the left side (false)
    /// @return The index of the closest non-zero bit. If there is no closest bit, it returns max(uint256)
    function closestBit(
        uint256 _integer,
        uint8 _bit,
        bool _rightSide
    ) internal pure returns (uint256) {
        return _rightSide ? closestBitRight(_integer, _bit - 1) : closestBitLeft(_integer, _bit + 1);
    }

    /// @notice Returns the most (or least) significant bit of `_integer`
    /// @param _integer The integer
    /// @param _isMostSignificant Whether we want the most (true) or the least (false) significant bit
    /// @return The index of the most (or least) significant bit
    function significantBit(uint256 _integer, bool _isMostSignificant) internal pure returns (uint8) {
        return _isMostSignificant ? mostSignificantBit(_integer) : leastSignificantBit(_integer);
    }

    /// @notice Returns the index of the closest bit on the right of x that is non null
    /// @param x The value as a uint256
    /// @param bit The index of the bit to start searching at
    /// @return id The index of the closest non null bit on the right of x.
    /// If there is no closest bit, it returns max(uint256)
    function closestBitRight(uint256 x, uint8 bit) internal pure returns (uint256 id) {
        unchecked {
            uint256 _shift = 255 - bit;
            x <<= _shift;

            // can't overflow as it's non-zero and we shifted it by `_shift`
            return (x == 0) ? type(uint256).max : mostSignificantBit(x) - _shift;
        }
    }

    /// @notice Returns the index of the closest bit on the left of x that is non null
    /// @param x The value as a uint256
    /// @param bit The index of the bit to start searching at
    /// @return id The index of the closest non null bit on the left of x.
    /// If there is no closest bit, it returns max(uint256)
    function closestBitLeft(uint256 x, uint8 bit) internal pure returns (uint256 id) {
        unchecked {
            x >>= bit;

            return (x == 0) ? type(uint256).max : leastSignificantBit(x) + bit;
        }
    }

    /// @notice Returns the index of the most significant bit of x
    /// @param x The value as a uint256
    /// @return msb The index of the most significant bit of x
    function mostSignificantBit(uint256 x) internal pure returns (uint8 msb) {
        unchecked {
            if (x >= 1 << 128) {
                x >>= 128;
                msb = 128;
            }
            if (x >= 1 << 64) {
                x >>= 64;
                msb += 64;
            }
            if (x >= 1 << 32) {
                x >>= 32;
                msb += 32;
            }
            if (x >= 1 << 16) {
                x >>= 16;
                msb += 16;
            }
            if (x >= 1 << 8) {
                x >>= 8;
                msb += 8;
            }
            if (x >= 1 << 4) {
                x >>= 4;
                msb += 4;
            }
            if (x >= 1 << 2) {
                x >>= 2;
                msb += 2;
            }
            if (x >= 1 << 1) {
                msb += 1;
            }
        }
    }

    /// @notice Returns the index of the least significant bit of x
    /// @param x The value as a uint256
    /// @return lsb The index of the least significant bit of x
    function leastSignificantBit(uint256 x) internal pure returns (uint8 lsb) {
        unchecked {
            if (x << 128 != 0) {
                x <<= 128;
                lsb = 128;
            }
            if (x << 64 != 0) {
                x <<= 64;
                lsb += 64;
            }
            if (x << 32 != 0) {
                x <<= 32;
                lsb += 32;
            }
            if (x << 16 != 0) {
                x <<= 16;
                lsb += 16;
            }
            if (x << 8 != 0) {
                x <<= 8;
                lsb += 8;
            }
            if (x << 4 != 0) {
                x <<= 4;
                lsb += 4;
            }
            if (x << 2 != 0) {
                x <<= 2;
                lsb += 2;
            }
            if (x << 1 != 0) {
                lsb += 1;
            }

            return 255 - lsb;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {FeeHelper} from "../../libraries/FeeHelper.sol";
import {Oracle} from "../../libraries/Oracle.sol";
import {DLPairFees, IDLFactory} from "./DLPairFees.sol";

/// @title Discretized Liquidity Pair
/// @author Bentoswap
/// @notice Contract used to manage pair oracle functions
abstract contract DLPairOracle is DLPairFees {
    using FeeHelper for FeeHelper.FeeParameters;
    using Oracle for bytes32[65_535];

    /// @notice Set the factory address
    /// @param _factory The address of the factory
    constructor(IDLFactory _factory) DLPairFees(_factory) { }

    /// @notice Increase the length of the oracle
    /// @param _newSize The new size of the oracle. Needs to be bigger than current one
    function increaseOracleLength(uint16 _newSize) external override {
        _increaseOracle(_newSize);
    }

    /// @notice View function to get the oracle's sample at `_timeDelta` seconds
    /// @dev Return a linearized sample, the weighted average of 2 neighboring samples
    /// @param _timeDelta The number of seconds before the current timestamp
    /// @return cumulativeId The weighted average cumulative id
    /// @return cumulativeVolatilityAccumulated The weighted average cumulative volatility accumulated
    /// @return cumulativeBinCrossed The weighted average cumulative bin crossed
    function getOracleSampleFrom(uint256 _timeDelta)
        external
        view
        override
        returns (
            uint256 cumulativeId,
            uint256 cumulativeVolatilityAccumulated,
            uint256 cumulativeBinCrossed
        )
    {
        uint256 _lookUpTimestamp = block.timestamp - _timeDelta;

        (uint256 _oracleActiveSize, uint256 _oracleId) = _getOracleSampleParameters();

        uint256 timestamp;
        (timestamp, cumulativeId, cumulativeVolatilityAccumulated, cumulativeBinCrossed) = _oracle.getSampleAt(
            _oracleActiveSize,
            _oracleId,
            _lookUpTimestamp
        );

        if (timestamp < _lookUpTimestamp) {
            FeeHelper.FeeParameters memory _fp = _feeParameters;
            uint256 _activeId = _pairInformation.activeId;
            _fp.updateVariableFeeParameters(_activeId);

            unchecked {
                uint256 _deltaT = _lookUpTimestamp - timestamp;

                cumulativeId += _activeId * _deltaT;
                cumulativeVolatilityAccumulated += uint256(_fp.volatilityAccumulated) * _deltaT;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Discretized Liquidity Decoder Library
/// @author Bentoswap
/// @notice Helper contract used for decoding bytes32 sample
library Decoder {
    /// @notice Internal function to decode a bytes32 sample using a mask and offset
    /// @dev This function can overflow
    /// @param _sample The sample as a bytes32
    /// @param _mask The mask
    /// @param _offset The offset
    /// @return value The decoded value
    function decode(
        bytes32 _sample,
        uint256 _mask,
        uint256 _offset
    ) internal pure returns (uint256 value) {
        assembly {
            value := and(shr(_offset, _sample), _mask)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @title Discretized Liquidity Encoder Library
/// @author Bentoswap
/// @notice Helper contract used for encoding uint256 value
library Encoder {
    /// @notice Internal function to encode a uint256 value using a mask and offset
    /// @dev This function can underflow
    /// @param _value The value as a uint256
    /// @param _mask The mask
    /// @param _offset The offset
    /// @return sample The encoded bytes32 sample
    function encode(
        uint256 _value,
        uint256 _mask,
        uint256 _offset
    ) internal pure returns (bytes32 sample) {
        assembly {
            sample := shl(_offset, and(_value, _mask))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {
    Math128x128__LogUnderflow,
    Math128x128__PowerUnderflow
} from "../DLErrors.sol";
import {BitMath} from "./BitMath.sol";
import {Constants} from "./Constants.sol";
import {Math512Bits} from "./Math512Bits.sol";

/// @title Discretized Liquidity Math Helper Library
/// @author Bentoswap
/// @notice Helper contract used for power and log calculations
library Math128x128 {
    using Math512Bits for uint256;
    using BitMath for uint256;

    uint256 constant LOG_SCALE_OFFSET = 127;
    uint256 constant LOG_SCALE = 1 << LOG_SCALE_OFFSET;
    uint256 constant LOG_SCALE_SQUARED = LOG_SCALE * LOG_SCALE;

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation
    /// Also because x is converted to an unsigned 129.127-binary fixed-point number during the operation to optimize the multiplication
    ///
    /// @param x The unsigned 128.128-binary fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 128.128-binary fixed-point number.
    function log2(uint256 x) internal pure returns (int256 result) {
        // Convert x to a unsigned 129.127-binary fixed-point number to optimize the multiplication.
        // If we use an offset of 128 bits, y would need 129 bits and y**2 would would overflow and we would have to
        // use mulDiv, by reducing x to 129.127-binary fixed-point number we assert that y will use 128 bits, and we
        // can use the regular multiplication

        if (x == 1) return -128;
        if (x == 0) revert Math128x128__LogUnderflow();

        x >>= 1;

        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= LOG_SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas
                x = LOG_SCALE_SQUARED / x;
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = (x >> LOG_SCALE_OFFSET).mostSignificantBit();

            // The integer part of the logarithm as a signed 129.127-binary fixed-point number. The operation can't overflow
            // because n is maximum 255, LOG_SCALE_OFFSET is 127 bits and sign is either 1 or -1.
            result = int256(n) << LOG_SCALE_OFFSET;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y != LOG_SCALE) {
                // Calculate the fractional part via the iterative approximation.
                // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
                for (int256 delta = int256(1 << (LOG_SCALE_OFFSET - 1)); delta > 0; delta >>= 1) {
                    y = (y * y) >> LOG_SCALE_OFFSET;

                    // Is y^2 > 2 and so in the range [2,4)?
                    if (y >= 1 << (LOG_SCALE_OFFSET + 1)) {
                        // Add the 2^(-m) factor to the logarithm.
                        result += delta;

                        // Corresponds to z/2 on Wikipedia.
                        y >>= 1;
                    }
                }
            }
            // Convert x back to unsigned 128.128-binary fixed-point number
            result = (result * sign) << 1;
        }
    }

    /// @notice Returns the value of x^y. It calculates `1 / x^abs(y)` if x is bigger than 2^128.
    /// At the end of the operations, we invert the result if needed.
    /// @param x The unsigned 128.128-binary fixed-point number for which to calculate the power
    /// @param y A relative number without any decimals, needs to be between ]2^20; 2^20[
    /// @return result The result of `x^y`
    function power(uint256 x, int256 y) internal pure returns (uint256 result) {
        bool invert;
        uint256 absY;

        if (y == 0) return Constants.SCALE;

        assembly {
            absY := y
            if slt(absY, 0) {
                absY := sub(0, absY)
                invert := iszero(invert)
            }
        }

        if (absY < 0x100000) {
            result = Constants.SCALE;
            assembly {
                let pow := x
                if gt(x, 0xffffffffffffffffffffffffffffffff) {
                    pow := div(not(0), pow)
                    invert := iszero(invert)
                }

                if and(absY, 0x1) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x2) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x4) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x8) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x10) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x20) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x40) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x80) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x100) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x200) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x400) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x800) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x1000) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x2000) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x4000) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x8000) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x10000) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x20000) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x40000) {
                    result := shr(128, mul(result, pow))
                }
                pow := shr(128, mul(pow, pow))
                if and(absY, 0x80000) {
                    result := shr(128, mul(result, pow))
                }
            }
        }

        // revert if y is too big or if x^y underflowed
        if (result == 0) revert Math128x128__PowerUnderflow(x, y);

        return invert ? type(uint256).max / result : result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {
    DLPair__AddressZeroOrThis,
    DLPair__OnlyFeeRecipient,
    DLPair__OnlyStrictlyIncreasingId
} from "../../DLErrors.sol";
import {Constants} from "../../libraries/Constants.sol";
import {Decoder} from "../../libraries/Decoder.sol";
import {FeeHelper} from "../../libraries/FeeHelper.sol";
import {Math512Bits} from "../../libraries/Math512Bits.sol";
import {SafeCast} from "../../libraries/SafeCast.sol";
import {TokenHelper, IERC20} from "../../libraries/TokenHelper.sol";
import {IDLFactory} from "../../interfaces/IDLFactory.sol";
import {DLPairState} from "./DLPairState.sol";

/// @title Discretized Liquidity Pair
/// @author Bentoswap
/// @notice Contract used to manage pair fees
abstract contract DLPairFees is DLPairState {
    using Decoder for bytes32;
    using Math512Bits for uint256;
    using SafeCast for uint256;
    using TokenHelper for IERC20;

    /// @notice Set the factory address
    /// @param _factory The address of the factory
    constructor(IDLFactory _factory) DLPairState(_factory) { }

    /// @notice Force the decaying of the references for volatility and index
    /// @dev Only callable by the factory
    function forceDecay() external override onlyFactory {
        unchecked {
            _feeParameters.volatilityReference = uint24(
                (uint256(_feeParameters.reductionFactor) * _feeParameters.volatilityReference) /
                    Constants.BASIS_POINT_MAX
            );
            _feeParameters.indexRef = _pairInformation.activeId;
        }
    }

    /// @notice View function to get the total fees and the protocol fees of each tokens
    /// @return feesXTotal The total fees of tokenX
    /// @return feesYTotal The total fees of tokenY
    /// @return feesXProtocol The protocol fees of tokenX
    /// @return feesYProtocol The protocol fees of tokenY
    function getGlobalFees()
        external
        view
        override
        returns (
            uint128 feesXTotal,
            uint128 feesYTotal,
            uint128 feesXProtocol,
            uint128 feesYProtocol
        )
    {
        return _getGlobalFees();
    }

    /// @notice View function to get the fee parameters
    /// @return The fee parameters
    function feeParameters() external view override returns (FeeHelper.FeeParameters memory) {
        return _feeParameters;
    }

    /// @notice Collect fees of an user
    /// @param _account The address of the user
    /// @param _ids The list of bin ids to collect fees in
    /// @return amountX The amount of tokenX claimed
    /// @return amountY The amount of tokenY claimed
    function collectFees(address _account, uint256[] calldata _ids) external override nonReentrant returns (uint256 amountX, uint256 amountY) {
        if (_account == address(0) || _account == address(this)) revert DLPair__AddressZeroOrThis();

        bytes32 _unclaimedData = _unclaimedFees[_account];
        delete _unclaimedFees[_account];

        amountX = _unclaimedData.decode(type(uint128).max, 0);
        amountY = _unclaimedData.decode(type(uint128).max, 128);

        unchecked {
            for (uint256 i; i < _ids.length; ++i) {
                uint256 _id = _ids[i];
                uint256 _balance = balanceOf(_account, _id);

                if (_balance != 0) {
                    Bin memory _bin = _bins[_id];

                    (uint256 _amountX, uint256 _amountY) = _getPendingFeesForBin(_bin, _account, _id, _balance);
                    _updateUserDebts(_bin, _account, _id, _balance);

                    amountX += _amountX;
                    amountY += _amountY;
                }
            }
        }

        if (amountX != 0) {
            _pairInformation.feesX.total -= uint128(amountX);
        }
        if (amountY != 0) {
            _pairInformation.feesY.total -= uint128(amountY);
        }

        tokenX.safeTransfer(_account, amountX);
        tokenY.safeTransfer(_account, amountY);

        emit FeesCollected(msg.sender, _account, amountX, amountY);
    }

    /// @notice Collect the protocol fees and send them to the feeRecipient
    /// @dev The balances are not zeroed to save gas by not resetting the storage slot
    /// Only callable by the fee recipient
    /// @return amountX The amount of tokenX claimed
    /// @return amountY The amount of tokenY claimed
    function collectProtocolFees() external override nonReentrant returns (uint128 amountX, uint128 amountY) {
                address _feeRecipient = factory.feeRecipient();

        if (msg.sender != _feeRecipient) revert DLPair__OnlyFeeRecipient(_feeRecipient, msg.sender);

        (uint128 _feesXTotal, uint128 _feesYTotal, uint128 _feesXProtocol, uint128 _feesYProtocol) = _getGlobalFees();

        // The protocol fees are not set to 0 to reduce the gas cost during a swap
        if (_feesXProtocol > 1) {
            amountX = _feesXProtocol - 1;
            _feesXTotal -= amountX;

            _setFees(_pairInformation.feesX, _feesXTotal, 1);

            tokenX.safeTransfer(_feeRecipient, amountX);
        }

        if (_feesYProtocol > 1) {
            amountY = _feesYProtocol - 1;
            _feesYTotal -= amountY;

            _setFees(_pairInformation.feesY, _feesYTotal, 1);

            tokenY.safeTransfer(_feeRecipient, amountY);
        }

        emit ProtocolFeesCollected(msg.sender, _feeRecipient, amountX, amountY);
    }

    /// @notice Update the unclaimed fees of a given user before a transfer
    /// @param _bin The bin where the user has collected fees
    /// @param _user The address of the user
    /// @param _id The id where the user has collected fees
    /// @param _previousBalance The previous balance of the user
    /// @param _newBalance The new balance of the user
    function _cacheFees(
        Bin memory _bin,
        address _user,
        uint256 _id,
        uint256 _previousBalance,
        uint256 _newBalance
    ) internal {
        unchecked {
            bytes32 _unclaimedData = _unclaimedFees[_user];

            uint256 amountX = _unclaimedData.decode(type(uint128).max, 0);
            uint256 amountY = _unclaimedData.decode(type(uint128).max, 128);

            (uint256 _amountX, uint256 _amountY) = _getPendingFeesForBin(_bin, _user, _id, _previousBalance);
            _updateUserDebts(_bin, _user, _id, _newBalance);

            (amountX += _amountX).safe128();
            (amountY += _amountY).safe128();

            _unclaimedFees[_user] = bytes32((amountY << 128) | amountX);
        }
    }

    /// @notice View function to get the pending fees of a user
    /// @dev The array must be strictly increasing to ensure uniqueness
    /// @param _account The address of the user
    /// @param _ids The list of ids
    /// @return amountX The amount of tokenX pending
    /// @return amountY The amount of tokenY pending
    function pendingFees(address _account, uint256[] calldata _ids)
        external
        view
        override
        returns (uint256 amountX, uint256 amountY)
    {
        if (_account == address(this) || _account == address(0)) return (0, 0);

        bytes32 _unclaimedData = _unclaimedFees[_account];

        amountX = _unclaimedData.decode(type(uint128).max, 0);
        amountY = _unclaimedData.decode(type(uint128).max, 128);

        uint256 _lastId;
        unchecked {
            for (uint256 i; i < _ids.length; ++i) {
                uint256 _id = _ids[i];

                // Ensures uniqueness of ids
                if (_lastId >= _id && i != 0) revert DLPair__OnlyStrictlyIncreasingId();

                uint256 _balance = balanceOf(_account, _id);

                if (_balance != 0) {
                    Bin memory _bin = _bins[_id];

                    (uint256 _amountX, uint256 _amountY) = _getPendingFeesForBin(_bin, _account, _id, _balance);

                    amountX += _amountX;
                    amountY += _amountY;
                }

                _lastId = _id;
            }
        }
    }

    /// @notice Update fees of a given user
    /// @param _bin The bin where the user has collected fees
    /// @param _account The address of the user
    /// @param _id The id where the user has collected fees
    /// @param _balance The new balance of the user
    function _updateUserDebts(
        Bin memory _bin,
        address _account,
        uint256 _id,
        uint256 _balance
    ) internal {
        uint256 _debtX = _bin.accTokenXPerShare.mulShiftRoundDown(_balance, Constants.SCALE_OFFSET);
        uint256 _debtY = _bin.accTokenYPerShare.mulShiftRoundDown(_balance, Constants.SCALE_OFFSET);

        _accruedDebts[_account][_id].debtX = _debtX;
        _accruedDebts[_account][_id].debtY = _debtY;
    }

    /// @notice Return the fee added to a flashloan
    /// @dev Rounds up the amount of fees
    /// @param _amount The amount of the flashloan
    /// @return The fee added to the flashloan
    function _getFlashLoanFee(uint256 _amount) internal view returns (uint256) {
        uint256 _fee = factory.flashLoanFee();
        return (_amount * _fee + Constants.PRECISION - 1) / Constants.PRECISION;
    }

    /// @notice View function to get the pending fees of an account on a given bin
    /// @param _bin  The bin where the user is collecting fees
    /// @param _account The address of the user
    /// @param _id The id where the user is collecting fees
    /// @param _balance The previous balance of the user
    /// @return amountX The amount of tokenX pending for the account
    /// @return amountY The amount of tokenY pending for the account
    function _getPendingFeesForBin(
        Bin memory _bin,
        address _account,
        uint256 _id,
        uint256 _balance
    ) internal view returns (uint256 amountX, uint256 amountY) {
        Debts memory _debts = _accruedDebts[_account][_id];

        amountX = _bin.accTokenXPerShare.mulShiftRoundDown(_balance, Constants.SCALE_OFFSET) - _debts.debtX;
        amountY = _bin.accTokenYPerShare.mulShiftRoundDown(_balance, Constants.SCALE_OFFSET) - _debts.debtY;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {
    DLPair__AddressZero,
    DLPair__AlreadyInitialized,
    DLPair__NewSizeTooSmall,
    DLPair__OnlyFactory
} from "../../DLErrors.sol";
import {IDLFactory} from "../../interfaces/IDLFactory.sol";
import {IDLPair, IERC20} from "../../interfaces/IDLPair.sol";
import {Decoder} from "../../libraries/Decoder.sol";
import {FeeHelper} from "../../libraries/FeeHelper.sol";
import {Oracle} from "../../libraries/Oracle.sol";
import {ReentrancyGuardUpgradeable} from "../../libraries/ReentrancyGuardUpgradeable.sol";
import {SafeCast} from "../../libraries/SafeCast.sol";
import {DLToken} from "./DLToken.sol";

/// @title Discretized Liquidity Pair
/// @author Bentoswap
/// @notice The state contract that holds state, dependencies, and any assembly code to prevent intellisense from breaking
abstract contract DLPairState is DLToken, ReentrancyGuardUpgradeable, IDLPair {
    using Decoder for bytes32;
    using Oracle for bytes32[65_535];
    using SafeCast for uint256;

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //    -'~'-.,__,.-'~'-.,__,.- CONSTANTS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    // The offset within a single uint256 slot where to find the packed x reserve amount within a PairInformation struct
    // 24 is the size of the first parameter in the packed slot (which is the activeId)
    uint256 internal constant OFFSET_PAIR_RESERVE_X = 24;
    // The offset within a single uint256 slot where to find the packed y reserve amount of a given Bin struct
    // 112 is the size of the x reserve amount value within the Bin struct
    uint256 internal constant OFFSET_BIN_RESERVE_Y = 112;
    // The offset within a single uint256 slot where to find the packed protocol fee within a FeesDistribution struct
    // 128 is the size of the total fees information within the only slot in the FeesDistribution struct
    uint256 internal constant OFFSET_PROTOCOL_FEE = 128;
    // The offset within a single uint256 slot where to find the variable fee parameters within the FeeParameters struct
    // 144 is the size of the first 8 packed values, leaving the final 4 values to be retrieved:
    // 1. uint24 volatilityAccumulated;
    // 2. uint24 volatilityReference;
    // 3. uint24 indexRef;
    // 4. uint40 time;
    uint256 internal constant OFFSET_VARIABLE_FEE_PARAMETERS = 144;
    // The offset within a single uint256 slot where to find the oracleSampleLifetime in the PairInformation struct
    // 136 is the size of the first packed value in the second slot of the PairInformation struct
    uint256 internal constant OFFSET_ORACLE_SAMPLE_LIFETIME = 136;
    // The offset within a single uint256 slot where to find the oracleSize in the PairInformation struct
    // 152 is the size of the first two packed values in the second slot of the PairInformation struct
    uint256 internal constant OFFSET_ORACLE_SIZE = 152;
    // The offset within a single uint256 slot where to find the oracleActiveSize in the PairInformation struct
    // 168 is the size of the first three packed values in the second slot of the PairInformation struct
    uint256 internal constant OFFSET_ORACLE_ACTIVE_SIZE = 168;
    // The offset within a single uint256 slot where to find the oracleLastTimestamp in the PairInformation struct
    // 184 is the size of the first four packed values in the second slot of the PairInformation struct
    uint256 internal constant OFFSET_ORACLE_LAST_TIMESTAMP = 184;
    // The offset within a single uint256 slot where to find the oracleId in the PairInformation struct
    // 224 is the size of the first five packed values in the second slot of the PairInformation struct
    uint256 internal constant OFFSET_ORACLE_ID = 224;

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //       -'~'-.,__,.-'~'-.,__,.- VARS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    IDLFactory public immutable override factory;
    IERC20 public override tokenX;
    IERC20 public override tokenY;

    PairInformation internal _pairInformation;
    FeeHelper.FeeParameters internal _feeParameters;
    bytes32[65_535] internal _oracle;
    /// @dev The reserves of tokens for every bin. This is the amount
    /// of tokenY if `id < _pairInformation.activeId`; of tokenX if `id > _pairInformation.activeId`
    /// and a mix of both if `id == _pairInformation.activeId`
    mapping(uint256 => Bin) internal _bins;
    /// @dev Tree to find bins with non zero liquidity
    mapping(uint256 => uint256)[3] internal _tree;
    /// @dev Mapping from account to user's unclaimed fees. The first 128 bits are tokenX and the last are for tokenY
    mapping(address => bytes32) internal _unclaimedFees;
    /// @dev Mapping from account to id to user's accruedDebt.
    mapping(address => mapping(uint256 => Debts)) internal _accruedDebts;

    /// @notice Set the factory address
    /// @param _factory The address of the factory
    constructor(IDLFactory _factory) DLToken() {
        if (address(_factory) == address(0)) revert DLPair__AddressZero();
        factory = _factory;
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- EXTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @notice Initialize the parameters of the DLPair
    /// @dev The different parameters needs to be validated very cautiously.
    /// It is highly recommended to never call this function directly, use the factory
    /// as it validates the different parameters
    /// @param _tokenX The address of the tokenX. Can't be address 0
    /// @param _tokenY The address of the tokenY. Can't be address 0
    /// @param _activeId The active id of the pair
    /// @param _sampleLifetime The lifetime of a sample. It's the min time between 2 oracle's sample
    /// @param _packedFeeParameters The fee parameters packed in a single 256 bits slot
    function initialize(
        IERC20 _tokenX,
        IERC20 _tokenY,
        uint24 _activeId,
        uint16 _sampleLifetime,
        bytes32 _packedFeeParameters
    ) external override onlyFactory {
        if (address(_tokenX) == address(0) || address(_tokenY) == address(0)) revert DLPair__AddressZero();
        if (address(tokenX) != address(0)) revert DLPair__AlreadyInitialized();

        __ReentrancyGuard_init();

        tokenX = _tokenX;
        tokenY = _tokenY;

        _pairInformation.activeId = _activeId;
        _pairInformation.oracleSampleLifetime = _sampleLifetime;

        setFeesParameters(_packedFeeParameters);
        _increaseOracle(2);
    }

    /// @notice Set the fees parameters
    /// @dev Needs to be called by the factory that will validate the values
    /// The bin step will not change
    /// Only callable by the factory
    /// @param _packedFeeParameters The packed fee parameters
    function setFeesParameters(bytes32 _packedFeeParameters) public override onlyFactory {
        bytes32 _feeStorageSlotData;
        assembly {
            _feeStorageSlotData := sload(_feeParameters.slot)
        }

        uint256 _varParameters = _feeStorageSlotData.decode(type(uint112).max, OFFSET_VARIABLE_FEE_PARAMETERS);
        uint256 _newFeeParameters = _packedFeeParameters.decode(type(uint144).max, 0);

        assembly {
            sstore(_feeParameters.slot, or(_newFeeParameters, shl(144, _varParameters)))
        }
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- INTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @notice Private function to increase the oracle's number of sample
    /// @param _newSize The new size of the oracle. Needs to be bigger than current one
    function _increaseOracle(uint16 _newSize) internal {
        uint256 _oracleSize = _pairInformation.oracleSize;

        if (_oracleSize >= _newSize) revert DLPair__NewSizeTooSmall(_newSize, _oracleSize);

        _pairInformation.oracleSize = _newSize;

        unchecked {
            for (uint256 _id = _oracleSize; _id < _newSize; ++_id) {
                _oracle.initialize(_id);
            }
        }

        emit OracleSizeIncreased(_oracleSize, _newSize);
    }

    /// @notice The following is an optimized `_bins[_id] = _bin` to do only 1 sstore
    /// First, store the mapping key in memory slot 0
    /// Then store the slot of the mapping in the next slot (32 bytes after id)
    /// The resulting 64 bytes are a concatenation of the mapping key + mapping slot,
    ///  which is how solidity finds the storage slot of the value of the key in the mapping
    /// Pull that slot into memory, calculate the value to store, and then store it in a single sstore operation.
    /// @param _id The ID for the bin to update reserves for
    /// @param _reserveX The amount of reserves for the x token
    /// @param _reserveY TheThe amount of reserves for the y token
    function _saveBinReserves(
        uint256 _id,
        uint256 _reserveX,
        uint256 _reserveY
    ) internal {
        assembly {
            mstore(0, _id)
            mstore(32, _bins.slot)
            let slot := keccak256(0, 64)

            let reserves := add(shl(OFFSET_BIN_RESERVE_Y, _reserveY), _reserveX)
            sstore(slot, reserves)
        }
    }

    /// @notice Internal view function to return the oracle's parameters
    /// @return oracleSampleLifetime The lifetime of a sample, it accumulates information for up to this timestamp
    /// @return oracleSize The size of the oracle (last ids can be empty)
    /// @return oracleActiveSize The active size of the oracle (no empty data)
    /// @return oracleLastTimestamp The timestamp of the creation of the oracle's latest sample
    /// @return oracleId The index of the oracle's latest sample
    /// @return min The min delta time of two samples
    /// @return max The safe max delta time of two samples
    function getOracleParameters()
        external
        view
        override
        returns (
            uint256 oracleSampleLifetime,
            uint256 oracleSize,
            uint256 oracleActiveSize,
            uint256 oracleLastTimestamp,
            uint256 oracleId,
            uint256 min,
            uint256 max
        )
    {
        bytes32 _slotData;
        assembly {
            _slotData := sload(add(_pairInformation.slot, 1))
        }
        oracleSampleLifetime = _slotData.decode(type(uint16).max, OFFSET_ORACLE_SAMPLE_LIFETIME);
        oracleSize = _slotData.decode(type(uint16).max, OFFSET_ORACLE_SIZE);
        oracleActiveSize = _slotData.decode(type(uint16).max, OFFSET_ORACLE_ACTIVE_SIZE);
        oracleLastTimestamp = _slotData.decode(type(uint40).max, OFFSET_ORACLE_LAST_TIMESTAMP);
        oracleId = _slotData.decode(type(uint16).max, OFFSET_ORACLE_ID);
        min = oracleActiveSize == 0 ? 0 : oracleSampleLifetime;
        max = oracleSampleLifetime * oracleActiveSize;
    }

    /// @notice Internal view function to return the oracle's sample parameters
    /// @return oracleActiveSize The active size of the oracle (no empty data)
    /// @return oracleId The index of the oracle's latest sample
    function _getOracleSampleParameters()
        internal
        view
        returns (
            uint256 oracleActiveSize,
            uint256 oracleId
        )
    {
        bytes32 _slotData;
        assembly {
            _slotData := sload(add(_pairInformation.slot, 1))
        }
        oracleActiveSize = _slotData.decode(type(uint16).max, OFFSET_ORACLE_ACTIVE_SIZE);
        oracleId = _slotData.decode(type(uint16).max, OFFSET_ORACLE_ID);
    }

    /// @notice Private view function to get the reserves and active id
    /// @return reserveX The reserve of asset X
    /// @return reserveY The reserve of asset Y
    /// @return activeId The active id of the pair
    function _getReservesAndId()
        internal
        view
        returns (
            uint256 reserveX,
            uint256 reserveY,
            uint256 activeId
        )
    {
        uint256 _mask24 = type(uint24).max;
        uint256 _mask136 = type(uint136).max;
        assembly {
            let _slotData := sload(add(_pairInformation.slot, 1))
            reserveY := and(_slotData, _mask136)

            _slotData := sload(_pairInformation.slot)
            activeId := and(_slotData, _mask24)
            reserveX := and(shr(OFFSET_PAIR_RESERVE_X, _slotData), _mask136)
        }
    }

    /// @notice Private view function to get the bin at `id`
    /// @param _id The bin id
    /// @return reserveX The reserve of tokenX of the bin
    /// @return reserveY The reserve of tokenY of the bin
    function _getBin(uint24 _id) internal view returns (uint256 reserveX, uint256 reserveY) {
        bytes32 _slotData;
        uint256 _mask112 = type(uint112).max;
        // low level read of mapping to only load 1 storage slot
        // First, store the mapping key in memory slot 0
        // Then store the slot of the mapping in the next slot (32 bytes after id)
        // The resulting 64 bytes are a concatenation of the mapping key + mapping slot,
        //  which is how solidity finds the storage slot of the value of the key in the mapping
        // Pull that slot into memory and store the value (which is the Bin struct)
        // Save the x reserve amount by only keeping the first 112 bits
        // Then shift off the x reserve amount from data and store that as the y reserve
        // Finally, ensure the values retrieved are 112 compatable and return them.
        // This is critical incase there are code changes that pack something else into the first slot of the Bin struct,
        //  since the x and y reserves are each 112 bits, that's 224 bits, which leaves 32 bits empty in the first slot
        assembly {
            mstore(0, _id)
            mstore(32, _bins.slot)
            _slotData := sload(keccak256(0, 64))

            reserveX := and(_slotData, _mask112)
            reserveY := shr(OFFSET_BIN_RESERVE_Y, _slotData)
        }

        return (reserveX.safe112(), reserveY.safe112());
    }

    /// @notice Private view function to get the global fees information, the total fees and those for protocol
    /// @dev The fees for users are `total - protocol`
    /// @return feesXTotal The total fees of asset X
    /// @return feesYTotal The total fees of asset Y
    /// @return feesXProtocol The protocol fees of asset X
    /// @return feesYProtocol The protocol fees of asset Y
    function _getGlobalFees()
        internal
        view
        returns (
            uint128 feesXTotal,
            uint128 feesYTotal,
            uint128 feesXProtocol,
            uint128 feesYProtocol
        )
    {
        // Without loading the entire PairInfo struct (which is 4 slots large), we pull the fee portions directly from storage
        bytes32 _slotDataX;
        bytes32 _slotDataY;
        assembly {
            _slotDataX := sload(add(_pairInformation.slot, 2))
            _slotDataY := sload(add(_pairInformation.slot, 3))
        }

        // Fees are packed into a single uint256 slot, half allocated to LP fees, other half protocol fees.
        // Pull the first half and load it from the fee slots for the LP fees
        feesXTotal = uint128(_slotDataX.decode(type(uint128).max, 0));
        feesYTotal = uint128(_slotDataY.decode(type(uint128).max, 0));

        // Pull the second half and load it from the fee slots for the protocol fees
        feesXProtocol = uint128(_slotDataX.decode(type(uint128).max, OFFSET_PROTOCOL_FEE));
        feesYProtocol = uint128(_slotDataY.decode(type(uint128).max, OFFSET_PROTOCOL_FEE));
    }

    /// @notice Set the total and protocol fees
    /// @dev The assembly block does:
    /// _pairFees = FeeHelper.FeesDistribution({total: _totalFees, protocol: _protocolFees});
    /// @param _pairFees The storage slot of the fees
    /// @param _totalFees The new total fees
    /// @param _protocolFees The new protocol fees
    function _setFees(FeeHelper.FeesDistribution storage _pairFees, uint128 _totalFees, uint128 _protocolFees) internal {
        assembly {
            sstore(_pairFees.slot, and(shl(OFFSET_PROTOCOL_FEE, _protocolFees), _totalFees))
        }
    }

    /// @notice Returns whether this contract implements the interface defined by
    /// `interfaceId` (true) or not (false)
    /// @param _interfaceId The interface identifier
    /// @return Whether the interface is supported (true) or not (false)
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(_interfaceId) || _interfaceId == type(IDLPair).interfaceId;
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //    -'~'-.,__,.-'~'-.,__,.- MODIFIERS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    modifier onlyFactory() {
        if (msg.sender != address(factory)) revert DLPair__OnlyFactory();
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {
    ReentrancyGuardUpgradeable__AlreadyInitialized,
    ReentrancyGuardUpgradeable__ReentrantCall
} from "../DLErrors.sol";

/// @title Reentrancy Guard
/// @author Bentoswap
/// @notice Contract module that helps prevent reentrant calls to a function
abstract contract ReentrancyGuardUpgradeable {
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

    function __ReentrancyGuard_init() internal {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal {
        if (_status != 0) revert ReentrancyGuardUpgradeable__AlreadyInitialized();

        _status = _NOT_ENTERED;
    }

    /// @notice Prevents a contract from calling itself, directly or indirectly.
    /// Calling a `nonReentrant` function from another `nonReentrant`
    /// function is not supported. It is possible to prevent this from happening
    /// by making the `nonReentrant` function external, and making it call a
    /// `private` function that does the actual work
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        if (_status != _NOT_ENTERED) revert ReentrancyGuardUpgradeable__ReentrantCall();

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

import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";

import {
    DLToken__BurnExceedsBalance,
    DLToken__BurnFromAddress0,
    DLToken__LengthMismatch,
    DLToken__MintToAddress0,
    DLToken__NotSupported,
    DLToken__SelfApproval,
    DLToken__SpenderNotApproved,
    DLToken__TransferExceedsBalance,
    DLToken__TransferFromOrToAddress0,
    DLToken__TransferToSelf
} from "../../DLErrors.sol";
import {IDLToken} from "../../interfaces/IDLToken.sol";

/// @title Descretized Liquidity Token
/// @author Bentoswap
/// @notice The DLToken is an implementation of a multi-token.
/// It allows to create multi-ERC20 represented by their ids
contract DLToken is IDLToken {
    using EnumerableSet for EnumerableSet.UintSet;

    /// @dev Mapping from token id to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    /// @dev Mapping from account to spender approvals
    mapping(address => mapping(address => bool)) private _spenderApprovals;

    /// @dev Mapping from token id to total supplies
    mapping(uint256 => uint256) private _totalSupplies;

    string private constant _NAME = "Discretized Liquidity Token";
    string private constant _SYMBOL = "DLT";

    modifier checkApproval(address _from, address _spender) {
        if (!_isApprovedForAll(_from, _spender)) revert DLToken__SpenderNotApproved(_from, _spender);
        _;
    }

    modifier checkAddresses(address _from, address _to) {
        if (_from == address(0) || _to == address(0)) revert DLToken__TransferFromOrToAddress0();
        if (_from == _to) revert DLToken__TransferToSelf();
        _;
    }

    modifier checkLength(uint256 _lengthA, uint256 _lengthB) {
        if (_lengthA != _lengthB) revert DLToken__LengthMismatch(_lengthA, _lengthB);
        _;
    }

    modifier checkDLTokenSupport(address recipient) {
        if (!_verifyDLTokenSupport(recipient)) revert DLToken__NotSupported();
        _;
    }

    /// @notice Returns the name of the token
    /// @return The name of the token
    function name() public pure virtual override returns (string memory) {
        return _NAME;
    }

    /// @notice Returns the symbol of the token, usually a shorter version of the name
    /// @return The symbol of the token
    function symbol() public pure virtual override returns (string memory) {
        return _SYMBOL;
    }

    /// @notice Returns the total supply of token of type `id`
    /// @dev This is the amount of token of type `id` minted minus the amount burned
    /// @param _id The token id
    /// @return The total supply of that token id
    function totalSupply(uint256 _id) public view virtual override returns (uint256) {
        return _totalSupplies[_id];
    }

    /// @notice Returns the amount of tokens of type `id` owned by `_account`
    /// @param _account The address of the owner
    /// @param _id The token id
    /// @return The amount of tokens of type `id` owned by `_account`
    function balanceOf(address _account, uint256 _id) public view virtual override returns (uint256) {
        return _balances[_id][_account];
    }

    /// @notice Return the balance of multiple (account/id) pairs
    /// @param _accounts The addresses of the owners
    /// @param _ids The token ids
    /// @return batchBalances The balance for each (account, id) pair
    function balanceOfBatch(address[] calldata _accounts, uint256[] calldata _ids)
        public
        view
        virtual
        override
        checkLength(_accounts.length, _ids.length)
        returns (uint256[] memory batchBalances)
    {
        batchBalances = new uint256[](_accounts.length);

        unchecked {
            for (uint256 i; i < _accounts.length; ++i) {
                batchBalances[i] = balanceOf(_accounts[i], _ids[i]);
            }
        }
    }

    /// @notice Returns true if `spender` is approved to transfer `_account`'s tokens
    /// @param _owner The address of the owner
    /// @param _spender The address of the spender
    /// @return True if `spender` is approved to transfer `_account`'s tokens
    function isApprovedForAll(address _owner, address _spender) public view virtual override returns (bool) {
        return _isApprovedForAll(_owner, _spender);
    }

    /// @notice Grants or revokes permission to `spender` to transfer the caller's tokens, according to `approved`
    /// @param _spender The address of the spender
    /// @param _approved The boolean value to grant or revoke permission
    function setApprovalForAll(address _spender, bool _approved) public virtual override {
        _setApprovalForAll(msg.sender, _spender, _approved);
    }

    /// @notice Transfers `_amount` token of type `_id` from `_from` to `_to`
    /// @param _from The address of the owner of the token
    /// @param _to The address of the recipient
    /// @param _id The token id
    /// @param _amount The amount to send
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount
    ) public virtual override checkAddresses(_from, _to) checkApproval(_from, msg.sender) checkDLTokenSupport(_to) {
        address _spender = msg.sender;

        _transfer(_from, _to, _id, _amount);

        emit TransferSingle(_spender, _from, _to, _id, _amount);
    }

    /// @notice Batch transfers `_amount` tokens of type `_id` from `_from` to `_to`
    /// @param _from The address of the owner of the tokens
    /// @param _to The address of the recipient
    /// @param _ids The list of token ids
    /// @param _amounts The list of amounts to send
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    )
        public
        virtual
        override
        checkLength(_ids.length, _amounts.length)
        checkAddresses(_from, _to)
        checkApproval(_from, msg.sender)
        checkDLTokenSupport(_to)
    {
        unchecked {
            for (uint256 i; i < _ids.length; ++i) {
                _transfer(_from, _to, _ids[i], _amounts[i]);
            }
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
    }

    /// @notice Returns whether this contract implements the interface defined by
    /// `interfaceId` (true) or not (false)
    /// @param _interfaceId The interface identifier
    /// @return Whether the interface is supported (true) or not (false)
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IDLToken).interfaceId || _interfaceId == type(IERC165).interfaceId;
    }

    /// @notice Internal function to transfer `_amount` tokens of type `_id` from `_from` to `_to`
    /// @param _from The address of the owner of the token
    /// @param _to The address of the recipient
    /// @param _id The token id
    /// @param _amount The amount to send
    function _transfer(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount
    ) internal virtual {
        uint256 _fromBalance = _balances[_id][_from];
        if (_fromBalance < _amount) revert DLToken__TransferExceedsBalance(_from, _id, _amount);

        _beforeTokenTransfer(_from, _to, _id, _amount);

        unchecked {
            _balances[_id][_from] = _fromBalance - _amount;
            _balances[_id][_to] += _amount;
        }
    }

    /// @dev Creates `_amount` tokens of type `_id`, and assigns them to `_account`
    /// @param _account The address of the recipient
    /// @param _id The token id
    /// @param _amount The amount to mint
    function _mint(
        address _account,
        uint256 _id,
        uint256 _amount
    ) internal virtual {
        if (_account == address(0)) revert DLToken__MintToAddress0();

        _beforeTokenTransfer(address(0), _account, _id, _amount);

        _totalSupplies[_id] += _amount;

        unchecked {
            _balances[_id][_account] += _amount;
        }

        emit TransferSingle(msg.sender, address(0), _account, _id, _amount);
    }

    /// @dev Destroys `_amount` tokens of type `_id` from `_account`
    /// @param _account The address of the owner
    /// @param _id The token id
    /// @param _amount The amount to destroy
    function _burn(
        address _account,
        uint256 _id,
        uint256 _amount
    ) internal virtual {
        if (_account == address(0)) revert DLToken__BurnFromAddress0();

        uint256 _accountBalance = _balances[_id][_account];
        if (_accountBalance < _amount) revert DLToken__BurnExceedsBalance(_account, _id, _amount);

        _beforeTokenTransfer(_account, address(0), _id, _amount);

        unchecked {
            _balances[_id][_account] = _accountBalance - _amount;
            _totalSupplies[_id] -= _amount;
        }

        emit TransferSingle(msg.sender, _account, address(0), _id, _amount);
    }

    /// @notice Grants or revokes permission to `spender` to transfer the caller's tokens, according to `approved`
    /// @param _owner The address of the owner
    /// @param _spender The address of the spender
    /// @param _approved The boolean value to grant or revoke permission
    function _setApprovalForAll(
        address _owner,
        address _spender,
        bool _approved
    ) internal virtual {
        if (_owner == _spender) revert DLToken__SelfApproval(_owner);

        _spenderApprovals[_owner][_spender] = _approved;
        emit ApprovalForAll(_owner, _spender, _approved);
    }

    /// @notice Returns true if `spender` is approved to transfer `owner`'s tokens
    /// or if `sender` is the `owner`
    /// @param _owner The address of the owner
    /// @param _spender The address of the spender
    /// @return True if `spender` is approved to transfer `owner`'s tokens
    function _isApprovedForAll(address _owner, address _spender) internal view virtual returns (bool) {
        return _owner == _spender || _spenderApprovals[_owner][_spender];
    }

    /// @notice Hook that is called before any token transfer. This includes minting
    /// and burning.
    ///
    /// Calling conditions (for each `id` and `amount` pair):
    ///
    /// - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
    /// of token type `id` will be  transferred to `to`.
    /// - When `from` is zero, `amount` tokens of token type `id` will be minted
    /// for `to`.
    /// - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
    /// will be burned.
    /// - `from` and `to` are never both zero.
    /// @param from The address of the owner of the token
    /// @param to The address of the recipient of the  token
    /// @param id The id of the token
    /// @param amount The amount of token of type `id`
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual {}

    /// @notice Return if the `_target` contract supports DLToken interface
    /// @param _target The address of the contract
    /// @return supported Whether the contract is supported (1) or not (any other value)
    function _verifyDLTokenSupport(address _target) private view returns (bool supported) {
        if (_target.code.length == 0) return true;

        bytes4 selectorERC165 = IERC165.supportsInterface.selector;
        bytes4 IDLTokenInterfaceId = type(IDLToken).interfaceId;

        assembly {
            mstore(0x00, selectorERC165)
            mstore(0x04, IDLTokenInterfaceId)

            let success := staticcall(30000, _target, 0x00, 0x24, 0x00, 0x20)
            let size := eq(returndatasize(), 0x20)
            let data := eq(mload(0x00), 1)

            supported := and(and(success, size), data)
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// import {IERC1155} from "openzeppelin/token/erc1155/IERC1155.sol";
import "openzeppelin/utils/introspection/IERC165.sol";

/// @title Discretized Liquidity Token Interface
/// @author Bentoswap
/// @notice Required interface of DLToken contract
interface IDLToken is IERC165 {
    event TransferSingle(address indexed sender, address indexed from, address indexed to, uint256 id, uint256 amount);

    event TransferBatch(
        address indexed sender,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory batchBalances);

    function totalSupply(uint256 id) external view returns (uint256);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function setApprovalForAll(address sender, bool approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata id,
        uint256[] calldata amount
    ) external;
}