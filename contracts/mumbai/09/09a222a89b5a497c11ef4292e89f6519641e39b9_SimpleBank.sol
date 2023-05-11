/**
 *Submitted for verification at polygonscan.com on 2023-05-11
*/

pragma solidity 0.6.6;


contract SimpleBank { // CapWords
    
    mapping (address => uint) private balances;

    address public owner;
    event LogDepositMade(address accountAddress, uint amount);

    // Constructor, can receive one or many variables here; only one allowed
    constructor() public {
        owner = msg.sender;
    }


    function deposit() public payable returns (uint) {
        // Use 'require' to test user inputs, 'assert' for internal invariants
        // Here we are making sure that there isn't an overflow issue
        require((balances[msg.sender] + msg.value) >= balances[msg.sender]);

        balances[msg.sender] += msg.value;
        // no "this." or "self." required with state variable
        // all values set to data type's initial value by default

        emit LogDepositMade(msg.sender, msg.value); // fire event

        return balances[msg.sender];
    }


    function withdraw(uint withdrawAmount) public returns (uint remainingBal) {
        require(withdrawAmount <= balances[msg.sender]);

        balances[msg.sender] -= withdrawAmount;

        // this automatically throws on a failure, which means the updated balance is reverted
        msg.sender.transfer(withdrawAmount);

        return balances[msg.sender];
    }

    function balance() view public returns (uint) {
        return balances[msg.sender];
    }
}