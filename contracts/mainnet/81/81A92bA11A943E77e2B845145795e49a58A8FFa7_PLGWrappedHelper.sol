/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPLGFactory {
    function getAddr(string memory key) external view returns (address);
}

interface IPLGDistributor {
    function manual() external returns (bool);
}

interface IPLGWrapped {
    function depositForPermit(address account) external payable returns (bool);
    function withdrawForPermit(address account,uint256 amount) external returns (bool);
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint256);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract PLGWrappedHelper is permission {
    
    address public owner;

    IPLGFactory factory;
    
    constructor(address _factory) {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
        factory = IPLGFactory(_factory);
    }

    function depositFor(address recipient) external payable returns (bool) {
        IPLGWrapped(factory.getAddr("plg_wtoken")).depositForPermit{ value: msg.value }(recipient);
        return true;
    }

    function withdraw(uint256 amount) external returns (bool) {
        IPLGWrapped(factory.getAddr("plg_wtoken")).withdrawForPermit(msg.sender,amount);
        IPLGDistributor(factory.getAddr("implement")).manual();
        return true;
    }

    function factoryAddressSetting(address _factory) public forRole("owner") returns (bool) {
        factory = IPLGFactory(_factory);
        return true;
    }

    function purgeToken(address token) public forRole("owner") returns (bool) {
      uint256 amount = IERC20(token).balanceOf(address(this));
      IERC20(token).transfer(msg.sender,amount);
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