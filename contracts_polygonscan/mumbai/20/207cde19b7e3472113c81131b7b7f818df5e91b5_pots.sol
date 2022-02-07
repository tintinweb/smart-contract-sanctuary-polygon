/**
 *Submitted for verification at polygonscan.com on 2022-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract pots{

    Pool pool;

    constructor(){
        pool = new Pool();
    }

    group[] public groups;

    function memcmp(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }
    
     function strcmp(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return memcmp(bytes(a), bytes(b));
    }

    struct group{
        uint256 id;
        string name;
        address creater;
        address[] walletAddresses;
        uint256 balance;
    }

    //new group
    function newGroup(string memory name,address creater, address[] memory walletAddresses) public returns(uint256) {
        group storage new_group = groups.push();
        new_group.id = groups.length +1;
        new_group.name = name;
        new_group.creater = creater;
        new_group.walletAddresses = walletAddresses;
        new_group.balance = 0;
        return new_group.id;
    }
    //delete group
    function deleteGroup(uint256 id) public returns(bool){
        require(groups[id].creater == msg.sender,"error: you are not the creater of the pot!!");
        require(groups[id].balance==0);
        delete groups[id];
        return true;
    }
    //add crypto
    uint256 i;
    modifier verifiedUser(uint256 pot_id) {
        bool check = false;
        for(i=0;i<groups[pot_id].walletAddresses.length;i++){
            if(groups[pot_id].walletAddresses[i]==msg.sender){
                check = true;
            }
        }
        require(check);
        _;
    }

    function addCrypto(uint256 id, string memory name, uint256 amount ) payable public verifiedUser(id){
        require(strcmp(groups[id].name,name));
        groups[id].balance = groups[id].balance + amount;
        //add crypto to the pool
        payable(pool).transfer(amount);
    }

    function takeCrypto(uint256 id, string memory name, uint256 amount ) payable public verifiedUser(id){
        require(strcmp(groups[id].name,name));
        require(groups[id].balance>=amount);
        groups[id].balance = groups[id].balance - amount;
        //take crypto from pool contract
        payable(msg.sender).transfer(amount);
    }
}

contract Pool{
    fallback() external payable{

    }
}