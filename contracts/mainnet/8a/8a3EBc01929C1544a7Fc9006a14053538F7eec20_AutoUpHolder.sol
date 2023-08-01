//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface _IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)  external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AutoUpHolder {

    constructor(address _contract, address _token) {
        // Matrix Contract
        // 0x7154ca1986e59D45F34AA4e509008D7dB5680940
        mainContract = _contract;

        // USDT
        token = _IERC20(_token);
    }

    fallback() external {}

    address mainContract;
    _IERC20 token;
    
    function getFund(uint amount) public returns(bool) {
        require(msg.sender == mainContract, "Only Matrix Contract can call it");
        
        if(token.transfer(mainContract, amount))
            return true;
            
        return false;
    }
    
}