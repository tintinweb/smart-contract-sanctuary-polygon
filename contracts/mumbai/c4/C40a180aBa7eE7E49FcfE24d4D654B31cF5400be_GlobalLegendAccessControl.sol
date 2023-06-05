// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract GlobalLegendAccessControl {
    string public symbol;
    string public name;

    mapping(address => bool) private admins;
    mapping(address => bool) private writers;

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event WriterAdded(address indexed writer);
    event WriterRemoved(address indexed writer);

    modifier onlyAdmin() {
        require(admins[msg.sender], "GlobalLegendAccessControl: Only admin can perform this action");
        _;
    }

    modifier onlyWrite() {
        require(
            writers[msg.sender],
            "GlobalLegendAccessControl: Only authorized writers can perform this action"
        );
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        symbol = _symbol;
        name = _name;
        admins[msg.sender] = true;
    }

    function addAdmin(address _admin) external onlyAdmin {
        require(
            !admins[_admin] && _admin != msg.sender,
            "GlobalLegendAccessControl: Cannot add existing admin or yourself"
        );
        admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    function removeAdmin(address _admin) external onlyAdmin {
        require(_admin != msg.sender, "GlobalLegendAccessControl: Cannot remove yourself as admin");
        admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    function addWriter(address _writer) external onlyAdmin {
        writers[_writer] = true;
        emit WriterAdded(_writer);
    }

    function removeWriter(address _writer) external onlyAdmin {
        writers[_writer] = false;
        emit WriterRemoved(_writer);
    }

    function isAdmin(address _admin) public view returns (bool) {
        return admins[_admin];
    }

    function isWriter(address _writer) public view returns (bool) {
        return writers[_writer];
    }
}