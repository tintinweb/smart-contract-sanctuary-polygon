interface BeefyUniV2Zap {
    function beefIn(address beefyVault, uint256 tokenAmountOutMin , address tokenIn , uint256 tokenInAmount ) external;
}

// SPDX-License-Identifier: MIT
import "./interfaces/BeefyUniV2Zap.sol";

pragma solidity ^0.8.7;

interface IXuhaoVault {
    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function depositTokenUSDC(uint _amount) external returns (bool);

    function depositTokenMAI(uint _amount) external returns (bool);

    function withdrawTokenMAI(
        address recipient,
        uint256 _amount
    ) external returns (bool);

    function withdrawTokenUSDC(
        address recipient,
        uint256 _amount
    ) external returns (bool);

    function withdrawTokenUSDCAll() external returns (bool);

    function withdrawTokenMAIAll() external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract XuhaoVault {
    address owner;
    address public constant usdc =
        address(0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747);
    address public constant mai =
        address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address public constant beefyVaultV6 =
        address(0xaAa5B9e6c589642f98a1cDA99B9D024B8407285A);
    address public constant beefyUniV2Zap =
        address(0x540A9f99bB730631BF243a34B19fd00BA8CF315C);

    uint256 private constant MAX_UINT256 = 2 ** 256 - 1;
    uint256 public balanceUSDC;
    uint256 public balanceMAI;
    uint8 public decimalsUSDC;
    uint8 public decimalsMAI;
    mapping(address => uint) private staked;
    mapping(address => mapping(address => uint256)) public allowed;

    event TransferFrom(address indexed from, address indexed to, uint256 value);
    event Transfer(address indexed recipient, uint256 value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    constructor(
        uint256 _balanceMAI,
        uint8 _decimalsMAI,
        uint256 _balanceUSDC,
        uint8 _decimalsUSDC
    ) {
        decimalsMAI = _decimalsMAI;
        decimalsUSDC = _decimalsUSDC;
        balanceUSDC = _balanceUSDC;
        balanceMAI = _balanceMAI;
        owner = msg.sender;
    }

    function approve(
        address _spender,
        uint256 _value
    ) public returns (bool success) {
        allowed[owner][_spender] = _value;
        emit Approval(owner, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function depositTokenUSDC(uint _amount) public returns (bool) {
        require(_amount > 0, "Invalid deposit amount");

        IXuhaoVault(usdc).transferFrom(owner, address(this), _amount);
        BeefyUniV2Zap(beefyUniV2Zap).beefIn(beefyVaultV6,0,usdc,_amount);
        staked[owner] = staked[owner] + _amount;
        balanceUSDC += _amount;
        emit TransferFrom(owner, address(this), _amount);
        return true;
    }

    function withdrawTokenUSDC(uint256 _amount) public returns (bool) {
        uint256 balance = staked[owner];

        require((_amount) > 0, "Invalid withdraw amount");
        require((_amount) < balance, "Insufficient balance");
        IXuhaoVault(usdc).transfer(owner, (_amount));
        staked[owner] = staked[owner] - _amount;
        balanceUSDC -= _amount;
        emit Transfer(owner, _amount);
        return true;
    }

    function withdrawTokenUSDCAll() public returns (bool) {
        uint256 balance = staked[owner];
        require(balance > 0, "Insufficient balance");
        IXuhaoVault(usdc).transfer(owner, balance);
        staked[owner] = 0;
        balanceUSDC -= balance;
        emit Transfer(owner, balance);
        return true;
    }

    function depositTokenMAI(uint _amount) public returns (bool) {
        require(_amount > 0, "Invalid deposit amount");
        IXuhaoVault(mai).transferFrom(owner, address(this), _amount);
        staked[owner] = staked[owner] + _amount;
        balanceMAI += _amount;
        emit TransferFrom(owner, address(this), _amount);
        return true;
    }

    function withdrawTokenMAI(uint256 _amount) public returns (bool) {
        uint256 balance = staked[owner];

        require((_amount) > 0, "Invalid withdraw amount");
        require((_amount) < balance, "Insufficient balance");
        IXuhaoVault(mai).transfer(owner, (_amount));
        staked[owner] = staked[owner] - _amount;
        balanceMAI -= _amount;
        emit Transfer(owner, _amount);
        return true;
    }

    function withdrawTokenMAIAll() public returns (bool) {
        uint256 balance = staked[owner];
        require(balance > 0, "Insufficient balance");
        IXuhaoVault(mai).transfer(owner, balance);
        staked[owner] = 0;
        balanceMAI -= balance;
        emit Transfer(owner, balance);
        return true;
    }
}