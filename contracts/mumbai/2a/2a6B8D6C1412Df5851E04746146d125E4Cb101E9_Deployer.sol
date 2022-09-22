/**
 *Submitted for verification at polygonscan.com on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IModule {
  function getModule(uint module_) external view returns (address);
}

interface IRelayer {
  function isTrustedForwarder(address) external view returns (bool);
}

contract Proxy {
  address public callee;
  address public deployer;

  constructor (address callee_, address deployer_) {
    callee = callee_;
    deployer = deployer_;
  }

  fallback() external {
    assembly {
      let _target := sload(0)                                                  /* Load the target from storage slot 1 */
      calldatacopy(0x0, 0x0, calldatasize())                                   /* Copy the calldata to memory position f to mem at position t*/    
      let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)  /* Call the target with calldata */
      returndatacopy(0x0, 0x0, returndatasize())
      switch result
        case 0  { revert(0, returndatasize()) }
        default { return (0, returndatasize()) }  
    }
  }
}

contract Deployer {
  /**
   * @notice Module Manager instance
   */
  IModule moduleManager;

  /**
   * @notice Relayer instance
   */
  IRelayer relayer;

  /**
   * @notice Builder
   */
  constructor (address moduleAddress_) {
    moduleManager = IModule(moduleAddress_);
    relayer = IRelayer(moduleManager.getModule(4));
  }

  /**
   * @notice Only allowed addresses
   */
  modifier onlyTrustedForwarder {
    require(relayer.isTrustedForwarder(msg.sender), '{msg.sender} has to be a trusted forwarder');
    _;
  }

  /**
   * @notice Fired when a contract is deployed
   */
  event Deployed(address newContract);

  /**
   * @notice Function to deploy a contract
   * @param logic The logic contract address
   * @param user The user address
   */
  function deploy(address logic, address user) public onlyTrustedForwarder returns (address newContract) {
    newContract = address(new Proxy(logic, user));
    emit Deployed(newContract);
  }

  /**
   * @notice Refresh the modules
   */
  function refresh() public onlyTrustedForwarder {
    relayer = IRelayer(moduleManager.getModule(4));
  }

}