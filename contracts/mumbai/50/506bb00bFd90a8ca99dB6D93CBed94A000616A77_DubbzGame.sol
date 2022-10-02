/**
 *Submitted for verification at polygonscan.com on 2022-10-01
*/

pragma solidity 0.8.16;
// SPDX-License-Identifier: MIT

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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

        /// @solidity memory-safe-assembly
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
     * @dev Returns the number of values in the set. O(1).
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract DubbzGame is Ownable {

    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    mapping (address => bool) public isAuthorized;
    IERC20 public dUSDC;
    mapping (uint256 => EnumerableSet.UintSet) private gamePlayers;
    EnumerableSet.UintSet private activeGames;
    EnumerableSet.UintSet private closedGames;
    mapping (uint256 => uint256) public amountWonByPlayerId;
    mapping (uint256 => GameInfo) private gameInformation;
    mapping (uint256 => address) public userIdToWallet;
    address public platformReceiver;
    address public dividendReceiver;
    uint256 public feeLimit;

    uint256 public totalDividendsPaid;
    uint256 public totalPlatformPaid;
    uint256 public totalPayoutsPaid;

    struct GameInfo {
        string description;
        uint256 numberOfPlayers;
        uint256 playersRegistered;
        uint256 entryFee;
        uint256 totalEntryFee;
        uint256 totalPayout;
        uint256 dividendsPaid;
        uint256 platformPaid;
        bool active;
    }

    event GameInitialized(uint256 indexed gameId, string description, uint256 numberOfPlayers, uint256 entryFee);
    event PlayerRegistered(uint256 indexed gameId, bool indexed isWallet, address indexed walletAddress, uint256 amount);
    event PaidOut(uint256 indexed gameId, uint256 indexed playerId, uint256 indexed amount);
    event GameClosed(uint256 indexed gameId);
    event GameReopened(uint256 indexed gameId);
    event SentToDividends(address indexed divReceiver, uint256 amount);
    event SentToPlatform(address indexed platformReceiver, uint256 amount);

    constructor(address _dUSDC){
        dUSDC = IERC20(_dUSDC);
        isAuthorized[msg.sender] = true;
        platformReceiver = msg.sender;
        feeLimit = 500; // 5%
    }

    modifier onlyAuthorized {
        require(isAuthorized[msg.sender], "Not Authorized");
        _;
    }

    function setAuthorization(address account, bool authorized) external onlyOwner {
        isAuthorized[account] = authorized;
    }

    function setReceivers(address _dividendReceiver, address _platformReceiver) external onlyOwner {
        platformReceiver = _platformReceiver;
        dividendReceiver = _dividendReceiver;
    }

    function _registerPlayer(
        uint256 gameId,
        bool isWallet,
        address walletAddress,
        uint256 playerId,
        uint256 amount
    ) private {
        GameInfo storage gameInfo = gameInformation[gameId];
        require(gamePlayers[gameId].length() < gameInfo.numberOfPlayers, "Too many players");
        require(amount <= gameInfo.entryFee, "Amount too high");

        if(!gamePlayers[gameId].contains(playerId)){
            gamePlayers[gameId].add(playerId);
            gameInfo.playersRegistered += 1;
        } else {
            revert("Player already added to game");
        }

        if(isWallet){
            require(getWalletDusdcBalance(walletAddress) >= amount, "Not enough tokens");
            if(amount > 0){
                dUSDC.transferFrom(walletAddress, address(this), amount);
            }
            if(userIdToWallet[playerId] == address(0)){
                userIdToWallet[playerId] = walletAddress;
            }
        }
        
        gameInfo.totalEntryFee += amount;
        
        emit PlayerRegistered(gameId, isWallet, walletAddress, amount);
    }

    // used to start a game
    function initializeNewGame(
        uint256 gameId, 
        string calldata desc, 
        uint256 _numberOfPlayers, 
        uint256 entryFee, 
        uint256[] memory playerIds,
        address[] memory walletAddresses
    ) external onlyAuthorized {
        require(!activeGames.contains(gameId), "Game already created");
        activeGames.add(gameId);
        gameInformation[gameId] = (GameInfo({description: desc, numberOfPlayers: _numberOfPlayers, playersRegistered: 0, entryFee: entryFee, totalEntryFee: 0, totalPayout: 0, dividendsPaid: 0, platformPaid: 0, active: true }));
        for(uint256 i = 0; i < playerIds.length; i++){
            _registerPlayer(
                gameId,
                true,
                walletAddresses[i],
                playerIds[i],
                entryFee
            );
        }
        emit GameInitialized(gameId, desc, _numberOfPlayers, entryFee);
    }

    // register each player individually using this function
    function registerPlayer(
        uint256 gameId, 
        bool isWallet, 
        address walletAddress, 
        uint256 playerId, 
        uint256 amount
    ) external onlyAuthorized {
       _registerPlayer(
        gameId,
        isWallet, 
        walletAddress,
        playerId,
        amount
       );
    }

    //  payout each game
    function payOutWinners(
        uint256 gameId, 
        uint256[] memory playerIds, 
        uint256[] memory amounts, 
        uint256[] memory platformFees, 
        uint256[] memory dividendFees, 
        bool closeGame
    ) external onlyAuthorized {

        require(activeGames.contains(gameId), "Game Not Active");
        require(playerIds.length == amounts.length && amounts.length == platformFees.length && platformFees.length == dividendFees.length, "Array length mismatch");
        
        uint256 playerId;
        uint256 amount;
        uint256 totalDividendPayout;
        uint256 totalPlatformPayout;
        uint256 totalPayoutAmount;

        for(uint256 i = 0; i < playerIds.length; i++){
            playerId = playerIds[i];
            amount = amounts[i];
            require(getContractDusdcBalance() >= amount, "Not enough dUSDC to payout");
            require(gamePlayers[gameId].contains(playerId), "Player not registered");
            if(userIdToWallet[playerId] != address(0)){
                dUSDC.transfer(userIdToWallet[playerId], amount);
            }
            totalDividendPayout = dividendFees[i];
            totalPlatformPayout = platformFees[i];
            totalPayoutAmount = amounts[i];
            amountWonByPlayerId[playerId] += amount;
            emit PaidOut(gameId, playerId, amount);
        }

        GameInfo storage gameInfo = gameInformation[gameId];
        require(totalDividendPayout + totalPlatformPayout + totalPayoutAmount + gameInfo.totalPayout + gameInfo.dividendsPaid + gameInfo.platformPaid <= gameInfo.totalEntryFee, "Payout too high");

        gameInfo.totalPayout += totalPayoutAmount;
        totalPayoutsPaid += totalPayoutAmount;

        if(totalDividendPayout > 0){
            dUSDC.transfer(dividendReceiver, totalDividendPayout);
            gameInfo.dividendsPaid += totalDividendPayout;
            totalDividendsPaid += totalDividendPayout;
            emit SentToDividends(dividendReceiver, totalDividendPayout);
        }

        if(totalPlatformPayout > 0){
            dUSDC.transfer(platformReceiver, totalPlatformPayout);
            gameInfo.platformPaid += totalPlatformPayout;
            totalPlatformPaid += totalPlatformPayout;
            emit SentToPlatform(dividendReceiver, totalDividendPayout);
        }

        if(closeGame){
            activeGames.remove(gameId);
            closedGames.add(gameId);
            gameInfo.active = false;
            emit GameClosed(gameId);
        }
    }

    //for emergency reopening a game to finish payouts
    function reopenGame(uint256 gameId) external onlyOwner {
        GameInfo storage gameInfo = gameInformation[gameId];
        require(closedGames.contains(gameId), "Game is not closed");
        
        activeGames.add(gameId);
        closedGames.remove(gameId);
        gameInfo.active = true;
        emit GameReopened(gameId);
    }

    function getGameInfo(uint256 gameId) external view returns (GameInfo memory){
        return gameInformation[gameId];
    }

    function getGamePlayers(uint256 gameId) external view returns (uint256[] memory){
        return gamePlayers[gameId].values();
    }

    function getGameInfoWithPlayers(uint256 gameId) external view returns (GameInfo memory, uint256[] memory){
        return (gameInformation[gameId], gamePlayers[gameId].values());
    }
    function getContractDusdcBalance() public view returns (uint256){
        return dUSDC.balanceOf(address(this));
    }

    function getWalletDusdcBalance(address holder) public view returns (uint256){
        return dUSDC.balanceOf(holder);
    }

    function getActiveGames() public view returns (uint256[] memory){
        return activeGames.values();
    }
    
    function getInactiveGames() public view returns (uint256[] memory){
        return closedGames.values();
    }
}