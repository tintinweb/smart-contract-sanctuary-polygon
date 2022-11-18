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

  mapping (uint => Holder) public deepBook;
  mapping (address => uint) public index;
  mapping(address => bool) internal authorisations; 

  event addEvent(uint indexed _holderId);

  modifier onlyOwner() {
      require(msg.sender == owner, "Only owner");
      _;
  }

  modifier onlyAllowed() {
      require(
          authorisations[msg.sender] || msg.sender == owner,
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
    ) private onlyAllowed {
      index[_holder.wallet] = holdersCount;
      deepBook[holdersCount] = Holder(_holder.name, _holder.balance, _holder.wallet, _holder.ipfsContractLink);
      holdersCount++;
  }

  function getHolder(
    address _wallet
    ) external view onlyAllowed returns(Holder memory) {
    return deepBook[index[_wallet]];
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

  function updateDeep(Holder memory _buyer, Holder memory _seller) private onlyAllowed {
    deepBook[index[_seller.wallet]].balance = _seller.balance;
    if(index[_buyer.wallet] >= 0) {
      deepBook[index[_buyer.wallet]].balance = _buyer.balance;
    } else {
      _addHolder(_buyer);
    }
  }
}