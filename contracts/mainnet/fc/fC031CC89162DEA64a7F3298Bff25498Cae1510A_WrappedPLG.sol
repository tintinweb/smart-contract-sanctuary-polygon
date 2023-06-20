/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}

interface IPLGFactory {
    function getAddr(string memory key) external view returns (address);
}

interface IPLGPool {
    function processETHRequest(address recipient,uint256 amount) external returns (bool);
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

contract WrappedPLG is permission {

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed from, address indexed to, uint amount);

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    address public owner;
    bool public isPublicWrapped;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

    IPLGFactory factory;

    bool locked;
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor(address _factory,string memory _name,string memory _symbol,uint256 _supply,uint256 _decimals) {
        factory = IPLGFactory(_factory);
        name = _name;
        symbol = _symbol;
        totalSupply = _supply * (10**_decimals);
        owner = msg.sender;
        balances[owner] = totalSupply;
        newpermit(owner,"owner");
        emit Transfer(address(0), owner, totalSupply);
    }
    
    function balanceOf(address adr) public view returns(uint) { return balances[adr]; }

    function approve(address to, uint256 amount) public returns (bool) {
        require(to != address(0));
        allowance[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender,to,amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) public returns(bool) {
        allowance[from][msg.sender] -= amount;
        _transfer(from,to,amount);
        return true;
    }

    function _transfer(address from,address to, uint256 amount) internal {
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function deposit(address recipient) external payable returns (bool) {
        require(isPublicWrapped,"Revert not public wrapped");
        _deposit(recipient,msg.value);
        return true;
    }

    function withdraw(uint256 amount) external returns (bool) {
        require(isPublicWrapped,"Revert not public wrapped");
        _withdraw(msg.sender,amount);
        return true;
    }

    function depositForPermit(address account) external payable forRole("permit") returns (bool) {
        _deposit(account,msg.value);
        return true;
    }

    function withdrawForPermit(address account,uint256 amount) external forRole("permit") returns (bool) {
        _withdraw(account,amount);
        return true;
    }
    
    function _deposit(address recipient,uint256 amount) internal noReentrant {
        balances[recipient] += amount;
        emit Transfer(address(0), recipient, amount);
        _clearStuckBalance(factory.getAddr("plg_pool"));
    }

    function _withdraw(address recipient,uint256 amount) internal noReentrant {
        balances[recipient] -= amount;
        totalSupply -= amount;
        emit Transfer(recipient, address(0), amount);
        bool success = IPLGPool(factory.getAddr("plg_pool")).processETHRequest(recipient,amount);
        require(success,"Revert: error withdraw");
    }

    function flagWrappedState() public forRole("owner") returns (bool) {
        isPublicWrapped = !isPublicWrapped;
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