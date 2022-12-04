/**
 *Submitted for verification at polygonscan.com on 2022-12-04
*/

// File: contracts/Executor.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWMATIC is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

// This contract simply calls multiple targets sequentially, ensuring WMATIC balance before and after

contract FlashBotsMultiCall {
    address private immutable owner;
    address private immutable executor;
    IWMATIC private constant WMATIC = IWMATIC(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    modifier onlyExecutor() {
        require(msg.sender == executor);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _executor) public payable {
        owner = msg.sender;
        executor = _executor;
        if (msg.value > 0) {
            WMATIC.deposit{value: msg.value}();
        }
    }

    receive() external payable {
    }

    function uniswapWmatic(uint256 _wmaticAmountToFirstMarket, uint256 _maticAmountToCoinbase, address[] memory _targets, bytes[] memory _payloads) external onlyExecutor payable {
        require (_targets.length == _payloads.length);
        uint256 _wmaticBalanceBefore = WMATIC.balanceOf(address(this));
        WMATIC.transfer(_targets[0], _wmaticAmountToFirstMarket);
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, bytes memory _response) = _targets[i].call(_payloads[i]);
            require(_success); _response;
        }

        uint256 _wmaticBalanceAfter = WMATIC.balanceOf(address(this));
        require(_wmaticBalanceAfter > _wmaticBalanceBefore + _maticAmountToCoinbase);
        if (_maticAmountToCoinbase == 0) return;

        uint256 _maticBalance = address(this).balance;
        if (_maticBalance < _maticAmountToCoinbase) {
            WMATIC.withdraw(_maticAmountToCoinbase - _maticBalance);
        }
        block.coinbase.transfer(_maticAmountToCoinbase);
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external onlyOwner payable returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }
}