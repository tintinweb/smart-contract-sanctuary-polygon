// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import "../../DLErrors.sol";
import {TokenHelper} from "../../libraries/TokenHelper.sol";
import {IDLFactory} from "../../interfaces/IDLFactory.sol";
import {IDLPair} from "../../interfaces/IDLPair.sol";
import {IWCT} from "../../interfaces/IWCT.sol";
import {DLRouterLiquidity} from "./DLRouterLiquidity.sol";

/// @title Discretized Liquidity Router
/// @author Bentoswap
/// @notice Main contract to interact with pairs to swap and manage liquidity on Bentoswap exchange.
contract DLRouter is DLRouterLiquidity {
    using TokenHelper for IERC20;

    /// @notice Constructor
    /// @param _factory DLFactory address
    /// @param _wct Address of WCT
    constructor(IDLFactory _factory, IWCT _wct) DLRouterLiquidity(_factory, _wct) {}

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- EXTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @notice Create a liquidity bin DLPair for _tokenX and _tokenY using the factory
    /// @param _tokenX The address of the first token
    /// @param _tokenY The address of the second token
    /// @param _activeId The active id of the pair
    /// @param _binStep The bin step in basis point, used to calculate log(1 + binStep)
    /// @return pair The address of the newly created DLPair
    function createDLPair(
        IERC20 _tokenX,
        IERC20 _tokenY,
        uint24 _activeId,
        uint16 _binStep
    ) external override returns (IDLPair pair) {
        pair = factory.createDLPair(_tokenX, _tokenY, _activeId, _binStep);
    }

    /// @notice Unstuck tokens that are sent to this contract by mistake
    /// @dev Only callable by the factory owner
    /// @param _token The address of the token
    /// @param _to The address of the user to send back the tokens
    /// @param _amount The amount to send
    function sweep(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external override onlyFactoryOwner {
        if (address(_token) == address(0)) {
            if (_amount == type(uint256).max) _amount = address(this).balance;
            _safeTransferCT(_to, _amount);
        } else {
            if (_amount == type(uint256).max) _amount = _token.balanceOf(address(this));
            _token.safeTransfer(_to, _amount);
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

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

/// @title WCT Interface
/// @notice Required interface of Wrapped network contracts, ie. WETH
interface IWCT is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import "../../DLErrors.sol";
import {TokenHelper} from "../../libraries/TokenHelper.sol";
import {IDLFactory} from "../../interfaces/IDLFactory.sol";
import {IDLPair} from "../../interfaces/IDLPair.sol";
import {IDLToken} from "../../interfaces/IDLToken.sol";
import {IWCT} from "../../interfaces/IWCT.sol";
import {DLRouterSwaps} from "./DLRouterSwaps.sol";

/// @title Discretized Liquidity Router
/// @author Bentoswap
/// @notice Contract used to manage routing liquidity to pairs
abstract contract DLRouterLiquidity is DLRouterSwaps {
    using TokenHelper for IERC20;

    constructor(IDLFactory _factory, IWCT _wct) DLRouterSwaps(_factory, _wct) {}

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- EXTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @notice Add liquidity while performing safety checks
    /// @dev This function is compliant with fee on transfer tokens
    /// @param _liquidityParameters The liquidity parameters
    /// @return depositIds Bin ids where the liquidity was actually deposited
    /// @return liquidityMinted Amounts of DLToken minted for each bin
    function addLiquidity(LiquidityParameters calldata _liquidityParameters)
        external
        override
        returns (uint256[] memory depositIds, uint256[] memory liquidityMinted)
    {
        IDLPair _DLPair = _getDLPairInformation(
            _liquidityParameters.tokenX,
            _liquidityParameters.tokenY,
            _liquidityParameters.binStep
        );
        if (_liquidityParameters.tokenX != _DLPair.tokenX()) revert DLRouter__WrongTokenOrder();

        _liquidityParameters.tokenX.safeTransferFrom(msg.sender, address(_DLPair), _liquidityParameters.amountX);
        _liquidityParameters.tokenY.safeTransferFrom(msg.sender, address(_DLPair), _liquidityParameters.amountY);

        (depositIds, liquidityMinted) = _addLiquidity(_liquidityParameters, _DLPair);
    }

    /// @notice Remove liquidity while performing safety checks
    /// @dev This function is compliant with fee on transfer tokens
    /// @param _tokenX The address of token X
    /// @param _tokenY The address of token Y
    /// @param _binStep The bin step of the DLPair
    /// @param _amountXMin The min amount to receive of token X
    /// @param _amountYMin The min amount to receive of token Y
    /// @param _ids The list of ids to burn
    /// @param _amounts The list of amounts to burn of each id in `_ids`
    /// @param _to The address of the recipient
    /// @param _deadline The deadline of the tx
    /// @return amountX Amount of token X returned
    /// @return amountY Amount of token Y returned
    function removeLiquidity(
        IERC20 _tokenX,
        IERC20 _tokenY,
        uint16 _binStep,
        uint256 _amountXMin,
        uint256 _amountYMin,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        address _to,
        uint256 _deadline
    ) external override ensure(_deadline) returns (uint256 amountX, uint256 amountY) {
        IDLPair _DLPair = _getDLPairInformation(_tokenX, _tokenY, _binStep);
        bool _isWrongOrder = _tokenX != _DLPair.tokenX();

        if (_isWrongOrder) (_amountXMin, _amountYMin) = (_amountYMin, _amountXMin);

        (amountX, amountY) = _removeLiquidity(_DLPair, _amountXMin, _amountYMin, _ids, _amounts, _to);

        if (_isWrongOrder) (amountX, amountY) = (amountY, amountX);
    }

    /// @notice Add liquidity with Chain Token (CT) (i.e. eth/avax/matic) while performing safety checks
    /// @dev This function is compliant with fee on transfer tokens
    /// @param _liquidityParameters The liquidity parameters
    /// @return depositIds Bin ids where the liquidity was actually deposited
    /// @return liquidityMinted Amounts of DLToken minted for each bin
    function addLiquidityWCT(LiquidityParameters calldata _liquidityParameters)
        external
        payable
        override
        returns (uint256[] memory depositIds, uint256[] memory liquidityMinted)
    {
        IDLPair _DLPair = _getDLPairInformation(
            _liquidityParameters.tokenX,
            _liquidityParameters.tokenY,
            _liquidityParameters.binStep
        );
        if (_liquidityParameters.tokenX != _DLPair.tokenX()) revert DLRouter__WrongTokenOrder();

        if (_liquidityParameters.tokenX == wct && _liquidityParameters.amountX == msg.value) {
            _wctDepositAndTransfer(address(_DLPair), msg.value);
            _liquidityParameters.tokenY.safeTransferFrom(msg.sender, address(_DLPair), _liquidityParameters.amountY);
        } else if (_liquidityParameters.tokenY == wct && _liquidityParameters.amountY == msg.value) {
            _liquidityParameters.tokenX.safeTransferFrom(msg.sender, address(_DLPair), _liquidityParameters.amountX);
            _wctDepositAndTransfer(address(_DLPair), msg.value);
        } else
            revert DLRouter__WrongWCTLiquidityParameters(
                address(_liquidityParameters.tokenX),
                address(_liquidityParameters.tokenY),
                _liquidityParameters.amountX,
                _liquidityParameters.amountY,
                msg.value
            );

        (depositIds, liquidityMinted) = _addLiquidity(_liquidityParameters, _DLPair);
    }

    /// @notice Remove Chain Token (CT) (i.e. eth/avax/matic) liquidity while performing safety checks
    /// @dev This function is **NOT** compliant with fee on transfer tokens.
    /// This is wanted as it would make users pays the fee on transfer twice,
    /// use the `removeLiquidity` function to remove liquidity with fee on transfer tokens.
    /// @param _token The address of token
    /// @param _binStep The bin step of the DLPair
    /// @param _amountTokenMin The min amount to receive of token
    /// @param _amountCTMin The min amount to receive of CT
    /// @param _ids The list of ids to burn
    /// @param _amounts The list of amounts to burn of each id in `_ids`
    /// @param _to The address of the recipient
    /// @param _deadline The deadline of the tx
    /// @return amountToken Amount of token returned
    /// @return amountCT Amount of Chain Token (CT) (i.e. eth/avax/matic) returned
    function removeLiquidityWCT(
        IERC20 _token,
        uint16 _binStep,
        uint256 _amountTokenMin,
        uint256 _amountCTMin,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        address payable _to,
        uint256 _deadline
    ) external override ensure(_deadline) returns (uint256 amountToken, uint256 amountCT) {
        IDLPair _DLPair = _getDLPairInformation(_token, IERC20(wct), _binStep);

        bool _isCTTokenY = IERC20(wct) == _DLPair.tokenY();
        {
            if (!_isCTTokenY) {
                (_amountTokenMin, _amountCTMin) = (_amountCTMin, _amountTokenMin);
            }

            (uint256 _amountX, uint256 _amountY) = _removeLiquidity(
                _DLPair,
                _amountTokenMin,
                _amountCTMin,
                _ids,
                _amounts,
                address(this)
            );

            (amountToken, amountCT) = _isCTTokenY ? (_amountX, _amountY) : (_amountY, _amountX);
        }

        _token.safeTransfer(_to, amountToken);

        wct.withdraw(amountCT);
        _safeTransferCT(_to, amountCT);
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- INTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @notice Helper function to add liquidity
    /// @param _liq The liquidity parameter
    /// @param _DLPair DLPair where liquidity is deposited
    /// @return depositIds Bin ids where the liquidity was actually deposited
    /// @return liquidityMinted Amounts of DLToken minted for each bin
    function _addLiquidity(LiquidityParameters memory _liq, IDLPair _DLPair)
        internal
        ensure(_liq.deadline)
        returns (uint256[] memory depositIds, uint256[] memory liquidityMinted)
    {
        unchecked {
            if (_liq.deltaIds.length != _liq.distributionX.length && _liq.deltaIds.length != _liq.distributionY.length)
                revert DLRouter__LengthsMismatch();

            if (_liq.activeIdDesired > type(uint24).max || _liq.idSlippage > type(uint24).max)
                revert DLRouter__IdDesiredOverflows(_liq.activeIdDesired, _liq.idSlippage);

            (, , uint256 _activeId) = _DLPair.getReservesAndId();
            if (
                _liq.activeIdDesired + _liq.idSlippage < _activeId || _activeId + _liq.idSlippage < _liq.activeIdDesired
            ) revert DLRouter__IdSlippageCaught(_liq.activeIdDesired, _liq.idSlippage, _activeId);

            depositIds = new uint256[](_liq.deltaIds.length);
            for (uint256 i; i < depositIds.length; ++i) {
                int256 _id = int256(_activeId) + _liq.deltaIds[i];
                if (_id < 0 || uint256(_id) > type(uint24).max) revert DLRouter__IdOverflows(_id);
                depositIds[i] = uint256(_id);
            }

            uint256 _amountXAdded;
            uint256 _amountYAdded;

            (_amountXAdded, _amountYAdded, liquidityMinted) = _DLPair.mint(
                depositIds,
                _liq.distributionX,
                _liq.distributionY,
                _liq.to
            );

            if (_amountXAdded < _liq.amountXMin || _amountYAdded < _liq.amountYMin)
                revert DLRouter__AmountSlippageCaught(_liq.amountXMin, _amountXAdded, _liq.amountYMin, _amountYAdded);
        }
    }

    /// @notice Helper function to remove liquidity
    /// @param _DLPair The address of the DLPair
    /// @param _amountXMin The min amount to receive of token X
    /// @param _amountYMin The min amount to receive of token Y
    /// @param _ids The list of ids to burn
    /// @param _amounts The list of amounts to burn of each id in `_ids`
    /// @param _to The address of the recipient
    /// @return amountX The amount of token X sent by the pair
    /// @return amountY The amount of token Y sent by the pair
    function _removeLiquidity(
        IDLPair _DLPair,
        uint256 _amountXMin,
        uint256 _amountYMin,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        address _to
    ) internal returns (uint256 amountX, uint256 amountY) {
        IDLToken(address(_DLPair)).safeBatchTransferFrom(msg.sender, address(_DLPair), _ids, _amounts);
        (amountX, amountY) = _DLPair.burn(_ids, _amounts, _to);
        if (amountX < _amountXMin || amountY < _amountYMin)
            revert DLRouter__AmountSlippageCaught(_amountXMin, amountX, _amountYMin, amountY);
    }
    
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import "../../DLErrors.sol";
import {TokenHelper} from "../../libraries/TokenHelper.sol";
import {IDLFactory} from "../../interfaces/IDLFactory.sol";
import {IDLPair} from "../../interfaces/IDLPair.sol";
import {IWCT} from "../../interfaces/IWCT.sol";
import {DLRouterViews} from "./DLRouterViews.sol";

/// @title Discretized Liquidity Router
/// @author Bentoswap
/// @notice Contract used to manage router swaps
abstract contract DLRouterSwaps is DLRouterViews {
    using TokenHelper for IERC20;

    constructor(IDLFactory _factory, IWCT _wct) DLRouterViews(_factory, _wct) {}

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- EXTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @notice Swaps exact tokens for tokens while performing safety checks
    /// @param _amountIn The amount of token to send
    /// @param _amountOutMin The min amount of token to receive
    /// @param _pairBinSteps The bin step of the pairs
    /// @param _tokenPath The swap path using the binSteps following `_pairBinSteps`
    /// @param _to The address of the recipient
    /// @param _deadline The deadline of the tx
    /// @return amountOut Output amount of the swap
    function swapExactTokensForTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256[] memory _pairBinSteps,
        IERC20[] memory _tokenPath,
        address _to,
        uint256 _deadline
    ) external override ensure(_deadline) verifyInputs(_pairBinSteps, _tokenPath) returns (uint256 amountOut) {
        address[] memory _pairs = _getPairs(_pairBinSteps, _tokenPath);

        _tokenPath[0].safeTransferFrom(msg.sender, _pairs[0], _amountIn);

        amountOut = _swapExactTokensForTokens(_amountIn, _pairs, _pairBinSteps, _tokenPath, _to);
        if (_amountOutMin > amountOut) revert DLRouter__InsufficientAmountOut(_amountOutMin, amountOut);
    }

    /// @notice Swaps exact tokens for Chain Token (CT) (i.e. eth/avax/matic) while performing safety checks
    /// @param _amountIn The amount of token to send
    /// @param _amountOutMinCT The min amount of Chain Token (CT) (i.e. eth/avax/matic) to receive
    /// @param _pairBinSteps The bin step of the pairs
    /// @param _tokenPath The swap path using the binSteps following `_pairBinSteps`
    /// @param _to The address of the recipient
    /// @param _deadline The deadline of the tx
    /// @return amountOut Output amount of the swap
    function swapExactTokensForWCT(
        uint256 _amountIn,
        uint256 _amountOutMinCT,
        uint256[] memory _pairBinSteps,
        IERC20[] memory _tokenPath,
        address payable _to,
        uint256 _deadline
    ) external override ensure(_deadline) verifyInputs(_pairBinSteps, _tokenPath) returns (uint256 amountOut) {
        if (_tokenPath[_pairBinSteps.length] != IERC20(wct))
            revert DLRouter__InvalidTokenPath(address(_tokenPath[_pairBinSteps.length]));
        address[] memory _pairs = _getPairs(_pairBinSteps, _tokenPath);

        _tokenPath[0].safeTransferFrom(msg.sender, _pairs[0], _amountIn);

        amountOut = _swapExactTokensForTokens(_amountIn, _pairs, _pairBinSteps, _tokenPath, address(this));
        if (_amountOutMinCT > amountOut) revert DLRouter__InsufficientAmountOut(_amountOutMinCT, amountOut);
        _wctWithdrawAndTransfer(_to, amountOut);
    }

    /// @notice Swaps exact Chain Token (CT) (i.e. eth/avax/matic) for tokens while performing safety checks
    /// @param _amountOutMin The min amount of token to receive
    /// @param _pairBinSteps The bin step of the pairs
    /// @param _tokenPath The swap path using the binSteps following `_pairBinSteps`
    /// @param _to The address of the recipient
    /// @param _deadline The deadline of the tx
    /// @return amountOut Output amount of the swap
    function swapExactWCTForTokens(
        uint256 _amountOutMin,
        uint256[] memory _pairBinSteps,
        IERC20[] memory _tokenPath,
        address _to,
        uint256 _deadline
    ) external payable override ensure(_deadline) verifyInputs(_pairBinSteps, _tokenPath) returns (uint256 amountOut) {
        if (_tokenPath[0] != IERC20(wct)) revert DLRouter__InvalidTokenPath(address(_tokenPath[0]));
        address[] memory _pairs = _getPairs(_pairBinSteps, _tokenPath);

        _wctDepositAndTransfer(_pairs[0], msg.value);

        amountOut = _swapExactTokensForTokens(msg.value, _pairs, _pairBinSteps, _tokenPath, _to);
        if (_amountOutMin > amountOut) revert DLRouter__InsufficientAmountOut(_amountOutMin, amountOut);
    }

    /// @notice Swaps tokens for exact tokens while performing safety checks
    /// @param _amountOut The amount of token to receive
    /// @param _amountInMax The max amount of token to send
    /// @param _pairBinSteps The bin step of the pairs
    /// @param _tokenPath The swap path using the binSteps following `_pairBinSteps`
    /// @param _to The address of the recipient
    /// @param _deadline The deadline of the tx
    /// @return amountsIn Input amounts for every step of the swap
    function swapTokensForExactTokens(
        uint256 _amountOut,
        uint256 _amountInMax,
        uint256[] memory _pairBinSteps,
        IERC20[] memory _tokenPath,
        address _to,
        uint256 _deadline
    ) external override ensure(_deadline) verifyInputs(_pairBinSteps, _tokenPath) returns (uint256[] memory amountsIn) {
        address[] memory _pairs = _getPairs(_pairBinSteps, _tokenPath);
        amountsIn = _getAmountsIn(_pairBinSteps, _pairs, _tokenPath, _amountOut);
        if (amountsIn[0] > _amountInMax) revert DLRouter__MaxAmountInExceeded(_amountInMax, amountsIn[0]);

        _tokenPath[0].safeTransferFrom(msg.sender, _pairs[0], amountsIn[0]);

        uint256 _amountOutReal = _swapTokensForExactTokens(_pairs, _pairBinSteps, _tokenPath, _to);
        if (_amountOutReal < _amountOut) revert DLRouter__InsufficientAmountOut(_amountOut, _amountOutReal);
    }

    /// @notice Swaps tokens for exact Chain Token (CT) (i.e. eth/avax/matic) while performing safety checks
    /// @param _amountCTOut The amount of Chain Token (CT) (i.e. eth/avax/matic) to receive
    /// @param _amountInMax The max amount of token to send
    /// @param _pairBinSteps The bin step of the pairs
    /// @param _tokenPath The swap path using the binSteps following `_pairBinSteps`
    /// @param _to The address of the recipient
    /// @param _deadline The deadline of the tx
    /// @return amountsIn Input amounts for every step of the swap
    function swapTokensForExactWCT(
        uint256 _amountCTOut,
        uint256 _amountInMax,
        uint256[] memory _pairBinSteps,
        IERC20[] memory _tokenPath,
        address payable _to,
        uint256 _deadline
    ) external override ensure(_deadline) verifyInputs(_pairBinSteps, _tokenPath) returns (uint256[] memory amountsIn) {
        if (_tokenPath[_pairBinSteps.length] != IERC20(wct))
            revert DLRouter__InvalidTokenPath(address(_tokenPath[_pairBinSteps.length]));
        address[] memory _pairs = _getPairs(_pairBinSteps, _tokenPath);
        amountsIn = _getAmountsIn(_pairBinSteps, _pairs, _tokenPath, _amountCTOut);
        if (amountsIn[0] > _amountInMax) revert DLRouter__MaxAmountInExceeded(_amountInMax, amountsIn[0]);

        _tokenPath[0].safeTransferFrom(msg.sender, _pairs[0], amountsIn[0]);
        uint256 _amountOutReal = _swapTokensForExactTokens(_pairs, _pairBinSteps, _tokenPath, address(this));

        if (_amountOutReal < _amountCTOut) revert DLRouter__InsufficientAmountOut(_amountCTOut, _amountOutReal);
        _wctWithdrawAndTransfer(_to, _amountOutReal);
    }

    /// @notice Swaps Chain Token (CT) (i.e. eth/avax/matic) for exact tokens while performing safety checks
    /// @dev Will refund any Chain Token (CT) (i.e. eth/avax/matic) amount sent in excess to `msg.sender`
    /// @param _amountOut The amount of tokens to receive
    /// @param _pairBinSteps The bin step of the pairs
    /// @param _tokenPath The swap path using the binSteps following `_pairBinSteps`
    /// @param _to The address of the recipient
    /// @param _deadline The deadline of the tx
    /// @return amountsIn Input amounts for every step of the swap
    function swapWCTForExactTokens(
        uint256 _amountOut,
        uint256[] memory _pairBinSteps,
        IERC20[] memory _tokenPath,
        address _to,
        uint256 _deadline
    )
        external
        payable
        override
        ensure(_deadline)
        verifyInputs(_pairBinSteps, _tokenPath)
        returns (uint256[] memory amountsIn)
    {
        if (_tokenPath[0] != IERC20(wct)) revert DLRouter__InvalidTokenPath(address(_tokenPath[0]));
        address[] memory _pairs = _getPairs(_pairBinSteps, _tokenPath);
        amountsIn = _getAmountsIn(_pairBinSteps, _pairs, _tokenPath, _amountOut);
        if (amountsIn[0] > msg.value) revert DLRouter__MaxAmountInExceeded(msg.value, amountsIn[0]);

        _wctDepositAndTransfer(_pairs[0], amountsIn[0]);
        uint256 _amountOutReal = _swapTokensForExactTokens(_pairs, _pairBinSteps, _tokenPath, _to);

        if (_amountOutReal < _amountOut) revert DLRouter__InsufficientAmountOut(_amountOut, _amountOutReal);
        if (msg.value > amountsIn[0]) _safeTransferCT(msg.sender, msg.value - amountsIn[0]);
    }

    /// @notice Swaps exact tokens for tokens while performing safety checks supporting for fee on transfer tokens
    /// @param _amountIn The amount of token to send
    /// @param _amountOutMin The min amount of token to receive
    /// @param _pairBinSteps The bin step of the pairs
    /// @param _tokenPath The swap path using the binSteps following `_pairBinSteps`
    /// @param _to The address of the recipient
    /// @param _deadline The deadline of the tx
    /// @return amountOut Output amount of the swap
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256[] memory _pairBinSteps,
        IERC20[] memory _tokenPath,
        address _to,
        uint256 _deadline
    ) external override ensure(_deadline) verifyInputs(_pairBinSteps, _tokenPath) returns (uint256 amountOut) {
        address[] memory _pairs = _getPairs(_pairBinSteps, _tokenPath);
        IERC20 _targetToken = _tokenPath[_pairs.length];
        uint256 _balanceBefore = _targetToken.balanceOf(_to);

        _tokenPath[0].safeTransferFrom(msg.sender, _pairs[0], _amountIn);
        _swapSupportingFeeOnTransferTokens(_pairs, _pairBinSteps, _tokenPath, _to);

        amountOut = _targetToken.balanceOf(_to) - _balanceBefore;
        if (_amountOutMin > amountOut) revert DLRouter__InsufficientAmountOut(_amountOutMin, amountOut);
    }

    /// @notice Swaps exact tokens for Chain Token (CT) (i.e. eth/avax/matic) while performing safety checks supporting for fee on transfer tokens
    /// @param _amountIn The amount of token to send
    /// @param _amountOutMinCT The min amount of Chain Token (CT) (i.e. eth/avax/matic) to receive
    /// @param _pairBinSteps The bin step of the pairs
    /// @param _tokenPath The swap path using the binSteps following `_pairBinSteps`
    /// @param _to The address of the recipient
    /// @param _deadline The deadline of the tx
    /// @return amountOut Output amount of the swap
    function swapExactTokensForWCTSupportingFeeOnTransferTokens(
        uint256 _amountIn,
        uint256 _amountOutMinCT,
        uint256[] memory _pairBinSteps,
        IERC20[] memory _tokenPath,
        address payable _to,
        uint256 _deadline
    ) external override ensure(_deadline) verifyInputs(_pairBinSteps, _tokenPath) returns (uint256 amountOut) {
        if (_tokenPath[_pairBinSteps.length] != IERC20(wct))
            revert DLRouter__InvalidTokenPath(address(_tokenPath[_pairBinSteps.length]));
        address[] memory _pairs = _getPairs(_pairBinSteps, _tokenPath);
        uint256 _balanceBefore = wct.balanceOf(address(this));

        _tokenPath[0].safeTransferFrom(msg.sender, _pairs[0], _amountIn);
        _swapSupportingFeeOnTransferTokens(_pairs, _pairBinSteps, _tokenPath, address(this));

        amountOut = wct.balanceOf(address(this)) - _balanceBefore;
        if (_amountOutMinCT > amountOut) revert DLRouter__InsufficientAmountOut(_amountOutMinCT, amountOut);

        _wctWithdrawAndTransfer(_to, amountOut);
    }

    /// @notice Swaps exact Chain Token (CT) (i.e. eth/avax/matic) for tokens while performing safety checks supporting for fee on transfer tokens
    /// @param _amountOutMin The min amount of token to receive
    /// @param _pairBinSteps The bin step of the pairs
    /// @param _tokenPath The swap path using the binSteps following `_pairBinSteps`
    /// @param _to The address of the recipient
    /// @param _deadline The deadline of the tx
    /// @return amountOut Output amount of the swap
    function swapExactWCTForTokensSupportingFeeOnTransferTokens(
        uint256 _amountOutMin,
        uint256[] memory _pairBinSteps,
        IERC20[] memory _tokenPath,
        address _to,
        uint256 _deadline
    ) external payable override ensure(_deadline) verifyInputs(_pairBinSteps, _tokenPath) returns (uint256 amountOut) {
        if (_tokenPath[0] != IERC20(wct)) revert DLRouter__InvalidTokenPath(address(_tokenPath[0]));
        address[] memory _pairs = _getPairs(_pairBinSteps, _tokenPath);
        IERC20 _targetToken = _tokenPath[_pairs.length];
        uint256 _balanceBefore = _targetToken.balanceOf(_to);

        _wctDepositAndTransfer(_pairs[0], msg.value);
        _swapSupportingFeeOnTransferTokens(_pairs, _pairBinSteps, _tokenPath, _to);

        amountOut = _targetToken.balanceOf(_to) - _balanceBefore;
        if (_amountOutMin > amountOut) revert DLRouter__InsufficientAmountOut(_amountOutMin, amountOut);
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- INTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @notice Helper function to swap exact tokens for tokens
    /// @param _amountIn The amount of token sent
    /// @param _pairs The list of pairs
    /// @param _pairBinSteps The bin step of the pairs
    /// @param _tokenPath The swap path using the binSteps following `_pairBinSteps`
    /// @param _to The address of the recipient
    /// @return amountOut The amount of token sent to `_to`
    function _swapExactTokensForTokens(
        uint256 _amountIn,
        address[] memory _pairs,
        uint256[] memory _pairBinSteps,
        IERC20[] memory _tokenPath,
        address _to
    ) internal returns (uint256 amountOut) {
        amountOut = _amountIn;
        for (uint256 i; i < _pairs.length; ++i) {
            (uint256 _amountXOut, uint256 _amountYOut, bool _swapForY) =
                _swap(_pairs[i], _pairBinSteps[i], _tokenPath[i], _tokenPath[i + 1], i + 1 == _pairs.length ? _to : _pairs[i + 1]);
            amountOut = _swapForY ? _amountYOut : _amountXOut;
        }
    }

    /// @notice Helper function to swap tokens for exact tokens
    /// @param _pairs The array of pairs
    /// @param _pairBinSteps The bin step of the pairs
    /// @param _tokenPath The swap path using the binSteps following `_pairBinSteps`
    /// @param _to The address of the recipient
    /// @return amountOut The amount of token sent to `_to`
    function _swapTokensForExactTokens(
        address[] memory _pairs,
        uint256[] memory _pairBinSteps,
        IERC20[] memory _tokenPath,
        address _to
    ) internal returns (uint256 amountOut) {
        for (uint256 i; i < _pairs.length; ++i) {
            (uint256 _amountXOut, uint256 _amountYOut, bool _swapForY) =
                _swap(_pairs[i], _pairBinSteps[i], _tokenPath[i], _tokenPath[i + 1], i + 1 == _pairs.length ? _to : _pairs[i + 1]);
            amountOut = _swapForY ? _amountYOut : _amountXOut;
        }
    }

    /// @notice Helper function to swap exact tokens supporting for fee on transfer tokens
    /// @param _pairs The list of pairs
    /// @param _pairBinSteps The bin step of the pairs
    /// @param _tokenPath The swap path using the binSteps following `_pairBinSteps`
    /// @param _to The address of the recipient
    function _swapSupportingFeeOnTransferTokens(
        address[] memory _pairs,
        uint256[] memory _pairBinSteps,
        IERC20[] memory _tokenPath,
        address _to
    ) internal {
        for (uint256 i; i < _pairs.length; ++i) {
            _swap(_pairs[i], _pairBinSteps[i], _tokenPath[i], _tokenPath[i + 1], i + 1 == _pairs.length ? _to : _pairs[i + 1]);
        }
    }

    /// @notice Helper function to perform a pair swap
    /// @param _pair The pair to swap
    /// @param _pairBinStep The bin step of the pair
    /// @param _tokenA One of the tokens in the pair
    /// @param _tokenB The second token in the pair
    /// @param _recipient The address of the recipient of the swap
    /// @return _amountXOut The amount of tokenX given to the recipient from the swap
    /// @return _amountYOut The amount of tokenY given to the recipient from the swap
    /// @return _swapForY If the swap was performed for the Y token of the given pair
    function _swap(
        address _pair,
        uint256 _pairBinStep,
        IERC20 _tokenA,
        IERC20 _tokenB,
        address _recipient
    ) internal returns (uint256 _amountXOut, uint256 _amountYOut, bool _swapForY) {
        unchecked {
            if (_pairBinStep == 0) {
                revert DLRouter__MissingBinStepForPair(address(_tokenA), address(_tokenB));
            }
            _swapForY = _tokenB == IDLPair(_pair).tokenY();
            (_amountXOut, _amountYOut) = IDLPair(_pair).swap(_swapForY, _recipient);
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

pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import "../../DLErrors.sol";
import {BinHelper} from "../../libraries/BinHelper.sol";
import {Constants} from "../../libraries/Constants.sol";
import {FeeHelper} from "../../libraries/FeeHelper.sol";
import {Math512Bits} from "../../libraries/Math512Bits.sol";
import {SwapHelper} from "../../libraries/SwapHelper.sol";
import {IDLFactory} from "../../interfaces/IDLFactory.sol";
import {IDLPair} from "../../interfaces/IDLPair.sol";
import {IWCT} from "../../interfaces/IWCT.sol";
import {DLRouterState} from "./DLRouterState.sol";

/// @title Discretized Liquidity Router
/// @author Bentoswap
/// @notice Contract used to manage view functions to be used internally and externally
abstract contract DLRouterViews is DLRouterState {
    using FeeHelper for FeeHelper.FeeParameters;
    using Math512Bits for uint256;
    using SwapHelper for IDLPair.Bin;

    constructor(IDLFactory _factory, IWCT _wct) DLRouterState(_factory, _wct) {}

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- EXTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @notice Simulate a swap in
    /// @param _dlPair The address of the DLPair
    /// @param _amountOut The amount of token to receive
    /// @param _swapForY Whether you swap X for Y (true), or Y for X (false)
    /// @return amountIn The amount of token to send in order to receive _amountOut token
    /// @return feesIn The amount of fees paid in token sent
    function getSwapIn(
        IDLPair _dlPair,
        uint256 _amountOut,
        bool _swapForY
    ) external view override returns (uint256 amountIn, uint256 feesIn) {
        (amountIn, feesIn) = _getSwapIn(_dlPair, _amountOut, _swapForY);
    }

    /// @notice Simulate a swap out
    /// @param _dlPair The address of the DLPair
    /// @param _amountIn The amount of token sent
    /// @param _swapForY Whether you swap X for Y (true), or Y for X (false)
    /// @return amountOut The amount of token received if _amountIn tokenX are sent
    /// @return feesIn The amount of fees paid in token sent
    function getSwapOut(
        IDLPair _dlPair,
        uint256 _amountIn,
        bool _swapForY
    ) external view override returns (uint256 amountOut, uint256 feesIn) {
        (amountOut, feesIn) = _getSwapOut(_dlPair, _amountIn, _swapForY);
    }

    /// @notice Returns the approximate id corresponding to the inputted price.
    /// Warning, the returned id may be inaccurate close to the start price of a bin
    /// @param _dlPair The address of the DLPair
    /// @param _price The price of y per x (multiplied by 1e36)
    /// @return The id corresponding to this price
    function getIdFromPrice(IDLPair _dlPair, uint256 _price) external view override returns (uint24) {
        return BinHelper.getIdFromPrice(_price, _dlPair.feeParameters().binStep);
    }

    /// @notice Returns the price corresponding to the inputted id
    /// @param _dlPair The address of the DLPair
    /// @param _id The id
    /// @return The price corresponding to this id
    function getPriceFromId(IDLPair _dlPair, uint24 _id) external view override returns (uint256) {
        return BinHelper.getPriceFromId(_id, _dlPair.feeParameters().binStep);
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- INTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @notice Helper function to return the amounts in
    /// @param _pairBinSteps The bin step of the pairs
    /// @param _pairs The list of pairs
    /// @param _tokenPath The swap path
    /// @param _amountOut The amount out
    /// @return amountsIn The list of amounts in
    function _getAmountsIn(
        uint256[] memory _pairBinSteps,
        address[] memory _pairs,
        IERC20[] memory _tokenPath,
        uint256 _amountOut
    ) internal view returns (uint256[] memory amountsIn) {
        amountsIn = new uint256[](_tokenPath.length);
        // Avoid doing -1, as `_pairs.length == _pairBinSteps.length-1`
        amountsIn[_pairs.length] = _amountOut;

        for (uint256 i = _pairs.length; i != 0; i--) {
            IERC20 _token = _tokenPath[i - 1];
            uint256 _binStep = _pairBinSteps[i - 1];
            address _pair = _pairs[i - 1];
            if (_binStep == 0) {
                revert DLRouter__MissingBinStepForPair(address(IDLPair(_pair).tokenX()), address(IDLPair(_pair).tokenY()));
            }

            (amountsIn[i - 1], ) = _getSwapIn(IDLPair(_pair), amountsIn[i], IDLPair(_pair).tokenX() == _token);
        }
    }

    /// @notice Simulate a swap in
    /// @param _dlPair The address of the DLPair
    /// @param _amountOut The amount of token to receive
    /// @param _swapForY Whether you swap X for Y (true), or Y for X (false)
    /// @return amountIn The amount of token to send in order to receive _amountOut token
    /// @return feesIn The amount of fees paid in token sent
    function _getSwapIn(
        IDLPair _dlPair,
        uint256 _amountOut,
        bool _swapForY
    ) internal view returns (uint256 amountIn, uint256 feesIn) {
        (uint256 _pairReserveX, uint256 _pairReserveY, uint256 _activeId) = _dlPair.getReservesAndId();

        if (_amountOut == 0 || (_swapForY ? _amountOut > _pairReserveY : _amountOut > _pairReserveX))
            revert DLRouter__WrongAmounts(_amountOut, _swapForY ? _pairReserveY : _pairReserveX); // If this is wrong, then we're sure the amounts sent are wrong

        FeeHelper.FeeParameters memory _fp = _dlPair.feeParameters();
        _fp.updateVariableFeeParameters(_activeId);

        uint256 _amountOutOfBin;
        uint256 _amountInWithFees;
        uint256 _reserve;
        // Performs the actual swap, bin per bin
        // It uses the findFirstNonEmptyBinId function to make sure the bin we're currently looking at
        // has liquidity in it.
        while (true) {
            {
                (uint256 _reserveX, uint256 _reserveY) = _dlPair.getBin(uint24(_activeId));
                _reserve = _swapForY ? _reserveY : _reserveX;
            }
            uint256 _price = BinHelper.getPriceFromId(_activeId, _fp.binStep);
            if (_reserve != 0) {
                _amountOutOfBin = _amountOut >= _reserve ? _reserve : _amountOut;
                uint256 _amountInToBin = _swapForY
                    ? _amountOutOfBin.shiftDivRoundUp(Constants.SCALE_OFFSET, _price)
                    : _price.mulShiftRoundUp(_amountOutOfBin, Constants.SCALE_OFFSET);

                // We update the fee, but we don't store the new volatility reference, volatility accumulated and indexRef to not penalize traders
                _fp.updateVolatilityAccumulated(_activeId);
                uint256 _fee = _fp.getFeeAmount(_amountInToBin);
                _amountInWithFees = _amountInToBin + _fee;

                if (_amountInWithFees + _reserve > type(uint112).max) revert DLRouter__SwapOverflows(_activeId);
                amountIn += _amountInWithFees;
                feesIn += _fee;
                _amountOut -= _amountOutOfBin;
            }

            if (_amountOut != 0) {
                _activeId = _dlPair.findFirstNonEmptyBinId(uint24(_activeId), _swapForY);
            } else {
                break;
            }
        }
        if (_amountOut != 0) revert DLRouter__BrokenSwapSafetyCheck(); // Safety check, but should never be false as it would have reverted on transfer
    }

    /// @notice Simulate a swap out
    /// @param _dlPair The address of the DLPair
    /// @param _amountIn The amount of token sent
    /// @param _swapForY Whether you swap X for Y (true), or Y for X (false)
    /// @return amountOut The amount of token received if _amountIn tokenX are sent
    /// @return feesIn The amount of fees paid in token sent
    function _getSwapOut(
        IDLPair _dlPair,
        uint256 _amountIn,
        bool _swapForY
    ) internal view returns (uint256 amountOut, uint256 feesIn) {
        (, , uint256 _activeId) = _dlPair.getReservesAndId();

        FeeHelper.FeeParameters memory _fp = _dlPair.feeParameters();
        _fp.updateVariableFeeParameters(_activeId);
        IDLPair.Bin memory _bin;

        // Performs the actual swap, bin per bin
        // It uses the findFirstNonEmptyBinId function to make sure the bin we're currently looking at
        // has liquidity in it.
        while (true) {
            {
                (uint256 _reserveX, uint256 _reserveY) = _dlPair.getBin(uint24(_activeId));
                _bin = IDLPair.Bin(uint112(_reserveX), uint112(_reserveY), 0, 0);
            }
            if (_bin.reserveX != 0 || _bin.reserveY != 0) {
                (uint256 _amountInToBin, uint256 _amountOutOfBin, FeeHelper.FeesDistribution memory _fees) = _bin
                    .getAmounts(_fp, _activeId, _swapForY, _amountIn);

                if (_amountInToBin > type(uint112).max) revert DLRouter__BinReserveOverflows(_activeId);

                _amountIn -= _amountInToBin + _fees.total;
                feesIn += _fees.total;
                amountOut += _amountOutOfBin;
            }

            if (_amountIn != 0) {
                _activeId = _dlPair.findFirstNonEmptyBinId(uint24(_activeId), _swapForY);
            } else {
                break;
            }
        }
        if (_amountIn != 0) revert DLRouter__TooMuchTokensIn(_amountIn);
    }

    /// @notice Helper function to return the address of the DLPair
    /// @dev Revert if the pair is not created yet
    /// @param _tokenX The address of the tokenX
    /// @param _tokenY The address of the tokenY
    /// @param _binStep The bin step of the DLPair
    /// @return The address of the DLPair
    function _getDLPairInformation(
        IERC20 _tokenX,
        IERC20 _tokenY,
        uint256 _binStep
    ) internal view returns (IDLPair) {
        IDLPair _dlPair = factory.getDLPairInformation(_tokenX, _tokenY, _binStep).dlPair;
        if (address(_dlPair) == address(0))
            revert DLRouter__PairNotCreated(address(_tokenX), address(_tokenY), _binStep);
        return _dlPair;
    }

    /// @notice Helper function to return the address of the pair
    /// @dev Revert if the pair is not created yet
    /// @param _binStep The bin step of the DLPair
    /// @param _tokenX The address of the tokenX
    /// @param _tokenY The address of the tokenY
    /// @return _pair The address of the pair of binStep `_binStep`
    function _getPair(
        uint256 _binStep,
        IERC20 _tokenX,
        IERC20 _tokenY
    ) internal view returns (address _pair) {
        if (_binStep == 0) {
            revert DLRouter__MissingBinStepForPair(address(_tokenX), address(_tokenY));
        }
        
        _pair = address(_getDLPairInformation(_tokenX, _tokenY, _binStep));
    }

    function _getPairs(uint256[] memory _pairBinSteps, IERC20[] memory _tokenPath)
        internal
        view
        returns (address[] memory pairs)
    {
        pairs = new address[](_pairBinSteps.length);

        IERC20 _token;
        IERC20 _tokenNext = _tokenPath[0];
        unchecked {
            for (uint256 i; i < pairs.length; ++i) {
                _token = _tokenNext;
                _tokenNext = _tokenPath[i + 1];

                pairs[i] = _getPair(_pairBinSteps[i], _token, _tokenNext);
            }
        }
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

import "../../DLErrors.sol";
import {TokenHelper} from "../../libraries/TokenHelper.sol";
import {IDLFactory} from "../../interfaces/IDLFactory.sol";
import {IDLRouter, IWCT} from "../../interfaces/IDLRouter.sol";

/// @title Discretized Liquidity Router State
/// @author Bentoswap
/// @notice Contract used to hold the contract state and shared functions that read/write state
abstract contract DLRouterState is IDLRouter {
    using TokenHelper for IWCT;

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //       -'~'-.,__,.-'~'-.,__,.- VARS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    IDLFactory public immutable override factory;
    IWCT public immutable override wct;

    /// @notice Constructor
    /// @param _factory DLFactory address
    /// @param _wct Address of WCT
    constructor(IDLFactory _factory, IWCT _wct) {
        factory = _factory;
        wct = _wct;
    }

    /// @dev Receive function that only accept Chain Token (CT) (i.e. eth/avax/matic) from the WCT contract
    receive() external payable {
        if (msg.sender != address(wct)) revert DLRouter__SenderIsNotWCT();
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //     -'~'-.,__,.-'~'-.,__,.- INTERNAL -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    /// @notice Helper function to deposit and transfer wct
    /// @param _to The address of the recipient
    /// @param _amount The Chain Token (CT) (i.e. eth/avax/matic) amount to wrap
    function _wctDepositAndTransfer(address _to, uint256 _amount) internal {
        wct.deposit{value: _amount}();
        wct.safeTransfer(_to, _amount);
    }

    /// @notice Helper function to withdraw and transfer wct
    /// @param _to The address of the recipient
    /// @param _amount The Chain Token (CT) (i.e. eth/avax/matic) amount to unwrap
    function _wctWithdrawAndTransfer(address _to, uint256 _amount) internal {
        wct.withdraw(_amount);
        _safeTransferCT(_to, _amount);
    }

    /// @notice Helper function to transfer CT
    /// @param _to The address of the recipient
    /// @param _amount The Chain Token (CT) (i.e. eth/avax/matic) amount to send
    function _safeTransferCT(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) revert DLRouter__FailedToSendCT(_to, _amount);
    }

    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>
    //    -'~'-.,__,.-'~'-.,__,.- MODIFIERS -.,__,.-'~'-.,__,.-'~'-
    // <<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>><<>>

    modifier onlyFactoryOwner() {
        if (msg.sender != factory.owner()) revert DLRouter__NotFactoryOwner();
        _;
    }

    modifier ensure(uint256 _deadline) {
        if (block.timestamp > _deadline) revert DLRouter__DeadlineExceeded(_deadline, block.timestamp);
        _;
    }

    modifier verifyInputs(uint256[] memory _pairBinSteps, IERC20[] memory _tokenPath) {
        if (_pairBinSteps.length == 0 || _pairBinSteps.length + 1 != _tokenPath.length)
            revert DLRouter__LengthsMismatch();
        _;
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

import {IDLFactory} from "./IDLFactory.sol";
import {IDLPair, IERC20} from "./IDLPair.sol";
import {IDLToken} from "./IDLToken.sol";
import {IWCT} from "./IWCT.sol";

/// @title Discretized Liquidity Router Interface
/// @author Bentoswap
/// @notice Required interface of DLRouter contract
interface IDLRouter {
    /// @dev The liquidity parameters, such as:
    /// - tokenX: The address of token X
    /// - tokenY: The address of token Y
    /// - binStep: The bin step of the pair
    /// - amountX: The amount to send of token X
    /// - amountY: The amount to send of token Y
    /// - amountXMin: The min amount of token X added to liquidity
    /// - amountYMin: The min amount of token Y added to liquidity
    /// - activeIdDesired: The active id that user wants to add liquidity from
    /// - idSlippage: The number of id that are allowed to slip
    /// - deltaIds: The list of delta ids to add liquidity (`deltaId = activeId - desiredId`)
    /// - distributionX: The distribution of tokenX with sum(distributionX) = 100e18 (100%) or 0 (0%)
    /// - distributionY: The distribution of tokenY with sum(distributionY) = 100e18 (100%) or 0 (0%)
    /// - to: The address of the recipient
    /// - deadline: The deadline of the tx
    struct LiquidityParameters {
        IERC20 tokenX;
        IERC20 tokenY;
        uint256 binStep;
        uint256 amountX;
        uint256 amountY;
        uint256 amountXMin;
        uint256 amountYMin;
        uint256 activeIdDesired;
        uint256 idSlippage;
        int256[] deltaIds;
        uint256[] distributionX;
        uint256[] distributionY;
        address to;
        uint256 deadline;
    }

    function factory() external view returns (IDLFactory);

    function wct() external view returns (IWCT);

    function getIdFromPrice(IDLPair DLPair, uint256 price) external view returns (uint24);

    function getPriceFromId(IDLPair DLPair, uint24 id) external view returns (uint256);

    function getSwapIn(
        IDLPair DLPair,
        uint256 amountOut,
        bool swapForY
    ) external view returns (uint256 amountIn, uint256 feesIn);

    function getSwapOut(
        IDLPair DLPair,
        uint256 amountIn,
        bool swapForY
    ) external view returns (uint256 amountOut, uint256 feesIn);

    function createDLPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint24 activeId,
        uint16 binStep
    ) external returns (IDLPair pair);

    function addLiquidity(LiquidityParameters calldata liquidityParameters)
        external
        returns (uint256[] memory depositIds, uint256[] memory liquidityMinted);

    function addLiquidityWCT(LiquidityParameters calldata liquidityParameters)
        external
        payable
        returns (uint256[] memory depositIds, uint256[] memory liquidityMinted);

    function removeLiquidity(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address to,
        uint256 deadline
    ) external returns (uint256 amountX, uint256 amountY);

    function removeLiquidityWCT(
        IERC20 token,
        uint16 binStep,
        uint256 amountTokenMin,
        uint256 amountWCTMin,
        uint256[] memory ids,
        uint256[] memory amounts,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountWCT);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForWCT(
        uint256 amountIn,
        uint256 amountOutMinWCT,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactWCTForTokens(
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function swapTokensForExactWCT(
        uint256 amountOut,
        uint256 amountInMax,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address payable to,
        uint256 deadline
    ) external returns (uint256[] memory amountsIn);

    function swapWCTForExactTokens(
        uint256 amountOut,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amountsIn);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactTokensForWCTSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMinWCT,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address payable to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactWCTForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        uint256[] memory pairBinSteps,
        IERC20[] memory tokenPath,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function sweep(
        IERC20 token,
        address to,
        uint256 amount
    ) external;
}