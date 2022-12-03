/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

//SPDX-License-Identifier: MIT License
pragma solidity ^0.8.0;

abstract contract IBattleMtnData {
    function getCurrentConditions()
        external
        view
        virtual
        returns (
            uint8 auraBonus,
            uint8 petTypeBonus,
            uint8 lightAngelBonus,
            uint8 attackerBonus,
            uint8 petLevelBonus,
            bool superBerakiel,
            bool bridge1,
            bool bridge2,
            bool bridge3,
            uint8 bonusLevel,
            uint64 lastConditionChangeTime
        );
}

contract BattleMtnStructure {
    struct Node {
        //connections from any one spot.
        uint8[5] nodeConnections;
    }

    struct Panel {
        uint8[8] members;
    }

    Node[65] ValidPaths; //array featuring all connections.
    Panel[8] Panels;

    mapping(uint8 => uint8) public specialLocation;

    function init() public {
        Panels[0].members = [1, 2, 3, 4, 5, 13, 20, 27];
        Panels[1].members = [6, 11, 12, 14, 15, 21, 22, 28];
        Panels[2].members = [7, 9, 16, 18, 23, 25, 30, 32];
        Panels[3].members = [8, 10, 17, 19, 24, 26, 34, 37];
        Panels[4].members = [29, 31, 33, 35, 38, 40, 42, 45];
        Panels[5].members = [36, 41, 44, 46, 48, 54, 55, 56];
        Panels[6].members = [39, 43, 47, 49, 50, 51, 52, 53];
        Panels[7].members = [57, 58, 59, 60, 61, 62, 63, 64];
    }

    function definePaths() public {
        //So that ranking spot == paths from that ranking spot.
        ValidPaths[0].nodeConnections = [0];
        ValidPaths[1].nodeConnections = [2];
        ValidPaths[2].nodeConnections = [1, 4, 5];
        ValidPaths[3].nodeConnections = [4, 5, 20, 21];
        ValidPaths[4].nodeConnections = [2, 3, 11];
        ValidPaths[5].nodeConnections = [2, 3, 7];
        ValidPaths[6].nodeConnections = [11, 12];
        ValidPaths[7].nodeConnections = [5, 23];
        ValidPaths[8].nodeConnections = [12, 24];
        ValidPaths[9].nodeConnections = [25];
        ValidPaths[10].nodeConnections = [26];
        ValidPaths[11].nodeConnections = [4, 6];
        ValidPaths[12].nodeConnections = [6, 8, 22];
        ValidPaths[13].nodeConnections = [20];
        ValidPaths[14].nodeConnections = [21];
        ValidPaths[15].nodeConnections = [22];
        ValidPaths[16].nodeConnections = [23];
        ValidPaths[17].nodeConnections = [24];
        ValidPaths[18].nodeConnections = [25];
        ValidPaths[19].nodeConnections = [26];
        ValidPaths[20].nodeConnections = [3, 13, 27];
        ValidPaths[21].nodeConnections = [3, 14, 28];
        ValidPaths[22].nodeConnections = [12, 15, 31];
        ValidPaths[23].nodeConnections = [7, 16, 25, 30];
        ValidPaths[24].nodeConnections = [8, 17, 34];
        ValidPaths[25].nodeConnections = [9, 18, 23, 32];
        ValidPaths[26].nodeConnections = [10, 19, 34];
        ValidPaths[27].nodeConnections = [20, 32];
        ValidPaths[28].nodeConnections = [21, 29];
        ValidPaths[29].nodeConnections = [28, 33];
        ValidPaths[30].nodeConnections = [23, 40];
        ValidPaths[31].nodeConnections = [22, 35];
        ValidPaths[32].nodeConnections = [25, 27, 33, 40];
        ValidPaths[33].nodeConnections = [29, 32, 35, 38];
        ValidPaths[34].nodeConnections = [24, 26, 35, 36, 37];
        ValidPaths[35].nodeConnections = [31, 33, 34, 41, 42];
        ValidPaths[36].nodeConnections = [34, 46];
        ValidPaths[37].nodeConnections = [34, 41];
        ValidPaths[38].nodeConnections = [33, 42];
        ValidPaths[39].nodeConnections = [40, 43];
        ValidPaths[40].nodeConnections = [30, 32, 39, 45];
        ValidPaths[41].nodeConnections = [35, 37, 44, 46];
        ValidPaths[42].nodeConnections = [35, 38, 43, 44];
        ValidPaths[43].nodeConnections = [39, 42, 47, 49];
        ValidPaths[44].nodeConnections = [41, 42, 47, 54];
        ValidPaths[45].nodeConnections = [40, 50];
        ValidPaths[46].nodeConnections = [36, 41, 48, 55];
        ValidPaths[47].nodeConnections = [43, 44, 52, 53];
        ValidPaths[48].nodeConnections = [46, 56];
        ValidPaths[49].nodeConnections = [43, 51];
        ValidPaths[50].nodeConnections = [45];
        ValidPaths[51].nodeConnections = [49];
        ValidPaths[52].nodeConnections = [47];
        ValidPaths[53].nodeConnections = [47];
        ValidPaths[54].nodeConnections = [44];
        ValidPaths[55].nodeConnections = [46];
        ValidPaths[56].nodeConnections = [48];
        ValidPaths[57].nodeConnections = [58, 59];
        ValidPaths[58].nodeConnections = [57, 60, 62];
        ValidPaths[59].nodeConnections = [57, 60, 61];
        ValidPaths[60].nodeConnections = [58, 59, 63, 64];
        ValidPaths[61].nodeConnections = [59, 63];
        ValidPaths[62].nodeConnections = [58, 64];
        ValidPaths[63].nodeConnections = [60, 61];
        ValidPaths[64].nodeConnections = [60, 62];
    }

    // Returns whether or not a team can make a certain move.
    function isValidMove(
        uint8 position,
        uint8 to,
        address battleMtnDataContract
    ) public view returns (bool) {
        // Coming off the board to attack a gate.
        if ((position == 99) && ((to >= 50 && to <= 56) || (to >= 63))) {
            return true;
        }

        IBattleMtnData BattleMtnData = IBattleMtnData(battleMtnDataContract);
        bool bridge1;
        bool bridge2;
        bool bridge3;
        (, , , , , , bridge1, bridge2, bridge3, , ) = BattleMtnData
            .getCurrentConditions();

        // Make the lower spot number the from position
        // to help with bridge validation
        uint256 fromPosition = position;
        uint256 toPosition = to;

        if (position > to) {
            fromPosition = to;
            toPosition = position;
        }

        // Bridge 1
        if (fromPosition == 8 && toPosition == 12) {
            return bridge1;
        }
        // Bridge 2
        else if (fromPosition == 4 && toPosition == 11) {
            return bridge2;
        }
        // Bridge 3
        else if (fromPosition == 5 && toPosition == 7) {
            return bridge3;
        }

        // Connecting nodes
        for (
            uint256 i = 0;
            i < ValidPaths[fromPosition].nodeConnections.length;
            i++
        ) {
            if (ValidPaths[fromPosition].nodeConnections[i] == toPosition) {
                return true;
            }
        }

        return false;
    }

    function getSpotFromPanel(uint8 panel, uint8 spot)
        public
        view
        returns (uint8)
    {
        return Panels[panel].members[spot];
    }
}