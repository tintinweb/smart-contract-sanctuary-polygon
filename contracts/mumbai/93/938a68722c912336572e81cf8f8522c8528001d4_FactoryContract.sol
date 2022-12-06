/**
 *Submitted for verification at polygonscan.com on 2022-12-05
*/

// File: Contracts/Internal.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract InternalContract {

   address sendAddress;
   uint tokenId;
   mapping(uint => Info) public infoC;
   address private owner;
   event OwnerSet(address indexed oldOwner, address indexed newOwner);

    struct Info {
     string le;
     uint am;
     uint ra;
     uint tr;
     uint di;
     uint du;
     uint update_date;
    }

   constructor(address _sendaddress, uint _tokenid) {
      sendAddress = _sendaddress;
      tokenId = _tokenid;
      owner = msg.sender;
      emit OwnerSet(address(0), owner);

   }

   modifier isOwner() {
       require(msg.sender == owner, "Caller is not owner");
       _;
   }

    function getOwner() external view returns (address) {
        return owner;
    }

    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwner() public isOwner {
         emit OwnerSet(owner, address(0));
         owner = address(0);
    }

   function update(string memory _le, uint _am, uint _ra, uint _tr, uint _di, uint _du) public isOwner {
         uint _updatedate = block.timestamp;
         infoC[0] = Info(_le, _am, _ra, _tr, _di, _du, _updatedate);
   }
}
// File: Contracts/Factory.sol

pragma solidity ^0.8.0;


contract FactoryContract {
    address[] public deployedContractsList;
    mapping(uint => Info) public infos;
    uint[] public deployedContractsNum;
    address private owner;
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    struct Info {
        uint token_id;
        address contract_add;
    }

    constructor() {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }

   modifier isOwner() {
       require(msg.sender == owner, "Caller is not owner");
       _;
   }

    function getOwner() external view returns (address) {
        return owner;
    }

    function DeployNContract(uint _tokenid) public isOwner {
        uint _id = deployedContractsNum.length + 1;
        address _sendaddress = msg.sender;
        InternalContract _deployedContract = new InternalContract(_sendaddress, _tokenid);
        address _contractaddress = address(_deployedContract);
        deployedContractsList.push(_contractaddress);
        deployedContractsNum.push(_id);
        infos[_id] = Info(_tokenid, _contractaddress);

    }
}