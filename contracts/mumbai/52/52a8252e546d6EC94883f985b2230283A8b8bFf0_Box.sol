// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./access-control/Auth.sol";

contract Box {
    uint256 private _value;
    Auth private _auth;

    modifier onlyAdministrator() {
        require(_auth.isAdministrator(msg.sender), "Unauthorised");
        _;
    }

    event ValueChanged(uint256 value);

    constructor() {
        _auth = new Auth(msg.sender);
    }

    function store(uint256 value) public onlyAdministrator {
        _value = value;
        emit ValueChanged(value);
    }

    function retrieve() public view returns (uint256) {
        return _value;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Auth {
    address private _administrator;

    constructor(address deployer) {
        _administrator = deployer;
    }

    function isAdministrator(address user) public view returns (bool) {
        return user == _administrator;
    }
}