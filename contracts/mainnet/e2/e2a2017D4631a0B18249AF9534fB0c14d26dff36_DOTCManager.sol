//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "../dOTCTokens/TokenListManager.sol";
import "../permissioning/PermissionManager.sol";
import "../interfaces/IdOTC.sol";
import "./Permissions/AdminFunctions.sol";
import "../interfaces/IEscrow.sol";

contract DOTCManager is ERC1155Holder, IdOTC, AdminFunctions, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _offerId;
    Counters.Counter private _nftOfferId;
    Counters.Counter private _takerOrdersId;
    Counters.Counter private _nftOrdersId;

    /**
     *    @dev takerOrders this is store partial offer takers,
     *    ref the offerId  to the taker address and ref the amount paid
     */
    mapping(uint256 => Order) internal takerOrders;
    mapping(uint256 => NftOrder) internal nftTakerOrders;
    mapping(uint256 => Offer) internal allOffers;
    mapping(address => Offer[]) internal offersFromAddress;
    mapping(address => Offer[]) internal takenOffersFromAddress;
    mapping(address => Offer[]) internal takenNftOffersFromAddress;
    mapping(uint256 => Offer) internal allNftOffers;

    // Event Of the DOTC SC

    event CreatedOffer(
        uint256 indexed offerId,
        address indexed maker,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        OfferType offerType,
        address specialAddress,
        bool isComplete,
        uint256 expiryTime
    );
    event CreatedOrder(
        uint256 indexed offerId,
        uint256 indexed orderId,
        uint256 amountPaid,
        address indexed orderedBy,
        uint256 amountToReceive
    );
    event CompletedOffer(uint256 offerId);
    event CompletedNftOffer(uint256 indexed offerId);
    event CanceledOffer(uint256 indexed offerId, address canceledBy, uint256 amountToReceive);
    event freezeOffer(uint256 indexed offerId, address freezedBy);
    event unFreezeOffer(uint256 indexed offerId, address unFreezedBy);
    event AdminRemoveOffer(uint256 indexed offerId, address freezedBy);
    event CreatedNftOffer(
        uint256 indexed nftOfferId,
        address nftAddress,
        address tokenOutAddress,
        uint256 offerPrice,
        uint256[] nftIds,
        uint256[] nftAmounts,
        address specialAddress,
        uint256 expiresAt
    );
    event CreatedNftOrder(uint256 indexed nftOfferId, uint256 orderId, uint256 amount, address taker);
    event CanceledNftOffer(uint256 indexed offerId, address canceledBy);
    event TokenOfferUpdated(uint256 indexed offerId, uint256 newOffer);
    event NftOfferUpdated(uint256 indexed offerId, uint256 newOffer);

    constructor(address _tokenListManagerAddress, address _permission) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        tokenListManagerAddress = _tokenListManagerAddress;
        permissionAddress = _permission;
    }

    /**
     *  @dev makeOffer this create an Offer which can be sell or buy
     *  Requirements: msg.sender must be a Tier 2
     *  Requirements: _tokenInAddress and _tokenOutAddress must be allowed on swarm market
     *  @param  _amountOut uint256
     *  @param  _tokenInAddress address
     *  @param  _tokenOutAddress address
     *  @param  _amountIn uint256
     *  @param  _amountOut uint256
     *  @param  _expiryInDays uint256 in Days
     *  @param  _offerType uint8 is the offer PARTIAL or FULL
     *  @param _specialAddress special Adress of taker and if specified
     *  only this address can take the offer else anyone can take the offer
     *  @return offerId uint256
     */
    //  Address of specific taker
    function makeOffer(
        address _tokenInAddress,
        address _tokenOutAddress,
        uint256 _amountIn,
        uint256 _amountOut,
        uint256 _expiryInDays,
        uint8 _offerType,
        address _specialAddress
    )
        public
        allowedERC20Asset(_tokenInAddress)
        allowedERC20Asset(_tokenOutAddress)
        _accountIsTierTwo
        _accountSuspended
        nonReentrant
        returns (uint256 offerId)
    {
        require(IERC20(_tokenInAddress).balanceOf(msg.sender) >= (_amountIn), "Insufficient balance for transaction");
        require(_tokenInAddress != _tokenOutAddress, "Same ERC20 not allowed");
        require(_offerType <= uint8(OfferType.FULL), "Out of range");
        require(_amountIn > 0, "Invalid Amount In");
        require(_amountOut > 0, "Invalid Amount Out");
        _offerId.increment();
        uint256 currentOfferId = _offerId.current();
        Offer memory _offer =
            setOffer(
                currentOfferId,
                _amountIn,
                _tokenInAddress,
                _tokenOutAddress,
                _amountOut,
                _expiryInDays,
                OfferType(_offerType),
                _specialAddress
            );
        offersFromAddress[msg.sender].push(_offer);
        allOffers[currentOfferId] = _offer;
        IEscrow(allOffers[currentOfferId].escrowAddress).setMakerDeposit(currentOfferId);
        safeTransfertokenIn(_tokenInAddress, _amountIn);
        emit CreatedOffer(
            currentOfferId,
            msg.sender,
            _tokenInAddress,
            _tokenOutAddress,
            _amountIn,
            _amountOut,
            OfferType(_offerType),
            _specialAddress,
            false,
            _offer.expiryTime
        );
        return currentOfferId;
    }

    /**
     * @dev returns a memory for order Structure
     */
    function setOffer(
        uint256 _currentOfferId,
        uint256 _amountIn,
        address _tokenInAddress,
        address _tokenOutAddress,
        uint256 _amountOut,
        uint256 _expiryInDays,
        OfferType _offerType,
        address _specialAddress
    ) internal view returns (Offer memory offer) {
        uint256 sandaradAmountIn = standardiseNumber(_amountIn, _tokenInAddress);
        uint256 sandaradAmountOut = standardiseNumber(_amountOut, _tokenOutAddress);
        uint256[] memory emptyArray;
        Offer memory _offer =
            Offer({
                isNft: false,
                offerId: _currentOfferId,
                maker: msg.sender,
                tokenInAddress: _tokenInAddress,
                tokenOutAddress: _tokenOutAddress,
                amountIn: sandaradAmountIn,
                availableAmount: sandaradAmountIn,
                expiryTime: block.timestamp + (_expiryInDays * 1 days),
                unitPrice: sandaradAmountOut.mul(10**DECIMAL).div(sandaradAmountIn),
                amountOut: sandaradAmountOut,
                fullyTaken: false,
                offerType: _offerType,
                specialAddress: address(_specialAddress),
                escrowAddress: escrow,
                offerFee: feeAmount,
                nftIds: emptyArray, // list nft ids
                nftAddress: address(0),
                offerPrice: 0,
                nftAmounts: emptyArray
            });
        return _offer;
    }

    /**
     *  @dev takeOffer this take an Offer that is available
     *  Requirements: msg.sender must be a Tier 2
     *  @param  offerId uint256
     *  @param  _amount uint256
     */
    function takeOffer(
        uint256 offerId,
        uint256 _amount,
        uint256 minExpectedAmount
    ) public isSpecial(offerId) isAvailable(offerId) can_buy(offerId) nonReentrant returns (uint256 takenOderId) {
        uint256 amountToReceiveByTaker = 0;
        uint256 standardAmount = standardiseNumber(_amount, allOffers[offerId].tokenOutAddress);
        require(_amount > 0, "Amount is zero");
        require(standardAmount <= allOffers[offerId].amountOut, "Amount is greater than offer");
        require(IERC20(allOffers[offerId].tokenOutAddress).balanceOf(msg.sender) >= _amount, "Insufficient balance");

        if (allOffers[offerId].offerType == OfferType.FULL) {
            require(standardAmount == allOffers[offerId].amountOut, "This is a Full Request");
            amountToReceiveByTaker = allOffers[offerId].amountIn;
            allOffers[offerId].amountOut = 0;
            allOffers[offerId].availableAmount = 0;
            allOffers[offerId].fullyTaken = true;
            emit CompletedOffer(offerId);
        } else {
            if (standardAmount == allOffers[offerId].amountOut) {
                amountToReceiveByTaker = allOffers[offerId].availableAmount;
                allOffers[offerId].amountOut = 0;
                allOffers[offerId].availableAmount = 0;
                emit CompletedOffer(offerId);
            } else {
                amountToReceiveByTaker = standardAmount.mul(10**DECIMAL).div(allOffers[offerId].unitPrice);
                allOffers[offerId].amountOut -= standardAmount;
                allOffers[offerId].availableAmount -= amountToReceiveByTaker;
            }
        }
        if (allOffers[offerId].amountOut == 0) {
            allOffers[offerId].fullyTaken = true;
            emit CompletedOffer(offerId);
        }
        takenOffersFromAddress[msg.sender].push(allOffers[offerId]);
        _takerOrdersId.increment();
        uint256 orderId = _takerOrdersId.current();
        takerOrders[orderId] = Order(
            offerId,
            _amount,
            msg.sender,
            amountToReceiveByTaker,
            standardiseNumber(minExpectedAmount, allOffers[offerId].tokenInAddress)
        );
        uint256 amountFeeRatio = _amount.mul(allOffers[offerId].offerFee).div(BPSNUMBER);
        IEscrow(allOffers[offerId].escrowAddress).withdrawDeposit(offerId, orderId);
        payFee(allOffers[offerId].tokenOutAddress, amountFeeRatio);
        safeTransferAsset(
            allOffers[offerId].tokenOutAddress,
            allOffers[offerId].maker,
            msg.sender,
            (_amount.sub(amountFeeRatio))
        );
        uint256 realAmount = unstandardisedNumber(amountToReceiveByTaker, allOffers[offerId].tokenInAddress);
        emit CreatedOrder(offerId, orderId, _amount, msg.sender, realAmount);
        return orderId;
    }

    /**
     *  @dev cancel an offer, refunds offer maker.
     *  @param offerId uint256 order id
     */
    function cancelOffer(uint256 offerId) external can_cancel(offerId) nonReentrant returns (bool success) {
        Offer memory offer = allOffers[offerId];
        delete allOffers[offerId];
        uint256 _amountToSend = offer.amountOut.mul(10**DECIMAL).div(offer.unitPrice);
        uint256 realAmount = unstandardisedNumber(_amountToSend, offer.tokenInAddress);
        require(_amountToSend > 0, "can not cancel");
        require(
            IEscrow(offer.escrowAddress).cancelDeposit(offerId, offer.tokenInAddress, offer.maker, realAmount),
            "Can not cancel offer"
        );
        emit CanceledOffer(offerId, msg.sender, _amountToSend);
        return true;
    }

    function makeNFTOffer(
        address _nftAddress,
        address _tokenOutAddress,
        uint256[] memory _nftIds,
        uint256[] memory _nftAmounts,
        uint256 _offerPrice,
        uint256 _expiryInDays,
        address _specialAddress
    )
        public
        allowedERC1155Asset(_nftAddress)
        allowedERC20Asset(_tokenOutAddress)
        _accountIsTierTwo
        _accountSuspended
        nonReentrant
        returns (uint256 offerId)
    {
        _nftOfferId.increment();
        uint256 currentOfferId = _nftOfferId.current();
        Offer memory offer =
            Offer({
                isNft: true,
                offerId: currentOfferId,
                tokenInAddress: address(0),
                amountIn: 0,
                unitPrice: 0,
                amountOut: 0,
                offerType: OfferType.FULL,
                nftAddress: _nftAddress,
                tokenOutAddress: _tokenOutAddress,
                availableAmount: 0,
                nftIds: _nftIds,
                offerPrice: _offerPrice,
                nftAmounts: _nftAmounts,
                expiryTime: block.timestamp + (_expiryInDays * 1 days),
                specialAddress: _specialAddress,
                escrowAddress: escrow,
                offerFee: feeAmount,
                maker: msg.sender,
                fullyTaken: false
            });
        allNftOffers[currentOfferId] = offer;
        IEscrow(escrow).setNFTDeposit(currentOfferId);
        IERC1155(_nftAddress).safeBatchTransferFrom(msg.sender, escrow, _nftIds, _nftAmounts, bytes(""));
        emit CreatedNftOffer(
            currentOfferId,
            _nftAddress,
            _tokenOutAddress,
            _offerPrice,
            _nftIds,
            _nftAmounts,
            _specialAddress,
            offer.expiryTime
        );
        return currentOfferId;
    }

    /**
     *  @dev takeNftOffer this take an nft Offer that is available
     *  Requirements: msg.sender must be a Tier 2
     *  @param  nftOfferId uint256
     *  @param  _amount uint256
     */
    function takeNftOffer(uint256 nftOfferId, uint256 _amount)
        public
        isSpecialNftOffer(nftOfferId)
        nftOfferIsAvailable(nftOfferId)
        canBuyNftOffer(nftOfferId)
        nonReentrant
        returns (uint256 takenOderId)
    {
        require(_amount > 0, "Amount is zero");
        require(_amount == allNftOffers[nftOfferId].offerPrice, "Amount is greater than offer");
        require(
            IERC20(allNftOffers[nftOfferId].tokenOutAddress).balanceOf(msg.sender) >= _amount,
            "Insufficient balance"
        );
        allNftOffers[nftOfferId].fullyTaken = true;
        takenNftOffersFromAddress[msg.sender].push(allNftOffers[nftOfferId]);
        _nftOrdersId.increment();
        uint256 orderId = _nftOrdersId.current();
        nftTakerOrders[orderId] = NftOrder(
            nftOfferId,
            allNftOffers[nftOfferId].nftIds,
            _amount,
            allNftOffers[nftOfferId].nftAmounts,
            msg.sender
        );
        IEscrow(allNftOffers[nftOfferId].escrowAddress).withdrawNftDeposit(nftOfferId, orderId);
        IERC1155(allNftOffers[nftOfferId].nftAddress).safeBatchTransferFrom(
            allNftOffers[nftOfferId].escrowAddress,
            msg.sender,
            allNftOffers[nftOfferId].nftIds,
            allNftOffers[nftOfferId].nftAmounts,
            bytes("")
        );
        payFee(allNftOffers[nftOfferId].tokenOutAddress, _amount.mul(allNftOffers[nftOfferId].offerFee).div(BPSNUMBER));
        safeTransferAsset(
            allNftOffers[nftOfferId].tokenOutAddress,
            allNftOffers[nftOfferId].maker,
            msg.sender,
            (_amount - _amount.mul(feeAmount).div(BPSNUMBER))
        );
        emit CompletedNftOffer(nftOfferId);
        emit CreatedNftOrder(nftOfferId, orderId, _amount, msg.sender);
        return orderId;
    }

    /**
     * @dev update offer amountOut
     * @param offerId uint256
     * @param newOffer uint256
     * @return status bool
     */
    function updateOffer(
        uint256 offerId,
        uint256 newOffer,
        bool isNFT
    ) external returns (bool status) {
        require(newOffer > 0, "Invalid zeror amount");
        if (!isNFT) {
            require(allOffers[offerId].maker == msg.sender, "not offer owner");
            allOffers[offerId].amountOut = newOffer;
            allOffers[offerId].unitPrice = standardiseNumber(newOffer, allOffers[offerId].tokenOutAddress)
                .mul(10**DECIMAL)
                .div(allOffers[offerId].amountIn);
            emit TokenOfferUpdated(offerId, newOffer);
        } else {
            require(allNftOffers[offerId].maker == msg.sender, "not offer owner");
            allNftOffers[offerId].offerPrice = newOffer;
            emit NftOfferUpdated(offerId, newOffer);
        }
        return true;
    }

    /**
        @dev getOfferOwner returns the address of the maker
        @param offerId uint256 the Id of the order
        @return owner address
     */
    function getOfferOwner(uint256 offerId) external view override returns (address owner) {
        return allOffers[offerId].maker;
    }

    /**
     *  @dev cancel an NftOffer, refunds nft to maker.
     *  @param nftOfferId uint256 order id
     */
    function cancelNftOffer(uint256 nftOfferId) external nonReentrant returns (bool success) {
        Offer memory offer = allNftOffers[nftOfferId];
        require(offer.maker == msg.sender, "Not permitted");
        delete allNftOffers[nftOfferId];
        // cancel nft offer what happens we will take the nft from the escrow and send it to maker
        IEscrow(allNftOffers[nftOfferId].escrowAddress).cancelNftDeposit(nftOfferId);
        IERC1155(allNftOffers[nftOfferId].nftAddress).safeBatchTransferFrom(
            allNftOffers[nftOfferId].escrowAddress,
            msg.sender,
            allNftOffers[nftOfferId].nftIds,
            allNftOffers[nftOfferId].nftAmounts,
            bytes("")
        );
        emit CanceledNftOffer(nftOfferId, msg.sender);
        return true;
    }

    /**
        @dev getNftOfferOwner returns the address of the maker
        @param nftOfferId uint256 the Id of the order
        @return owner address
     */
    function getNftOfferOwner(uint256 nftOfferId) external view override returns (address owner) {
        return allNftOffers[nftOfferId].maker;
    }

    /**
     *  @dev getTaker returns the address of the taker
     *  @param orderId uint256 the id of the order
     *  @return taker address
     */
    function getTaker(uint256 orderId) external view override returns (address taker) {
        return takerOrders[orderId].takerAddress;
    }

    /**
     *  @dev getNftTaker returns the address of the taker
     *  @param _nftOrderId uint256 the id of the order
     *  @return taker address
     */
    function getNftTaker(uint256 _nftOrderId) external view override returns (address taker) {
        return nftTakerOrders[_nftOrderId].takerAddress;
    }

    /**
     *   @dev getOffer returns the Offer Struct of the offerId
     *   @param offerId uint256 the Id of the offer
     *   @return offer Offer
     */
    function getOffer(uint256 offerId) external view override returns (Offer memory offer) {
        return allOffers[offerId];
    }

    /**
     *   @dev getNftOffer returns the NFT Offer Struct of the nftOfferId
     *   @param nftOfferId uint256 the Id of the NftOffer
     *   @return offer Offer
     */
    function getNftOffer(uint256 nftOfferId) external view override returns (Offer memory offer) {
        return allNftOffers[nftOfferId];
    }

    /**
     *   @dev getTakerOrders returns the Order Struct of the oreder_id
     *   @param orderId uint256
     *   @return order Order
     */
    function getTakerOrders(uint256 orderId) external view override returns (Order memory order) {
        return takerOrders[orderId];
    }

    /**
     *   @dev getNftOrders returns the Order Struct of the oreder_id
     *   @param _nftOrderId uint256
     *   @return order Order
     */
    function getNftOrders(uint256 _nftOrderId) external view override returns (NftOrder memory order) {
        return nftTakerOrders[_nftOrderId];
    }

    /**
     *   @dev freezeXOffer this freeze a particular offer
     *   @param offerId uint256
     */
    function freezeXOffer(uint256 offerId) external isAdmin returns (bool hasfrozen) {
        if (IEscrow(escrow).freezeOneDeposit(offerId, msg.sender)) {
            emit freezeOffer(offerId, msg.sender);
            return true;
        }
        return false;
    }

    /**
     *   @dev adminRemoveOffer this freeze a particular offer
     *   @param offerId uint256
     */
    function adminRemoveOffer(uint256 offerId) external isAdmin returns (bool hasRemoved) {
        delete allOffers[offerId];
        if (IEscrow(escrow).removeOffer(offerId, msg.sender)) {
            emit AdminRemoveOffer(offerId, msg.sender);
            return true;
        }
        return false;
    }

    /**
     *   @dev unFreezeXOffer
     *   Requirement : caller must have admin role
     *   @param offerId uint256
     *   @return hasUnfrozen bool
     */
    function unFreezeXOffer(uint256 offerId) external isAdmin returns (bool hasUnfrozen) {
        if (IEscrow(escrow).unFreezeOneDeposit(offerId, msg.sender)) {
            emit unFreezeOffer(offerId, msg.sender);
            return true;
        }
        return false;
    }

    /**
     *  @dev getOffersFromAddress all offers from an account
     *  @param account address
     *  @return Offer[] memory
     */
    function getOffersFromAddress(address account) external view returns (Offer[] memory) {
        return offersFromAddress[account];
    }

    /**
     *  @dev getTakenOffersFromAddress all offers from an account
     *  @param account address
     *  @return Offer[] memory
     */
    function getTakenOffersFromAddress(address account) external view returns (Offer[] memory) {
        return takenOffersFromAddress[account];
    }

    /**
     *   @dev safeTransfer Asset revert transaction if failed
     *   @param token address
     *   @param amount uint256
     */
    function safeTransfertokenIn(address token, uint256 amount) internal {
        //checks
        require(amount > 0, "Amount is 0");
        //transfer to address
        require(IERC20(token).transferFrom(msg.sender, escrow, amount), "Transfer failed");
    }

    /**
     *   @dev safeTransfer Asset revert transaction if failed
     *   @param token address
     *   @param amount uint256
     */
    function payFee(address token, uint256 amount) internal {
        //checks
        require(amount > 0, "Amount is 0");
        //transfer to address
        require(IERC20(token).transferFrom(msg.sender, feeAddress, amount), "Transfer failed");
    }

    /**
     *   @dev safeTransferAsset Asset revert transaction if failed
     *   @param erc20Token address
     *   @param _to address
     *   @param _from address
     *   @param _amount address
     */
    function safeTransferAsset(
        address erc20Token,
        address _to,
        address _from,
        uint256 _amount
    ) internal {
        require(IERC20(erc20Token).transferFrom(_from, _to, _amount), "Transfer failed");
    }

    /**
     *    @dev isActive bool that checks if the expirydate is < now
     *    @param offerId uint256
     *    @return active bool
     */
    function isActive(uint256 offerId) public view returns (bool active) {
        return allOffers[offerId].expiryTime > block.timestamp;
    }

    /**
     *    @dev isActiveNftOffer bool that checks if the expirydate is < now
     *    @param offerId uint256
     *    @return active bool
     */
    function isActiveNftOffer(uint256 offerId) public view returns (bool active) {
        return allNftOffers[offerId].expiryTime > block.timestamp;
    }

    function isWrapperedERC20(address token) internal view returns (bool wrapped) {
        return TokenListManager(tokenListManagerAddress).allowedErc20tokens(token) != 0;
    }

    function isWrapperedERC1155(address token) internal view returns (bool wrapped) {
        return TokenListManager(tokenListManagerAddress).allowedErc1155tokens(token) != 0;
    }

    function standardiseNumber(uint256 amount, address _token) internal view returns (uint256) {
        uint8 decimal = ERC20(_token).decimals();
        return amount.mul(BPSNUMBER).div(10**decimal);
    }

    function unstandardisedNumber(uint256 _amount, address _token) internal view returns (uint256) {
        uint8 decimal = ERC20(_token).decimals();
        return _amount.mul(10**decimal).div(BPSNUMBER);
    }

    /**
     *   @dev Asset is Approve on the Swarm DOTC Market
     *   @param tokenAddress address
     */
    modifier allowedERC20Asset(address tokenAddress) {
        require(isWrapperedERC20(tokenAddress), "Asset not allowed");
        _;
    }
    /**
     *   @dev Asset is Approve on the Swarm DOTC Market
     *   @param tokenAddress address
     */
    modifier allowedERC1155Asset(address tokenAddress) {
        require(isWrapperedERC1155(tokenAddress), "Asset not allowed");
        _;
    }

    /**
        @dev can_buy check if an Order is Active
        @param offerId uint256
    */
    modifier can_buy(uint256 offerId) {
        require(isActive(offerId), "cannot buy, order ID not active");
        _;
    }

    /**
        @dev canBuyNftOffer check if an Offer is Active
        @param offerId uint256
    */
    modifier canBuyNftOffer(uint256 offerId) {
        require(isActiveNftOffer(offerId), "cannot buy, order ID not active");
        _;
    }
    /**
     *   @dev checks if sender account is a tier on the swarm market protocol
     */
    modifier _accountIsTierTwo() {
        require(PermissionManager(permissionAddress).hasTier2(msg.sender), "NOT_ALLOWED_ON_THIS_PROTOCOL");
        _;
    }
    /**
     *   @dev checks if sender account is suspended on the swarm market protocol
     */
    modifier _accountSuspended() {
        require(!PermissionManager(permissionAddress).isSuspended(msg.sender), "Account is suspended");
        _;
    }
    /**
     *   @dev check if an offer can be cancled
     *   @param id uint256 id of the offer
     */

    modifier can_cancel(uint256 id) {
        require(isActive(id), "cannot cancel, offer ID not active");
        require(allOffers[id].maker == msg.sender, "cannot cancel, msg.sender not the same as offer maker");
        _;
    }

    /**
     *    @dev check if an offer is special Offer assigined to a particular user
     *   @param offerId uint256
     */
    modifier isSpecial(uint256 offerId) {
        if (allOffers[offerId].specialAddress != address(0)) {
            require(allOffers[offerId].specialAddress == msg.sender, "not permitted to take this offer");
        }
        _;
    }

    /**
     *    @dev check if an offer is special Offer assigined to a particular user
     *   @param offerId uint256
     */
    modifier isSpecialNftOffer(uint256 offerId) {
        if (allNftOffers[offerId].specialAddress != address(0)) {
            require(allOffers[offerId].specialAddress == msg.sender, "not permitted to take this offer");
        }
        _;
    }

    /**
     *   @dev check if the offer is available
     */
    modifier isAvailable(uint256 offerId) {
        require(allOffers[offerId].amountIn != 0, "Offer not found");
        _;
    }

    /**
     *   @dev check if the offer is available
     */
    modifier nftOfferIsAvailable(uint256 offerId) {
        require(allNftOffers[offerId].offerPrice != 0, "Offer not found");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.7.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TokenListManager is AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _erc20Id;
    Counters.Counter private _erc1155Id;

    /**
     * @dev ERC20 Tokens registry.
     */
    mapping(address => uint256) public allowedErc20tokens;

    /**
     * @dev ERC1155 Tokens registry.
     */
    mapping(address => uint256) public allowedErc1155tokens;

    bytes32 public constant TOKEN_MANAGER_ROLE = keccak256("TOKEN_MANAGER_ROLE");

    /**
     * @dev Grants the contract deployer the default admin role.
     *
     */
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Grants TOKEN_MANAGER_ROLE to `_manager`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setRegistryManager(address _manager) external {
        grantRole(TOKEN_MANAGER_ROLE, _manager);
    }

    /**
     * @dev Registers a new ERC20 to be allowed into DOTCProtocol.
     *
     * Requirements:
     *
     * - the caller must have TOKEN_MANAGER_ROLE.
     * - `_token` cannot be the zero address.
     *
     * @param _token The address of the ERC20 being registered.
     */
    function registerERC20Token(address _token) external isAdmin {
        require(_token != address(0), "token is the zero address");

        emit RegisterERC20Token(_token);
        _erc20Id.increment();
        allowedErc20tokens[_token] = _erc20Id.current();
    }

    /**
     * @dev Registers a new ERC1155 to be allowed into DOTCProtocol.
     *
     * Requirements:
     *
     * - the caller must have TOKEN_MANAGER_ROLE.
     * - `_token` cannot be the zero address.
     *
     * @param _token The address of the ERC20 being registered.
     */
    function registerERC1155Token(address _token) external isAdmin {
        require(_token != address(0), "token is the zero address");
        emit RegisterERC1155Token(_token);
        _erc1155Id.increment();
        allowedErc1155tokens[_token] = _erc1155Id.current();
    }

    /**
     * @dev unRegisterERC20Token a new ERC20 allowed into DOTCProtocol.
     *
     * Requirements:
     *
     * - the caller must have TOKEN_MANAGER_ROLE.
     * - `_token` cannot be the zero address.
     *
     * @param _token The address of the ERC20 being registered.
     */
    function unRegisterERC20Token(address _token) external isAdmin {
        require(_token != address(0), "token is the zero address");
        emit unRegisterERC20(_token);
        delete allowedErc20tokens[_token];
    }

    /**
     * @dev unRegisterERC1155Token a new ERC1155 allowed into DOTCProtocol.
     *
     * Requirements:
     *
     * - the caller must have TOKEN_MANAGER_ROLE.
     * - `_token` cannot be the zero address.
     *
     * @param _token The address of the ERC20 being registered.
     */
    function unRegisterERC1155Token(address _token) external isAdmin {
        require(_token != address(0), "token is the zero address");
        emit unRegisterERC1155(_token);
        delete allowedErc1155tokens[_token];
    }

    /**
     *   @dev check if sender has admin role
     */
    modifier isAdmin() {
        require(hasRole(TOKEN_MANAGER_ROLE, _msgSender()), "must have dOTC Admin role");
        _;
    }

    /**
     * @dev Emitted when `erc20Asset` is registered.
     */
    event RegisterERC20Token(address indexed token);

    /**
     * @dev Emitted when `erc1155Asset` is registered.
     */
    event RegisterERC1155Token(address indexed token);

    /**
     * @dev Emitted when `erc1155Asset` is unRegistered.
     */
    event unRegisterERC1155(address indexed token);

    /**
     * @dev Emitted when `erc20Asset` is unRegistered.
     */
    event unRegisterERC20(address indexed token);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./PermissionItems.sol";
import "./PermissionManagerStorage.sol";

/**
 * @title PermissionManager
 * @author Protofire
 * @dev Provide tier based permissions assignments and revoking functions.
 */
contract PermissionManager is Initializable, AccessControlUpgradeable, PermissionManagerStorage {
    struct UserProxy {
        address user;
        address proxy;
    }

    /**
     * @dev Emitted when `permissionItems` address is set.
     */
    event PermissionItemsSet(address indexed newPermissions);

    /**
     * @dev Initalize the contract.
     *
     * Sets ownership to the account that deploys the contract.
     *
     * Requirements:
     *
     * - `_permissionItems` should not be the zero address.
     *
     * @param _permissionItems The address of the new Pemissions module.
     */
    function initialize(address _permissionItems, address _admin) public initializer {
        require(_permissionItems != address(0), "_permissionItems is the zero address");
        require(_admin != address(0), "_admin is the zero address");
        permissionItems = _permissionItems;

        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);

        emit PermissionItemsSet(permissionItems);
    }

    /**
     * @dev Throws if called by some address without DEFAULT_ADMIN_ROLE.
     */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "must have default admin role");
        _;
    }

    /**
     * @dev Throws if called by some address without PERMISSIONS_ADMIN_ROLE.
     */
    modifier onlyPermissionsAdmin() {
        require(hasRole(PERMISSIONS_ADMIN_ROLE, _msgSender()), "must have permissions admin role");
        _;
    }

    /**
     * @dev Grants PERMISSIONS_ADMIN_ROLE to `_permissionsAdmin`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     * - `_permissionsAdmin` should not be the zero address.
     */
    function setPermissionsAdmin(address _permissionsAdmin) external onlyAdmin {
        require(_permissionsAdmin != address(0), "_permissionsAdmin is the zero address");
        grantRole(PERMISSIONS_ADMIN_ROLE, _permissionsAdmin);
    }

    /**
     * @dev Sets `_permissionItems` as the new permissionItems module.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - `_permissionItems` should not be the zero address.
     *
     * @param _permissionItems The address of the new Pemissions module.
     */
    function setPermissionItems(address _permissionItems) external onlyAdmin returns (bool) {
        require(_permissionItems != address(0), "_permissionItems is the zero address");
        emit PermissionItemsSet(_permissionItems);
        permissionItems = _permissionItems;
        return true;
    }

    /**
     * @dev assigns Tier1 permission to the list `_accounts`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - each address in `_accounts` should not have Tier1 already assigned.
     *
     * @param _accounts The addresses to assign Tier1.
     */
    function assingTier1(address[] memory _accounts) external onlyPermissionsAdmin {
        for (uint256 i = 0; i < _accounts.length; i++) {
            require(!hasTier1(_accounts[i]), "PermissionManager: Address already has Tier 1 assigned");
            PermissionItems(permissionItems).mint(_accounts[i], TIER_1_ID, 1, "");
        }
    }

    /**
     * @dev assigns Tier2 permission to a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should not have Tier2 already assigned.
     * - All proxy addresses in `_usersProxies` should not have Tier2 already assigned.
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where user and proxy are bout required.
     */
    function assingTier2(UserProxy[] memory _usersProxies) external onlyPermissionsAdmin {
        for (uint256 i = 0; i < _usersProxies.length; i++) {
            UserProxy memory userProxy = _usersProxies[i];
            require(!hasTier2(userProxy.user), "PermissionManager: Address already has Tier 2 assigned");
            require(!hasTier2(userProxy.proxy), "PermissionManager: Proxy already has Tier 2 assigned");

            PermissionItems(permissionItems).mint(userProxy.user, TIER_2_ID, 1, "");
            PermissionItems(permissionItems).mint(userProxy.proxy, TIER_2_ID, 1, "");
        }
    }

    /**
     * @dev suspends pemissions effects to a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should not be already suspended.
     * - All proxy addresses in `_usersProxies` should not be already suspended.
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where is required
     *                      but proxy can be optional if it is set to zero address.
     */
    function suspendUser(UserProxy[] memory _usersProxies) external onlyPermissionsAdmin {
        for (uint256 i = 0; i < _usersProxies.length; i++) {
            UserProxy memory userProxy = _usersProxies[i];
            require(!isSuspended(userProxy.user), "PermissionManager: Address is already suspended");
            PermissionItems(permissionItems).mint(userProxy.user, SUSPENDED_ID, 1, "");

            if (userProxy.proxy != address(0)) {
                require(!isSuspended(userProxy.proxy), "PermissionManager: Proxy is already suspended");
                PermissionItems(permissionItems).mint(userProxy.proxy, SUSPENDED_ID, 1, "");
            }
        }
    }

    /**
     * @dev Assigns Reject permission to a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should not be already rejected.
     * - All proxy addresses in `_usersProxies` should not be already rejected.
     *
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where is required
     *                      but proxy can be optional if it is set to zero address.
     */
    function rejectUser(UserProxy[] memory _usersProxies) external onlyPermissionsAdmin {
        for (uint256 i = 0; i < _usersProxies.length; i++) {
            UserProxy memory userProxy = _usersProxies[i];
            require(!isRejected(userProxy.user), "PermissionManager: Address is already rejected");
            PermissionItems(permissionItems).mint(userProxy.user, REJECTED_ID, 1, "");

            if (userProxy.proxy != address(0)) {
                require(!isRejected(userProxy.proxy), "PermissionManager: Proxy is already rejected");
                PermissionItems(permissionItems).mint(userProxy.proxy, REJECTED_ID, 1, "");
            }
        }
    }

    /**
     * @dev removes Tier1 permission from the list `_accounts`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - each address in `_accounts` should have Tier1 assigned.
     *
     * @param _accounts The addresses to revoke Tier1.
     */
    function revokeTier1(address[] memory _accounts) external onlyPermissionsAdmin {
        for (uint256 i = 0; i < _accounts.length; i++) {
            require(hasTier1(_accounts[i]), "PermissionManager: Address doesn't has Tier 1 assigned");
            PermissionItems(permissionItems).burn(_accounts[i], TIER_1_ID, 1);
        }
    }

    /**
     * @dev removes Tier2 permission from a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should have Tier2 assigned.
     * - All proxy addresses in should have Tier2 assigned.
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where user and proxy are bout required.
     */
    function revokeTier2(UserProxy[] memory _usersProxies) external onlyPermissionsAdmin {
        for (uint256 i = 0; i < _usersProxies.length; i++) {
            UserProxy memory userProxy = _usersProxies[i];
            require(hasTier2(userProxy.user), "PermissionManager: Address doesn't has Tier 2 assigned");
            require(hasTier2(userProxy.proxy), "PermissionManager: Proxy doesn't has Tier 2 assigned");

            PermissionItems(permissionItems).burn(userProxy.user, TIER_2_ID, 1);
            PermissionItems(permissionItems).burn(userProxy.proxy, TIER_2_ID, 1);
        }
    }

    /**
     * @dev re-activates pemissions effects on a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should be suspended.
     * - All proxy addresses in `_usersProxies` should be suspended.
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where is required
     *                      but proxy can be optional if it is set to zero address.
     */
    function unsuspendUser(UserProxy[] memory _usersProxies) external onlyPermissionsAdmin {
        for (uint256 i = 0; i < _usersProxies.length; i++) {
            UserProxy memory userProxy = _usersProxies[i];
            require(isSuspended(userProxy.user), "PermissionManager: Address is not currently suspended");
            PermissionItems(permissionItems).burn(userProxy.user, SUSPENDED_ID, 1);

            if (userProxy.proxy != address(0)) {
                require(isSuspended(userProxy.proxy), "PermissionManager: Proxy is not currently suspended");
                PermissionItems(permissionItems).burn(userProxy.proxy, SUSPENDED_ID, 1);
            }
        }
    }

    /**
     * @dev Removes Reject permission from a list of users and proxies.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - All user addresses in `_usersProxies` should be rejected.
     * - All proxy addresses in `_usersProxies` should be rejected.
     *
     *
     * @param _usersProxies The addresses of the users and proxies.
     *                      An array of the struct UserProxy where is required
     *                      but proxy can be optional if it is set to zero address.
     */
    function unrejectUser(UserProxy[] memory _usersProxies) external onlyPermissionsAdmin {
        for (uint256 i = 0; i < _usersProxies.length; i++) {
            UserProxy memory userProxy = _usersProxies[i];
            require(isRejected(userProxy.user), "PermissionManager: Address is not currently rejected");
            PermissionItems(permissionItems).burn(userProxy.user, REJECTED_ID, 1);

            if (userProxy.proxy != address(0)) {
                require(isRejected(userProxy.proxy), "PermissionManager: Proxy is not currently rejected");
                PermissionItems(permissionItems).burn(userProxy.proxy, REJECTED_ID, 1);
            }
        }
    }

    /**
     * @dev assigns specific item `_itemId` to the list `_accounts`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - each address in `_accounts` should not have `_itemId` already assigned.
     *
     * @param _itemId Item to be assigned.
     * @param _accounts The addresses to assign Tier1.
     */
    function assignItem(uint256 _itemId, address[] memory _accounts) external onlyPermissionsAdmin {
        for (uint256 i = 0; i < _accounts.length; i++) {
            require(!_hasItem(_accounts[i], _itemId), "PermissionManager: Account is assigned with item");
            PermissionItems(permissionItems).mint(_accounts[i], _itemId, 1, "");
        }
    }

    /**
     * @dev removes specific item `_itemId` to the list `_accounts`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - each address in `_accounts` should have `_itemId` already assigned.
     *
     * @param _itemId Item to be removeded
     * @param _accounts The addresses to assign Tier1.
     */
    function removeItem(uint256 _itemId, address[] memory _accounts) external onlyPermissionsAdmin {
        for (uint256 i = 0; i < _accounts.length; i++) {
            require(_hasItem(_accounts[i], _itemId), "PermissionManager: Account is not assigned with item");
            PermissionItems(permissionItems).burn(_accounts[i], _itemId, 1);
        }
    }

    function _hasItem(address _user, uint256 itemId) internal view returns (bool) {
        return PermissionItems(permissionItems).balanceOf(_user, itemId) > 0;
    }

    /**
     * @dev Returns `true` if `_account` has been assigned Tier1 permission.
     *
     * @param _account The address of the user.
     */
    function hasTier1(address _account) public view returns (bool) {
        return _hasItem(_account, TIER_1_ID);
    }

    /**
     * @dev Returns `true` if `_account` has been assigned Tier2 permission.
     *
     * @param _account The address of the user.
     */
    function hasTier2(address _account) public view returns (bool) {
        return _hasItem(_account, TIER_2_ID);
    }

    /**
     * @dev Returns `true` if `_account` has been Suspended.
     *
     * @param _account The address of the user.
     */
    function isSuspended(address _account) public view returns (bool) {
        return _hasItem(_account, SUSPENDED_ID);
    }

    /**
     * @dev Returns `true` if `_account` has been Rejected.
     *
     * @param _account The address of the user.
     */
    function isRejected(address _account) public view returns (bool) {
        return _hasItem(_account, REJECTED_ID);
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title IEscrow
 * @author Protofire
 * @dev Ilamini Dagogo for Protofire.
 *
 */
interface IdOTC {
    /**
        @dev Offer Stucture 
    */

    struct Offer {
        bool isNft;
        address maker;
        uint256 offerId;
        uint256[] nftIds; // list nft ids
        bool fullyTaken;
        uint256 amountIn; // offer amount
        uint256 offerFee;
        uint256 unitPrice;
        uint256 amountOut; // the amount to be receive by the maker
        address nftAddress;
        uint256 expiryTime;
        uint256 offerPrice;
        OfferType offerType; // can be PARTIAL or FULL
        uint256[] nftAmounts;
        address escrowAddress;
        address specialAddress; // makes the offer avaiable for one account.
        address tokenInAddress; // Token to exchange for another
        uint256 availableAmount; // available amount
        address tokenOutAddress; // Token to receive by the maker
    }

    struct Order {
        uint256 offerId;
        uint256 amountToSend; // the amount the taker sends to the maker
        address takerAddress;
        uint256 amountToReceive;
        uint256 minExpectedAmount; // the amount the taker is to recieve
    }

    struct NftOrder {
        uint256 offerId;
        uint256[] nftIds;
        uint256 amountPaid;
        uint256[] nftAmounts;
        address takerAddress;
    }

    enum OfferType { PARTIAL, FULL }

    function getOfferOwner(uint256 offerId) external view returns (address owner);

    function getNftOfferOwner(uint256 _nftOfferId) external view returns (address owner);

    function getOffer(uint256 offerId) external view returns (Offer memory offer);

    function getNftOffer(uint256 _nftOfferId) external view returns (Offer memory offer);

    function getTaker(uint256 orderId) external view returns (address taker);

    function getNftTaker(uint256 _nftOrderId) external view returns (address taker);

    function getTakerOrders(uint256 orderId) external view returns (Order memory order);

    function getNftOrders(uint256 _nftOrderId) external view returns (NftOrder memory order);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../../interfaces/IEscrow.sol";

/**
 * @title IEscrow
 * @author Protofire
 * @dev Ilamini Dagogo for Protofire.
 *
 */

contract AdminFunctions is AccessControl {
    address internal escrow;
    uint256 public feeAmount = 3 * 10**24;
    uint256 public constant BPSNUMBER = 10**27;
    uint256 public constant DECIMAL = 18;
    address internal feeAddress;
    address internal tokenListManagerAddress;
    address internal permissionAddress;
    bytes32 public constant dOTC_Admin_ROLE = keccak256("dOTC_ADMIN_ROLE");
    bytes32 public constant ESCROW_MANAGER_ROLE = keccak256("ESCROW_MANAGER_ROLE");
    bytes32 public constant PERMISSION_SETTER_ROLE = keccak256("PERMISSION_SETTER_ROLE");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");

    /**
     * @dev Grants dOTC_Admin_ROLE to `_dOTCAdmin`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setdOTCAdmin(address _dOTCAdmin) external {
        grantRole(dOTC_Admin_ROLE, _dOTCAdmin);
    }

    function setEscrowAddress(address _address) public returns (bool status) {
        require(hasRole(ESCROW_MANAGER_ROLE, _msgSender()), "Not allowed");
        escrow = _address;
        return true;
    }

    function setEscrowLinker() external returns (bool status) {
        require(hasRole(ESCROW_MANAGER_ROLE, _msgSender()), "Not allowed");
        if (IEscrow(escrow).setdOTCAddress(address(this))) {
            return true;
        }
        return false;
    }

    function freezeEscrow() external isAdmin returns (bool status) {
        if (IEscrow(escrow).freezeEscrow(msg.sender)) {
            return true;
        }
        return false;
    }

    /**
     *    @dev unFreezeEscrow
     *    Requirement : caller must have admin role
     *   @return status bool
     */
    function unFreezeEscrow() external isAdmin returns (bool status) {
        if (IEscrow(escrow).unFreezeEscrow(msg.sender)) {
            return true;
        }
        return false;
    }

    function setTokenListManagerAddress(address _contractAddress) external isAdmin returns (bool status) {
        tokenListManagerAddress = _contractAddress;
        return true;
    }

    function setPermissionAddress(address _permissionAddress) external isAdmin returns (bool status) {
        require(hasRole(PERMISSION_SETTER_ROLE, _msgSender()), "account not permmited");
        permissionAddress = _permissionAddress;
        return true;
    }

    function setFeeAddress(address _newFeeAddress) external isAdmin returns (bool status) {
        require(hasRole(FEE_MANAGER_ROLE, _msgSender()), "account not permmited");
        feeAddress = _newFeeAddress;
        return true;
    }

    function setFeeAmount(uint256 _feeAmount) external isAdmin returns (bool status) {
        require(hasRole(FEE_MANAGER_ROLE, _msgSender()), "account not permmited");
        feeAmount = _feeAmount;
        return true;
    }

    /**
     *   @dev check if sender has admin role
     */
    modifier isAdmin() {
        require(hasRole(dOTC_Admin_ROLE, _msgSender()), "must have dOTC Admin role");
        _;
    }
    // Limit
    // Fee Manager
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IEscrow
 * @author Protofire
 * @dev Ilamini Dagogo for Protofire.
 *
 */
interface IEscrow {
    function setMakerDeposit(uint256 _offerId) external;

    function setNFTDeposit(uint256 _offerId) external;

    function withdrawDeposit(uint256 offerId, uint256 orderId) external;

    function withdrawNftDeposit(uint256 _nftOfferId, uint256 _nftOrderId) external;

    function freezeEscrow(address _account) external returns (bool);

    function setdOTCAddress(address _token) external returns (bool);

    function freezeOneDeposit(uint256 offerId, address _account) external returns (bool);

    function unFreezeOneDeposit(uint256 offerId, address _account) external returns (bool);

    function unFreezeEscrow(address _account) external returns (bool status);

    function cancelDeposit(
        uint256 offerId,
        address token,
        address maker,
        uint256 _amountToSend
    ) external returns (bool status);

    function cancelNftDeposit(uint256 nftOfferId) external;

    function removeOffer(uint256 offerId, address _account) external returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() {
        _registerInterface(
            ERC1155Receiver(0).onERC1155Received.selector ^
            ERC1155Receiver(0).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../GSN/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
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
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
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
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

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
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual {
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
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
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
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title PermissionItems
 * @author Protofire
 * @dev Contract module which provides a permissioning mechanism through the asisgnation of ERC1155 tokens.
 * It inherits from standard ERC1155 and extends functionality for
 * role based access control and makes tokens non-transferable.
 */
contract PermissionItems is ERC1155, AccessControl {
    // Constants for roles assignments
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /**
     * @dev Grants the contract deployer the default admin role.
     *
     */
    constructor() ERC1155("") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Grants TRANSFER role to `account`.
     *
     * Grants MINTER role to `account`.
     * Grants BURNER role to `account`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setAdmin(address account) external {
        grantRole(MINTER_ROLE, account);
        grantRole(BURNER_ROLE, account);
    }

    /**
     * @dev Revokes TRANSFER role to `account`.
     *
     * Revokes MINTER role to `account`.
     * Revokes BURNER role to `account`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeAdmin(address account) external {
        revokeRole(MINTER_ROLE, account);
        revokeRole(BURNER_ROLE, account);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - the caller must have MINTER role.
     * - `account` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "PermissionItems: must have minter role to mint");

        super._mint(to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "PermissionItems: must have minter role to mint");

        super._mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - the caller must have BURNER role.
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external {
        require(hasRole(BURNER_ROLE, _msgSender()), "PermissionItems: must have burner role to burn");
        super._burn(account, id, value);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external {
        require(hasRole(BURNER_ROLE, _msgSender()), "PermissionItems: must have burner role to burn");
        super._burnBatch(account, ids, values);
    }

    /**
     * @dev Disabled setApprovalForAll function.
     *
     */
    function setApprovalForAll(address, bool) public pure override {
        revert("disabled");
    }

    /**
     * @dev Disabled safeTransferFrom function.
     *
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure override {
        revert("disabled");
    }

    /**
     * @dev Disabled safeBatchTransferFrom function.
     *
     */
    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public pure override {
        revert("disabled");
    }
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title PemissionManagerStorage
 * @author Protofire
 * @dev Storage structure used by PermissionManager contract.
 *
 * All storage must be declared here
 * New storage must be appended to the end
 * Never remove items from this list
 */
abstract contract PermissionManagerStorage {
    bytes32 public constant PERMISSIONS_ADMIN_ROLE = keccak256("PERMISSIONS_ADMIN_ROLE");

    address public permissionItems;

    // Constants for Permissions ID
    uint256 public constant SUSPENDED_ID = 0;
    uint256 public constant TIER_1_ID = 1;
    uint256 public constant TIER_2_ID = 2;
    uint256 public constant REJECTED_ID = 3;
    uint256 public constant PROTOCOL_CONTRACT = 4;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC1155.sol";
import "./IERC1155MetadataURI.sol";
import "./IERC1155Receiver.sol";
import "../../GSN/Context.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(accounts[i] != address(0), "ERC1155: batch balance query for the zero address");
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}