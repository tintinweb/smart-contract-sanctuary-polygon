// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
pragma solidity ^0.8.18;
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract SonanceV1 is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using Counters for Counters.Counter;

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    // Custom errors for gas saving
    error SongExists();
    error NameTaken();
    error NotOwner();
    error InvalidAmount();
    error InvalidAddress();
    error InvalidID();
    error DoesntExist();
    error AlreadyDeleted();

    /*
    New song event
    @param artist
    @param title
    @param songCID
    @param coverCID
     */
    event NewSong(
        address indexed owner,
        string artist,
        string title,
        string trackIPFS,
        string coverIPFS,
        bool explicit
    );

    /*
    New donation event
    @param sender: the donator
    @param index: the song id
    @param amount: the donation amount
     */
    event Donated(
        address indexed sender,
        uint256 indexed index,
        uint256 amount
    );

    /*
    New playlist event
    @param owner: owner of the playlist
    @param name: name of the playlist
    @param trackIds: the array of tracks
     */
    event NewPlaylist(address indexed owner, string name, uint256[] trackIds);

    /*
      Track is a struct that declares the necessary values for a song
      @param owner: the address that uploaded the song
      @param artist: the artist name
      @param title: the song title
      @param coverIPFS: the IPFS url for cover art
      @param trackIPFS: the IPFS url for the song
      @param genre: genre from the enum Genre
      @param explicit: default is false
      To get the avg rating, divide totalRatings / numRatings
     */
    struct Track {
        address owner;
        string artist;
        string title;
        string coverIPFS;
        string trackIPFS;
        uint songId;
        Genre genre;
        bool explicit;
    }

    /* 
    Playlist is a struct that takes in the trackIds as an array to build a playlist
    @param trackIds: the array of tracks in the palylist by ID
    @param name: the playlist name
    */
    struct Playlist {
        uint256[] trackIds;
        string name;
        address owner;
        uint playlistId;
    }

    /*
      Enum for Genre type
      @param genres: a list of all the popular genres 0-12
     */
    enum Genre {
        Unknown, // 0
        Pop, // 1
        Rock, // 2
        HipHop, // 3
        Rap, // 4
        Soul, // 5
        EDM, // 6
        Alternative, // 7
        Country, // 8
        Dance, // 9
        Jazz, // 10
        Classical, // 11
        Other // 12
    }

    Track[] public tracks; // reveals property of a track by id
    Playlist[] public playlists; // array of playlists
    Counters.Counter public trackIds; //  tracker for song id's
    Counters.Counter public playlistIds; // tracker for playlist id's
    mapping(uint256 => uint256) public likes; // input songId to see how many likes it has

    /*
    Function to upload a song
    @param _artist: artist name
    @param _title: song title
    @param _coverIPFS: the IPFS url for the song to play
    @param _trackIPFS: the IPFS url for the song to play
    @param _genre: select the appropriate
    @param _explicit: default is false 
    NOTE: Checks the keccak256 hash of the artist and title to prevent duplicates
    NOTE: Requires the msg.sender set their artist name first
   */
    function uploadTrack(
        string memory _artist,
        string memory _title,
        string memory _coverIPFS,
        string memory _trackIPFS,
        Genre _genre,
        bool _explicit
    ) external {
        for (uint256 i = 0; i < tracks.length; i++) {
            if (
                keccak256(bytes(tracks[i].artist)) ==
                keccak256(bytes(_artist)) &&
                keccak256(bytes(tracks[i].title)) == keccak256(bytes(_title)) &&
                keccak256(bytes(tracks[i].coverIPFS)) ==
                keccak256(bytes(_coverIPFS)) &&
                keccak256(bytes(tracks[i].trackIPFS)) ==
                keccak256(bytes(_trackIPFS))
            ) {
                revert SongExists();
            }
        }
        Track memory newTrack = Track(
            msg.sender,
            _artist,
            _title,
            _coverIPFS,
            _trackIPFS,
            trackIds.current(),
            _genre,
            _explicit
        );
        tracks.push(newTrack);
        trackIds.increment();
        emit NewSong(
            msg.sender,
            _artist,
            _title,
            _coverIPFS,
            _trackIPFS,
            _explicit
        );
    }

    /* 
    Function to like a track and add it to a playlist
    @param _songId: the song ID
    */
    function likeTrack(uint256 _songId) external {
        if (_songId >= tracks.length) {
            revert InvalidID();
        }
        likes[_songId]++;
    }

    /* 
    Function to delete a song
    @param _songId: the song id to delete
    */
    function deleteTrack(uint256 _songId) external {
        if (msg.sender != tracks[_songId].owner) {
            revert NotOwner();
        }
        if (_songId >= tracks.length) {
            revert DoesntExist();
        }
        delete tracks[_songId];
    }

    /* 
    Function to create a new playlist
    @param _name: the playlist name
    @param _trackIds: the tracks they want to add
    */
    function createPlaylist(
        string memory _name,
        uint256[] memory _trackIds
    ) external {
        if (_trackIds.length <= 0) {
            revert InvalidAmount();
        }
        Playlist memory newPlaylist = Playlist(
            _trackIds,
            _name,
            msg.sender,
            playlistIds.current()
        );
        playlists.push(newPlaylist);
        playlistIds.increment();
        emit NewPlaylist(msg.sender, _name, _trackIds);
    }

    /* 
    Function to delete a playlist
    @param _playlistId: the playlist ID to delete
    */
    function deletePlaylist(uint256 _playlistId) external {
        if (msg.sender != playlists[_playlistId].owner) {
            revert NotOwner();
        }
        if (_playlistId >= playlists.length) {
            revert DoesntExist();
        }
        if (playlists[_playlistId].trackIds.length <= 0) {
            revert AlreadyDeleted();
        }
        delete playlists[_playlistId].trackIds; // removes from trackIds array
        delete playlists[_playlistId]; // removes struct
    }

    /* 
    Function to donate to the artist that created the song
    @param _songId: the song ID
    NOTE: Takes the OpenZeppelin nonReentrant modifier to prevent attacks
    */
    function donateToArtist(uint256 _songId) external payable nonReentrant {
        if (msg.value <= 0) {
            revert InvalidAmount();
        }
        if (_songId >= tracks.length) {
            revert InvalidID();
        }
        address payable trackOwner = payable(tracks[_songId].owner);
        trackOwner.transfer(msg.value);
        emit Donated(msg.sender, _songId, msg.value);
    }

    /*
    Updates
     */

    /*
     Function to update playlist title 
     @param _playlistId: the playlistID
     @param _name: the new name
     */

    function updatePlaylistTitle(
        uint256 _playlistId,
        string memory _name
    ) external {
        if (msg.sender != playlists[_playlistId].owner) {
            revert NotOwner();
        }
        if (_playlistId > playlists.length) {
            revert DoesntExist();
        }
        playlists[_playlistId].name = _name;
    }

    /*
    Function to update artist
    @param _songId: the song ID
    @param _title: the new artist
   */
    function updateArtist(uint256 _songId, string memory _artist) external {
        if (msg.sender != tracks[_songId].owner) {
            revert NotOwner();
        }
        if (_songId > tracks.length) {
            revert InvalidID();
        }
        tracks[_songId].artist = _artist;
    }

    /*
    Function to update title
    @param _songId: the song ID
    @param _title: the new title
   */
    function updateTitle(uint256 _songId, string memory _title) external {
        if (msg.sender != tracks[_songId].owner) {
            revert NotOwner();
        }
        if (_songId > tracks.length) {
            revert InvalidID();
        }
        tracks[_songId].title = _title;
    }

    /*
    Function to update genre
    @param _songId: the song ID
    @param _genre: the new genre
   */
    function updateGenre(uint256 _songId, Genre _genre) external {
        if (msg.sender != tracks[_songId].owner) {
            revert NotOwner();
        }
        if (_songId > tracks.length) {
            revert InvalidID();
        }
        tracks[_songId].genre = _genre;
    }

    /*
    Function to update track IPFS url
    @param _songId: the song ID
    @param _trackIPFS: the new url
   */
    function updateTrackIPFS(
        uint256 _songId,
        string memory _trackIPFS
    ) external {
        if (msg.sender != tracks[_songId].owner) {
            revert NotOwner();
        }
        if (_songId > tracks.length) {
            revert InvalidID();
        }
        tracks[_songId].trackIPFS = _trackIPFS;
    }

    /*
    Function to update cover art
    @param _songId: the song ID
    @param _coverIPFS: the new url 
   */
    function updateCoverIPFS(
        uint256 _songId,
        string memory _coverIPFS
    ) external {
        if (msg.sender != tracks[_songId].owner) {
            revert NotOwner();
        }
        if (_songId > tracks.length) {
            revert InvalidID();
        }
        tracks[_songId].coverIPFS = _coverIPFS;
    }

    /*
    Function to update explicit label
    @param _songId: the song ID
    @param _explicit: True - explicit, False - not explicit
   */
    function updateExplicit(uint256 _songId, bool _explicit) external {
        if (msg.sender != tracks[_songId].owner) {
            revert NotOwner();
        }
        if (_songId > tracks.length) {
            revert InvalidID();
        }
        tracks[_songId].explicit = _explicit;
    }

    /* 
    Admin Only
    */

    /*
    Function to withdraw funds from the contract    
    NOTE: This is only for funds that are accidentally sent to the contract
    NOTE: Only the contract owner can call this function
    NOTE: Takes the OpenZeppellin nonReentrat to prevent attacks
    */
    function withdrawFunds() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available");
        payable(owner()).transfer(balance);
    }

    /* 
    Function to force delete a song that violates rules
    @param _songId: the song being deleted
    NOTE: This is only for those abusing copyright laws
    NOTE: Only the contract owner can call this function
    */

    function deleteAdminTrack(uint256 _songId) external onlyOwner {
        if (_songId > tracks.length) {
            revert DoesntExist();
        }
        delete tracks[_songId];
    }

    /* 
    Function to transfer ownership of the first 10 songs on deploy
    NOTE: This is only to rightfully give ownership to the first 10 songs released on deploy. 
    NOTE: Can only be called by the contract owner
    NOTE: Once ownership has transferred, the function cannot be called by contract owner again.
    @param: _songId: the song ID
    @param: _newOwner: the address of the new owner
    */

    function transferOriginalTrackOwnership(
        uint256 _songId,
        address _newOwner
    ) external onlyOwner {
        if (msg.sender != tracks[_songId].owner) {
            revert NotOwner();
        }
        if (_songId > 10) {
            revert DoesntExist();
        }
        tracks[_songId].owner = _newOwner;
    }
}