/**
 *Submitted for verification at polygonscan.com on 2023-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UeriiLearningPlatform {
    address public owner;
    mapping(bytes4 => bool) ipAddresses;
    bytes4[] ipAddressList;
    string[] public dnsList;
    string public constant VERSION = "1.00.00";
    string public constant SITEINFO = "https://www.uerii.com";

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    function addIPAddress(bytes4 _ipAddress) public onlyOwner {
        require(!ipAddresses[_ipAddress], "IP address already exists.");

        ipAddresses[_ipAddress] = true;
        ipAddressList.push(_ipAddress);
    }

    function removeIPAddress(bytes4 _ipAddress) public onlyOwner {
        require(ipAddresses[_ipAddress], "IP address does not exist.");

        for (uint i = 0; i < ipAddressList.length; i++) {
            if (ipAddressList[i] == _ipAddress) {
                ipAddressList[i] = ipAddressList[ipAddressList.length - 1];
                ipAddressList.pop();
                break;
            }
        }

        ipAddresses[_ipAddress] = false;
    }

    function getIPAddressList() public view returns (bytes4[] memory) {
        return ipAddressList;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address.");
        owner = _newOwner;
    }

    function addDns(string memory _string) public onlyOwner {
        dnsList.push(_string);
    }

    function removeDns(uint _index) public onlyOwner {
        require(_index < dnsList.length, "Invalid index.");

        for (uint i = _index; i < dnsList.length-1; i++) {
            dnsList[i] = dnsList[i+1];
        }

        dnsList.pop();
    }

    function getDnsArray() public view returns (string[] memory) {
        return dnsList;
    }

}