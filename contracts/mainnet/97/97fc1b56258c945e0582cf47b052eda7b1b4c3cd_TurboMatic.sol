/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TurboMatic {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    address public owner;
    address public icoContract;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    event IcoContractUpdated(address indexed previousIcoContract, address indexed newIcoContract);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    modifier onlyIcoContract() {
        require(msg.sender == icoContract, "Only the ICO contract can perform this action");
        _;
    }

    function setIcoContract(address _icoContract) external onlyOwner {
        require(_icoContract != address(0), "Invalid ICO contract address");
        emit IcoContractUpdated(icoContract, _icoContract);
        icoContract = _icoContract;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "Invalid recipient address");
        require(_value > 0, "Transfer value must be greater than zero");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0), "Invalid spender address");

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "Invalid recipient address");
        require(_value > 0, "Transfer value must be greater than zero");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) external returns (bool) {
        require(_value > 0, "Burn value must be greater than zero");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;

        emit Burn(msg.sender, _value);
        return true;
    }

    function withdrawToIcoContract(uint256 _value) external onlyIcoContract returns (bool) {
        require(_value > 0, "Withdraw value must be greater than zero");
        require(balanceOf[address(this)] >= _value, "Insufficient balance in the token contract");

        balanceOf[address(this)] -= _value;
        balanceOf[icoContract] += _value;

        emit Transfer(address(this), icoContract, _value);
        return true;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}