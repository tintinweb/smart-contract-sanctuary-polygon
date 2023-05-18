/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


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

// File: NftMarketPlace.sol



pragma solidity 0.8.17;


contract MyMarketPlace {
    uint nftHolders;
    uint nftSources;
    uint totalAvailableNFTs = 0;

    struct tokenInfo {
        uint id;
        address owner;
        uint price;
        address NFTSource;
        bool isListed;
        bool availableForAuction;
    }

    mapping(address => mapping(uint => bool)) isListed;
    mapping(address => tokenInfo[]) listedNFTs;

    mapping(uint => address) allOwners;
    mapping(address => bool) isNewOwner;

    mapping(uint => address) allNFTsources;
    mapping(address => bool) isNewNFTsource;

    function isNFTlisted(
        uint tokenID,
        address _NFTaddress
    ) public view returns (bool) {
        require(isListed[_NFTaddress][tokenID] == true, "Token Not Exists");
        return true;
    }

    function listNFT(uint tokenID, uint _price, address _NFTaddress) public {
        require(
            IERC721(_NFTaddress).ownerOf(tokenID) == msg.sender,
            "Invalid User"
        );
        require(isListed[_NFTaddress][tokenID] == false, "Already Minted");

        listedNFTs[msg.sender].push(
            tokenInfo(tokenID, msg.sender, _price, _NFTaddress, true, false)
        );
        isListed[_NFTaddress][tokenID] = true;
        totalAvailableNFTs++;

        if (!isNewOwner[msg.sender]) {
            allOwners[nftHolders] = msg.sender;
            isNewOwner[msg.sender] = true;
            nftHolders++;
        }

        if (!isNewNFTsource[_NFTaddress]) {
            allNFTsources[nftSources] = msg.sender;
            isNewNFTsource[_NFTaddress] = true;
            nftSources++;
        }
    }

    function isListedForAuction(
        uint tokenID,
        address _NFTaddress,
        address _tokenOwner
    ) public view returns (bool) {
        tokenInfo[] memory tempList = listedNFTs[_tokenOwner];

        for (uint i = 0; i < tempList.length; i++) {
            if (
                tempList[i].NFTSource == _NFTaddress &&
                tempList[i].availableForAuction == true &&
                tempList[i].id == tokenID
            ) {
                return true;
            }
        }
        return false;
    }

    function changeListedForAuctionStatus(
        uint tokenID,
        address _NFTaddress,
        address _tokenOwner,
        bool status
    ) public returns (bool) {
        tokenInfo[] storage tempList = listedNFTs[_tokenOwner];

        for (uint i = 0; i < tempList.length; i++) {
            // if(tempList[i].availableForAuction == false){

            if (
                tempList[i].NFTSource == _NFTaddress &&
                tempList[i].id == tokenID
            ) {
                tempList[i].availableForAuction = status;

                return true;
            }
            // }
        }
        return false;
    }

    function buyNFT(
        uint tokenID,
        address _NFTaddress,
        address _tokenOwner
    ) public payable {
        require(isListed[_NFTaddress][tokenID] == true, "Token Not Exists");
        require(
            msg.sender != IERC721(_NFTaddress).ownerOf(tokenID),
            "User should Not be the Owner"
        );
        require(
            _tokenOwner == IERC721(_NFTaddress).ownerOf(tokenID),
            "tokenOwner must be the token owner"
        );

        tokenInfo[] storage tempList = listedNFTs[_tokenOwner];

        for (uint i = 0; i < tempList.length; i++) {
            if (tempList[i].availableForAuction == true) {
                revert("Currently Listed for Auction");
            }

            if (
                tempList[i].NFTSource == _NFTaddress &&
                tempList[i].id == tokenID
            ) {
                require(msg.value >= tempList[i].price, "Low Value Pass");
                isListed[_NFTaddress][tokenID] = false;
                break;
            }
        }

        IERC721(_NFTaddress).transferFrom(
            IERC721(_NFTaddress).ownerOf(tokenID),
            msg.sender,
            tokenID
        );
        payable(IERC721(_NFTaddress).ownerOf(tokenID)).transfer(msg.value);

        unlistgiven(_NFTaddress, tokenID);
    }

    function updatePriceOfNFT(
        uint tokenID,
        uint _price,
        address _NFTaddress
    ) public {
        require(isNewOwner[msg.sender], "Invalid user");
        require(isListed[_NFTaddress][tokenID] == true, "Token Not Exists");
        require(
            IERC721(_NFTaddress).ownerOf(tokenID) == msg.sender,
            "Invalid User"
        );

        tokenInfo[] storage tempList = listedNFTs[msg.sender];

        for (uint i = 0; i < tempList.length; i++) {
            if (
                tempList[i].NFTSource == _NFTaddress &&
                tempList[i].id == tokenID
            ) {
                tempList[i].price = _price;
                break;
            }
        }
    }

    function unlistNFT(uint tokenId, address _NFTaddress) public {
        require(isNewOwner[msg.sender], "Invalid user");
        require(
            IERC721(_NFTaddress).ownerOf(tokenId) == msg.sender,
            "Invalid User"
        );
        require(isListed[_NFTaddress][tokenId] == true, "not Listed");

        tokenInfo[] storage tempList = listedNFTs[msg.sender];

        for (uint i = 0; i < tempList.length; i++) {
            if (
                tempList[i].NFTSource == _NFTaddress &&
                tempList[i].id == tokenId
            ) tempList[i].isListed = false;
            isListed[_NFTaddress][tokenId] = false;
        }

        unlistgiven(_NFTaddress, tokenId);
    }

    function unlistgiven(address _NFTaddress, uint tokenId) public {
        tokenInfo[] storage tempList = listedNFTs[msg.sender];

        for (uint i = 0; i < tempList.length; i++) {
            if (
                tempList[i].isListed == false &&
                isListed[_NFTaddress][tokenId] == false
            ) {
                tempList[i] = tempList[tempList.length - 1];
                tempList.pop();
                totalAvailableNFTs--;
                break;
            }
        }
    }

    function nftListOfUser(
        address _address
    ) public view returns (tokenInfo[] memory) {
        uint x = 0;
        for (uint i = 0; i < nftHolders; i++) {
            tokenInfo[] memory tempList = listedNFTs[allOwners[i]];

            for (uint j = 0; j < tempList.length; j++) {
                if (
                    tempList[j].owner == _address &&
                    tempList[j].isListed == true
                ) {
                    x++;
                }
            }
        }

        uint y;
        tokenInfo[] memory IsTemp = new tokenInfo[](x);

        for (uint i = 0; i < nftHolders; i++) {
            tokenInfo[] memory tempList = listedNFTs[allOwners[i]];

            for (uint j = 0; j < tempList.length; j++) {
                if (
                    tempList[j].owner == _address &&
                    tempList[j].isListed == true
                ) {
                    IsTemp[y] = tempList[j];
                    y++;
                }
            }
        }
        return IsTemp;
    }

    function listAllAvailableNFTs() public view returns (tokenInfo[] memory) {
        tokenInfo[] memory IsTemp = new tokenInfo[](totalAvailableNFTs);
        uint x = 0;
        for (uint i = 0; i < nftHolders; i++) {
            tokenInfo[] memory tempList = listedNFTs[allOwners[i]];
            for (uint j = 0; j < listedNFTs[allOwners[i]].length; j++) {
                IsTemp[x] = tempList[j];
                x++;
            }
        }
        return IsTemp;
    }

    function listAllofNFTsource(
        address _NFTaddress
    ) public view returns (tokenInfo[] memory) {
        uint x = 0;
        for (uint i = 0; i < nftHolders; i++) {
            tokenInfo[] memory tempList = listedNFTs[allOwners[i]];

            for (uint j = 0; j < tempList.length; j++) {
                if (
                    tempList[j].NFTSource == _NFTaddress &&
                    tempList[j].isListed == true
                ) {
                    x++;
                }
            }
        }

        uint y;
        tokenInfo[] memory IsTemp = new tokenInfo[](x);

        for (uint i = 0; i < nftHolders; i++) {
            tokenInfo[] memory tempList = listedNFTs[allOwners[i]];

            for (uint j = 0; j < tempList.length; j++) {
                if (
                    tempList[j].NFTSource == _NFTaddress &&
                    tempList[j].isListed == true
                ) {
                    IsTemp[y] = tempList[j];
                    y++;
                }
            }
        }
        return IsTemp;
    }
}