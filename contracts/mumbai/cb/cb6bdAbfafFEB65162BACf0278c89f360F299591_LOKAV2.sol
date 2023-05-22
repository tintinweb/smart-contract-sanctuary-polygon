// SPDX-License-Identifier: MIT
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LOKAV2 {
    uint256 public constant ticketPrice = 100 * 10**18; // 100 tokens (wei value)
    uint256 public constant maxTickets = 1000; // maximum tickets per lottery
    uint256 public constant ticketCommission = 10 * 10**18; // 10 tokens (wei value) commission per ticket
    uint256 public constant duration = 1440 minutes; // The duration set for the lottery

    uint256 public expiration; // Timeout in case the lottery was not carried out.
    address public lotteryOperator; // the creator of the lottery
    uint256 public operatorTotalCommission = 0; // the total commission balance
    address public lastWinner; // the last winner of the lottery
    uint256 public lastWinnerAmount; // the last winner amount of the lottery

    mapping(address => uint256) public winnings; // maps the winners to their winnings
    address[] public tickets; // array of purchased Tickets

    IERC20 public token; // the ERC20 token used for buying tickets

    // modifier to check if the caller is the lottery operator
    modifier isOperator() {
        require(
            (msg.sender == lotteryOperator),
            "Caller is not the lottery operator"
        );
        _;
    }

    // modifier to check if the caller is a winner
    modifier isWinner() {
        require(IsWinner(), "Caller is not a winner");
        _;
    }

    constructor(address _tokenAddress) {
        lotteryOperator = msg.sender;
        expiration = block.timestamp + duration;
        token = IERC20(_tokenAddress);
    }

    // return all the tickets
    function getTickets() public view returns (address[] memory) {
        return tickets;
    }

    function getWinningsForAddress(address addr) public view returns (uint256) {
        return winnings[addr];
    }

    function BuyTickets(uint256 numOfTicketsToBuy) public {
        require(
            numOfTicketsToBuy > 0,
            "Number of tickets to buy must be greater than zero"
        );

        uint256 totalPrice = ticketPrice * numOfTicketsToBuy;

        require(
            token.allowance(msg.sender, address(this)) >= totalPrice,
            "Insufficient token allowance"
        );

        require(
            numOfTicketsToBuy <= RemainingTickets(),
            "Not enough tickets available."
        );

        for (uint256 i = 0; i < numOfTicketsToBuy; i++) {
            tickets.push(msg.sender);
        }

        token.transferFrom(msg.sender, address(this), totalPrice);
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
}

function restartDraw() public isOperator {
    require(tickets.length == 0, "Cannot restart draw as draw is in play");

    delete tickets;
    expiration = block.timestamp + duration;
}

function checkWinningsAmount() public view returns (uint256) {
    address payable winner = payable(msg.sender);

    uint256 reward2Transfer = winnings[winner];

    return reward2Transfer;
}

function WithdrawWinnings(address tokenAddress) public isWinner {
    address payable winner = payable(msg.sender);

    uint256 reward2Transfer = winnings[winner];
    require(reward2Transfer > 0, "No winnings to withdraw");

    winnings[winner] = 0;

    if (tokenAddress == address(0)) {
        // Withdraw Ether
        (bool success, ) = winner.call{ value: reward2Transfer }("");
        require(success, "Failed to withdraw winnings in Ether");
    } else {
        // Withdraw Tokens
        IERC20 tokenToWithdraw = IERC20(tokenAddress);
        require(tokenToWithdraw.transfer(winner, reward2Transfer), "Token transfer failed");
    }
}

function RefundAll() public {
    require(block.timestamp >= expiration, "The lottery has not expired yet");

    for (uint256 i = 0; i < tickets.length; i++) {
        address payable to = payable(tickets[i]);
        tickets[i] = address(0);
        (bool success, ) = to.call{ value: ticketPrice }("");
        require(success, "Failed to refund ticket");
    }
    delete tickets;
	}

    function WithdrawCommission(address tokenAddress) public isOperator {
    address payable operator = payable(msg.sender);

    uint256 commission2Transfer = operatorTotalCommission;
    operatorTotalCommission = 0;

    if (tokenAddress == address(0)) {
        // Withdraw Ether
        (bool success, ) = operator.call{ value: commission2Transfer }("");
        require(success, "Failed to withdraw commission in Ether");
    } else {
        // Withdraw Tokens
        IERC20 commissionToken = IERC20(tokenAddress);
        require(commissionToken.transfer(operator, commission2Transfer), "Token transfer failed");
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
}