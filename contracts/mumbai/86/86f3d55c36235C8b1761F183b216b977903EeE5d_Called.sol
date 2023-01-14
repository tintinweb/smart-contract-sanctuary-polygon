pragma solidity ^0.8.9;

//SPDX-License-Identifier: UNLICENSED



contract Called {
    event callEvent(address sender, address origin, address from);

    function callMe() public {
        emit callEvent(msg.sender, tx.origin, address(this)); // print out context
    }
}

contract Caller {

    function makeCalls(address _contractAddress) public {
        
        address(_contractAddress).call(abi.encodeWithSignature("callMe()"));  // one using call
        
        address(_contractAddress).delegatecall( 
            abi.encodeWithSignature("callMe()")
        );
    }

    function makeCall(address _contractAddress) public {
        address(_contractAddress).call(abi.encodeWithSignature("callMe()"));  // one using call
    }

    function makeDelegateCall(address _contractAddress) public {
        address(_contractAddress).delegatecall( 
            abi.encodeWithSignature("callMe()")
        );
    }

}