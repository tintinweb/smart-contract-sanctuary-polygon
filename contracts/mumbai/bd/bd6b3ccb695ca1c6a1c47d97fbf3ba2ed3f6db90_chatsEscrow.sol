/**
 *Submitted for verification at polygonscan.com on 2023-04-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

interface IWmatic {
    function deposit() external payable;
}

contract chatsEscrow {
  address public constant WMATIC_ADDRESS = 0xE4c9693Fa57D54A296ebC116CAc480A39370D1fE ;
    function fundCampaignMatic () public payable virtual returns (bool) {
        uint256 amount = msg.value;
       IWmatic wmaticToken = IWmatic(WMATIC_ADDRESS);
        wmaticToken.deposit{value: amount}();
        return true;
    }

}