//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
 
contract Random {

    mapping(uint32 => bool) is_available;
    uint32[] public values;
    uint32 lastIndex;

    uint32[] public shuffled;

    function fillValues() external {
        uint32 _lastIndex =lastIndex + 1000;
        uint32 i;
        for( i = lastIndex; i < _lastIndex  ; i++ ){
            values.push(i);
        }
        lastIndex = i;
    } 

    function shuffle(uint256 number) external {
        uint32 _last = lastIndex;
        uint32[] memory array = values;
        uint32 t;
        uint32 i;
        while(_last != 0) {

            i = uint32(uint(keccak256(abi.encodePacked(number,msg.sender,i))) % _last);
            t = array[_last];
            array[_last] = array[i];
            array[i] = t;
            _last -= 1;
        } 
        shuffled = array;
    }
    function returnValue() public view returns(uint32[] memory){
        return values;
    }
    function shuffledValue() public view returns(uint32[] memory){
        return shuffled;
    }
}