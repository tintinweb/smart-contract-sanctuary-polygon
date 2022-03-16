/**
 *Submitted for verification at polygonscan.com on 2022-03-16
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/Aggregator.sol
pragma solidity ^0.8.4;


contract Aggregator{
    IERC20 private MANA; // mana address
    address private owner; // contract address
    address private officialWallet; // official address
    uint256 transferFee; // need to divide 10000

    struct NFT{
        string desc;
        uint256 price;
        uint256 lowerBound;
        uint256 upperBound;
        uint256 balance;
        address addr;
    }
    mapping(string => string[]) private NFTGroups; // groupName -> NFT name array
    mapping(string => NFT) private NFTs; // NFT name -> NFT

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address incomeAddress, address manaAddress, uint256 fee) {
        owner = msg.sender;
        officialWallet = incomeAddress;
        MANA = IERC20(manaAddress);
        transferFee = fee;
    }

    function putNFTsIntoGroup(string[] memory nftNames, string memory groupName) public onlyOwner {
        for (uint256 i = 0; i < nftNames.length; i++) {
            NFTGroups[groupName].push(nftNames[i]);
        }
    }

    function deleteNFTFromGroup(string memory nftName, string memory groupName) public onlyOwner {
        uint len = NFTGroups[groupName].length;
        for(uint i = 0; i < len; i++) {
            if(keccak256(abi.encodePacked(NFTGroups[groupName][i])) == keccak256(abi.encodePacked(nftName))) {
                delete NFTGroups[groupName][i];
                if (i != len - 1) {
                    NFTGroups[groupName][i] = NFTGroups[groupName][len - 1];
                    NFTGroups[groupName].pop();
                }
                return;
            }
        }
    }

    function createNFT(
        string memory name, 
        string memory desc, 
        uint256 price, 
        uint256 lowerBound, 
        uint256 upperBound, 
        uint256 balance, 
        address addr) public onlyOwner{
            require(NFTs[name].addr == address(0), "nft already exists");
            NFTs[name] = NFT(desc, price, lowerBound, upperBound, balance, addr);
    }

    function increaseNFT(
        string memory name,
        uint256 increasement) public onlyOwner{
            NFTs[name].balance += increasement;
    }

    function getNFT(string memory name) public view returns (string memory, uint256, uint256, uint256, uint256, address) {
        NFT memory nft = NFTs[name];
        return (nft.desc, nft.price, nft.lowerBound, nft.upperBound, nft.balance, nft.addr);
    }

    function getNFTGroup(string memory groupName) public view returns (string [] memory) {
        return NFTGroups[groupName];
    }

    function buyNFT(address to, string memory nftName) public {
        require(NFTs[nftName].balance > 0, "nft not enough");
        _transferNFT(to, NFTs[nftName]);
        _transferERC20(address(this), officialWallet, NFTs[nftName].price);
        return;
    }

    function buyNFTGroup(address to, string memory groupName) public {
        string[] memory nftgroup = NFTGroups[groupName];
        require(nftgroup.length > 0, "no nft in such nftgroup");
        uint256 sum = 0;
        for(uint i = 0; i < nftgroup.length; i++) {
            require(NFTs[nftgroup[i]].balance > 0, "nft not enough");
            sum += NFTs[nftgroup[i]].price;
        }
        _transferERC20(address(this), officialWallet, sum);
        for(uint i = 0; i < nftgroup.length; i++) {
            _transferNFT(to, NFTs[nftgroup[i]]);
        }
    }

    function transferERC20(address _to, uint256 amt) public onlyOwner {
        require(amt > 0);
        MANA.transfer(_to, amt);
    }

    function _transferERC20(address _to, address _feeTo, uint256 price) internal {
        uint256 fee = price * transferFee / 10000;
        require(fee > 0);
        require(price - fee > 0);
        MANA.transferFrom(msg.sender, _to, price - fee);
        MANA.transferFrom(msg.sender, _feeTo, fee);
    }

    function transferNFT(address to, string memory name, uint256 num) public onlyOwner {
        NFT memory nft = NFTs[name];
        require (nft.addr != address(0), "nft not found");
        require (nft.balance >= num, "nft not enough");
        NFTs[name].balance -= num;
        IERC721Enumerable nftContract = IERC721Enumerable(nft.addr);
        uint256 total = nftContract.balanceOf(address(this));
        for(uint i = 0; i < total; i++) {
            uint256 tokenId = nftContract.tokenOfOwnerByIndex(address(this), i);
            if (tokenId <= nft.upperBound && tokenId >= nft.lowerBound) {
                nftContract.transferFrom(address(this), to, tokenId);
                i--;
                total--;
                num--;
                if(num == 0) {
                    return;
                }
            }
        }
    }

    function _transferNFT(address to, NFT storage nft) internal {
        IERC721Enumerable nftContract = IERC721Enumerable(nft.addr);
        uint256 total = nftContract.balanceOf(address(this));
        for(uint i = 0; i < total; i++) {
            uint256 tokenId = nftContract.tokenOfOwnerByIndex(address(this), i);
            if (tokenId <= nft.upperBound && tokenId >= nft.lowerBound) {
                nft.balance -= 1;
                nftContract.transferFrom(address(this), to, tokenId);
                return;
            }
        }
        revert("nft not found");
    }
}