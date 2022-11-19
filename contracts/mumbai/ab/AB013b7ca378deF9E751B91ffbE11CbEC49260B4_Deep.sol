// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

contract Deep {

  address public owner;
  uint private holdersCount;

  struct Holder {
    string name;
    uint balance;
    address wallet;
    string ipfsContractLink;
  }

  struct Index {
     uint val;
     bool isValue;
   }

  mapping (uint => Holder) public deepBook;
  mapping (address => Index) public index;
  mapping(address => bool) internal authorisations; 

  // event addEvent(uint indexed _holderId);

  modifier onlyOwner() {
      require(msg.sender == owner, "Only owner");
      _;
  }

  modifier onlyAllowed() {
      require(
          msg.sender == owner || authorisations[msg.sender],
          "only allowed"
      );
      _;
  }

  constructor() {
      owner = msg.sender;
      holdersCount = 0;
  }

  function _addHolder(
    Holder memory _holder
    ) private {
      index[_holder.wallet].val = holdersCount;
      index[_holder.wallet].isValue = true;
      deepBook[holdersCount] = Holder(_holder.name, _holder.balance, _holder.wallet, _holder.ipfsContractLink);
      holdersCount++;
  }

  function getHolder(
    address _wallet
    ) external view onlyAllowed returns(Holder memory) {
    return deepBook[index[_wallet].val];
  }

  function getDeep() external view onlyAllowed returns(Holder[] memory) {
    Holder[] memory holder;
    for (uint i = 0; i <= holdersCount; i++) {
      if(deepBook[i].balance > 0) {
        holder[i] = Holder(
        deepBook[i].name,
        deepBook[i].balance, 
        deepBook[i].wallet, 
        deepBook[i].ipfsContractLink 
        );
      }
    }
    return holder;
  }

  function updateDeep(Holder memory _buyer, Holder memory _seller) external onlyAllowed {
    if(index[_seller.wallet].isValue) {
      deepBook[index[_seller.wallet].val].balance = _seller.balance;
    } else {
      _addHolder(_seller);
    }
    if(index[_buyer.wallet].isValue) {
      deepBook[index[_buyer.wallet].val].balance = _buyer.balance;
    } else {
      _addHolder(_buyer);
    }
  }
}