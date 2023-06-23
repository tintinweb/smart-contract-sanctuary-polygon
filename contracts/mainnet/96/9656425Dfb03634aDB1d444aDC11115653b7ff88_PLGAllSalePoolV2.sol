/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPLGFactory {
    function getAddr(string memory key) external view returns (address);
}

interface IPLGUser {
    function getParticipants() external view returns (address[] memory);
}

interface IPLGAllSale {
    function user(address account) external view returns (uint256,uint256);
}

contract permission {
    mapping(address => mapping(string => bytes32)) private permit;

    function newpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode(adr,str))); }

    function clearpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode("null"))); }

    function checkpermit(address adr,string memory str) public view returns (bool) {
        if(permit[adr][str]==bytes32(keccak256(abi.encode(adr,str)))){ return true; }else{ return false; }
    }

    modifier forRole(string memory str) {
        require(checkpermit(msg.sender,str),"Permit Revert!");
        _;
    }
}

contract PLGAllSalePoolV2 is permission {
    
    address public owner;
    uint256 public totalPaid;
    uint256 public totalStakedPLG;

    uint256 public index;
    uint256 public max;

    IPLGFactory factory;

    address[] changedAddress;

    mapping(address => uint256) public oldBalance;
    mapping(address => uint256) public newBalance;

    constructor(address _factory) {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
        factory = IPLGFactory(_factory);
        //881
    }

    function getchangedAddress() external view returns (address[] memory) {
        return changedAddress;
    }

    function updateIndex(uint256 enumIndexUpdate) public forRole("owner") returns (bool) {
        max += enumIndexUpdate;
        address[] memory accounts = IPLGUser(factory.getAddr("plg_user")).getParticipants();
        while(index<max){
            (uint256 balance,uint256 claimed) = IPLGAllSale(factory.getAddr("plg_allsale")).user(accounts[index]);
            totalStakedPLG += balance;
            totalPaid += claimed;
            index += 1;
        }
        return true;
    }

    function checkIndex(uint256 enumIndexUpdate) public forRole("owner") returns (bool) {
        max += enumIndexUpdate;
        address oldCA = 0xe955D83298b714e06250b06F51917aA605385fA7;
        address[] memory accounts = IPLGUser(factory.getAddr("plg_user")).getParticipants();
        while(index<max){
            (uint256 balanceOld,) = IPLGAllSale(oldCA).user(accounts[index]);
            (uint256 balanceNew,) = IPLGAllSale(factory.getAddr("plg_allsale")).user(accounts[index]);
            if(balanceOld!=balanceNew){
                changedAddress.push(accounts[index]);
                oldBalance[accounts[index]] = balanceOld;
                newBalance[accounts[index]] = balanceNew;
            }
            index += 1;
        }
        return true;
    }

    function factoryAddressSetting(address _factory) public forRole("owner") returns (bool) {
        factory = IPLGFactory(_factory);
        return true;
    }

    function grantRole(address adr,string memory role) public forRole("owner") returns (bool) {
        newpermit(adr,role);
        return true;
    }

    function revokeRole(address adr,string memory role) public forRole("owner") returns (bool) {
        clearpermit(adr,role);
        return true;
    }

    function transferOwnership(address adr) public forRole("owner") returns (bool) {
        newpermit(adr,"owner");
        clearpermit(msg.sender,"owner");
        owner = adr;
        return true;
    }

    receive() external payable {}
}