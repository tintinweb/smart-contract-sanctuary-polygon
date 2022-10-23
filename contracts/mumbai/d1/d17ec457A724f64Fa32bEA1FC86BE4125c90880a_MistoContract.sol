/**
 *Submitted for verification at polygonscan.com on 2022-10-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IMistoFeeManager {
    function setFee(uint _fee) external;
    function getFee() external returns(uint256);
}

interface IMistoToken {
    function transfer(address from, address to, uint256 id, uint256 amount) external;
    function mint(uint256 id, uint256 amount) external;
}

contract MistoContract is Ownable, IMistoToken {
    address private tokenAddr;
    address private feeManagerAddr;

    mapping (uint256 => uint256) private oneHryvniaCost;
    mapping (uint256 => uint256) private goal;
    mapping (uint256 => uint256) private collected;
    mapping (uint256 => uint256) private goalInHryvnias;
    mapping (uint256 => uint256) private collectedInHryvnias;
    mapping (uint256 => address[]) private supporters;
    mapping (uint256 => mapping (address => uint256)) private transactions;
    mapping (address => uint256) private balances;

    event Funded(uint256 tenderId);
    event Collected(uint256 tenderId, address supporter, uint256 amount);

    function addTender(uint256 tenderId, uint256 _goal, uint256 _goalInHryvnias) public onlyOwner {
        require(_goalInHryvnias != 0, "Goal cannot be 0");
        require(_goal != 0, "Goal cannot be 0");
        require(goal[tenderId] == 0, "Tender already exists");

        oneHryvniaCost[tenderId] = _goal / _goalInHryvnias;

        goal[tenderId] = _goal;
        goalInHryvnias[tenderId] = _goalInHryvnias;
        mint(tenderId, _goal);
    }

    function removeTender(uint256 tenderId) public onlyOwner {
        delete goal[tenderId];
        delete collected[tenderId];
        delete goalInHryvnias[tenderId];
        delete collectedInHryvnias[tenderId];
    }

    function donate(uint256 tenderId, uint256 amountInHryvnia) public payable {
        uint256 feeAmount = msg.value * IMistoFeeManager(feeManagerAddr).getFee() / 1000;
        uint256 feeAmountInHryvnia = feeAmount / oneHryvniaCost[tenderId];

        require((msg.value / oneHryvniaCost[tenderId]) == amountInHryvnia, "Wrong amount in hryvnia");
        require(msg.sender.balance >= msg.value, "Insufficient balance");
        require(goal[tenderId] != 0, "Tender does not exist");
        require(collected[tenderId] <= goal[tenderId], "Funds are already collected for this tender");


        uint256 amountMinusFee = msg.value - feeAmount;
        uint256 possibleCollected = collected[tenderId] + amountMinusFee;
        uint256 tokenAmount;
        if (possibleCollected > goal[tenderId]) {
            uint256 extra = possibleCollected - goal[tenderId];
            uint256 requiredValue = msg.value - extra  - feeAmount;

            if(requiredValue != 0) {
                collected[tenderId] = collected[tenderId] + requiredValue;
                collectedInHryvnias[tenderId] = (requiredValue * oneHryvniaCost[tenderId]) - feeAmountInHryvnia;
                tokenAmount = requiredValue;
            }

            balances[msg.sender] += extra;
            transactions[tenderId][msg.sender] += requiredValue;


        } else {
            collected[tenderId] = collected[tenderId] + amountMinusFee;
            collectedInHryvnias[tenderId] = msg.value * oneHryvniaCost[tenderId] - feeAmountInHryvnia;
            transactions[tenderId][msg.sender] += amountMinusFee;
            tokenAmount = amountMinusFee;
        }

        if (tokenAmount != 0 ) {
            transfer(tokenAddr, msg.sender, tenderId, tokenAmount);
        }

        if (supporters[tenderId].length >= 1) {
            for (uint256 i = 0; i < supporters[tenderId].length; i++) {
                if (supporters[tenderId][i] == msg.sender) {
                    continue;
                } else {
                    supporters[tenderId].push(msg.sender);
                }
            }
        } else {
            supporters[tenderId].push(msg.sender);
        }


        if (collected[tenderId] >= goal[tenderId]) {
            emit Funded(tenderId);
        }

        emit Collected(tenderId, msg.sender, amountMinusFee);
    }

    function getTenderGoal(uint256 tenderId) public view returns(uint256) {
        return goal[tenderId];
    }

    function getTenderCollected(uint256 tenderId) public view returns(uint256) {
        return collected[tenderId];
    }

    function getTenderStatus(uint256 tenderId) public view returns(string memory) {
        if (collected[tenderId] == goal[tenderId]) {
            return "Tender is completed or does not exist";
        } else {
            return "Tender is in progress";
        }
    }

    function cancelTender(uint256 tenderId) public onlyOwner {
        require(goal[tenderId] != 0, "Tender does not exist");

        address[] memory addresses = supporters[tenderId];
        for (uint256 i = 0; i < addresses.length; i++) {
            address txAddr = addresses[i];
            balances[txAddr] += transactions[tenderId][txAddr];
            transfer(txAddr, tokenAddr, tenderId, transactions[tenderId][txAddr]);
        }

        collected[tenderId] = 0;
        goal[tenderId] = 0;
        collectedInHryvnias[tenderId] = 0;
    }

    function transfer(address from, address to, uint256 id, uint256 amount) public {
        IMistoToken(tokenAddr).transfer(from, to, id, amount);
    }

    function mint(uint256 id, uint amount) public onlyOwner {
        IMistoToken(tokenAddr).mint(id, amount);
    }

    function setTokenAddress(address _tokenAddr) public onlyOwner {
        tokenAddr = _tokenAddr;
    }

    function setFeeManagerAddr(address _feeManagerAddr) public onlyOwner {
        feeManagerAddr = _feeManagerAddr;
    }

    function getOneHryvniaCost(uint256 tenderId) public view returns (uint256) {
        return oneHryvniaCost[tenderId];
    }

    function getSupporterBalance(address supporterAddr) public view returns (uint256) {
        return balances[supporterAddr];
    }

    function setSupporterBalance(address supporterAddr, uint256 amount) public onlyOwner {
        balances[supporterAddr] = amount;
    }

    function donateFromBalance(address supporterAddr, uint256 amountInHryvnia, uint256 tenderId) public onlyOwner {
        uint256 amountInWei = amountInHryvnia * oneHryvniaCost[tenderId];

        require(balances[supporterAddr] >= amountInWei, "Insufficient balance");
        require(goal[tenderId] != 0, "Tender does not exist");
        require(collected[tenderId] <= goal[tenderId], "Funds are already collected for this tender");

        balances[supporterAddr] -= amountInWei;
        collected[tenderId] += amountInWei;
        collectedInHryvnias[tenderId] += amountInHryvnia;

        transfer(tokenAddr, supporterAddr, tenderId, amountInWei);
    }

    function topUpContractBalance() public payable onlyOwner {}

    function withdrawContractBalance(uint256 amount, address payee) public onlyOwner {
        payable(payee).transfer(amount);
    }
}