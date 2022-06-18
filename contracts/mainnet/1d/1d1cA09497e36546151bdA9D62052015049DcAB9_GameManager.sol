// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                              //
//                                                                                                                              //
//                                                                                             ....    .:-===-.                 //
//                                             .:--:.      --==:   .+++++.:***#-       [email protected]@@@@@@@@@@+ -%@@@@@@@@@+               //
//                -*****##*+-    #%@@#   =#@@@@@@@@+   [email protected]@@@:  [email protected]@@@=  [email protected]@@@.       @@@@@@@%%%%%:[email protected]@@@=:-*@@@@-                 //
//                %@@@@@@@@@@@+ [email protected]@@@= [email protected]@@@@#*#@@@@%. *@@@@ [email protected]@@@=    %@@@%       [email protected]@@@-        [email protected]@@@*=-.                      //
//               [email protected]@@@+-:-#@@@@[email protected]@@@[email protected]@@@+    -%###= @@@@@@@@@+     [email protected]@@@+       [email protected]@@@@%@@@@=  .#@@@@@@@@%+.                  //
//               [email protected]@@@    *@@@@.%@@@% @@@@%           :@@@@@@@@@=     [email protected]@@@.       %@@@@######.     -+*%@@@@@@.                 //
//               %@@@@%%%@@@@@[email protected]@@@+ @@@@*         . [email protected]@@@@%@@@@-    #@@@%       [email protected]@@@+        ****+    *@@@@-                 //
//              [email protected]@@@@@@@@@#+. [email protected]@@@: @@@@@     %@@@@ %@@@%  #@@@@-   @@@@%++++**[email protected]@@@%##%%%%% [email protected]@@@@#*%@@@@*                  //
//              [email protected]@@@.         *@@@@  [email protected]@@@@#*#@@@@%[email protected]@@@+   #@@@@- [email protected]@@@@@@@@@@ *@@@@@@@@@@@*  :*%@@@@@@#+.                   //
//              %@@@#          @@@@*   .+%@@@@@@@*-  -%%##.    ****+.-++======--: ::::::......        .....                     //
//              ++++-          -:::.       .::.     .:::.           --===      .+*****##*+-   -%%@@@@@@@@@%                     //
//                 -----=====++:  -*#%%%%#+.     -#@@@@@@@%=       *@@@@@=     [email protected]@@@@@@@@@@@. *@@@@@@@@%%%+                     //
//                [email protected]@@@@@@@@@@@[email protected]@@@@%@@@@@=  :%@@@@%#%@@@@%     [email protected]@@@@@%     *@@@@[email protected]@@@* @@@@#                             //
//                [email protected]@@@+=====-- @@@@#   =+++= [email protected]@@@*    -%%%%-   [email protected]@@#@@@@-    @@@@*   [email protected]@@@*:@@@@@%%%@@%                       //
//                #@@@@-=====   #@@@@@%#*=:   @@@@%             [email protected]@@# %@@@#   :@@@@%%%@@@@@%[email protected]@@@%%####=                       //
//                @@@@@@@@@@%    -#@@@@@@@@%: @@@@*        ..  [email protected]@@#[email protected]@@@.  *@@@@@@%%%#+:  @@@@#                              //
//               [email protected]@@@+---::.       .:=#@@@@% @@@@@     %@@@@ [email protected]@@@@@@@@@@@*  @@@@#         [email protected]@@@@%%%%@@@=                      //
//               *@@@@::[email protected]@@@%-::[email protected]@@@* [email protected]@@@@*+*@@@@@:[email protected]@@@***++%@@@@.:@@@@=         [email protected]@@@@@@@@@@@.                      //
//               @@@@@@@@@@@@+ [email protected]@@@@@@@@@@+   :*@@@@@@@@#= [email protected]%%%.     -#***-:++++.         .--:::::.....                       //
//              :#####******+.   :=+++++=:        .::-:.                                                                        //
//                                                                                                                              //
//                                                                                                          www.miinded.com     //
//                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "./AdminGame.sol";
import "./IPickleEscape.sol";

contract GameManager is AdminGame, IGameResponse {

    uint16 public seasonId;
    uint8 public dayId;
    bytes32 internal hashSD;
    uint8 maxWays = 6;

    struct Game {
        uint16 seasonId;
        uint8 dayId;
        uint8 state;
        bool isFinalDay;

        bool walletsNotChooseDone;

        bool selectWinnerWayDone;
        bool selectLostPicklesDone;
        bool[7] loadRepartitionDone;
        bool[7] killPickleDone;
        bool dayDone;

        bool finalLoadWalletNotChooseDone;
        bool finalLoadRepartitionDone;
        bool finalKillPickleDone;
        bool finalSetWinnerSeasonDone;
        bool finalDone;
    }

    //////////////////////////////////////////////////
    // Globals
    //////////////////////////////////////////////////
    // hash(seasonId => dayId) => GameManager
    mapping(bytes32 => Game) internal _gameManager;

    IPickleEscape public pickleEscape;

    //////////////////////////////////////////////////
    // Events
    //////////////////////////////////////////////////
    event GameManagerResponse(string method, uint16 offset, uint16 total, uint16 state, uint16 data1, uint16 seasonId, uint8 dayId);

    constructor(){}

    //////////////////////////////////////////////////
    // Game Step Execute
    //////////////////////////////////////////////////
    function gameExecute(uint16 _length) public onlyAdmin {

        if (_gameManager[hashSD].state <= 3) {
            emit GameManagerResponse("nothingDoTo", 0, 0, _gameManager[hashSD].state, 0, seasonId, dayId);
            return;
        }

        if (_gameManager[hashSD].isFinalDay) {

            if (!_gameManager[hashSD].finalLoadWalletNotChooseDone) {
                _gameManager[hashSD].finalLoadWalletNotChooseDone = response(pickleEscape._finalLoadWalletNotChosen(_length));
                return;
            }

            _gameManager[hashSD].state = 7;

            if (!_gameManager[hashSD].finalLoadRepartitionDone) {
                _gameManager[hashSD].finalLoadRepartitionDone = response(pickleEscape._finalLoadRepartition(_length));
                return;
            }

            _gameManager[hashSD].state = 8;

            if (!_gameManager[hashSD].finalKillPickleDone) {
                _gameManager[hashSD].finalKillPickleDone = response(pickleEscape._finalKillPickles(_length));
                return;
            }

            _gameManager[hashSD].state = 9;

            if (!_gameManager[hashSD].finalSetWinnerSeasonDone) {
                _gameManager[hashSD].finalSetWinnerSeasonDone = response(pickleEscape._finalSetWinnerSeason(_length));
                return;
            }

            _gameManager[hashSD].state = 10;

            nextDay();

            return;
        }

        if (!_gameManager[hashSD].walletsNotChooseDone) {
            _gameManager[hashSD].walletsNotChooseDone = response(pickleEscape._walletsNotChoose(_length));
            return;
        }

        _gameManager[hashSD].state = 6;

        if (!_gameManager[hashSD].selectWinnerWayDone) {
            _gameManager[hashSD].selectWinnerWayDone = response(pickleEscape._setWinnerWay());
            return;
        }

        _gameManager[hashSD].state = 7;

        if (!_gameManager[hashSD].selectLostPicklesDone) {
            _gameManager[hashSD].selectLostPicklesDone = response(pickleEscape._loadWaysKill());
            return;
        }

        _gameManager[hashSD].state = 8;

        for (uint8 wayId = 0; wayId <= maxWays; wayId++) {
            if (!_gameManager[hashSD].loadRepartitionDone[wayId]) {
                _gameManager[hashSD].loadRepartitionDone[wayId] = response(pickleEscape._loadRepartition(wayId, _length));
                return;
            }
        }
        _gameManager[hashSD].state = 9;

        for (uint8 wayId = 0; wayId <= maxWays; wayId++) {
            if (!_gameManager[hashSD].killPickleDone[wayId]) {
                _gameManager[hashSD].killPickleDone[wayId] = response(pickleEscape._killPickle(wayId, _length));
                return;
            }
        }

        _gameManager[hashSD].state = 10;

        nextDay();

        return;
    }

    //////////////////////////////////////////////////
    // Getters
    //////////////////////////////////////////////////
    function getCurrentSeasonId() public view returns(uint16){
        return seasonId;
    }
    function getCurrentDayId() public view returns(uint8){
        return dayId;
    }
    function getCurrentGameState() public view returns (uint8){
        return _gameManager[hashSD].state;
    }
    function response(Response memory _response) internal returns (bool){
        emit GameManagerResponse(_response.method, _response.offset, _response.total, _gameManager[hashSD].state, _response.data, seasonId, dayId);
        return _response.done;
    }
    function dateIn(uint64 _start, uint64 _end) public view onlyAdmin returns(bool){
        return block.timestamp >= _start && _end <= block.timestamp;
    }
    function getHashSD(uint16 _seasonId, uint8 _dayId) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_seasonId, _dayId));
    }

    //////////////////////////////////////////////////
    // Setters
    //////////////////////////////////////////////////
    function setPickleEscapeGameContract(address _pickleEscape) public onlyAdmin {
        pickleEscape = IPickleEscape(_pickleEscape);
    }
    function setNewHashSD() public onlyAdmin {
        hashSD = getHashSD(seasonId, dayId);
    }
    function setCurrentGameState(uint8 _state) public onlyAdmin {
        emit GameManagerResponse('setCurrentGameState', 0, 0, _gameManager[hashSD].state, _state, seasonId, dayId);
        _gameManager[hashSD].state = _state;
    }

    //////////////////////////////////////////////////
    // Next steps
    //////////////////////////////////////////////////
    function nextDay() public onlyAdmin {

        _gameManager[hashSD].dayDone = true;

        dayId += 1;

        setNewHashSD();

        _gameManager[hashSD].isFinalDay = response(pickleEscape._setDayId(dayId));

        _gameManager[hashSD].seasonId = seasonId;
        _gameManager[hashSD].dayId = dayId;

        _gameManager[hashSD].state = 2;
    }

    function nextSeason() public onlyAdmin {

        seasonId += 1;
        dayId = 0;

        setNewHashSD();

        response(pickleEscape._setSeasonId(seasonId));

        _gameManager[hashSD].seasonId = seasonId;
        _gameManager[hashSD].dayId = dayId;
        _gameManager[hashSD].state = 1;
    }

    //////////////////////////////////////////////////
    // Exposed
    //////////////////////////////////////////////////
    function addPickleBalanceIn(uint16 _jarId, uint16 _count) public onlyAdmin {

        require(_gameManager[hashSD].dayId == 0, "MNO");

        pickleEscape._addPickleBalanceIn(_jarId, _count);
    }

    function addPickleBalanceInMany(uint16[] memory _jarIds, uint16[] memory _counts) public onlyAdmin {

        require(_gameManager[hashSD].dayId == 0, "MNO");

        pickleEscape._addPickleBalanceInMany(_jarIds, _counts);
    }

    function chooseWayMany(uint16[] memory _wayIds, uint16[] memory _jarIds) public onlyAdmin {

        if(_gameManager[hashSD].state == 2 || _gameManager[hashSD].state == 3){
            pickleEscape._chooseWayMany(_wayIds, _jarIds);
        }

        if(_gameManager[hashSD].isFinalDay){
            pickleEscape._finalChoosePlane(_wayIds, _jarIds);
        }
    }

    function activeBonusFor(uint16 _jarId, uint8 _bonusId) public onlyAdmin {
        pickleEscape._activeBonusFor(_jarId, _bonusId);
    }

    function activeBonusForMany(uint16[] memory _jarIds, uint8[] memory _bonusIds) public onlyAdmin {
        pickleEscape._activeBonusForMany(_jarIds, _bonusIds);
    }

    //////////////////////////////////////////////////
    // Admin
    //////////////////////////////////////////////////
    function getGame(uint16 _seasonId, uint8 _dayId) public view returns (Game memory){
        bytes32 _hashSD = getHashSD(_seasonId, _dayId);
        return _gameManager[_hashSD];
    }
    function getCurrentGame() public view returns (Game memory){
        return _gameManager[hashSD];
    }
    function setGame(uint16 _seasonId, uint8 _dayId, Game memory _game) public onlyAdmin {
        bytes32 _hashSD = getHashSD(_seasonId, _dayId);
        _gameManager[_hashSD] = _game;
    }
    function getGameState(uint16 _seasonId, uint8 _dayId) public view returns (uint8){
        bytes32 _hashSD = getHashSD(_seasonId, _dayId);
        return _gameManager[_hashSD].state;
    }
    function setNewHashSD(uint16 _seasonId, uint8 _dayId) public onlyAdmin {
        hashSD = getHashSD(_seasonId, _dayId);
    }
    function setGameState(uint16 _seasonId, uint8 _dayId, uint8 _state) public onlyAdmin {
        bytes32 _hashDS = getHashSD(_seasonId, _dayId);
        emit GameManagerResponse('setGameState', 0, 0, _gameManager[_hashDS].state, _state, _seasonId, _dayId);
        _gameManager[_hashDS].state = _state;
    }
    function setSeasonId(uint16 _seasonId) public onlyAdmin {

        seasonId = _seasonId;
        dayId = 0;

        response(pickleEscape._setSeasonId(_seasonId));

        setNewHashSD();

        _gameManager[hashSD].seasonId = seasonId;
        _gameManager[hashSD].dayId = dayId;
    }
    function setDayId(uint8 _dayId) public onlyAdmin {

        response(pickleEscape._setDayId(_dayId));

        dayId = _dayId;

        setNewHashSD();

        _gameManager[hashSD].dayDone = false;

        _gameManager[hashSD].seasonId = seasonId;
        _gameManager[hashSD].dayId = dayId;

    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AdminGame is Ownable{

    mapping(address => bool) admins;

    modifier onlyAdmin(){
        require(admins[_msgSender()] || owner() == _msgSender(), "BAW");
        _;
    }

    function setAdminAddress(address _admin, bool _toggle) public onlyOwner {
        admins[_admin] = _toggle;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IGameResponse.sol";

interface IPickleEscape is IGameResponse {

    function transfer(address _from, address _to, uint256 _tokenId) external;
    function burnOneFor(uint16 _jarId) external;
    function totalPickle() external view returns(uint256);

    function _addPickleBalanceIn(uint16 _jarId, uint16 _count) external;
    function _addPickleBalanceInMany(uint16[] memory _jarIds, uint16[] memory _counts) external;
    function _chooseWayMany(uint16[] memory _wayId, uint16[] memory _jarIds) external;
    function _activeBonusFor(uint16 _jarId, uint8 _bonusId) external;
    function _activeBonusForMany(uint16[] memory _jarIds, uint8[] memory _bonusIds) external;
    function _finalChoosePlane(uint16[] memory _placeId, uint16[] memory _jarId) external;

    function _finalLoadWalletNotChosen(uint16 _length) external returns(Response memory);
    function _finalLoadRepartition(uint16 _length) external returns(Response memory);
    function _finalKillPickles(uint16 _length) external returns(Response memory);
    function _finalSetWinnerSeason(uint16 _length) external returns(Response memory);

    function _burnNfts(uint16 _length) external returns(Response memory);
    function _setSeasonId(uint16 _seasonId) external returns(Response memory);
    function _setDayId(uint8 _dayId) external returns(Response memory);

    function _walletsNotChoose(uint16 _length) external returns(Response memory);

    function _setWinnerWay() external returns(Response memory);
    function _loadWaysKill() external returns(Response memory);

    function _loadRepartition(uint8 _wayId, uint16 _length) external returns(Response memory);
    function _killPickle(uint8 _wayId, uint16 _length) external returns(Response memory);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGameResponse {

    struct Response{
        bool done;
        string method;
        uint16 offset;
        uint16 total;
        uint16 data;
    }
}