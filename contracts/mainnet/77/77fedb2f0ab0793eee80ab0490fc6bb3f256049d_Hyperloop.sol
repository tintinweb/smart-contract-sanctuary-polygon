/**
 *Submitted for verification at polygonscan.com on 2022-02-13
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;



interface ERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}

contract Protected {

    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }

    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }

    receive() external payable {}
    fallback() external payable {}
}


contract Hyperloop is Protected {

    /// Common data

    address public bridge;

    mapping(address => bool) public allowed_token;
    mapping(address => uint) public fees;
    mapping(address => mapping (address => uint)) public pending;
    mapping(address => mapping (address => uint)) public to_payback;
    
    event deposited_token(address token, uint qty, address addy);

    uint tax = 2; // 0.2%
    uint upfront = 1000000000000000000; // 1 MATIC/FTM/BNB....

    /// Modifiers

    modifier onlyBridge () {
        require(msg.sender==bridge, "Nope");
        _;
    }

    modifier allowed(address tkn) {
        require(allowed_token[tkn], "Not allowed");
        _;
    }

    /// Constructor

    constructor() {
        owner = msg.sender;
    }

    
    /// Generic bridge endpoints

    function deposit_token (address token, uint qty) payable public safe allowed(token) {
        require(msg.value==upfront);
        ERC20 TOKEN = ERC20(token);
        require(TOKEN.allowance(msg.sender, address(this)) >= qty, "Allowance");
        uint tax_qty = (qty*tax)/1000;
        uint taxed_qty = qty - tax_qty;
        fees[token] += tax_qty;
        bool sent = TOKEN.transferFrom(msg.sender, address(this), qty);
        require(sent, "Error in transfer");
        pending[msg.sender][token] += qty;
        emit deposited_token(token, taxed_qty, msg.sender);
    }
    
    function deposit_token_to_eth(address token, uint qty, address receiver) public onlyBridge allowed(token) {
        ERC20 TOKEN = ERC20(token);
        require(TOKEN.balanceOf(address(this)) >= qty, "Not enough funds");
        require(pending[msg.sender][token] >= qty, "Not enough pending");
        uint tax_qty = (qty*tax)/1000;
        uint taxed_qty = qty - tax_qty;
        fees[token] += tax_qty;
        bool sent = TOKEN.transfer(receiver, taxed_qty);
        require(sent, "Error in transfer");
        pending[msg.sender][token] -= qty;
    }
    
    function payback(address token) public safe {
        uint qty = to_payback[msg.sender][token];
        require(qty >= 0, "No payback");
        ERC20 TOKEN = ERC20(token);
        require(TOKEN.balanceOf(address(this)) >= qty, "Not enough funds");
        bool sent = TOKEN.transfer(msg.sender, qty);
        to_payback[msg.sender][token] = 0;
        require(sent, "Error in transfer");
    }

    /// Control panel

    function set_bridge(address _bridge) public onlyOwner {
        bridge = _bridge;
    }

    function set_token(address token, bool booly) public onlyOwner {
        allowed_token[token] = booly;
    }

    function unstuck_token(address token, uint qty, address receiver) public onlyOwner {
        ERC20 TOKEN = ERC20(token);
        require(TOKEN.balanceOf(address(this)) >= qty, "Not enough funds");
        bool sent = TOKEN.transfer(receiver, qty);
        require(sent, "Error in transfer");
    }

    function retrieve_eth() public onlyOwner {
        (bool sent,) =msg.sender.call{value: (address(this).balance)}("");
        require(sent, "Error in transfer");
    }

    function retrieve_fees(address token) public onlyOwner {
        ERC20 TOKEN = ERC20(token);
        require(TOKEN.balanceOf(address(this)) >= fees[token]);
        bool sent = TOKEN.transfer(msg.sender, fees[token]);
        require(sent, "Error in transfer");
        fees[token] = 0;

    }

    function payback_sender(address token, address receiver, uint qty) public onlyBridge {
        require(pending[receiver][token] >= qty, "No pending");
        pending[receiver][token] -= qty;
        to_payback[receiver][token] += qty;
    }

    function change_tax(uint new_tax) public onlyOwner {
        require(new_tax <= 500, "Too high"); // Max 50%
        tax = new_tax;
    }
    

}