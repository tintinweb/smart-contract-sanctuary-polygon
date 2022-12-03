/**
 *Submitted for verification at polygonscan.com on 2022-12-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract ElfOnAShelf {




    //uint[] public caloriesCarried;

    constructor(){


    }

    function calculateMostCaloriesElf(uint[] memory _caloriesOnElfs) external view returns(uint){


        uint amountOfElves = 1;
        for(uint i=0; i<_caloriesOnElfs.length;i++){

                if(_caloriesOnElfs[i] == 0){
                    amountOfElves++;

                }

        }

        uint[] memory elfCarriers = new uint[](amountOfElves);
        
        uint currentElf = 0;
        uint currentHighestCaloriesCarried = 0;
        for(uint j=0; j< _caloriesOnElfs.length; j++){
            
              
                if(_caloriesOnElfs[j] == 0){
                    
                    if(currentHighestCaloriesCarried <  elfCarriers[currentElf]){
                        currentHighestCaloriesCarried = elfCarriers[currentElf];
                    }
                    currentElf++;
                    continue;

                }
                
                elfCarriers[currentElf] += _caloriesOnElfs[j];


        }


        return currentHighestCaloriesCarried;



    }
}