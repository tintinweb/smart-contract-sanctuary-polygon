/**
 *Submitted for verification at polygonscan.com on 2022-12-14
*/

// File: bet.sol

// "SPDX-License-Identifier: MIT"

pragma solidity 0.8.7;
 

/** 
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable { 
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() {
        owner =  msg.sender;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Instances is Ownable{

  Session[] public contracts;
  function getContractCount() public view returns(uint contractCount) {
    return contracts.length;
  }


  function newCookie()
    public onlyOwner
    returns(Session newContract)
  {
    Session c = new Session(owner);
    contracts.push(c);
    return c;
  }
}

contract Session is Ownable {

    constructor (address _owner) payable {
        transferOwnership(_owner);
    }
  
   event EtherTransfer(address beneficiary, uint amount);

    bool bettingActive = false;
    
   uint256 devFee = 9000;

   uint256 public minimumBet;
   address payable[] public players;
   struct Player {
      uint256 amountBet;
      uint16 teamSelected;
    }

   mapping(address => Player) public playerInfo;
   receive() external payable {}
   
function kill() public { 
      if(msg.sender == owner) selfdestruct(payable(owner));
    }
function checkPlayerExists(address player) public view returns(bool){
      for(uint256 i = 0; i < players.length; i++){
         if(players[i] == player) return true;
      }
      return false;
    }
    function beginVotingPeriod()  public onlyOwner returns(bool) {
        bettingActive = true;
        return true;
    }
    


    function bet(uint8 _teamSelected) public payable {
      require(bettingActive);

      require(!checkPlayerExists(msg.sender));

      require(msg.value >= minimumBet);


      playerInfo[msg.sender].amountBet = msg.value;
      playerInfo[msg.sender].teamSelected = _teamSelected;


      players.push(payable(msg.sender));
    }

    function distributePrizes(uint16 teamWinner) public onlyOwner {
      require(bettingActive == false);
      address[1000] memory winners;

      uint256 count = 0; 
      uint256 LoserBet = 0; 
      uint256 WinnerBet = 0; 

      for(uint256 i = 0; i < players.length; i++){
         address payable playerAddress = players[i];

         if(playerInfo[playerAddress].teamSelected == teamWinner){
            winners[count] = playerAddress;
            WinnerBet += playerInfo[players[i]].amountBet;
            count++;
         }
         else
         {
             LoserBet += playerInfo[players[i]].amountBet;
         }
      }

      address add = winners[0];
      uint256 betamount = 0;
      for(uint256 j = 0; j < count; j++){
         if(winners[j] != address(0))
            add = winners[j];
            betamount = playerInfo[add].amountBet;
            payable(winners[j]).transfer((betamount*(10000+(LoserBet*devFee /WinnerBet)))/10000);
      }
      delete players;
      LoserBet = 0; 
      WinnerBet = 0;
    }
     function withdrawEther(address beneficiary) public onlyOwner {
        payable(beneficiary).transfer(address(this).balance);
    }
    function closeVoting() public onlyOwner returns (bool) {
        bettingActive = false;
        return true;
    }
    function setDevFee(uint256 newDevFee) public onlyOwner() {
    devFee = newDevFee;
  }
  function setMinBet(uint256 newMinBet) public onlyOwner() {
    minimumBet = newMinBet;
  }
}