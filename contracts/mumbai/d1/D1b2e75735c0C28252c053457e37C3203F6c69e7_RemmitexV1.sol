pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract RemmitexV1 {
    address private _owner;
    address private _tokenAddress;
    uint256 private _feePercentage;
    mapping(address => uint256) private _fees;

    constructor() {
        _owner = msg.sender;
        _tokenAddress = 0xA3C957f5119eF3304c69dBB61d878798B3F239D9;
        _feePercentage = 1;
    }

    function transfer(address recipient, uint256 amount) external {
        require(recipient != address(0), "RemmitexV1: Invalid recipient address");

        uint256 fee = (amount * _feePercentage) / 100;
        uint256 netAmount = amount - fee;

        IERC20 token = IERC20(_tokenAddress);

        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "RemmitexV1: Transfer amount exceeds allowance");

        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "RemmitexV1: Transfer to contract failed");

        success = token.transfer(recipient, netAmount);
        require(success, "RemmitexV1: Transfer to recipient failed");

        _fees[msg.sender] += fee;
    }

    function withdrawFees() external {
        require(msg.sender == _owner, "RemmitexV1: Only owner can withdraw fees");

        IERC20 token = IERC20(_tokenAddress);
        uint256 feeAmount = _fees[msg.sender];
        require(feeAmount > 0, "RemmitexV1: No fees to withdraw");

        _fees[msg.sender] = 0;

        bool success = token.transfer(msg.sender, feeAmount);
        require(success, "RemmitexV1: Withdraw failed");
    }
}