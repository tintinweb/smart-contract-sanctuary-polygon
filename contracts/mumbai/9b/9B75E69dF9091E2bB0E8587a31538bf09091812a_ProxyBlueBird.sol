// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ProxyBlueBird {
  address public implementation;

  constructor(address _implementation) {
    implementation = _implementation;
  }

  function upgradeTo(address _newImplementation) public {
    implementation = _newImplementation;
  }

  function call(bytes memory _data) public {
    (bool success, ) = implementation.call(_data);
    require(success, "Call to implementation failed.");
  }
}

/*
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

// Kept for backwards compatibility with older versions of Hardhat and Truffle plugins.
contract AdminUpgradeabilityProxy is TransparentUpgradeableProxy {
    constructor(address logic, bytes memory data) payable TransparentUpgradeableProxy(logic, msg.sender, data) {}
}

/*

pragma solidity ^0.8.0;

contract Proxy{
    address public implementation;
    address public immutable owner;


    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor(address _implementation) {
        owner = msg.sender;
        implementation = _implementation;
    }

    function upgradeTo(address _implementation) public onlyOwner {
        implementation = _implementation;
    }

    function execute(bytes memory _data) public {
        (bool success,) = address(implementation).delegatecall(_data);
        require(success);
    }
}
*/