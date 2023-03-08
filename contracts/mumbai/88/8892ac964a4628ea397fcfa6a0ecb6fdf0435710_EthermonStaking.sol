/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

pragma solidity >=0.4.7 <0.8.0;

contract EthermonStaking {
    address public stakingPayable;

    constructor(address _stakingPayable) public {
        stakingPayable = _stakingPayable;
    }

    function sendMatic() public payable {
        EthermonStakingPayable payableStaking = EthermonStakingPayable(
            stakingPayable
        );
        payableStaking.callFunc();
    }
}

contract EthermonStakingPayable {
    event Payment(uint256 _received, address _owner);
    event Called(address _owner);

    function callFunc() public {
        emit Called(msg.sender);
    }

    function() external payable {
        emit Payment(msg.value, msg.sender);
    }
}