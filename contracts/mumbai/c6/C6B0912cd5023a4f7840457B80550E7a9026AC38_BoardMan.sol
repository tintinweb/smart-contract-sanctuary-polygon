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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./helper.sol";


contract BoardMan is Ownable, helper {
    uint8 constant PRECISION = 18;

    // EVENTS
    event BETCREATED (
        uint256 betId_, uint256 deadline_, string name_,
        bytes32 choiceOne_, bytes32 choiceTwo_,
        address betMaster_, uint8 numOfChoices_
    );
    event BETCREATED (
        uint256 betId_, uint256 deadline_, string name_,
        bytes32 choiceOne_, bytes32 choiceTwo_, bytes32 choiceThree_,
        address betMaster_, uint8 numOfChoices_
    );
    event BETCREATED (
        uint256 betId_, uint256 deadline_, string name_,
        bytes32 choiceOne_, bytes32 choiceTwo_, bytes32 choiceThree_, 
        bytes32 choiceFour_, address betMaster_, uint8 numOfChoices_
    );
    event BETPLACED( 
        address pundit_, uint256 betId_, 
        Choices choice_, uint256 amount_
    );
    event BETEXECUTED(
        uint256 betId_, uint8 correctChoice_, bool executed_
    );
    event PAYOUTCLAIMED(
        uint256 betId_, uint256 amount_, address pundit_
    );

    struct AmountMaps{
        mapping(uint8 => uint256) choiceAmountMap;
    }

    struct ChoiceOne {
        bytes32 choiceOne_;
        uint32 choiceOneNoB;
        uint256 choiceOneAmount;
        uint256 oddOne;
        uint256 finalOddOne;
    }

    struct ChoiceTwo {
        bytes32 choiceTwo_;
        uint32 choiceTwoNoB;
        uint256 choiceTwoAmount;
        uint256 oddTwo;
        uint256 finalOddTwo;
    }

    struct ChoiceThree {
        bytes32 choiceThree_;
        uint32 choiceThreeNoB;
        uint256 choiceThreeAmount;
        uint256 oddThree;
        uint256 finalOddThree;
    }

    struct ChoiceFour {
        bytes32 choiceFour_;
        uint32 choiceFourNoB;
        uint256 choiceFourAmount;
        uint256 oddFour;
        uint256 finalOddFour;
    }

    struct Totals {
        uint256 totalAmountCorrectChoice;
        uint256 totalNumberOfBetsCorrectChoice;
        uint256 totalBets;
        uint256 totalAmount;
    }

    struct INIT {
        uint256 betId;
        // deadline - the UNIX timestamp until which this bet Event is active.
        uint256 deadline;
        // Bet Event Name;
        string name;
        // Bet Creator address;
        address betMaster;
        
        uint256 creationFee;
        uint8 numOfChoices;
                
    }

    struct FINALIZE {
        uint8 correctChoice;
        bool finalOddsUpdated;
        bool executed;
    }

    struct BetEvent {
        INIT init;

        ChoiceOne choiceOne;

        ChoiceTwo choiceTwo;

        ChoiceThree choiceThree;

        ChoiceFour choiceFour;

        Totals totals;

        FINALIZE finalize;

        mapping(uint8 => uint256) finalOddsMaps;

        mapping(address => AmountMaps) amountMaps;
    }

    // Create a mapping of ID to BetEvent
    mapping(uint256 => BetEvent) public betEvents;

    uint256 public numBetEvents;

    uint256 private createBetEventFee;
    uint256 private minBetFee;

    // Create a payable constructor which initializes the contract
    
    // The payable allows this constructor to accept an ETH deposit when it is being deployed
    constructor(uint256 _createBetEventFee, uint256 _minBetFee) payable {
        createBetEventFee = _createBetEventFee;
        minBetFee = _minBetFee;
    }

    function createBetEvent(
        string memory _name, 
        uint256 _deadline,
        bytes32 _choiceOne,
        bytes32 _choiceTwo
        )
        external payable
        validateDeadline(_deadline)
        returns (uint256)
    {
        require(msg.value >= createBetEventFee, "PAY BET EVENT FEE");
        BetEvent storage betEvent = betEvents[numBetEvents];
        betEvent.init.betId = numBetEvents;
        // Set the bet Events deadline
        betEvent.init.deadline = _deadline;
        betEvent.init.name = _name;
        betEvent.choiceOne.choiceOne_ = _choiceOne;
        betEvent.choiceTwo.choiceTwo_ = _choiceTwo;
        betEvent.init.betMaster = msg.sender;
        betEvent.choiceOne.choiceOneNoB = 1;
        betEvent.choiceTwo.choiceTwoNoB = 1;

        betEvent.choiceOne.choiceOneAmount = msg.value/2;
        betEvent.choiceTwo.choiceTwoAmount = msg.value/2;
        betEvent.init.creationFee = msg.value;

        validChoices(numBetEvents);
        emit BETCREATED(
            numBetEvents,
            _deadline,
            _name,
            _choiceOne,
            _choiceTwo,
            betEvent.init.betMaster,
            betEvent.init.numOfChoices
            );
        numBetEvents++;
        return numBetEvents - 1;
    }

    function createBetEvent(
        string memory _name, 
        uint256 _deadline,
        bytes32 _choiceOne,
        bytes32 _choiceTwo,
        bytes32 _choiceThree
        )
        external payable
        validateDeadline(_deadline)
        returns (uint256)
    {
        require(msg.value >= createBetEventFee, "PAY BET EVENT FEE");
        BetEvent storage betEvent = betEvents[numBetEvents];
        betEvent.init.betId = numBetEvents;
        // Set the bet Events deadline
        betEvent.init.deadline = _deadline;
        betEvent.init.name = _name;
        betEvent.choiceOne.choiceOne_ = _choiceOne;
        betEvent.choiceTwo.choiceTwo_ = _choiceTwo;
        betEvent.choiceThree.choiceThree_ = _choiceThree;
        betEvent.init.betMaster = msg.sender;
        betEvent.choiceOne.choiceOneNoB = 1;
        betEvent.choiceTwo.choiceTwoNoB = 1;
        betEvent.choiceThree.choiceThreeNoB = 1;

        uint256 amount = msg.value;
        uint256 splitAmount = amount/3;
        betEvent.choiceOne.choiceOneAmount = splitAmount;
        betEvent.choiceTwo.choiceTwoAmount = splitAmount;
        betEvent.choiceThree.choiceThreeAmount = splitAmount;
        betEvent.init.creationFee = amount;

        validChoices(numBetEvents);
        emit BETCREATED(
            numBetEvents,
            _deadline,
            _name,
            _choiceOne,
            _choiceTwo,
            _choiceThree,
            betEvent.init.betMaster,
            betEvent.init.numOfChoices
            );
        numBetEvents++;
        return numBetEvents - 1;
    }

    function createBetEvent(
        string memory _name, 
        uint256 _deadline,
        bytes32 _choiceOne,
        bytes32 _choiceTwo,
        bytes32 _choiceThree,
        bytes32 _choiceFour
        )
        external payable
        validateDeadline(_deadline)
        returns (uint256)
    {
        require(msg.value >= createBetEventFee, "PAY BET EVENT FEE");
        BetEvent storage betEvent = betEvents[numBetEvents];
        betEvent.init.betId = numBetEvents;
        // Set the bet Events deadline
        betEvent.init.deadline = _deadline;
        betEvent.init.name = _name;
        betEvent.choiceOne.choiceOne_ = _choiceOne;
        betEvent.choiceTwo.choiceTwo_ = _choiceTwo;
        betEvent.choiceThree.choiceThree_ = _choiceThree;
        betEvent.choiceFour.choiceFour_ = _choiceFour;
        betEvent.init.betMaster = msg.sender;
        betEvent.choiceOne.choiceOneNoB = 1;
        betEvent.choiceTwo.choiceTwoNoB = 1;
        betEvent.choiceThree.choiceThreeNoB = 1;
        betEvent.choiceFour.choiceFourNoB = 1;

        uint256 amount = msg.value;
        uint256 splitAmount = amount/3;
        betEvent.choiceOne.choiceOneAmount = splitAmount;
        betEvent.choiceTwo.choiceTwoAmount = splitAmount;
        betEvent.choiceThree.choiceThreeAmount = splitAmount;
        betEvent.choiceFour.choiceFourAmount = splitAmount;
        betEvent.init.creationFee = amount;

        validChoices(numBetEvents);
        emit BETCREATED(
            numBetEvents,
            _deadline,
            _name,
            _choiceOne,
            _choiceTwo,
            _choiceThree,
            _choiceFour,
            betEvent.init.betMaster,
            betEvent.init.numOfChoices
            );
        numBetEvents++;
        return numBetEvents - 1;
    }

    // Create a modifier which only allows a function to be
    // called if the given bet EVents deadline has not been exceeded yet
    modifier activeBetEventOnly(uint256 _betId) {
        require(
            betEvents[_betId].init.deadline > block.timestamp,
            "DEADLINE_EXCEEDED"
        );
        _;
    }

    modifier validateBetFee() {
        require(msg.value >= minBetFee, "PLACE A HIGHER BET");
        _;
    }

    enum Choices {
        choiceOne_,
        choiceTwo_,
        choiceThree_,
        choiceFour_
    }

    function validChoices(uint256 _betId) internal returns (uint8) {
        BetEvent storage betEvent = betEvents[_betId];
        uint256 valid;
        uint8 numChoices;
        valid = uint(betEvent.choiceOne.choiceOne_);
        if (valid != 0) {
            numChoices++;
        }
        valid = uint(betEvent.choiceTwo.choiceTwo_);
        if (valid != 0) {
            numChoices++;
        }
        valid = uint(betEvent.choiceThree.choiceThree_);
        if (valid != 0) {
            numChoices++;
        }
        valid = uint(betEvent.choiceFour.choiceFour_);
        if (valid != 0) {
            numChoices++;
        }
        betEvent.init.numOfChoices = numChoices;
        return numChoices;
    }
    function checkValidChoices(uint256 _betId, uint8 option) internal view validateChoices(option) returns(uint256 valid) {
        BetEvent storage betEvent = betEvents[_betId];
        if (option == 0) {
            valid = uint(betEvent.choiceOne.choiceOne_);
            require(valid != 0, "INVALID: EMPTY CHOICE");
            return valid;
        }
        if (option == 1) {
            valid = uint(betEvent.choiceTwo.choiceTwo_);
            require(valid != 0, "INVALID: EMPTY CHOICE");
            return valid;
        }
        if (option == 2) {
            valid = uint(betEvent.choiceThree.choiceThree_);
            require(valid != 0, "INVALID: EMPTY CHOICE");
            return valid;
        }
        if (option == 3) {
            valid = uint(betEvents[_betId].choiceFour.choiceFour_);
            require(valid != 0, "INVALID: EMPTY CHOICE");
            return valid;
        }
        
    }

    function placeBet(uint256 _betId, Choices choice_)
        external payable
        activeBetEventOnly(_betId)
        validateBetFee returns (bool success)
    {
        BetEvent storage betEvent = betEvents[_betId];
        uint256 amount = msg.value;

        if (choice_ == Choices.choiceOne_) {
            uint8 option = 0;
            checkValidChoices(_betId, option);
            betEvent.choiceOne.choiceOneNoB += 1;
            betEvent.choiceOne.choiceOneAmount += amount;
            betEvent.amountMaps[msg.sender].choiceAmountMap[0] += amount;
            success = true;
            emit BETPLACED (
                msg.sender,
                _betId,
                choice_,
                amount
            );
            recalcOdds(_betId);
            return success;
        }
        if (choice_ == Choices.choiceTwo_) {
            uint8 option = 1;
            checkValidChoices(_betId, option);
            betEvent.choiceTwo.choiceTwoNoB += 1;
            betEvent.choiceTwo.choiceTwoAmount += amount;
            betEvent.amountMaps[msg.sender].choiceAmountMap[1] += amount;
            success = true;
            emit BETPLACED (
                msg.sender,
                _betId,
                choice_,
                amount
            );
            recalcOdds(_betId);
            return success;
        }
        if (choice_ == Choices.choiceThree_) {
            uint8 option = 2;
            checkValidChoices(_betId, option);
            betEvent.choiceThree.choiceThreeNoB += 1;
            betEvent.choiceThree.choiceThreeAmount += amount;
            betEvent.amountMaps[msg.sender].choiceAmountMap[2] += amount;
            success = true;
            emit BETPLACED (
                msg.sender,
                _betId,
                choice_,
                amount
            );
            recalcOdds(_betId);
            return success;
        }
        if (choice_ == Choices.choiceFour_) {
            uint8 option = 3;
            checkValidChoices(_betId, option);
            betEvent.choiceFour.choiceFourNoB += 1;
            betEvent.choiceFour.choiceFourAmount += amount;
            betEvent.amountMaps[msg.sender].choiceAmountMap[3] += amount;
            success = true;
            emit BETPLACED (
                msg.sender,
                _betId,
                choice_,
                amount
            );
            recalcOdds(_betId);
            return success;
        }
    }

    
    modifier inactiveBetEvent(uint256 _betId) {
        require(
            betEvents[_betId].init.deadline <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            betEvents[_betId].finalize.executed == false,
            "BET_EVENT_ALREADY_EXECUTED"
        );
        _;
    }

    modifier inactiveBetEventToClaim(uint256 _betId) {
        require(
            betEvents[_betId].init.deadline <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            betEvents[_betId].finalize.executed == true,
            "BET_EVENT_NOT_EXECUTED"
        );
        _;
    }

    modifier onlyBetMaster(uint256 _betId) {
        address caller = msg.sender;
        require(caller == betEvents[_betId].init.betMaster,
        "NOT_THE_BET_MASTER"
        );
        _;
    }

    function checkIfBetMaster(uint256 _betId) external view returns (bool) {
        address caller = msg.sender;
        if (caller == betEvents[_betId].init.betMaster) {
            return true;
        }
        return false;
    }

    function viewBetMaster(uint256 _betId) external view returns (address) {
        return betEvents[_betId].init.betMaster;
    }

    function addAmountCorrectChoice(uint256 _betId, uint8 _correctChoice)
        internal
        validateChoices(_correctChoice)
        inactiveBetEventToClaim(_betId)
        onlyBetMaster(_betId)
        returns (bool success)
    {
        BetEvent storage betEvent = betEvents[_betId];

        if (_correctChoice == 0) {
            betEvent.totals.totalNumberOfBetsCorrectChoice = betEvent.choiceOne.choiceOneNoB;
            betEvent.totals.totalAmountCorrectChoice = betEvent.choiceOne.choiceOneAmount;
            success = true;
            return success;
        }
        if (_correctChoice == 1) {
            betEvent.totals.totalNumberOfBetsCorrectChoice = betEvent.choiceTwo.choiceTwoNoB;
            betEvent.totals.totalAmountCorrectChoice = betEvent.choiceTwo.choiceTwoAmount;
            success = true;
            return success;
        }
        if (_correctChoice == 2) {
            betEvent.totals.totalNumberOfBetsCorrectChoice = betEvent.choiceThree.choiceThreeNoB;
            betEvent.totals.totalAmountCorrectChoice = betEvent.choiceThree.choiceThreeAmount;
            success = true;
            return success;
        }
        if (_correctChoice == 3) {
            betEvent.totals.totalNumberOfBetsCorrectChoice = betEvent.choiceFour.choiceFourNoB;
            betEvent.totals.totalAmountCorrectChoice = betEvent.choiceFour.choiceFourAmount;
            success = true;
            return success;
        }
    }

    function getTotalBets (uint256 _betId) internal returns (uint256) {
        BetEvent storage betEvent = betEvents[_betId];
        uint32 totalChoiceOneBets = betEvent.choiceOne.choiceOneNoB;
        uint32 totalChoiceTwoBets = betEvent.choiceTwo.choiceTwoNoB;
        uint32 totalChoiceThreeBets = betEvent.choiceThree.choiceThreeNoB;
        uint32 totalChoiceFourBets = betEvent.choiceFour.choiceFourNoB;
        betEvent.totals.totalBets = totalChoiceOneBets + totalChoiceTwoBets + totalChoiceThreeBets + totalChoiceFourBets;
        return betEvent.totals.totalBets;
    }

    function getTotalAmount (uint256 _betId) internal returns (uint256) {
        BetEvent storage betEvent = betEvents[_betId];
        uint256 totalChoiceOneAmount = betEvent.choiceOne.choiceOneAmount;
        uint256 totalChoiceTwoAmount = betEvent.choiceTwo.choiceTwoAmount;
        uint256 totalChoiceThreeAmount = betEvent.choiceThree.choiceThreeAmount;
        uint256 totalChoiceFourAmount = betEvent.choiceFour.choiceFourAmount;
        betEvent.totals.totalAmount = totalChoiceOneAmount + totalChoiceTwoAmount + totalChoiceThreeAmount + totalChoiceFourAmount;
        return betEvent.totals.totalAmount;
    }

    function recalcOdds (uint256 _betId) internal returns
    (uint256, uint256, uint256, uint256) {
        BetEvent storage betEvent = betEvents[_betId];
        uint256 _oddOne;
        uint256 _oddTwo;
        uint256 _oddThree;
        uint256 _oddFour;
        (_oddOne, _oddTwo, _oddThree, _oddFour) = execChoiceBetEvent(_betId);
        betEvent.choiceOne.oddOne = _oddOne;
        betEvent.choiceTwo.oddTwo = _oddTwo;
        betEvent.choiceThree.oddThree = _oddThree;
        betEvent.choiceFour.oddFour = _oddFour;
        return (_oddOne, _oddTwo, _oddThree, _oddFour);
    }
    function executeBetEvent(uint256 _betId, uint8 _correctChoice)
        external
        validateChoices(_correctChoice)
        inactiveBetEvent(_betId) 
        onlyBetMaster(_betId)
        returns (bool success) 
    {
        checkValidChoices(_betId, _correctChoice);
        BetEvent storage betEvent = betEvents[_betId];
        betEvent.finalize.correctChoice = _correctChoice;
        getTotalAmount(_betId);
        getTotalBets(_betId);
        betEvent.finalize.executed = true;
        addAmountCorrectChoice(_betId, _correctChoice);
        validChoices(_betId);
        recalcOdds(_betId);
        emit BETEXECUTED(
            _betId, _correctChoice, betEvent.finalize.executed
        );
        return betEvent.finalize.executed;
    }

    function getStageOneOdds(uint256 _betId) public view 
    returns (
        uint256, uint256, uint256, uint256
    ) {
        BetEvent storage betEvent = betEvents[_betId];
        uint256 _oddOne = betEvent.choiceOne.oddOne;
        uint256 _oddTwo = betEvent.choiceTwo.oddTwo;
        uint256 _oddThree = betEvent.choiceThree.oddThree;
        uint256 _oddFour = betEvent.choiceFour.oddFour;
        return (_oddOne, _oddTwo, _oddThree, _oddFour);
    }

    function getNumeratorOne(uint256 _betId) internal view returns (uint256) {
        BetEvent storage betEvent = betEvents[_betId];
        uint32 choiceOneNOB = betEvent.choiceOne.choiceOneNoB;
        uint256 choiceOneAmount = betEvent.choiceOne.choiceOneAmount;
        uint256 numerator1 = choiceOneNOB * choiceOneAmount *1e18;
        return numerator1;
    }

    function getNumeratorTwo(uint256 _betId) internal view returns (uint256) {
        BetEvent storage betEvent = betEvents[_betId];
        uint32 choiceTwoNOB = betEvent.choiceTwo.choiceTwoNoB;
        uint256 choiceTwoAmount = betEvent.choiceTwo.choiceTwoAmount;
        uint256 numerator2 = choiceTwoNOB * choiceTwoAmount *1e18;
        return numerator2;
    }

    function getNumeratorThree(uint256 _betId) internal view returns (uint256) {
        BetEvent storage betEvent = betEvents[_betId];
        uint32 choiceThreeNOB = betEvent.choiceThree.choiceThreeNoB;
        uint256 choiceThreeAmount = betEvent.choiceThree.choiceThreeAmount;
        uint256 numerator3 = choiceThreeNOB * choiceThreeAmount *1e18;
        return numerator3;
    }

    function getNumeratorFour(uint256 _betId) internal view returns (uint256) {
        BetEvent storage betEvent = betEvents[_betId];
        uint32 choiceFourNOB = betEvent.choiceFour.choiceFourNoB;
        uint256 choiceFourAmount = betEvent.choiceFour.choiceFourAmount;
        uint256 numerator4 = choiceFourNOB * choiceFourAmount *1e18;
        return numerator4;
    }

    function getDenominator(uint256 _betId) internal returns (uint256) {
        uint256 totalNOB = getTotalBets(_betId);
        uint256 totalAmount = getTotalAmount(_betId);
        uint256 denominator = totalNOB * totalAmount;
        return denominator;
    }
    function execChoiceBetEvent(uint256 _betId) internal
    returns (uint256 odds1, uint256 odds2, uint256 odds3, uint256 odds4) {

        (odds1, odds2, odds3, odds4) = oddsFourCalculator(getNumeratorOne(_betId), 
        getNumeratorTwo(_betId), getNumeratorThree(_betId), 
        getNumeratorFour(_betId), getDenominator(_betId)
        );
        return(odds1, odds2, odds3, odds4);
    }

    function viewCorrectChoice(uint256 _betId) 
    public view 
    inactiveBetEventToClaim(_betId) 
    returns (uint8 correctChoice) {
        return betEvents[_betId].finalize.correctChoice;
    }

    function finalOdds(uint256 _betId, uint256 odds1, uint256 odds2,
    uint256 odds3, uint256 odds4) public 
    inactiveBetEventToClaim(_betId)
    onlyBetMaster(_betId)
    returns (uint256 finalOdds1, uint256 finalOdds2, uint256 finalOdds3, uint256 finalOdds4) {
        BetEvent storage betEvent = betEvents[_betId];
        betEvent.choiceOne.finalOddOne = odds1;
        betEvent.choiceTwo.finalOddTwo = odds2;
        betEvent.choiceThree.finalOddThree = odds3;
        betEvent.choiceFour.finalOddFour = odds4;
        betEvent.finalOddsMaps[0] = odds1;
        betEvent.finalOddsMaps[1] = odds2;
        betEvent.finalOddsMaps[2] = odds3;
        betEvent.finalOddsMaps[3] = odds4;
        betEvent.finalize.finalOddsUpdated = true;
        return (odds1, odds2, odds3, odds4);
    }

    function viewFinalOdds(uint256 _betId) external view
    returns (uint256 finalOdd1, uint256 finalOdd2, uint256 finalOdd3, uint256 finalOdd4) {
        finalOdd1 = betEvents[_betId].choiceOne.finalOddOne;
        finalOdd2 = betEvents[_betId].choiceTwo.finalOddTwo;
        finalOdd3 = betEvents[_betId].choiceThree.finalOddThree;
        finalOdd4 = betEvents[_betId].choiceFour.finalOddFour;
        return (finalOdd1, finalOdd2, finalOdd3, finalOdd4);
    }

    modifier onlyWinners (uint256 _betId) {
        address pundit = msg.sender;
        BetEvent storage betEvent = betEvents[_betId];
        uint8 correctChoice__ = betEvent.finalize.correctChoice;
        uint256 amountBet = betEvent.amountMaps[pundit].choiceAmountMap[correctChoice__];
        require(amountBet > 0, "Sorry, WINNERS ONLY");
        _;
    }

    modifier onlyWhenFinalOddsUpdated (uint256 _betId) {
        BetEvent storage betEvent = betEvents[_betId];
        bool finalOddsUpdated = betEvent.finalize.finalOddsUpdated;
        require(finalOddsUpdated == true, "Final Odds Not Updated");
        _;
    }
    function claimPayout(uint256 _betId) external
    inactiveBetEventToClaim(_betId) 
    onlyWinners(_betId)
    onlyWhenFinalOddsUpdated(_betId)
    returns (bool success) {
        BetEvent storage betEvent = betEvents[_betId];
        uint8 correctChoice__ = betEvent.finalize.correctChoice;
        uint256 amountBet = betEvent.amountMaps[msg.sender].choiceAmountMap[correctChoice__];
        uint256 payout = (amountBet * betEvent.finalOddsMaps[correctChoice__])/(10 ** PRECISION);
        betEvent.amountMaps[msg.sender].choiceAmountMap[correctChoice__] = 0;
        (success, ) = payable(msg.sender).call{value: payout}("");
        require(success, "Failed to send Ether");
        emit PAYOUTCLAIMED (
            _betId, payout, msg.sender
        );

        return success;
    }

    function claimBetMaster(uint256 _betId) external payable 
    onlyBetMaster(_betId)
    inactiveBetEventToClaim(_betId) returns (bool success){
        BetEvent storage betEvent = betEvents[_betId];
        uint256 _amount = betEvent.totals.totalAmountCorrectChoice;
        uint256 _totalAmount = betEvent.totals.totalAmount;
        address betMasterAddress = betEvent.init.betMaster;
        success = payCut(_betId, _amount, _totalAmount, betMasterAddress);
        return success;
    }

    function viewBetEventFee() public view returns (uint256) {
        return createBetEventFee;
    }

    function viewMinBetFee() public view returns (uint256) {
        return minBetFee;
    }
    /// @dev withdrawEther allows the contract owner (deployer) to withdraw the ETH from the contract
    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // The following two functions allow the contract to accept ETH deposits
    // directly from a wallet without calling a function
    receive() external payable {}

    fallback() external payable {}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract helper {
    // Helper Contract
    event BETMASTERPAYOUTCLAIMED(
        uint256 betId_, uint256 profit_, address betMaster_
    );

    modifier validateChoices (uint8 _choice) {
        require(_choice >= 0 && _choice <= 3, "INVALID CHOICE NUMBER");
        _;        
    }

    modifier validateDeadline(uint256 _deadline) {
        require(_deadline > (block.timestamp + 5 minutes), "INVALID DEADLINE: TOO SHORT");
        require(_deadline < (block.timestamp + 365 days), "INVALID DEADLINE: TOO LONG");
        _;
    }
    function oddsFourCalculator (
        uint256 numerator1,
        uint256 numerator2,
        uint256 numerator3,
        uint256 numerator4,
        uint256 denominator
    ) internal pure returns(uint256 odds1, uint256 odds2, uint256 odds3, uint256 odds4) {
        
        odds1 = numerator1/denominator;
        odds2 = numerator2/denominator;
        odds3 = numerator3/denominator;
        odds4 = numerator4/denominator;
        return (odds1, odds2, odds3, odds4);
    }

    function payCut(uint256 _betId, uint256 _payoutAmount, uint256 _totalAmount, address _betMaster) internal 
    returns (bool success) {
        uint256 profit = _totalAmount - _payoutAmount;
        uint256 percentCut = (profit * 5)/100;
        if (percentCut > 0) {
            (success, ) = _betMaster.call{value: profit}("");
            require (success, "BET MASTER PAID");
            emit BETMASTERPAYOUTCLAIMED (
                _betId, profit, _betMaster
            );
            return success;
        } else {
            require(percentCut > 0, "NOTHING TO WITHDRAW");
        }
    }
}