/**
 *Submitted for verification at polygonscan.com on 2022-12-01
*/

pragma solidity ^0.8.17;

contract Day01 {

    bool ranElfMostCalories = false;
    bool ranTop3ElfMostCalories = false;

    event FoundElfMostCalories(uint64 highest);
    event FoundTop3ElfMostCalories(uint64 top3);

    function findElfMostCalories(uint64[][] memory elfCalories) external returns(uint64) {
        require(!ranElfMostCalories, "Only run once!");
        uint64 highest = 0;
        for (uint16 i = 0; i < elfCalories.length; i++) {
            uint64 calories = 0;
            for (uint16 j = 0; j < elfCalories[i].length; j++) {
                calories += elfCalories[i][j];
            }
            if (calories > highest) highest = calories;
        }
        emit FoundElfMostCalories(highest);
        ranElfMostCalories = true;
        return highest;
    }

    function findTop3ElfMostCalories(uint64[][] memory elfCalories) external returns(uint64) {
        require(!ranTop3ElfMostCalories, "Only run once!");
        uint64[] memory highest = new uint64[](3);
        highest[0] = 0;
        highest[1] = 0;
        highest[2] = 0;
        for (uint16 i = 0; i < elfCalories.length; i++) {
            uint64 calories = 0;
            for (uint16 j = 0; j < elfCalories[i].length; j++) {
                calories += elfCalories[i][j];
            }
            if (calories >= highest[0]) {
                highest[2] = highest[1];
                highest[1] = highest[0];
                highest[0] = calories;
            } else if (calories >= highest[1]) {
                highest[2] = highest[1];
                highest[1] = calories;
            } else if (calories >= highest[2]) {
                highest[2] = calories;
            }
        }
        uint64 top3 = highest[0] + highest[1] + highest[2];
        emit FoundTop3ElfMostCalories(top3);
        ranTop3ElfMostCalories = true;
        return top3;
    }

}