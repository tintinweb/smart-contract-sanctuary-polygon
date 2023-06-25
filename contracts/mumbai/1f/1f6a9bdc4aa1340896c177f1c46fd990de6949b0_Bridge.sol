// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Pool.sol";
import "./interfaces/IMailbox.sol";

contract Bridge is Pool {

    // address constant mailbox = 0x0E3239277501d215e17a4d31c487F86a425E110B;

    address immutable _mailbox;

    // uint32 constant avalancheDomain = 43114;
    // address constant avalancheRecipient = 0x36FdA966CfffF8a9Cdc814f546db0e6378bFef35;
    // address constant ethereumMailbox = 0x2f9DB5616fa3fAd1aB06cB2C906830BA63d135e3;

    constructor(
        address[3] memory _tokenAddresses,
        uint256[3] memory _prices,
        address _originMailbox
    ) Pool (
        _tokenAddresses,
        _prices
    ) {
        _mailbox = _originMailbox;
    }

    // for access control on handle implementations
    modifier onlyMailbox() {
        require(msg.sender == _mailbox);
        _;    
    }

    /**
     * @notice Dispatches a message to the destination domain & recipient.
     * @param _tokenToSwap Domain of destination chain
     * @param _amountToDeposit Domain of destination chain
     * @param _destinationChainId Address of recipient on destination chain as bytes32
     * @param _bridgeOnDestinationChain Raw bytes content of message body
     * @param _destinationChainRecipient the address of person we are sending tokens to on the destination chain
     * @return The message ID inserted into the Mailbox's merkle tree
     */
    function swapAndBridge(
        address _tokenToSwap,
        address _outputToken,
        uint256 _amountToDeposit,
        uint32 _destinationChainId,
        address _bridgeOnDestinationChain,
        address _destinationChainRecipient
    ) external returns (bytes32) {

        // deposit amountToDeposit of tokenToSwap in Pool.sol

        bytes32 response = IMailbox(_mailbox).dispatch(
            _destinationChainId,
            _addressToBytes32(_bridgeOnDestinationChain),
            bytes(abi.encode(_tokenToSwap, _outputToken, _amountToDeposit, _destinationChainRecipient))
        );

        deposit(_tokenToSwap, _amountToDeposit);

        return response;

    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _body
    ) external onlyMailbox {

        (address inputToken, address outputToken, uint256 amount, address recipient) = abi.decode(_body, (address, address, uint256, address));

        withdraw(inputToken, outputToken, amount, recipient);
    
    }

    function _addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Pool {

    mapping(address => uint256) private tokenPrices;

    constructor(
        address[3] memory tokenAddresses,
        uint256[3] memory prices
    ) {

        require(tokenAddresses.length == prices.length, "tokenAddresses and prices must be the same length");

        for (uint256 i = 0; i < tokenAddresses.length; i++) {

            setTokenPrice(tokenAddresses[i], prices[i]);

        }

    }

    function setTokenPrice(address tokenAddress, uint256 price) internal {

        tokenPrices[tokenAddress] = price;

    }

    function deposit(address tokenAddress, uint256 amount) internal {

        IERC20 token = IERC20(tokenAddress);

        token.transferFrom(msg.sender, address(this), amount);

    }    

    function withdraw(address inputToken, address outputToken, uint256 amount, address recipient) internal {

        require(tokenPrices[inputToken] > 0, "Input token price not set");

        require(tokenPrices[outputToken] > 0, "Output token price not set");

        uint256 inputTokenPrice = tokenPrices[inputToken];

        uint256 outputTokenPrice = tokenPrices[outputToken];

        uint256 outputAmount = (amount * inputTokenPrice) / outputTokenPrice;
        
        IERC20 outputTokenContract = IERC20(outputToken);

        outputTokenContract.transfer(recipient, outputAmount);

    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IMailbox {

    /**
     * @notice Dispatches a message to the destination domain & recipient.
     * @param _destination Domain of destination chain
     * @param _recipient Address of recipient on destination chain as bytes32
     * @param _body Raw bytes content of message body
     * @return The message ID inserted into the Mailbox's merkle tree
     */
    function dispatch(
        uint32 _destination,
        bytes32 _recipient,
        bytes calldata _body
    ) external returns (bytes32);

    function process(
        bytes calldata _metadata,
        bytes calldata _message
    ) external;
}