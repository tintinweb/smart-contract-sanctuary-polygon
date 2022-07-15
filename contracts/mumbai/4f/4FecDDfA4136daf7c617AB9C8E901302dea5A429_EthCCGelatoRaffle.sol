// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {RaffleRules} from "./RaffleRules.sol";
import {RoundInfo, RoundLibrary} from "./libraries/RoundLibrary.sol";
import {IEthCCGelatoNFT} from "./interfaces/IEthCCGelatoNFT.sol";

//solhint-disable not-rely-on-time
contract EthCCGelatoRaffle is RaffleRules {
    using EnumerableSet for EnumerableSet.AddressSet;
    using RoundLibrary for mapping(uint256 => RoundInfo);

    //solhint-disable no-empty-blocks
    constructor(address _ops, uint256 _roundInterval)
        RaffleRules(_ops, _roundInterval)
    {}

    function joinRaffle(address _player)
        external
        onlyOps
        raffleLive
        hasGelatoNft(_player)
        notJoined(_player)
    {
        _roundInfo.addPlayerToRound(roundNow, _player);
    }

    function pickWinner()
        external
        onlyOps
        raffleLive
        winnerNotPicked
        roundIntervalPassed
        hasPlayers
    {
        uint256 round = roundNow;
        address[] memory players = _roundInfo.getPlayersOfRound(round);

        address winner = _selectWinner(players);

        _roundInfo.addWinnerToRound(round, winner);
        _startNewRound();

        emit LogWinner(round, winner);
    }

    /**
     * @dev Previous round winner must claim before
     * the end of current round.
     */
    function confirmWinner(address _player) external onlyAdmins {
        require(
            _isPreviousRoundWinner(roundNow, _player),
            "Raffle: Too late/ Not winner"
        );
        winners[_player] = true;
    }

    function startRaffle() external onlyAdmins rafflePaused {
        isRaffleLive = true;
        _startNewRound();
    }

    /**
     * @dev Ongoing round data will be cleared.
     * Round will restart from a new state the next
     * time `startRaffle` is called
     */
    function pauseRaffle() external onlyAdmins raffleLive {
        isRaffleLive = false;
        uint256 round = roundNow;

        delete _roundInfo[round];
        roundNow = round - 1;

        emit LogRafflePaused(round);
    }

    function setAdmins(address[] memory _user, bool _admin)
        external
        onlyProxyAdmin
    {
        uint256 length = _user.length;
        for (uint256 i; i < length; i++) {
            address user = _user[i];
            admins[user] = _admin;
        }
    }

    function setGelatoNft(IEthCCGelatoNFT _gelatoNft) external onlyProxyAdmin {
        gelatoNft = _gelatoNft;
    }

    function remainingTimeInRound() external view returns (uint256) {
        uint256 roundEndTime = _roundInfo.getStartTimeOfRound(roundNow) +
            roundInterval;
        if (block.timestamp >= roundEndTime) return 0;

        uint256 remainingTime = roundEndTime - block.timestamp;

        return remainingTime;
    }

    function getRoundInfo(uint256 _round)
        external
        view
        returns (
            uint256,
            address,
            address[] memory
        )
    {
        uint256 startTime = _roundInfo.getStartTimeOfRound(_round);
        address winner = _roundInfo.getWinnerOfRound(_round);
        address[] memory players = _roundInfo.getPlayersOfRound(_round);

        return (startTime, winner, players);
    }

    function enteredRound(uint256 _round, address _player)
        external
        view
        returns (bool)
    {
        return _roundInfo.playersContain(_round, _player);
    }

    /**
     * @dev Golden Gelato lasts for 1 round
     */
    function getGelatoIdAndState(address _player, uint256 _tokenId)
        external
        view
        returns (uint256, uint256)
    {
        uint256 round = roundNow;
        uint256 gelatoState = _getGelatoState();

        if (winners[_player]) return (_GOLD_ID, gelatoState);

        if (_isPreviousRoundWinner(round, _player))
            return (_GOLD_ID, gelatoState);

        uint256 gelatoId = (_tokenId + round) % _NORMAL_VARIANTS;
        return (gelatoId, gelatoState);
    }

    function _startNewRound() private {
        uint256 newRound = roundNow + 1;

        roundNow = newRound;
        _roundInfo.setRoundStartTime(newRound, block.timestamp);

        emit LogRoundStarted(newRound, block.timestamp);
    }

    /**
     * @dev Gelato will be FROZEN for 1/3 of round,
     * THAWED for 1/3 of round & MELTED for 1/3 of round
     */
    function _getGelatoState() private view returns (uint256) {
        if (!isRaffleLive) return uint256(GelatoState.FROZEN);

        uint256 startTime = _roundInfo.getStartTimeOfRound(roundNow);
        uint256 stateInterval = roundInterval /
            (uint256(type(GelatoState).max) + 1);

        uint256 state = (block.timestamp - startTime) / stateInterval;

        uint256 meltedState = uint256(GelatoState.MELTED);

        if (state > meltedState) state = meltedState;

        return state;
    }

    function _selectWinner(address[] memory _players)
        private
        view
        returns (address)
    {
        uint256 winnerPos = _rng() % (_players.length);
        return _players[winnerPos];
    }

    function _isPreviousRoundWinner(uint256 _roundNow, address _player)
        private
        view
        returns (bool)
    {
        if (
            _roundNow > 1 &&
            _player == _roundInfo.getWinnerOfRound(_roundNow - 1)
        ) return true;
        return false;
    }

    function _rng() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(block.difficulty, block.timestamp, tx.origin)
                )
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {RaffleStorage} from "./RaffleStorage.sol";
import {Proxied} from "./vendor/proxy/EIP173/Proxied.sol";
import {RoundInfo, RoundLibrary} from "./libraries/RoundLibrary.sol";

//solhint-disable not-rely-on-time
contract RaffleRules is Proxied, RaffleStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    using RoundLibrary for mapping(uint256 => RoundInfo);

    modifier onlyOps() {
        require(msg.sender == ops, "Raffle: Only Ops");
        _;
    }

    modifier onlyAdmins() {
        require(
            admins[msg.sender] || msg.sender == _proxyAdmin(),
            "Raffle: Only Admins"
        );
        _;
    }

    modifier raffleLive() {
        require(isRaffleLive, "Raffle: Not live");
        _;
    }

    modifier rafflePaused() {
        require(!isRaffleLive, "Raffle: Live");
        _;
    }

    modifier hasGelatoNft(address _player) {
        require(gelatoNft.balanceOf(_player) > 0, "Raffle: No Gelato nft");
        _;
    }

    modifier notJoined(address _player) {
        require(
            !_roundInfo.playersContain(roundNow, _player),
            "Raffle: Joined"
        );
        _;
    }

    modifier winnerNotPicked() {
        require(
            _roundInfo.getWinnerOfRound(roundNow) == address(0),
            "Raffle: Winner picked"
        );
        _;
    }

    modifier roundIntervalPassed() {
        uint256 roundStartTime = _roundInfo.getStartTimeOfRound(roundNow);
        require(roundStartTime > 0, "Raffle: Round not started");
        require(
            block.timestamp >= roundStartTime + roundInterval,
            "Raffle: Round in progress"
        );
        _;
    }

    modifier hasPlayers() {
        uint256 length = _roundInfo.getPlayersOfRound(roundNow).length;
        require(length > 0, "Raffle: No players");
        _;
    }

    //solhint-disable no-empty-blocks
    constructor(address _ops, uint256 _roundInterval)
        RaffleStorage(_ops, _roundInterval)
    {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IEthCCGelatoNFT} from "./interfaces/IEthCCGelatoNFT.sol";
import {RoundInfo} from "./libraries/RoundLibrary.sol";

//solhint-disable max-states-count
abstract contract RaffleStorage {
    enum GelatoState {
        FROZEN,
        THAWED,
        MELTED
    }

    address public immutable ops;
    uint256 public immutable roundInterval;
    uint256 internal constant _GOLD_ID = 6;
    uint256 internal constant _NORMAL_VARIANTS = 6;

    IEthCCGelatoNFT public gelatoNft;
    bool public isRaffleLive;
    uint256 public roundNow;
    mapping(uint256 => RoundInfo) internal _roundInfo;
    mapping(address => bool) public admins;
    mapping(address => bool) public winners;

    event LogWinner(uint256 indexed round, address indexed winner);
    event LogRoundStarted(uint256 indexed round, uint256 indexed startTime);
    event LogRafflePaused(uint256 indexed round);

    constructor(address _ops, uint256 _roundInterval) {
        ops = _ops;
        roundInterval = _roundInterval;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../vendor/oz/IERC721MetaTxEnumerable.sol";

interface IEthCCGelatoNFT is IERC721MetaTxEnumerable {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

struct RoundInfo {
    uint256 startTime;
    address winner;
    EnumerableSet.AddressSet players;
}

library RoundLibrary {
    using EnumerableSet for EnumerableSet.AddressSet;

    function addPlayerToRound(
        mapping(uint256 => RoundInfo) storage _roundInfo,
        uint256 _round,
        address _player
    ) internal {
        _roundInfo[_round].players.add(_player);
    }

    function removePlayerFromRound(
        mapping(uint256 => RoundInfo) storage _roundInfo,
        uint256 _round,
        address _player
    ) internal {
        _roundInfo[_round].players.remove(_player);
    }

    function addWinnerToRound(
        mapping(uint256 => RoundInfo) storage _roundInfo,
        uint256 _round,
        address _winner
    ) internal {
        _roundInfo[_round].winner = _winner;
    }

    function setRoundStartTime(
        mapping(uint256 => RoundInfo) storage _roundInfo,
        uint256 _round,
        uint256 _startTime
    ) internal {
        _roundInfo[_round].startTime = _startTime;
    }

    function playersContain(
        mapping(uint256 => RoundInfo) storage _roundInfo,
        uint256 _round,
        address _player
    ) internal view returns (bool) {
        return _roundInfo[_round].players.contains(_player);
    }

    function getStartTimeOfRound(
        mapping(uint256 => RoundInfo) storage _roundInfo,
        uint256 _round
    ) internal view returns (uint256) {
        return _roundInfo[_round].startTime;
    }

    function getWinnerOfRound(
        mapping(uint256 => RoundInfo) storage _roundInfo,
        uint256 _round
    ) internal view returns (address) {
        return _roundInfo[_round].winner;
    }

    function getPlayersOfRound(
        mapping(uint256 => RoundInfo) storage _roundInfo,
        uint256 _round
    ) internal view returns (address[] memory) {
        return _roundInfo[_round].players.values();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

//solhint-disable no-empty-blocks
interface IERC721MetaTxEnumerable is IERC721Enumerable {

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address adminAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            adminAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
    }
}