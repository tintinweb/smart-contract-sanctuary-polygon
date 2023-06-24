/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.15;

contract token {
    function transferFrom(address sender, address receiver, uint amount) returns(bool success) {}
    function burn() {}
}

library SafeMath {
    function mul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract DodoICO {
    using SafeMath for uint;
    // The maximum amount of tokens to be sold
    uint constant public maxGoal = 275000000e18; // 275 Million Dodo Tokens
    // There are different prices and amount available in each period
    uint[2] public prices = [4200, 3500]; // 1MATIC = 4200 DODO, 1MATIC = 3500 DODO
    uint[2] public amount_stages = [137500000e18, 275000000e18]; // the amount stages for different prices
    // How much has been raised by crowdsale (in MATIC)
    uint public amountRaised;
    // The number of tokens already sold
    uint public tokensSold = 0;
    // The start date of the crowdsale
    uint constant public start = 1516356000; // Friday, 19 January 2018 10:00:00 GMT
    // The end date of the crowdsale
    uint constant public end = 1516960800; // Friday, 26 January 2018 10:00:00 GMT
    // The balances (in MATIC) of all token holders
    mapping(address => uint) public balances;
    // Indicates if the crowdsale has been ended already
    bool public crowdsaleEnded = false;
    // Tokens will be transferred from this address
    address public tokenOwner;
    // The address of the token contract
    token public tokenReward;
    // The wallet on which the funds will be stored
    address wallet;
    // Notifying transfers and the success of the crowdsale
    event Finalize(address _tokenOwner, uint _amountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution, uint _amountRaised);

    // ---- FOR TEST ONLY ----
    uint _current = 0;
    function current() public returns (uint) {
        // Override not in use
        if(_current == 0) {
            return now;
        }
        return _current;
    }
    function setCurrent(uint __current) {
        _current = __current;
    }
    //------------------------

    // Constructor/initialization
    constructor(address tokenAddr, address walletAddr, address tokenOwnerAddr) public {
        tokenReward = token(tokenAddr);
        wallet = walletAddr;
        tokenOwner = tokenOwnerAddr;
    }

    // Exchange DODO by sending MATIC to the contract.
    function() external payable {
        revert("MATIC not accepted. Use the exchange() function with the specified amount of MATIC.");
    }

    // Make an exchange. Only callable if the crowdsale started and hasn't

     //been ended, and the maxGoal wasn't reached yet.
    // The current token price is determined by the available amount. Bought tokens are transferred to the receiver.
    // The sent value is directly forwarded to a safe wallet.
    function exchange(address receiver, uint amount) external {
        uint price = getPrice();
        uint numTokens = amount.mul(price);

        require(numTokens > 0);
        require(!crowdsaleEnded && current() >= start && current() <= end && tokensSold.add(numTokens) <= maxGoal);

        balances[receiver] = balances[receiver].add(amount);

        // Calculate the amount raised and tokens sold
        amountRaised = amountRaised.add(amount);
        tokensSold = tokensSold.add(numTokens);

        assert(tokenReward.transferFrom(tokenOwner, receiver, numTokens));
        emit FundTransfer(receiver, amount, true, amountRaised);
    }

    // Manual exchange tokens for BTC, LTC, Fiat contributions.
    // @param receiver The address to which tokens will be sent.
    // @param value The amount of tokens.
    function manualExchange(address receiver, uint value) public {
        require(msg.sender == tokenOwner);
        require(tokensSold.add(value) <= maxGoal);
        tokensSold = tokensSold.add(value);
        assert(tokenReward.transferFrom(tokenOwner, receiver, value));
    }

    // Looks up the current token price
    function getPrice() public view returns (uint price) {
        for(uint i = 0; i < amount_stages.length; i++) {
            if(tokensSold < amount_stages[i])
                return prices[i];
        }
        return prices[prices.length-1];
    }

    modifier afterDeadline() { if (current() >= end) _; }

    // Checks if the goal or time limit has been reached and ends the campaign
    function finalize() public afterDeadline {
        require(!crowdsaleEnded);
        tokenReward.burn(); // Burn remaining tokens except the reserved ones
        emit Finalize(tokenOwner, amountRaised);
        crowdsaleEnded = true;
    }

    // Allows funders to withdraw their funds if the goal has not been reached.
    // Only works after funds have been returned from the wallet.
    function safeWithdrawal() public afterDeadline {
        uint amount = balances[msg.sender];
        if (address(this).balance >= amount) {
            balances[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit FundTransfer(msg.sender, amount, false, amountRaised);
            }
        }
    }
}