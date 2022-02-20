/**
 *Submitted for verification at polygonscan.com on 2022-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.5.10;


contract MaticGame {
    using SafeMath for uint256;

    // Contract Variables
    uint public totalInvestors;
    uint public totalInvested;
    uint public totalRefRewards;
    uint public tax;
    uint public ref;
    uint256 constant public TIME_STEP = 1 seconds;

    // Lockup Period and Returns
    struct Tariff {
        uint time;
        uint percent;
    }

    // Deposit Data Structure
    struct Deposit {
        uint tariff;
        uint amount;
        uint initamount;
        uint at;
        uint256 finish;
    }

    // Investor Data Structure
    struct Investor {
        bool registered;
        address referrer;
        uint referral_counter;
        uint balanceRef;
        uint totalRef;
        Deposit[] deposits;
        uint invested;
        uint lastPaidAt;
        uint withdrawn;
    }


    Tariff[] public tariffs;

    mapping(address => Investor) public investors;
    // Variable that starts the contract

    // Deployer smart contract that is only able to change tax and ref percentages within a predefined bound
    address payable public owner;

    event InvestedAt(address user, uint value);

    // Initial contract settings
    constructor() public {
        owner = msg.sender;
        tax = 5;
        ref = 7;
        // Set owner as investor to handle players without a referrer
        totalInvestors++;
        investors[msg.sender].registered = true;
        tariffs.push(Tariff(14 days, 100));
    }

    // Invest function, takes referrer as input and checks that the amount is bigger than 10 MATIC
    function invest(address payable referrer) public minimumInvest(msg.value) payable {
        uint tariff = 0;
        // Only 1 deposit is possible per player
        require(!investors[msg.sender].registered, "You have already deposited into the game");
        // You cannot set yourself as referrer
        require(referrer != msg.sender && investors[referrer].registered, "You need a valid referrer that is not yourself");
        // Update Game Stats
        if (!investors[msg.sender].registered) {
            totalInvestors++;
            investors[msg.sender].registered = true;

            if (investors[referrer].registered && referrer != msg.sender) {
                investors[msg.sender].referrer = referrer;
                investors[referrer].referral_counter++;
            }
        }

        investors[referrer].balanceRef += msg.value * 5 / 100;
        investors[referrer].totalRef += msg.value * 5 / 100;
        totalRefRewards += msg.value * 5 / 100;


        investors[msg.sender].invested += msg.value;
        totalInvested += msg.value;
        // Get time the lock period ends
        uint256 finish = block.timestamp.add(tariffs[tariff].time.mul(TIME_STEP));

        // Get deducted fees according to current contract tax
        uint256 fees = msg.value * tax / 100;
        // Record Deposit information
        investors[msg.sender].deposits.push(Deposit(tariff, msg.value - fees, msg.value - fees, block.timestamp, finish));
        // Send taxed amount to deployer wallet
        owner.transfer(fees);
        // Send referral amount to referrer wallet
        referrer.transfer(msg.value * ref / 100);
        emit InvestedAt(msg.sender, msg.value);

    }

    // Withdrawable function, takes user address as input and returns the rewards amount, whether it is unlocked, and the amount of time left in the lock period in seconds
    function withdrawable(address user) public view returns (uint amount, bool decision, uint finish){
        // Fetch deposit of calling user
        Deposit storage dep = investors[user].deposits[0];

        // Check whether the current block has surpassed the lock period
        decision = block.timestamp > dep.finish && investors[user].withdrawn == 0;
        // Get the reward amount
        amount = dep.amount;
        // Get the amount of time (in seconds) left until the lock period ends
        if (!decision)
            finish = (dep.finish - block.timestamp).div(TIME_STEP);
        if (investors[user].withdrawn > 0) {
            finish = 0;
        }

    }

    // Withdraw function
    function withdraw() public {
        // Get investor structure of calling player
        Investor storage investor = investors[msg.sender];
        // Get amount to be rewarded and whether the reward is unlocked
        (uint amount, bool decision,) = withdrawable(msg.sender);
        // Function fails if funds are still locked
        require(decision, 'You need to wait 14 days');

        investor.lastPaidAt = block.number;

        // Check that there is enough balance, otherwise give what is left of the balance
        uint256 contractBalance = address(this).balance;
        if (contractBalance < amount) {
            amount = contractBalance;
        }
        // Check if player has rewards otherwise withdraw will fail
        require(amount > 0, "User has no dividends");

        // Send reward to player's wallet
        msg.sender.transfer(amount);
        investor.withdrawn += amount;
        investor.balanceRef = 0;
        // Set the new amounts to 0 as the player no longer is a part of the game
        investors[msg.sender].deposits[0].amount = 0;
        investors[msg.sender].deposits[0].initamount = 0;

    }

    // Extend function
    function extend() public {
        // Get withdrawing details
        (uint amount, bool decision,) = withdrawable(msg.sender);
        // Rewards have to be unlocked
        require(decision, 'You need to wait until the end of the lockup period');
        // Update new lock period end and new rewards
        investors[msg.sender].deposits[0] = Deposit(0, amount + investors[msg.sender].deposits[0].initamount, investors[msg.sender].deposits[0].initamount, block.timestamp, block.timestamp.add(tariffs[0].time.mul(TIME_STEP)));
    }
    // Change tax amount (maximum of 10%)
    function changeTax(uint newTax) onlyOwner public {
        if (newTax <= 10) {
            tax = newTax;
        }
    }

    // Change referral amount (min 3% and max 7%)
    function changeRef(uint newRef) onlyOwner public {
        if (newRef <= 7 && newRef >= 3) {
            tax = newRef;
        }
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    modifier minimumInvest(uint val){
        require(val >= 10 * 1000000000000000000, "Minimum invest is 0.1 MATIC");
        _;
    }

    modifier onlyOwner(){
        require(owner == msg.sender, "Only owner !");
        _;
    }

}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}