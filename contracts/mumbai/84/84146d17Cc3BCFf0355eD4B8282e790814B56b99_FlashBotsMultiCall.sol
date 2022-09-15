//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

pragma experimental ABIEncoderV2;

interface IUniswapV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// This contract simply calls multiple targets sequentially, ensuring WETH balance before and after

contract FlashBotsMultiCall {
    address private immutable owner;
    address private immutable executor;

    // TODO IDK
    IWETH private WETH = IWETH(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    modifier onlyExecutor() {
        require(msg.sender == executor, "Only executor");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(address _executor) payable {
        owner = msg.sender;
        executor = _executor;
        if (msg.value > 0) {
            WETH.deposit{value: msg.value}();
        }
    }

    function setWeth(address _new) public onlyOwner {
        WETH = IWETH(_new);
    }

    receive() external payable {}

    function sweepERC20(
        IERC20 token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        token.transfer(_to, _amount);
    }

    function hoppity(
        uint256 _amountIn,
        address[] calldata _targets,
        uint256[2][] calldata _amountOuts
    ) external onlyExecutor {
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));

        bool success = WETH.transfer(_targets[0], _amountIn);
        require(success, "first weth fail");
        uint256 n = _targets.length;
        for (uint256 i = 0; i < n - 1; i++) {
            IUniswapV2Pair(_targets[i]).swap(
                _amountOuts[i][0],
                _amountOuts[i][1],
                _targets[i + 1],
                ""
            );
        }
        IUniswapV2Pair(_targets[n - 1]).swap(
            _amountOuts[n - 1][0],
            _amountOuts[n - 1][1],
            address(this),
            ""
        );
        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(
            _wethBalanceAfter > _wethBalanceBefore,
            "reverted non profitable"
        );
    }

    function twohop(
        uint256 wethIn,
        address[] calldata targets,
        uint256[] calldata amount0Outs,
        uint256[] calldata amount1Outs
    ) external payable onlyExecutor {
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
        bool success = WETH.transfer(targets[0], wethIn);
        require(success, "first weth fail");
        IUniswapV2Pair(targets[0]).swap(
            amount0Outs[0],
            amount1Outs[0],
            targets[1],
            ""
        );
        IUniswapV2Pair(targets[1]).swap(
            amount0Outs[1],
            amount1Outs[1],
            address(this),
            ""
        );
        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(
            _wethBalanceAfter > _wethBalanceBefore,
            "reverted non profitable"
        );
    }

    function uniswapWeth(
        uint256 _wethAmountToFirstMarket,
        uint256 _ethAmountToCoinbase,
        address[] memory _targets,
        bytes[] memory _payloads
    ) external payable onlyExecutor {
        require(_targets.length == _payloads.length, "bad lengths");
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
        bool success = WETH.transfer(_targets[0], _wethAmountToFirstMarket);
        require(success, "first weth fail");
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, bytes memory _response) = _targets[i].call(
                _payloads[i]
            );
            require(_success, "error on loop");
            _response;
        }

        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(
            _wethBalanceAfter > _wethBalanceBefore,
            "reverted non profitable"
        );
        // require(
        //     _wethBalanceAfter > _wethBalanceBefore + _ethAmountToCoinbase,
        //     "coinbase fail"
        // );
        // if (_ethAmountToCoinbase == 0) return;

        // uint256 _ethBalance = address(this).balance;
        // if (_ethBalance < _ethAmountToCoinbase) {
        //     WETH.withdraw(_ethAmountToCoinbase - _ethBalance);
        // }
        // block.coinbase.transfer(_ethAmountToCoinbase);
    }

    function call(
        address payable _to,
        uint256 _value,
        bytes calldata _data
    ) external payable onlyOwner returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }
}