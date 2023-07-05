// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error IncorrectBetTime();
error IncorrectEndBetTime();
error IncorrectValue();
error UnderBetLimit();
error SendEthFail();
error NotBetOwner();
error CannotReceiveTwice();
error NotWinFinalResult();
error NotDetermineWinResult();
error IsDetermined();
error NotMatchedArray();

contract FightingBet is Ownable, ReentrancyGuard {
    uint256 public betLimit;
    uint256 public contractPool;
    uint16 public feeRate; // Basis pont, means 200/10000 = 2%;

    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _gameNumberCounter;
    Counters.Counter private _betNumberCounter;

    enum BetFightOptions {
        fighterA_KO_TKO_B_Round1,
        fighterB_KO_TKO_A_Round1,
        fighterA_KO_TKO_B_Round2,
        fighterB_KO_TKO_A_Round2,
        fighterA_KO_TKO_B_Round3,
        fighterB_KO_TKO_A_Round3,
        fighterA_KO_TKO_B_Round4,
        fighterB_KO_TKO_A_Round4,
        fighterA_KO_TKO_B_Round5,
        fighterB_KO_TKO_A_Round5,
        fighterA_Decision_Win,
        fighterB_Decision_Win,
        fighterA_Submission_Win,
        fighterB_Submission_Win
    }

    struct FighterInfo {
        string fighterA;
        string fighterB;
    }

    struct FightBetSaleInfo {
        uint256 startValue;
        uint256 totalValue;
        uint40 startBetTime;
        uint40 endBetTime;
        // BetFightOptions => bet value
        mapping(uint256 => uint256) betPoolValues;
    }

    struct BetInfo {
        uint256 fightNumber;
        uint256 betValue;
        address buyer;
        BetFightOptions winResult;
        bool isReceiveAward;
    }

    struct FightResult {
        uint256 betAwardRate;
        BetFightOptions finalResult;
        bool isDetermined;
        bool isCanceled;
    }

    // fightNumber => Fighter Info
    mapping(uint256 => FighterInfo) fightNumbers;

    // fightNumber => FightBetSale Info
    mapping(uint256 => FightBetSaleInfo) fightBetSaleinfos;

    // fightNumber => FightBetSale Info
    mapping(uint256 => FightResult) public fightResults;

    // betNumber => Bet Info
    mapping(uint256 => BetInfo) betInfos;

    event BetFight(
        uint256 betNumber,
        address buyer,
        uint256 fightNumber,
        uint256 betValue,
        BetFightOptions winResult
    );

    constructor(uint256 _betLimit, uint16 _feeRate) {
        betLimit = _betLimit;
        feeRate = _feeRate;
    }

    function setParams(uint256 _betLimit, uint16 _feeRate) external onlyOwner {
        betLimit = _betLimit;
        feeRate = _feeRate;
    }

    function setFightInfo(
        uint256 _startPool,
        bool _useContractPool,
        uint40 _startBetTime,
        uint40 _endBetTime,
        FighterInfo calldata fighters
    ) external payable onlyOwner {
        if (block.timestamp > _startBetTime) revert IncorrectBetTime();
        if (_endBetTime < _startBetTime) revert IncorrectEndBetTime();
        if (_useContractPool) {
            if (msg.value > 0) revert IncorrectValue();
            contractPool = contractPool.sub(_startPool);
        } else {
            if (msg.value != _startPool) revert IncorrectValue();
        }
        uint256 fightNumber = _gameNumberCounter.current();
        _gameNumberCounter.increment();
        fightNumbers[fightNumber] = fighters;
        FightBetSaleInfo storage fightBetSaleInfo = fightBetSaleinfos[
            fightNumber
        ];
        fightBetSaleInfo.startValue = _startPool;
        fightBetSaleInfo.startBetTime = _startBetTime;
        fightBetSaleInfo.endBetTime = _endBetTime;
        fightBetSaleInfo.totalValue = _startPool;
    }

    function fightInfo(
        uint256 _fightNumber
    )
        external
        view
        returns (
            FighterInfo memory fighters,
            uint256 totalValue,
            uint40 startBetTime,
            uint40 endBetTime
        )
    {
        FighterInfo memory fighterInfo = fightNumbers[_fightNumber];
        FightBetSaleInfo storage fightBetSaleInfo = fightBetSaleinfos[
            _fightNumber
        ];
        return (
            fighterInfo,
            fightBetSaleInfo.totalValue,
            fightBetSaleInfo.startBetTime,
            fightBetSaleInfo.endBetTime
        );
    }

    function bet(
        uint256 _fightNumber,
        uint256 _betValue,
        BetFightOptions _winResult
    ) public payable {
        if (msg.value != _betValue) revert IncorrectValue();
        if (_betValue < betLimit) revert UnderBetLimit();
        uint256 betNumber = _betNumberCounter.current();
        _betNumberCounter.increment();
        FightBetSaleInfo storage fightBetSaleInfo = fightBetSaleinfos[
            _fightNumber
        ];
        fightBetSaleInfo.totalValue += _betValue;
        fightBetSaleInfo.betPoolValues[uint(_winResult)] += _betValue;
        BetInfo storage betInfo = betInfos[betNumber];
        betInfo.fightNumber = _fightNumber;
        betInfo.betValue = _betValue;
        betInfo.buyer = msg.sender;
        betInfo.winResult = _winResult;
        emit BetFight(
            betNumber,
            msg.sender,
            _fightNumber,
            _betValue,
            _winResult
        );
    }

    function batchBet(
        uint256 _fightNumber,
        uint256[] calldata _betValues,
        BetFightOptions[] calldata _winResults
    ) public payable {
        uint256 totalBetValue;
        if (_betValues.length != _winResults.length) revert NotMatchedArray();
        for (uint256 i = 0; i < _betValues.length; ) {
            if (_betValues[i] < betLimit) revert UnderBetLimit();
            totalBetValue += _betValues[i];
            unchecked {
                ++i;
            }
        }
        if (totalBetValue != msg.value) revert IncorrectValue();
        for (uint256 i = 0; i < _betValues.length; ) {
            uint256 betNumber = _betNumberCounter.current();
            _betNumberCounter.increment();
            FightBetSaleInfo storage fightBetSaleInfo = fightBetSaleinfos[
                _fightNumber
            ];
            fightBetSaleInfo.totalValue += _betValues[i];
            fightBetSaleInfo.betPoolValues[uint(_winResults[i])] += _betValues[
                i
            ];
            BetInfo storage betInfo = betInfos[betNumber];
            betInfo.fightNumber = _fightNumber;
            betInfo.betValue = _betValues[i];
            betInfo.buyer = msg.sender;
            betInfo.winResult = _winResults[i];
            emit BetFight(
                betNumber,
                msg.sender,
                _fightNumber,
                _betValues[i],
                _winResults[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    function queryBet(
        uint256 _betNumber
    ) external view returns (BetInfo memory) {
        BetInfo memory betInfo = betInfos[_betNumber];
        return betInfo;
    }

    function determineCancelResult(uint256 _fightNumber) external onlyOwner {
        FightBetSaleInfo storage fightBetSaleInfo = fightBetSaleinfos[
            _fightNumber
        ];
        FightResult storage fightGameResult = fightResults[_fightNumber];
        if (fightGameResult.isDetermined) revert IsDetermined();
        fightGameResult.isCanceled = true;
        fightGameResult.isDetermined = true;
        contractPool = fightBetSaleInfo.startValue;
    }

    function determineWinResult(
        uint256 _fightNumber,
        BetFightOptions _winResult
    ) external onlyOwner nonReentrant {
        FightResult storage fightGameResult = fightResults[_fightNumber];
        FightBetSaleInfo storage fightBetSaleInfo = fightBetSaleinfos[
            _fightNumber
        ];
        if (fightGameResult.isDetermined) revert IsDetermined();
        fightGameResult.finalResult = _winResult;
        uint256 winBetPool = fightBetSaleInfo.betPoolValues[uint(_winResult)];
        uint256 ownerFee = fightBetSaleInfo.totalValue.mul(feeRate).div(10000);
        uint256 remainAward = fightBetSaleInfo.totalValue.sub(ownerFee);
        if (winBetPool == 0) {
            fightGameResult.betAwardRate = 0;
            contractPool += remainAward;
        } else {
            fightGameResult.betAwardRate = remainAward.div(
                winBetPool.div(10000)
            );
        }

        fightGameResult.isDetermined = true;

        // effect-interaction
        (bool success, ) = msg.sender.call{value: ownerFee}("");
        if (!success) revert SendEthFail();
    }

    function queryOdds(
        uint256 _fightNumber
    ) external view returns (uint256[] memory) {
        FightBetSaleInfo storage fightBetSaleInfo = fightBetSaleinfos[
            _fightNumber
        ];
        uint256 ownerFee = fightBetSaleInfo.totalValue.mul(feeRate).div(10000);
        uint256 remainAward = fightBetSaleInfo.totalValue.sub(ownerFee);
        uint256[] memory odds = new uint256[](14);
        for (uint256 i = 0; i < 14; ) {
            if (fightBetSaleInfo.betPoolValues[i] != 0) {
                odds[i] = remainAward.div(
                    fightBetSaleInfo.betPoolValues[i].div(10000)
                );
            }
            unchecked {
                ++i;
            }
        }
        return odds;
    }

    function withdrawAward(uint256 _betNumber) external payable nonReentrant {
        BetInfo storage betInfo = betInfos[_betNumber];
        if (betInfo.buyer != msg.sender) revert NotBetOwner();
        if (betInfo.isReceiveAward) revert CannotReceiveTwice();
        FightResult storage fightGameResult = fightResults[betInfo.fightNumber];
        if (!fightGameResult.isDetermined) revert NotDetermineWinResult();
        if (fightGameResult.isCanceled) {
            // update state first,
            betInfo.isReceiveAward = true;
            // effect-interaction
            (bool ok, ) = msg.sender.call{value: betInfo.betValue}("");
            if (!ok) revert SendEthFail();
            return;
        }
        if (betInfo.winResult != fightGameResult.finalResult)
            revert NotWinFinalResult();

        // update state first,
        betInfo.isReceiveAward = true;
        uint256 totalAward = betInfo
            .betValue
            .mul(fightGameResult.betAwardRate)
            .div(10000);

        // effect-interaction
        (bool success, ) = msg.sender.call{value: totalAward}("");
        if (!success) revert SendEthFail();
    }
}