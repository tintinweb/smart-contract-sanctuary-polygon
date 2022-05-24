// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

contract BoxV2 {
    uint256 public val;

    // constructor(uint256 _val){
    //     val = _val;
    // }

    // function initialize(uint256 _val) external {
    //     val = _val;
    // }

    function incre() external{
        val+=1;
    }
}