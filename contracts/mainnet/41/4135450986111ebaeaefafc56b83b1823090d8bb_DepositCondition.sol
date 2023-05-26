/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPLGv4 {
    function depositWithPermit(address account,address referral,uint256 value) external returns (bool);
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

contract DepositCondition is permission {
    
    address public owner;
    address public PLGv4 = 0x95B988236c0a3F400DDEc9D16D5C94fe60850ed1;

    uint256 public deleyed = 86400*7;
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

    function depositWithMATIC(address account,address referral) public payable returns (bool) {
        (uint256 balance,,uint256 block_deposit,,,,) = IPLGv4(PLGv4).invest(account);
        require(block.timestamp>=block_deposit+deleyed,"Revert By Minimum Deposit");
        require(msg.value>=minimam_deposit,"Revert By Minimum Deposit");
        require(msg.value<=maximum_deposit,"Revert By Maximum Deposit");
        require(msg.value>=balance,"Must Be Deposit More or Equal Balance");
        if(balance>0){
            require(msg.value<=balance*150/100,"Must Be Deposit Below or Equal 1.5x Balance");
        }
        (bool success,) = PLGv4.call{ value: msg.value }("");
        require(success, "!fail to send eth");
        IPLGv4(PLGv4).depositWithPermit(account,referral,msg.value);
        return true;
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