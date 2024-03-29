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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVault {
    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }

    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

    function getPoolTokens(
        bytes32 poolId
    ) external view returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);
}

interface IMailbox {
    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external returns (bytes32);
}

interface IInterchainGasPaymaster {
    function payForGas(
        bytes32 _messageId,
        uint32 _destinationDomain,
        uint256 _gasAmount,
        address _refundAddress
    ) external payable;

    function quoteGasPayment(uint32 _destinationDomain, uint256 _gasAmount) external view returns (uint256);
}

contract CarbonCreditCalculator {
    uint256 private constant _SCALING_FACTOR = 1e18;

    uint16 private constant _POLYGON_CHAIN_ID = 137;

    address public constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    // In principal we could have multiple pools, but with different types, etc., each one might be different
    // So hard-code the most important one
    bytes32 public constant BALANCER_BCT_POOL_ID = 0x16faf9f73748013155b7bc116a3008b57332d1e600020000000000000000006d;

    // The list of carbon tokens we are measuring; would be different addresses on different chains
    IERC20[] private _carbonTokens;

    // Their relative weights (e.g., tons per token). This is an 18-decimal floating point value.
    uint256[] private _tokenWeights;

    uint16 private immutable _chainId;

    // Hyperlane integration. Send token balances to an L2 for cross-chain Dapps.
    IMailbox private immutable _mailbox;

    IInterchainGasPaymaster private immutable _gasPaymaster;

    event TotalCarbonCreditsSent(address indexed user, uint32 chainId, address recipient);

    /**
     * @dev Error thrown if you try to look at the zero address
     */
    error InvalidAddress();

    /**
     * @dev Error thrown if tokens and weight arrays do not match.
     */
    error InputLengthMismatch();

    constructor(
        uint16 chainId,
        IMailbox hyperlaneMailbox,
        IInterchainGasPaymaster gasPaymaster,
        IERC20[] memory carbonTokens,
        uint256[] memory tokenWeights
    ) {
        if (carbonTokens.length != tokenWeights.length) {
            revert InputLengthMismatch();
        }

        _chainId = chainId;
        _mailbox = hyperlaneMailbox;
        _gasPaymaster = gasPaymaster;

        if (carbonTokens.length > 0) {
            _carbonTokens = new IERC20[](carbonTokens.length);
            _tokenWeights = new uint256[](carbonTokens.length);

            for (uint256 i = 0; i < carbonTokens.length; i++) {
                _carbonTokens[i] = carbonTokens[i];
                _tokenWeights[i] = tokenWeights[i];
            }
        }
    }

    /**
     * @dev Check the wallet, internal balance, and pool for tokens
     * @param user - the account we are checking for credits
     */
    function getTotalCarbonCredits(address user) public view returns (uint256) {
        if (user == address(0)) {
            revert InvalidAddress();
        }

        uint256 poolBalance;

        // Are they an LP in the pool? This pool is on Polygon Mainnet
        if (_chainId == _POLYGON_CHAIN_ID) {
            (address poolAddress, ) = IVault(BALANCER_VAULT).getPool(BALANCER_BCT_POOL_ID);

            uint256 bptBalance = IERC20(poolAddress).balanceOf(user);

            if (bptBalance > 0) {
                uint256 totalSupply = IERC20(poolAddress).totalSupply();

                // This is an immutable 50/50 pool with USDC/BCT - BCT is the 2nd token
                (, uint256[] memory balances, ) = IVault(BALANCER_VAULT).getPoolTokens(BALANCER_BCT_POOL_ID);

                // The user holds bptBalance/totalSupply of the BCT token
                poolBalance = (balances[1] * bptBalance) / totalSupply;
            }
        }

        return _getWalletBalances(user) + _getInternalBalances(user) + poolBalance;
    }

    /**
     * @dev Send the carbon credit total cross-chain
     * @param destinationDomain - the chain id of the destination.
     * @param recipient - the address of the L2 `CarbonCreditReceiver` contract.
     * @param payRelayer - if set, will manually pay gas. Otherwise, throws itself upon the mercy of the relayer.
     */
    function sendTotalCarbonCredits(
        uint32 destinationDomain,
        address recipient,
        bool payRelayer
    ) external payable returns (bytes32 msgID) {
        bytes32 encodedRecipient = bytes32(uint256(uint160(recipient)));
        bytes memory encodedCredits = abi.encode(msg.sender, getTotalCarbonCredits(msg.sender));

        msgID = _mailbox.dispatch(destinationDomain, encodedRecipient, encodedCredits);

        if (payRelayer) {
            // Pay for gas
            uint256 gasAmount = _gasPaymaster.quoteGasPayment(destinationDomain, 100_000);

            // Refund to sender
            _gasPaymaster.payForGas{ value: msg.value }(msgID, destinationDomain, gasAmount, msg.sender);
        }

        emit TotalCarbonCreditsSent(msg.sender, destinationDomain, recipient);

        return msgID;
    }

    function _getWalletBalances(address user) private view returns (uint256 totalCredits) {
        for (uint256 i = 0; i < _carbonTokens.length; i++) {
            totalCredits += (_carbonTokens[i].balanceOf(user) * _tokenWeights[i]) / _SCALING_FACTOR;
        }
    }

    function _getInternalBalances(address user) private view returns (uint256 totalCredits) {
        uint256[] memory internalBalances = IVault(BALANCER_VAULT).getInternalBalance(user, _carbonTokens);

        for (uint256 i = 0; i < _carbonTokens.length; i++) {
            totalCredits += (internalBalances[i] * _tokenWeights[i]) / _SCALING_FACTOR;
        }
    }
}