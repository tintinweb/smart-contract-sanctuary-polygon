// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract LaxmiCryptFund {
    // Tracking total investors
    uint256 public investors;

    // Declaring variables for min and max investments
    uint256 public minInvestment;
    uint256 public maxInvestment;

    // Declaring conract owner
    address payable public owner;

    // List of memos
    Memo[] public Memos;

    // Event to emit a Memo
    event NewMemo(
        address indexed investor,
        string result,
        uint256 investment,
        uint256 timestamp
    );

    // Memo structure
    struct Memo {
        address investor;
        string result;
        uint256 investment;
        uint256 timestamp;
    }

    // Constructor function to run at the beginning of smart contract deployment
    constructor() payable {
        owner = payable(msg.sender);
        investors = 0;
        minInvestment = 0.0001 ether;
        maxInvestment = 0.01 ether;
    }

    /**
     * @dev Returns all the memos
     */
    function getMemos() public view returns (Memo[] memory) {
        return Memos;
    }

    /**
     * @dev Change the limits of min and max investments
     * @param _minInvestment Minimum value of investment
     * @param _maxInvestment Maximum value of investment
     */
    function changeInvestmentLimits(
        uint256 _minInvestment,
        uint256 _maxInvestment
    ) public {
        require(
            msg.sender == owner,
            "You cannot change the investment limits."
        );

        minInvestment = _minInvestment;
        maxInvestment = _maxInvestment;
    }

    /**
     * @dev Generates a random number
     */
    function generateRandomNumber() public view returns (uint256) {
        return uint256(blockhash(block.number - 1)) % 100;
    }

    /**
     * @dev Owner can withdraw funds
     */
    function withdrawFunds() public {
        require(msg.sender == owner, "Only owner can withdraw funds.");

        owner.transfer(address(this).balance);
    }

    /**
     * @dev Invest in Laxmi Crypt Fund
     */
    function invest() public payable {
        // Minimum value sent should be greater than 0.0001
        require(msg.value >= minInvestment, "Too less to invest.");

        // Maximum value sent should be less than 0.01
        require(msg.value <= maxInvestment, "Too much to invest.");

        // Fund should be having required funds
        require(address(this).balance > 2 * msg.value, "We just scammed you!");

        // Generating a lucky number
        uint256 luckyNumber = generateRandomNumber();

        // If luckyNumber is greater than 50, investor wins
        if (luckyNumber >= 50) {
            // Adding memo to Memos
            Memos.push(Memo(msg.sender, "doubled", msg.value, block.timestamp));

            // Emitting the event
            emit NewMemo(msg.sender, "doubled", msg.value, block.timestamp);

            // Sending double of investment
            payable(msg.sender).transfer(2 * msg.value);
        } else {
            // Adding memo to Memos
            Memos.push(Memo(msg.sender, "lost", msg.value, block.timestamp));

            // Emitting the event
            emit NewMemo(msg.sender, "lost", msg.value, block.timestamp);
        }

        // Increasing the count of investors
        investors++;
    }
}