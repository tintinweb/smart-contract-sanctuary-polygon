pragma solidity 0.8.0;

contract returnVal{
    function returnTime() external view returns(uint){
        return block.timestamp;
    }

    address public admin;
    constructor(){
        admin = msg.sender;
    }

    function votingPeriod() public pure returns (uint) { return 5 minutes; } 

    uint public val;
    uint public finall = 2;
    uint public final2 = 3;

    function testing() public returns(uint){
        val = finall;
        require(msg.sender == admin,"you are not owner");
        val = final2;
        return val;
    }


}