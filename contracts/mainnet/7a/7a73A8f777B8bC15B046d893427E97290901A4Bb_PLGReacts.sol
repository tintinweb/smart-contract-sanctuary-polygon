/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPLGm {
    function invest(address account) external view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256);
}

interface IPLGv2 {
    function updateWithPermit(address account,uint256[] memory data) external returns (bool);
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

contract PLGReacts is permission {
    
    address public owner;
    address public migrate = 0xe38c473Cc6d3E676d79Fe18a4E7595056A411313;
    address public plgv2 = 0x059489B43F8FF27706f1acd0181BC37a6Df4dBF1;

    constructor() {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
    }

    function depositWithMATIC_Migrate(address account) public forRole("owner") returns (bool) {
        uint256[] memory data = new uint256[](7);
        (uint256 a,uint256 s,uint256 d,uint256 f,uint256 g,uint256 h,uint256 j) = IPLGm(migrate).invest(account);
        data[0] = a;data[1] = s;data[2] = d;data[3] = f;data[4] = g;data[5] = h;data[6] = j;
        IPLGv2(plgv2).updateWithPermit(account,data);
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