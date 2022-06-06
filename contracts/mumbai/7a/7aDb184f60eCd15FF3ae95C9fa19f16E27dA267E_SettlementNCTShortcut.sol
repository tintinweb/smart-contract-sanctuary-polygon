// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity =0.8.14;

import "../libraries/Orders.sol";
import "../libraries/EIP712.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";


abstract contract Settlement is Ownable{
    using SafeERC20 for IERC20;
    using Orders for Orders.Order;

    uint constant SPREAD_FEE = 200;             // 2%
    uint constant ONE_HUNDRED_PERCENT = 10000;  // Min percent of 0.01%

    // solhint-disable-next-line var-name-mixedcase
    bytes32 public immutable DOMAIN_SEPARATOR;

    // Hash of an order => if canceled
    mapping(address => mapping(bytes32 => bool)) public canceledOfHash;
    // Hash of an order => filledAmountIn
    mapping(bytes32 => uint256) public filledAmountInOfHash;

    event OrderFilled(bytes32 indexed hash, uint256 amountIn, uint256 amountOut);
    event OrderCanceled(bytes32 indexed hash);
    event FeeTransferred(bytes32 indexed hash, address indexed recipient, uint256 amount);
    event NewFill(Orders.Order order, uint amountToFillIn);

    constructor(
        uint256 orderBookChainId,
        address orderBookAddress
    ) Ownable() {
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

    function batchFill(Orders.Order[] memory argsArray) external virtual{
        // voids flashloan attack vectors
        // solhint-disable-next-line avoid-tx-origin
        require(msg.sender == tx.origin, "called-by-contract");
        uint len = argsArray.length;
        require(len % 2 == 0, "args must be in pairs");
        
        // for each order pair 
        for(uint i; i < len; i+=2){
            _fillInOrder(argsArray[i], argsArray[i+1]);
        }
    }

    // Fills an order
    function _fillInOrder(Orders.Order memory order1, Orders.Order memory order2) internal virtual {        
        require(order1.fromToken == order2.toToken, "The pair of orders must satisfy eachother");
        require(order1.toToken == order2.fromToken, "The pair of orders must satisfy eachother");
        bytes32 o1h = order1.hash();
        bytes32 o2h = order2.hash();

        uint firstIn = order1.remainingIn(filledAmountInOfHash[o1h]);
        uint secondIn = order2.remainingIn(filledAmountInOfHash[o2h]);
        uint firstOut = order1.remainingOut(filledAmountInOfHash[o1h]);
        uint secondOut = order2.remainingOut(filledAmountInOfHash[o2h]);
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
            // isBigOrder1 = false;     Wastes gas but this is what's happening
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
    function _settle(Orders.Order memory big, Orders.Order memory small) internal virtual{
        
        uint I_ = small.remainingIn(filledAmountInOfHash[small.hash()]);
        uint O_s = small.remainingOut(filledAmountInOfHash[small.hash()]);
        uint a = (I_ * big.amountIn) / big.amountOutMin;

        _verifyOrders(big, small, a);

        require(a > O_s, "The price offered by the larger order must be lower");

        // give all of smalls in remaining to big
        IERC20(small.fromToken).safeTransferFrom(small.maker, big.maker, I_);

        // send small all of it's request for out remaining
        IERC20(small.toToken).safeTransferFrom(big.maker, small.maker, O_s);

        // the difference between bigs value of smalls in and the amount small actually took is the spread
        uint senkenSpreadFee = ((a - O_s) * SPREAD_FEE) / ONE_HUNDRED_PERCENT;
        // send caller the majority of spread fee (again the difference between bigs value of smalls in and what small actually took)
        IERC20(small.fromToken).safeTransferFrom(big.maker, msg.sender, a - O_s - senkenSpreadFee);
        // and the rest of that spread fee goes to senken (owner)
        IERC20(small.fromToken).safeTransferFrom(big.maker, owner(), senkenSpreadFee);
    }
    function _verifyOrders(Orders.Order memory big, Orders.Order memory small, uint amountSmallOrderFromTokenToBig) internal{
        // Check if the order is canceled / already fully filled
        bytes32 hashBig = big.hash();
        bytes32 hashSmall = small.hash();

        uint smallRemainingIn = small.remainingIn(filledAmountInOfHash[hashSmall]);

        // validate status is done with tempArgs after amount filled in is already updated
        _validateStatus(big, hashBig, amountSmallOrderFromTokenToBig);
        _validateStatus(small, hashSmall, smallRemainingIn);

        filledAmountInOfHash[hashBig] += (amountSmallOrderFromTokenToBig);
        filledAmountInOfHash[hashSmall] += smallRemainingIn;       // samll gets all filled in


        require(_isSigValid(hashBig, big), "Invalid Signature For Big Order");
        require(_isSigValid(hashSmall, small), "Invalid Signature For Small Order");
    }

    function _isSigValid(bytes32 _hash, Orders.Order memory _order) internal returns(bool){
        // Check if the signature is valid
        address signer = EIP712.recover(DOMAIN_SEPARATOR, _hash, _order.v, _order.r, _order.s);
        return(signer != address(0) && signer == _order.maker);
    }

    // Checks if an order is canceled / already fully filled
    function _validateStatus(Orders.Order memory _order, bytes32 hash, uint _amountToFillIn) internal {
        require(_order.deadline >= block.timestamp, "order-expired");
        require(!canceledOfHash[_order.maker][hash], "order-canceled");
        require(filledAmountInOfHash[hash] + (_amountToFillIn) <= _order.amountIn, "already-filled");
        emit NewFill(_order, _amountToFillIn);
    }

    // Cancels an order, has to been called by order maker
    function cancelOrder(bytes32 hash) external {
        canceledOfHash[msg.sender][hash] = true;

        emit OrderCanceled(hash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.14;

import "./Settlement.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INCT is IERC20{
    function calculateRedeemFees(
        address[] memory tco2s,
        uint256[] memory amounts
    ) external view returns (uint256);

    function redeemMany(address[] memory tco2s, uint256[] memory amounts) external;
}

interface IToucanRegistry{
    function checkERC20(address _address)
        external
        view
        returns (bool);
}

contract SettlementNCTShortcut is Settlement{
    using SafeERC20 for IERC20;
    using Orders for Orders.Order;

    bool public TestDidShortcut;
    // sushi router 2
    IUniswapV2Router02 public immutable dex;
    address public immutable NCT;
    IToucanRegistry public immutable toucanRegistry;
    constructor(        
        uint256 orderBookChainId,
        address orderBookAddress,
        address _NCT,
        address _toucanRegistry,
        address _dex
    ) Settlement(orderBookChainId, orderBookAddress){
        dex = IUniswapV2Router02(_dex);
        NCT = _NCT;
        toucanRegistry = IToucanRegistry(_toucanRegistry);
    }

    event ShortcutError(bytes e);
    event ShortcutValid(Orders.Order _order);
    event ShortcutInvalid(Orders.Order _order);
    event ShortcutComplete(Orders.Order _order);

    /**
    * @dev override to make shortcut possible
    * NOTE only change is that orders no longer have to be in pairs
    *   and if you are submitting an odd it must be an array of 1 that is the shortcut order
     */
    function batchFill(Orders.Order[] memory argsArray) external override{
        // voids flashloan attack vectors
        // solhint-disable-next-line avoid-tx-origin

        Orders.Order memory firstOrder = argsArray[0];

        require(msg.sender == tx.origin, "called-by-contract");
        uint len = argsArray.length;

        if(len % 2 == 0){
            // for each order pair 
            for(uint i; i < len; i+=2){
                _fillInOrder(argsArray[i], argsArray[i+1]);
            }
        }else{
            require(len == 1, "At the moment we only support odd shortcut array of size 1");
            if(_checkShortcutValid(firstOrder) && _buyNCT(firstOrder)){
                // verify order and finish filling it in
                _verifySingleOrder(firstOrder, firstOrder.remainingIn(filledAmountInOfHash[firstOrder.hash()]));
                // exchange the NCT tokens for TCO2s and send to user
                _exchangeNCTForTCO2(INCT(NCT), firstOrder);
                // emit complete event
                TestDidShortcut = true;
                emit ShortcutComplete(firstOrder);
            }
        }
    
    }

    /**
    * @dev function to check if a shortcut will be valid, only returns true if
        the amounts out for the trade can be exchanged for the TCO2 for the right
        amountOut even with fees
     */
    function _checkShortcutValid(Orders.Order memory _order) internal returns(bool){
        // check if token is in fact a TCO2
        try toucanRegistry.checkERC20(_order.toToken) returns(bool b){
            if (!b){return false;}
        }catch(bytes memory _err){
            emit ShortcutError(_err);
            return false;
        }

        uint amIn = _order.remainingIn(filledAmountInOfHash[_order.hash()]);
        uint amOut = _order.remainingOut(filledAmountInOfHash[_order.hash()]);

        address[] memory path = new address[](2);
        path[0] = _order.fromToken;
        path[1] = NCT;

        try dex.getAmountsOut(amIn, path) returns(uint[] memory amounts){
            address[] memory tco2s = new address[](1);
            uint256[] memory amountsIn = new uint256[](1);
            tco2s[0] = _order.toToken;
            amountsIn[0] = amounts[1];

            try INCT(NCT).calculateRedeemFees(tco2s, amountsIn) returns(uint256 out){
                if(out >= amOut){
                    emit ShortcutValid(_order);
                    return true;
                }else{
                    emit ShortcutInvalid(_order);
                    return false;
                }
            }catch(bytes memory _err){
                emit ShortcutError(_err);
                return false;
            }
        }catch(bytes memory _err) {
            emit ShortcutError(_err);
            return false;
        }
    }

    /**
    * @dev settle override that will first check if shortcut is possible, then try and preform the shortcut
    *    it does this for the large and small order, and if both fail, just does a normal settle
     */
    function _settle(Orders.Order memory big, Orders.Order memory small) internal override{
        // check if shortcut valid AND (so this isn't executed if not valid) buy NCT succeeds
        if(_checkShortcutValid(big) && _buyNCT(big)){
            // verify order and finish filling it in
            _verifySingleOrder(big, big.remainingIn(filledAmountInOfHash[big.hash()]));
            // exchange the NCT tokens for TCO2s and send to user
            _exchangeNCTForTCO2(INCT(NCT), big);
            // emit complete event
            TestDidShortcut = true;
            emit ShortcutComplete(big);

        // do the same thing with the small order
        }else if(_checkShortcutValid(small) && _buyNCT(small)){
            _verifySingleOrder(small, small.remainingIn(filledAmountInOfHash[small.hash()]));
            _exchangeNCTForTCO2(INCT(NCT), small);
            TestDidShortcut = true;
            emit ShortcutComplete(small);

        }else{
            // if neither are valid for shortcut do a normal settlement
            super._settle(big,small);
        }
    }

    /**
    * @dev helper function to exchange the contracts NCT tokens for TCO2s
     */
    function _exchangeNCTForTCO2(INCT nctContract, Orders.Order memory _order) internal{
            require(nctContract.balanceOf(address(this)) != 0, "trying to redeem with no NCT tokens");
            address[] memory tco2s = new address[](1);
            uint[] memory amounts = new uint[](1);
            tco2s[0] = _order.toToken;
            amounts[0] = nctContract.balanceOf(address(this));

            nctContract.redeemMany(tco2s, amounts);
            uint amount = IERC20(_order.toToken).balanceOf(address(this));

            // require enough tokens were received
            require(amount >= _order.amountOutMin, "Shortcut Error: Order failed to retreive TCO2s");

            // send the user the amount they asked for
            IERC20(_order.toToken).safeTransfer(_order.maker, _order.amountOutMin);

            // take the remainder as the fee
            if(amount > _order.amountOutMin){
                IERC20(_order.toToken).safeTransfer(owner(), amount - _order.amountOutMin);
            }
    }

    /**
    * @dev function to buy an Order with NCT
     */
    function _buyNCT(Orders.Order memory _order) internal returns(bool){
        uint amIn = _order.remainingIn(filledAmountInOfHash[_order.hash()]);
        uint amOut = _order.remainingOut(filledAmountInOfHash[_order.hash()]);

        IERC20(_order.fromToken).safeTransferFrom(_order.maker, address(this), amIn);
        // we approve each time since NCT does not interpret MAXUINT as infinite
        IERC20(_order.fromToken).approve(address(dex), amIn);

        address[] memory path = new address[](2);
        path[0] = _order.fromToken;
        path[1] = NCT;

        try dex.swapExactTokensForTokens(amIn, amOut, path, address(this), block.timestamp) returns(uint[] memory amounts){
            return _checkOutValid(_order, amounts[1]);
        }catch (bytes memory _err){
            emit ShortcutError(_err);
            return false;
        }
    }

    /**
    * @dev function to return true if amount out is valid. Very simple for now, but could be upgraded with a fee
     */
    function _checkOutValid(Orders.Order memory _order, uint _amountOut) internal pure returns(bool isValid){
        isValid = (_amountOut >= _order.amountOutMin);
    }

    /**
    * @dev even if shortcut is performed we need to still verify an order and fill it in, 
    *   this helper function does that for a single order instead of a pair 
     */
    function _verifySingleOrder(Orders.Order memory _order, uint _amountToFill) internal{
        // Check if the order is canceled / already fully filled
        bytes32 hashOrder = _order.hash();

        // validate status is done with tempArgs after amount filled in is already updated
        _validateStatus(_order, hashOrder, _amountToFill);

        filledAmountInOfHash[hashOrder] = filledAmountInOfHash[hashOrder] + _amountToFill;

        require(_isSigValid(hashOrder, _order), "Invalid Signature For Big Order");

    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.14;

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

pragma solidity =0.8.14;

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
        require(order.amountIn != 0, "invalid-amount-in");
        require(order.amountOutMin != 0, "invalid-amount-out-min");
        require(order.recipient != address(0), "invalid-recipient");
        require(order.deadline > block.timestamp, "invalid-deadline");
    }
}