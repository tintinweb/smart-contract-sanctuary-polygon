// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGame.sol";
import "./PIC.sol";

contract GameFactory is Ownable {

    struct GameQuery{
        address GameAddress;
        uint256 startTime;
    }
    GameQuery[] public GameStorage;

    event GameCreated(address indexed _GameAddress, uint256 indexed _auctionStartTime);

    function createGame(address _newGame, IPlayer.PlayerQuery[] memory _Players, uint256 _auctionStartTime) public onlyOwner {
        PIC newPlayer = new PIC(_Players);
        IGame newGame = IGame(_newGame);
        newGame.start(address(newPlayer), _auctionStartTime);

        GameQuery memory newQuery = GameQuery(_newGame, _auctionStartTime);
        GameStorage.push(newQuery);
        emit GameCreated(_newGame, _auctionStartTime);
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
pragma solidity ^0.8.8;

interface IGame {
    function start(address _PICAddress, uint256 _auctionStartTime) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "./interfaces/IPlayer.sol";

contract PIC {
    uint256 private s_PlayerCount;
    address private owner;
    IPlayer.PlayerQuery[] public s_PlayerStorage;

    event PlayerUpdated(uint256 indexed tokenId);

    error NotOwner();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    constructor(IPlayer.PlayerQuery[] memory _Players) {
        s_PlayerCount = _Players.length;

        for (uint256 i = 0; i < _Players.length; i++) {
            s_PlayerStorage.push(_Players[i]);
        }
        owner = tx.origin;
    }

    function updatetokenURI(
        uint256 tokenId,
        string memory _imageURI
    ) external onlyOwner {
        s_PlayerStorage[tokenId].imageURI = _imageURI;
        emit PlayerUpdated(tokenId);
    }

    function imageURI(uint256 tokenId) public view returns (string memory) {
        return s_PlayerStorage[tokenId].imageURI;
    }

    function getplayerDetails(
        uint256 tokenId
    ) external view returns (IPlayer.PlayerQuery memory) {
        return s_PlayerStorage[tokenId];
    }

    function getTotalPlayers() external view returns (uint256) {
        return s_PlayerCount;
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
pragma solidity ^0.8.8;

interface IPlayer {
    struct PlayerQuery{
        string imageURI;
        string role;
        uint256 id;
    }
}