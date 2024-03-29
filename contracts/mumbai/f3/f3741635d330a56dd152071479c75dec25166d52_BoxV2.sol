// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BoxV2 {
    uint256 private _value;
    uint a;
    uint b;
    uint sum;

    // Emitted when the stored value changes
    event ValueChanged(uint256 value);

    // Stores a new value in the contract
    function store(uint256 value) public {
        _value = value;
        emit ValueChanged(value);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return _value;
    }
    function increment() public {
        _value = _value + 1;
        emit ValueChanged(_value);
    }

    //Add Addition contract method
    function AddSum(uint _a,uint _b)public{
        a=_a;
        b=_b;
        sum = a+b;
    }

    function getRes()public view returns(uint){
        return sum;
    }


}