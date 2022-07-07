/**
 *Submitted for verification at polygonscan.com on 2022-07-07
*/

pragma solidity ^0.8.0;


library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }


    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface CToken {
    function comptroller() external view returns (address);
    function redeem(uint redeemTokens) external returns (uint);
    function underlying() external view returns (address);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function balanceOf(address owner) external view returns (uint256 balance);
    function symbol() external view returns (bytes32);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function balanceOfUnderlying(address account) external returns (uint);
    function accrueInterest() external returns (uint);
}

interface CEther is CToken {
    function liquidateBorrow(address borrower, address collateral) external payable;
}

interface CErc20 is CToken {
    function liquidateBorrow(address borrower, uint repayAmount, address collateral) external returns (uint);
}

interface IComptroller {
    function closeFactorMantissa() external view returns (uint256);
    function liquidationIncentiveMantissa() external view returns (uint);
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
    function getAssetsIn(address account) external view returns (address[] memory);
    function checkMembership(address account, address cToken) external view returns (bool);
    function liquidateCalculateSeizeTokens(address cTokenBorrowed, address cTokenCollateral, uint repayAmount) external view returns (uint, uint);
    function oracle() external view returns (address);
}

interface IPriceOracle {
    function getUnderlyingPrice(address cToken) external view returns (uint);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient,uint256 amount ) external returns (bool);
}

contract CompoundLikeLiquidate {

    using SafeERC20 for IERC20;
    using Address for address;

    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    address public owner;
    mapping(address => bool) public ethMarkets;
    address public WETH;


    constructor(address _WETH, address[] memory _ethMarkets){
        owner = msg.sender;
        WETH = _WETH;
        setEthMarkets(_ethMarkets,true);
    }

    receive() payable external {}

    function liquidate(address borrower, address borrowMarket, address collateralMarket, uint repayAmount) virtual public {

        checkAccountLiquidity(borrower, borrowMarket, collateralMarket);
        repayAmount = repayAmount==0 ? _calculateAmount(borrower, collateralMarket, borrowMarket) : repayAmount;
        liquidateBorrowAndRedeem(borrower, borrowMarket, collateralMarket, repayAmount);
    }


    function checkAccountLiquidity(address borrower, address borrowMarket, address collateralMarket) internal {
        _accrueInterest(borrower, borrowMarket);
        IComptroller comptroller = IComptroller(CToken(collateralMarket).comptroller());
        (,,uint shortfall) = comptroller.getAccountLiquidity(borrower);
        require(shortfall > 0, "Cannot be liquidated");
    }


    function liquidateBorrowAndRedeem(
        address borrower, 
        address borrowMarket, 
        address collateralMarket, 
        uint repayAmount
    ) internal{

        if (_isEthMarket(borrowMarket)) {
            IWETH(WETH).withdraw(repayAmount);
            CEther(borrowMarket).liquidateBorrow{value : repayAmount}(borrower, collateralMarket);
        }else{
            _approveInternal(CErc20(borrowMarket).underlying(), borrowMarket, repayAmount);    
            CErc20(borrowMarket).liquidateBorrow(borrower, repayAmount, collateralMarket);
        }

        uint collateralBalance = CToken(collateralMarket).balanceOf(address(this));
        require(collateralBalance > 0, "collateralBalance is zero");
        CToken(collateralMarket).redeem(collateralBalance);

        if (_isEthMarket(collateralMarket)) {
            IWETH(WETH).deposit{value : address(this).balance}();
        }

    }


    function _accrueInterest(address borrower,address _borrowMarket) internal{
        IComptroller comptroller = IComptroller(CToken(_borrowMarket).comptroller());
        address[] memory assertsIn = comptroller.getAssetsIn(borrower);
        for(uint i = 0; i < assertsIn.length; i++){
            CToken market = CToken(assertsIn[i]);
            (, , uint borrowBalance, ) = market.getAccountSnapshot(borrower);
            if(borrowBalance > 0){
                market.accrueInterest();
            }
        }
    }

    function _getUnderlyingPrice(address _market) internal view returns (uint){
        IComptroller comptroller = IComptroller(CToken(_market).comptroller());
        IPriceOracle priceOracle = IPriceOracle(comptroller.oracle());
        return priceOracle.getUnderlyingPrice(_market);
    }

    function _calculateAmount(address _borrower, address _collateralMarket, address _borrowMarket) internal returns (uint256){
        IComptroller comptroller = IComptroller(CToken(_borrowMarket).comptroller());

        uint closeFact = comptroller.closeFactorMantissa();
        uint liqIncent = comptroller.liquidationIncentiveMantissa();

        uint repayMax = CToken(_borrowMarket).borrowBalanceCurrent(_borrower) * closeFact / uint(10 ** 18);
        uint seizeMax = CToken(_collateralMarket).balanceOfUnderlying(_borrower) * uint(10 ** 18) / liqIncent;
        uint uPriceBorrow = _getUnderlyingPrice(_borrowMarket);

        repayMax *= uPriceBorrow;
        seizeMax *= _getUnderlyingPrice(_collateralMarket);

        return ((repayMax < seizeMax) ? repayMax : seizeMax) / uPriceBorrow;
    }
    
    function _isEthMarket(address _market) internal view returns (bool){
        return ethMarkets[_market];
    }

    function _balanceOfInternal(address _input) internal view returns (uint) {
        if (_input == ETH) {
            return address(this).balance;
        }
        return IERC20(_input).balanceOf(address(this));
    }

    function _transferInternal(address _asset, address payable _to, uint _amount) internal {
        if(_amount == 0) {
            return;
        }
        if (_asset == ETH) {
            (bool success,) = _to.call{value : _amount}("");
            require(success == true, "Couldn't transfer ETH");
            return;
        }
        IERC20(_asset).safeTransfer(_to, _amount);
    }

    function _approveInternal(address _asset, address _spender, uint amount) internal {
        IERC20 erc20 = IERC20(_asset);
        uint allowance = erc20.allowance(address(this), _spender);
        if (allowance < amount) {
            erc20.safeApprove(_spender, MAX_INT);
        }
    }

    // admin function

    function withdrawal(address _asset, address payable _to, uint _amount) public {
        require(msg.sender == owner);
        if (_amount == 0) {
            _amount = _balanceOfInternal(_asset);
        }
        _transferInternal(_asset, _to, _amount);
    }

    function setEthMarkets(address[] memory tokens, bool status) public {
        require(msg.sender == owner);
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            ethMarkets[token] = status;
        }
    }

    function call(address target, bytes memory data, uint256 value) external returns (bytes memory){
        require(msg.sender == owner);
        return target.functionCallWithValue(data,value,"Error call");
    }

}

contract CompoundLikeLiquidateWithUniswapFlashloan is CompoundLikeLiquidate {

    using SafeERC20 for IERC20;

    IUniswapV2Router02 public router;
    IUniswapV2Factory public factory;
    address[] public baseTokens;

    constructor(IUniswapV2Router02 _router, address[] memory _baseTokens, address _WETH, address[] memory _ethMarkets) CompoundLikeLiquidate(_WETH, _ethMarkets){
        router = _router;
        factory = IUniswapV2Factory(router.factory());
        setBaseTokens(_baseTokens);
    }


    function liquidate(address borrower, address borrowMarket, address collateralMarket, uint repayAmount) override public {
        
        checkAccountLiquidity(borrower, borrowMarket, collateralMarket);
        repayAmount = repayAmount==0 ? _calculateAmount(borrower, collateralMarket, borrowMarket) : repayAmount;

        address borrowToken = _isEthMarket(borrowMarket) ? WETH : CErc20(borrowMarket).underlying();
        address collateralToken = _isEthMarket(collateralMarket) ? WETH : CErc20(collateralMarket).underlying();

        (IUniswapV2Pair borrowPair, uint256 actualRepayAmount) = _getFlashloanPair(borrowToken, collateralToken, repayAmount);
        address againstToken = borrowPair.token0() == borrowToken ? borrowPair.token1() : borrowPair.token0();

        bytes memory data = abi.encode(
            borrower, 
            collateralMarket, 
            borrowMarket, 
            collateralToken, 
            borrowToken, 
            againstToken
        );
        uint amount0 = borrowPair.token0() == borrowToken ? actualRepayAmount : 0;
        uint amount1 = borrowPair.token1() == borrowToken ? actualRepayAmount : 0;
        borrowPair.swap(amount0, amount1, address(this), data);

        _transferInternal(borrowToken, payable(owner), _balanceOfInternal(borrowToken));
        _transferInternal(collateralToken, payable(owner), _balanceOfInternal(collateralToken));
        _transferInternal(againstToken, payable(owner), _balanceOfInternal(againstToken));
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        _flashloanCallback(sender, amount0, amount1, data);
    }

    function _flashloanCallback(address sender, uint amount0, uint amount1, bytes calldata data) internal {

        uint amount = amount0 != 0 ? amount0 : amount1;
        (address borrower, 
        address collateralMarket, 
        address borrowMarket, 
        address collateralToken, 
        address borrowToken,
        address againstToken) = abi.decode(data, (address, address, address, address, address, address));
        
        liquidateBorrowAndRedeem(borrower, borrowMarket, collateralMarket, amount);

        _payFlashloanBack(msg.sender, amount, borrowToken, collateralToken, againstToken);
    }


    function _getFlashloanPair(address borrowToken, address collateralToken, uint repayAmount) internal view returns (IUniswapV2Pair, uint){

        address[] memory tokens = new address[](baseTokens.length + 1);
        tokens[0] = collateralToken;
        for (uint256 i = 0; i < baseTokens.length; i++) {
            tokens[i + 1] = baseTokens[i];
        }

        IUniswapV2Pair borrowPair;
        uint actualRepayAmount;
        uint maxFlashLoan;

        for(uint i = 0; i < tokens.length; i++){
            IUniswapV2Pair _borrowPair = IUniswapV2Pair(factory.getPair(borrowToken, tokens[i]));
            if (address(_borrowPair) != address(0)) {
                uint _maxFlashLoan = _maxFlashLoanInternal(address(_borrowPair), borrowToken);
                if (_maxFlashLoan > maxFlashLoan) {
                    borrowPair = _borrowPair;
                    actualRepayAmount = _maxFlashLoan > repayAmount ? repayAmount : _maxFlashLoan;
                    maxFlashLoan = _maxFlashLoan;
                }
            }
        }

        require(address(borrowPair) != address(0), "not found borrowPair");

        return (borrowPair, actualRepayAmount);
    }

    function _payFlashloanBack(address pair, uint amount, address borrowToken, address collateralToken, address againstToken) internal {

        uint seizedAmount = _balanceOfInternal(collateralToken);

        //1. 如果 borrowToken == collateralToken 那么就不用做交易了
        if (borrowToken == collateralToken) {
            IERC20(borrowToken).safeTransfer(pair, (amount * 1000 / 997) + 1);
            return;
        }

        {
            (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
            (uint reserveIn, uint reserveOut) = IUniswapV2Pair(pair).token0() == borrowToken ? (reserve1, reserve0) : (reserve0, reserve1);
            uint amountRequired = router.getAmountIn(amount, reserveIn, reserveOut);

            //2. 如果 borrowToken 和 collateralToken 在一个交易对，那么就直接使用 collateralToken 还
            if (pair == factory.getPair(borrowToken, collateralToken) && seizedAmount > amountRequired) {
                IERC20(collateralToken).safeTransfer(pair, amountRequired);
                return;          
            }

            //3. pair == borrowToken/againstToken 。那么可以通过 collateralToken/againstToken 将 collateralToken 交易为 againstToken，然后还 againstToken。
            if(collateralToken != againstToken) {
                address[] memory path = new address[](2);
                path[0] = collateralToken;
                path[1] = againstToken;
                _approveInternal(collateralToken, address(router), seizedAmount);
                try router.swapTokensForExactTokens(amountRequired, seizedAmount, path, address(this), block.timestamp) returns(uint[] memory amounts) {
                    IERC20(againstToken).safeTransfer(pair, amountRequired);
                    return;
                }catch{

                }
            }
        }
    
        {
            //4. 计算在不包括闪电贷的pair外，最多能获得的交易金额以及路径；如果合适，就进行交易
            uint amountRequired = (amount * 1000 / 997) + 1;
            (uint amountOut, address[] memory bestPath) = _getEstimateOut(collateralToken, borrowToken, seizedAmount, pair);
            if(amountOut > amountRequired){
                _approveInternal(collateralToken, address(router), seizedAmount);
                router.swapTokensForExactTokens(amountOut, seizedAmount, bestPath, address(this), block.timestamp);
                IERC20(borrowToken).safeTransfer(pair, amountRequired);
                return;
            }
        }

    }

    function _maxFlashLoanInternal(address pairAddress, address token) internal view returns (uint256) {
        uint256 balance = IERC20(token).balanceOf(pairAddress);
        if (balance > 0) {
            return balance - 1;
        }
        return 0;
    }

    function _getEstimateOut(address tokenIn, address tokenOut, uint256 amountIn, address ignorePair) internal view returns (uint256, address[] memory){

        uint256 resultAmount = 0;
        address[] memory resultPath;

        for (uint256 i = 0; i < baseTokens.length; i++) {
            if (baseTokens[i] == tokenIn || baseTokens[i] == tokenOut) {
                continue;
            }
            if (factory.getPair(tokenIn, baseTokens[i]) == address(0)) {
                continue;
            }
            if (factory.getPair(baseTokens[i], tokenOut) != address(0)) {
                address[] memory tempPath = new address[](3);
                tempPath[0] = tokenIn;
                tempPath[1] = baseTokens[i];
                tempPath[2] = tokenOut;
                if(factory.getPair(tempPath[0], tempPath[1]) == ignorePair || factory.getPair(tempPath[1], tempPath[2]) == ignorePair){
                    continue;
                }

                uint256[] memory amounts = _getAmountsOut(amountIn, tempPath);
                if (resultAmount < amounts[amounts.length - 1]) {
                    resultAmount = amounts[amounts.length - 1];
                    resultPath = tempPath;
                }
            }

            for (uint256 j = 0; j < baseTokens.length; j++) {
                if (baseTokens[i] == baseTokens[j]) {
                    continue;
                }
                if (baseTokens[j] == tokenIn || baseTokens[j] == tokenOut) {
                    continue;
                }
                if (factory.getPair(baseTokens[i], baseTokens[j]) == address(0)) {
                    continue;
                }
                if (factory.getPair(baseTokens[j], tokenOut) == address(0)) {
                    continue;
                }
                address[] memory tempPath = new address[](4);
                tempPath[0] = tokenIn;
                tempPath[1] = baseTokens[i];
                tempPath[2] = baseTokens[j];
                tempPath[3] = tokenOut;
                if(factory.getPair(tempPath[0], tempPath[1]) == ignorePair || factory.getPair(tempPath[1], tempPath[2]) == ignorePair || factory.getPair(tempPath[2], tempPath[3]) == ignorePair){
                    continue;
                }

                uint256[] memory amounts = _getAmountsOut(amountIn, tempPath);
                if (resultAmount < amounts[amounts.length - 1]) {
                    resultAmount = amounts[amounts.length - 1];
                    resultPath = tempPath;
                }
            }
   
        }

        return (resultAmount, resultPath);

    }

    function _getAmountsOut(uint256 amountIn, address[] memory path) internal view returns (uint256[] memory) {
        bytes memory data = abi.encodeWithSignature("getAmountsOut(uint256,address[])", amountIn, path);
        (bool success, bytes memory returnData) = address(router).staticcall(data);
        if (success) {
            return abi.decode(returnData, (uint256[]));
        } else {
            uint256[] memory result = new uint256[](1);
            result[0] = 0;
            return result;
        }
    }

    // admin function
    function setBaseTokens(address[] memory tokens) public {
        require(msg.sender == owner);
        baseTokens = tokens;
    }



}