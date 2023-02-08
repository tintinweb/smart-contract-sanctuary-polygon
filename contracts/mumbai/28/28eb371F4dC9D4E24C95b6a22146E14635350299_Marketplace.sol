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
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IAgreementNFT is IERC721 {
    function createAgreement(
        address farmerAddr,
        string memory _tokenURI
    ) external returns (uint256);

    function closeAgreement(address _buyerAddr, uint256 _agreementId) external;
    
    function updateAgreement(uint256 agreementNFTId, string memory agreementIPFSUrl) external;
}

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IAgreementNFT.sol";

contract Marketplace is Ownable {
    event Sell(
        uint256 indexed farmNFTId,
        uint256 indexed price,
        uint256 agreementNFTId
    );
    event ClosedContractNFT(uint256 indexed farmNFTId);
    event Buy(
        address indexed buyer,
        uint256 indexed farmNFTId,
        uint256 agreementNFTId,
        string updatedTokenURI
    );

    struct AgreementInfo {
        uint256 farmNFTId;
        uint256 price;
        uint256 agreementNftId;
        uint256 startDate;
        uint256 endDate;
        address buyer;
        address farmerAddr;
        string razorTransId;
        bool isClosedContract;
    }
    // Mapping from agreementNFTId to AgreementInfo struct
    mapping(uint256 => AgreementInfo) public agreementDetails;

    // Mapping from buyer address to buy contractNFT list
    mapping(address => uint256[]) private agreementList;

    IERC721 private immutable farmNFT;
    IAgreementNFT private immutable agreementNFT;

    constructor(address farmNFT_, address agreementNFT_) {
        require(
            farmNFT_ != address(0) && agreementNFT_ != address(0),
            "Zero Address"
        );
        farmNFT = IERC721(farmNFT_);
        agreementNFT = IAgreementNFT(agreementNFT_);
    }
    
    /**
    @dev put contract NFT on sell & call createAgreement() to create Contract NFT
    * Requirements:
    * - `price_` must be greater than 0
    - `startDate_` must be greater than current timestamp
    - `endDate_` must be greater than startDate_
    Emits a {Sell} event.
    */
    function putContractOnSell(
        address farmerAddr_,
        uint256 farmNFTId_,
        uint256 price_,
        uint256 startDate_,
        uint256 endDate_,
        string memory agreementNftUri_
    ) external onlyOwner {
        require(price_ != 0, "Invalid price");
        // require(
        //     block.timestamp <= startDate_,
        //     "startDate less than current time"
        // );
        require(startDate_ < endDate_, "end date should be less");

        uint256 agreementNftId_ = IAgreementNFT(agreementNFT).createAgreement(
            msg.sender,
            agreementNftUri_
        );

        agreementDetails[agreementNftId_].farmNFTId = farmNFTId_;
        agreementDetails[agreementNftId_].farmerAddr = farmerAddr_;
        agreementDetails[agreementNftId_].price = price_;
        agreementDetails[agreementNftId_].startDate = startDate_;
        agreementDetails[agreementNftId_].endDate = endDate_;

        agreementDetails[agreementNftId_].agreementNftId = agreementNftId_;

        emit Sell(farmNFTId_, price_, agreementNftId_);
    }

    /**
    @dev to buy contract NFT
    @param agreementNftId_ array of contract NFT id
    @param transactionId array of razorpay transaction id
    Requirements:
    -`agreementNftId_ & transactionId` length of array must be equal
    -`msg.sender` must not be equal to farmerAddr & owner
     */

    function buyContract(
        uint256[] memory agreementNftId_,
        string memory transactionId,
        string[] memory updateTokenURI
    ) external {
        require(
            agreementNftId_.length == updateTokenURI.length,
            "Array length not same"
        );
        uint256 arrayLength = agreementNftId_.length;

        for (uint256 i = 0; i < arrayLength; ) {
            require(
                msg.sender != agreementDetails[agreementNftId_[i]].farmerAddr &&
                    msg.sender != owner(),
                "Owner can't buy"
            );
            require(
                agreementDetails[agreementNftId_[i]].agreementNftId != 0,
                "Not on sale"
            );

            agreementList[msg.sender].push(agreementNftId_[i]);
            agreementDetails[agreementNftId_[i]].buyer = msg.sender;
            agreementDetails[agreementNftId_[i]].razorTransId = transactionId;

            IAgreementNFT(agreementNFT).updateAgreement(agreementNftId_[i], updateTokenURI[i]);
            emit Buy(
                msg.sender,
                agreementDetails[agreementNftId_[i]].farmNFTId,
                agreementNftId_[i],
                updateTokenURI[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
    @dev to closed contract NFT
    @param agreementNftId_ contract NFT id
    Requirements:
    -`isClosedContract` to check whether contract NFT is on sale or not.
    -`buyer` msg.sender must equal to buyer address
    Emits a {ClosedContractNFT} event.
     */

    function soldContractNFT(uint256 agreementNftId_) external {
        require(
            !(agreementDetails[agreementNftId_].isClosedContract),
            "Not on sale"
        );
        // require(
        //     msg.sender == agreementDetails[agreementNftId_].buyer,
        //     "Only Buyer"
        // );

       agreementDetails[agreementNftId_].isClosedContract = true;

        emit ClosedContractNFT(agreementNftId_);
    }

    /**
    @dev to get sell detail
    @param agreementNFTId array of contract NFT Id
    - returns a agreement data.
     */

    function getSellDetailByTokenId(
        uint256[] calldata agreementNFTId
    ) external view returns (AgreementInfo[] memory) {
        AgreementInfo[] memory agreementData = new AgreementInfo[](
            agreementNFTId.length
        );
        for (uint256 i = 0; i < agreementNFTId.length; i++) {
            agreementData[i] = agreementDetails[agreementNFTId[i]];
        }
        return agreementData;
    }

    /**
    @dev to get all active contract list of particular buyer
    @param _buyerAddr buyer address
    - returns all array of contract list of buyer
     */
    function getAcceptedContractList(
        address _buyerAddr
    ) external view returns (uint256[] memory) {
        return agreementList[_buyerAddr];
    }
}