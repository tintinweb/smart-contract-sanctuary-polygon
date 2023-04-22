/**
 *Submitted for verification at polygonscan.com on 2023-04-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

//File: [ReentrancyGuard.sol]

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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//File: [IRouter.sol]

interface IUniRouterV1
{
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

interface IUniRouterV2 is IUniRouterV1
{
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

//File: [IERC20.sol]

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

//File: [Context.sol]

/*
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

//File: [Address.sol]

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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

//File: [IERC165.sol]

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//File: [ML_TransferETH.sol]

contract ML_TransferETH
{
    //========================
    // ATTRIBUTES
    //======================== 

    uint256 public transferGas = 30000;

    //========================
    // CONFIG FUNCTIONS
    //======================== 

    function _setTransferGas(uint256 _gas) internal
    {
        require(_gas >= 30000, "Gas to low");
        require(_gas <= 250000, "Gas to high");
        transferGas = _gas;
    }

    //========================
    // TRANSFER FUNCTIONS
    //======================== 

    function transferETH(address _to, uint256 _amount) internal
    {
        (bool success, ) = payable(_to).call{ value: _amount, gas: transferGas }("");
        success; //prevent warning
    }
}

//File: [IFactory.sol]

interface IFactory
{
    //========================
    // PAIR FUNCTIONS
    //========================

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

//File: [IToken.sol]

interface IToken
{
	//========================
    // EVENTS FUNCTIONS
    //========================

	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

	//========================
    // INFO FUNCTIONS
    //========================
	
	function decimals() external view returns (uint8);	
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
	function totalSupply() external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);

	//========================
    // USER INFO FUNCTIONS
    //========================

    function balanceOf(address account) external view returns (uint256);

    //========================
    // TRANSFER / APPROVE FUNCTIONS
    //========================

    function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);    
    function approve(address spender, uint256 amount) external returns (bool);
}

//File: [Ownable.sol]

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//File: [Pausable.sol]

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

//File: [IERC721.sol]

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

//File: [IERC1155.sol]

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

//File: [ML_ETHOracle.sol]

contract ML_ETHOracle
{
    //========================
    // CONSTANTS
    //========================

    uint256 public constant PERCENT_FACTOR = 1000000; //100%

    //========================
    // ATTRIBUTES
    //========================

    //fees
    IToken public peggedToken; //pegged token for oracle (recommended: stable coin)
    IUniRouterV2 public oracleRouter; //router to get amount in ETH
    uint256 public oracleSlippage; //allowed oracle slippage

    //========================
    // CONFIG FUNCTIONS
    //========================

    function _setFeeSlippage(uint256 _slippage) internal
    {
        require(_slippage <= PERCENT_FACTOR, "Invalid slippage");
        oracleSlippage = _slippage;
    }

    function _setOracle(IUniRouterV2 _router, IToken _peggedToken) internal
    {
        //check
        require(
            IFactory(_router.factory())
                .getPair(
                    address(_peggedToken),
                    _router.WETH())
                != address(0),
            "No oracle pair found"
        );

        //set
        oracleRouter = _router;
        peggedToken = _peggedToken;
    }

    //========================
    // INFO FUNCTIONS
    //========================

    function _getOracleAmountInETH(uint256 _amount) internal view returns (uint256)
    {
        if (address(oracleRouter) == address(0)
            || address(peggedToken) == address(0))
        {
            return 0;
        }

        //make direct route [token => wETH]
        address[] memory path = new address[](2);
        path[0] = address(peggedToken);  
        path[1] = oracleRouter.WETH(); 

        //get amounts out
        uint256[] memory out = oracleRouter.getAmountsOut(_amount, path);          
        return out[out.length - 1];
    }

    function _getOracleAmountInETHWithSlippage(uint256 _amount) internal view returns (uint256)
    {
        return (_getOracleAmountInETH(_amount) * (PERCENT_FACTOR - oracleSlippage)) / PERCENT_FACTOR;
    }
}

//File: [SafeERC20.sol]

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

//File: [IReferralManager.sol]

interface IReferralManager
{
    //========================
    // ATTRIBUTES
    //========================

    function userReferralMap(uint256 _referralID) external view returns (address);

    //========================
    // REFERRAL INFO FUNCTIONS
    //========================

    function getUserReferralFeeShare(address _user, string calldata _service, uint256 _amount) external view returns (uint256);

    //========================
    // DEPOSIT FUNCTIONS
    //========================

    function depositToken(uint256 _referralID, IToken _token, uint256 _amount) external;
    function depositETH(uint256 _referralID) external payable;
}

//File: [ML_RecoverFunds.sol]

contract ML_RecoverFunds is ML_TransferETH
{
    //========================
    // LIBS
    //========================

    using SafeERC20 for IERC20;

    //========================
    // EMERGENCY FUNCTIONS
    //======================== 

    function _recoverETH(uint256 _amount, address _to) internal
    {
        transferETH(_to, _amount);
    }

    function _recoverToken(IToken _token, uint256 _amount, address _to) internal
    {
        IERC20(address(_token)).safeTransfer(_to, _amount);
    }  
}

//File: [ML_TransferHelper.sol]

contract ML_TransferHelper
{
    //========================
    // LIBS
    //========================

    using SafeERC20 for IERC20;

    //========================
    // STRUCTS
    //========================

    struct TransferResult
    {
        uint256 fromBefore;     //balance of from-token, before transfer
        uint256 toBefore;       //balance of token, before transfer
        uint256 toAfter;        //balance of token, after transfer
        uint256 transferred;    //transferred amount 
    }

    //========================
    // FUNCTIONS
    //========================

    function safeTransferFrom(
        IToken _token,
        uint256 _amount,
        address _from,
        address _to
    ) internal returns (TransferResult memory)
    {
        //init
        TransferResult memory result = TransferResult(
        {
            fromBefore: _token.balanceOf(_from),
            toBefore: _token.balanceOf(_to),
            toAfter: 0,
            transferred: 0
        });

        //transfer
        IERC20(address(_token)).safeTransferFrom(
            _from, 
            _to, 
            _amount
        );

        //process
        result.toAfter = _token.balanceOf(_to);
        result.transferred = result.toAfter - result.toBefore;

        return result;
    }

    function safeTransfer(
        IToken _token,
        uint256 _amount,
        address _to
    ) internal returns (TransferResult memory)
    {
        //init
        TransferResult memory result = TransferResult(
        {
            fromBefore: _token.balanceOf(msg.sender),
            toBefore: _token.balanceOf(_to),
            toAfter: 0,
            transferred: 0
        });

        //transfer
        IERC20(address(_token)).safeTransfer(
            _to, 
            _amount
        );

        //process
        result.toAfter = _token.balanceOf(_to);
        result.transferred = result.toAfter - result.toBefore;

        return result;
    }

    function safeApprove(IToken _token, address _spender, uint256 _amount) internal
    {
        _token.approve(_spender, 0); //first reset to 0 to be safe
        if (_amount != 0)
        {
            _token.approve(_spender, _amount);
        }
    }
}

//File: [ServiceWithReferral.sol]

contract ServiceWithReferral is
    ML_TransferETH
{
    //========================
    // ATTRIBUTES
    //======================== 

    IReferralManager public referralManager;
    string public serviceName;

    //========================
    // CONFIG FUNCTIONS
    //======================== 

    function _setReferralManager(IReferralManager _manager) internal
    {
        referralManager = _manager;
    }

    function _setServiceName(string memory _service) internal
    {
        serviceName = _service;
    }

    //========================
    // REFERRAL FEE FUNCTIONS
    //========================     

    function getReferralFeeAmount(uint256 _referralID, uint256 _amount) private view returns (uint256)
    {
        if (address(referralManager) == address(0)
            || bytes(serviceName).length == 0
            || _referralID == 0)
        {
            return 0;
        }

        address referrer = referralManager.userReferralMap(_referralID);
        if (referrer == address(0))
        {
            return 0;
        }

        return referralManager.getUserReferralFeeShare(referrer, serviceName, _amount);
    }

    function _handleReferralFeeETH(uint256 _referralID, uint256 _amount) internal returns (uint256)
    {
        uint256 referralFeeAmount = getReferralFeeAmount(_referralID, _amount);
        if (referralFeeAmount != 0)
        {
            referralManager.depositETH{ value: referralFeeAmount }(_referralID);
        }

        return (_amount - referralFeeAmount);
    }

    function _handleReferralFeeToken(uint256 _referralID, IToken _token, uint256 _amount) internal returns (uint256)
    {
        uint256 referralFeeAmount = getReferralFeeAmount(_referralID, _amount);
        if (referralFeeAmount != 0)
        {
            //approve
            _token.approve(address(referralManager), 0);
            _token.approve(address(referralManager), referralFeeAmount);

            //deposit
            referralManager.depositToken(_referralID, _token, referralFeeAmount);

            //remove approval
            _token.approve(address(referralManager), 0);
        }

        return (_amount - referralFeeAmount);
    }
}

contract Airdrop is
    Ownable,
    Pausable,
    ReentrancyGuard,
    ML_RecoverFunds,
    ML_TransferHelper,
    ML_ETHOracle,
    ServiceWithReferral
{
    //========================
    // LIBS
    //========================

    using SafeERC20 for IERC20;

    //========================
    // STRUCTS
    //========================

    struct AirdropInfoERC20
    {
        address to;
        uint256 amount;
    }

    struct AirdropInfoERC721
    {
        address to;
        uint256 id;
    }

    struct AirdropInfoERC1155
    {
        address to;
        uint256 id;
        uint256 amount;
    }    

    //========================
    // CONSTANTS
    //========================

    string public constant VERSION = "1.0.0";

    //========================
    // ATTRIBUTES
    //========================

    uint256 public erc20_maxAirdropLength = 200;
    uint256 public erc721_maxAirdropLength = 200;
    uint256 public erc1155_maxAirdropLength = 200;

    //fee info
    uint256 public feesInPeggedAmountPerItem; //fee in the value of pegged token
    address public feeWallet; //fee receiver
    uint256 public feeSlippage; //allowed fee slippage

    //whitelist
    mapping(address => bool) public whitelisted; //users that dont have to pay

    //========================
    // CREATE
    //========================

    constructor()
    {
        _setServiceName("Airdrop");
        feeSlippage = 50; //0.5%
        feeWallet = msg.sender;
    }

    //========================
    // CONFIG FUNCTIONS
    //========================

    function setReferralManager(IReferralManager _manager) external onlyOwner
    {
        _setReferralManager(_manager);
    }

    function setFeeSlippage(uint256 _slippage) external onlyOwner
    {
        _setFeeSlippage(_slippage);
    }

    function setOracle(IUniRouterV2 _router, IToken _peggedToken) external onlyOwner
    {
        _setOracle(_router, _peggedToken);
    }

    function setFeeWallet(address _wallet) external onlyOwner
    {
        feeWallet = _wallet;
    }

    function setFeeAmountInPeggedPerItem(uint256 _amount) external onlyOwner
    {
        feesInPeggedAmountPerItem = _amount;
    }

    function setTransferGas(uint256 _gas) external onlyOwner
    {
        _setTransferGas(_gas);
    }

    function setWhitelist(address _user, bool _whitelist) external onlyOwner
    {
        whitelisted[_user] = _whitelist;
    }

    //========================
    // INFO FUNCTIONS
    //========================

    function getFeeAmountInETH(uint256 _items) public view returns (uint256)
    {
        if (whitelisted[msg.sender])
        {
            return 0;
        }
        return _getOracleAmountInETH(feesInPeggedAmountPerItem * _items);
    }

    function getFeeAmountInETHWithSlippage(uint256 _items) public view returns (uint256)
    {
        if (whitelisted[msg.sender])
        {
            return 0;
        }
        return _getOracleAmountInETHWithSlippage(feesInPeggedAmountPerItem * _items);
    }    

    //========================
    // AIRDROP FUNCTIONS
    //========================

    function airdropERC20(
        IERC20 _token,
        AirdropInfoERC20[] memory _info,
        bool _checkTax,
        uint256 _referralID
    ) external payable nonReentrant whenNotPaused
    {
        //check
        requireMaxLength(_info.length, erc20_maxAirdropLength);

        //take fee
        takeFee(_info.length, _referralID);

        //airdrop
        uint256 transferred = 0;
        for (uint256 n = 0; n < _info.length; n++)
        {
            //check if transfer required
            if (_info[n].to == msg.sender)
            {
                continue;
            }

            //transfer
            transferred = safeTransferFrom(
                IToken(address(_token)),
                _info[n].amount,
                msg.sender,
                _info[n].to
            ).transferred;

            //check tax
            require(!_checkTax || transferred == _info[n].amount, "Token has tax");            
        }
    }

    function airdropERC721(
        IERC721 _token,
        AirdropInfoERC721[] memory _info,
        uint256 _referralID
    ) external payable nonReentrant whenNotPaused
    {
        //check
        requireMaxLength(_info.length, erc721_maxAirdropLength);

        //take fee
        takeFee(_info.length, _referralID);

        //airdrop
        for (uint256 n = 0; n < _info.length; n++)
        {
            //check if transfer required
            if (_info[n].to == msg.sender)
            {
                continue;
            }

            //transfer
            _token.safeTransferFrom(
                msg.sender,
                _info[n].to,
                _info[n].id
            );       
        }
    }

    function airdropERC1155(
        IERC1155 _token,
        AirdropInfoERC1155[] memory _info,
        uint256 _referralID
    ) external payable nonReentrant whenNotPaused
    {
        //check
        requireMaxLength(_info.length, erc1155_maxAirdropLength);

        //take fee
        takeFee(_info.length, _referralID);

        //airdrop
        for (uint256 n = 0; n < _info.length; n++)
        {
            //check if transfer required
            if (_info[n].to == msg.sender)
            {
                continue;
            }
            
            //transfer
            _token.safeTransferFrom(
                msg.sender,
                _info[n].to,
                _info[n].id,
                _info[n].amount,
                ""
            );       
        }
    }

    //========================
    // FEE FUNCTIONS
    //========================

    function takeFee(uint256 _items, uint256 _referralID) private
    {
        //check fee
        uint256 fee = getFeeAmountInETHWithSlippage(_items);
        require(fee <= msg.value, "Insufficent fee payment");

        //to fee wallet                
        if (feeWallet != address(0))
        {
            uint256 feeAmount = _handleReferralFeeETH(_referralID, msg.value);
            transferETH(feeWallet, feeAmount);
        }
    }

    //========================
    // HELPER FUNCTIONS
    //========================

    receive() external payable {}

    function requireMaxLength(uint256 _length, uint256 _maxLength) private pure
    {
        require(_length <= _maxLength, "Airdrop list to long");
    }

    //========================
    // SECURITY FUNCTIONS
    //========================

    function pause() external onlyOwner
    {
        _pause();
    }

    function unpause() external onlyOwner
    {
        _unpause();
    }

    //========================
    // EMERGENCY FUNCTIONS
    //======================== 

    function recoverETH(uint256 _amount, address _to) external onlyOwner
    {
        super._recoverETH(_amount, _to);        
    }

    function recoverToken(IToken _token, uint256 _amount, address _to) external onlyOwner
    {
        super._recoverToken(_token, _amount, _to);
    }  
}