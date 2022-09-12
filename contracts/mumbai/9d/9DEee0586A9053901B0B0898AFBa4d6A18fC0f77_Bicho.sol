// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface BichoInterface {
    function ReceiveSortedResults(
        uint256 drawID,
        uint256[] memory randomWords,
        uint256 timestamp
    ) external;
    function AlreadyHaveBets() external view returns ( bool );
}

contract Bicho {
    event KeeperChanged(address oldKeeper, address newKeeper);
    event OwnerChanged(address oldOwner, address newOwner);
    event FeeChanged(uint256 ticketValue, uint256 newFee);
    event MaxBetsPerUserChanged(uint256 oldMaxBetsPerUser, uint256 newMaxBetsPerUser);
    event WithdrawThresholdChanged(uint256 oldThreshold, uint256 newThreshold);
    event GameStateChanged(GameState current);
    event WithdrawFromBichos(address player,uint256 amount,uint256 gameID);

    event NewBets(
        address sender,
        uint256 gameID,
        uint256[] betID,
        BetType[] betType,
        uint32[][] values,
        uint256[] quantity
    );

    event NewBet(
        address sender,
        uint256 gameID,
        uint256 betID,
        BetType betType,
        uint32[] values,
        uint256 quantity
    );


    event ResultsReceived(
        address[] playersFromRound,
        uint256[] results,
        uint256 drawID,
        uint256 gameID,
        uint256 withdrawThreshold,
        uint256 timestamp
    );

    enum BetType {
        SecoGrupo,
        CercadoGrupo
    }

    enum GameState {
        OPEN,
        CLOSED
    }

    mapping(BetType => uint256) public BetValues;

    struct Bet {
        uint256 betID;
        BetType betType;
        uint32[] values;
        uint256 quantity;
    }

    struct Bets {
        address better;
        uint256 quantity;
        Bet[] bets;
        bool retrieved;
    }

    struct Result {
        uint256 drawID;
        uint256[] randomWords;
        uint256 timestamp;
    }

    uint256 public currentGameID;
    uint256 public counter;
    address public s_owner;

    address public keeper;

    uint256 maxBetsPerUser = 100;
    uint256 withdrawThreshold = 7 days; // 1 week

    GameState currentGameState;
    uint256 ticketValue = 5 * 10**15;

    mapping(address => Bets) bets;

    address[] players;
    mapping(uint256 => mapping(address => Bets)) public pastGames;
    mapping(uint256 => Result) public pastResults;

    // Constructor
    constructor() {
        counter = 0;
        s_owner = msg.sender;
        currentGameID = 1;
        BetValues[BetType.SecoGrupo] = 18;
        BetValues[BetType.CercadoGrupo] = 18;
    }

    // Multiples Bets
    function newBets(
        BetType[] calldata betTypes,
        uint32[][] calldata values,
        uint256[] calldata quantity
    ) public payable {
        require(currentGameState != GameState.CLOSED, "game state is closed");
        uint256 previousCounter = counter;
        uint256 newcounter = counter + betTypes.length;
        uint256 sum = 0;

        Bets storage betsHere = bets[msg.sender];
        if (betsHere.bets.length == 0) {
            betsHere.better = msg.sender;
            betsHere.quantity = 0;
            players.push(msg.sender);
        }

        for (uint256 index = 0; index < betTypes.length; index++) {
            sum += quantity[index];
        }

        require(
            sum + betsHere.quantity <= maxBetsPerUser,
            "user can't have more bets than the maximum allowed"
        );

        // preço pago pelos tickets.
        require( ( sum * ticketValue ) == msg.value, "wrong value for tickets fee");

        previousCounter = counter;
        counter += betTypes.length;
        uint256[] memory betIDs = new uint256[](newcounter - previousCounter);
        for (uint256 index = 0; index < betTypes.length; index++) {
            uint256 newID = previousCounter + index;
            betIDs[index] = newID;
            betsHere.bets[betsHere.bets.length + index] = Bet(
                newID,
                betTypes[index],
                values[index],
                quantity[index]
            );
        }

        counter += betTypes.length;
        bets[msg.sender] = betsHere;

        emit NewBets(msg.sender, currentGameID, betIDs, betTypes, values, quantity);
    }

    // Sinlge BET
    function newBet(
        BetType betType,
        uint32[] calldata values,
        uint256 quantity
    ) public payable {
        require(currentGameState != GameState.CLOSED, "game state is closed");
        uint256 previousCounter = counter;
        uint256 newcounter = counter + 1;

        Bets storage betsHere = bets[msg.sender];
        if (betsHere.bets.length == 0) {
            betsHere.better = msg.sender;
            betsHere.quantity = 0;
            players.push(msg.sender);
        }

        require(
            quantity + betsHere.quantity <= maxBetsPerUser,
            "user can't have more bets than the maximum allowed"
        );

        require( ( quantity * ticketValue ) <= msg.value, "wrong value for tickets fee");

        counter += 1;
        uint256 betID = counter;
        betsHere.bets[betsHere.bets.length ] = Bet(
            betID,
            betType,
            values,
            quantity
        );
    

        counter++;
        bets[msg.sender] = betsHere;

        emit NewBet(msg.sender, currentGameID, betID, betType, values, quantity);
    }

    function AlreadyHaveBets() external view returns ( bool ){
        for (uint256 index = 0; index < players.length; index++) {
            if ( bets[players[index]].bets.length > 0 ) {
                return true;
            }
        }
        return false;
    }

    function ReceiveSortedResults(
        uint256 drawID,
        uint256[] memory randomWords,
        uint256 timestamp
    ) external {
        require(msg.sender == keeper || msg.sender == s_owner, "sender must be keeper or owner");
        closeGameState();
        emit ResultsReceived(
            players,
            randomWords,
            drawID,
            currentGameID,
            withdrawThreshold,
            timestamp
        );
        pastResults[currentGameID] = Result(drawID, randomWords, timestamp);
        for (uint256 index = 0; index < players.length; index++) {
            pastGames[currentGameID][players[index]] = bets[players[index]];
            delete bets[players[index]];
        }
        currentGameID++;
        delete players;
    }

    function withdraw(uint256 gameID) public {
        require(
            pastGames[gameID][msg.sender].bets.length > 0,
            "user needs to have played so it can whitdraw"
        );
        require(pastGames[gameID][msg.sender].retrieved = false, "user already retrieved prize");

        uint256 sum = 0;
        Bet[] memory betsWithdraw = pastGames[gameID][msg.sender].bets;

        uint256[] memory drawnAnimals;

        // get the tens for the drawn result with VRF
        for (uint256 index = 0; index < pastResults[gameID].randomWords.length; index++) {
            drawnAnimals[index] = ((pastResults[gameID].randomWords[index] % 100) / 4) + 1;
        }

        for (uint256 index = 0; index < betsWithdraw.length; index++) {
            // LOGIC GRUPO SECO
            if (betsWithdraw[index].betType == BetType.SecoGrupo) {
                if (drawnAnimals[0] == betsWithdraw[index].values[0]) {
                    sum += BetValues[BetType.SecoGrupo];
                }
                // LOGIC GRUPO CERCADO
            } else if (betsWithdraw[index].betType == BetType.CercadoGrupo) {
                for (uint256 indexB = 0; indexB < drawnAnimals.length; indexB++) {
                    if (drawnAnimals[indexB] == betsWithdraw[index].values[0]) {
                        sum += BetValues[BetType.CercadoGrupo];
                        break;
                    }
                }
            }
        }
        pastGames[gameID][msg.sender].retrieved = true;
        require(sum > 0, "nothing to withdraw");

        sum = sum * ticketValue;

        require(address(this).balance >= sum,"not enough balance to withdraw");

        payable(msg.sender).transfer(sum);

        emit WithdrawFromBichos(msg.sender,sum,gameID);
        // procurar no google como enviar o montando para o cara la, é 0.005 * o somatorio que temos.
    }

    function openGameState() public {
        emit GameStateChanged(GameState.OPEN);
        currentGameState = GameState.OPEN;
    }

    function closeGameState() public {
        emit GameStateChanged(GameState.CLOSED);
        currentGameState = GameState.CLOSED;
    }

    function setMaxBetsPerUserChanged(uint256 _newMaxBetsPerUser) public onlyOwner {
        emit MaxBetsPerUserChanged(maxBetsPerUser, _newMaxBetsPerUser);
        maxBetsPerUser = _newMaxBetsPerUser;
    }

    function setWithdrawThreshold(uint256 _newThreshold) public onlyOwner {
        emit WithdrawThresholdChanged(withdrawThreshold, _newThreshold);
        withdrawThreshold = _newThreshold;
    }

    function setKeeper(address _newKeeper) public onlyOwner {
        emit KeeperChanged(keeper, _newKeeper);
        keeper = _newKeeper;
    }

    function setOwner(address _newOwner) public onlyOwner {
        emit OwnerChanged(s_owner, _newOwner);
        s_owner = _newOwner;
    }

    function setFee(uint256 _newFee) public onlyOwner {
        emit FeeChanged(ticketValue, _newFee);
        ticketValue = _newFee;
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper, "not the keeper");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner, "not the owner");
        _;
    }

    modifier gameStateOpen() {
        require(currentGameState == GameState.OPEN, "game state is closed");
        _;
    }
}