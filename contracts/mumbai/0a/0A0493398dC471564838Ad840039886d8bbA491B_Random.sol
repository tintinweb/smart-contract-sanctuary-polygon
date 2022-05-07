//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Random {

    mapping(uint => bool) is_available;
    uint[] randomValues;

    function findValues(uint256 number) external {

        uint[] memory random = new uint[](500) ;
        
        uint i = 0;
        while(i<500){
            uint value = uint(keccak256(abi.encodePacked(number,msg.sender,i))) % 100000 + 1;
            if(! is_available[value]) {
                
                is_available[value] = true;
                random[i] = value;
                i+=1;
            }
            random[i] = value;
            i++;
        }
        randomValues = random;
    }  

    function values() external view returns(uint[] memory) {
        return randomValues;
    }
}

// pragma solidity ^0.8.4;
 
// contract Random {

//     mapping(address => uint256) users;
//     address[] public users_array;

//     function choosingRandom(uint256 seed) external {

//         address[] memory winners = new address[](500);
//         uint32 i ;
//         uint winnerIndex;
        
//         for( i = 0; i < 500 ; i++) {

//             uint256 length = users_array.length + 1;

//             winnerIndex = uint(keccak256(abi.encodePacked(seed,winnerIndex))) % length;

//             winners[i] = users_array[winnerIndex];
//             users_array[winnerIndex] = users_array[length-1];

//         }
//     }

    
// }