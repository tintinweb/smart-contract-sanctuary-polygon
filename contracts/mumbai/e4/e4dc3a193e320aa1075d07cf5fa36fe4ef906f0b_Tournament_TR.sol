/**
 *Submitted for verification at polygonscan.com on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0 <0.6.0;

contract Tournament_TR {

    address public owner; // Address of the owner
    address public organizer; // Address of the organizer
    address public winner; // Address of the winner
    uint public minNumOfPlayers; // Minimal number of players
    uint public playersCounter; // Counter of players
    uint public entrantsCounter; // Counter of entrants
    uint public buyIn; // The buy-in amount in Wei (1 Ether = 10^18 Wei)
    uint public winnerShare; // The winner's share in percents
    uint public prize; // The prize amount in Wei
    uint public deadline; // Participants registration deadline in Unix time format
    uint public tournamentDeadline; // Tournament end deadline in Unix time format
    uint public contractBalance; // The balance of the contract
    uint public availableFunds; // Amount available to the organizer for withdrawal
    // Possible statuses of the tournament
    enum statuses {NotTerminated, LackOfPlayers, Cancelled, NoWinner, Winner}
    // Current status of the tournament (initial value is NotTerminated)
    statuses public status;
    bool public deadlineIsChanged; // True if deadline is changed
    bool public prizeIsPaid; // True if prize is paid to the winner
    // The list of entrants' addresses
    address[] public entrantsList;
    // Mapping <entrant's address> => <entrant's entrance code>
    mapping (address => uint) public entranceCodes;
    // Mapping <entrant's address> => <entrant's entrances counter>
    mapping (address => int) public entranceCounters;
    // Mapping <entrant's entrance code> => <entrant's address>
    mapping (uint => address) public whoseEntranceCode;

    // The event of the contract creation
    event onCreation(
        address organizer, uint minNumOfPlayers, uint buyIn, uint winnerShare, uint deadline, uint tournamentDeadline
    );
    // Entrance event
    event onEntrance(address entrantAddress, uint entranceCode, int entrancesCounter);
    // Unregistering event
    event onUnregistering(address entrantAddress, int entrancesCounter);
    // Deadline change event
    event onDeadlineChange(uint newDeadline);
    // The event of the winner announcement
    event onWinnerAnnouncement(address winnerAddress);
    // The event of the prize payment to the winner
    event onPrizePayment(address winnerAddress, uint amount);
    // The event of the tournament termination with one of the statuses
    // LackOfPlayers, Cancelled and NoWinner
    event onTermination(statuses status);
    // Refund event
    event onRefund(address playerAddress);
    // Withdrawal event
    event onWithdrawal(uint amount);


    constructor (
        uint _minNumOfPlayers,
        uint _buyIn,
        uint _winnerShare,
        uint _deadline,
        uint _tournamentDeadline,
        address _organizer
    ) public {
        owner = msg.sender; // The owner = the contract creator
        organizer = _organizer; // The organizer = the tournament organizer
        minNumOfPlayers = _minNumOfPlayers;
        buyIn = _buyIn;
        winnerShare = _winnerShare;
        deadline = _deadline;
        tournamentDeadline = _tournamentDeadline;
        emit onCreation(_organizer, _minNumOfPlayers, _buyIn, _winnerShare, _deadline, _tournamentDeadline);
    }

    modifier byOwnerOrOrganizerOnly() {
        require(
            msg.sender == owner || msg.sender == organizer,
            "Only the owner/organizer is authorized to perform this function"
        );
        _;
    }

    modifier byOwnerOnly() {
        require(
            msg.sender == owner,
            "Only the owner is authorized to perform this function"
        );
        _;
    }

    modifier checkTermination() {
        statuses _status = status;
        if (_status == statuses.LackOfPlayers) {
            revert("The tournament has been terminated due to lack of players");
        }
        if (_status == statuses.Cancelled ||
            _status == statuses.NoWinner) {
            revert("The tournament has been terminated by the organizer");
        }
        if (_status == statuses.Winner) {
            revert("The tournament has been finished with winner announcement");
        }
        _;
    }

    /// enter accepts buy-ins from participants and register them for the tournament
    function enter(uint _entranceCode)
        public
        payable
        checkTermination
    {
        int _entranceCounter = entranceCounters[msg.sender];

        require(
            now < deadline,
            "Time to enter into the tournament has passed"
        );
        require(
            _entranceCounter <= 0,
            "You are already in the list of players"
        );
        require(
            msg.value == buyIn,
            "The amount you deposit is not equal to the buy-in amount"
        );
        require(
            _entranceCode >= 1000000000000000 && _entranceCode <= 9999999999999999,
            "The entrance code must be a 16-digit number"
        );
        require(
            whoseEntranceCode[_entranceCode] == address(0),
            "The code you have entered is already used"
        );

        _entranceCounter = 10 - _entranceCounter;
        entranceCounters[msg.sender] = _entranceCounter;
        entranceCodes[msg.sender] = _entranceCode;
        whoseEntranceCode[_entranceCode] = msg.sender;
        if (_entranceCounter == 10) {
            entrantsCounter++;
            entrantsList.push(msg.sender);
        }
        playersCounter++;
        emit onEntrance(msg.sender, _entranceCode, _entranceCounter);
        uint _balance = address(this).balance;
        contractBalance = _balance;
        prize = _balance * winnerShare / 100;
            // In Solidity, division rounds towards zero
    }

    /// unregister lets participants to unregister for the tournament
    /// with full refund
    function unregister()
        public
        checkTermination
    {
        int _entranceCounter = entranceCounters[msg.sender];

        require(
            now < deadline,
            "Time to unregister for the tournament has passed"
        );
        require(
            _entranceCounter > 0,
            "You are not in the list of players"
        );

        _entranceCounter = -_entranceCounter;
        entranceCounters[msg.sender] = _entranceCounter;
        whoseEntranceCode[entranceCodes[msg.sender]] = address(0);
        playersCounter--;
        emit onUnregistering(msg.sender, _entranceCounter);
        msg.sender.transfer(buyIn);
        uint _balance = address(this).balance;
        contractBalance = _balance;
        prize = _balance * winnerShare / 100;
            // In Solidity, division rounds towards zero
    }

    /// changeDeadline shifts the registration deadline
    function changeDeadline(uint _newDeadline)
        public
        byOwnerOrOrganizerOnly
        checkTermination
    {
        uint _oldDeadline = deadline;

        require(
            now < _oldDeadline,
            "Time to change the deadline has passed"
        );
        require(
            !deadlineIsChanged,
            "The deadline has already been changed"
        );
        require(
            _newDeadline != _oldDeadline,
            "New deadline is equal to the current one"
        );
        require(
            (_newDeadline > _oldDeadline &&
            _newDeadline <= _oldDeadline + 72 hours) ||
            (_newDeadline < _oldDeadline &&
            _newDeadline >= now + 24 hours),
            "New deadline is out of allowable limits"
        );

        deadline = _newDeadline;
        deadlineIsChanged = true;
        emit onDeadlineChange(_newDeadline);
    }

    /// announceWinner stores the winner's address in the contract
    /// and assignes the tournament with the status Winner
    function announceWinner(address payable _winner)
        public
        byOwnerOnly
        checkTermination
    {
        require(
            block.timestamp >= tournamentDeadline,
            "The winner is announced too early"
        );
        require(
            entranceCounters[_winner] > 0,
            "The winner is not in the list of players"
        );

        availableFunds = address(this).balance - prize;
        winner = _winner;
        status = statuses.Winner;
        emit onWinnerAnnouncement(_winner);
    }

    /// terminate assignes the tournament with one of the statuses
    /// Cancelled or NoWinner
    function terminate(statuses newStatus)
        public
        byOwnerOrOrganizerOnly
        checkTermination
    {
        require(
            newStatus == statuses.Cancelled ||
            newStatus == statuses.NoWinner,
            "Invalid termination status"
        );
        
        status = newStatus;
        emit onTermination(newStatus);
    }

    /// takePrize transfers the prize to the winner's address
    function takePrize()
        public
    {
        uint _prize = prize;

        require(
            status == statuses.Winner,
            "The winner has not been announced"
        );
        require(
            msg.sender == winner,
            "You are not the winner"
        );
        require(
            !prizeIsPaid,
            "You have already taken your prize"
        );

        prizeIsPaid = true;
        emit onPrizePayment(msg.sender, _prize);
        msg.sender.transfer(_prize);
        contractBalance = address(this).balance;
    }

    function lackOfPlayers()
        public
        byOwnerOrOrganizerOnly
    {
        statuses _status = status;

        require(
            block.timestamp >= deadline,
            "Resgistration is not finished yet."
        );

        require(
            block.timestamp >= deadline && playersCounter < minNumOfPlayers,
            "There are sufficient number of players."
        );

        if (now >= deadline &&
            _status == statuses.NotTerminated &&
            playersCounter < minNumOfPlayers) {
            _status = statuses.LackOfPlayers;
            status = _status;
            emit onTermination(_status);
            // return();
        }
    }

    /// refund lets the players take away their buy-ins if the tournament
    /// has one of the statuses LackOfPlayers, Cancelled or NoWinner
    function refund()
        public
    {
        int _entranceCounter = entranceCounters[msg.sender];
        statuses _status = status;
        
        require(
            _entranceCounter > 0,
            "You are not a player of the tournament"
        );
        require(
            _entranceCounter % 10 == 0,
            "You have already refunded"
        );
        require(
            _status == statuses.LackOfPlayers ||
            _status == statuses.Cancelled ||
            _status == statuses.NoWinner,
            "You can refund only if the tournament terminated with no winner"
        );
        _entranceCounter++;
        entranceCounters[msg.sender] = _entranceCounter;
        emit onRefund(msg.sender);
        msg.sender.transfer(buyIn);
        contractBalance = address(this).balance;
    }

    /// withdraw assigns the torunament with the status LackOfPlayers if appropriate,
    /// or transfers the requested amount to the organizer if the amount is non-zero
    /// and it does not exceed the available funds
    function withdraw(uint amount)
        public
        byOwnerOrOrganizerOnly
    {
        // statuses _status = status;
        uint _availableFunds = availableFunds;

        require(
            block.timestamp >= tournamentDeadline,
            "Tournament not finished yet."
        );

        // if (now >= deadline &&
        //     _status == statuses.NotTerminated &&
        //     playersCounter < minNumOfPlayers) {
        //     _status = statuses.LackOfPlayers;
        //     status = _status;
        //     emit onTermination(_status);
        //     return();
        // }
        if (amount > 0 && amount <= _availableFunds) {
            _availableFunds -= amount;
            emit onWithdrawal(amount);
            msg.sender.transfer(amount);
            contractBalance = address(this).balance;
            availableFunds = _availableFunds;
        }
    }

}

// 10, 1000000000000000, 80, 1668181383, 1668199383, "0x2c4664f85b69f4B22eB7B1B52498a76770a12C8a"