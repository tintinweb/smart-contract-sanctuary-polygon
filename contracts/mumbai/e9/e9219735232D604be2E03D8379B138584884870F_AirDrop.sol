/**
 *Submitted for verification at polygonscan.com on 2022-11-19
*/

// File: contracts/Airdrop.sol


pragma solidity 0.8.17;

/**
 * @title Token
 * @dev Simpler version of ERC20 interface
 */
interface Token {
  function transfer(address to, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor()  {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract AirDrop is Ownable {

  // This declares a state variable that would store the contract address
  Token public tokenInstance;

  /*
    constructor function to set token address
   */
  constructor(address _tokenAddress)  {
    tokenInstance = Token(_tokenAddress);
  }

  /*
    Airdrop function which take up a array of address, single token amount and eth amount and call the
    transfer function to send the token 
   */
  function doAirDrop(address[] memory _address, uint256 _amount) onlyOwner public returns (bool) {
    uint256 count = _address.length;
    for (uint256 i = 0; i < count; i++)
    {
      /* calling transfer function from contract */
      tokenInstance.transfer(_address [i],_amount);
    }
    return true;
  }

  /*
    Airdrop function which take up a array of address, indvidual token amount and eth amount
   */
   function sendBatch(address[] memory _recipients, uint[] memory _values) onlyOwner public returns (bool) {
         require(_recipients.length == _values.length);
         for (uint i = 0; i < _values.length; i++) {
             tokenInstance.transfer(_recipients[i], _values[i]);
         }
         return true;
   }

  /*
    function to kill contract
  */

 
}