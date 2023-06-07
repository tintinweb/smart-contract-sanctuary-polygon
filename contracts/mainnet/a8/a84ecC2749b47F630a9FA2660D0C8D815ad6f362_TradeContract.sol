/**
 *Submitted for verification at polygonscan.com on 2023-06-07
*/

pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface TradeParameters {
    function addParameters(
        address _userAddress,
        uint256 _topRange,
        uint256 _bottomRange,
        uint256 _token1TradeAmount,
        uint256 _token2TradeAmount,
        address _token1Address,
        address _token2Address,
        string[] memory _data
    ) external;
}


contract TradeContract {
    address private contractOwner;
    address private WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    mapping(address => mapping(address => bool)) private userApprovedPairs;
    address paymentToken = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address tradeParametersAddress = 0xbb688595C63f49B004e169C882C3D2d6D4478019;


    constructor() {
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(
            msg.sender == contractOwner,
            "Only the contract owner can call this function."
        );
        _;
    }

    function executeTrade(
        address userAddress,
        uint256 amountIn,
        uint256 amountOutMin,
        address _token1,
        address _token2,
        address _uniswapRouterAddress
    ) public onlyOwner {
        IERC20 token1 = IERC20(_token1);
        require(
            token1.transferFrom(userAddress, address(this), amountIn),
            "Token transfer failed."
        );

        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(
            _uniswapRouterAddress
        );
        token1.approve(_uniswapRouterAddress, amountIn);

        address[] memory path;
        if (_token1 == WMATIC || _token2 == WMATIC) {
            path = new address[](2);
            path[0] = _token1;
            path[1] = _token2;
        } else {
            path = new address[](3);
            path[0] = _token1;
            path[1] = WMATIC;
            path[2] = _token2;
        }

        uniswapRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            userAddress,
            block.timestamp
        );
    }

    function setTradeParameters(
        uint256 _topRange,
        uint256 _bottomRange,
        uint256 _token1TradeAmount,
        uint256 _token2TradeAmount,
        address _token1,
        address _token2,  
        string[] memory _data
    ) public {
        
        IERC20 token1 = IERC20(_token1);
        token1.approve(address(this), type(uint256).max);
        userApprovedPairs[msg.sender][_token2] = true;

        IERC20 token2 = IERC20(_token2);
        token2.approve(address(this), type(uint256).max);
        userApprovedPairs[msg.sender][_token1] = true;

        IERC20 paymentTokenContract = IERC20(paymentToken);
        paymentTokenContract.approve(address(this), type(uint256).max);



        TradeParameters parameters = TradeParameters(tradeParametersAddress);
        parameters.addParameters(
            msg.sender, //_userAddress
            _topRange,
            _bottomRange,
            _token1TradeAmount,
            _token2TradeAmount,
            _token1,
            _token2,
            _data
        );
        
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address.");
        contractOwner = newOwner;
    }
}