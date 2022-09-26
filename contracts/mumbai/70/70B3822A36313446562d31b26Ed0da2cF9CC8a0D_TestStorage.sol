//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract TestStorage{

    event Deposited(address _sender, uint256 _val);
    uint256[] public arrayOfNumbers;
    bytes32[] public arrayOfBytes;

    uint256 public intVariable;

    function updateArrayOfNumbers(uint256[] memory  _nums) public {
        require(_nums.length > 0, "Empty array of numbers");
        for(uint256 i = 0; i < _nums.length; i++) {
            arrayOfNumbers.push(_nums[i]);
        }
    }

     function updateArrayOfBytes(bytes32[] memory  _b) public {
        require(_b.length > 0, "Empty array of numbers");
        for(uint256 i = 0; i < _b.length; i++) {
            arrayOfBytes.push(_b[i]);
        }
    }

    function updateIntVariable(uint256 _num) public {
        intVariable = _num;
    }


    function transferFunds(address _transferTo) external payable returns(bool sent){
        require(msg.value > 0, "zero value");
        require(_transferTo != address(0), "invalid address to tranfer");
        (sent, ) = payable(_transferTo).call{value: msg.value}("");
    }

}