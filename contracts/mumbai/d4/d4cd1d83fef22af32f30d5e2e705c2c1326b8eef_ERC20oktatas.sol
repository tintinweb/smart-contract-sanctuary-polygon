/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ERC20oktatas {

    // PROPERTY
    uint256 public tokenMennyiseg; 
    string public nev;
    string public szimbolum;
    uint8 public decimalok;
    mapping(address => uint256) public balances;

    // EVENT
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);


    // CONSTRUCTOR
    constructor (string memory _nev,string memory _szimbolum, uint8 _decimalok) {
        nev = _nev;
        szimbolum = _szimbolum;
        decimalok = _decimalok;
        balances[msg.sender] = 10000;
        tokenMennyiseg = 10000;
    } 

    // MODIFIER

    // VIEW
    function totalSupply() external view returns (uint256) {
        return tokenMennyiseg;
    }

    function name() public view returns (string memory) {
        return nev;
    }

    function symbol() public view returns (string memory) {
        return szimbolum;
    }

    function decimals() public view returns (uint8) {
        return decimalok;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256){
        // TODO IMPL
        return 0;        
    }


    // TRANSACTIONS

    function transfer(address recipient, uint256 amount) external returns (bool) {
        require((balances[msg.sender] >= amount), "legyen annyi penzunk amennyit atutalunk");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        // TODO
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        // TODO 
        return true;
    }

}