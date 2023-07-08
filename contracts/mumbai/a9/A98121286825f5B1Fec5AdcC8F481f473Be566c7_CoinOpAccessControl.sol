// SPDX-License-Identifier: UNLICENSE

pragma solidity ^0.8.9;

contract CoinOpAccessControl {
    string public symbol;
    string public name;

    mapping(address => bool) private admins;
    mapping(address => bool) private writers;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event WriterAdded(address indexed admin);
    event WriterRemoved(address indexed admin);

    modifier onlyAdmin() {
        require(
            admins[msg.sender],
            "CoinOpAccessControl: Only admins can perform this action"
        );
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol
    ) {
        symbol = _symbol;
        name = _name;
        admins[msg.sender] = true;
    }

    function addAdmin(address _admin) external onlyAdmin {
        require(
            !admins[_admin] && _admin != msg.sender,
            "CoinOpAccessControl: Cannot add existing admin or yourself"
        );
        admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    function removeAdmin(address _admin) external onlyAdmin {
        require(
            _admin != msg.sender,
            "CoinOpAccessControl: Cannot remove yourself as admin"
        );
        require(admins[_admin], "CoinOpAccessControl: Admin doesn't exist.");
        admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    function addWriter(address _writer) external onlyAdmin {
        require(
            !writers[_writer],
            "CoinOpAccessControl: Cannot add existing writer"
        );
        writers[_writer] = true;
        emit WriterAdded(_writer);
    }

    function removeWriter(address _writer) external onlyAdmin {
        require(
            writers[_writer],
            "CoinOpAccessControl: Cannot remove a writer that doesn't exist"
        );
        writers[_writer] = false;
        emit WriterRemoved(_writer);
    }

    function isAdmin(address _address) public view returns (bool) {
        return admins[_address];
    }

    function isWriter(address _address) public view returns (bool) {
        return writers[_address];
    }
}