// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Lottery {
    uint256 public constant ticketPrice = 1000000000000000000; // Price in ERC-20 tokens
    uint256 public constant maxTickets = 100; // Maximum tickets per lottery
    uint256 public constant ticketCommission = 100000000000000000; // Commission per ticket
    uint256 public constant duration = 3 minutes; // The duration set for the lottery

    uint256 public expiration; // Timeout in case the lottery was not carried out.
    address public lotteryOperator; // The creator of the lottery
    uint256 public operatorTotalCommission = 0; // The total commission balance
    address public lastWinner; // The last winner of the lottery
    uint256 public lastWinnerAmount; // The last winner amount of the lottery

    mapping(address => uint256) public winnings; // Maps the winners to their winnings
    address[] public tickets; // Array of purchased tickets

    IERC20 public token; // ERC-20 token contract

    // Modifier to check if caller is the lottery operator
    modifier isOperator() {
        require(msg.sender == lotteryOperator, "Caller is not the lottery operator");
        _;
    }

    // Modifier to check if caller is a winner
    modifier isWinner() {
        require(IsWinner(), "Caller is not a winner");
        _;
    }

    constructor(address _token) {
        lotteryOperator = msg.sender;
        expiration = block.timestamp + duration;
        token = IERC20(_token);
    }

    // Return all the tickets
    function getTickets() public view returns (address[] memory) {
        return tickets;
    }

    function getWinningsForAddress(address addr) public view returns (uint256) {
        return winnings[addr];
    }

    function BuyTickets(uint256 amount) public {
        require(amount % ticketPrice == 0, "The value must be a multiple of the ticket price");
        uint256 numOfTicketsToBuy = amount / ticketPrice;

        require(numOfTicketsToBuy <= RemainingTickets(), "Not enough tickets available");

        for (uint256 i = 0; i < numOfTicketsToBuy; i++) {
            tickets.push(msg.sender);
        }

        token.transferFrom(msg.sender, address(this), amount);
    }

    function DrawWinnerTicket() public isOperator {
        require(tickets.length > 0, "No tickets were purchased");

        bytes32 blockHash = blockhash(block.number - tickets.length);
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, blockHash)));
        uint256 winningTicket = randomNumber % tickets.length;

        address winner = tickets[winningTicket];
        lastWinner = winner;
        winnings[winner] += (tickets.length * (ticketPrice - ticketCommission));
        lastWinnerAmount = winnings[winner];
        operatorTotalCommission += (tickets.length * ticketCommission);
        delete tickets;
        expiration = block.timestamp + duration;
    }

    function restartDraw() public isOperator {
        require(tickets.length == 0, "Cannot restart draw as draw is in play");

        delete tickets;
        expiration = block.timestamp + duration;
    }

    function checkWinningsAmount() public view returns (uint256) {
        return winnings[msg.sender];
    }

    function WithdrawWinnings() public isWinner {
        uint256 reward2Transfer = winnings[msg.sender];
        winnings[msg.sender] = 0;

        token.transfer(msg.sender, reward2Transfer);
    }

    function RefundAll() public {
        require(block.timestamp >= expiration, "The lottery has not expired yet");

        for (uint256 i = 0; i < tickets.length; i++) {
            address to = tickets[i];
            tickets[i] = address(0);
            token.transfer(to, ticketPrice);
        }
        delete tickets;
    }

    function WithdrawCommission() public isOperator {
        uint256 commission2Transfer = operatorTotalCommission;
        operatorTotalCommission = 0;

        token.transfer(msg.sender, commission2Transfer);
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
}