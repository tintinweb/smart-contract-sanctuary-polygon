/**
 *Submitted for verification at polygonscan.com on 2023-04-16
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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/PERNFTSale.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;





pragma solidity ^0.8.0;

contract PERNFTSale is IERC721Receiver, Ownable {
    uint256 private nonce = 0;
    uint256 private nextSaleId;

    struct PrivateSaleAddress {
        uint limitAmount;
        uint exchangedCount;
        bool isValid;
    }

    struct SaleSchedule {
        string saleId;
        address nftHolder;
        address nftContract;
        address currencyTokenContract; // Add currencyTokenContract field
        uint256 startDate;
        uint256 endDate;
        uint256 price;
        uint256 totalAmount;
        uint256 limitAmountPerWallet;
        uint256 exchangedCount;
        uint256 collectedAmount;
        bool isPrivate;
        bool isValid;
        mapping(address => PrivateSaleAddress) privateSaleAdresses;
    }

    struct SaleScheduleConstants {
        string saleId;
        address nftHolder;
        address nftContract;
        address currencyTokenContract; // Add currencyTokenContract field
        uint256 startDate;
        uint256 endDate;
        uint256 price;
        uint256 totalAmount;
        uint256 limitAmountPerWallet;
        bool isPrivate;
    }

    struct SaleScheduleInfo {
        string saleId;
        uint256 startDate;
        uint256 endDate;
        uint256 price;
        uint256 totalAmount;
        uint256 exchangedCount;
        uint256 collectedAmount;
        bool isPrivate;
        bool isValid;
    }

    mapping(string => SaleSchedule) private saleSchedules;

    event SaleScheduleAdded(string indexed saleId);
    event PrivateSaleAddressAdded(
        address indexed buyer,
        uint256 indexed limitAmount,
        string indexed saleId
    );

    event NFTExchanged(
        string indexed saleId,
        address indexed buyer,
        uint256 indexed tokenId,
        address currencyTokenContract,
        uint256 price
    );

    function addSaleSchedule(
        string calldata saleId,
        address nftHolder,
        address nftContract,
        address currencyTokenContract, // Add currencyTokenContract parameter
        uint256 startDate,
        uint256 endDate,
        uint256 price,
        uint256 totalAmount,
        uint256 limitAmountPerWallet,
        bool isPrivate
    ) external onlyOwner {
        require(
            saleSchedules[saleId].isValid == false,
            "Sale schedule already exists"
        );
        
        saleSchedules[saleId].saleId = saleId;
        saleSchedules[saleId].nftHolder = nftHolder;
        saleSchedules[saleId].nftContract = nftContract;
        saleSchedules[saleId].currencyTokenContract = currencyTokenContract; // Store currencyTokenContract
        saleSchedules[saleId].startDate = startDate;
        saleSchedules[saleId].endDate = endDate;
        saleSchedules[saleId].price = price;
        saleSchedules[saleId].totalAmount = totalAmount;
        saleSchedules[saleId].limitAmountPerWallet = limitAmountPerWallet;
        saleSchedules[saleId].isPrivate = isPrivate;
        saleSchedules[saleId].isValid = true;

        emit SaleScheduleAdded(saleId);
    }

    function getSaleScheduleConsts(
        string calldata saleId
    )
        external
        view
        returns (SaleScheduleConstants memory)
    {
        require(
            saleSchedules[saleId].isValid == true,
            "Sale schedule does not exist"
        );
        return
            SaleScheduleConstants(
                saleSchedules[saleId].saleId,
                saleSchedules[saleId].nftHolder,
                saleSchedules[saleId].nftContract,
                saleSchedules[saleId].currencyTokenContract, // Add currencyTokenContract field
                saleSchedules[saleId].startDate,
                saleSchedules[saleId].endDate,
                saleSchedules[saleId].price,
                saleSchedules[saleId].totalAmount,
                saleSchedules[saleId].limitAmountPerWallet,
                saleSchedules[saleId].isPrivate
            );
    }

    function getSaleScheduleInfo(
        string calldata saleId
    )
        external
        view
        returns (SaleScheduleInfo memory)
    {
        require(
            saleSchedules[saleId].isValid == true,
            "Sale schedule does not exist"
        );

        return
            SaleScheduleInfo(
                saleSchedules[saleId].saleId,
                saleSchedules[saleId].startDate,
                saleSchedules[saleId].endDate,
                saleSchedules[saleId].price,
                saleSchedules[saleId].totalAmount,
                saleSchedules[saleId].exchangedCount,
                saleSchedules[saleId].collectedAmount,
                saleSchedules[saleId].isPrivate,
                saleSchedules[saleId].isValid
            );
    }

    function delSaleSchedule(
        string calldata saleId
    ) external onlyOwner {
        require(
            saleSchedules[saleId].isValid == true,
            "Sale schedule does not exist"
        );
        // delete saleSchedules[saleId]
        saleSchedules[saleId].isValid = false;
    }

    function transferSales(
        string memory fromSaleId,
        string memory toSaleId
    ) external onlyOwner {
        require(
            saleSchedules[fromSaleId].isValid == true,
            "fromSaleId: Sale schedule does not exist"
        );
        require(
            saleSchedules[toSaleId].isValid == true,
            "toSaleId: Sale schedule does not exist"
        );
        require(
            saleSchedules[fromSaleId].nftContract ==
                saleSchedules[toSaleId].nftContract,
            "NFT contract is not same"
        );
        require(
            saleSchedules[fromSaleId].nftHolder ==
                saleSchedules[toSaleId].nftHolder,
            "NFT holder is not same"
        );
        
        SaleSchedule storage fromSale = saleSchedules[fromSaleId];
        SaleSchedule storage toSale = saleSchedules[toSaleId];

        // require(block.timestamp > fromSale.endDate, "From sale is expired");
        require(block.timestamp <= toSale.endDate, "To sale is not expired");

        uint256 remainingAmount = fromSale.totalAmount -
            fromSale.exchangedCount;

        // remainingAmount should bigger than 0
        require(remainingAmount > 0, "No remaining amount");

        if (remainingAmount > 0) {
            fromSale.totalAmount = fromSale.exchangedCount;
            toSale.totalAmount += remainingAmount;
        }
    }


    function _addPrivateSaleAddress(
        address buyer,
        uint256 limitAmount,
        string calldata saleId
    ) internal {
        PrivateSaleAddress memory newPrivateSaleAddress = PrivateSaleAddress({
            limitAmount: limitAmount,
            exchangedCount: 0,
            isValid: true
        });
        
        saleSchedules[saleId].privateSaleAdresses[
            buyer
        ] = newPrivateSaleAddress;

        emit PrivateSaleAddressAdded(buyer, limitAmount, saleId);
    }

    function addPrivateSaleAddress(
        address buyer,
        uint256 limitAmount,
        string calldata saleId
    ) external onlyOwner {
        require(
            saleSchedules[saleId].isValid == true,
            "Sale schedule does not exist"
        );
        require(
            saleSchedules[saleId].isPrivate == true,
            "Sale schedule is not private");
        require(
            saleSchedules[saleId].privateSaleAdresses[buyer].isValid == false,
            "Private sale address already exists");
        _addPrivateSaleAddress(buyer, limitAmount, saleId);
    }

    

    function addPrivateSaleAddressBatch(
        address[] calldata addresses, // 0xfffffffasfasf,0xoskfoksofskofksofk - address string separated by ","
        uint256 limitAmount,
        string calldata saleId
    ) external onlyOwner {
        require(
            saleSchedules[saleId].isValid == true,
            "Sale schedule does not exist"
        );
        require(
            saleSchedules[saleId].isPrivate == true,
            "Sale schedule is not private");
        require(addresses.length > 0, "Addresses length should be bigger than 0");

        SaleSchedule storage sale = saleSchedules[saleId];
        mapping(address => PrivateSaleAddress)
            storage privateSaleAdresses = sale.privateSaleAdresses;
        
        for (uint256 i = 0; i < addresses.length; i++) {
            if (privateSaleAdresses[addresses[i]].isValid) {
                continue; // skip if already exists
            } 
            _addPrivateSaleAddress(addresses[i], limitAmount, saleId);
        }
    }

    function mintable(
        string calldata saleId,
        address user
    ) public view returns (uint256) {
        require(
            saleSchedules[saleId].isValid == true,
            "Sale schedule does not exist"
        );
        
        SaleSchedule storage sale = saleSchedules[saleId];
        PrivateSaleAddress storage privateSaleAddress = sale
            .privateSaleAdresses[user];
        uint256 remainingAmount = sale.totalAmount - sale.exchangedCount;

        if (!sale.isPrivate) { // public sale
            if (!privateSaleAddress.isValid) { // haven't private recrods
                uint256 mintableAmount = min( // return min value
                    remainingAmount,
                    sale.limitAmountPerWallet
                );
                return mintableAmount;
            } else { // have sales records
                uint256 mintableAmount = min( // return min value
                    remainingAmount,
                    privateSaleAddress.limitAmount - privateSaleAddress.exchangedCount
                );
                return mintableAmount;
            }
        }
        else { // private sale
                uint256 mintableAmount = min( // return min value
                    remainingAmount,
                    privateSaleAddress.limitAmount - privateSaleAddress.exchangedCount
                );
                return mintableAmount;
        }
    }

    function getSaleAddress(
        string calldata saleId,
        address buyer
    ) public view returns (uint256 limitAmount, uint256 exchangedCount) {
        require(
            saleSchedules[saleId].isValid == true,
            "Sale schedule does not exist"
        );
        require(
            saleSchedules[saleId].privateSaleAdresses[buyer].isValid == true,
            "Private sale address does not exist"
        );

        PrivateSaleAddress storage privateSaleAddress = saleSchedules[saleId]
            .privateSaleAdresses[buyer];
        return (
            privateSaleAddress.limitAmount,
            privateSaleAddress.exchangedCount
        );
    }



    function tokenTransferFrom(
        address from,
        address to,
        uint256 amount,
        address currencyTokenContract
    ) internal {
        IERC20 token = IERC20(currencyTokenContract);
        require(
            token.balanceOf(from) >= amount,
            "Insufficient token balance"
        );

        require(
            token.allowance(from, address(this)) >= amount,
            "Insufficient token allowance"
        );

        token.transferFrom(from, to, amount);
    }

    function exchange(string calldata saleId) 
        external payable {
        require(
            saleSchedules[saleId].isValid == true,
            "Sale schedule does not exist"
        );

        SaleSchedule storage sale = saleSchedules[saleId];
        require(
            block.timestamp >= sale.startDate &&
                block.timestamp <= sale.endDate,
            "Sale not active"
        );

        // check sale limit
        require(
            sale.exchangedCount < sale.totalAmount,
            "Sale limit reached"
        );

        address addressSelf = address(this);
        IERC721Enumerable nft = IERC721Enumerable(sale.nftContract);

        // check nft holder
        address nftHolder = sale.nftHolder;
        if ( nftHolder == address(0) ) {
            nftHolder = addressSelf;
        }
        else {
            // check approved all
            require(
                nft.isApprovedForAll(nftHolder, addressSelf),
                "Not approved all"
            );
        }

        // check have nft to exchange
        require(nft.balanceOf(nftHolder) > 0, "No NFT left");

        mapping(address => PrivateSaleAddress)
            storage privateSaleAdresses = sale.privateSaleAdresses;

        PrivateSaleAddress storage privateSaleAddress = privateSaleAdresses[
            msg.sender
        ];

        // check registered OG/WL user if sale is private
        if (sale.isPrivate) {
            require(privateSaleAddress.isValid, "Not registered");
            
            require(
                privateSaleAddress.exchangedCount <
                    privateSaleAddress.limitAmount,
                "Reached exchange limit"
            );

            privateSaleAddress.exchangedCount++;
        }
        else if (sale.limitAmountPerWallet > 0) {
            if ( !privateSaleAddress.isValid ) {
                PrivateSaleAddress memory newPrivateSaleAddress = PrivateSaleAddress({
                    limitAmount: sale.limitAmountPerWallet,
                    exchangedCount: 0,
                    isValid: true
                });

                privateSaleAdresses[
                    msg.sender
                ] = newPrivateSaleAddress;

                privateSaleAddress = privateSaleAdresses[
                    msg.sender
                ];
            }

            require(
                privateSaleAddress.exchangedCount <
                    privateSaleAddress.limitAmount,
                "Reached exchange limit"
            );

            privateSaleAddress.exchangedCount++;
        }

        // state changes
        sale.exchangedCount++;

        // get random tokenId from addressSelf
        uint256 randomIndex = getRandom() % nft.balanceOf(nftHolder);
        uint256 tokenIdToBeExchange = nft.tokenOfOwnerByIndex(
            nftHolder,
            randomIndex
        );

        // transfer nft to me if nftHolder are not me
        if ( nftHolder != addressSelf ) {
            nft.transferFrom(nftHolder, addressSelf, tokenIdToBeExchange);
        }

        // Send tokens or Ether
        if (sale.currencyTokenContract == address(0)) {
            require(msg.value >= sale.price, "Not enough Ether sent");
            // Send any excessive Ether back to the sender
            if (msg.value > sale.price) {
                (bool success, ) = payable(msg.sender).call{value: msg.value - sale.price}("");
                require(success, "payback failed");
            }
        } else {
            tokenTransferFrom(
                msg.sender,
                addressSelf,
                sale.price,
                sale.currencyTokenContract
            );
        }

        // send nft to msg.sender
        nft.transferFrom(addressSelf, msg.sender, tokenIdToBeExchange);

        emit NFTExchanged(saleId, msg.sender, tokenIdToBeExchange, sale.currencyTokenContract, sale.price);
    }

    function tokenOrCoinTransfer(
        address to,
        uint256 amount,
        address currencyTokenContract
    ) internal {
        // if currencyTokenContract is 0x0, it means ETH
        if (currencyTokenContract == address(0)) {
            require(
                address(this).balance >= amount,
                "Insufficient ETH balance"
            );
            // send to `to` address with amount ETH
            (bool success, ) = payable(to).call{value: amount}("");
            require(success, "Transfer failed");
        } else {
            IERC20 token = IERC20(currencyTokenContract);
            require(
                token.balanceOf(address(this)) >= amount,
                "Insufficient token balance"
            );

            token.transfer(to, amount);
        }
    }

    function collect(
        string calldata saleId
    ) external {
        SaleSchedule storage sale = saleSchedules[saleId];

        require(
            sale.isValid == true,
            "Sale schedule does not exist"
        );

        if (sale.nftHolder != address(0)) {
            require(
                sale.nftHolder == msg.sender,
                "Only nft holder can collect"
            );
        } else {
            require(
                owner() == msg.sender,
                "Not owner"
            );
        }

        uint256 salesAmount = sale.exchangedCount * sale.price;
        uint256 collectableAmount = salesAmount - sale.collectedAmount;

        require(
            collectableAmount > 0,
            "No collectable amount"
        );

        sale.collectedAmount = salesAmount;

        tokenOrCoinTransfer( // transfer from contract to owner
            msg.sender,
            collectableAmount,
            sale.currencyTokenContract
        );
    }


    function getRandom() internal returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    msg.sender,
                    nonce
                )
            )
        );
        nonce++;
        return randomNumber;
    }

    function min(uint256 x, uint256 y) internal view returns (uint256) {
        if (x < y) {
            return x;
        } else {
            return y;
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // nothing needed

        return this.onERC721Received.selector;
    }
}