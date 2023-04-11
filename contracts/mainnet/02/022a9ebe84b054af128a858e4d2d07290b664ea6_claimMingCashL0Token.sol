// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./IERC20.sol";
contract claimMingCashL0Token 
{
    function claim()public
    {
        IERC20(0xEB0dEe3dc0834e2F9C9de17b5605868961317d50).transfer(msg.sender,88 * (10 **18));
    }
}