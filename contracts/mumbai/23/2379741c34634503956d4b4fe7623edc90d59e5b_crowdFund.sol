/**
 *Submitted for verification at polygonscan.com on 2022-02-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract crowdFund{
    uint id = 0;
    struct donation{
        uint fund_id;
        uint amount;
        uint amount_got;
        address payable aggregator;
        string title;
        string details;
        address[] givers;
        uint[] amount_given;
        uint256[] timestamp;
    }
    donation[] public donations;

    function setDonations(string memory _title, string memory _details, address payable _address, uint _amount) public {
        donation memory Donation;
        Donation.fund_id = id;
        Donation.amount = _amount;
        Donation.amount_got = 0;
        Donation.aggregator = _address;
        Donation.title = _title;
        Donation.details = _details;
        donations.push(Donation);
        id+=1;
    }

    function getDonations(uint _index) public view returns (string memory title, string memory details, uint amount,uint amount_got) {
        donation storage Donation = donations[_index];
        return (Donation.title, Donation.details , Donation.amount, Donation.amount_got);
    }

    function sendBal(uint _index, uint amount) public payable {
        donation storage Donation = donations[_index];
        Donation.aggregator.transfer(amount);
        Donation.amount_got+=amount/(10**18);
        Donation.givers.push(msg.sender);
        Donation.amount_given.push(amount/(10**18));
    }

    function getTransactions(uint _index) public view returns(address[] memory givers, uint[] memory amount_given){
        donation storage Donation = donations[_index];
        return (Donation.givers, Donation.amount_given);
    }


}