/**
 *Submitted for verification at polygonscan.com on 2022-10-09
*/

pragma solidity ^0.8.0;

contract payForward {

    constructor() public {}

    Donation[] public donations;
    uint public claims;

    struct Donation {
        address donor;
        uint amount;
    }

    function makeDonation() public payable returns (uint) {
        donations.push(Donation(msg.sender, msg.value));
        emit DonationMade(donations.length -1, msg.sender, msg.value);
        return donations.length - 1;
    }

    function claimPool() public returns(uint) {
        address payable claimer = payable(msg.sender);
        uint poolFunds = address(this).balance;
        claimer.transfer(address(this).balance);
        claims += 1;
        emit PoolClaimed(claims, msg.sender, poolFunds);
        return claims;
    }


    event DonationMade(uint donation_id, address donor, uint amount);
    event PoolClaimed(uint claim_num, address claimer, uint amount);

}