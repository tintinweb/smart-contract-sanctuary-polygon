// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @notice IFeesController
 * @author Atlendis Labs
 * Contract responsible for gathering protocol fees from users
 * actions and making it available for governance to withdraw
 * Is called from the pools contracts directly
 */
interface IFeesController {
    /*//////////////////////////////////////////////////////////////
                             EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when management fees are registered
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     **/
    event ManagementFeesRegistered(address token, uint256 amount);

    /**
     * @notice Emitted when exit fees are registered
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     * @param rate Exit fees rate
     **/
    event ExitFeesRegistered(address token, uint256 amount, uint256 rate);

    /**
     * @notice Emitted when borrowing fees are registered
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     **/
    event BorrowingFeesRegistered(address token, uint256 amount);

    /**
     * @notice Emitted when repayment fees are registered
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     **/
    event RepaymentFeesRegistered(address token, uint256 amount);

    /**
     * @notice Emitted when fees are withdrawn from the fee collector
     * @param token Token address of the fees taken
     * @param amount Amount of fees taken
     * @param to Recipient address of the fees
     **/
    event FeesWithdrawn(address token, uint256 amount, address to);

    /**
     * @notice Emitted when the due fees are pulled from the pool
     * @param token Token address of the fees
     * @param amount Amount of due fees
     */
    event DuesFeesPulled(address token, uint256 amount);

    /**
     * @notice Emitted when pool is initialized
     * @param managedPool Address of the managed pool
     */
    event PoolInitialized(address managedPool);

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the repayment fee rate
     * @dev Necessary for RCL pool new epochs amounts accounting
     * @return repaymentFeesRate Amount of fees taken at repayment
     **/
    function getRepaymentFeesRate() external view returns (uint256 repaymentFeesRate);

    /**
     * @notice Get the total amount of fees currently held by the contract for the target token
     * @param token Address of the token for which total fees are queried
     * @return fees Amount of fee held by the contract
     **/
    function getTotalFees(address token) external view returns (uint256 fees);

    /**
     * @notice Get the amount of fees currently held by the pool contract for the target token ready to be withdrawn to the Fees Controller
     * @param token Address of the token for which total fees are queried
     * @return fees Amount of fee held by the pool contract
     **/
    function getDueFees(address token) external view returns (uint256 fees);

    /**
     * @notice Get the managed pool contract address
     * @return managedPool The managed pool contract address
     */
    function getManagedPool() external view returns (address managedPool);

    /*//////////////////////////////////////////////////////////////
                             EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register fees on lender position withdrawal
     * @param amount Withdrawn amount subjected to fees
     * @return fees Amount of fees taken in the pool token for pool accounting
     *
     * Emits a {ManagementFeesRegistered} event
     **/
    function registerManagementFees(uint256 amount) external returns (uint256 fees);

    /**
     * @notice Register fees on exit
     * @param amount Exited amount subjected to fees
     * @return fees Amount of fees taken in the pool token for pool accounting
     *
     * Emits a {ExitFeesRegistered} event
     **/
    function registerExitFees(uint256 amount, uint256 timeUntilMaturity) external returns (uint256 fees);

    /**
     * @notice Register fees on borrow
     * @param amount Borrowed amount subjected to fees
     * @return fees Amount of fees taken in the pool token for pool accounting
     *
     * Emits a {BorrowingFeesRegistered} event
     **/
    function registerBorrowingFees(uint256 amount) external returns (uint256 fees);

    /**
     * @notice Register fees on repayment
     * @param amount Repaid interests subjected to fees
     * @return fees Amount of fees taken in the pool token for pool accounting
     *
     * Emits a {RepaymentFeesRegistered} event
     **/
    function registerRepaymentFees(uint256 amount) external returns (uint256 fees);

    /**
     * @notice Pull dues fees from the pool
     * @param token Address of the token for which the fees are pulled
     *
     * Emits a {DuesFeesPulled} event
     */
    function pullDueFees(address token) external;

    /**
     * @notice Allows the contract owner to withdraw accumulated fees
     * @param token Address of the token for which fees are withdrawn
     * @param amount Amount of fees to withdraw
     * @param to Recipient address of the witdrawn fees
     *
     * Emits a {FeesWithdrawn} event
     **/
    function withdrawFees(
        address token,
        uint256 amount,
        address to
    ) external;

    /**
     * @notice Initialize the managed pool
     * @param managedPool Address of the managed pool
     *
     * Emits a {PoolInitialized} event
     */
    function initializePool(address managedPool) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import {FixedPointMathLib as SolmateFixedPointMathLib} from 'lib/solmate/src/utils/FixedPointMathLib.sol';

/**
 * @title FixedPointMathLib library
 * @author Atlendis Labs
 * @dev Overlay over Solmate FixedPointMathLib
 *      Results of multiplications and divisions are always rounded down
 */
library FixedPointMathLib {
    using SolmateFixedPointMathLib for uint256;

    struct LibStorage {
        uint256 denominator;
    }

    function libStorage() internal pure returns (LibStorage storage ls) {
        bytes32 position = keccak256('diamond.standard.library.storage');
        assembly {
            ls.slot := position
        }
    }

    function setDenominator(uint256 denominator) internal {
        LibStorage storage ls = libStorage();
        ls.denominator = denominator;
    }

    function mul(uint256 x, uint256 y) internal view returns (uint256) {
        return x.mulDivDown(y, libStorage().denominator);
    }

    function div(uint256 x, uint256 y) internal view returns (uint256) {
        return x.mulDivDown(libStorage().denominator, y);
    }

    function mul(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256) {
        return x.mulDivDown(y, denominator);
    }

    function div(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256) {
        return x.mulDivDown(denominator, y);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title DataTypes library
 * @dev Defines the structs and enums used by the revolving credit line
 */
library DataTypes {
    struct BaseEpochsAmounts {
        uint256 adjustedDeposits;
        uint256 adjustedOptedOut;
        uint256 available;
        uint256 borrowed;
    }

    struct NewEpochsAmounts {
        uint256 toBeAdjusted;
        uint256 available;
        uint256 borrowed;
        uint256 optedOut;
    }

    struct WithdrawnAmounts {
        uint256 toBeAdjusted;
        uint256 borrowed;
    }

    struct Epoch {
        bool isBaseEpoch;
        uint256 borrowed;
        uint256 deposited;
        uint256 optedOut;
        uint256 accruals;
        uint256 precedingLoanId;
        uint256 loanId;
    }

    struct Tick {
        uint256 yieldFactor;
        uint256 loanStartEpochId;
        uint256 currentEpochId;
        uint256 latestLoanId;
        BaseEpochsAmounts baseEpochsAmounts;
        NewEpochsAmounts newEpochsAmounts;
        WithdrawnAmounts withdrawnAmounts;
        mapping(uint256 => Epoch) epochs;
        mapping(uint256 => uint256) endOfLoanYieldFactors;
    }

    struct Loan {
        uint256 id;
        uint256 maturity;
        uint256 nonStandardRepaymentTimestamp;
        uint256 lateRepayTimeDelta;
        uint256 lateRepayFeeRate;
        uint256 repaymentFeesRate;
    }

    enum OrderBookPhase {
        OPEN,
        CLOSED,
        NON_STANDARD
    }

    struct Position {
        uint256 baseDeposit;
        uint256 rate;
        uint256 epochId;
        uint256 creationTimestamp;
        uint256 optOutLoanId;
        uint256 withdrawLoanId;
        WithdrawalAmounts withdrawn;
    }

    struct WithdrawalAmounts {
        uint256 borrowed;
        uint256 expectedAccruals;
    }

    struct BorrowInput {
        uint256 totalAmountToBorrow;
        uint256 totalAccrualsToAllocate;
        uint256 rate;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title Errors library
 * @dev Defines the errors used in the Revolving credit line product
 */
library RevolvingCreditLineErrors {
    error RCL_ONLY_LENDER(); // "Operation restricted to lender only"
    error RCL_ONLY_BORROWER(); // "Operation restricted to borrower only"
    error RCL_ONLY_OPERATOR(); // "Operation restricted to operator only"

    error RCL_OUT_OF_BOUND_MIN_RATE(); // "Input rate is below min rate"
    error RCL_OUT_OF_BOUND_MAX_RATE(); // "Input rate is above max rate"
    error RCL_INVALID_RATE_SPACING(); // "Input rate is invalid with respect to rate spacing"
    error RCL_INVALID_PHASE(); // "Phase is invalid for this operation"
    error RCL_ZERO_AMOUNT_NOT_ALLOWED(); // "Zero amount not allowed"
    error RCL_DEPOSIT_AMOUNT_TOO_LOW(); // "Deposit amount is too low"
    error RCL_NO_LIQUIDITY(); // "No liquidity available for the amount to borrow"
    error RCL_LOAN_RUNNING(); // "Loan has not reached maturity"
    error RCL_AMOUNT_EXCEEDS_MAX(); // "Amount exceeds maximum allowed"
    error RCL_NO_LOAN_RUNNING(); // No loan currently running
    error RCL_ONLY_OWNER(); // Has to be position owner
    error RCL_TIMELOCK(); // ActionNot possible within this block
    error RCL_CANNOT_EXIT(); // Cannot exit after maturity
    error RCL_POSITION_NOT_BORROWED(); // The positions is currently not under a borrow
    error RCL_POSITION_BORROWED(); // The positions is currently under a borrow
    error RCL_POSITION_NOT_FULLY_BORROWED(); // The position is currently not fully borrowed
    error RCL_POSITION_FULLY_BORROWED(); // The position is currently fully borrowed
    error RCL_HAS_OPTED_OUT(); // Position that already opted out can not exit
    error RCL_REPAY_TOO_EARLY(); // Cannot repay before repayment period started
    error RCL_WRONG_INPUT(); // The specified input does not pass validation
    error RCL_REMAINING_AMOUNT_TOO_LOW(); // Withdraw or exit cannot result in the position being worth less than the minimum deposit
    error RCL_AMOUNT_TOO_HIGH(); // Cannot withdraw more than the position current value
    error RCL_AMOUNT_TOO_LOW(); // Cannot withdraw less that the minimum position deposit
    error RCL_MATURITY_PASSED(); // Cannot perform the target action after maturity

    error RCL_INVALID_FEES_CONTROLLER_MANAGED_POOL(); // "Managed pool of fees controller is not the instance one"

    error RCL_NOT_ENOUGH_ADJUSTED_DEPOSITS(); // "Adjusted deposits are too low in the tick compared to the input"
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../common/fees/IFeesController.sol';
import '../../../libraries/FixedPointMathLib.sol';
import './Errors.sol';
import './DataTypes.sol';

/**
 * @title TickLogic
 * @author Atlendis Labs
 */
library TickLogic {
    /*//////////////////////////////////////////////////////////////
                                LIBRARIES
    //////////////////////////////////////////////////////////////*/
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint256 constant RAY = 1e27;

    /*//////////////////////////////////////////////////////////////
                            GLOBAL TICK LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Evaluates the increase in yield factor depending on the tick borrow status
     * @param tick Target tick
     * @param timeDelta Duration during which the fees accrue
     * @param rate Rate at which the fees accrue
     * @return yieldFactorIncrease Increase in the yield factor value
     */
    function calculateYieldFactorIncrease(
        DataTypes.Tick storage tick,
        uint256 timeDelta,
        uint256 rate
    ) public view returns (uint256 yieldFactorIncrease) {
        // if base epoch was fully exit yield factor does not increase
        if (tick.baseEpochsAmounts.adjustedDeposits == 0) return 0;
        yieldFactorIncrease = accrualsFor(tick.baseEpochsAmounts.borrowed, timeDelta, rate).div(
            tick.baseEpochsAmounts.adjustedDeposits
        );
    }

    /**
     * @notice Evaluates and includes late repayment fees in tick data
     * @param tick Target tick
     * @param timeDelta Duration between maturity and late repay
     * @param rate Rate at which the fees accrue
     */
    function registerLateRepaymentAccruals(
        DataTypes.Tick storage tick,
        uint256 timeDelta,
        uint256 rate
    ) external {
        if (tick.baseEpochsAmounts.borrowed != 0) {
            tick.yieldFactor += calculateYieldFactorIncrease(tick, timeDelta, rate);
        }
        if (tick.newEpochsAmounts.borrowed != 0) {
            uint256 newEpochsAccruals = accrualsFor(tick.newEpochsAmounts.borrowed, timeDelta, rate);
            tick.newEpochsAmounts.toBeAdjusted += newEpochsAccruals;
        }
        if (tick.withdrawnAmounts.borrowed != 0) {
            uint256 withdrawnAccruals = accrualsFor(tick.withdrawnAmounts.borrowed, timeDelta, rate);
            tick.withdrawnAmounts.toBeAdjusted += withdrawnAccruals;
        }
    }

    /**
     * @notice Prepares all the tick data structures for the next loan cycle
     * @param tick Target tick
     * @param currentLoan Current loan information
     */
    function prepareTickForNextLoan(DataTypes.Tick storage tick, DataTypes.Loan storage currentLoan) external {
        DataTypes.Epoch storage lastEpoch = tick.epochs[tick.currentEpochId];
        if (lastEpoch.borrowed == 0) {
            lastEpoch.isBaseEpoch = true;
            lastEpoch.precedingLoanId = tick.latestLoanId;
        }

        // opted out amounts are not to be adjusted into base epoch
        if (tick.newEpochsAmounts.available + tick.newEpochsAmounts.borrowed > 0) {
            tick.newEpochsAmounts.toBeAdjusted -= tick
                .newEpochsAmounts
                .toBeAdjusted
                .mul(tick.newEpochsAmounts.optedOut)
                .div(tick.newEpochsAmounts.available + tick.newEpochsAmounts.borrowed);
        }

        // wrapping up all tick action and new epochs amounts into the base epoch for the next loan
        uint256 tickAdjusted = tick.baseEpochsAmounts.adjustedDeposits +
            (tick.newEpochsAmounts.toBeAdjusted + tick.withdrawnAmounts.toBeAdjusted).div(tick.yieldFactor) -
            tick.baseEpochsAmounts.adjustedOptedOut;
        uint256 tickAvailable = tickAdjusted.mul(tick.yieldFactor);

        // recording end of loan yield factor for further use
        tick.endOfLoanYieldFactors[currentLoan.id] = tick.yieldFactor;

        // resetting data structures
        delete tick.baseEpochsAmounts;
        delete tick.newEpochsAmounts;
        delete tick.withdrawnAmounts;
        tick.baseEpochsAmounts.adjustedDeposits = tickAdjusted;
        tick.baseEpochsAmounts.available = tickAvailable;
    }

    /*//////////////////////////////////////////////////////////////
                            POSITION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Gets the adjusted amount corresponding to the position depending on its history
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @return adjustedAmount Adjusted amount of the position
     */
    function getAdjustedAmount(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan
    ) public view returns (uint256 adjustedAmount) {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];
        if (position.withdrawLoanId > 0) {
            uint256 lateRepayFees = accrualsFor(
                position.withdrawn.borrowed,
                referenceLoan.lateRepayTimeDelta,
                referenceLoan.lateRepayFeeRate
            );
            uint256 protocolFees = (position.withdrawn.expectedAccruals + lateRepayFees).mul(
                referenceLoan.repaymentFeesRate
            );
            return
                adjustedAmount = (position.withdrawn.borrowed +
                    position.withdrawn.expectedAccruals +
                    lateRepayFees -
                    protocolFees).div(tick.endOfLoanYieldFactors[position.withdrawLoanId]);
        }
        adjustedAmount = position.baseDeposit.div(getEquivalentYieldFactor(tick, epoch, referenceLoan));
    }

    /**
     * @notice Gets the equivalent yield factor for the target epoch depending on its borrow history
     * @param tick Target tick
     * @param epoch Target epoch
     * @param referenceLoan Either first loan or detach loan of the position
     * @return equivalentYieldFactor Equivalent yield factor of the position
     */
    function getEquivalentYieldFactor(
        DataTypes.Tick storage tick,
        DataTypes.Epoch storage epoch,
        DataTypes.Loan storage referenceLoan
    ) public view returns (uint256 equivalentYieldFactor) {
        if (epoch.isBaseEpoch) {
            equivalentYieldFactor = tick.endOfLoanYieldFactors[epoch.precedingLoanId];
        } else {
            uint256 accruals = epoch.accruals +
                accrualsFor(epoch.borrowed, referenceLoan.lateRepayTimeDelta, referenceLoan.lateRepayFeeRate);
            uint256 protocolFees = accruals.mul(referenceLoan.repaymentFeesRate);
            uint256 endOfLoanValue = epoch.deposited + accruals - protocolFees;

            equivalentYieldFactor = tick.endOfLoanYieldFactors[epoch.loanId].mul(epoch.deposited).div(endOfLoanValue);
        }
    }

    /**
     * @notice Gets the position current overall value
     * Holds in all cases whatever the position status
     * Returns the exact position value including non repaid interests of current loan
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return currentValue Current value of the position
     */
    function getPositionCurrentValue(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) public view returns (uint256) {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];
        if (position.optOutLoanId > 0) {
            bool optOutLoanRepaid = (position.optOutLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (optOutLoanRepaid) {
                return
                    getAdjustedAmount(tick, position, referenceLoan).mul(
                        tick.endOfLoanYieldFactors[position.optOutLoanId]
                    );
            }
        }
        if (position.withdrawLoanId > 0) {
            bool withdrawLoanRepaid = (position.withdrawLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (!withdrawLoanRepaid) {
                if (block.timestamp > currentLoan.maturity) {
                    uint256 lateRepayTimeDelta = block.timestamp - currentLoan.maturity;
                    uint256 lateRepayFees = accrualsFor(
                        position.withdrawn.borrowed,
                        lateRepayTimeDelta,
                        currentLoan.lateRepayFeeRate
                    );
                    return position.withdrawn.borrowed + position.withdrawn.expectedAccruals + lateRepayFees;
                } else {
                    uint256 timeUntilMaturity = currentLoan.maturity - block.timestamp;
                    uint256 unrealizedInterests = accrualsFor(
                        position.withdrawn.borrowed,
                        timeUntilMaturity,
                        position.rate
                    );
                    return position.withdrawn.borrowed + position.withdrawn.expectedAccruals - unrealizedInterests;
                }
            }
        }
        // current epoch is never borrowed
        if (position.epochId == tick.currentEpochId) {
            return position.baseDeposit;
        }
        // new epochs for currently ongoing loan share a part of the expected fees
        if (
            (position.epochId > tick.loanStartEpochId) &&
            ((tick.baseEpochsAmounts.borrowed > 0) || (tick.newEpochsAmounts.borrowed > 0))
        ) {
            if (block.timestamp > currentLoan.maturity) {
                uint256 lateRepayTimeDelta = block.timestamp - currentLoan.maturity;
                uint256 lateRepayFees = accrualsFor(epoch.borrowed, lateRepayTimeDelta, currentLoan.lateRepayFeeRate);
                return
                    position.baseDeposit +
                    (epoch.accruals + lateRepayFees).mul(position.baseDeposit).div(epoch.deposited);
            } else {
                uint256 timeUntilMaturity = currentLoan.maturity - block.timestamp;
                uint256 unrealizedInterests = accrualsFor(epoch.borrowed, timeUntilMaturity, position.rate);
                return
                    position.baseDeposit +
                    (epoch.accruals - unrealizedInterests).mul(position.baseDeposit).div(epoch.deposited);
            }
        }

        // all base epochs verify the position value = adjusted value * current yield factor formula
        // we compute the last exact yield factor depending on the state of the loan maturity
        uint256 newYieldFactor = tick.yieldFactor;
        uint256 referenceTimestamp = currentLoan.nonStandardRepaymentTimestamp > 0
            ? currentLoan.nonStandardRepaymentTimestamp
            : block.timestamp;
        if (referenceTimestamp > currentLoan.maturity) {
            uint256 lateRepayFeesYieldFactorDelta = calculateYieldFactorIncrease(
                tick,
                referenceTimestamp - currentLoan.maturity,
                currentLoan.lateRepayFeeRate
            );
            newYieldFactor += lateRepayFeesYieldFactorDelta;
        } else {
            uint256 unrealizedYieldFactorIncrease = calculateYieldFactorIncrease(
                tick,
                currentLoan.maturity - referenceTimestamp,
                position.rate
            );
            newYieldFactor -= unrealizedYieldFactorIncrease;
        }

        return getAdjustedAmount(tick, position, referenceLoan).mul(newYieldFactor);
    }

    /**
     * @notice Gets the position value at the start of the current loan
     * @dev Only holds when the position is currently borrowed
     * @dev Is used to evaluate current loan earnings for a specific position
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return positionValue Start of loan value of the position
     */
    function getPositionStartOfLoanValue(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) public view returns (uint256 positionValue) {
        if (position.withdrawLoanId > 0) {
            bool withdrawLoanRepaid = (position.withdrawLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (!withdrawLoanRepaid) return position.withdrawn.borrowed;
        }
        if ((position.epochId < tick.loanStartEpochId) || position.withdrawn.borrowed > 0) {
            uint256 precedingLoanId = tick.epochs[tick.loanStartEpochId].precedingLoanId;
            positionValue = getAdjustedAmount(tick, position, referenceLoan).mul(
                tick.endOfLoanYieldFactors[precedingLoanId]
            );
        } else {
            positionValue = position.baseDeposit;
        }
    }

    /**
     * @notice Gets the position value at the end of the current loan
     * @dev Only holds when the position is currently borrowed
     * @dev Is used to evaluate expected end of loan earnings for a specific position
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return positionValue Expected value of the position at the end of the current loan
     */
    function getPositionEndOfLoanValue(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) public view returns (uint256 positionValue) {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];
        if (position.optOutLoanId > 0) {
            bool optOutLoanRepaid = (position.optOutLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (optOutLoanRepaid)
                return
                    getAdjustedAmount(tick, position, referenceLoan).mul(
                        tick.endOfLoanYieldFactors[position.optOutLoanId]
                    );
        }
        if (position.withdrawLoanId > 0) {
            bool withdrawLoanRepaid = (position.withdrawLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (!withdrawLoanRepaid) return position.withdrawn.borrowed + position.withdrawn.expectedAccruals;
        }
        if ((position.epochId <= tick.loanStartEpochId) || position.withdrawn.borrowed > 0) {
            positionValue = getAdjustedAmount(tick, position, referenceLoan).mul(tick.yieldFactor);
        } else {
            uint256 endOfLoanInterest = epoch.accruals.mul(position.baseDeposit).div(epoch.deposited);
            positionValue = position.baseDeposit + endOfLoanInterest;
        }
    }

    /**
     * @notice Gets the repartition of the position between borrowed an unborrowed amount
     * @dev The borrowed amount does not include pending interest for the current loan
     * @dev Holds in all cases, whether the position is borrowed or not
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return unborrowedAmount Amount that is not currently borrowed, and can be withdrawn
     * @return borrowedAmount Amount that is currently borrowed
     */
    function getPositionRepartition(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) public view returns (uint256, uint256) {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];
        uint256 unborrowedAmount;
        uint256 borrowedAmount;
        if (position.optOutLoanId > 0) {
            bool optOutLoanRepaid = (position.optOutLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (optOutLoanRepaid) {
                unborrowedAmount = getAdjustedAmount(tick, position, referenceLoan).mul(
                    tick.endOfLoanYieldFactors[position.optOutLoanId]
                );
                return (unborrowedAmount, 0);
            }
        }
        if (position.withdrawLoanId > 0) {
            bool withdrawLoanRepaid = (position.withdrawLoanId < currentLoan.id) || currentLoan.maturity == 0;
            if (!withdrawLoanRepaid) return (0, position.withdrawn.borrowed);
        }
        if (tick.currentEpochId == 0) {
            return (position.baseDeposit, 0);
        }
        if (currentLoan.maturity == 0) {
            uint256 adjustedAmount = getAdjustedAmount(tick, position, referenceLoan);
            unborrowedAmount = adjustedAmount.mul(tick.yieldFactor);
            return (unborrowedAmount, 0);
        }
        if (position.epochId <= tick.loanStartEpochId) {
            uint256 adjustedAmount = getAdjustedAmount(tick, position, referenceLoan);
            unborrowedAmount = tick.baseEpochsAmounts.available.mul(adjustedAmount).div(
                tick.baseEpochsAmounts.adjustedDeposits
            );
            borrowedAmount = tick.baseEpochsAmounts.borrowed.mul(adjustedAmount).div(
                tick.baseEpochsAmounts.adjustedDeposits
            );
            return (unborrowedAmount, borrowedAmount);
        }

        unborrowedAmount = (epoch.deposited - epoch.borrowed).mul(position.baseDeposit).div(epoch.deposited);
        borrowedAmount = epoch.borrowed.mul(position.baseDeposit).div(epoch.deposited);
        return (unborrowedAmount, borrowedAmount);
    }

    function getPositionLoanShare(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan,
        uint256 totalBorrowedWithSecondary
    ) external view returns (uint256 positionShare) {
        if (currentLoan.maturity == 0 || (tick.baseEpochsAmounts.borrowed == 0 && tick.newEpochsAmounts.borrowed == 0))
            return 0;

        (, uint256 borrowedAmount) = getPositionRepartition(tick, position, referenceLoan, currentLoan);

        // @dev bear in mind that a.mul(b) = a * b / ONE, therefore RAY.mul(1) = RAY / ONE
        return (borrowedAmount * RAY.mul(1)).div(totalBorrowedWithSecondary);
    }

    /*//////////////////////////////////////////////////////////////
                            LENDER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Logic for lenders depositing a position
     * @param tick Target tick
     * @param currentLoan Current loan information
     * @param amount Amount deposited
     */
    function deposit(
        DataTypes.Tick storage tick,
        DataTypes.Loan storage currentLoan,
        uint256 amount
    ) public {
        if ((currentLoan.maturity > 0) && (tick.latestLoanId == currentLoan.id)) {
            tick.newEpochsAmounts.toBeAdjusted += amount;
            tick.newEpochsAmounts.available += amount;
            tick.epochs[tick.currentEpochId].deposited += amount;
        } else {
            tick.baseEpochsAmounts.available += amount;
            tick.baseEpochsAmounts.adjustedDeposits += amount.div(tick.yieldFactor);
        }
    }

    /**
     * @notice Logic for updating the rate of a position
     * @param position Target position
     * @param tick Current tick of the position
     * @param newTick New tick of the position
     * @param currentLoan Current loan information
     * @param referenceLoan Either first loan or detach loan of the position
     * @param newRate New rate
     * @return updatedAmount Amount of funds updated
     */
    function updateRate(
        DataTypes.Position storage position,
        DataTypes.Tick storage tick,
        DataTypes.Tick storage newTick,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan,
        uint256 newRate
    ) public returns (uint256 updatedAmount) {
        updatedAmount = withdraw(tick, position, type(uint256).max, referenceLoan, currentLoan);
        deposit(newTick, currentLoan, updatedAmount);

        position.baseDeposit = updatedAmount;
        position.rate = newRate;
        position.epochId = newTick.currentEpochId;
    }

    /**
     * @notice Logic for withdrawing an unborrowed position
     * @dev Can only be called either when there's no loan ongoing or the target position is not currently borrowed
     * @dev expectedWithdrawnAmount set to type(uint256).max means a full withdraw
     * @param tick Target tick
     * @param position Target position
     * @param expectedWithdrawnAmount Requested withdrawal amount
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return withdrawnAmount Actual withdrawn amount
     */
    function withdraw(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        uint256 expectedWithdrawnAmount,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) public returns (uint256 withdrawnAmount) {
        uint256 positionCurrentValue = getPositionCurrentValue(tick, position, referenceLoan, currentLoan);

        if (expectedWithdrawnAmount == type(uint256).max) {
            withdrawnAmount = positionCurrentValue;
        } else {
            withdrawnAmount = expectedWithdrawnAmount;
        }

        // if the position was optedOut to exit, its value has already been removed from the tick data
        if (position.optOutLoanId > 0) {
            return positionCurrentValue;
        }

        // when the tick is not borrowed, all positions are part of the base epoch
        if (currentLoan.maturity == 0 || (currentLoan.maturity > 0 && tick.latestLoanId < currentLoan.id)) {
            uint256 adjustedAmountToWithdraw = withdrawnAmount.div(tick.yieldFactor);
            // @dev precision issue
            bool precisionIssueDetected = withdrawnAmount > tick.baseEpochsAmounts.available ||
                adjustedAmountToWithdraw > tick.baseEpochsAmounts.adjustedDeposits;

            if (!precisionIssueDetected) {
                tick.baseEpochsAmounts.available -= withdrawnAmount;
                tick.baseEpochsAmounts.adjustedDeposits -= adjustedAmountToWithdraw;
            } else {
                if (
                    withdrawnAmount > tick.baseEpochsAmounts.available + 10 ||
                    adjustedAmountToWithdraw > tick.baseEpochsAmounts.adjustedDeposits + 10
                ) revert RevolvingCreditLineErrors.RCL_NOT_ENOUGH_ADJUSTED_DEPOSITS();
                withdrawnAmount = tick.baseEpochsAmounts.available;
                tick.baseEpochsAmounts.available = 0;
                tick.baseEpochsAmounts.adjustedDeposits = 0;
            }
        }
        // when a loan is ongoing, only the current epoch is not borrowed
        else {
            if (currentLoan.maturity > 0 && tick.currentEpochId != position.epochId)
                revert RevolvingCreditLineErrors.RCL_LOAN_RUNNING();
            tick.newEpochsAmounts.toBeAdjusted -= withdrawnAmount;
            tick.newEpochsAmounts.available -= withdrawnAmount;
            tick.epochs[tick.currentEpochId].deposited -= withdrawnAmount;
        }

        if (expectedWithdrawnAmount != type(uint256).max) {
            position.baseDeposit = positionCurrentValue - expectedWithdrawnAmount;
            position.epochId = tick.currentEpochId;
            position.withdrawLoanId = 0;
            position.withdrawn = DataTypes.WithdrawalAmounts({borrowed: 0, expectedAccruals: 0});
        }
    }

    /**
     * @notice Logic for withdrawing the unborrowed part of a borrowed position
     * @dev Can only be called if the position is partially borrowed
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return unborrowedAmount Position unborrowed amount that was withdrawn
     */
    function detach(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan,
        uint256 minDepositAmount
    ) external returns (uint256 unborrowedAmount) {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];
        uint256 borrowedAmount;
        (unborrowedAmount, borrowedAmount) = getPositionRepartition(tick, position, referenceLoan, currentLoan);
        if (unborrowedAmount == 0) revert RevolvingCreditLineErrors.RCL_POSITION_FULLY_BORROWED();

        uint256 endOfLoanPositionValue = getPositionEndOfLoanValue(tick, position, referenceLoan, currentLoan);

        if (endOfLoanPositionValue - unborrowedAmount < minDepositAmount)
            revert RevolvingCreditLineErrors.RCL_REMAINING_AMOUNT_TOO_LOW();
        if (unborrowedAmount < minDepositAmount) revert RevolvingCreditLineErrors.RCL_AMOUNT_TOO_LOW();

        uint256 accruals = endOfLoanPositionValue - borrowedAmount - unborrowedAmount;

        if (position.epochId <= tick.loanStartEpochId) {
            uint256 adjustedAmount = getAdjustedAmount(tick, position, referenceLoan);
            if (position.optOutLoanId == currentLoan.id) {
                tick.baseEpochsAmounts.adjustedOptedOut -= adjustedAmount;
            } else {
                tick.withdrawnAmounts.borrowed += borrowedAmount;
                tick.withdrawnAmounts.toBeAdjusted += borrowedAmount + accruals;
            }
            tick.baseEpochsAmounts.adjustedDeposits -= adjustedAmount;
            tick.baseEpochsAmounts.available -= unborrowedAmount;
            tick.baseEpochsAmounts.borrowed -= borrowedAmount;
        } else {
            if (position.optOutLoanId == currentLoan.id) {
                epoch.optedOut -= position.baseDeposit;
                tick.newEpochsAmounts.optedOut -= position.baseDeposit;
            } else {
                tick.withdrawnAmounts.borrowed += borrowedAmount;
                tick.withdrawnAmounts.toBeAdjusted += borrowedAmount + accruals;
            }
            tick.newEpochsAmounts.available -= unborrowedAmount;
            tick.newEpochsAmounts.borrowed -= borrowedAmount;
            tick.newEpochsAmounts.toBeAdjusted = tick.newEpochsAmounts.toBeAdjusted - endOfLoanPositionValue;
            epoch.borrowed -= borrowedAmount;
            epoch.deposited -= position.baseDeposit;
            epoch.accruals -= accruals;
        }
        position.withdrawn = DataTypes.WithdrawalAmounts({borrowed: borrowedAmount, expectedAccruals: accruals});
        position.withdrawLoanId = currentLoan.id;
    }

    /**
     * @notice Logic for preparing an exit before reallocating the borrowed amount
     * @dev borrowedAmountToExit set to type(uint256).max means a full exit
     * @dev partial exits are only possible for fully matched positions
     * @dev any partially matched position can be detached to result in being fully matched
     * @param tick Target tick
     * @param position Target position
     * @param borrowedAmountToExit Requested borrowed amount to exit
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @return endOfLoanBorrowedAmountValue Expected end of loan value of the borrowed part of the position
     * @return realizedInterests Interests accrued by the position until the exit
     * @return borrowedAmount Borrowed part of the position
     * @return unborrowedAmount Unborrowed part of the position to be withdrawn
     */
    function registerExit(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        uint256 borrowedAmountToExit,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    )
        external
        returns (
            uint256 endOfLoanBorrowedAmountValue,
            uint256 realizedInterests,
            uint256 borrowedAmount,
            uint256 unborrowedAmount
        )
    {
        (unborrowedAmount, borrowedAmount) = getPositionRepartition(tick, position, referenceLoan, currentLoan);

        // scale down all amounts in case of partial exit
        if (borrowedAmountToExit == type(uint256).max) borrowedAmountToExit = borrowedAmount;
        uint256 exitProportion = borrowedAmountToExit.div(borrowedAmount);
        borrowedAmount = borrowedAmount.mul(exitProportion);

        // get position values
        uint256 currentPositionValue = getPositionCurrentValue(tick, position, referenceLoan, currentLoan).mul(
            exitProportion
        );
        uint256 startOfLoanPositionValue = getPositionStartOfLoanValue(tick, position, referenceLoan, currentLoan).mul(
            exitProportion
        );
        uint256 endOfLoanPositionValue = getPositionEndOfLoanValue(tick, position, referenceLoan, currentLoan).mul(
            exitProportion
        );
        realizedInterests = (currentPositionValue - startOfLoanPositionValue);
        endOfLoanBorrowedAmountValue = (endOfLoanPositionValue - realizedInterests - unborrowedAmount);
        if (position.withdrawn.borrowed > 0) {
            uint256 scaledWithdrawnAmount = position.withdrawn.borrowed.mul(exitProportion);
            tick.withdrawnAmounts.toBeAdjusted -= endOfLoanPositionValue;
            tick.withdrawnAmounts.borrowed -= scaledWithdrawnAmount;
            position.withdrawn.borrowed -= scaledWithdrawnAmount;
            position.withdrawn.expectedAccruals -= position.withdrawn.expectedAccruals.mul(exitProportion);
        }
        // register the exit for base epoch
        else if (position.epochId <= tick.loanStartEpochId) {
            (borrowedAmount, unborrowedAmount) = registerBaseEpochExit(
                tick,
                position,
                referenceLoan,
                borrowedAmount,
                unborrowedAmount,
                exitProportion
            );
        }
        // register the exit for new epochs
        else {
            registerNewEpochExit(
                tick,
                position,
                currentLoan,
                startOfLoanPositionValue,
                currentPositionValue,
                endOfLoanPositionValue,
                borrowedAmount,
                unborrowedAmount
            );
        }
    }

    /**
     * @notice Prepare the exit of a base epoch position
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param borrowedAmount Borrowed amount of the position
     * @param unborrowedAmount Unborrowed amount of the position
     * @param exitProportion Proportion of the position to be withdrawn, used for partial exits
     * @return actualBorrowedAmount Actual borrowed amound, differ from the input in case of imprecision
     * @return actualUnborrowedAmount Actual unborrowed amound, differ from the input in case of imprecision
     */
    function registerBaseEpochExit(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        uint256 borrowedAmount,
        uint256 unborrowedAmount,
        uint256 exitProportion
    ) public returns (uint256 actualBorrowedAmount, uint256 actualUnborrowedAmount) {
        uint256 adjustedAmount = getAdjustedAmount(tick, position, referenceLoan).mul(exitProportion);
        // @dev precision issue
        if (adjustedAmount > tick.baseEpochsAmounts.adjustedDeposits) {
            if (adjustedAmount > tick.baseEpochsAmounts.adjustedDeposits + 10)
                revert RevolvingCreditLineErrors.RCL_NOT_ENOUGH_ADJUSTED_DEPOSITS();

            actualBorrowedAmount = tick.baseEpochsAmounts.borrowed;
            actualUnborrowedAmount = tick.baseEpochsAmounts.available;

            tick.baseEpochsAmounts.adjustedDeposits = 0;
            tick.baseEpochsAmounts.borrowed = 0;
            tick.baseEpochsAmounts.available = 0;
        } else {
            actualBorrowedAmount = borrowedAmount;
            actualUnborrowedAmount = unborrowedAmount;

            tick.baseEpochsAmounts.adjustedDeposits -= adjustedAmount;
            tick.baseEpochsAmounts.borrowed -= borrowedAmount;
            tick.baseEpochsAmounts.available -= unborrowedAmount;
        }

        uint256 precedingLoanId = tick.epochs[tick.loanStartEpochId].precedingLoanId;
        position.baseDeposit -= borrowedAmount
            .mul(getEquivalentYieldFactor(tick, tick.epochs[position.epochId], referenceLoan))
            .div(tick.endOfLoanYieldFactors[precedingLoanId]);
    }

    /**
     * @notice Prepare the exit of a new epoch position
     * @param tick Target tick
     * @param position Target position
     * @param currentLoan Current loan information
     * @param startOfLoanPositionValue Value of the position at the start of the loan
     * @param currentPositionValue Current value of the position
     * @param endOfLoanPositionValue Value of the position at the end of the loan
     * @param borrowedAmount Borrowed amount of the position
     * @param unborrowedAmount Unborrowed amount of the position
     */
    function registerNewEpochExit(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage currentLoan,
        uint256 startOfLoanPositionValue,
        uint256 currentPositionValue,
        uint256 endOfLoanPositionValue,
        uint256 borrowedAmount,
        uint256 unborrowedAmount
    ) public {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];

        // update epoch
        epoch.borrowed -= borrowedAmount;
        epoch.deposited -= startOfLoanPositionValue;
        epoch.accruals -= (endOfLoanPositionValue - startOfLoanPositionValue);

        // update tick
        tick.newEpochsAmounts.borrowed -= borrowedAmount;
        tick.newEpochsAmounts.available -= unborrowedAmount;
        tick.newEpochsAmounts.toBeAdjusted -=
            currentPositionValue +
            accrualsFor(borrowedAmount, currentLoan.maturity - block.timestamp, position.rate);
        position.baseDeposit -= borrowedAmount;
    }

    /**
     * @notice Redistributes the amount to be exited on the order book
     * @dev Logic is similar to a borrow, with the exception that we optimise for end of position value
     * @dev Since the repaid amount must be the same at the end of loan, the borrowed amount can vary depending on the rate of the receiving tick
     * @dev Accruals realized by the exited position are counted as borrowed amount, they will be repaid at the end of the loan
     * @dev Positions that advance realized accruals also claim the accruals that are missed due to that actions, these are basically advances accruals accruals
     * @param tick Target tick
     * @param currentLoan Current loan information
     * @param endOfLoanBorrowedAmountValue Expected end of loan value of the exited borrowed amount
     * @param remainingAccrualsToAllocate Remaining amount of realized accruals left to be allocated to the order book
     * @param rate Rate of the exiting tick
     * @param one One value for the token precision
     * @return tickBorrowed Amount borrowed from the tick
     * @return tickAllocatedAccruals Amount of accruals allocated to the tick
     * @return tickAllocatedAccrualsInterests Expected amount of accruals of the allocated accruals
     * @return tickBorrowedEndOfLoanValue End of loan value of the amount borrowed in the tick
     */
    function exit(
        DataTypes.Tick storage tick,
        DataTypes.Loan storage currentLoan,
        uint256 endOfLoanBorrowedAmountValue,
        uint256 remainingAccrualsToAllocate,
        uint256 rate,
        uint256 one
    )
        external
        returns (
            uint256 tickBorrowed,
            uint256 tickAllocatedAccruals,
            uint256 tickAllocatedAccrualsInterests,
            uint256 tickBorrowedEndOfLoanValue
        )
    {
        uint256 tickToBorrowEquivalent = toTickCurrentValue(
            endOfLoanBorrowedAmountValue,
            currentLoan.maturity,
            rate,
            one
        );

        (tickBorrowed, tickAllocatedAccruals, tickAllocatedAccrualsInterests) = borrow(
            tick,
            currentLoan,
            DataTypes.BorrowInput({
                totalAmountToBorrow: tickToBorrowEquivalent,
                totalAccrualsToAllocate: remainingAccrualsToAllocate,
                rate: rate
            })
        );

        tickBorrowedEndOfLoanValue = toEndOfLoanValue(tickBorrowed, currentLoan.maturity, rate, one);
    }

    /**
     * @notice Mark the position as optedOut and register the optedOut amount in the ticks
     * @param tick Target tick
     * @param position Target position
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     */
    function optOut(
        DataTypes.Tick storage tick,
        DataTypes.Position storage position,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) external {
        DataTypes.Epoch storage epoch = tick.epochs[position.epochId];

        if (position.withdrawLoanId == currentLoan.id) {
            tick.withdrawnAmounts.borrowed -= position.withdrawn.borrowed;
            tick.withdrawnAmounts.toBeAdjusted -= position.withdrawn.borrowed + position.withdrawn.expectedAccruals;
        }
        // if the position is from the base epoch, the adjusted amount to remove at the end of the loan is known in advance
        else if (position.epochId <= tick.loanStartEpochId) {
            tick.baseEpochsAmounts.adjustedOptedOut += getAdjustedAmount(tick, position, referenceLoan);
        }
        // if the position is from a new epoch, the exact earnings to be removed at the end of the loan will be computed later
        else {
            epoch.optedOut += position.baseDeposit;
            tick.newEpochsAmounts.optedOut += position.baseDeposit;
        }
        position.optOutLoanId = currentLoan.id;
    }

    /*//////////////////////////////////////////////////////////////
                            BORROWER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Logic for borrowing against the order book
     * @dev The borrow args are in a struct to prevent a stack too deep error
     * @dev This function is used both when borrowing and exiting, the logic being the exact same
     * @dev When borrowing, the amount of accruals to allocate is set to zero
     * @dev This function is responsible for the deciding how to allocate borrowed amounts between base and new epochs
     * @param tick Target tick
     * @param currentLoan Current loan information
     * @param args Input arguments for the borrow actions
     * @return tickBorrowed Amount borrowed from the target tick
     * @return tickAccrualsAllocated Amount of accruals allocated to the target tick
     * @return tickAccrualsExpectedEarnings Amount of expected accruals accumualted until the end of the loan by the accruals allocated to the tick
     */
    function borrow(
        DataTypes.Tick storage tick,
        DataTypes.Loan storage currentLoan,
        DataTypes.BorrowInput memory args
    )
        public
        returns (
            uint256 tickBorrowed,
            uint256 tickAccrualsAllocated,
            uint256 tickAccrualsExpectedEarnings
        )
    {
        DataTypes.Epoch storage epoch;
        uint256 epochBorrowed = 0;
        uint256 epochAccruals = 0;
        if (tick.baseEpochsAmounts.available + tick.newEpochsAmounts.available > 0) {
            // borrow from base epoch
            // @dev precision issue - available amount and adjusted deposits can be desynchronised with zero value
            if (tick.baseEpochsAmounts.available > 0 && tick.baseEpochsAmounts.adjustedDeposits > 0) {
                uint256 epochId = tick.currentEpochId;
                // if this is the first borrow for that tick, we rectify the epochId
                if (tick.latestLoanId == currentLoan.id) epochId--;
                epoch = tick.epochs[epochId];
                (epochBorrowed, epochAccruals) = borrowFromBase({
                    tick: tick,
                    epoch: epoch,
                    currentLoan: currentLoan,
                    amountToBorrow: args.totalAmountToBorrow,
                    accrualsToAllocate: args.totalAccrualsToAllocate,
                    rate: args.rate
                });
            }
            // else tap into new epoch potential partial fill
            else {
                epoch = tick.epochs[tick.currentEpochId - 1];
                if (!epoch.isBaseEpoch && epoch.deposited > epoch.borrowed && epoch.borrowed > 0) {
                    (epochBorrowed, epochAccruals) = borrowFromNew({
                        tick: tick,
                        epoch: epoch,
                        currentLoan: currentLoan,
                        amountToBorrow: args.totalAmountToBorrow,
                        accrualsToAllocate: args.totalAccrualsToAllocate,
                        rate: args.rate
                    });
                }
            }
            uint256 timeUntilMaturity = currentLoan.maturity - block.timestamp;
            args.totalAmountToBorrow -= epochBorrowed;
            tickBorrowed += epochBorrowed;
            args.totalAccrualsToAllocate -= epochAccruals;
            tickAccrualsAllocated += epochAccruals;
            tickAccrualsExpectedEarnings += accrualsFor(epochAccruals, timeUntilMaturity, args.rate);

            // if amount remaining, tap into untouched new epoch
            if (args.totalAmountToBorrow > 0 && tick.newEpochsAmounts.available > 0) {
                epoch = tick.epochs[tick.currentEpochId];
                (epochBorrowed, epochAccruals) = borrowFromNew({
                    tick: tick,
                    epoch: epoch,
                    currentLoan: currentLoan,
                    amountToBorrow: args.totalAmountToBorrow,
                    accrualsToAllocate: args.totalAccrualsToAllocate,
                    rate: args.rate
                });

                tickBorrowed += epochBorrowed;
                tickAccrualsAllocated += epochAccruals;
                tickAccrualsExpectedEarnings += accrualsFor(epochAccruals, timeUntilMaturity, args.rate);
            }
        }
    }

    /**
     * @notice Borrow against the base epoch of the tick
     * @param tick Target tick
     * @param epoch Target epoch
     * @param currentLoan Current loan information
     * @param amountToBorrow Total amount to borrow left to allocate
     * @param accrualsToAllocate Total accruals left to allocate
     * @param rate Rate of the tick being borrowed
     * @return amountBorrowed Actual borrowed amount in the tick
     * @return accrualsAllocated Actual amount of accruals allocated to the tick
     */
    function borrowFromBase(
        DataTypes.Tick storage tick,
        DataTypes.Epoch storage epoch,
        DataTypes.Loan storage currentLoan,
        uint256 amountToBorrow,
        uint256 accrualsToAllocate,
        uint256 rate
    ) public returns (uint256 amountBorrowed, uint256 accrualsAllocated) {
        if (tick.baseEpochsAmounts.borrowed == 0) {
            epoch.isBaseEpoch = true;
            tick.loanStartEpochId = tick.currentEpochId;
            epoch.precedingLoanId = tick.latestLoanId;
            epoch.loanId = currentLoan.id;
            tick.latestLoanId = currentLoan.id;
            tick.currentEpochId += 1;
        }
        (amountBorrowed, accrualsAllocated) = allocateBorrowAmounts(
            tick.baseEpochsAmounts.available,
            amountToBorrow,
            accrualsToAllocate
        );
        tick.baseEpochsAmounts.borrowed += amountBorrowed + accrualsAllocated;
        tick.baseEpochsAmounts.available -= amountBorrowed + accrualsAllocated;
        tick.yieldFactor += accrualsFor(
            amountBorrowed + accrualsAllocated,
            currentLoan.maturity - block.timestamp,
            rate
        ).div(tick.baseEpochsAmounts.adjustedDeposits);
    }

    /**
     * @notice Borrow against the new epoch of the tick
     * @param tick Target tick
     * @param epoch Target epoch
     * @param currentLoan Current loan information
     * @param amountToBorrow Total amount to borrow left to allocate
     * @param accrualsToAllocate Total accruals left to allocate
     * @param rate Rate of the tick being borrowed
     * @return amountBorrowed Actual borrowed amount in the tick
     * @return accrualsAllocated Actual amount of accruals allocated to the tick
     */
    function borrowFromNew(
        DataTypes.Tick storage tick,
        DataTypes.Epoch storage epoch,
        DataTypes.Loan storage currentLoan,
        uint256 amountToBorrow,
        uint256 accrualsToAllocate,
        uint256 rate
    ) public returns (uint256 amountBorrowed, uint256 accrualsAllocated) {
        if (epoch.borrowed == 0) {
            epoch.loanId = currentLoan.id;
            tick.currentEpochId += 1;
        }
        uint256 epochAvailable = epoch.deposited - epoch.borrowed;
        (amountBorrowed, accrualsAllocated) = allocateBorrowAmounts(epochAvailable, amountToBorrow, accrualsToAllocate);

        uint256 earnings = accrualsFor(
            amountBorrowed + accrualsAllocated,
            currentLoan.maturity - block.timestamp,
            rate
        );
        epoch.borrowed += amountBorrowed + accrualsAllocated;
        epoch.accruals += earnings;

        tick.newEpochsAmounts.borrowed += amountBorrowed + accrualsAllocated;
        tick.newEpochsAmounts.available -= amountBorrowed + accrualsAllocated;
        tick.newEpochsAmounts.toBeAdjusted += earnings;
    }

    /*//////////////////////////////////////////////////////////////
                            FEES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Logic to persist the repayment fees for base epoch
     * @param tick Target tick
     * @param feesController Address of the fees controller
     * @return baseEpochsFees Amount of fees accrued for the tick base epoch
     */
    function registerBaseEpochFees(DataTypes.Tick storage tick, IFeesController feesController)
        public
        returns (uint256 baseEpochsFees)
    {
        if (tick.baseEpochsAmounts.adjustedDeposits == 0) return 0;
        uint256 baseEpochsAccruals = tick.baseEpochsAmounts.adjustedDeposits.mul(tick.yieldFactor) -
            tick.baseEpochsAmounts.available -
            tick.baseEpochsAmounts.borrowed;
        baseEpochsFees = feesController.registerRepaymentFees(baseEpochsAccruals);
        tick.yieldFactor -= baseEpochsFees.div(tick.baseEpochsAmounts.adjustedDeposits);
    }

    /**
     * @notice Logic to persist the repayment fees for new epochs
     * @param tick Target tick
     * @param feesController Address of the fees controller
     * @return newEpochsFees Amount of fees accrued for the tick new epochs
     */
    function registerNewEpochsFees(DataTypes.Tick storage tick, IFeesController feesController)
        public
        returns (uint256 newEpochsFees)
    {
        uint256 newEpochsAccruals = tick.newEpochsAmounts.toBeAdjusted -
            tick.newEpochsAmounts.borrowed -
            tick.newEpochsAmounts.available;
        newEpochsFees = feesController.registerRepaymentFees(newEpochsAccruals);
        tick.newEpochsAmounts.toBeAdjusted -= newEpochsFees;
    }

    /**
     * @notice Logic to persist the repayment fees for base epoch and new epochs
     * @param tick Target tick
     * @param feesController Address of the fees controller
     * @return fees Amount of fees accrued for the tick base epoch and the tick new epochs
     */
    function registerRepaymentFees(DataTypes.Tick storage tick, IFeesController feesController)
        external
        returns (uint256 fees)
    {
        uint256 baseEpochsFees = registerBaseEpochFees(tick, feesController);
        uint256 newEpochsFees = registerNewEpochsFees(tick, feesController);
        fees = baseEpochsFees + newEpochsFees;
    }

    /*//////////////////////////////////////////////////////////////
                              VALIDATION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Validation logic for withdrawal actions
     * @dev Used for both withdraw and update rate actions
     * @param position Target position
     * @param tick Target tick
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @param amountToWithdraw Amount of funds to withdraw from the tick
     * @param minDepositAmount Minimum amount of funds that must be held in a position
     */
    function validateWithdraw(
        DataTypes.Position storage position,
        DataTypes.Tick storage tick,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan,
        uint256 amountToWithdraw,
        uint256 minDepositAmount
    ) external view {
        if (position.creationTimestamp == block.timestamp) revert RevolvingCreditLineErrors.RCL_TIMELOCK();

        (, uint256 borrowedAmount) = getPositionRepartition(tick, position, referenceLoan, currentLoan);
        if (borrowedAmount > 0) revert RevolvingCreditLineErrors.RCL_POSITION_BORROWED();
        uint256 positionCurrentValue = getPositionCurrentValue(tick, position, referenceLoan, currentLoan);
        if (amountToWithdraw != type(uint256).max && amountToWithdraw > positionCurrentValue)
            revert RevolvingCreditLineErrors.RCL_AMOUNT_TOO_HIGH();
        if (amountToWithdraw != type(uint256).max && positionCurrentValue - amountToWithdraw < minDepositAmount)
            revert RevolvingCreditLineErrors.RCL_REMAINING_AMOUNT_TOO_LOW();
        if (amountToWithdraw < minDepositAmount) revert RevolvingCreditLineErrors.RCL_AMOUNT_TOO_LOW();
    }

    /**
     * @notice Validation logic for exit actions
     * @param position Target position
     * @param tick Target tick
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     * @param borrowedAmountToExit Borrowed amount from the position to exit
     * @param minDepositAmount Minimum amount of funds that must be held in a position
     */
    function validateExit(
        DataTypes.Position storage position,
        DataTypes.Tick storage tick,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan,
        uint256 borrowedAmountToExit,
        uint256 minDepositAmount
    ) external view {
        (uint256 unborrowedAmount, uint256 borrowedAmount) = getPositionRepartition(
            tick,
            position,
            referenceLoan,
            currentLoan
        );
        if ((unborrowedAmount > 0) && borrowedAmountToExit != type(uint256).max)
            revert RevolvingCreditLineErrors.RCL_POSITION_NOT_FULLY_BORROWED();
        if (borrowedAmount == 0) revert RevolvingCreditLineErrors.RCL_POSITION_NOT_BORROWED();
        if (position.optOutLoanId > 0) revert RevolvingCreditLineErrors.RCL_HAS_OPTED_OUT();
        if (block.timestamp > currentLoan.maturity) revert RevolvingCreditLineErrors.RCL_CANNOT_EXIT();
        if (borrowedAmountToExit != type(uint256).max && borrowedAmountToExit > borrowedAmount)
            revert RevolvingCreditLineErrors.RCL_AMOUNT_TOO_HIGH();
        if (borrowedAmountToExit != type(uint256).max && borrowedAmount - borrowedAmountToExit < minDepositAmount)
            revert RevolvingCreditLineErrors.RCL_REMAINING_AMOUNT_TOO_LOW();
        if (borrowedAmountToExit < minDepositAmount) revert RevolvingCreditLineErrors.RCL_AMOUNT_TOO_LOW();
    }

    /**
     * @notice Validation logic for position opting out
     * @param position Target position
     * @param tick Target tick
     * @param referenceLoan Either first loan or detach loan of the position
     * @param currentLoan Current loan information
     */
    function validateOptOut(
        DataTypes.Position storage position,
        DataTypes.Tick storage tick,
        DataTypes.Loan storage referenceLoan,
        DataTypes.Loan storage currentLoan
    ) external view {
        (, uint256 borrowedAmount) = getPositionRepartition(tick, position, referenceLoan, currentLoan);

        if (borrowedAmount == 0) revert RevolvingCreditLineErrors.RCL_POSITION_NOT_BORROWED();
        if (block.timestamp > currentLoan.maturity) revert RevolvingCreditLineErrors.RCL_MATURITY_PASSED();
    }

    /*//////////////////////////////////////////////////////////////
                            UTILS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculates the accruals accumulated by an amount during a duration and at a target rate
     * @param amount Amount to calculate accruals for
     * @param timeDelta Duration during which to calculate the accruals
     * @param rate Accrual rate
     */
    function accrualsFor(
        uint256 amount,
        uint256 timeDelta,
        uint256 rate
    ) public view returns (uint256 accruals) {
        accruals = ((amount * timeDelta * rate) / 365 days).mul(1);
    }

    /**
     * @notice Logic for allocating amounts to borrow between amount to borrow and accruals to allocate
     * @param epochAvailable Amount available in the target epoch
     * @param amountToBorrow Total amount to borrow
     * @param accrualsToAllocate Total amount of accruals to allocate
     * @return amountBorrowed Actual amount borrowed for the epoch
     * @return accrualsAllocated Actual amount of accruals to allocate for the epoch
     */
    function allocateBorrowAmounts(
        uint256 epochAvailable,
        uint256 amountToBorrow,
        uint256 accrualsToAllocate
    ) public view returns (uint256 amountBorrowed, uint256 accrualsAllocated) {
        if (amountToBorrow + accrualsToAllocate >= epochAvailable) {
            accrualsAllocated = accrualsToAllocate.mul(epochAvailable).div(amountToBorrow + accrualsToAllocate);
            amountBorrowed = epochAvailable - accrualsAllocated;
        } else {
            amountBorrowed = amountToBorrow;
            accrualsAllocated = accrualsToAllocate;
        }
    }

    /**
     * @notice Util to calculate the equivalent current value of an amount for a tick depending on its end of loan value
     * @param endOfLoanValue Address of the fees controller
     * @param currentMaturity Maturity of the current loan
     * @param rate Rate of the target tick
     * @param one One value for the token precision
     * @return tickCurrentValue Equivalent current value for the target tick
     */
    function toTickCurrentValue(
        uint256 endOfLoanValue,
        uint256 currentMaturity,
        uint256 rate,
        uint256 one
    ) private view returns (uint256 tickCurrentValue) {
        uint256 currentValueToEndOfLoanMultiplier = one + accrualsFor(one, currentMaturity - block.timestamp, rate);
        tickCurrentValue = endOfLoanValue.div(currentValueToEndOfLoanMultiplier);
    }

    /**
     * @notice Util to calculate the end loan value of an amount for a tick depending on its current value
     * @param tickCurrentValue Current value of the amount
     * @param currentMaturity Maturity of the current loan
     * @param rate Rate of the target tick
     * @param one One value for the token precision
     * @return endOfLoanValue Value of the amount at the end of the loan
     */
    function toEndOfLoanValue(
        uint256 tickCurrentValue,
        uint256 currentMaturity,
        uint256 rate,
        uint256 one
    ) private view returns (uint256 endOfLoanValue) {
        uint256 currentValueToEndOfLoanMultiplier = one + accrualsFor(one, currentMaturity - block.timestamp, rate);
        endOfLoanValue = tickCurrentValue.mul(currentValueToEndOfLoanMultiplier);
    }
}