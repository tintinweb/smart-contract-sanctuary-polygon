/**
 *Submitted for verification at polygonscan.com on 2022-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Enum {
    enum CCService {
        AnyCall,
        LayerZero
    }

    CCService public ccService;

    function testCCService(CCService _ccService) external returns (CCService) {
        ccService = _ccService;
        return ccService;
    }


}