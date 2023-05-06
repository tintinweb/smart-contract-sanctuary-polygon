/**
 *Submitted for verification at polygonscan.com on 2023-05-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

contract Raffle {
    address public owner;
    IERC20 public token;
    uint256 public ticketPrice;
    uint256 public ticketSupply;
    uint256 public endTime;
    uint256 public winnerIndex;
    mapping(address => uint256) public balances;
    mapping(uint256 => address) public tickets;

    event RaffleStarted(uint256 endTime, uint256 ticketPrice, uint256 ticketSupply);
    event TicketPurchased(address indexed buyer, uint256 amount);
    event RaffleEnded(address indexed winner);

    constructor(
        IERC20 _token,
        uint256 _ticketPrice,
        uint256 _ticketSupply,
        uint256 _durationInMinutes
    ) {
        owner = msg.sender;
        token = _token;
        ticketPrice = _ticketPrice;
        ticketSupply = _ticketSupply;
        endTime = block.timestamp + (_durationInMinutes * 1 minutes);
        emit RaffleStarted(endTime, ticketPrice, ticketSupply);
    }

    function purchaseTicket() external {
        require(block.timestamp < endTime, "Raffle has ended");
        require(balances[msg.sender] + ticketPrice <= token.allowance(msg.sender, address(this)), "Insufficient token allowance");
        require(balances[msg.sender] + ticketPrice <= token.balanceOf(msg.sender), "Insufficient token balance");
        require(ticketSupply > 0, "All tickets sold out");
        
        token.transferFrom(msg.sender, address(this), ticketPrice);
        
        balances[msg.sender] += ticketPrice;
        tickets[ticketSupply] = msg.sender;
        ticketSupply--;
        
        emit TicketPurchased(msg.sender, ticketPrice);
    }

    function endRaffle() external {
        require(msg.sender == owner, "Only the owner can end the raffle");
        require(block.timestamp >= endTime, "Raffle has not ended yet");
        require(ticketSupply == 0, "Raffle is not sold out");
        
        // Randomly select a winner
        winnerIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, ticketSupply))) % ticketSupply;
        address winner = tickets[winnerIndex];
        
        // Transfer the prize to the winner
        token.transfer(winner, token.balanceOf(address(this)));
        
        emit RaffleEnded(winner);
    }
}