// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.8.4;

import "@opengsn/contracts/src/BaseRelayRecipient.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Valist registry contract
///
/// @custom:err-empty-meta metadata URI is required
/// @custom:err-empty-members atleast one member is required
/// @custom:err-empty-name name is required
/// @custom:err-name-claimed name has already been claimed
/// @custom:err-not-member sender is not a member
/// @custom:err-member-exist member already exists
/// @custom:err-member-not-exist member does not exist
/// @custom:err-not-exist account, project, or release does not exist
contract Registry is BaseRelayRecipient {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @dev emitted when an account is created
  event AccountCreated(
    uint _accountID,
    string _name,
    string _metaURI,
    address _sender
  );

  /// @dev emitted when an account is updated
  event AccountUpdated(
    uint _accountID,
    string _metaURI,
    address _sender
  );

  /// @dev emitted when an account member is added
  event AccountMemberAdded(
    uint _accountID,
    address _member,
    address _sender
  );
  
  /// @dev emitted when an account member is removed
  event AccountMemberRemoved(
    uint _accountID,
    address _member,
    address _sender
  );

  /// @dev emitted when a new project is created
  event ProjectCreated(
    uint _accountID,
    uint _projectID,
    string _name,
    string _metaURI, 
    address _sender
  );

  /// @dev emitted when an existing project is updated
  event ProjectUpdated(
    uint _projectID,
    string _metaURI,
    address _sender
  );

  /// @dev emitted when a new project member is added
  event ProjectMemberAdded(
    uint _projectID,
    address _member,
    address _sender
  );

  /// @dev emitted when an existing project member is removed
  event ProjectMemberRemoved(
    uint _projectID,
    address _member,
    address _sender
  );

  /// @dev emitted when a new release is created
  event ReleaseCreated(
    uint _projectID,
    uint _releaseID,
    string _name,
    string _metaURI, 
    address _sender
  );

  /// @dev emitted when a release is approved by a signer
  event ReleaseApproved(
    uint _releaseID,
    address _sender
  );

  /// @dev emitted when a release approval is revoked by a signer.
  event ReleaseRevoked(
    uint _releaseID,
    address _sender
  );

  struct Account {
    EnumerableSet.AddressSet members;
  }

  struct Project {
    uint accountID;
    EnumerableSet.AddressSet members;
  }

  struct Release {
    uint projectID;
    EnumerableSet.AddressSet signers;
  }

  /// @dev mapping of account ID to account
  mapping(uint => Account) private accountByID;
  /// @dev mapping of project ID to project
  mapping(uint => Project) private projectByID;
  /// @dev mapping of release ID to release
  mapping(uint => Release) private releaseByID;
  /// @dev mapping of account, project, and release ID to meta URI
  mapping(uint => string) public metaByID;

  /// @dev version of BaseRelayRecipient this contract implements
  string public override versionRecipient = "2.2.3";
  /// @dev address of contract owner
  address payable public owner;
  /// @dev account name claim fee
  uint public claimFee;

  /// Creates a Valist Registry contract.
  ///
  /// @param _forwarder Address of meta transaction forwarder.
  constructor(address _forwarder) {
    owner = payable(msg.sender);
    _setTrustedForwarder(_forwarder);
  }

  /// Creates an account with the given members.
  ///
  /// @param _name Unique name used to identify the account.
  /// @param _metaURI URI of the account metadata.
  /// @param _members List of members to add to the account.
  function createAccount(
    string memory _name,
    string memory _metaURI,
    address[] memory _members
  )
    public
    payable
  {
    require(msg.value >= claimFee, "err-value");
    require(bytes(_metaURI).length > 0, "err-empty-meta");
    require(bytes(_name).length > 0, "err-empty-name");
    require(_members.length > 0, "err-empty-members");

    uint accountID = generateID(block.chainid, _name);
    require(bytes(metaByID[accountID]).length == 0, "err-name-claimed");

    metaByID[accountID] = _metaURI;
    emit AccountCreated(accountID, _name, _metaURI, _msgSender());

    for (uint i = 0; i < _members.length; ++i) {
      accountByID[accountID].members.add(_members[i]);
      emit AccountMemberAdded(accountID, _members[i], _msgSender());
    }

    Address.sendValue(owner, msg.value);
  }
  
  /// Creates a new project. Requires the sender to be a member of the account.
  ///
  /// @param _accountID ID of the account to create the project under.
  /// @param _name Unique name used to identify the project.
  /// @param _metaURI URI of the project metadata.
  /// @param _members Optional list of members to add to the project.
  function createProject(
    uint _accountID,
    string memory _name,
    string memory _metaURI,
    address[] memory _members
  )
    public
  {
    require(bytes(_metaURI).length > 0, "err-empty-meta");
    require(bytes(_name).length > 0, "err-empty-name");

    uint projectID = generateID(_accountID, _name);
    require(isAccountMember(_accountID, _msgSender()), "err-not-member");
    require(bytes(metaByID[projectID]).length == 0, "err-name-claimed");

    metaByID[projectID] = _metaURI;
    projectByID[projectID].accountID = _accountID;
    emit ProjectCreated(_accountID, projectID, _name, _metaURI, _msgSender());

    for (uint i = 0; i < _members.length; ++i) {
      projectByID[projectID].members.add(_members[i]);
      emit ProjectMemberAdded(projectID, _members[i], _msgSender());
    }
  }

  /// Creates a new release. Requires the sender to be a member of the project.
  ///
  /// @param _projectID ID of the project create the release under.
  /// @param _name Unique name used to identify the release.
  /// @param _metaURI URI of the project metadata.
  function createRelease(
    uint _projectID,
    string memory _name,
    string memory _metaURI
  )
    public
  {
    require(bytes(_name).length > 0, "err-empty-name");
    require(bytes(_metaURI).length > 0, "err-empty-meta");
    require(bytes(metaByID[_projectID]).length > 0, "err-not-exist");

    uint releaseID = generateID(_projectID, _name);
    require(bytes(metaByID[releaseID]).length == 0, "err-name-claimed");

    uint accountID = getProjectAccountID(_projectID);
    require(
      isProjectMember(_projectID, _msgSender()) ||
      isAccountMember(accountID, _msgSender()),
      "err-not-member"
    );

    metaByID[releaseID] = _metaURI;
    releaseByID[releaseID].projectID = _projectID;
    emit ReleaseCreated(_projectID, releaseID, _name, _metaURI, _msgSender());
  }

  /// Approve the release by adding the sender's address to the approvers list.
  ///
  /// @param _releaseID ID of the release.
  function approveRelease(uint _releaseID) public {
    require(bytes(metaByID[_releaseID]).length > 0, "err-not-exist");
    require(!releaseByID[_releaseID].signers.contains(_msgSender()), "err-member-exist");

    releaseByID[_releaseID].signers.add(_msgSender());
    emit ReleaseApproved(_releaseID, _msgSender());
  }

  /// Revoke a release signature by removing the sender's address from the approvers list.
  ///
  /// @param _releaseID ID of the release.
  function revokeRelease(uint _releaseID) public {
    require(bytes(metaByID[_releaseID]).length > 0, "err-not-exist");
    require(releaseByID[_releaseID].signers.contains(_msgSender()), "err-member-exist");

    releaseByID[_releaseID].signers.remove(_msgSender());
    emit ReleaseRevoked(_releaseID, _msgSender());
  }

  /// Add a member to the account. Requires the sender to be a member of the account.
  ///
  /// @param _accountID ID of the account.
  /// @param _address Address of member.
  function addAccountMember(uint _accountID, address _address) public {
    require(isAccountMember(_accountID, _msgSender()), "err-not-member");
    require(!isAccountMember(_accountID, _address), "err-member-exist");

    accountByID[_accountID].members.add(_address);
    emit AccountMemberAdded(_accountID, _address, _msgSender());
  }

  /// Remove a member from the account. Requires the sender to be a member of the account.
  ///
  /// @param _accountID ID of the account.
  /// @param _address Address of member.
  function removeAccountMember(uint _accountID, address _address) public {
    require(isAccountMember(_accountID, _msgSender()), "err-not-member");
    require(isAccountMember(_accountID, _address), "err-member-not-exist");

    accountByID[_accountID].members.remove(_address);
    emit AccountMemberRemoved(_accountID, _address, _msgSender());
  }

  /// Add a member to the project. Requires the sender to be a member of the parent account.
  ///
  /// @param _projectID ID of the project.
  /// @param _address Address of member.
  function addProjectMember(uint _projectID, address _address) public {
    require(bytes(metaByID[_projectID]).length > 0, "err-not-exist");
    require(!isProjectMember(_projectID, _address), "err-member-exist");

    uint accountID = getProjectAccountID(_projectID);
    require(isAccountMember(accountID, _msgSender()), "err-not-member");

    projectByID[_projectID].members.add(_address);
    emit ProjectMemberAdded(_projectID, _address, _msgSender());
  }

  /// Remove a member from the project. Requires the sender to be a member of the parent account.
  ///
  /// @param _projectID ID of the project.
  /// @param _address Address of member.
  function removeProjectMember(uint _projectID, address _address) public {
    require(bytes(metaByID[_projectID]).length > 0, "err-not-exist");
    require(isProjectMember(_projectID, _address), "err-member-not-exist"); 

    uint accountID = getProjectAccountID(_projectID);
    require(isAccountMember(accountID, _msgSender()), "err-not-member");

    projectByID[_projectID].members.remove(_address);
    emit ProjectMemberRemoved(_projectID, _address, _msgSender());   
  }

  /// Sets the account metadata URI. Requires the sender to be a member of the account.
  ///
  /// @param _accountID ID of the account.
  /// @param _metaURI Metadata URI.
  function setAccountMetaURI(uint _accountID, string memory _metaURI) public {
    require(bytes(_metaURI).length > 0, "err-empty-meta");
    require(isAccountMember(_accountID, _msgSender()), "err-not-member");
    require(bytes(metaByID[_accountID]).length > 0, "err-not-exist");

    metaByID[_accountID] = _metaURI;
    emit AccountUpdated(_accountID, _metaURI, _msgSender());
  }

  /// Sets the project metadata URI. Requires the sender to be a member of the parent account.
  ///
  /// @param _projectID ID of the project.
  /// @param _metaURI Metadata URI.
  function setProjectMetaURI(uint _projectID, string memory _metaURI) public {
    require(bytes(_metaURI).length > 0, "err-empty-meta");
    require(bytes(metaByID[_projectID]).length > 0, "err-not-exist");

    uint accountID = getProjectAccountID(_projectID);
    require(isAccountMember(accountID, _msgSender()), "err-not-member");

    metaByID[_projectID] = _metaURI;
    emit ProjectUpdated(_projectID, _metaURI, _msgSender());
  }

  /// Generates account, project, or release ID.
  ///
  /// @param _parentID ID of the parent account or project. Use `block.chainid` for accounts.
  /// @param _name Name of the account, project, or release.
  function generateID(uint _parentID, string memory _name) public pure returns (uint) {
    return uint(keccak256(abi.encodePacked(_parentID, keccak256(bytes(_name)))));
  }

  /// Returns true if the address is a member of the team.
  ///
  /// @param _accountID ID of the account.
  /// @param _member Address of member.
  function isAccountMember(uint _accountID, address _member) public view returns (bool) {
    return accountByID[_accountID].members.contains(_member);
  }

  /// Returns true if the address is a member of the project.
  ///
  /// @param _projectID ID of the project.
  /// @param _member Address of member.
  function isProjectMember(uint _projectID, address _member) public view returns (bool) {
    return projectByID[_projectID].members.contains(_member);
  }

  /// Returns true if the address is a signer of the release.
  ///
  /// @param _releaseID ID of the release.
  /// @param _signer Address of the signer.
  function isReleaseSigner(uint _releaseID, address _signer) public view returns (bool) {
    return releaseByID[_releaseID].signers.contains(_signer);
  }

  /// Returns a list of account members.
  ///
  /// @param _accountID ID of the account.
  function getAccountMembers(uint _accountID) public view returns (address[] memory) {
    return accountByID[_accountID].members.values();
  }

  /// Returns a list of project members.
  ///
  /// @param _projectID ID of the project.
  function getProjectMembers(uint _projectID) public view returns (address[] memory) {
    return projectByID[_projectID].members.values();
  }

  /// Returns a list of release signers.
  ///
  /// @param _releaseID ID of the release.
  function getReleaseSigners(uint _releaseID) public view returns (address[] memory) {
    return releaseByID[_releaseID].signers.values();
  }

  /// Returns the parent account ID for the project.
  ///
  /// @param _projectID ID of the project.
  function getProjectAccountID(uint _projectID) public view returns (uint) {
    return projectByID[_projectID].accountID;
  }

  /// Returns the parent project ID for the release.
  /// 
  /// @param _releaseID ID of the release.
  function getReleaseProjectID(uint _releaseID) public view returns (uint) {
    return releaseByID[_releaseID].projectID;
  }

  /// Sets the owner address. Owner only.
  ///
  /// @param _owner Address of the new owner.
  function setOwner(address payable _owner) public onlyOwner {
    owner = _owner;
  }

  /// Sets the account claim fee. Owner only.
  ///
  /// @param _claimFee Claim fee amount in wei.
  function setClaimFee(uint _claimFee) public onlyOwner {
    claimFee = _claimFee;
  }

  /// Sets the trusted forward address. Owner only.
  ///
  /// @param _forwarder Address of meta transaction forwarder.
  function setTrustedForwarder(address _forwarder) public onlyOwner {
    _setTrustedForwarder(_forwarder);
  }

  /// Modifier that ensures only the owner can call a function.
  modifier onlyOwner() {
    require(owner == _msgSender(), "caller is not the owner");
    _;
  }
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}