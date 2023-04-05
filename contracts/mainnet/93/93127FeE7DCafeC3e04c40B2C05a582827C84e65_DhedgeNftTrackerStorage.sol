// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IHasGuardInfo {
  // Get guard
  function getContractGuard(address extContract) external view returns (address);

  // Get asset guard
  function getAssetGuard(address extContract) external view returns (address);

  // Get mapped addresses from Governance
  function getAddress(bytes32 name) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../../interfaces/IHasGuardInfo.sol";

contract DhedgeNftTrackerStorage is OwnableUpgradeable {
  address public poolFactory; // dhedge pool factory
  mapping(bytes32 => mapping(address => bytes[])) internal _nftTrackData; // keccak of NFT_TYPE -> poolAddress -> data[]

  // solhint-disable-next-line no-empty-blocks
  function initialize(address _poolFactory) external initializer {
    __Ownable_init();
    poolFactory = _poolFactory;
  }

  /// @notice implementations should not be left unintialized
  // solhint-disable-next-line no-empty-blocks
  function implInitializer() external initializer {}

  modifier checkContractGuard(address _guardedContract) {
    require(IHasGuardInfo(poolFactory).getContractGuard(_guardedContract) == msg.sender, "not correct contract guard");

    _;
  }

  /**
   * @notice record new NFT data
   * @dev only called by authorized guard
   * @param _guardedContract the address of contract using nftStorage
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @param _data the nft track data to be recorded in storage
   */
  function addData(
    address _guardedContract,
    bytes32 _nftType,
    address _pool,
    bytes memory _data
  ) external checkContractGuard(_guardedContract) {
    _addData(_nftType, _pool, _data);
  }

  /**
   * @notice record new NFT data
   * @dev only called by authorized guard
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @param _data the nft track data to be recorded in storage
   */
  function _addData(
    bytes32 _nftType,
    address _pool,
    bytes memory _data
  ) private {
    _nftTrackData[_nftType][_pool].push(_data);
  }

  /**
   * @notice delete NFT data
   * @dev only called by authorized guard
   * @param _guardedContract the address of contract using nftStorage
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @param _index the nft track data index to be removed from storage
   */
  function removeData(
    address _guardedContract,
    bytes32 _nftType,
    address _pool,
    uint256 _index
  ) external checkContractGuard(_guardedContract) {
    _removeData(_nftType, _pool, _index);
  }

  /**
   * @notice delete NFT data
   * @dev only called by authorized guard
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @param _index the nft track data index to be removed from storage
   */
  function _removeData(
    bytes32 _nftType,
    address _pool,
    uint256 _index
  ) private {
    uint256 length = _nftTrackData[_nftType][_pool].length;
    require(_index < length, "invalid index");

    _nftTrackData[_nftType][_pool][_index] = _nftTrackData[_nftType][_pool][length - 1];
    _nftTrackData[_nftType][_pool].pop();
  }

  /**
   * @notice returns tracked nft by index
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @param _index the index of nft track data
   * @return data the nft track data of given NFT_TYPE & poolLogic & index
   */
  function getData(
    bytes32 _nftType,
    address _pool,
    uint256 _index
  ) external view returns (bytes memory) {
    return _nftTrackData[_nftType][_pool][_index];
  }

  /**
   * @notice returns all tracked nfts by NFT_TYPE & poolLogic
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @return data all tracked nfts of given NFT_TYPE & poolLogic
   */
  function getAllData(bytes32 _nftType, address _pool) public view returns (bytes[] memory) {
    return _nftTrackData[_nftType][_pool];
  }

  /**
   * @notice returns all tracked nfts by NFT_TYPE & poolLogic
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @return count all tracked nfts count of given NFT_TYPE & poolLogic
   */
  function getDataCount(bytes32 _nftType, address _pool) public view returns (uint256) {
    return _nftTrackData[_nftType][_pool].length;
  }

  /**
   * @notice returns all tracked nft ids by NFT_TYPE & poolLogic if stored as uint256
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @return tokenIds all tracked nfts of given NFT_TYPE & poolLogic
   */
  function getAllUintIds(bytes32 _nftType, address _pool) public view returns (uint256[] memory tokenIds) {
    bytes[] memory data = getAllData(_nftType, _pool);
    tokenIds = new uint256[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      tokenIds[i] = abi.decode(data[i], (uint256));
    }
  }

  /**
   * @notice record new NFT uint256 id
   * @dev only called by authorized guard
   * @param _guardedContract the address of contract using nftStorage
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @param _nftID the nft id recorded in storage
   */
  function addUintId(
    address _guardedContract,
    bytes32 _nftType,
    address _pool,
    uint256 _nftID,
    uint256 _maxPositions
  ) external checkContractGuard(_guardedContract) {
    _addData(_nftType, _pool, abi.encode(_nftID));
    require(getDataCount(_nftType, _pool) <= _maxPositions, "max position reached");
  }

  /**
   * @notice record new NFT uint256 id
   * @dev only called by authorized guard
   * @param _guardedContract the address of contract using nftStorage
   * @param _nftType keccak of NFT_TYPE
   * @param _pool the poolLogic address
   * @param _nftID the nft id recorded in storage
   */
  function removeUintId(
    address _guardedContract,
    bytes32 _nftType,
    address _pool,
    uint256 _nftID
  ) external checkContractGuard(_guardedContract) {
    bytes[] memory data = getAllData(_nftType, _pool);
    for (uint256 i = 0; i < data.length; i++) {
      if (abi.decode(data[i], (uint256)) == _nftID) {
        _removeData(_nftType, _pool, i);
        return;
      }
    }

    revert("not found");
  }

  function removeDataByUintId(
    bytes32 _nftType,
    address _pool,
    uint256 _nftID
  ) external onlyOwner {
    bytes[] memory data = getAllData(_nftType, _pool);
    for (uint256 i = 0; i < data.length; i++) {
      if (abi.decode(data[i], (uint256)) == _nftID) {
        _removeData(_nftType, _pool, i);
        return;
      }
    }
    revert("not found");
  }

  function removeDataByIndex(
    bytes32 _nftType,
    address _pool,
    uint256 _index
  ) external onlyOwner {
    _removeData(_nftType, _pool, _index);
  }

  function addDataByUintId(
    bytes32 _nftType,
    address _pool,
    uint256 _nftID
  ) external onlyOwner {
    _addData(_nftType, _pool, abi.encode(_nftID));
  }
}