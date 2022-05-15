/**
 *Submitted for verification at polygonscan.com on 2022-05-14
*/

pragma solidity ^0.8.13;


contract testnet {
    
    struct Users {
        address account;
        uint balance;
        bool usrblock;
    }

    Users users;


    // constructor (Users memory table) public {
    //     users = table;
    // }
    
    function login (address account) public {
        users = Users(account, 0, false);
    }
}