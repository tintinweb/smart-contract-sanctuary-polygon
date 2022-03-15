// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Proxy.sol";
import "./UpgradeabilityStorage.sol";

contract UpgradeabilityProxy is Proxy, UpgradeabilityStorage 
{
  

  event Upgraded(string version, address indexed implementation);
  function upgradeTo(string memory version, address implementationaddress) public {
    require(_implementation != implementationaddress);
    _version = version;
    _implementation = implementationaddress;
    emit Upgraded(version, implementationaddress);
  }

  function implementation() public virtual override view returns (address){
    return _implementation;
  }
  

}