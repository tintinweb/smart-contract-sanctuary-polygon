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

import './LoanTypes.sol';

/**
 * @title LoanErrors
 * @author Atlendis Labs
 */
library LoanErrors {
    error LOAN_INVALID_RATE_BOUNDARIES(); // "Invalid rate boundaries parameters"
    error LOAN_INVALID_ZERO_RATE_SPACING(); // "Can not have rate spacing to zero"
    error LOAN_INVALID_RATE_PARAMETERS(); // "Invalid rate parameters"
    error LOAN_INVALID_PERCENTAGE_VALUE(); // "Invalid percentage value"

    error LOAN_OUT_OF_BOUND_MIN_RATE(); // "Input rate is below min rate"
    error LOAN_OUT_OF_BOUND_MAX_RATE(); // "Input rate is above max rate"
    error LOAN_INVALID_RATE_SPACING(); // "Input rate is invalid with respect to rate spacing"

    error LOAN_ONLY_GOVERNANCE(); // "Operation restricted to governance only"
    error LOAN_ONLY_LENDER(); // "Operation restricted to lender only"
    error LOAN_ONLY_BORROWER(); // "Operation restricted to borrower only"
    error LOAN_ONLY_OPERATOR(); // "Operation restricted to operator only"

    error LOAN_INVALID_PHASE(); // "Phase is invalid for this operation"
    error LOAN_DEPOSIT_AMOUNT_TOO_LOW(); // "Deposit amount is too low"
    error LOAN_MGMT_ONLY_OWNER(); // "Only the owner of the position token can manage it (update rate, withdraw)";
    error LOAN_TIMELOCK(); // "Cannot withdraw or update rate in the same block as deposit";
    error LOAN_BOOK_BUILDING_TIME_NOT_OVER(); // "Book building time window is not over";
    error LOAN_ALLOWED_ONLY_BOOK_BUILDING_PHASE(); // "Action only allowed during the book building phase";
    error LOAN_REPAY_TOO_EARLY(); // "Loan cannot be early repaid";
    error LOAN_EARLY_PARTIAL_REPAY_NOT_ALLOWED(); // "Partial repays are not allowed before maturity or during not allowed phases";
    error LOAN_NOT_ENOUGH_FUNDS_AVAILABLE(); // "Not enough funds available in pool"
    error LOAN_WITHDRAW_AMOUNT_TOO_LARGE(); // "Cannot withdraw more than the position amount"
    error LOAN_WITHDRAW_AMOUNT_TOO_LOW(); // "Cannot withdraw less than the min deposit amount"
    error LOAN_REMAINING_AMOUNT_TOO_LOW(); // "Remaining amount in position after withdraw is less than the minimum amount"
    error LOAN_WITHDRAWAL_NOT_ALLOWED(); // "Withdrawal not possible"
    error LOAN_ZERO_BORROW_AMOUNT_NOT_ALLOWED(); // "Borrowing from an empty pool is not allowed"
    error LOAN_ORIGINATION_PHASE_EXPIRED(); // "Origination phase has expired"
    error LOAN_ORIGINATION_PERIOD_STILL_ACTIVE(); // "Origination period not expired yet"
    error LOAN_WRONG_INPUT(); // The specified input does not pass validation
    error LOAN_INSTALLMENTS_TOO_LOW(); // "Installment parameter too low"
    error NO_PAYMENTS_DUE(); // "No payment is due"
    error LOAN_POSITIONS_NOT_EXIST(); // "Position does not exits";
    error LOAN_MATURITY_REACHED(); // "Loan maturity has been reached"
    error LOAN_BORROW_AMOUNT_OUT_OF_RANGE(); // "Borrow amount has to be between min and target origination"
    error LOAN_BORROW_AMOUNT_TOO_HIGH(); // "Cannot borrow more than the pool deposits"

    error LOAN_INVALID_FEES_CONTROLLER_MANAGED_POOL(); // "Managed pool of fees controller is not the instance one"
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

import '../../../../libraries/FixedPointMathLib.sol';
import './LoanErrors.sol';
import './LoanTypes.sol';

/**
 * @title LoanLogic
 * @author Atlendis Labs
 */
library LoanLogic {
    using FixedPointMathLib for uint256;

    /**
     * @dev Gets the number of payments that are due and not yet paid
     * @param referenceTimestamp Either non standard procedure start or block timestamp
     * @param borrowTimestamp Borrow timestamp
     * @param loanDuration Duration of the loan
     * @param repaymentPeriodDuration Period of time before maturity when the borrower can repay
     * @param paymentPeriod Period of time during two payments
     * @return paymentsDueCount Total number of payments due
     */
    function getNumberOfPaymentsExpired(
        uint256 referenceTimestamp,
        uint256 borrowTimestamp,
        uint256 loanDuration,
        uint256 repaymentPeriodDuration,
        uint256 paymentPeriod
    ) internal pure returns (uint256 paymentsDueCount) {
        uint256 loanMaturity = borrowTimestamp + loanDuration;
        if (referenceTimestamp > loanMaturity - repaymentPeriodDuration) return loanDuration / paymentPeriod;
        uint256 maturityCappedTimestamp = referenceTimestamp > loanMaturity ? loanMaturity : referenceTimestamp;
        return (maturityCappedTimestamp - borrowTimestamp) / paymentPeriod;
    }

    /**
     * @dev Gets the global rate of a single payment
     * @param rate Rate of the loan
     * @param paymentPeriod Period of time during two payments
     * @param one Precision
     * @return paymentRate Actual rate of a payment
     */
    function getPaymentRate(
        uint256 rate,
        uint256 paymentPeriod,
        uint256 one
    ) internal pure returns (uint256 paymentRate) {
        paymentRate = (rate * one * paymentPeriod) / 365 days / one;
    }

    /**
     * @dev Get the total amount of payment to withdraw for a position
     * @param tick Target tick
     * @param position Target position
     * @param paymentsDoneCount Total number of payments done
     * @return paymentsAmountToWithdraw Total amount of payment to be withdrawn for the target position
     * @return earnings Part of net earnings of the payments amount to be withdrawn
     */
    function getPaymentsAmountToWithdraw(
        LoanTypes.Tick storage tick,
        LoanTypes.Position storage position,
        uint256 paymentsDoneCount
    ) internal view returns (uint256 paymentsAmountToWithdraw, uint256 earnings) {
        uint256 numberOfPaymentsDue = paymentsDoneCount - position.numberOfPaymentsWithdrawn;
        if (numberOfPaymentsDue > 0) {
            paymentsAmountToWithdraw = (numberOfPaymentsDue * position.depositedAmount)
                .mul(tick.singlePaymentAmount)
                .div(tick.depositedAmount);
            earnings = (numberOfPaymentsDue * position.depositedAmount).mul(tick.singlePaymentEarnings).div(
                tick.depositedAmount
            );
        }
    }

    /**
     * @dev Distributes escrowed cancellation fee to tick
     * @param tick Target tick
     * @param cancellationFeePercentage Percentage of the total borrowed amount to be kept in escrow
     * @param remainingEscrow Remaining amount in escrow
     */
    function repayCancelFeeForTick(
        LoanTypes.Tick storage tick,
        uint256 cancellationFeePercentage,
        uint256 remainingEscrow,
        bool redistributeCancelFee
    ) internal returns (uint256 cancelFeeForTick) {
        if (redistributeCancelFee) {
            if (cancellationFeePercentage.mul(tick.depositedAmount) > remainingEscrow) {
                cancelFeeForTick = remainingEscrow;
            } else {
                cancelFeeForTick = cancellationFeePercentage.mul(tick.depositedAmount);
            }
        }
        tick.repaidAmount = tick.depositedAmount + cancelFeeForTick;
    }

    /**
     * @dev Deposit amount to tick
     * @param tick Target tick
     * @param amount Amount to be deposited
     */
    function depositToTick(LoanTypes.Tick storage tick, uint256 amount) internal {
        tick.depositedAmount += amount;
    }

    /**
     * @dev Transfer an amount from one tick to another
     * @param currentTick Tick for which the deposited amount will decrease
     * @param newTick Tick for which the deposited amount will increase
     * @param amount The transferred amount
     */
    function updateTicksDeposit(
        LoanTypes.Tick storage currentTick,
        LoanTypes.Tick storage newTick,
        uint256 amount
    ) internal {
        currentTick.depositedAmount -= amount;
        newTick.depositedAmount += amount;
    }

    /**
     * @dev Register borrowed amount in tick
     * @param tick Target tick
     * @param amountToBorrow The amount to borrow
     * @return borrowComplete True if the deposited amount of the tick is larger than the amount to borrow
     * @return remainingAmount Remaining amount to borrow
     */
    function borrowFromTick(LoanTypes.Tick storage tick, uint256 amountToBorrow)
        internal
        returns (bool borrowComplete, uint256 remainingAmount)
    {
        if (tick.depositedAmount == 0) return (false, amountToBorrow);

        if (tick.depositedAmount < amountToBorrow) {
            amountToBorrow -= tick.depositedAmount;
            tick.borrowedAmount += tick.depositedAmount;
            return (false, amountToBorrow);
        }

        if (tick.depositedAmount >= amountToBorrow) {
            tick.borrowedAmount += amountToBorrow;
            return (true, 0);
        }
    }

    /**
     * @dev Register amounts for a single payment in the target tick
     * @param tick Target tick
     * @param paymentAmount Total amount paid for a single payment
     * @param earningsAmount Earnings part of the payment made
     */
    function registerPaymentsAmounts(
        LoanTypes.Tick storage tick,
        uint256 paymentAmount,
        uint256 earningsAmount
    ) internal {
        tick.singlePaymentAmount = paymentAmount;
        tick.singlePaymentEarnings = earningsAmount;
    }

    /**
     * @dev Derive the allowed amount to be withdrawn
     *      The sequence of conditional branches is relevant for correct logic
     *      Decrease tick deposited amount if the contract is in the Book Building phase
     * @param tick Target tick
     * @param poolPhase The current pool phase
     * @param depositedAmount The original deposited amount in the position
     * @param didPartiallyWithdraw True if the position has already been partially withdrawn
     * @return amountToWithdraw The allowed amount to be withdrawn
     * @return unborrowedAmountWithdrawn True if it is a partial withdraw
     */
    function withdrawFromTick(
        LoanTypes.Tick storage tick,
        LoanTypes.PoolPhase poolPhase,
        uint256 depositedAmount,
        bool didPartiallyWithdraw
    ) external returns (uint256 amountToWithdraw, bool unborrowedAmountWithdrawn) {
        (uint256 unborrowedAmount, , bool partialWithdraw) = getInitialPositionRepartition(
            tick,
            poolPhase,
            depositedAmount,
            didPartiallyWithdraw
        );
        if (poolPhase == LoanTypes.PoolPhase.BOOK_BUILDING) {
            tick.depositedAmount -= unborrowedAmount;
        }

        return (unborrowedAmount, partialWithdraw);
    }

    /**
     * @dev Gets the position repartition before payments addition
     * @param tick Target tick
     * @param poolPhase The current pool phase
     * @param depositedAmount The original deposited amount in the position
     * @param didPartiallyWithdraw True if the position has already been partially withdrawn
     * @return unborrowedAmount Unborrowed part of the position
     * @return borrowedAmount Borrowed part of the position
     * @return partialWithdraw Boolean to signal whether the position has been already partially withdrawn
     */
    function getInitialPositionRepartition(
        LoanTypes.Tick storage tick,
        LoanTypes.PoolPhase poolPhase,
        uint256 depositedAmount,
        bool didPartiallyWithdraw
    )
        public
        view
        returns (
            uint256 unborrowedAmount,
            uint256 borrowedAmount,
            bool partialWithdraw
        )
    {
        /// @dev The order of conditional statements in this function is relevant to the correctness of the logic
        if (poolPhase == LoanTypes.PoolPhase.BOOK_BUILDING) {
            unborrowedAmount = depositedAmount;
            return (unborrowedAmount, borrowedAmount, partialWithdraw);
        }

        // partial withdraw during borrow before repay
        if (
            tick.borrowedAmount > 0 &&
            tick.borrowedAmount < tick.depositedAmount &&
            (poolPhase == LoanTypes.PoolPhase.ISSUED || poolPhase == LoanTypes.PoolPhase.NON_STANDARD)
        ) {
            uint256 unborrowedPart = depositedAmount.mul(tick.depositedAmount - tick.borrowedAmount).div(
                tick.depositedAmount
            );
            unborrowedAmount = didPartiallyWithdraw ? 0 : unborrowedPart;
            borrowedAmount = depositedAmount - unborrowedPart;
            partialWithdraw = true;
            return (unborrowedAmount, borrowedAmount, partialWithdraw);
        }

        // if tick was not matched
        if (tick.borrowedAmount == 0 && poolPhase != LoanTypes.PoolPhase.CANCELLED) {
            unborrowedAmount = depositedAmount;
            return (unborrowedAmount, borrowedAmount, partialWithdraw);
        }

        // If loan has not been paid back and the tick was fully filled
        if (tick.depositedAmount == tick.borrowedAmount && tick.repaidAmount == 0) {
            borrowedAmount = depositedAmount;
            return (unborrowedAmount, borrowedAmount, partialWithdraw);
        }
        // If full fill and repaid or origination was cancelled
        if (
            (tick.depositedAmount == tick.borrowedAmount && poolPhase == LoanTypes.PoolPhase.REPAID) ||
            poolPhase == LoanTypes.PoolPhase.CANCELLED
        ) {
            unborrowedAmount = depositedAmount.mul(tick.repaidAmount).div(tick.depositedAmount);
            return (unborrowedAmount, borrowedAmount, partialWithdraw);
        }

        // If loan has been paid back and the tick was partially filled
        if (tick.depositedAmount > tick.borrowedAmount && poolPhase == LoanTypes.PoolPhase.REPAID) {
            uint256 unborrowedAmountToWithdraw = didPartiallyWithdraw
                ? 0
                : depositedAmount.mul(tick.depositedAmount - tick.borrowedAmount).div(tick.depositedAmount);
            unborrowedAmount =
                depositedAmount.mul(tick.repaidAmount).div(tick.depositedAmount) +
                unborrowedAmountToWithdraw;
            return (unborrowedAmount, borrowedAmount, partialWithdraw);
        }
        return (unborrowedAmount, borrowedAmount, partialWithdraw);
    }

    function getPositionRepartition(
        LoanTypes.Tick storage tick,
        LoanTypes.Position storage position,
        LoanTypes.PoolPhase poolPhase,
        uint256 paymentsDoneCount
    ) external view returns (uint256 unborrowedAmount, uint256 borrowedAmount) {
        (unborrowedAmount, borrowedAmount, ) = getInitialPositionRepartition(
            tick,
            poolPhase,
            position.depositedAmount,
            position.unborrowedAmountWithdrawn
        );

        uint256 paymentOutstanding = paymentsDoneCount - position.numberOfPaymentsWithdrawn;

        unborrowedAmount += paymentOutstanding * tick.singlePaymentAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.13;

/**
 * @title PoolDataTypes library
 * @dev Defines the structs and enums related to the pool
 */
library LoanTypes {
    enum PoolPhase {
        INACTIVE,
        BOOK_BUILDING,
        ORIGINATION,
        ISSUED,
        REPAID,
        NON_STANDARD,
        CANCELLED
    }

    struct Tick {
        uint256 depositedAmount;
        uint256 borrowedAmount;
        uint256 repaidAmount;
        uint256 singlePaymentAmount;
        uint256 singlePaymentEarnings;
    }

    struct Position {
        uint256 depositedAmount;
        uint256 rate;
        uint256 depositBlockNumber;
        bool unborrowedAmountWithdrawn;
        uint256 numberOfPaymentsWithdrawn;
    }
}