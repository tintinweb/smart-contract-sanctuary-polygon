// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

 interface IWhitelist {
        function whitelistedAddresses(address) external view returns (bool);
 }

contract UnderStandEmbedContract {

      uint amount = 0;

      IWhitelist whitelist;

   constructor () {
    }

    function setContractAddress(address _contractOneAddress ) external {
        whitelist = IWhitelist(_contractOneAddress);
    }

   
    function addAmount(uint amt) public{
				//either whitelisted user or non whitelisted and amt<=5
        require(whitelist.whitelistedAddresses(msg.sender) || (!whitelist.whitelistedAddresses(msg.sender) && amt<=5), "Non Whitelisted addresses can add only upto 5");
        //non whitelisted user with amount <=5 or whitelisted user with amount <=10
        require(!whitelist.whitelistedAddresses(msg.sender) || (whitelist.whitelistedAddresses(msg.sender) && amt<=10), "Whitelisted addresses can add only upto 10");
        amount += amt;
    }

    function getAmount() public view returns (uint256){
       return amount;
    }

}