/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

pragma solidity ^0.8.9;

contract PhantomBroadcast {

  struct Dapp {
    string displayName;
    string logoURI;
    address[] adminAddresses;
    address[] broadcastAddresses;
    string[] broadcasts;
    bool verified;
  }

  uint public nextDappId;
  mapping(uint => Dapp) public registeredDapps;

  event BroadcastMessage(string messageText);

  constructor() {
    nextDappId = 0;
  }

  function validBroadcastAddressForDapp(uint dappId, address lookupAddress) public view returns (bool) {
    for (uint i = 0; i < registeredDapps[dappId].broadcastAddresses.length; i++) {
      if(registeredDapps[dappId].broadcastAddresses[i] == lookupAddress) {
        return true;
      }
    }
    return false;
  }

  function registerDapp(string memory displayName, string memory logoURI) public returns (uint) {
    uint targetDappId = nextDappId;

    address[] memory adminAddresses = new address[](1);
    adminAddresses[0] = msg.sender;

    address[] memory broadcastAddresses = new address[](1);
    broadcastAddresses[0] = msg.sender;

    string[] memory broadcasts = new string[](0);

    registeredDapps[targetDappId] = Dapp({
      displayName: displayName,
      logoURI: logoURI,
      adminAddresses: adminAddresses,
      broadcastAddresses: broadcastAddresses,
      broadcasts: broadcasts,
      verified: false
    });

    nextDappId++;
    return targetDappId;
  }

  function addBroadcastAddressToDapp(uint dappId, address broadcastAddress) public returns (bool) {
    require(validBroadcastAddressForDapp(dappId, msg.sender), "Invalid admin address for dapp");
    require(!validBroadcastAddressForDapp(dappId, broadcastAddress), "Broadcast address already exists for dapp");
    registeredDapps[dappId].broadcastAddresses.push(broadcastAddress);
    return true;
  }

  function broadcastMessageForDapp(uint dappId, string memory messageText) public returns (bool) {
    require(validBroadcastAddressForDapp(dappId, msg.sender), "Invalid broadcast address for dapp");
    registeredDapps[dappId].broadcasts.push(messageText);
    emit BroadcastMessage(messageText);
    return true;
  }


}