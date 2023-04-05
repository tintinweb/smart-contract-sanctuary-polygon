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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./OptionAPED.sol";

contract FactoryAPED is Ownable {

    struct Options {
        address optionAddress;
        string optionName;
    }

    event Created(address indexed creator, address indexed collection, uint256 counter);

    uint256 public optionCounter;
    mapping(uint256 => Options) public options;

    constructor() {}

    function createCollection(
        address apedFeed,
        string memory optionName,
        address tokenIn,
        address[] calldata tokensOut,
        uint24[] calldata poolFees,
        address tokenBid,
        address feeKeeper,
        uint256 fee,
        uint256 startTimestamp
        ) public 
    {
        optionCounter++;
        require(tokensOut.length == poolFees.length, "Wrong arrays calldata");
        OptionAPED option = new OptionAPED(
            apedFeed,
            optionName,
            tokenIn,
            tokensOut,
            poolFees,
            tokenBid,
            feeKeeper,
            fee,
            startTimestamp,
            msg.sender
        );
        options[optionCounter] = Options(address(option), optionName);
    }

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPriceFeedAPED} from "./interfaces/IPriceFeedAPED.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract OptionAPED is Ownable {
    
    struct Option {
        uint256 startTs; // start time in seconds since Unix epoch
        uint256 endTs; // end time in seconds since Unix epoch
        uint256 startPrice;
        uint256 closePrice;
        uint256 upBets; // total amount of bets on up outcome
        uint256 downBets; // total amount of bets on down outcome
        OptionStage result; 
    }

    struct Client {
        address user;
        uint256 betAmount;
        OptionStage selectedOption;
        bool claimed;
    }

    struct OptionInfo {
        OptionStage optionStage;
        uint256 optionIndex;
        string optionName;
        address tokenIn;
        address[] tokensOut;
        address tokenBid;
        address feeKeeper;
        uint256 fee;
        uint256 startTs;
        uint256 endTs;
        uint256 startPrice;
        uint256 closePrice;
        uint256 upBets;
        uint256 downBets;
    }

    enum OptionStage{
        NotStarted,
        Deposits,
        Lock,
        Down,
        Up,
        NotChanged
    }

    IPriceFeedAPED public apedFeed;
    string public optionName;
    address public tokenIn;
    address[] public tokensOut;
    uint24[] public poolFees;
    address public tokenBid;
    address public feeKeeper;
    uint256 public optionsCounter;
    uint256 public fee;
    bool public isStarted;
    
    mapping(uint256 => Option) public options; // mapping of binary options
    mapping(address => uint256[]) public userOptions;
    mapping(address => mapping(uint256 => Client)) public clients;

    event NewOption(uint256 id, uint256 start, uint256 end);
    event BetPlaced(uint256 id, address user, uint256 amount, bool outcome);
    event OptionResolved(uint256 id, bool outcome);
    event FundsWithdrawn(uint256 id, address user, uint256 amount);

    constructor(
        address apedFeed_,
        string memory optionName_,
        address tokenIn_,
        address[] memory tokensOut_,
        uint24[] memory poolFees_,
        address tokenBid_,
        address feeKeeper_,
        uint256 fee_,
        uint256 startTimestamp_,
        address owner
    ) {
        apedFeed = IPriceFeedAPED(apedFeed_);
        optionName = optionName_;
        tokenIn = tokenIn_;
        tokensOut = tokensOut_;
        poolFees = poolFees_;
        tokenBid = tokenBid_;
        feeKeeper = feeKeeper_;
        fee = fee_;
        startOptions(startTimestamp_);
        _transferOwnership(owner);
    }

    function toggleOption() public onlyOwner {
        isStarted = !isStarted;
    }

    function startOptions(uint256 _startTimestamp) public onlyOwner {
        optionsCounter++;
        options[optionsCounter] = Option(
            _startTimestamp,
            _startTimestamp + 30 minutes,
            0, 0, 0, 0,
            OptionStage.NotStarted
        );
        startNewOption();
    }

    function startNewOption() internal  {
        options[optionsCounter + 1] = Option(
            options[optionsCounter].endTs,
            options[optionsCounter].endTs + 30 minutes,
            0, 0, 0, 0,
            OptionStage.NotStarted
        );
    }

    function getOptionInfo(uint256 _index) public view returns(OptionInfo memory option){
        uint256 id = getOptionIndex(_index);
        option = OptionInfo(
            getOptionStage(id),
            id,
            optionName,
            tokenIn,
            tokensOut,
            tokenBid,
            feeKeeper,
            fee,
            options[id].startTs,
            options[id].endTs,
            options[id].startPrice > 0 ? options[id].startPrice : getPrice(options[id].startTs),
            options[id].closePrice > 0 ? options[id].closePrice : getPrice(options[id].closePrice),
            options[id].upBets,
            options[id].downBets
        );
    }

    function detAllClientOptionsInfo(address client) public view returns(Client[] memory) {
        uint256[] memory _optionIds = userOptions[client];
        uint256 _size = _optionIds.length;
        Client[] memory _options = new Client[](_size);
        for (uint256 i = 0; i < _size; ) {
            _options[i] = getClientOptionInfo(client, _optionIds[i]);
        unchecked {i++;}
        }
        return _options;
    }

    function getClientOptionInfo(address client, uint256 _index) public view returns(Client memory){
        uint256 id = getOptionIndex(_index);
        return clients[client][id];
    }

    function getOptionStage(uint256 _index) public view returns (OptionStage) {
        uint256 _indexOption = getOptionIndex(_index);
        if (_indexOption == 0 || !isStarted || options[_indexOption].startTs > block.timestamp + 5 minutes) {
            return OptionStage.NotStarted;
        }
        if (block.timestamp > options[_indexOption].endTs) {
            return options[_indexOption].result > OptionStage.Lock ? options[_indexOption].result : OptionStage.Lock;
        }
        if (block.timestamp > options[_indexOption].startTs) {
            return OptionStage.Lock;
        }
        return OptionStage.Deposits;
    }

    function getOptionIndex(uint256 _index) public view returns (uint256) {
        return _index > 0 ? _index : optionsCounter;
    }

    function placeBet(uint256 _betAmount, OptionStage _selectedOption) payable external {
        require(_selectedOption == OptionStage.Down || _selectedOption == OptionStage.Up, "Wrong choice");
        if (getOptionStage(optionsCounter + 1) == OptionStage.Deposits) {
            optionsCounter++;
            startNewOption();
        } 
        OptionStage stage = getOptionStage(optionsCounter);
        require(stage == OptionStage.Deposits, "Option is not started yet");        
        require(_betAmount > 0, "Bet amount must be greater than 0");

        usdtTransfer(msg.sender, address(this), _betAmount);
        _selectedOption ==  OptionStage.Down ? options[optionsCounter].downBets += _betAmount : options[optionsCounter].upBets += _betAmount;
        if (userOptions[msg.sender].length == 0 || userOptions[msg.sender][userOptions[msg.sender].length - 1] != optionsCounter) {
            userOptions[msg.sender].push(optionsCounter);
            clients[msg.sender][optionsCounter].user = msg.sender;
            clients[msg.sender][optionsCounter].selectedOption = _selectedOption;
        } else {
            require(_selectedOption == clients[msg.sender][optionsCounter].selectedOption, "You alredy choosed another bet");
        }
        clients[msg.sender][optionsCounter].betAmount += _betAmount;
        // emit BetPlaced(id, msg.sender, msg.value, outcome);
    }

    function usdtTransfer(address from, address to, uint256 amount) internal {
        uint256 _balance = IERC20(tokenBid).balanceOf(from);
        IERC20(tokenBid).transferFrom(from, to, amount);
        require(IERC20(tokenBid).balanceOf(from) == _balance - amount, "TransferFrom Error");
    }

    function getWonAmount(address _user, uint256 _index) public view returns(uint256) {
        uint256 rewardAmount;
        if (options[_index].result ==  OptionStage.Down) {
            rewardAmount = clients[_user][_index].selectedOption ==  OptionStage.Down ?
                (options[_index].upBets * clients[_user][_index].betAmount / options[_index].downBets) * (100 - fee) / 100: 
                0;
        } else rewardAmount = clients[_user][_index].selectedOption ==  OptionStage.Up ? 
            (options[_index].downBets * clients[_user][_index].betAmount / options[_index].upBets) * (100 - fee) / 100: 
            0;
            
        return rewardAmount;
    }

    // тесты  

    function getPrice(uint256 timeStamp) public view returns(uint256) {
        return block.timestamp > timeStamp ? IPriceFeedAPED(apedFeed).getPrice(tokenIn, tokensOut, poolFees, uint32(block.timestamp - timeStamp)) : 0;
    }
    
    function resolveOption(uint256 id) internal {
        Option storage option = options[id];
        // require(block.timestamp > option.endTs, "Option isn't ended");
        option.startPrice = getPrice(option.startTs);
        option.closePrice = getPrice(option.endTs);
        uint256 amountFee;
        if (option.closePrice > option.startPrice) {
            options[id].result = OptionStage.Up;
            amountFee = options[id].upBets * fee / 100;
        } else {
            if (option.closePrice < option.startPrice) {
                options[id].result = OptionStage.Down;
                amountFee = options[id].downBets * fee / 100;
            } else {
                options[id].result = OptionStage.NotChanged;
                amountFee = 0;
            }
        }
        usdtTransfer(address(this), feeKeeper, amountFee);
        // emit OptionResolved(id, outcome);
    }

    function batchRecive(uint256[] calldata ids) external {
        require(ids.length > 0, "Wrong calldata");
        for (uint256 i = 0; i < ids.length;) {
            receiveFunds(ids[i]);
        unchecked {i++;}
        }
    }

    function receiveFunds(uint256 _index) public {
        uint256 id = getOptionIndex(_index);
        OptionStage stage = getOptionStage(id);
        if (stage < OptionStage.Down && block.timestamp >= options[id].endTs) {
            resolveOption(id);
            stage = getOptionStage(id);
        }
        require(stage >= OptionStage.Down, "Option isn't ended");
        require(!clients[msg.sender][id].claimed, "You already claimed");
        clients[msg.sender][id].claimed = true;
        usdtTransfer(address(this), msg.sender, getWonAmount(msg.sender, id));
    }
}