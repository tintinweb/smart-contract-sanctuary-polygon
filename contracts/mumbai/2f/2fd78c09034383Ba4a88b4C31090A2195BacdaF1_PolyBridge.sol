/**
 *Submitted for verification at polygonscan.com on 2023-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract PolyBridge is Ownable {

    address public TOKEN_ADDRESS;
    uint256 private constant FEE_PERCENT = 1; // 1% fee

    event Deposit(address indexed sourceAddress, address indexed destinationAddress, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    function setTokenAddress(address _token) external onlyOwner {
        TOKEN_ADDRESS = _token;
    }

    function deposit(address destinationAddress, uint256 amount) external {
        uint256 feeAmount = (amount * FEE_PERCENT) / 100;
        uint256 netAmount = amount - feeAmount;
    
        IERC20 token = IERC20(TOKEN_ADDRESS);

        token.transferFrom(msg.sender, address(this), amount);
        token.transfer(owner(), feeAmount);
        token.transfer(destinationAddress, netAmount);

        emit Deposit(msg.sender, destinationAddress, netAmount);
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        IERC20(TOKEN_ADDRESS).transfer(to, amount);
        emit Withdraw(to, amount);
    }
}