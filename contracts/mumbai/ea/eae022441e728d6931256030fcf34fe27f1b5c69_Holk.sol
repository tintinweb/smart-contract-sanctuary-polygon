/**
 *Submitted for verification at polygonscan.com on 2023-05-19
*/

pragma solidity ^0.8.0;

contract Holk {
    string public name = "Holk";
    string public symbol = "HLK";
    uint8 public decimals = 9;
    uint256 public totalSupply = 100000000 * (10 ** uint256(decimals));
    uint256 public maxSupply = 100000000 * (10 ** uint256(decimals));
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public burnPercentage = 3;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(to != address(0), "Invalid address");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        
        _transfer(from, to, value);
        _approve(from, msg.sender, allowance[from][msg.sender] - value);
        return true;
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        uint256 burnAmount = (value * burnPercentage) / 100;
        uint256 transferAmount = value - burnAmount;
        
        balanceOf[from] -= value;
        balanceOf[to] += transferAmount;
        balanceOf[burnAddress] += burnAmount;
        
        emit Transfer(from, to, transferAmount);
        emit Transfer(from, burnAddress, burnAmount);
    }
    
    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0), "Invalid address");
        
        _approve(msg.sender, spender, value);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 value) internal {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    
    function addLiquidity() external payable {
        // Implementa aquí la lógica para añadir liquidez a Uniswap V3
    }
    
    function burn(uint256 value) external {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        
        balanceOf[msg.sender] -= value;
        balanceOf[burnAddress] += value;
        
        emit Transfer(msg.sender, burnAddress, value);
    }
}