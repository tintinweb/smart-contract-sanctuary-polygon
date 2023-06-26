/**
 *Submitted for verification at polygonscan.com on 2023-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract FirstGear {
    function transferFrom(address sender, address receiver, uint256 amount) public returns(bool success) {}
    function burn() public {}
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Subtraction overflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a && c >= b, "Addition overflow");
        return c;
    }
}

contract FirstGearICO {
    using SafeMath for uint256;

    // The maximum amount of tokens to be sold
    uint256 constant public maxGoal = 275000000e18; // 275 Million FirstGear Tokens

    // There are different prices and amount available in each period
    uint256[2] public prices = [4200, 3500]; // 1MATIC = 4200 FirstGear, 1MATIC = 3500 FirstGear
    uint256[2] public amountStages = [137500000e18, 275000000e18]; // the amount stages for different prices

    // How much has been raised by crowdsale (in MATIC)
    uint256 public amountRaised;

    // The number of tokens already sold
    uint256 public tokensSold = 0;

    // The start date of the crowdsale
    uint256 constant public start = 1677264000; // June 25, 2023 00:00:00 GMT

    // The end date of the crowdsale
    uint256 constant public end = 1679856000; // July 25, 2023 00:00:00 GMT

    // The balances (in MATIC) of all token holders
    mapping(address => uint256) public balances;

    // Indicates if the crowdsale has been ended already
    bool public crowdsaleEnded = false;

    // Tokens will be transferred from this address
    address public tokenOwner;

    // The address of the token contract
    FirstGear public tokenReward;

    // The wallet on which the funds will be stored
    address payable wallet;

    // Notifying transfers and the success of the crowdsale
    event Finalize(address indexed tokenOwner, uint256 amountRaised);
    event FundTransfer(address indexed backer, uint256 amount, bool indexed isContribution, uint256 amountRaised);

    constructor(address tokenAddr, address payable walletAddr, address tokenOwnerAddr) {
        tokenReward = FirstGear(tokenAddr);
        wallet = walletAddr;
        tokenOwner = tokenOwnerAddr;
    }

    // Exchange FirstGear by sending MATIC to the contract.
    receive() external payable {
        revert("MATIC not accepted. Use the exchange() function with the specified amount of MATIC.");
    }

    // Make an exchange. Only callable if the crowdsale started and hasn't been ended,
    // and the maxGoal wasn't reached yet.
    // The current token price is determined by the available amount. Bought tokens are transferred to the receiver.
    // The sent value is directly forwarded to a safe wallet.
    function exchange(address receiver, uint256 amount) external {
        uint256 price = getPrice();
        uint256 numTokens = amount.mul(price);

        require(numTokens > 0, "Amount is too low");
        require(!crowdsaleEnded && block.timestamp >= start && block.timestamp <= end && tokensSold.add(numTokens) <= maxGoal, "Invalid exchange");

        balances[receiver] = balances[receiver].add(amount);

        // Calculate the amount raised and tokens sold
        amountRaised = amountRaised.add(amount);
        tokensSold = tokensSold.add(numTokens);

        require(tokenReward.transferFrom(tokenOwner, receiver, numTokens), "Token transfer failed");

        emit FundTransfer(receiver, amount, true, amountRaised);
    }

    // Looks up the current token price
    function getPrice() public view returns (uint256) {
        for (uint256 i = 0; i < amountStages.length; i++) {
            if (tokensSold < amountStages[i]) {
                return prices[i];
            }
        }
        return prices[prices.length - 1];
    }

    // Checks if the goal or time limit has been reached and ends the campaign
    function finalize() external {
        require(!crowdsaleEnded, "Crowdsale already ended");
        tokenReward.burn(); // Burn remaining tokens except the reserved ones
        emit Finalize(tokenOwner, amountRaised);
        crowdsaleEnded = true;
    }

    // Allows funders to withdraw their funds if the goal has not been reached.
    // Only works after funds have been returned from the wallet.
    function safeWithdrawal() external {
        uint256 amount = balances[msg.sender];
        if (address(this).balance >= amount) {
            balances[msg.sender] = 0;
            if (amount > 0) {
                payable(msg.sender).transfer(amount);
                emit FundTransfer(msg.sender, amount, false, amountRaised);
            }
        }
    }
}