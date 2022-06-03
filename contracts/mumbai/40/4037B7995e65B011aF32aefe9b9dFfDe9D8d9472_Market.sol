// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import './ERC721.sol';

contract Market is ERC721, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;

    address payable internal marketer;

    uint256 public percentage = 2;

    struct Offer {
        bool isForSale;
        uint256 itemIndex;
        IERC721 tokenContract;
        address seller;
        uint256 minValue;
    }

    struct Bid {
        bool hasBid;
        uint256 itemIndex;
        address bidder;
        uint256 value;
    }

    struct Collections {
        bool isEqual;
        IERC721 contractAddressCollection;
        address ownerOfCollection;
        uint256 percentOfCommission;
    }

    mapping (address => mapping(uint => Bid)) public ItemBids;
    mapping (address => mapping(uint => Offer)) public OfferedForSale;
    mapping (address => uint256) public pendingWithdrawals;


    mapping (address => Collections) public CollectionsContract;

    constructor(string memory name, string memory symbol, address payable _marketer) ERC721(name, symbol) {
        marketer = _marketer;
    }

    /*************************************************************************** */
    //                             Collections :


    function addContractERC721 (address _contract, uint256 _commission) public onlyownerOfCollection(_contract) {
        Collections memory collection = Collections({
            isEqual : true,
            contractAddressCollection : IERC721(_contract),
            ownerOfCollection : msg.sender,
            percentOfCommission : _commission
        });

        CollectionsContract[_contract] = collection;


        emit AddCollection(_contract ,_msgSender(),_commission);
    }


    function changeContractERC721 (address _contract, uint256 _commission) public {
        CollectionsContract[_contract].percentOfCommission = _commission;
        emit ChangeContract(_contract ,_msgSender(),_commission);
    }

    /*************************************************************************** */
    //                             End Collections :



    /*************************************************************************** */
    //                             Offer && Buy :

    function offerForSale(uint256 tokenId, uint256 minSalePriceInWei , address _contract) public onlyOwnerItem(_msgSender(), tokenId,_contract) {
        OfferedForSale[_contract][tokenId] = Offer(true, tokenId,IERC721(_contract), _msgSender(), minSalePriceInWei);

        emit ItemOffered(tokenId, _contract, minSalePriceInWei, _msgSender());
    }

    function buy(uint256 tokenId , address _constant) payable public {
        Offer memory offer = OfferedForSale[_constant][tokenId];

        IERC721 buyOfContract =  CollectionsContract[_constant].contractAddressCollection;


        require(offer.isForSale, "Not For Sale");
        require(msg.value >= offer.minValue, "Insufficient amount");

        address seller = offer.seller; // seller of token for send price

        address ownerCollection =   CollectionsContract[_constant].ownerOfCollection; // owner collection for send profit

        // Send Amount for Bidder
        Bid memory existing = ItemBids[_constant][tokenId];
        if(existing.hasBid) {
            ItemBids[_constant][tokenId] = Bid(false, tokenId, address(0), 0);
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        // Send Amount for Bidder

        // Transfer the NFT

        buyOfContract.safeTransferFrom(seller , _msgSender() , tokenId);

        // handle Calc

        uint FeeAmount = msg.value * percentage / 100;

        uint profit = msg.value *  CollectionsContract[_constant].percentOfCommission / 100;

        uint sellerAmount = ((msg.value  - FeeAmount) - profit);

        // Fee

        (bool sentFee, ) = marketer.call{ value: FeeAmount }("");
        require(sentFee, "Market comission was not paid ......... ");

        // Seller Amount
        (bool sent, ) = seller.call{ value: sellerAmount }("");
        require(sent, "The amount was not paid to the seller");

        // Owner Profit
        (bool sentProfit, ) = ownerCollection.call{ value: profit }("");
        require(sentProfit, "No interest was paid");


        OfferedForSale[_constant][tokenId] =  Offer(false, tokenId,IERC721(_constant), seller, 0);
    }

    function NoLongerForSale(uint256 tokenId, address _contract) public onlyOwnerItem(_msgSender(), tokenId,_contract) {
        _NoLongerForSale(_msgSender(), tokenId , _contract);
    }

    function _NoLongerForSale(address from, uint256 tokenId, address _contract) internal onlyOwnerItem(_msgSender(), tokenId,_contract){
        OfferedForSale[_contract][tokenId] = Offer(false, tokenId,IERC721(_contract), from, 0);
        emit NoForSale(tokenId, _contract);
    }


    /*************************************************************************** */


    /*************************************************************************** */
    //                             Bid && Accept Bid :


    function enterBidForItem(uint256 tokenId ,address _contract) public payable {
        require(msg.value > 0, 'bid can not be zero');
        require(msg.value > ItemBids[_contract][tokenId].value, "Invalid");

        Bid memory existing = ItemBids[_contract][tokenId];

        if (existing.value > 0) {
            pendingWithdrawals[existing.bidder] += existing.value;
        }

        ItemBids[_contract][tokenId] = Bid(true, tokenId, _msgSender(), msg.value);
        emit BidEntered(tokenId, _msgSender(), msg.value);
    }


    function withdrawBidForItem(uint256 tokenId,address _contract) public {
        require(ItemBids[_contract][tokenId].bidder == _msgSender(), "Invalid");

        uint amountBid = ItemBids[_contract][tokenId].value;
        ItemBids[_contract][tokenId] = Bid(false, tokenId, address(0), 0);

        // Refund the bid money
        (bool success,) = _msgSender().call{value: amountBid}("");
        require(success, 'not send price to bidder ');
        emit BidWithdrawn(tokenId, ItemBids[_contract][tokenId].value, _msgSender());
    }


    function acceptBidForItem(uint256 tokenId, address _contract) public onlyOwnerItem(_msgSender(), tokenId,_contract){
        IERC721 buyOfContract =  CollectionsContract[_contract].contractAddressCollection;

        require(ItemBids[_contract][tokenId].value > 0, 'there is not any bid');

        Bid memory bid = ItemBids[_contract][tokenId];

        address ownerCollection = CollectionsContract[_contract].ownerOfCollection; // owner collection for send profit

        ItemBids[_contract][tokenId] = Bid(false, tokenId, address(0), 0);

        buyOfContract.safeTransferFrom(_msgSender() ,bid.bidder , tokenId);

        // handle Calc
        uint FeeAmount = bid.value * percentage / 100;

        uint profit = bid.value *  CollectionsContract[_contract].percentOfCommission / 100;

        uint sellerAmount = ((bid.value  - FeeAmount) - profit);


        OfferedForSale[_contract][tokenId] =  Offer(false, tokenId,IERC721(_contract), _msgSender(), 0);

        // Fee
        (bool sentFee, ) = marketer.call{ value: FeeAmount }("");
        require(sentFee, "Market comission was not paid ......... ");

        // Seller Amount
        (bool sent, ) =  _msgSender().call{ value: sellerAmount }("");
        require(sent, "The amount was not paid to the seller");

        // Owner Profit
        (bool sentProfit, ) = ownerCollection.call{ value: profit }("");
        require(sentProfit, "No interest was paid");


    }


    function withdraw() public {
        uint256 amount = pendingWithdrawals[_msgSender()];
        pendingWithdrawals[_msgSender()] = 0;
        (bool success,) = _msgSender().call{value: amount}("");
        require(success, 'withdraw undone');
    }

    /*************************************************************************** */



    /*************************************************************************** */
    //                             Admin functions:


    function changepercentage (uint256 price) public onlyOwner {
        percentage = price;
    }


    function changeMarketOwner (address payable _marketer) public onlyOwner {
        marketer = _marketer;
    }
    /*************************************************************************** */


    /*************************************************************************** */
    //                             Modifiers:


    modifier onlyOwnerItem (address from, uint256 tokenId , address _contract) {
        IERC721 collectionContract =  CollectionsContract[_contract].contractAddressCollection;

        require(collectionContract.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        _;
    }


    modifier onlyownerOfCollection(address _contract) {
        address owner = Ownable(_contract).owner();

       require(owner == msg.sender, "ERC721: transfer of token that is not ow");
       _;
    }


    /*************************************************************************** */
    //                             Events:

    event ItemOffered(uint tokenId , address contractCollections , uint price, address seller);
    event NoForSale(uint tokenId , address contractCollections );
    event BidEntered(uint tokenId ,address bidder, uint price );
    event BidWithdrawn(uint tokenId,uint value,uint walletAddress);
    event BoughtBid(uint tokenId,uint value,address walletAddressSender ,address walletAddressBidder , address contractAddress);
    event AddCollection(address contractAddress ,address owner,uint256 commission);
    event ChangeContract(address contractAddress ,address owner,uint256 commission);
}