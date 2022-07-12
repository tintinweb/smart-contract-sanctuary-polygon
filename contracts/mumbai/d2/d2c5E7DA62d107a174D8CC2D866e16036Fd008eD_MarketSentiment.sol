// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MarketSentiment{
    address public owner; //1 owner
    string[] public cryptoArray; //To store cryptos which are available

constructor(){
    owner = msg.sender; // Initiater is the owner
}
struct crypto{
    bool exists; //whether crypto is available to show
    uint256 up; //How many Upvotes
    uint256 down; //How many Downvotes
    mapping(address => bool) Voters; /// Voters address is check whether they have voted or not(It is an internal mapping so it will be an atribute)
}
//Events are fired when user makes a action just like clicking 
// or sending a response to the chain 

event cryptoUpdated(
    uint256 up,   
    uint256 down,
    address voter,
    string crypto
);
mapping(string => crypto) private Crypto; //BTC,ETH,BSB,Matic short names as string to get the cryptos

function addCrypto(string memory _crypto) public { //Function to add crypto 
    require(msg.sender == owner,"only owner can add crypto");
    crypto storage newCrypto  = Crypto[_crypto]; //We stored the new _crypto (string) into the mapping and made a temporary variable for updating the crypto values  
    newCrypto.exists = true; //Now crypto is added becoz it now exists
    cryptoArray.push(_crypto);
}

function vote(string memory _crypto ,bool _vote ) public{
    require(Crypto[_crypto].exists == true,"Cant vote on this coin"); //check if the coin exists
    require((Crypto[_crypto].Voters[msg.sender]) == false,"You have already voted"); //check if voter has already voted or not 

    crypto storage t = Crypto[_crypto]; //We stored the new _crypto (string) into the mapping and made a temporary variable for updating the crypto values  
    t.Voters[msg.sender] == true; //Make the voter as true(Voted) using t as a variable

    if(_vote == true){ 
        t.up+=1;
    }
    else{
        t.down+=1;
    }
emit cryptoUpdated(t.up, t.down, msg.sender, _crypto);
}
function getVotes(string memory _crypto) public view returns(uint256 up,uint256 down){ //Function for returning the votes
    require(Crypto[_crypto].exists == true);
    crypto storage t = Crypto[_crypto];
    return(t.up,t.down);
}


}