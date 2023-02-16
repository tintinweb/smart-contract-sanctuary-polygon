// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
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
interface IERC165 {
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
contract CooperatableBase is Ownable 
{
    mapping (address => bool) cooperative_contracts;
    function add_cooperative(address contract_addr) external onlyOwner{
        cooperative_contracts[contract_addr] = true;
    }
    function add_cooperatives(address[] memory contract_addrs) external onlyOwner {
        for(uint256 i = 0; i < contract_addrs.length; i++)
            cooperative_contracts[contract_addrs[i]] = true;
    }

    function remove_cooperative(address contract_addr) external onlyOwner {
        delete cooperative_contracts[contract_addr];
    }
    function remove_cooperatives(address[] memory contract_addrs) external onlyOwner{
        for(uint256 i = 0; i < contract_addrs.length; i++)
           delete cooperative_contracts[contract_addrs[i]];
    }
    function is_cooperative_contract(address _addr) internal view returns (bool){return cooperative_contracts[_addr];}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./TokenCooperatableDriverContract.sol";
import "../Interfaces/IERC721TokenContract.sol";

contract Erc721CooperatableDriverContract is TokenCooperatableDriverContract {

    constructor(string memory name_,string memory desc_,address token_contract_) 
        TokenCooperatableDriverContract(name_,desc_,token_contract_) {    
    }
    function fetch_token_contract_interface_id() internal virtual override returns(bytes4) {
       return type(IERC721TokenContract).interfaceId;
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "../Util/CooperatableDriver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../Interfaces/ITokenOperatableTemplate.sol";

contract TokenCooperatableDriverContract is CooperatableDriver ,ITokenOperatableTemplate,ERC165 {
    
    using ERC165Checker for address;
    using Address for address;

    string constant private EmptyString = "";
    string private name;
    string private description;
    
    //NFT or Token to mint
    address private token_contract = address(0);

    //Interface id of token or NFT.
    bytes4 private token_constract_interface_id = 0xffffffff;

    constructor(string memory name_,string memory description_,address token_contract_) {
        name = name_;
        description = description_;
        token_constract_interface_id = fetch_token_contract_interface_id();
        _set_token_contract_internal(token_contract_);
    }
    function _set_token_contract_internal(address addr) internal{
        require(addr.supportsInterface(token_constract_interface_id),"UNSUPPORT_TOKEN");
        token_contract = addr;
    }
    function set_token_contract(address addr) external onlyOwner{
        _set_token_contract_internal(addr);
    }
    function fetch_token_contract_interface_id() internal virtual returns(bytes4) {return 0xffffffff;}
    function get_metadata() public view returns (string memory,string memory,address){return (name,description,token_contract);}
    function get_token_contract() external view virtual override returns (address){return token_contract;}
    function get_token_contract_address() public view returns (address){return token_contract;}
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(ITokenOperatableTemplate).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    
    function get_template_metadata(uint256) external view virtual override returns (string memory,string memory,uint256,bool,address){return (EmptyString,EmptyString,0,false,address(0));}
    function is_template_defined(uint256) external view virtual override returns (bool){return false;}
    function is_template_enabled(uint256) external view virtual override returns (bool){return false;}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../base/Erc721CooperatableDriverContract.sol";
import "../Interfaces/IERC721InteractionDriver.sol";

contract Erc721InteractionDriver is Erc721CooperatableDriverContract,IERC721InteractionDriver {
    
    constructor(string memory name_,string memory desc_,address token_contract_) 
        Erc721CooperatableDriverContract(name_,desc_,token_contract_) {
    }
    function mintNFTsFor(address addr,uint256 amount) external virtual override onlyOwnerAndOperatableTemplate returns (uint256[] memory){
        address _token_contract = get_token_contract_address();
        require(_token_contract != address(0),"NO_TOKEN_CONTRACT");
        
        IERC721TokenContract _tokenContract = IERC721TokenContract(_token_contract);
        return _tokenContract.mintNFTsFor(addr,amount);
    }
    function mintNFTFor(address addr,string memory tokenUri) external virtual override onlyOwnerAndOperatableTemplate  returns (uint256){
        address _token_contract = get_token_contract_address();
        require(_token_contract != address(0),"NO_TOKEN_CONTRACT");
        
        IERC721TokenContract _tokenContract = IERC721TokenContract(_token_contract);
        return _tokenContract.mintNFTFor(addr,tokenUri);
    }
    function burnNFTFor(address addr,uint256 tokenId) external virtual override onlyOwnerAndOperatableTemplate {
        address _token_contract = get_token_contract_address();
        require(_token_contract != address(0),"NO_TOKEN_CONTRACT");
        
        IERC721TokenContract _tokenContract = IERC721TokenContract(_token_contract);
        _tokenContract.burnNFTFor(addr,tokenId);
    }
    function updateURIOf(address addr,uint256 token_id,string memory new_uri,bool only_unreveal) external virtual override onlyOwnerAndOperatableTemplate {
        address _token_contract = get_token_contract_address();
        require(_token_contract != address(0),"NO_TOKEN_CONTRACT");
        IERC721TokenContract _tokenContract = IERC721TokenContract(_token_contract);
        require(_tokenContract.isOwnedToken(addr,token_id),"NOT_OWNED_TOKEN");
        require(!only_unreveal || !_tokenContract.isTokenRevealed(token_id),"ALREADY_REVEALED");
        _tokenContract.updateTokenURI(token_id, new_uri);
    }
    function get_driver_token_contract() external view virtual override returns (address){return get_token_contract_address();}
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721InteractionDriver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./ITokenInteractionDriver.sol";

interface IERC721InteractionDriver is ITokenInteractionDriver {
   
    function mintNFTsFor(address addr,uint256 amount) external returns (uint256[] memory);

    function mintNFTFor(address addr,string memory tokenURI) external returns (uint256);

    function burnNFTFor(address addr,uint256 tokenId) external;
    
    function updateURIOf(address addr,uint256 token_id,string memory new_uri,bool only_unreveal) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of use for all of ScrewUp NFT token.
 */
interface IERC721TokenContract {
   
    //Get Contract Level metadata uri - See https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() external view returns (string memory);
    
    //Set Contract Level metadata uri - See https://docs.opensea.io/docs/contract-level-metadata
    function setContractURI(string memory contractURI_) external;

    //Get all of items for address.
    function ownedTokenOf(address _addr) external view returns (uint256[] memory);

    //Get all of items for address.
    function firstOwnedTokenOf(address _addr,uint256 count) external view returns (uint256[] memory,uint256);

    //Check address is really own item.
    function isOwnedToken(address _addr,uint256 tokenId) external view returns(bool);

    //Update token URI for token Id
    function updateTokenURI(uint256 tokenId,string memory tokenURI) external;

    //Mint nft (unreveal only) for some user by contact owner. use for bleeding or mint NFT from App
    function mintNFTsFor(address addr,uint256 amount) external returns (uint256[] memory);

    //Mint nft for some user by contact owner. use for bleeding or mint NFT from App
    function mintNFTFor(address addr,string memory tokenURI) external returns (uint256);

    //Mint nft for some user by contact owner. use for bleeding or mint NFT from App
    function burnNFTFor(address addr,uint256 tokenId) external;

    //Update display name of token when unreveal.
    function getUnrevealName() external view returns (string memory);

    //Update token uri of token when unreveal.
    function getUnrevealTokenUri() external view returns (string memory);

    function getUnrevealMetadata() external view returns (string memory,string memory);    

    function getTokenIds(uint256 page_index,uint256 per_page) external view returns (uint256[] memory);

    function getUnrevealTokenOf(address _addr,uint256 count) external view returns (uint256[] memory);

    function isTokenRevealed(uint256 token_id) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOperatableDriverManagerContract {
    
    function is_cooperative_driver(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenInteractionDriver {
   
    function get_driver_token_contract() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenOperatableTemplate {
    
    function get_template_metadata(uint256 template_id) external view returns (string memory,string memory,uint256,bool,address);

    function is_template_defined(uint256 template_id) external view returns (bool);

    function is_template_enabled(uint256 template_id) external view returns (bool);

    function get_token_contract() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../base/CooperatableBase.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "../Interfaces/IOperatableDriverManagerContract.sol";

contract CooperatableDriver is CooperatableBase 
{
    using ERC165Checker for address;
    
    modifier onlyOwnerAndOperatableTemplate(){
        bool _as_owner = owner() == msg.sender;
        bool _as_driver_manager = msg.sender.supportsInterface(type(IOperatableDriverManagerContract).interfaceId) && IOperatableDriverManagerContract(msg.sender).is_cooperative_driver(address(this)) && is_cooperative_contract(msg.sender);
        require(_as_owner || _as_driver_manager,"NOT_DRIVER_MANAGER");
        _;
    }
}