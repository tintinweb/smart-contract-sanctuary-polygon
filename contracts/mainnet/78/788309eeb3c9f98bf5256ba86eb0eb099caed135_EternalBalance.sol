/**
 *Submitted for verification at polygonscan.com on 2022-06-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract EternalBalance{
    mapping(address => uint256) balances;

    mapping(address => bool) enabled;
    mapping(address => bool) blocked;

    address owner;
    mapping(address => uint) admins;

    event Stopped(address _to, address _admin);

    constructor() {
        owner = msg.sender;
        enabled[owner] = true;
        admins[owner] = 3;
    }

    function set_admin(address _usr, uint level) public{
        require(msg.sender == owner);

        admins[_usr] = level;
    }

    function remove_admin(address _usr) public{
        require(admins[msg.sender] >= 3);

        admins[_usr] = 0;
    }

    function disable(address _to) public{
        require(admins[msg.sender] >= 1);

        enabled[_to] = false;
        emit Stopped(_to, msg.sender);
    }

    function enable(address _to) public{
        require(msg.sender == owner);

        enabled[_to] = true;
    }

    function block_usr(address _usr) public{
        require(admins[msg.sender] >= 2);

        blocked[_usr] = true;
    }

    function unblock_usr(address _usr) public{
        require(msg.sender == owner);

        blocked[_usr] = false;
    }

    function get(address _owner) public view returns(uint256){
        return balances[_owner];
    }

    function add(address _owner, uint256 value) public {
        require(enabled[msg.sender]);
        require(!blocked[_owner]);

        require(value > 0);
        require(balances[_owner] + value >= balances[_owner]);

        balances[_owner] += value;
    }

    function sub(address _owner, uint256 value) public {
        require(enabled[msg.sender]);
        require(!blocked[_owner]);

        require(value > 0);
        require(balances[_owner] >= value);

        balances[_owner] -= value;
    }
}