// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ReentrancyGuard.sol";


interface ERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}


contract Web3DebitV2 is ReentrancyGuard {

address public constant EMPTY_ADDRESS = address(0);

address public owner;
uint public fee;
uint public transactionid;
bool public locked;


struct Transaction {
    uint idtransaction;
    uint datetransaction;
    string nametoken;
    address addresstoken;
    uint transactionamount;
    uint transactionfee;
    uint transactionamountnet;
    uint transactionmemo;
    }
    
mapping(address => Transaction[]) public storetransactions;


event Payment(address indexed store, address indexed token, uint amount, uint amountnet, uint fee, uint id, uint memo);


constructor(address _owner) {
    owner = _owner;
}


modifier onlyOwner() {
    require(msg.sender == owner);
    _;
}


function transferOwner(address _newowner) external onlyOwner {
    require(_newowner != EMPTY_ADDRESS);
    owner = _newowner;
}


function changeFee(uint _newfee) external onlyOwner {
    fee = _newfee;
}


function lockGateway() external onlyOwner {
    if (locked) {
        locked = false;
    }

    if (!locked) {
        locked = true;
    }
}


function payment(address _store, address _token, uint _amount, uint _memo) external nonReentrant {
    require(!locked);
    require(_amount > 0);
    require(_memo > 0);
    ERC20 token = ERC20(_token);
    uint decimals = token.decimals();
    string memory tokenname = token.symbol();
    transactionid += 1;

    require(token.balanceOf(msg.sender) >= _amount);
    require(token.allowance(msg.sender, address(this)) >= _amount);
        
    require(token.transferFrom(msg.sender, address(this), _amount));
    
    uint feeamount = _amount * ((fee) * 10 ** decimals / 10000);
    feeamount = feeamount / 10 ** decimals;

    uint netamount = _amount - feeamount;
        
    require(token.transfer(_store, netamount));

    if (feeamount > 0) {
    require(token.transfer(owner, feeamount));
    }
    
    storetransactions[_store].push(Transaction(transactionid, block.timestamp, tokenname, _token, _amount, feeamount, netamount, _memo));

    emit Payment(_store, _token, _amount, netamount, feeamount, transactionid, _memo);

}


function getTransactionsStore(address _account) external view returns (Transaction[] memory) {
    return storetransactions[_account];
} 


}