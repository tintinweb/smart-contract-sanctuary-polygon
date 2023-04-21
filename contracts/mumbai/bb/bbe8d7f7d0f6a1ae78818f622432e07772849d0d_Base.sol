/**
 *Submitted for verification at polygonscan.com on 2023-04-20
*/

// SPDX-License-Identifier: MIT 

pragma solidity 0.8.19;


contract Base{


    address public owner ;


    mapping (address => bool) public whitelist;
    address[] public Whitelisted_Hospitals;

    constructor(){

        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner{
        // require(msg.sender == owner, "Only the contract owner can transfer ownership"); // Make sure only the current owner can transfer ownership
        owner = newOwner;
    }

    function addToWhitelist(address _address) external onlyOwner{
        // require(msg.sender == owner); // Make sure only the contract owner can add to the whitelist

    if(whitelist[_address]){
        revert("Already whitelisted!");
    }
    else{

        whitelist[_address] = true;
        Whitelisted_Hospitals.push(_address);
    }
    }


    function findIndex(address _addr) internal view returns(uint){
        uint c;
        for(uint i=0;i<Whitelisted_Hospitals.length;i++){
            if(Whitelisted_Hospitals[i]==_addr){
                c = i;
                break;
            }
            
        }
        return c;
    }

    function removeFromWhitelist(address _address) external onlyOwner{
        // require(msg.sender == owner); // Make sure only the contract owner can remove from the whitelist
        
        if(!whitelist[_address]){
            revert("Not Whitelisted!");
        }else{
            whitelist[_address] = false;

            uint index = findIndex(_address);

            require(index < Whitelisted_Hospitals.length, "Index out of bounds");

            for(uint i = index; i< Whitelisted_Hospitals.length -1;i++){
                Whitelisted_Hospitals[i] = Whitelisted_Hospitals[i+1];
            }
            Whitelisted_Hospitals.pop();


        }
        
    
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function getWhitelistedHospitals() public view returns(address[] memory){
        return Whitelisted_Hospitals;
    }
}