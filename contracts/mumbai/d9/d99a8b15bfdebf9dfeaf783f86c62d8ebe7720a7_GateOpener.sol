pragma solidity ^0.8.0;

contract GateOpener {

    address target;

    function setTarget(address gate) public {
        target = gate;
    }

    fallback() external {
        target.delegatecall{gas: 40955}(msg.data);
    }

}