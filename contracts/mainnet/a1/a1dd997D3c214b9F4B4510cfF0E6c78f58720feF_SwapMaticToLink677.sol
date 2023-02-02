/**
 *Submitted for verification at polygonscan.com on 2023-02-02
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;
pragma abicoder v2;


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
}

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

    
interface IWMatic is IERC20 {
    function deposit() external payable;
}

interface AggregatorV3Interface {
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract UniV3WmaticLinkSwap {


    //AggregatorV3Interface to retrieve Link/Matic price feed
    AggregatorV3Interface public priceFeed;
    //ISwapRouter interface
    ISwapRouter public swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    address constant ERC677_link = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    address constant bridged_Link = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;
    address  constant wmatic = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    //Declares pool fee equal to 0.3%.
    uint24 public constant poolFee = 3000;
    
    
    /**
     * Chainlink Price Feed Aggregator V3 
     * 
     * Network: Polygon Mainnet
     * Aggregator: Link/Matic
     * Address: 0x5787BefDc0ECd210Dfa948264631CD53E68F7802
     */
    /// @notice Constructor is executed upon deployment
    /// @dev Initializes pricefeed value through constructor 
    constructor(){
            priceFeed = AggregatorV3Interface(
            0x5787BefDc0ECd210Dfa948264631CD53E68F7802
        );
    }

    /// @notice Uses IWmatic interface to deposit matic for wrapped matic, finally swaps wrapped matic for bridged_Link
    /// @dev this function is called by MaticLinkSwap contract to wrap matic and launch a Uni v3 single swap
    /// @return amountOut the amount of token sent back after wrapping to wmatic and then swapping for bridged_Link
    function wrapAndSwap() external payable returns (uint256){
        require(msg.sender==address(this), "Function disabled");
        IWMatic(wmatic).deposit{value: msg.value}();
        IWMatic(wmatic).transfer(msg.sender, msg.value);
        uint256 amountOut = swapExactInputSingle(msg.value);
        return amountOut;
    }
    
    /// @notice swapExactInputSingle swaps a fixed amount of wmatic for a maximum possible amount of bridged_Link
    /// using the wmatic/bridged_Link 0.3% pool by calling `exactInputSingle` in the swap router.
    /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its wmatic for this function to succeed.
    /// @param amountIn The exact amount of wmatic that will be swapped for bridged_Link.
    /// @return amountOut The amount of bridged_Link received.
    function swapExactInputSingle(uint256 amountIn) internal returns (uint256 amountOut) {
        // msg.sender must approve this contract

        // Transfer the specified amount of wmatic to this contract.
        TransferHelper.safeTransferFrom(wmatic, msg.sender, address(this), amountIn);

        // Approve the router to spend wmatic.
        TransferHelper.safeApprove(wmatic, address(swapRouter), amountIn);
       
       
        //calculate the amount of matic that make 1 link
        uint256 amount = ((checkLinkPerMatic()) * amountIn) / 1e18;
      
        //create a variable and calculate the amount to input in amountOutMinimum
        uint256 minOut =  (amount - (((amount)*5)/100));
        //set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: wmatic,
                tokenOut: bridged_Link,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                //minOut will be a number up to 5% less at worst
                amountOutMinimum: minOut,
                sqrtPriceLimitX96: 0
            });

        //The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
    }


    
    ///@notice getLatestPrice for a given pair
    ///@dev reads from AggregatorV3Interface and returns latestRoundData
    ///@return price returns latestRoundData price as int 
    function getLatestPrice() public view returns (int) {
        (
            ,
            int price,
            ,
            ,
        ) = priceFeed.latestRoundData();
            return price;
    }
    ///@notice Calculates the amount of Link per matic
    ///@dev Calculates the amount of link per matic through getLatestPrice()
    ///@return price in link of one matic price as uint256
    function checkLinkPerMatic() public view returns (uint256){
        return ((1e18 * 1e18 /(uint256(getLatestPrice()))) );
    }
    
}
   
    


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}


    /// @title interface for chainlink PegSwap
    /// @notice needed to interact with PegSwap contract 
    /// @dev Interface for PegSwap contract at 0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b 
interface IPegSwap{
    function swap(uint256 amount, address source, address target) external;
}
    /// @title Matic to Link ERC677 compatible in one function
    /// @author SolidtyDrone - See deployer address;
    /// @notice this contract contains and external function to swap matic to erc677 Link
    /// @dev simply create an interface for swap() external payable returns(uint256) and call from a contract
contract SwapMaticToLink677 is UniV3WmaticLinkSwap, ReentrancyGuard{

    
    event SwapCompleted(address indexed caller, uint256 indexed maticAmount, uint256 linkAmount);
    
    IPegSwap public immutable pegswap;
    UniV3WmaticLinkSwap public immutable MaticLinkSwap;
    //@notice address for polygon mainnet Chainlink PegSwap 
    //              https://polygonscan.com/address/0xaa1dc356dc4b18f30c347798fd5379f3d77abc5b#code
    address constant ChainlinkPegSwap =             0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b;
    //              https://polygonscan.com/address/0xb0897686c545045aFc77CF20eC7A532E3120E0F1#code
    address public constant ERC677_Link =           0xb0897686c545045aFc77CF20eC7A532E3120E0F1;

    /// @notice constructor is called upon deployment
    /// @dev intializes immutable variables
    constructor(){
        MaticLinkSwap = UniV3WmaticLinkSwap(address(this));
        pegswap = IPegSwap(ChainlinkPegSwap);
    }

    /// @notice Swaps matic for erc677 Link in one function
    /// @dev call this function with a msg.value greater than 0 to swap matic for 677Link
    /// @param (msg.value) requires to be greater than 0 and less than 1e23 (100000Eth)
    /// @return swapAmountOut of token returned from operations
    function swap() external payable nonReentrant returns (uint256){
        require(msg.value >= 1e18, "Msg.value has to be higher than 1 eth (matic)");
        require(msg.value < 1e23, "Msg.value has to be less than 100000 eth (matic)");
        //This address MUST be approved to call swapExactInputSingle() called in wrapAndSwap()
        IERC20(wmatic).approve(address(this), msg.value);
        //calls wrapAndSwap from MaticLinkSwap which returns uint256
        uint256 swapAmountOut =  MaticLinkSwap.wrapAndSwap{value: msg.value}();
        //returned swapAmountOut value must be greater than 0 to save worthless transactions
        require(swapAmountOut > 0, "Swap returns 0");
        //This address MUST be approved to call swap() on PegSwap chainlink contract
        IERC20(bridged_Link).approve(ChainlinkPegSwap, swapAmountOut);
        //call swap() and swaps swapAmountOut from bridged_Link to ERC677_Link on PegSwap contract 
        pegswap.swap(swapAmountOut, bridged_Link, ERC677_Link);
        //finally transfer ERC677Link tokens to msg.sender( the consumer ) of this function
        IERC20(ERC677_Link).transfer(msg.sender, IERC20(ERC677_Link).balanceOf(address(this)));

        //emits event SwapCompleted
        emit SwapCompleted(msg.sender, msg.value, swapAmountOut);
        return swapAmountOut;
    }
    
 
}