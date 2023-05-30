// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TestXS {

    mapping(uint256 => uint256[]) public skillPool;
    mapping(uint256 => uint256[]) public skillZonePool;

    constructor() {
        skillZonePool[1] = [11, 12];
        skillZonePool[2] = [7,8,9,10];
        skillZonePool[3] = [1,2,3,4,5,6];

        skillPool[1] = [51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69];
        skillPool[2] = [26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50];
        skillPool[3] = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25];
    }

    function _calculateRandom(address owner, uint256 randomNumber, uint256 module) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(owner, randomNumber))) % module + 1;
    }

    function _randomSkill(address owner, uint256 randomNumber) private view returns(uint256){
        // uint256 number =  randomNumber % 1000 + 1;
        uint256 number = _calculateRandom(owner, randomNumber, 1000);

        uint256 skill;
        if(number <= 700){
            skill = number % skillPool[3].length;
            return skillPool[3][skill];
        }else if(number > 700 && number <= 955){
            skill = number % skillPool[2].length;
            return skillPool[2][skill];
        }else{
            skill = number % skillPool[1].length;
            return skillPool[1][skill];
        }
    }

    function _randomSkillZone(address owner, uint256 randomNumber) private view returns(uint256){
        // uint256 number =  randomNumber % 1000 + 1;
        uint256 number = _calculateRandom(owner, randomNumber, 1000);

        uint256 skillZone;

        if(number <= 600){
            skillZone = number % skillZonePool[3].length;
            return skillZonePool[3][skillZone];
        }else if(number > 600 && number <= 980){
            skillZone = number % skillZonePool[2].length;
            return skillZonePool[2][skillZone];
        }else{
            skillZone = number % skillZonePool[1].length;
            return skillZonePool[1][skillZone];
        }
    }

    function _randomSupport(address owner, uint256 randomNumber) private pure returns(uint256) {
        // uint256 number =  randomNumber % 1000 + 1;
        uint256 number = _calculateRandom(owner, randomNumber, 1000);


        if(number <= 200){
            return 1;
        } else if(number > 200 && number <= 380){
            return 2;
        } else if(number > 380 && number <= 540){
            return 3;
        } else if(number > 540 && number <= 680){
            return 4;
        } else if(number > 680 && number <= 800){
            return 5;
        } else if(number > 800 && number <= 880){
            return 6;
        } else if(number > 880 && number <= 940){
            return 7;
        } else if(number > 940 && number <= 970){
            return 8;
        } else if(number > 970 && number <= 990){
            return 9;
        } else {
            return 10;
        }
    }

    function _randomSabotage(address owner, uint256 randomNumber) private pure returns(uint256){
        // uint256 number =  randomNumber % 1000 + 1;
        uint256 number = _calculateRandom(owner, randomNumber, 1000);


        if(number <= 200){
            return 1;
        } else if(number > 200 && number <= 380){
            return 2;
        } else if(number > 380 && number <= 540){
            return 3;
        } else if(number > 540 && number <= 680){
            return 4;
        } else if(number > 680 && number <= 800){
            return 5;
        } else if(number > 800 && number <= 880){
            return 6;
        } else if(number > 880 && number <= 940){
            return 7;
        } else if(number > 940 && number <= 970){
            return 8;
        } else if(number > 970 && number <= 990){
            return 9;
        } else {
            return 10;
        }
    }

    function setSkillPool(uint256 _id, uint256[] memory _skills) external {
        skillPool[_id] = _skills;
    }

    function setSkillZonePool(uint256 _id, uint256[] memory _skillZone) external {
        skillZonePool[_id] = _skillZone;
    }

    function getRandomID(address _owner, uint256 randomNumber) public view returns(uint256){
        // uint256 number = randomNumber % 10000 + 1;
        randomNumber += 532323;
        randomNumber += 532323;
        randomNumber += 532323;

        uint256 number = _calculateRandom(_owner, randomNumber, 10000);
    
        uint256 plantID;

        if(number <= 9600){
            uint256 plantType = number % 9 + 1;
            plantID = 100000000000 + plantType * 10**10;
            uint256 plantNumber;

            if(number <= 5500){ //common
                plantNumber = number % 2 + 1;
                plantID += plantNumber * 10**8;
            } else if (number > 5500 && number <= 8500){
                plantNumber = 3;
                plantID += plantNumber * 10**8;
            } else if (number > 8500 && number <= 9400){
                plantNumber = 4;
                plantID += plantNumber * 10**8;
            } else{
                plantNumber = 5;
                plantID += plantNumber * 10**8;
            }

            plantID +=  _randomSkill(_owner, randomNumber) * 10**6 + _randomSkillZone(_owner, randomNumber) * 10**4 + _randomSupport(_owner, randomNumber) * 10**2 + _randomSabotage(_owner, randomNumber);
            return plantID;

        } else {
            plantID = 2000000000;
            uint256 plantType = number % 9 + 1;
            plantID += plantType * 10**8 + plantType * 10**6;
            if(number <= 9850){
                plantID += 1 * 10 ** 4 +1 * 10**2 + 1;
            }else if(number > 9850 && number <= 9850){
                plantID += 2 * 10 ** 4 +1 * 10**2 + 2;
            }else if(number > 9850 && number <= 9890){
                plantID += 3 * 10 ** 4 +1 * 10**2 + 3;
            }else{
                plantID += 4 * 10 ** 4 +1 * 10**2 + 4;
            }
            return plantID;
        }

    }
    
}