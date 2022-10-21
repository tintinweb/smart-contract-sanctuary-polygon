// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./interfaces/ITreasury.sol";
import "./GameManager.sol";
import "./TreasuryManager.sol";
import "./VRFManager.sol";

contract PanamaCanal is GameManager, VRFManager, TreasuryManager, ERC2771Context, AccessControlEnumerable {

    bytes32 public constant GAME_MANAGER = keccak256("GAME_MANAGER");

    mapping(uint256 => uint256) public gameByRequestId;

    event GameCreated(
        uint256 indexed _gameId,
        address indexed _player,
        address indexed _token,
        uint256 _ante
    );

    event GameCompleted(uint256 indexed _gameId, Winner[] _winner);
    event Hit(uint256 indexed _gameId);
    event DoubleDown(uint256 indexed _gameId);
    event Split(uint256 indexed _gameId);
    event Stay(uint256 indexed _gameId);
    event Surrender(uint256 indexed _gameId);
    event GettingDealerCards(uint256 indexed _gameId);

    constructor(
        address _forwarder,
        ITreasury _treasuryContract,
        address _vrfOracleContract,
        GameManagerConstructorArgs memory _gameManagerConstructorArgs
    )
        ERC2771Context(_forwarder)
        VRFManager(_vrfOracleContract)
        GameManager(_gameManagerConstructorArgs)
        TreasuryManager(_treasuryContract)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function startGame(uint256 _ante, address _token) public {

        require(active, "startGame: game not active");

        address sender = _msgSender();

        require(
            playerInGame[sender] == 0,
            "startGame: player already in game"
        );

        require(
            minimumAnte[_token] != 0 &&
            maximumAnte[_token] != 0,
            "startGame: token not approved for game"
        );

        require(
            _ante >= minimumAnte[_token] && _ante <= maximumAnte[_token],
            "startGame: ante not within the min/max"
        );

        gameCounter++;

        initializeGameData(gameCounter, sender, _token, _ante);

        // hold player funds
        holdFundsToStartGame(sender, _token, _ante);
        gameData[gameCounter].playerHold += _ante; 
        gameData[gameCounter].houseHold += (_ante * HOUSE_HOLD_MULTIPLIER);
        
        emit GameCreated(gameCounter, sender, _token, _ante);
        getInitialCards(gameCounter);
    }

    function getInitialCards(uint256 _gameCounter) private {

        require(
            gameData[_gameCounter].state == GameState.WAITING, 
            "getInitialCards: incorrect game state"
        );

        gameData[_gameCounter].state = GameState.GETTING_INITIAL_VRF;

        getShuffledCards(_gameCounter, 3);

    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) 
        internal
        override
    {
        uint256 gameNumber = gameByRequestId[_requestId];
        uint256 handPointer = gameData[gameNumber].playerHandPointer;
        
        require(gameNumber != 0, "fulfillRandomWords: request ID maps to an invalid game number");

        if(gameData[gameNumber].state == GameState.GETTING_INITIAL_VRF) {

            uint256[] memory dealtCards = dealCards(3, gameNumber, _randomWords, 0);
            // deal 1 card to the player
            assignNextPlayerCard(gameNumber, handPointer, dealtCards[0]);
            // deal 1 card to the dealer
            assignNextDealerCard(gameNumber, dealtCards[1]);
            // deal 1 card to the player
            assignNextPlayerCard(gameNumber, handPointer, dealtCards[2]);
            
            // check for blackjack
            (uint256 handValue, ) = getHandValue(gameData[gameNumber].playerDealtCards[0]);

            if(handValue == BLACK_JACK_VALUE) {

                gameData[gameNumber].winner[0] = Winner.PLAYER;

                uint256 playerHold = gameData[gameNumber].playerHold;
                uint256 houseHold = gameData[gameNumber].houseHold;
                uint256 playerPayout = gameData[gameNumber].ante * 2;
                uint256 housePayout = playerHold + houseHold - playerPayout;
   
                endGame(gameNumber, playerPayout, housePayout);

            }

            else{

                // change state to waiting on player decision
                gameData[gameNumber].state = GameState.WAITING_ON_PLAYER_DECISION;

            }
        }

        else if (gameData[gameNumber].state == GameState.GETTING_VRF_HIT) {

            uint256[] memory dealtCards = dealCards(1, gameNumber, _randomWords, 0);

            assignNextPlayerCard(gameNumber, handPointer, dealtCards[0]);

            // check for blackjack
            (uint256 handValue, ) = getHandValue(gameData[gameNumber].playerDealtCards[handPointer]);

            // check for bust or 21
            if(handValue >= BLACK_JACK_VALUE){
  
                if (handValue > BLACK_JACK_VALUE) {
                    gameData[gameNumber].winner[handPointer] = Winner.HOUSE;

                    if(handPointer + 1 == gameData[gameNumber].numberOfPlayerHands){

                        uint256 playerPayout = getBonusPayout(gameNumber, handPointer);

                        uint256 i;
                        bool goToDealer = false;

                        // checks all hands for bust, if all hands busted don't go to dealer
                        for(; i < handPointer;){

                            goToDealer = goToDealer || (gameData[gameNumber].winner[i] != Winner.HOUSE);
                            playerPayout += getBonusPayout(gameNumber, i);

                            unchecked {
                                ++i;
                            }
                        }

                        if(!goToDealer){
                            
                            uint256 housePayout = gameData[gameNumber].playerHold + gameData[gameNumber].houseHold - playerPayout;
                            endGame(gameNumber, playerPayout , housePayout);
                            return;
                            
                        }

                    }
                }

                if(handPointer + 1 < gameData[gameNumber].numberOfPlayerHands){ 
                    
                    uint256 i;

                    for(; i < gameData[gameNumber].numberOfPlayerHands - handPointer - 1;){ 

                        gameData[gameNumber].playerHandPointer++; 

                        (uint256 nextHandValue, ) = getHandValue(gameData[gameNumber].playerDealtCards[gameData[gameNumber].playerHandPointer]); //check this

                        if(nextHandValue < BLACK_JACK_VALUE) {
                            gameData[gameNumber].state = GameState.WAITING_ON_PLAYER_DECISION;
                            return;
                        }

                        unchecked {
                            ++i;
                        }
                    }
                   
                }

                callDealerCards(gameNumber);

            }
            else {
                gameData[gameNumber].state = GameState.WAITING_ON_PLAYER_DECISION;
            }
        }

        else if (gameData[gameNumber].state == GameState.GETTING_VRF_DOUBLE) {

            uint256[] memory dealtCards = dealCards(1, gameNumber, _randomWords, 0);

            assignNextPlayerCard(gameNumber, handPointer, dealtCards[0]);

            if(handPointer + 1 < gameData[gameNumber].numberOfPlayerHands){
    
                uint256 i;
                for(; i < gameData[gameNumber].numberOfPlayerHands - handPointer - 1;){

                    gameData[gameNumber].playerHandPointer++;

                    (uint256 nextHandValue,) = getHandValue(gameData[gameNumber].playerDealtCards[gameData[gameNumber].playerHandPointer]);

                    if(nextHandValue < BLACK_JACK_VALUE) {
                        gameData[gameNumber].state = GameState.WAITING_ON_PLAYER_DECISION;
                        return;
                    }

                    unchecked {
                        ++i;
                    }

                }
            }

            callDealerCards(gameNumber);
        }

        else if (gameData[gameNumber].state == GameState.GETTING_VRF_SPLIT) {
            uint256[] memory dealtCards = dealCards(2, gameNumber, _randomWords, 0);

            uint256 splitHandPointer = gameData[gameNumber].numberOfPlayerHands - 1;
            
            assignNextPlayerCard(gameNumber, handPointer, dealtCards[0]);
            assignNextPlayerCard(gameNumber, splitHandPointer, dealtCards[1]);

            (uint256 handValue, ) = getHandValue(gameData[gameNumber].playerDealtCards[handPointer]);

            // check for 21
            if(handValue == BLACK_JACK_VALUE){
                // if hand pointer is less than number of hands, increment hand pointer

                if(handPointer + 1 < gameData[gameNumber].numberOfPlayerHands){

                    uint256 i;
                    
                    for(; i < gameData[gameNumber].numberOfPlayerHands - handPointer - 1;){

                        gameData[gameNumber].playerHandPointer++;

                        (uint256 nextHandValue, ) = getHandValue(gameData[gameNumber].playerDealtCards[gameData[gameNumber].playerHandPointer]);

                        if(nextHandValue < BLACK_JACK_VALUE) {
                            gameData[gameNumber].state = GameState.WAITING_ON_PLAYER_DECISION;
                            return;
                        }

                        unchecked {
                            ++i;
                        }
                    } 
                }

                callDealerCards(gameNumber);
            }
            else {
                gameData[gameNumber].state = GameState.WAITING_ON_PLAYER_DECISION;
            }
        }

        if (gameData[gameNumber].state == GameState.GETTING_VRF_DEALER){

            uint256 playerPayout;
           
            uint256[] memory dealtCards = dealCards(16, gameNumber, _randomWords, _randomWords.length - 16);
           
            uint256 dealerHandValue;
            bool soft;
            uint256 i;
        
            while(dealerHandValue < 17 || (dealerHandValue == 17 && soft)) {
                
                assignNextDealerCard(gameNumber, dealtCards[i]);

                (dealerHandValue, soft) = getHandValue(gameData[gameNumber].dealerCards);

                unchecked {
                    ++i;
                }
                
            }

            delete i;
            uint256 playerHandValue; 

            for(; i < gameData[gameNumber].numberOfPlayerHands;) {

                (playerHandValue,) = getHandValue(gameData[gameNumber].playerDealtCards[i]);

                // add 3 unsuited bonus to all outcomes
                playerPayout += getBonusPayout(gameNumber, i);

                // determine payout per hand
                if(dealerHandValue == BLACK_JACK_VALUE && gameData[gameNumber].dealerCards.length == 2){
                    // dealer has blackjack
                    // check for double, return double wager
                    if(gameData[gameNumber].doubleDownHand[i]){
                        playerPayout += gameData[gameNumber].ante;
                    }

                    gameData[gameNumber].winner[i] = Winner.HOUSE;
                }
                else if(dealerHandValue == playerHandValue){
                    // push
                    // check for double
                    if(gameData[gameNumber].doubleDownHand[i]){
                        playerPayout += gameData[gameNumber].ante * 2;
                    }
                    else{
                        playerPayout += gameData[gameNumber].ante;
                    }
                    
                    gameData[gameNumber].winner[i] = Winner.PUSH;
                }
                else if((playerHandValue > dealerHandValue || dealerHandValue > BLACK_JACK_VALUE) && playerHandValue <= BLACK_JACK_VALUE){
                    // player wins
                    // check for double down
                    if(gameData[gameNumber].doubleDownHand[i]){
                        playerPayout += gameData[gameNumber].ante * 4;
                    }
                    else{
                        if(gameData[gameNumber].playerDealtCards[i].length >= 5 && playerHandValue == BLACK_JACK_VALUE){
                            playerPayout += (gameData[gameNumber].ante * 5)/2;
                        }
                        else{
                            playerPayout += gameData[gameNumber].ante * 2;
                        }
                    }

                    gameData[gameNumber].winner[i] = Winner.PLAYER;
                }
                else if(dealerHandValue > playerHandValue && dealerHandValue <= BLACK_JACK_VALUE){ 
                    // dealer wins
                    gameData[gameNumber].winner[i] = Winner.HOUSE;
                }

                unchecked {
                    ++i;
                }
            }
            
            // find difference between holds (player + house) and payouts, assign to house 
            uint256 housePayout = gameData[gameNumber].playerHold + gameData[gameNumber].houseHold - playerPayout;

            endGame(gameNumber, playerPayout, housePayout);

        }
    }

    function hit() public {

        address sender = _msgSender();

        uint256 gameNumber = playerInGame[sender];
        uint256 handPointer = gameData[gameNumber].playerHandPointer;

        require(gameNumber != 0, "hit: player not in game");

        require(
            gameData[gameNumber].state == GameState.WAITING_ON_PLAYER_DECISION, 
            "hit: incorrect game state"
        );

        if(
            gameData[gameNumber].numberOfPlayerHands > 1 &&
            gameData[gameNumber].playerDealtCards[handPointer].length == 2
        ) {
            require(
                gameData[gameNumber].playerDealtCards[handPointer][0].number != 0,
                "hit: cannot hit on split aces"
            );
        }

        gameData[gameNumber].state = GameState.GETTING_VRF_HIT;

        emit Hit(gameNumber);

        (uint256 handValue, ) = getHandValue(gameData[gameNumber].playerDealtCards[handPointer]);

        if((gameData[gameNumber].playerHandPointer + 1 == gameData[gameNumber].numberOfPlayerHands) && handValue > 9){
            getShuffledCards(gameNumber, 17);
        }

        else if(handPointer + 1 < gameData[gameNumber].numberOfPlayerHands){ 
                            
            uint256 i;
            bool needsDealerCards = true;

            for(; i < gameData[gameNumber].numberOfPlayerHands - handPointer - 1;){ 

                handPointer++; 

                (uint256 nextHandValue, ) = getHandValue(gameData[gameNumber].playerDealtCards[handPointer]);

                needsDealerCards =  needsDealerCards && (nextHandValue == BLACK_JACK_VALUE && handValue > 9);

                unchecked {
                    ++i;
                }
            }

            if(needsDealerCards){
                getShuffledCards(gameNumber, 17);
            }
            else {
                getShuffledCards(gameNumber, 1);
            }
        
        }

        else {
            getShuffledCards(gameNumber, 1);
        }
    }

    function doubleDown() public {

        address sender = _msgSender();

        uint256 gameNumber = playerInGame[sender];
        uint256 handPointer = gameData[gameNumber].playerHandPointer;

        require(gameNumber != 0, "doubleDown: player not in game");

        require(
            gameData[gameNumber].state == GameState.WAITING_ON_PLAYER_DECISION, 
            "doubleDown: incorrect game state"
        );

        require (
            gameData[gameNumber].playerDealtCards[handPointer].length == 2 ||
            gameData[gameNumber].playerDealtCards[handPointer].length == 3,
            "doubleDown: too many cards to double down"
        );

        if(gameData[gameNumber].playerDealtCards[handPointer].length == 3){
           
            uint256 handValue;
            uint256 i;
            for(; i < 3;){

                handValue += cardValueMap[gameData[gameNumber].playerDealtCards[handPointer][i].number];

                unchecked {
                    ++i;
                }
            }
            require(
                handValue == 9 ||
                handValue == 10 ||
                handValue == 11, 
                "doubleDown: must have hand value of 9, 10, or 11 to double down with three cards"
            );
        }

        // hold additional player funds on treasury
        holdPlayerFunds(sender, gameData[gameNumber].anteToken, gameData[gameNumber].ante);
        // increment hold in game struct
        gameData[gameNumber].playerHold += gameData[gameNumber].ante;

        gameData[gameNumber].doubleDownHand[handPointer] = true;

        gameData[gameNumber].state = GameState.GETTING_VRF_DOUBLE;

        emit DoubleDown(gameNumber);

        if(gameData[gameNumber].numberOfPlayerHands == gameData[gameNumber].playerHandPointer + 1){
            getShuffledCards(gameNumber, 17);
        }

        else if(handPointer + 1 < gameData[gameNumber].numberOfPlayerHands){ 
                            
            uint256 i;
            bool needsDealerCards = true;

            for(; i < gameData[gameNumber].numberOfPlayerHands - handPointer - 1;){ 

                handPointer++; 

                (uint256 nextHandValue, ) = getHandValue(gameData[gameNumber].playerDealtCards[handPointer]); //check this

                needsDealerCards =  needsDealerCards && (nextHandValue == BLACK_JACK_VALUE);

                unchecked {
                    ++i;
                }
            }

            if(needsDealerCards){
                getShuffledCards(gameNumber, 17);
            }

            else {
                getShuffledCards(gameNumber, 1);
            }
        }
        else {
            getShuffledCards(gameNumber, 1);
        }

    }

    function split() public {

        address sender = _msgSender();

        uint256 gameNumber = playerInGame[sender];
        uint256 handPointer = gameData[gameNumber].playerHandPointer;
        GameData storage game = gameData[gameNumber];

        require(gameNumber != 0, "split: player not in game");

        require(
            gameData[gameNumber].state == GameState.WAITING_ON_PLAYER_DECISION, 
            "split: incorrect game state"
        );

        require(
            gameData[gameNumber].numberOfPlayerHands < MAX_NUMBER_OF_HANDS,
            "split: cannot split more than MAX_NUMBER_OF_HANDS"
        );

        require(
            gameData[gameNumber].playerDealtCards[handPointer].length == MAX_NUMBER_OF_CARDS_BEFORE_SPLIT, 
            "split: can only split with two cards in hand"
        );

        require(
            cardValueMap[gameData[gameNumber].playerDealtCards[handPointer][0].number] == 
            cardValueMap[gameData[gameNumber].playerDealtCards[handPointer][1].number],
            "split: cards must be of same value to split"
        );

        // hold additional player funds on treasury
        holdPlayerFunds(sender, gameData[gameNumber].anteToken, gameData[gameNumber].ante);
        // increment hold in game struct
        gameData[gameNumber].playerHold += gameData[gameNumber].ante;

        gameData[gameNumber].numberOfPlayerHands++;
        
        game.playerDealtCards[gameData[gameNumber].numberOfPlayerHands - 1].push(gameData[gameNumber].playerDealtCards[handPointer][1]); 
        
        gameData[gameNumber].playerDealtCards[handPointer].pop(); 

        gameData[gameNumber].doubleDownHand.push(false);
        gameData[gameNumber].winner.push(Winner.NOT_SET);

        gameData[gameNumber].state = GameState.GETTING_VRF_SPLIT;

        emit Split(gameNumber);

        getShuffledCards(gameNumber, 18);

    }

    function stay() public {

        address sender = _msgSender();

        uint256 gameNumber = playerInGame[sender];
        uint256 handPointer = gameData[gameNumber].playerHandPointer;

        require(gameNumber != 0, "hit: player not in game");

        require(
            gameData[gameNumber].state == GameState.WAITING_ON_PLAYER_DECISION, 
            "hit: incorrect game state"
        );

        // if there is another hand from a split, check if its a winner 
        if(handPointer + 1 < gameData[gameNumber].numberOfPlayerHands){
    
            uint256 i;
            for(; i < gameData[gameNumber].numberOfPlayerHands - handPointer - 1;){

                gameData[gameNumber].playerHandPointer++;

                (uint256 nextHandValue, ) = getHandValue(gameData[gameNumber].playerDealtCards[gameData[gameNumber].playerHandPointer]);

                if(nextHandValue < BLACK_JACK_VALUE) {
                    gameData[gameNumber].state = GameState.WAITING_ON_PLAYER_DECISION;
                    return;
                }

                unchecked {
                    ++i;
                }

            }
        }

        emit Stay(gameNumber);

        callDealerCards(gameNumber);
        getShuffledCards(gameNumber, 16);
    }

    function surrender() public {

        address sender = _msgSender();

        uint256 gameNumber = playerInGame[sender];

        require(gameNumber != 0, "surrender: player not in game");

        require(
            gameData[gameNumber].state == GameState.WAITING_ON_PLAYER_DECISION, 
            "surrender: incorrect game state"
        );

        require(gameData[gameNumber].numberOfPlayerHands == 1, "surrender: cannot surrender if player has more than 1 hand");
        require(gameData[gameNumber].playerDealtCards[0].length == 2, "surrender: cannot surrender if player has more than 2 cards");
        require(gameData[gameNumber].dealerCards[0].number != 0, "surrender: cannot surrender if dealer is showing an ace");

        gameData[gameNumber].winner[0] = Winner.SURRENDER;

        uint256 playerPayout = gameData[gameNumber].ante / 2;
        uint256 housePayout = gameData[gameNumber].playerHold + gameData[gameNumber].houseHold - playerPayout;

        emit Surrender(gameNumber);
        
        endGame(gameNumber, playerPayout, housePayout);

    }

    function getHandValue(Card[] memory _cards) public view returns (uint256, bool) {
        uint256 cardTotal;
        uint256 i;
        uint256 numberOfAces;
        bool soft;

        for(; i < _cards.length;){

            uint256 cardValue = cardValueMap[_cards[i].number];

            if(cardValue == 1) {
                numberOfAces++;
            }
            else {
                cardTotal += cardValue;
            }
            
            unchecked {
                ++i;
            }
        }

        delete i;

        for(; i < numberOfAces;){

            if(cardTotal + 11 > BLACK_JACK_VALUE)
                cardTotal += 1;
            else{
                if(i == numberOfAces -1){
                    soft = true;
                    cardTotal += 11;
                }
                else{
                    cardTotal += 1;
                }
                
            }
           
            unchecked {
                ++i;
            }
        }

        return (cardTotal, soft);
    }

    function assignNextPlayerCard(uint256 _gameNumber, uint256 _handPointer, uint256 _dealtCard) private {

        uint256 suit = (_dealtCard % 52) / 13;
        uint256 number = _dealtCard % 13;

        GameData storage game = gameData[_gameNumber];

        game.playerDealtCards[_handPointer].push(Card({
            suit: suit,
            number: number     
        }));
    }

    function assignNextDealerCard(uint256 _gameNumber, uint256 _dealtCard) private {

        uint256 suit = (_dealtCard % 52) / 13;
        uint256 number = _dealtCard % 13;

        GameData storage game = gameData[_gameNumber];

        game.dealerCards.push(Card({
            suit: suit,
            number: number     
        }));
    }

    function callDealerCards(uint256 _gameNumber) private {
        gameData[_gameNumber].state = GameState.GETTING_VRF_DEALER;
    }

    function getBonusPayout(uint256 _gameNumber, uint256 _handIndex) private view returns (uint256) {

        uint256[] memory cardCounter = new uint256[](13);
        uint256 j;
        bool bonusAwarded;
        uint256 bonusPayout;
        for(; j < gameData[_gameNumber].playerDealtCards[_handIndex].length && !bonusAwarded;) {

            cardCounter[gameData[_gameNumber].playerDealtCards[_handIndex][j].number] += 1;

            if(cardCounter[gameData[_gameNumber].playerDealtCards[_handIndex][j].number] == 3) {
                bonusPayout += gameData[_gameNumber].ante * 2;
                bonusAwarded = true;
            }

            unchecked {
                ++j;
            }
        }

        return bonusPayout;

    }

    function endGame(uint256 _gameNumber, uint256 _playerPayout, uint256 _housePayout) private {

        gameData[_gameNumber].state = GameState.COMPLETED;

        singlePlayerPayout(
            SinglePlayerPayoutArgs({
                _player: gameData[_gameNumber].player,
                _tokenContract: gameData[_gameNumber].anteToken,
                _playerReleaseAmount: gameData[_gameNumber].playerHold,
                _houseReleaseAmount: gameData[_gameNumber].houseHold,
                _playerPayout: _playerPayout,
                _housePayout: _housePayout
            })
        );

        delete playerInGame[gameData[_gameNumber].player];
        emit GameCompleted(_gameNumber, gameData[_gameNumber].winner);
    }

    function dealCards(
        uint256 _numberOfCards,
        uint256 _gameId,
        uint256[] memory _randomWords,
        uint256 _randomWordsStartingIndex
    ) 
        private 
        returns (uint256[] memory)
    {
        GameData storage g = gameData[_gameId];
        uint256 startingIndex = g.drawIndex;
        uint256 cardsRemaining = numberOfCards - startingIndex;
        uint256[] memory dealtCards = new uint256 [](_numberOfCards);

        for (; g.drawIndex < startingIndex + _numberOfCards; ) {
            uint256 randomNum = _randomWords[g.drawIndex - startingIndex + _randomWordsStartingIndex] %
                cardsRemaining;

            uint256 index = g.deckCache[randomNum] == 0
                ? randomNum
                : g.deckCache[randomNum];

            g.deckCache[randomNum] = g.deckCache[cardsRemaining - 1] == 0
                ? cardsRemaining - 1
                : g.deckCache[cardsRemaining - 1];

            // g.dealtCards[g.drawIndex] = index;
            dealtCards[g.drawIndex - startingIndex] = index;

            unchecked {
                --cardsRemaining;
                ++g.drawIndex;
            }
        }

        return dealtCards;
    }

    function getShuffledCards(uint256 _gameNumber, uint32 _numberOfCards) private {

        uint256 requestId = IOracle(VRFOracleContract).requestRandomWords(_numberOfCards);
        
        // switch back to requestId
        gameByRequestId[requestId] = _gameNumber;

        // push the request ID into the game data
        gameData[_gameNumber].requestId.push(requestId);

    }

    function setMinimumAnte(address _token, uint256 _minimumAnte) public override onlyRole(GAME_MANAGER){
        super.setMinimumAnte(_token, _minimumAnte);
    }

    function setMaximumAnte(address _token, uint256 _maximumAnte) public override onlyRole(GAME_MANAGER){
        super.setMaximumAnte(_token, _maximumAnte);
    }

    function setTimeout(uint256 _timeout) public override onlyRole(GAME_MANAGER){
        super.setTimeout(_timeout);
    }

    function toggleActive() public override onlyRole(GAME_MANAGER){
        super.toggleActive();
    }

    function removePlayerFromGame(address _player) public override onlyRole(GAME_MANAGER) {

        uint256 gameId = playerInGame[_player];

        require(gameId != 0, "removePlayerInGame: player not in game");
        
        refund(_player, gameData[gameId].anteToken, gameData[gameId].playerHold, gameData[gameId].houseHold);

        super.removePlayerFromGame(_player);

        gameData[gameId].state = GameState.REVOKED;
        
    }

    function _msgSender()
        internal
        view
        override(ERC2771Context, Context)
        returns (address sender)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        override(ERC2771Context, Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

abstract contract ITreasury {
    mapping(address => mapping(address => uint256)) public playerBalances;
    mapping(address => mapping(address => uint256)) public playerHolds;
    mapping(address => uint256) public houseBalances;
    mapping(address => uint256) public houseHolds;

    function creditPlayerBalance(
        address _player,
        address _tokenContract,
        uint256 _amount
    ) external virtual;

    function debitPlayerBalance(
        address _player,
        address _tokenContract,
        uint256 _amount
    ) external virtual;

    function creditPlayerHold(
        address _player,
        address _tokenContract,
        uint256 _amount
    ) external virtual;

    function debitPlayerHold(
        address _player,
        address _tokenContract,
        uint256 _amount
    ) external virtual;

    function creditHouseBalance(address _tokenContract, uint256 _amount)
        external
        virtual;

    function debitHouseBalance(address _tokenContract, uint256 _amount)
        external
        virtual;

    function creditHouseHold(address _tokenContract, uint256 _amount)
        external
        virtual;

    function debitHouseHold(address _tokenContract, uint256 _amount)
        external
        virtual;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IOracle {

    function requestRandomWords(uint256 _numberOfWords) external returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IConsumer {

    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./interfaces/IOracle.sol";
import "./interfaces/IConsumer.sol";

contract VRFManager is IConsumer {

    address public VRFOracleContract;

    constructor(address _VRFOracleContract){
        VRFOracleContract = _VRFOracleContract; 
    }

    function updateOracleContract(address _VRFOracleContract) external virtual {
        VRFOracleContract = _VRFOracleContract;
    }

    function fulfillRandomWords(uint256, uint256[] memory)
        internal
        virtual
    {}

    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        
        require(msg.sender == VRFOracleContract, "rawFulfillRandomWords: only oracle can fulfill random words");

        fulfillRandomWords(requestId, randomWords);

    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./interfaces/ITreasury.sol";

struct SinglePlayerPayoutArgs {
    address _player;
    address _tokenContract;
    uint256 _playerReleaseAmount;
    uint256 _houseReleaseAmount;
    uint256 _playerPayout;
    uint256 _housePayout;
}

contract TreasuryManager {
    ITreasury public treasuryContract;

    uint256 public constant HOUSE_HOLD_MULTIPLIER = 32;

    constructor(ITreasury _treasuryContract) {
        treasuryContract = _treasuryContract;
    }

    function holdFundsToStartGame(
        address _sender,
        address _token,
        uint256 _ante
    ) internal {
        holdPlayerFunds(_sender, _token, _ante);
        holdHouseFunds(_token, _ante * HOUSE_HOLD_MULTIPLIER);
    }

    function holdPlayerFunds(
        address _sender,
        address _token,
        uint256 _ante
    ) internal {
        treasuryContract.debitPlayerBalance(_sender, _token, _ante);
        treasuryContract.creditPlayerHold(_sender, _token, _ante);
    }

    function holdHouseFunds(address _token, uint256 _amount) internal {
        treasuryContract.debitHouseBalance(_token, _amount);
        treasuryContract.creditHouseHold(_token, _amount);
    }

    function refund(
        address _player,
        address _tokenContract,
        uint256 _playerAmount,
        uint256 _houseAmount
    ) internal {
        treasuryContract.debitHouseHold(_tokenContract, _houseAmount);
        treasuryContract.creditHouseBalance(_tokenContract, _houseAmount);
        treasuryContract.debitPlayerHold(
            _player,
            _tokenContract,
            _playerAmount
        );
        treasuryContract.creditPlayerBalance(
            _player,
            _tokenContract,
            _playerAmount
        );
    }

    function singlePlayerPayout(
        SinglePlayerPayoutArgs memory _singlePlayerPayoutArgs
    ) internal {
        require(
            treasuryContract.houseHolds(
                _singlePlayerPayoutArgs._tokenContract
            ) >= _singlePlayerPayoutArgs._houseReleaseAmount,
            "payout: insufficient house hold"
        );

        require(
            _singlePlayerPayoutArgs._houseReleaseAmount != 0,
            "payout: house release amount must be greater than zero"
        );

        treasuryContract.debitHouseHold(
            _singlePlayerPayoutArgs._tokenContract,
            _singlePlayerPayoutArgs._houseReleaseAmount
        );
        treasuryContract.creditHouseBalance(
            _singlePlayerPayoutArgs._tokenContract,
            _singlePlayerPayoutArgs._housePayout
        );

        uint256 totalReleased = _singlePlayerPayoutArgs._houseReleaseAmount +
            _singlePlayerPayoutArgs._playerReleaseAmount;
        uint256 totalPayout = _singlePlayerPayoutArgs._housePayout +
            _singlePlayerPayoutArgs._playerPayout;

        require(
            treasuryContract.playerHolds(
                _singlePlayerPayoutArgs._player,
                _singlePlayerPayoutArgs._tokenContract
            ) >= _singlePlayerPayoutArgs._playerReleaseAmount,
            "payout: insufficient player hold"
        );

        require(
            _singlePlayerPayoutArgs._playerReleaseAmount != 0,
            "payout: player release amount must be greater than zero"
        );

        treasuryContract.debitPlayerHold(
            _singlePlayerPayoutArgs._player,
            _singlePlayerPayoutArgs._tokenContract,
            _singlePlayerPayoutArgs._playerReleaseAmount
        );
        treasuryContract.creditPlayerBalance(
            _singlePlayerPayoutArgs._player,
            _singlePlayerPayoutArgs._tokenContract,
            _singlePlayerPayoutArgs._playerPayout
        );

        require(
            totalPayout == totalReleased,
            "payout: held funds do not match payouts"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

struct GameData {
    GameState state;
    uint256 gameStarted;
    address player;
    uint256 ante;
    address anteToken;
    uint256 timeout;
    uint256 drawIndex;
    mapping(uint256 => uint256) deckCache;
    mapping(uint256 => Card[]) playerDealtCards;
    uint256 numberOfPlayerHands;
    uint256 playerHandPointer;
    bool[] doubleDownHand;
    Card[] dealerCards;
    Winner[] winner;
    uint256[] requestId;
    uint256 playerHold;
    uint256 houseHold;
}

enum GameState {
    WAITING,
    GETTING_INITIAL_VRF,
    WAITING_ON_PLAYER_DECISION,
    GETTING_VRF_HIT,
    GETTING_VRF_DOUBLE,
    GETTING_VRF_SPLIT,
    GETTING_VRF_DEALER,
    COMPLETED,
    REVOKED
}

enum Winner {
    NOT_SET,
    PLAYER,
    HOUSE,
    SURRENDER,
    PUSH
}

struct Card {
    uint256 suit;
    uint256 number;
}

struct GameManagerConstructorArgs {
    uint256[] minimumAnte;
    uint256[] maximumAnte;
    address[] approvedTokens;
    uint256 timeout;
    bool active;
}

contract GameManager {

    uint256 public constant MAX_NUMBER_OF_HANDS = 4;
    uint256 public constant MAX_NUMBER_OF_CARDS_BEFORE_SPLIT = 2;
    uint256 public constant BLACK_JACK_VALUE = 21;

    mapping(address => uint256) public minimumAnte;
    mapping(address => uint256) public maximumAnte;
    uint256 public timeout;
    bool public active;

    uint256 public gameCounter;
    mapping(uint256 => GameData) public gameData;
    mapping(address => uint256) public playerInGame;
    uint256 public numberOfCards;
    mapping(uint256 => uint256) public cardValueMap;

    event MinimumAnteUpdated(uint256 _minimumAnte);
    event MaximumAnteUpdated(uint256 _maximumAnte);
    event TimeoutUpdated(uint256 _timeout);
    event ActiveToggled(bool _active);

    constructor(GameManagerConstructorArgs memory _gameManagerConstructorArgs){

        uint256 expectedLength = _gameManagerConstructorArgs.approvedTokens.length;


        require(
            _gameManagerConstructorArgs.minimumAnte.length == expectedLength && 
            _gameManagerConstructorArgs.maximumAnte.length == expectedLength,
            "GameManager: minimum and maximum ante arrays must match token contract array"
        );

        uint256 i;
        for(; i < expectedLength;){
            
            minimumAnte[_gameManagerConstructorArgs.approvedTokens[i]] = _gameManagerConstructorArgs.minimumAnte[i];
            maximumAnte[_gameManagerConstructorArgs.approvedTokens[i]] = _gameManagerConstructorArgs.maximumAnte[i];
            
            unchecked {
                i++;
            }
        }

        timeout = _gameManagerConstructorArgs.timeout;
        active = _gameManagerConstructorArgs.active;
        numberOfCards = 208;

        cardValueMap[0] = 1;
        cardValueMap[1] = 2;
        cardValueMap[2] = 3;
        cardValueMap[3] = 4;
        cardValueMap[4] = 5;
        cardValueMap[5] = 6;
        cardValueMap[6] = 7;
        cardValueMap[7] = 8;
        cardValueMap[8] = 9;
        cardValueMap[9] = 10;
        cardValueMap[10] = 10;
        cardValueMap[11] = 10;
        cardValueMap[12] = 10;
        
    }

    function getWinners(uint256 _gameId) public view returns (Winner[] memory) {
        return gameData[_gameId].winner;
    }

     function getRequestIdsByGame(uint256 _gameId) public view returns (uint256[] memory) {
        return gameData[_gameId].requestId;
    }

    function getDoubleDownHand(uint256 _gameId) public view returns (bool[] memory) {
        return gameData[_gameId].doubleDownHand;
    }

    function getDealerCards(uint256 _gameId) public view returns (Card[] memory) {
        return gameData[_gameId].dealerCards;
    }

    function getPlayerDealtCards(uint256 _gameId, uint256 _handPointer) public view returns (Card[] memory) {
        return gameData[_gameId].playerDealtCards[_handPointer];
    }

    function setMinimumAnte(address _token, uint256 _minimumAnte) public virtual {
        minimumAnte[_token] = _minimumAnte;
        emit MinimumAnteUpdated(_minimumAnte);
    }

    function setMaximumAnte(address _token, uint256 _maximumAnte) public virtual {
        maximumAnte[_token] = _maximumAnte;
        emit MaximumAnteUpdated(_maximumAnte);
    }

    function setTimeout(uint256 _timeout) public virtual {
        timeout = _timeout;
        emit TimeoutUpdated(timeout);
    }

    function removePlayerFromGame(address _player) public virtual {
        delete playerInGame[_player];
    }

    function toggleActive() public virtual {
        active = !active;
        emit ActiveToggled(active);
    }

    function initializeGameData(
        uint256 _gameCounter,
        address _player,
        address _anteToken,
        uint256 _ante
    ) 
        internal 
    {

        GameData storage g = gameData[_gameCounter];
        g.gameStarted = block.timestamp;
        g.player = _player;
        g.ante = _ante;
        g.anteToken = _anteToken;
        g.timeout = timeout;
        g.numberOfPlayerHands = 1;
        g.playerHandPointer = 0;
        g.winner.push(Winner.NOT_SET);
        g.doubleDownHand.push(false);
        playerInGame[_player] = _gameCounter;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}