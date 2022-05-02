/**
 *Submitted for verification at polygonscan.com on 2022-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

error NotOwner();
error FeeDoesNotMatch(uint256 requiredFee, uint256 suppliedFee);
error PasteIdTaken();

struct PasteStruct {
  bytes data;
  address sender;
  uint256 timestamp;
}

contract Chainpaste {

  address payable contractOwner;

  /**
  * Holds the actual pastes.
  *
  * A mapping of pairs {paste ID} => {paste structure}.
  */
  mapping (bytes => PasteStruct) pastes;

  /**
  * Fee wei requested by storePaste(...)
  *
  * Can be updated by contractOwner
  */
  uint256 fee;

  modifier MustBeOwner() {
    if(contractOwner != payable(msg.sender)) {
      revert NotOwner();
    }

    _;
  }

  modifier FeeMustMatch() {
    if(fee != msg.value) {
      revert FeeDoesNotMatch(fee, msg.value);
    }

    _;
  }

  modifier PasteIdMustBeEmpty(bytes calldata pasteId) {
    PasteStruct memory p = pastes[pasteId];

    if(p.data.length > 0 || p.sender != address(0) || p.timestamp > 0) {
      revert PasteIdTaken();
    }
    _;
  }

  constructor() {
    contractOwner = payable(msg.sender);
  }

  /******* all may be called by public *******/

  function getPaste(bytes calldata pasteId) public view returns(PasteStruct memory) {
    return pastes[pasteId];
  }

  function getFee() public view returns(uint256) {
    return fee;
  }

  function storePaste(
    bytes calldata pasteId, 
    bytes calldata pasteContent,
    bool storeSender,
    bool storeTimestamp
  ) public payable FeeMustMatch PasteIdMustBeEmpty(pasteId) {
    PasteStruct memory Paste;
    Paste.data = pasteContent;

    if(storeSender) {
      Paste.sender = msg.sender;
    }

    if(storeTimestamp) {
      Paste.timestamp = block.timestamp;
    }

    pastes[pasteId] = Paste;
  }

  /******* all may be called by contractOwner *******/

  function deletePaste(bytes calldata pasteId) public MustBeOwner {
    delete pastes[pasteId];
  }

  function drainFunds() external MustBeOwner {
    contractOwner.call{value: address(this).balance}("");
  }

  function setFee(uint256 newFee) public MustBeOwner {
    fee = newFee;
  }
}