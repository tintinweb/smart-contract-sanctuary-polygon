pragma solidity ^0.8.7;
pragma abicoder v2;

contract SkillsInterface {
     uint8 constant NUMBER_OF_SKILLS = 12;
     uint8 constant NUMBER_OF_CLASSES = 7;
     uint8 constant MAX_SKILLS = 6;
     uint8 constant REQUIRED_ENTROPY = 5;
     uint8 constant MAX_POWERS = 6;

     struct SKILL_LIST {
        uint8[MAX_SKILLS] skills;
     }

    mapping(uint8 => uint8[6]) validSkillsList;

    uint8[MAX_SKILLS][NUMBER_OF_CLASSES] public validSkillsForClass = [
        [1, 2, 7, 8, 10, 11],
        [2, 3, 5, 6, 10, 12],
        [3, 4, 5, 6, 9, 12],
        [3, 4, 5, 8, 10, 12],
        [1, 2, 7, 8, 9, 11],
        [3, 4, 5, 9, 10, 12],
        [1, 2, 4, 7, 10, 11]
     ];

     function getValidSkillsForClass(uint8 classId) internal view returns (uint8[MAX_SKILLS] memory skills) {
        skills = validSkillsForClass[classId];
        return skills;
     }

     function deriveRandomnessFromEntropy(uint256 entropy, uint256 seed) internal pure returns (uint256 derivedRandomness) {
        derivedRandomness = uint256(keccak256(abi.encode(entropy, seed)));
        return derivedRandomness;
     }

     struct FilteredSkills {
        uint8 rolledSkills;
        uint8 rolledPowers;
        uint8[MAX_SKILLS] skills;
        uint8[MAX_POWERS] powers;
     }

     function rollSkillsForPlayer(uint256 entropy, uint8 classId, uint8 tier) public view returns (uint8[MAX_SKILLS] memory skillsToRoll) {
        uint8[6] memory rolledSkills = [0, 0, 0, 0, 0, 0];
        uint8 seed = 1;
        uint8 skillIndex = 0;
        rolledSkills[0] = uint8(deriveRandomnessFromEntropy(entropy, seed) % MAX_SKILLS + 1);
        skillIndex++;
        seed++;
         for(uint8 index = 1; index <= tier; index++) {
               seed++;
               bool done = false;
               while(!done) {
                  seed++;
                  uint newDerivedRandomness = deriveRandomnessFromEntropy(entropy, seed * index);

                  uint8 newValue = uint8(newDerivedRandomness % MAX_SKILLS + 1);
                  if(newValue != rolledSkills[0] &&
                     newValue != rolledSkills[1] &&
                     newValue != rolledSkills[2] &&
                     newValue != rolledSkills[3] &&
                     newValue != rolledSkills[4] &&
                     newValue != rolledSkills[5]
                  ) {
                     rolledSkills[index] = newValue;
                     done = true;
                  }
               }
         }

         if(tier >= 5) {
            for(uint8 finalIndex = 1; finalIndex < MAX_SKILLS; finalIndex++) {
               if(rolledSkills[0] != finalIndex && rolledSkills[1] != finalIndex && rolledSkills[2] != finalIndex && rolledSkills[3] != finalIndex && rolledSkills[4] != finalIndex) {
                  rolledSkills[5] = finalIndex;
               }
            }
         }

         uint8[MAX_SKILLS] memory validSkills = validSkillsForClass[classId]; 
         uint8[MAX_SKILLS] memory selectedClassSkills = [0, 0, 0, 0, 0, 0];

         for(uint8 zeroCheckIndex = 0; zeroCheckIndex < rolledSkills.length; zeroCheckIndex++) {
            if(rolledSkills[zeroCheckIndex] != 0) {
               selectedClassSkills[zeroCheckIndex] = validSkills[rolledSkills[zeroCheckIndex]];
            }
         }

         return selectedClassSkills;
     }


     function getSkillNames() public pure returns (string[NUMBER_OF_SKILLS] memory)  {
        string[NUMBER_OF_SKILLS] memory skillNames;
        skillNames[0] = 'Physical';
        skillNames[1] = 'Travel';
        skillNames[2] = 'Energy';
        skillNames[3] = 'Illusion';
        skillNames[4] = 'Life Control';
        skillNames[5] = 'Mental';
        skillNames[6] = 'Defense';
        skillNames[7] = 'Matter';
        skillNames[8] = 'Magic';
        skillNames[9] = 'Sensory';
        skillNames[10] = 'Fighting';
        skillNames[11] = 'Control';
        return skillNames;
    }

    function getClassNames() public pure returns (string[NUMBER_OF_CLASSES] memory)  {
        string[NUMBER_OF_CLASSES] memory classNames;
        classNames[0] = 'Close Combat Specialist';
        classNames[1] = 'Mentalist';
        classNames[2] = 'Spellcaster';
        classNames[3] = 'Elementalist';
        classNames[4] = 'Range Combat Specialist';
        classNames[5] = 'Mage';
        classNames[6] = 'Assassin';
        return classNames;
    }
}