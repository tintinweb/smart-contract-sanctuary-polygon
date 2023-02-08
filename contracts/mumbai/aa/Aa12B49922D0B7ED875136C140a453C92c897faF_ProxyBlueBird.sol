// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract ProxyBlueBird {
  bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
  bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  constructor(address _add) {
    bytes32 slot = _ADMIN_SLOT;
    address _admin = msg.sender;
    assembly {
      sstore(slot, _admin)
    }
    slot = _IMPLEMENTATION_SLOT;
    assembly {
      sstore(slot, _add)
    }
  }

  function admin() public view returns (address adm) {
    bytes32 slot = _ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  function implementation() public view returns (address impl) {
    bytes32 slot = _IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  function upgrade(address newImplementation) external {
    require(msg.sender == admin(), 'admin only');
    bytes32 slot = _IMPLEMENTATION_SLOT;
    assembly {
      sstore(slot, newImplementation)
    }
  }

  fallback() external payable {
    assembly {
      let _target := sload(_IMPLEMENTATION_SLOT)
      calldatacopy(0x0, 0x0, calldatasize())
      let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)
      returndatacopy(0x0, 0x0, returndatasize())
      switch result case 0 {revert(0, 0)} default {return (0, returndatasize())}
    }
  }
}


/*
pragma solidity ^0.8.0;

contract ProxyBlueBird {

    address public delegate;
    address public owner;

    constructor(address newDelegateAddress){
      owner = msg.sender;
      delegate = newDelegateAddress;
    }

    function upgradeDelegate(address newDelegateAddress) public {
        require(msg.sender == owner);
        assembly {
          sstore(slot, newDelegateAddress)
        } 
    }

    fallback() external payable {
        assembly {
            let _target := sload(0)
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize())}
        }
    }
}

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