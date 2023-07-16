// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Z {
    uint256 public a; 

    function main(uint256 _a) public {
      a = _a; 
    }

    function reset() public {
      a = 0; 
    }

    function send() external {
        (bool s1, ) = address(this).call{gas: 50000000000 /*50 gwei*/ }(abi.encodeWithSignature("main(uint256)", 1));
        require(s1, "Transaction failed");
    
        (bool s2, ) = address(this).call{gas: 500000000000 /*500 gwei*/ }(abi.encodeWithSignature("main(uint256)", 100));
        require(s2, "Transaction failed");
    }
}