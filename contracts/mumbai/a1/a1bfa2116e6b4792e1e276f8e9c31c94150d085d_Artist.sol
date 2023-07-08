/**
 *Submitted for verification at polygonscan.com on 2023-07-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// TODO1: create new contract
contract Artist {
    
    // (optional) todo 7: trigger an event when an investment was made
    // (optional) todo 8: trigger an event when a payment was made
    event Investment(address investorAddress, uint amount);
    event Payout(uint amount);
    
    address payable public artistAddress;
    uint public nrOfInvestors;
    string public artistName;
    uint public artistInvestmentRequired = 1 ether;
    uint public artistInvestmentStillRequired = artistInvestmentRequired;
    bool public artistInvestMentComplete = false;
    
    struct Investor {
        address payable investorAddress;
        uint investment;
        string name;
    }
    
    address payable[] public arrInvestors;
    mapping (address => Investor) public investors;
    
    // TODO3: a constructor that takes a parameter _name for our artist and sets the owner address
    constructor(string memory _name) {
        artistName = _name;
        artistAddress = payable(msg.sender);
    }
    
    
    // TODO4: a mmethod getInvestors() that returns the investors for our frontend
    function getInvestors() external view returns (address payable[] memory _investors) {
        return arrInvestors;
    }
    
    // TODO5: a function invest() that allows investing in our artist
    // - minimum amount must be 0.1 ether
    // - an investor can only invest once in this artist
    // - an investor can only invest if there is an open investment amount
    // - an investor can only invest if there is room to invest left
    // - add the payable address to our array so that we can pay the investor later on
    // - add the investor details to our mapping
    function invest (string memory _investorName) payable public {
        require(msg.value >= 0.1 ether, "Value must be at least 0.1 ETH to participate.");
        require(investors[msg.sender].investment == 0, "You can only invest once.");
        require(artistInvestMentComplete != true, "Investing isn't possible anymore.");
        require(artistInvestmentStillRequired >= msg.value, "You need to invest the exact amount still available.");
        
        artistInvestmentStillRequired -= msg.value;
        if(artistInvestmentStillRequired == 0) {
            artistInvestMentComplete = true;
        }
        investors[msg.sender] = Investor({ investorAddress: payable(msg.sender), investment: msg.value, name: _investorName });
        arrInvestors.push(payable(msg.sender));
        nrOfInvestors++;
        emit Investment(msg.sender, msg.value);
    }
    
    // TODO6: a function payRoyalties() that shares the royalties with the artist and investors 50/50 in this example
    // - note, we could make this distribution flexible with additional methods
    function payRoyalties() public payable returns(bool success) {
        require(msg.value > 0);
        uint amountArtist = msg.value * 50/100;
        uint amountInvestors = msg.value * 50/100;
        payable(artistAddress).transfer(amountArtist);
        for(uint i = 0; i < arrInvestors.length; i++) {
            payable(arrInvestors[i]).transfer( amountInvestors * investors[arrInvestors[i]].investment / artistInvestmentRequired );
        }
        emit Payout(msg.value);
        return true;
    }
    

    
}