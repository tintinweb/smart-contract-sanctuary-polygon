// SPDX-License-Identifier: AGPL-1.0
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./DefiMagicPolygon.sol";

contract SwapNightToDMagic is Ownable, DefiMagicPolygon, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public depositToken = 0xEEf10C9Bf17c9d2C9619fd29447B231EA0Fde548;
    address public returnToken = 0x61dAECaB65EE2A1D5b6032df030f3fAA3d116Aa7;
    uint256 private returnRatio;     
    uint256 private depositRatio;
    address private outputAddress;
    uint256 public depositCount;
    uint256 public depositTotal;
    uint256 public returnTotal;

    constructor() {
        IERC20(depositToken).approve(_dragonDirect, type(uint256).max);
    }

    function depositTokens(uint256 _amount) external nonReentrant {
        require(_amount > 0, 'amount <= 0');
        uint256 returnAmount = _amount * returnRatio / depositRatio;
        require(returnAmount <= IERC20(returnToken).balanceOf(address(this)), 'Not enough tokens');
        IERC20(depositToken).safeTransferFrom(_msgSender(), address(this), _amount);
        uint256 bal = IERC20(returnToken).balanceOf(address(this));
        DefiMagicPolygon.nightToDmagic(IERC20(depositToken).balanceOf(address(this)));
        if (outputAddress != address(0)) {
            IERC20(returnToken).transfer(outputAddress, IERC20(returnToken).balanceOf(address(this)) - bal);
        }
        //send returnToken to user
        IERC20(returnToken).safeTransfer(_msgSender(), returnAmount);
        depositCount++;
        depositTotal += _amount;
        returnTotal += returnAmount;

        emit DepositTokens(_msgSender(), _amount, returnAmount);
    }

    function getDepositRatio() external view returns(uint256, uint256) {
        return (returnRatio, depositRatio);
    }

    function getMaximumDeposit() public view returns(uint256) {
        uint bal = IERC20(returnToken).balanceOf(address(this));
        return bal * depositRatio / returnRatio;
    }

    function getOutputAmount(uint amount_) public view returns(uint256) {
        return amount_ * returnRatio / depositRatio;
    }      

    function setTokens(address _depositToken, address _returnToken) external onlyOwner {
        require(_depositToken != address(0), '_depositToken == 0');
        require(_returnToken != address(0), '_returnToken == 0');
        depositToken = _depositToken;
        returnToken = _returnToken;
        emit SetTokens(_msgSender(), _depositToken, _returnToken);
    }    

    function setSwapRatio(uint256 _returnRatio, uint256 _depositRatio) external onlyOwner {
        returnRatio = _returnRatio;
        depositRatio = _depositRatio;
        emit SetSwapRatio(_msgSender(), _returnRatio, _depositRatio);
    }

    function setOutputAddress(address outputAddress_) external onlyOwner {
        outputAddress = outputAddress_;
    }

    function setPolygonAddresses(address dragonDirect_, address dragonDirectSushi_, address axMaticDirectSushi_) external onlyOwner {
        _setPolygonAddresses(dragonDirect_, dragonDirectSushi_, axMaticDirectSushi_);
    }    

    /*******************/
    /*  GENERAL ADMIN  */
    /*******************/

    function withdraw(address _token) external nonReentrant {
        IERC20(_token).safeTransfer(owner(), IERC20(_token).balanceOf(address(this)));
        emit Withdraw(_msgSender(), _token);
    }
    
    function withdrawETH() external onlyOwner nonReentrant {
        payable(owner()).transfer(address(this).balance);
    }

    event SetAdmins(address[] Admins);
    event DepositTokens(address msgSender, uint256 amount, uint256 returnAmount);
    event Withdraw(address msgSender, address token);
    event SetTokens(address msgSender, address depositToken, address returnToken);
    event SetSwapRatio(address msgSender, uint256 returnRatio, uint256 depositRatio);
}

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: AGPL-1.0
pragma solidity 0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IAxMaticDirectSushi.sol";
import "./interfaces/IAxMaticDirect.sol";
import "./interfaces/IDragonDirectSushi.sol";
import "./interfaces/IDragonDirect.sol";

contract DefiMagicPolygon {
    bool internal isBSC;

    // Polygon
    address internal _dragonDirectSushi = 0xD4c18Bf16Eb1e767c83E28382C4519A7736D75D8; // _dragonDirectSushi contract
    address internal _dragonDirect = 0x5a86C816dB23D5C6bcC7d051A8877Bc63CFC650C; // _dragonDirectSushi contract
    address internal _axMaticDirectSushi = 0x15aE9edB45f54beb13778f8E0df83DBC45427921; // sushiswap zapper 
    address internal _axMaticDirect = 0x7f8D518e8204702255e539236c90E9104292e8d7; // quickswap zapper

    constructor() {
        isBSC = block.chainid == 56;
    }

    function _setPolygonAddresses(address dragonDirect_, address dragonDirectSushi_, address axMaticDirectSushi_) internal virtual {
        _dragonDirectSushi = dragonDirectSushi_;
        _axMaticDirectSushi = axMaticDirectSushi_;
        _dragonDirect = dragonDirect_;
    }    

    // MATIC => DMAGIC
    function maticToDmagicSushiswap() internal  onlyPolygon {
        IAxMaticDirectSushi(_axMaticDirectSushi).easyBuy();
    }

    // MATIC => DMAGIC
    function maticToDmagicQuickswap() internal onlyPolygon {
        IAxMaticDirect(_axMaticDirect).easyBuy();
    }

    // DMAGIC => MATIC
    function dmagicToMaticSushiswap(uint256 amount_) internal onlyPolygon returns(uint256 result) {
        result = IAxMaticDirectSushi(_axMaticDirectSushi).easySell(amount_);
    }

    // DMAGIC => MATIC
    function dmagicToMaticQuickswap(uint256 amount_) internal onlyPolygon returns(uint256 result) {
        result = IAxMaticDirect(_axMaticDirect).easySell(amount_);
    }

    // MATIC => DRAX
    function maticToDrax() internal onlyPolygon {
        IDragonDirectSushi(_dragonDirectSushi).easyBuyDirect();
    }

    // DRAX => MATIC
    function draxToMatic(uint256 amount_) internal onlyPolygon {
        IDragonDirectSushi(_dragonDirectSushi).easySellToMatic(amount_);
    }       

    // DMAGIC => DRAX
    function dmagicToDrax(uint256 amount_) internal onlyPolygon {
        IDragonDirectSushi(_dragonDirectSushi).easyBuyFromDmagic(amount_);
    }
    
    // DMAGIC => DRAX
    function draxToDmagic(uint256 amount_) internal onlyPolygon {
        IDragonDirectSushi(_dragonDirectSushi).easySellTodMagic(amount_);
    }

    // MATIC => NIGHT
    function maticToNight() internal onlyPolygon {
        IDragonDirect(_dragonDirect).easyBuyDirect();
    }

    // NIGHT => MATIC
    function nightToMatic(uint256 amount_) internal onlyPolygon {
        IDragonDirect(_dragonDirect).easySellToMatic(amount_);
    }       

    // DMAGIC => NIGHT
    function dmagicToNight(uint256 amount_) internal onlyPolygon {
        IDragonDirect(_dragonDirect).easyBuyFromDmagic(amount_);
    }
    
    // NIGHT => DMAGIC
    function nightToDmagic(uint256 amount_) internal onlyPolygon {
        IDragonDirect(_dragonDirect).easySellTodMagic(amount_);
    }

    modifier onlyPolygon() {
        require(!isBSC, "Not Polygon");
        _;
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

// SPDX-License-Identifier: AGPL-1.0
pragma solidity 0.8.11;

interface IAxMaticDirectSushi {

    // estimate axMATIC => DMAGIC
    function estimateBuy(uint256 axMaticAmountIn) external view returns (uint256 darkMagicAmount);
    // estimate DMAGIC => axMATIC
    function estimateSell(uint256 darkMagicAmountIn) external view returns (uint256 ethAmount);
    // MATIC => DMAGIC
    function easyBuy() external payable returns (uint256 darkMagicAmount);
    // axMATIC => DMAGIC
    function easyBuyFromAxMatic(uint256 axMaticIn) external  returns (uint256 darkMagicAmount);
    // DMAGIC => MATIC
    function easySell(uint256 darkMagicAmountIn) external returns (uint256 axMaticAmount);
    // DMAGIC => axMATIC
    function easySellToAxMatic(uint256 darkMagicAmountIn) external returns (uint256 axMaticAmount);
    // axMATIC => DMAGIC
    function buyFromAxMatic(uint256 axMaticIn, uint256 dMagicOutMin) external returns (uint256 darkMagicAmount);
    // axMATIC => DMAGIC
    function buy(uint256 axMaticIn, uint256 dMagicOutMin) external payable returns (uint256 darkMagicAmount);
    // DMAGIC => axMATIC
    function sell(uint256 darkMagicAmountIn, uint256 axMaticOutMin) external returns (uint256 axMaticAmount);
}

// SPDX-License-Identifier: AGPL-1.0
pragma solidity 0.8.11;

interface IAxMaticDirect {

    // estimate axMATIC => DMAGIC
    function estimateBuy(uint256 axMaticAmountIn) external view returns (uint256 darkMagicAmount);
    // estimate DMAGIC => axMATIC
    function estimateSell(uint256 darkMagicAmountIn) external view returns (uint256 ethAmount);
    // MATIC => DMAGIC
    function easyBuy() external payable returns (uint256 darkMagicAmount);
    // axMATIC => DMAGIC
    function easyBuyFromAxMatic(uint256 axMaticIn) external  returns (uint256 darkMagicAmount);
    // DMAGIC => MATIC
    function easySell(uint256 darkMagicAmountIn) external returns (uint256 axMaticAmount);
    // DMAGIC => axMATIC
    function easySellToAxMatic(uint256 darkMagicAmountIn) external returns (uint256 axMaticAmount);
    // axMATIC => DMAGIC
    function buyFromAxMatic(uint256 axMaticIn, uint256 dMagicOutMin) external returns (uint256 darkMagicAmount);
    // axMATIC => DMAGIC
    function buy(uint256 axMaticIn, uint256 dMagicOutMin) external payable returns (uint256 darkMagicAmount);
    // DMAGIC => axMATIC
    function sell(uint256 darkMagicAmountIn, uint256 axMaticOutMin) external returns (uint256 axMaticAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IDragonDirectSushi {

    //  MATIC => DRAX via LP
    function easyBuy() external payable;

    //  MATIC => DRAX
    function easyBuyDirect() external payable;

    //  axMATIC => DRAX
    function easyBuyFromAxMatic(uint256) external;

    //  DMAGIC => DRAX
    function easyBuyFromDmagic(uint256 dMagicAmt) external;

    //  DMAGIC => DRAX
    function easyBuyFromDmagicDirect(uint256 dMagicAmt) external;

    //  DRAX => DMAGIC
    function easySellTodMagic(uint256 draxAmt) external;

    //  DRAX => axMATIC
    function easySellToAxMatic(uint256 draxAmt) external;

    //  DRAX => MATIC
    function easySellToMatic(uint256 draxAmt) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IDragonDirect {

    //  MATIC => NIGHT via LP
    function easyBuy() external payable;

    //  MATIC => NIGHT
    function easyBuyDirect() external payable;

    //  axMATIC => NIGHT
    function easyBuyFromAxMatic(uint256) external;

    //  DMAGIC => NIGHT
    function easyBuyFromDmagic(uint256 dMagicAmt) external;

    //  DMAGIC => NIGHT
    function easyBuyFromDmagicDirect(uint256 dMagicAmt) external;

    //  NIGHT => DMAGIC
    function easySellTodMagic(uint256 draxAmt) external;

    //  NIGHT => axMATIC
    function easySellToAxMatic(uint256 draxAmt) external;

    //  NIGHT => MATIC
    function easySellToMatic(uint256 draxAmt) external;
}