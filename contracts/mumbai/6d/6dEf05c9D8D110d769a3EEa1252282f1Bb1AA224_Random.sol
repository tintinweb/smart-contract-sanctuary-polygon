//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
 
contract Random {

    mapping(uint => bool) is_available;

    function findValues(uint256 number) external returns(uint256[] memory) {

        uint[] memory random = new uint[](500) ;
        
        uint i = 1;
        while(i<500){
            uint value = uint(keccak256(abi.encodePacked(number,msg.sender,i))) % 100000 + 1;
            if(! is_available[value]) {
                i+=1;
                is_available[value] = true;
                random[i] = value;
            }
            random[i] = value;
            i++;
        }
        return random;
    }  
}