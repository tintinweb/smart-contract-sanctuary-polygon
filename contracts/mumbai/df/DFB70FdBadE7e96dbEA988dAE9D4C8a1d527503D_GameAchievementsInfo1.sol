//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GameAchievementsInfo1 is Ownable {

    event GameCreated(uint256 indexed _id, string _title);
    event GameUpdated(uint256 indexed _id, string _oldTitle, string _newTitle, bool _isDeleted);

    event AchievementTypeCreated(uint256 indexed _id, uint256 indexed _gameId, string _title);
    event AchievementTypeUpdated(uint256 indexed _id, uint256 _oldGameId, uint256 _newGameId, string _oldTitle, string _newTitle, bool _isDeleted);

    struct Game {
        uint256 _id;
        string _title;
        bool _isDeleted;
    }

    struct AchievementType {
        uint256 _id;
        uint256 _gameId;
        string _title;
        bool _isDeleted;
    }

    uint256[] private _gameIdList;
    mapping(uint256 => Game) private _gameList;

    mapping(uint256 => uint256[])  private _achievementTypeIdList;
    mapping(uint256 => AchievementType)  private _achievementTypeList;


    function totalGames() public view virtual returns (uint256) {
        return _gameIdList.length;
    }

    function createGame(uint256 id, string memory title) external onlyOwner {
        _requirePositive(id);
        require(!_existsGame(id), "Game duplication");

        _gameIdList.push(id);
        _gameList[id] = Game(id, title, false);

        emit GameCreated(id, title);
    }

    function updateGame(uint256 id, string memory title, bool isDeleted) external onlyOwner {
        _requiredGame(id);

        Game storage game = _gameList[id];
        string memory oldTitle = game._title;

        game._title = title;
        game._isDeleted = isDeleted;

        emit GameUpdated(game._id, oldTitle, title, isDeleted);
    }

    function getGameByIndex(uint256 index) public view virtual returns (uint256 _id, string memory _title, bool _isDeleted) {
        require(index < totalGames(), "Index isn't correct");

        return getGameBy(_gameIdList[index]);
    }

    function getGameBy(uint256 id) public view virtual returns (uint256 _id, string memory _title, bool _isDeleted) {
        _requiredGame(id);

        return (_gameList[id]._id, _gameList[id]._title, _gameList[id]._isDeleted);
    }

    function totalAchievementTypes(uint256 gameId) public view virtual returns (uint256) {
        return _achievementTypeIdList[gameId].length;
    }

    function createAchievementType(uint256 gameId, uint256 id, string memory title) external onlyOwner {
        _requirePositive(id);
        _requiredGame(gameId);
        require(!_existsAchievementType(id), "Achievement type duplication");

        _achievementTypeIdList[gameId].push(id);
        _achievementTypeList[id] = AchievementType(id, gameId, title, false);

        emit AchievementTypeCreated(id, gameId, title);
    }

    function updateAchievementType(uint256 gameId, uint256 id, string memory title) external onlyOwner {
        _requiredGame(gameId);
        _requiredAchievementType(id);

        AchievementType storage achievement = _achievementTypeList[id];
        string memory oldTitle = achievement._title;
        uint256 oldGameId = achievement._gameId;

        achievement._title = title;
        achievement._gameId = gameId;

        emit AchievementTypeUpdated(achievement._id, oldGameId, gameId, oldTitle, title, achievement._isDeleted);
    }

    function getAchievementTypeByIndex(uint256 gameId, uint256 index) public view virtual returns (uint256 _id, uint256 _gameId, string memory _title, bool _isDeleted) {
        _requireCorrectAchievementTypesIndex(gameId, index);

        return getAchievementType(_achievementTypeIdList[gameId][index]);
    }

    function getAchievementType(uint256 id) public view virtual returns (uint256 _id, uint256 _gameId, string memory _title, bool _isDeleted) {
        _requiredAchievementType(id);

        return (_achievementTypeList[id]._id, _achievementTypeList[id]._gameId, _achievementTypeList[id]._title, _achievementTypeList[id]._isDeleted);
    }

    function moveAchievementTypeToAnotherGame(uint256 gameId, uint256 index, uint256 id, uint256 newGameId) external onlyOwner {
        removeAchievementTypeFromGame(gameId, index, id);
        restoreAchievementTypeToGame(newGameId, id);
    }

    function restoreAchievementTypeToGame(uint256 gameId, uint256 id) public onlyOwner {
        _requiredGame(gameId);
        _requiredAchievementType(id);

        AchievementType storage achievement = _achievementTypeList[id];
        uint256 oldGameId = achievement._gameId;

        require(oldGameId != gameId, "Same gameId");
        require(achievement._isDeleted, "Achievement isn't deleted");

        _achievementTypeIdList[gameId].push(id);
        achievement._isDeleted = false;
        achievement._gameId = gameId;

        emit AchievementTypeUpdated(achievement._id, oldGameId, gameId, achievement._title, achievement._title, achievement._isDeleted);
    }

    function removeAchievementTypeFromGame(uint256 gameId, uint256 index, uint256 id) public onlyOwner {
        _requiredGame(gameId);
        _requiredAchievementType(id);
        _requireCorrectAchievementTypesIndex(gameId, index);
        require(_achievementTypeIdList[gameId][index] == id, "Args aren't correct");

        _achievementTypeIdList[gameId][index] = _achievementTypeIdList[gameId][totalAchievementTypes(gameId)-1];
        _achievementTypeIdList[gameId].pop();

        AchievementType storage achievement = _achievementTypeList[id];
        uint256 oldGameId = achievement._gameId;

        achievement._isDeleted = true;
        achievement._gameId = 0;

        emit AchievementTypeUpdated(achievement._id, oldGameId, achievement._gameId, achievement._title, achievement._title, achievement._isDeleted);
    }

    function _requiredGame(uint id) internal view virtual {
        require(_existsGame(id), "Game not found");
    }

    function _existsGame(uint256 id) internal view virtual returns (bool) {
        return _gameList[id]._id > 0;
    }

    function _requiredAchievementType(uint256 id) internal view virtual {
        require(_existsAchievementType(id), "Achievement type not found");
    }

    function _existsAchievementType(uint256 id) internal view virtual returns (bool) {
        return _achievementTypeList[id]._id > 0;
    }

    function _requireCorrectAchievementTypesIndex(uint256 gameId, uint256 index) internal view virtual {
        require(index < totalAchievementTypes(gameId), "Index isn't correct");
    }

    function _requirePositive(uint256 id) internal view virtual {
        require(id > 0, "Id isn't positive");
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