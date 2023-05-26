/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

// Version of Solidity compiler this program was written for
pragma solidity ^0.5.11;

// Heads or tails game contract
contract HeadsOrTails {
  address payable owner;
  string public name;

  struct Game {
    address addr;
    uint amountBet;
    uint8 guess;
    bool winner;
    uint ethInJackpot;
  }

  Game[] lastPlayedGames;

  //Log game result (heads 0 or tails 1) in order to display it on frontend
  event GameResult(uint8 side);

  // Contract constructor run only on contract creation. Set owner.
  constructor() public {
    owner = msg.sender;
    name = "Heads or Tails dApp";
  }

  //add this modifier to functions, which should only be accessible by the owner
  modifier onlyOwner {
    require(msg.sender == owner, "This function can only be launched by the owner");
    _;
  }

  //Play the game!
  function lottery(uint8 guess) public payable returns(bool){
    require(guess == 0 || guess == 1, "Variable 'guess' should be either 0 ('heads') or 1 ('tails')");
    require(msg.value > 0, "Bet more than 0");
    require(msg.value <= address(this).balance - msg.value, "You cannot bet more than what is available in the jackpot");
    //address(this).balance is increased by msg.value even before code is executed. Thus "address(this).balance-msg.value"
    //Create a random number. Use the mining difficulty & the player's address, hash it, convert this hex to int, divide by modulo 2 which results in either 0 or 1 and return as uint8
    uint8 result = uint8(uint256(keccak256(abi.encodePacked(block.difficulty, msg.sender, block.timestamp)))%2);
    bool won = false;
    if (guess == result) {
      //Won!
      msg.sender.transfer(msg.value * 2);
      won = true;
    }

    emit GameResult(result);
    lastPlayedGames.push(Game(msg.sender, msg.value, guess, won, address(this).balance));
    return won; //Return value can only be used by other functions, but not within web3.js (as of 2019)
  }

  //Get amount of games played so far
  function getGameCount() public view returns(uint) {
    return lastPlayedGames.length;
  }

  //Get stats about a certain played game, e.g. address of player, amount bet, won or lost, and ETH in the jackpot at this point in time
  function getGameEntry(uint index) public view returns(address addr, uint amountBet, uint8 guess, bool winner, uint ethInJackpot) {
    return (
      lastPlayedGames[index].addr,
      lastPlayedGames[index].amountBet,
      lastPlayedGames[index].guess,
      lastPlayedGames[index].winner,
      lastPlayedGames[index].ethInJackpot
    );
  }

  // Contract destructor (Creator of contract can also destroy it and receives remaining ether of contract address).
  //Advantage compared to "withdraw": SELFDESTRUCT opcode uses negative gas because the operation frees up space on
  //the blockchain by clearing all of the contract's data
  function destroy() external onlyOwner {
    selfdestruct(owner);
  }

  //Withdraw money from contract
  function withdraw(uint amount) external onlyOwner {
    require(amount < address(this).balance, "You cannot withdraw more than what is available in the contract");
    owner.transfer(amount);
  }

  // Accept any incoming amount
  function () external payable {}
}