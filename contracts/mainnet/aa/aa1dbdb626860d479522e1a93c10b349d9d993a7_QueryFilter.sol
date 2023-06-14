/**
 *Submitted for verification at polygonscan.com on 2023-06-14
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

//
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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


// File contracts/did/interfaces/IHashDB.sol

//
pragma solidity ^0.8.9;

interface IPushItemSingle {
    function pushElement(bytes32 itemKey, bytes memory itemValue) external;
}

interface IRemoveElement {
    function removeElement(bytes32 itemKey) external;
}

interface IItemArray {
    function itemArrayLength(bytes32 itemKey) external view returns (uint256);

    function itemArraySlice(bytes32 itemKey, uint256 start, uint256 end) external view returns (bytes[] memory);
}

interface IGetElement {
    function getElement(bytes32 itemKey, uint256 idx) external view returns (bytes memory);
}

interface IGetFirstElement {
    function getFirstElement(bytes32 itemKey) external view returns (bytes memory);
}

interface IRemoveItemArray {
    function removeItemArray(bytes32 itemKey) external;
}

interface IReplaceItemArray {
    function replaceItemArray(bytes32 itemKey, bytes[] memory itemArray) external;
}

interface IReplaceItemArrayWithElement {
    function replaceItemArray(bytes32 itemKey, bytes memory itemValue) external;
}


// File contracts/did/interfaces/IDB.sol

//

pragma solidity ^0.8.9;

interface ISetReverse {
    function setReverse(address owner, bytes32 node) external;
}

interface INodeStatus {
    function isNodeActive(bytes32 node) external view returns (bool);
    function isNodeExisted(bytes32 node) external view returns (bool);
}

interface IActivate {
    function activate(bytes32 parent, address owner, uint64 expire, string memory name, bytes memory _data)
        external
        returns (bytes32);
}

interface IDeactivate {
    function deactivate(bytes32 node) external;
}

interface NodeStruct {
    struct Node {
        bytes32 parent;
        address owner;
        uint64 expire;
        uint64 transfer;
        string name;
    }
}

interface INodeRecord is NodeStruct {
    function getNodeRecord(bytes32 node) external view returns (Node memory);
}

interface IIsNodeActive {
    function isNodeActive(bytes32 node) external view returns (bool);
}

interface IOwnerOf {
    function ownerOf(uint256 tokenId) external view returns (address);
}


// File contracts/did/lib/Parser.sol

//

pragma solidity ^0.8.9;

library Parser {
    function encodeNameToNode(bytes32 parent, string memory name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(parent, keccak256(abi.encodePacked(name))));
    }

    // !!! keyHash must be a hash value, but keySub might be converted from a unit256 number directly !!!
    function encodeToKey(bytes32 node, address owner, bytes32 keyHash, bytes32 keySub)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(node, owner, keyHash, keySub));
    }

    function abiBytesToAddressTime(bytes memory bys) internal pure returns (address addr, uint64 time) {
        uint256 num = abiBytesToUint256(bys);
        addr = address(uint160(num >> 96));
        time = uint64(num & type(uint96).max);
    }

    //
    //    function abiBytesToAddress(bytes memory bys) internal pure returns (address ret) {
    //        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
    //        if (bys.length == 32) {
    //            ret = abi.decode(bys, (address));
    //        }
    //        return ret;
    //    }
    //
    //    function abiBytesToUint64(bytes memory bys) internal pure returns (uint64 ret) {
    //        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
    //        if (bys.length == 32) {
    //            ret = abi.decode(bys, (uint64));
    //        }
    //        return ret;
    //    }
    //
    function abiBytesToUint256(bytes memory bys) internal pure returns (uint256 ret) {
        require(bys.length == 32 || bys.length == 0, "Data bytes can not be decoded");
        if (bys.length == 32) {
            ret = abi.decode(bys, (uint256));
        }
        return ret;
    }
    //
    //    function abiBytesToString(bytes memory bys) internal pure returns (string memory ret) {
    //        if (bys.length > 0) {
    //            ret = abi.decode(bys, (string));
    //        }
    //        return ret;
    //    }
    //

    function abiBytesCutToAddress(bytes memory bys) internal pure returns (address addr) {
        uint256 num = abiBytesToUint256(bys);
        addr = address(uint160(num >> 96));
    }
}


// File contracts/aggregator/QueryFilter.sol

//



pragma solidity ^0.8.9;

interface INodeOwnerItem {
    function getNodeOwnerItem(bytes32 node, address owner, bytes32 item_key) external view returns (bytes memory);
}

interface IReverseRecord {
    function reverseRecord(address main_address) external view returns (bytes32);
}

interface IMultiCall {
    function DB() external view returns (address);
    function BUFFER() external view returns (address);
}

contract QueryFilter {
    address public multiCall;
    address public admin;
    address public DB;
    address public BUFFER;

    event AdminUpdated(address _admin);
    event MultiCallUpdated(address _multiCall);

    constructor(address _multiCall) {
        admin = msg.sender;
        multiCall = _multiCall;
        DB = IMultiCall(multiCall).DB();
        BUFFER = IMultiCall(multiCall).BUFFER();
    }

    function setAdmin(address _admin) public {
        require(msg.sender == admin, "Not Granted");
        require(_admin != admin && _admin != address(0), "Args error");

        admin = _admin;
        emit AdminUpdated(_admin);
    }

    function setMultiCall(address _multiCall) public {
        require(msg.sender == admin, "Not Granted");
        require(_multiCall != multiCall && _multiCall != address(0), "Args error");

        multiCall = _multiCall;
        DB = IMultiCall(multiCall).DB();
        BUFFER = IMultiCall(multiCall).BUFFER();
        emit MultiCallUpdated(_multiCall);
    }

    function filterBUF(string[] memory names, string memory suffix) external view returns (string[] memory invalid) {
        IERC721 DID = IERC721(DB);
        IERC721 BUF = IERC721(BUFFER);
        bytes32 tld = Parser.encodeNameToNode(bytes32(0), suffix);

        for (uint256 i = 0; i < names.length; i++) {
            uint256 node = uint256(Parser.encodeNameToNode(tld, names[i]));
            if (DID.ownerOf(node) == address(0) && BUF.ownerOf(node) == address(0)) {
                names[i] = "";
            }
        }
        invalid = names;
    }

    function filterDID(string[] memory names, string memory suffix) external view returns (string[] memory invalid) {
        IERC721 DID = IERC721(DB);
        bytes32 tld = Parser.encodeNameToNode(bytes32(0), suffix);

        for (uint256 i = 0; i < names.length; i++) {
            uint256 node = uint256(Parser.encodeNameToNode(tld, names[i]));
            if (DID.ownerOf(node) == address(0)) {
                names[i] = "";
            }
        }
        invalid = names;
    }
}