// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)
pragma solidity ^0.8.13;


import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaNftV2 is ERC1155, Ownable {

    //** vars */
    uint32 public foundationFee = 200;// 2% foundation on only initial sale
    uint32 public adminFee = 800;// 8% admin  =>. owner() on initial sale

    uint32 public adminFeeOnResell = 250;// 2.5% admin  =>. owner() on resell
    uint32 public creatorFee = 750;// 7.5% creator (init artist) on resell

    uint256 public nextTokenId = 1001;

    //** structs */
    struct NftItem {
        uint256 tokenId;
        uint32 quantity;
        address creator;
        bool isListed;
        bool isGallery;//new
        uint32 galleryFee;
        address galleryAddress;
        address[] collaborators;
        uint32[] collaboratorsFee;
    }

    struct Sale {
        uint32 quantity;
        uint256 price;
        address seller;
        bool resell;
    }

    struct AuctionState {
        bool active;
        uint256 price;
        address seller;
        bool resell;
    }

    //** mappings */
    mapping(address => uint256) public _fundRecord;
    mapping(uint256 => mapping(address => uint256)) public _auctionBids;

    mapping(uint256 => string) _uris;
    mapping(uint256 => NftItem) _idToNftItem;
    mapping(uint256 => mapping(address => Sale)) _sailingBox;
    mapping(uint256 => AuctionState) _auctionState;

    mapping(bytes32 => uint256) public _membershipTypeToTokenId;
    mapping(uint256 => uint256) public _membershipTokenPrice;
    uint256[] public membershipTypesIds;
    mapping(uint256 => uint32) public _membershipTokenLeft;
    mapping(uint256 => mapping(address => uint256)) public _membershipOfUserOnTokenTill; // tokenId -> (address -> timestamp)

    address foundationAddress = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

    //** events */
    event NftItemCreated(
        uint256 tokenId, uint32 qty, address creator,
        bool isGallery, uint32 galleryFee, address galleryAddress,
        address[] collaborators, uint32[] collaboratorsFee
    );

    event NftItemSold(uint256 tokenId, uint256 price, uint32 qty, address seller, address buyer, bool wasAuction);

    event SaleCreated(uint256 tokenId, address creator, uint32 qty, uint256 price, bool isResell);

    event SaleDropped(uint256 tokenId, address creator);

    event AuctionCreated(uint256 tokenId, address creator, uint256 minPrice, uint256 buyNowPrice, bool isResell);

    event BidCreated(uint256 tokenId, address bidder, uint256 addBid, uint256 totalBid);

    event BidWithdrawn(uint256 tokenId, address bidder);

    event AuctionClosed(uint256 tokenId, address seller);

    event FundAdded(address user, uint256 amount);

    event FundDropped(address user, uint256 amount);

    event MembershipCreated(bytes32 _type, uint256 price);

    event MembershipSubmitted(bytes32 _type, address user, uint256 till, uint256 paid);

    event MembershipUpdated(bytes32 _fromType, bytes32 _toType, address user, uint256 till, uint256 paid);

    event MembershipReleased(bytes32 _type, address user, address caller);

    constructor()  ERC1155("") {
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        return (_uris[_tokenId]);
    }

    function changeFoundationAddress(address _newAddress) public onlyOwner returns (bool)  {
        foundationAddress = _newAddress;
        return true;
    }

    // modifiers

    modifier onlyTokenOwner(uint256 _tokenId, uint256 _quantity)  {
        require(balanceOf(msg.sender, _tokenId) >= _quantity, "Not owner");
        _;
    }

    modifier onlySeller(uint256 _tokenId)  {
        require(_sailingBox[_tokenId][msg.sender].seller != msg.sender, "Not a seller");
        _;
    }

    modifier onlyActiveAuction(uint256 _tokenId)  {
        require(_auctionState[_tokenId].active, "This Auction is unavailable!");
        _;
    }

    modifier isFeePercentagesLessThanMaximum(uint32[] memory _feePercentages) {
        uint32 totalPercent;
        for (uint256 i = 0; i < _feePercentages.length; i++) {
            totalPercent = totalPercent + _feePercentages[i];
        }
        require(totalPercent <= 10000, "Fee percentages exceed maximum");
        _;
    }

    modifier correctFeeRecipientsAndPercentages(
        uint256 _recipientsLength,
        uint256 _percentagesLength
    ) {
        require(
            _recipientsLength == _percentagesLength,
            "Recipients != percentages"
        );
        _;
    }

    modifier priceGreaterThanZero(uint256 _price) {
        require(_price > 0, "Price cannot be 0");
        _;
    }

    // public views

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getSailingList(uint256 _tokenId) public view returns (Sale memory) {
        return _sailingBox[_tokenId][msg.sender];
    }

    function getSailingParams(uint256 _tokenId, address _seller) public view returns (uint256, uint32){
        return (_sailingBox[_tokenId][_seller].price, _sailingBox[_tokenId][_seller].quantity);
    }

    function getStateAuction(uint256 _tokenId) public view returns (AuctionState memory){
        return _auctionState[_tokenId];
    }

    function getAuctionBid(uint256 _tokenId, address bidder) public view returns (uint256){
        return _auctionBids[_tokenId][bidder];
    }

    function getUserFund(address user) public view returns (uint256) {
        return _fundRecord[user];
    }

    function getMembershipLeft(bytes32 _type) public view returns (uint256 left){
        return _membershipTokenLeft[_membershipTypeToTokenId[_type]];
    }

    function getMembership(bytes32 _type, address _user) public view returns (uint256 till){
        return _membershipOfUserOnTokenTill[_membershipTypeToTokenId[_type]][_user];
    }

    // externals

    // seller

    function createSailing(
        string memory _uri,
        uint256 _price,
        uint32 _quantity,
        uint32 _galleryFee,
        address _galleryAddress,
        address[] memory _collaborators,
        uint32[] memory _collaboratorsFee)
    priceGreaterThanZero(_price)
    external returns (bool, uint256)
    {
        uint256 tokenId = _createNftItem(_quantity, _galleryFee, _galleryAddress, _collaborators, _collaboratorsFee);
        _uris[tokenId] = _uri;
        _setupSale(tokenId, _quantity, _price, false);

        return (true, tokenId);
    }

    function resell(uint256 _tokenId, uint32 _quantity, uint256 _price)
    priceGreaterThanZero(_price) onlyTokenOwner(_tokenId, _quantity)
    external returns (bool)
    {
        require(!_auctionState[_tokenId].active, "resale is forbidden on active auction");
        require(_membershipTokenPrice[_tokenId] == 0, "Membership token can't be sold");

        _setupSale(_tokenId, _quantity, _price, true);
        return true;
    }

    function dropSailingList(uint256 _tokenId) external onlySeller(_tokenId) returns (bool) {

        delete _sailingBox[_tokenId][msg.sender];
        emit SaleDropped(_tokenId, msg.sender);

        return true;
    }

    function createAuction(string memory _uri,
        uint256 _minPrice,
        uint256 _buyNowPrice,
        uint32 _galleryFee,
        address _galleryAddress,
        address[] memory _collaborators,
        uint32[] memory _collaboratorsFee)
    priceGreaterThanZero(_minPrice)
    external returns (uint256)
    {

        uint256 tokenId = _createNftItem(1, _galleryFee, _galleryAddress, _collaborators, _collaboratorsFee);
        _uris[tokenId] = _uri;
        _setupAuction(tokenId, _minPrice, _buyNowPrice, false);
        return tokenId;
    }

    function resaleWithAuction(uint256 _tokenId, uint256 _minPrice, uint256 _buyNowPrice)
    priceGreaterThanZero(_minPrice) onlyTokenOwner(_tokenId, 1)
    external returns (bool){

        require(!_auctionState[_tokenId].active, "resale is forbidden on active auction");
        require(_idToNftItem[_tokenId].quantity == 1, "Only NFT with 1 of a kind can create auction");

        require(_membershipTokenPrice[_tokenId] == 0, "Membership token can't be sold");

        _setupAuction(_tokenId, _minPrice, _buyNowPrice, true);
        return true;
    }


    // buyer

    function multiBuy(uint256[] memory _tokenIds, uint32[] memory _quantities, address[] memory _sellers) external payable returns (bool)
    {
        uint256 leftValue = msg.value;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            leftValue -= _buy(_tokenIds[i], _quantities[i], _sellers[i], leftValue);
        }
        if (leftValue > 0) {
            _fundRecord[msg.sender] += leftValue;
        }
        return true;
    }

    function buy(uint256 _tokenId, uint32 _quantity, address _seller) external payable returns (bool)
    {
        uint256 leftValue = msg.value;

        leftValue -= _buy(_tokenId, _quantity, _seller, leftValue);

        if (leftValue > 0) {
            _fundRecord[msg.sender] += leftValue;
        }
        return true;
    }


    function bidAuction(uint256 _tokenId, uint256 addBid) external onlyActiveAuction(_tokenId) returns (bool){

        AuctionState memory auction = _auctionState[_tokenId];

        require(_auctionBids[_tokenId][msg.sender] + addBid >= auction.price, "Price must be bigger to listing price");
        require(balanceOf(auction.seller, _tokenId) >= 1, "Seller address does not hold token");
        require(_fundRecord[msg.sender] >= addBid, "Not enough funds for bidding");

        uint256 buyNowPrice = _sailingBox[_tokenId][auction.seller].price;

        if (buyNowPrice > 0) {
            require(buyNowPrice < _fundRecord[msg.sender] + addBid, "Bidding amount must be less then buyNow");
        }

        _fundRecord[msg.sender] = _fundRecord[msg.sender] - addBid;
        _auctionBids[_tokenId][msg.sender] += addBid;

        emit BidCreated(_tokenId, msg.sender, addBid, _auctionBids[_tokenId][msg.sender]);

        return true;
    }


    function withdrawBid(uint256 _tokenId) external returns (bool) {

        require(_auctionBids[_tokenId][msg.sender] > 0, "No bids found");

        delete _auctionBids[_tokenId][msg.sender];

        emit BidWithdrawn(_tokenId, msg.sender);

        return _payout(msg.sender, _auctionBids[_tokenId][msg.sender], true);
    }


    function endAuction(uint256 _tokenId, address winner) external onlyTokenOwner(_tokenId, 1) onlyActiveAuction(_tokenId) returns (bool){
        _endAuction(_tokenId, winner);
        return true;
    }

    function endAuctionByAdmin(uint256 _tokenId, address winner) external onlyOwner() onlyActiveAuction(_tokenId) returns (bool){
        _endAuction(_tokenId, winner);
        return true;
    }

    function closeAuction(uint256 _tokenId) external onlyTokenOwner(_tokenId, 1) returns (bool){
        delete _auctionState[_tokenId];

        emit AuctionClosed(_tokenId, msg.sender);
        return true;
    }


    function addFund(uint256 _amount) external payable returns (bool)
    {
        require(_amount > 0 && _amount == msg.value, "Please submit the valid amounts!");

        _fundRecord[msg.sender] += _amount;

        emit FundAdded(msg.sender, _amount);
        return true;
    }

    function dropFund(uint256 _amount) external returns (bool)
    {
        require(_amount > 0 && _amount <= _fundRecord[msg.sender], "Please submit the valid amounts!");

        _fundRecord[msg.sender] -= _amount;
        _payout(msg.sender, _amount, false);

        emit FundDropped(msg.sender, _amount);

        return true;
    }

    function mintMembership(bytes32 _type, string memory _uri, uint256 _price)
    external
    onlyOwner
    priceGreaterThanZero(_price)
    returns (bool, uint256)
    {

        require(_membershipTypeToTokenId[_type] == 0, "Membership type already minted");

        address[] memory tmp;
        //setupdate
        uint256 tokenId = _createNftItem(1000, 0, address(0), tmp, new uint32[](0));
        _uris[tokenId] = _uri;
        _membershipTypeToTokenId[_type] = tokenId;
        membershipTypesIds.push(tokenId);
        _membershipTokenLeft[tokenId] = 1000;
        _membershipTokenPrice[tokenId] = _price;

        emit MembershipCreated(_type, _price);

        return (true, tokenId);
    }

    function submitMembership(bytes32 _type) external payable returns (bool) {

        require(_membershipTypeToTokenId[_type] > 0, "Membership type not minted");
        require(_membershipTokenLeft[_membershipTypeToTokenId[_type]] > 0, "Membership is sold");

        uint256 tokenId = _membershipTypeToTokenId[_type];

        for (uint8 i = 0; i < membershipTypesIds.length; i++) {
            if (_membershipOfUserOnTokenTill[membershipTypesIds[i]][msg.sender] > 0) {
                revert("User already member");
            }
        }

        NftItem memory nft = _idToNftItem[tokenId];

        require(msg.value == _membershipTokenPrice[tokenId], "Exact price is required");

        _fundRecord[owner()] += msg.value;

        _safeTransferFrom(owner(), msg.sender, tokenId, 1, "");

        _membershipOfUserOnTokenTill[tokenId][msg.sender] = block.timestamp + 31536000;
        _membershipTokenLeft[tokenId] -= 1;

        emit MembershipSubmitted(_type, msg.sender, _membershipOfUserOnTokenTill[tokenId][msg.sender], msg.value);

        return true;

    }


    function upgradeMembership(bytes32 _currentType, bytes32 _toType) external payable returns (bool) {

        uint256 tokenIdCurrent = _membershipTypeToTokenId[_currentType];
        uint256 tokenIdTo = _membershipTypeToTokenId[_toType];

        require(tokenIdCurrent > 0 && tokenIdTo > 0, "Invalid membership types");
        require(_membershipTokenLeft[tokenIdTo] > 0, "Membership is sold");

        if (_membershipOfUserOnTokenTill[tokenIdCurrent][msg.sender] <= 0) {
            revert("Membership is not active");
        }

        require(msg.value == (_membershipTokenPrice[tokenIdTo] - _membershipTokenPrice[tokenIdCurrent]), "Upgrade value is not valid");

        _fundRecord[owner()] += msg.value;

        _safeTransferFrom(msg.sender, owner(), tokenIdCurrent, 1, "");
        _safeTransferFrom(owner(), msg.sender, tokenIdTo, 1, "");

        _membershipOfUserOnTokenTill[tokenIdTo][msg.sender] = _membershipOfUserOnTokenTill[tokenIdCurrent][msg.sender];
        delete _membershipOfUserOnTokenTill[tokenIdCurrent][msg.sender];

        _membershipTokenLeft[tokenIdCurrent] += 1;
        _membershipTokenLeft[tokenIdTo] -= 1;

        emit MembershipUpdated(_currentType, _toType, msg.sender, _membershipOfUserOnTokenTill[tokenIdTo][msg.sender], msg.value);

        return true;

    }

    function releaseMembership(bytes32 _type, address _user) external returns (bool)
    {
        require(_membershipTypeToTokenId[_type] > 0, "Membership type not minted");

        uint256 expirationTime = _membershipOfUserOnTokenTill[_membershipTypeToTokenId[_type]][_user];
        require(block.timestamp > expirationTime, "membership not expired");

        _safeTransferFrom(_user, owner(), _membershipTypeToTokenId[_type], 1, "");
        _membershipTokenLeft[_membershipTypeToTokenId[_type]] = _membershipTokenLeft[_membershipTypeToTokenId[_type]] + 1;

        emit MembershipReleased(_type, _user, msg.sender);

        return (true);
    }


    //  internals


    function _createNftItem(
        uint32 _quantity,
        uint32 _galleryFee,
        address _galleryAddress,
        address[] memory _collaborators,
        uint32[] memory _collaboratorsFee)
    correctFeeRecipientsAndPercentages(_collaborators.length, _collaboratorsFee.length)
    isFeePercentagesLessThanMaximum(_collaboratorsFee)
    internal returns (uint256)
    {
        bool isGallery = false;

        if (_galleryAddress != address(0)) {//new
            require(_galleryFee < 10000, "Fee can't be more then 100%");
            isGallery = true;
        } else {
            require(_galleryFee == 0, "Gallery fee can't assigned");
        }

        // mint
        uint256 tokenId = _mintInternal(_quantity);

        _idToNftItem[tokenId] = NftItem(
            tokenId,
            _quantity,
            msg.sender,
            true,
            isGallery,
            _galleryFee,
            _galleryAddress,
            _collaborators,
            _collaboratorsFee
        );


        emit NftItemCreated(
            tokenId, _quantity, msg.sender,
            isGallery, _galleryFee, _galleryAddress,
            _collaborators, _collaboratorsFee
        );

        return tokenId;
    }

    function _mintInternal(uint32 _quantity) internal returns (uint256)
    {
        _mint(msg.sender, nextTokenId, _quantity, "");
        nextTokenId++;
        return nextTokenId - 1;
    }

    function _setupSale(uint256 _tokenId, uint32 _quantity, uint256 _price, bool _resell) internal {

        _sailingBox[_tokenId][msg.sender] = Sale(_quantity, _price, msg.sender, _resell);
        emit SaleCreated(_tokenId, msg.sender, _quantity, _price, _resell);
    }

    function _setupAuction(uint256 _tokenId, uint256 _minPrice, uint256 _buyNowPrice, bool resell) internal {
        require(_buyNowPrice == 0 || _buyNowPrice > _minPrice, "buyNowPrice must be more then price");

        if (_buyNowPrice > 0) {
            // setting this will allow buy with one click
            _sailingBox[_tokenId][msg.sender] = Sale(1, _minPrice, msg.sender, resell);
        }

        _auctionState[_tokenId] = AuctionState(true, _minPrice, msg.sender, resell);

        emit AuctionCreated(_tokenId, msg.sender, _minPrice, _buyNowPrice, resell);
    }


    function _buy(uint256 _tokenId, uint32 _quantity, address _seller, uint256 _totalAmountLeft) internal returns (uint256) {

        uint32 quantity = _sailingBox[_tokenId][_seller].quantity;
        uint256 price = _sailingBox[_tokenId][_seller].price;
        address seller = _sailingBox[_tokenId][_seller].seller;
        bool _resell = _sailingBox[_tokenId][_seller].resell;

        require(balanceOf(seller, _tokenId) >= _quantity, "Seller address does not hold token(s)");

        uint256 total = price * _quantity;

        require(_totalAmountLeft >= total, "Price must be bigger to listing price");
        require(_quantity <= quantity, "Quantity can't be more then listing");

        //uint _tokenId,address creator,address OwnerOFToken,uint price
        _sailingBox[_tokenId][_seller].quantity -= _quantity;

        if (_auctionState[_tokenId].active) {
            delete _auctionState[_tokenId];
        }

        _safeTransferFrom(_seller, msg.sender, _tokenId, _quantity, "");
        _separateFees(_tokenId, seller, total, _resell);

        emit NftItemSold(_tokenId, price, _quantity, _seller, msg.sender, false);

        return total;
    }

    function _endAuction(uint256 _tokenId, address _winner) internal {

        uint256 bidAmount = _auctionBids[_tokenId][_winner];
        bool resell = _auctionState[_tokenId].resell;

        require(bidAmount >= _auctionState[_tokenId].price, "Bid is not valid for this user");

        address seller = _auctionState[_tokenId].seller;

        _sailingBox[_tokenId][seller].seller = address(0);
        _sailingBox[_tokenId][seller].price = 0;
        _sailingBox[_tokenId][seller].quantity = 0;

        delete _auctionBids[_tokenId][_winner];
        delete _auctionState[_tokenId];

        _safeTransferFrom(seller, _winner, _tokenId, 1, "");
        _separateFees(_tokenId, seller, bidAmount, resell);

        emit NftItemSold(_tokenId, bidAmount, 1, seller, _winner, true);

    }

    function _separateFees(uint256 _tokenId, address _seller, uint256 _price, bool _resell) internal returns (bool)
    {
        NftItem memory nft = _idToNftItem[_tokenId];

        address creator = nft.creator;

        uint256 foundationPart;
        uint256 adminPart;
        uint256 galleryPart;
        uint256 creatorPart;
        uint256 userPart;

        if (_seller == owner() && !_resell) {
            _fundRecord[msg.sender] += _price;
            return true;
        } else {

            if (!_resell) {

                foundationPart = _price * foundationFee / 10000;
                adminPart = _price * adminFee / 10000;

                if (nft.isGallery) {

                    uint256 galleryFee = nft.galleryFee;
                    galleryPart = (_price - foundationPart - adminPart) * galleryFee / 10000;
                }

                creatorPart = _price - foundationPart - adminPart - galleryPart;

            } else {

                adminPart = _price * adminFeeOnResell / 10000;
                creatorPart = _price * creatorFee / 10000;
                userPart = _price - adminPart - creatorPart;
            }

            if (foundationPart > 0) {
                _fundRecord[foundationAddress] += foundationPart;
            }
            if (adminPart > 0) {
                _fundRecord[owner()] += adminPart;
            }
            if (galleryPart > 0) {
                _fundRecord[nft.galleryAddress] += galleryPart;
            }
            if (userPart > 0) {
                _fundRecord[_seller] += userPart;
            }
            if (creatorPart > 0) {

                uint256 feesPaid = 0;
                for (uint256 i = 0; i < nft.collaborators.length; i++) {
                    uint256 fee = creatorPart * nft.collaboratorsFee[i] / 10000;
                    feesPaid += fee;
                    _fundRecord[nft.collaborators[i]] += fee;
                }
                _fundRecord[creator] += (creatorPart - feesPaid);
            }

            return true;
        }
    }


    function _payout(address _recipient, uint256 _amount, bool addInFundsOnFail) internal returns (bool) {
        // attempt to send the funds to the recipient
        (bool success,) = payable(_recipient).call{value : _amount, gas : 20000}("");
        // if it failed, update their credit balance so they can pull it later

        if (!success) {
            if (addInFundsOnFail) {
                _fundRecord[_recipient] += _amount;
            } else {
                require(success, "payout failed");
            }
        }
        return success;
    }


    //    overrides

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - Membership token can't be transferred beside contract
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from != owner() && to != owner()) {
            for (uint256 i = 0; i < ids.length; i++) {
                if (_membershipTokenPrice[ids[i]] > 0) {
                    revert("Membership token can't be transferred");
                }
            }
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
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
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
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
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
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
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
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
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
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
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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