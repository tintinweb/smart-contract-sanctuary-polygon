/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Base{

    uint256 private value;

    function SetValue ( uint256 _value )external {
        value = _value;
    }

    function fetchValue ( ) external view returns ( uint256 ){
        return value;
    }

    function pureValue ( uint256 _a , uint256 _b )external pure returns ( uint256 ){
        return _a ^ _b ;
    }

}

contract Interface{

    event ContractCreated( address _baseContract );

    function fetchValue ( address _contractAddress ) external view returns ( uint256 ){
        Base BContract = Base(_contractAddress); // Read Call
        return BContract.fetchValue();
    }

    function setValue ( address _contractAddress , uint256 _value ) external {
        Base BContract = Base(_contractAddress); // Write Call
        BContract.SetValue(_value);
    }

    function createBase() external {
        Base B = new Base(); // Init new contract 
        emit ContractCreated( address(B));
    }

}