/**
 *Submitted for verification at polygonscan.com on 2022-04-04
*/

// File: contracts/interfaces/RandomnessConsumer.sol

pragma solidity ^0.8.0;

interface RandomnessConsumer {
    function receiveRandomInt(uint256 randomInt) external;
}

// File: contracts/interfaces/RandomnessProvider.sol

pragma solidity ^0.8.0;

interface RandomnessProvider {
    function requestRandomness() external;
}

// File: contracts/test/TestRandomnessProvider.sol

pragma solidity ^0.8.0;
contract TestRandomnessProvider is RandomnessProvider {

    address lastRequester;

    function requestRandomness() public {
        lastRequester = msg.sender;
    }

    function sendRandomness(uint256 r) public {
        require(lastRequester != address(0));
        RandomnessConsumer(lastRequester).receiveRandomInt(r);
    }
}