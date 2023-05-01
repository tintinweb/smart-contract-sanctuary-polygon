// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract CSLBToken is ERC20, Ownable {
    struct Transaction {
        address from;
        address to;
        uint256 value;
        uint256 timestamp;
        bytes32 txid;
    }

    mapping(address => Transaction[]) private _transactionsByAddress;
    mapping(address => mapping(address => uint256)) private _autoAllowances;

    constructor(uint256 initialSupply) ERC20("CSLB Token", "CSLB") {
        _mint(msg.sender, initialSupply * 10**18);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    event TransactionId(
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 timestamp,
        bytes32 txid
    );

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        bytes32 txid = keccak256(
            abi.encodePacked(_msgSender(), recipient, amount, block.timestamp)
        );
        _transactionsByAddress[_msgSender()].push(
            Transaction(_msgSender(), recipient, amount, block.timestamp, txid)
        );
        _transactionsByAddress[recipient].push(
            Transaction(_msgSender(), recipient, amount, block.timestamp, txid)
        );
        emit TransactionId(
            _msgSender(),
            recipient,
            amount,
            block.timestamp,
            txid
        );
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);
        bytes32 txid = keccak256(
            abi.encodePacked(sender, recipient, amount, block.timestamp)
        );
        _transactionsByAddress[sender].push(
            Transaction(sender, recipient, amount, block.timestamp, txid)
        );
        _transactionsByAddress[recipient].push(
            Transaction(sender, recipient, amount, block.timestamp, txid)
        );
        emit TransactionId(sender, recipient, amount, block.timestamp, txid);
        return true;
    }

    function autoApprove(address spender, uint256 amount) public onlyOwner {
        _autoAllowances[_msgSender()][spender] = amount;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        uint256 autoAllowance = _autoAllowances[_msgSender()][spender];
        if (autoAllowance > 0 && amount == 0) {
            _approve(_msgSender(), spender, autoAllowance);
            return true;
        } else {
            _approve(_msgSender(), spender, amount);
            return true;
        }
    }

    function transactionsByAddress(address account)
        public
        view
        returns (Transaction[] memory)
    {
        return _transactionsByAddress[account];
    }
}