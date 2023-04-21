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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {OptionAPED} from "./OptionAPED.sol";
import {CreateOptionParams} from "./interfaces/CreateOptionParams.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FactoryAPED is Ownable {

    struct Option {
        uint256 id;
        address optionAddress;
        string optionName;
        bool initialized;
    }

    struct ListOptionResponse {
        Option[] options;
        uint256 optionCount;
    }

    uint256 public optionCount;
    mapping(uint256 => Option) private options;

    function createOption(CreateOptionParams calldata params) public {
        require(params.tokensOut.length == params.poolFees.length, "Wrong arrays calldata");
        OptionAPED option = new OptionAPED(params);
        option.transferOwnership(msg.sender);
        options[optionCount] = Option(optionCount, address(option), params.name, true);
        optionCount++;
    }

    function listOptions(uint256 from, uint256 to) external view returns (ListOptionResponse memory) {
        require(from <= to, "Incorrect range");
        uint256 num = getOptionNumberInRange(from, to);
        Option[] memory filteredOptions = getOptionsInRange(from, to, num);
        return ListOptionResponse(filteredOptions, optionCount);
    }

    function deleteOption(uint256 id) external {
        delete options[id];
    }

    function getOptionNumberInRange(uint256 from, uint256 to) private view returns (uint256 count) {
        for (uint256 i = from; i <= to; i++) {
            if (options[i].initialized) {
                count++;
            }
        }
    }

    function getOptionsInRange(uint256 from, uint256 to, uint256 num) private view returns (Option[] memory) {
        Option[] memory initializedOptions = new Option[](num);
        uint256 counter;
        for (uint256 i = from; i <= to; i++) {
            if (options[i].initialized) {
                initializedOptions[counter++] = options[i];
            }
        }
        return initializedOptions;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

struct TokenFeePair {
    address token;
    uint24 fee;
}

struct CreateOptionParams {
    address feed;
    string name;
    address tokenIn;
    //todo: replace with TokenFeePair
    address[] tokensOut;
    uint24[] poolFees;
    address tokenBid;
    address feeKeeper;
    uint256 fee;
    uint256 startTimestamp;
    uint256 depositPeriod;
    uint256 lockPeriod;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

interface IPriceFeedAPED {
    function estimateAmountOut(
        address tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint32 secondsAgo,
        uint24 _fee
    ) external view returns (uint256 amountOut);

    function getPrice(address tokenIn, address[] calldata tokensOut, uint24[] calldata poolFees, uint32 secondsAgo) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPriceFeedAPED} from "./interfaces/IPriceFeedAPED.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {CreateOptionParams} from "./interfaces/CreateOptionParams.sol";

contract OptionAPED is Ownable {

    struct Option {
        OptionStage optionStage;
        OptionResult result;
        uint256 optionIndex;
        string optionName;
        address tokenIn;
        address[] tokensOut;
        address tokenBid;
        string tokenBidName;
        address feeKeeper;
        uint256 fee;
        uint256 startOption;
        uint256 startLock;
        uint256 endTs;
        uint256 startPrice;
        uint256 closePrice;
        uint256 upBets;
        uint256 downBets;
        uint256 totalBets;
        uint8 decimals;
        bool resolved;
    }

    struct Bid {
        uint256 betAmountUp;
        uint256 betAmountDown;
        bool claimed;
        uint256 wonAmount;
    }

    struct BidInfo {
        OptionStage optionStage;
        OptionResult result;
        BidType bidType;
        uint256 optionId;
        uint256 betAmount;
        uint256 timeStamp;
        uint256 wonAmount;
        bool claimed;
    }


    struct CurrentOptionInfo {
        Option currentRound;
        Option prevRound;
        uint256 currentPrice;
        uint256 currentTimestamp;
    }

    enum OptionStage {
        NotStarted,
        Deposits,
        Lock,
        Ended,
        Closed
    }

    enum OptionResult {
        Down,
        Up,
        NotChanged
    }

    enum BidType {
        Down,
        Up
    }

    IPriceFeedAPED private priceFeed;
    string private optionName;
    address private tokenIn;
    address[] private tokensOut;
    uint24[] private poolFees;
    IERC20 private tokenBid;
    address private feeKeeper;
    uint256 private fee;
    uint256 public startTimestamp;
    uint256 public depositPeriod;
    uint256 public lockPeriod;
    bool public isStarted;

    mapping(uint256 => Option) private options;
    mapping(address => uint256[]) private userOptions;
    mapping(address => mapping(uint256 => Bid)) private bids;

    // event NewOption(uint256 id, uint256 start, uint256 end);
    // event BetPlaced(uint256 id, address user, uint256 amount, bool outcome);
    // event OptionResolved(uint256 id, bool outcome);
    // event FundsWithdrawn(uint256 id, address user, uint256 amount);

    constructor(CreateOptionParams memory params) {
        priceFeed = IPriceFeedAPED(params.feed);
        optionName = params.name;
        tokenIn = params.tokenIn;
        tokensOut = params.tokensOut;
        poolFees = params.poolFees;
        tokenBid = IERC20(params.tokenBid);
        feeKeeper = params.feeKeeper;
        fee = params.fee;
        startTimestamp = params.startTimestamp;
        depositPeriod = params.depositPeriod;
        lockPeriod = params.lockPeriod;
    }

    function getCurrentOptionId() public view returns (uint256) {
        if (startTimestamp > block.timestamp) {
            return 0;
        }
        return 1 + (block.timestamp - startTimestamp) / lockPeriod;
    }

    function currentOptionInfo() public view returns (CurrentOptionInfo memory) {
        (uint256 currentPrice, uint256 currentTimestamp) = getCurrentPrice();
        uint256 currentOptionId = getCurrentOptionId();
        uint256 prevOptionId = currentOptionId > 0 ? currentOptionId - 1 : currentOptionId;
        return CurrentOptionInfo(
            getOptionInfo(currentOptionId),
            getOptionInfo(prevOptionId),
            currentPrice,
            currentTimestamp
        );
    }

    function getOptionInfo(uint256 id) public view returns (Option memory) {
        if (options[id].resolved) {
            return options[id];
        }

        uint256 optionTimestamp = getOptionTimestamp(id);
        return Option(
            getOptionStage(id),
            options[id].result,
            id,
            optionName,
            tokenIn,
            tokensOut,
            address(tokenBid),
            tokenBid.symbol(),
            feeKeeper,
            fee,
            optionTimestamp - depositPeriod,
            optionTimestamp,
            optionTimestamp + lockPeriod,
            options[id].startPrice > 0 ? options[id].startPrice : getPrice(optionTimestamp),
            options[id].closePrice > 0 ? options[id].closePrice : getPrice(optionTimestamp + lockPeriod),
            options[id].upBets,
            options[id].downBets,
            options[id].upBets + options[id].downBets,
            tokenBid.decimals(),
            options[id].resolved
        );
    }

    function getAllBidInfo(address client) public view returns (BidInfo[] memory _bids) {
        uint256[] memory _optionIds = userOptions[client];
        _bids = batchBidInfo(client, 0, _optionIds.length);
    }

    function batchBidInfo(address client, uint256 from, uint256 to) public view returns(BidInfo[] memory _bids) {
        require(from <= to, "Incorrect range");
        uint256 size = from > 0 ? to - from + 1 : to - from;
        uint256[] memory _optionIds = userOptions[client];
        uint256 count = getNumBids(client, size, from);
        _bids = new BidInfo[](count);
        uint256 counter;
        for (uint256 i = 0; i < size; i++) {
            if (from + i >= optionsAmount(client)) {
                i = size;
            } else {
                for (uint256 j = 0; j < getBidInfo(client, _optionIds[from + i]).length; j++){
                    _bids[counter] = getBidInfo(client, _optionIds[from + i])[j];
                    counter ++;
                }
            }
        }
    }

    function getNumBids(address client, uint256 amount, uint256 startedId) public view returns(uint256 count) {
        uint256[] memory _optionIds = userOptions[client];
        for (uint256 i = 0; i < amount; i ++) {
            if (startedId + i >= optionsAmount(client)) {
                i = amount;
            } else {
                count += getBidInfo(client, _optionIds[startedId + i]).length;
            }
        }
    }

    function getCurrentBidInfo(address client) public view returns (BidInfo[] memory) {
        uint256 currentCount;
        uint256 prevCount;
        uint256 prevBidId = getCurrentOptionId() - 1;

        if (getBidInfo(client, getCurrentOptionId()).length > 0) {
            currentCount += getBidInfo(client, getCurrentOptionId()).length;
        }
        if (getBidInfo(client, prevBidId).length > 0) {
            prevCount += getBidInfo(client, prevBidId).length;
        }

        BidInfo[] memory bidsInfo = new BidInfo[](currentCount + prevCount);
        for (uint256 i = 0; i < currentCount; i++) {
            bidsInfo[i] = getBidInfo(client, getCurrentOptionId())[i];
        }
        for (uint256 i = 0; i < prevCount; i++) {
            bidsInfo[currentCount + i] = getBidInfo(client, prevBidId)[i];
        }
        return bidsInfo;
    }

    function getBidInfo(address client, uint256 id) public view returns (BidInfo[] memory _bidsInfo) {
        uint256 count;
        if (bids[client][id].betAmountUp > 0) count++;
        if (bids[client][id].betAmountDown > 0) count++;
        _bidsInfo = new BidInfo[](count);
        uint256 wonAmountUp;
        uint256 wonAmountDown;
        if (options[id].resolved) {
            if (options[id].result == OptionResult.Down) wonAmountDown = getWonAmount(client, id);
            if (options[id].result == OptionResult.Up) wonAmountUp = getWonAmount(client, id);
        }

        if (bids[client][id].betAmountDown > 0) {
            _bidsInfo[0] = BidInfo(
                getOptionStage(id),
                options[id].result,
                BidType.Down,
                id,
                bids[client][id].betAmountDown,
                getOptionTimestamp(id),
                wonAmountDown,
                bids[client][id].claimed
            );
        }
        if (bids[client][id].betAmountUp > 0) {
            _bidsInfo[count - 1] = BidInfo(
                getOptionStage(id),
                options[id].result,
                BidType.Up,
                id,
                bids[client][id].betAmountUp,
                getOptionTimestamp(id),
                wonAmountUp,
                bids[client][id].claimed
            );
        }
    }

    function placeBid(uint256 _betAmount, BidType _selectedBid) external {
        uint256 optionsCounter = getCurrentOptionId();
        OptionStage stage = getOptionStage(optionsCounter);

        require(stage == OptionStage.Deposits, "Option is not started yet");
        require(_betAmount > 0, "Bet amount must be greater than 0");

        bidTokenTransfer(msg.sender, address(this), _betAmount);
        if (userOptions[msg.sender].length == 0 || userOptions[msg.sender][userOptions[msg.sender].length - 1] != optionsCounter) {
            userOptions[msg.sender].push(optionsCounter);
        }
        if (_selectedBid == BidType.Down) {
            options[optionsCounter].downBets += _betAmount;
            bids[msg.sender][optionsCounter].betAmountDown += _betAmount;
        } else {
            options[optionsCounter].upBets += _betAmount;
            bids[msg.sender][optionsCounter].betAmountUp += _betAmount;
        }
        // emit BetPlaced(id, msg.sender, msg.value, outcome);
    }

    function bidTokenTransfer(address from, address to, uint256 amount) internal {
        uint256 _balance = tokenBid.balanceOf(from);
        from == address(this) ? tokenBid.transfer(to, amount) : tokenBid.transferFrom(from, to, amount);
        require(tokenBid.balanceOf(from) == _balance - amount, "TransferFrom Error");
    }

    function batchClaim(uint256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            claim(ids[i]);
        }
    }

    function claim(uint256 id) public {
        uint256 optionTimestamp = getOptionTimestamp(id);
        if (!options[id].resolved || block.timestamp >= optionTimestamp + lockPeriod) {
            _resolve(id, getPrice(optionTimestamp), getPrice(optionTimestamp + lockPeriod));
        }
        require(options[id].resolved, "Option isn't ended");
        require(!bids[msg.sender][id].claimed, "You already claimed");
        bids[msg.sender][id].claimed = true;
        bids[msg.sender][id].wonAmount = getWonAmount(msg.sender, id);
        uint256 betAmount = options[id].result == OptionResult.Down ? bids[msg.sender][id].betAmountDown : bids[msg.sender][id].betAmountUp;
        if (options[id].result == OptionResult.NotChanged) {
            betAmount = bids[msg.sender][id].betAmountDown + bids[msg.sender][id].betAmountUp;
        }
        bidTokenTransfer(address(this), msg.sender, getWonAmount(msg.sender, id) + betAmount);
    }

    function _resolve(uint256 id, uint256 startPrice, uint256 closePrice) internal {
        Option storage option = options[id];
        option.startPrice = startPrice;
        option.closePrice = closePrice;
        uint256 amountFee;
        if (option.closePrice > option.startPrice) {
            options[id].result = OptionResult.Up;
            amountFee = options[id].upBets * fee / 100;
        } else {
            if (option.closePrice < option.startPrice) {
                options[id].result = OptionResult.Down;
                amountFee = options[id].downBets * fee / 100;
            } else {
                options[id].result = OptionResult.NotChanged;
                amountFee = 0;
            }
        }
        option.resolved = true;
        bidTokenTransfer(address(this), feeKeeper, amountFee);
        // emit OptionResolved(id, outcome);
    }

    function optionsOf(address client) public view returns (uint256[] memory) {
        return userOptions[client];
    }

    function optionsAmount(address client) public view returns (uint256) {
        return userOptions[client].length;
    }

    function currentOptionTimestamp() public view returns (uint256) {
        return getOptionTimestamp(getCurrentOptionId());
    }

    function getOptionStage(uint256 id) private view returns (OptionStage) {
        if (!isStarted) {
            return OptionStage.Closed;
        }
        uint256 optionTimestamp = getOptionTimestamp(id);
        if (optionTimestamp > block.timestamp + depositPeriod) {
            return OptionStage.NotStarted;
        }
        if (block.timestamp > optionTimestamp + lockPeriod) {
            return OptionStage.Ended;
        }
        if (block.timestamp > optionTimestamp) {
            return OptionStage.Lock;
        }
        return OptionStage.Deposits;
    }

    function getWonAmount(address user, uint256 optionIndex) private view returns (uint256) {
        OptionResult result = options[optionIndex].result;

        if (result == OptionResult.Up) {
            return options[optionIndex].upBets > 0 ? getPotentialEarningsUp(user, optionIndex) : 0;
        }
        if (result == OptionResult.Down) {
            return options[optionIndex].downBets > 0 ? getPotentialEarningsDown(user, optionIndex) : 0;
        }
        return 0;
    }

    function getOptionTimestamp(uint256 id) private view returns (uint256) {
        if (id == 0) {
            return startTimestamp;
        }
        return startTimestamp + lockPeriod * id;
    }

    function getCurrentPrice() private view returns (uint256, uint256) {
        uint256 ts = block.timestamp - 1;
        return (getPrice(ts), ts);
    }

    function getPrice(uint256 timeStamp) private view returns (uint256) {
        if (timeStamp >= block.timestamp) {
            return 0;
        }
        return priceFeed.getPrice(tokenIn, tokensOut, poolFees, uint32(block.timestamp - timeStamp));
    }

    function getPotentialEarningsUp(address user, uint256 optionIndex) internal view returns (uint256) {
        if (options[optionIndex].upBets == 0) {
            return 0;
        }
        return options[optionIndex].downBets * bids[user][optionIndex].betAmountUp / options[optionIndex].upBets * getCommission();
    }

    function getPotentialEarningsDown(address user, uint256 optionIndex) internal view returns (uint256) {
        if (options[optionIndex].downBets == 0) {
            return 0;
        }
        return options[optionIndex].upBets * bids[user][optionIndex].betAmountDown / options[optionIndex].downBets * getCommission();
    }

    function getCommission() private view returns (uint256) {
        return (100 - fee) / 100;
    }

    function resolve(uint256 id, uint256 startPrice, uint256 closePrice) external onlyOwner {
        _resolve(id, startPrice, closePrice);
    }

    function toggleOption() public onlyOwner {
        isStarted = !isStarted;
    }

    function setApedFeed(IPriceFeedAPED newApedFeed) public onlyOwner {
        priceFeed = newApedFeed;
    }

    function setOptionName(string calldata newOptionName) public onlyOwner {
        optionName = newOptionName;
    }

    function setTokenIn(address newAddress) public onlyOwner {
        tokenIn = newAddress;
    }

    function setTokensOut(address[] calldata newTokensOut) public onlyOwner {
        tokensOut = newTokensOut;
    }

    function setPoolFees(uint24[] calldata newPoolFees) public onlyOwner {
        poolFees = newPoolFees;
    }

    function setFeeKeeper(address newFeeKeeper) public onlyOwner {
        feeKeeper = newFeeKeeper;
    }

    function setFee(uint256 newFee) public onlyOwner {
        fee = newFee;
    }

    function setStartTimestamp(uint256 newStartTimestamp) public onlyOwner {
        startTimestamp = newStartTimestamp;
    }

    function setDepositPeriod(uint256 newDepositPeriod) public onlyOwner {
        depositPeriod = newDepositPeriod;
    }

    function setLockPeriod(uint256 newLockPeriod) public onlyOwner {
        lockPeriod = newLockPeriod;
    }
}