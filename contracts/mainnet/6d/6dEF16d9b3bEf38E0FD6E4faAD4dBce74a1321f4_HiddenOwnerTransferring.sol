pragma solidity ^0.5.0;

contract HiddenOwnerTransferring {
    address public owner;
    uint[] private bonusCodes;

    constructor() public {
        bonusCodes = new uint[](0);
        owner = msg.sender;
    }

    function PushBonusCode(uint c) public {
        bonusCodes.push(c);
    }

    function PopBonusCode() public {
        require(0 <= bonusCodes.length);
        bonusCodes.length--;
    }

    function UpdateBonusCodeAt(uint idx, uint c) public {
        require(idx < bonusCodes.length);
        bonusCodes[idx] = c;
    }
}