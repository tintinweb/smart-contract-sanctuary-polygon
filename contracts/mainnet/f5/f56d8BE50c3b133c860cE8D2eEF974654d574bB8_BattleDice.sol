// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// @author AnAllergyToAnalogy
/// @title Big Head Club Doomies BattleDice Contract
/// @notice View and Pure functions that just do the pseudo-random dice roll stuff.
contract BattleDice {

    // Function to calculate and return the stats of a player piece
    //  Called when the piece is created
    //  Takes no args
    //  Returns int8[7] array of stats for the piece
    function rollPlayerStats() public view returns (int8[7] memory stats) {
        uint256 base = uint256(
            keccak256(abi.encodePacked(tx.origin, block.difficulty, block.timestamp))
        );
        int8[5] memory rolls = [int8(1), int8(1), int8(1), int8(1), int8(1)];
        uint256 i = 0;
        while (i < 30) {
            uint256 roll = (base % 5);
            base /= 5;
            if (rolls[roll] < 10) {
                rolls[roll]++;
                ++i;
            }
        }

        uint256 nope0 = base % 7;
        base /= 7;
        uint256 nope1 = base % 7;
        base /= 7;

        if (nope0 == nope1) {
            nope1 = 6 - nope0;
        }
        if (nope0 == nope1) {
            nope1++;
            nope0--;
        }

        uint256 j = 0;
        for (uint256 k = 0; k < 7; k++) {
            if (k != nope0 && k != nope1) {
                stats[k] = rolls[j];
                ++j;
            }
        }
        return stats;
    }

    // Function to calculate and return the stats of a weapon piece
    //  Called when the piece is created
    //  Takes a uint32 as part of the source for the pseudo-randomness
    //  Returns int8[7] array of stats for the piece
    function rollWeaponStats(uint32 salt)
        public
        view
        returns (int8[7] memory stats)
    {
        uint256 base = uint256(
            keccak256(abi.encodePacked(salt, block.difficulty, block.timestamp))
        );

        int8[3] memory increase = [int8(1), int8(1), int8(1)];
        int8[2] memory decrease = [int8(1), int8(1)];

        increase[base % 3]++;
        base /= 3;

        uint256 i;
        uint256 j;
        uint256 k;

        for (i = 0; i < 5; i++) {
            j = base % 3;
            base /= 3;
            k = base % 2;
            base /= 2;

            if (increase[j] < 3 && decrease[k] < 2) {
                increase[j]++;
                decrease[k]++;
            }
        }

        uint256[7] memory order = [
            uint256(0),
            uint256(0),
            uint256(10),
            uint256(20),
            uint256(30),
            uint256(100),
            uint256(200)
        ];

        for (i = 0; i < 21; i++) {
            j = base % 7;
            base /= 7;
            k = base % 7;
            base /= 7;

            uint256 l = order[j];
            order[j] = order[k];
            order[k] = l;
        }

        for (i = 0; i < 7; i++) {
            if (order[i] >= 100) {
                stats[i] = -decrease[order[i] / 100 - 1];
            } else if (order[i] >= 10) {
                stats[i] = increase[order[i] / 10 - 1];
            }
        }

        return stats;
    }

    // Function to calculate outcome of a battle
    //  Called when a battle happens
    //  Takes playerIds and player and weapon stats as args
    //  Returns the id of the winner, and int256[8] arrays of the rolls of bth players
    //      Final element of arrays is result of coin-toss in cases of overall draw
    function battle(
        uint32 player1,
        uint32 player2,
        int8[7] memory stats1,
        int8[7] memory weapon1,
        int8[7] memory stats2,
        int8[7] memory weapon2
    )
        public
        view
        returns (
            uint32 victor,
            int256[8] memory rolls1,
            int256[8] memory rolls2
        )
    {
        uint256 base = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp))
        );

        //        Piece memory piece1  = pieces[player1];
        //        Piece memory weapon1 = pieces[piece1.data];
        //
        //        Piece memory piece2 = pieces[player2];
        //        Piece memory weapon2 = pieces[piece2.data];

        int256 score;
        //        int[8] memory rolls1;
        //        int[8] memory rolls2;

        for (uint256 i = 0; i < 7; i++) {
            int256 stat1 = stats1[i];
            if (stat1 != 0) {
                stat1 += weapon1[i];
                if (stat1 < 1) {
                    stat1 = 1;
                }
                if (stat1 > 10) {
                    stat1 = 10;
                }
            }

            int256 stat2 = stats2[i];
            if (stat2 != 0) {
                stat2 += weapon2[i];
                if (stat2 < 1) {
                    stat2 = 1;
                }
                if (stat2 > 10) {
                    stat2 = 10;
                }
            }

            if (stat1 == 0 && stat2 == 0) {
                continue;
            } else if (stat1 == 0) {
                score++;
            } else if (stat2 == 0) {
                score--;
            } else {
                int256 roll1;
                int256 roll2;

                while (roll1 == roll2) {
                    (base, roll1) = _strike(base, uint256(stat1));
                    (base, roll2) = _strike(base, uint256(stat2));
                }

                if (roll1 > roll2) {
                    score--;
                } else {
                    score++;
                }
                rolls1[i] = roll1;
                rolls2[i] = roll2;
            }
        }
        if (score == 0) {
            if (base % 2 == 0) {
                score--;
                rolls1[7] = 1;
            } else {
                score++;
                rolls2[7] = 1;
            }
        }

        if (score < 0) {
            return (player1, rolls1, rolls2);
        } else {
            return (player2, rolls1, rolls2);
        }
    }

    function _strike(uint256 source, uint256 max)
        internal
        pure
        returns (uint256 newSource, int256 result)
    {
        if (max == 1) {
            return (source - 1, 1);
        } else {
            result = int256((source % max) + 1);
            return (source / max, result);
        }
    }
}