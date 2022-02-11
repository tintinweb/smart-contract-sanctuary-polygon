//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./../interfaces/ISheeshaDao.sol";
import "./../interfaces/ISheeshaVotes.sol";
import "./../interfaces/ISheeshaVoting.sol";
import "./../utils/Arrays.sol";
import "./../utils/Bytes.sol";

contract SheeshaDefaultVoting is
    ISheeshaVoting,
    ContextUpgradeable {
    using Arrays for uint256[];
    using Bytes for bytes;

    uint32 public override begin;
    uint32 public override end;
    uint8 public override quorum;
    uint8 public override threshold;

    address public override dao;
    bool public override executed;
    mapping(address => uint256[]) public override votesOfFor;
    uint256[] public override votesFor;

    event Voted(address sender, address voter, uint256 added);

    function initializeAsImpl() external initializer {
    }

    function initialize(address dao_, bytes calldata data_) external override initializer {
        __SheeshaDefaultVoting_init(dao_, data_);
    }

    function __SheeshaDefaultVoting_init(address dao_, bytes calldata data_) internal onlyInitializing {
        __Context_init_unchained();
        __SheeshaDefaultVoting_init_unchained(dao_, data_);
    }

    function __SheeshaDefaultVoting_init_unchained(address dao_, bytes calldata data_) internal onlyInitializing {
        dao = dao_;
        votesFor = new uint256[](data_.sliceUint(0));
        begin = uint32(data_.sliceUint(32));
        end = uint32(data_.sliceUint(64));
        quorum = uint8(data_.sliceUint(96));
        threshold = uint8(data_.sliceUint(128));
        require(
            end > block.timestamp
            && end > begin
            && quorum <= 100
            && threshold <= 100, "SDV: invalid initialization");
    }

    function votesOf(address member) public view override returns (uint256) {
        return votesOfFor[member].sum();
    }

    function votesForNum() external view override returns (uint256) {
        return votesFor.length;
    }

    function votes() public view override returns (uint256) {
        return votesFor.sum();
    }

    function hasQuorum() public view override returns (bool) {
        return _hasQuorum(votes());
    }

    function state() public view override returns (State) {
        return block.timestamp < begin ? State.STATE_INACTIVE :
            block.timestamp < end ? State.STATE_ACTIVE :
            _completionState();
    }

    function winners() public view override returns(uint256 winners_) {
        uint256 votes_ = votes();
        if (_hasQuorum(votes_)) {
            winners_ = _winners(votes_);
        }
    }

    function vote(bytes calldata data) external override {
        require(ISheeshaDao(dao).activeVoting() == address(this), "SDV: not active");
        address voter = address(uint160(data.sliceUint(0)));
        require(voter == _msgSender() 
            || ISheeshaDao(dao).delegates(voter, _msgSender()),
            "SDV: not delegated");
        uint256 candidates = data.sliceUint(32);      
        require(candidates <= votesFor.length, "SDV: too many candidates");
        uint256 votesAdded = _vote(voter, candidates, data, 64);
        uint256 totalOf_ = ISheeshaVotes(ISheeshaDao(dao).votes()).totalOf(voter);
        require(totalOf_ >= votesOf(voter), "SDV: not enough votes");
        emit Voted(_msgSender(), voter, votesAdded);
    }

    function verify(address[] calldata members) external view override returns (address[] memory violators) {
        return _verify(members, 0);
    }

    function cancel(address[] calldata members) external override {
        require(members.length > 0, "SDV: bad input");
        ISheeshaVotes votes_ = ISheeshaVotes(ISheeshaDao(dao).votes());
        for (uint256 i = 0; i < members.length; ) {
            address voter = members[i];
            require(votes_.totalOf(voter) < votesOf(voter), "SDV: bad cancel address");
            uint256[] storage votesOfFor_ = votesOfFor[voter];
            for (uint256 k = 0; k < votesFor.length;) {
                votesFor[k] -= votesOfFor_[k];
                unchecked { k++; }
            }
            delete votesOfFor[voter];
            unchecked { i++; }
        }
    }

    function execute() external pure override {
        revert("SDV: not supported");
    }

    function _hasQuorum(uint256 votes_) internal view returns (bool) {
        return votes_ > 0 && votes_ * 100 / ISheeshaVotes(ISheeshaDao(dao).votes()).total() >= quorum;
    }

    function _completionState() internal view returns (State) {
        uint256 votes_ = votes();
        return votes_ == 0 || !_hasQuorum(votes_) ? State.STATE_COMPLETED_NO_QUORUM :
            _winners(votes_) == 0 ? State.STATE_COMPLETED_NO_WINNER :
            executed ? State.STATE_COMPLETED_EXECUTED : State.STATE_COMPLETED;
    }

    function _winners(uint256 votes_) internal view returns(uint256 winners_) {
        for (uint256 i = 0; i < votesFor.length;) {
            if (votesFor[i] * 100 / votes_ >= quorum) winners_ |= 1 << i;
            unchecked { i++; }
        }
    }

    function _vote(address voter, uint256 candidates, bytes calldata data, uint256 pos) internal returns (uint256 sum) {
        uint256[] storage votesOfFor_ = votesOfFor[voter];
        if (votesOfFor_.length == 0) {
            votesOfFor[voter] = new uint256[](votesFor.length);
        }
        for (uint256 i  = 0; i < candidates; ) {
            uint256 votes_ = data.sliceUint(pos + i * 32);
            votesFor[i] += votes_;
            votesOfFor_[i] += votes_;
            sum += votes_;
            unchecked { i++; }
        }
    }

    function _verify(address[] calldata members, uint256 num) internal view returns (address[] memory violators) {
        ISheeshaVotes votes_ = ISheeshaVotes(ISheeshaDao(dao).votes());
        if (num > 0) {
            violators = new address[](num);
            num = 0;
        }
        for (uint256 i = 0; i < members.length;) {
            address voter = members[i];
            if (votes_.totalOf(voter) < votesOf(voter)) {
                if (violators.length > 0) {
                    violators[num] = voter;
                }
                unchecked { num++; }
            }
            unchecked { i++; }
        }
        if (num > 0 && violators.length == 0) {
            violators = _verify(members, num);
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISheeshaDao {
    function votes() external view returns (address);
    function activeVoting() external view returns (address);
    function latestVoting() external view returns (address);
    function delegates(address who, address whom) external view returns (bool);

    function setVotes(address) external;
    function execute(address target, uint256 value, bytes calldata data) external;

    event SetVotes(address who, address votes);
    event Executed(address who, address target, uint256 value, bytes data);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ISheeshaDaoInitializable.sol";
import "./ISheeshaVotesLocker.sol";

interface ISheeshaVotes is
    ISheeshaDaoInitializable,
    ISheeshaVotesLocker {
    function dao() external view returns (address);
    function SHVault() external view returns (address);
    function LPVault() external view returns (address);
    function SHToken() external view returns (address);
    function LPToken() external view returns (address);
    function prices() external view returns (uint256 shPrice, uint256 lpPrice);

    function setVaults(address SHVault_, address LPVault_) external;

    event SetVaults(address, address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ISheeshaDaoInitializable.sol";

interface ISheeshaVoting is ISheeshaDaoInitializable {
    enum State {
        STATE_INACTIVE,
        STATE_ACTIVE,
        STATE_COMPLETED_NO_QUORUM,
        STATE_COMPLETED_NO_WINNER,
        STATE_COMPLETED,
        STATE_COMPLETED_EXECUTED
    }
    function dao() external view returns (address);
    function begin() external view returns (uint32);
    function end() external view returns (uint32);
    function quorum() external view returns (uint8);
    function threshold() external view returns (uint8);
    function votesOf(address member) external view returns (uint256);
    function votesOfFor(address member, uint256 candidate) external view returns (uint256);
    function votesFor(uint256) external view returns (uint256);
    function votesForNum() external view returns (uint256);
    function votes() external view returns (uint256);
    function hasQuorum() external view returns (bool);
    function state() external view returns (State);
    function winners() external view returns(uint256);
    function executed() external view returns (bool);

    function vote(bytes calldata data) external;
    function verify(address[] calldata members) external view returns (address[] memory);
    function cancel(address[] calldata members) external;
    function execute() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Arrays {
    function sum(uint256[] storage data) internal view returns (uint256 ret) {
        for (uint256 i  = 0; i < data.length; ) {
            ret += data[i]; 
            unchecked { i++; }
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library Bytes {
    function sliceUint(bytes memory bs, uint256 pos) internal pure returns (uint256) {
        require(bs.length >= pos + 32, "slicing out of range");
        uint256 x;
        assembly {
            x := mload(add(bs, add(0x20, pos)))
        }
        return x;
    }
    function sliceAddress(bytes memory bs, uint256 pos) internal pure returns (address) {
        return address(uint160(sliceUint(bs, pos)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

interface ISheeshaDaoInitializable {
    function initialize(address dao, bytes calldata data) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISheeshaVotesLocker {
    function total() external view returns (uint256);
    function locked() external view returns (uint256);
    function unlocked() external view returns (uint256);
    function totalOf(address member) external view returns (uint256);
    function lockedOf(address member) external view returns (uint256);
    function unlockedOf(address member) external view returns (uint256);
    function unlockedSHOf(address member) external view returns (uint256);
    function unlockedLPOf(address member) external view returns (uint256);
}