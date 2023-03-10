// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20.sol";

// interface IERC20 {
//     function totalSupply() external view returns (uint256);
//     function balanceOf(address account) external view returns (uint256);
//     function transfer(address recipient, uint256 amount) external returns (bool);
//     function allowance(address owner, address spender) external view returns (uint256);
//     function approve(address spender, uint256 amount) external returns (bool);
//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
// }

contract GLDToken is ERC20 {
    constructor() ERC20("Gold", "GLD") {
        _mint(msg.sender, 1000000000000000000000000000);
    }
}

contract USDTMultiSender {
    address public _owner;
    IERC20 public _usdt;

    constructor() {
        _owner = msg.sender;
        // _usdt = IERC20(0xE097d6B3100777DC31B34dC2c58fB524C2e76921);
        _usdt = IERC20(0x1c959864aa035156325D034fD7183729953F986c);
    }

    function depositUSDT(uint256 amount) external {
        require(
            _usdt.transfer(address(this), amount),
            "Tra0x1c959864aa035156325D034fD7183729953F986cnsfer failed."
        );
    }

    function viewUSDTBalance() external view returns (uint256) {
        return _usdt.balanceOf(address(this));
    }

    function getUSDTBalance(address account) external view returns (uint256) {
        return _usdt.balanceOf(account);
    }

    function checkUSDTAllowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        return _usdt.allowance(owner, spender);
    }

    function approveUSDTTransfer(uint256 amount) external {
        require(msg.sender == _owner, "Only owner can call this function.");
        _usdt.approve(address(this), amount);
        _usdt.approve(msg.sender, amount);
        // require(_usdt.approve(address(this), amount), "Approval failed.");
        // require(_usdt.approve(msg.sender, amount), "Approval failed2.");
    }

    function transferUSDT(address recipients, uint256 amounts) external {
        require(msg.sender == _owner, "Only owner can call this function.");
        // require(recipients.length == amounts.length, "Invalid input.");
        require(_usdt.transfer(recipients, amounts), "Transfer failed.");
    }

    function transferFromUSDT(address recipient, uint256 amount) external {
        require(
            _usdt.transferFrom(_owner, recipient, amount),
            "Transfer failed."
        );
    }
}