pragma solidity ^0.5.0;

import "./RewardKaran.sol";

contract RWDAirdrop {
    string public name = "RWD Airdrop";
    RewardKaran public testToken;

    //declaring owner state variable
    address public owner;


    constructor(RewardKaran _testToken) public payable {
        testToken = _testToken;

        //assigning owner on deployment
        owner = msg.sender;
    }

    //stake tokens function


    //cliam test 1000 Tst (for testing purpose only !!)
    function claimTst() public {
        address recipient = msg.sender;
        uint256 tst = 1000000000000000000000;
        uint256 balance = tst;
        testToken.transfer(recipient, balance);
    }
}