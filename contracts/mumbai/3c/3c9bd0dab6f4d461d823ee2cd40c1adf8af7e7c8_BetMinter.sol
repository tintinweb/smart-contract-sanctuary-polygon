/**
 *Submitted for verification at polygonscan.com on 2022-11-18
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: contracts/contracts/interfaces/IBetsPool.sol

pragma solidity >0.8.16;

interface IBetsPool {
    struct PendingBet {
        address from;
        uint256 price;
        bool favour;
    }
    struct ActiveBet {
        address favourWallet;
        address againstWallet;
        uint256 price;
    }

    event BetInitiated(
        uint256 indexed _betId,
        uint8 indexed sportId,
        string indexed bestslug
    );

    event BetCreated(
        uint256 indexed _betId,
        uint8 indexed sportId,
        string indexed bestslug
    );

    event BetResolved(
        uint256 indexed _betId,
        uint8 indexed sportId,
        string indexed bestslug
    );

    function allActiveBets(
        string memory _sport,
        string memory _match,
        string memory _team,
        string memory _player,
        string memory _event,
        string memory _timeframe
    ) external view returns (ActiveBet[] memory);

    function addBet(
        string memory _sport,
        string memory _match,
        string memory _team,
        string memory _player,
        string memory _event,
        string memory _timeframe,
        address sender,
        uint256 _price,
        bool _favour
    ) external;

    function trigger(
        string memory _sport,
        string memory _match,
        string memory _team,
        string memory _player,
        string memory _event,
        string memory _timeframe
    ) external;
}

// File: contracts/contracts/BetMinter.sol

pragma solidity >0.8.16;



contract BetMinter is Context {
    IBetsPool _betsPool;

    constructor(IBetsPool betsPool) {
        _betsPool = betsPool;
    }

    function Bet(
        string memory _sport,
        string memory _match,
        string memory _team,
        string memory _player,
        string memory _event,
        string memory _timeframe,
        uint256 _price,
        bool _favour
    ) external {
        require(_price > 0, "Bet amount too low");
        _betsPool.addBet(_sport, _match, _team, _player, _event, _timeframe, _msgSender(), _price, _favour);
    }
}