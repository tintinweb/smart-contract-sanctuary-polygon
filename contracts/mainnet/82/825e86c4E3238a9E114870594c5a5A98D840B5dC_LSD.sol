// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

import "./abstracts/BaseContract.sol";
import "./interfaces/INFTPass.sol";
import "./interfaces/IMENToken.sol";
import "./libs/app/ArrayUtil.sol";

contract LSD is BaseContract {
  using ArrayUtil for uint[];
  struct Config {
    uint secondsInADay;
    uint minAmountForTaxDiscount;
    uint systemLastBurnt;
    uint systemTodayBurnt;
    uint systemBurnHardCap;
  }
  struct User {
    uint[] burnableAt;
    uint[] burnableAmount;
    uint qualifyForDiscountUntil;
  }
  Config public config;
  mapping (address => User) public users;
  IMENToken public menToken;
  IMENToken public stToken;
  mapping (address => bool) private ignoreTransfer;
  address public shareManager;

  event ConfigUpdated(uint secondsInADay, uint minAmountForTaxDiscount, uint systemBurnHardCap, uint timestamp);
  event STBurnt(address indexed trigger, uint amount, uint timestamp);
  event STMinted(address indexed miner, uint amount, uint expiredAt, uint timestamp, uint duration);
  event STLocked(address indexed sender, address indexed locker, uint amount, uint expiredAt, uint timestamp);

  modifier onlyMENToken() {
    require(msg.sender == address(menToken), "LSD: onlyMENToken");
    _;
  }

  modifier onlyStToken() {
    require(msg.sender == address(stToken), "LSD: onlyStToken");
    _;
  }

  function initialize() public initializer {
    BaseContract.init();
    config.minAmountForTaxDiscount = 10_000 ether;
    config.secondsInADay = 86_400;
  }

  function mint(uint _tokenAmount, uint _duration) external {
    require(_duration >= 30, "LSD: duration must be >= 30");
    _takeToken(menToken, _tokenAmount);
    uint expiredAt = block.timestamp + _duration * config.secondsInADay + config.secondsInADay;
    if (_duration >= 60 && _tokenAmount >= config.minAmountForTaxDiscount) {
      users[msg.sender].qualifyForDiscountUntil = expiredAt;
    }
    users[msg.sender].burnableAt.push(expiredAt);
    users[msg.sender].burnableAmount.push(_tokenAmount);
    stToken.mint(_tokenAmount);
    stToken.transfer(msg.sender, _tokenAmount);
    emit STMinted(msg.sender, _tokenAmount, expiredAt, block.timestamp, _duration);
  }

  function burn(uint _stAmount) external {
    User storage user = users[msg.sender];
    require(user.burnableAt.length > 0, "LSD: please lock token first");
    _validateSystemCap(_stAmount);
    _takeToken(stToken, _stAmount);
    uint totalBurnt;
    uint i;

    while (user.burnableAt.length > 0 && i < user.burnableAt.length) {
      if (user.burnableAt[i] == user.qualifyForDiscountUntil &&
        user.burnableAmount[i] - _stAmount < config.minAmountForTaxDiscount
      ) {
        user.qualifyForDiscountUntil = 0;
      }
      if (user.burnableAt[i] <= block.timestamp) {
        if (totalBurnt + user.burnableAmount[i] <= _stAmount) {
          totalBurnt += user.burnableAmount[i];
          user.burnableAt.removeElementFromArrayByIndex(i);
          user.burnableAmount.removeElementFromArrayByIndex(i);
          i = i > 0 ? i-- : 0;
        } else {
          user.burnableAmount[i] -= (_stAmount - totalBurnt);
          totalBurnt = _stAmount;
          break;
        }
      } else {
        i++;
      }
    }

    require(totalBurnt == _stAmount, "LSD: insufficient stAmount");

    stToken.burn(totalBurnt);
    menToken.transfer(msg.sender, totalBurnt);
    emit STBurnt(msg.sender, totalBurnt, block.timestamp);
  }

  function transfer(address _from, address _to, uint _stAmount) external onlyStToken {
    uint totalTransferred;
    if (!ignoreTransfer[_from] && _to != address(this) && _to != shareManager) {
      User storage fromUser = users[_from];
      while (totalTransferred < _stAmount) {
        if (fromUser.burnableAt[0] == fromUser.qualifyForDiscountUntil) {
          if (
            fromUser.burnableAmount[0] < _stAmount ||
            fromUser.burnableAmount[0] - _stAmount < config.minAmountForTaxDiscount
          ) {
            fromUser.qualifyForDiscountUntil = 0;
          }
        }
        if (totalTransferred + fromUser.burnableAmount[0] <= _stAmount) {
          totalTransferred += fromUser.burnableAmount[0];
          fromUser.burnableAt.removeElementFromArrayByIndex(0);
          fromUser.burnableAmount.removeElementFromArrayByIndex(0);
        } else {
          fromUser.burnableAmount[0] -= (_stAmount - totalTransferred);
          totalTransferred = _stAmount;
          break;
        }
      }
    }
    if (!ignoreTransfer[_to] && _from != address(0) && _from != address(this) && _from != shareManager) {
      User storage toUser = users[_to];
      uint expiredAt = block.timestamp + 30 * config.secondsInADay;
      toUser.burnableAt.push(expiredAt);
      uint burnableAmount = totalTransferred > 0 ? totalTransferred : _stAmount;
      emit STLocked(_from, _to, burnableAmount, expiredAt, block.timestamp);
      toUser.burnableAmount.push(burnableAmount);
    }
  }

  function isQualifiedForTaxDiscount(address _user) external view returns (bool) {
    return users[_user].qualifyForDiscountUntil >= block.timestamp;
  }

  function getUserInfo(address _user) external view returns (uint[] memory, uint[] memory, uint, uint) {
    User storage user = users[_user];
    uint burnable;
    uint i;
    while (true) {
      if (user.burnableAt.length == 0) break;

      if (i > (user.burnableAt.length - 1)) {
        break;
      }
      burnable += user.burnableAt[i] <= block.timestamp ? user.burnableAmount[i] : 0;
      i++;
    }
    return (
      user.burnableAt,
      user.burnableAmount,
      user.qualifyForDiscountUntil,
      burnable
    );
  }

  function getUserBurnableUntil(address _user, uint _to) external view returns (uint) {
    User storage user = users[_user];
    uint burnable;
    uint i;

    if (user.burnableAt.length == 0) {
      return 0;
    }

    while (true) {
      if (i > (user.burnableAt.length - 1) || user.burnableAt[i] > _to) {
        break;
      }
      if (user.burnableAt[i] > block.timestamp) {
        burnable += user.burnableAmount[i];
      }
      i++;
    }
    return burnable;
  }

  function getSystemTodayBurnt() external view returns (uint) {
    if (config.systemLastBurnt < _getStartOfDayTimestamp()) {
      return 0;
    }

    return config.systemTodayBurnt;
  }

  // PRIVATE FUNCTIONS

  function _validateSystemCap(uint _stAmount) private {
    if (config.systemLastBurnt < _getStartOfDayTimestamp()) {
      config.systemTodayBurnt = 0;
    }
    require(config.systemTodayBurnt + _stAmount <= config.systemBurnHardCap, "LSD: system hard cap reached");
    config.systemTodayBurnt += _stAmount;
    config.systemLastBurnt = block.timestamp;
  }

  function _getStartOfDayTimestamp() private view returns (uint) {
    return block.timestamp - block.timestamp % config.secondsInADay;
  }

  function _takeToken(IMENToken _token, uint _amount) private {
    require(_token.allowance(msg.sender, address(this)) >= _amount, "LSD: allowance invalid");
    require(_token.balanceOf(msg.sender) >= _amount, "LSD: insufficient balance");
    _token.transferFrom(msg.sender, address(this), _amount);
  }

  function _initDependentContracts() override internal {
    menToken = IMENToken(addressBook.get("menToken"));
    stToken = IMENToken(addressBook.get("stToken"));
    ignoreTransfer[address(0)] = true;
    ignoreTransfer[address(this)] = true;
    ignoreTransfer[addressBook.get("lpToken")] = true;
    shareManager = addressBook.get("shareManager");
    ignoreTransfer[shareManager] = true;
  }

  // AUTH FUNCTIONS

  function updateConfig(uint _secondsInADay, uint _minAmountForTaxDiscount, uint _systemBurnHardCap) external onlyMn {
    config.secondsInADay = _secondsInADay;
    config.minAmountForTaxDiscount = _minAmountForTaxDiscount;
    config.systemBurnHardCap = _systemBurnHardCap;
    emit ConfigUpdated(_secondsInADay, _minAmountForTaxDiscount, _systemBurnHardCap, block.timestamp);
  }
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.9;

import "../libs/app/Auth.sol";
import "../interfaces/IAddressBook.sol";

abstract contract BaseContract is Auth {

  function init() virtual public {
    Auth.init(msg.sender);
  }
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface INFTPass is IERC721Upgradeable {
  function mint(address _owner, uint _quantity) external;
  function getOwnerNFTs(address _owner) external view returns(uint[] memory);
  function waitingList(address _user) external view returns (bool);
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

import "../libs/zeppelin/token/BEP20/IBEP20.sol";

interface IMENToken is IBEP20 {
  function releaseMintingAllocation(uint _amount) external returns (bool);
  function releaseCLSAllocation(uint _amount) external returns (bool);
  function burn(uint _amount) external;
  function mint(uint _amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library ArrayUtil {
  function removeElementFromArray(uint[] storage _array, uint _element) internal returns (uint[] memory) {
    uint index = _getElementIndex(_array, _element);
    if (index >= 0 && index < _array.length) {
      _array[index] = _array[_array.length - 1];
      _array.pop();
    }
    return _array;
  }

  function removeElementFromArrayByIndex(uint[] storage _array, uint _index) internal returns (uint[] memory) {
    if (_index >= 0 && _index < _array.length) {
      for (uint i = _index; i < _array.length - 1; i++) {
        _array[i] = _array[i + 1];
      }
      _array.pop();
    }
    return _array;
  }

  function _getElementIndex(uint[] memory _array, uint _element) private pure returns (uint) {
    for(uint i = 0; i < _array.length; i++) {
      if (_array[i] == _element) return i;
    }
    return type(uint).max;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../interfaces/IAddressBook.sol";

abstract contract Auth is Initializable {

  address public bk;
  address public mn;
  address public contractCall;
  IAddressBook public addressBook;

  event ContractCallUpdated(address indexed _newOwner);

  function init(address _mn) virtual public {
    mn = _mn;
    contractCall = _mn;
  }

  modifier onlyBk() {
    require(_isBk(), "onlyBk");
    _;
  }

  modifier onlyMn() {
    require(_isMn(), "Mn");
    _;
  }

  modifier onlyContractCall() {
    require(_isContractCall() || _isMn(), "onlyContractCall");
    _;
  }

  function updateContractCall(address _newValue) external onlyMn {
    require(_newValue != address(0x0));
    contractCall = _newValue;
    emit ContractCallUpdated(_newValue);
  }

  function setAddressBook(address _addressBook) external onlyMn {
    addressBook = IAddressBook(_addressBook);
    _initDependentContracts();
  }

  function reloadAddresses() external onlyMn {
    _initDependentContracts();
  }

  function updateBk(address _newBk) external onlyBk {
    require(_newBk != address(0), "TokenAuth: invalid new bk");
    bk = _newBk;
  }

  function reload() external onlyBk {
    mn = addressBook.get("mn");
    contractCall = addressBook.get("contractCall");
  }

  function _initDependentContracts() virtual internal;

  function _isBk() internal view returns (bool) {
    return msg.sender == bk;
  }

  function _isMn() internal view returns (bool) {
    return msg.sender == mn;
  }

  function _isContractCall() internal view returns (bool) {
    return msg.sender == contractCall;
  }
}

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity 0.8.9;

interface IAddressBook {
  function get(string calldata _name) external view returns (address);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
interface IERC165Upgradeable {
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

pragma solidity 0.8.9;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IBEP20 {

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}