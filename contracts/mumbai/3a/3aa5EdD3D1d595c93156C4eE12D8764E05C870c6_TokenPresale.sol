// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
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
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

/**
@title presale contract by d3Launch 
@author https://gitlab.com/directo3Inc
@notice This preslae Contract is part of directo3Inc Ecosystem
*/
contract TokenPresale is ReentrancyGuard, Ownable {
    event Purchase(address indexed buyer, uint256 amount); // event to emit when a purchase is made

    struct Presale {
        IERC20 token;
        uint256 startTime; // start time of the presale
        uint256 endTime; // end time of the presale
        uint256 tokenPrice; // price of one token in wei
        uint256 minPurchaseAmount; // minimum purchase amount in wei
        uint256 maxPurchaseAmount; // maximum purchase amount in wei
        uint256 liquidityLock; // percentage of liquidityLock
        uint256 liquidityLockPeriod; // period of liquidityLock
    }

    struct Vesting {
        uint256 cycle; // period of one vesting cycle
        uint256 releasePercentage; // percentage to release each cycle
        uint256 period; // total vesting period
    }

    Presale public presale;
    Vesting public vesting;

    IERC20 public immutable DRTP; // DRTP address
    address public immutable D3VAULT; // payment splitter address
    bool public preSaleFundsWithdrawn;
    uint256 public totalTokensSold; // total number of tokens sold

    mapping(address => uint256) public purchasedTokens; // mapping of addresses to their purchased token amount
    mapping(address => uint256) public claimedVestedTokens; // mapping of addresses to their claimed vested tokens
    address[] public investors; // list of investors and key value of purchasedTokens mapping

    bool private presaleSetupDone;
    bool private isPancake;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    constructor(
        bool feeInDRTP,
        IERC20 _drtp,
        address _d3Vault,
        uint256 fee
    ) payable {
        DRTP = _drtp;
        D3VAULT = _d3Vault;

        if (feeInDRTP) {
            DRTP.transferFrom(msg.sender, D3VAULT, fee);
        } else {
            Address.sendValue(payable(D3VAULT), fee);
        }
    }

    //==================  External Functions    ==================//

    function setupPresale(
        Presale memory _presale,
        Vesting memory _vesting,
        bool _isPancake
    ) external nonReentrant {
        require(presaleSetupDone == false, "Setup done already");
        presaleSetupDone = true;
        isPancake = _isPancake;

        require(
            _presale.liquidityLock <= 100,
            "liquidityLock greater than 100"
        );
        require(
            _presale.liquidityLockPeriod > 0,
            "liquidityLockPeriod less than block time"
        );
        require(
            _vesting.releasePercentage <= 100,
            "releasePercentage greater than 100"
        );
        require(_vesting.cycle != 0, "vesting.cycle cannot be 0");
        require(_vesting.period != 0, "vesting.period cannot be 0");
        presale = Presale({
            liquidityLock: _presale.liquidityLock,
            liquidityLockPeriod: _presale.liquidityLockPeriod,
            token: _presale.token,
            startTime: _presale.startTime,
            endTime: _presale.endTime,
            tokenPrice: _presale.tokenPrice,
            minPurchaseAmount: _presale.minPurchaseAmount,
            maxPurchaseAmount: _presale.maxPurchaseAmount
        });

        vesting = Vesting({
            cycle: _vesting.cycle,
            releasePercentage: _vesting.releasePercentage,
            period: _vesting.period
        });
    }

    function purchaseTokens() external payable nonReentrant {
        require(this.presaleIsActive(), "Presale not active");
        require(
            msg.value >= presale.minPurchaseAmount &&
                msg.value <= presale.maxPurchaseAmount,
            "Invalid purchase amount"
        );

        // %2 investor fee to D3VAULT
        Address.sendValue(payable(D3VAULT), (msg.value * 2) / 100);

        uint256 amount = (msg.value - ((msg.value * 2) / 100)) /
            presale.tokenPrice;
        require(
            presale.token.balanceOf(address(this)) - totalTokensSold >= amount,
            "Insufficient token balance in presale contract"
        );
        totalTokensSold += amount;
        if (purchasedTokens[msg.sender] == 0) {
            investors.push(msg.sender);
        }
        purchasedTokens[msg.sender] += amount;
        emit Purchase(msg.sender, amount);
    }

    //==================  Administrative Functions    ==================//

    function withdrawFunds() external nonReentrant onlyOwner {
        require(preSaleFundsWithdrawn == false, "Funds already withdrawn");

        require(presaleIsActive() == false, "Presale Is Active");

        preSaleFundsWithdrawn = true;

        uint256 contractBalance = address(this).balance;
        // 4% fee to D3VAULT
        Address.sendValue(payable(D3VAULT), (contractBalance * 4) / 100);

        contractBalance = contractBalance - ((contractBalance * 4) / 100);

        contractBalance =
            contractBalance -
            ((contractBalance * presale.liquidityLock) / 100);

        // sending funds excluding liquidity lock amount to presale owner
        Address.sendValue(payable(owner()), contractBalance);

        // sending non sold tokens back to presale owner
        uint256 remainingTokens = presale.token.balanceOf(address(this)) -
            totalTokensSold;
        if (remainingTokens > 0)
            presale.token.transfer(owner(), remainingTokens);
    }

    function withdrawLockedFunds() external nonReentrant onlyOwner {
        // require(
        //     block.timestamp >= presale.liquidityLockPeriod + presale.endTime,
        //     "Liquidity Lock Time Active"
        // );

        if (isPancake) {
            uniswapV2Router = IUniswapV2Router02(
                // 0x10ED43C718714eb63d5aA57B78B54704E256024E // Router address of Pancakeswap
                0xD99D1c33F9fC3444f8101754aBC46c52416550D1 // Router address of Pancakeswap testnet
            );
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(presale.token), uniswapV2Router.WETH());
            uniswapV2Router.addLiquidityETH{value: address(this).balance}(
                address(presale.token),
                0,
                0,
                0,
                owner(),
                block.timestamp
            );
        }

        // Address.sendValue(payable(msg.sender), address(this).balance);
    }

    //==================  Public Functions    ==================//

    function claim() public {
        require(purchasedTokens[msg.sender] > 0, "Not an investor");
        uint256 totalClaimableNow = claimableTokens();
        claimedVestedTokens[msg.sender] += totalClaimableNow;
        presale.token.transfer(msg.sender, totalClaimableNow);
    }

    //==================  Read only Functions    ==================//

    function claimableTokens() public view returns (uint256) {
        require(
            block.timestamp >= presale.endTime + vesting.period,
            "Vesting still locked"
        );
        uint256 totalTokensInvestorShouldHaveClaimed = ((purchasedTokens[
            msg.sender
        ] * vesting.releasePercentage) / 100) * currentVestingCycle();

        if (
            totalTokensInvestorShouldHaveClaimed > purchasedTokens[msg.sender]
        ) {
            totalTokensInvestorShouldHaveClaimed = purchasedTokens[msg.sender];
        }

        return
            totalTokensInvestorShouldHaveClaimed -
            claimedVestedTokens[msg.sender];
    }

    function presaleIsActive() public view returns (bool) {
        return
            block.timestamp >= presale.startTime &&
                block.timestamp <= presale.endTime
                ? true
                : false;
    }

    function totalInvestors() public view returns (uint256) {
        return investors.length;
    }

    function currentVestingCycle() public view returns (uint256) {
        return (block.timestamp - presale.endTime) / vesting.cycle;
    }

    //==================  Internal Functions    ==================//
}