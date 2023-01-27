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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IReferralsEternalStorage {
    function addReferral(address referralAddress, address ambasadorAddress) external;

    function getReferrer(address referral) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./abstractions/IReferralsEternalStorage.sol";

contract Cryptoholic is Ownable {
    uint8 private constant USDT_INDEX = 1;
    uint256 private constant REFERAL_PERCENTAGE = 5;

    event TransactionProcessed(bytes txID);

    ISwapRouter private uniswapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IReferralsEternalStorage private referralsStorage;

    address[] private payoutCurrencies;
    address private wETH9;
    address private _usdt;
    address private feeAddress;
    uint32 private payoutCurrncyPosition;

    //txIDs[x] == true if subscription is completed
    mapping(bytes => bool) private txIDs;
    mapping(bytes20 => bool) private usedNonces;

    Founder[] private feeAddresses;

    struct Founder {
        address addr;
        uint256 percent;
    }

    struct Signature {
        bytes32 sigR;
        bytes32 sigS;
        uint8 sigV;
    }

    constructor(address referralsStorageAddress)  {
        wETH9 = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
        // wrapped ETH address on polygon mainnet
        _usdt = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
        // usdt on polygon mainnet
        payoutCurrencies.push(address(0));
        // add first element in payoutCurrency list; default == matic
        payoutCurrencies.push(_usdt);
        // add USDT as payout currency

        payoutCurrncyPosition = 1;

    feeAddresses.push(
            Founder(address(0x8f38BB133BDfBD88982B43a4A005278845BB5A0B), 55)
        );

        feeAddresses.push(
            Founder(address(0x6463805F09451ae351e4BE75fc041586FF08F451), 35)
        );

        feeAddresses.push(
            Founder(address(0x240B84ceDaA936688D42c52556b81956d33Bb895), 10)
        );

        referralsStorage = IReferralsEternalStorage(referralsStorageAddress);
    }

    //returns payout currencies array
    function getPayoutCurrency() external view returns (address[] memory) {
        return payoutCurrencies;
    }

    //add new payout currency
    function addPayoutCurrency(address addr) external onlyOwner {
        payoutCurrencies.push(addr);
    }

    function removePayoutCurrency(uint32 pos) external onlyOwner {
        require(pos < payoutCurrencies.length, "OUT_OF_BOUNDS");

        for (uint i = pos; i < payoutCurrencies.length - 1; i++) {
            payoutCurrencies[i] = payoutCurrencies[i + 1];
        }

        payoutCurrencies.pop();
    }

    function changePayoutCurrency(uint32 pos) external onlyOwner {
        require(pos < payoutCurrencies.length, "OUT_OF_BOUNDS");
        require(pos != 0, "NOT_AVAILABLE_POSITION");

        payoutCurrncyPosition = pos;
    }

    function subscribe(
        bytes calldata txID,
        uint8 payoutCurrencyID,
        bytes calldata subscriptionID,
        bytes20 nonce,
        Signature calldata sig,
        address creator,
        uint64 expiresOn,
        uint64 timestamp
    ) external payable {
        _validateSignature(
            txID,
            msg.value,
            payoutCurrencyID,
            subscriptionID,
            nonce,
            creator,
            expiresOn,
            sig
        );

        require(!usedNonces[nonce], "NONCE_USED");
        usedNonces[nonce] = true;

        require(timestamp < expiresOn, "SUBSCRIPTION_EXPIRED");

        txIDs[txID] = true;

        _makePayment(payoutCurrencyID, creator, timestamp);

        emit TransactionProcessed(txID);
    }

    function payPerPost(
        bytes calldata txID,
        uint8 payoutCurrencyID,
        bytes calldata postID,
        bytes20 nonce,
        Signature calldata sig,
        address creator,
        uint64 timestamp
    ) external payable {
        _validateSignaturePost(
            txID,
            msg.value,
            payoutCurrencyID,
            postID,
            nonce,
            creator,
            sig
        );

        require(!usedNonces[nonce], "NONCE_USED");
        usedNonces[nonce] = true;

        txIDs[txID] = true;

        _makePayment(payoutCurrencyID, creator, timestamp);

        emit TransactionProcessed(txID);
    }

    function _makePayment(
        uint8 payoutCurrencyID,
        address creator,
        uint64 timestamp
    ) private {
        uint256 feePercentage = _getTier(msg.value);

        uint256 creatorAmount = (msg.value * (1000 - feePercentage)) / 1000;
        uint256 feeAmount = msg.value - creatorAmount;

        if (payoutCurrencyID == 0) {
            // pay to content creator in MATIC
            payable(creator).transfer(creatorAmount);
        } else {
            // pay to content creator in desired currency
            _swapAndPay(payoutCurrencyID, creator, creatorAmount, timestamp);
        }

        // pay fee to owner and referral
        address referrer = referralsStorage.getReferrer(creator);
        if (referrer != address(0)) {
            uint256 referalAmount = (msg.value * REFERAL_PERCENTAGE) / 100;

            // transfer % to referral
            _swapAndPay(payoutCurrncyPosition, referrer, referalAmount, timestamp);

            feeAmount = feeAmount - referalAmount;
        }

        _distributeFoundersFee(feeAmount, timestamp);
    }

    function _getTier(uint256 amount) private pure returns (uint256) {
        if (amount > 2000 * 10 ** 18) {
            // Tier 5 == fee is 10%
            return 100;
        } else if (amount > 1000 * 10 ** 18) {
            // Tier 4 == fee is 12.5%
            return 125;
            // 12.5
        } else if (amount > 500 * 10 ** 18) {
            // Tier 3 == fee is 15%
            return 150;
        } else if (amount > 100 * 10 ** 18) {
            // Tier 2 == fee is 17.5%
            return 175;
        } else {
            // Tier 1 == fee is 20%
            return 200;
        }
    }

    function _swapAndPay(
        uint32 payoutCurrencyID,
        address creator,
        uint256 amount,
        uint64 timestamp
    ) private {
        uint256 deadline = timestamp;
        address tokenIn = wETH9;
        address tokenOut = payoutCurrencies[payoutCurrencyID];
        uint24 fee = 3000;
        address recipient = creator;
        uint256 amountIn = amount;
        uint256 amountOutMinimum = 0;
        uint160 sqrtPriceLimitX96 = 0;
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
        .ExactInputSingleParams(
            tokenIn,
            tokenOut,
            fee,
            recipient,
            deadline,
            amountIn,
            amountOutMinimum,
            sqrtPriceLimitX96
        );
        uniswapRouter.exactInputSingle{value : amount}(params);
    }

    function _validateSignature(
        bytes calldata txID,
        uint256 amount,
        uint8 payoutCurrencyID,
        bytes calldata subscriptionID,
        bytes20 nonce,
        address creator,
        uint64 expiresOn,
        Signature calldata sig
    ) private view {
        address user = msg.sender;

        bytes32 dataHash = keccak256(
            abi.encodePacked(
                txID,
                user,
                creator,
                amount,
                subscriptionID,
                payoutCurrencyID,
                expiresOn,
                nonce,
                address(this)
            )
        );

        address signer = ecrecover(dataHash, sig.sigV, sig.sigR, sig.sigS);
        require(signer == owner(), "INVALID_ECDSA");
    }

    function _validateSignaturePost(
        bytes calldata txID,
        uint256 amount,
        uint8 payoutCurrencyID,
        bytes calldata postID,
        bytes20 nonce,
        address creator,
        Signature calldata sig
    ) private view {
        address user = msg.sender;

        bytes32 dataHash = keccak256(
            abi.encodePacked(
                txID,
                user,
                creator,
                amount,
                postID,
                payoutCurrencyID,
                nonce,
                address(this)
            )
        );

        address signer = ecrecover(dataHash, sig.sigV, sig.sigR, sig.sigS);
        require(signer == owner(), "INVALID_ECDSA");
    }

    function _distributeFoundersFee(uint256 foundersFee, uint64 timestamp) private {
        for (uint256 i = 0; i < feeAddresses.length; i++) {
            Founder memory founderFee = feeAddresses[i];

            _swapAndPay(payoutCurrncyPosition, founderFee.addr, (foundersFee * founderFee.percent) / 100, timestamp);
        }
    }
}