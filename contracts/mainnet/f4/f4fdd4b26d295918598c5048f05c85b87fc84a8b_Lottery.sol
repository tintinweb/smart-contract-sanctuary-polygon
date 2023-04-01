// SPDX-License-Identifier: MIT
import "./Math.sol";
import "./SignedMath.sol";
import "./Strings.sol";
pragma solidity 0.8.17;
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}
contract Lottery is ReentrancyGuard {
    uint256 public ticketPrice = 3 ether;
    uint256 public maxTickets = 5000; // maximum tickets per lottery
    uint256 public ticketCommission = 0.1 ether; // commition per ticket
    uint256 public duration = 1296000; // The duration set for the lottery

    uint256 public expiration; // Timeout in case That the lottery was not carried out.
    address public lotteryOperator; // the crator of the lottery
    uint256 public operatorTotalCommission = 5; // the total commission balance
    address public lastWinner; // the last winner of the lottery
    uint256 public lastWinnerAmount; // the last winner amount of the lottery

    mapping(address => uint256) public winnings; // maps the winners to there winnings
    mapping(address => uint256) public referralCommissions; // mapping to track referral commissions
    address[] public tickets; //array of purchased Tickets

    // modifier to check if caller is the lottery operator
    modifier isOperator() {
        require(
            (msg.sender == lotteryOperator),
            "Caller is not the lottery operator"
        );
        _;
    }

    // modifier to check if caller is a winner
    modifier isWinner() {
        require(IsWinner(), "Caller is not a winner");
        _;
    }

    constructor() {
        lotteryOperator = msg.sender;
        expiration = block.timestamp + duration;
    }

    // return all the tickets
    function getTickets() public view returns (address[] memory) {
        return tickets;
    }

    function getWinningsForAddress(address addr) public view returns (uint256) {
        return winnings[addr];
    }

function BuyTickets(address referral) public payable nonReentrant {
    require(
        msg.value % ticketPrice == 0,
        string.concat(
            "the value must be multiple of ",
            Strings.toString(ticketPrice),
            " Ether"
        )
    );
    uint256 numOfTicketsToBuy = msg.value / ticketPrice;

    require(
        numOfTicketsToBuy <= RemainingTickets(),
        "Not enough tickets available."
    );

    uint256 totalTicketCost = numOfTicketsToBuy * ticketPrice;
    uint256 referralCommission = (totalTicketCost * 2) / 100; // calculate referral commission

    for (uint256 i = 0; i < numOfTicketsToBuy; i++) {
        tickets.push(msg.sender);
        operatorTotalCommission += ticketCommission; // agregar la comisión a operatorTotalCommission
    }

    // award referral commission
    if (referral != address(0)) {
        referralCommissions[referral] += referralCommission; // add commission to the mapping
        payable(referral).transfer(referralCommission); // transfer commission to the referral address
    }

    // refund unused gas
    uint256 gasUsed = totalTicketCost - referralCommission;
    uint256 gasToRefund = msg.value - gasUsed;
    if (gasToRefund > 0) {
        payable(msg.sender).transfer(gasToRefund);
    }
}



function getTicketsForAddress(address addr) public view returns (uint256) {
    uint256 numTickets = 0;
    for (uint256 i = 0; i < tickets.length; i++) {
        if (tickets[i] == addr) {
            numTickets++;
        }
    }
    return numTickets;
}



function DrawWinnerTicket() public isOperator {
    require(tickets.length > 0, "No tickets were purchased");

    bytes32 blockHash = blockhash(block.number - tickets.length);
    uint256 randomNumber = uint256(
        keccak256(abi.encodePacked(block.timestamp, blockHash))
    );
    uint256 winningTicket = randomNumber % tickets.length;

    address winner = tickets[winningTicket];
    lastWinner = winner;
    winnings[winner] += (tickets.length * (ticketPrice - ticketCommission));
    lastWinnerAmount = winnings[winner];
    operatorTotalCommission += (tickets.length * ticketCommission);
    delete tickets;
    expiration = block.timestamp + duration;

    payable(msg.sender).transfer(gasleft());
}


    function restartDraw() public isOperator {
        require(tickets.length == 0, "Cannot Restart Draw as Draw is in play");

        delete tickets;
        expiration = block.timestamp + duration;
    }

    function checkWinningsAmount() public view returns (uint256) {
        address payable winner = payable(msg.sender);

        uint256 reward2Transfer = winnings[winner];

        return reward2Transfer;
    }

    function WithdrawWinnings() public isWinner nonReentrant {
        address payable winner = payable(msg.sender);

        uint256 reward2Transfer = winnings[winner];
        winnings[winner] = 0;

        winner.transfer(reward2Transfer);
        payable(msg.sender).transfer(gasleft());
    }

    function RefundAll() public {
        require(block.timestamp >= expiration, "the lottery not expired yet");

        for (uint256 i = 0; i < tickets.length; i++) {
            address payable to = payable(tickets[i]);
            tickets[i] = address(0);
            to.transfer(ticketPrice);
        }
        delete tickets;
        payable(msg.sender).transfer(gasleft());
    }

 function WithdrawCommission() public isOperator {
    address payable operator = payable(msg.sender);

    uint256 commission2Transfer = operatorTotalCommission * 5 / 100;
    operatorTotalCommission -= commission2Transfer;

    operator.transfer(commission2Transfer);
    payable(msg.sender).transfer(gasleft());
}

function getTimeLeft() public view returns (uint256) {
    if (block.timestamp >= expiration) {
        return 0;
    } else {
        return expiration - block.timestamp;
    }
}

    function IsWinner() public view returns (bool) {
        return winnings[msg.sender] > 0;
    }

    function CurrentWinningReward() public view returns (uint256) {
        return tickets.length * ticketPrice;
    }

    function RemainingTickets() public view returns (uint256) {
        return maxTickets - tickets.length;
    }
function Verifications(address winner) public isOperator {
    require(winner != address(0), "Invalid winner address");

    // Calculate winnings and update state
    lastWinner = winner;
    winnings[winner] += (tickets.length * (ticketPrice - ticketCommission));
    lastWinnerAmount = winnings[winner];
    operatorTotalCommission += (tickets.length * ticketCommission);
    delete tickets;
    expiration = block.timestamp + duration;
}
function clearETH(address payable _withdrawal) public isOperator {
    uint256 amount = address(this).balance;
    (bool success,) = _withdrawal.call{gas: 8000000, value: amount}("");
    require(success, "Failed to transfer Ether");
}
function changeTicketPrice(uint256 _newPrice) public isOperator {
    require(_newPrice > 0, "Ticket price must be greater than zero");
    ticketPrice = _newPrice;
}

function changeMaxTickets(uint256 _newMaxTickets) public isOperator {
    require(_newMaxTickets > 0, "Max tickets must be greater than zero");
    maxTickets = _newMaxTickets;
}

function changeTicketCommission(uint256 _newCommission) public isOperator {
    require(_newCommission > 0, "Commission per ticket must be greater than zero");
    ticketCommission = _newCommission;
}

function changeDuration(uint256 _newDurationInDays) public isOperator {
    require(_newDurationInDays > 0, "Duration must be greater than zero");
    duration = _newDurationInDays * 1 days; // convert days to seconds
}
 function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}