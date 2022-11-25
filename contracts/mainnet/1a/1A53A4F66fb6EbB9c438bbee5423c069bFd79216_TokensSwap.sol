/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: TokenSwap.sol


pragma solidity 0.8.7;



interface IERC20{

    function balanceOf(
        address account
    ) external view returns (
        uint256
    );
 
}


interface IUniswapV2CustomRouter {

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address[] calldata feePath,
        address to,
        uint deadline
    ) external payable returns (
        uint[] memory amounts
    );
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address[] calldata feePath,
        address to,
        uint deadline
    ) external payable returns (
        uint[] memory amounts
    );
    function swapTokensForExactETH(
        uint amountOut, 
        uint amountInMax, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (
        uint[] memory amounts
    );
    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (
        uint[] memory amounts
    );
    function swapExactETHForTokens(
        uint amountIn,
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (
        uint[] memory amounts
    );
    function swapETHForExactTokens(
        uint amountIn,
        uint amountOut, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (
        uint[] memory amounts
    );
    function quote(
        uint amountA, 
        uint reserveA, 
        uint reserveB
    ) external pure returns (
        uint amountB
    );
    function getAmountOut(
        uint amountIn, 
        uint reserveIn, 
        uint reserveOut
    ) external pure returns (
        uint amountOut
    );
    function getAmountIn(
        uint amountOut, 
        uint reserveIn, 
        uint reserveOut
    ) external pure returns (
        uint amountIn
    );
    function getAmountsOut(
        uint amountIn, 
        address[] calldata path
    ) external view returns (
        uint[] memory amounts
    );
    function getAmountsIn(
        uint amountOut, 
        address[] calldata path
    ) external view returns (
        uint[] memory amounts
    );

}


interface IWETH {

    function transfer(
        address to, 
        uint value
    ) external returns (
        bool
    );
    function withdraw(
        uint
    ) external;
    function deposit() external payable;

}


interface IUniswapV2Pair {

    event Approval(
        address indexed owner, 
        address indexed spender, 
        uint value
    );
    event Transfer(
        address indexed from, 
        address indexed to, 
        uint value
    );
    event Mint(
        address indexed sender, 
        uint amount0, 
        uint amount1
    );
    event Burn(
        address indexed sender, 
        uint amount0, 
        uint amount1, 
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(
        uint112 reserve0, 
        uint112 reserve1
    );

    function approve(
        address spender, 
        uint value
    ) external returns (
        bool
    );
    function transfer(
        address to, 
        uint value
    ) external returns (
        bool
    );
    function transferFrom(
        address from, 
        address to, 
        uint value
    ) external returns (
        bool
    );
    function mint(
        address to
    ) external returns (
        uint liquidity
    );
    function burn(
        address to
    ) external returns (
        uint amount0, 
        uint amount1
    );
    function swap(
        uint amount0Out, 
        uint amount1Out, 
        address to, 
        bytes calldata data
    ) external;
    function skim(
        address to
    ) external;
    function sync() external;
    function initialize(
        address, address
    ) external;
    function permit(
        address owner, 
        address spender, 
        uint value, 
        uint deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external;
    function MINIMUM_LIQUIDITY() external pure returns (
        uint
    );
    function PERMIT_TYPEHASH() external pure returns (
        bytes32
    );
    function name() external pure returns (
        string memory
    );
    function symbol() external pure returns (
        string memory
    );
    function decimals() external pure returns (
        uint8
    );
    function totalSupply() external view returns (
        uint
    );
    function balanceOf(
        address owner
    ) external view returns (
        uint
    );
    function allowance(
        address owner, 
        address spender
    ) external view returns (
        uint
    );
    function DOMAIN_SEPARATOR() external view returns (
        bytes32
    );
    function nonces(
        address owner
    ) external view returns (
        uint
    );
    function factory() external view returns (
        address
    );
    function token0() external view returns (
        address
    );
    function token1() external view returns (
        address
    );
    function getReserves() external view returns (
        uint112 reserve0, 
        uint112 reserve1, 
        uint32 blockTimestampLast
    );
    function price0CumulativeLast() external view returns (
        uint
    );
    function price1CumulativeLast() external view returns (
        uint
    );
    function kLast() external view returns (
        uint
    );

}


library TransferHelper {

    function safeApprove(
        address token, 
        address to, 
        uint value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token, 
        address to, 
        uint value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token, 
        address from, 
        address to, 
        uint value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(
        address to, 
        uint value
    ) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

}


library SafeMathUniswap {

    function add(
        uint x, 
        uint y
    ) internal pure returns (
        uint z
    ) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(
        uint x, 
        uint y
    ) internal pure returns (
        uint z
    ) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(
        uint x, 
        uint y
    ) internal pure returns (
        uint z
    ) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

}


library UniswapV2Library {

    using SafeMathUniswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(
        address tokenA, 
        address tokenB
    ) internal pure returns (
        address token0, 
        address token1
    ) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory, 
        address tokenA, 
        address tokenB
    ) internal pure returns (
        address pair
    ) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory, 
        address tokenA, 
        address tokenB
    ) internal view returns (
        uint reserveA, 
        uint reserveB
    ) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint amountA, 
        uint reserveA, 
        uint reserveB
    ) internal pure returns (
        uint amountB
    ) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint amountIn, 
        uint reserveIn, 
        uint reserveOut
    ) internal pure returns (
        uint amountOut
    ) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint amountOut, 
        uint reserveIn, 
        uint reserveOut
    ) internal pure returns (
        uint amountIn
    ) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory, 
        uint amountIn, 
        address[] memory path
    ) internal view returns (
        uint[] memory amounts
    ) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory, 
        uint amountOut, 
        address[] memory path
    ) internal view returns (
        uint[] memory amounts
    ) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

}


/**
 *
 * @author Bhupesh Dubey 
*/
contract TokensSwap is IUniswapV2CustomRouter, Ownable {

    using SafeMathUniswap for uint;

    struct SwapUtils {
        uint appFee;
        uint appFeeInEther;
        uint[] resultAmount;  
    }
    struct DiscountRates{
        uint amount;
        uint8 discountPercent;
    }

    address public immutable factory;
    address public immutable WETH;
    address public immutable USDC;
    address public feeHolderAddress;
    address public gieTokenContract;

    DiscountRates[4] public discountRates; 

    uint public gieAppFees;
    uint public gieAppFeesDecimals;
    uint public donationFees;
    uint public donationFeesDecimals;
    uint public totalCollectedFee;
    uint public totalCollectedDonationFee;

    modifier ensure(
        uint deadline
    ) {
        require(
            deadline >= block.timestamp, 
            'UniswapV2Router: EXPIRED'
        );
        _;
    }

    modifier onlyValidFees(
        uint fees, 
        uint decimals
    ) {
        require(
            fees != 0 && 
            decimals != 0, 
            "Invalid fees!"
        );
        require(
            fees/decimals <= 100, 
            "Fee percent should be greater than 0 & less than equal to 100!"
        );
        _;
    }

    event FeesPaid(
        address indexed swapper,
        uint indexed feesPaid
    );
    event DonationFeesPaid(
        address indexed donater,
        address indexed treasuryAddress,
        uint indexed treasuryAmount,
        uint donationFeesPaid
    );

    /**
     *
     * @notice constructor initializes sushiswap and fees contracts
       @param _factory sushiswap's factory contract address
       @param _WETH sushiswap's WETH contract address
       @param _USDC sushiswap's USDC contract address
       @param _gieTokenContract gie token contract address
       @param _feeHolderAddress fee holder address
       @param _fees fees percent to be dedcuted from transaction of user
       @param _decimals decimals for gie app fees fraction value
       @param _donationFees fees percent to be dedcuted for donation
       @param _donationFeesDecimals decimals for donation fees fraction value
    */
    constructor(
        address _factory, 
        address _WETH,
        address _USDC,
        address _gieTokenContract,
        address _feeHolderAddress,
        uint _fees,
        uint _decimals,
        uint _donationFees,
        uint _donationFeesDecimals
    ) onlyValidFees(_fees, _decimals) onlyValidFees(_donationFees, _donationFeesDecimals) {
        require(
            _factory != address(0) && 
            _WETH != address(0) && 
            _USDC != address(0) && 
            _gieTokenContract != address(0) &&
            _feeHolderAddress != address(0), 
            "Swap: zero address not allowed!"
        );
        factory = _factory;
        WETH = _WETH;
        USDC =_USDC;
        gieTokenContract = _gieTokenContract;
        feeHolderAddress = _feeHolderAddress;
        gieAppFees = _fees;
        gieAppFeesDecimals = _decimals;
        donationFees = _donationFees;
        donationFeesDecimals = _donationFeesDecimals;
        discountRates[0] = DiscountRates(50000 * 10 ** 18, 5);
        discountRates[1] = DiscountRates(250000 * 10 ** 18, 10);
        discountRates[2] = DiscountRates(500000 * 10 ** 18, 25);
        discountRates[3] = DiscountRates(1000000 * 10 ** 18, 60);
    }

    /**
     *
     * @notice gets called when someone sends ether to this contract
    */
    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    /**
     *
     * @notice swaps first token with second token provided in path array such that user      
       specifies the input token amount here and accordingly output tokens are derived
       @return amounts array consisting on input tokens and output tokens amount
       @param amountIn amount to provide as a input for swap
       @param amountOutMin amount to expect as a output for swap
       @param path array of addresses with input and output tokens to make a swap
       @param feePath array of addresses with input and Ether address to charge fees
       @param to user's wallet address where output token has to be sent
       @param deadline timestamp before which transaction should be completed
    */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address[] calldata feePath,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (
        uint[] memory amounts
    ) {
        require(path[0] == feePath[0], "Invalid input token!");
        require(feePath[feePath.length-1] == WETH, "Invalid fee token!");
        SwapUtils memory swapUtils = _swapPreCheck(msg.sender, feePath, amountIn, false, msg.value);
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "Insufficient output amount!");
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
        totalCollectedFee += swapUtils.appFeeInEther;
        TransferHelper.safeTransferETH(feeHolderAddress, swapUtils.appFeeInEther);
        if(msg.value > swapUtils.appFeeInEther){
            TransferHelper.safeTransferETH(msg.sender, (msg.value - swapUtils.appFeeInEther));
        }
        emit FeesPaid(
            msg.sender,
            swapUtils.appFeeInEther
        );
    }

    /**
     *
     * @notice swaps first token with second token provided in path array such that user      
       specifies the output token amount here and accordingly input tokens are derived
       @return amounts array consisting on input tokens and output tokens amount
       @param amountOut amount to expect as a output for swap
       @param amountInMax amount to provide as a input for swap
       @param path array of addresses with input and output tokens to make a swap
       @param feePath array of addresses with input and Ether address to charge fees
       @param to user's wallet address where output token has to be sent
       @param deadline timestamp before which transaction should be completed
    */
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address[] calldata feePath,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (
        uint[] memory amounts
    ) {
        require(path[0] == feePath[0], "Invalid input token!");
        require(feePath[feePath.length-1] == WETH, "Invalid fee token!");
        SwapUtils memory swapUtils = _swapPreCheck(msg.sender, feePath, amountInMax, false, msg.value);
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "Excessive input amount!");
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
         totalCollectedFee += swapUtils.appFeeInEther;
        TransferHelper.safeTransferETH(feeHolderAddress, swapUtils.appFeeInEther);
        if(msg.value > swapUtils.appFeeInEther){
            TransferHelper.safeTransferETH(msg.sender, (msg.value - swapUtils.appFeeInEther));
        }
        emit FeesPaid(
            msg.sender,
            swapUtils.appFeeInEther
        );
    }

    /**
     *
     * @notice swaps first token with ether provided in path array such that user      
       specifies the ether output amount here and accordingly input tokens are derived
       @return amounts array consisting on input tokens and output tokens amount
       @param amountOut amount to expect as a output for swap
       @param amountInMax amount to provide as a input for swap
       @param path array of addresses with input and output tokens to make a swap
       @param to user's wallet address where output token has to be sent
       @param deadline timestamp before which transaction should be completed
    */
    function swapTokensForExactETH(
        uint amountOut, 
        uint amountInMax, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external virtual override payable ensure(deadline) returns (
        uint[] memory amounts
    ) {
        require(path[path.length - 1] == WETH, "Invalid path!");
        SwapUtils memory swapUtils = _swapPreCheck(msg.sender, path, amountInMax, false, msg.value);
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, "Excessive input amount!");
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
         totalCollectedFee += swapUtils.appFeeInEther;
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(feeHolderAddress, swapUtils.appFeeInEther);
        if(msg.value > swapUtils.appFeeInEther){
            TransferHelper.safeTransferETH(msg.sender, (msg.value - swapUtils.appFeeInEther));
        }
        emit FeesPaid(
            msg.sender,
            swapUtils.appFeeInEther
        );
    }

    /**
     *
     * @notice swaps first token with ether provided in path array such that user      
       specifies the input amount of first token here and accordingly output token ether is derived
       @return amounts array consisting on input tokens and output tokens amount
       @param amountIn amount to provide as a input for swap
       @param amountOutMin amount to expect as a output for swap
       @param path array of addresses with input and output tokens to make a swap
       @param to user's wallet address where output token has to be sent
       @param deadline timestamp before which transaction should be completed
    */
    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external virtual override payable ensure(deadline) returns (
        uint[] memory amounts
    ) {
        require(path[path.length - 1] == WETH, "Invalid path!");
        SwapUtils memory swapUtils = _swapPreCheck(msg.sender, path, amountIn, false, msg.value);
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "Insufficient output amount!");
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
         totalCollectedFee += swapUtils.appFeeInEther;
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(feeHolderAddress, swapUtils.appFeeInEther);
        if(msg.value > swapUtils.appFeeInEther){
            TransferHelper.safeTransferETH(msg.sender, (msg.value - swapUtils.appFeeInEther));
        }
        emit FeesPaid(
            msg.sender,
            swapUtils.appFeeInEther
        );
    }

    /**
     *
     * @notice swaps ether with second token provided in path array such that user      
       specifies the second token output amount here and accordingly input ether is derived
       @return amounts array consisting on input tokens and output tokens amount
       @param amountIn amount to provide as a input for swap
       @param amountOut amount to expect as a output for swap
       @param path array of addresses with input and output tokens to make a swap
       @param to user's wallet address where output token has to be sent
       @param deadline timestamp before which transaction should be completed
    */
    function swapETHForExactTokens(
        uint amountIn,
        uint amountOut, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external virtual override payable ensure(deadline) returns (
        uint[] memory amounts
    ) {
        require(path[0] == WETH, "Invalid path!");
        SwapUtils memory swapUtils = _swapPreCheck(msg.sender, path, amountIn, true, msg.value);
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= (msg.value - swapUtils.appFeeInEther), "Excessive input amount!");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        totalCollectedFee += swapUtils.appFeeInEther;
        TransferHelper.safeTransferETH(feeHolderAddress, swapUtils.appFeeInEther);
        if(msg.value > (swapUtils.appFeeInEther + amounts[0])){
            TransferHelper.safeTransferETH(msg.sender, (msg.value - (swapUtils.appFeeInEther + amounts[0])));
        }
        emit FeesPaid(
            msg.sender,
            swapUtils.appFeeInEther
        );
    }

    /**
     *
     * @notice swaps ether with output token provided in path array such that user      
       specifies the input amount of ether here and accordingly output token amount is derived
       @return amounts array consisting on input tokens and output tokens amount
       @param amountIn amount to provide as a input for swap
       @param amountOutMin amount to expect as a output for swap
       @param path array of addresses with input and output tokens to make a swap
       @param to user's wallet address where output token has to be sent
       @param deadline timestamp before which transaction should be completed
    */
    function swapExactETHForTokens(
        uint amountIn,
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external virtual override payable ensure(deadline) returns (
        uint[] memory amounts
    ) {
        require(path[0] == WETH, "Invalid path!");
        SwapUtils memory swapUtils = _swapPreCheck(msg.sender, path, amountIn, true, msg.value);
        amounts = UniswapV2Library.getAmountsOut(factory, (msg.value - swapUtils.appFeeInEther), path);
        require(amounts[amounts.length - 1] >= amountOutMin, "Insufficient output amount!");
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
         totalCollectedFee += swapUtils.appFeeInEther;
        TransferHelper.safeTransferETH(feeHolderAddress, swapUtils.appFeeInEther);
        if(msg.value > (swapUtils.appFeeInEther + amounts[0])){
            TransferHelper.safeTransferETH(msg.sender, (msg.value - (swapUtils.appFeeInEther + amounts[0])));
        }
        emit FeesPaid(
            msg.sender,
            swapUtils.appFeeInEther
        );
    }

    /**
     *
     * @notice swaps first token with USDC provided in path array such that user      
       specifies the input token amount here and accordingly output tokens are derived
       @return amounts array consisting on input tokens and output tokens amount
       @param amountIn amount to provide as a input for swap
       @param path array of addresses with input and output tokens to make a swap
       @param to treasury wallet address where output token has to be sent
       @param deadline timestamp before which transaction should be completed
    */
    function swapExactTokensToUSDCForDonation(
        uint amountIn,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (
        uint[] memory amounts
    ) {
        uint donationAmount;
        uint treasuryAmount;
        string memory underflowErrorMessage = "Underflow value";
        if(path[0] == USDC){
            require((amountIn * donationFees) >= (donationFeesDecimals * 100), underflowErrorMessage);
            donationAmount = (amountIn * donationFees)/(donationFeesDecimals * 100);
            treasuryAmount = amountIn - donationAmount;
            TransferHelper.safeTransferFrom(USDC, msg.sender, feeHolderAddress, donationAmount);
            TransferHelper.safeTransferFrom(USDC, msg.sender, to, treasuryAmount);
        }else{
            require(path[path.length-1] == USDC, "Invalid input token!");
            amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
            require((amounts[amounts.length-1] * (donationFees)) >= (donationFeesDecimals * 100), underflowErrorMessage);
            TransferHelper.safeTransferFrom(
                path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
            );
            _swap(amounts, path, address(this));
            donationAmount = (amounts[amounts.length-1] * (donationFees))/(donationFeesDecimals * 100);   
            treasuryAmount = amounts[amounts.length-1] - donationAmount;
            TransferHelper.safeTransfer(USDC, feeHolderAddress, donationAmount);
            TransferHelper.safeTransfer(USDC, to, treasuryAmount);
        }
        totalCollectedDonationFee += donationAmount;
        emit DonationFeesPaid(
            msg.sender,
            to,
            treasuryAmount,
            donationAmount
        );
    }

    /**
     *
     * @notice swaps ether with USDC provided in path array such that user specifies the 
       input amount of ether here and accordingly output token amount is derived
       @return amounts array consisting on input tokens and output tokens amount
       @param amountIn amount to provide as a input for swap
       @param path array of addresses with input and output tokens to make a swap
       @param to treasury address where output token has to be sent
       @param deadline timestamp before which transaction should be completed
    */
    function swapExactETHToUSDCForDonation(
        uint amountIn, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable ensure(deadline) returns (
        uint[] memory amounts
    ) {
        uint donationAmount;
        uint treasuryAmount;
        require(path[0] == WETH && path[path.length-1] == USDC, "Invalid tokens path!");
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, address(this));
        donationAmount = (amounts[amounts.length-1] * (donationFees))/(donationFeesDecimals * 100) ;
        treasuryAmount = amounts[amounts.length-1] - donationAmount;
        TransferHelper.safeTransfer(USDC, feeHolderAddress, donationAmount);
        TransferHelper.safeTransfer(USDC, to, treasuryAmount);
        totalCollectedDonationFee += donationAmount;
        emit DonationFeesPaid(
            msg.sender,
            to,
            treasuryAmount,
            donationAmount
        );
    }

    /**
     *
     * @notice swaps first token with MATIC and then USDC provided in path array such that user      
       specifies the input token amount here and accordingly output tokens are derived
       @return amounts array consisting on input tokens and output tokens amount
       @param amountIn amount to provide as a input for swap
       @param amountOutMin amount to expect as a output for swap
       @param path1 array of addresses with input and output tokens to make a swap e.g [SDT, MATIC]
       @param path2 array of addresses with input and output tokens to make a swap e.g [MATIC, USDC]
       @param to treasury wallet address where output token has to be sent
       @param deadline timestamp before which transaction should be completed
    */
    function swapExactTokensToETHToUSDCForDonation(
        uint amountIn,
        uint amountOutMin, 
        address[] calldata path1,
        address[] calldata path2,
        address to,
        uint deadline
    ) external payable virtual ensure(deadline) returns (
        uint[] memory amounts
    ) {
        require(path1[path1.length - 1] == WETH, "Invalid path!");
        SwapUtils memory swapUtils = _swapPreCheck(msg.sender, path1, amountIn, false, msg.value);
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path1);
        require(amounts[amounts.length - 1] >= amountOutMin, "Insufficient output amount!");
        TransferHelper.safeTransferFrom(
            path1[0], msg.sender, UniswapV2Library.pairFor(factory, path1[0], path1[1]), amounts[0]
        );
        _swap(amounts, path1, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        totalCollectedFee += swapUtils.appFeeInEther;
        uint WETHAmount = amounts[amounts.length - 1];
  

        uint donationAmount;
        uint treasuryAmount;
        require(path2[0] == WETH && path2[path2.length-1] == USDC, "Invalid tokens path!");
        amounts = UniswapV2Library.getAmountsOut(factory, WETHAmount, path2);
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path2[0], path2[1]), amounts[0]));
        _swap(amounts, path2, address(this));
        donationAmount = (amounts[amounts.length-1] * (donationFees))/(donationFeesDecimals * 100) ;
        treasuryAmount = amounts[amounts.length-1] - donationAmount;
        donationAmount = donationAmount+(swapUtils.appFeeInEther);
        TransferHelper.safeTransfer(USDC, feeHolderAddress, donationAmount);
        TransferHelper.safeTransfer(USDC, to, treasuryAmount);
        if(msg.value > swapUtils.appFeeInEther){
            TransferHelper.safeTransferETH(msg.sender, (msg.value - swapUtils.appFeeInEther));
        }
        totalCollectedDonationFee += donationAmount;
        emit DonationFeesPaid(
            msg.sender,
            to,
            treasuryAmount,
            donationAmount
        );
    }

    /**
     *
     * @notice swaps ether with USDC provided in path array such that user specifies the 
       input amount of ether here and accordingly output token amount is derived
       @return amounts array consisting on input tokens and output tokens amount
       @param amountIn amount to provide as a input for swap
       @param path array of addresses with input and output tokens to make a swap
       @param deadline timestamp before which transaction should be completed
    */
    function swapExactETHToUSDCForConversion(
        uint amountIn, 
        address[] calldata path, 
        uint deadline
    ) external payable ensure(deadline) onlyOwner() returns (
        uint[] memory amounts
    ) {
        require(path[0] == WETH && path[path.length-1] == USDC, "Invalid tokens path!");
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, msg.sender);
    }

    /**
     *
     * @notice modifies the Donation fees and can be called by contract owner only
       @notice zero's appended in the last of input number represents decimal places
       @param _fees fees percent to be dedcuted from donation of user
       @param _decimals decimals for donation fees fraction value
    */
    function setDonationFees(
        uint _fees,
        uint _decimals
    ) external onlyOwner() onlyValidFees(_fees, _decimals) {
        require(
            _fees != donationFees || 
            _decimals != donationFeesDecimals, 
            "Already same fee used!"
        );        
        donationFees = _fees;
        donationFeesDecimals = _decimals;
    }

    /**
     *
     * @notice modifies the Gie app fees and can be called by contract owner only
       @notice zero's appended in the last of input number represents decimal places
       @param fees fees percent to be dedcuted from transaction of user
       @param decimals decimals for gie app fees fraction value
    */
    function setGieAppFees(
        uint fees,
        uint decimals
    ) external onlyOwner() onlyValidFees(fees, decimals) {
        require(
            fees != gieAppFees || 
            decimals != gieAppFeesDecimals, 
            "Already same fee used!"
        );        
        gieAppFees = fees;
        gieAppFeesDecimals = decimals;
    }

    /**
     *
     * @notice modifies the fee holder address and can be called by contract owner only
       @param _feeHolderAddress new donation holder address
    */
    function setFeeHolderAddress(
        address _feeHolderAddress
    ) external onlyOwner() {
        require(_feeHolderAddress != address(0), "Fee holder is the zero address");
        require(feeHolderAddress != _feeHolderAddress, "Already a fee holder address!");
        feeHolderAddress = _feeHolderAddress;
    }
    
    /**
     *
     * @notice modifies the gie token contract address and can be called by contract owner only
       @param _gieTokenContract new gie token contract address
    */
    function setGieTokenContract(
        address _gieTokenContract
    ) external onlyOwner() {
        require(_gieTokenContract != address(0), "Swap: gie token contract is the zero address");
        require(_gieTokenContract != gieTokenContract, "Already a GIE Token contract address!");
        gieTokenContract = _gieTokenContract;
    }

    /**
     *
     * @notice updates discount rates for GIE token holders, only owner allowed
       @param _tierNo tier no. whose rate is to be changes
       @param _amount new amount for the tier for discount
       @param _discountPercent new discount percent for tier
    */
    function updateDiscount(
        uint _tierNo, 
        uint _amount, 
        uint8 _discountPercent
    ) external onlyOwner() {
        require(_tierNo > 0 && _tierNo < 5, "tier no. should be between 0 and 5!");
        require(_amount > 0 && _discountPercent > 0, "amount & discount should be greater than 0!");
        if(_tierNo > 1 && _tierNo < 4){
            _preUpdateDiscountCheck(_tierNo, _amount, _discountPercent, 0);
            _preUpdateDiscountCheck(_tierNo, _amount, _discountPercent, 2);
            _updateDiscount(_tierNo, _amount, _discountPercent);
        } else if(_tierNo == 1){
            _preUpdateDiscountCheck(_tierNo, _amount, _discountPercent, 0);
            _updateDiscount(_tierNo, _amount, _discountPercent);
        } else{
            _preUpdateDiscountCheck(_tierNo, _amount, _discountPercent, 2);
            _updateDiscount(_tierNo, _amount, _discountPercent);
        }
    }

    /**
     *
       @notice changes the owner to new owner
       @param newOwner address of the new owner
    */
    function transferOwnership(
        address newOwner
    ) public override onlyOwner {
        require(newOwner != address(0), "Swap: new owner is the zero address");
        require(newOwner != owner(), "Swap: Already a owner");
        _transferOwnership(newOwner);
    }

    /**
     *
     * @notice swaps one token with another token
       @param amounts array of input and output tokens amount
       @param path array of input and output tokens addresses
       @param _to address of user where swapped tokens has to be sent
    */
    function _swap(
        uint[] memory amounts, 
        address[] memory path, 
        address _to
    ) internal {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    /**
     *
     * @notice modifies the discount rate states
       @param _tierNo tier no. whose rate is to be changes
       @param _amount new amount for the tier for discount
       @param _discountPercent new discount percent for tier
    */
    function _updateDiscount(
        uint _tierNo, 
        uint _amount, 
        uint8 _discountPercent
    ) internal {
        require(
            discountRates[_tierNo-1].amount != _amount ||
            discountRates[_tierNo-1].discountPercent != _discountPercent, 
            "Already same discount exists!"
        );
        discountRates[_tierNo-1].amount = _amount;
        discountRates[_tierNo-1].discountPercent = _discountPercent;
    }

    /**
     *
     * @notice checks the parameters whether valid for swap or not
       @return returns structure to be used for further calculation of swapping
       @param account address which calls the swap function 
       @param feePath array of addresses pf path for input token to ETH
       @param amountIn input amount for swapping
       @param isInputEth boolean value to check input token is ETH or not
       @param ethAsFee amount as gie app fees for swap
    */
    function _swapPreCheck(
        address account,
        address[] memory feePath,
        uint amountIn,
        bool isInputEth,
        uint ethAsFee
    ) internal view returns(
        SwapUtils memory
    ) {
        SwapUtils memory swapUtils = SwapUtils(0,0, new uint[](feePath.length));
        swapUtils.appFee = calculateFeesForTransaction(account, amountIn);
        if(isInputEth){
            swapUtils.appFeeInEther = swapUtils.appFee;
        }else{
            swapUtils.resultAmount = getAmountsOut(swapUtils.appFee, feePath);
            swapUtils.appFeeInEther = swapUtils.resultAmount[swapUtils.resultAmount.length - 1];
        }
        require(ethAsFee >= swapUtils.appFeeInEther, "Insufficient transaction fees!");  
        return swapUtils;
    }

    /**
     *
     * @notice checks discount rate values before changing discount rate
       @param _tierNo tier no. whose rate is to be changes
       @param _amount new amount for the tier for discount
       @param _discountPercent new discount percent for tier
       @param _index number to check where tier lies in between or at edges
    */
    function _preUpdateDiscountCheck(
        uint _tierNo, 
        uint _amount, 
        uint8 _discountPercent,
        uint8 _index
    ) internal view {
        string memory errorMessage = "amount & discount must be lesser than next tier & greater than previous tier!";
        if(_index == 2){
            require(
                discountRates[_tierNo - _index].amount <  _amount && 
                discountRates[_tierNo - _index].discountPercent < _discountPercent, 
                errorMessage
            );
        } else{
            require(
                discountRates[_tierNo].amount > _amount && 
                discountRates[_tierNo].discountPercent > _discountPercent, 
                errorMessage
            );
        }
    }

    /**
     *
     * @notice calculates amount of tokenB to get in return when some amount of tokenA is provided 
       @return amountB output token amount
       @param amountA input token amount
       @param reserveA reserve of pool for input token A
       @param reserveB reserve of pool for output token B
    */
    function quote(
        uint amountA, 
        uint reserveA, 
        uint reserveB
    ) public pure virtual override returns (
        uint amountB
    ) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    /**
     *
     * @notice calculates amount of tokenA to get in return when some amount of tokenB is provided
       @return amountOut output token amount
       @param amountIn input token amount
       @param reserveIn reserve of pool for input token 
       @param reserveOut reserve of pool for output token
    */
    function getAmountOut(
        uint amountIn, 
        uint reserveIn, 
        uint reserveOut
    ) public pure virtual override returns (
        uint amountOut
    ) {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    /**
     *
     * @notice calculates amount of tokenA to give when some amount of tokenB is expected in return
       @return amountIn input token amount
       @param amountOut output token amount
       @param reserveIn reserve of pool for input token 
       @param reserveOut reserve of pool for output token
    */
    function getAmountIn(
        uint amountOut, 
        uint reserveIn, 
        uint reserveOut
    ) public pure virtual override returns (
        uint amountIn
    ) {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function allTiers() public pure returns(
        uint8[4] memory
    ) {
        return [1,2,3,4];
    }

    /**
     *
     * @notice calculates amount of tokenA to get in return when some amount of tokenB is provided 
       @return amounts array of input and output tokens amount
       @param amountIn input token amount
       @param path array of addresses with input and output tokens
    */
    function getAmountsOut(
        uint amountIn, 
        address[] memory path
    ) public view virtual override returns (
        uint[] memory amounts
    ) {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    /**
     *
     * @notice calculates amount of tokenA to give when some amount of tokenB is expected in return
       @return amounts array of input and output tokens amount
       @param amountOut output token amount
       @param path array of addresses with input and output tokens
    */
    function getAmountsIn(
        uint amountOut, 
        address[] memory path
    ) public view virtual override returns (
        uint[] memory amounts
    ) {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }

    /**
     *
     * @notice provides reserves of two tokens pair
       @return reserveA reserve of first token
       @return reserveB reserve of second token
       @param tokenA address of first token 
       @param tokenB address of second token 
    */
    function getReserves(
        address tokenA, 
        address tokenB
    ) public view returns (
        uint reserveA, 
        uint reserveB
    ) {
        return UniswapV2Library.getReserves(factory, tokenA, tokenB);
    }

    /**
     *
     * @notice calculates gie app for some amount of input tokens provided by 
       the user to swap
       @return gieAppFee gie app fee to be charged from for swapping
       @param account address that called to swap function of tokens
       @param amount input amount to swap 
    */
    function calculateFeesForTransaction(
        address account,
        uint amount
    ) public view returns(
        uint gieAppFee
    ){
        require(amount != 0, "Invalid amount!");
        uint discountPercent = calculateDiscountPercent(account);
        gieAppFee = (amount * gieAppFees * (100 - discountPercent)) / (gieAppFeesDecimals * 100 * 100);
    }

    /**
     *
     * @notice calculates discount percentage on transaction fees
       @return discountPercent returns discount percentage for GIE token holder
       @param account address for which discount percentage if to find
    */
    function calculateDiscountPercent(
        address account
    ) public view returns (
        uint256 discountPercent
    ){
        uint userBalance = IERC20(gieTokenContract).balanceOf(account);
        for(int i = int(discountRates.length-1); i >= 0; i--){
            if(userBalance > discountRates[uint(i)].amount){
                discountPercent = discountRates[uint(i)].discountPercent;
                break;
            }
        }
        return discountPercent;
    }
}