/**
 *Submitted for verification at polygonscan.com on 2022-03-11
*/

// SPDX-License-Identifier: MIT

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts/security/[email protected]

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/token/ERC721/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


// File contracts/libs/IFactoryNFT.sol

/*
    ,-,--.   ,---.      .-._                           ___    ,---.      .-._         
 ,-.'-  _\.--.'  \    /==/ \  .-._  _,..---._  .-._ .'=.'\ .--.'  \    /==/ \  .-._  
/==/_ ,_.'\==\-/\ \   |==|, \/ /, /==/,   -  \/==/ \|==|  |\==\-/\ \   |==|, \/ /, / 
\==\  \   /==/-|_\ |  |==|-  \|  ||==|   _   _\==|,|  / - |/==/-|_\ |  |==|-  \|  |  
 \==\ -\  \==\,   - \ |==| ,  | -||==|  .=.   |==|  \/  , |\==\,   - \ |==| ,  | -|  
 _\==\ ,\ /==/ -   ,| |==| -   _ ||==|,|   | -|==|- ,   _ |/==/ -   ,| |==| -   _ |  
/==/\/ _ /==/-  /\ - \|==|  /\ , ||==|  '='   /==| _ /\   /==/-  /\ - \|==|  /\ , |  
\==\ - , |==\ _.\=\.-'/==/, | |- ||==|-,   _`//==/  / / , |==\ _.\=\.-'/==/, | |- |  
 `--`---' `--`        `--`./  `--``-.`.____.' `--`./  `--` `--`        `--`./  `--`  
                                                                    by sandman.finance                                     
 */
pragma solidity ^0.8.6;

interface  IFactoryNFT {
    function setExperience(uint256 tokenId, uint256 _newExperience) external;
    function getCharacterStats(uint256 tokenId) external view returns (uint256,uint256,uint256,uint256,uint256,uint256);
    function getCharacterOverView(uint256 tokenId) external returns (string memory,uint256,uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File contracts/libs/ImergeAPI.sol

/*
    ,-,--.   ,---.      .-._                           ___    ,---.      .-._         
 ,-.'-  _\.--.'  \    /==/ \  .-._  _,..---._  .-._ .'=.'\ .--.'  \    /==/ \  .-._  
/==/_ ,_.'\==\-/\ \   |==|, \/ /, /==/,   -  \/==/ \|==|  |\==\-/\ \   |==|, \/ /, / 
\==\  \   /==/-|_\ |  |==|-  \|  ||==|   _   _\==|,|  / - |/==/-|_\ |  |==|-  \|  |  
 \==\ -\  \==\,   - \ |==| ,  | -||==|  .=.   |==|  \/  , |\==\,   - \ |==| ,  | -|  
 _\==\ ,\ /==/ -   ,| |==| -   _ ||==|,|   | -|==|- ,   _ |/==/ -   ,| |==| -   _ |  
/==/\/ _ /==/-  /\ - \|==|  /\ , ||==|  '='   /==| _ /\   /==/-  /\ - \|==|  /\ , |  
\==\ - , |==\ _.\=\.-'/==/, | |- ||==|-,   _`//==/  / / , |==\ _.\=\.-'/==/, | |- |  
 `--`---' `--`        `--`./  `--``-.`.____.' `--`./  `--` `--`        `--`./  `--`  
                                                                    by sandman.finance                                     
 */
pragma solidity ^0.8.6;

interface  ImergeAPI {
    function getSkillCard(uint256 _nftID)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected].2.0

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File @openzeppelin/contracts/access/[email protected]

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


// File contracts/SandManToken.sol

/*
    ,-,--.   ,---.      .-._                           ___    ,---.      .-._         
 ,-.'-  _\.--.'  \    /==/ \  .-._  _,..---._  .-._ .'=.'\ .--.'  \    /==/ \  .-._  
/==/_ ,_.'\==\-/\ \   |==|, \/ /, /==/,   -  \/==/ \|==|  |\==\-/\ \   |==|, \/ /, / 
\==\  \   /==/-|_\ |  |==|-  \|  ||==|   _   _\==|,|  / - |/==/-|_\ |  |==|-  \|  |  
 \==\ -\  \==\,   - \ |==| ,  | -||==|  .=.   |==|  \/  , |\==\,   - \ |==| ,  | -|  
 _\==\ ,\ /==/ -   ,| |==| -   _ ||==|,|   | -|==|- ,   _ |/==/ -   ,| |==| -   _ |  
/==/\/ _ /==/-  /\ - \|==|  /\ , ||==|  '='   /==| _ /\   /==/-  /\ - \|==|  /\ , |  
\==\ - , |==\ _.\=\.-'/==/, | |- ||==|-,   _`//==/  / / , |==\ _.\=\.-'/==/, | |- |  
 `--`---' `--`        `--`./  `--``-.`.____.' `--`./  `--` `--`        `--`./  `--`  
                                                                    by sandman.finance                                     
 */
pragma solidity ^0.8.6;



/*
 * TABLE ERROR REFERENCE:
 * E1: The sender is on the blacklist. Please contact to support.
 * E2: The recipient is on the blacklist. Please contact to support.
 * E3: User cannot send more than allowed.
 * E4: User is not operator.
 * E5: User is excluded from antibot system.
 * E6: Bot address is already on the blacklist.
 * E7: The expiration time has to be greater than 0.
 * E8: Bot address is not found on the blacklist.
 * E9: Address cant be 0.
 * E10: newMaxUserTransferAmountRate must be greather than 50 (0.05%)
 * E11: newMaxUserTransferAmountRate must be less than or equal to 10000 (100%)
 * E12: newTransferTax sum must be less than MAX
 * E13: transferTax can't be higher than amount
 */
contract SandManToken is ERC20, Ownable {
    ///@dev Max transfer amount rate. (default is 3% of total supply)
    uint16 public maxUserTransferAmountRate = 300;

    ///@dev Exclude operators from antiBot system
    mapping(address => bool) private _excludedOperators;

    ///@dev mapping store blacklist. address => ExpirationTime 
    mapping(address => uint256) private _blacklist;

    ///@dev Length of blacklist addressess
    uint256 public blacklistLength;

    /// Transfer tax Liquidity Rate 3%
    uint16 public transferTaxLiquidityRate = 300;

    /// Transfer tax Ownership Rate 3%
    uint16 public transferTaxOwnershipRate = 300;

    /// Transfer tax BurnRate 0.66%
    uint16 public transferTaxBurnRate = 66;

    /// Max transfer tax rate: 20.00%.
    uint16 public constant MAXIMUM_TRANSFER_TAX_RATE = 2000;

    // The trading pair
    address public sandManSwapPair;

    // SandMan Treasury
    address public treasuryDAOAddress;
    address public treasuryLiquidityAddress;

    // Burnd Address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Operator Role
    address internal _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event TransferTaxRateUpdated(address indexed operator, uint256 previousRate, uint256 newRate);
    event SetMaxUserTransferAmountRate(address indexed operator, uint256 previousRate, uint256 newRate);
    event SetTransferTaxLiquidityRate(address indexed operator, uint256 previousRate, uint256 newRate);
    event SetTransferTaxOwnershipRate(address indexed operator, uint256 previousRate, uint256 newRate);
    event SetTransferTaxBurnRate(address indexed operator, uint256 previousRate, uint256 newRate);
    event AddBotAddress(address indexed botAddress);
    event RemoveBotAddress(address indexed botAddress);
    event SetOperators(address indexed operatorAddress, bool previousStatus, bool newStatus);

    constructor(address _treasuryDAOAddress, address _treasuryLiquidityAddress)
        ERC20('SANDMAN V2', 'SANDMAN')
    {
        // Exclude operator addresses: lps, burn, treasury, admin, etc from antibot system
        _excludedOperators[msg.sender] = true;
        _excludedOperators[address(0)] = true;
        _excludedOperators[address(this)] = true;
        _excludedOperators[BURN_ADDRESS] = true;
        _excludedOperators[_treasuryDAOAddress] = true;
        _excludedOperators[_treasuryLiquidityAddress] = true;

        treasuryDAOAddress = _treasuryDAOAddress;
        treasuryLiquidityAddress = _treasuryLiquidityAddress;

        _operator = _msgSender();
    }

    /// Modifiers ///
    modifier antiBot(address sender, address recipient, uint256 amount) {
        //check blacklist
        require(!blacklistCheck(sender), "E1");
        require(!blacklistCheck(recipient), "E2");

        // check  if sender|recipient has a tx amount is within the allowed limits
        if (!isExcludedOperator(sender)) {
            if (!isExcludedOperator(recipient))
                require(amount <= maxUserTransferAmount(), "E3");
        }

        _;
    }

    modifier onlyOperator() {
        require(_operator == _msgSender(), "E4");
        _;
    }

    /// External functions ///
    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }

    /// @dev internal function to add address to blacklist.
    function addBotAddressToBlackList(address botAddress, uint256 expirationTime) external onlyOwner {
        require(!isExcludedOperator(botAddress), "E5");
        require(_blacklist[botAddress] == 0, "E6");
        require(expirationTime > 0, "E7");

        _blacklist[botAddress] = expirationTime;
        blacklistLength = blacklistLength + 1;

        emit AddBotAddress(botAddress);
    }
    
    ///@dev internal function to remove address from blacklist.
    function removeBotAddressToBlackList(address botAddress) external onlyOperator {
        require(_blacklist[botAddress] > 0, "E8");

        delete _blacklist[botAddress];
        blacklistLength = blacklistLength - 1;

        emit RemoveBotAddress(botAddress);
    }

    ///@dev Update operator address
    function transferOperator(address newOperator) external onlyOperator {
        require(newOperator != address(0), "E9");

        _operator = newOperator;

        emit OperatorTransferred(_operator, newOperator);
    }

    ///@dev Update operator address status
    function setOperators(address operatorAddress, bool status) external onlyOwner {
        require(operatorAddress != address(0), "E9");

        emit SetOperators(operatorAddress, _excludedOperators[operatorAddress], status);

        _excludedOperators[operatorAddress] = status;
    }

    /*
     * Updates the max user transfer amount.
     * @dev set it to 10000 in order to turn off anti whale system (anti bot)
     */
    function setMaxUserTransferAmountRate(uint16 newMaxUserTransferAmountRate) external onlyOwner {
        require(newMaxUserTransferAmountRate >= 50, "E10");
        require(newMaxUserTransferAmountRate <= 10000, "E11");

        emit SetMaxUserTransferAmountRate(_msgSender(), maxUserTransferAmountRate, newMaxUserTransferAmountRate);

        maxUserTransferAmountRate = newMaxUserTransferAmountRate;
    }

    function setTransferTaxLiquidityRate(uint16 newTransferTaxLiquidityRate) external onlyOwner {
        require((newTransferTaxLiquidityRate + transferTaxOwnershipRate + transferTaxBurnRate) <= MAXIMUM_TRANSFER_TAX_RATE, "E12");

        emit SetTransferTaxLiquidityRate(_msgSender(), transferTaxLiquidityRate, newTransferTaxLiquidityRate);

        transferTaxLiquidityRate = newTransferTaxLiquidityRate;
    }

    function setTransferTaxOwnershipRate(uint16 newTransferTaxOwnershipRate) external onlyOwner {
        require((newTransferTaxOwnershipRate + transferTaxLiquidityRate + transferTaxBurnRate) <= MAXIMUM_TRANSFER_TAX_RATE, "E12");

        emit SetTransferTaxOwnershipRate(_msgSender(), transferTaxOwnershipRate, newTransferTaxOwnershipRate);

        transferTaxOwnershipRate = newTransferTaxOwnershipRate;
    }

    function setTransferTaxBurnRate(uint16 newTransferTaxBurnRate) external onlyOwner {
        require((newTransferTaxBurnRate + transferTaxLiquidityRate + transferTaxOwnershipRate) <= MAXIMUM_TRANSFER_TAX_RATE, "E12");

        emit SetTransferTaxBurnRate(_msgSender(), transferTaxBurnRate, newTransferTaxBurnRate);

        transferTaxBurnRate = newTransferTaxBurnRate;
    }

    /// External functions that are view ///
    ///@dev check if the address is in the blacklist or not
    function blacklistCheckExpirationTime(address botAddress) external view returns(uint256){
        return _blacklist[botAddress];
    }

    function operator() external view returns (address) {
        return _operator;
    }

    ///@dev Check if the address is excluded from antibot system.
    function isExcludedOperator(address userAddress) public view returns(bool) {
        return _excludedOperators[userAddress];
    }

    /// Public functions ///
    /// @notice Creates `amount` token to `to`. Must only be called by the owner (MasterChef).
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    ///@dev Max user transfer allowed
    function maxUserTransferAmount() public view returns (uint256) {
        return (totalSupply() * maxUserTransferAmountRate) / 10000;
    }

    ///@dev check if the address is in the blacklist or expired
    function blacklistCheck(address _botAddress) public view returns(bool) {
        return _blacklist[_botAddress] > block.timestamp;
    }

    /// Internal functions ///
    /// @dev overrides transfer function to meet tokenomics of SANDMAN
    function _transfer(address sender, address recipient, uint256 amount) internal virtual override antiBot(sender, recipient, amount) {
        if (isExcludedOperator(sender) || isExcludedOperator(recipient)) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 sendAmount = amount;
            uint256 burnAmount;
            uint256 liquidityAmount;
            uint256 ownershipAmount;

            if (transferTaxBurnRate > 0)
                burnAmount = (sendAmount * transferTaxBurnRate) / 10000;

            if (transferTaxLiquidityRate > 0)
                liquidityAmount = (sendAmount * transferTaxLiquidityRate) / 10000;

            if (transferTaxOwnershipRate > 0)
                ownershipAmount = (sendAmount * transferTaxOwnershipRate) / 10000;

            require(sendAmount > (burnAmount + liquidityAmount + ownershipAmount), "E13");

            sendAmount = sendAmount - burnAmount - liquidityAmount - ownershipAmount;

            if (burnAmount > 0)
                super._transfer(sender, BURN_ADDRESS, burnAmount);

            if (liquidityAmount > 0)
                super._transfer(sender, treasuryLiquidityAddress, liquidityAmount);

            if (ownershipAmount > 0)
                super._transfer(sender, treasuryDAOAddress, ownershipAmount);

            super._transfer(sender, recipient, sendAmount);

            amount = sendAmount;
        }
    }
}


// File contracts/TheEndlessToken.sol

/*
    ,-,--.   ,---.      .-._                           ___    ,---.      .-._         
 ,-.'-  _\.--.'  \    /==/ \  .-._  _,..---._  .-._ .'=.'\ .--.'  \    /==/ \  .-._  
/==/_ ,_.'\==\-/\ \   |==|, \/ /, /==/,   -  \/==/ \|==|  |\==\-/\ \   |==|, \/ /, / 
\==\  \   /==/-|_\ |  |==|-  \|  ||==|   _   _\==|,|  / - |/==/-|_\ |  |==|-  \|  |  
 \==\ -\  \==\,   - \ |==| ,  | -||==|  .=.   |==|  \/  , |\==\,   - \ |==| ,  | -|  
 _\==\ ,\ /==/ -   ,| |==| -   _ ||==|,|   | -|==|- ,   _ |/==/ -   ,| |==| -   _ |  
/==/\/ _ /==/-  /\ - \|==|  /\ , ||==|  '='   /==| _ /\   /==/-  /\ - \|==|  /\ , |  
\==\ - , |==\ _.\=\.-'/==/, | |- ||==|-,   _`//==/  / / , |==\ _.\=\.-'/==/, | |- |  
 `--`---' `--`        `--`./  `--``-.`.____.' `--`./  `--` `--`        `--`./  `--`  
                                                                    by sandman.finance                                     
 */

pragma solidity ^0.8.6;


contract TheEndlessToken is Ownable, ERC20("TheEndless Owernship", "TheEndless") {
    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }

    /// @notice Creates `amount` token to `to`. Must only be called by the owner (MasterChef).
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;



/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

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


// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File contracts/libs/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File contracts/TreasuryDAO.sol

/*
    ,-,--.   ,---.      .-._                           ___    ,---.      .-._         
 ,-.'-  _\.--.'  \    /==/ \  .-._  _,..---._  .-._ .'=.'\ .--.'  \    /==/ \  .-._  
/==/_ ,_.'\==\-/\ \   |==|, \/ /, /==/,   -  \/==/ \|==|  |\==\-/\ \   |==|, \/ /, / 
\==\  \   /==/-|_\ |  |==|-  \|  ||==|   _   _\==|,|  / - |/==/-|_\ |  |==|-  \|  |  
 \==\ -\  \==\,   - \ |==| ,  | -||==|  .=.   |==|  \/  , |\==\,   - \ |==| ,  | -|  
 _\==\ ,\ /==/ -   ,| |==| -   _ ||==|,|   | -|==|- ,   _ |/==/ -   ,| |==| -   _ |  
/==/\/ _ /==/-  /\ - \|==|  /\ , ||==|  '='   /==| _ /\   /==/-  /\ - \|==|  /\ , |  
\==\ - , |==\ _.\=\.-'/==/, | |- ||==|-,   _`//==/  / / , |==\ _.\=\.-'/==/, | |- |  
 `--`---' `--`        `--`./  `--``-.`.____.' `--`./  `--` `--`        `--`./  `--`  
                                                                    by sandman.finance                                     
 */

pragma solidity ^0.8.6;






/*
 * Errors table:
 * E1: transfer failed!
 * E2: failed approve
 */
contract TreasuryDAO is ReentrancyGuard, AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");

    address public immutable usdAddress;

    address public sandManAddress;

    // default to two weeks
    uint256 public distributionTimeFrame = 3600 * 24; // FIXME: 3600 * 24 * 14

    uint256 public lastUSDDistroTime;

    uint256 public lastSandManDistroTime;

    uint256 public pendingUSD;

    uint256 public pendingSandMan;

    // receive() external payable {}

    event USDTransferredToUser(address recipient, uint256 amount);
    event SandManTransferredToUser(address recipient, uint256 amount);
    event SetDistributionTimeFrame(uint256 distributionTimeFrame);
    event SetSandManAddress(address sandManAddress);

    constructor(address _usdAddress, uint256 startTime) {
        usdAddress = _usdAddress;

        lastUSDDistroTime = startTime;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    /// External functions ///
    ///@dev sell all of a current type of token for usd. and distribute on a drip.
    function getUSDDrip(uint256 totalUsdLockup) external onlyRole(OPERATOR_ROLE) returns (uint256) {
        uint256 usdBalance = IERC20(usdAddress).balanceOf(address(this));
        if (pendingUSD + totalUsdLockup > usdBalance)
            return 0;

        uint256 usdAvailable = usdBalance - pendingUSD - totalUsdLockup;

        // only provide a drip if there has been some blocks passed since the last drip
        uint256 timeSinceLastDistro = block.timestamp > lastUSDDistroTime ? block.timestamp - lastUSDDistroTime : 0;

        // We distribute the usd assuming the old usd balance wanted to be distributed over distributionTimeFrame blocks.
        uint256 usdRelease = (timeSinceLastDistro * usdAvailable) / distributionTimeFrame;

        usdRelease = usdRelease > usdAvailable ? usdAvailable : usdRelease;

        lastUSDDistroTime = block.timestamp;
        pendingUSD = pendingUSD + usdRelease;

        return usdRelease;
    }

    ///@dev sell all of a current type of token for usd. and distribute on a drip.
    function getSandManDrip(uint256 totalSandManLockup) external onlyRole(OPERATOR_ROLE) returns (uint256) {
        require(sandManAddress != address(0));

        uint256 sandManBalance = IERC20(sandManAddress).balanceOf(address(this));
        if (pendingSandMan + totalSandManLockup > sandManBalance)
            return 0;

        uint256 sandManAvailable = sandManBalance - pendingSandMan - totalSandManLockup;

        // only provide a drip if there has been some blocks passed since the last drip
        uint256 timeSinceLastDistro = block.timestamp > lastSandManDistroTime ? block.timestamp - lastSandManDistroTime : 0;

        // We distribute the sandMan assuming the old sandMan balance wanted to be distributed over distributionTimeFrame blocks.
        uint256 sandManRelease = (timeSinceLastDistro * sandManAvailable) / distributionTimeFrame;

        sandManRelease = sandManRelease > sandManAvailable ? sandManAvailable : sandManRelease;

        lastSandManDistroTime = block.timestamp;
        pendingSandMan = pendingSandMan + sandManRelease;

        return sandManRelease;
    }

    function transferUSDToOwner(address ownerAddress, uint256 amount) external onlyRole(OPERATOR_ROLE) {
        uint256 usdBalance = IERC20(usdAddress).balanceOf(address(this));
        if (usdBalance < amount)
            amount = usdBalance;

        require(IERC20(usdAddress).transfer(ownerAddress, amount), "E1");

        /// avoid negative result
        if (amount > pendingUSD)
            amount = pendingUSD;

        pendingUSD = pendingUSD - amount;

        emit USDTransferredToUser(ownerAddress, amount);
    }

    function transferSandManToOwner(address ownerAddress, uint256 amount) external onlyRole(OPERATOR_ROLE) {
        require(sandManAddress != address(0));

        uint256 sandManBalance = IERC20(sandManAddress).balanceOf(address(this));
        if (sandManBalance < amount)
            amount = sandManBalance;

        require(IERC20(sandManAddress).transfer(ownerAddress, amount), "E1");

        /// avoid negative result
        if (amount > pendingSandMan)
            amount = pendingSandMan;

        pendingSandMan = pendingSandMan - amount;

        emit SandManTransferredToUser(ownerAddress, amount);
    }

    function setSandManAddress(address newSandManAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        sandManAddress = newSandManAddress;

        emit SetSandManAddress(sandManAddress);
    }

    function setDistributionTimeFrame(uint256 newUsdDistributionTimeFrame) external onlyRole(DEFAULT_ADMIN_ROLE) {
        distributionTimeFrame = newUsdDistributionTimeFrame;

        emit SetDistributionTimeFrame(distributionTimeFrame);
    }

    function emergencyWithDrawToken(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        if (balanceToken > 0)
            IERC20(token).transfer(msg.sender, balanceToken);
    }
}


// File contracts/MasterChefNFT.sol

/*
    ,-,--.   ,---.      .-._                           ___    ,---.      .-._         
 ,-.'-  _\.--.'  \    /==/ \  .-._  _,..---._  .-._ .'=.'\ .--.'  \    /==/ \  .-._  
/==/_ ,_.'\==\-/\ \   |==|, \/ /, /==/,   -  \/==/ \|==|  |\==\-/\ \   |==|, \/ /, / 
\==\  \   /==/-|_\ |  |==|-  \|  ||==|   _   _\==|,|  / - |/==/-|_\ |  |==|-  \|  |  
 \==\ -\  \==\,   - \ |==| ,  | -||==|  .=.   |==|  \/  , |\==\,   - \ |==| ,  | -|  
 _\==\ ,\ /==/ -   ,| |==| -   _ ||==|,|   | -|==|- ,   _ |/==/ -   ,| |==| -   _ |  
/==/\/ _ /==/-  /\ - \|==|  /\ , ||==|  '='   /==| _ /\   /==/-  /\ - \|==|  /\ , |  
\==\ - , |==\ _.\=\.-'/==/, | |- ||==|-,   _`//==/  / / , |==\ _.\=\.-'/==/, | |- |  
 `--`---' `--`        `--`./  `--``-.`.____.' `--`./  `--` `--`        `--`./  `--`  
                                                                    by sandman.finance                                     
 */
pragma solidity ^0.8.6;








/*
 * Errors Ref Table
 * E1: add: invalid deposit fee basis points
 * E2: add: invalid harvest interval
 * E3: set: invalid deposit fee basis points
 * E4: we dont accept deposits of 0 size
 * E5: withdraw: not good
 * E6: user already added nft
 * E7: User is not owner of nft sent
 * E8: user no has nft
 * E9: !nonzero
 * E10: cannot change start block if sale has already commenced
 * E11: cannot set start block in the past
 */
contract MasterChefNFT is Ownable, ReentrancyGuard, ERC721Holder {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 sandManRewardDebt;
        uint256 theEndlessRewardDebt;
        uint256 usdRewardDebt;
        uint256 extraSandManRewardDebt;
        uint256 sandManRewardLockup;
        uint256 theEndlessRewardLockup;
        uint256 usdRewardLockup;
        uint256 extraSandManRewardLockup;
        uint256 nextHarvestUntil;
    }

    struct UserNftInfo {
        uint256 nftId;
        uint256 powerStaking;
        uint256 experience;
        bool hasNft;
    }

    struct PoolInfo {
        address lpToken;
        uint256 allocPoint;
        uint256 lastRewardTime;
        uint256 accSandManPerShare;
        uint256 accTheEndlessPerShare;
        uint256 totalLocked;
        uint256 harvestInterval;
        uint256 depositFeeBP;
        uint256 tokenType;
    }

    uint256 public constant sandManMaximumSupply = 500 * (10 ** 3) * (10 ** 18); // 500,000 sandManToken

    uint256 constant MAX_EMISSION_RATE = 10 * (10 ** 18); // 10

    uint256 constant MAXIMUM_HARVEST_INTERVAL = 4 hours;

    // The SANDMAN TOKEN!
    address public immutable sandManToken;

    // SandMan Treasury
    TreasuryDAO public immutable treasuryDAO;

    // SandMan Treasury Util Address
    address public immutable treasuryUtil;

    // The THE ENDLESS TOKEN!
    address public immutable theEndlessToken;

    // Interface NFT FACTORY
    address public immutable iFactoryNFT;

    // Interface Merge API
    address immutable iMergeAPI;

    // Total usd collected
    uint256 public totalUSDCollected;

    // Total usd collected
    uint256 public totalExtraSandManCollected;

    // USD per share
    uint256 public accDepositUSDRewardPerShare;

    // Extra Sandman per share
    uint256 public accDepositExtraSandManRewardPerShare;

    // SANDMAN tokens created per second.
    uint256 public sandManPerSecond;

    // TheEndless tokens created per second.
    uint256 public theEndlessPerSecond;

    // Experience rate created per second.
    uint256 public experienceRate;

    // Deposit Fee address.
    address public feeAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    mapping(uint256 => mapping(address => UserNftInfo)) public userNftInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    // The Endless PID.
    uint256 public theEndlessPid;
    
    // The block number when SANDMAN mining starts.
    uint256 public startTime;

    // The block number when SANDMAN mining ends.
    uint256 public emmissionEndTime = type(uint256).max;

    // Used NFT.
    // mapping(uint256 => bool) nftIds;

    // Whitelist for avoid harvest lockup for some operative contracts like vaults.
    mapping(address => bool) public harvestLockupWhiteList;

    // The harvest interval.
    uint256 harvestInterval;

    // Total token minted for farming.
    uint256 totalSupplyFarmed;

    // Total usd Lockup
    uint256 public totalUsdLockup;

    // Total extra Sandman Lockup
    uint256 public totalExtraSandManLockup;

    // Events definitions
    event AddPool(uint256 indexed pid, uint256 tokenType, uint256 allocPoint, address lpToken, uint256 depositFeeBP);
    event SetPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint256 depositFeeBP);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 treasuryDepositFee);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawNFT(address indexed user, uint256 indexed pid, uint256 nftId);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetEmissionRate(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetStartTime(uint256 indexed newStartTime);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event WithDrawNFTByIndex(uint256 indexed nftId, address indexed userAddress);

    constructor(
        TreasuryDAO _treasuryDAO,
        address _treasuryUtil,
        address _sandManToken,
        address _theEndlessToken,
        address _iFactoryNFT,
        address _iMergeAPI,
        address _feeAddress,
        uint256 _sandManPerSecond,
        uint256 _theEndlessPerSecond,
        uint256 _experienceRate,
        uint256 _startTime
    ) {
        treasuryDAO = _treasuryDAO;
        treasuryUtil = _treasuryUtil;
        sandManToken = _sandManToken;
        theEndlessToken = _theEndlessToken;
        iFactoryNFT = _iFactoryNFT;
        iMergeAPI = _iMergeAPI;
        feeAddress = _feeAddress;
        sandManPerSecond = _sandManPerSecond;
        theEndlessPerSecond = _theEndlessPerSecond;
        experienceRate = _experienceRate;
        startTime = _startTime;
    }

    /// External functions ///
    /// Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 newTokenType,
        uint256 newAllocPoint,
        address newLpToken,
        uint256 newDepositFeeBP,
        uint256 newHarvestInterval,
        bool withUpdate
    ) external onlyOwner {
        // Make sure the provided token is ERC20
        IERC20(newLpToken).balanceOf(address(this));

        require(newDepositFeeBP <= 401, "E1");
        require(newHarvestInterval <= MAXIMUM_HARVEST_INTERVAL, "E2");

        if (withUpdate)
            _massUpdatePools();

        uint256 lastRewardTime = block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint + newAllocPoint;

        poolInfo.push(PoolInfo({
          tokenType: newTokenType,
          lpToken : newLpToken,
          allocPoint : newAllocPoint,
          lastRewardTime : lastRewardTime,
          depositFeeBP : newDepositFeeBP,
          totalLocked: 0,
          accSandManPerShare: 0,
          accTheEndlessPerShare: 0,
          harvestInterval: newHarvestInterval
        }));

        emit AddPool(poolInfo.length - 1, newTokenType, newAllocPoint, newLpToken, newDepositFeeBP);
    }

    /// Update the given pool's SANDMAN allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 pid,
        uint256 newTokenType,
        uint256 newAllocPoint,
        uint256 newDepositFeeBP,
        uint256 newHarvestInterval,
        bool withUpdate
    ) external onlyOwner {
        require(newDepositFeeBP <= 401, "E3");

        if (withUpdate)
            _massUpdatePools();

        totalAllocPoint = totalAllocPoint - poolInfo[pid].allocPoint + newAllocPoint;
        poolInfo[pid].allocPoint = newAllocPoint;
        poolInfo[pid].depositFeeBP = newDepositFeeBP;
        poolInfo[pid].tokenType = newTokenType;
        poolInfo[pid].harvestInterval = newHarvestInterval;

        emit SetPool(pid, poolInfo[pid].lpToken, newAllocPoint, newDepositFeeBP);
    }

    function deposit(uint256 pid, uint256 amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        _updatePool(pid);
        _payPendingTheEndlessSandMan(pid);
        uint256 treasuryDepositFee;
        if (amount > 0) {
            uint256 balanceBefore = IERC20(pool.lpToken).balanceOf(address(this));
            IERC20(pool.lpToken).safeTransferFrom(address(msg.sender), address(this), amount);
            amount = IERC20(pool.lpToken).balanceOf(address(this)) - balanceBefore;
            require(amount > 0, "E4");

            if (pool.depositFeeBP > 0) {
                uint256 totalDepositFee = (amount * pool.depositFeeBP) / 10000;
                uint256 devDepositFee = (totalDepositFee * 7500) / 10000;
                treasuryDepositFee = totalDepositFee - devDepositFee;
                amount = amount - totalDepositFee;
                // send 3% to sandman finance
                IERC20(pool.lpToken).safeTransfer(feeAddress, devDepositFee);
                // send 1% to treasury
                IERC20(pool.lpToken).safeTransfer(address(treasuryUtil), treasuryDepositFee);

                user.amount = user.amount + amount;
                pool.totalLocked = pool.totalLocked + amount;
            } else {
                user.amount = user.amount + amount;
                pool.totalLocked = pool.totalLocked + amount;
            }
        }
        user.sandManRewardDebt = (user.amount * pool.accSandManPerShare) / 1e24;
        user.theEndlessRewardDebt = (user.amount * pool.accTheEndlessPerShare) / 1e24;
        if (pid == theEndlessPid) {
            user.usdRewardDebt = ((user.amount * accDepositUSDRewardPerShare) / 1e24);
            user.extraSandManRewardDebt = ((user.amount * accDepositExtraSandManRewardPerShare) / 1e24);
        }

        emit Deposit(msg.sender, pid, amount, treasuryDepositFee);
    }

    function withdraw(uint256 pid, uint256 amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        require(user.amount >= amount, "E5");

        _updatePool(pid);
        _payPendingTheEndlessSandMan(pid);
        
        if (amount > 0) {
            user.amount = user.amount - amount;
            IERC20(pool.lpToken).safeTransfer(address(msg.sender), amount);
            pool.totalLocked = pool.totalLocked - amount;
        }

        user.sandManRewardDebt = (user.amount * pool.accSandManPerShare) / 1e24;
        user.theEndlessRewardDebt = (user.amount * pool.accTheEndlessPerShare) / 1e24;

        if (pid == theEndlessPid) {
            user.usdRewardDebt = ((user.amount * accDepositUSDRewardPerShare) / 1e24);
            user.extraSandManRewardDebt = ((user.amount * accDepositExtraSandManRewardPerShare) / 1e24);
        }

        emit Withdraw(msg.sender, pid, amount);
    }

    function addNFT(uint256 pid, uint256 nftId) external nonReentrant {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        UserNftInfo storage userNft = userNftInfo[pid][msg.sender];

        require(!userNft.hasNft, "E6");
        require(IFactoryNFT(iFactoryNFT).ownerOf(nftId) == msg.sender, "E7");

        _updatePool(pid);
        _payPendingTheEndlessSandMan(pid);

        IFactoryNFT(iFactoryNFT).safeTransferFrom(msg.sender, address(this), nftId);

        userNft.hasNft = true;
        // nftIds[nftId] = true;
        userNft.nftId = nftId;
        userNft.powerStaking = _getNFTPowerStaking(userNft.nftId);
        userNft.experience = _getNFTExperience(userNft.nftId);

        _updateHarvestLockup(pid);

        user.sandManRewardDebt = (user.amount * pool.accSandManPerShare) / 1e24;
    }

    function withdrawNFT(uint256 pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        UserNftInfo storage userNft = userNftInfo[pid][msg.sender];

        require(userNft.hasNft, "E8");

        _updatePool(pid);

        _payPendingTheEndlessSandMan(pid);
        
        if (user.sandManRewardLockup > 0) {
            _payNFTBoost(pid, user.sandManRewardLockup);
            userNft.experience = userNft.experience + ((user.sandManRewardLockup * experienceRate) / 10000);
            IFactoryNFT(iFactoryNFT).setExperience(userNft.nftId, userNft.experience);
        }

        IFactoryNFT(iFactoryNFT).safeTransferFrom(address(this), msg.sender, userNft.nftId); 

        // nftIds[user.nftId] = false;

        userNft.hasNft = false;
        userNft.nftId = 0;
        userNft.powerStaking = 0;
        userNft.experience = 0;

        _updateHarvestLockup(pid);

        user.sandManRewardDebt = (user.amount * pool.accSandManPerShare) / 1e24;

        emit WithdrawNFT(msg.sender, pid, userNft.nftId);
    }

    function emergencyWithdraw(uint256 pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.sandManRewardDebt = 0;
        user.sandManRewardLockup = 0;

        user.theEndlessRewardDebt = 0;
        user.theEndlessRewardLockup = 0;

        user.usdRewardDebt = 0;
        user.usdRewardLockup = 0;
        user.extraSandManRewardDebt = 0;
        user.extraSandManRewardLockup = 0;

        user.nextHarvestUntil = 0;
        IERC20(pool.lpToken).safeTransfer(address(msg.sender), amount);

        // In the case of an accounting error, we choose to let the user emergency withdraw anyway
        if (pool.totalLocked >= amount)
            pool.totalLocked = pool.totalLocked - amount;
        else
            pool.totalLocked = 0;

        emit EmergencyWithdraw(msg.sender, pid, amount);
    }

    // Set fee address. OnlyOwner
    function setFeeAddress(address newFeeAddress) external onlyOwner {
        require(newFeeAddress != address(0), "E9");
        feeAddress = newFeeAddress;
        // emit SetFeeAddress(msg.sender, newFeeAddress);
    }

    ///@dev Set startTime. Only can run before start by Owner.
    function setStartTime(uint256 newStartTime) external onlyOwner {
        require(block.timestamp < startTime, "E10");
        require(block.timestamp < newStartTime, "E11");

        startTime = newStartTime;
        _massUpdateLastRewardTimePools();

        // emit SetStartTime(startTime);
    }

    function setEmissionRate(uint256 newSandManPerSecond) external onlyOwner {
        require(newSandManPerSecond > 0);
        require(newSandManPerSecond < MAX_EMISSION_RATE);

        _massUpdatePools();
        sandManPerSecond = newSandManPerSecond;

        emit SetEmissionRate(msg.sender, sandManPerSecond, newSandManPerSecond);
    }

    function setExperienceRate(uint256 newExperienceRate) external onlyOwner {
        require(newExperienceRate >= 0);

        experienceRate = newExperienceRate;
    }

    /// Add/Remove address to whitelist for havest lockup.
    function setHarvestLockupWhiteList(address recipient, bool newStatus) external onlyOwner {
        harvestLockupWhiteList[recipient] = newStatus;
    }

    ///@dev Emergency NFT WithDraw, only owner.
    function emergencyWithdrawNFTByIndex(uint256 nftId, address userAddress) external onlyOwner {
        require(IFactoryNFT(iFactoryNFT).ownerOf(nftId) == address(this));

        IFactoryNFT(iFactoryNFT).safeTransferFrom(address(this), userAddress, nftId);

        emit WithDrawNFTByIndex(nftId, userAddress);
    }

    /// External functions that are view ///
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    ///@return pending USD.
    function pendingUSD(address userAddress) external view returns (uint256) {
        UserInfo storage user = userInfo[0][userAddress];

        return ((user.amount * accDepositUSDRewardPerShare) / 1e24) + user.usdRewardLockup - user.usdRewardDebt;
    }

    ///@return pending Extra Sandman.
    function pendingExtraSandMan(address userAddress) external view returns (uint256) {
        UserInfo storage user = userInfo[0][userAddress];

        return ((user.amount * accDepositExtraSandManRewardPerShare) / 1e24) + user.extraSandManRewardLockup - user.extraSandManRewardDebt;
    }

    ///@return pending SandMan.
    function pendingSandMan(uint256 pid, address userAddress) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][userAddress];
        uint256 accSandManPerShare = pool.accSandManPerShare;
        if (block.timestamp > pool.lastRewardTime && pool.totalLocked != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint256 sandManReward = (multiplier * sandManPerSecond * pool.allocPoint) / totalAllocPoint;
            accSandManPerShare = accSandManPerShare + ((sandManReward * 1e24) / pool.totalLocked);
        }
        uint256 pending = ((user.amount * accSandManPerShare) /  1e24) - user.sandManRewardDebt;

        return pending + user.sandManRewardLockup;
    }

    ///@return pending Endless.
    function pendingTheEndless(uint256 pid, address userAddress) external view returns (uint256) {
        if (pid == theEndlessPid)
            return 0;

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][userAddress];
        uint256 accTheEndlessPerShare = pool.accTheEndlessPerShare;
        if (block.timestamp > pool.lastRewardTime && pool.totalLocked != 0 && totalAllocPoint > poolInfo[theEndlessPid].allocPoint) {
            uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
            uint256 theEndlessReward = (multiplier * theEndlessPerSecond * pool.allocPoint) / (totalAllocPoint - poolInfo[theEndlessPid].allocPoint);
            accTheEndlessPerShare = accTheEndlessPerShare + ((theEndlessReward * 1e24) / pool.totalLocked);
        }
        uint256 pending = ((user.amount * accTheEndlessPerShare) /  1e24) - user.theEndlessRewardDebt;

        return pending + user.theEndlessRewardLockup;
    }

    /// Public functions ///
    function canHarvest(uint256 pid, address userAddress) public view returns (bool) {
        UserInfo storage user = userInfo[pid][userAddress];

        return block.timestamp >= user.nextHarvestUntil;
    }

    /// Internal functions ///
    function _massUpdatePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    function _updatePool(uint256 pid) internal {
        PoolInfo storage pool = poolInfo[pid];
        if (block.timestamp <= pool.lastRewardTime)
            return;

        if (pool.totalLocked == 0 || pool.allocPoint == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }

        // TheEndless pool is always pool 0.
        if (poolInfo[theEndlessPid].totalLocked > 0) {
            uint256 usdRelease = treasuryDAO.getUSDDrip(totalUsdLockup);
            accDepositUSDRewardPerShare = accDepositUSDRewardPerShare + ((usdRelease * 1e24) / poolInfo[theEndlessPid].totalLocked);
            totalUSDCollected = totalUSDCollected + usdRelease;

            uint256 extraSandManRelease = treasuryDAO.getSandManDrip(totalExtraSandManLockup);
            accDepositExtraSandManRewardPerShare = accDepositExtraSandManRewardPerShare + ((extraSandManRelease * 1e24) / poolInfo[theEndlessPid].totalLocked);
            totalExtraSandManCollected = totalExtraSandManCollected + extraSandManRelease;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardTime, block.timestamp);
        uint256 sandManReward = (multiplier * sandManPerSecond * pool.allocPoint) / totalAllocPoint;

        // This shouldn't happen, but just in case we stop rewards.
        if (totalSupplyFarmed > sandManMaximumSupply)
            sandManReward = 0;
        else if ((totalSupplyFarmed + sandManReward) > sandManMaximumSupply)
            sandManReward = sandManMaximumSupply - totalSupplyFarmed;

        if (sandManReward > 0) {
            SandManToken(sandManToken).mint(address(this), sandManReward);
            totalSupplyFarmed = totalSupplyFarmed + sandManReward;
        }

        if (pid != theEndlessPid && totalAllocPoint > poolInfo[theEndlessPid].allocPoint) { 
            uint256 theEndlessReward = (multiplier * theEndlessPerSecond * pool.allocPoint) / (totalAllocPoint - poolInfo[theEndlessPid].allocPoint);
            if (theEndlessReward > 0) {
                TheEndlessToken(theEndlessToken).mint(address(this), theEndlessReward);
                pool.accTheEndlessPerShare = pool.accTheEndlessPerShare + ((theEndlessReward * 1e24) / pool.totalLocked);
            }
        }

        // The first time we reach SandMan max supply we solidify the end of farming.
        if (totalSupplyFarmed >= sandManMaximumSupply && emmissionEndTime == type(uint256).max)
            emmissionEndTime = block.timestamp;

        pool.accSandManPerShare = pool.accSandManPerShare + ((sandManReward * 1e24) / pool.totalLocked);
        pool.lastRewardTime = block.timestamp;
    }

    function _safeTokenTransfer(address token, address to, uint256 amount) internal {
        uint256 tokenBal = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, amount > tokenBal ? tokenBal : amount);
    }

    // Update lastRewardTime variables for all pools.
    function _massUpdateLastRewardTimePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            poolInfo[pid].lastRewardTime = startTime;
        }
    }

    ///@dev Pay or Lockup pending sandManToken and the endless token.
    function _payPendingTheEndlessSandMan(uint256 pid) internal {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];

        if (user.nextHarvestUntil == 0)
            _updateHarvestLockup(pid);

        uint256 pendingSandManToken = ((user.amount * pool.accSandManPerShare) / 1e24) - user.sandManRewardDebt;
        uint256 pendingTheEndlessToken;
        uint256 pendingUSDToken;
        uint256 pendingExtraSandManToken;
        if (pid == theEndlessPid) {
            pendingUSDToken = ((user.amount * accDepositUSDRewardPerShare) / 1e24) - user.usdRewardDebt;
            pendingExtraSandManToken = ((user.amount * accDepositExtraSandManRewardPerShare) / 1e24) - user.extraSandManRewardDebt;
        } else {
            pendingTheEndlessToken = ((user.amount * pool.accTheEndlessPerShare) / 1e24) - user.theEndlessRewardDebt;
        }

        if (canHarvest(pid, msg.sender)) {
            if (pendingSandManToken > 0 || user.sandManRewardLockup > 0) {
                uint256 sandmanRewards = pendingSandManToken + user.sandManRewardLockup;
                // reset lockup
                user.sandManRewardLockup = 0;
                _updateHarvestLockup(pid);

                // send rewards
                _safeTokenTransfer(sandManToken, msg.sender, sandmanRewards);

                UserNftInfo storage userNft = userNftInfo[pid][msg.sender];

                if (userNft.hasNft) {
                    _payNFTBoost(pid, sandmanRewards);
                    userNft.experience = userNft.experience + ((sandmanRewards * experienceRate) / 10000);
                    IFactoryNFT(iFactoryNFT).setExperience(userNft.nftId, userNft.experience);
                }
            }

            if (pid == theEndlessPid) {
                if (pendingUSDToken > 0 || user.usdRewardLockup > 0) {
                    uint256 usdRewards = pendingUSDToken + user.usdRewardLockup;
                    treasuryDAO.transferUSDToOwner(msg.sender, usdRewards);
                    if (user.usdRewardLockup > 0) {
                        totalUsdLockup = totalUsdLockup - user.usdRewardLockup;
                        user.usdRewardLockup = 0;
                    }
                }
                if (pendingExtraSandManToken > 0 || user.extraSandManRewardLockup > 0) {
                    uint256 extraSandManRewards = pendingExtraSandManToken + user.extraSandManRewardLockup;
                    treasuryDAO.transferSandManToOwner(msg.sender, extraSandManRewards);
                    if (user.extraSandManRewardLockup > 0) {
                        totalUsdLockup = totalUsdLockup - user.extraSandManRewardLockup;
                        user.extraSandManRewardLockup = 0;
                    }
                }
            } else {
                if (pendingTheEndlessToken > 0 || user.theEndlessRewardLockup > 0) {
                    uint256 theEndlessRewards = pendingTheEndlessToken + user.theEndlessRewardLockup;
                    user.theEndlessRewardLockup = 0;
                    _safeTokenTransfer(theEndlessToken, msg.sender, theEndlessRewards);
                }
            }
        } else if (pendingSandManToken > 0 || pendingTheEndlessToken > 0 || pendingUSDToken > 0 || pendingExtraSandManToken > 0) {
            user.sandManRewardLockup = user.sandManRewardLockup + pendingSandManToken;
            if (pid == theEndlessPid) {
                if (pendingUSDToken > 0) {
                    user.usdRewardLockup = user.usdRewardLockup + pendingUSDToken;
                    totalUsdLockup = totalUsdLockup + pendingUSDToken;
                }

                if (pendingExtraSandManToken > 0) {
                    user.extraSandManRewardLockup = user.extraSandManRewardLockup + pendingExtraSandManToken;
                    totalExtraSandManLockup = totalExtraSandManLockup + pendingExtraSandManToken;
                }
            } else {
                user.theEndlessRewardLockup = user.theEndlessRewardLockup + pendingTheEndlessToken;
            }
        }

        emit RewardLockedUp(msg.sender, pid, pendingSandManToken);
    }

    function _getNFTExperience(uint256 nftId) internal returns (uint256) {
        (,uint256 experience,) = IFactoryNFT(iFactoryNFT).getCharacterOverView(nftId);

        return experience;
    }

    function _updateHarvestLockup(uint256 pid) internal {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][msg.sender];
        UserNftInfo storage userNft = userNftInfo[pid][msg.sender];

        uint256 newHarvestInverval = harvestLockupWhiteList[msg.sender] ? 0 : pool.harvestInterval;

        if (userNft.hasNft && newHarvestInverval > 0) {
            uint256 quarterInterval = (newHarvestInverval * 2500) / 10000;
            uint256 extraBoosted;
            if (userNft.experience > 100)
                extraBoosted = (userNft.experience / 10) / 1e18;

            if (extraBoosted > quarterInterval)
                extraBoosted = quarterInterval;

            newHarvestInverval = newHarvestInverval - quarterInterval - extraBoosted;
        }

        user.nextHarvestUntil = block.timestamp + newHarvestInverval;
    }

    function _payNFTBoost(uint256 pid, uint256 pending) internal {
        UserNftInfo storage userNft = userNftInfo[pid][msg.sender];

        uint256 extraBoosted;
        if (userNft.experience > 100)
            extraBoosted = (userNft.experience / 1e18) / 100;

        uint256 rewardBoosted = (pending * (userNft.powerStaking + extraBoosted)) / 10000;
        if (rewardBoosted > 0)
            SandManToken(sandManToken).mint(msg.sender, rewardBoosted);
    }

    /// Internal functions that are view ///
    ///@dev Get returns MergeAPI if exists or NFTFactory stats
    function _getNFTPowerStaking(uint256 nftId) internal view returns (uint256) {
        uint256 strength;
        uint256 agility;
        uint256 endurance;
        uint256 intelligence;
        uint256 wisdom;
        uint256 magic;

        (
            strength,
            agility,
            endurance,
            intelligence,
            magic,
            wisdom
        ) = ImergeAPI(iMergeAPI).getSkillCard(nftId); // support for merged cards

        if (strength == 0 && agility == 0 ) {
            (
                strength,
                agility,
                endurance,
                intelligence,
                wisdom,
                magic
            ) = IFactoryNFT(iFactoryNFT).getCharacterStats(nftId);
        }

        return (strength + agility + endurance + intelligence + magic + wisdom);
    }

    ///@dev Return reward multiplier over the given from to to time.
    function getMultiplier(uint256 from, uint256 to) internal view returns (uint256) {
        // As we set the multiplier to 0 here after emmissionEndTime
        // deposits aren't blocked after farming ends.
        if (from > emmissionEndTime)
            return 0;

        if (to > emmissionEndTime)
            return emmissionEndTime - from;
        else
            return to - from;
    }
}