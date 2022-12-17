// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


contract GetterSetter {
    uint public number;

    /**
     * @dev function is setting the new value of number variable
     * @param _setNumber is value we are giving to number variable
     */
    function Setter(uint _setNumber) public {
        number = _setNumber;
    }

    /**
     * @dev function is getting the value of number variable
     */
    function Getter() public view returns(uint){
        return number;
    }

}