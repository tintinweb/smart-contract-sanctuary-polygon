// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ICryptoHands} from "./interfaces/ICryptoHands.sol";
import {IRockPaperScissors} from "./interfaces/IRockPaperScissors.sol";

contract RockPaperScissors is
    Pausable,
    ReentrancyGuard,
    Ownable,
    IRockPaperScissors
{
    using Counters for Counters.Counter;

    ICryptoHands private s_cryptoHands;

    uint256 private s_maxBet;
    uint256 private s_minBet;
    uint256 private s_divider = 100;

    Counters.Counter private s_betId;

    mapping(uint256 => Bet) public s_bets;
    mapping(address => uint256) public s_nftWinPercentage;
    mapping(address => uint256) public s_gamesPlayed;
    mapping(address => uint256) public s_gamesWon;
    mapping(address => uint256) public s_nftWon;

    constructor(
        uint256 _maxBet,
        uint256 _minBet,
        address _cryptoHands
    ) {
        s_maxBet = _maxBet;
        s_minBet = _minBet;
        s_cryptoHands = ICryptoHands(_cryptoHands);
    }

    function makeBet(uint256 _choice)
        external
        payable
        nonReentrant
        whenNotPaused
    {
        require(
            msg.value >= s_minBet,
            "RockPaperScissors: Bet is Smaller than Minimum Bet Amount"
        );
        require(
            msg.value <= s_maxBet,
            "RockPaperScissors: Bet is Greater than Maximun Bet Amount"
        );
        require(_choice < 3, "RoclPaperScissors: Choice Shoule Be 0, 1 or 2");
        uint256 _randomNumber = _getRandomNumber(
            s_betId.current(),
            msg.sender
        ) % 10000;

        uint256 totalHandsWinned = s_cryptoHands.getTotalHandsWinned();
        uint256 maxHandsAvailableToWin = s_cryptoHands
            .getMaxHandsAvailableToWin();

        if (totalHandsWinned <= maxHandsAvailableToWin) {
            if (s_nftWinPercentage[msg.sender] == 10000) {
                s_cryptoHands.winHands(msg.sender);
                s_nftWinPercentage[msg.sender] == 0;
            }
            if (s_nftWinPercentage[msg.sender] > _randomNumber) {
                s_cryptoHands.winHands(msg.sender);
            }
        }

        _createBetAndSettle(_choice, msg.sender, msg.value);

        s_nftWinPercentage[msg.sender] = s_nftWinPercentage[msg.sender] + 1;
    }

    function _createBetAndSettle(
        uint256 _choice,
        address _player,
        uint256 _betAmount
    ) internal {
        GameChoices _playerChoice = _getChoiceAccordingToNumber(_choice);

        GameChoices _outcome = _getRockOrPaperOrScissors(_player);

        uint256 winAmount = _amountToWinningPool(msg.value);

        Results _result = _winOrLoose(_playerChoice, _outcome);

        if (_result == Results.Win) {
            (bool hs, ) = payable(_player).call{value: winAmount}("");
            require(hs, "Failed to send MATIC 1");

            s_gamesWon[_player] = s_gamesWon[_player] + 1;
            s_nftWon[_player] = s_nftWon[_player] + 1;
        }
        if (_result == Results.Tie) {
            (bool hs, ) = payable(_player).call{value: _betAmount}("");
            require(hs, "Failed to send MATIC 2");
        }

        Bet memory _bet = Bet(
            s_betId.current(),
            _playerChoice,
            _outcome,
            _player,
            msg.value,
            winAmount,
            _result
        );

        s_bets[s_betId.current()] = _bet;
        s_betId.increment();

        emit BetCreated(
            s_betId.current(),
            _playerChoice,
            _player,
            _betAmount,
            winAmount,
            _getCurrentTime()
        );

        emit ResultsDeclared(
            _bet.betId,
            _bet.choice,
            _bet.outcome,
            _bet.amount,
            _bet.winAmount,
            _bet.player,
            _bet.result,
            _getCurrentTime()
        );

        s_gamesPlayed[_player] = s_gamesPlayed[_player] + 1;
    }

    function _winOrLoose(GameChoices _playerChoice, GameChoices _outcome)
        internal
        pure
        returns (Results _result)
    {
        if (_playerChoice == GameChoices.Rock && _outcome == GameChoices.Rock) {
            _result = Results.Tie;
        }
        if (
            _playerChoice == GameChoices.Rock && _outcome == GameChoices.Paper
        ) {
            _result = Results.Loose;
        }
        if (
            _playerChoice == GameChoices.Rock &&
            _outcome == GameChoices.Scissors
        ) {
            _result = Results.Win;
        }
        if (
            _playerChoice == GameChoices.Paper && _outcome == GameChoices.Paper
        ) {
            _result = Results.Tie;
        }
        if (
            _playerChoice == GameChoices.Paper &&
            _outcome == GameChoices.Scissors
        ) {
            _result = Results.Loose;
        }
        if (
            _playerChoice == GameChoices.Paper && _outcome == GameChoices.Rock
        ) {
            _result = Results.Win;
        }
        if (
            _playerChoice == GameChoices.Scissors &&
            _outcome == GameChoices.Scissors
        ) {
            _result = Results.Tie;
        }
        if (
            _playerChoice == GameChoices.Scissors &&
            _outcome == GameChoices.Rock
        ) {
            _result = Results.Loose;
        }
        if (
            _playerChoice == GameChoices.Scissors &&
            _outcome == GameChoices.Paper
        ) {
            _result = Results.Win;
        }
    }

    function _amountToWinningPool(uint256 _bet)
        internal
        view
        returns (uint256 _winningPool)
    {
        uint256 balance = address(this).balance;
        _winningPool = (balance / s_divider) + _bet;
    }

    function _getRandomNumber(uint256 _num, address _sender)
        internal
        view
        returns (uint256 _randomNumber)
    {
        _randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    s_betId.current(),
                    _getBlockDifficulty(),
                    _getCurrentTime(),
                    _getBlockNumber(),
                    _sender,
                    _num
                )
            )
        );
    }

    function _getChoiceAccordingToNumber(uint256 _number)
        internal
        pure
        returns (GameChoices _gameChoice)
    {
        require(_number < 3, "RockPaperScissors: Choice should be less than 3");
        if (_number == 0) {
            _gameChoice = GameChoices.Rock;
        }
        if (_number == 1) {
            _gameChoice = GameChoices.Paper;
        }
        if (_number == 2) {
            _gameChoice = GameChoices.Scissors;
        }
    }

    function _getRockOrPaperOrScissors(address _sender)
        internal
        view
        returns (GameChoices _outcome)
    {
        uint256 randomNumber = _getRandomNumber(s_betId.current(), _sender);
        uint256 randomOutcome = randomNumber % 3;

        _outcome = _getChoiceAccordingToNumber(randomOutcome);
    }

    function _getBlockDifficulty()
        internal
        view
        returns (uint256 _blockDifficulty)
    {
        _blockDifficulty = block.difficulty;
    }

    function _getCurrentTime() internal view returns (uint256 _currentTime) {
        _currentTime = block.timestamp;
    }

    function _getBlockNumber() internal view returns (uint256 _blockNumber) {
        _blockNumber = block.number;
    }

    function getGameAddress()
        internal
        view
        returns (ICryptoHands _gameAddress)
    {
        _gameAddress = s_cryptoHands;
    }

    function getMaxBet() external view returns (uint256 _maxBet) {
        _maxBet = s_maxBet;
    }

    function getMinBet() external view returns (uint256 _minBet) {
        _minBet = s_minBet;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateCryptoHands(address _cryptoHands) external onlyOwner {
        s_cryptoHands = ICryptoHands(_cryptoHands);
        emit CryptoHandsUpdated(_cryptoHands);
    }

    function updateMaxBet(uint256 _maxBet) external onlyOwner {
        s_maxBet = _maxBet;
        emit MaxBetUpdated(_maxBet);
    }

    function updateMinBet(uint256 _minBet) external onlyOwner {
        s_minBet = _minBet;
        emit MinBetUpdated(_minBet);
    }

    function updateDivider(uint256 _divider) external onlyOwner {
        s_divider = _divider;
        emit DividerUpdated(_divider);
    }

    function deposite() external payable nonReentrant {}

    function withdraw(uint256 _amount) external onlyOwner {
        (bool os, ) = payable(owner()).call{value: _amount}("");
        require(os);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ICryptoHands {
    event PriceUpdated(uint256 newPrice);

    event BaseUriUpdated(string newBaseUri);

    event HiddenUriUpdated(string newHiddenUri);

    event PresaleToggled();

    event RootHashUpdated(bytes32 newRootHash);

    event WhitelistAdded(address user);

    event WhitelistRemoved(address user);

    event Revealed();

    event HandsMinted(address receiver, uint256 amount);

    event HandsWon(address winner);

    event GameAddressUpdated(address game);

    function mintHands(uint256 _mintAmount) external payable;

    function winHands(address _winner) external;

    function revealHands() external;

    function addWhitelist(address[] memory _addresses) external;

    function removeWhitelist(address[] memory _addresses) external;

    function updatePrice(uint256 _price) external;

    function updateBaseUri(string memory _baseUri) external;

    function updateGameAddress(address _game) external;

    function updateHiddenUri(string memory _hiddenUri) external;

    function pause() external;

    function unpause() external;

    function togglePresale() external;

    function tokenURI(uint256 _tokenId)
        external
        view
        returns (string memory _tokenUri);

    function getPrice() external view returns (uint256 _price);

    function getBaseUri() external view returns (string memory _baseUri);

    function getHiddenUri() external view returns (string memory _hiddenUri);

    function getMaxHands() external view returns (uint256 _maxHands);

    function getMaxHandsAvailableToMint()
        external
        view
        returns (uint256 _maxHandsAvailableToMint);

    function getMaxHandsAvailableToWin()
        external
        view
        returns (uint256 _maxHandsAvailableToWin);

    function getTotalHandsMinted()
        external
        view
        returns (uint256 _totalHandsMinted);

    function getTotalHandsWinned()
        external
        view
        returns (uint256 _totalHandsWinned);

    function getIsPresale() external view returns (bool _isPresale);

    function getGameAddress() external view returns (address _game);

    function getMaxHandsPerTx() external view returns (uint256 _maxHandsPerTx);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IRockPaperScissors {
    struct Bet {
        uint256 betId;
        GameChoices choice;
        GameChoices outcome;
        address player;
        uint256 amount;
        uint256 winAmount;
        Results result;
    }

    enum GameChoices {
        Rock,
        Paper,
        Scissors
    }

    enum Results {
        Win,
        Loose,
        Tie
    }

    event CryptoHandsUpdated(address _newCryptoHands);
    event MaxBetUpdated(uint256 _newMaxBet);
    event MinBetUpdated(uint256 _newMinBet);
    event DividerUpdated(uint256 _newDivider);
    event BetCreated(
        uint256 _betId,
        GameChoices _playerChoice,
        address _player,
        uint256 _betAmount,
        uint256 _winAmount,
        uint256 _time
    );
    event ResultsDeclared(
        uint256 _betId,
        GameChoices _choice,
        GameChoices _outcome,
        uint256 _amount,
        uint256 _winAmount,
        address _player,
        Results _result,
        uint256 _time
    );
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