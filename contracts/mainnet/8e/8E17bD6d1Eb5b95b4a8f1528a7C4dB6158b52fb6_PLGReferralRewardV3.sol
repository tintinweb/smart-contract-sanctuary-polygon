/**
 *Submitted for verification at polygonscan.com on 2023-06-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPLGFactory {
    function getAddr(string memory key) external view returns (address);
}

interface IPLGUser {
    function getUserReferralMap(address account) external view returns (address[] memory);
    function getUserUpline(address account,uint256 level) external view returns (address[] memory);
}

interface IPLGData {
    function invest(address account) external view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256);
}

interface IPLGPool {
    function depositFor(address recipient) external payable returns (bool);
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

contract PLGReferralRewardV3 is permission {
    
    address public owner;

    IPLGFactory factory;

    mapping(address => uint256) public vipBlock;
    mapping(address => mapping(address => bool)) public isCount;
    mapping(address => mapping(uint256 => uint256)) public members;
    mapping(address => mapping(string => mapping(uint256 => uint256))) public recordData;

    constructor(address _factory) {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
        factory = IPLGFactory(_factory);
    }

    function rewardDistribute(address account,address userContract,string memory dataSlot) public payable forRole("permit") returns (bool) {
        address[] memory addrs = IPLGUser(userContract).getUserUpline(account,30);
        for(uint256 i=0; i<30; i++){
            if(!isCount[account][safeAddr(addrs[i])]){
                isCount[account][safeAddr(addrs[i])] = true;
                members[safeAddr(addrs[i])][i+1] += 1;
            }
            bool shouldreward = false;
            uint256 capreward = 0;
            (uint256 balance,uint256 repeat,,,,uint256 cycle,) = IPLGData(factory.getAddr("plg_router")).invest(safeAddr(addrs[i]));
            if(vipBlock[account]>block.timestamp){ shouldreward = true; }else{
                uint256 maxEarnAmount = balance * repeat;
                if(recordData[safeAddr(addrs[i])]["stack"][cycle]+(msg.value/30)>maxEarnAmount){
                    if(recordData[safeAddr(addrs[i])]["stack"][cycle]<maxEarnAmount){
                        capreward = maxEarnAmount - recordData[safeAddr(addrs[i])]["stack"][cycle];
                        shouldreward = true;
                    }
                }else{ shouldreward = true; }
            }
            if(shouldreward){
                address[] memory refmap = IPLGUser(userContract).getUserReferralMap(safeAddr(addrs[i]));
                if(vipBlock[safeAddr(addrs[i])]>block.timestamp || refmap.length>i){
                    uint256 spenderAmount;
                    if(capreward>0){ spenderAmount = capreward; }else{ spenderAmount = msg.value / 30; }
                    recordData[safeAddr(addrs[i])][dataSlot][i] += spenderAmount;
                    recordData[safeAddr(addrs[i])]["stack"][cycle] += spenderAmount;
                    IPLGPool(factory.getAddr("plg_wrapped")).depositFor{ value: spenderAmount }(safeAddr(addrs[i]));
                }
            }
        }
        return true;
    }

    function viewMembersData(address account) public view returns (uint256[] memory,uint256) {
        uint256[] memory result = new uint256[](31);
        uint256 sum;
        for(uint256 i=0; i<30; i++){
            result[i] = members[account][i];
            sum += result[i];
        }
        return (result,sum);
    }
    
    function updateVIPBlockWithPermit(address account,uint256 timer) public forRole("permit") returns (bool) {
        _updateVIPBlock(account,timer);
        return true;
    }

    function _updateVIPBlock(address account,uint256 timer) internal { vipBlock[account] = timer; }

    function updateRecordData(address account,string memory dataSlot,uint256 index,uint256 amount) public forRole("permit") returns (bool) {
        recordData[account][dataSlot][index] = amount;
        return true;
    }

    function increaseRecordData(address account,string memory dataSlot,uint256 index,uint256 amount) public forRole("permit") returns (bool) {
        recordData[account][dataSlot][index] += amount;
        return true;
    }

    function decreaseRecordData(address account,string memory dataSlot,uint256 index,uint256 amount) public forRole("permit") returns (bool) {
        recordData[account][dataSlot][index] -= amount;
        return true;
    }

    function safeAddr(address account) internal view returns (address) {
        if(account==address(0)){ return factory.getAddr("plg_pool"); }else{ return account; }
    }

    function factoryAddressSetting(address _factory) public forRole("owner") returns (bool) {
        factory = IPLGFactory(_factory);
        return true;
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