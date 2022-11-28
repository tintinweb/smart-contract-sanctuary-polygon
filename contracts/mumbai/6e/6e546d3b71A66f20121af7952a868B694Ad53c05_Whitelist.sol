/**
 *Submitted for verification at polygonscan.com on 2022-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract Whitelist {

    address Owner;
    address private AdminsContract;

    mapping(address => bool) Whitelisted;
    mapping(address => uint) Minted;
    uint private MaxMintPerAddress = 200;

    constructor() {
        Owner = msg.sender;
    }

    function setOwner(address _address) public {
        require(msg.sender == Owner, "Forbidden access");
        Owner = _address;
    }

    function isAdmin(address _address) internal virtual returns (bool) {
        if(_address == Owner) return true;
        return false;
    }

    function setAdminsContract(address _address) public {
        require(isAdmin(msg.sender), "Forbidden access");
        AdminsContract = _address;
    }

    function setWhitelisted(address _address, bool active) public {
        require(msg.sender == Owner, "Forbidden access");
        Whitelisted[_address] = active;
    }

    function batchSetWhitelisted(address[] memory _addresses, bool active) public {
        require(msg.sender == Owner, "Forbidden access");
        for(uint256 i; i < _addresses.length; i++) {
            Whitelisted[_addresses[i]] = active;
        }
    }

    function isWhitelisted(address _address) external view returns (bool, string memory, uint) {
        if(Whitelisted[_address]) return (true, "Whitelisted", MaxMintPerAddress - Minted[_address]);
        return (false, "You're not whitelisted", 0);
    }

    function addMinted(address _address, uint amount) external {
        uint total = Minted[_address] + amount;
        Minted[_address] = total;
    }

}