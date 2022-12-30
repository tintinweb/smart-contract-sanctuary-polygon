// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./lib/AdminRole.sol";
import "./PepemonCardDeck.sol";
import "./PepemonCardOracle.sol";
import "./lib/ChainLinkRngOracle.sol";

contract PepemonBattle is AdminRole {
    
    event BattleCreated(address indexed player1Addr, address indexed player2Addr, uint256 battleId);

    mapping (uint => uint) public battleIdRNGSeed;

    uint constant _max_inte = 8;
    uint constant _max_cards_on_table = 5;
    uint constant _refreshTurn = 5;

    //Attacker can either be PLAYER_ONE or PLAYER_TWO
    enum Attacker {
        PLAYER_ONE,
        PLAYER_TWO
    }

    //Game can either be in FIRST_HALF or SECOND_HALF
    enum TurnHalves {
        FIRST_HALF,
        SECOND_HALF
    }

    //Battle contains:
    //battleId = ID of this battle
    //player1, player2 = players
    //currentTurn
    //attacker
    //turnHalves => first half or second half?
    struct Battle {
        uint256 battleId;
        Player player1;
        Player player2;
        uint256 currentTurn;
        Attacker attacker;
        TurnHalves turnHalves;
    }

    //playerAddr
    //deckId = Id of deck
    //hand = keeps track of current player's stats (such as health)
    //totalSupportCardIds = all IDs of support cards
    //playedCardCount = number of cards played already
    struct Player {
        address playerAddr;
        uint256 deckId;
        Hand hand;
        uint256[60] totalSupportCardIds;
        uint256 playedCardCount;
    }

    //health - health of player's battle card
    // battleCardId = card id of player
    // currentBCstats = all stats of the player's battle cards currently
    // supportCardInHandIds = IDs of the support cards in your current hand
    //                  the amount of support cards a player can play is determined by intelligence
    // tableSupportCardStats = Number of support cards that are currently played on the table
    // currentSuportCards = cards on the table, based on which turn ago they were played
    //                      Notice that the number of turns is limited by _refreshTurn
    struct Hand {
        int256 health;
        uint256 battleCardId;
        CurrentBattleCardStats currentBCstats;
        uint256[_max_inte] supportCardInHandIds;
        uint256 tableSupportCardStats;
        TableSupportCardStats[_max_cards_on_table] tableSupportCards;
    }
    //spd, inte, def, atk, sAtk, sDef - Current stats of battle card (with powerups included)
    //Each param can go into the negatives
    struct CurrentBattleCardStats {
        int256 spd;
        uint256 inte;
        int256 def;
        int256 atk;
        int256 sAtk;
        int256 sDef;
    }

    //links supportCardID with effectMany
    struct TableSupportCardStats {
        uint256 supportCardId;
        PepemonCardOracle.EffectMany effectMany;
    }

    mapping(uint256 => Battle) public battles;

    uint256 private _nextBattleId;


    PepemonCardOracle private _cardContract;
    PepemonCardDeck private _deckContract;
    ChainLinkRngOracle private _randNrGenContract;

    constructor(
        address cardOracleAddress,
        address deckOracleAddress,
        address randOracleAddress
    ) {
        _cardContract = PepemonCardOracle(cardOracleAddress);
        _deckContract = PepemonCardDeck(deckOracleAddress);
        _randNrGenContract = ChainLinkRngOracle(randOracleAddress);
        _nextBattleId = 1;
    }

    /**
     * @dev Create battle
     * @param p1Addr address player1
     * @param p1DeckId uint256
     * @param p2Addr address player2
     * @param p2DeckId uint256
     */
    function createBattle(
        address p1Addr,
        uint256 p1DeckId,
        address p2Addr,
        uint256 p2DeckId
    ) public onlyAdmin returns (Battle memory, uint256 battleId)  {
        require(p1Addr != p2Addr, "PepemonBattle: Cannot battle yourself");

        (uint256 p1BattleCardId, ) = _deckContract.decks(p1DeckId);
        (uint256 p2BattleCardId, ) = _deckContract.decks(p2DeckId);

        PepemonCardOracle.BattleCardStats memory p1BattleCard = _cardContract.getBattleCardById(p1BattleCardId);
        PepemonCardOracle.BattleCardStats memory p2BattleCard = _cardContract.getBattleCardById(p2BattleCardId);

        Battle memory newBattle;
        // Initiate battle ID
        newBattle.battleId = _nextBattleId;
        // Initiate player1
        newBattle.player1.hand.health = int256(p1BattleCard.hp);
        newBattle.player1.hand.battleCardId = p1BattleCardId;
        newBattle.player1.playerAddr = p1Addr;
        newBattle.player1.deckId = p1DeckId;
        // Initiate player2
        newBattle.player2.hand.health = int256(p2BattleCard.hp);
        newBattle.player2.hand.battleCardId = p2BattleCardId;
        newBattle.player2.playerAddr = p2Addr;
        newBattle.player2.deckId = p2DeckId;
        // Set the RNG seed
        battleIdRNGSeed[_nextBattleId] = _randSeed(newBattle);

        //Emit event
        emit BattleCreated(p1Addr, p2Addr, _nextBattleId);
        return (newBattle, _nextBattleId++);
    }

    function goForBattle(Battle memory battle) public view returns (Battle memory, address winner) {

        //Initialize battle by starting the first turn
        battle = goForNewTurn(battle);
        address winnerAddr;
        // Battle goes!
        while (true) {
            // Resolve attacker in the current turn
            battle = resolveAttacker(battle);
            // Fight
            battle = fight(battle);

            // Check if battle ended
            (bool isEnded, address win) = checkIfBattleEnded(battle);
            if (isEnded) {
                winnerAddr = win;
                break;
            }

            // Resolve turn halves
            battle = updateTurnInfo(battle);
        }
        return (battle, winnerAddr);
    }

    //If currently in first half -> go to second half
    //If currently in second half -> make a new turn
    function updateTurnInfo(Battle memory battle) internal view returns (Battle memory) {
        // If the current half is first, go over second half
        // or go over next turn
        if (battle.turnHalves == TurnHalves.FIRST_HALF) {
            battle.turnHalves = TurnHalves.SECOND_HALF;
        } else {
            battle = goForNewTurn(battle);
        }

        return battle;
    }

    //Things this function does:
    //Reset both players hand infos back to base stats (stats with no support card powerups)
    //Check if support cards need to be scrambled and redealt
    //Redeal support cards if necessary
    //Calculate support card's power
    //Finally, draw Pepemon's intelligence number of cards.
    function goForNewTurn(Battle memory battle) internal view returns (Battle memory) {
        Player memory player1 = battle.player1;
        Player memory player2 = battle.player2;

        // Get base battle card stats (stats without any powerups)
        PepemonCardOracle.BattleCardStats memory p1BattleCard = _cardContract.getBattleCardById(
            player1.hand.battleCardId
        );
        PepemonCardOracle.BattleCardStats memory p2BattleCard = _cardContract.getBattleCardById(
            player2.hand.battleCardId
        );

        //Reset both players' hand infos to base stats
        player1.hand.currentBCstats = getCardStats(p1BattleCard);
        player2.hand.currentBCstats = getCardStats(p2BattleCard);

        uint256 p1SupportCardIdsLength = _deckContract.getSupportCardCountInDeck(player1.deckId);
        uint256 p2SupportCardIdsLength = _deckContract.getSupportCardCountInDeck(player2.deckId);

        //Refresh cards every 5 turns
        bool isRefreshTurn = (battle.currentTurn % _refreshTurn == 0);

        if (isRefreshTurn) {
            //Need to refresh decks

            // Shuffle player1 support cards
            //Create a pseudorandom seed and shuffle the cards 
            uint[] memory scrambled = _deckContract.shuffleDeck(player1.deckId, // tbd: use in-place shuffling
                _randMod(
                    69, battle
                )
            );
            //Copy back scrambled cards to original list
            for (uint i = 0 ; i < p1SupportCardIdsLength; i++){
                player1.totalSupportCardIds[i]=scrambled[i];
            }
            
            //Reset played card count
            player1.playedCardCount = 0;

            //Shuffling player 2 support cards
            //Create a pseudorandom seed and shuffle the cards
            uint[] memory scrambled2 = _deckContract.shuffleDeck(player2.deckId, 
                _randMod(
                    420, battle
                )
            );

            //Copy the support cards back into the list
            for (uint256 i = 0; i < p2SupportCardIdsLength; i++) {
                player2.totalSupportCardIds[i]=scrambled2[i];
            }
            
            //Reset player2 played card counts
            player2.playedCardCount = 0;
        }
        else 
        {
            //Don't need to refresh cards now

            // Get temp support info of previous turn's hands and calculate their effect for the new turn
            player1.hand = calSupportCardsOnTable(player1.hand, player2.hand);
            player2.hand = calSupportCardsOnTable(player2.hand, player1.hand);
        }

        // Draw player1 support cards for the new turn
        for (uint256 i = 0; i < player1.hand.currentBCstats.inte; i++) {
            player1.hand.supportCardInHandIds[i] = player1.totalSupportCardIds[(i + player1.playedCardCount) % p1SupportCardIdsLength];
        }
        player1.playedCardCount += player1.hand.currentBCstats.inte;

        // Draw player2 support cards for the new turn
        for (uint256 i = 0; i < player2.hand.currentBCstats.inte; i++) {
            player2.hand.supportCardInHandIds[i] = player2.totalSupportCardIds[(i + player2.playedCardCount) % p2SupportCardIdsLength];
        }
        player2.playedCardCount += player2.hand.currentBCstats.inte;

        //Update current battle info
        battle.player1 = player1;
        battle.player2 = player2;

        // Increment current turn number of battle
        battle.currentTurn++;

        // Go for first half in turn
        battle.turnHalves = TurnHalves.FIRST_HALF;

        return battle;
    }

    //This method calculates the battle card's stats after taking into consideration all the support cards currently being played
    function calSupportCardsOnTable(Hand memory hand, Hand memory oppHand) internal pure returns (Hand memory) {
        for (uint256 i = 0; i < hand.tableSupportCardStats; i++) {
            //Loop through every support card currently played

            //Get the support card being considered now
            TableSupportCardStats memory tableSupportCardStat = hand.tableSupportCards[i];
            
            //Get the effect of that support card
            PepemonCardOracle.EffectMany memory effect = tableSupportCardStat.effectMany;
            
            //If there is at least 1 turn left
            if (effect.numTurns >= 1) {

                //If the effect is for me
                if (effect.effectFor == PepemonCardOracle.EffectFor.ME) {
                    // Change my card's stats using that support card
                    // Currently effectTo of EffectMany can be ATTACK, DEFENSE, SPEED and INTELLIGENCE
                    //Get the statistic changed and update it 
                    //Intelligence can't go into the negatives
                    if (effect.effectTo == PepemonCardOracle.EffectTo.ATTACK) {
                        hand.currentBCstats.atk += effect.power;
                    } else if (effect.effectTo == PepemonCardOracle.EffectTo.DEFENSE) {
                        hand.currentBCstats.def += effect.power;
                    } else if (effect.effectTo == PepemonCardOracle.EffectTo.SPEED) {
                        hand.currentBCstats.spd += effect.power;
                    } else if (effect.effectTo == PepemonCardOracle.EffectTo.INTELLIGENCE) {
                        int temp;
                        temp = int256(hand.currentBCstats.inte) + effect.power;
                        hand.currentBCstats.inte = (temp > 0 ? uint(temp) : 0);
                    }
                } else {
                    //The card affects the opp's pepemon
                    //Update card stats of the opp's pepemon
                    //Make sure INT stat can't go below zero
                    if (effect.effectTo == PepemonCardOracle.EffectTo.ATTACK) {
                        oppHand.currentBCstats.atk += effect.power;
                    } else if (effect.effectTo == PepemonCardOracle.EffectTo.DEFENSE) {
                        oppHand.currentBCstats.def += effect.power;
                    } else if (effect.effectTo == PepemonCardOracle.EffectTo.SPEED) {
                        oppHand.currentBCstats.spd += effect.power;
                    } else if (effect.effectTo == PepemonCardOracle.EffectTo.INTELLIGENCE) {
                        int temp;
                        temp = int256(oppHand.currentBCstats.inte) + effect.power;
                        oppHand.currentBCstats.inte = (temp > 0 ? uint(temp) : 0);
                    }
                }
                // Decrease effect numTurns by 1 since 1 turn has already passed
                effect.numTurns--;
                // Delete this one from tableSupportCardStat if all turns of the card have been exhausted
                if (effect.numTurns == 0) {
                    if (i < hand.tableSupportCardStats - 1) {
                        hand.tableSupportCards[i] = hand.tableSupportCards[hand.tableSupportCardStats - 1];
                    }
                    delete hand.tableSupportCards[hand.tableSupportCardStats - 1];
                    hand.tableSupportCardStats--;
                }
            }
        }

        return hand;
    }

    //This method gets the current attacker
    function resolveAttacker(Battle memory battle) internal view returns (Battle memory) {
        CurrentBattleCardStats memory p1CurrentBattleCardStats = battle.player1.hand.currentBCstats;
        CurrentBattleCardStats memory p2CurrentBattleCardStats = battle.player2.hand.currentBCstats;

        if (battle.turnHalves == TurnHalves.FIRST_HALF) {
            //Player with highest speed card goes first
            if (p1CurrentBattleCardStats.spd > p2CurrentBattleCardStats.spd) {
                battle.attacker = Attacker.PLAYER_ONE;
            } else if (p1CurrentBattleCardStats.spd < p2CurrentBattleCardStats.spd) {
                battle.attacker = Attacker.PLAYER_TWO;
            } else {
                //Tiebreak: intelligence
                if (p1CurrentBattleCardStats.inte > p2CurrentBattleCardStats.inte) {
                    battle.attacker = Attacker.PLAYER_ONE;
                } else if (p1CurrentBattleCardStats.inte < p2CurrentBattleCardStats.inte) {
                    battle.attacker = Attacker.PLAYER_TWO;
                } else {
                    //Second tiebreak: use RNG
                    uint256 rand = _randMod(69420, battle) % 2;
                    battle.attacker = (rand == 0 ? Attacker.PLAYER_ONE : Attacker.PLAYER_TWO);
                }
            }
        } else {
            //For second half, switch players
            battle.attacker = (battle.attacker == Attacker.PLAYER_ONE ? Attacker.PLAYER_TWO : Attacker.PLAYER_ONE);
        }

        return battle;
    }

    //Create a random seed, using the chainlink number and the addresses of the combatants as entropy
    function _randSeed(Battle memory battle) private view returns (uint256) {
        //Get the chainlink random number
        uint chainlinkNumber = _randNrGenContract.getRandomNumber();
        //Create a new pseudorandom number using the seed and battle info as entropy
        //This makes sure the RNG returns a different number every time
        uint256 randomNumber = uint(keccak256(abi.encodePacked(block.number, chainlinkNumber, battle.player1.playerAddr, battle.player2.playerAddr)));
        return randomNumber;
    }

    function _randMod(uint256 seed, Battle memory battle) private view returns (uint256) {
        uint256 randomNumber = uint(keccak256(abi.encodePacked(seed, battle.currentTurn, battleIdRNGSeed[battle.battleId])));
        return randomNumber;
    }

    //Check if battle ended by looking at player's health
    function checkIfBattleEnded(Battle memory battle) public pure returns (bool, address) {
        if (battle.player1.hand.health <= 0) {
            return (true, battle.player1.playerAddr);
        } else if (battle.player2.hand.health <= 0) {
            return (true, battle.player2.playerAddr);
        } else {
            return (false, address(0));
        }
    }

    function fight(Battle memory battle) public view returns (Battle memory) {
        Hand memory atkHand;
        Hand memory defHand;

        //Get attacker and defender for current turn
        if (battle.attacker == Attacker.PLAYER_ONE) {
            atkHand = battle.player1.hand;
            defHand = battle.player2.hand;
        } else {
            atkHand = battle.player2.hand;
            defHand = battle.player1.hand;
        }

        (atkHand, defHand) = calSupportCardsInHand(atkHand, defHand);

        // Fight

        //Calculate HP loss for defending player
        if (atkHand.currentBCstats.atk > defHand.currentBCstats.def) {
            //If attacker's attack > defender's defense, find difference. That is the defending player's HP loss
            defHand.health -= (atkHand.currentBCstats.atk - defHand.currentBCstats.def);
        } else {
            //Otherwise, defender loses 1 HP
            defHand.health -= 1;
        }

        //Write updated info back into battle
        if (battle.attacker == Attacker.PLAYER_ONE) {
            battle.player1.hand = atkHand;
            battle.player2.hand = defHand;
        } else {
            battle.player1.hand = defHand;
            battle.player2.hand = atkHand;
        }

        return battle;
    }

    
    //We calculate the effect of every card in the player's hand
    function calSupportCardsInHand(Hand memory atkHand, Hand memory defHand) public view returns (Hand memory, Hand memory) {
        // If this card is included in player's hand, adds an additional power equal to the total of
        // all normal offense/defense cards
        bool isPower0CardIncluded = false;
        // Total sum of normal support cards
        int256 totalNormalPower = 0;
        // Cal attacker hand
        for (uint256 i = 0; i < atkHand.currentBCstats.inte; i++) {
            //Loop through every card the attacker has in his hand
            uint256 id = atkHand.supportCardInHandIds[i];

            //Get the support cardStats
            PepemonCardOracle.SupportCardStats memory cardStats = _cardContract.getSupportCardById(id);
            if (cardStats.supportCardType == PepemonCardOracle.SupportCardType.OFFENSE) {
                // Card type is OFFENSE.
                // Calc effects of EffectOne array
                for (uint256 j = 0; j < cardStats.effectOnes.length; j++) {
                    PepemonCardOracle.EffectOne memory effectOne = cardStats.effectOnes[j];
                    
                    //Checks if that support card is triggered and by how much it is triggered by
                    (bool isTriggered, uint256 multiplier) = checkReqCode(atkHand, defHand, effectOne.reqCode, true);
                    if (isTriggered) {
                        //use triggeredPower if triggered
                        atkHand.currentBCstats.atk += effectOne.triggeredPower * int256(multiplier);
                        totalNormalPower += effectOne.triggeredPower * int256(multiplier);
                    }
                    else{
                        //use basePower if not
                        atkHand.currentBCstats.atk += effectOne.basePower;
                        totalNormalPower += effectOne.basePower;
                    }
                }
            } else if (cardStats.supportCardType == PepemonCardOracle.SupportCardType.STRONG_OFFENSE) {
                // Card type is STRONG OFFENSE.

                //Make sure unstackable cards can't be stacked
                if (cardStats.unstackable) {
                    bool isNew = true;
                    // Check if card is new to previous cards
                    for (uint256 j = 0; j < i; j++) {
                        if (id == atkHand.supportCardInHandIds[j]) {
                            isNew = false;
                            break;
                        }
                    }
                    if (!isNew) {
                        //If it isn't - skip card
                        continue;
                    }
                    // Check if card is new to temp support info cards
                    for (uint256 j = 0; j < atkHand.tableSupportCardStats; j++) {
                        if (id == atkHand.tableSupportCards[j].supportCardId) {
                            isNew = false;
                            break;
                        }
                    }
                    if (!isNew) {
                        //If it isn't - skip card
                        continue;
                    }
                }

                // Calc effects of EffectOne array
                for (uint256 j = 0; j < cardStats.effectOnes.length; j++) {
                    PepemonCardOracle.EffectOne memory effectOne = cardStats.effectOnes[j];
                    (bool isTriggered, uint256 multiplier) = checkReqCode(atkHand, defHand, effectOne.reqCode, true);
                    if (isTriggered) {
                        //If triggered: use triggered power
                        if (multiplier > 1) {
                            atkHand.currentBCstats.atk += effectOne.triggeredPower * int256(multiplier);
                        } else {
                            if (effectOne.effectTo == PepemonCardOracle.EffectTo.STRONG_ATTACK) {
                                // If it's a use Special Attack instead of Attack card
                                atkHand.currentBCstats.atk = atkHand.currentBCstats.sAtk;
                                continue;
                            } else if (effectOne.triggeredPower == 0) {
                                // We have a card that says ATK is increased by amount
                                // Equal to the total of all offense cards in the current turn
                                isPower0CardIncluded = true;
                                continue;
                            }
                            atkHand.currentBCstats.atk += effectOne.triggeredPower;
                        }
                    }
                    else{
                        //If not triggered: use base power instead
                        atkHand.currentBCstats.atk += effectOne.basePower;
                        totalNormalPower += effectOne.basePower;
                    }
                }
                // If card lasts for >1 turns
                if (cardStats.effectMany.power != 0) {
                    // Add card  to table if <5 on table currently
                    if (atkHand.tableSupportCardStats < 5) {
                        atkHand.tableSupportCards[atkHand.tableSupportCardStats++] = TableSupportCardStats({
                            supportCardId: id,
                            effectMany: cardStats.effectMany
                        });
                    }
                }
            } else {
                // Other card type is ignored.
                continue;
            }
        }
        if (isPower0CardIncluded) {
            //If we have a card that says ATK is increased by amount equal to total of all offense cards
            atkHand.currentBCstats.atk += totalNormalPower;
        }
        // Cal defense hand
        isPower0CardIncluded = false;
        totalNormalPower = 0;

        for (uint256 i = 0; i < defHand.currentBCstats.inte; i++) {
            uint256 id = defHand.supportCardInHandIds[i];
            PepemonCardOracle.SupportCardStats memory card = _cardContract.getSupportCardById(id);
            if (card.supportCardType == PepemonCardOracle.SupportCardType.DEFENSE) {
                // Card type is DEFENSE
                // Calc effects of EffectOne array
                for (uint256 j = 0; j < card.effectOnes.length; j++) {
                    PepemonCardOracle.EffectOne memory effectOne = card.effectOnes[j];
                    (bool isTriggered, uint256 multiplier) = checkReqCode(atkHand, defHand, effectOne.reqCode, false);
                    if (isTriggered) {
                        defHand.currentBCstats.def += effectOne.triggeredPower * int256(multiplier);
                        totalNormalPower += effectOne.triggeredPower * int256(multiplier);
                    }
                    else{
                        //If not triggered, use base power instead
                        defHand.currentBCstats.def += effectOne.basePower;
                        totalNormalPower += effectOne.basePower;
                    }
                }
            } else if (card.supportCardType == PepemonCardOracle.SupportCardType.STRONG_DEFENSE) {
                // Card type is STRONG DEFENSE
                if (card.unstackable) {
                    bool isNew = true;
                    // Check if card is new to previous cards
                    for (uint256 j = 0; j < i; j++) {
                        if (id == defHand.supportCardInHandIds[j]) {
                            isNew = false;
                            break;
                        }
                    }
                    // Check if card is new to temp support info cards
                    for (uint256 j = 0; j < defHand.tableSupportCardStats; j++) {
                        if (id == defHand.tableSupportCards[j].supportCardId) {
                            isNew = false;
                            break;
                        }
                    }
                    if (!isNew) {
                        continue;
                    }
                }
                // Calc effects of EffectOne array
                for (uint256 j = 0; j < card.effectOnes.length; j++) {
                    PepemonCardOracle.EffectOne memory effectOne = card.effectOnes[j];
                    (bool isTriggered, uint256 num) = checkReqCode(atkHand, defHand, effectOne.reqCode, false);
                    if (isTriggered) {
                        if (num > 0) {
                            defHand.currentBCstats.def += effectOne.triggeredPower * int256(num);
                        } else {
                            if (effectOne.effectTo == PepemonCardOracle.EffectTo.STRONG_DEFENSE) {
                                defHand.currentBCstats.def = defHand.currentBCstats.sDef;
                                continue;
                            } else if (effectOne.triggeredPower == 0) {
                                // Equal to the total of all defense cards in the current turn
                                isPower0CardIncluded = true;
                                continue;
                            }
                            defHand.currentBCstats.def += effectOne.triggeredPower;
                        }
                    }
                    else{
                        //If not triggered, use base stats instead
                        defHand.currentBCstats.def += effectOne.basePower;
                        totalNormalPower += effectOne.basePower;
                    }
                }
                // If card effect lasts >1 turn
                if (card.effectMany.power != 0) {
                    // Add card to table if there are <5 cards on table right now
                    if (defHand.tableSupportCardStats < 5) {
                        defHand.tableSupportCards[defHand.tableSupportCardStats++] = TableSupportCardStats({
                            supportCardId: id,
                            effectMany: card.effectMany
                        });
                    }
                }
            } else {
                // Other card type is ignored.
                continue;
            }
        }
        if (isPower0CardIncluded) {
            //If a "add total of defense" card is included
            defHand.currentBCstats.def += totalNormalPower;
        }

        return (atkHand, defHand);
    }

    //Strip important game information (like speed, intelligence, etc.) from battle card
    function getCardStats(PepemonCardOracle.BattleCardStats memory x) internal pure returns (CurrentBattleCardStats memory){
        CurrentBattleCardStats memory ret;

        ret.spd = int(x.spd);
        ret.inte = x.inte;
        ret.def = int(x.def);
        ret.atk = int(x.atk);
        ret.sAtk = int(x.sAtk);
        ret.sDef = int(x.sDef);

        return ret;
    }

//Checks if the requirements are satisfied for a certain code
//returns bool - is satisfied?
// uint - the multiplier for the card's attack power
// for most cases multiplier is 1
function checkReqCode(
        Hand memory atkHand,
        Hand memory defHand,
        uint256 reqCode,
        bool isAttacker
    ) internal view returns (bool, uint256) {
        bool isTriggered = false;
        uint256 multiplier = 0;
        if (reqCode == 0) {
            // No requirement
            isTriggered = true;
            multiplier = 1;
        } else if (reqCode == 1) {
            // Intelligence of offense pepemon <= 5.
            isTriggered = (atkHand.currentBCstats.inte <= 5 );
            multiplier = 1;

        } else if (reqCode == 2) {
            // Number of defense cards of defense pepemon is 0.
            isTriggered = true;
            for (uint256 i = 0; i < defHand.currentBCstats.inte; i++) {
                PepemonCardOracle.SupportCardType supportCardType = _cardContract.getSupportCardTypeById(
                    defHand.supportCardInHandIds[i]
                );
                if (supportCardType == PepemonCardOracle.SupportCardType.DEFENSE) {
                    isTriggered = false;
                    break;
                }
            }
            multiplier = 1;
        } else if (reqCode == 3) {
            // Each +2 offense cards of offense pepemon.
            for (uint256 i = 0; i < atkHand.currentBCstats.inte; i++) {
                PepemonCardOracle.SupportCardStats memory card = _cardContract.getSupportCardById(
                    atkHand.supportCardInHandIds[i]
                );
                if (card.supportCardType != PepemonCardOracle.SupportCardType.OFFENSE) {
                    continue;
                }
                for (uint256 j = 0; j < card.effectOnes.length; j++) {
                    PepemonCardOracle.EffectOne memory effectOne = card.effectOnes[j];
                    if (effectOne.basePower == 2) {
                        multiplier++;
                    }
                }
            }
            isTriggered = (multiplier > 0 );
        } else if (reqCode == 4) {
            // Each +3 offense cards of offense pepemon.
            for (uint256 i = 0; i < atkHand.currentBCstats.inte; i++) {
                PepemonCardOracle.SupportCardStats memory card = _cardContract.getSupportCardById(
                    atkHand.supportCardInHandIds[i]
                );
                if (card.supportCardType != PepemonCardOracle.SupportCardType.OFFENSE) {
                    continue;
                }
                for (uint256 j = 0; j < card.effectOnes.length; j++) {
                    PepemonCardOracle.EffectOne memory effectOne = card.effectOnes[j];
                    if (effectOne.basePower == 3) {
                        multiplier++;
                    }
                }
            }
            isTriggered = (multiplier > 0 );
        } else if (reqCode == 5) {
            // Each offense card of offense pepemon.
            for (uint256 i = 0; i < atkHand.currentBCstats.inte; i++) {
                PepemonCardOracle.SupportCardStats memory card = _cardContract.getSupportCardById(
                    atkHand.supportCardInHandIds[i]
                );
                if (card.supportCardType != PepemonCardOracle.SupportCardType.OFFENSE) {
                    continue;
                }
                multiplier++;
            }
            isTriggered = (multiplier > 0 );
        } else if (reqCode == 6) {
            // Each +3 defense card of defense pepemon.
            for (uint256 i = 0; i < defHand.currentBCstats.inte; i++) {
                PepemonCardOracle.SupportCardStats memory card = _cardContract.getSupportCardById(
                    defHand.supportCardInHandIds[i]
                );
                if (card.supportCardType != PepemonCardOracle.SupportCardType.DEFENSE) {
                    continue;
                }
                for (uint256 j = 0; j < card.effectOnes.length; j++) {
                    PepemonCardOracle.EffectOne memory effectOne = card.effectOnes[j];
                    if (effectOne.basePower == 3) {
                        multiplier++;
                    }
                }
            }
            isTriggered = (multiplier > 0 );
        } else if (reqCode == 7) {
            // Each +4 defense card of defense pepemon.
            for (uint256 i = 0; i < defHand.currentBCstats.inte; i++) {
                PepemonCardOracle.SupportCardStats memory card = _cardContract.getSupportCardById(
                    defHand.supportCardInHandIds[i]
                );
                if (card.supportCardType != PepemonCardOracle.SupportCardType.DEFENSE) {
                    continue;
                }
                for (uint256 j = 0; j < card.effectOnes.length; j++) {
                    PepemonCardOracle.EffectOne memory effectOne = card.effectOnes[j];
                    if (effectOne.basePower == 4) {
                        multiplier++;
                    }
                }
            }
            isTriggered = (multiplier > 0 );
        } else if (reqCode == 8) {
            // Intelligence of defense pepemon <= 5.
            isTriggered = (defHand.currentBCstats.inte <= 5 );
            multiplier = 1;
        } else if (reqCode == 9) {
            // Intelligence of defense pepemon >= 7.
            isTriggered = (defHand.currentBCstats.inte >= 7 );
            multiplier = 1;
        } else if (reqCode == 10) {
            // Offense pepemon is using strong attack
            for (uint256 i = 0; i < atkHand.currentBCstats.inte; i++) {
                PepemonCardOracle.SupportCardStats memory card = _cardContract.getSupportCardById(
                    atkHand.supportCardInHandIds[i]
                );
                if (card.supportCardType == PepemonCardOracle.SupportCardType.STRONG_OFFENSE) {
                    isTriggered = true;
                    break;
                }
            }
            multiplier = 1;
        } else if (reqCode == 11) {
            // The current HP is less than 50% of max HP.
            if (isAttacker) {
                isTriggered = (
                    atkHand.health * 2 <= int256(_cardContract.getBattleCardById(atkHand.battleCardId).hp)
                );
            } else {
                isTriggered = (
                    defHand.health * 2 <= int256(_cardContract.getBattleCardById(defHand.battleCardId).hp)

                );
            }
            multiplier = 1;
        }
        return (isTriggered, multiplier);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./PepemonFactory.sol";
import "./PepemonCardOracle.sol";
import "./lib/Arrays.sol";

contract PepemonCardDeck is ERC721, ERC1155Holder, Ownable {
    using SafeMath for uint256;

    struct Deck {
        uint256 battleCardId;
        uint256 supportCardCount;
        mapping(uint256 => SupportCardType) supportCardTypes;
        uint256[] supportCardTypeList;
    }

    struct SupportCardType {
        uint256 supportCardId;
        uint256 count;
        uint256 pointer;
        bool isEntity;
    }

    struct SupportCardRequest {
        uint256 supportCardId;
        uint256 amount;
    }

    uint256 public MAX_SUPPORT_CARDS;
    uint256 public MIN_SUPPORT_CARDS;

    uint256 nextDeckId;
    address public battleCardAddress;
    address public supportCardAddress;

    mapping(uint256 => Deck) public decks;
    mapping(address => uint256[]) public playerToDecks;

    constructor() ERC721("Pepedeck", "Pepedeck") {
        nextDeckId = 1;
        MAX_SUPPORT_CARDS = 60;
        MIN_SUPPORT_CARDS = 40;
    }

    /**
     * @dev Override supportInterface .
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // MODIFIERS
    modifier sendersDeck(uint256 _deckId) {
        require(msg.sender == ownerOf(_deckId), "PepemonCardDeck: Not your deck");
        _;
    }

    // PUBLIC METHODS
    function setBattleCardAddress(address _battleCardAddress) public onlyOwner {
        battleCardAddress = _battleCardAddress;
    }

    function setSupportCardAddress(address _supportCardAddress) public onlyOwner {
        supportCardAddress = _supportCardAddress;
    }

    function setMaxSupportCards(uint256 _maxSupportCards) public onlyOwner {
        MAX_SUPPORT_CARDS = _maxSupportCards;
    }

    function setMinSupportCards(uint256 _minSupportCards) public onlyOwner {
        MIN_SUPPORT_CARDS = _minSupportCards;
    }

    function createDeck() public {
        _safeMint(msg.sender, nextDeckId);
        playerToDecks[msg.sender].push(nextDeckId);
        nextDeckId = nextDeckId.add(1);
    }

    function addBattleCardToDeck(uint256 deckId, uint256 battleCardId) public sendersDeck(deckId) {
        require(
            PepemonFactory(battleCardAddress).balanceOf(msg.sender, battleCardId) >= 1,
            "PepemonCardDeck: Don't own battle card"
        );

        require(battleCardId != decks[deckId].battleCardId, "PepemonCardDeck: Card already in deck");

        uint256 oldBattleCardId = decks[deckId].battleCardId;
        decks[deckId].battleCardId = battleCardId;

        PepemonFactory(battleCardAddress).safeTransferFrom(msg.sender, address(this), battleCardId, 1, "");

        returnBattleCardFromDeck(oldBattleCardId);
    }

    function removeBattleCardFromDeck(uint256 _deckId) public sendersDeck(_deckId) {
        uint256 oldBattleCardId = decks[_deckId].battleCardId;

        decks[_deckId].battleCardId = 0;

        returnBattleCardFromDeck(oldBattleCardId);
    }

    function addSupportCardsToDeck(uint256 deckId, SupportCardRequest[] memory supportCards) public sendersDeck(deckId) {
        for (uint256 i = 0; i < supportCards.length; i++) {
            addSupportCardToDeck(deckId, supportCards[i].supportCardId, supportCards[i].amount);
        }
    }

    function removeSupportCardsFromDeck(uint256 _deckId, SupportCardRequest[] memory _supportCards) public sendersDeck(_deckId) {
        for (uint256 i = 0; i < _supportCards.length; i++) {
            removeSupportCardFromDeck(_deckId, _supportCards[i].supportCardId, _supportCards[i].amount);
        }
    }

    // INTERNALS
    function addSupportCardToDeck(
        uint256 _deckId,
        uint256 _supportCardId,
        uint256 _amount
    ) internal {
        require(MAX_SUPPORT_CARDS >= decks[_deckId].supportCardCount.add(_amount), "PepemonCardDeck: Deck overflow");
        require(
            PepemonFactory(supportCardAddress).balanceOf(msg.sender, _supportCardId) >= _amount,
            "PepemonCardDeck: You don't have enough of this card"
        );

        if (!decks[_deckId].supportCardTypes[_supportCardId].isEntity) {
            decks[_deckId].supportCardTypes[_supportCardId] = SupportCardType({
                supportCardId: _supportCardId,
                count: _amount,
                pointer: decks[_deckId].supportCardTypeList.length,
                isEntity: true
            });

            // Prepend the ID to the list
            decks[_deckId].supportCardTypeList.push(_supportCardId);
        } else {
            SupportCardType storage supportCard = decks[_deckId].supportCardTypes[_supportCardId];
            supportCard.count = supportCard.count.add(_amount);
        }

        decks[_deckId].supportCardCount = decks[_deckId].supportCardCount.add(_amount);

        PepemonFactory(supportCardAddress).safeTransferFrom(msg.sender, address(this), _supportCardId, _amount, "");
    }

    function removeSupportCardFromDeck(
        uint256 _deckId,
        uint256 _supportCardId,
        uint256 _amount
    ) internal {
        SupportCardType storage supportCardList = decks[_deckId].supportCardTypes[_supportCardId];
        supportCardList.count = supportCardList.count.sub(_amount);

        decks[_deckId].supportCardCount = decks[_deckId].supportCardCount.sub(_amount);

        if (supportCardList.count == 0) {
            uint256 lastItemIndex = decks[_deckId].supportCardTypeList.length - 1;

            // update the pointer of the item to be swapped
            uint256 lastSupportCardId = decks[_deckId].supportCardTypeList[lastItemIndex];
            decks[_deckId].supportCardTypes[lastSupportCardId].pointer = supportCardList.pointer;

            // swap the last item of the list with the one to be deleted
            decks[_deckId].supportCardTypeList[supportCardList.pointer] = decks[_deckId].supportCardTypeList[lastItemIndex];
            decks[_deckId].supportCardTypeList.pop();

            delete decks[_deckId].supportCardTypes[_supportCardId];
        }

        PepemonFactory(supportCardAddress).safeTransferFrom(address(this), msg.sender, _supportCardId, _amount, "");
    }

    function returnBattleCardFromDeck(uint256 _battleCardId) internal {
        if (_battleCardId != 0) {
            PepemonFactory(battleCardAddress).safeTransferFrom(address(this), msg.sender, _battleCardId, 1, "");
        }
    }

    // VIEWS
    function getDeckCount(address player) public view returns (uint256) {
        return playerToDecks[player].length;
    }

    function getBattleCardInDeck(uint256 _deckId) public view returns (uint256) {
        return decks[_deckId].battleCardId;
    }

    function getCardTypesInDeck(uint256 _deckId) public view returns (uint256[] memory) {
        Deck storage deck = decks[_deckId];

        uint256[] memory supportCardTypes = new uint256[](deck.supportCardTypeList.length);

        for (uint256 i = 0; i < deck.supportCardTypeList.length; i++) {
            supportCardTypes[i] = deck.supportCardTypeList[i];
        }

        return supportCardTypes;
    }

    function getCountOfCardTypeInDeck(uint256 _deckId, uint256 _cardTypeId) public view returns (uint256) {
        return decks[_deckId].supportCardTypes[_cardTypeId].count;
    }

    function getSupportCardCountInDeck(uint256 deckId) public view returns (uint256) {
        return decks[deckId].supportCardCount;
    }

    /**
     * @dev Returns array of support cards for a deck
     * @param _deckId uint256 ID of the deck
     */
    function getAllSupportCardsInDeck(uint256 _deckId) public view returns (uint256[] memory) {
        Deck storage deck = decks[_deckId];
        uint256[] memory supportCards = new uint256[](deck.supportCardCount);
        uint256 idx = 0;
        for (uint256 i = 0; i < deck.supportCardTypeList.length; i++) {
            uint256 supportCardId = deck.supportCardTypeList[i];
            for (uint256 j = 0; j < deck.supportCardTypes[supportCardId].count; j++) {
                supportCards[idx++] = supportCardId;
            }
        }
        return supportCards;
    }

    /**
     * @dev Shuffles deck
     * @param _deckId uint256 ID of the deck
     */
    function shuffleDeck(uint256 _deckId, uint256 _seed) public view returns (uint256[] memory) {
        uint256[] memory totalSupportCards = getAllSupportCardsInDeck(_deckId);
        return Arrays.shuffle(totalSupportCards, _seed);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./lib/AdminRole.sol";

/**
This contract acts as the oracle, it contains battling information for both the Pepemon Battle and Support cards
**/
contract PepemonCardOracle is AdminRole {
    enum BattleCardType {
        PLANT,
        FIRE
    }

    enum SupportCardType {
        OFFENSE,
        STRONG_OFFENSE,
        DEFENSE,
        STRONG_DEFENSE
    }

    enum EffectTo {
        ATTACK,
        STRONG_ATTACK,
        DEFENSE,
        STRONG_DEFENSE,
        SPEED,
        INTELLIGENCE
    }

    enum EffectFor {
        ME,
        ENEMY
    }

    struct BattleCardStats {
        uint256 battleCardId;
        BattleCardType battleCardType;
        string name;
        uint256 hp; // hitpoints
        uint256 spd; // speed
        uint256 inte; // intelligence
        uint256 def; // defense
        uint256 atk; // attack
        uint256 sAtk; // special attack
        uint256 sDef; // special defense
    }

    struct SupportCardStats {
        uint256 supportCardId;
        SupportCardType supportCardType;
        string name;
        EffectOne[] effectOnes;
        EffectMany effectMany;
        // If true, duplicate copies of the card in the same turn will have no extra effect.
        bool unstackable;
        // This property is for EffectMany now.
        // If true, assume the card is already in effect
        // then the same card drawn and used within a number of turns does not extend or reset duration of the effect.
        bool unresettable;
    }

    struct EffectOne {
        // If power is 0, it is equal to the total of all normal offense/defense cards in the current turn.
        
        //basePower = power if req not met
        int256 basePower;

        //triggeredPower = power if req met
        int256 triggeredPower;
        EffectTo effectTo;
        EffectFor effectFor;
        uint256 reqCode; //requirement code
    }

    struct EffectMany {
        int256 power;
        uint256 numTurns;
        EffectTo effectTo;
        EffectFor effectFor;
        uint256 reqCode; //requirement code
    }

    mapping(uint256 => BattleCardStats) public battleCardStats;
    mapping(uint256 => SupportCardStats) public supportCardStats;

    event BattleCardCreated(address sender, uint256 cardId);
    event BattleCardUpdated(address sender, uint256 cardId);
    event SupportCardCreated(address sender, uint256 cardId);
    event SupportCardUpdated(address sender, uint256 cardId);

    function addBattleCard(BattleCardStats memory cardData) public onlyAdmin {
        require(battleCardStats[cardData.battleCardId].battleCardId == 0, "PepemonCard: BattleCard already exists");

        BattleCardStats storage _card = battleCardStats[cardData.battleCardId];
        _card.battleCardId = cardData.battleCardId;
        _card.battleCardType = cardData.battleCardType;
        _card.name = cardData.name;
        _card.hp = cardData.hp;
        _card.spd = cardData.spd;
        _card.inte = cardData.inte;
        _card.def = cardData.def;
        _card.atk = cardData.atk;
        _card.sDef = cardData.sDef;
        _card.sAtk = cardData.sAtk;

        emit BattleCardCreated(msg.sender, cardData.battleCardId);
    }

    function updateBattleCard(BattleCardStats memory cardData) public onlyAdmin {
        require(battleCardStats[cardData.battleCardId].battleCardId != 0, "PepemonCard: BattleCard not found");

        BattleCardStats storage _card = battleCardStats[cardData.battleCardId];
        _card.hp = cardData.hp;
        _card.battleCardType = cardData.battleCardType;
        _card.name = cardData.name;
        _card.spd = cardData.spd;
        _card.inte = cardData.inte;
        _card.def = cardData.def;
        _card.atk = cardData.atk;
        _card.sDef = cardData.sDef;
        _card.sAtk = cardData.sAtk;

        emit BattleCardUpdated(msg.sender, cardData.battleCardId);
    }

    function getBattleCardById(uint256 _id) public view returns (BattleCardStats memory) {
        require(battleCardStats[_id].battleCardId != 0, "PepemonCard: BattleCard not found");
        return battleCardStats[_id];
    }

    function addSupportCard(SupportCardStats memory cardData) public onlyAdmin {
        require(supportCardStats[cardData.supportCardId].supportCardId == 0, "PepemonCard: SupportCard already exists");

        SupportCardStats storage _card = supportCardStats[cardData.supportCardId];
        _card.supportCardId = cardData.supportCardId;
        _card.supportCardType = cardData.supportCardType;
        _card.name = cardData.name;
        for (uint256 i = 0; i < cardData.effectOnes.length; i++) {
            _card.effectOnes.push(cardData.effectOnes[i]);
        }
        _card.effectMany = cardData.effectMany;
        _card.unstackable = cardData.unstackable;
        _card.unresettable = cardData.unresettable;

        emit SupportCardCreated(msg.sender, cardData.supportCardId);
    }

    function updateSupportCard(SupportCardStats memory cardData) public onlyAdmin {
        require(supportCardStats[cardData.supportCardId].supportCardId != 0, "PepemonCard: SupportCard not found");

        SupportCardStats storage _card = supportCardStats[cardData.supportCardId];
        _card.supportCardId = cardData.supportCardId;
        _card.supportCardType = cardData.supportCardType;
        _card.name = cardData.name;
        for (uint256 i = 0; i < cardData.effectOnes.length; i++) {
            _card.effectOnes.push(cardData.effectOnes[i]);
        }
        _card.effectMany = cardData.effectMany;
        _card.unstackable = cardData.unstackable;
        _card.unresettable = cardData.unresettable;

        emit SupportCardUpdated(msg.sender, cardData.supportCardId);
    }

    function getSupportCardById(uint256 _id) public view returns (SupportCardStats memory) {
        require(supportCardStats[_id].supportCardId != 0, "PepemonCard: SupportCard not found");
        return supportCardStats[_id];
    }

    /**
     * @dev Get supportCardType of supportCard
     * @param _id uint256
     */
    function getSupportCardTypeById(uint256 _id) public view returns (SupportCardType) {
        return getSupportCardById(_id).supportCardType;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Roles.sol";

contract AdminRole {
  using Roles for Roles.Role;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  Roles.Role private admins;

  constructor() {
    _addAdmin(msg.sender);
  }

  modifier onlyAdmin() {
    require(isAdmin(msg.sender));
    _;
  }

  function isAdmin(address account) public view returns (bool) {
    return admins.has(account);
  }

  function addAdmin(address account) public onlyAdmin {
    _addAdmin(account);
  }

  function renounceAdmin() public {
    _removeAdmin(msg.sender);
  }

  function _addAdmin(address account) internal {
    admins.add(account);
    emit AdminAdded(account);
  }

  function _removeAdmin(address account) internal {
    admins.remove(account);
    emit AdminRemoved(account);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./AdminRole.sol";

abstract contract ChainLinkRngOracle is VRFConsumerBase, AdminRole {
    bytes32 immutable keyHash;
    bytes32 public lastRequestId;
    uint256 internal fee;

    address constant maticLink = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    address constant maticVrfCoordinator = 0x3d2341ADb2D31f1c5530cDC622016af293177AE0;
    bytes32 constant maticKeyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;

    address constant mumbaiLink = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address constant mumbaiVrfCoordinator = 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255;
    bytes32 constant mumbaiKeyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;



    mapping(bytes32 => uint256) internal results;

    constructor() VRFConsumerBase(mumbaiVrfCoordinator, mumbaiLink) {
        keyHash = mumbaiKeyHash;
        fee = 1 ether / 1000;
    }

    //Get a new random number (paying link for it)
    //Only callable by admin
    function getNewRandomNumber() public onlyAdmin returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        lastRequestId = requestRandomness(keyHash, fee);
        return lastRequestId;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        results[requestId] = randomness;
    }

    function fetchNumberByRequestId(bytes32 _requestId) public view returns (uint256) {
        return results[_requestId];
    }

    //Get most recent random number and use that as randomness source    
    function getRandomNumber() public view returns (uint256){
        return fetchNumberByRequestId(lastRequestId);        
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface PepemonFactory {
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Arrays {
    //Shuffles an array of uints with random seed
    function shuffle(uint256[] memory _elements, uint256 _seed) internal pure returns (uint256[] memory) {
        for (uint256 i = 0; i < _elements.length; i++) {
            //Pick random index to swap current element with
            uint256 n = i + _seed % (_elements.length - i);

            //swap elements
            uint256 temp = _elements[n];
            _elements[n] = _elements[i];
            _elements[i] = temp;

            //Create new pseudorandom number using seed.
            _seed = uint(keccak256(abi.encodePacked(_seed)));
        }
        return _elements;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "./extensions/IERC721Enumerable.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account's access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/PepemonBattle.sol";

contract XPepemonBattle is PepemonBattle {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address cardOracleAddress, address deckOracleAddress, address randOracleAddress) PepemonBattle(cardOracleAddress, deckOracleAddress, randOracleAddress) {}

    function x_max_inte() external pure returns (uint256) {
        return _max_inte;
    }

    function x_max_cards_on_table() external pure returns (uint256) {
        return _max_cards_on_table;
    }

    function x_refreshTurn() external pure returns (uint256) {
        return _refreshTurn;
    }

    function xupdateTurnInfo(PepemonBattle.Battle calldata battle) external view returns (PepemonBattle.Battle memory) {
        return super.updateTurnInfo(battle);
    }

    function xgoForNewTurn(PepemonBattle.Battle calldata battle) external view returns (PepemonBattle.Battle memory) {
        return super.goForNewTurn(battle);
    }

    function xcalSupportCardsOnTable(PepemonBattle.Hand calldata hand,PepemonBattle.Hand calldata oppHand) external pure returns (PepemonBattle.Hand memory) {
        return super.calSupportCardsOnTable(hand,oppHand);
    }

    function xresolveAttacker(PepemonBattle.Battle calldata battle) external view returns (PepemonBattle.Battle memory) {
        return super.resolveAttacker(battle);
    }

    function xgetCardStats(PepemonCardOracle.BattleCardStats calldata x) external pure returns (PepemonBattle.CurrentBattleCardStats memory) {
        return super.getCardStats(x);
    }

    function xcheckReqCode(PepemonBattle.Hand calldata atkHand,PepemonBattle.Hand calldata defHand,uint256 reqCode,bool isAttacker) external view returns (bool, uint256) {
        return super.checkReqCode(atkHand,defHand,reqCode,isAttacker);
    }

    function x_addAdmin(address account) external {
        return super._addAdmin(account);
    }

    function x_removeAdmin(address account) external {
        return super._removeAdmin(account);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/PepemonCardDeck.sol";

contract XPepemonCardDeck is PepemonCardDeck {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function xnextDeckId() external view returns (uint256) {
        return nextDeckId;
    }

    function xaddSupportCardToDeck(uint256 _deckId,uint256 _supportCardId,uint256 _amount) external {
        return super.addSupportCardToDeck(_deckId,_supportCardId,_amount);
    }

    function xremoveSupportCardFromDeck(uint256 _deckId,uint256 _supportCardId,uint256 _amount) external {
        return super.removeSupportCardFromDeck(_deckId,_supportCardId,_amount);
    }

    function xreturnBattleCardFromDeck(uint256 _battleCardId) external {
        return super.returnBattleCardFromDeck(_battleCardId);
    }

    function x_baseURI() external view returns (string memory) {
        return super._baseURI();
    }

    function x_safeTransfer(address from,address to,uint256 tokenId,bytes calldata _data) external {
        return super._safeTransfer(from,to,tokenId,_data);
    }

    function x_exists(uint256 tokenId) external view returns (bool) {
        return super._exists(tokenId);
    }

    function x_isApprovedOrOwner(address spender,uint256 tokenId) external view returns (bool) {
        return super._isApprovedOrOwner(spender,tokenId);
    }

    function x_safeMint(address to,uint256 tokenId) external {
        return super._safeMint(to,tokenId);
    }

    function x_safeMint(address to,uint256 tokenId,bytes calldata _data) external {
        return super._safeMint(to,tokenId,_data);
    }

    function x_mint(address to,uint256 tokenId) external {
        return super._mint(to,tokenId);
    }

    function x_burn(uint256 tokenId) external {
        return super._burn(tokenId);
    }

    function x_transfer(address from,address to,uint256 tokenId) external {
        return super._transfer(from,to,tokenId);
    }

    function x_approve(address to,uint256 tokenId) external {
        return super._approve(to,tokenId);
    }

    function x_beforeTokenTransfer(address from,address to,uint256 tokenId) external {
        return super._beforeTokenTransfer(from,to,tokenId);
    }

    function x_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function x_msgData() external view returns (bytes memory) {
        return super._msgData();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/PepemonCardOracle.sol";

contract XPepemonCardOracle is PepemonCardOracle {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function x_addAdmin(address account) external {
        return super._addAdmin(account);
    }

    function x_removeAdmin(address account) external {
        return super._removeAdmin(account);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/PepemonFactory.sol";

abstract contract XPepemonFactory is PepemonFactory {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/lib/AdminRole.sol";

contract XAdminRole is AdminRole {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function x_addAdmin(address account) external {
        return super._addAdmin(account);
    }

    function x_removeAdmin(address account) external {
        return super._removeAdmin(account);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/lib/Arrays.sol";

contract XArrays {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor() {}

    function xshuffle(uint256[] calldata _elements,uint256 _seed) external pure returns (uint256[] memory) {
        return Arrays.shuffle(_elements,_seed);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/lib/ChainLinkRngOracle.sol";

contract XChainLinkRngOracle is ChainLinkRngOracle {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    event xrequestRandomness_Returned(bytes32 arg0);

    constructor() {}

    function xkeyHash() external view returns (bytes32) {
        return keyHash;
    }

    function xfee() external view returns (uint256) {
        return fee;
    }

    function xmaticLink() external pure returns (address) {
        return maticLink;
    }

    function xmaticVrfCoordinator() external pure returns (address) {
        return maticVrfCoordinator;
    }

    function xmaticKeyHash() external pure returns (bytes32) {
        return maticKeyHash;
    }

    function xmumbaiLink() external pure returns (address) {
        return mumbaiLink;
    }

    function xmumbaiVrfCoordinator() external pure returns (address) {
        return mumbaiVrfCoordinator;
    }

    function xmumbaiKeyHash() external pure returns (bytes32) {
        return mumbaiKeyHash;
    }

    function xresults(bytes32 arg0) external view returns (uint256) {
        return results[arg0];
    }

    function xLINK() external view returns (LinkTokenInterface) {
        return LINK;
    }

    function xfulfillRandomness(bytes32 requestId,uint256 randomness) external {
        return super.fulfillRandomness(requestId,randomness);
    }

    function x_addAdmin(address account) external {
        return super._addAdmin(account);
    }

    function x_removeAdmin(address account) external {
        return super._removeAdmin(account);
    }

    function xrequestRandomness(bytes32 _keyHash,uint256 _fee) external returns (bytes32) {
        (bytes32 ret0) = super.requestRandomness(_keyHash,_fee);
        emit xrequestRandomness_Returned(ret0);
        return (ret0);
    }

    function xmakeVRFInputSeed(bytes32 _keyHash,uint256 _userSeed,address _requester,uint256 _nonce) external pure returns (uint256) {
        return super.makeVRFInputSeed(_keyHash,_userSeed,_requester,_nonce);
    }

    function xmakeRequestId(bytes32 _keyHash,uint256 _vRFInputSeed) external pure returns (bytes32) {
        return super.makeRequestId(_keyHash,_vRFInputSeed);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/lib/Roles.sol";

contract XRoles {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    mapping(uint256 => Roles.Role) internal xv_Roles_Role;

    constructor() {}

    function xadd(uint256 role,address account) external payable {
        return Roles.add(xv_Roles_Role[role],account);
    }

    function xremove(uint256 role,address account) external payable {
        return Roles.remove(xv_Roles_Role[role],account);
    }

    function xhas(uint256 role,address account) external view returns (bool) {
        return Roles.has(xv_Roles_Role[role],account);
    }

    receive() external payable {}
}