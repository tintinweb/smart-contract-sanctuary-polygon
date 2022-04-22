// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

pragma solidity ^0.8.0;

import "../libraries/Orders.sol";
import "../libraries/EIP712.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Settlement{
    using Orders for Orders.Order;

    uint constant SPREAD_FEE = 2 ether;
    uint constant ONE_HUNDRED_PERCENT = 100 ether;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 public immutable DOMAIN_SEPARATOR;

    // Hash of an order => if canceled
    mapping(address => mapping(bytes32 => bool)) public canceledOfHash;
    // Hash of an order => filledAmountIn
    mapping(bytes32 => uint256) public filledAmountInOfHash;

    event OrderFilled(bytes32 indexed hash, uint256 amountIn, uint256 amountOut);
    event OrderCanceled(bytes32 indexed hash);
    event FeeTransferred(bytes32 indexed hash, address indexed recipient, uint256 amount);
    event FeeSplitTransferred(bytes32 indexed hash, address indexed recipient, uint256 amount);

    constructor(
        uint256 orderBookChainId,
        address orderBookAddress
    ) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("OrderBook"),
                keccak256("1"),
                orderBookChainId,
                orderBookAddress
            )
        );

    }
    
    function getFilledInAmount(Orders.Order memory order) external view returns(uint){
        return filledAmountInOfHash[order.hash()];
    }

    function batchFill(Orders.Order[] memory argsArray) external{
        // voids flashloan attack vectors
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender == tx.origin, "called-by-contract");
        require(argsArray.length % 2 == 0, "args must be in pairs");
        
        // for each order pair 
        for(uint i = 0; i < argsArray.length; i+=2){
            _fillInOrder(argsArray[i], argsArray[i+1]);
        }
    }

    // Fills an order
    function _fillInOrder(Orders.Order memory order1, Orders.Order memory order2) internal {        
        require(order1.fromToken == order2.toToken, "The pair of orders must satisfy eachtother");

        uint firstIn = order1.remainingIn(filledAmountInOfHash[order1.hash()]);
        uint secondIn = order2.remainingIn(filledAmountInOfHash[order2.hash()]);
        uint firstOut = order1.remainingOut(filledAmountInOfHash[order1.hash()]);
        uint secondOut = order2.remainingOut(filledAmountInOfHash[order2.hash()]);
        // Either 
        // 1s In must be greater than 2s Out and 2s In is less than 1s out
        // Or
        // 2s In is greater than 1s out and 1s in is less than 2s out
        // also depending on which one of these is true, we define if the big order is 1 or 2
        bool isBigOrder1;
        if(            
            (
                firstIn >= secondOut 
                && 
                secondIn <= firstOut
            ) 
        ){
            isBigOrder1 = true;
        }else if(
            (
                secondIn >= firstOut 
                && 
                firstIn <= secondOut
            )
        ){
            isBigOrder1 = false;
        }else{
            revert("These orders have an incompatible spread");
        }
        
        isBigOrder1 ? _settle(order1, order2): _settle(order2, order1);
        
    }

    /**
    * @dev settlement algo looks like this
    *
    *          Big
    *        /     / a
    *   I'_s/  [Spread Fee]      O'_s + Spread Fee = a
    *      /    / O'_s
    *      small
    *
    * with the direction of these lines going clockwise
    *
    * Note 
    * _s = for small order
    * _b for big order
    * I = In
    * O = Out
    * I' = remaining In
    * a = (I'_s * I_b / O_b)
     */
    function _settle(Orders.Order memory big, Orders.Order memory small) internal{
        
        uint I_ = small.remainingIn(filledAmountInOfHash[small.hash()]);
        uint O_s = small.remainingOut(filledAmountInOfHash[small.hash()]);
        uint a = (I_ * big.amountIn) / big.amountOutMin;

        _verifyOrders(big, small, a);

        require(a > O_s, "The price offered by the larger order must be lower");

        // give all of smalls in remaining to big
        IERC20(small.fromToken).transferFrom(small.maker, big.maker, I_);

        // send small all of it's request for out remaining
        IERC20(small.toToken).transferFrom(big.maker, small.maker, O_s);

        // the difference between bigs value of smalls in and the amount small actually took is the spread
        uint senkenSpreadFee = ((a - O_s) * SPREAD_FEE) / ONE_HUNDRED_PERCENT;
        // send caller the majority of spread fee (again the difference between bigs value of smalls in and what small actually took)
        IERC20(small.fromToken).transferFrom(big.maker, msg.sender, a - O_s - senkenSpreadFee);
        // and the rest of that spread fee goes to senken (this)
        IERC20(small.fromToken).transferFrom(big.maker, address(this), senkenSpreadFee);
    }
    function _verifyOrders(Orders.Order memory big, Orders.Order memory small, uint amountSmallOrderFromTokenToBig) internal{
        // Check if the order is canceled / already fully filled
        bytes32 hashBig = big.hash();
        bytes32 hashSmall = small.hash();

        // validate status is done with tempArgs after amount filled in is already updated
        _validateStatus(big, hashBig, amountSmallOrderFromTokenToBig);
        _validateStatus(small, hashSmall, small.remainingIn(filledAmountInOfHash[small.hash()]));

        filledAmountInOfHash[hashBig] = filledAmountInOfHash[hashBig] + (amountSmallOrderFromTokenToBig);
        filledAmountInOfHash[hashSmall] = filledAmountInOfHash[hashSmall] + small.remainingIn(filledAmountInOfHash[small.hash()]);       // samll gets all filled in


        require(_isSigValid(hashBig, big), "Invalid Signature For Big Order");
        require(_isSigValid(hashSmall, small), "Invalid Signature For Small Order");
    }

    function _isSigValid(bytes32 _hash, Orders.Order memory _order) internal returns(bool){
        // Check if the signature is valid
        address signer = EIP712.recover(DOMAIN_SEPARATOR, _hash, _order.v, _order.r, _order.s);
        return(signer != address(0) && signer == _order.maker);

    }

    // Checks if an order is canceled / already fully filled
    function _validateStatus(Orders.Order memory _order, bytes32 hash, uint _amountToFillIn) internal view {
        require(_order.deadline >= block.timestamp, "order-expired");
        require(!canceledOfHash[_order.maker][hash], "order-canceled");
        require(filledAmountInOfHash[hash] + (_amountToFillIn) <= _order.amountIn, "already-filled");
    }

    // Swaps an exact amount of tokens for another token through the path passed as an argument
    // Returns the amount of the final token
    function _swapExactTokensForTokens(
        address from,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to
    ) internal returns (uint256 amountOut) {
        // uint256[] memory amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        // amountOut = amounts[amounts.length - 1];
        // require(amountOut >= amountOutMin, "insufficient-amount-out");
        // TransferHelper.safeTransferFrom(path[0], from, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn);
        // _swap(amounts, path, to);
    }

    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        // for (uint256 i; i < path.length - 1; i++) {
        //     (address input, address output) = (path[i], path[i + 1]);
        //     (address token0, ) = UniswapV2Library.sortTokens(input, output);
        //     uint256 amountOut = amounts[i + 1];
        //     (uint256 amount0Out, uint256 amount1Out) = input == token0
        //         ? (uint256(0), amountOut)
        //         : (amountOut, uint256(0));
        //     address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
        //     IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
        //         amount0Out,
        //         amount1Out,
        //         to,
        //         new bytes(0)
        //     );
        // }
    }

    // Cancels an order, has to been called by order maker
    function cancelOrder(bytes32 hash) public {
        canceledOfHash[msg.sender][hash] = true;

        emit OrderCanceled(hash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library EIP712 {
    function recover(
        // solhint-disable-next-line var-name-mixedcase
        bytes32 DOMAIN_SEPARATOR,
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash));
        return ecrecover(digest, v, r, s);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Orders {
    // keccak256("Order(address maker,address fromToken,address toToken,uint256 amountIn,uint256 amountOutMin,address recipient,uint256 deadline)")
    bytes32 public constant ORDER_TYPEHASH = 0x7c228c78bd055996a44b5046fb56fa7c28c66bce92d9dc584f742b2cd76a140f;

    struct Order {
        address maker;
        address fromToken;
        address toToken;
        uint256 amountIn;
        uint256 amountOutMin;
        address recipient;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function hash(Order memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    order.maker,
                    order.fromToken,
                    order.toToken,
                    order.amountIn,
                    order.amountOutMin,
                    order.recipient,
                    order.deadline
                )
            );
    }

    function remainingIn(Order memory order, uint _filledIn) internal pure returns(uint){
        return order.amountIn - _filledIn;
    }

    function remainingOut(Order memory order, uint _filledIn) internal pure returns(uint){
        return (remainingIn(order, _filledIn) * order.amountOutMin) / order.amountIn;
    }


    function validate(Order memory order) internal {
        require(order.maker != address(0), "invalid-maker");
        require(order.fromToken != address(0), "invalid-from-token");
        require(order.toToken != address(0), "invalid-to-token");
        require(order.fromToken != order.toToken, "duplicate-tokens");
        require(order.amountIn > 0, "invalid-amount-in");
        require(order.amountOutMin > 0, "invalid-amount-out-min");
        require(order.recipient != address(0), "invalid-recipient");
        require(order.deadline > 0, "invalid-deadline");
    }
}