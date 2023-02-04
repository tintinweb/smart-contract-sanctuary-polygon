// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "../../accounts/CryptopiaAccountRegister/ICryptopiaAccountRegister.sol";
import "../AvatarEnums.sol";
import "./ICryptopiaAvatarRegister.sol";

/// @title Cryptopia Avatar Register
/// @notice Register for avatar data
/// @author Frank Bonnet - <[email protected]>
contract CryptopiaAvatarRegister is ICryptopiaAvatarRegister, ContextUpgradeable {

    struct AvatarData
    {
        // Required {Male, Female}
        AvatarEnums.Gender gender;

        // Body
        uint8 bodyWeight; // muscular for male, roudings for female
        uint8 bodyShape; // in kilos

        // Style
        uint8 hairStyleIndex;
        uint8 eyeColorIndex;
        uint8 skinColorIndex;

        // Cloting
        uint8 defaultHatIndex;
        uint8 defaultShirtIndex;
        uint8 defaultPantsIndex;
        uint8 defaultShoesIndex;
    }


    /**
     * Storage
     */
    // Refs
    address public accountRegisterContract;

    // Account => AvatarData
    mapping (address => AvatarData) public avatarDatas;


    /**
     * Events
     */
    /// @dev Emited when an avatar is changed
    /// @param account The address of the (multisig) account that owns the avatar data
    event ChangeAvatarData(address indexed account);


    /** 
     * Public functions
     */
    /// @param _accountRegisterContract Contract responsible for accounts
    function initialize(
        address _accountRegisterContract) 
        public initializer 
    {
        __Context_init();

        // Assign refs
        accountRegisterContract = _accountRegisterContract;
    }


    /// @dev Returns data that is used to create the avatar for `account`
    /// @param account The address of the (mulstisig) account to return the avatar data for
    /// @return gender {Male, Female}
    /// @return bodyWeight The avatar body weight in kilos
    /// @return bodyShape The avatar body shape, the higher the value the better the shape (muscles for male, roundings for female)
    /// @return hairStyleIndex Refers to hairstyles in the game client
    /// @return eyeColorIndex Refers to eye colors in the game client
    /// @return skinColorIndex Refers to skin colors in the game client
    /// @return defaultHatIndex Refers to a hat in the game client (0 signals no hat)
    /// @return defaultShirtIndex Refers to a shirt in the game client (0 signals no shirt)
    /// @return defaultPantsIndex Refers to a pants in the game client (0 signals no pants)
    /// @return defaultShoesIndex Refers to a shoes in the game client (0 signals no shoes)
    function getAvatarData(address account)
        public virtual override view 
        returns (
            AvatarEnums.Gender gender,
            uint8 bodyWeight,
            uint8 bodyShape,
            uint8 hairStyleIndex,
            uint8 eyeColorIndex,
            uint8 skinColorIndex,
            uint8 defaultHatIndex,
            uint8 defaultShirtIndex,
            uint8 defaultPantsIndex,
            uint8 defaultShoesIndex
        )
    {
        gender = avatarDatas[account].gender;
        bodyWeight = avatarDatas[account].bodyWeight;
        bodyShape = avatarDatas[account].bodyShape;
        hairStyleIndex = avatarDatas[account].hairStyleIndex;
        eyeColorIndex = avatarDatas[account].eyeColorIndex;
        skinColorIndex = avatarDatas[account].skinColorIndex;
        defaultHatIndex = avatarDatas[account].defaultHatIndex;
        defaultShirtIndex = avatarDatas[account].defaultShirtIndex;
        defaultPantsIndex = avatarDatas[account].defaultPantsIndex;
        defaultShoesIndex = avatarDatas[account].defaultShoesIndex;
    }


    /// @dev Returns data that is used to create the avatars for `accounts`
    /// @param accounts The addresses of the (mulstisig) accounts to return avatar data for
    /// @return gender {Male, Female}
    /// @return bodyWeight The avatar body weight in kilos
    /// @return bodyShape The avatar body shape, the higher the value the better the shape (muscles for male, roundings for female)
    /// @return hairStyleIndex Refers to hairstyles in the game client
    /// @return eyeColorIndex Refers to eye colors in the game client
    /// @return skinColorIndex Refers to skin colors in the game client
    /// @return defaultHatIndex Refers to a hat in the game client (0 signals no hat)
    /// @return defaultShirtIndex Refers to a shirt in the game client (0 signals no shirt)
    /// @return defaultPantsIndex Refers to a pants in the game client (0 signals no pants)
    /// @return defaultShoesIndex Refers to a shoes in the game client (0 signals no shoes)
    function getAvatarDatas(address[] memory accounts)
        public virtual override view 
        returns (
            AvatarEnums.Gender[] memory gender,
            uint8[] memory bodyWeight,
            uint8[] memory bodyShape,
            uint8[] memory hairStyleIndex,
            uint8[] memory eyeColorIndex,
            uint8[] memory skinColorIndex,
            uint8[] memory defaultHatIndex,
            uint8[] memory defaultShirtIndex,
            uint8[] memory defaultPantsIndex,
            uint8[] memory defaultShoesIndex
        )
    {
        gender = new AvatarEnums.Gender[](accounts.length);
        bodyWeight = new uint8[](accounts.length);
        bodyShape = new uint8[](accounts.length);
        hairStyleIndex = new uint8[](accounts.length);
        eyeColorIndex = new uint8[](accounts.length);
        skinColorIndex = new uint8[](accounts.length);
        defaultHatIndex = new uint8[](accounts.length);
        defaultShirtIndex = new uint8[](accounts.length);
        defaultPantsIndex = new uint8[](accounts.length);
        defaultShoesIndex = new uint8[](accounts.length);
        
        for (uint i = 0; i < accounts.length; i++)
        {
            gender[i] = avatarDatas[accounts[i]].gender;
            bodyWeight[i] = avatarDatas[accounts[i]].bodyWeight;
            bodyShape[i] = avatarDatas[accounts[i]].bodyShape;
            hairStyleIndex[i] = avatarDatas[accounts[i]].hairStyleIndex;
            eyeColorIndex[i] = avatarDatas[accounts[i]].eyeColorIndex;
            skinColorIndex[i] = avatarDatas[accounts[i]].skinColorIndex;
            defaultHatIndex[i] = avatarDatas[accounts[i]].defaultHatIndex;
            defaultShirtIndex[i] = avatarDatas[accounts[i]].defaultShirtIndex;
            defaultPantsIndex[i] = avatarDatas[accounts[i]].defaultPantsIndex;
            defaultShoesIndex[i] = avatarDatas[accounts[i]].defaultShoesIndex;
        }
    }


    /// @dev Sets data that is used to create the avatar for an account (msg.sender)
    /// @param gender {Male, Female}
    /// @param bodyWeight The avatar body weight in kilos
    /// @param bodyShape The avatar body shape, the higher the value the better the shape (muscles for male, roundings for female)
    /// @param hairStyleIndex Refers to hairstyles in the game client
    /// @param eyeColorIndex Refers to eye colors in the game client
    /// @param skinColorIndex Refers to skin colors in the game client
    /// @param defaultHatIndex Refers to a hat in the game client (0 signals no hat)
    /// @param defaultShirtIndex Refers to a shirt in the game client (0 signals no shirt)
    /// @param defaultPantsIndex Refers to a pants in the game client (0 signals no pants)
    /// @param defaultShoesIndex Refers to a shoes in the game client (0 signals no shoes)
    function setAvatarData(
        AvatarEnums.Gender gender,
        uint8 bodyWeight,
        uint8 bodyShape,
        uint8 hairStyleIndex,
        uint8 eyeColorIndex,
        uint8 skinColorIndex,
        uint8 defaultHatIndex,
        uint8 defaultShirtIndex,
        uint8 defaultPantsIndex,
        uint8 defaultShoesIndex) 
    public virtual override 
    {
        address account = _msgSender();
        require(
            ICryptopiaAccountRegister(accountRegisterContract).isRegistered(account), 
            "CryptopiaAvatarRegister: Not registered"
        );

        // Set avatar data
        AvatarData storage avatarData = avatarDatas[account];
        avatarData.gender = gender;
        avatarData.bodyWeight = bodyWeight;
        avatarData.bodyShape = bodyShape;
        avatarData.hairStyleIndex = hairStyleIndex;
        avatarData.eyeColorIndex = eyeColorIndex;
        avatarData.skinColorIndex = skinColorIndex;
        avatarData.defaultHatIndex = defaultHatIndex;
        avatarData.defaultShirtIndex = defaultShirtIndex;
        avatarData.defaultPantsIndex = defaultPantsIndex;
        avatarData.defaultShoesIndex = defaultShoesIndex;

        // Emit (assume change)
        emit ChangeAvatarData(account);
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../AvatarEnums.sol";

/// @title Cryptopia Avatar Register
/// @notice Register for avatar data
/// @author Frank Bonnet - <[email protected]>
interface ICryptopiaAvatarRegister {

    /// @dev Returns data that is used to create the avatar for `account`
    /// @param account The address of the (mulstisig) account to return the avatar data for
    /// @return gender {Male, Female}
    /// @return bodyWeight The avatar body weight in kilos
    /// @return bodyShape The avatar body shape, the higher the value the better the shape (muscles for male, roundings for female)
    /// @return hairStyleIndex Refers to hairstyles in the game client
    /// @return eyeColorIndex Refers to eye colors in the game client
    /// @return skinColorIndex Refers to skin colors in the game client
    /// @return defaultHatIndex Refers to a hat in the game client (0 signals no hat)
    /// @return defaultShirtIndex Refers to a shirt in the game client (0 signals no shirt)
    /// @return defaultPantsIndex Refers to a pants in the game client (0 signals no pants)
    /// @return defaultShoesIndex Refers to a shoes in the game client (0 signals no shoes)
    function getAvatarData(address account)
        external view 
        returns (
            AvatarEnums.Gender gender,
            uint8 bodyWeight,
            uint8 bodyShape,
            uint8 hairStyleIndex,
            uint8 eyeColorIndex,
            uint8 skinColorIndex,
            uint8 defaultHatIndex,
            uint8 defaultShirtIndex,
            uint8 defaultPantsIndex,
            uint8 defaultShoesIndex
        );


    /// @dev Returns data that is used to create the avatars for `accounts`
    /// @param accounts The addresses of the (mulstisig) accounts to return avatar data for
    /// @return gender {Male, Female}
    /// @return bodyWeight The avatar body weight in kilos
    /// @return bodyShape The avatar body shape, the higher the value the better the shape (muscles for male, roundings for female)
    /// @return hairStyleIndex Refers to hairstyles in the game client
    /// @return eyeColorIndex Refers to eye colors in the game client
    /// @return skinColorIndex Refers to skin colors in the game client
    /// @return defaultHatIndex Refers to a hat in the game client (0 signals no hat)
    /// @return defaultShirtIndex Refers to a shirt in the game client (0 signals no shirt)
    /// @return defaultPantsIndex Refers to a pants in the game client (0 signals no pants)
    /// @return defaultShoesIndex Refers to a shoes in the game client (0 signals no shoes)
    function getAvatarDatas(address[] memory accounts)
        external view 
        returns (
            AvatarEnums.Gender[] memory gender,
            uint8[] memory bodyWeight,
            uint8[] memory bodyShape,
            uint8[] memory hairStyleIndex,
            uint8[] memory eyeColorIndex,
            uint8[] memory skinColorIndex,
            uint8[] memory defaultHatIndex,
            uint8[] memory defaultShirtIndex,
            uint8[] memory defaultPantsIndex,
            uint8[] memory defaultShoesIndex
        );


    /// @dev Sets data that is used to create the avatar for an account (msg.sender)
    /// @param gender {Male, Female}
    /// @param bodyWeight The avatar body weight in kilos
    /// @param bodyShape The avatar body shape, the higher the value the better the shape (muscles for male, roundings for female)
    /// @param hairStyleIndex Refers to hairstyles in the game client
    /// @param eyeColorIndex Refers to eye colors in the game client
    /// @param skinColorIndex Refers to skin colors in the game client
    /// @param defaultHatIndex Refers to a hat in the game client (0 signals no hat)
    /// @param defaultShirtIndex Refers to a shirt in the game client (0 signals no shirt)
    /// @param defaultPantsIndex Refers to a pants in the game client (0 signals no pants)
    /// @param defaultShoesIndex Refers to a shoes in the game client (0 signals no shoes)
    function setAvatarData(
        AvatarEnums.Gender gender,
        uint8 bodyWeight,
        uint8 bodyShape,
        uint8 hairStyleIndex,
        uint8 eyeColorIndex,
        uint8 skinColorIndex,
        uint8 defaultHatIndex,
        uint8 defaultShirtIndex,
        uint8 defaultPantsIndex,
        uint8 defaultShoesIndex
    ) external;
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Avatar enums
/// @author Frank Bonnet - <[email protected]>
contract AvatarEnums {

    enum Gender 
    {
        Male,
        Female
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../AccountEnums.sol";

/// @title Cryptopia Account Register
/// @notice Creates and registers accounts
/// @author Frank Bonnet - <[email protected]>
interface ICryptopiaAccountRegister {

    /// @dev Allows verified creation of a Cryptopia account. Use of create2 allows identical addresses across networks
    /// @param owners List of initial owners
    /// @param required Number of required confirmations
    /// @param dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis
    /// @param username Unique username
    /// @param sex {Undefined, Male, Female}
    /// @return account Returns wallet address
    function create(address[] memory owners, uint required, uint dailyLimit, bytes32 username, AccountEnums.Sex sex) 
        external 
        returns (address payable account);


    /// @dev Check if an account was created and registered 
    /// @param account Account address.
    /// @return true if account is registered.
    function isRegistered(address account) 
        external view 
        returns (bool);


    /// @dev Retrieve account info 
    /// @param account The account to retrieve info for
    /// @return username Account username
    /// @return sex {Undefined, Male, Female}
    function getAccountData(address account) 
        external view 
        returns (
            bytes32 username,
            AccountEnums.Sex sex
        );


    /// @dev Retrieve account info for a range of addresses
    /// @param addresses contract adresses
    /// @return username Account usernames
    /// @return sex {Undefined, Male, Female}
    function getAccountDatas(address payable[] memory addresses) 
        external view 
        returns (
            bytes32[] memory username,
            AccountEnums.Sex[] memory sex
        );

    
    /// @dev Returns the amount of friends for `account`
    /// @param account The account to query 
    /// @return uint number of friends
    function getFriendCount(address account) 
        external view 
        returns (uint);


    /// @dev Returns the `friend_account` and `friend_username` of the friend at `index` for `account`
    /// @param account The account to retrieve the friend for (subject)
    /// @param index The index of the friend to retrieve
    /// @return friend_account The address of the friend
    /// @return friend_username The unique username of the friend
    /// @return friend_relationship The type of relationship `account` has with the friend
    function getFriendAt(address account, uint index) 
        external view 
        returns (
            address friend_account, 
            bytes32 friend_username,
            AccountEnums.Relationship friend_relationship
        );


    /// @dev Returns an array of friends for `account`
    /// @param account The account to retrieve the friends for (subject)
    /// @param skip Location where the cursor will start in the array
    /// @param take The amount of friends to return
    /// @return friend_accounts The addresses of the friends
    /// @return friend_usernames The unique usernames of the friends
    /// @return friend_relationships The type of relationship `account` has with the friends
    function getFriends(address account, uint skip, uint take) 
        external view 
        returns (
            address[] memory friend_accounts, 
            bytes32[] memory friend_usernames,
            AccountEnums.Relationship[] memory friend_relationships
        );


    /// @dev Returns true if `account` and `other` are friends
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @return bool True if `account` and `other` are friends
    function isFriend(address account, address other) 
        external view
        returns (bool);

    
    /// @dev Returns true if `account` and `other` have 'relationship'
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @param relationship The type of relationship to test
    /// @return bool True if `account` and `other` have 'relationship'
    function hasRelationsip(address account, address other, AccountEnums.Relationship relationship) 
        external view
        returns (bool);

    
    /// @dev Returns true if a pending friend request between `account` and `other` exists
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @return bool True if a pending friend request exists
    function hasPendingFriendRequest(address account, address other) 
        external view
        returns (bool);


    /// @dev Request friendship with `friend_account` for `msg.sender`
    /// @param friend_account The account to add the friend request for
    /// @param friend_relationship The type of relationship that is requested
    function addFriendRequest(address friend_account, AccountEnums.Relationship friend_relationship) 
        external;


    /// @dev Request friendship with `friend_accounts` for `msg.sender`
    /// @param friend_accounts The accounts to add the friend requests for
    /// @param friend_relationships The type of relationships that are requested
    function addFriendRequests(address[] memory friend_accounts, AccountEnums.Relationship[] memory friend_relationships) 
        external;


    /// @dev Removes the friend request with `friend_account` for `msg.sender`
    /// @param friend_account The account to remove the friend request for
    function removeFriendRequest(address friend_account) 
        external;


    /// @dev Removes the friend requests with `friend_accounts` for `msg.sender`
    /// @param friend_accounts The accounts to remove the friend requests for
    function removeFriendRequests(address[] memory friend_accounts) 
        external;

    
    /// @dev Accept friendship with `friend_account` for `msg.sender`
    /// @param friend_account The account to accept the friend request for
    function acceptFriendRequest(address friend_account) 
        external;


    /// @dev Accept friendships with `friend_accounts` for `msg.sender`
    /// @param friend_accounts The accounts to accept the friend requests for
    function acceptFriendRequests(address[] memory friend_accounts) 
        external;
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Account enums
/// @author Frank Bonnet - <[email protected]>
contract AccountEnums {

    enum Sex 
    {
        Undefined,
        Male,
        Female
    }

    enum Gender 
    {
        Male,
        Female
    }

    enum Relationship
    {
        None,
        Friend,
        Family,
        Spouse
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}