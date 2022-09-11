// SPDX-License-Identifier: nolicense
pragma solidity ^0.8.0;

contract Name {
    string public name;
    mapping(address => bool) public _frozen;
    mapping(address => uint) public userAccounts;

    // function setName(string memory _newName) public returns (bool) {
    //     name = _newName;
    //     return true;
    // }

    // function getName() public view returns (string memory) {
    //     return name;
    // }

    function freeze(address account) public {
        _frozen[account] = true;
        userAccounts[account] = 335;
    }

    function unfreeze(address account) public {
        _frozen[account] = false;
        delete userAccounts[account];
    }

    function isAccountFrozen(address account) public view returns (bool) {
        return _frozen[account];
    }
}