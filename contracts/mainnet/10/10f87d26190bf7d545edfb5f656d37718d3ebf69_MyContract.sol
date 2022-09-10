// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IFlashLoanReceiver, ILendingPool, ILendingPoolAddressesProvider, IERC20} from "./Interfaces.sol";
import {SafeMath} from "./Libraries.sol";

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract MyContract is IFlashLoanReceiver {
    using SafeMath for uint256;

    address private owner;
    address private baseToken;
    IUniswapV2Router02 private router0;
    IUniswapV2Router02 private router1;
    ILendingPool private lendingPool;
    address[] private route;

    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event BaseTokenSet(address indexed oldBaseToken, address indexed newBaseToken);
    event Router0Set(address indexed oldRouter0, address indexed newRouter0);
    event Router1Set(address indexed oldRouter1, address indexed newRouter1);
    event LendingPoolSet(address indexed oldLendingPool, address indexed newLendingPool);
    event TokenAddedToRoute(address indexed tokenAdded);
    event TokenRemovedFromRoute(address indexed tokenRemoved);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor(
        address _baseToken,
        address _router0,
        address _router1,
        ILendingPoolAddressesProvider _addressProvider
    )
    public
    {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
        baseToken = _baseToken;
        emit BaseTokenSet(address(0), baseToken);
        router0 = IUniswapV2Router02(_router0);
        emit Router0Set(address(0), address(router0));
        router1 = IUniswapV2Router02(_router1);
        emit Router1Set(address(0), address(router1));
        lendingPool = ILendingPool(_addressProvider.getLendingPool());
        emit LendingPoolSet(address(0), address(lendingPool));
    }

    receive() payable external {}

    function changeOwner(address _newOwner) external isOwner {
        require(_newOwner != owner, "New owner matches old owner");
        owner = _newOwner;
        emit OwnerSet(owner, _newOwner);
    }

    function changeBaseToken(address _newBaseToken) external isOwner {
        require(_newBaseToken != baseToken, "New token matches old token");
        baseToken = _newBaseToken;
        emit BaseTokenSet(baseToken, _newBaseToken);
    }

    function changeRouter0(address _newRouter0) external isOwner {
        require(_newRouter0 != address(router0), "New router matches old router");
        router0 = IUniswapV2Router02(_newRouter0);
        emit Router0Set(address(router0), _newRouter0);
    }

    function changeRouter1(address _newRouter1) external isOwner {
        require(_newRouter1 != address(router1), "New router matches old router");
        router1 = IUniswapV2Router02(_newRouter1);
        emit Router1Set(address(router1), _newRouter1);
    }

    function changeLendingPool(address _newLendingPool) external isOwner {
        require(_newLendingPool != address(lendingPool), "New lending pool matches old lending pool");
        lendingPool = ILendingPool(_newLendingPool);
        emit LendingPoolSet(address(lendingPool), _newLendingPool);
    }

    function addTokenToRoute(address _tokenToBeAdded) external isOwner {
        require(!tokenExistsInRoute(_tokenToBeAdded), "Token already exists");
        route.push(_tokenToBeAdded);
        emit TokenAddedToRoute(_tokenToBeAdded);
    }

    function removeLastTokenFromRoute() external isOwner {
        require(route.length > 0, "Route is empty");
        address tokenToBeRemoved = route[route.length-1];
        route.pop();
        emit TokenRemovedFromRoute(tokenToBeRemoved);
    }

    function withdrawFunds(address _token) external isOwner {
        uint assetBalance;
        if (_token == baseToken) {
            assetBalance = address(this).balance;
            require(assetBalance > 0, "Not enough funds");
            msg.sender.transfer(assetBalance);
        } else {
            assetBalance = IERC20(_token).balanceOf(address(this));
            require(assetBalance > 0, "Not enough funds");
            IERC20(_token).transfer(msg.sender, assetBalance);
        }
    }

    function callFlashLoan(uint _amount, bool _startWithRouter0) external isOwner {
        address receiverAddress = address(this);
        address[] memory assets = new address[](1);
        assets[0] = address(route[0]);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;
        address onBehalfOf = address(this);
        bytes memory params = abi.encode(msg.sender, _startWithRouter0);
        uint16 referralCode = 0;
        lendingPool.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {
        (address originalCaller, bool startWithRouter0) = abi.decode(params, (address, bool));
        require(originalCaller == owner, "Original caller is not owner");
        executeArbitrage(amounts[0], startWithRouter0);
        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(lendingPool), amountOwing);
        }
        return true;
    }

    function getOwner() external view returns (address _owner) {
        _owner = owner;
    }

    function getBaseToken() external view returns (address _baseToken) {
        _baseToken = baseToken;
    }

    function getRouter0() external view returns (IUniswapV2Router02 _router0) {
        _router0 = router0;
    }

    function getRouter1() external view returns (IUniswapV2Router02 _router1) {
        _router1 = router1;
    }

    function getLendingPool() external view returns (ILendingPool _lendingPool) {
        _lendingPool = lendingPool;
    }

    function getRouteLength() external view returns (uint _length) {
        _length = route.length;
    }

    function getCurrentBlockNumber() external  view returns (uint _currentBlockNumber) {
        _currentBlockNumber = block.number;
    }
    
    function getBalance(address _token) external view returns (uint _balance) {
        if(_token == baseToken) {
            _balance = address(this).balance;
        }
        _balance = IERC20(_token).balanceOf(address(this));
    }

    function checkProfits(uint _amount) external view isOwner returns (uint _profit0, uint _profit1) {
        require(route.length > 1, "Not enough tokens in route");
        uint firstAmountReceived;
        uint secondAmountReceived;
        address[] memory reversedRoute = getReversedRoute();
        firstAmountReceived = router0.getAmountsOut(_amount, route)[route.length-1];
        secondAmountReceived = router1.getAmountsOut(firstAmountReceived, reversedRoute)[reversedRoute.length-1];
        if (secondAmountReceived > _amount) {
            _profit0 = secondAmountReceived - _amount;
        }
        firstAmountReceived = router1.getAmountsOut(_amount, route)[route.length-1];
        secondAmountReceived = router0.getAmountsOut(firstAmountReceived, reversedRoute)[reversedRoute.length-1];
        if (secondAmountReceived > _amount) {
            _profit1 = secondAmountReceived - _amount;
        }
    }

    function tokenExistsInRoute(address _tokenToBeSearchedFor) public view returns (bool _exists) {
        _exists = false;
        for (uint i = 0; i < route.length; i++) {
            if (route[i] == _tokenToBeSearchedFor) {
                _exists = true;
            }
        }
    }

    function getReversedRoute() public view returns (address[] memory _reversedRoute) {
        _reversedRoute = new address[](route.length);
        uint j = 0;
        for(uint i = route.length; i >= 1; i--) {
            _reversedRoute[j] = route[i-1];
            j++;
        }
    }

    function executeArbitrage(uint _amount, bool _startWithRouter0) private {
        IUniswapV2Router02 firstRouter;
        IUniswapV2Router02 secondRouter;
        if (_startWithRouter0) {
            firstRouter = router0;
            secondRouter = router1;
        } else {
            firstRouter = router1;
            secondRouter = router0;
        }
        uint deadlineInSeconds = block.timestamp + 300;
        address receiverAddress = address(this);
        address[] memory reversedRoute = getReversedRoute();
        IERC20(route[0]).approve(address(firstRouter), _amount);
        uint firstAmountReceived = firstRouter.swapExactTokensForTokens(_amount, 1, route, receiverAddress, deadlineInSeconds)[route.length-1];
        IERC20(reversedRoute[0]).approve(address(secondRouter), firstAmountReceived);
        uint secondAmountReceived = secondRouter.swapExactTokensForTokens(firstAmountReceived, 1, reversedRoute, receiverAddress, deadlineInSeconds)[reversedRoute.length-1];
    }
}