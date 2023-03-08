/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.7 <0.8.0;

contract EthermonStakingPayable {
    event Payment(uint256 _received, address _owner);
    event Called(address _owner);

    function callFunc() public {
        emit Called(msg.sender);
    }

    receive() external payable {
        emit Payment(msg.value, msg.sender);
    }
}

contract EthermonStaking is EthermonStakingPayable {
    address public stakingPayable;

    constructor(address _stakingPayable) public {
        stakingPayable = _stakingPayable;
    }

    function setStakingPayable(address _stakingPayable) external {
        stakingPayable = _stakingPayable;
    }

    function sendMatic() public payable {
        EthermonStakingPayable payableStaking = EthermonStakingPayable(
            payable(stakingPayable)
        );
        payableStaking.callFunc();
    }
}