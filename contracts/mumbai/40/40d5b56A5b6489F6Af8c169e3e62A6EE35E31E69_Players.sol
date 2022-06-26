//SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IShip.sol";
import "./interfaces/IWorld.sol";
import "./interfaces/IHashVault.sol";


contract Players is Initializable, OwnableUpgradeable {
   using CountersUpgradeable for CountersUpgradeable.Counter;

    uint256 constant public NFTPRICE = 0.01 ether;

    struct PersonProfile {
            uint256 playerId;
            uint256 timeJoined;
            uint256 lastQueried;
            uint256 stepsAvailable;
            uint256 totalStepsTaken;
            uint256 amountEarned;
    }

    CountersUpgradeable.Counter indexPlayerIds;
    CountersUpgradeable.Counter public indexStartingPosition;
    address public BACKEND;
    address public NFT;
    address public WORLD;
    address public AAVE_VAULT;

    mapping (address => PersonProfile) public players;

    event TreasuryFunded(uint amountFunded);

    event StepsAdded(uint stepsTaken, address player, uint timestamp);

    event PlanetConquer(address indexed player, uint amount, uint planetType, uint timestamp); // TODO: add planetId


    function initialize() public initializer {
        __Ownable_init();
    }

    /**
        The address of our web2 backend.
        Messages from the backend which are verified in this contract
     */
    function setBackendAddress(address _address) public onlyOwner {
        BACKEND = _address;
    }

    /**
        We set the Nft Contract
     */
    function setNftAddress(address _nftContractAddress) public onlyOwner {
        NFT = _nftContractAddress;
    }

    /**
        We set the Worldcontract Contract
     */
    function setWorldAddress(address _worldAddress) public onlyOwner {
        WORLD = _worldAddress;
    }

    function setAaveVault(address _address) public onlyOwner {
        AAVE_VAULT = _address;
    }

    /**
        Creates the user profile of the user and mints a starship nft
        and forwards $$ to the treasury
     */
    function registerProfile(string memory _tokenURI) public payable
     {
        _createProfile();

        require(msg.value == NFTPRICE, "Not enought/too much ether sent");

        // put coins to work in vault
        IHashVault(AAVE_VAULT).deposit{value: msg.value}();

        // mint ship
        uint256 shipId = IShip(NFT).mint(msg.sender, _tokenURI);
        (uint startingX, uint startingY) = determineStartingPosition();
        IShip(NFT).setLocation(shipId, msg.sender, startingX, startingY);
    }

    function _createProfile() private {
        PersonProfile storage player = players[msg.sender];
        require(player.playerId == 0, "you already signed up");
        indexPlayerIds.increment();
        player.playerId = indexPlayerIds.current();
        player.timeJoined = block.timestamp;
        // give the user 12 hour window, so that he does not sign up with zero steps
        player.lastQueried = block.timestamp - (60*60*12);
        player.stepsAvailable = 0;
        player.totalStepsTaken = 0;
        player.amountEarned = 0;
    }

    /**
        Sync the steps for the user
    */
    function syncSteps(
        bytes32 _hashedMessageBackend,
        uint256 _steps,
        uint256 _lastQueried,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        // verify
        PersonProfile storage player = players[msg.sender];
        require(player.playerId != 0, "you need to be registered");

        require(_lastQueried == player.lastQueried, "last queried does not match");
        verifySteps(_hashedMessageBackend, _steps, _lastQueried, _v, _r, _s);

        // write
        player.totalStepsTaken += _steps;
        player.stepsAvailable += _steps;
        player.lastQueried = block.timestamp;
        emit StepsAdded(_steps, msg.sender, block.timestamp);
    }

    function verifySteps(
        bytes32 _hashedMessageBackend,
        uint256 _message,
        uint256 _lastQueried,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public view {

        bytes32 hashedMessageSol = keccak256(abi.encode(_message, _lastQueried));
        require(hashedMessageSol == _hashedMessageBackend, "payload was modified");

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessageBackend));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);

        require(signer == address(BACKEND), "wrong signer");
    }

    /**
        Move the ship to a new position
        {_planetId} the planet you want to reach
        {_shipId} the ship you are moving
     */
    function moveShip(uint x, uint y, uint _planetId, uint _shipId, uint _worldId) public payable {

        // current location of the ship
        (uint xCoordShip, uint yCoordShip) = IShip(NFT).getLocation(_shipId);

        // calculate distance moved
        uint travelX = get_abs_diff(xCoordShip, x);
        uint travelY = get_abs_diff(yCoordShip, y);
        uint travelDistance = uint(sqrt((travelX * travelX) + (travelY * travelY)));

        // check enough steps available
        require(players[msg.sender].stepsAvailable > travelDistance * 10, "Not enough steps available to move there");

        // update steps of user
        players[msg.sender].stepsAvailable -= travelDistance * 10;

        // update ship position
        IShip(NFT).setLocation(_shipId, msg.sender, x, y);

        // check if we landed on a planet
        SharedStructs.Planet memory planet = IWorld(WORLD).getPlanet(_planetId);

        if (x == planet.xCoord && y == planet.yCoord) {
            _payout(planet.planetType);
        }
    }

    function _payout(uint planetType) internal {
        // route to vaults
        if (planetType == 1) {
            uint yield = IHashVault(AAVE_VAULT).yield();

            if (yield > 0 && yield > 0.0000002 ether) { // did run into issues with the amount is too low
                IHashVault(AAVE_VAULT).withdraw(msg.sender);
                players[msg.sender].amountEarned += yield;
                emit PlanetConquer(msg.sender, yield, planetType, block.timestamp);
                return;
            }
        }
        emit PlanetConquer(msg.sender, 0, planetType, block.timestamp);
    }

    function get_abs_diff(uint val1, uint val2) private pure returns (uint) {
        return val1 > val2 ? val1 - val2 : val2 - val1;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function determineStartingPosition() internal returns(uint x, uint y) {

        indexStartingPosition.increment();
        uint positionIndex = indexStartingPosition.current();

        uint startingX = positionIndex * 42;
        uint startingY = 16;

        if (positionIndex == 46) {
            indexStartingPosition.reset();
        }

        return (startingX, startingY);
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
library CountersUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.0 <0.9.0;

interface IShip {
    /**
      gets the location of the ship
    */
    function getLocation(
        uint256 _tokenId
    ) external returns (uint x, uint y);

    /**
      sets the location of the ship
    */
    function setLocation(
        uint256 _tokenId,
        address _ownerAddress,
        uint x,
        uint y
    ) external;

    /**
      mints a new nft ship
     */
    function mint(address player, string memory _tokenURI) external returns (uint256);
}

//SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.0 <0.9.0;

import "../structs/shared.sol";

interface IWorld {

    /**
      gets a planet
    */
    function getPlanet(uint _planetId) external view returns (SharedStructs.Planet memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IHashVault {
    function deposit() external payable;
    function withdraw(address _receiver) external;
    function yield() external view returns(uint);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

library SharedStructs {
        // Define planet information
    struct Planet {
        uint planetID; // an ID that is unique across all world maps
        uint worldMapIndex; // which world map does this planet belong to
        uint xCoord; // x-axis coordinate in respective world map
        uint yCoord; // y-axis coordinate in respective world map
        uint planetType;
        uint balance; // The total value of tokens inside the planet
    }
}