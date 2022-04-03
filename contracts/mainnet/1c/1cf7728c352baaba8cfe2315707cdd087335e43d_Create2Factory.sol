/**
 *Submitted for verification at polygonscan.com on 2022-04-03
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

contract DeployWithCreate2 {
  address public owner;

  constructor(address _owner) {
    owner = _owner;
  }

  function getAddress() external view returns (address) {
    return address(this);
  }
}

contract Create2Factory {
  event Deploy(address addr);
  event Broadcast(bytes bytecode);

  function deploy(uint256 _salt) external {
    DeployWithCreate2 _contract = new DeployWithCreate2{ salt: bytes32(_salt) }(msg.sender);

    emit Deploy(address(_contract));
  }

  function getAddress(bytes memory bytecode, uint256 _salt) public view returns (address) {
    bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));

    return address(uint160(uint(hash)));
  }

  function getBytecode(address _owner) public  returns (bytes memory) {
    // 获取要部署的合约的机器码
    bytes memory bytecode = type(DeployWithCreate2).creationCode;

    //在这里广播一下机器码
    emit Broadcast(bytecode);

    return abi.encodePacked(bytecode, abi.encode(_owner));
  }
}