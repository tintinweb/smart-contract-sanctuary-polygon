/**
 *Submitted for verification at polygonscan.com on 2022-06-05
*/

// File: contracts/DaiFaucet.sol

pragma solidity ^0.5.9;


interface DaiToken {
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external  returns (uint);
}

contract owned {
    DaiToken daitoken;
    address owner;

    constructor() public{
        owner = msg.sender;
        daitoken = DaiToken(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    }

    modifier onlyOwner {
        require(msg.sender == owner,
        "Only the contract owner can call this function");
        _;
    }
}

contract mortal is owned {
    // Only owner can shutdown this contract.
    function destroy() public onlyOwner {
        daitoken.transfer(owner, daitoken.balanceOf(address(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063)));
        selfdestruct(msg.sender);
    }
}

contract DaiFaucet is mortal {

    event Withdrawal(address indexed to, uint amount);
    event Deposit(address indexed from, uint amount);

    // Give out Dai to anyone who asks
    function withdraw(uint withdraw_amount) public {
        // Limit withdrawal amount
        require(withdraw_amount >= 100 ether);
        require(daitoken.balanceOf(address(this)) >= withdraw_amount,
            "sufficient balance in  for withdrawal request");
        // Send the amount to the address that requested it
        daitoken.transfer(msg.sender, withdraw_amount);
        emit Withdrawal(msg.sender, withdraw_amount);
    }

    // Accept any incoming amount
    function () external payable {
        emit Deposit(msg.sender, msg.value);
    }
}