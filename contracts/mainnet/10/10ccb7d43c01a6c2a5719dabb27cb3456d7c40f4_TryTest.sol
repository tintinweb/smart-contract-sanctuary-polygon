/**
 *Submitted for verification at polygonscan.com on 2022-07-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


contract TryTest {
    FeeCalc public feeCalc;
    uint256 public a;

    function sendCrossDomainMessage() public  {
        uint256 submissionFee = 0.01 ether;
        try feeCalc.calculateRetryableSubmissionFee(123, 123) returns (uint256 fee) {
            submissionFee = fee;
        } catch {}

        a = submissionFee;
    }

    function setFeeCalc(FeeCalc _feeCalc) external {
        feeCalc = _feeCalc;
    }
}

contract FeeCalc {
    function calculateRetryableSubmissionFee(uint256 dataLength, uint256 baseFee)
        public
        pure
        returns (uint256)
    {
        return 1;
    }
}