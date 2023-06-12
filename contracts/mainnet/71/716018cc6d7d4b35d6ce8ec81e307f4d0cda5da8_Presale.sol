/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// File contracts/presaleNew.sol

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity 0.8.19;

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
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.19;

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

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity 0.8.19;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity 0.8.19;

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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.19;

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity 0.8.19;

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

// File contracts/Presale.sol
// SPDX-License-Identifier: MIT
// import "hardhat/console.sol";
pragma solidity 0.8.19;

contract Presale is Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    uint256[4] public rate;

    // Token for which presale is being done
    address public saleToken;
    uint public saleTokenDec;

    //Total tokens to be sold in the presale
    uint256 public totalTokensforSale;
    uint256 public maxBuyLimit; // Maximum amount of tokens to buy per user
    uint256 public minBuyLimit; // Minimum amount of tokens to buy per transaction

    // Whitelist of tokens to buy from
    mapping(address => bool) public tokenWL;

    // 1 Token price in terms of WL tokens
    mapping(address => uint256[4]) public tokenPrices;

    // List of Buyers
    address[] public buyers;

    uint256 public presaleStartTime;
    uint256 public presaleEndTime;

    bool public isUnlockingStarted;

    // Amounts bought by buyers
    mapping(address => BuyerTokenDetails) public buyersAmount;

    //
    // Statistics
    //
    uint256 public totalTokensSold;

    Bounce[] public bounces;

    struct BuyerTokenDetails {
        uint amount;
        bool isClaimed;
    }

    struct Bounce {
        uint256 amount;
        uint256 percentage;
    }

    constructor() {}

    modifier isPresaleHasNotStarted() {
        if (presaleStartTime != 0) {
            require(
                block.timestamp < presaleStartTime,
                "Presale: Presale has already started"
            );
        }
        _;
    }

    modifier isPresaleStarted() {
        require(
            block.timestamp >= presaleStartTime,
            "Presale: Presale has not started yet"
        );
        _;
    }

    modifier isPresaleNotEnded() {
        require(block.timestamp < presaleEndTime, "Presale: Presale has ended");
        _;
    }

    modifier isPresaleEnded() {
        require(
            block.timestamp >= presaleEndTime,
            "Presale: Presale has not ended yet"
        );
        _;
    }

    event TokenAdded(address token, uint256[4] price);

    event TokenUpdated(address token, uint256[4] price);

    event TokensBought(
        address indexed buyer,
        address indexed token,
        uint256 amount,
        uint256 tokensBought
    );

    event TokensUnlocked(address indexed buyer, uint256 amount);

    event SaleTokenAdded(address token, uint256 amount);

    //function to set information of Token sold in Pre-Sale and its rate in Native currency
    function setSaleTokenParams(
        address _saleToken,
        uint256 _totalTokensforSale
    ) external onlyOwner isPresaleHasNotStarted {
        require(
            _saleToken != address(0),
            "Presale: Sale token cannot be zero address"
        );
        require(
            _totalTokensforSale > 0,
            "Presale: Total tokens for sale cannot be zero"
        );

        saleToken = _saleToken;
        saleTokenDec = IERC20Metadata(saleToken).decimals();

        IERC20(saleToken).safeTransferFrom(
            msg.sender,
            address(this),
            _totalTokensforSale
        );

        totalTokensforSale = IERC20(saleToken).balanceOf(address(this));

        emit SaleTokenAdded(_saleToken, _totalTokensforSale);
    }

    function setPresaleTime(
        uint256 _presaleStartTime,
        uint256 _presaleEndTime
    ) external onlyOwner isPresaleHasNotStarted {
        require(
            _presaleStartTime < _presaleEndTime,
            "Presale: Start time must be less than end time"
        );

        presaleStartTime = _presaleStartTime;
        presaleEndTime = _presaleEndTime;
    }

    // Add a token to buy presale token from, with price
    function addWhiteListedToken(
        address _token,
        uint256[4] memory _price
    ) external onlyOwner {
        tokenWL[_token] = true;
        tokenPrices[_token] = _price;

        emit TokenAdded(_token, _price);
    }

    function updateEthRate(uint256[4] memory _rate) external onlyOwner {
        rate = _rate;
    }

    function updateTokenRate(
        address _token,
        uint256[4] memory _price
    ) external onlyOwner {
        require(tokenWL[_token], "Presale: Token not whitelisted");
        tokenPrices[_token] = _price;

        emit TokenUpdated(_token, _price);
    }

    function startUnlocking() external onlyOwner isPresaleEnded {
        require(!isUnlockingStarted, "Presale: Unlocking has already started");
        isUnlockingStarted = true;
    }

    function stopUnlocking() external onlyOwner isPresaleEnded {
        require(isUnlockingStarted, "Presale: Unlocking hasn't started yet!");
        isUnlockingStarted = false;
    }

    function setBounces(
        uint256[] memory _amounts,
        uint256[] memory _percentages
    ) external onlyOwner {
        require(
            _amounts.length == _percentages.length,
            "Presale: Bounce arrays length mismatch"
        );

        // check if all elements in _percentages array are less than 1000
        for (uint256 i = 0; i < _percentages.length; i++) {
            require(
                _percentages[i] <= 1000,
                "Presale: Percentage should be less than 1000"
            );
        }

        // delete old bounces
        delete bounces;

        // set Bonuce array in sorted order
        for (uint256 i = 0; i < _amounts.length; i++) {
            uint256 min = i;
            for (uint256 j = i + 1; j < _amounts.length; j++) {
                if (_amounts[j] < _amounts[min]) {
                    min = j;
                }
            }
            uint256 temp = _amounts[min];
            _amounts[min] = _amounts[i];
            _amounts[i] = temp;

            temp = _percentages[min];
            _percentages[min] = _percentages[i];
            _percentages[i] = temp;

            bounces.push(Bounce(_amounts[i], _percentages[i]));
        }
    }

    function getCurrentTier() public view returns (uint) {
        uint256 duration = presaleEndTime - (presaleStartTime);

        if (block.timestamp <= presaleStartTime + (duration / (4))) {
            return 0;
        } else if (block.timestamp <= presaleStartTime + (duration / (2))) {
            return 1;
        } else if (block.timestamp <= presaleStartTime + ((duration * 3) / 4)) {
            return 2;
        } else {
            return 3;
        }
    }

    // Public view function to calculate amount of sale tokens returned if you buy using "amount" of "token"
    function getTokenAmount(
        address token,
        uint256 amount
    ) public view returns (uint256) {
        uint256 amtOut;
        uint tier = getCurrentTier();
        if (token != address(0)) {
            require(tokenWL[token], "Presale: Token not whitelisted");

            amtOut = tokenPrices[token][tier] != 0
                ? (amount * (10 ** saleTokenDec)) / (tokenPrices[token][tier])
                : 0;
        } else {
            amtOut = rate[tier] != 0
                ? (amount * (10 ** saleTokenDec)) / (rate[tier])
                : 0;
        }
        return amtOut;
    }

    function getBounceAmount(uint256 amount) public view returns (uint256) {
        uint256 bounce = 0;
        for (uint256 i = 0; i < bounces.length; i++) {
            if (amount >= bounces[i].amount) {
                bounce = bounces[i].percentage;
            }
        }
        return (amount * bounce) / 1000;
    }

    // Public Function to buy tokens. APPROVAL needs to be done first
    function buyToken(
        address _token,
        uint256 _amount
    ) external payable isPresaleStarted isPresaleNotEnded {
        uint256 saleTokenAmt = _token != address(0)
            ? getTokenAmount(_token, _amount)
            : getTokenAmount(address(0), msg.value);

        // check if saleTokenAmt is greater than minBuyLimit
        require(
            saleTokenAmt >= minBuyLimit,
            "Presale: Min buy limit not reached"
        );
        require(
            buyersAmount[msg.sender].amount + saleTokenAmt <= maxBuyLimit,
            "Presale: Max buy limit reached for this phase"
        );
        require(
            (totalTokensSold + saleTokenAmt) <= totalTokensforSale,
            "Presale: Total Token Sale Reached!"
        );

        if (_token != address(0)) {
            require(_amount > 0, "Presale: Cannot buy with zero amount");
            require(tokenWL[_token], "Presale: Token not whitelisted");

            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        saleTokenAmt = saleTokenAmt + (getBounceAmount(saleTokenAmt));

        totalTokensSold += saleTokenAmt;
        buyersAmount[msg.sender].amount += saleTokenAmt;

        emit TokensBought(msg.sender, _token, _amount, saleTokenAmt);
    }

    function withdrawToken() external {
        require(isUnlockingStarted, "Presale: Locking period not over yet");

        require(
            !buyersAmount[msg.sender].isClaimed,
            "Presale: Already claimed"
        );

        uint256 tokensforWithdraw = buyersAmount[msg.sender].amount;
        buyersAmount[msg.sender].isClaimed = true;
        IERC20(saleToken).safeTransfer(msg.sender, tokensforWithdraw);

        emit TokensUnlocked(msg.sender, tokensforWithdraw);
    }

    function setMinBuyLimit(uint _minBuyLimit) external onlyOwner {
        minBuyLimit = _minBuyLimit;
    }

    function setMaxBuyLimit(uint _maxBuyLimit) external onlyOwner {
        maxBuyLimit = _maxBuyLimit;
    }

    function withdrawSaleToken(
        uint256 _amount
    ) external onlyOwner isPresaleEnded {
        IERC20(saleToken).safeTransfer(msg.sender, _amount);
    }

    function withdrawAllSaleToken() external onlyOwner isPresaleEnded {
        uint256 amt = IERC20(saleToken).balanceOf(address(this));
        IERC20(saleToken).safeTransfer(msg.sender, amt);
    }

    function withdraw(address token, uint256 amt) public onlyOwner {
        require(
            token != saleToken,
            "Presale: Cannot withdraw sale token with this method, use withdrawSaleToken() instead"
        );
        IERC20(token).safeTransfer(msg.sender, amt);
    }

    function withdrawAll(address token) public onlyOwner {
        require(
            token != saleToken,
            "Presale: Cannot withdraw sale token with this method, use withdrawAllSaleToken() instead"
        );
        uint256 amt = IERC20(token).balanceOf(address(this));
        withdraw(token, amt);
    }

    function withdrawCurrency(uint256 amt) public onlyOwner {
        payable(msg.sender).transfer(amt);
    }
}