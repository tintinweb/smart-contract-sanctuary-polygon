/**
 *Submitted for verification at polygonscan.com on 2022-12-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Aaltra {
    // address for the owner of the contract
    address payable public artistAddress;
    string public artistName;
    uint public investmentTotal = 1 ether;
    uint public investmentLeft = investmentTotal;
    bool public investmentComplete = false;

    // struct for the investors
    struct Investor {
        address payable investorAddress;
        string investorName;
        uint investmentAmount;
    }

    // array of payable addresses
    address payable[] public arrInvestors;

    // mapping of investors
    mapping(address => Investor) public investors;

    // new event for when an investor invests
    event Investment(address investorAddress, string investorName, uint investmentAmount);
    event RoyaltiesPaid(uint amount);
    
    // constructor
    constructor(string memory _artistName) {
        artistName = _artistName;
        artistAddress = payable(msg.sender);
    }

    // function to invest in the project
    function invest(string memory _investorName) public payable {
        require(!investmentComplete, "Investment is complete");
        require(msg.value >= 0.1 ether, "Minimum investment is 0.1 ether");
        require(msg.value <= investmentLeft, "Investment is less than what's left");
        
        // create investor struct
        Investor memory investor = Investor({
            investorAddress: payable(msg.sender),
            investorName: _investorName,
            investmentAmount: msg.value
        });

        // update investment left
        investmentLeft -= msg.value;
        if(investmentLeft == 0) {
            investmentComplete = true;
        }

        // add investor to mapping
        investors[msg.sender] = investor;

        // add investor to array
        arrInvestors.push(payable(msg.sender));

        // emit event
        emit Investment(msg.sender, _investorName, msg.value);
    }

    // function to pay investors
    function payRoyalties() public payable {
        require(investmentComplete, "Investment is not complete");
        // 50% for artist
        uint artistShare = msg.value * 50/100;
        uint investmentShare = msg.value * 50/100;

        // transfer artist share
        artistAddress.transfer(artistShare);

        // 50% for investors
        // loop over investors
        for(uint i = 0; i < arrInvestors.length; i++) {
            // get investor
            Investor memory investor = investors[arrInvestors[i]];
            // calculate investor share
            uint investorShare = (investor.investmentAmount / investmentTotal) * investmentShare;
            
            // transfer investor share        
            payable(arrInvestors[i]).transfer( investorShare * investors[arrInvestors[i]].investmentAmount / investmentTotal );


        }

        emit RoyaltiesPaid(msg.value);

    }

}