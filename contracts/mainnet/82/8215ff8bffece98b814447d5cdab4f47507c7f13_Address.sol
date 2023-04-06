/**
 *Submitted for verification at polygonscan.com on 2023-04-06
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Strings.sol

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
  bytes16 private constant _HEX_SYMBOLS = '0123456789abcdef';

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return '0';
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

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
   */
  function toHexString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return '0x00';
    }
    uint256 temp = value;
    uint256 length = 0;
    while (temp != 0) {
      length++;
      temp >>= 8;
    }
    return toHexString(value, length);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
   */
  function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = '0';
    buffer[1] = 'x';
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = _HEX_SYMBOLS[value & 0xf];
      value >>= 4;
    }
    require(value == 0, 'Strings: hex length insufficient');
    return string(buffer);
  }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
    assembly {
      size := extcodesize(account)
    }
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
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
    return functionCall(target, data, 'Address: low-level call failed');
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
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    require(isContract(target), 'Address: call to non-contract');

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return functionStaticCall(target, data, 'Address: low-level static call failed');
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
    require(isContract(target), 'Address: static call to non-contract');

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), 'Address: delegate call to non-contract');

    (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: @openzeppelin/contracts/utils/Context.sol
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

// File: @openzeppelin/contracts/access/Ownable.sol
pragma solidity ^0.8.0;

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
    _setOwner(_msgSender());
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
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
    _setOwner(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

pragma solidity ^0.8;

interface IERC20 {
  function transfer(address _to, uint256 _value) external returns (bool);

  function balanceOf(address account) external view returns (uint256);

  // don't need to define other functions, only using `transfer()` in this case
}

pragma solidity >=0.7.0 <0.9.0;

contract ColateralContract_v2_0_0 is Ownable {
  using Strings for uint256;

  address public LenderLiq = 0x799CD6A0625fF3542592875c6331c6B626109B3C;
  address public LiqVault = 0xf54788900ef8679d740279fc8aEdC24Ae80CD938;
  address public usdtTokenAddress;
  address public usdcTokenAddress;
  address public wbtcTokenAddress;
  address public wethTokenAddress;
  address public rescueWalletAccount;
  string public contractName;

  constructor(address _usdcTokenAddress, address _usdtTokenAddress, address _wbtcTokenAddress, address _wethTokenAddress) {
    usdcTokenAddress = _usdcTokenAddress;
    usdtTokenAddress = _usdtTokenAddress;
    wbtcTokenAddress = _wbtcTokenAddress;
    wethTokenAddress = _wethTokenAddress;
    // Mumbai addresses
    // usdcTokenAddress = 0xe11A86849d99F524cAC3E7A0Ec1241828e332C62;
    // usdtTokenAddress = 0xA02f6adc7926efeBBd59Fd43A84f4E0c0c91e832;
    // wbtcTokenAddress = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889; // WMATIC 
    // wethTokenAddress = 0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa;
  }

  function setRescueWalletAccount(address _rescueWalletAccount) public {
          string memory errorMessage;
          if (msg.sender == LiqVault) {
            rescueWalletAccount = _rescueWalletAccount;
          }
          else {
          revert(errorMessage);
          }
  }

  function setUSDCTokenAddress(address _usdcTokenAddress) public onlyOwner {
    usdcTokenAddress = _usdcTokenAddress;
  }

  function setUSDTTokenAddress(address _usdtTokenAddress) public onlyOwner {
    usdtTokenAddress = _usdtTokenAddress;
  }

  function setWBTCTokenAddress(address _wbtcTokenAddress) public onlyOwner {
    wbtcTokenAddress = _wbtcTokenAddress;
  }

  function setWETHTokenAddress(address _wethTokenAddress) public onlyOwner {
    wethTokenAddress = _wethTokenAddress;
  }

  function withdrawBalance() public payable onlyOwner {
    // This will payout the owner 100% of the contract balance.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function withdraw(uint256 _amount) public payable onlyOwner {
    // This will payout the amount of the contract balance.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: _amount}('');
    require(os);
    // =============================================================================
  }

  function withdrawUSDT(uint256 _amount) public onlyOwner {
    IERC20 usdt = IERC20(address(usdtTokenAddress));

    // transfers USDT that belong to your contract to the contract owner address
    usdt.transfer(address(owner()), _amount);
  }

  function withdrawUSDC(uint256 _amount) public onlyOwner {
    IERC20 usdc = IERC20(address(usdcTokenAddress));

    // transfers USDC that belong to your contract to the contract owner address
    usdc.transfer(address(owner()), _amount);
  }

  function withdrawWBTC(uint256 _amount) public onlyOwner {
    IERC20 wbtc = IERC20(address(wbtcTokenAddress));

    // transfers WBTC that belong to your contract to the contract owner address
    wbtc.transfer(address(owner()), _amount);
  }

  function withdrawWETH(uint256 _amount) public onlyOwner {
    IERC20 weth = IERC20(address(wethTokenAddress));

    // transfers WETH that belong to your contract to the contract owner address
    weth.transfer(address(owner()), _amount);
  }

  function balanceOfUSDC() public view virtual returns (uint256) {
    IERC20 usdc = IERC20(address(usdcTokenAddress));

    // returns balance of USDC token in contract.
    return usdc.balanceOf(address(this));
  }

  function balanceOfUSDT() public view virtual returns (uint256) {
    IERC20 usdt = IERC20(address(usdtTokenAddress));

    // returns balance of USDT token in contract.
    return usdt.balanceOf(address(this));
  }

  function balanceOfWBTC() public view virtual returns (uint256) {
    IERC20 wbtc = IERC20(address(wbtcTokenAddress));

    // returns balance of WBTC token in contract.
    return wbtc.balanceOf(address(this));
  }

  function balanceOfWETH() public view virtual returns (uint256) {
    IERC20 weth = IERC20(address(wethTokenAddress));

    // returns balance of WETH token in contract.
    return weth.balanceOf(address(this));
  }

  function rescueBalance() public payable onlyOwner {
    require(rescueWalletAccount != address(0), 'Rescue wallet is the zero address');

    (bool os, ) = payable(rescueWalletAccount).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function rescue(uint256 _amount) public payable onlyOwner {
    require(rescueWalletAccount != address(0), 'Rescue wallet is the zero address');

    (bool os, ) = payable(rescueWalletAccount).call{value: _amount}('');
    require(os);
    // =============================================================================
  }

  function rescueUSDT(uint256 _amount) public onlyOwner {
    require(rescueWalletAccount != address(0), 'Rescue wallet is the zero address');

    IERC20 usdt = IERC20(address(usdtTokenAddress));

    // transfers USDT that belong to your contract to the rescueWalletAccount address
    usdt.transfer(address(rescueWalletAccount), _amount);
  }

  function rescueUSDC(uint256 _amount) public onlyOwner {
    require(rescueWalletAccount != address(0), 'Rescue wallet is the zero address');

    IERC20 usdc = IERC20(address(usdcTokenAddress));

    // transfers USDC that belong to your contract to the rescueWalletAccount address
    usdc.transfer(address(rescueWalletAccount), _amount);
  }

  function rescueWBTC(uint256 _amount) public onlyOwner {
    require(rescueWalletAccount != address(0), 'Rescue wallet is the zero address');

    IERC20 wbtc = IERC20(address(wbtcTokenAddress));

    // transfers WBTC that belong to your contract to the rescueWalletAccount address
    wbtc.transfer(address(rescueWalletAccount), _amount);
  }

  function rescueWETH(uint256 _amount) public onlyOwner {
    require(rescueWalletAccount != address(0), 'Rescue wallet is the zero address');

    IERC20 weth = IERC20(address(wethTokenAddress));

    // transfers WETH that belong to your contract to the rescueWalletAccount address
    weth.transfer(address(rescueWalletAccount), _amount);
  }

  struct CustomBalance {
    string token;
    uint256 balance;
  }

  function getBalances() public view virtual returns (uint256[5] memory) {
    uint256 localBalance = address(this).balance;
    uint256 usdcBalance = balanceOfUSDC();
    uint256 usdtBalance = balanceOfUSDT();
    uint256 wbtcBalance = balanceOfWBTC();
    uint256 wethBalance = balanceOfWETH();

    // return balances;
    uint256[5] memory balances = [localBalance, usdcBalance, usdtBalance, wbtcBalance, wethBalance];

    return balances;
  }
}