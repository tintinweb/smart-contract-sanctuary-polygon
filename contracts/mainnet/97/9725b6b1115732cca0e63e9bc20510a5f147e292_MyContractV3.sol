// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

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
    function getAmountsOut(
		uint amountIn,
		address[] calldata path
	) external view returns (uint[] memory amounts);
}

contract MyContractV3 is IFlashLoanReceiver {
    using SafeMath for uint256;
    address private owner;
    address private baseToken;
    ILendingPool private lendingPool;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor(address _baseToken, ILendingPoolAddressesProvider _addressProvider) {
        owner = msg.sender;
        baseToken = _baseToken;
        lendingPool = ILendingPool(_addressProvider.getLendingPool());
    }

    receive() payable external {}

    function changeOwner(address _owner) external isOwner {
        require(owner != _owner, "New owner matches old owner");
        owner = _owner;
    }

    function changeBaseToken(address _baseToken) external isOwner {
        require(baseToken != _baseToken, "New token matches old token");
        baseToken = _baseToken;
    }

    function changeLendingPool(address _lendingPool) external isOwner {
        require(address(lendingPool) != _lendingPool, "New lending pool matches old lending pool");
        lendingPool = ILendingPool(_lendingPool);
    }
    
    function withdrawFunds(address _token) external isOwner {
        uint assetBalance;
        if (_token == baseToken) {
            assetBalance = address(this).balance;
            require(assetBalance > 0, "Not enough funds");
            payable(msg.sender).transfer(assetBalance);
        } else {
            assetBalance = IERC20(_token).balanceOf(address(this));
            require(assetBalance > 0, "Not enough funds");
            IERC20(_token).transfer(msg.sender, assetBalance);
        }
    }

    function callFlashLoan(
        uint _amount,
        address[2] calldata _routers,
        address[][2] calldata _paths,
        uint[2] calldata _amounts
    ) external isOwner {
        require(_paths[0].length >= 2, "Not enough tokens in path 0");
        require(_paths[1].length >= 2, "Not enough tokens in path 1");
        address[] memory assets = new address[](1);
        assets[0] = address(_paths[0][0]);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = _amount;
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;
        bytes memory params = abi.encode(
            msg.sender,
            _routers,
            _paths,
            _amounts
        );
        lendingPool.flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(this),
            params,
            0
        );
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        (
            address originalCaller,
            address[2] memory decodedRouters,
            address[][2] memory decodedPaths,
            uint[2] memory decodedAmounts
        ) = abi.decode(params, (
            address,
            address[2],
            address[][2],
            uint[2]
        ));
        require(owner == originalCaller, "Original caller is not owner");
        executeArbitrage(
            amounts[0],
            decodedRouters,
            decodedPaths,
            decodedAmounts
        );
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

    function getLendingPool() external view returns (ILendingPool _lendingPool) {
        _lendingPool = lendingPool;
    }

    function getCurrentBlockNumber() external view returns (uint _currentBlockNumber) {
        _currentBlockNumber = block.number;
    }

    function getBalance(address _token) external view returns (uint _balance) {
        if (_token == baseToken) {
            _balance = address(this).balance;
        } else {
            _balance = IERC20(_token).balanceOf(address(this));
        }
    }

    function checkProfits(
        uint _amount,
        address[2] calldata _routers,
        address[][2] calldata _paths
    ) external view returns (uint[][2] memory _amountsStartingWith0, uint[][2] memory _amountsStartingWith1) {
        require(_paths[0].length >= 2, "Not enough tokens in path 0");
        require(_paths[1].length >= 2, "Not enough tokens in path 1");
        address[] memory path0_Reversed = getReversedPath(_paths[0]);
        address[] memory path1_Reversed = getReversedPath(_paths[1]);
        _amountsStartingWith0[0] = IUniswapV2Router02(_routers[0]).getAmountsOut(_amount, _paths[0]);
        _amountsStartingWith0[1] = IUniswapV2Router02(_routers[1]).getAmountsOut(_amountsStartingWith0[0][_paths[0].length-1], path1_Reversed);
        _amountsStartingWith1[0] = IUniswapV2Router02(_routers[1]).getAmountsOut(_amount, _paths[1]);
        _amountsStartingWith1[1] = IUniswapV2Router02(_routers[0]).getAmountsOut(_amountsStartingWith1[0][_paths[1].length-1], path0_Reversed);
    }

    function getReversedPath(address[] calldata _path) public pure returns (address[] memory _reversedPath) {
        _reversedPath = new address[](_path.length);
        uint j = 0;
        for(uint i = _path.length; i >= 1; i--) {
            _reversedPath[j] = _path[i-1];
            j++;
        }
    }

    function getBestPathForRouter(
        uint _amount,
        address[2] calldata _routers,
        address[][] calldata _possiblePaths
    ) external view returns (uint[][2] memory _amounts) {
        require(_possiblePaths.length > 0, "No path provided");
        require(_possiblePaths[0].length >= 2, "Not enough tokens in path");
        _amounts[0] = new uint[](_possiblePaths.length);
        _amounts[1] = new uint[](_possiblePaths.length);
        for (uint i = 0; i < _possiblePaths.length; i++) {
            _amounts[0][i] = IUniswapV2Router02(_routers[0]).getAmountsOut(_amount, _possiblePaths[i])[_possiblePaths[i].length-1];
            _amounts[1][i] = IUniswapV2Router02(_routers[1]).getAmountsOut(_amount, _possiblePaths[i])[_possiblePaths[i].length-1];
        }
    }

    function executeArbitrage(
        uint _amount,
        address[2] memory _routers,
        address[][2] memory _paths,
        uint[2] memory _amounts
    ) private {
        require(_paths[0].length >= 2, "Not enough tokens in path 0");
        require(_paths[1].length >= 2, "Not enough tokens in path 1");
        uint deadlineInSeconds = block.timestamp + 300;
        IERC20(_paths[0][0]).approve(_routers[0], _amount);
        uint firstAmountReceived = IUniswapV2Router02(_routers[0]).swapExactTokensForTokens(_amount, _amounts[0], _paths[0], address(this), deadlineInSeconds)[_paths[0].length-1];
        IERC20(_paths[1][0]).approve(_routers[1], firstAmountReceived);
        IUniswapV2Router02(_routers[1]).swapExactTokensForTokens(firstAmountReceived, _amounts[1], _paths[1], address(this), deadlineInSeconds)[_paths[1].length-1];
    }
}