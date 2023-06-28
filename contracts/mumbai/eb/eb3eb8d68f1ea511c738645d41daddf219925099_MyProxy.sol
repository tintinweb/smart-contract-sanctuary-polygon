/**
 *Submitted for verification at polygonscan.com on 2023-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MyProxy {
    address private implementation;

    function upgradeTo(address newImplementation) public {
        require(implementation != newImplementation, "0x36da847dc9b37497270fdf8619a40fc803c16558");
        implementation = newImplementation;
    }

    fallback() external {
        address _impl = implementation;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
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