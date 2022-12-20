/**
 *Submitted for verification at polygonscan.com on 2022-12-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Aaltra {
    // properties are public by default
    address payable public artistAddress;
    string public artistName;
    uint public investmentTotal = 1 ether; // ether, gwei and wei can be used 
    uint public investmentLeft = investmentTotal;
    bool public investmentComplete = false; // no computed value since it's less expensive to set this once rather than calculating it all the time

    // struct for the investors
    struct Investor {
        address payable investorAddress;
        string investorName;
        uint investorAmount;
    }

    // array of payable addresses
    address payable[] public arrInvestors;

    // mapping of investors (mapping because it's cheaper)
    mapping(address => Investor) public investors;

    // new event for when investors invests
    event Investment(address investorAddress, string investorName, uint investmentAmount);

    // new event for when royalties are payed
    event RoyaltiesPayed(uint royaltiesAmount);

    // constructor
    constructor(string memory _artistName) {
        artistName = _artistName;
        artistAddress = payable(msg.sender);
    }

    // function to invest in the project
    function invest(string memory _investorName) public payable { 
        require(!investmentComplete, "No more investment left");
        require(msg.value >= 0.1 ether, "Minimum investment is 0.1 ether");
        require(msg.value <= investmentLeft, "Not enough investment left");

        // create investor struct
        Investor memory investor = Investor({
            investorAddress: payable(msg.sender),
            investorName: _investorName,
            investorAmount: msg.value
        });

        // update investment left
        investmentLeft -= msg.value;
        if (investmentLeft == 0) investmentComplete = true;

        // add investor to mapping
        investors[msg.sender] = investor;

        // add investor to array
        arrInvestors.push(payable(msg.sender));

        // emit event
        emit Investment(msg.sender, _investorName, msg.value);
    }

    // function to pay investors
    function payRoyalties() public payable {
        require(investmentComplete, "Investment is not yet complete");
        
        uint artistShare = msg.value / 2;
        uint investmentShare = msg.value - artistShare;

        // transfer artist share
        artistAddress.transfer(artistShare);

        for (uint i = 0; i < arrInvestors.length; i++) {
            // get investor
            Investor memory investor = investors[arrInvestors[i]];
            // calculate investor share
            uint investorShare = (investor.investorAmount / investmentTotal) * investmentShare;
            // transfer investor share
            payable(investor.investorAddress).transfer(investorShare);
        }

        emit RoyaltiesPayed(msg.value);
    }
}

// TODO1: create new contract

    
    // (optional) todo 7: trigger an event when an investment was made
    // (optional) todo 8: trigger an event when a payment was made
    
    // TODO2: what do you want to store on the contract?
    // a payable address for the artist/owner (artistAddress)
    // a counter to keep track of the number of investors (nrOfInvestors)
    // a name for our artist (artistName)
    // an ETH amount to be invested (artistInvestmentRequired) in ether or wei 
    // an ETH amount that is still available for investors to participate
    // a boolean that tell us if the full invested has been done (artistInvestMentComplete)
    // a structure that can hold investor details (payable address, investment amount, investor name) (Investor)
    // an array of payable addresses so that we can pay our investors later on (arrInvestors)
    // a mapping that keeps track of investors (this allows for cheap checks e.g. has investor already invested?) (investors)
 
    // TODO3: a constructor that takes a parameter _name for our artist and sets the owner address
    
    // TODO4: a mmethod getInvestors() that returns the investors for our frontend
    
    // TODO5: a function invest() that allows investing in our artist
    // - minimum amount must be 0.1 ether
    // - an investor can only invest once in this artist
    // - an investor can only invest if there is an open investment amount
    // - an investor can only invest if there is room to invest left
    // - add the payable address to our array so that we can pay the investor later on
    // - add the investor details to our mapping
    
    // TODO6: a function payRoyalties() that shares the royalties with the artist and investors 50/50 in this example
    // - note, we could make this distribution flexible with additional methods