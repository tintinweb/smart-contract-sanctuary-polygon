//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Interfaces.sol";
import "./Libraries.sol";


contract PolyArb is FlashLoanReceiverBase, IUniswapV2Callee {

    event GrantRole(bytes32 indexed role, address indexed account);
    event RevokeRole(bytes32 indexed role, address indexed account);

    mapping(bytes32 => mapping(address => bool)) public roles;

    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32 private constant USER = keccak256(abi.encodePacked("USER"));

    // POLYGON Testnet
    ITOKEN private constant WMATIC = ITOKEN(0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889);
    address private constant QUICKSWAP_Factory = address(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);
    address private constant SAND = address(0xE03489D4E90b22c59c5e23d45DFd59Fc0dB8a025);
    // POLYGON mainnet
    // address private constant SAND = address(0xBbba073C31bF03b8ACf7c28EF0738DeCF3695683);
    // ITOKEN private constant WMATIC = ITOKEN(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    // address private constant QUICKSWAP_Factory = address(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);
    address private constant MATIC_address = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    
    
    modifier permitRole(bytes32 _role) {
        require(roles[_role][msg.sender], "Not Authorized");
        _;
    }

    constructor(ILendingPoolAddressesProvider _addressProvider) FlashLoanReceiverBase(_addressProvider) payable {
        _grantRole(ADMIN, msg.sender);
        _grantRole(USER, msg.sender);
 
        if (msg.value > 0) {
            WMATIC.deposit{value: msg.value}();
        }
    }

    function _grantRole(bytes32 _role, address _account) internal {
        roles[_role][_account] = true;
        emit GrantRole(_role, _account);
    }

    function grantRole(bytes32 _role, address _account) external permitRole(ADMIN) {
        _grantRole(_role, _account);
        emit GrantRole(_role, _account);
    }

    function revokeRole(bytes32 _role, address _account) external permitRole(ADMIN) {
        roles[_role][_account] = false;
        emit RevokeRole(_role, _account);
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external permitRole(ADMIN) payable returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }

    function withdraw(address token) external permitRole(ADMIN) {
        if (token == MATIC_address) {
            uint256 bal = address(this).balance;
            payable(msg.sender).transfer(bal);
        } else if (token != MATIC_address) {
            uint256 bal = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(payable(address(msg.sender)), bal);
        }
    }

    receive() external payable {
    }

    function optimal_add(uint x) private pure returns (uint) {
        unchecked {
            return x+1;
        }
    }

    function getAmountOutMin(
        uint256 _amountIn, 
        address[] calldata _tokens, 
        address _dexRouterContractAddress
    ) external view returns (uint256) {
       //path is an array of addresses.
       //this path array will have 3 addresses [tokenIn, WMATIC, tokenOut]
       //the if statement below takes into account if token in or token out is WMATIC.  then the path is only 2 addresses
        address[] memory path;
        uint256 len = _tokens.length;
        for (uint256 i = 0; i < len; i = optimal_add(i)) {
            path[i] = address(_tokens[i]);
        }
        
        (uint256[] memory amountOutMins) = IUniswapV2Router(_dexRouterContractAddress).getAmountsOut(_amountIn, path);
        return amountOutMins[amountOutMins.length - 1];  
    }

    function multiSingleSwapFLParams(
        uint256 _amountToFirstMarket, 
        bytes memory _params, 
        uint256 totalLoanDebt
    ) internal {
        ( 
            /* uint256  _cycleType */, 
            uint256 _maticAmountToCoinbase, 
            address[] memory _targets, 
            bytes[] memory _payloads, 
            address[] memory _tokens, 
            address[] memory _dexRouterContractAddress,
            /* address[][] memory _routerTokens */
        ) = abi.decode(_params, (uint256, uint256, address[], bytes[], address[], address[], address[][]));
        require(_targets.length == _payloads.length);
        IERC20 baseToken = IERC20(_tokens[0]);
        baseToken.transfer(_targets[0], _amountToFirstMarket);
        uint256 i = 0;
        uint256 len = _targets.length;
        for (i; i < len; optimal_add(i)) {
            (bool _success, ) = _targets[i].call(_payloads[i]);
            require(_success); 
        }

        uint256 _token0BalanceAfter = WMATIC.balanceOf(address(this));
        require(_token0BalanceAfter > totalLoanDebt + _maticAmountToCoinbase);

        
        if (address(_tokens[0]) == address(WMATIC)) {
            uint256 _maticBalance = address(this).balance;
            if (_maticBalance < _maticAmountToCoinbase) {
                WMATIC.withdraw(_maticAmountToCoinbase - _maticBalance);
            }
        } else { 
            baseToken.approve(_dexRouterContractAddress[0], _maticAmountToCoinbase);
            address[] memory path = new address[](2);
            path[0] = address(_tokens[0]);
            path[1] = address(WMATIC);
            // check next line for correct implementation 
            (uint256[] memory _amountOutMin) = IUniswapV2Router(_dexRouterContractAddress[0]).getAmountsOut(_maticAmountToCoinbase, path);
            // doublecheck the _amountOutMin[0] to see which is the correct output.
            IUniswapV2Router(_dexRouterContractAddress[0]).swapExactTokensForTokens(_maticAmountToCoinbase, (_amountOutMin[0] * 80) / 100  , path, payable(address(this)), block.timestamp);
            WMATIC.withdraw(_amountOutMin[0]);
        }

        if (_maticAmountToCoinbase > 0) {
            if (address(_tokens[0])== address(WMATIC)) {
                uint256 _maticBalance = address(this).balance;
                if (_maticBalance < _maticAmountToCoinbase) {
                    WMATIC.withdraw(_maticAmountToCoinbase - _maticBalance);
                }
            } else {
                baseToken.approve(_dexRouterContractAddress[0], _maticAmountToCoinbase);
                
                uint256 slippage = totalLoanDebt > 0 ? block.timestamp : block.timestamp + 100;
                address[] memory path = new address[](2);
                path[0] = address(_tokens[0]);
                path[1] = address(WMATIC);
                
                // check next line for correct implementation 
                uint256[] memory _amountOutWMATIC = IUniswapV2Router(_dexRouterContractAddress[0]).getAmountsOut(_maticAmountToCoinbase, path);
                IUniswapV2Router(_dexRouterContractAddress[0]).swapExactTokensForTokens(_maticAmountToCoinbase, (_amountOutWMATIC[0] * 80) / 100, path, payable(address(this)), slippage);
                WMATIC.withdraw(_amountOutWMATIC[0]);
            }
            (bool _success, ) = payable(block.coinbase).call{value: _maticAmountToCoinbase}(new bytes(0));
            require(_success);
        }
    }

    function multiCyclicFLParams(
        uint256 _amountToFirstExchange, 
        bytes memory _params, 
        uint256 totalLoanDebt
    ) internal {
        ( 
          /* uint256  _cycleType */, 
          uint256 _maticAmountToCoinbase, 
          address[] memory _targets, 
          bytes[] memory _payloads, 
          /* address[] memory _tokens */, 
          address[] memory _dexRouterContractAddress, 
          address[][] memory _routerTokens
        ) = abi.decode(_params, (uint256, uint256, address[], bytes[], address[], address[], address[][]));
        require(_targets.length == _payloads.length);

        //                _________________________     _________________________
        //               [dex0inputToken, dex0path]  |  [dex1inputToken, dex1path]
        //                            | ___________  |  __________ |
        // _token param structure is: [ [a, [a,b,c] ], [c, [c,d,a] ] ]
        uint256 j = 0;
        uint256 len = _targets.length;
        uint256[] memory _amountOutMin;
        address baseToken = address(_routerTokens[0][0]);
        for (j; j < len; optimal_add(j)) {
            if ( j == 0 && baseToken == address(WMATIC)) {
                IERC20(baseToken).approve(_dexRouterContractAddress[0], _amountToFirstExchange);
            } else if (j == 0 && baseToken != address(WMATIC)) {
                IERC20(baseToken).approve(_dexRouterContractAddress[0], _amountToFirstExchange + _maticAmountToCoinbase); 
            } else if (j > 0) {
                // Check parameter Types specially amountOutMin
                _amountOutMin = IUniswapV2Router(_dexRouterContractAddress[--j]).getAmountsOut(j < 2 ? _amountToFirstExchange: _amountOutMin[_amountOutMin.length-1], _routerTokens[--j]);
                IERC20(_routerTokens[j][0]).approve(_dexRouterContractAddress[j], _amountOutMin[_amountOutMin.length-1] );
            }

            (bool _success, ) = _targets[j].call(_payloads[j]);
            require(_success); 
        }

        uint256 _tokenBalanceAfter = IERC20(baseToken).balanceOf(address(this));
        require(_tokenBalanceAfter > totalLoanDebt + _maticAmountToCoinbase);
        
        if (_maticAmountToCoinbase > 0) {
            if (baseToken == address(WMATIC)) {
                uint256 _maticBalance = address(this).balance;
                if (_maticBalance < _maticAmountToCoinbase) {
                    WMATIC.withdraw(_maticAmountToCoinbase - _maticBalance);
                }
            } else {
                IERC20(baseToken).approve(_dexRouterContractAddress[0], _maticAmountToCoinbase);
                
                uint256 slippage = totalLoanDebt > 0 ? block.timestamp : block.timestamp + 100;
                address[] memory path = new address[](2);
                path[0] = address(baseToken);
                path[1] = address(WMATIC);
                
                uint256[] memory _amountOutWMATIC = IUniswapV2Router(_dexRouterContractAddress[0]).getAmountsOut(_maticAmountToCoinbase, path);
                IUniswapV2Router(_dexRouterContractAddress[0]).swapExactTokensForTokens(_maticAmountToCoinbase, (_amountOutWMATIC[0] * 80) / 100, path, payable(address(this)), slippage);
                WMATIC.withdraw(_amountOutWMATIC[0]);
            }
            payable(block.coinbase).transfer(_maticAmountToCoinbase);
        }
    }

    function multiSingleSwap (
        uint256 _amountIn,
        bytes memory _params
    ) external payable permitRole(USER) {
        multiSingleSwapFLParams(_amountIn, _params, 0);
    }

    function multiCyclicSwap (
        uint256 _amountIn,
        bytes memory _params
    ) external payable permitRole(USER) {
        multiCyclicFLParams(_amountIn, _params, 0);
    }

    /* 
        Aave Flashloan
    */

    function flashloanAave(address borrowedTokenAddress, uint256 amountToBorrow, bytes calldata _params) external permitRole(USER) {
        address receiverAddress = payable(address(this));

        address[] memory assets = new address[](1);
        assets[0] = borrowedTokenAddress;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountToBorrow;

        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);
        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            _params,
            referralCode
        );
    }

    function executeOperation(
        address[] calldata /* assets */,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address /* initiator */,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {
        uint amountOwing = amounts[0] + premiums[0];
        (
            uint256  _cycleType , 
            /* uint256 _maticAmountToCoinbase */, 
            /* address[] memory _targets */, 
            /* bytes[] memory _payloads */, 
            address[] memory _tokens, 
            /* address[] memory _dexRouterContractAddress */,
            address[][] memory _routerTokens
        ) = abi.decode(params, (uint256, uint256, address[], bytes[], address[], address[], address[][]));
        
        if (_cycleType == 0) {
            multiSingleSwapFLParams(amounts[0], params, amountOwing);
            IERC20(_tokens[0]).approve(address(LENDING_POOL), amountOwing);
        } else if (_cycleType == 1) {
            multiCyclicFLParams(amounts[0], params, amountOwing);
            IERC20(_routerTokens[0][0]).approve(address(LENDING_POOL), amountOwing);
        }
        
        return true;
    }

    /* 
        QuickSwap Flashloan
    */

    function flashloanUniswap(address borrowedTokenAddress, uint256 amountToBorrow, bytes memory _params) external permitRole(USER) {

        address pair;
        if (borrowedTokenAddress == address(WMATIC) || borrowedTokenAddress == address(SAND)) {
            // WMATIC-SAND
            pair = address(0x369582d2010B6eD950B571F4101e3bB9b554876F);
        } else {
            pair = IUniswapV2Factory(QUICKSWAP_Factory).getPair(borrowedTokenAddress, address(WMATIC));
            require(pair != address(0), "!pair");
        }
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint amount0Out = borrowedTokenAddress == token0 ? amountToBorrow : 0;
        uint amount1Out = borrowedTokenAddress == token1 ? amountToBorrow : 0;
        

        bytes memory data = abi.encode(borrowedTokenAddress, amountToBorrow, _params);

        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    function uniswapV2Call(
        address _sender,
        uint /* _amount0 */,
        uint /* _amount1 */,
        bytes calldata _data
    ) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(QUICKSWAP_Factory).getPair(token0, token1);

        require(msg.sender == pair, "!pair");
        require(_sender == address(this), "!sender");

        (address borrowedTokenAddress, uint amountToBorrow, bytes memory _params) = abi.decode(_data, (address, uint, bytes));

        uint fee = ((amountToBorrow * 3) / 997) + 1;
        uint amountToRepay = amountToBorrow + fee;

        (
            uint256  _cycleType , 
            /* uint256 _maticAmountToCoinbase */, 
            /* address[] memory _targets */, 
            /* bytes[] memory _payloads */, 
            /* address[] memory _tokens */, 
            /* address[] memory _dexRouterContractAddress */,
            /* address[][] memory _routerTokens */
        ) = abi.decode(_params, (uint256, uint256, address[], bytes[], address[], address[], address[][]));
        
        if (_cycleType == 0) {
            multiSingleSwapFLParams(amountToBorrow, _params, amountToRepay);
        } else if (_cycleType == 1) {
            multiCyclicFLParams(amountToBorrow, _params, amountToRepay);
        }

        IERC20(borrowedTokenAddress).transfer(pair, amountToRepay);
    }
}