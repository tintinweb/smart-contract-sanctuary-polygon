/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPLGv4 {
    function depositWithPermit(address account,address referral,uint256 value) external returns (bool);
    function updateWithPermit(address account,uint256[] memory data) external returns (bool);
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

contract DepositConditionV2 is permission {
    
    address public owner;
    address public PLGv4 = 0x95B988236c0a3F400DDEc9D16D5C94fe60850ed1;

    uint256 public deleyed_maximumed = 86400*30;
    uint256 public deleyed_default = 86400*6;

    uint256 public minimam_deposit = 30 * 1e18;
    uint256 public maximum_deposit = 1000 * 1e18;

    bool locked;
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
    }

    function getAccountPreventBlock(address account) public view returns (uint256) {
        (,,uint256 d,,,uint256 h,) = IPLGv4(PLGv4).invest(account);
        uint256 preventBlock = d+deleyed_default+(86400*h);
        if(preventBlock>deleyed_maximumed){ preventBlock = deleyed_maximumed; }
        return d+preventBlock;
    }

    function depositWithMATIC(address account,address referral) public payable returns (bool) {
        (uint256 a,,uint256 d,,,uint256 h,) = IPLGv4(PLGv4).invest(account);
        uint256 preventBlock = deleyed_default+(86400*h);
        require(block.timestamp>=d+preventBlock,"Revert By Minimum Deposit");
        require(msg.value>=minimam_deposit,"Revert By Minimum Deposit");
        require(msg.value<=maximum_deposit,"Revert By Maximum Deposit");
        require(msg.value>=a,"Must Be Deposit More or Equal Balance");
        if(a>0){ require(msg.value<=a*150/100,"Must Be Deposit Below or Equal 1.5x Balance"); }
        internalDeposit(account,referral,msg.value);
        updateAccountDeleyedBlock(account,preventBlock);
        return true;
    }

    function internalDeposit(address account,address referral,uint256 value) internal {
        (bool success,) = PLGv4.call{ value: value }("");
        require(success, "!fail to send eth");
        IPLGv4(PLGv4).depositWithPermit(account,referral,value);
    }

    function updateAccountDeleyedBlock(address account,uint256 preventBlock) internal {
        if(preventBlock>deleyed_maximumed){ preventBlock = deleyed_maximumed; }
        (uint256 a,uint256 s,uint256 d,uint256 f,uint256 g,uint256 h,uint256 j) = IPLGv4(PLGv4).invest(account);
        if(d+preventBlock>g){
            uint256[] memory data = new uint256[](7);
            data[0] = a;
            data[1] = s;
            data[2] = d;
            data[3] = f;
            data[4] = g+(86400*3);
            data[5] = h;
            data[6] = j;
            IPLGv4(PLGv4).updateWithPermit(account,data);
        }
    }

    function purgeETH() public forRole("owner") returns (bool) {
      (bool success,) = msg.sender.call{ value: address(this).balance }("");
      require(success, "!fail to send eth");
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