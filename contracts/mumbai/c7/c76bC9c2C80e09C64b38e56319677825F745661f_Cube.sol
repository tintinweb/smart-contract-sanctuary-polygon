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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ICube} from "./ICube.sol";
import {IPrizePoap} from "./PrizePoap/IPrizePoap.sol";

contract Cube is ICube, Ownable {
    uint256 public constant MAX_SIZE = 10;
    IPrizePoap public prizePoap;
    mapping(address => ICube.CubeObj[MAX_SIZE][MAX_SIZE]) private _cubes;
    mapping(address => mapping(uint256 => ICube.PrizeInfo)) private _prizeInfo;

    constructor(address prizePoapAddress) {
        prizePoap = IPrizePoap(prizePoapAddress);
    }

    modifier checkCubeObj(ICube.CubeObj memory cubeObj) {
        require(
            cubeObj.positionX < MAX_SIZE &&
                cubeObj.positionY < MAX_SIZE &&
                cubeObj.positionZ < MAX_SIZE,
            "checkCubeObj: Out of range positionXYZ"
        );
        require(
            cubeObj.rotationX <= 360 &&
                cubeObj.rotationY <= 360 &&
                cubeObj.rotationZ <= 360,
            "checkCubeObj: Out of range rotationXYZ"
        );
        require(cubeObj.set, "checkCubeObj: Invalid set");
        _;
    }

    function getCube(
        address userAddress
    ) external view returns (ICube.CubeObj[MAX_SIZE][MAX_SIZE] memory cubeObj) {
        return _cubes[userAddress];
    }

    function getCubeObj(
        address userAddress,
        uint256 x,
        uint256 z
    ) external view returns (ICube.CubeObj memory) {
        return _cubes[userAddress][z][x];
    }

    function setCubeObj(
        uint256 x,
        uint256 z,
        ICube.CubeObj memory cubeObj
    ) public checkCubeObj(cubeObj) {
        require(x < MAX_SIZE && z < MAX_SIZE, "setCubeObj: Out of range");

        uint32 prizeId = cubeObj.prizeId;
        require(
            prizePoap.balanceOf(msg.sender, prizeId) > 0,
            "lack of prizeNum"
        );

        uint256 updatedPrizeId = cubeObj.prizeId;
        if (_prizeInfo[msg.sender][updatedPrizeId].usedNum > 0)
            delete _prizeInfo[msg.sender][updatedPrizeId];

        if (_cubes[msg.sender][z][x].set) {
            updatedPrizeId = _cubes[msg.sender][z][x].prizeId;
            if (_prizeInfo[msg.sender][updatedPrizeId].usedNum > 0)
                delete _prizeInfo[msg.sender][updatedPrizeId];
        }

        _prizeInfo[msg.sender][prizeId].usedNum++;
        _prizeInfo[msg.sender][prizeId].positionX = cubeObj.positionX;
        _prizeInfo[msg.sender][prizeId].positionY = cubeObj.positionY;
        _prizeInfo[msg.sender][prizeId].positionZ = cubeObj.positionZ;

        _cubes[msg.sender][z][x] = cubeObj;
    }

    function setBatchCubeObj(
        uint256[] memory xList,
        uint256[] memory zList,
        ICube.CubeObj[] memory cubeObjList
    ) external {
        require(
            xList.length == zList.length &&
                xList.length == cubeObjList.length &&
                zList.length == cubeObjList.length,
            "Length mismatch"
        );
        for (uint256 i; i < xList.length; i++) {
            setCubeObj(xList[i], zList[i], cubeObjList[i]);
        }
    }

    function setPrizePoap(address prizePoapAddress) external onlyOwner {
        prizePoap = IPrizePoap(prizePoapAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICube {
    struct CubeObj {
        uint32 prizeId;
        uint8 positionX;
        uint8 positionY;
        uint8 positionZ;
        uint8 rotationX;
        uint8 rotationY;
        uint8 rotationZ;
        bool set;
    }

    struct PrizeInfo {
        uint32 usedNum;
        uint8 positionX;
        uint8 positionY;
        uint8 positionZ;
    }

    function getCube(
        address userAddress
    ) external view returns (CubeObj[10][10] memory cubeObj);

    function getCubeObj(
        address userAddress,
        uint256 x,
        uint256 z
    ) external view returns (CubeObj memory);

    function setCubeObj(uint256 x, uint256 z, CubeObj memory cubeObj) external;

    function setBatchCubeObj(
        uint256[] memory xList,
        uint256[] memory zList,
        CubeObj[] memory cubeObjList
    ) external;

    function setPrizePoap(address prizePoapAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IPrizePoap is IERC1155 {
    struct Prize {
        string tokenURI;
        uint32 requiredExp;
        uint32 communityId;
        bool closed;
    }

    event SetTokenURI(
        address indexed publisher,
        uint256 indexed tokenId,
        string oldState,
        string newState
    );

    event SetkBatchTokenURI(
        address indexed publisher,
        uint256[] tokenIds,
        string[] oldState,
        string[] newState
    );

    event SetRequiredExp(
        address indexed publisher,
        uint256 indexed tokenId,
        uint32 oldState,
        uint32 newState
    );

    event SetClosed(
        address indexed publisher,
        uint256 indexed tokenId,
        bool oldState,
        bool newState
    );

    event Created(
        address indexed publisher,
        string tokenURI,
        uint32 requiredExp,
        uint32 indexed communityId,
        bool closed
    );

    function getBaseURI() external view returns (string memory prize);

    function getPrize(
        uint256 tokenId
    ) external view returns (IPrizePoap.Prize memory prize);

    function getPrizeList(
        uint256 page,
        uint256 pageSize
    ) external view returns (IPrizePoap.Prize[] memory, uint256);

    function getPrizeListLength() external view returns (uint256 length);

    function setCommunityPortal(address _communityPortal) external;

    function setBaseURI(string memory _baseURL) external;

    function setTokenURI(uint256 tokenId, string calldata _tokenURI) external;

    function setkBatchTokenURI(
        uint256[] memory tokenIds,
        string[] memory tokenURIs
    ) external;

    function setRequiredExp(uint256 tokenId, uint32 _requiredExp) external;

    function setCommunityId(uint256 tokenId, uint32 _communityId) external;

    function setClosed(uint256 tokenId, bool _closed) external;

    function create(
        string calldata _tokenURI,
        uint32 _requiredExp,
        uint32 _communityId
    ) external;

    function mint(uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    function checkObtainable(
        address target,
        uint256 tokenId
    ) external view returns (bool);

    function checkBatchObtainable(
        address[] memory targets,
        uint256[] memory tokenIds
    ) external view returns (bool[] memory);

    function checkObtained(
        address target,
        uint256 tokenId
    ) external view returns (bool);

    function checkBatchObtained(
        address[] memory targets,
        uint256[] memory tokenIds
    ) external view returns (bool[] memory);
}