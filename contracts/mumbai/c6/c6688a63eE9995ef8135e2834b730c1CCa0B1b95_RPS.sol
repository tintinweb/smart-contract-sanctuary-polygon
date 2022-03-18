/**
 *Submitted for verification at polygonscan.com on 2022-03-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


pragma solidity >=0.8.0 <0.9.0;

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

// File: @openzeppelin/contracts/utils/Context.sol
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

// File: @openzeppelin/contracts/access/Ownable.sol
pragma solidity ^0.8.0;
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract RPS is Ownable{
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private game;

    address public gameMasterAddress = 0xAC693D5736173E6469cd2ce88dd6a8a9b7f836f4;
    mapping(address => uint256) public deposits;
    mapping(uint256 => address) public winner;
    mapping(address => uint256) public winningPool;
    
    mapping (uint256 => mapping (uint256 => address)) public gamePlayers;

    uint256 public minAmount = 0.01 ether;

    function setMinAmount(uint256 _newMinAmount) public returns (uint256) {
        minAmount = _newMinAmount;
        return minAmount;
    }

    function setGameMasterAddress(address _newAddress) public onlyOwner {
        gameMasterAddress = _newAddress;
    }

    function totalGames() public view returns (uint256) {
        return game.current();
    }

    function joinGame() public payable returns (bool)  {
        require(msg.value >= minAmount);
        deposits[msg.sender] += msg.value;
        return true;
    }

    function addressHasBalanceToPlay(address _player) public view returns (bool) {
        return deposits[_player] >= minAmount;
    }

    function setPlayer(address _playerA, address _playerB, uint256 _gameId) public onlyOwner {
        require(gamePlayers[_gameId][0] == address(0x0), "Game already exists");
        require(deposits[_playerA] >= minAmount, "Player A did not deposit sufficient amount to play");
        require(deposits[_playerB] >= minAmount, "Player B did not deposit sufficient amount to play");
        gamePlayers[_gameId][0] = _playerA;
        gamePlayers[_gameId][1] = _playerB;
        game.increment();
    }

    function setWinner(address _winnerAddress, uint256 _gameId, uint256 _percentage) public payable onlyOwner {
        require(winner[_gameId] == address(0x0), "There is already a winner declared for this game");
        
        // record winner for the game
        winner[_gameId] = _winnerAddress;
        
        // set the winning amount
        uint256 totalStaked = minAmount * 2;
        uint256 winningAmount = totalStaked * _percentage / 100;
        uint256 balance = totalStaked - winningAmount;
        winningPool[_winnerAddress] += winningAmount;
        
        // remove the deposit from the game players
        address playerA = gamePlayers[_gameId][0];
        address playerB = gamePlayers[_gameId][1];
        deposits[playerA] -= minAmount;
        deposits[playerB] -= minAmount;
        
        // withdraw the balance of winnings
        (bool os, ) = payable(gameMasterAddress).call{value: balance}("");
        require(os);
    }

    function claimWinnings() public payable {
        require(winningPool[msg.sender] > 0, "Your winning pool is currently empty");

        uint balance = winningPool[msg.sender];

        (bool hs, ) = payable(msg.sender).call{value: balance}("");
        require(hs);

    }
}