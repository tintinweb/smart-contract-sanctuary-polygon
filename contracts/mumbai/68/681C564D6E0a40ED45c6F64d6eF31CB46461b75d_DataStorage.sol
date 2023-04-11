/**
 *Submitted for verification at polygonscan.com on 2023-04-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract DataStorage {
    string[] temp = [
        "30.71*C",
        "30.77*C",
        "30.75*C",
        "30.79*C",
        "30.83*C",
        "31.27*C",
        "31.29*C",
        "30.87*C",
        "30.89*C",
        "30.90*C"
    ];

    string[] ultrasonic = [
        "2 inches t5 cm", "2 inches t6 cm", "2 inches t7 cm", "2 inches t4 cm", "1 inches t6 cm", "2 inches t5 cm", "2 inches t6 cm"
    ];

    uint[] hall_effect = [
        511, 512, 510,508,490,495,510,520,485,496
    ];

    function getDataFromBlockchain() public view returns(string[] memory){
        return temp;
    }

}