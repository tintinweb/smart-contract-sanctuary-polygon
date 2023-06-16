// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract GiveMeMoney {

    //Address of contract deployer
    address payable owner;

    //Deploy Logic.
    constructor () {
        owner = payable(msg.sender);

    }

    function sendMoney() public payable {
        require(msg.value > 0, "can't send me 0"); 
        //Condição para não receber um valor igual a 0, sempre maior.   
        
    }

        /**
        * @dev send the entire balance stored in this contract to the owner
        */
        function withdrawTips() public {
            require(owner.send(address(this).balance));

        }

}