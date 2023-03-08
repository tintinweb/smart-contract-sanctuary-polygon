/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 往合约里存入链币或者其它代币，锁定预设的区块数，区块数不到，不能提取
contract MyDeposit {

    mapping(address => mapping(address => uint256)) public funds;
    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint)) public tokenFreezeNum;
    mapping(address => uint) public balanceFreezeNum;

    event Deposit(address depositer, address fund, uint256 amount);
    event DepositETH(address depositer, uint256 amount);

    event Withdraw(address depositer, address fund, uint256 amount);
    event WithdrawETH(address depositer, uint256 amount);

    uint public freezeNum;

    constructor(uint _freezeNum){
        freezeNum = _freezeNum;
    }

    receive() payable external {}

    function depositETH(
    ) payable external returns(bool) {

        require(msg.value > 0);

        balanceOf[msg.sender] = SafeMath.add(balanceOf[msg.sender], msg.value);

        balanceFreezeNum[msg.sender] = block.number;

        emit DepositETH(msg.sender, msg.value);

        return true;

    }

    function withdrawETH(
        uint256 _amount
    ) external returns(bool) {

        require(_amount > 0);

        require(_amount <= balanceOf[msg.sender], "Insufficient funds.");

        uint depositNum = balanceFreezeNum[msg.sender];

        require(SafeMath.sub(block.number, depositNum) >= freezeNum, "Please wait, when the block to more high.");

        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _amount);

        TransferHelper.safeTransferETH(msg.sender, _amount);

        emit WithdrawETH(msg.sender, _amount);

        return true;

    }

    function depositToken(
        address _fund,
        uint256 _amount
    ) external returns(bool) {

        require(address(0) != _fund);

        require(_amount > 0);

        TransferHelper.safeTransferFrom(_fund, msg.sender, address(this), _amount);

        funds[msg.sender][_fund] = SafeMath.add(funds[msg.sender][_fund], _amount);

        tokenFreezeNum[msg.sender][_fund] = block.number;

        emit Deposit(msg.sender, _fund, _amount);

        return true;

    }

    function withdrawToken(
        address _fund,
        uint256 _amount
    ) external returns(bool) {

        require(address(0) != _fund);

        require(_amount > 0);

        require(_amount <= funds[msg.sender][_fund], "Insufficient funds.");

        uint depositNum = tokenFreezeNum[msg.sender][_fund];

        require(SafeMath.sub(block.number, depositNum) >= freezeNum,"Please wait, when the block to more high.");

        funds[msg.sender][_fund] = SafeMath.sub(funds[msg.sender][_fund], _amount);

        TransferHelper.safeTransfer(_fund, msg.sender, _amount);

        emit Withdraw(msg.sender, _fund, _amount);

        return true;

    }

}

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns(uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
}

library TransferHelper {
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}