// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "hardhat/console.sol";

import "../lib/Require.sol";
import {TransferMarketLib as LibMarket} from "../lib/TransferMarketLib.sol";
import {CreateMarketLib} from "../lib/CreateMarketLib.sol";
import "../interfaces/INonLazyMarket.sol";
import "../interfaces/ILazyNFT.sol";

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NonLazyMintMarket is
    INonLazyMarket,
    ReentrancyGuard,
    ERC721Holder,
    Pausable,
    AccessControl
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public constant name = "BlockVare Market-Place";

    ILazyNFT public nftContract;

    using LibMarket for *;

    uint256 public listingFee;
    uint256 public totalmarketFeeInEth;

    // bid days is hardcoded 32 days and can not be modified after deployment
    uint256 public constant maxBidDays = 2764800 seconds; /// 32days*24hrs*60mins*60seconds
    uint256 public minBidDays = 259200 seconds; //259200 seconds; /// 3days*24hrs*60mins*60seconds

    // // to keep track of all marketitems created with unique on-chain NFT id.
    // /// @dev does not keep track of NFT vouchers as they are not minted yet.

    mapping(uint256 => MarketItem) public tokenIdToMarketItem;
    mapping(uint256 => address) public tokenIdToNFTcontract;

    // /** @dev used to keep track of bidders eth amount bid on each token Id so that he can withdraw it post bid */
    mapping(address => mapping(uint256 => uint256)) isBidderOf;

    mapping(address => mapping(uint256 => uint256))
        public pendingERC20Withdrawal;

    // // to keep track of Market item with an unique index

    mapping(address => mapping(address => mapping(uint256 => DrawableBidder))) drawablesBidder;

    // // keep track of eth to be withdrawn by each seller;

    mapping(address => DrawableSeller) drawableSeller;

    // to track failed ERC20 royalty transfers
    mapping(address => FailedRoyaltyPay) failedRoyaltyTransfers;

    // // to track failed ETH royalty transfers
    // mapping(address => FailedRoyaltyPay) failedEthRoyaltyTransfers;

    /** --------------------------------------------------------------------constructor-------------------------------------------------------- */

    constructor(address _nftContract) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        require(isContract(_nftContract), "invalid address.");

        nftContract = ILazyNFT(_nftContract);
    }

    function isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    /// @dev non-lazy NFT listing logic

    function createEthMarket(
        uint256 _tokenId,
        uint256 _price,
        // uint256 _buyNowPrice,
        string memory _uri,
        uint256 _bidStartsAt,
        uint256 _bidEndsAt,
        address _nftContract
    ) external payable whenNotPaused {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "Market: only authorized sellers!"
        );
        require(
            (IERC721(_nftContract).ownerOf(_tokenId) == msg.sender),
            "Market: Only-NFT-owner"
        );
        require(!tokenIdToMarketItem[_tokenId].isListed, "already listed!");

        // require(_bidEndsAt < (_bidStartsAt + bidDays), "Market: bid End be < 32 days!");

        require(msg.sender != address(0), "Invalid address!");

        require(msg.value >= listingFee, "send listing fee.");

        totalmarketFeeInEth += msg.value;

        CreateMarketLib.createMarketItemNormalMintWithEtherPrice(
            tokenIdToMarketItem,
            _tokenId,
            _price,
            // _buyNowPrice,
            _uri,
            _bidStartsAt,
            _bidEndsAt,
            _nftContract
        );

        drawableSeller[msg.sender].isSeller = true;
        tokenIdToNFTcontract[_tokenId] = _nftContract;

        emit MarketItemCreated(msg.sender, _tokenId, _price);
    }

    function bidwithETH(uint256 _tokenId, address _nftContract)
        external
        payable
        whenNotPaused
    {
        emit BidMade(msg.sender, msg.value, _tokenId);

        CreateMarketLib.MakeABidWithEth(
            tokenIdToMarketItem,
            drawablesBidder,
            isBidderOf,
            _tokenId,
            _nftContract
        );

        // pendingERC20Withdrawal[msg.sender][_tokenId] += msg.value;

        // uint256 val = drawablesBidder[msg.sender][
        //     0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF
        // ][_tokenId].eth[0];
        // console.log("value at 0 index before updating value %s", val);

        // drawablesBidder[msg.sender][0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF][
        //     _tokenId
        // ].eth.push(msg.value);
        // drawablesBidder[msg.sender][0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF][
        //     _tokenId
        // ].isBidder = true;

        // uint256 newVal = drawablesBidder[msg.sender][
        //     0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF
        // ][_tokenId].eth.length;

        // console.log("make eth bid array new lenght %s", newVal);
    }

    function createERC20Market(
        uint256 _tokenId,
        uint256 _price,
        // uint256 _buyNowPrice,
        string memory _uri,
        uint256 _bidStartsAt,
        uint256 _bidEndsAt,
        address _nftContract,
        address _paymentToken
    ) external payable whenNotPaused {
        require(
            (IERC721(_nftContract).ownerOf(_tokenId) == msg.sender),
            "Only NFT-owner"
        );

        require(!tokenIdToMarketItem[_tokenId].isListed, "already listed!");

        if (listingFee > 0) {
            require(msg.value == listingFee, "send exact listing fee.");
        }

        require(isContract(_paymentToken), "Market: invalid ERC20");
        require(isContract(_nftContract), "Market: invalid ERC721");
        require(msg.sender != address(0), "zero address!");

        emit MarketItemCreated(msg.sender, _tokenId, _price);

        CreateMarketLib.createMarketItemforNormalMintWithERC20tokenPrice(
            tokenIdToMarketItem,
            _tokenId,
            _price,
            // _buyNowPrice,
            _uri,
            _nftContract,
            _paymentToken,
            _bidStartsAt,
            _bidEndsAt
        );

        // drawableSeller[msg.sender][_tokenId].isSeller = true;
        // drawableSeller[msg.sender].isSeller = true;

        tokenIdToNFTcontract[_tokenId] = _nftContract;
    }

    function bidwithERC20(
        uint256 _tokenId,
        uint256 _newBidinERC20,
        address _nftContract
    ) external payable whenNotPaused {
        emit BidMade(msg.sender, _newBidinERC20, _tokenId);
        CreateMarketLib.makeAbidWithERC20(
            tokenIdToMarketItem,
            drawablesBidder,
            pendingERC20Withdrawal,
            _tokenId,
            _nftContract,
            _newBidinERC20
        );
    }

    function revokeListing(uint256 _tokenId) public {
        uint256 _bidEndsAt = tokenIdToMarketItem[_tokenId].bidEndsAt;
        // console.log("block_time %s", block.timestamp);
        // console.log("end time %s", _bidEndsAt);
        require(tokenIdToMarketItem[_tokenId].isListed, "Market: not listed!");

        uint256 revokePeriod = (_bidEndsAt - 43200);
        console.log("end time - 43200 %s", revokePeriod);
        require(
            block.timestamp < revokePeriod, //1668 594600//(_bidEndsAt - 43200), /// 12hrs * 60 mins * 60 secs 43200
            "Market: allowed only 12hrs before bid ends!"
        );
        require(
            msg.sender == tokenIdToMarketItem[_tokenId].creator,
            "Market: only market creator!"
        );
        delete tokenIdToMarketItem[_tokenId];

        emit MarketItemCancelled(msg.sender, _tokenId);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setListingFee(uint96 _feePercent)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_feePercent > 0, "Market: can't set negative fee!");
        listingFee = _feePercent;

        emit MarketFeeChanged(msg.sender, _feePercent);
    }

    /** @dev ---------------------------------Functions to withdraw Ether or ERC20 to cretor/seller account ----------------------------------- */

    function withdrawEther(uint256 _tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        // require(!voucherIdToBids[_tokenId].started, "Only after bid duration!");

        // IMPORTANT: casting msg.sender to a payable address is only safe if ALL members of the minter role are payable addresses.
        address payable withdrawer = payable(msg.sender);
        require(withdrawer != address(0), "Market: invalid address");
        require(
            withdrawer != tokenIdToMarketItem[_tokenId].highestBidder,
            "Market: highest bidder not allowed!"
        );
        uint256 _amount;

        if (CheckIf.isBidder(drawablesBidder, address(0), _tokenId)) {
            require(
                isBidderOf[withdrawer][_tokenId] > 0,
                "Market: no pending widrawls for this Id"
            );

            // zero account before transfer to prevent re-entrancy attack

            _amount = drawablesBidder[withdrawer][address(0)][_tokenId].eth;

            delete drawablesBidder[withdrawer][address(0)][_tokenId].eth;

            require(_amount > 0, "Bidder: Zero Eth Bal.");

            /// deleting the stored balance from the struct after complete withdrawal
            delete isBidderOf[withdrawer][_tokenId];
        } else {
            _amount = drawableSeller[withdrawer].eth;

            require(_amount > 0, "Zero Eth Bal.");

            // zero account before transfer to prevent re-entrancy attack
            drawableSeller[withdrawer].eth -= _amount;
        }

        /// @dev Emitting Etherwithdrawal event before state change to  Ether balance of caller
        emit Etherwithdrawal(withdrawer, _amount);

        // USING LIBTRANSFER TO  ACCOMPLISH THE BELOW ETH TRANSFER

        bool sent = LibMarket.transferEth(withdrawer, _amount);

        require(sent, "Market: ETH TF");
    }

    function withdrawERC20(address _ERC20token, uint256 _tokenId)
        external
        whenNotPaused
        nonReentrant
    {
        require(msg.sender != address(0), "Invalid caller");

        require(
            msg.sender != tokenIdToMarketItem[_tokenId].highestBidder,
            "Market: highest bidder not allowed!"
        );

        // require(
        //     block.timestamp > voucherIdToBids[_tokenId].endsAt,
        //     "Only after bid duration!"
        // );

        // USING BELOW TWO LINES FRO ABOVE CHECK
        require(
            CheckIf.isBidder(drawablesBidder, _ERC20token, _tokenId) ||
                CheckIf.isSeller(drawableSeller),
            "Market: only bidders or sellers!"
        );

        // require(
        //     pendingERC20Withdrawal[msg.sender][_tokenId] > 0,
        //     "Zero ER20 balance!"
        // );

        uint256 _amount = 0;

        // require(amount > 0, "Zero ERC20 balance!");

        /// @dev Emitting ERC20withdrawal before state changes to ERC20 balance of caller

        if (drawablesBidder[msg.sender][_ERC20token][_tokenId].isBidder) {
            // amount = drawablesBidder[msg.sender].erc;
            // drawablesBidder[msg.sender][_tokenId].erc();

            _amount = drawablesBidder[msg.sender][_ERC20token][_tokenId].erc;

            // console.log("Bidder withdrawable erc is %s", amount);
            require(_amount > 0, "Seller: Zero ER20 balance!");

            delete drawablesBidder[msg.sender][_ERC20token][_tokenId];

            // LibMarket.safeTransfer(_ERC20token, msg.sender, amount);

            // require(sent, "ERC20 TF");
        } else if (drawableSeller[msg.sender].isSeller) {
            _amount = drawableSeller[msg.sender].erc;

            // console.log("seller withdrawable erc is %s", amount);

            require(_amount > 0, "Seller: Zero ER20 balance!");

            drawableSeller[msg.sender].erc -= _amount;
        } else {
            revert("Market: only bidder or seller!");
        }

        emit ERC20withdrawal(msg.sender, _amount, _ERC20token);

        pendingERC20Withdrawal[msg.sender][_tokenId] -= _amount;

        /// @dev transferring the ERC20 value to  caller

        LibMarket.safeTransfer(_ERC20token, msg.sender, _amount);
    }

    /// @notice Retuns the amount of Ether available to the caller to withdraw.

    function availableToWithdrawSeller()
        public
        view
        returns (uint256 ethAmount, uint256 ercAmount)
    {
        return (drawableSeller[msg.sender].eth, drawableSeller[msg.sender].erc);
    }

    /// @notice Retuns the amount of Ether available to the caller to withdraw.

    function availableToWithdrawBidder(uint256 _voucherId)
        public
        view
        returns (uint256 ethAmount, uint256 erc20Amount)
    {
        address _paymentToken = tokenIdToMarketItem[_voucherId]
            .paymentToken
            .tokenAddress;

        /** @dev to fetch total Eth amount */

        ethAmount = drawablesBidder[msg.sender][address(0)][_voucherId].eth;

        /** @dev to fetch total ERC20 amount */

        erc20Amount = drawablesBidder[msg.sender][_paymentToken][_voucherId]
            .erc;
    }

    function claimNFT(uint256 _tokenId)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        /**@dev ---Sanity check------------------- */

        require(
            block.timestamp > tokenIdToMarketItem[_tokenId].bidEndsAt,
            "Market: only after bid ends!"
        );
        require(
            CheckIf.isListedAndActive(tokenIdToMarketItem, _tokenId),
            "Market: id not listed or no bid on it"
        );
        address highestBidder = tokenIdToMarketItem[_tokenId].highestBidder;
        require(msg.sender == highestBidder, "Market: only highest bidder!");

        // require(drawableSeller[msg.sender].isSeller, "Market: Only sellers.");
        // require(CheckIf.isSeller(drawableSeller), "Market: Only sellers.");
        // require(
        //     tokenIdToMarketItem[_tokenId].isListed &&
        //         tokenIdToMarketItem[_tokenId].isBidActive,
        //     "Market: id not listed or no bid on it"
        // );
        address payable seller = payable(msg.sender);
        require(seller != address(0), "caller zero address.");

        /**@dev end of sanit check------------------- */

        /** @dev tranfer of value and assets starts */

        if (tokenIdToMarketItem[_tokenId].isERC20exists) {
            /**---------------------------------------------------*/

            // USING "ERC20AndAssetTransfer"LIBRARY TO PERFORM THE TRANSFER FUNCTIONS
            tokenIdToMarketItem.ERC20AndAssetTransfer(
                drawableSeller,
                drawablesBidder,
                failedRoyaltyTransfers,
                _tokenId
            );

            /**------------------------------------------------------*/

            uint256 amount = tokenIdToMarketItem[_tokenId].highestBid;

            emit MarketItemSold(
                seller,
                highestBidder,
                block.timestamp,
                _tokenId,
                amount
            );

            delete tokenIdToMarketItem[_tokenId];

            // wasListed[_tokenId][address(_nftContract)] = true;
        } else {
            // storing  highest bid into 'amount' of Eth to send it to seller
            uint256 amount = tokenIdToMarketItem[_tokenId].highestBid;

            emit MarketItemSold(
                seller,
                highestBidder,
                block.timestamp,
                _tokenId,
                amount
            );

            /**-------------------------------------------------------------*/

            // USING "ERC20AndAssetTransfer"LIBRARY TO PERFORM THE TRANSFER FUNCTIONS

            tokenIdToMarketItem.EThAndAssetTransfer(
                drawableSeller,
                drawablesBidder,
                failedRoyaltyTransfers,
                _tokenId
            );

            /**-------------------------------------------------------------*/
            // MOVED BELOW LINE TO ABOVE IF BLOCK BECAUSE OF SLITHER TEST WARNING

            delete tokenIdToMarketItem[_tokenId];

            // wasListed[_tokenId][address(_nftContract)] = true;
        }

        // require(bidState[_tokenId][address(_nftContract)] == BidState(1), "Bid's not put to Closed at the and of accept bid");
    }

    /** ---------------------------------------------------Withdraw fuctions end here----------------------------------------------------------- */

    /** @dev Required for any contract which needs to receive Ehter value */

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    function withDrawMarketFeeEth(address payable receiver)
        external
        payable
        whenNotPaused
        returns (bool sent)
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Admin allowed");
        require(receiver != address(0), "Market: invalid addres!");
        require(totalmarketFeeInEth > 0, "Market: 0 bal!");

        uint256 amount = totalmarketFeeInEth;
        totalmarketFeeInEth = 0;

        // (sent, ) = receiver.call{value: amount}("");
        // require(sent, "withdrawal failed");

        return (sent) = receiver.transferEth(amount);
    }

    /**@dev allows creator to withdraw failed royalty transfer*/

    function withdrawERC20Royalty() external whenNotPaused {
        address _royaltyReceiver = msg.sender;
        uint256 _amount = failedRoyaltyTransfers[msg.sender].amount;
        require(_amount > 0, "Market: zero erc20 balance!");
        address _erc20Address = failedRoyaltyTransfers[msg.sender].erc20Address;

        LibMarket.safeTransfer(_erc20Address, _royaltyReceiver, _amount);
    }

    function withdrawETHRoyalty()
        external
        whenNotPaused
        returns (bool success)
    {
        address payable _royaltyReceiver = payable(msg.sender);
        uint256 _amount = failedRoyaltyTransfers[msg.sender].amount;
        require(_amount > 0, "Market: zero ETH balance!");

        success = LibMarket.transferEth(_royaltyReceiver, _amount);
    }

    /** @dev The following function of ERC721Holder is implemented so as to enable the INF contract to receive ERC721 tokens  */

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    ////MUST BE REMOVED AFTER TESTING THE CONTRACT
    /*********************NOTICE SELF DESTRUCT********************** */

    function whoosh() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "only admin");
        selfdestruct(payable(msg.sender));
    }

    // need to remove the following setter after test and change the minBidDays to constant

    function changeMinBidDays(uint256 _minBidDuration)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        minBidDays = _minBidDuration;
    }

    /** ----------------------------------NFT voucher verification related function starts here--------------------------------------------- */
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {DrawableBidder, DrawableSeller} from "../interfaces/ILazyMintMarket.sol";
import {MarketItem} from "../interfaces/INonLazyMarket.sol";
import {NFTVoucher} from "../interfaces/ILazyNFT.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library CheckIf {
    function isBidder(
        mapping(address => mapping(address => mapping(uint256 => DrawableBidder)))
            storage drawablesBidder,
        address _erc20Token,
        uint256 _voucherId
    ) external view returns (bool) {
        return drawablesBidder[msg.sender][_erc20Token][_voucherId].isBidder;
    }

    function isSeller(mapping(address => DrawableSeller) storage drawableSeller)
        external
        view
        returns (bool)
    {
        return drawableSeller[msg.sender].isSeller;
    }

    function isZeroAddress(address seller) external pure {
        require(seller != address(0), "caller zero address.");
    }

    function isListedAndActive(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        uint256 _tokenId
    ) external view returns (bool) {
        // require(
        //     tokenIdToMarketItem[_tokenId].isListed &&
        //         tokenIdToMarketItem[_tokenId].isBidActive,
        //     "Market: id not listed or no bid on it"
        // );

        return
            tokenIdToMarketItem[_tokenId].isListed &&
            tokenIdToMarketItem[_tokenId].isBidActive;
    }

    function isERC20exits(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        uint256 _tokenId
    ) external view returns (bool) {
        // require(tokenIdToMarketItem[_tokenId].isERC20exits);
        return tokenIdToMarketItem[_tokenId].isERC20exists;
    }

    function isBidHigherEth(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        uint256 _tokenId
    ) external view returns (bool) {
        // require(
        //     msg.value > tokenIdToMarketItem[_tokenId].highestBid &&
        //         msg.value >= tokenIdToMarketItem[_tokenId].minPrice,
        //     "Increase ETH value"
        // );
        return
            msg.value > tokenIdToMarketItem[_tokenId].highestBid &&
            msg.value >= tokenIdToMarketItem[_tokenId].minPrice;
    }

    function isBidHigherERC(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        uint256 _newBidinERC20,
        uint256 _tokenId
    ) external view returns (bool) {
        // require(
        //     _newBidinERC20 >= tokenIdToMarketItem[_tokenId].paymentToken.cost &&
        //         _newBidinERC20 >= tokenIdToMarketItem[_tokenId].highestBid,
        //     "bid higher ERC20"
        // );

        return
            _newBidinERC20 >= tokenIdToMarketItem[_tokenId].paymentToken.cost &&
            _newBidinERC20 >= tokenIdToMarketItem[_tokenId].highestBid;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {MarketItem, FailedRoyaltyPay} from "../interfaces/INonLazyMarket.sol";
import "../interfaces/ILazyMintMarket.sol";

library TransferMarketLib {
    using SafeERC20 for IERC20;

    function safeTransfer(
        address token,
        address to,
        uint256 amount
    ) external {
        IERC20(token).safeTransfer(to, amount);
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external {
        IERC20(token).safeTransferFrom(from, to, amount);
    }

    function transferNFT(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        IERC721 nft,
        uint256 id
    ) external {
        address highestBidder = tokenIdToMarketItem[id].highestBidder;

        address seller = tokenIdToMarketItem[id].creator;

        nft.transferFrom(seller, highestBidder, id);
    }

    function ERC20AndAssetTransfer(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        mapping(address => DrawableSeller) storage drawableSeller,
        mapping(address => mapping(address => mapping(uint256 => DrawableBidder)))
            storage drawablesBidder,
        mapping(address => FailedRoyaltyPay) storage failedRoyaltyTransfers,
        uint256 _tokenId
    ) external {
        require(tokenIdToMarketItem[_tokenId].isERC20exists);
        uint256 _amount = tokenIdToMarketItem[_tokenId].highestBid;
        address nftContract = tokenIdToMarketItem[_tokenId].nftContract;
        IERC721 _nftContract = IERC721(nftContract);

        address erc20Token = tokenIdToMarketItem[_tokenId]
            .paymentToken
            .tokenAddress;

        address payable seller = payable(msg.sender);
        require(seller != address(0), "caller zero address.");

        address highestBidder = tokenIdToMarketItem[_tokenId].highestBidder;

        (address _royaltyReceiver, uint256 _royaltyAmount) = _royalty(
            _tokenId,
            _amount,
            nftContract
        );

        // transfer value

        if (msg.sender == tokenIdToMarketItem[_tokenId].creator) {
            // bool success1 = IERC20(erc20Token).transfer(seller, _amount);
            // require(success1, "IERC20: TF");

            /// saving the amount in seller mapping to be withdrawn later by the seller
            /// used instead of sending the value.
            drawableSeller[seller].erc = _amount - _amount;
        } else {
            // paying to seller after royalty deduction
            // bool _sellerPayment = IERC20(erc20Token).transfer(
            //     seller,
            //     (_amount - _royaltyAmount)
            // );
            // require(_sellerPayment, "IERC20: TF to Seller!");

            /// saving the amount in seller mapping to be withdrawn later by the seller
            /// used instead of sending the value.
            drawableSeller[seller].erc = _amount - _royaltyAmount;

            // sending royalty to creator

            bool _royaltyTansfer = IERC20(erc20Token).transfer(
                _royaltyReceiver,
                _royaltyAmount
            );
            if (!_royaltyTansfer) {
                failedRoyaltyTransfers[_royaltyReceiver] = FailedRoyaltyPay(
                    _tokenId,
                    _royaltyAmount,
                    erc20Token
                );
            }
        }

        //deducting withdrawable ERC20 balance 'amount' from highest bidder

        delete drawablesBidder[highestBidder][erc20Token][_tokenId].erc;

        //transfer asset

        _transferAsset(tokenIdToMarketItem, _nftContract, _tokenId);

        // to reset all value to zero for the token-Id sold
    }

    function EThAndAssetTransfer(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        mapping(address => DrawableSeller) storage drawableSeller,
        mapping(address => mapping(address => mapping(uint256 => DrawableBidder)))
            storage drawablesBidder,
        mapping(address => FailedRoyaltyPay) storage failedRoyaltyTransfers,
        uint256 _tokenId
    ) external {
        uint256 _amount = tokenIdToMarketItem[_tokenId].highestBid;
        address nftContract = tokenIdToMarketItem[_tokenId].nftContract;
        IERC721 _nftContract = IERC721(nftContract);

        address payable seller = payable(msg.sender);
        require(seller != address(0), "caller zero address.");

        address highestBidder = tokenIdToMarketItem[_tokenId].highestBidder;
        (address _royaltyReceiver, uint256 _royaltyAmount) = _royalty(
            _tokenId,
            _amount,
            nftContract
        );
        if (msg.sender == tokenIdToMarketItem[_tokenId].creator) {
            // sending the Eth to seller

            // (bool success2, ) = seller.call{value: _amount}("");

            // require(success2, "Market: Ether TF to seller!");

            /// saving the amount to seller mapping to be withdrawn later by the  seller
            drawableSeller[seller].eth = _amount;
        } else {
            // sending the Eth to seller after deducting royalty

            // (bool _sellerPayment, ) = seller.call{
            //     value: (_amount - _royaltyAmount)
            // }("");

            // require(_sellerPayment, "Market: Ether TF to Seller!");

            drawableSeller[seller].eth = _amount - _royaltyAmount;

            // sending royalty to creator
            (bool _royaltyrPayment, ) = _royaltyReceiver.call{
                value: _royaltyAmount
            }("");

            require(_royaltyrPayment, "Market: Ether TF to Creator!");

            if (!_royaltyrPayment) {
                failedRoyaltyTransfers[_royaltyReceiver] = FailedRoyaltyPay(
                    _tokenId,
                    _royaltyAmount,
                    address(0)
                );
            }
        }

        //deducting withdrawable Eth balance 'amount' from highest bidder
        delete drawablesBidder[highestBidder][
            0x0000000000000000000000000000000000000000
        ][_tokenId].eth;

        // transeferring NFT to highest bidder

        _transferAsset(tokenIdToMarketItem, _nftContract, _tokenId);

        // to reset all value to zero for the token Id sole
    }

    function _transferAsset(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        IERC721 _nft,
        uint256 _tokenId
    ) private {
        address highestBidder = tokenIdToMarketItem[_tokenId].highestBidder;

        address seller = tokenIdToMarketItem[_tokenId].creator;

        _nft.transferFrom(seller, highestBidder, _tokenId);
    }

    function transferEth(address payable to, uint256 amount)
        external
        returns (bool sent)
    {
        (sent, ) = to.call{value: amount}("");
        require(sent, "TransferMarketLib: TF");
        return sent;
    }

    /// ROYALTY INFO FOR DEDUCTING AMOUNT

    function _royalty(
        uint256 _tokenId,
        uint256 _soldPrice,
        address nftContract
    ) private view returns (address _royaltyRecipient, uint256 _royaltyAmount) {
        (_royaltyRecipient, _royaltyAmount) = IERC2981(address(nftContract))
            .royaltyInfo(_tokenId, _soldPrice);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {ILazyMintMarket} from "./ILazyMintMarket.sol";

struct MarketItem {
    uint256 tokenId;
    uint256 minPrice;
    // uint256 buyNowPrice;
    string uri;
    address payable creator;
    address payable buyer;
    address nftContract;
    PaymentToken paymentToken;
    uint256 bidStartsAt;
    uint256 bidEndsAt;
    uint256 highestBid;
    bool isBidActive;
    address highestBidder;
    bool isERC20exists;
    bool isListed;
}

struct PaymentToken {
    address tokenAddress;
    uint256 cost;
}

struct FailedRoyaltyPay{
    uint256 tokenId;
    uint256 amount;
    address erc20Address;
}

interface INonLazyMarket is ILazyMintMarket {}

// SPDX-License-Identifier: MIT

import "../lib/Require.sol";
import "../interfaces/ILazyMintMarket.sol";
import "../interfaces/ILazyNFT.sol";
import "../interfaces/INonLazyMarket.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Require.sol";

pragma solidity ^0.8.7;

library CreateMarketLib {
    function createMarketItemNormalMintWithEtherPrice(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        uint256 _tokenId,
        uint256 _price,
        // uint256 _buyNowPrice,
        string memory _uri,
        uint256 _bidStartsAt,
        uint256 _bidEndsAt,
        address _nftContract
    ) external {
        tokenIdToMarketItem[_tokenId] = MarketItem({
            tokenId: _tokenId,
            minPrice: _price,
            // buyNowPrice: _buyNowPrice,
            uri: _uri,
            creator: payable(msg.sender),
            buyer: payable(address(0)),
            nftContract: _nftContract,
            paymentToken: PaymentToken(address(0), 0),
            bidStartsAt: _bidStartsAt,
            bidEndsAt: _bidEndsAt,
            highestBid: 0,
            isBidActive: true,
            highestBidder: address(0),
            isERC20exists: false,
            isListed: true
        });
    }

    function MakeABidWithEth(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        mapping(address => mapping(address => mapping(uint256 => DrawableBidder)))
            storage drawablesBidder,
        mapping(address => mapping(uint256 => uint256)) storage isBidderOf,
        uint256 _tokenId,
        address _nftContract
    ) external {
        require(msg.sender != address(0), "Invalid address");

        require(
            CheckIf.isListedAndActive(tokenIdToMarketItem, _tokenId),
            "Market: not available."
        );

        require(
            tokenIdToMarketItem[_tokenId].bidEndsAt > block.timestamp,
            "Market: already ended."
        );

        // Can't bid on your own NFT

        require(
            msg.sender != IERC721(_nftContract).ownerOf(_tokenId),
            "Market: owner not allowed!"
        );

        require(
            (!CheckIf.isERC20exits(tokenIdToMarketItem, _tokenId)),
            "Market: only market item priced in Eth!"
        );

        if (drawablesBidder[msg.sender][address(0)][_tokenId].isBidder = true) {
            // fetching the previous bid amount
            uint256 previousBidAmount = isBidderOf[msg.sender][_tokenId];

            // calculating the difference to be send with bid

            uint256 differenceBidAmount = tokenIdToMarketItem[_tokenId]
                .highestBid - previousBidAmount;

            // ensuring value sent by the repeat bidder is higher then the difference amount

            require(
                msg.value > differenceBidAmount,
                "Market: must be > the last bid!"
            );

            // new highest bid

            uint256 _newHeighestBid = previousBidAmount + msg.value;

            MarketItem memory _item = tokenIdToMarketItem[_tokenId];

            _item.isBidActive = true;
            _item.highestBid = _newHeighestBid;
            _item.highestBidder = msg.sender;

            /** @dev updating the values of item to storage */
            tokenIdToMarketItem[_tokenId] = _item;

            // drawablesBidder[msg.sender][voucher.tokenId].isBidder = true;
            drawablesBidder[msg.sender][address(0)][_tokenId]
                .eth = _newHeighestBid;

            drawablesBidder[msg.sender][address(0)][_tokenId].isBidder = true;

            isBidderOf[msg.sender][_tokenId] = _newHeighestBid;
        } else {
            require(
                CheckIf.isBidHigherEth(tokenIdToMarketItem, _tokenId) &&
                    msg.value >= tokenIdToMarketItem[_tokenId].minPrice,
                "Increase ETH value"
            );

            // MarketItem memory _item = tokenIdToMarketItem[_tokenId];

            // _item.started = true;
            // _item.highestBid = msg.value;
            // _item.highestBidder = msg.sender;

            // /** @dev updating the values of vBids to storage VocherBids */
            // tokenIdToMarketItem[_tokenId] = _item;

            // // drawablesBidder[msg.sender][voucher.tokenId].isBidder = true;
            // drawablesBidder[msg.sender][
            //     0x0000000000000000000000000000000000000000
            // ][voucher.tokenId].eth = msg.value;

            // drawablesBidder[msg.sender][
            //     0x0000000000000000000000000000000000000000
            // ][voucher.tokenId].isBidder = true;
            // isBidderOf[msg.sender][voucher.tokenId] += msg.value;

            drawablesBidder[msg.sender][address(0)][_tokenId].eth = msg.value;
            drawablesBidder[msg.sender][address(0)][_tokenId].isBidder = true;

            /** @dev below line of code 'isBidderOf' is only used in makeABidwithEth and withdrawEther function only.*/
            /** @dev It is not used in adding or substracting ether amount of a bidder.*/
            isBidderOf[msg.sender][_tokenId] = msg.value;

            // updating market item values to  storage

            tokenIdToMarketItem[_tokenId].highestBid = msg.value;
            tokenIdToMarketItem[_tokenId].highestBidder = msg.sender;
            tokenIdToMarketItem[_tokenId].isBidActive = true;
            tokenIdToMarketItem[_tokenId].isListed = true;
        }

        ////////////////////////////////////////////////////////////////////////////////////////////////////
    }

//     function cancelBidWith(
//         mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
//         mapping(address => mapping(address => mapping(uint256 => DrawableBidder)))
//             storage drawablesBidder,
//         mapping(address => mapping(uint256 => uint256)) storage isBidderOf,
//         uint256 _tokenId,
//         address _nftContract
//     ) external {
//         require(msg.sender != address(0), "Invalid address");

//         require(msg.sender != tokenIdToMarketItem[_tokenId].highestBidder, "Market: highest bidder not allowed!");

//         require(
//             tokenIdToMarketItem[_tokenId].bidEndsAt > block.timestamp,
//             "Market: bid already ended."
//         );

//         require(
//             CheckIf.isListedAndActive(tokenIdToMarketItem, _tokenId),
//             "Market: Not available."
//         );

//         require(
//             msg.sender == IERC721(_nftContract).ownerOf(_tokenId),
//             "Market: only owner allowed!"
//         );

//         //     uint256 tokenId;


//         MarketItem memory item = tokenIdToMarketItem[_tokenId];
//  }


    // function cancelBidWithEth(
    //     mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
    //     // mapping(address => mapping(address => mapping(uint256 => DrawableBidder)))
    //     //     storage drawablesBidder,
    //     // mapping(address => mapping(uint256 => uint256)) storage isBidderOf,
    //     uint256 _tokenId,
    //     address _nftContract
    // ) external {
    //     require(msg.sender != address(0), "Invalid address");

    //     require(msg.sender != tokenIdToMarketItem[_tokenId].highestBidder, "Market: highest bidder not allowed!");

    //     require(
    //         tokenIdToMarketItem[_tokenId].bidEndsAt > block.timestamp,
    //         "Market: bid already ended."
    //     );

    //     require(
    //         CheckIf.isListedAndActive(tokenIdToMarketItem, _tokenId),
    //         "Market: Not available."
    //     );

    //     require(
    //         msg.sender == IERC721(_nftContract).ownerOf(_tokenId),
    //         "Market: only owner allowed!"
    //     );

    //     // deleting market item
    //     delete tokenIdToMarketItem[_tokenId];
    // }

    function createMarketItemforNormalMintWithERC20tokenPrice(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        uint256 _tokenId,
        uint256 _cost,
        // uint256 _buyNowPrice,
        string memory _uri,
        address _nftContract,
        address _paymentToken,
        uint256 _bidStartsAt,
        uint256 _bidEndsAt
    ) external {
        tokenIdToMarketItem[_tokenId] = MarketItem({
            tokenId: _tokenId,
            minPrice: _cost,
            // buyNowPrice: _buyNowPrice,
            uri: _uri,
            creator: payable(msg.sender),
            buyer: payable(address(0)),
            nftContract: _nftContract,
            paymentToken: PaymentToken(_paymentToken, _cost),
            bidStartsAt: _bidStartsAt,
            bidEndsAt: _bidEndsAt,
            highestBid: 0,
            isBidActive: true,
            highestBidder: address(0),
            isERC20exists: true,
            isListed: true
        });
    }

    function makeAbidWithERC20(
        mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
        mapping(address => mapping(address => mapping(uint256 => DrawableBidder)))
            storage drawablesBidder,
        mapping(address => mapping(uint256 => uint256))
            storage pendingERC20Withdrawal,
        uint256 _tokenId,
        address _nftContract,
        uint256 _newBidinERC20
    ) external {
        require(msg.sender != address(0), "Invalid address");

        require(
            tokenIdToMarketItem[_tokenId].bidEndsAt > block.timestamp,
            "Market: already ended."
        );

        require(
            CheckIf.isListedAndActive(tokenIdToMarketItem, _tokenId),
            "Market: Not available."
        );

        // Can't bid on your own NFT

        require(
            msg.sender != IERC721(_nftContract).ownerOf(_tokenId),
            "Market: owner not allowed!"
        );

        require(
            tokenIdToMarketItem[_tokenId].isERC20exists,
            "Market: token not priced in ERC20."
        );

        // check to ensure bid amount is higher than the last highest bid
        //  if the biddier is the very first bidder, then the bid must be higher than the cost set by the seller in PaymentToken struct //

        // require(
        //     _newBidinERC20 > tokenIdToMarketItem[_tokenId].paymentToken.cost &&
        //         _newBidinERC20 > tokenIdToMarketItem[_tokenId].highestBid,
        //     "Bid higher ERC20"
        // );

        // Transferring ERC20 to marketpalce. Market must be approved by the  bidder to transfer ERC20

        address _paymentToken = tokenIdToMarketItem[_tokenId]
            .paymentToken
            .tokenAddress;

        if (drawablesBidder[msg.sender][_paymentToken][_tokenId].isBidder) {
            uint256 _previousBidAmount = drawablesBidder[msg.sender][
                _paymentToken
            ][_tokenId].erc;

            uint256 _differenceBidAmount = tokenIdToMarketItem[_tokenId]
                .highestBid - _previousBidAmount;

            /// below line of code assures a repeat bidder sending the right difference amount

            require(
                _newBidinERC20 > _differenceBidAmount,
                "Market: must be > the last bid!"
            );

            uint256 _newHeighestBid = _previousBidAmount + _newBidinERC20;

            bool _ERC20TransferToMarket = IERC20(_paymentToken).transferFrom(
                msg.sender,
                address(this),
                _newHeighestBid
            );

            require(_ERC20TransferToMarket, "Market: ERC20 TF");

            drawablesBidder[msg.sender][_paymentToken][_tokenId]
                .erc = _newHeighestBid;

            drawablesBidder[msg.sender][_paymentToken][_tokenId]
                .isBidder = true;

            // pendingWithdrawalsERC20[msg.sender][_token] += _newBidinERC20;

            // below line of  code for restriction in ERC20 withdrawls by bidder

            pendingERC20Withdrawal[msg.sender][_tokenId] = _newHeighestBid;

            tokenIdToMarketItem[_tokenId].highestBidder = msg.sender;

            tokenIdToMarketItem[_tokenId].highestBid = _newHeighestBid;

            tokenIdToMarketItem[_tokenId].isBidActive = true;
        } else {
            require(
                CheckIf.isBidHigherERC(
                    tokenIdToMarketItem,
                    _newBidinERC20,
                    _tokenId
                ) && _newBidinERC20 > tokenIdToMarketItem[_tokenId].highestBid,
                "Bid higher ERC20"
            );
            bool _erc20TransferToMarket = IERC20(_paymentToken).transferFrom(
                msg.sender,
                address(this),
                _newBidinERC20
            );

            require(_erc20TransferToMarket, "Market: erc20 TF");

            drawablesBidder[msg.sender][_paymentToken][_tokenId]
                .erc = _newBidinERC20;

            drawablesBidder[msg.sender][_paymentToken][_tokenId]
                .isBidder = true;

            // pendingWithdrawalsERC20[msg.sender][_token] += _newBidinERC20;

            // below line of  code for restriction in ERC20 withdrawls by bidder

            pendingERC20Withdrawal[msg.sender][_tokenId] = _newBidinERC20;

            tokenIdToMarketItem[_tokenId].highestBidder = msg.sender;

            tokenIdToMarketItem[_tokenId].highestBid = _newBidinERC20;

            tokenIdToMarketItem[_tokenId].isBidActive = true;

            tokenIdToMarketItem[_tokenId].isListed = true;
        }
    }

    function isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    /// @notice To start a Bid for an nft

    // function makeAbid(
    //     mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
    //     mapping(address => uint256) storage drawableSeller,
    //     address _nftContract,
    //     uint256 _tokenId,
    //     uint256 _newBidinERC20
    // ) public payable {
    //     // bidExits[_tokenId] = true;

    //     require(msg.sender != address(0), "Invalid address");

    //     // require(
    //     //     tokenIdToMarketItem[_tokenId].isListed &&
    //     //         tokenIdToMarketItem[_tokenId].isBidActive,
    //     //     "Market: Not available."
    //     // );
    //     require(
    //         CheckIf.isListedAndActive(tokenIdToMarketItem, _tokenId),
    //         "Market: Not available."
    //     );

    //     require(
    //         tokenIdToMarketItem[_tokenId].bidEndsAt > block.timestamp,
    //         "Market: already ended."
    //     );

    //     // Can't bid on your own NFT

    //     require(
    //         msg.sender != IERC721(_nftContract).ownerOf(_tokenId),
    //         "Market: owner not allowed!"
    //     );

    //     if (msg.value != 0) {
    //         // require(
    //         //     !tokenIdToMarketItem[_tokenId].isERC20exits,
    //         //     "Market: ERC20 token only! "
    //         // );

    //         require(
    //             (!CheckIf.isERC20exits(tokenIdToMarketItem, _tokenId)),
    //             "Market: ERC20 token only!"
    //         );

    //         // require(
    //         //     msg.value > tokenIdToMarketItem[_tokenId].highestBid &&
    //         //         msg.value >= tokenIdToMarketItem[_tokenId].minPrice,
    //         //     "Increase ETH value"
    //         // );
    //         require(
    //             CheckIf.isBidHigherEth(tokenIdToMarketItem, _tokenId) &&
    //                 msg.value >= tokenIdToMarketItem[_tokenId].minPrice,
    //             "Increase ETH value"
    //         );
    //         emit BidMade(msg.sender, msg.value, _tokenId);

    //         drawablesBidder[msg.sender][_tokenId].eth += msg.value;

    //         tokenIdToMarketItem[_tokenId].highestBid = msg.value;
    //         isBidderOf[msg.sender][_tokenId] += msg.value;
    //         tokenIdToMarketItem[_tokenId].bidders.push(msg.sender);
    //         drawablesBidder[msg.sender][_tokenId].isBidder = true;
    //         tokenIdToMarketItem[_tokenId].isBidActive = true;
    //     } else {
    //         require(tokenIdToMarketItem[_tokenId].isERC20exits);

    //         // check to ensure bid amount is higher than the last highest bid
    //         //  if the biddier is the very first bidder, then the bid must be higher than the cost set by the seller in PaymentToken struct //

    //         // require(
    //         //     _newBidinERC20 >
    //         //         tokenIdToMarketItem[_tokenId].paymentToken.cost &&
    //         //         _newBidinERC20 > tokenIdToMarketItem[_tokenId].highestBid,
    //         //     "Bid higher ERC20"
    //         // );
    //         require(
    //             CheckIf.isBidHigherERC(
    //                 tokenIdToMarketItem,
    //                 _newBidinERC20,
    //                 _tokenId
    //             ) && _newBidinERC20 > tokenIdToMarketItem[_tokenId].highestBid,
    //             "Bid higher ERC20"
    //         );

    //         emit BidMade(msg.sender, _newBidinERC20, _tokenId);

    //         // Transferring ERC20 to marketpalce. Market must be approved by the  bidder to transfer ERC20

    //         address _token = tokenIdToMarketItem[_tokenId]
    //             .paymentToken
    //             .tokenAddress;

    //         bool success = IERC20(_token).transferFrom(
    //             msg.sender,
    //             address(this),
    //             _newBidinERC20
    //         );

    //         require(success, "Market: ERC20 TF");

    //         drawablesBidder[msg.sender][_tokenId].erc += _newBidinERC20;
    //         pendingWithdrawalsERC20[msg.sender][_token] += _newBidinERC20;

    //         // below line of  code for restriction in ERC20 withdrawls by bidder

    //         pendingERC20Withdrawal[msg.sender][_tokenId] += _newBidinERC20;

    //         tokenIdToMarketItem[_tokenId].bidders.push(msg.sender);

    //         drawablesBidder[msg.sender][_tokenId].isBidder = true;

    //         tokenIdToMarketItem[_tokenId].highestBid = _newBidinERC20;

    //         tokenIdToMarketItem[_tokenId].isBidActive = true;
    //     }
    // }

    // function acceptBidNonLazyNFT(
    //     mapping(uint256 => MarketItem) storage tokenIdToMarketItem,
    //     mapping(address => uint256) storage drawableSeller,
    //     mapping(address => uint256) storage drawablesBidder,
    //     IERC721 _nftContract,
    //     uint256 _tokenId
    // ) public payable nonReentrant {
    //     /**@dev ---Sanity check------------------- */
    //     require(
    //         (IERC721(_nftContract).ownerOf(_tokenId) == msg.sender),
    //         "Only NFT-owner"
    //     );
    //     // require(drawableSeller[msg.sender].isSeller, "Market: Only sellers.");
    //     require(CheckIf.isSeller(drawableSeller), "Market: Only sellers.");
    //     // require(
    //     //     tokenIdToMarketItem[_tokenId].isListed &&
    //     //         tokenIdToMarketItem[_tokenId].isBidActive,
    //     //     "Market: id not listed or no bid on it"
    //     // );
    //     require(
    //         CheckIf.isListedAndActive(tokenIdToMarketItem, _tokenId),
    //         "Market: id not listed or no bid on it"
    //     );
    //     address payable seller = payable(msg.sender);
    //     require(seller != address(0), "caller zero address.");

    //     address highestBidder = tokenIdToMarketItem[_tokenId].bidders[
    //         tokenIdToMarketItem[_tokenId].bidders.length - 1
    //     ];

    //     /**@dev end of sanit check------------------- */

    //     /** @dev tranfer of value and assets starts */

    //     if (tokenIdToMarketItem[_tokenId].isERC20exits) {
    //         /**-------------------------------------------------------------*/

    //         // USING "ERC20AndAssetTransfer"LIBRARY TO PERFORM THE TRANSFER FUNCTIONS
    //         tokenIdToMarketItem.ERC20AndAssetTransfer(
    //             drawablesBidder,
    //             _tokenId
    //         );

    //         /**------------------------------------------------------------*/

    //         uint256 amount = tokenIdToMarketItem[_tokenId].highestBid;

    //         emit MarketItemSold(seller, highestBidder, _tokenId, amount);

    //         delete tokenIdToMarketItem[_tokenId];

    //         // wasListed[_tokenId][address(_nftContract)] = true;
    //     } else {
    //         // storing  highest bid into 'amount' of Eth to send it to seller
    //         uint256 amount = tokenIdToMarketItem[_tokenId].highestBid;

    //         emit MarketItemSold(seller, highestBidder, _tokenId, amount);

    //         /**-------------------------------------------------------------*/

    //         // USING "ERC20AndAssetTransfer"LIBRARY TO PERFORM THE TRANSFER FUNCTIONS

    //         tokenIdToMarketItem.EThAndAssetTransfer(drawablesBidder, _tokenId);

    //         /**-------------------------------------------------------------*/

    //         delete tokenIdToMarketItem[_tokenId];

    //         // wasListed[_tokenId][address(_nftContract)] = true;
    //     }

    //     // require(bidState[_tokenId][address(_nftContract)] == BidState(1), "Bid's not put to Closed at the and of accept bid");
    // }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
struct NFTVoucher {
    address creator;
    /// @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
    uint256 tokenId;
    /// @notice The minimum price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
    uint256 minPrice;
    /// @notice The creator royalty in BPS. Must not be in the range of 0% to 10% of sale price. Example: 10% royalty in BPS is 10% * 100 = 1000
    uint256 royaltyBPS;
    /// @notice The metadata URI to associate with this token.
    string uri;
    /// @notice the EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
    bytes signature;
}

interface ILazyNFT is IERC721 {
    struct RoyaltyReceiver {
        address payable creator;
        uint256 royaltyInBP;
    }
    event EtherReceived(address indexed sender, uint256 indexed value);
    event EtherReceivedFallback(address indexed sender, uint256 indexed value);
    event EtherWithdrawn(address indexed withdrawer, uint256 indexed value);
    event MarketPlaceAddressChanged(address indexed newAddress);
    event ListingFeeChanged(uint96 indexed amount);

    function redeem(
        address redeemer,
        address signer,
        NFTVoucher calldata voucher
    ) external returns (uint256);

    // function nonLazyMint(address to, string memory _uri)
    //     external
    //     payable
    //     returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// contract defines all events, DrawableBidder and DrawableSeller which are shared by other interfaces and contracts

// struct MarketItem {
//     uint256 tokenId;
//     uint256 minPrice;
//     uint256 buyNowPrice;
//     string uri;
//     address payable creator;
//     address payable buyer;
//     address nftContract;
//     PaymentToken paymentToken;
//     uint256 bidStartsAt;
//     uint256 bidEndsAt;
//     uint256 highestBid;
//     bool isBidActive;
//     address[] bidders;
//     //Bid bid;
//     bool isERC20exists;
//     bool isListed;
// }

// struct PaymentToken {
//     address tokenAddress;
//     uint256 cost;
// }

struct DrawableBidder {
    uint256 eth;
    uint256 erc;
    bool isBidder;
}

struct DrawableSeller {
    uint256 eth;
    uint256 erc;
    bool isSeller;
}

// struct Bid {
//     uint256 bidStartsAt;
//     uint256 bidEndsAt;
//     uint256 highestBid;
//     bool isBidActive;
//     bool bidSuccess;
//     bool bidInit;
//     address[] bidders;
//     address paymentToken;
// }
// struct VoucherBids {
//     bool started;
//     bool listed;
//     uint256 endsAt;
//     address highestBidder;
//     uint256 highestBid;
//     address paymentToken;
// }

interface ILazyMintMarket {
    event MarketItemCreated(
        address indexed creator,
        uint256 indexed tokenId,
        uint256 indexed minPrice
        // uint256 buyNowPrice
    );

    event MarketItemCancelled(
        address indexed cancelledBy,
        uint256 indexed tokenId
    );

    event MarketItemSold(
        address indexed seller,
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 soldTime,
        uint256 sellPrice
    );

    event BidMade(
        address indexed Bidder,
        uint256 indexed BidAmount,
        uint256 indexed tokenId
    );

    event ERC20withdrawal(
        address indexed receiever,
        uint256 indexed amount,
        address indexed _ERC20token
    );
    event Etherwithdrawal(address indexed receiver, uint256 indexed value);
    event EtherReceived(address indexed sender, uint256 indexed value);

    event VoucherERCMarketCreated(
        address indexed creator,
        address indexed erc20Token,
        uint256 minPrice,
        uint256 indexed endTime
    );
    event VoucherETHMarketCreated(
        address indexed creator,
        uint256 minEthPrice,
        uint256 indexed endTime
    );

    event VoucherUnlisted(uint256 indexed voucherId);
    event MarketFeeChanged(address indexed feeSetter, uint96 indexed amount);
    // struct Drawable {
    //     uint256 eth;
    //     uint256 erc;
    //     bool isBidder;
    //     bool isSeller;
    // }

    // struct Auction {
    //     //map token ID to
    //     uint32 bidIncreasePercentage;
    //     uint32 auctionBidPeriod; //Increments the length of time the auction is open in which a new bid can be made after each bid.
    //     uint64 auctionEnd;
    //     uint128 minPrice;
    //     uint128 buyNowPrice;
    //     uint128 nftHighestBid;
    //     address nftHighestBidder;
    //     address nftSeller;
    //     address whitelistedBuyer; //The seller can specify a whitelisted address for a sale (this is effectively a direct sale).
    //     address nftRecipient; //The bidder can specify a recipient for the NFT if their bid is successful.
    //     address ERC20Token; // The seller can specify an ERC20 token that can be used to bid or purchase the NFT.
    //     address[] feeRecipients;
    //     uint32[] feePercentages;
    // }
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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