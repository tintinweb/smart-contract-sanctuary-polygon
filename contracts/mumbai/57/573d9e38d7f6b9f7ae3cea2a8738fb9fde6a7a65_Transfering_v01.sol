/**
 *Submitted for verification at polygonscan.com on 2022-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Transfering_v01 {
    
    address dc;
    
    function multitransfer(address payable _addr, address[] memory addresses, uint256  amountTo) public {
         for (uint i = 0; i < addresses.length; i++) {
            address toAddress = addresses[i];
            _testCallFoo(_addr,toAddress,amountTo);
        }
    }


     function _testCallFoo(address payable _addr, address toaddress, uint256  amountTo) private  {
        // You can send ether and specify a custom gas amount
        (bool success, bytes memory data) = _addr.call{value: msg.value}(
            abi.encodeWithSignature("transfer(address,uint256)", toaddress, amountTo)
        );

       
    }
}