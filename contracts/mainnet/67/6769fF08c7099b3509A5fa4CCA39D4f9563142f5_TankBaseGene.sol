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
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Fortress Arena Tank NFT contract
 * @author Atomrigs Lab
 *     ______           __                         ___
 *    / ____/___  _____/ /_________  __________   /   |  ________  ____  ____ _
 *   / /_  / __ \/ ___/ __/ ___/ _ \/ ___/ ___/  / /| | / ___/ _ \/ __ \/ __ `/
 *  / __/ / /_/ / /  / /_/ /  /  __(__  |__  )  / ___ |/ /  /  __/ / / / /_/ /
 * /_/    \____/_/   \__/_/   \___/____/____/  /_/  |_/_/   \___/_/ /_/\__,_/
 *
 **/

contract TankBaseGene is OwnableUpgradeable {
    uint private constant CHAIN_BASE = 20_000_000;

    address public _tankNft;

    string[] private races;

    string[] private colors;

    string[] private materials;

    string[] private classes;

    string[] private elements;

    string[] private generations;

    string[] private founderTanks;

    modifier onlyNftOrOwner() {
        require(
            _msgSender() == _tankNft || _msgSender() == owner(),
            "TankGene: caller is not the NFT tank contract address"
        );
        _;
    }

    function initGene() private {
        races = [
            "carrot", //0
            "cannon", //1
            "poseidon", //2
            "crossbow", //3
            "catapult", //4
            "ionattacker", //5
            "multi", //6
            "missile", //7
            "minelander", //8
            "secwind", //9
            "laser", //10
            "duke", //11
            "ironhammer", //12
            "walkietalkie", //13
            "rainbowshell", //14
            "windblow", //15
            "dragoncannon", //16
            "solartank", //17
            "blazer", //18
            "overcharger" //19
        ];

        colors = [
            "blue", //0
            "red", //1
            "green", //2
            "brown", //3
            "yellow", //4
            "purple" //5
        ];

        materials = [
            "steel", //0
            "wood", //1
            "radios" //2
        ];

        classes = [
            "normal", //0
            "superior", //1
            "rare", //2
            "epic", //3
            "legendary" //4
        ];

        elements = [
            "fire", //0
            "wind", //1
            "earth", //2
            "water", //3
            "light", //4
            "dark" //5
        ];

        generations = ["generation-0", "generation-N"];

        founderTanks = ["founder-tank", "regular-tank"];
    }

    function initialize(address _tankNftAddr) public initializer {
        __Ownable_init();
        _tankNft = _tankNftAddr;
        initGene();
    }

    function tankNft() external view returns (address) {
        return _tankNft;
    }

    function setTankNft(address _nftAddr) external onlyOwner {
        _tankNft = _nftAddr;
    }

    function getOldSeed(
        uint _tokenId
    ) public view onlyNftOrOwner returns (uint) {
        return uint256(keccak256(abi.encodePacked(_tokenId, uint(2021))));
    }

    function getSeed(
        uint _tokenId,
        uint _entropy
    ) public view onlyNftOrOwner returns (uint) {
        if (_entropy != uint(0)) {
            return uint256(keccak256(abi.encodePacked(_tokenId, _entropy)));
        } else {
            return uint(0);
        }
    }

    function getBaseGenes(
        uint _tokenId,
        uint _entropy
    ) public view onlyNftOrOwner returns (uint[] memory) {
        uint[] memory genes = new uint[](7);
        uint seed = getSeed(_tokenId, _entropy);
        if (seed == uint(0)) {
            return genes;
        }

        genes[0] = getRaceIdx(seed);
        genes[1] = getColorIdx(seed);
        genes[2] = getMaterialIdx(seed);
        genes[3] = getClassIdx(seed);
        genes[4] = getElementIdx(seed);
        genes[5] = getGeneration();
        genes[6] = getFounderTank();

        if (_tokenId >= CHAIN_BASE + 121 && _tokenId <= CHAIN_BASE + 3720) {
            uint oldSeed = getOldSeed(_tokenId - CHAIN_BASE);
            uint oldClassIdx = getClassIdx(oldSeed);
            if (oldClassIdx >= 3) {
                genes[3] = oldClassIdx;
            }
        }
        return genes;
    }

    function getBaseGeneNames(
        uint _tokenId,
        uint _entropy
    ) public view onlyNftOrOwner returns (string[] memory) {
        uint[] memory genes = getBaseGenes(_tokenId, _entropy);
        string[] memory geneNames = new string[](7);
        geneNames[0] = races[genes[0]];
        geneNames[1] = colors[genes[1]];
        geneNames[2] = materials[genes[2]];
        geneNames[3] = classes[genes[3]];
        geneNames[4] = elements[genes[4]];
        geneNames[5] = generations[genes[5]];
        geneNames[6] = founderTanks[genes[6]];
        return geneNames;
    }

    function getImgIdx(
        uint _tokenId,
        uint _entropy
    ) public view onlyNftOrOwner returns (string memory) {
        uint[] memory genes = getBaseGenes(_tokenId, _entropy);
        string memory race = toString(genes[0] + uint(101));
        string memory color;
        if (genes[1] <= 8) {
            color = string(abi.encodePacked("0", toString(genes[1] + uint(1))));
        } else {
            color = toString(genes[1] + uint(1));
        }
        string memory material = toString(genes[2] + uint(1));
        string memory class = toString(genes[3] + uint(1));
        string memory element = toString(genes[4] + uint(1));
        return string(abi.encodePacked(race, color, material, class, element));
    }

    function getRaceIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed / 10) % 100;
        if (v < 10) {
            return uint(0);
        } else if (v < 19) {
            return uint(1);
        } else if (v < 28) {
            return uint(2);
        } else if (v < 36) {
            return uint(3);
        } else if (v < 43) {
            return uint(4);
        } else if (v < 49) {
            return uint(5);
        } else if (v < 54) {
            return uint(6);
        } else if (v < 59) {
            return uint(7);
        } else if (v < 64) {
            return uint(8);
        } else if (v < 69) {
            return uint(9);
        } else if (v < 73) {
            return uint(10);
        } else if (v < 77) {
            return uint(11);
        } else if (v < 81) {
            return uint(12);
        } else if (v < 85) {
            return uint(13);
        } else if (v < 88) {
            return uint(14);
        } else if (v < 91) {
            return uint(15);
        } else if (v < 94) {
            return uint(16);
        } else if (v < 96) {
            return uint(17);
        } else if (v < 98) {
            return uint(18);
        } else {
            return uint(19);
        }
    }

    function getColorIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed / 1000) % 100;
        if (v < 30) {
            return uint(0);
        } else if (v < 50) {
            return uint(1);
        } else if (v < 70) {
            return uint(2);
        } else if (v < 85) {
            return uint(3);
        } else if (v < 95) {
            return uint(4);
        } else {
            return uint(5);
        }
    }

    function getMaterialIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed / 100000) % 100;
        if (v < 50) {
            return uint(0);
        } else if (v < 80) {
            return uint(1);
        } else {
            return uint(2);
        }
    }

    function getClassIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed / 10000000) % 100;
        if (v < 40) {
            return uint(0);
        } else if (v < 70) {
            return uint(1);
        } else if (v < 90) {
            return uint(2);
        } else if (v < 98) {
            return uint(3);
        } else {
            return uint(4);
        }
    }

    function getElementIdx(uint _seed) private pure returns (uint) {
        uint v = (_seed / 1000000000) % 100;
        if (v < 20) {
            return uint(0);
        } else if (v < 40) {
            return uint(1);
        } else if (v < 60) {
            return uint(2);
        } else if (v < 80) {
            return uint(3);
        } else if (v < 94) {
            return uint(4);
        } else {
            return uint(5);
        }
    }

    function getGeneration() private pure returns (uint) {
        return uint(0); //this contract owns all genration 0 tanks only
    }

    function getFounderTank() private pure returns (uint) {
        return uint(1);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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
}