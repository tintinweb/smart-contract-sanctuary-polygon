/**
 *Submitted for verification at polygonscan.com on 2022-08-20
*/

// SPDX-License-Identifier: MIT 
 
 /*   THE WHEEL - The more you put in, the more odds you'll win!
 *
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Enter the Prize Pool by buying one or more tickets.
 *   2) THE WHEEL will spin when all the tickets have been sold.
 *   3) Every round, one lucky winner will receive the grand prize!
 *   4) Every n rounds, one lucky winner will receive the bonus prize!
 *
 *   [PRIZE POOL DISTRIBUTION]
 *
 *   - 85% Grand prize (1 winner)
 *   - 5%  Bonus prize (accumulates across n rounds)
 *   - 5%  Dev
 *   - 2%  Dude
 *   - 3%  Treasury
 */

pragma solidity >=0.4.22 <0.9.0;

contract TheWheel {
	using SafeMath for uint256;

    string public name = "THE WHEEL";

	uint256 public PERCENTS_DIVIDER = 1000;
    uint256 public seed;
    uint256 public ticketPrice;
    uint256 public ticketLimit;
    uint256 public roundPrize;
    uint256 public roundPrizeNET;
    uint256 public roundLength;
    uint256 public roundLimit;
    uint256 public bonusPrize;

    address public roundWinner;
    address public bonusWinner;
    address public dev;
    address public dud;
    address public ops;

    uint256 public devFee;
    uint256 public dudFee;
    uint256 public opsFee;

    address[] public roundEntries;
    address[] public bonusEntries;

    constructor(address devWallet, address dudeWallet, address opsWallet) {
        dev = devWallet;
        dud = dudeWallet;
        ops = opsWallet;

        ticketPrice = 0.1 ether;
        ticketLimit = 20;

        //prizes
        roundPrize    = ticketPrice.mul(ticketLimit);
        roundPrizeNET = roundPrize.mul(850).div(PERCENTS_DIVIDER);
        roundLimit    = 3;
        bonusPrize    = roundPrize.mul(50).mul(roundLimit).div(PERCENTS_DIVIDER);

        //fees
        devFee = roundPrize.mul(50).div(PERCENTS_DIVIDER);
        dudFee = roundPrize.mul(20).div(PERCENTS_DIVIDER);
        opsFee = roundPrize.mul(30).div(PERCENTS_DIVIDER);
    }

    function buy() public payable {
        address entrant = msg.sender;
        uint256 tickets = msg.value.div(ticketPrice);

        require(tickets >= 1, "Minimum is 1.");
        require(ticketsSold().add(tickets) <= ticketLimit, "Sold Out.");

        for (uint256 i = 0; i < tickets; i++) {
            roundEntries.push(entrant);
            bonusEntries.push(entrant);
        }

        if(ticketsSold() == ticketLimit) {
            address winner = getRoundWinner();
            delete roundEntries;

            //pay fees
            payable(dev).transfer(devFee);
            payable(dud).transfer(dudFee);
            payable(ops).transfer(opsFee);

            //new round
            roundWinner = winner;
            roundLength++;

            //pay winner
            payable(winner).transfer(roundPrizeNET);
        }

        if(roundLength == roundLimit) {
            address winner = getBonusWinner();
            delete bonusEntries;

            //new bonus
            bonusWinner = winner;
            roundLength = 0;

            //pay winner
            payable(winner).transfer(bonusPrize);
        }
    }

    function getRoundWinner() private returns (address winner){
        uint256 r = random(roundEntries.length);
        winner    = roundEntries[r];
    }

    function getBonusWinner() private returns (address winner){
        uint256 r = random(bonusEntries.length);
        winner    = bonusEntries[r];
    }

    function random(uint256 range) private returns(uint256 r) {
        r = uint256(keccak256(abi.encodePacked(seed++))) % range;
    }

    function getRoundEntries() public view returns (address [] memory) {
        return roundEntries;
    }

    function getBonusEntries() public view returns (address [] memory) {
        return bonusEntries;
    }

    function ticketsSold() public view returns (uint256) {
        return roundEntries.length;
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