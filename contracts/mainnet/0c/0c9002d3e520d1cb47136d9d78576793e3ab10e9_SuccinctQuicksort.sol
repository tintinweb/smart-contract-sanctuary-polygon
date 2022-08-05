/**
 *Submitted for verification at polygonscan.com on 2022-08-05
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.15;

interface ISortProgram {
    function sort(uint256[] calldata input) external view returns (uint256[] memory result);
}

// no assembly no magic, pure gas burner
contract SuccinctQuicksort is ISortProgram {
    function _sortHelper(uint256[] memory input, uint start, uint len)
        internal pure returns (uint256[] memory result)
    {
        result = new uint256[](len);

        // trivial cases
        if (len == 0) return result;
        if (len == 1) { result[0] = input[start]; return result; }

        // partitioning, always choose 1st element for pivoting
        uint j;
        uint k;
        uint256 pivotVal = input[start];
        for (uint i = 1; i < len; ++i) {
            uint256 val = input[start + i];
            if (val <= pivotVal) {
                result[j++] = val;
            } else {
                result[len - 1 - k++] = val;
            }
        }

        // combining result
        result[j] = pivotVal;
        uint256[] memory smallerSorted = _sortHelper(result, 0, j);
        uint256[] memory biggerSorted =  _sortHelper(result, j + 1, k);
        for (uint i = 0; i < j; ++i) result[i] = smallerSorted[i];
        for (uint i = 0; i < k; ++i) result[j + 1 + i] = biggerSorted[i];
        return result;
    }

    function sort(uint256[] calldata input) public override pure returns (uint256[] memory result) {
        result = _sortHelper(input, 0, input.length);
    }
}