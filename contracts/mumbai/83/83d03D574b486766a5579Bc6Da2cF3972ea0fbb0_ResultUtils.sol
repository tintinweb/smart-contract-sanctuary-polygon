// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

uint8 constant MAX_RESULTS = 47;

library ResultUtils {
    error ResultTooLarge(uint8 result);

    /**
     * Convert a uint8 value that represents a result index
     * to a uint48 value with zero bits in all bits except
     * for result-th bit
     * 
     * @param result Index of the result (0 - MAX_RESULTS)
     */
    function toResultMask(
        uint8 result
    ) public pure returns (uint48 resultMask) {
        if (result > MAX_RESULTS) {
            revert ResultTooLarge(result);
        }

        return uint48(1) << result;
    }

    /**
     * Takes a bitmask representing a set of results
     * and turns it into an array of result indexes
     * 
     * @param mask Bitmask representing a set of results
     */
    function toResults(
        uint48 mask
    ) public pure returns (uint8[] memory members) {
        uint8[] memory results = new uint8[](MAX_RESULTS);
        uint48 currentMask = mask;
        uint8 currentResult = 1;
        uint8 numResults = 0;

        while (currentMask != 0) {
            if (currentMask & 1 != 0) {
                results[numResults] = currentResult;

                unchecked {
                    numResults++;
                }
            }

            unchecked {
                currentMask >>= 1;
                currentResult++;
            }
        }

        members = new uint8[](numResults);
        for (uint8 i = 0; i < numResults; i++) {
            members[i] = results[i];
        }
    }

    /**
     * Checks whether a mask contains a result
     * 
     * @param mask Bitmask
     * @param result Index of a result
     */
    function containsResult(uint48 mask, uint8 result) public pure returns (bool) {
        return mask & toResultMask(result) != 0;
    }

    /**
     * Check whether mask contains another mask
     * 
     * @param mask Mask that needs to contain subset
     * @param subset Mask that needs to be a subset of mask
     */
    function containsResultMask(uint48 mask, uint48 subset) public pure returns (bool) {
        // By definition, when mask is zero this function will return false
        if (subset == 0) return false;

        // To see whether mask contains subset we need to check
        // whether mask has 1s in places where subset has 1s
        //
        // The easiest is to negate the subset to get 1s where 0s were, then & the result with mask
        // 
        // This way, if the subset has 1s where mask had 0s (and now has 1s), we would get a non-0 value
        return subset & ~mask == 0;
    }
}