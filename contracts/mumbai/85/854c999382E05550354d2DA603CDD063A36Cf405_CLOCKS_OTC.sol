// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/Timer.sol";
import "./libraries/Whitelist.sol";

contract CLOCKS_OTC is Pausable, ReentrancyGuard, WhiteList {
    using SafeERC20 for IERC20;

    //=====Access_Management=====//
    address public owner;
    address public treasury;

    //=====Token=====//
    IERC20 public OTHER_token;
    IERC20 public CLK_token;

    uint256 public one_CLK_token;

    //=====Transaction_configuration=====//
    Timer.Window public transactionWindow;

    uint256 public buyRate;
    uint256 public sellRate;
    uint256 public maxBuyAmountCLK;
    uint256 public maxSellAmountCLK;

    //=====Events=====//

    // TransactionWindowChanged is emitted from the Timer library. But to emit the event,
    // it should also be defined in the contract here.
    event TransactionWindowChanged(
        uint256 oldStart,
        uint256 oldStop,
        uint256 newStart,
        uint256 newStop
    );
    event BuyEvent(uint256 amountUSDC, uint256 amountCLK, address buyerAddress);
    event SellEvent(
        uint256 amountCLK,
        uint256 amountUSDC,
        address sellerAddress
    );
    event BuyRateChanged(uint256 oldRate, uint256 newRate);
    event SellRateChanged(uint256 oldRate, uint256 newRate);
    event MaxBuyAmountClkChanged(uint256 oldMax, uint256 newMax);
    event MaxSellAmountClkChanged(uint256 oldMax, uint256 newMax);
    event OwnershipTransfered(address oldOwner, address newOwner);
    event TreasuryAddressTransfered(address oldTreasury, address newTreasury);
    event WithdrawnCLK(address from, address to, uint256 amount);
    event WithdrawnOTHER(address from, address to, uint256 amount);

    constructor(
        address ownerAddress,
        address treasuryAddress,
        address otherTokenAddress,
        address clkTokenAddress,
        uint256 initialBuyRate,
        uint256 initialSellRate,
        uint256 initialMaxBuyAmountCLK,
        uint256 initialMaxSellAmountCLK
    ) Pausable() {
        require(ownerAddress != address(0), "Owner can't be address 0");
        require(treasuryAddress != address(0), "Treasury can't be address 0");
        require(otherTokenAddress != address(0), "OTHER can't be address 0");
        require(clkTokenAddress != address(0), "CLK can't be address 0");
        require(initialBuyRate > 0, "buyRate should be >0");
        require(initialSellRate > 0, "sellRate should be >0");

        OTHER_token = IERC20(otherTokenAddress);
        CLK_token = IERC20(clkTokenAddress);

        one_CLK_token = 10**18;

        transactionWindow.startTime = 0;
        transactionWindow.stopTime = 0;

        owner = ownerAddress;
        treasury = treasuryAddress;

        buyRate = initialBuyRate;
        sellRate = initialSellRate;
        maxBuyAmountCLK = initialMaxBuyAmountCLK;
        maxSellAmountCLK = initialMaxSellAmountCLK;
    }

    //=====Modifiers=====//

    modifier onlyOwnerRole() {
        require(owner == msg.sender, "Caller != owner");
        _;
    }

    modifier windowIsOpen() {
        require(
            Timer.currentTimeIsInWindow(transactionWindow),
            "Buy/sell window closed"
        );
        _;
    }

    //=====Functions=====//

    //-----Transaction-----//
    /// @notice A user buys CLK tokens with another token.
    /// @param amountCLK: The amount of CLK tokens to buy in the smallest unit.
    function buy(uint256 amountCLK, bytes32[] calldata proof)
        external
        nonReentrant
        whenNotPaused
        windowIsOpen
    {
        require(
            !whitelistIsActive || verifyMerkleProof(proof, msg.sender),
            "Address not whitelisted"
        );
        require(amountCLK <= maxBuyAmountCLK, "amountCLK > maxBuyAmountCLK");
        require(
            CLK_token.balanceOf(treasury) >= amountCLK,
            "Not enough CLK available"
        );

        address buyer = msg.sender;

        uint256 amountOTHER = (amountCLK * buyRate) / one_CLK_token;
        require(
            OTHER_token.balanceOf(buyer) >= amountOTHER,
            "You don't have enough OTHER"
        );

        OTHER_token.safeTransferFrom(buyer, treasury, amountOTHER);
        CLK_token.safeTransferFrom(treasury, buyer, amountCLK);

        emit BuyEvent(amountOTHER, amountCLK, buyer);
    }

    /// @notice A user sells CLK tokens and receives another token.
    /// @param amountCLK: The amount of CLK tokens to buy in the smallest unit.
    function sell(uint256 amountCLK, bytes32[] memory proof)
        external
        nonReentrant
        whenNotPaused
        windowIsOpen
    {
        require(
            !whitelistIsActive || verifyMerkleProof(proof, msg.sender),
            "Address not whitelisted"
        );
        require(amountCLK <= maxSellAmountCLK, "amountCLK > maxSellAmountCLK");

        address seller = msg.sender;
        require(
            CLK_token.balanceOf(seller) >= amountCLK,
            "You don't have enough CLK"
        );

        uint256 amountOTHER = (amountCLK * sellRate) / one_CLK_token;
        require(
            OTHER_token.balanceOf(treasury) >= amountOTHER,
            "Not enough OTHER available"
        );

        CLK_token.safeTransferFrom(seller, treasury, amountCLK);
        OTHER_token.safeTransferFrom(treasury, seller, amountOTHER);

        emit SellEvent(amountCLK, amountOTHER, seller);
    }

    function withdrawCLK() external nonReentrant onlyOwnerRole {
        uint256 balance = CLK_token.balanceOf(treasury);
        CLK_token.safeTransferFrom(treasury, owner, balance);

        emit WithdrawnCLK(treasury, owner, balance);
    }

    function withdrawOTHER() external nonReentrant onlyOwnerRole {
        uint256 balance = OTHER_token.balanceOf(treasury);
        OTHER_token.safeTransferFrom(treasury, owner, balance);

        emit WithdrawnOTHER(treasury, owner, balance);
    }

    //-----Cofiguration-----//

    function pauseContract() external onlyOwnerRole {
        _pause();
    }

    function unpauseContract() external onlyOwnerRole {
        _unpause();
    }

    function setTransactionWindow(uint256 startTime, uint256 stopTime)
        external
        onlyOwnerRole
    {
        Timer.setWindow(transactionWindow, startTime, stopTime);
    }

    function getMinimumTransactionWindow() external pure returns (uint256) {
        return Timer.minimumWindowDuration;
    }

    /// @param other_clk_rate: How many of the other token in the smallest unit is needed for 1 CLOCKS token.
    function setBuyRate(uint256 other_clk_rate) external onlyOwnerRole {
        require(other_clk_rate > 0, "Buy rate should be >0");

        uint256 oldRate = buyRate;
        buyRate = other_clk_rate;

        emit BuyRateChanged(oldRate, other_clk_rate);
    }

    /// @param other_clk_rate: how many of the other token in the smallest unit is needed for 1 CLOCKS token.
    function setSellRate(uint256 other_clk_rate) external onlyOwnerRole {
        require(other_clk_rate > 0, "Sell rate should be >0");

        uint256 oldRate = sellRate;
        sellRate = other_clk_rate;

        emit SellRateChanged(oldRate, other_clk_rate);
    }

    function setMaxBuyAmountCLK(uint256 newMaxBuyAmountCLK)
        external
        onlyOwnerRole
    {
        uint256 oldMaxAmountCLK = maxBuyAmountCLK;
        maxBuyAmountCLK = newMaxBuyAmountCLK;

        emit MaxBuyAmountClkChanged(oldMaxAmountCLK, newMaxBuyAmountCLK);
    }

    function setMaxSellAmountCLK(uint256 newMaxSellAmountCLK)
        external
        onlyOwnerRole
    {
        uint256 oldMaxAmountCLK = maxSellAmountCLK;
        maxSellAmountCLK = newMaxSellAmountCLK;

        emit MaxSellAmountClkChanged(oldMaxAmountCLK, newMaxSellAmountCLK);
    }

    //-----Ownership-----//

    function updateOwner(address newOwner) external onlyOwnerRole {
        require(newOwner != address(0), "newOwner != 0");

        address oldOwner = owner;
        owner = newOwner;

        emit OwnershipTransfered(oldOwner, owner);
    }

    function updateTreasury(address newTreasury) external onlyOwnerRole {
        require(newTreasury != address(0), "newTreasury != 0");

        address oldTreasury = treasury;
        treasury = newTreasury;

        emit TreasuryAddressTransfered(oldTreasury, treasury);
    }

    function flipWhitelistIsActive() public override onlyOwnerRole {
        _flipWhitelistIsActive();
    }

    function setMerkleRoot(bytes32 newMerkleRoot)
        public
        override
        onlyOwnerRole
    {
        _setMerkleRoot(newMerkleRoot);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
pragma solidity ^0.8.4;
pragma abicoder v2;

library Timer {
    //=====Structs=====//
    struct Window {
        uint256 startTime;
        uint256 stopTime;
    }

    //=====Variables=====//
    // https://cryptomarketpool.com/block-timestamp-manipulation-attack/ 15 second rule
    uint256 public constant minimumWindowDuration = 20;

    //=====Events=====//
    event TransactionWindowChanged(
        uint256 oldStart,
        uint256 oldStop,
        uint256 newStart,
        uint256 newStop
    );

    //=====Functions=====//

    /// @param startTime: The amount of seconds since unix epoch till the start time
    /// @param stopTime: The amount of seconds since unix epoch till the stop time
    function setWindow(
        Window storage windowToSet,
        uint256 startTime,
        uint256 stopTime
    ) internal {
        require(stopTime > startTime, "stopTime <= startTime");
        require(
            (stopTime - startTime) >= minimumWindowDuration,
            "Window < minimumWindowDuration"
        );

        uint256 oldStartTime = windowToSet.startTime;
        uint256 oldStopTime = windowToSet.stopTime;

        windowToSet.startTime = startTime;
        windowToSet.stopTime = stopTime;

        emit TransactionWindowChanged(
            oldStartTime,
            oldStopTime,
            startTime,
            stopTime
        );
    }

    /// @notice This function checks if block.timestamp is within the given window.
    ///          The value block.timestamp can have around 15 seconds of slack since
    ///          miners can have an influence on the timestamp.
    /// @param window: The window for which block.timestamp is checked.
    function currentTimeIsInWindow(Window memory window)
        internal
        view
        returns (bool)
    {
        uint256 currentTime = block.timestamp;

        return ((currentTime >= window.startTime) &&
            (currentTime <= window.stopTime));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

/**
    To use this contract all you have to do is implement the virtual funcs  
    The gist of those implementations is already done in internal funcs
    All you have to do is use these, and set the required access-control :)
 */

interface IWhiteList {
    event MerkleRootSet(bytes32 newMerkeRoot);
    event FlipWhitelistIsActive();

    // Virtual so you can set an onlyOwner
    function flipWhitelistIsActive() external;

    // Be sure to lock access!
    function setMerkleRoot(bytes32 newMerkleRoot) external;

    function verifyMerkleProof(bytes32[] memory proof, address leafAddress)
        external
        view
        returns (bool);
}

abstract contract WhiteList is IWhiteList {
    bytes32 public merkleRoot = keccak256(abi.encodePacked(uint256(0)));
    bool public whitelistIsActive = true;

    // Virtual so you can set an onlyOwner
    function _flipWhitelistIsActive() internal {
        whitelistIsActive = !whitelistIsActive;
        emit FlipWhitelistIsActive();
    }

    // Be sure to lock access!
    function _setMerkleRoot(bytes32 newMerkleRoot) internal {
        require(
            newMerkleRoot != keccak256(abi.encodePacked(uint256(0))),
            'Merkle root cannot be 0'
        );
        merkleRoot = newMerkleRoot;
        emit MerkleRootSet(newMerkleRoot);
    }

    function verifyMerkleProof(bytes32[] memory proof, address leafAddress)
        public
        view
        override
        returns (bool)
    {
        require(
            merkleRoot != keccak256(abi.encodePacked(uint256(0))),
            'Merkle root not set'
        );
        bytes32 leaf = keccak256(abi.encodePacked(leafAddress));
        return MerkleProof.verify(proof, merkleRoot, leaf);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}