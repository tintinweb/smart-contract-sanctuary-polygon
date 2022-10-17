/**
 *Submitted for verification at polygonscan.com on 2022-10-16
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @uniswap/v3-periphery/contracts/interfaces/IQuoter.sol


pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// File: @uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol


pragma solidity >=0.5.0;

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

// File: @uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol


pragma solidity >=0.7.5;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: @uniswap/v3-periphery/contracts/libraries/TransferHelper.sol


pragma solidity >=0.6.0;


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

// File: contracts/payblob.sol


pragma solidity ^0.8.13;





contract ERC20{
    constructor(){}
    function transferFrom(address from,address to,uint256 amount) public{}
    function transfer(address to,uint256 amount) public{}
    function approve(address spender, uint256 amount) public returns (bool) {}
    function balanceOf(address wallet) public returns(uint){}
}

contract ERC1155 {
    constructor(){}

    function balanceOf(address wallet) view public returns(uint){}
}

contract StakingClass {
    constructor(){}

    function isStaking(address wallet) view public returns(bool){}
}

contract PayBlobTunnel {

    /* Our Transaction structure
     * encryptedData is dataze related to the transaction sent by the user
     * like real name, delivery address ...
     * This data is encrypted with the shop's public key so only him can reveal it
     */
    struct Transaction {
        address sender;
        address token;
        uint value;
        string encryptedData;
        uint256 timestamp;
    }   

    //Keep track of the transactions per shop address
    mapping(address => mapping(uint => Transaction)) public transactionsHistory;
    mapping(address => uint) public transactionsCount;
    mapping(address => mapping(address => uint)) public collectedAmount;
    mapping(address => bool) public bannedAddress;

    // Data related to rewards for buyers & sellers
    bool public rewardsEnabled = true;
    bool public stakingEnabled = false;
    bool public nftEnabled = false;
    address public NFTContract;
    address public StakingContract;
    address public rewardsTokenAddress = 0x8A3a1CE8D9370F57C1e5f10371A707d0366708d4;
    uint public FeesForNormies = 20;
    uint public FeesForStaker = 15;
    uint public FeesForHolders = 10;

    //Uniswap
    ISwapRouter public swapRouter;
    address private constant SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564; //CHANGE
    address public wethToken = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
    //Events
    event TransactionDone(address indexed shop, address indexed sender,address indexed token,uint value,string data,uint256 timestamp);
    event TransactionHash(string indexed hash, address shop, address sender, address token, uint value);

    //Managers list
    mapping(address => bool) Managers;

    //Founders addresses;
    address payable public feesAddress1;
    address payable public feesAddress2;
    address payable public feesAddress3;

    //ContractInstances
    ERC1155 NFTInstance;
    StakingClass StakingInstance;

    constructor(){
        Managers[msg.sender] = true;
        feesAddress1 = payable(0x0Ca2d160bF83079456BA175435f06354cdb6beBe);
        feesAddress2 = payable(0x63cB2A1934c72B19760723006ce27960b953f453);
        feesAddress3 = payable(0x5cF62461b8F8baf538df8E0257cc22EafCe34Fca);
        Managers[feesAddress1] = true;
        Managers[feesAddress2] = true;
        Managers[feesAddress3] = true;
        swapRouter = ISwapRouter(SWAP_ROUTER);
    }

    /*
     * Utils Functions
     */
    function getHistory(address shop, uint256 startPage, uint256 amountTx) view public returns(Transaction[] memory){
        require(amountTx > 0, "not enough transactions");
        require(amountTx <= 20, "to much transactions");
        require(startPage > 0, "first page is 1");
        Transaction[] memory txhs = new Transaction[](amountTx+1);
        uint256 counter = 0;
        uint256 end = (startPage+amountTx) > transactionsCount[shop] ? transactionsCount[shop] : (startPage+amountTx);
        for(uint256 i = startPage; i <= end; i+=1) {
            Transaction memory txh_ = transactionsHistory[shop][i];
            txhs[counter] = txh_;
            counter += 1;
        }
        return txhs;
    }

    function getLastHistory(address shop) view public returns(Transaction memory){
        return transactionsHistory[shop][transactionsCount[shop]];
    }

    function isStaking(address wallet) view public returns(bool){
        if(!stakingEnabled) return(false);
        return (StakingInstance.isStaking(wallet));
    }

    function isHodler(address wallet) view public returns(bool){
        if(!nftEnabled) return(false);
        return (NFTInstance.balanceOf(wallet) > 0);
    }

    function feesFor(address wallet, address shop) public view returns(uint){
        if(isHodler(shop)) return FeesForHolders;
        return (isHodler(wallet) ? FeesForHolders : (isStaking(wallet) ? FeesForStaker : FeesForNormies));
    }


    /*
     * Management Functions
     */
    modifier onlyManager {
      require(Managers[msg.sender] == true,"You're not a manager");
      _;
    }

    function setNFTContract(address contractA) public onlyManager{
        NFTContract = contractA;
        NFTInstance = ERC1155(contractA);
    }

    function setStakingContract(address contractA) public onlyManager{
        StakingContract = contractA;
        StakingInstance = StakingClass(contractA);
    }

    function setManager(address manager, bool state) public onlyManager{
        Managers[manager] = state;
    }

    function setFees(uint value1,uint value2,uint value3) public onlyManager{
        FeesForNormies = value1;
        FeesForStaker = value2;
        FeesForHolders = value3;
    }

    function setRewards(address tokenAddress,address contractAddress, bool state) public onlyManager{
        rewardsEnabled = state;
        rewardsTokenAddress = tokenAddress;
        swapRouter = ISwapRouter(contractAddress);
    }

    function setNft(address contractAddress, bool state) public onlyManager{
        rewardsEnabled = state;
        NFTContract = contractAddress;
    }

    function setStakingState(bool state) public onlyManager{
        stakingEnabled = state;
    }

    function setBan(address wallet, bool state) public onlyManager{
        bannedAddress[wallet] = state;
    }

    function setFounderAddress1(address wallet) public{
        require(msg.sender == feesAddress1);
        feesAddress1 = payable(wallet);
    }
    
    function setFounderAddress2(address wallet) public{
        require(payable(msg.sender) == feesAddress2);
        feesAddress2 = payable(wallet);
    }
    
    function setFounderAddress3(address wallet) public{
        require(payable(msg.sender) == feesAddress3);
        feesAddress3 = payable(wallet);
    }

    /*
     * Internal Functions
     */

    function HandleData(address sender,address payable shop,string memory data,string memory txnUuid,uint value,address tokenAdd) internal{
        Transaction memory transaction = Transaction(sender,tokenAdd,value,data,block.timestamp);
        transactionsCount[shop] += 1;
        transactionsHistory[shop][transactionsCount[shop]] = transaction;
        collectedAmount[shop][tokenAdd] += value;
        emit TransactionHash(txnUuid,shop,sender,tokenAdd,value);
        emit TransactionDone(shop,sender,tokenAdd,value,data,block.timestamp);
    }

    function executeSwapETH(address tokenOut,address recipient,uint amountIn) internal{
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: wethToken,//CHANGE
            tokenOut: tokenOut,
            fee: 10000,
            recipient: recipient,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 1,
            sqrtPriceLimitX96: 0
        });
        swapRouter.exactInputSingle{value: amountIn}(params);
    }

    function executeSwapToken(address tokenIn,uint amountIn) internal returns(uint){
        ISwapRouter.ExactInputSingleParams memory paramsB = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: wethToken,//CHANGE
            fee: 10000,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 1,
            sqrtPriceLimitX96: 0
        });
        return swapRouter.exactInputSingle(paramsB);
    }
    
    /*
     * Shop Functions
     */
    function clearShopTransactions() public{
        require(transactionsCount[msg.sender] > 0,"You don't have any transaction");
        transactionsCount[msg.sender] = 0;
    }

    function Pay(address payable shop,string memory data,string memory txnUuid) public payable{
        require(bytes(txnUuid).length > 0 && bytes(txnUuid).length < 40,"Wrong txnUuid length");
        require(!bannedAddress[shop],"This shop is banned");
        require(!bannedAddress[msg.sender],"You are banned from this service ");
        require(msg.value > 0, "You have to send something ser");
        ERC20 blob = ERC20(rewardsTokenAddress);
        if(blob.balanceOf(address(this)) > 1000000){
            blob.transfer(msg.sender,1000000);
        }
        uint valueToFees = feesFor(msg.sender, shop)*msg.value/1000;
        uint valueToRewards = (rewardsEnabled ? valueToFees/4 : 0);
        uint valueToSend = (msg.value - valueToFees);
        uint valueToFounders = (valueToFees-valueToRewards);
        shop.transfer(valueToSend);
        uint divided = valueToFounders/3;
        feesAddress1.transfer(divided);
        feesAddress2.transfer(divided);
        feesAddress3.transfer(valueToFounders-divided*2);    
        if(valueToRewards > 0){
            executeSwapETH(rewardsTokenAddress,msg.sender,valueToRewards/2);
            executeSwapETH(rewardsTokenAddress,shop,valueToRewards/2);    
        }

        HandleData(msg.sender,shop, data, txnUuid,valueToSend,0x0000000000000000000000000000000000000000);
    }

    function PayWithToken(address shop,string memory data,address tokenAddress,uint value,string memory txnUuid) public{
        require(bytes(txnUuid).length > 0 && bytes(txnUuid).length < 40,"Wrong txnUuid length");
        require(!bannedAddress[shop],"This shop is banned");
        require(!bannedAddress[msg.sender],"You are banned from this service ");
        require(value > 0, "You have to send something ser");

        uint valueToFees = feesFor(msg.sender, shop)*value/1000;
        uint valueToRewards = rewardsEnabled ? valueToFees/4 : 0;
        uint valueToSend = value - valueToFees;
        uint valueToFounders = valueToFees-valueToRewards;
        ERC20 blob = ERC20(rewardsTokenAddress);
        if(blob.balanceOf(address(this)) > 1000000){
            blob.transfer(msg.sender,1000000);
        }
        ERC20 Token = ERC20(tokenAddress);
        Token.transferFrom(msg.sender,address(this),value);
        
        Token.transfer(shop, valueToSend);
        uint divided = valueToFounders/3;

        Token.transfer(feesAddress1, divided);
        Token.transfer(feesAddress2, divided);
        Token.transfer(feesAddress3, valueToFounders-2*divided);

        if(valueToRewards > 0){
            Token.approve(SWAP_ROUTER,valueToRewards);
            uint rewardsFinalAmount = executeSwapToken(tokenAddress, valueToRewards);

            ERC20 WETH = ERC20(0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889);
            WETH.approve(SWAP_ROUTER,rewardsFinalAmount);

            executeSwapETH(rewardsTokenAddress,msg.sender,rewardsFinalAmount/2);
            executeSwapETH(rewardsTokenAddress,shop,rewardsFinalAmount/2);
        }

        HandleData(msg.sender,payable(shop), data, txnUuid,valueToSend,tokenAddress);
    }
}