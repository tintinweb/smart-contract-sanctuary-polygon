/**
 *Submitted for verification at polygonscan.com on 2022-09-03
*/

// SPDX-License-Identifier: MIT
// File: 1.sol



pragma solidity ^0.8.7;

contract DonateContract {

  uint totalDonations; // the amount of donations
  address payable owner1; // contract creator's address

  //contract settings
  constructor() {
    owner1 = payable(msg.sender); // setting the contract creator
  }

  //public function to make donate
  function donate() public payable {
    (bool success,) = owner1.call{value: 10}("");
    require(success, "Failed to send money");
  }

  // public function to return total of donations
  function getTotalDonations() view public returns(uint) {
    return totalDonations;
  }
}

contract Ownable is DonateContract {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
  * @dev The Ownable constructor sets the original `owner` of the contract to the sender
  * account.
  */
  constructor()  {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
  * @return the address of the owner.
  */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
  * @return true if `msg.sender` is the owner of the contract.
  */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
  * @dev Allows the current owner to relinquish control of the contract.
  * @notice Renouncing to ownership will leave the contract without an owner.
  * It will not be possible to call the functions with the `onlyOwner`
  * modifier anymore.
  */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
  * @dev Allows the current owner to transfer control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
  * @dev Transfers control of the contract to a newOwner.
  * @param newOwner The address to transfer ownership to.
  */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


contract Poker is Ownable {

event NewEvent(uint256 eventID, uint price, uint eventTimeStamp);
event RSVP(uint256 eventID, uint price, uint eventTimeStamp);

function createEvent(uint256 eventID, uint256 price, uint256 eventTimeStamp) external onlyOwner() { 
    emit NewEvent(eventID, price, eventTimeStamp);
}

function newRSVP (uint256 eventID, uint price, uint eventTimeStamp) public {
    require(eventTimeStamp >= 1 days);
    emit RSVP(eventID, price, eventTimeStamp);
    donate();
}
}