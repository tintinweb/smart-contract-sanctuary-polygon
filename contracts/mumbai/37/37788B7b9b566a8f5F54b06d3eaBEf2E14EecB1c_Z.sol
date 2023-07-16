// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Z {
    uint256 public a; 
    string public note; 

    function main(uint256 _a) public {
      a = _a; 
    }

    function reset() public {
      a = 0; 
    }

    function speakFriend(string memory _note) public {
      require(bytes(_note).length < 96, ""); 
      note = _note; 
    }

    function send(uint256 gas1, uint256 gas2) external {
        (bool s1, ) = address(this).call{gas: gas1}(abi.encodeWithSignature("main(uint256)", 1));
        require(s1, "Transaction failed");
    
        (bool s2, ) = address(this).call{gas: gas2}(abi.encodeWithSignature("main(uint256)", 100));
        require(s2, "Transaction failed");
    }
}