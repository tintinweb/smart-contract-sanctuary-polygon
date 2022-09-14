// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ISheetFighterToken.sol";
import "Strings.sol";

/// @notice Contains detailed business logic to determine the value of moves in a battle
/// @notice Contains utility functions related to randomness
library PolygonBattleUtilsV2 {
    event Log(uint8 lower, uint8 upper, uint8 baseValue, uint256 randomness);

    /// @notice Defines possible move type in a battle
    enum MoveType {
        ATTACK,
        DEFENSE,
        CRITICAL,
        HEAL
    }

    /// @notice Defines possible paper stock stat of a battling sheet fighter token
    /// @dev repeat here in order to keep imports simpler
    enum PaperStock {
        GLOSSY,
        MATTE,
        SATIN
    }

    /// @notice Defines possible colors for a Sheet
    /// @dev repeat here in order to keep imports simpler
    enum SheetColor {
        BLUE,
        RED,
        GREEN,
        ORANGE,
        PINK,
        PURPLE
    }

    uint256 public constant PLAYER_REWARD_BLUE = 4e18;      // 4 $SHREDS
    uint256 public constant PLAYER_REWARD_RED = 5e18;       // 5 $SHREDS
    uint256 public constant PLAYER_REWARD_GREEN = 6e18;     // 6 $SHREDS
    uint256 public constant PLAYER_REWARD_ORANGE = 7e18;    // 7 $SHREDS
    uint256 public constant PLAYER_REWARD_PINK = 9e18;      // 9 $SHREDS
    uint256 public constant PLAYER_REWARD_PURPLE = 11e18;   // 11 $SHREDS

    /// @dev Contains a fighter's stats
    /// @dev move stats are uint16 to accomodate boosts that move the value > 255
    struct FighterStatsX {
        uint8 HP;
        uint16 critical;
        uint16 heal;
        uint16 defense;
        uint16 attack;
        SheetColor color;
        PaperStock paperStock;
    }

    /// @dev we store upgradable stats from before each battle in order to provide historically accurate battle logs
    struct UpgradableStats {
        uint8 HP;
        uint16 critical;
        uint16 heal;
        uint16 defense;
        uint16 attack;
    }

    /// @dev makes it easier to sync battle code and battle tests
    struct RandomSeeds {
        uint256 p1Range;
        uint256 p2Range;
        uint256 p1Fail;
        uint256 p2Fail;
        uint256 stun;
    }

    struct RoundSetup {
        MoveType p1Move;
        MoveType p2Move;
        RandomSeeds seeds;
        FighterStatsX p1Stats;
        FighterStatsX p2Stats;
        bool p1Stunned;
        bool p2Stunned;
    }

    struct RoundResult {
        int16 p1MoveValue; // always > 0 but avoiding uint16 to avoid many conversions
        int16 p1HPDiff;
        bool p1Stunned;
        int16 p2MoveValue; // always > 0 but avoiding uint16 to avoid many conversions
        int16 p2HPDiff;
        bool p2Stunned;
    }

    function playRound(RoundSetup memory setup) public pure returns(RoundResult memory) {
        MoveType p1Move = setup.p1Move;
        MoveType p2Move = setup.p2Move;

        // SITUATIONS ABOVE THE MATRIX DIAGONAL
        if (p1Move == MoveType.ATTACK && p2Move == MoveType.ATTACK) {
            return _attackVsAttack(setup);
        } else if (p1Move == MoveType.ATTACK && p2Move == MoveType.DEFENSE) {
            return _attackVsDefense(setup);
        } else if (p1Move == MoveType.DEFENSE && p2Move == MoveType.DEFENSE) {
            return _defenseVsDefense(setup);
        } else if (p1Move == MoveType.ATTACK && p2Move == MoveType.CRITICAL) {
            return _attackVsCritical(setup);
        } else if (p1Move == MoveType.DEFENSE && p2Move == MoveType.CRITICAL) {
            return _defenseVsCritical(setup);
        } else if (p1Move == MoveType.CRITICAL && p2Move == MoveType.CRITICAL) {
            return _criticalVsCritical(setup);
        } else if (p1Move == MoveType.ATTACK && p2Move == MoveType.HEAL) {
            return _attackVsHeal(setup);
        } else if (p1Move == MoveType.DEFENSE && p2Move == MoveType.HEAL) {
            return _defenseVsHeal(setup);
        } else if (p1Move == MoveType.CRITICAL && p2Move == MoveType.HEAL) {
            return _criticalVsHeal(setup);
        } else if (p1Move == MoveType.HEAL && p2Move == MoveType.HEAL) {
            return _healVsHeal(setup);
        } 
        // SITUATIONS BELOW THE MATRIX DIAGONAL (reusing logic, inverting results)
        else if (p1Move == MoveType.DEFENSE && p2Move == MoveType.ATTACK) {
            return _invertedResult(_attackVsDefense(_invertedSetup(setup)));
        } else if (p1Move == MoveType.CRITICAL && p2Move == MoveType.ATTACK) {
            return _invertedResult(_attackVsCritical(_invertedSetup(setup)));
        } else if (p1Move == MoveType.HEAL && p2Move == MoveType.ATTACK) {
            return _invertedResult(_attackVsHeal(_invertedSetup(setup)));
        } else if (p1Move == MoveType.CRITICAL && p2Move == MoveType.DEFENSE) {
            return _invertedResult(_defenseVsCritical(_invertedSetup(setup)));
        } else if (p1Move == MoveType.HEAL && p2Move == MoveType.DEFENSE) {
            return _invertedResult(_defenseVsHeal(_invertedSetup(setup)));
        } else if (p1Move == MoveType.HEAL && p2Move == MoveType.CRITICAL) {
            return _invertedResult(_criticalVsHeal(_invertedSetup(setup)));
        } else {
            revert("unexpected moves combination");
        }
    }

    /// @dev so we can reuse the same function in symmetrical situations
    function _invertedSetup(RoundSetup memory setup) private pure returns (RoundSetup memory) {
        return RoundSetup(
            setup.p2Move,
            setup.p1Move,
            RandomSeeds(
                setup.seeds.p2Range,
                setup.seeds.p1Range,
                setup.seeds.p2Fail,
                setup.seeds.p1Fail, 
                setup.seeds.stun
            ),
            setup.p2Stats,
            setup.p1Stats,
            setup.p2Stunned,
            setup.p1Stunned
        );
    }

    /// @dev so we can reuse the same function in symmetrical situations
    function _invertedResult(RoundResult memory result) private pure returns (RoundResult memory) {
        return RoundResult(
            result.p2MoveValue,
            result.p2HPDiff,
            result.p2Stunned,
            result.p1MoveValue,
            result.p1HPDiff,
            result.p1Stunned
        );
    }

    // --------------------- Move vs Move ------------------- //

    /**
     * @dev Keeping move impact calculations agnostic of who is who
     * @dev Calculations are symmetrical - less code and easier to reuse in PvP mode
     */
    function _attackVsAttack(RoundSetup memory setup)
        public
        pure
        returns (RoundResult memory)
    {
        int16 p1MoveValue;
        int16 p2MoveValue;

        if (setup.p1Stunned) {
            p1MoveValue = 0;
            p2MoveValue = randomInRange(100,100,setup.p2Stats.attack, 0);
        } else if (setup.p2Stunned) {
            p1MoveValue = randomInRange(100,100,setup.p1Stats.attack, 0);
            p2MoveValue = 0;
        } else {
            p1MoveValue = randomInRange(
                25, 50, setup.p1Stats.attack, setup.seeds.p1Range
            );
            p2MoveValue = randomInRange(
                25, 50, setup.p2Stats.attack, setup.seeds.p2Range
            );
        }

        int16 p1HPDiff = -p2MoveValue;
        int16 p2HPDiff = -p1MoveValue;

        return RoundResult(p1MoveValue, p1HPDiff, false, p2MoveValue, p2HPDiff, false);
    }

    function _attackVsDefense(RoundSetup memory setup)
        public
        pure
        returns (RoundResult memory)
    {
        int16 p1MoveValue;
        int16 p2MoveValue;

        if (setup.p1Stunned) {
            p1MoveValue = 0;
            p2MoveValue = randomInRange(100,100,setup.p2Stats.defense,0);
        } else if (setup.p2Stunned) {
            p1MoveValue = randomInRange(100,100,setup.p1Stats.attack, 0);
            p2MoveValue = 0; 
        } else {
            p1MoveValue = randomInRange(
                20, 30, setup.p1Stats.attack, setup.seeds.p1Range
            );
            p2MoveValue = randomInRange(
                80, 100, setup.p2Stats.defense, setup.seeds.p2Range 
            );
        }

        int16 p1HPDiff = 0;
        // attack stronger than defense ? damage : nothing
        int16 p2HPDiff = p1MoveValue > p2MoveValue
            ? p2MoveValue - p1MoveValue
            : int16(0);

        /// @dev if attacker is stunned already, their attack is naturally weaker than the defender's defense
        /// --> in that case we don't have the attacker stunned again
        bool attackerStunned = !setup.p1Stunned && p2MoveValue > p1MoveValue && setup.seeds.stun % 100 > 50;

        return RoundResult(p1MoveValue, p1HPDiff, attackerStunned, p2MoveValue, p2HPDiff, false);
    }

    function _defenseVsDefense(RoundSetup memory setup)
        public
        pure
        returns (RoundResult memory)
    {
        // nothing to do 
        return RoundResult(0,0,false,0,0,false); 
    }

    function _attackVsCritical(RoundSetup memory setup)
        public
        pure
        returns (RoundResult memory)
    {
        int16 p1MoveValue;
        int16 p2MoveValue;

        if (setup.p1Stunned) {
            p1MoveValue = 0;
            // critical has 2/3 chance of having no impact
            p2MoveValue = fallibleCritical(
                setup.seeds.p2Fail,
                randomInRange(
                    100, 100, setup.p2Stats.critical, 0
                )
            );
        } else if (setup.p2Stunned) {
            p1MoveValue = randomInRange(100,100,setup.p1Stats.attack, 0);
            p2MoveValue = 0;
        } else {
            // critical has 2/3 chance of having no impact
            p1MoveValue = randomInRange(
                25, 50, setup.p1Stats.attack, setup.seeds.p1Range
            );
            p2MoveValue = fallibleCritical(
                setup.seeds.p2Fail,
                randomInRange(
                    80, 120, setup.p2Stats.critical, setup.seeds.p2Range
                )
            );
        }

        int16 p1HPDiff = -p2MoveValue;
        int16 p2HPDiff = -p1MoveValue;

        return RoundResult(p1MoveValue, p1HPDiff, false, p2MoveValue, p2HPDiff, false);
    }

    function _defenseVsCritical(RoundSetup memory setup)
        public
        pure
        returns (RoundResult memory)
    {
        int16 p1MoveValue;
        int16 p2MoveValue;

        if (setup.p1Stunned) {
            p1MoveValue = 0;
            // critical has 2/3 chance of having no impact
            p2MoveValue = fallibleCritical(
                setup.seeds.p2Fail,
                randomInRange(
                    100, 100, setup.p2Stats.critical, 0
                )
            );
        } else if (setup.p2Stunned) {
            p1MoveValue = randomInRange(100, 100,setup.p1Stats.defense,0);
            p2MoveValue = 0;
        } else {
            p1MoveValue = randomInRange(
                80, 100, setup.p1Stats.defense, setup.seeds.p1Range
            );
            // critical has 2/3 chance of having no impact
            p2MoveValue = fallibleCritical(
                setup.seeds.p2Fail,
                randomInRange(
                    100, 125, setup.p2Stats.critical, setup.seeds.p2Range
                )
            );
        }

        // critical's impact stronger than defense ? damage : nothing
        int16 p1HPDiff = p2MoveValue > p1MoveValue
            ? p1MoveValue - p2MoveValue
            : int16(0);
        // defense has no impact on critical
        int16 p2HPDiff = 0;

        return RoundResult(p1MoveValue, p1HPDiff, false, p2MoveValue, p2HPDiff, false);
    }

    function _criticalVsCritical(RoundSetup memory setup)
        public
        pure
        returns (RoundResult memory)
    {
        int16 p1MoveValue;
        int16 p2MoveValue;

        if (setup.p1Stunned) {
            p1MoveValue = 0;
            // player2's critical has 2/3 chance of having no impact on player1
            p2MoveValue = fallibleCritical(
                setup.seeds.p2Fail,
                randomInRange(
                    100, 100, setup.p2Stats.critical, 0
                )
            );
        } else if (setup.p2Stunned) {
            // player1's critical has 2/3 chance of having no impact on player2
            p1MoveValue = fallibleCritical(
                setup.seeds.p1Fail,
                randomInRange(
                    100, 100, setup.p1Stats.critical, 0
                )
            );
            p2MoveValue = 0;
        } else {
            // player1's critical has 2/3 chance of having no impact on player2
            p1MoveValue = fallibleCritical(
                setup.seeds.p1Fail,
                randomInRange(
                    50, 120, setup.p1Stats.critical, setup.seeds.p1Range
                )
            );

            // player2's critical has 2/3 chance of having no impact on player1
            p2MoveValue = fallibleCritical(
                setup.seeds.p2Fail,
                randomInRange(
                    50, 120, setup.p2Stats.critical, setup.seeds.p2Range
                )
            );
        }

        int16 p1HPDiff = -p2MoveValue;
        int16 p2HPDiff = -p1MoveValue;

        return RoundResult(p1MoveValue, p1HPDiff, false, p2MoveValue, p2HPDiff, false);
    }

    function _attackVsHeal(RoundSetup memory setup)
        public
        pure
        returns (RoundResult memory)
    {
        int16 p1MoveValue;
        int16 p2MoveValue;

        if (setup.p1Stunned) {
            p1MoveValue = 0;
            p2MoveValue = randomInRange(100,100,setup.p2Stats.heal, 0);
        } else if (setup.p2Stunned) {
            p1MoveValue = randomInRange(100,100,setup.p1Stats.attack, 0);
            p2MoveValue = 0;
        } else {
            p1MoveValue = randomInRange(
                90, 100, setup.p1Stats.attack, setup.seeds.p1Range
            );
            p2MoveValue = randomInRange(
                80, 100, setup.p2Stats.heal, setup.seeds.p2Range
            );
        }

        int16 p1HPDiff = 0; 
        // healing - damage taken
        int16 p2HPDiff = p2MoveValue - p1MoveValue;

        return RoundResult(p1MoveValue, p1HPDiff, false, p2MoveValue, p2HPDiff, false);
    }

    function _defenseVsHeal(RoundSetup memory setup)
        public
        pure
        returns (RoundResult memory)
    {
        int16 p1MoveValue;
        int16 p2MoveValue;

        if (setup.p1Stunned) {
            p1MoveValue = 0;
            p2MoveValue = randomInRange(100,100,setup.p2Stats.heal, 0);
        } else if (setup.p2Stunned) {
            p1MoveValue = 0;
            p2MoveValue = 0;
        } else {
            p1MoveValue = 0;
            p2MoveValue = randomInRange(
                100, 100, setup.p2Stats.heal, 0
            );
        }

        int16 p1HPDiff = 0;
        // healing effect
        int16 p2HPDiff = p2MoveValue; 

        return RoundResult(p1MoveValue, p1HPDiff, false, p2MoveValue, p2HPDiff, false);
    }

    function _criticalVsHeal(RoundSetup memory setup)
        public
        pure
        returns (RoundResult memory)
    {
        int16 p1MoveValue;
        int16 p2MoveValue;

        if (setup.p1Stunned) {
            p1MoveValue = 0;
            p2MoveValue = randomInRange(100,100,setup.p2Stats.heal, 0);
        } else if (setup.p2Stunned) {
            // critical has 2/3 chance of having no impact
            p1MoveValue = fallibleCritical(
                setup.seeds.p1Fail,
                randomInRange(
                    100, 100, setup.p1Stats.critical, 0
                )
            );
            p2MoveValue = 0;
        } else {
            // critical has 2/3 chance of having no impact
            p1MoveValue = fallibleCritical(
                setup.seeds.p1Fail,
                randomInRange(
                    100, 160, setup.p1Stats.critical, setup.seeds.p1Range
                )
            );
            p2MoveValue = randomInRange(
                80, 100, setup.p2Stats.heal, setup.seeds.p2Range
            );
        }

        int16 p1HPDiff = 0;
        // healing - damage taken
        int16 p2HPDiff = p2MoveValue - p1MoveValue;
        return RoundResult(p1MoveValue, p1HPDiff, false, p2MoveValue, p2HPDiff, false);
    }

    function _healVsHeal(RoundSetup memory setup)
        public
        pure
        returns (RoundResult memory)
    {
        int16 p1MoveValue;
        int16 p2MoveValue;

        if (setup.p1Stunned) {
            p1MoveValue = 0;
            p2MoveValue = randomInRange(100,100,setup.p2Stats.heal, 0);
        } else if (setup.p2Stunned) {
            p1MoveValue = randomInRange(100,100,setup.p1Stats.heal, 0);
            p2MoveValue = 0;
        } else {
            p1MoveValue = randomInRange(
                100, 100, setup.p1Stats.heal, 0
            );
            p2MoveValue = randomInRange(
                100, 100, setup.p2Stats.heal, 0
            );
        }

        int16 p1HPDiff = p1MoveValue;
        int16 p2HPDiff = p2MoveValue;
        return RoundResult(p1MoveValue, p1HPDiff, false, p2MoveValue, p2HPDiff, false);
    }

    /// @notice MATTE beats SATIN beats GLOSSY beats MATTE
    /// @return -1 if ps1 weaker, 1 if ps1 stronger, 0 if equal
    function paperStockCompare(PaperStock ps1, PaperStock ps2) public pure returns (int8) {
        if (ps1 == ps2) return 0;
        if (ps1 == PaperStock.MATTE) {
            if (ps2 == PaperStock.SATIN) {
                return 1; // matte beats satin
            } else { // player 2 == GLOSSY
                return -1; // glossy beats matte
            }
        } else if (ps1 == PaperStock.SATIN) { 
            if (ps2 == PaperStock.MATTE) {
                return -1; // matte beats satin
            } else { // player 2 == GLOSSY
                return 1; // satin beats glossy
            }
        } else { // player 1 == GLOSSY
            if (ps2 == PaperStock.MATTE) {
                return 1; // glossy beats matte
            } else { // player 2 == SATIN
                return -1; // satin beats glossy
            }
        }
    }

    /// @notice boost the fight move stats for the fighter with superior paperstock
    /// @dev produces side effects on storage params
    function boostStatsForStrongerPaperStock(
        FighterStatsX storage stats1,
        FighterStatsX storage stats2, 
        uint8 percentage
    ) public 
    {
        int8 comparison = paperStockCompare(stats1.paperStock, stats2.paperStock);
        if (comparison > 0) {
            _boostStats(stats1, percentage);
        } else if (comparison < 0) {
            _boostStats(stats2, percentage);
        }
        // for equal paperstock there is no boost
    }

    /// @dev boost fight move stats
    function _boostStats(FighterStatsX storage stats, uint8 percentage) public {
        stats.attack = _boostedStat(stats.attack, percentage);
        stats.defense = _boostedStat(stats.defense, percentage);
        stats.critical = _boostedStat(stats.critical, percentage);
        stats.heal = _boostedStat(stats.heal, percentage);
    }

    function _boostedStat(uint16 stat, uint8 percentage) public pure returns(uint16) {
        return stat * (100 + uint16(percentage)) / 100;
    }

    function initialHP(uint8 statHP, uint8 multiplier) public pure returns(int16) {
        return int16(uint16(statHP) * uint16(multiplier));
    }

    function asNonNegative(int16 battleHP) public pure returns(int16) {
        return battleHP < 0 ? int16(0) : battleHP;
    }
    
    function int16ToString(int16 num) public pure returns(string memory) {
        // Add negative sign
        string memory result = num < 0 ? "-" : "";

        // Construct result string
        result = string(
            abi.encodePacked(
                result,
                Strings.toString(uint256(uint16(num < 0 ? -num : num)))
            )
        );

        return result;
    }

    // -------------------------------------------------------

    /// @notice Decide if player1 is considered the winner in case of a draw.
    /// @dev The paperStock stat decides the winner.
    /// @dev In case of identical paperStock, decide randomly.
    /// @return true if player1 wins
    function player1WinsInDraw(
        uint256 randomness,
        PaperStock player1Paperstock,
        PaperStock player2Paperstock
    ) public view returns (bool) {

        if (player1Paperstock == player2Paperstock) {
            return randomness % block.timestamp % 2 == 0; // "coin toss"
        }

        return paperStockCompare(player1Paperstock, player2Paperstock) > 0;
    }

    /// @notice Encode sequence of moves (integers) as a string
    /// @dev public so it's available to frontend for convenience
    function encodeMovesAsString(MoveType[12] memory moves) public pure returns (string memory) {
        string memory acc = string(
            abi.encodePacked(
                Strings.toString(uint256(moves[0]))
            )
        );
        for (uint i = 1; i < moves.length; i++) {
            acc = string(
                abi.encodePacked(
                    acc, 
                    ",", 
                    Strings.toString(uint256(moves[i]))
                )
            );
        }
        return acc;
    }

    // ====================== RANDOMNESS ====================== //

    /// @dev Determine a SET of available moves for the player
    /// @dev 12 in total: 2 of each type (2 * 4) + 4 picked randomly
    /// @param randomness Random number generated by Chainlink VRF
    function pickHand(uint256 randomness) public pure returns (MoveType[12] memory) {
        uint256[] memory last4 = expandRandom(randomness, 4);
        return [
            MoveType(0),
            MoveType(0),
            MoveType(1),
            MoveType(1),
            MoveType(2),
            MoveType(2),
            MoveType(3),
            MoveType(3),
            MoveType(last4[0] % 4),
            MoveType(last4[1] % 4),
            MoveType(last4[2] % 4),
            MoveType(last4[3] % 4)
        ]; 
    }

    /// @notice generates 2 seeds for range calculation and 2 for critical fail calculation
    /// @dev Using a struct for these seeds in order to keep move value tests less error-prone
    function roundSeeds(uint256 randomness) public pure 
        returns(RandomSeeds memory)
    {
        uint256[] memory fiveSeeds = expandRandom(randomness, 5);
        return RandomSeeds(
            fiveSeeds[0],
            fiveSeeds[1],
            fiveSeeds[2],
            fiveSeeds[3], 
            fiveSeeds[4]
        );
    } 

    /// @notice Randomly derive a fraction of given baseValue that lies between given bounds
    /// @param lower bound as percentage of @param baseValue
    /// @param upper bound as percentage of @param baseValue
    /// @param randomness seed to use for randomized calculation
    /// @return int16 since result may go above 255 and will be used with other int16 values
    function randomInRange(
        uint8 lower, uint8 upper, uint16 baseValue, uint256 randomness
    ) public pure returns (int16) {
        require(upper >= lower, "invalid range inputs");
        uint8 targetPercentage = upper == lower
            ? lower
            : lower + uint8(randomness % (upper - lower));
        int32 targetResult = int32(uint32(baseValue)) * int32(uint32(targetPercentage)) / 100;
        require(targetResult < 2 ** 15 - 1, "unexpectedly high move value");
        // safe to convert
        return int16(targetResult);
    }

    function fallibleCritical(uint256 randomness, int16 value) public pure returns(int16) {
        bool criticalFail = randomness % 100 >= 33;
        return criticalFail ? int16(0) : value;
    }

    /// @notice Get a winner's reward based on the sheet color
    /// @param color The pertaining sheet color
    /// @return The amount of SHREDS$ that the winner should be rewarded
    function getReward(SheetColor color) public pure returns(uint256) {
        if (color == SheetColor.BLUE) {
            return PLAYER_REWARD_BLUE;
        }
        if (color == SheetColor.RED) {
            return PLAYER_REWARD_RED;
        }
        if (color == SheetColor.GREEN) {
            return PLAYER_REWARD_GREEN;
        }
        if (color == SheetColor.ORANGE) {
            return PLAYER_REWARD_ORANGE;
        }
        if (color == SheetColor.PINK) {
            return PLAYER_REWARD_PINK;
        }
        if (color == SheetColor.PURPLE) {
            return PLAYER_REWARD_PURPLE;
        }
        return 0;
    }

    /// @dev Generate multiple random numbers from a single seed
    /// @param randomValue seed
    /// @param n the number of values to be generated
    function expandRandom(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    /// @dev Get first 8 moves from given sequence
    function pickFirst8Moves(MoveType[12] memory sourceSequence) public pure returns (MoveType[8] memory) {
        MoveType[8] memory pickedSequence;
        for(uint256 i = 0; i < 8; i++) {
            pickedSequence[i] = sourceSequence[i];
        }
        return pickedSequence;
    }

    /// @dev Fisher Yates Shuffle (Knuth Shuffle)
    /// @dev Shuffles "from right to left"
    /// @param availableMoves to be shuffled
    /// @param randomness shuffle seed
    function shuffleHand(MoveType[12] memory availableMoves, uint randomness) public pure returns (MoveType[12] memory) {
        uint8 size = 12;
        uint256[] memory manySeeds = expandRandom(randomness, size - 1); // there will be `size - 1` iterations
        
        // Init
        for (uint8 i = 0; i < size; i++) {
           availableMoves[i] = availableMoves[i];
        }
        
        // last item of the not-yet shuffled part
        uint8 lastPos = size - 1;
        
        // `size - 1` iterations for a complete shuffle
        for (uint8 i = 1; i < size - 1; i++) {
            // item to be swapped with last
            uint8 swappedPos = uint8(manySeeds[i - 1] % lastPos);
            
            // Swap items `swappedPos <> lastPos`.
            MoveType aux = availableMoves[lastPos];
            availableMoves[lastPos] = availableMoves[swappedPos];
            availableMoves[swappedPos] = aux;
            
            // Array of already shuffled items "builds up" at the end
            lastPos--;
        }

        return availableMoves;
    }

    /// @notice same as shuffleHand 
    function shuffleMovesSequence(MoveType[8] memory availableMoves, uint randomness) public pure returns (MoveType[8] memory) {
        uint8 size = 8;
        uint256[] memory manySeeds = expandRandom(randomness, size - 1); // there will be `size - 1` iterations
        
        // Init
        for (uint8 i = 0; i < size; i++) {
           availableMoves[i] = availableMoves[i];
        }
        
        // last item of the not-yet shuffled part
        uint8 lastPos = size - 1;
        
        // `size - 1` iterations for a complete shuffle
        for (uint8 i = 1; i < size - 1; i++) {
            // item to be swapped with last
            uint8 swappedPos = uint8(manySeeds[i - 1] % lastPos);
            
            // Swap items `swappedPos <> lastPos`.
            MoveType aux = availableMoves[lastPos];
            availableMoves[lastPos] = availableMoves[swappedPos];
            availableMoves[swappedPos] = aux;
            
            // Array of already shuffled items "builds up" at the end
            lastPos--;
        }

        return availableMoves;
    }

    /// @notice checks whether given sequence could have been chosen based on given hand
    /// @dev add up moves of each type and compere the group sizes
    function sequenceMatchesHand(
        MoveType[8] memory sequence,
        MoveType[12] memory hand
    ) public pure returns (bool) {
        require(sequence.length == 8 && hand.length == 12, "wrong array length");
        uint[] memory sequenceGroupSizes = getNumberOfMovesInSequence(sequence);
        uint[] memory handGroupSizes = getNumberOfMovesInHand(hand);

        for (uint i = 0; i < 4; i++) {
            if (sequenceGroupSizes[i] > handGroupSizes[i]) {
                return false;
            }
        }
        return true;
    }

    /// @notice create histogram for sequence (distribution of moves)
    function getNumberOfMovesInSequence(MoveType[8] memory sequence) public pure returns (uint[] memory groupSizes) {
        groupSizes = new uint[](4);
        for (uint i = 0; i < sequence.length; i++) {
            groupSizes[uint(sequence[i])]++;
        }
    }

    /// @notice create histogram for a hand (distribution of moves)
    function getNumberOfMovesInHand(MoveType[12] memory sequence) public pure returns (uint[] memory groupSizes) {
        groupSizes = new uint[](4);
        for (uint i = 0; i < sequence.length; i++) {
            groupSizes[uint(sequence[i])]++;
        }
    }

    /// @notice shorthand to encode hp's when constructing the battle log
    /// @dev also helps to avoid stack too deep errors
    function encodeHPForLog(int16 playerBattleHP) public pure returns(string memory) {
        return int16ToString(asNonNegative(playerBattleHP));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721Enumerable.sol";

interface ISheetFighterToken is IERC721Enumerable {

    /// @notice Update the address of the CellToken contract
    /// @param _contractAddress Address of the CellToken contract
    function setCellTokenAddress(address _contractAddress) external;

    /// @notice Update the address which signs the mint transactions
    /// @dev    Used for ensuring GPT-3 values have not been altered
    /// @param  _mintSigner New address for the mintSigner
    function setMintSigner(address _mintSigner) external;

    /// @notice Update the address of the bridge
    /// @dev Used for authorization
    /// @param  _bridge New address for the bridge
    function setBridge(address _bridge) external;

    /// @notice Update the address of the upgrade contract
    /// @dev Used for authorization
    /// @param  _upgradeContract New address for the upgrade contract
    function setUpgradeContract(address _upgradeContract) external;

    /// @dev Withdraw funds as owner
    function withdraw() external;

    /// @notice Set the sale state: options are 0 (closed), 1 (presale), 2 (public sale) -- only owner can call
    /// @dev    Implicitly converts int argument to TokenSaleState type -- only owner can call
    /// @param  saleStateId The id for the sale state: 0 (closed), 1 (presale), 2 (public sale)
    function setSaleState(uint256 saleStateId) external;

    /// @notice Mint up to 20 Sheet Fighters
    /// @param  numTokens Number of Sheet Fighter tokens to mint (1 to 20)
    function mint(uint256 numTokens) external payable;

    /// @notice "Print" a Sheet. Adds GPT-3 flavor text and attributes
    /// @dev    This function requires signature verification
    /// @param  _tokenIds Array of tokenIds to print
    /// @param  _flavorTexts Array of strings with flavor texts concatonated with a pipe character
    /// @param  _signature Signature verifying _flavorTexts are unmodified
    function print(
        uint256[] memory _tokenIds,
        string[] memory _flavorTexts,
        bytes memory _signature
    ) external;

    /// @notice Bridge the Sheets
    /// @dev Transfers Sheets to bridge
    /// @param tokenOwner Address of the tokenOwner who is bridging their tokens
    /// @param tokenIds Array of tokenIds that tokenOwner is bridging
    function bridgeSheets(address tokenOwner, uint256[] calldata tokenIds) external;

    /// @notice Update the sheet to sync with actions that occured on otherside of bridge
    /// @param tokenId Id of the SheetFighter
    /// @param HP New HP value
    /// @param critical New luck value
    /// @param heal New heal value
    /// @param defense New defense value
    /// @param attack New attack value
    function syncBridgedSheet(
        uint256 tokenId,
        uint8 HP,
        uint8 critical,
        uint8 heal,
        uint8 defense,
        uint8 attack
    ) external;

    /// @notice Get Sheet stats
    /// @param _tokenId Id of SheetFighter
    /// @return tuple containing sheet's stats
    function tokenStats(uint256 _tokenId) external view returns(uint8, uint8, uint8, uint8, uint8, uint8, uint8);

    /// @notice Return true if token is printed, false otherwise
    /// @param _tokenId Id of the SheetFighter NFT
    /// @return bool indicating whether or not sheet is printed
    function isPrinted(uint256 _tokenId) external view returns(bool);

    /// @notice Returns the token metadata and SVG artwork
    /// @dev    This generates a data URI, which contains the metadata json, encoded in base64
    /// @param _tokenId The tokenId of the token whos metadata and SVG we want
    function tokenURI(uint256 _tokenId) external view returns (string memory);

    /// @notice Update the sheet to via upgrade contract
    /// @param tokenId Id of the SheetFighter
    /// @param attributeNumber specific attribute to upgrade
    /// @param value new attribute value
    function updateStats(uint256 tokenId,uint8 attributeNumber,uint8 value) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}