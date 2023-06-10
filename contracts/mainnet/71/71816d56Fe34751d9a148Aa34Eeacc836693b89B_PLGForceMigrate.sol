/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPLGReward {
    function updateVIPBlockWithPermit(address account,uint256 timer) external returns (bool);
}

interface IPLGMigrate {
    function getPendingId() external view returns (uint256[] memory);
    function getDataFromId(uint256 id) external view returns (address,uint256[] memory,uint256);
}

interface IAllSale {
    function totalPaid() external view returns (uint256);
    function totalStakedPLG() external view returns (uint256);
    function totalRewardDeposit() external view returns (uint256);
    function user(address account) external view returns (uint256,uint256);
    function updateAppStateWithPermit(uint256[] memory data) external returns (bool);
    function updateUserWithPermit(address account, uint256[] memory data) external returns (bool);
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

contract PLGForceMigrate is permission {

    address public owner;
    address public refreward = 0x8E17bD6d1Eb5b95b4a8f1528a7C4dB6158b52fb6;
    address public migrate = 0xBA376019C5535336950F176777326A2C173b5df5;
    address public allsale = 0x6cfb1D28729fa8f6008B20A151a414041d3B274C;

    mapping(uint256 => bool) public isSuccess;

    constructor() {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
    }

    function reset() public forRole("owner") returns (bool) {
        uint256[] memory data = new uint256[](3);
        data[0] = 0;
        data[1] = 0;
        data[2] = 0;
        IAllSale(allsale).updateAppStateWithPermit(data);
        _resetId(1);
        _resetId(2);
        _resetId(3);
        _resetId(4);
        _resetId(5);
        return true;
    }
    
    function updateId(uint256 id) public forRole("owner") returns (bool) {
        _updateId(id);
        return true;
    }

    function _updateId(uint256 id) internal {
        _updateUser(id);
        _updateApp(id);
        isSuccess[id] = true;
    }

    function _updateUser(uint256 id) internal {
        (address account,uint256[] memory data,uint256 status) = IPLGMigrate(migrate).getDataFromId(id);    
        data[0] = data[2];
        data[1] = data[3];
        IPLGReward(refreward).updateVIPBlockWithPermit(account,data[1]);
        IAllSale(allsale).updateUserWithPermit(account,data);
    }

    function _updateApp(uint256 id) internal {
        uint256 totalPaid = IAllSale(allsale).totalPaid();
        uint256 totalStakedPLG = IAllSale(allsale).totalStakedPLG();
        uint256 totalRewardDeposit = IAllSale(allsale).totalRewardDeposit();
        (address account,uint256[] memory data,uint256 status) = IPLGMigrate(migrate).getDataFromId(id);
        uint256[] memory dataApp = new uint256[](3);
        dataApp[0] = totalPaid+data[3];
        dataApp[1] = totalStakedPLG+data[2];
        dataApp[2] = totalRewardDeposit;
        IAllSale(allsale).updateAppStateWithPermit(dataApp);
    }

    function _resetId(uint256 id) internal {
        (address account,uint256[] memory data,uint256 status) = IPLGMigrate(migrate).getDataFromId(id);
        uint256[] memory dataUser = new uint256[](2);
        dataUser[0] = 0;
        dataUser[1] = 0;
        IPLGReward(refreward).updateVIPBlockWithPermit(account,0);
        IAllSale(allsale).updateUserWithPermit(account,dataUser);
        isSuccess[id] = false;
    }

    function purgeETH() public forRole("owner") returns (bool) {
      _clearStuckBalance(owner);
      return true;
    }

    function _clearStuckBalance(address receiver) internal {
      (bool success,) = receiver.call{ value: address(this).balance }("");
      require(success, "!fail to send eth");
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