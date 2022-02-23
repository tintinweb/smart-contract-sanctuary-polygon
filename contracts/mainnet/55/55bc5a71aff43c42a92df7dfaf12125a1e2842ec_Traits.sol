/**
 *Submitted for verification at polygonscan.com on 2022-02-23
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.7;

contract Traits{

    address creator;
    address moderator;
    mapping(uint256=>uint256[]) traits;

    constructor(){
        creator=msg.sender;
    }

    function addTrait(uint256 _id, uint256[] memory _traits) public{
        require(checkAdmin(),"You are not admin");
        traits[_id]=_traits;
    }
    function addTraits(uint256[] memory _id, uint256[][] memory _traits) public{
        require(checkAdmin(),"You are not admin");
        for(uint i=0;i<_id.length;i++){
            traits[_id[i]]=_traits[i];
        }
    }

    function addModerator(address _address) public{
        require(checkAdmin(),"You are not admin");
        moderator=_address;
    }

    function getTrait(uint256 _id) public view returns(uint256[] memory){
        return traits[_id];
    }


    function checkAdmin() private view returns(bool){
        bool _admin=false;
        if(msg.sender==creator || msg.sender==moderator){_admin=true;}
        return _admin;
    }



}