/**
 *Submitted for verification at polygonscan.com on 2023-06-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {

        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Pausable is Context {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract opXOnsCentralBank is ReentrancyGuard, Pausable {
    
    IERC20 public token;
    address public owner;
    address public feeRecipient;
    uint256 public feeAmount;

    constructor(IERC20 _token, address _feeRecipient, uint256 _feeAmount) {
        owner = msg.sender;
        token = _token;
        feeRecipient = _feeRecipient;
        feeAmount = _feeAmount;
    }

    function deposit(uint256 amount) public whenNotPaused nonReentrant {
        require(token.allowance(msg.sender, address(this)) >= amount, "Increase the allowance");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    function approve(address spender, uint256 amount) public whenNotPaused nonReentrant {
        require(msg.sender == owner, "Only the owner can approve spenders");
        require(token.approve(spender, amount), "Approval failed");
    }

    function transfer(address to, uint256 amount) public whenNotPaused nonReentrant {
        require(msg.sender == owner, "Only the owner can transfer tokens");
        require(token.balanceOf(address(this)) >= amount, "Not enough tokens");
        require(amount > feeAmount, "Transfer amount must be greater than fee");

        // Subtract the fee from the transfer amount and send it to feeRecipient
        uint256 newAmount = amount - feeAmount;
        
        require(token.transfer(feeRecipient, feeAmount), "Fee transfer failed");
        require(token.transfer(to, newAmount), "Transfer failed");
    }

    function transferFrom(address from, address to, uint256 amount) public whenNotPaused nonReentrant returns (bool) {
        require(token.allowance(from, address(this)) >= amount, "Increase the allowance");
        require(amount > feeAmount, "Transfer amount must be greater than fee");

        // Subtract the fee from the transfer amount and send it to feeRecipient
        uint256 newAmount = amount - feeAmount;
        
        require(token.transferFrom(from, feeRecipient, feeAmount), "Fee transfer failed");
        return token.transferFrom(from, to, newAmount);
    }

    function setFeeRecipient(address _feeRecipient) public whenNotPaused {
        require(msg.sender == owner, "Only the owner can set the fee recipient");
        feeRecipient = _feeRecipient;
    }

    function setFeeAmount(uint256 _feeAmount) public whenNotPaused {
        require(msg.sender == owner, "Only the owner can set the fee amount");
        feeAmount = _feeAmount;
    }

    function pause() public {
        require(msg.sender == owner, "Only the owner can pause the contract");
        _pause();
    }

    function unpause() public {
        require(msg.sender == owner, "Only the owner can unpause the contract");
        _unpause();
    }
}