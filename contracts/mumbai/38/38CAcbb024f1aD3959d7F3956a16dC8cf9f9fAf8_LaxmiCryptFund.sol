// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract LaxmiCryptFund {
    // Tracking total investors
    uint256 public investors;

    // Declaring variables for min and max investments
    uint256 public minInvestment;
    uint256 public maxInvestment;

    // Random Nonce for random number generation
    uint256 public randomNonce;

    // Declaring conract owner
    address payable public owner;

    // Tracking won and lost investors
    uint256 investorsWon;
    uint256 investorsLost;

    // List of memos
    Memo[] public Memos;

    // Event to emit a Memo
    event NewMemo(
        address indexed investor,
        uint256 luckyNumber,
        string result,
        uint256 investment,
        uint256 timestamp
    );

    // Memo structure
    struct Memo {
        address investor;
        uint256 luckyNumber;
        string result;
        uint256 investment;
        uint256 timestamp;
    }

    // Constructor function to run at the beginning of smart contract deployment
    constructor() payable {
        owner = payable(msg.sender);
        investors = 0;
        minInvestment = 10e5 gwei;
        maxInvestment = 10e7 gwei;
        randomNonce = 0;
        investorsWon = 0;
        investorsLost = 0;
    }

    /**
     * @dev Get investors won
     */
    function getWon() public view returns (uint256) {
        return (investorsWon);
    }

    /**
     * @dev Get investors lost
     */
    function getLost() public view returns (uint256) {
        return (investorsLost);
    }

    /**
     * @dev Fund the smart contract
     */
    function fundContract() public payable {
        require(msg.value > 0, "Invalid Amount.");
    }

    /**
     * @dev Get the balance of smart contract
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
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
    function generateRandomNumber() internal returns (uint256) {
        randomNonce++;

        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randomNonce)
                )
            ) % 100;
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

        // Crypt Fund should be having required funds
        require(address(this).balance > 2 * msg.value, "We just scammed you!");

        // Generating a lucky number
        uint256 luckyNumber = generateRandomNumber();

        // If luckyNumber is greater than 50, investor wins
        if (luckyNumber >= 50) {
            // Investor won
            investorsWon++;

            // Adding memo to Memos
            Memos.push(
                Memo(
                    msg.sender,
                    luckyNumber,
                    "doubled",
                    msg.value,
                    block.timestamp
                )
            );

            // Emitting the event
            emit NewMemo(
                msg.sender,
                luckyNumber,
                "doubled",
                msg.value,
                block.timestamp
            );

            // Sending double of investment
            payable(msg.sender).transfer(2 * msg.value);
        } else {
            // Investor Lost
            investorsLost++;

            // Adding memo to Memos
            Memos.push(
                Memo(
                    msg.sender,
                    luckyNumber,
                    "lost",
                    msg.value,
                    block.timestamp
                )
            );

            // Emitting the event
            emit NewMemo(
                msg.sender,
                luckyNumber,
                "lost",
                msg.value,
                block.timestamp
            );
        }

        // Increasing the count of investors
        investors++;
    }
}