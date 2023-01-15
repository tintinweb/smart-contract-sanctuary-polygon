// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

contract ZenaPolyGame {
    using SafeMath for uint256;
    using Address for address;

    address public owner;
    address private _operator;

    uint256 private _totalmatic;
    mapping(address => uint256) private _totaltoken;
    mapping(address => bool) private _staker;
    mapping(address => uint256) private _totalStake;
    mapping(address => mapping(address => uint256)) private _stakeTokenBalance;

    event Charge(uint256 amount);
    event Deposit(uint256 amount);
    event Withdraw(uint256 amount, uint256 fee);
    event Stake(address staker, uint256 amount);
    event UnStake(address staker, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function setOperator(address operator) public {
        require(owner == msg.sender, "You're not Owner");
        require(operator != address(0), "Can't set zero address for operator");
        require(_operator == address(0), "Already set operator");

        _operator = operator;
    }

    function hideOperator() public view returns(address) {
        require(owner == msg.sender, "You're not Owner");
        
        return _operator;
    }

    function setStaker(address staker) public {
        require(_operator == msg.sender, "You're not Operator");
        
        _staker[staker] = true;
    }

    function initialStake(address staker, address token, uint256 amount) public {
        require(msg.sender == _operator, "You aren't the operator");
        
        _staker[staker] = true;
        _stakeTokenBalance[staker][token] = _stakeTokenBalance[staker][token].add(amount);
        _totalStake[token] = _totalStake[token].add(amount);
    }

    function resetStake(address staker, address token) public {
        require(msg.sender == _operator, "You aren't the operator");
        
        _totalStake[token] = _totalStake[token].sub(_stakeTokenBalance[staker][token]);
        _stakeTokenBalance[staker][token] = 0;
    }

    function stake(address token, uint256 amount) public {
        require(_staker[msg.sender] == true, "You're not Staker");
        
        IERC20 Token = IERC20(token);

        _stakeTokenBalance[msg.sender][token] = _stakeTokenBalance[msg.sender][token].add(amount);
        _totalStake[token] = _totalStake[token].add(amount);
        _totaltoken[token] = _totaltoken[token].add(amount);

        Token.transferFrom(msg.sender, address(this), amount);

        emit Stake(msg.sender, amount);
    }

    function unStake(address token, uint256 amount) public {
        require(_staker[msg.sender] == true, "Address is not Staker");
        require(_totaltoken[token] >= amount, "Out of balance");
        require(_totalStake[token] >= amount, "Out of balance");
        require(_stakeTokenBalance[msg.sender][token] >= amount, "Exceed Stake balance");
        
        IERC20 Token = IERC20(token);

        _totalStake[token] = _totalStake[token].sub(_stakeTokenBalance[msg.sender][token]);
        _totaltoken[token] = _totaltoken[token].sub(amount);
        _stakeTokenBalance[msg.sender][token] = 0;

        Token.approve(msg.sender, amount);
        Token.transfer(msg.sender, amount);

        emit UnStake(msg.sender, amount);
    }

    function chargeMATIC() payable public {
        require(msg.value > 0, "Unable to charge zero.");
        _totalmatic = _totalmatic.add(msg.value);

        emit Charge(msg.value);
    }

    function chargeToken(address token, uint256 amount) public {
        require(amount > 0, "Unable to charge zero.");

        IERC20 Token = IERC20(token);
        _totaltoken[token] = _totaltoken[token].add(amount);
        
        Token.transferFrom(msg.sender, address(this), amount);

        emit Charge(amount);
    }

    function maticBalance() public view returns(uint256) {
        return _totalmatic;
    }

    function tokenBalance(address token) public view returns(uint256) {
        return _totaltoken[token];
    }

    function isStaker(address staker) public view returns(bool) {
        return _staker[staker];
    }

    function totalStakeBalance(address token) public view returns(uint256) {
        return _totalStake[token];
    }

    function stakeBalance(address staker, address token) public view returns(uint256) {
        return _stakeTokenBalance[staker][token];
    }

    function depositMATIC() payable public {
        require(msg.sender == _operator, "You aren't the operator");
        _totalmatic = _totalmatic.add(msg.value);

        emit Deposit(msg.value);
    }

    function depositToken(address token, uint256 amount) public {
        require(msg.sender == _operator, "You aren't the operator");

        IERC20 Token = IERC20(token);
        _totaltoken[token] = _totaltoken[token].add(amount);
        Token.transferFrom(msg.sender, address(this), amount);

        emit Deposit(amount);
    }

    function withdrawMATIC(address recipient, uint256 amount, uint256 fee) public {
        require(msg.sender == _operator, "You aren't the operator");
        require(_totalmatic >= amount, "Out of balance");

        uint256 outcome = amount;

        if (fee > 0) {
            outcome = amount.sub(fee);
        }

        _totalmatic = _totalmatic.sub(outcome);
        payable(recipient).transfer(outcome);

        emit Withdraw(outcome, fee);
    }

    function withdrawToken(address token, address recipient, uint256 amount, uint256 fee) public {
        require(msg.sender == _operator, "You aren't the operator");
        require(_totaltoken[token] >= amount, "Out of balance");

        IERC20 Token = IERC20(token);

        uint256 outcome = amount;

        if (fee > 0) {
            outcome = amount.sub(fee);
        }
        
        _totaltoken[token] = _totaltoken[token].sub(outcome);

        Token.approve(recipient, outcome);
        Token.transfer(recipient, outcome);

        emit Withdraw(outcome, fee);
    }
}