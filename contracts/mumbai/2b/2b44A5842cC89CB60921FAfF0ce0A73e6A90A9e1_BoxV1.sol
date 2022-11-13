// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
 
contract BoxV1 {
    uint256 private value;
    address public admin;
    uint256 private age;
 
    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);
 
    // Stores a new value in the contract
    function store(uint256 newValue) public {
        value = newValue;
        admin = msg.sender;
        emit ValueChanged(newValue);
    }
 
    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return value;
    }

    function calculate(uint256 _val1, uint256 _val2) public pure returns(uint256 _product){
        return _val1 *_val2;
    }
    function subtract(uint256 _val1, uint256 _val2) public pure returns(uint256 _subtract){
        return _val1 - _val2;
    }
      function addition(uint256 _val1, uint256 _val2) public pure returns(uint256 _addition){
        return _val1 + _val2;
    }
    function storeAge(uint256 _age) public {
     age = _age;
    }
}