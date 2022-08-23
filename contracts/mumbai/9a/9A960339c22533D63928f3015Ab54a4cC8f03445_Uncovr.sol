/**
 *Submitted for verification at polygonscan.com on 2022-08-22
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Uncovr {
    address owner;
    address ownerAccount;
    IERC20 USDC;

    constructor() {
        owner = msg.sender;
        USDC = IERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        ownerAccount = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only for Owner");
        _;
    }

    mapping(address => uint256) accountToId;
    mapping(address => uint256) public accountToSpentMoney;
    mapping(address => uint256) public accountToSpendableMoney;
    uint256 public lockPool;
    uint256 public adminPool;
    uint256 public bufferAmount;
    struct Balances {
        uint256 funds;
        uint256 lockedFunds;
    }

    function changeOwnerAccount(address _to) public onlyOwner {
        ownerAccount = _to;
    }

    function changeOwner(address _to) public onlyOwner {
        owner = _to;
    }

    function lockMoney(uint256 _amount) public {
        require(
            accountToSpendableMoney[msg.sender] >= _amount,
            "You need to fund your account"
        );
        accountToSpendableMoney[msg.sender] -= _amount;
        accountToSpentMoney[msg.sender] += _amount;
        lockPool += _amount;
    }

    function approveFeedback(uint256 _amount, address[] memory _addresses)
        public
    {
        uint256 totalMoney = _amount * _addresses.length;
        uint256 adminCut = (totalMoney / 100) * 10;
        uint256 individualPayout = (totalMoney - adminCut) / _addresses.length;
        require(
            accountToSpentMoney[msg.sender] >= totalMoney,
            "Not enough funds!"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            accountToSpendableMoney[_addresses[i]] += individualPayout;
        }
        accountToSpentMoney[msg.sender] -= totalMoney;
        adminPool += adminCut;
        lockPool -= totalMoney;
    }

    function fundAccountTest(uint256 _amount, address _to) public {
        accountToSpendableMoney[_to] += _amount;
    }

    function accountBalance(address _address)
        public
        view
        returns (uint256[2] memory)
    {
        uint256[2] memory balances = [
            accountToSpendableMoney[_address],
            accountToSpentMoney[_address]
        ];
        return balances;
    }

    /*function fundAccount(uint256 _amount, address _to) public{
         require(USDC.balanceOf(msg.sender)>_amount,"Not enough USDC");
        bool transfer = USDC.transferFrom(msg.sender,address(this) ,_amount);
        require(transfer==true,"Transfer did not go through");
        accountToSpendableMoney[_to] += _amount;
    }*/
    function fundAccountOwner(uint256 _amount, address _to) public onlyOwner {
        require(bufferAmount > _amount, "Not enough USDC");
        bool transfer = USDC.transferFrom(msg.sender, address(this), _amount);
        require(transfer == true, "Transfer did not go through");
        accountToSpendableMoney[_to] += _amount;
    }

    function addBuffer(uint256 _amount) public onlyOwner {
        require(USDC.balanceOf(msg.sender) > _amount, "Not enough USDC");
        bool transfer = USDC.transferFrom(msg.sender, address(this), _amount);
        require(transfer == true, "Transfer did not go through");
        bufferAmount += _amount;
    }

    function withdrawMoneyToWallet(uint256 _amount, address _to) public {
        require(
            accountToSpendableMoney[msg.sender] >= _amount,
            "You don't have that much money"
        );
        USDC.transferFrom(address(this), _to, _amount);
    }

    function withdrawMoneyToCash(uint256 _amount) public onlyOwner {
        require(bufferAmount >= _amount, "Not enough buffer money");
        USDC.transferFrom(address(this), ownerAccount, _amount);
    }
}