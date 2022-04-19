// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./library/SwapHelper.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

interface IWETH {
    function deposit()
        external payable;

    function withdraw(uint) 
        external;

    function transfer(
        address to, 
        uint value) 
        external returns (bool);
}

/// @title Swap for Polygon chain
/// @author Matrixswap
/// @notice Swap 'multiple-tokens' -> 'single-token' or 'single-token' -> 'multiple-tokens' in one transaction.
/// 'single-token': ERC20 address, can be an input or output
/// 'multiple-tokens': array of ERC20 addresses, can be inputs or outputs
contract Swap is Initializable {
    using SafeMathUpgradeable for uint;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    event SwapEvent(
        address indexed from,
        uint amountIn,
        uint amountOut,
        address indexed to,
        uint amountMATIC,
        uint priceMATIC,
        uint8 decimalIn,
        uint8 decimalOut,
        uint8 defaultDecimal
    );
    
    /// @dev Placeholder address of native token. Not used for now.
    address private constant addressETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @dev Default WMATIC address for Polygon AMMs, except for Dfyn.
    address private constant addressWETH = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    /// @dev WMATIC contract
    IWETH WETH;
    /// @dev Array of addresses of aggregated AMMs for Polygon.
    IUniswapV2Router02[] private routerList;
    /// @dev Intermediary tokens used when there is no direct liquidity between 2 tokens.
    address[] private commonTokens;
    /// @notice Owner address
    address private owner;
    /// @notice Admin address
    address private admin;

    /// @dev Determines if the 'single-token' is native or not
    bool private isSingleEth;
    /// @dev Determines if the transaction is single token -> multiple tokens.
    bool private isMultiToSingleToken;
    /// @dev Address of input token, varies every loop of multiple token transaction.
    address private inputToken;
    /// @notice Address of output token, varies every loop of multiple token transaction.
    address private outputToken;
    /// @notice Commonly used error message.
    string private errorMessage;
    /// @dev Array of input and output amounts in a multiple tokens swap.
    /// Has a length of 2 and varies every loop
    uint[] private amount;
    /// @notice Determines if the transaction has multiple tokens, used as a fee basis.
    bool private isMultiSwap;
    /// @notice Determines if the nuke button on frontend if clicked, used as a fee basis.
    /// Nuke button's function is to find all of the user's approved tokens and choose
    /// those tokens automatically in convenience of the user.
    bool private isNukeTx;
    /// @notice Discount for the holders of MATRIX token.
    /// 25% off for holding 10000 or more MATRIX.
    /// 15% off for holding 5000 to 9999 MATRIX.
    /// Calculation is done in the frontend.
    uint private discount;
    /// @dev The timestamp used before the transaction expires.
    uint private deadline;
    /// @dev taken from ReentrancyGuardUpgradeable.sol of openzeppelin.
    uint private constant NOT_ENTERED = 1;
    /// @dev taken from ReentrancyGuardUpgradeable.sol of openzeppelin.
    uint private constant ENTERED = 2;
    /// @dev taken from ReentrancyGuardUpgradeable.sol of openzeppelin.
    uint private status;
    /// @notice The number of tokens to swap.
    uint8 private tokensCount;
    /// @dev The number of failed swap due to slippage.
    uint8 private failedTxCount;

    function initialize(
        address _owner, 
        address _admin, 
        address[] memory _routerList, 
        address[] memory _commonTokens
    ) external initializer {
        errorMessage = "Tx Fail";
        amount = new uint[](2);
        owner = _owner;
        admin = _admin;
        commonTokens = _commonTokens;
        status = NOT_ENTERED;

        for (uint8 i = 0; i < _routerList.length; i++) {
            routerList.push(IUniswapV2Router02(_routerList[i]));
        }
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    modifier onlyAdmin() {
        require(msg.sender == admin, "Matrixswap: caller is not the admin");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Matrixswap: caller is not the owner");
        _;
    }

    /// @dev taken from ReentrancyGuardUpgradeable.sol of openzeppelin.
    modifier nonReentrant() {
        require(status != ENTERED, "ReentrancyGuard: reentrant call");
        status = ENTERED;
        _;
        status = NOT_ENTERED;
    }

    function changeOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function addCommonToken(address _commonToken) external onlyAdmin {
        commonTokens.push(_commonToken);
    }

    function showOwner() external view returns(address _owner) {
        return owner;
    }

    function _getAmountMatic(
        uint _amountIn, 
        address _inputToken, 
        IUniswapV2Router02 _router, 
        address[] memory _path
    ) private view returns (uint _amountMATIC) {
        if (_inputToken == addressWETH) {
            _amountMATIC = _amountIn;
        }
        else if (_path.length == 3 && _path[1] == addressWETH) {
            _amountMATIC = _router.getAmountsOut(_amountIn, SwapHelper._path2(_inputToken, addressWETH))[1];
        }
        else {
            _amountMATIC = _router.getAmountsOut(_amountIn, _path)[_path.length-1];
        }
    }

    function _addSwapEvent(
        uint _amountIn, 
        uint _amountOut, 
        uint _amountMATIC
    ) private {
        /// @dev The price of MATIC against USD
        uint _priceMATIC = routerList[1].getAmountsOut(
            uint(1000000000000000000), 
            SwapHelper._path2(addressWETH, commonTokens[4]))[1];
        uint8 _decimalIn = IERC20Upgradeable(inputToken).decimals();
        uint8 _decimalOut = IERC20Upgradeable(outputToken).decimals();
        emit SwapEvent(msg.sender, _amountIn, _amountOut, msg.sender, _amountMATIC, _priceMATIC, _decimalIn, _decimalOut, uint8(18));
    }

    /// @notice swapping either ERC20 or native token to ERC20 token
    function _swapToken(
        IUniswapV2Router02 _router, 
        uint _amountIn, 
        address[] memory _path, 
        address _to, 
        address _tokenAddress, 
        bool _isEth, 
        uint _minimumAmountOut, 
        bool _isFirstCall
    ) private returns (uint[] memory amounts) {
        uint _fee;
        uint _percentage;
        if (!isMultiSwap || !_isFirstCall) {
            _fee = 0;
        }
        else if (isNukeTx) {
            _percentage = uint(1000).sub(uint(1000).mul(discount).div(100));
            _fee = (_amountIn.mul(_percentage)).div(uint(100000));
        }
        else {
            _percentage = uint(300).sub(uint(300).mul(discount).div(100));
            _fee = (_amountIn.mul(_percentage)).div(uint(100000));
        }

        if ((SwapHelper._isInputAllEth(isMultiToSingleToken, isSingleEth) || (_isEth && isMultiToSingleToken)) && _isFirstCall) {
            if (SwapHelper._isWrapUnwrap(_path[0], _path[1], addressWETH)) {
                WETH = IWETH(_path[0]);
                WETH.deposit{value: _amountIn}();
                bool success = WETH.transfer(msg.sender, _amountIn);
                require(success, errorMessage);
                amounts = new uint[](2);
                amounts[0] = _amountIn;
                amounts[1] = _amountIn;
            }
            else {
                if (_fee > 0) {
                    _amountIn = _amountIn.sub(_fee);
                    SwapHelper._safeTransferNativeToken(owner, _fee);
                }
                if (address(_router) == address(routerList[0])) {
                    /// @dev this is the address of Dfyn's version of WMATIC
                    /// this is a special case since it has different WMATIC from other AMMs
                    _path[0] = 0x4c28f48448720e9000907BC2611F73022fdcE1fA;
                }
                return _router.swapExactETHForTokens{value: _amountIn}(
                    _minimumAmountOut,
                    _path, 
                    _to, 
                    deadline
                );
            }
        }
        else {
            if (_fee > 0) {
                _amountIn = _amountIn.sub(_fee);
                IERC20Upgradeable(inputToken).safeTransfer(owner, _fee);
            }

            IERC20Upgradeable(_tokenAddress).safeApprove(address(_router), 0);
            IERC20Upgradeable(_tokenAddress).safeApprove(address(_router), _amountIn);
            
            return _router.swapExactTokensForTokens(
                _amountIn,
                _minimumAmountOut,
                _path,
                _to,
                deadline
            );
        }
    }

    /// @notice swapping ERC20 token to output native token
    function _swapToETH(
        address _firstPath, 
        address _secondPath, 
        IUniswapV2Router02 _router, 
        uint _amountIn, 
        address[] memory _path, 
        uint _minimumAmountOut, 
        bool isFirstCall
    ) private returns (uint[] memory amounts) {
        if (SwapHelper._isWrapUnwrap(_firstPath, _secondPath, addressWETH)) {
            WETH = IWETH(_firstPath);
            WETH.withdraw(_amountIn);
            SwapHelper._safeTransferNativeToken(msg.sender, _amountIn);
            amounts = new uint[](2);
            amounts[0] = _amountIn;
            amounts[1] = _amountIn;
        }
        else {
            if (isFirstCall && isMultiSwap) {
                uint _percentage = uint(300).sub(uint(300).mul(discount).div(100));
                uint _fee = (_amountIn.mul(_percentage)).div(uint(100000));
                _amountIn = _amountIn.sub(_fee);
                IERC20Upgradeable(_firstPath).safeTransfer(owner, _fee);
            }

            IERC20Upgradeable(_firstPath).safeApprove(address(_router), 0);
            IERC20Upgradeable(_firstPath).safeApprove(address(_router), _amountIn);

            amounts = _router.swapExactTokensForETH(
                _amountIn,
                _minimumAmountOut,
                _path,
                msg.sender,
                deadline
            );
        }
    }

    /// @notice swapping ERC20 token to intermediary ERC20 token
    function _swapToEthInitial(
        IUniswapV2Router02 _router, 
        address _tokenAddress, 
        uint _amountIn, 
        address[] memory _path, 
        uint _minimumAmountOut
    ) private returns (uint[] memory amounts) {
        if (isMultiSwap) {
            uint _percentage = uint(300).sub(uint(300).mul(discount).div(100));
            uint _fee = (_amountIn.mul(_percentage)).div(uint(100000));
            _amountIn = _amountIn.sub(_fee);
            IERC20Upgradeable(_tokenAddress).safeTransfer(owner, _fee);
        }

        IERC20Upgradeable(_tokenAddress).safeApprove(address(_router), 0);
        IERC20Upgradeable(_tokenAddress).safeApprove(address(_router), _amountIn);

        return _router.swapExactTokensForTokens(
            _amountIn,
            _minimumAmountOut,
            _path,
            address(this),
            deadline
        );
    }

    /// @notice this path follows swapping ERC20 token to native token
    function _everySwapToEth(
        uint _amountIn, 
        address _token, 
        uint8[] memory _swapRoute, 
        uint _minimumAmountOut
    ) private {
        IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _amountIn);

        if (_swapRoute[0] == _swapRoute[2] && _swapRoute[1] == 0) {
            _twoTokensSwapToEth(routerList[_swapRoute[0]-1], _amountIn, _minimumAmountOut);
        }

        else if (_swapRoute[0] == _swapRoute[2] && _swapRoute[1] > 0) {
            _threeTokensSwapToEth(
                commonTokens[_swapRoute[1]-1], 
                routerList[_swapRoute[0]-1], 
                _amountIn, 
                _minimumAmountOut
            );
        }

        else if (_swapRoute[0] != _swapRoute[2]) {
            _twoRoutersSwapToEth(
                commonTokens[_swapRoute[1]-1], 
                routerList[_swapRoute[0]-1], 
                routerList[_swapRoute[2]-1], 
                _amountIn, 
                _minimumAmountOut
            );
        }
    }

    /// @dev using 1 router with no intermediary token.
    /// Checks if the swap will pass with the set slippage.
    /// Returns native token to the user if the swap fails.
    function _twoTokensSwapToEth(
        IUniswapV2Router02 _router, 
        uint _amountIn, 

        uint _minimumAmountOut
    ) private {
        if (!SwapHelper._isValidTwoTokensSwap(
            _router, 
            _amountIn, 
            _minimumAmountOut, 
            inputToken, 
            outputToken, 
            addressWETH)
        ) {
            _returnBalanceToEth(_amountIn);
            return;
        }
        amount = _swapToETH(
            inputToken, 
            outputToken, 
            _router, 
            _amountIn, 
            SwapHelper._path2(inputToken, outputToken), 
            _minimumAmountOut, 
            true
        );
        uint _amountMATIC = _getAmountMatic(
            _amountIn, 
            inputToken, 
            _router, 
            SwapHelper._path2(inputToken, addressWETH)
        );
        _addSwapEvent(_amountIn, amount[amount.length - 1], _amountMATIC);
    }

    /// @dev using 1 router with intermediary token.
    /// Checks if the swap will pass with the set slippage.
    /// Returns native token to the user if the swap fails.
    function _threeTokensSwapToEth(
        address _secondPath, 
        IUniswapV2Router02 _router, 
        uint _amountIn, 
        uint _minimumAmountOut
    ) private {
        if (!SwapHelper._isValidThreeTokensSwap(
            _secondPath, 
            _router, 
            _amountIn, 
            _minimumAmountOut, 
            inputToken, 
            outputToken, 
            addressWETH)
        ) {
            _returnBalanceToEth(_amountIn);
            return;
        }
        amount = _swapToETH(
            inputToken, 
            _secondPath, 
            _router, 
            _amountIn, 
            SwapHelper._path3(inputToken, _secondPath, outputToken), 
            _minimumAmountOut, 
            true
        );
        uint _amountMATIC = _getAmountMatic(
            _amountIn, 
            inputToken, 
            _router, 
            SwapHelper._path3(inputToken, _secondPath, addressWETH)
        );
        _addSwapEvent(_amountIn, amount[amount.length - 1], _amountMATIC);
    }

    /// @dev using 2 routers. Default with intermediary token.
    /// Checks if the swap will pass with the set slippage.
    /// Returns native token to the user if the swap fails.
    function _twoRoutersSwapToEth(
        address _secondPath, 
        IUniswapV2Router02 _firstRouter, 
        IUniswapV2Router02 _secondRouter, 
        uint _amountIn, 
        uint _minimumAmountOut
    ) private {
        if (!SwapHelper._isValidTwoRoutersSwap(
            _secondPath, 
            _firstRouter, 
            _secondRouter, 
            _amountIn, 
            _minimumAmountOut, 
            inputToken, 
            outputToken, 
            addressWETH)
        ) {
            _returnBalanceToEth(_amountIn);
            return;
        }
        amount = _swapToEthInitial(
            _firstRouter, 
            inputToken, 
            _amountIn, 
            SwapHelper._path2(inputToken, _secondPath), 
            0
        );
        uint _amountMATIC = _getAmountMatic(
            amount[amount.length-1], 
            _secondPath, 
            _secondRouter, 
            SwapHelper._path2(_secondPath, addressWETH)
        );
        amount = _swapToETH(
            _secondPath, 
            outputToken, 
            _secondRouter, 
            amount[amount.length-1], 
            SwapHelper._path2(_secondPath, outputToken), 
            _minimumAmountOut, 
            false
        );
        _addSwapEvent(_amountIn, amount[amount.length - 1], _amountMATIC);
    }

    /// @dev using 1 router with no intermediary token.
    /// Checks if the swap will pass with the set slippage.
    /// Returns ERC20 to the user if the swap fails.
    function _twoTokensSwap(
        IUniswapV2Router02 _router, 
        uint _amountIn, 
        bool _isEth, 
        uint _minimumAmountOut
    ) private {
        if (!SwapHelper._isValidTwoTokensSwap(
            _router, 
            _amountIn, 
            _minimumAmountOut, 
            inputToken, 
            outputToken, 
            addressWETH)
        ) {
            _returnBalance(_isEth, _amountIn);
            return;
        }
        amount = _swapToken(
            _router, 
            _amountIn, 
            SwapHelper._path2(inputToken, outputToken), 
            msg.sender, 
            inputToken, 
            _isEth, 
            _minimumAmountOut, 
            true
        );
        uint _amountMATIC = _getAmountMatic(
            _amountIn, 
            inputToken, 
            _router, 
            SwapHelper._path2(inputToken, addressWETH)
        );
        _addSwapEvent(_amountIn, amount[amount.length - 1], _amountMATIC);
    }

    /// @dev using 1 router with intermediary token.
    /// Checks if the swap will pass with the set slippage.
    /// Returns ERC20 to the user if the swap fails.
    function _threeTokensSwap(
        address _secondPath, 
        IUniswapV2Router02 _router, 
        uint _amountIn, 
        bool _isEth, 
        uint _minimumAmountOut
    ) private {
        if (!SwapHelper._isValidThreeTokensSwap(
            _secondPath, 
            _router, 
            _amountIn, 
            _minimumAmountOut, 
            inputToken, 
            outputToken, 
            addressWETH)
        ) {
            _returnBalance(_isEth, _amountIn);
            return;
        }
        amount = _swapToken(
            _router, 
            _amountIn, 
            SwapHelper._path3(inputToken, _secondPath, outputToken), 
            msg.sender, 
            inputToken, 
            _isEth, 
            _minimumAmountOut, 
            true
        );
        uint _amountMATIC = _getAmountMatic(
            _amountIn, 
            inputToken, 
            _router, 
            SwapHelper._path3(inputToken, _secondPath, addressWETH)
        );
        _addSwapEvent(_amountIn, amount[amount.length - 1], _amountMATIC);
    }
    
    /// @dev using 2 routers. Default with intermediary token.
    /// Checks if the swap will pass with the set slippage.
    /// Returns ERC20 to the user if the swap fails.
    function _twoRoutersSwap(
        address _secondPath, 
        IUniswapV2Router02 _firstRouter, 
        IUniswapV2Router02 _secondRouter, 
        uint _amountIn, 
        bool _isEth, 
        uint _minimumAmountOut
    ) private {
        if (!SwapHelper._isValidTwoRoutersSwap(
            _secondPath, 
            _firstRouter, 
            _secondRouter, 
            _amountIn, 
            _minimumAmountOut, 
            inputToken, 
            outputToken, 
            addressWETH)
        ) {
            _returnBalance(_isEth, _amountIn);
            return;
        }
        amount = _swapToken(
            _firstRouter, 
            _amountIn, 
            SwapHelper._path2( inputToken, _secondPath), 
            address(this), 
            inputToken, 
            _isEth, 
            0, 
            true
        );
        uint _amountMATIC = _getAmountMatic(
            amount[amount.length-1], 
            _secondPath, 
            _secondRouter, 
            SwapHelper._path2(_secondPath, addressWETH)
        );
        amount = _swapToken(
            _secondRouter, 
            amount[amount.length-1], 
            SwapHelper._path2(_secondPath, outputToken), 
            msg.sender, 
            _secondPath, 
            _isEth, 
            _minimumAmountOut, 
            false
        );
        _addSwapEvent(_amountIn, amount[amount.length - 1], _amountMATIC);
    }

    /// @notice returns the native token to the user if the swap fails due to slippage
    function _returnBalanceToEth(uint _amountIn) private {
        failedTxCount = failedTxCount + uint8(1);
        require(failedTxCount < tokensCount, "Matrixswap: INSUFFICIENT_OUTPUT_AMOUNT");
        IERC20Upgradeable(inputToken).safeTransfer(msg.sender, _amountIn);
    }

    /// @notice returns the ERC20 token to the user if the swap fails due to slippage
    function _returnBalance(bool _isEth, uint _amountIn) private {
        failedTxCount = failedTxCount + uint8(1);
        require(failedTxCount < tokensCount, "Matrixswap: INSUFFICIENT_OUTPUT_AMOUNT");
        if (SwapHelper._isInputAllEth(isMultiToSingleToken, isSingleEth) || (_isEth && isMultiToSingleToken)) {
            SwapHelper._safeTransferNativeToken(msg.sender, _amountIn);
        }
        else {
            IERC20Upgradeable(inputToken).safeTransfer(msg.sender, _amountIn);
        }
    }

    /// @notice Swapping 'multiple-tokens' -> 'single-token' or 'single-token' -> 'multiple-tokens'
    /// @param _amountIn array of token amounts corresponding to 'multiple-tokens'
    /// @param _token array of ERC20 addresses corresponding to 'multiple-tokens'
    /// @param _swapRoute each array element contains an array with length of 3.
    /// _swapRoute element contains:
    /// [0]: index of first router used, reference: routerList
    /// [0]: index of intermediary token used, reference: commonTokens
    /// [1]: index of second router used, reference: routerList
    /// @param _isEth determines if the token from 'multiple-tokens' is native token
    /// @param _tokenTarget ERC20 address corresponding to 'single-token'
    /// @param _minimumAmountOut array of minimum amounts the user should receive
    /// so the swap will proceed without fail.
    /// @param _boolArray array containing [isMultiToSingleToken, isSingleEth, isNukeTx]
    /// @param _uintArray array containing [discount, deadline]
    /// They are enclosed in an array to avoid 'stack too deep' error
    function swap(
        uint[] memory _amountIn, 
        address[] memory _token, 
        uint8[][] memory _swapRoute, 
        bool[] memory _isEth, 
        address _tokenTarget, 
        uint[] memory _minimumAmountOut, 
        bool[] memory _boolArray, 
        uint[] memory _uintArray
    ) external payable nonReentrant {
        require(_token.length < uint8(40), "Block gas limit exceeded");
        isMultiToSingleToken = _boolArray[0];
        isSingleEth = _boolArray[1];
        isNukeTx = _boolArray[2];
        discount = _uintArray[0];
        deadline = _uintArray[1];
        isMultiSwap = _token.length > 1;
        tokensCount = uint8(_token.length);
        failedTxCount = uint8(0);
        uint _nativeTokenAmount = 0;

        for (uint8 i = 0; i < _token.length; i++) {
            inputToken = SwapHelper._getToken(_token[i], _tokenTarget, isMultiToSingleToken, true);
            outputToken = SwapHelper._getToken(_token[i], _tokenTarget, isMultiToSingleToken, false);

            if (!isSingleEth && !isMultiToSingleToken && _isEth[i]) {
                _everySwapToEth(_amountIn[i], inputToken, _swapRoute[i], _minimumAmountOut[i]);
                continue;
            }

            if (!(SwapHelper._isInputAllEth(isMultiToSingleToken, isSingleEth) || (_isEth[i] && isMultiToSingleToken))) {
                IERC20Upgradeable(inputToken).safeTransferFrom(msg.sender, address(this), _amountIn[i]);
            }
            else {
                _nativeTokenAmount = _nativeTokenAmount + _amountIn[i];
            }

            if (_swapRoute[i][0] == _swapRoute[i][2] && _swapRoute[i][1] == 0) {
                _twoTokensSwap(
                    routerList[_swapRoute[i][0]-1], 
                    _amountIn[i], 
                    _isEth[i], 
                    _minimumAmountOut[i]
                );
            }
            else if (_swapRoute[i][0] == _swapRoute[i][2] && _swapRoute[i][1] > 0) {
                _threeTokensSwap(
                    commonTokens[_swapRoute[i][1]-1], 
                    routerList[_swapRoute[i][0]-1], 
                    _amountIn[i], 
                    _isEth[i], 
                    _minimumAmountOut[i]
                );
            }
            else if (_swapRoute[i][0] != _swapRoute[i][2]) {
                _twoRoutersSwap(
                    commonTokens[_swapRoute[i][1]-1], 
                    routerList[_swapRoute[i][0]-1], 
                    routerList[_swapRoute[i][2]-1], 
                    _amountIn[i], _isEth[i], 
                    _minimumAmountOut[i]
                );
            }
        }

        /// @dev refund dust eth, if any
        if (msg.value > _nativeTokenAmount) SwapHelper._safeTransferNativeToken(msg.sender, msg.value - _nativeTokenAmount);
    }

    /// @notice Swapping 'multiple-tokens' to a native token
    /// @param _amountIn array of token amounts corresponding to 'multiple-tokens'
    /// @param _token array of ERC20 addresses  corresponding to 'multiple-tokens'
    /// @param _swapRoute each array element contains an array with length of 3.
    /// _swapRoute element contains:
    /// [0]: index of first router used, reference: routerList
    /// [0]: index of intermediary token used, reference: commonTokens
    /// [1]: index of second router used, reference: routerList
    /// @param _minimumAmountOut array of minimum amounts the user should receive
    /// so the swap will proceed without fail.
    /// @param _uintArray array containing [discount, deadline]
    /// They are enclosed in an array to avoid 'stack too deep' error
    function swapToETH(
        uint[] memory _amountIn, 
        address[] memory _token, 
        uint8[][] memory _swapRoute, 
        uint[] memory _minimumAmountOut, 
        uint[] memory _uintArray
    ) external nonReentrant { 
        require(_token.length < uint8(40), "Block gas limit exceeded");
        isMultiSwap = _token.length > 1;
        discount = _uintArray[0];
        deadline = _uintArray[1];
        tokensCount = uint8(_token.length);
        failedTxCount = uint8(0);

        for (uint8 i = 0; i < _token.length; i++) {
            inputToken = _token[i];
            outputToken = addressWETH;
            _everySwapToEth(_amountIn[i], _token[i], _swapRoute[i], _minimumAmountOut[i]);
        }
    }

    receive() payable external {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) 
        external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline)
        external returns (uint[] memory amounts);
    
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline)
        external payable returns (uint[] memory amounts);

    function WETH()
        external pure returns (address);

    function getAmountsOut(
        uint amountIn, 
        address[] memory path) 
        external view returns (uint[] memory amounts);
}

library SwapHelper {
    /// @notice Checks if the swap will pass with the set slippage.
    function _isValidTwoTokensSwap(
        IUniswapV2Router02 _router, 
        uint _amountIn, 
        uint _minimumAmountOut, 
        address _inputToken, 
        address _outputToken, 
        address _addressWETH
    ) internal view returns (bool success) {
        if (_isWrapUnwrap(_inputToken, _outputToken, _addressWETH)) return true;
        address[] memory _path = new address[](2);
        uint[] memory _amount = new uint[](2);
        _path[0] = _inputToken;
        _path[1] = _outputToken;
        _amount = _router.getAmountsOut(_amountIn, _path);
        success = _amount[_amount.length-1] > _minimumAmountOut;
    }

    /// @notice Checks if the swap will pass with the set slippage.
    function _isValidThreeTokensSwap(
        address _secondPath, 
        IUniswapV2Router02 _router, 
        uint _amountIn, 
        uint _minimumAmountOut, 
        address _inputToken, 
        address _outputToken, 
        address _addressWETH
    ) internal view returns (bool success) {
        if (_isWrapUnwrap(_inputToken, _outputToken, _addressWETH)) return true;
        address[] memory _path = new address[](3);
        uint[] memory _amount = new uint[](2);
        _path[0] = _inputToken;
        _path[1] = _secondPath;
        _path[2] = _outputToken;
        _amount = _router.getAmountsOut(_amountIn, _path);
        success = _amount[_amount.length-1] > _minimumAmountOut;
    }

    /// @notice Checks if the swap will pass with the set slippage.
    function _isValidTwoRoutersSwap(
        address _secondPath, 
        IUniswapV2Router02 _firstRouter, 
        IUniswapV2Router02 _secondRouter, 
        uint _amountIn, 
        uint _minimumAmountOut, 
        address _inputToken, 
        address _outputToken, 
        address _addressWETH
    ) internal view returns (bool success) {
        if (_isWrapUnwrap(_inputToken, _outputToken, _addressWETH)) return true;
        address[] memory _path = new address[](2);
        uint[] memory _amount = new uint[](2);
        uint[] memory _amount2 = new uint[](2);
        _path[0] = _inputToken;
        _path[1] = _secondPath;
        _amount = _firstRouter.getAmountsOut(_amountIn, _path);
        
        _path[0] = _secondPath;
        _path[1] = _outputToken;
        _amount2 = _secondRouter.getAmountsOut(_amount[_amount.length-1], _path);
        
        return _amount2[_amount2.length-1] > _minimumAmountOut;
    }

    /// @notice Checks which of the addresses is input or
    /// output and returns the address respectively.
    function _getToken(
        address _firstAddress, 
        address _secondAddress, 
        bool _isMultiToSingleToken, 
        bool _isInputToken
    ) internal pure returns (address token) {
        if (_isMultiToSingleToken == _isInputToken) {
            return _firstAddress;
        }
        else {
            return _secondAddress;
        }
    }

    /// @notice Checks if the input is 'single-token' and is a native token
    function _isInputAllEth(
        bool _isMultiToSingleToken, 
        bool _isSingleEth
    ) internal pure returns (bool) {
        return !_isMultiToSingleToken && _isSingleEth;
    }

    function _isWrapUnwrap(
        address _firstPath, 
        address _secondPath, 
        address weth
    ) internal pure returns (bool) {
        return _firstPath == _secondPath && _firstPath == weth;
    }

    function _path2(
        address _firstPath, 
        address _secondPath
    ) internal pure returns (address[] memory path) {
        address[] memory _path = new address[](2);
        _path[0] = _firstPath;
        _path[1] = _secondPath;
        return _path;
    }

    function _path3(
        address _firstPath, 
        address _secondPath, 
        address _thirdPath
    ) internal pure returns (address[] memory path) {
        address[] memory _path = new address[](3);
        _path[0] = _firstPath;
        _path[1] = _secondPath;
        _path[2] = _thirdPath;
        return _path;
    }

    function _safeTransferNativeToken(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "SwapHelper: NATIVE_TOKEN_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}