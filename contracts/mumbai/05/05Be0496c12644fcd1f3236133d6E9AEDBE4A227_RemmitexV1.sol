// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract RemmitexV1 {
    IERC20 usdc = IERC20(0xA3C957f5119eF3304c69dBB61d878798B3F239D9); // Polygon USDC contract address

    function transferUSDC(address _to, uint256 _value) public {
        require(_value > 0, "Value must be greater than 0");
        uint256 senderBalance = usdc.balanceOf(msg.sender);
        require(senderBalance >= _value, "Insufficient balance");
        bool success = usdc.transferFrom(msg.sender, _to, _value);
        require(success, "Transfer failed");
    }
}