// SPDX-License-Identifier: MIT

pragma solidity >=0.4.4 <0.7.0;

import "./SafeMath.sol";
import "./IERC20.sol";

// Implementación de nuestro SC heredando la Interfaz IERC20
contract MyToken is IERC20 {
    string public constant name = "Karachi Darbar";
    string public constant symbol = "KDR";
    uint256 public constant decimals = 18;

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed spender, uint256 tokens);

    using SafeMath for uint256;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;
    address private _owner;

    modifier onlyOwner() {
        require(isOwner(),
        "Función solo accesible por el propietario");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    constructor (uint256 initialSupply) public {
        _owner = msg.sender;
        totalSupply_ = initialSupply;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns(uint256){
        return totalSupply_;
    }

    function increaseTotalSupply(uint256 newTokensAmount) public onlyOwner {
        totalSupply_+= newTokensAmount;
        balances[msg.sender] += newTokensAmount;
    }

    function balanceOf(address tokenOwner) public override view returns(uint256){
        return balances[tokenOwner];
    }

    function allowance(address owner, address delegate) public override view returns(uint256){
        return allowed[owner][delegate];
    }

    function transfer(address recipient, uint256 numTokens) public override returns(bool){
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[recipient] = balances[recipient].add(numTokens);
        emit Transfer(msg.sender, recipient, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns(bool){
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns(bool){
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

}