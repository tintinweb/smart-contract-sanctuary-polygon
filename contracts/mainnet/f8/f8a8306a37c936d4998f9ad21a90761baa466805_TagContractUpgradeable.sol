/**
 *Submitted for verification at polygonscan.com on 2022-03-07
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity >=0.8.0 <0.9.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


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



// File contracts/TagUpgradable.sol


contract TagContractUpgradeable is Initializable, BaseRelayRecipient {

    using SafeMathUpgradeable for uint256;
        
    // events
    event CreateTag(string[] tags, string cid, address provider);
    event AddTag(string[] tags, string cid, address provider);
    event RemoveTag(string[] tags, string cid, address provider);
    event ClearTag(string cid, address provider);

    string public override versionRecipient;

    // Error string
    string private constant PROVIDER_EXIST_ERR = "Provider Exists";
    string private constant PROVIDER_ERR = "No Provider";
    string private constant CID_ERR = "No CID";
    string private constant INDEX_ERR = "Index Out of Bounds";
    string private constant TIME_ERR = "Expired deadline";
    string private constant MATCH_ERR = "NO MATCHING";
    
    address[] public providers;
    // map for Strings
    string[] public tagArray;
    string[] public cidArray;
    mapping(string=>uint256) public tagMapping;
    mapping(string=>uint256) public cidMapping;

    // data search
    mapping(address=>mapping(uint256=>uint256[])) public tagCidMapping;
    mapping(address=>mapping(uint256=>uint256[])) public cidTagMapping;
    // address-tag-cid mapping (for existence check)
    mapping(address=>mapping(uint256=>mapping(uint256=>uint256))) public tagCidExistenceMapping;
    // address-cid-tag mapping (for existence check)
    mapping(address=>mapping(uint256=>mapping(uint256=>uint256))) public cidTagExistenceMapping;


    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0));
        }
        if (v != 27 && v != 28) {
            return (address(0));
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0));
        }

        return (signer);
    }
    
    function initialize(address forwarder) public initializer {
        versionRecipient = "2.2.0";
        _setTrustedForwarder(forwarder);
    }

    // set a provider of tags, anyone can be a provider of tags
    function setTagProvider() public {
        // check if provider is already registered
        require( ! hasAddress(providers, _msgSender()),  PROVIDER_EXIST_ERR);
        // add provider into the provider list
        providers.push(_msgSender());
    }

    // set tag given that the tags are updated by the provider
    function setTags(string[] memory tags, string memory cid, address fromProvider) private {
        uint256 cidID = getCidID(cid);

        // check if msg sender is in the provider list
        require( hasAddress(providers, fromProvider), PROVIDER_ERR);

        if (cidTagMapping[fromProvider][cidID].length != 0) {
            // clear tags
            clearTags(cid, fromProvider);
        } 

        // create
        addTags(tags, cid, fromProvider);
        
        emit CreateTag(tags, cid, fromProvider);
    }

    function setTagsWithoutSig(
        string[] memory tags,
        string memory cid) public {
            setTags(tags, cid, _msgSender());
        }

    // set tag given that the tags are updated by the user
    function setTagsWithSig(
        string[] memory tags,
        string memory cid,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) public {
        // prove that the tags are signed by the valid provider
        // reject signature past deadline
        require(deadline > block.timestamp, TIME_ERR);
        // convert tag list into bytes
        bytes32 tagString = keccak256(abi.encode("SET", cid, tags, deadline));
        address recoveredProvider = tryRecover(tagString, v, r, s);
        require( hasAddress(providers, recoveredProvider), PROVIDER_ERR );

        // settags
        setTags(tags, cid, recoveredProvider);
    }

    function addTagsWithoutSig(
        string[] memory tags,
        string memory cid) public {
        addTags(tags, cid, _msgSender());
    }

    function addTagsWithSig(
        string[] memory tags,
        string memory cid,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) public {
        // prove that the tags are signed by the valid provider
        // reject signature past deadline
        require(deadline > block.timestamp, TIME_ERR);
        // convert tag list into bytes
        bytes32 tagString = keccak256(abi.encode("ADD", cid, tags, deadline));
        address recoveredProvider = tryRecover(tagString, v, r, s);
        require( hasAddress(providers, recoveredProvider), PROVIDER_ERR );

        // addtags
        addTags(tags, cid, recoveredProvider);
    }

    function removeTagsWithoutSig(
        string[] memory tags,
        string memory cid,
        bool skipUnmatch) public {
        removeTags(tags, cid, _msgSender(), skipUnmatch);
    }

    function removeTagsWithSig(
        string[] memory tags,
        string memory cid,
        bool skipUnmatch,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) public {
        // prove that the tags are signed by the valid provider
        // reject signature past deadline
        require(deadline > block.timestamp, TIME_ERR);
        // convert tag list into bytes
        bytes32 tagString = keccak256(abi.encode("REMOVE", cid, tags, skipUnmatch, deadline));
        address recoveredProvider = tryRecover(tagString, v, r, s);
        require( hasAddress(providers, recoveredProvider), PROVIDER_ERR );

        // removetags
        removeTags(tags, cid, recoveredProvider, skipUnmatch);
    }

    function clearTagsWithoutSig(
        string memory cid) public {
        clearTags(cid, _msgSender());
    }

    function clearTagsWithSig(
        string memory cid,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) public {
        // prove that the tags are signed by the valid provider
        // reject signature past deadline
        require(deadline > block.timestamp, TIME_ERR);
        // convert tag list into bytes
        bytes32 tagString = keccak256(abi.encode("CLEAR", cid, deadline));
        address recoveredProvider = tryRecover(tagString, v, r, s);
        require( hasAddress(providers, recoveredProvider), PROVIDER_ERR );

        // cleartags
        clearTags(cid, recoveredProvider);
    }

    // getCIDID
    function getCidID(string memory cid) private returns (uint256) {
        uint256 cidID;
        // if cid not exists add cid to list
        if (cidMapping[cid] == 0) {
            cidArray.push(cid);
            cidID = cidArray.length;
            cidMapping[cid] = cidID;
        } else {
            cidID = cidMapping[cid];
        }
        return cidID;
    } 

    // getTagID 
    function getTagID(string memory tag) private returns (uint256) {
        uint256 tagID;
        // if tag not exists add tag to list 
        if (tagMapping[tag] == 0) {
            tagArray.push(tag);
            tagID = tagArray.length;
            tagMapping[tag] = tagID;
        } else {
            tagID = tagMapping[tag];
        }
        return tagID;
    }

    // add Tags
    function addTags(string[] memory tags, string memory cid, address fromProvider) private {
        // check if msg sender is in the provider list
        require( hasAddress(providers, fromProvider), PROVIDER_ERR);

        // get cidID
        uint256 cidID = cidMapping[cid];
        require(cidID > 0, CID_ERR);

        for ( uint i = 0 ; i < tags.length ; i++ ) {
            // get tagID
            uint256 tagID = getTagID(tags[i]);

            // set mapping if not exists
            if ( tagCidExistenceMapping[fromProvider][tagID][cidID] == 0 ) {
                tagCidMapping[fromProvider][tagID].push(cidID);
                tagCidExistenceMapping[fromProvider][tagID][cidID] = tagCidMapping[fromProvider][tagID].length;
            }

            // set cid -> tag
            if ( cidTagExistenceMapping[fromProvider][cidID][tagID] == 0 ) {
                cidTagMapping[fromProvider][cidID].push(tagID);
                cidTagExistenceMapping[fromProvider][cidID][tagID] = cidTagMapping[fromProvider][cidID].length;
            }
        }
        emit AddTag(tags, cid, fromProvider);
    }

    // remove Tags skipUnmatch is a variable to skip the tags that do not match, else there will be an error
    function removeTags(string[] memory tags, string memory cid, address fromProvider, bool skipUnmatch) private {
        
        // check if msg sender is in the provider list
        require( hasAddress(providers, fromProvider), PROVIDER_ERR);

        // get cidID
        uint256 cidID = cidMapping[cid];
        require(cidID > 0, CID_ERR);

        for ( uint i = 0 ; i < tags.length ; i++ ) {

            // get tagID
            uint256 tagID = tagMapping[tags[i]];

            // unset mapping if not exist
            uint256 tagLoc = tagCidExistenceMapping[fromProvider][tagID][cidID];
            uint256 cidLoc = cidTagExistenceMapping[fromProvider][cidID][tagID];
            if ( tagLoc == 0 || cidLoc == 0) {
                require(skipUnmatch, MATCH_ERR);
                continue;
            }

            tagCidMapping[fromProvider][tagID][tagLoc.sub(1)] = 0;
            tagCidExistenceMapping[fromProvider][tagID][cidID] = 0;

            cidTagMapping[fromProvider][cidID][cidLoc.sub(1)] = 0;
            cidTagExistenceMapping[fromProvider][cidID][tagID] = 0;
        }
        emit RemoveTag(tags, cid, fromProvider);
    }

    // clear Tags
    function clearTags(string memory cid, address fromProvider) private {
        // check if msg sender is in the provider list
        require( hasAddress(providers, fromProvider), PROVIDER_ERR);
        
        // get cidID
        uint256 cidID = cidMapping[cid];
        require(cidID > 0, CID_ERR);
        
        uint256[] memory existingTags = cidTagMapping[fromProvider][cidID];
        for ( uint i = 0 ; i < existingTags.length ; i++ ) {
            
            uint256 tagLoc = tagCidExistenceMapping[fromProvider][existingTags[i]][cidID];
            if ( tagLoc != 0 ) {
                tagCidMapping[fromProvider][existingTags[i]][tagLoc.sub(1)] = 0;
                tagCidExistenceMapping[fromProvider][existingTags[i]][cidID] = 0;
            }

            // clear up existence mapping
            uint256 cidLoc = cidTagExistenceMapping[fromProvider][cidID][existingTags[i]];
            if ( cidLoc != 0 ) {
                cidTagExistenceMapping[fromProvider][cidID][existingTags[i]] = 0;
            }
        }

        // reset list
        cidTagMapping[fromProvider][cidID] = new uint256[](0);

        emit ClearTag(cid, fromProvider);
    }

    // get the tags with a given CID, and a list of providers
    function getTagsWithCID(string memory cid, address fromProvider, uint256 skip, uint256 limit) public view returns (string[] memory) {
        require( hasAddress(providers, fromProvider), PROVIDER_ERR);
        uint256 cidID = cidMapping[cid];
        require( skip + limit <= cidTagMapping[fromProvider][cidID].length, INDEX_ERR);
        string[] memory selectedTags = new string[](limit);
        for ( uint256 i = 0 ; i < limit ; i++ ) {
            uint256 tagID = cidTagMapping[fromProvider][cidID][skip+i];
            if (tagID != 0) {
                selectedTags[i] = tagArray[tagID.sub(1)];
            }
        }
        return selectedTags;
    }

    // get the cid list with given tags and a list of given proviers
    function getCIDswithTags(string memory tag, address fromProvider, uint256 skip, uint256 limit) public view returns (string[] memory) {
        require( hasAddress(providers, fromProvider), PROVIDER_ERR);
        uint256 tagID = tagMapping[tag];
        require( skip + limit <= tagCidMapping[fromProvider][tagID].length, INDEX_ERR);
        string[] memory selectedCids = new string[](limit);
        for ( uint256 i = 0 ; i < limit ; i++ ) {
            uint256 cidID = tagCidMapping[fromProvider][tagID][skip+i];
            if (cidID != 0) {
                selectedCids[i] = cidArray[cidID.sub(1)]; // get back the string
            }
        }
        return selectedCids;
    }

    function hasAddress(address[] memory addressList, address newAddress) private pure returns (bool) {
        for ( uint256 i = 0 ; i < addressList.length ; i ++ ) {
            if ( addressList[i] == newAddress ) {
                return true;
            }
        }
        return false;
    }

}