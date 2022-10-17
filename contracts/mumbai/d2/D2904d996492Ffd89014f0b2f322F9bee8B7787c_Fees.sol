// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { IFees } from "./IFees.sol";
import { Address } from "../library/Address.sol";
import { Governable } from "../Governance/Governable.sol";
import { Pausable } from "../Control/Pausable.sol";

contract Fees is IFees, Governable, Pausable {
  using Address for address payable;

  constructor(
    uint256 feeAmountBase_,
    address payable treasuryFeeAddress_,
    address payable stakingFeeAddress_
  ) Governable(_msgSender(), _msgSender()) {
    _feeAmountBase = feeAmountBase_;
    _treasuryFeeAddress = treasuryFeeAddress_;
    _stakingFeeAddress = stakingFeeAddress_;
    _exemptFromFees[_msgSender()] = true;

    // !!! setup some fee type presets

    // note this covers all staking contracts.
    _feeTypeAmountMap["DeployStaking"] = 300;
    _feeTypeAmountMap["DeployToken"] = 200;
    _feeTypeAmountMap["CreateTokenLock"] = 200;
    _feeTypeAmountMap["CreateInfiniteLock"] = 100;
    _feeTypeAmountMap["SplitLock"] = 100;
    _feeTypeAmountMap["MigrateLock"] = 100;
  }

  address payable internal _treasuryFeeAddress;
  address payable internal _stakingFeeAddress;

  /** 0-10000 - 2 decimals of precision. all fees should add up to 10000 (100%) */
  // send all to treasury by default, since staking will be implemented later
  uint16 internal _treasuryFee = 10000;
  uint16 internal _stakingFee = 0;

  uint256 internal _treasuryFeesDistributed;
  uint256 internal _stakingFeesDistributed;

  uint256 internal _feeAmountBase;

  mapping(address => bool) internal _exemptFromFees;
  mapping(string => uint256) internal _feeTypeAmountMap;

  function feeAmountBase() external virtual override view returns (uint256) {
    return _feeAmountBase;
  }

  function setFeeAmountBase(uint256 value) external virtual override onlyGovernor {
    _feeAmountBase = value;
  }

  /**
   * @return 0 if the msg sender is exempt from fees.
   */
  function getFeeAmountForType(string calldata feeType) external virtual override view returns (uint256) {
    return _exemptFromFees[_msgSender()] ? 0 : _feeAmountBase * _feeTypeAmountMap[feeType];
  }

  function setFeeAmountForType(string calldata feeType, uint256 amount) external virtual override onlyGovernor {
    _feeTypeAmountMap[feeType] = amount;
  }

  function setAddressExemptFromFees(address account, bool value) external virtual override onlyOwner {
    _exemptFromFees[account] = value;
  }

  function isAddressExemptFromFees(address account) external virtual override view returns (bool) {
    return _exemptFromFees[account];
  }

  function feesDistributed() external virtual override view returns (uint256 total, uint256 treasury, uint256 staking) {
    treasury = _treasuryFeesDistributed;
    staking = _stakingFeesDistributed;
    total = _treasuryFeesDistributed + _stakingFeesDistributed;
  }

  function treasuryFeeAddress() external virtual override view returns (address) {
    return _treasuryFeeAddress;
  }

  function setTreasuryFeeAddress(address payable value) external virtual override onlyOwner {
    _treasuryFeeAddress = value;
  }

  function stakingFeeAddress() external virtual override view returns (address) {
    return _stakingFeeAddress;
  }

  function setStakingFeeAddress(address payable value) external virtual override onlyOwner {
    _stakingFeeAddress = value;
  }

  function getFees() external virtual override view returns (uint16 treasury, uint16 staking) {
    treasury = _treasuryFee;
    staking = _stakingFee;
  }

  /** 0-10000 - 2 decimals of precision. all fees should add up to 10000 (100.00%) */
  function setFees(uint16 treasury, uint16 staking) external virtual override onlyGovernor {
    require(treasury + staking == 10000, "Total fees must equal 10000");

    _treasuryFee = treasury;
    _stakingFee = staking;
  }

  function _distributeFees(uint256 amount) internal virtual {
    require(amount != 0, "Cannot distribute 0");

    // explicitly check for 0% fee to avoid any chance of
    // precision errors when one of the fees is disabled.
    uint256 treasuryAmount = _treasuryFee == 0 ? 0 : (amount * _treasuryFee / 10000);
    uint256 stakingAmount = _stakingFee == 0 ? 0 : (amount - treasuryAmount);

    if (treasuryAmount != 0) {
      _treasuryFeesDistributed += treasuryAmount;
      _treasuryFeeAddress.sendValue(treasuryAmount);
    }
    
    if (stakingAmount != 0) {
      _stakingFeesDistributed += stakingAmount;
      _stakingFeeAddress.sendValue(stakingAmount);
    }
  }

  /**
   * @dev allow incoming fees to be paused in case of emergency.
   * sending fees here while paused will result in a reverted tx.
   */
  receive() external payable virtual onlyNotPaused {
    _distributeFees(msg.value);
  }
}

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { IGovernable } from "../Governance/IGovernable.sol";
import { IPausable } from "../Control/IPausable.sol";

interface IFees is IGovernable, IPausable {
  function feeAmountBase() external view returns (uint256);
  function setFeeAmountBase(uint256 value) external;
  function getFeeAmountForType(string memory feeType) external view returns (uint256);
  function setFeeAmountForType(string memory feeType, uint256 amount) external;
  function setAddressExemptFromFees(address account, bool value) external;
  function isAddressExemptFromFees(address account) external view returns (bool);
  function feesDistributed() external view returns (uint256 total, uint256 treasury, uint256 staking);
  function treasuryFeeAddress() external view returns (address);
  function setTreasuryFeeAddress(address payable value) external;
  function stakingFeeAddress() external view returns (address);
  function setStakingFeeAddress(address payable value) external;
  function getFees() external view returns (uint16 treasuryFee, uint16 stakingFee);
  function setFees(uint16 treasuryFee, uint16 stakingFee) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
        require(isContract(target), "Address: delegate call to non-contract");

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

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { IGovernable } from "./IGovernable.sol";
import { OwnableV2 } from "../Control/OwnableV2.sol";

/**
 * @title Governable
 * 
 * parent for governable contracts
 */
abstract contract Governable is IGovernable, OwnableV2 {
  constructor(address owner_, address governor_) OwnableV2(owner_) {
    _governor_ = governor_;
    emit GovernorshipTransferred(address(0), _governor());
  }

  address internal _governor_;

  function _governor() internal virtual view returns (address) {
    return _governor_;
  }

  function governor() external virtual override view returns (address) {
    return _governor();
  }

  modifier onlyGovernor() {
    require(_governor() == _msgSender(), "Only the governor can execute this function");
    _;
  }

  // not currently used - but here it is in case we want this
  // modifier onlyOwnerOrGovernor() {
  //   require(_owner() == _msgSender() || _governor() == _msgSender(), "Only the owner or governor can execute this function");
  //   _;
  // }

  function _transferGovernorship(address newGovernor) internal virtual {
    // keep track of old owner for event
    address oldGovernor = _governor();

    // set the new governor
    _governor_ = newGovernor;

    // emit event about ownership change
    emit GovernorshipTransferred(oldGovernor, _governor());
  }

  function transferGovernorship(address newGovernor) external virtual override onlyOwner {
    _transferGovernorship(newGovernor);
  }
}

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { IPausable } from "./IPausable.sol";
import { OwnableV2 } from "./OwnableV2.sol";

abstract contract Pausable is IPausable, OwnableV2 {
  bool internal _paused;

  modifier onlyNotPaused() {
    require(!_paused, "Contract is paused");
    _;
  }

  function paused() external view override returns (bool) {
    return _paused;
  }

  function _setPaused(bool value) internal virtual {
    _paused = value;
  }

  function setPaused(bool value) external override onlyOwner {
    _setPaused(value);
  }
}

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { IOwnableV2 } from "../Control/IOwnableV2.sol";

interface IGovernable is IOwnableV2 {
  event GovernorshipTransferred(address indexed oldGovernor, address indexed newGovernor);

  function governor() external view returns (address);
  function transferGovernorship(address newGovernor) external;
}

// SPDX-License-Identifier: GPL-3.0+

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { IOwnableV2 } from "./IOwnableV2.sol";

interface IPausable is IOwnableV2 {
  function paused() external view returns (bool);
  function setPaused(bool value) external;
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;


/**
 * @title Ownable
 * 
 * parent for ownable contracts
 */
interface IOwnableV2 {
  event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

  function owner() external view returns (address);
  function transferOwnership(address newOwner_) external;
}

// SPDX-License-Identifier: UNLICENSED

/**
  /$$$$$$            /$$           /$$      /$$                                        
 /$$__  $$          | $$          | $$$    /$$$                                        
| $$  \ $$ /$$$$$$$ | $$ /$$   /$$| $$$$  /$$$$  /$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$
| $$  | $$| $$__  $$| $$| $$  | $$| $$ $$/$$ $$ /$$__  $$ /$$__  $$| $$__  $$ /$$_____/
| $$  | $$| $$  \ $$| $$| $$  | $$| $$  $$$| $$| $$  \ $$| $$  \ $$| $$  \ $$|  $$$$$$ 
| $$  | $$| $$  | $$| $$| $$  | $$| $$\  $ | $$| $$  | $$| $$  | $$| $$  | $$ \____  $$
|  $$$$$$/| $$  | $$| $$|  $$$$$$$| $$ \/  | $$|  $$$$$$/|  $$$$$$/| $$  | $$ /$$$$$$$/
 \______/ |__/  |__/|__/ \____  $$|__/     |__/ \______/  \______/ |__/  |__/|_______/ 
                         /$$  | $$                                                     
                        |  $$$$$$/                                                     
                         \______/                                                      

  https://onlymoons.io/
*/

pragma solidity ^0.8.0;

import { Context } from "../library/Context.sol";
import { IOwnableV2 } from "./IOwnableV2.sol";

/**
 * @title Ownable
 * 
 * parent for ownable contracts
 */
abstract contract OwnableV2 is IOwnableV2, Context {
  constructor(address owner_) {
    _owner_ = owner_;
    emit OwnershipTransferred(address(0), _owner());
  }

  address internal _owner_;

  function _owner() internal virtual view returns (address) {
    return _owner_;
  }

  function owner() external virtual override view returns (address) {
    return _owner();
  }

  modifier onlyOwner() {
    require(_owner() == _msgSender(), "Only the owner can execute this function");
    _;
  }

  function _transferOwnership(address newOwner_) internal virtual onlyOwner {
    // keep track of old owner for event
    address oldOwner = _owner();

    // set the new owner
    _owner_ = newOwner_;

    // emit event about ownership change
    emit OwnershipTransferred(oldOwner, _owner());
  }

  function transferOwnership(address newOwner_) external virtual override onlyOwner {
    _transferOwnership(newOwner_);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

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