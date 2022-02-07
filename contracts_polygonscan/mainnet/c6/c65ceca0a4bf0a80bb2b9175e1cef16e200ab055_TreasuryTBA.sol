/**
 *Submitted for verification at polygonscan.com on 2022-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

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

interface IERC20Decimals {
    function decimals() external view returns(uint256);
}

interface IERC20Mintable {
    function mint(address account_, uint256 ammount_) external;
}

/// @title TreasuryTBA
/// @author Defiville
/// @notice Treasury used to mint new bAny and lock them for borrowing anys.
contract TreasuryTBA is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public governance;
    address public immutable BANY = 0xD51a5153f21D035CfBEBf640666f9A79d4d2BaF5;

    // users info
    mapping(address => uint256) public lockers; // bAny locked by users
    mapping(address => uint256) public borrowers; // any borrowed by users (same weight for each any)

    uint256 public anyDeposited; // total any deposited (same weight for each any)

    uint256 public borrowFee = 50; // 0.5%
    uint256 public immutable MAX_BORROW_FEE = 10000; // 100%
    address public anyAllocator; // borrow fee recipient

    // treasury tba allowances 
    mapping(address => bool) public anysWhitelist; // any tokens whitelisted 
    mapping(address => uint256) public mintersAllowance; // amount of bAny allowed to mint by each minter
    mapping(address => uint256) public anysAllowance; // amount of any allowed to use for minting bAny (common for all minters)

    /* Events */

    event BanyMinted(
        address indexed minter, 
        address indexed recipient, 
        address indexed any, 
        uint256 amount, 
        uint256 bAnyMinted
    );
    event BanyLocked(
        address indexed caller, 
        address indexed user, 
        uint256 amount
    );
    event BanyUnlocked(address indexed user, uint256 amount);
    event AnyBorrowed(address indexed user, address any, uint256 amount);
    event AnyRepaid(
        address indexed caller, 
        address indexed user, 
        address indexed any, 
        uint256 amount
    );
    event TBAIncreased(address indexed any, uint256 amount, uint256 totalAmount);
    event GovernanceChanged(address oldGov, address newGov);
    event BorrowFeeChanged(uint256 oldF, uint256 newF);
    event AnyAllocatorChanged(address oldAllocator, address newAllocator);
    event AnyWhitelisted(address any);
    event AnyAllowanceIncreased(address indexed any, uint256 anyAmount);
    event AnyAllowanceDecreased(address indexed any, uint256 anyAmount);
    event MinterAllowanceIncreased(address indexed minter, uint256 bAnyAmount);
    event MinterAllowanceDecreased(address indexed minter, uint256 bAnyAmount);
    event NonAnyRescued(address nonAny, uint256 amount, address recipient);
    
    constructor(address _anyAllocator) {
        require(_anyAllocator != address(0));
        anyAllocator = _anyAllocator;
        governance = msg.sender;
    }

    /**
     *  @notice mint and send bAny to the recipient
     *  @param _any any token address 
     *  @param _amount amount of any to deposit
     *  @param _recipient recipient to send bAny minted 
     */
    function mintBany(
        address _any,
        uint256 _amount,
        address _recipient
    ) external nonReentrant returns(uint256) {
        return _mintBany(_any, _amount, _recipient);
    }

    /**
     *  @notice mint and send bAny to the recipient using more than one any 
     *  @param _anys anys token addresses 
     *  @param _amounts amounts of anys to deposit
     *  @param _recipient recipient to send bAny minted
     */
    function mintBany(
        address[] memory _anys,
        uint256[] memory _amounts,
        address _recipient
    ) external nonReentrant returns(uint256) {
        require(_anys.length == _amounts.length);
        uint256 bAnyMinted;
        for(uint256 i = 0; i < _anys.length; i++) {
            bAnyMinted += _mintBany(_anys[i], _amounts[i], _recipient);
        }
        return bAnyMinted;
    }

    /**
     *  @notice mint and send bAny to the recipient
     *  @param _any any token address 
     *  @param _amount amount to minnt
     *  @param _recipient recipient address
     *  @return number of bAny minted
     */
    function _mintBany(
        address _any, 
        uint256 _amount,
        address _recipient 
    ) internal returns(uint256) {
        // as first check if any is whitelisted 
        require(anysWhitelist[_any], "any not whitelisted");
        // check if the treasuryTBA receives the correct amount of any
        _receiveERC20(_any, _amount);

        // Logic to assume that for every new bAny minted
        // the treasury has received the actual TBA amount of any
        uint256 tba = getTBA();
        uint256 amount18D = _amount * (1e18 / 10**IERC20Decimals(_any).decimals());
        // it traces the number of any deposited (it can't decrease)
        anyDeposited += amount18D; // every any is counted with 18 decimals
        require(amount18D > (tba / 1e18), "amount to mint too low");
        uint256 bAnyToMint = (amount18D * 1e18) / tba;

        // check allowances and decrease them
        require(mintersAllowance[msg.sender] >= bAnyToMint, "amount exceed minter allowance");
        mintersAllowance[msg.sender] -= bAnyToMint;
        require(anysAllowance[_any] >= _amount, "amount exceed any allowance");
        anysAllowance[_any] -= _amount;

        // mint new Bany 
        IERC20Mintable(BANY).mint(_recipient, bAnyToMint);

        emit BanyMinted(msg.sender, _recipient, _any, _amount, bAnyToMint);
        
        return bAnyToMint;
    }

    /**
     *  @notice lock bAny, this can be used to lock bAny for other 
     *  @param _user user to lock for
     *  @param _amount address
     */
    function lockBany(address _user, uint256 _amount) external nonReentrant {
        // check if the treasuryTBA receives the correct amount of bAny
        _receiveERC20(BANY, _amount);

        // increase the number of bAny locked by the user
        lockers[_user] +=  _amount;

        emit BanyLocked(msg.sender, _user, _amount);
    }

    /**
     *  @notice unlock bAny up to the max amount unlockable
     *  @param _amount amount of bAny to unlock
     */
    function unlockBany(uint256 _amount) external nonReentrant {
        require(_amount > 0, "amount needs to be > 0");
        // check if the user can unlock this bAny amount
        require(_amount <= maxBanyToUnlock(msg.sender), "exceed amount of bAny unlockable");

        // transfer bAny to user
        uint256 balanceBefore = IERC20(BANY).balanceOf(address(this));
        IERC20(BANY).safeTransfer(msg.sender, _amount);
        uint256 balanceAfter = IERC20(BANY).balanceOf(address(this));
        require(balanceBefore - balanceAfter == _amount, "wrong amount of BANY sent");
        // decrease the unlock amount
        lockers[msg.sender] -= _amount;

        emit BanyUnlocked(msg.sender, _amount);
    }

    /**
     *  @notice borrow anys based on the amount of bAny locked
     *  @param _anys any addresses 
     *  @param _amounts amount of anys to borrow
     */
    function borrowAnys(
        address[] memory _anys, 
        uint256[] memory _amounts
    ) external nonReentrant {
        require(_anys.length == _amounts.length, "Different length");
        for (uint256 i = 0; i < _anys.length; i++) {
            _borrowAny(_anys[i], _amounts[i]);
        }
    }

    /**
     *  @notice borrow any based on the amount of bAny locked
     *  @param _any any address
     *  @param _amount amount of any to borrow
     */
    function borrowAny(address _any, uint256 _amount) public nonReentrant {
        _borrowAny(_any, _amount);
    }

    /**
     *  @notice borrow any
     *  @param _any any address
     *  @param _amount amount of any to borrow
     */
    function _borrowAny(address _any, uint256 _amount) internal {
        // check if any is whitelisted
        require(anysWhitelist[_any], "Any not allowed");
        require(_amount > 0, "amount needs to be > 0");

        uint256 balanceBefore = IERC20(_any).balanceOf(address(this));
        // calculate borrow fee
        // the min amount threshold will be the same for any token
        // example 6 decimals -> min amount 0.01 any
        require(_amount >= MAX_BORROW_FEE, "amount to borrow too low");
        uint256 fee;
        if (borrowFee > 0) {
            fee = (_amount / MAX_BORROW_FEE) * borrowFee;
            // send fee to any allocator
            IERC20(_any).safeTransfer(anyAllocator, fee);
        }
        // send any borrowed to users 
        IERC20(_any).safeTransfer(msg.sender, _amount - fee);
        uint256 balanceAfter = IERC20(_any).balanceOf(address(this));
        require(balanceBefore - balanceAfter == _amount, "wrong amount sent");
            
        // every any is taken in 18 decimals
        uint256 amountWith18Decimals = _amount * (1e18 / 10**IERC20Decimals(_any).decimals());
        // check if the amount to borrow does not reach the max for the user 
        require(amountWith18Decimals <= maxAnyToBorrow(msg.sender), "exceed borrow limit");

        borrowers[msg.sender] += amountWith18Decimals;

        emit AnyBorrowed(msg.sender, _any, _amount);
    }

    /**
     *  @notice repay anys
     *  @param _anys any tokens
     *  @param _amounts amounts to repay for each any
     *  @param _locker address to repay anys
     */
    function repayAnys(
        address[] memory _anys, 
        uint256[] memory _amounts,
        address _locker
    ) external nonReentrant {
        require(_anys.length == _amounts.length, "different length");
        for (uint i = 0; i < _anys.length; i++) {
            _repayAny(_anys[i], _amounts[i], _locker);
        }
    }

    /**
     *  @notice repay any
     *  @param _any any tokens
     *  @param _amount amounts to repay for each any
     *  @param _locker address to repay any
     */
    function repayAny(address _any, uint256 _amount, address _locker) public nonReentrant {
        _repayAny(_any, _amount, _locker);
    }

    /**
     *  @notice repay any
     *  @param _any any tokens
     *  @param _amount amount to repay for each any
     *  @param _locker address to repay any
     */
    function _repayAny(address _any, uint256 _amount, address _locker) internal {
        // check if any is whitelisted
        require(anysWhitelist[_any], "any not allowed");

        // receive any from caller
        _receiveERC20(_any, _amount);

        uint256 amountWith18Decimals = _amount * (1e18 / 10**IERC20Decimals(_any).decimals());
        // repay any for locker
        borrowers[_locker] -= amountWith18Decimals;

        emit AnyRepaid(msg.sender, _locker, _any, _amount);
    }

    /**
     *  @notice deposit more than one any, increase the TBA
     *  @param _anys any token addresses
     *  @param _amounts amounts to deposit
     */
    function increaseTBA(address[] memory _anys, uint256[] memory _amounts) external nonReentrant {
        require(_anys.length == _amounts.length, "different length");
        for (uint i = 0; i < _anys.length; i++) {
            _increaseTBA(_anys[i], _amounts[i]);
        }
    }

    /**
     *  @notice deposit any, this action increases the TBA
     *  @param _any address
     *  @param _amount amount to deposit
     */
    function increaseTBA(address _any, uint256 _amount) public nonReentrant {
        _increaseTBA(_any, _amount);
    }

    /**
     *  @notice deposit any, this action increases the TBA
     *  @param _any address
     *  @param _amount amount to deposit
     */
    function _increaseTBA(address _any, uint256 _amount) internal {
        require(anysWhitelist[_any], "any not whitelisted");

        // receive any for increasing the TBA
        _receiveERC20(_any, _amount);

        // same weight and decimals for every any allowed
        uint256 amountWith18Decimals = _amount * (1e18 / 10**IERC20Decimals(_any).decimals());
        anyDeposited += amountWith18Decimals;

        emit TBAIncreased(_any, _amount, anyDeposited);
    }

    /**
     *  @notice receive any ERC20
     *  @param _token token address
     *  @param _amount amount to receive
     */
    function _receiveERC20(address _token, uint256 _amount) internal {
        require(_amount > 0, "amount needs to be > 0");
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        uint256 balanceAfter = IERC20(_token).balanceOf(address(this));
        require(balanceAfter - balanceBefore == _amount, "wrong amount received");
    }

    /* View functions */

    /**
     *  @notice get the actual tba (token backed amount)
     */
    function getTBA() public view returns(uint256) {
        uint256 totalSupply = IERC20(BANY).totalSupply();
        if (totalSupply > 0) {
            return (anyDeposited * 1e18) / totalSupply;   
        }
        return 1e18;
    }

    /**
     *  @notice return the max any amount left to borrow based on debt 
     *  @param _user user address
     */
    function maxAnyToBorrow(address _user) public view returns(uint256) {
        // bAny locked
        uint256 locked = lockers[_user];
        // any borrowed
        uint256 borrowed = borrowers[_user];
        // get the actual TBA
        uint256 tba = getTBA();
        // return the max amount of any left to borrow
        return ((locked * tba) / 1e18) - borrowed;
    }

    /**
     *  @notice return the max amount of bAny unlockable
     *  @param _user user address
     */
    function maxBanyToUnlock(address _user) public view returns(uint256) {
        // bAny locked
        uint256 locked = lockers[_user];
        // any borrowed
        uint256 borrowed = borrowers[_user];
        // get the actual TBA
        uint256 tba = getTBA();  
        // bAny not unlockable
        uint256 bAnyNotUnlockable = (borrowed * 1e18) / tba;
        // return the max any amount of bAny unlockable
        return locked - bAnyNotUnlockable;
    }

    /* Governance functions */

    /**
     *  @notice set new governance
     *  @param _governance address
     */
    function setGovernace(address _governance) external {
        require(msg.sender == governance, "!gov");
        require(_governance != address(0), "can't use address 0");
        emit GovernanceChanged(governance, _governance);
        governance = _governance;
    }

    /**
     *  @notice set new borrow fee
     *  @param _borrowFee fee in percentage (10000 = 100%)
     */
    function setBorrowFee(uint256 _borrowFee) external {
        require(msg.sender == governance, "!gov");
        require(_borrowFee <= MAX_BORROW_FEE, "exceed max borrow fee");
        emit BorrowFeeChanged(borrowFee, _borrowFee);
        borrowFee = _borrowFee;
    }

    /**
     *  @notice set new any allocator
     *  @param _anyAllocator address
     */
    function setAnyAllocator(address _anyAllocator) external {
        require(msg.sender == governance, "!gov");
        require(_anyAllocator != address(0), "can't use address 0");
        emit AnyAllocatorChanged(anyAllocator, _anyAllocator);
        anyAllocator = _anyAllocator;
    }

    /**
     *  @notice Whitelist a new any token
     *  @param _any token address
     */
    function whitelistAny(address _any) external {
        require(msg.sender == governance, "!gov");
        require(_any != address(0), "can't use address 0");
        require(anysWhitelist[_any] == false, "already whitelisted");
        anysWhitelist[_any] = true;
        emit AnyWhitelisted(_any);
    }

    /**
     *  @notice increase any allowance
     *  @param _any token address
     *  @param _anyAmount amount to increase
     */
    function increaseAnyAllowance(address _any, uint256 _anyAmount) external {
        require(msg.sender == governance, "!gov");
        require(_any != address(0), "can't use address 0");
        anysAllowance[_any] += _anyAmount;
        emit AnyAllowanceIncreased(_any, _anyAmount);
    }

    /**
     *  @notice decrease any allowance
     *  @param _any token address
     *  @param _anyAmount amount to decrease
     */
    function decreaseAnyAllowance(address _any, uint256 _anyAmount) external {
        require(msg.sender == governance, "!gov");
        require(_any != address(0), "can't use address 0");
        require(anysAllowance[_any] >= _anyAmount, "exceed total allowance");
        anysAllowance[_any] -= _anyAmount;
        emit AnyAllowanceDecreased(_any, _anyAmount);
    }

    /**
     *  @notice increase minter allowance
     *  @param _minter bAny minter address
     *  @param _bAnyAmount amount to increase the allowance 
     */
    function increaseMinterAllowance(address _minter, uint256 _bAnyAmount) external {
        require(msg.sender == governance, "!gov");
        require(_minter != address(0), "can't use address 0");
        mintersAllowance[_minter] += _bAnyAmount;
        emit MinterAllowanceIncreased(_minter, _bAnyAmount);
    }

    /**
     *  @notice decrease minter allowance
     *  @param _minter bAny minter address
     *  @param _bAnyAmount amount to decrease the allowance 
     */
    function decreaseMinterAllowance(address _minter, uint256 _bAnyAmount) external {
        require(msg.sender == governance, "!gov");
        require(_minter != address(0), "can't use address 0");
        require(mintersAllowance[_minter] >= _bAnyAmount, "exceed total allowance");
        mintersAllowance[_minter] -= _bAnyAmount;
        emit MinterAllowanceDecreased(_minter, _bAnyAmount);
    }

    /**
     *  @notice rescue non Any token 
     *  @param _nonAny token address to rescue
     *  @param _amount amount to rescue
     *  @param _recipient address to send non any rescued 
     */
    function rescueNonAny(address _nonAny, uint256 _amount, address _recipient) external {
        require(msg.sender == governance, "!gov");
        require(anysWhitelist[_nonAny] == false, "can't rescue any whitelisted");
        uint256 balance = IERC20(_nonAny).balanceOf(address(this));
        require(_amount <= balance, "amount exceed balance");
        IERC20(_nonAny).safeTransfer(_recipient, _amount);
        emit NonAnyRescued(_nonAny, _amount, _recipient);
    }
}