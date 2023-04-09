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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGold } from "./interfaces/IGold.sol";
import { IPriceFeed } from "./interfaces/IPriceFeed.sol";

contract UpVsDownGameV2 is Ownable {
    struct BetGroup {
        uint256[] bets;
        address[] addresses;
        string[] avatars;
        string[] countries;
        uint256 total;
        uint256 distributedCount;
        uint256 totalDistributed;
    }

    struct Round {
        bool created;
        int32 startPrice;
        int32 endPrice;
        uint256 minBetAmount;
        uint256 maxBetAmount;
        uint256 poolBetsLimit;
        BetGroup upBetGroup;
        BetGroup downBetGroup;
        int64 roundStartTime;
    }

    struct Distribution {
        uint256 fee;
        uint256 totalMinusFee;
        uint256 pending;
    }

    int32 public GAME_DURATION = 30;
    address public gameController;
    mapping(bytes => Round) public pools;
    uint256 public feePercentage = 5;
    bool public isRunning;
    bytes public notRunningReason;

    IGold public immutable gold;
    IPriceFeed public immutable priceFeed;
    IERC20 public immutable WBTC;
    IERC20 public immutable usdc;

    mapping(address => uint256) public lostGold;

    // Errors

    error PendingDistributions();

    // Events

    event RoundStarted(
        bytes poolId,
        int64 timestamp,
        int32 price,
        uint256 minTradeAmount,
        uint256 maxTradeAmount,
        uint256 poolTradesLimit,
        bytes indexed indexedPoolId
    );
    event RoundEnded(bytes poolId, int64 timestamp, int32 startPrice, int32 endPrice, bytes indexed indexedPoolId);
    event TradePlaced(
        bytes poolId,
        address sender,
        uint256 amount,
        string prediction,
        uint256 newTotal,
        bytes indexed indexedPoolId,
        address indexed indexedSender,
        string avatarUrl,
        string countryCode,
        int64 roundStartTime
    );
    event TradeReturned(bytes poolId, address sender, uint256 amount);
    event GameStopped(bytes reason);
    event GameStarted();
    event RoundDistributed(bytes poolId, uint256 totalWinners, uint256 from, uint256 to, int64 timestamp);
    event TradeWinningsSent(
        bytes poolId, address sender, uint256 tradeAmount, uint256 winningsAmount, address indexed indexedSender
    );

    // Modifiers

    modifier onlyGameController() {
        require(msg.sender == gameController, "Only game controller can do this");
        _;
    }

    modifier onlyOpenPool(bytes calldata poolId) {
        require(isPoolOpen(poolId), "This pool has a round in progress");
        _;
    }

    modifier onlyGameRunning() {
        require(isRunning, "The game is not running");
        _;
    }

    modifier onlyPoolExists(bytes calldata poolId) {
        require(pools[poolId].created == true, "Pool does not exist");
        _;
    }

    constructor(IGold gold_, IPriceFeed oneInchPriceFeed_, IERC20 WBTC_, IERC20 usdc_) {
        gold = gold_;
        priceFeed = oneInchPriceFeed_;
        WBTC = WBTC_;
        usdc = usdc_;
        gameController = msg.sender;
    }

    // Methods

    function changeGameDuration(int32 newGameDuration) public onlyOwner {
        require(newGameDuration != 0, "Game duration cannot be 0");
        GAME_DURATION = newGameDuration;
    }

    function changeGameControllerAddress(address newGameController) public onlyOwner {
        gameController = newGameController;
    }

    function changeGameFeePercentage(uint256 newFeePercentage) public onlyOwner {
        feePercentage = newFeePercentage;
    }

    function stopGame(bytes calldata reason) public onlyOwner {
        isRunning = false;
        notRunningReason = reason;
        emit GameStopped(reason);
    }

    function startGame() public onlyOwner {
        isRunning = true;
        notRunningReason = "";
        emit GameStarted();
    }

    function createPool(bytes calldata poolId, uint256 minBetAmount, uint256 maxBetAmount, uint256 poolBetsLimit)
        public
        onlyGameController
    {
        pools[poolId].created = true;
        pools[poolId].minBetAmount = minBetAmount;
        pools[poolId].maxBetAmount = maxBetAmount;
        pools[poolId].poolBetsLimit = poolBetsLimit;
    }

    function trigger(bytes calldata poolId, uint32 batchSize, uint256 price) public onlyPoolExists(poolId) {
        Round storage currentRound = pools[poolId];

        if (isPoolOpen(poolId) && int64(uint64(block.timestamp)) > currentRound.roundStartTime + 2 * GAME_DURATION) {
            require(isRunning, "The game is not running, rounds can only be ended at this point");
            //currentRound.startPrice = int32(uint32(priceFeed.getRate(WBTC, usdc, true)));
            currentRound.startPrice = int32(uint32(price));
            currentRound.roundStartTime = int64(uint64(block.timestamp));

            emit RoundStarted(
                poolId,
                int64(uint64(block.timestamp)),
                currentRound.startPrice,
                currentRound.minBetAmount,
                currentRound.maxBetAmount,
                currentRound.poolBetsLimit,
                poolId
            );
        } else if (
            currentRound.endPrice == 0 && int64(uint64(block.timestamp)) > currentRound.roundStartTime + GAME_DURATION
        ) {
            require(tx.origin == msg.sender, "Only EOA");
            //currentRound.endPrice = int32(uint32(priceFeed.getRate(WBTC, usdc, true)));
            currentRound.endPrice = int32(uint32(price));

            emit RoundEnded(
                poolId, int64(uint64(block.timestamp)), currentRound.startPrice, currentRound.endPrice, poolId
            );

            distribute(poolId, batchSize);
        } else {
            revert PendingDistributions();
        }
    }

    function returnBets(bytes calldata poolId, BetGroup storage group, uint32 batchSize) private {
        uint256 pending = group.bets.length - group.distributedCount;
        uint256 limit = pending > batchSize ? batchSize : pending;
        uint256 to = group.distributedCount + limit;

        for (uint256 i = group.distributedCount; i < to; i++) {
            bool success = sendGold(group.addresses[i], group.bets[i]);
            if (success) emit TradeReturned(poolId, group.addresses[i], group.bets[i]);
        }

        group.distributedCount = to;
    }

    function distribute(bytes calldata poolId, uint32 batchSize) public onlyPoolExists(poolId) {
        Round storage round = pools[poolId];

        if (round.upBetGroup.bets.length == 0 || round.downBetGroup.bets.length == 0) {
            BetGroup storage returnGroup = round.downBetGroup.bets.length == 0 ? round.upBetGroup : round.downBetGroup;

            uint256 fromReturn = returnGroup.distributedCount;
            returnBets(poolId, returnGroup, batchSize);
            emit RoundDistributed(
                poolId,
                returnGroup.bets.length,
                fromReturn,
                returnGroup.distributedCount,
                int64(uint64(block.timestamp))
            );

            if (returnGroup.distributedCount == returnGroup.bets.length) {
                clearPool(poolId);
            }
            return;
        }

        BetGroup storage winners = round.downBetGroup;
        BetGroup storage losers = round.upBetGroup;

        if (round.startPrice < round.endPrice) {
            winners = round.upBetGroup;
            losers = round.downBetGroup;
        }

        Distribution memory dist = calculateDistribution(winners, losers);
        uint256 limit = dist.pending > batchSize ? batchSize : dist.pending;
        uint256 to = winners.distributedCount + limit;

        for (uint256 i = winners.distributedCount; i < to; i++) {
            uint256 winnings = ((winners.bets[i] * 100 / winners.total) * dist.totalMinusFee / 100);
            bool success = sendGold(winners.addresses[i], winnings + winners.bets[i]);
            if (success) {
                emit TradeWinningsSent(poolId, winners.addresses[i], winners.bets[i], winnings, winners.addresses[i]);
            }
            winners.totalDistributed = winners.totalDistributed + winnings;
        }

        emit RoundDistributed(poolId, winners.bets.length, winners.distributedCount, to, int64(uint64(block.timestamp)));

        winners.distributedCount = to;
        if (winners.distributedCount == winners.bets.length) {
            sendGold(gameController, dist.fee + dist.totalMinusFee - winners.totalDistributed);
            clearPool(poolId);
        }
    }

    function calculateDistribution(BetGroup storage winners, BetGroup storage losers)
        private
        view
        returns (Distribution memory)
    {
        uint256 fee = feePercentage * losers.total / 100;
        uint256 pending = winners.bets.length - winners.distributedCount;
        return Distribution({ fee: fee, totalMinusFee: losers.total - fee, pending: pending });
    }

    function clearPool(bytes calldata poolId) private {
        delete pools[poolId].upBetGroup;
        delete pools[poolId].downBetGroup;
        delete pools[poolId].startPrice;
        delete pools[poolId].endPrice;
    }

    function hasPendingDistributions(bytes calldata poolId) public view returns (bool) {
        return (pools[poolId].upBetGroup.bets.length + pools[poolId].downBetGroup.bets.length) > 0;
    }

    function isPoolOpen(bytes calldata poolId) public view returns (bool) {
        return pools[poolId].startPrice == 0;
    }

    function addBet(BetGroup storage betGroup, uint256 amount, string calldata avatar, string calldata countryCode)
        private
        returns (uint256)
    {
        betGroup.bets.push(amount);
        betGroup.addresses.push(msg.sender);
        betGroup.avatars.push(avatar);
        betGroup.countries.push(countryCode);
        betGroup.total += amount;
        return betGroup.total;
    }

    struct makeTradeStruct {
        bytes poolId;
        string avatarUrl;
        string countryCode;
        bool upOrDown;
        uint256 goldBet;
    }

    function makeTrade(makeTradeStruct calldata userTrade)
        public
        payable
        onlyOpenPool(userTrade.poolId)
        onlyGameRunning
        onlyPoolExists(userTrade.poolId)
    {
        gold.privilegedTransferFrom(msg.sender, address(this), userTrade.goldBet);
        require(userTrade.goldBet > 0, "Needs to send Gold to trade");
        require(
            userTrade.goldBet >= pools[userTrade.poolId].minBetAmount, "Trade amount should be higher than the minimum"
        );
        require(
            userTrade.goldBet <= pools[userTrade.poolId].maxBetAmount, "Trade amount should be lower than the maximum"
        );
        uint256 newTotal;

        if (userTrade.upOrDown) {
            require(
                pools[userTrade.poolId].upBetGroup.bets.length <= pools[userTrade.poolId].poolBetsLimit - 1,
                "Pool is full, wait for next round"
            );
            newTotal = addBet(
                pools[userTrade.poolId].upBetGroup, userTrade.goldBet, userTrade.avatarUrl, userTrade.countryCode
            );
        } else {
            require(
                pools[userTrade.poolId].downBetGroup.bets.length <= pools[userTrade.poolId].poolBetsLimit - 1,
                "Pool is full, wait for next round"
            );
            newTotal = addBet(
                pools[userTrade.poolId].downBetGroup, userTrade.goldBet, userTrade.avatarUrl, userTrade.countryCode
            );
        }

        string memory avatar;
        {
            avatar = userTrade.avatarUrl;
        }

        string memory countryCode;
        {
            countryCode = userTrade.countryCode;
        }

        int64 roundStartTime;
        {
            roundStartTime = pools[userTrade.poolId].roundStartTime;
        }

        emit TradePlaced(
            userTrade.poolId,
            msg.sender,
            userTrade.goldBet,
            (userTrade.upOrDown) ? "UP" : "DOWN",
            newTotal,
            userTrade.poolId,
            msg.sender,
            avatar,
            countryCode,
            roundStartTime
        );
    }

    function claimLostGold() external {
        uint256 amount = lostGold[msg.sender];
        lostGold[msg.sender] = 0;
        sendGold(msg.sender, amount);
    }

    function sendGold(address to, uint256 amount) private returns (bool success) {
        try gold.transfer(to, amount) {
            success = true;
        } catch {
            lostGold[to] += amount;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./IOFTCore.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the OFT standard
 */
interface IOFT is IOFTCore, IERC20 { }

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface of the IOFT core standard
 */
interface IOFTCore is IERC165 {
    /**
     * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
     * _dstChainId - L0 defined chain id to send tokens too
     * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * _amount - amount of the tokens to transfer
     * _useZro - indicates to use zro to pay L0 fees
     * _adapterParam - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        bool _useZro,
        bytes calldata _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    /**
     * @dev send `_amount` amount of token to (`_dstChainId`, `_toAddress`) from `_from`
     * `_from` the owner of token
     * `_dstChainId` the destination chain identifier
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_amount` the quantity of tokens in wei
     * `_refundAddress` the address LayerZero refunds if too much message fee is sent
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    /**
     * @dev returns the circulating amount of tokens on current chain
     */
    function circulatingSupply() external view returns (uint256);

    /**
     * @dev returns the address of the ERC20 token
     */
    function token() external view returns (address);

    /**
     * @dev Emitted when `_amount` tokens are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
     * `_nonce` is the outbound nonce
     */
    event SendToChain(uint16 indexed _dstChainId, address indexed _from, bytes _toAddress, uint256 _amount);

    /**
     * @dev Emitted when `_amount` tokens are received from `_srcChainId` into the `_toAddress` on the local chain.
     * `_nonce` is the inbound nonce.
     */
    event ReceiveFromChain(uint16 indexed _srcChainId, address indexed _to, uint256 _amount);

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IOFT } from "src/dependencies/layerZero/interfaces/oft/IOFT.sol";

interface IGold is IOFT {
    error NotPrivilegedSender(address sender);
    error NotCharacterError(address sender);

    event GoldBurned(address indexed account, uint256 amount);
    event GoldMinted(address indexed account, uint256 amount);
    event GoldPrivilegedTransfer(address indexed from, address indexed to, uint256 amount);

    function burn(address account_, uint256 amount_) external;
    function mint(address account_, uint256 amount_) external;
    function privilegedTransferFrom(address from_, address to_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPriceFeed {
    function getRate(IERC20 srcToken_, IERC20 dstToken_, bool useWrappers_) external view returns (uint256 rate_);
}