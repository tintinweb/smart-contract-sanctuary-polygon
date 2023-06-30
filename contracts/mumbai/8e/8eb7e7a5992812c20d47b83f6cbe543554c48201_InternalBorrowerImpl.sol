// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

/// The configuration for the Internal Borrower.
/// The IBR is another assymptotic function like the fee calculator.
/// @dev We use lower precision here than in fee calculator to accomodate
/// maxUtils that are over 1 (which avoids div by 0).
/// Plus precision is not as important in this rate.
struct IBRConfig {
    uint120 invAlphaX120; // Always less than 1

    // We assume this value has already had the BETA_OFFSET added to it.
    // Otherwise it can be negative.
    uint72 betaX64; // Give it the extra bits so I don't have to think as hard.

    uint64 maxUtilX56; // Will be every so slightly greater than 1
} // 256 bits

struct InternalBorrower {
    // The total nominal liquidity values. I.E. liq * ticks width.
    // These can only take up to 128 + 24 = 152 bits.
    int256 totalMLiq;
    int256 totalTLiq;

    // How this IBR is configured.
    IBRConfig config; // 256 bits
}

library InternalBorrowerImpl {

    uint120 public constant DEFAULT_INVALPHAX120 = 3242783188242379110212435968;
    uint72 public constant DEFAULT_BETAX64 = 18446744031676564409;
    uint64 public constant DEFAULT_MAXUTILX56 = 72129651631965856;

    /// We use a beta offset so we can do all our operations in uint.
    uint72 private constant BETA_OFFSET = 1 << 64;

    /// The internal rate only changes with liquidity changes
    /// so we update liquidity and return the new rate at the same time.
    /// @return borrowRateX64 The SPR for the TBP. This is ALWAYS much less than 1 since its an SPR.
    function updateLiqs(InternalBorrower storage self, int256 mLiqDelta, int256 tLiqDelta) internal returns (uint64 borrowRateX64) {
        int256 m = self.totalMLiq + mLiqDelta;
        int256 t = self.totalTLiq + tLiqDelta;

        // Recall that t is at most 152 bits so this is a safe shift.
        // We know that t < m so this is a safe cast.
        uint64 utilX56 = uint64(uint256((t << 56) / m));
        // We know our util can't go over 1 due to liquidity constraints.
        // So we set our maxUtil to be slightly greater than 1 to avoid a divide by 0.

        borrowRateX64 = uint64(self.config.betaX64 + self.config.invAlphaX120 / (self.config.maxUtilX56 - utilX56) - BETA_OFFSET);

        self.totalMLiq = m;
        self.totalTLiq = t;
    }

    function getDefaultConfig() public pure returns (IBRConfig memory config) {
        config.invAlphaX120 = DEFAULT_INVALPHAX120;
        config.betaX64 = DEFAULT_BETAX64;
        config.maxUtilX56 = DEFAULT_MAXUTILX56;
    }
}