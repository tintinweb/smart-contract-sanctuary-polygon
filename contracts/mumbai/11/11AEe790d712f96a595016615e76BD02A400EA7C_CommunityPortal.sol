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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
import {ICommunityPassport} from "./Interface/ICommunityPassport.sol";
import {ICommunityPassportCreater} from "./Interface/ICommunityPassportCreater.sol";
import {ICommunityPortal} from "./ICommunityPortal.sol";

contract CommunityPortal is Ownable, ICommunityPortal {
    ICommunityPortal.Community[] private _communityList;
    ICommunityPassportCreater public passportCreater;
    address public questBoard;

    constructor(address _passportCreater, address _questBoard) {
        passportCreater = ICommunityPassportCreater(_passportCreater);
        questBoard = _questBoard;
    }

    function getCommunity(
        uint32 communityId
    )
        external
        view
        returns (string memory communityURI, address passport, bool closed)
    {
        communityURI = _communityList[communityId].communityURI;
        passport = _communityList[communityId].passport;
        closed = _communityList[communityId].closed;
    }

    function getCommunityList(
        uint256 page,
        uint256 pageSize
    ) external view returns (ICommunityPortal.Community[] memory, uint256) {
        require(pageSize > 0, "page size must be positive");
        uint256 actualSize = pageSize;
        if ((page + 1) * pageSize > _communityList.length) {
            actualSize = _communityList.length;
        }
        ICommunityPortal.Community[]
            memory res = new ICommunityPortal.Community[](actualSize);
        for (uint256 i = 0; i < actualSize; i++) {
            res[i] = _communityList[page * pageSize + i];
        }
        return (res, _communityList.length);
    }

    function setPassportCreater(address _passportCreater) external onlyOwner {
        address oldState = address(passportCreater);
        passportCreater = ICommunityPassportCreater(_passportCreater);
        emit SetPassportCreater(msg.sender, oldState, _passportCreater);
    }

    function setCommunityURI(
        uint32 communityId,
        string memory newCommunityURI
    ) external onlyOwner {
        string memory oldCommunityURI = _communityList[communityId]
            .communityURI;
        _communityList[communityId].communityURI = newCommunityURI;
        emit SetCommunityURI(communityId, oldCommunityURI, newCommunityURI);
    }

    function setQuestBoard(address _questBoard) external onlyOwner {
        questBoard = _questBoard;
    }

    function createCommunity(
        string memory _communityURI,
        string memory _name,
        string memory _contructURI
    ) external onlyOwner {
        ICommunityPortal.Community memory community;
        community.passport = passportCreater.createCommunityPassport(
            _name,
            _communityURI,
            _contructURI,
            uint32(_communityList.length)
        );
        community.communityURI = _communityURI;
        _communityList.push(community);
        emit Create(
            address(this),
            uint32(_communityList.length - 1),
            community.passport,
            community.communityURI
        );
    }

    function communitySupply() external view returns (uint256) {
        return _communityList.length;
    }

    function addExp(uint32 communityId, address fan, uint32 exp) external {
        require(msg.sender == questBoard, "You cannot run addExp");
        ICommunityPassport passport = ICommunityPassport(
            _communityList[communityId].passport
        );
        passport.addExp(fan, exp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICommunityPortal {
    struct Community {
        string communityURI;
        address passport;
        bool closed;
    }

    event SetPassportCreater(
        address indexed publisher,
        address oldState,
        address newState
    );

    event SetCommunityURI(
        uint32 indexed communityId,
        string oldState,
        string newState
    );

    event Create(
        address indexed publisher,
        uint32 communityId,
        address communityPassport,
        string communityURI
    );

    function getCommunity(
        uint32 communityId
    )
        external
        view
        returns (
            string memory communityURI,
            address communityPassport,
            bool closed
        );

    function getCommunityList(
        uint256 page,
        uint256 pageSize
    ) external view returns (Community[] memory, uint256);

    function setPassportCreater(address _passportCreater) external;

    function setCommunityURI(
        uint32 communityId,
        string memory newCommunityURI
    ) external;

    function setQuestBoard(address _questBoard) external;

    function createCommunity(
        string memory _communityURI,
        string memory _name,
        string memory _contructURI
    ) external;

    function communitySupply() external view returns (uint256);

    function addExp(uint32 communityId, address fan, uint32 exp) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICommunityPassport is IERC721 {
    struct Passport {
        string passportURI;
        address user;
        uint32 exp;
    }

    event AddExp(
        address indexed publisher,
        address indexed user,
        uint256 passportId,
        uint32 oldExp,
        uint32 newExp
    );

    event SetBaseURI(
        address indexed publisher,
        string oldValue,
        string newValue
    );

    event SetContractURI(
        address indexed publisher,
        string oldValue,
        string newValue
    );

    function getPassport(address user) external view returns (Passport memory);

    function getFanList(
        uint256 page,
        uint256 pageSize
    ) external view returns (address[] memory, uint256);

    function getPassportList(
        uint256 page,
        uint256 pageSize
    ) external view returns (ICommunityPassport.Passport[] memory, uint256);

    function getTokenURIFromAddress(
        address user
    ) external view returns (string memory);

    function setBaseURI(string memory newBaseTokenURI) external;

    function setContractURI(string memory newContractURI) external;

    function hashMsgSender(address addr) external pure returns (uint256);

    function safeMint() external;

    function burn() external;

    function contractURI() external view returns (string memory);

    function checkBatchFan(
        address[] memory userList
    ) external view returns (bool[] memory);

    function totalSupply() external view returns (uint256);

    function addExp(address user, uint32 exp) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICommunityPassportCreater {
    function createCommunityPassport(
        string memory _name,
        string memory _communityURI,
        string memory _contructURI,
        uint32 communityId
    ) external returns (address);
}