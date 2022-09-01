// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@zetachain/contracts/packages/protocol-contracts/contracts/ZetaInteractor.sol";
import "@zetachain/contracts/packages/protocol-contracts/contracts/interfaces/ZetaInterfaces.sol";

import "./GoerliMumbaiSwapErrors.sol";

/**
 * Goerli-to-Mumbai swap via 0x API
 */
contract GoerliMumbaiSwap is ZetaInteractor, ZetaReceiver, GoerliMumbaiSwapErrors, Pausable {
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    bytes32 private constant SWAP_MESSAGE = keccak256("GOERLI_MUMBAI_SWAP");

    address public immutable iZetaToken;
    address public immutable iZeroxExchangeProxy;

    // Events
    event FirstLegSuccess(address sellToken, uint256 sellAmount, uint256 zetaAmount);
    event SecondLegSuccess(address buyToken, uint256 buyAmount, uint256 zetaAmount);
    event FirstLegReverted(address receiver, address buyToken, uint256 zetaAmount);

    // Input arguments
    struct XcSwapTokenArgs {
        uint256 zetaAmount;
        bytes firstLegSwapCallData;
        uint256 sellAmount;
        bytes secondLegSwapCallData;
        address payable buyTokenAddress;
        address payable sellTokenAddress;
        uint256 destinationChainId;
        uint256 destinationGasLimit;
    }

    constructor(
        address _zetaConnector,
        address _zetaTokenInput,
        address _zeroxExchangeProxyInput
    ) ZetaInteractor(_zetaConnector) {
        iZetaToken = _zetaTokenInput;
        iZeroxExchangeProxy = _zeroxExchangeProxyInput;
    }

    /// @dev Allows this contract to receive ether.
    receive() external payable {}

    function xcSwap(XcSwapTokenArgs calldata args) external payable whenNotPaused {
        // Validate destination `chainID`
        if (keccak256(interactorsByChainId[args.destinationChainId]) == keccak256(new bytes(0)))
            revert InvalidDestinationChainId();

        // Input token validation
        if (args.sellTokenAddress == address(0) || args.sellTokenAddress == iZetaToken)
            revert InvalidTokenAddress();

        // Transferring ETH
        if (args.sellTokenAddress != ETH_ADDRESS) {
            // Transfer `sellToken` to this contract from sender
            IERC20 sellToken = IERC20(args.sellTokenAddress);
            if (!sellToken.transferFrom(msg.sender, address(this), args.sellAmount))
                revert ErrorTransferringTokens(args.sellTokenAddress);

            // Give `0xExchangeProxy` allowance to spend this contract's `sellToken`.
            if (!sellToken.approve(iZeroxExchangeProxy, args.sellAmount))
                revert ErrorApprovingTokens(args.sellTokenAddress);
        }

        // Call 1st leg 0x Swap - should buy ZETA
        (bool success, ) = iZeroxExchangeProxy.call{value: msg.value}(args.firstLegSwapCallData);
        if (!success) revert BuyZetaFailed();

        // Approve ZETA
        if (!IERC20(iZetaToken).approve(address(connector), args.zetaAmount))
            revert ErrorApprovingTokens(iZetaToken);

        // Send message
        connector.send(
            // TODO Also pass revert leg params
            ZetaInterfaces.SendInput({
                destinationChainId: args.destinationChainId,
                destinationAddress: interactorsByChainId[args.destinationChainId],
                destinationGasLimit: args.destinationGasLimit,
                message: abi.encode(
                    SWAP_MESSAGE,
                    msg.sender,
                    args.buyTokenAddress,
                    args.secondLegSwapCallData
                ),
                zetaValueAndGas: args.zetaAmount,
                zetaParams: abi.encode("")
            })
        );

        // Emit success event
        emit FirstLegSuccess(args.sellTokenAddress, args.sellAmount, args.zetaAmount);
    }

    function onZetaMessage(ZetaInterfaces.ZetaMessage calldata zetaMessage)
        external
        override
        isValidMessageCall(zetaMessage)
        whenNotPaused
    {
        // Decode incoming message
        (
            bytes32 messageType,
            address payable receiverAddress,
            address payable buyTokenAddress,
            bytes memory secondLegSwapCallData
        ) = abi.decode(zetaMessage.message, (bytes32, address, address, bytes));

        // Validate message
        if (messageType != SWAP_MESSAGE) revert InvalidMessageType();
        if (secondLegSwapCallData.length == 0) revert InvalidCallData();
        if (buyTokenAddress == address(0) || buyTokenAddress == iZetaToken)
            revert InvalidTokenAddress();

        // Give `0xExchangeProxy` an allowance to spend tranferred ZETA.
        IERC20 zetaToken = IERC20(iZetaToken);
        if (!zetaToken.approve(iZeroxExchangeProxy, zetaMessage.zetaValue))
            revert ErrorApprovingTokens(iZetaToken);

        // Call 2nd leg 0x Swap - should sell ZETA
        (bool success, ) = iZeroxExchangeProxy.call{value: 0}(secondLegSwapCallData);
        if (!success) revert SellZetaFailed();

        // Transfer purchased ETH/tokens to original sender
        uint256 buyAmount = 0;
        if (buyTokenAddress == ETH_ADDRESS) {
            buyAmount = address(this).balance;
            if (!receiverAddress.send(buyAmount)) revert ErrorTransferringEther();
        } else {
            IERC20 buyToken = IERC20(buyTokenAddress);
            buyAmount = buyToken.balanceOf(address(this));
            bool tokenTransfer = buyToken.transfer(receiverAddress, buyAmount);
            if (!tokenTransfer) revert ErrorTransferringTokens(buyTokenAddress);
        }

        // Emit success event
        emit SecondLegSuccess(buyTokenAddress, buyAmount, zetaMessage.zetaValue);
    }

    function onZetaRevert(ZetaInterfaces.ZetaRevert calldata zetaRevert)
        external
        override
        isValidRevertCall(zetaRevert)
        whenNotPaused
    {
        // Decode incoming message
        (
            bytes32 messageType,
            address receiverAddress,
            address payable buyTokenAddress,
            bytes memory secondLegSwapCallData
        ) = abi.decode(zetaRevert.message, (bytes32, address, address, bytes));

        // Validate message
        if (messageType != SWAP_MESSAGE) revert InvalidMessageType();
        if (secondLegSwapCallData.length == 0) revert InvalidCallData();

        // Emit revert event
        emit FirstLegReverted(receiverAddress, buyTokenAddress, zetaRevert.remainingZetaValue);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ZetaInterfaces.sol";
import "./interfaces/ZetaInteractorErrors.sol";

abstract contract ZetaInteractor is Ownable, ZetaInteractorErrors {
    bytes32 constant ZERO_BYTES = keccak256(new bytes(0));
    uint256 internal immutable currentChainId;
    ZetaConnector public immutable connector;

    /**
     * @dev Maps a chain id to its corresponding address of the MultiChainSwap contract
     * The address is expressed in bytes to allow non-EVM chains
     * This mapping is useful, mainly, for two reasons:
     *  - Given a chain id, the contract is able to route a transaction to its corresponding address
     *  - To check that the messages (onZetaMessage, onZetaRevert) come from a trusted source
     */
    mapping(uint256 => bytes) public interactorsByChainId;

    modifier isValidMessageCall(ZetaInterfaces.ZetaMessage calldata zetaMessage) {
        _isValidCaller();
        if (keccak256(zetaMessage.zetaTxSenderAddress) != keccak256(interactorsByChainId[zetaMessage.sourceChainId]))
            revert InvalidZetaMessageCall();
        _;
    }

    modifier isValidRevertCall(ZetaInterfaces.ZetaRevert calldata zetaRevert) {
        _isValidCaller();
        if (zetaRevert.zetaTxSenderAddress != address(this)) revert InvalidZetaRevertCall();
        if (zetaRevert.sourceChainId != currentChainId) revert InvalidZetaRevertCall();
        _;
    }

    constructor(address zetaConnectorAddress) {
        currentChainId = block.chainid;
        connector = ZetaConnector(zetaConnectorAddress);
    }

    function _isValidCaller() private view {
        if (msg.sender != address(connector)) revert InvalidCaller(msg.sender);
    }

    /**
     * @dev Useful for contracts that inherit from this one
     */
    function _isValidChainId(uint256 chainId) internal view returns (bool) {
        return (keccak256(interactorsByChainId[chainId]) != ZERO_BYTES);
    }

    function setInteractorByChainId(uint256 destinationChainId, bytes calldata contractAddress) external onlyOwner {
        interactorsByChainId[destinationChainId] = contractAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ZetaInterfaces {
    /**
     * @dev Use SendInput to interact with the Connector: connector.send(SendInput)
     */
    struct SendInput {
        /// @dev Chain id of the destination chain. More about chain ids https://docs.zetachain.com/learn/glossary#chain-id
        uint256 destinationChainId;
        /// @dev Address receiving the message on the destination chain (expressed in bytes since it can be non-EVM)
        bytes destinationAddress;
        /// @dev Gas limit for the destination chain's transaction
        uint256 destinationGasLimit;
        /// @dev An encoded, arbitrary message to be parsed by the destination contract
        bytes message;
        /// @dev ZETA to be sent cross-chain + ZetaChain gas fees + destination chain gas fees (expressed in ZETA)
        uint256 zetaValueAndGas;
        /// @dev Optional parameters for the ZetaChain protocol
        bytes zetaParams;
    }

    /**
     * @dev Our Connector calls onZetaMessage with this struct as argument
     */
    struct ZetaMessage {
        bytes zetaTxSenderAddress;
        uint256 sourceChainId;
        address destinationAddress;
        /// @dev Remaining ZETA from zetaValueAndGas after subtracting ZetaChain gas fees and destination gas fees
        uint256 zetaValue;
        bytes message;
    }

    /**
     * @dev Our Connector calls onZetaRevert with this struct as argument
     */
    struct ZetaRevert {
        address zetaTxSenderAddress;
        uint256 sourceChainId;
        bytes destinationAddress;
        uint256 destinationChainId;
        /// @dev Equals to: zetaValueAndGas - ZetaChain gas fees - destination chain gas fees - source chain revert tx gas fees
        uint256 remainingZetaValue;
        bytes message;
    }
}

interface ZetaConnector {
    /**
     * @dev Sending value and data cross-chain is as easy as calling connector.send(SendInput)
     */
    function send(ZetaInterfaces.SendInput calldata input) external;
}

interface ZetaReceiver {
    /**
     * @dev onZetaMessage is called when a cross-chain message reaches a contract
     */
    function onZetaMessage(ZetaInterfaces.ZetaMessage calldata zetaMessage) external;

    /**
     * @dev onZetaRevert is called when a cross-chain message reverts.
     * It's useful to rollback to the original state
     */
    function onZetaRevert(ZetaInterfaces.ZetaRevert calldata zetaRevert) external;
}

/**
 * @dev ZetaTokenConsumer makes it easier to handle the following situations:
 *   - Getting Zeta using native coin (to pay for destination gas while using `connector.send`)
 *   - Getting Zeta using a token (to pay for destination gas while using `connector.send`)
 *   - Getting native coin using Zeta (to return unused destination gas when `onZetaRevert` is executed)
 *   - Getting a token using Zeta (to return unused destination gas when `onZetaRevert` is executed)
 * @dev The interface can be implemented using different strategies, like UniswapV2, UniswapV3, etc
 */
interface ZetaTokenConsumer {
    event EthExchangedForZeta(uint256 amountIn, uint256 amountOut);
    event TokenExchangedForZeta(address token, uint256 amountIn, uint256 amountOut);
    event ZetaExchangedForEth(uint256 amountIn, uint256 amountOut);
    event ZetaExchangedForToken(address token, uint256 amountIn, uint256 amountOut);

    function getZetaFromEth(address destinationAddress, uint256 minAmountOut) external payable returns (uint256);

    function getZetaFromToken(
        address destinationAddress,
        uint256 minAmountOut,
        address inputToken,
        uint256 inputTokenAmount
    ) external returns (uint256);

    function getEthFromZeta(
        address destinationAddress,
        uint256 minAmountOut,
        uint256 zetaTokenAmount
    ) external returns (uint256);

    function getTokenFromZeta(
        address destinationAddress,
        uint256 minAmountOut,
        address outputToken,
        uint256 zetaTokenAmount
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface GoerliMumbaiSwapErrors {
    error ErrorTransferringTokens(address token);

    error ErrorTransferringEther();

    error ErrorApprovingTokens(address token);

    error InvalidMessageType();

    error InvalidCallTarget();

    error InvalidCallData();

    error InvalidTokenAddress();

    error BuyZetaFailed();

    error SellZetaFailed();

    error NotImplemented();
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
pragma solidity 0.8.7;

interface ZetaInteractorErrors {
    error InvalidDestinationChainId();

    error InvalidCaller(address caller);

    error InvalidZetaMessageCall();

    error InvalidZetaRevertCall();
}