//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Random {

    struct userData {
        address user;
        uint256 selected;
        uint256 balance;
    }

    mapping(uint => userData) staker;
    uint[] randomValues;
    uint256 counter;

    function findValues(uint256 number) external {

        uint[] memory random = new uint[](500) ;
        
        uint i = 0;
        uint value;

        userData memory user;
        while(i<500){
            value = uint(keccak256(abi.encodePacked(number,msg.sender,value))) % 100000 + 1;

            user = staker[value];
            if(user.selected != counter && user.balance >= 0 ) {
                
                staker[value].selected = counter;
                random[i] = value;
                i+=1;
            }
        }
        counter++;
        randomValues = random;
    }  

    function values() external view returns(uint[] memory) {
        return randomValues;
    }
}

/*


pragma solidity ^0.8.7;

contract Random {

    mapping(uint => mapping(uint => bool)) is_available;
    uint[] randomValues;
    uint counter;

    function findValues(uint256 number) external {

        uint[] memory random = new uint[](500) ;
        
        uint i = 0;
        uint value;
        while(i<500){
            value = uint(keccak256(abi.encodePacked(number,msg.sender,value))) % 100000 + 1;
            if(! is_available[counter][value]) {
                
                is_available[counter][value] = true;
                random[i] = value;
                i+=1;
            }
            random[i] = value;
            i++;
        }
        counter++;
        randomValues = random;
    }  

    function values() external view returns(uint[] memory) {
        return randomValues;
    }
}


*/