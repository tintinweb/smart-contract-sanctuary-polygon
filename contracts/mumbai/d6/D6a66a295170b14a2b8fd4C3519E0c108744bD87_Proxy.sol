/**
 *Submitted for verification at polygonscan.com on 2023-05-21
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

contract Proxy {
    
    uint256 ourNumber2;
    address public implementation;
    
    function initialize() public {
        ourNumber2 = 0x28;
    }
    
    function getNumber2() public view returns (uint256) {
        return ourNumber2;
    }
    
    function setImplementation(address implementation_) public {
        implementation = implementation_;
    }
    
    fallback() external {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(
                gas(),
                sload(implementation.slot),
                ptr,
                calldatasize(),
                0,
                0
            )

            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

}