/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EllaFundPolygon {
    string public name = "ella.fund";
    string public symbol = "ELLA";
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _totalSupply) {
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

    function transfer(address _to, uint256 _value) external {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _value) external {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Not enough allowance");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
    }
}

contract EllaFundBridge {
    address public polygonTokenAddress = 0x429F49fAeC3d568EF83eC803e02dF78E25d5ee7d;
    address public bscTokenAddress = 0x2bd3a69c4F69e5a324fE2c97eA98E2DC79d61E52;
    address public operator;

    event TokenSwap(address indexed sender, uint256 amount);

    modifier onlyOperator() {
        require(msg.sender == operator, "Caller is not the operator");
        _;
    }

    constructor() {
        operator = msg.sender;
    }

    function swapToBSC(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");

        // Transfer tokens from the sender to the bridge contract
        EllaFundPolygon(polygonTokenAddress).transferFrom(msg.sender, address(this), _amount);

        // Emit an event for the token swap
        emit TokenSwap(msg.sender, _amount);
    }

    function swapToPolygon(uint256 _amount) external onlyOperator {
        require(_amount > 0, "Amount must be greater than zero");

        // Transfer tokens from the bridge contract to the operator
        EllaFundPolygon(polygonTokenAddress).transfer(operator, _amount);

        // Emit an event for the token swap
        emit TokenSwap(operator, _amount);
    }
}