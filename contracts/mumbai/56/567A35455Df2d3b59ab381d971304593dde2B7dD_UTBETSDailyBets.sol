// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Interface/IUltiBetsToken.sol";
import "../Interface/IUltiBetsSign.sol";
import "../Utils/UltibetsCore.sol";

interface IUltibetsBuyback {
    function burnUTBETS() external;
}

interface ITreasury {
    function sendReferReward(address, uint256) external;

    function sendRefBetRefund(address, uint256) external;
}

interface IUltiBetsLeaderBoard {
    function isInfluencer(address) external view returns (bool);
}

interface ISquidBetNFTClaimer {
    function usePerkForBet(uint8) external;
}

interface IUltibetsReward {
    function payForPerk(uint8) external;

    function betUsingReferralCode(address, uint256) external;

    function freebetAmountForSBCRoundNFTPerk(
        uint8
    ) external view returns (uint256);

    function updateRewardTier(uint256) external;
}

contract UTBETSDailyBets is UltibetsCore {
    using EnumerableSet for EnumerableSet.UintSet;

    IUltiBetsToken public UTBETSContract;

    address public ultiBetsLeaderBoard;
    address public squidBetNFTClaimer;
    address public ultibetsReward;
    address public ultibetsSign;

    mapping(address => bool) public isNotFirstBet;

    /// @param _ultiBetsTreasury address of the treasury contract
    constructor(
        address _ultiBetsTreasury,
        address _ultibetsBuyback,
        address _squidBetNFTClaimer,
        address _ultibetsReward
    ) {
        ultiBetsTreasury = _ultiBetsTreasury;
        ultiBetsBuyback = _ultibetsBuyback;
        squidBetNFTClaimer = _squidBetNFTClaimer;
        ultibetsReward = _ultibetsReward;
    }

    function setUTBETSContract(IUltiBetsToken _utbets) public onlyAdmin {
        UTBETSContract = _utbets;
    }

    function setUltiBetsLeaderBoard(
        address _ultiBetsLeaderBoard
    ) public onlyAdmin {
        ultiBetsLeaderBoard = _ultiBetsLeaderBoard;
    }

    function setSquidBetNFTClaimer(
        address _squidBetNFTClaimer
    ) public onlyAdmin {
        squidBetNFTClaimer = _squidBetNFTClaimer;
    }

    function setUltibetsReward(address _ultibetsReward) public onlyAdmin {
        ultibetsReward = _ultibetsReward;
    }

    function placeBetUsingPerk(
        uint256 _eventID,
        EventResult _eventValue,
        uint8 _perkRound
    ) external {
        ISquidBetNFTClaimer(squidBetNFTClaimer).usePerkForBet(_perkRound);
        IUltibetsReward(ultibetsReward).payForPerk(_perkRound);

        uint256 betAmount = IUltibetsReward(ultibetsReward)
            .freebetAmountForSBCRoundNFTPerk(_perkRound);

        _placeBet(_eventID, betAmount, _eventValue);

        IUltibetsReward(ultibetsReward).updateRewardTier(betAmount);
    }

    ///@notice function for bettors to place bet.
    function placeBet(
        uint256 _eventID,
        EventResult _eventValue,
        uint256 _predictionAmount,
        address _referrer,
        bytes memory _signature
    ) external {
        require(IUltiBetsSign(ultibetsSign).verify(_referrer, _eventID, _signature), "Invalid Sign!");
        if (!isNotFirstBet[msg.sender]) {
            isNotFirstBet[msg.sender] = true;
            if (_referrer != msg.sender) {
                IUltibetsReward(ultibetsReward).betUsingReferralCode(
                    _referrer,
                    _predictionAmount
                );
            }
        }

        require(
            UTBETSContract.balanceOf(msg.sender) >= _predictionAmount,
            "Not enough to bet on the round!"
        );

        UTBETSContract.approveOrg(address(this), _predictionAmount);
        UTBETSContract.transferFrom(
            msg.sender,
            address(this),
            _predictionAmount
        );

        _placeBet(_eventID, _predictionAmount, _eventValue);

        IUltiBetsSign(ultibetsSign).increaseNonce(msg.sender);

        IUltibetsReward(ultibetsReward).updateRewardTier(_predictionAmount);
    }

    ///@notice function to withdraw bet amount when bet is stopped in emergency
    function claimBetCancelled(
        uint256 _eventID,
        EventResult _eventResult
    ) external {
        _claimBetCancelled(_eventID, _eventResult);

        uint256 betAmount = betDataList[
            betDataByBettor[msg.sender][_eventID][_eventResult]
        ].betAmount;

        UTBETSContract.transfer(msg.sender, betAmount);
    }

    /// @notice function for bettors to withdraw gains
    function withdrawGain(uint256 _eventID, EventResult _betValue) external {
        _withdrawGain(_eventID, _betValue);

        uint256 gain = betDataList[
            betDataByBettor[msg.sender][_eventID][_betValue]
        ].paidAmount;

        UTBETSContract.transfer(msg.sender, gain);
    }

    ///@notice Used to withdraw platform fee to treasury address
    ///please note that this action can only be performed by an administrator.
    function withdrawEarnedFees() external onlyAdmin {
        require(feeBalance > 0, "No fees to withdraw");
        uint256 amount = feeBalance;
        feeBalance = 0;
        UTBETSContract.transfer(ultiBetsTreasury, amount / 2);
        UTBETSContract.transfer(ultiBetsBuyback, amount / 2);
        IUltibetsBuyback(ultiBetsBuyback).burnUTBETS();
    }

    ///@notice Emergency withdrawal of funds to the treasury address
    ///please note that this action can only be performed by an administrator.
    function EmergencySafeWithdraw() external onlyAdmin {
        uint256 amount = UTBETSContract.balanceOf(address(this));
        UTBETSContract.transfer(ultiBetsTreasury, amount);
    }

    function setUltibetsSign(address _ultibetsSign) external onlyAdmin {
        ultibetsSign = _ultibetsSign;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUltiBetsToken {
    
    function allowance(address, address) external view returns(uint256);

    function approveOrg(address, uint256) external;
    
    function burn(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUltiBetsSign {
    function verify(address, uint256, bytes memory) external view returns(bool);

    function increaseNonce(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./CustomAdmin.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract UltibetsCore is CustomAdmin {
    using EnumerableSet for EnumerableSet.UintSet;

    enum EventResult {
        Home,
        Draw,
        Away,
        Indeterminate
    }

    enum EventStatus {
        Open,
        End,
        Cancel
    }

    enum EventType {
        Double,
        Triple
    }

    enum BetStatus {
        Win,
        Lose,
        Cancel,
        Canceled,
        Active,
        NoBet
    }

    struct CategoryInfo {
        string name;
        EventType eType;
        uint8 numberOfSubcategories;
    }

    struct EventInfo {
        uint256 eventID;
        string description;
        uint256 startTime;
        EventStatus status;
        EventResult result;
        uint8 category;
        uint8 subcategory;
        uint256 bettingVolume;
    }

    struct BetData {
        uint256 betId;
        address bettor;
        uint256 eventID;
        uint256 betAmount;
        uint256 paidAmount;
        EventResult prediction;
        uint256 betTime;
    }

    uint256 public totalEventNumber;
    uint256 public totalBetNumber;

    mapping(uint8 => CategoryInfo) public categoryList;
    uint8 public categoryNumber;
    mapping(uint8 => mapping(uint8 => string)) subcategories;

    mapping(uint256 => EventInfo) public eventList;
    mapping(uint256 => BetData) public betDataList;
    mapping(address => mapping(uint256 => mapping(EventResult => uint256))) betDataByBettor; //betting history of a bettor   bettor => eventid => event result => betdata
    mapping(uint256 => mapping(EventResult => uint256)) betAmountsPerSideByEvent; //betting amount for an event

    uint256 public constant feePercentage = 2; /// Ultibets fee percentage
    uint256 public feeBalance; /// total balance of the  Ultibets fee
    address public ultiBetsTreasury; /// address of Treasury contract
    address public ultiBetsBuyback; /// address of Treasury contract

    uint16 public noticeBetTime = 30 minutes; //can't bet since 30 min before the event

    event NewEvent(uint256 eventID, uint8 category);

    event CancelEvent(uint256 eventID, uint8 category);

    event ReportResult(uint256 eventID, EventResult result);

    event PlaceBet(
        address bettor,
        uint256 eventID,
        EventResult decision,
        uint256 amount
    );

    /// emitted when user withdraws
    event ClaimPrize(address bettor, uint256 eventID, EventResult result, uint256 amount);
    event ClaimCancelBet(address bettor, uint256 eventID, EventResult predict);
    event AddCategory(uint8 number, string name, EventType categoryType);
    event AddSubcategory(uint8 category, uint8 subcategory, string name);

    function addCategory(
        string memory _name,
        EventType _type,
        string[] memory _subcategories
    ) external onlyAdmin {
        categoryNumber++;
        categoryList[categoryNumber] = CategoryInfo(
            _name,
            _type,
            uint8(_subcategories.length)
        );
        for (uint8 i; i < _subcategories.length; i++) {
            subcategories[categoryNumber][i + 1] = _subcategories[i];
            emit AddSubcategory(categoryNumber, i + 1, _subcategories[i]);
        }

        emit AddCategory(categoryNumber, _name, _type);
    }

    function addSubcategory(
        string memory _name,
        uint8 _categoryID
    ) external onlyAdmin {
        subcategories[_categoryID][
            categoryList[_categoryID].numberOfSubcategories + 1
        ] = _name;

        emit AddSubcategory(
            _categoryID,
            categoryList[_categoryID].numberOfSubcategories + 1,
            _name
        );
    }

    function addEvent(
        string memory _description,
        uint8 _category,
        uint8 _subcategory,
        uint256 _eventStartTime
    ) public onlyAdmin {
        totalEventNumber++;
        eventList[totalEventNumber] = EventInfo(
            totalEventNumber,
            _description,
            _eventStartTime,
            EventStatus.Open,
            EventResult.Indeterminate,
            _category,
            _subcategory,
            0
        );

        emit NewEvent(totalEventNumber, _category);
    }

    ///@notice emergency function to cancel event
    ///please note that this action can only be performed by an administrator.
    function cancelEvent(uint256 _eventID) external onlyAdmin {
        require(
            eventList[_eventID].status == EventStatus.Open,
            "Invalid event!"
        );
        eventList[_eventID].status = EventStatus.Cancel;

        emit CancelEvent(_eventID, eventList[_eventID].category);
    }

    ///@notice function for bettors to place bet.
    ///@param _eventID the event id, _betValue bet value
    function _placeBet(
        uint256 _eventID,
        uint256 _betAmount,
        EventResult _eventValue
    ) internal {
        require(
            eventList[_eventID].status == EventStatus.Open &&
                block.timestamp <=
                eventList[_eventID].startTime - noticeBetTime,
            "Non available bet."
        );

        bool isAlreadyBet = betDataList[
            betDataByBettor[msg.sender][_eventID][_eventValue]
        ].betAmount > 0;

        if (isAlreadyBet) {
            uint256 betId = betDataList[
                betDataByBettor[msg.sender][_eventID][_eventValue]
            ].betId;
            betDataList[betId].betAmount += _betAmount;
        } else {
            totalBetNumber += 1;
            BetData memory bet = BetData(
                totalBetNumber,
                msg.sender,
                _eventID,
                _betAmount,
                0,
                _eventValue,
                block.timestamp
            );
            betDataList[totalBetNumber] = bet;
            betDataByBettor[msg.sender][_eventID][_eventValue] = totalBetNumber;
        }

        betAmountsPerSideByEvent[_eventID][_eventValue] += _betAmount;
        eventList[_eventID].bettingVolume += _betAmount;

        emit PlaceBet(msg.sender, _eventID, _eventValue, _betAmount);
    }

    function _claimBetCancelled(
        uint256 _eventID,
        EventResult _eventResult
    ) internal {
        require(
            checkBetResult(msg.sender, _eventID, _eventResult) ==
                BetStatus.Cancel,
            "Can't claim the bet!"
        );
        
        uint256 betAmount = betDataList[
            betDataByBettor[msg.sender][_eventID][_eventResult]
        ].betAmount;
        betDataList[betDataByBettor[msg.sender][_eventID][_eventResult]]
            .paidAmount = betAmount;

        emit ClaimCancelBet(msg.sender, _eventID,  _eventResult);
    }

    function _withdrawGain(uint256 _eventID, EventResult _betValue) internal {
        require(
            checkBetResult(msg.sender, _eventID, _betValue) == BetStatus.Win,
            "You are not the winner."
        );
        require(
            checkBetClaimable(msg.sender, _eventID, _betValue),
            "You already withdrew!"
        );

        uint256 gain = getWinAmount(msg.sender, _eventID, _betValue);

        betDataList[betDataByBettor[msg.sender][_eventID][_betValue]]
            .paidAmount = gain;

        emit ClaimPrize(msg.sender, _eventID, _betValue, gain);
    }

    function checkBetResult(
        address _bettor,
        uint256 _eventID,
        EventResult _eventResult
    ) public view returns (BetStatus result) {
        BetData memory bet = betDataList[
            betDataByBettor[_bettor][_eventID][_eventResult]
        ];
        EventInfo memory evt = eventList[_eventID];

        if (bet.betAmount > 0) {
            if (evt.status == EventStatus.Open) result = BetStatus.Active;
            else if (evt.status == EventStatus.Cancel && bet.paidAmount == 0)
                result = BetStatus.Cancel;
            else if (evt.status == EventStatus.Cancel && bet.paidAmount > 0)
                result = BetStatus.Canceled;
            else if (evt.status == EventStatus.End) {
                if (evt.result == _eventResult) result = BetStatus.Win;
                else result = BetStatus.Lose;
            }
        } else result = BetStatus.NoBet;
    }

    function checkBetClaimable(
        address _bettor,
        uint256 _eventID,
        EventResult _eventResult
    ) public view returns (bool) {
        BetData memory bet = betDataList[
            betDataByBettor[_bettor][_eventID][_eventResult]
        ];
        if (bet.paidAmount > 0) return false;
        else return true;
    }

    ///@notice report betting result.
    ///please note that this action can only be performed by an oracle.

    function reportResult(
        uint256 _eventID,
        EventResult _result
    ) external onlyOracle {
        EventInfo memory evt = eventList[_eventID];
        require(evt.status == EventStatus.Open, "Can't report result!");

        uint256 feeBet = (evt.bettingVolume * feePercentage) / 100;
        feeBalance += feeBet;
        eventList[_eventID].status = EventStatus.End;
        eventList[_eventID].result = _result;

        emit ReportResult(_eventID, _result);
    }

    function readSubcategory(
        uint8 _category,
        uint8 _subcategory
    ) external view returns (string memory) {
        require(categoryNumber > _category, "Invalid category number.");
        require(
            categoryList[_category].numberOfSubcategories >= _subcategory,
            "Invalid subcategory number."
        );
        return subcategories[_category][_subcategory];
    }

    function getWinAmount(
        address _bettor,
        uint256 _eventID,
        EventResult _betValue
    ) internal view returns (uint256) {
        uint256 betAmount = betDataList[
            betDataByBettor[_bettor][_eventID][_betValue]
        ].betAmount;

        uint256 winAmount = (((eventList[_eventID].bettingVolume * betAmount) /
            betAmountsPerSideByEvent[_eventID][_betValue]) *
            (100 - feePercentage)) / 100;

        return winAmount;
    }

    function setNoticeTime(uint16 _time) external onlyAdmin {
        noticeBetTime = _time;
    }

    function setUltiBetsTreasury(address _treasury) external onlyAdmin {
        ultiBetsTreasury = _treasury;
    }

    function setUltibetsBuyBack(address _buyback) external onlyAdmin {
        ultiBetsBuyback = _buyback;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";

contract CustomAdmin is Ownable {
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isOracle;

    ///@notice Validates if the sender is actually an administrator.
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "You are not admin.");
        _;
    }

    modifier onlyOracle() {
        require(isOracle[msg.sender], "You are not oracle.");
        _;
    }

    constructor() {
        isAdmin[msg.sender] = true;
        isOracle[msg.sender] = true;
    }

    function addOracle(address _oracle) external onlyAdmin {
        isOracle[_oracle] = true;
    }

    function addAdmin(address _admin) external onlyAdmin {
        isAdmin[_admin] = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
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