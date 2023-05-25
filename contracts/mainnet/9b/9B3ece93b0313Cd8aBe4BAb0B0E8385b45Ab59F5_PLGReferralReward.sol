/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPLGUser {
    function getUserUpline(address account,uint256 level) external view returns (address[] memory);
}

interface IPLGv2 {
    function invest(address account) external view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256);
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

contract PLGReferralReward is permission {
    
    address public owner;
    address public PLGv2;

    mapping(address => uint256) public vipBlock;
    mapping(address => mapping(address => bool)) public isCount;
    mapping(address => mapping(uint256 => uint256)) public members;
    mapping(address => mapping(string => mapping(uint256 => uint256))) public recordData;

    constructor() {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
    }

    function rewardDistribute(address account,address userContract,string memory dataSlot) public payable forRole("router") returns (bool) {
        address[] memory addrs = IPLGUser(userContract).getUserUpline(account,30);
        for(uint256 i=0; i<30; i++){
            if(!isCount[account][safeAddr(addrs[i])]){
                isCount[account][safeAddr(addrs[i])] = true;
                members[safeAddr(addrs[i])][i+1] += 1;
            }
            bool shouldreward = false;
            uint256 capreward = 0;
            (uint256 balance,uint256 repeat,,,,uint256 cycle,) = IPLGv2(PLGv2).invest(safeAddr(addrs[i]));
            if(vipBlock[account]>block.timestamp){ shouldreward = true; }else{
                if(recordData[safeAddr(addrs[i])]["stack"][cycle]+msg.value/30>balance * repeat){
                    if(recordData[safeAddr(addrs[i])]["stack"][cycle]<balance * repeat){
                        capreward = (balance * repeat) - recordData[safeAddr(addrs[i])]["stack"][cycle];
                    }
                }else{ shouldreward = true; }
            }
            if(shouldreward){
                uint256 spenderAmount;
                if(capreward>0){ spenderAmount = capreward; }else{ spenderAmount = msg.value / 30; }
                recordData[safeAddr(addrs[i])][dataSlot][i] += spenderAmount;
                recordData[safeAddr(addrs[i])]["stack"][cycle] += spenderAmount;
                (bool success,) = safeAddr(addrs[i]).call{ value: spenderAmount }("");
                require(success, "!fail to send eth");
            }
        }
        return true;
    }

    function updateVIPBlockWithPermit(address account,uint256 timer) public forRole("router") returns (bool) {
        _updateVIPBlock(account,timer);
        return true;
    }

    function _updateVIPBlock(address account,uint256 timer) internal { vipBlock[account] = timer; }

    function updateRecordData(address account,string memory dataSlot,uint256 index,uint256 amount) public forRole("router") returns (bool) {
        recordData[account][dataSlot][index] = amount;
        return true;
    }

    function increaseRecordData(address account,string memory dataSlot,uint256 index,uint256 amount) public forRole("router") returns (bool) {
        recordData[account][dataSlot][index] += amount;
        return true;
    }

    function decreaseRecordData(address account,string memory dataSlot,uint256 index,uint256 amount) public forRole("router") returns (bool) {
        recordData[account][dataSlot][index] += amount;
        return true;
    }

    function safeAddr(address account) internal view returns (address) {
        if(account==address(0)){ return owner; }else{ return account; }
    }

    function updateRouter(address router) public forRole("owner") returns (bool) {
        PLGv2 = router;
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