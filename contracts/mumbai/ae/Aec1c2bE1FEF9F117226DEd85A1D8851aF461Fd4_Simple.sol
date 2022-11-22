/**
 *Submitted for verification at polygonscan.com on 2022-11-22
*/

// File: contracts/simple.sol

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

contract Simple{
    struct User{
        uint id;
        string name;
        uint256 salary;
    }
    User[] users;
    

    constructor(){
        users.push(User(1, "Ayush Patel",20000));
        users.push(User(2, "Helly Shah",200));
        users.push(User(3, "Prince Ahuja",510));
        users.push(User(4, "Parth Pathak",2000));
    }

    function Employees() view public returns(uint){
        return users.length;
    }

     function is_salary_greater_than_1000(uint id) view external returns(bool){
            if(users[id].salary >= 1000){
                return true;
            }
            else{
                return false;
            }
    }
}