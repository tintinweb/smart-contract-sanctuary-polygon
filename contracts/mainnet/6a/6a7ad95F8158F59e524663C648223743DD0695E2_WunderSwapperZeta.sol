//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface QuickSwapRouter {
    function factory() external view returns (address);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface QuickSwapFactory {
    function getPair(address, address) external view returns (address);
}

contract WunderSwapperZeta {
    address public treasury;
    uint256 public feePerMille;

    address internal quickSwapRouterAddress =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address internal wrappedMaticAddress =
        0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    event BoughtTokens(
        address indexed trader,
        address indexed token,
        uint256 maticAmount,
        uint256 tokenAmount
    );
    event SoldTokens(
        address indexed trader,
        address indexed token,
        uint256 maticAmount,
        uint256 tokenAmount
    );
    event SwappedTokens(
        address indexed trader,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(address _treasury, uint256 _fee) {
        treasury = _treasury;
        feePerMille = _fee;
    }

    function getAmounts(uint256 _amount, address[] memory _path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        return
            QuickSwapRouter(quickSwapRouterAddress).getAmountsOut(
                _amount,
                _path
            );
    }

    function getMaticPriceOf(address _tokenAddress, uint256 _amount)
        public
        view
        returns (uint256 matic)
    {
        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = wrappedMaticAddress;
        return getAmounts(_amount, path)[1];
    }

    function getPriceWithPath(uint256 _amount, address[] memory _path)
        public
        view
        returns (uint256 matic)
    {
        uint256[] memory amounts = getAmounts(_amount, _path);
        return amounts[amounts.length - 1];
    }

    function getPriceOf(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) public view returns (uint256 matic) {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        return getAmounts(_amount, path)[1];
    }

    function getBestPriceOf(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) public view returns (uint256 matic) {
        address[] memory path = getPathFor(_tokenIn, _tokenOut, _amount);
        return getAmounts(_amount, path)[1];
    }

    function buyTokens(address _tokenAddress) external payable {
        require(msg.value > 0, "NOTHING TO TRADE");

        address[] memory path = new address[](2);
        path[0] = wrappedMaticAddress;
        path[1] = _tokenAddress;

        uint256 fee = (msg.value * feePerMille) / 1000;
        uint256 residualAmount = msg.value - fee;
        payable(treasury).transfer(fee);

        uint256[] memory amounts = getAmounts(residualAmount, path);
        QuickSwapRouter(quickSwapRouterAddress).swapExactETHForTokens{
            value: residualAmount
        }(amounts[1], path, msg.sender, block.timestamp + 1200);
        emit BoughtTokens(msg.sender, _tokenAddress, msg.value, amounts[1]);
    }

    function sellTokens(address _tokenAddress, uint256 _amount) public {
        require(_amount > 0, "NOTHING TO TRADE");

        uint256 balance = ERC20(_tokenAddress).balanceOf(msg.sender);
        require(balance >= _amount, "NOT ENOUGH FUNDS");

        ERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);

        uint256 swapAmount = transferFee(_tokenAddress, _amount);

        ERC20(_tokenAddress).approve(quickSwapRouterAddress, swapAmount);

        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = wrappedMaticAddress;
        uint256[] memory amounts = getAmounts(swapAmount, path);
        QuickSwapRouter(quickSwapRouterAddress).swapExactTokensForETH(
            amounts[0],
            amounts[1],
            path,
            msg.sender,
            block.timestamp + 1200
        );
        emit SoldTokens(msg.sender, _tokenAddress, _amount, amounts[0]);
    }

    function sellAllTokens(address _tokenAddress) external {
        uint256 balance = ERC20(_tokenAddress).balanceOf(msg.sender);
        sellTokens(_tokenAddress, balance);
    }

    function swapTokensWithPath(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount,
        address[] memory _path
    ) public {
        require(_amount > 0, "NOTHING TO TRADE");

        uint256 balance = ERC20(_tokenIn).balanceOf(msg.sender);
        require(balance >= _amount, "NOT ENOUGH FUNDS");

        ERC20(_tokenIn).transferFrom(msg.sender, address(this), _amount);
        uint256 swapAmount = transferFee(_tokenIn, _amount);

        uint256[] memory amounts = getAmounts(swapAmount, _path);
        ERC20(_tokenIn).approve(quickSwapRouterAddress, amounts[0]);
        QuickSwapRouter(quickSwapRouterAddress).swapExactTokensForTokens(
            amounts[0],
            amounts[amounts.length - 1],
            _path,
            msg.sender,
            block.timestamp + 1200
        );
        emit SwappedTokens(
            msg.sender,
            _tokenIn,
            _tokenOut,
            _amount,
            amounts[amounts.length - 1]
        );
    }

    function swapTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
    ) public {
        require(_amount > 0, "NOTHING TO TRADE");
        address[] memory path = getPathFor(_tokenIn, _tokenOut, _amount);
        swapTokensWithPath(_tokenIn, _tokenOut, _amount, path);
    }

    function swapAllTokensWithPath(
        address _tokenIn,
        address _tokenOut,
        address[] memory _path
    ) external {
        uint256 balance = ERC20(_tokenIn).balanceOf(msg.sender);
        swapTokensWithPath(_tokenIn, _tokenOut, balance, _path);
    }

    function swapAllTokens(address _tokenIn, address _tokenOut) external {
        uint256 balance = ERC20(_tokenIn).balanceOf(msg.sender);
        swapTokens(_tokenIn, _tokenOut, balance);
    }

    function getPathFor(
        address _tokenOne,
        address _tokenTwo,
        uint256 _amount
    ) public view returns (address[] memory) {
        address factoryAddress = QuickSwapRouter(quickSwapRouterAddress)
            .factory();
        address pairAddress = QuickSwapFactory(factoryAddress).getPair(
            _tokenOne,
            _tokenTwo
        );

        address[] memory maticPath = new address[](3);
        maticPath[0] = _tokenOne;
        maticPath[1] = wrappedMaticAddress;
        maticPath[2] = _tokenTwo;

        if (pairAddress == address(0)) {
            return maticPath;
        } else {
            address[] memory directPath = new address[](2);
            directPath[0] = _tokenOne;
            directPath[1] = _tokenTwo;
            uint256[] memory maticAmounts = getAmounts(_amount, maticPath);
            uint256[] memory directAmounts = getAmounts(_amount, directPath);

            if (
                maticAmounts[maticAmounts.length - 1] >
                directAmounts[directAmounts.length - 1]
            ) {
                return maticPath;
            } else {
                return directPath;
            }
        }
    }

    function transferFee(address _token, uint256 _totalAmount)
        internal
        returns (uint256 residualAmount)
    {
        uint256 fee = (_totalAmount * feePerMille) / 1000;
        residualAmount = _totalAmount - fee;
        require(
            ERC20(_token).transfer(treasury, fee),
            "COULD NOT TRANSFER FEES"
        );
    }

    function changeTreasury(address _newTreasury) public {
        require(msg.sender == treasury, "Unauthorized");
        treasury = _newTreasury;
    }

    function changeFee(uint256 _newFee) public {
        require(msg.sender == treasury, "Unauthorized");
        feePerMille = _newFee;
    }
}