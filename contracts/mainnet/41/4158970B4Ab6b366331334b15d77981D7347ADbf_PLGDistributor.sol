/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
  function enabledTrading() external view returns (bool);
  function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IPLCV1 {
    function usersCount() external view returns (uint256);
    function participants(uint256 id) external view returns (address);
    function users(address account) external view returns (uint256,uint256,uint256,uint256,uint256,address,bool,uint256);
    function records(address account) external view returns (uint256,uint256,uint256,uint256,uint256);
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

contract PLGDistributor is permission {
    
    address public owner;
    address public polycashv1 = 0xfE74Be25FF81B2857983150fbAA5cb626efa13Dd;
    address public polycashgold = 0x919A5712057173C7334cc60E7657791fF9ca6E8d;

    uint256 public updatedid;
    uint256 public totalTokenDistribute;

    IPLCV1 PLCv1;
    IERC20 PLG;

    mapping(address => uint256) public balances;

    constructor() {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
        PLCv1 = IPLCV1(polycashv1);
        PLG = IERC20(polycashgold);
    }

    function PullDataRequest(uint256 index) public forRole("owner") returns (bool) {
        uint256 userCount = PLCv1.usersCount();
        for(uint256 i=0; i<index; i++){
            if(updatedid<userCount){
                address account = PLCv1.participants(updatedid);
                (uint256 deposit,,,,,,,) = PLCv1.users(account);
                (,,,uint256 tWithdraw,) = PLCv1.records(account);
                if(deposit>tWithdraw){
                    uint256 divAmount = deposit - tWithdraw;
                    totalTokenDistribute += divAmount;
                    balances[account] = divAmount;
                }
                updatedid += 1;
            }
        }
        return true;
    }

    function claimToken() public returns (bool) {
        require(PLG.enabledTrading(),"Trading Was Not Open Yet");
        require(balances[msg.sender]>0,"Insufficient Token For Claim");
        PLG.transfer(msg.sender,balances[msg.sender]);
        balances[msg.sender] = 0;
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