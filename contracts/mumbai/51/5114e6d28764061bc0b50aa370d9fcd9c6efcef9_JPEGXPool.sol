// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./AuctionERC.sol";

/// @notice JPEGX Staking contract - NFT Option Protocol
/// @author Rems0
/// TODO implement OnlyOwner and Reentrancy guard

contract JPEGXPool is ERC721Holder, AuctionERC {
    /*** Constants ***/
    address public erc721;
    address public erc20;
    uint256 immutable epochduration = 1 days;
    uint256 immutable interval = 1 days / 12;
    uint256 hatching;
    /*** Owner variables ***/
    mapping(uint256 => mapping(uint256 => bool)) strikePriceAt;
    mapping(uint256 => mapping(uint256 => uint256)) premiumAt;
    mapping(uint256 => uint256) floorPriceAt;
    /*** Option relatives variables ***/
    mapping(uint256 => mapping(uint256 => uint256[])) NFTsAt;
    mapping(uint256 => mapping(uint256 => uint256)) NFTtradedAt;
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) shareAtOf;
    mapping(uint256 => Option) optionAt;
    /*** Events ***/
    event Stake(
        uint256 _epoch,
        uint256 _tokenId,
        uint256 _strikePrice,
        uint256 _premium,
        address _writer
    );
    event ReStake(
        uint256 _epoch,
        uint256 _tokenId,
        uint256 _strikePrice,
        uint256 _premium,
        address _writer
    );
    event BuyOption(
        uint256 _epoch,
        uint256 _tokenId,
        uint256 _strikePrice,
        uint256 _premium,
        address _writer,
        address _buyer
    );
    event CoverPosition(
        uint256 _epoch,
        uint256 _tokenId,
        uint256 _debt,
        address _writer,
        address _buyer
    );
    event WithdrawNFT(uint256 _tokenId, address _owner);
    event ClaimPremiums(
        uint256 _epoch,
        uint256 _shares,
        uint256 _premiums,
        address _owner
    );
    event ExerceOption(
        uint256 _tokenId,
        uint256 _firstPrice,
        address _writer,
        address _buyer,
        uint256 _debt
    );

    struct Option {
        address writer;
        address buyer;
        uint256 sPrice;
        uint256 premium;
        uint256 epoch;
        bool covered;
        bool liquidated;
    }

    constructor(address _erc721, address _erc20) AuctionERC(_erc721, _erc20) {
        hatching = block.timestamp;
        erc721 = _erc721;
        erc20 = _erc20;
    }

    // 100/160k gas
    function stake(uint256 _tokenId, uint256 _strikePrice) public {
        uint256 epoch = getEpoch_2e() + 1;
        require(strikePriceAt[epoch][_strikePrice], "Wrong strikePrice");
        IERC721(erc721).safeTransferFrom(msg.sender, address(this), _tokenId);
        optionAt[_tokenId].sPrice = _strikePrice;
        optionAt[_tokenId].writer = msg.sender;
        optionAt[_tokenId].premium = premiumAt[epoch][_strikePrice];
        optionAt[_tokenId].epoch = epoch;
        optionAt[_tokenId].buyer = address(0);
        NFTsAt[epoch][_strikePrice].push(_tokenId);
        ++shareAtOf[epoch][_strikePrice][msg.sender];
        emit Stake(
            epoch,
            _tokenId,
            _strikePrice,
            premiumAt[epoch][_strikePrice],
            msg.sender
        );
    }

    // 60k gas
    function restake(uint256 _tokenId, uint256 _strikePrice) public {
        Option memory option = optionAt[_tokenId];
        uint256 epoch = getEpoch_2e() + 1;
        require(
            block.timestamp - hatching >
                option.epoch * epochduration - 2 * interval,
            "Option has not expired"
        );
        require(option.writer == msg.sender, "You are not the owner");
        require(
            floorPriceAt[option.epoch] > 0,
            "Floor price not settled for this epoch"
        );
        require(
            floorPriceAt[option.epoch] <= option.sPrice ||
                option.covered ||
                option.buyer == address(0),
            "Cover your position"
        );
        require(strikePriceAt[epoch][_strikePrice], "Wrong strikePrice");
        optionAt[_tokenId].sPrice = _strikePrice;
        optionAt[_tokenId].writer = msg.sender;
        optionAt[_tokenId].premium = premiumAt[epoch][_strikePrice];
        optionAt[_tokenId].epoch = epoch;
        optionAt[_tokenId].buyer = address(0);
        NFTsAt[epoch][_strikePrice].push(_tokenId);
        ++shareAtOf[epoch][_strikePrice][msg.sender];
        emit ReStake(
            epoch,
            _tokenId,
            _strikePrice,
            premiumAt[epoch][_strikePrice],
            msg.sender
        );
    }

    // 79/52k gas
    // Check reentrancy
    function buyOption(uint256 _strikePrice) public {
        uint256 epoch = getEpoch_2e();
        require(strikePriceAt[epoch][_strikePrice], "Wrong strikePrice");
        require(
            NFTtradedAt[epoch][_strikePrice] <
                NFTsAt[epoch][_strikePrice].length,
            "All options have been bought"
        );
        require(
            IERC20(erc20).transferFrom(
                msg.sender,
                address(this),
                premiumAt[epoch][_strikePrice]
            )
        );
        uint256 tokenIterator = NFTsAt[epoch][_strikePrice].length -
            NFTtradedAt[epoch][_strikePrice] -
            1;
        ++NFTtradedAt[epoch][_strikePrice];
        uint256 tokenId = NFTsAt[epoch][_strikePrice][tokenIterator];
        require(
            optionAt[tokenId].buyer == address(0),
            "This option has already been bought"
        );
        optionAt[tokenId].buyer = msg.sender;
        emit BuyOption(
            epoch,
            tokenId,
            _strikePrice,
            premiumAt[epoch][_strikePrice],
            optionAt[tokenId].writer,
            msg.sender
        );
    }

    //165k gas
    function liquidateNFT(uint256 _tokenId) public {
        Option memory option = optionAt[_tokenId];
        uint256 epoch = option.epoch;
        require(
            block.timestamp - hatching >
                (option.epoch + 1) * epochduration + interval,
            "Liquidation period isn't reached"
        );
        require(
            floorPriceAt[epoch] > 0,
            "Floor price not settled for this epoch"
        );
        require(
            floorPriceAt[epoch] > option.sPrice,
            "Option expired worthless"
        );
        require(!option.covered, "Position covered");
        require(option.liquidated != true, "Option already liquidated");
        optionAt[_tokenId].liquidated = true;
        uint256 debt = floorPriceAt[epoch] - option.sPrice;
        start(
            _tokenId,
            (floorPriceAt[epoch] * 100) / 1000,
            option.writer,
            option.buyer,
            debt
        );
        emit ExerceOption(
            _tokenId,
            (floorPriceAt[epoch] * 100) / 1000,
            option.writer,
            option.buyer,
            debt
        );
    }

    // 43k gas
    function coverPosition(uint256 _tokenId) public {
        Option memory option = optionAt[_tokenId];
        require(
            floorPriceAt[option.epoch] > 0,
            "Floor price not settled for this epoch"
        );
        require(
            floorPriceAt[option.epoch] > option.sPrice,
            "Option expired worthless"
        );
        require(
            block.timestamp - hatching >
                (option.epoch + 1) * epochduration - 2 * interval,
            "Option has not expired"
        ); // this allows us to update floorPrice and check it before covering position
        require(option.liquidated != true, "Option already liquidated");
        require(option.buyer != address(0), "Option have not been bought");
        uint256 debt = floorPriceAt[option.epoch] - option.sPrice;
        require(IERC20(erc20).transferFrom(msg.sender, option.buyer, debt));
        optionAt[_tokenId].covered = true;
        emit CoverPosition(
            option.epoch,
            _tokenId,
            debt,
            msg.sender,
            option.buyer
        );
    }

    function withdrawNFT(uint256 _tokenId) public {
        Option memory option = optionAt[_tokenId];
        require(getEpoch_2e() > option.epoch, "Epoch not finished");
        require(option.writer == msg.sender, "You are not the owner");
        require(
            floorPriceAt[option.epoch] > 0,
            "Floor price not settled for this epoch"
        );
        require(
            floorPriceAt[option.epoch] <= option.sPrice ||
                option.covered ||
                option.buyer == address(0),
            "Cover your position"
        );
        IERC721(erc721).safeTransferFrom(address(this), msg.sender, _tokenId);
        //Maybe not secure if you are the last owner of the erc721 and withdraw at the time the new owner stakes it
    }

    // 8739 gas
    function claimPremiums(uint256 _epoch, uint256 _strikePrice) public {
        uint256 shares = shareAtOf[_epoch][_strikePrice][msg.sender];
        shareAtOf[_epoch][_strikePrice][msg.sender] = 0;
        IERC20(erc20).transfer(
            msg.sender,
            shares * premiumAt[_epoch][_strikePrice]
        );
    }

    function buyAtStrike(uint256 _tokenId) public {
        Option memory option = optionAt[_tokenId];
        require(option.buyer == msg.sender, "You don't own this option");
        require(getEpoch_2e() > option.epoch, "Epoch not finished");
        require(!option.covered, "Position covered");
        require(
            IERC20(erc20).transferFrom(
                msg.sender,
                option.writer,
                option.sPrice
            ),
            "Please set allowance"
        );
        require(!option.liquidated, "option already liquidated");
        IERC721(erc721).safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    /*** Admin functions ***/
    function setStrikePriceAt(
        uint256 _epoch,
        uint256[] memory _strikePrices,
        uint256[] memory _premiums
    ) public {
        require(
            _strikePrices.length == _premiums.length,
            "_strikePrices.length != _premiums.length"
        );
        for (uint256 i = 0; i != _strikePrices.length; ++i) {
            strikePriceAt[_epoch][_strikePrices[i]] = true;
            premiumAt[_epoch][_strikePrices[i]] = _premiums[i];
        }
    }

    function setfloorpriceAt(uint256 _epoch, uint256 _floorPrice) public {
        require(_floorPrice > 0, "Floor price < 0");
        floorPriceAt[_epoch] = _floorPrice;
    }

    /*** Getters ***/
    function getfloorprice(uint256 _epoch) public view returns (uint256) {
        return floorPriceAt[_epoch];
    }

    // 468 gas
    function getEpoch_2e() public view returns (uint256) {
        return (block.timestamp - hatching) / epochduration;
    }

    function getSharesAtOf(
        uint256 _epoch,
        uint256 _strikePrice,
        address _add
    ) public view returns (uint256) {
        return shareAtOf[_epoch][_strikePrice][_add];
    }

    function getOption(
        uint256 _tokenId
    ) public view returns (Option memory option) {
        return optionAt[_tokenId];
    }

    function getAmountLockedAt(
        uint256 _epoch,
        uint256 _strikePrice
    ) public view returns (uint256) {
        return NFTsAt[_epoch][_strikePrice].length;
    }

    function getOptionAvailableAt(
        uint256 _epoch,
        uint256 _strikePrice
    ) public view returns (uint256) {
        return
            NFTsAt[_epoch][_strikePrice].length -
            NFTtradedAt[_epoch][_strikePrice];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AuctionERC is ReentrancyGuard {
    event Start(uint256 _nftId, uint256 startingBid);
    event End(address actualBidder, uint256 highestBid);
    event Bid(address indexed sender, uint256 amount);
    event Withdraw(address indexed bidder, uint256 amount);

    address payable public seller;

    mapping(uint256 => bool) public started;
    mapping(uint256 => uint256) public endAt;

    IERC721 public nft;
    IERC20 public wrether;
    uint256 public nftId;

    mapping(uint256 => uint256) public highestBid;
    mapping(uint256 => address) public actualBidder;
    mapping(uint256 => mapping(address => uint256)) public bids;
    mapping(uint256 => address) public optionWriter;
    mapping(uint256 => address) public optionOwner;
    mapping(uint256 => uint256) public debt;

    constructor(address _tokenAddess, address _wrappedEtherAddress) {
        //seller = payable(msg.sender);
        nft = IERC721(_tokenAddess);
        wrether = IERC20(_wrappedEtherAddress);
    }

    function start(
        uint256 _nftId,
        uint256 startingBid,
        address _optionWriter,
        address _optionOwner,
        uint256 _debt
    ) public nonReentrant {
        require(!started[_nftId], "Already started[_nftId]!");
        highestBid[_nftId] = startingBid;
        started[_nftId] = true;
        endAt[_nftId] = block.timestamp + 2 days;
        optionWriter[_nftId] = _optionWriter;
        optionOwner[_nftId] = _optionOwner;
        debt[_nftId] = _debt;
        emit Start(_nftId, startingBid);
    }

    function bid(uint256 _nftId, uint256 _bidAmount) external {
        require(started[_nftId], "Not started[_nftId].");
        require(block.timestamp < endAt[_nftId], "ended[_nftId]!");
        require(
            _bidAmount + bids[_nftId][msg.sender] > highestBid[_nftId],
            "the total bid is lower than actual maxBid"
        );
        require(
            wrether.transferFrom(msg.sender, address(this), _bidAmount),
            "ERC20 - transfer is not allowed"
        );
        bids[_nftId][msg.sender] += _bidAmount;
        highestBid[_nftId] = bids[_nftId][msg.sender];
        actualBidder[_nftId] = msg.sender;
        emit Bid(actualBidder[_nftId], highestBid[_nftId]);
    }

    //  Users can retract at any times if they aren't the actual bidder
    function withdraw(uint256 _nftId) external payable nonReentrant {
        require(
            msg.sender != actualBidder[_nftId],
            "You are the actual bidder"
        );
        uint256 bal = bids[_nftId][msg.sender];
        bids[_nftId][msg.sender] = 0;
        wrether.transferFrom(address(this), msg.sender, bal);
        emit Withdraw(msg.sender, bal);
    }

    // End the Auction, this function needs to be trigerred by hand in a first time
    function end(uint256 _nftId) internal nonReentrant returns (bool) {
        require(started[_nftId], "You need to start first!");
        require(block.timestamp >= endAt[_nftId], "Auction is still ongoing!");
        bool sellIsDone = false;

        if (actualBidder[_nftId] != address(0)) {
            bids[_nftId][actualBidder[_nftId]] = 0;
            //Transfers the NFT to the actualBidder
            nft.safeTransferFrom(address(this), actualBidder[_nftId], nftId);
            wrether.transfer(optionOwner[_nftId], debt[_nftId]);
            wrether.transfer(
                optionWriter[nftId],
                (highestBid[_nftId] * 90) / 100
            );
            actualBidder[_nftId] = address(0);
            sellIsDone = true;
        }
        started[_nftId] = false;
        emit End(actualBidder[_nftId], highestBid[_nftId]);
        return sellIsDone;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}