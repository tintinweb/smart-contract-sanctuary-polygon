/**
 *Submitted for verification at polygonscan.com on 2022-10-06
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract BoxV1 {

    uint256 public boxDispatched;

    function initialize(uint256 _boxDispatched) external {
        boxDispatched = _boxDispatched;
    }

}