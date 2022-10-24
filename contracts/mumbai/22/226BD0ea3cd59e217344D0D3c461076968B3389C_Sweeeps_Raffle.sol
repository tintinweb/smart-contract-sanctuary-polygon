//Smart Contract for Sweeeps Raffle. 2022 RiftNinja and GhostMan.
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 < 0.9.0;

contract Sweeeps_Raffle {

    struct Game {
        string refId; // unique game reference
        string name; // display name
        uint256 ticketPrice; // price per ticket
        uint256 winningsRate; // rate for winners
        uint256 refundRate; // rate for refund
        uint256 endBlockTime; // block time for end of ticket sales
        uint256 maxTickets; // maximum number of tickets, set to 0 for unlimited
        uint256 maxTicketsPerUser; // maximum number of tickets, set to 0 for unlimited
        uint256 maxWinners; // maximum number of winners
        uint256 totalCommission; // total commission on game
        uint256 totalReward; // total reward for game
        string status; // pending, active, completed
    }

    struct Ticket {
        string ticketGame; // game reference key
        uint256 ticketNumber; // randomly generated number
        address tickerOwner; // public key address
        string numbers; // RSA encrypted numbers
        string numbersHash; // Keccak256 numbers hash
        string encryptedNumbers; // user encrypted numbers
        uint256 ticketPrice; // price ticket was purchased for
        uint256 refundAmount; // amount to refund
        bytes32 disbursementHash; // payment/refund transaction hash
        bool disbursed; // update to determine the state of the refund
        bool isWinner; // update to indicate winner
    }

    string[] public gameList; // list of all game references
    mapping (string => Game) public games; // game details
    mapping (uint256 => Ticket) public tickets; // active game tickets

    mapping (string => uint256[]) public gameTickets; // game details
    mapping (address => mapping (string => uint256[])) public userTickets; // user's tickets
    mapping (string => uint256[]) public winners; // winning tickets

    address public contractOwner; // defaults to contract creator
    mapping (address => bool) public operators; // operators
    address[] public whitelist;


    constructor() {
        contractOwner = msg.sender;
        operators[contractOwner] = true;
        whitelist.push(contractOwner);
    }

    modifier creatorOnly() {
        require(msg.sender == contractOwner, "Caller is not the creator");
        _;
    }

    modifier operatorOnly() {
        require((operators[msg.sender] || msg.sender == contractOwner), "Caller is not an operator");
        _;
    }

    function replaceOwner(address _newOwner) public creatorOnly {
        contractOwner = _newOwner;
    }

    function addOperator(address _operator) public creatorOnly {
        operators[_operator] = true;
    }

    function removeOperator(address _operator) public creatorOnly {
        operators[_operator] = false;
    }

    function stringEquals(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }


    function createUpdateGame(string memory _reference, string memory _name, uint256 _ticketPrice, uint256 _winningsRate, uint256 _refundRate, uint256 _endBlockTime, uint256 _maxTickets, uint256 _maxTicketsPerUser, uint256 _maxWinners) public operatorOnly {
        bool _isNewGame = !stringEquals(games[_reference].refId, _reference);
        if(!_isNewGame) require(stringEquals(games[_reference].status, "pending"), "Game data cannot be updated");

        games[_reference] = Game (
            _reference, // reference
            _name, // name
            _ticketPrice, // ticketPrice
            _winningsRate, // winningsRate
            _refundRate, // refundRate
            _endBlockTime, // endBlockTime
            _maxTickets, // maxTickets
            _maxTicketsPerUser, // maxTicketsPerUser
            _maxWinners, // maxWinners
            _isNewGame ? 0 : games[_reference].totalCommission, // totalCommission
            _isNewGame ? 0 : games[_reference].totalReward, // totalReward
            _isNewGame ? "pending" : games[_reference].status // status
        ); if(_isNewGame) gameList.push(_reference);
    }

    function updateGameStatus(string memory _reference, string memory _status) public {
        require(stringEquals(_status, "active") || stringEquals(_status, "completed"), "invalid status");
        require(!stringEquals(games[_reference].status, "completed"), "Game status cannot be updated");
        games[_reference].status = _status;
    }

    function getUserTickets(string memory _gameReference) public view returns (Ticket[] memory) {
        Ticket[] memory _userTickets;
        for(uint i = 0; i < userTickets[msg.sender][_gameReference].length; i++) {
            _userTickets[_userTickets.length] = tickets[userTickets[msg.sender][_gameReference][i]];
        }
        return _userTickets;
    }

    function remainTickets(string memory _gameReference) public view returns (uint256) {
        return games[_gameReference].maxTickets - gameTickets[_gameReference].length;
    }

    function remainUserTickets(address _address, string memory _gameReference) public view returns (uint256) {
        return games[_gameReference].maxTicketsPerUser - userTickets[_address][_gameReference].length;
    }

    function generateRandomNumber(string memory _reference) public view returns (uint256) {
        bytes32 blockHash = blockhash(block.number - gameTickets[_reference].length);
        return uint256(keccak256(abi.encodePacked(block.timestamp, blockHash)));
    }

    function buyTickets(string memory _gameReference) public payable {
        require(stringEquals(games[_gameReference].status, "active"), "Game is currently not active");
        require(block.timestamp <= games[_gameReference].endBlockTime, "Ticket sale for game has ended");

        require( // CHECK TO SEE VALUE BEING SENT
            msg.value >= games[_gameReference].ticketPrice && msg.value % games[_gameReference].ticketPrice == 0,
            "the value must be in multiples of ticket price"
        );

        uint256 _numOfTicketsToBuy = msg.value / games[_gameReference].ticketPrice;
        require(games[_gameReference].maxTickets == 0 || _numOfTicketsToBuy <= remainTickets(_gameReference), "Insufficient tickets available for sale");
        require(games[_gameReference].maxTicketsPerUser == 0 || _numOfTicketsToBuy <= remainUserTickets(msg.sender, _gameReference), "Maximum tickets per user exceeded");
        require(block.timestamp <= games[_gameReference].endBlockTime, "Ticket sale for game has ended");

        for (uint256 i = 0; i < _numOfTicketsToBuy; i++) {
            uint256 _tickNumber = generateRandomNumber(_gameReference);
            Ticket memory _newTicket = Ticket(
                _gameReference, // ticketGame
                _tickNumber, // ticketNumber
                msg.sender, // tickerOwner
                "", // numbers
                "", // numbersHash
                "", // encryptedNumbers
                games[_gameReference].ticketPrice, // ticketPrice
                (games[_gameReference].ticketPrice * games[_gameReference].refundRate) / 100, // refundAmount
                "", // disbursementHash
                false, // disbursed
                false // isWinner
            );

            // VERIFY THIS
            tickets[_tickNumber] = _newTicket;
            gameTickets[_gameReference].push(_tickNumber);
            userTickets[msg.sender][_gameReference].push(_tickNumber);

            games[_gameReference].totalReward += (games[_gameReference].ticketPrice * games[_gameReference].winningsRate) / 100;
            games[_gameReference].totalCommission += (games[_gameReference].ticketPrice * (100 - games[_gameReference].winningsRate - games[_gameReference].refundRate)) / 100;
        }
    }

    function initTicketRefund(uint256 _ticketNumber) public {
        require((operators[msg.sender] || msg.sender == contractOwner || msg.sender == tickets[_ticketNumber].tickerOwner), "Permission required to take action");
        require(tickets[_ticketNumber].ticketNumber == _ticketNumber, "Ticket not found");
        require(stringEquals(games[tickets[_ticketNumber].ticketGame].status, "completed") && winners[tickets[_ticketNumber].ticketGame].length > 0, "Winner is yet to be determined");
        require(!tickets[_ticketNumber].isWinner, "Refund is not available for winning tickets");
        require(!tickets[_ticketNumber].disbursed, "Refund already disbursed");

        tickets[_ticketNumber].disbursed = true;
        address payable _to = payable(tickets[_ticketNumber].tickerOwner);
        tickets[_ticketNumber].disbursementHash = keccak256(abi.encodePacked(_to, tickets[_ticketNumber].refundAmount));
        _to.transfer(tickets[_ticketNumber].refundAmount);
    }

    function withdrawWinnings(uint256 _ticketNumber) public {
        require((operators[msg.sender] || msg.sender == contractOwner || msg.sender == tickets[_ticketNumber].tickerOwner), "Permission required to take action");
        require(tickets[_ticketNumber].ticketNumber == _ticketNumber, "Ticket not found");
        require(stringEquals(games[tickets[_ticketNumber].ticketGame].status, "completed") && winners[tickets[_ticketNumber].ticketGame].length > 0, "Winner is yet to be determined");
        require(tickets[_ticketNumber].isWinner, "Winnings only available for winning tickets");
        require(!tickets[_ticketNumber].disbursed, "Winnings already disbursed");

        tickets[_ticketNumber].disbursed = true;
        address payable _to = payable(tickets[_ticketNumber].tickerOwner);
        tickets[_ticketNumber].disbursementHash = keccak256(abi.encodePacked(_to, games[tickets[_ticketNumber].ticketGame].totalReward / winners[tickets[_ticketNumber].ticketGame].length));
        _to.transfer(games[tickets[_ticketNumber].ticketGame].totalReward / winners[tickets[_ticketNumber].ticketGame].length);
    }

    function computeWinningTickets(string memory _gameReference, bool _autoDisburse) public operatorOnly {
        for(uint i = 0; i < games[_gameReference].maxWinners; i++) {
            uint256 _winner = uint256(keccak256(abi.encodePacked(block.timestamp + i, block.difficulty))) % gameTickets[_gameReference].length;
            _winner = gameTickets[_gameReference][_winner];
            winners[_gameReference].push(_winner);
            if(tickets[_winner].ticketNumber == _winner){
                tickets[_winner].isWinner = true;
                if(_autoDisburse) withdrawWinnings(_winner);
            }
        }
    }


    function addToWhitelist(address _address) public creatorOnly {
        for(uint i = 0; i < whitelist.length; i++) {
            if(whitelist[i] == _address) return;
        } whitelist.push(_address);
    }

    function removeFromWhitelist(address _address) public creatorOnly {
        address[] memory _whitelist;
        for(uint i = 0; i < whitelist.length; i++) {
            if(whitelist[i] != _address)
                _whitelist[_whitelist.length] = whitelist[i];
        }
        whitelist = _whitelist;
    }

    function withdrawCommission(string memory _gameReference, address payable _to) public operatorOnly {
        require(games[_gameReference].totalCommission > 0, "No commissions available");

        bool _canWithdraw = false;
        for(uint i = 0; i < whitelist.length; i++) {
            if(payable(whitelist[i]) == _to){
                _canWithdraw = true;
                break;
            }
        }

        require(_canWithdraw, "Withdrawal address is not whitelisted");
        games[_gameReference].totalCommission = 0;
        _to.transfer(games[_gameReference].totalCommission);
    }

    function destroy(bool _forceDestroy) public creatorOnly {
        // IF FORCE_DESTROY, SET ALL ACTIVE GAMES TO COMPLETED AND ASSIGN IMAGINARY WINNER
        if(_forceDestroy){
            for(uint i = 0; i < gameList.length; i++) {
                if(stringEquals(games[gameList[i]].status, "active")){
                    updateGameStatus(gameList[i], "completed");
                    winners[gameList[i]].push(0);
                    break;
                }
            }
        } else { // CHECK ALL GAMES ARE CLOSE, RETURN ERROR IF GAMES PENDING OR ACTIVE AND NO FORCE_DESTROY
            bool _hasActiveGames = false;
            for(uint i = 0; i < gameList.length; i++) {
                if(stringEquals(games[gameList[i]].status, "active")){
                    _hasActiveGames = true;
                    break;
                }
            }
            require(!_hasActiveGames, "Cannot destroy contract due to existing ongoing game(s)");
        }

        // DO ALL PENDING PAYMENTS AND REFUNDS FROM TICKETS
        for(uint i = 0; i < gameList.length; i++) {
            for(uint j = 0; j < gameTickets[gameList[i]].length; j++) {
                uint256 _ticketNumber = gameTickets[gameList[i]][j];
                if(tickets[_ticketNumber].ticketNumber == _ticketNumber && !tickets[_ticketNumber].disbursed){
                    if(tickets[_ticketNumber].isWinner){
                        withdrawWinnings(_ticketNumber);
                    } else {
                        initTicketRefund(_ticketNumber);
                    }
                }
            }
        }

        selfdestruct(payable(contractOwner));
    }
}