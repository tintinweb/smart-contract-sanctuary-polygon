/**
 *Submitted for verification at polygonscan.com on 2022-02-08
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

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

interface IWETH is IERC20 {
    function deposit() external payable;
    // function deposit(address user, bytes calldata depositData) external;
    function withdraw(uint256) external;
}

// This contract simply calls multiple targets sequentially, ensuring WETH balance before and after

contract FlashBotsMultiCall {
    address private immutable owner;
    address private immutable executor;
    // IWETH private constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // ethereum (wrapped ether)
    // IWETH private constant WETH = IWETH(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619); // polygon (wrapped ether)
    IWETH private constant WETH = IWETH(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270); // polygon (wrapped matic)

    modifier onlyExecutor() {
        require(msg.sender == executor, "only executor can call this function");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this function");
        _;
    }

    constructor(address _executor) public payable {
        owner = msg.sender;
        executor = _executor;
    }

    receive() external payable {
    }

    function uniswapWeth(uint256 _wethAmountToFirstMarket, uint256 _ethAmountToCoinbase, address[] memory _targets, bytes[] memory _payloads) external onlyExecutor payable {
        require (_targets.length == _payloads.length, "targets and payloads must be the same length");
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
        WETH.transfer(_targets[0], _wethAmountToFirstMarket);
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, bytes memory _response) = _targets[i].call(_payloads[i]);
            require(_success, "callX unsucessful"); _response;
        }

        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(_wethBalanceAfter > _wethBalanceBefore + _ethAmountToCoinbase, "no profit");
        if (_ethAmountToCoinbase == 0) return;

        uint256 _ethBalance = address(this).balance;
        if (_ethBalance < _ethAmountToCoinbase) {
            WETH.withdraw(_ethAmountToCoinbase - _ethBalance);
        }
        block.coinbase.transfer(_ethAmountToCoinbase);
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external onlyOwner payable returns (bytes memory) {
        require(_to != address(0), "must not be address zero");
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success, "callY unsucessful");
        return _result;
    }

    // reclaim tokens
    function reclaimToken(IERC20 token) public onlyOwner {
        require(address(token) != address(0), "must not be address zero");
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
}