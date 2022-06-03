/**
 *Submitted for verification at polygonscan.com on 2022-06-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

// import './ERC721.sol';

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


library SafeMath {
   
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}


contract Market is  Ownable {

    using SafeMath for uint256;
    using Strings for uint256;

    // MAX_COMMISSION
    uint256 public MAX_COMMISSION = 5;


    // Token name
    string private _name;
    // Token symbol
    string private _symbol;

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
        bool isExist;
        IERC721 contractAddressCollection;
        address ownerOfCollection;
        uint256 percentOfCommission;
    }

    mapping (address => mapping(uint => Bid)) public ItemBids;
    mapping (address => mapping(uint => Offer)) public OfferedForSale;
    mapping (address => uint256) public pendingWithdrawals;
    

    mapping (address => Collections) public CollectionsContract;

    constructor(string memory name_, string memory symbol_, address payable _marketer){
        marketer = _marketer;
        _name = name_;
        _symbol = symbol_;
    }

     /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /*************************************************************************** */
    //                             Collections : 


    function addContractERC721 (address _contract, uint256 _commission) public onlyownerOfCollection(_contract) {
        require(_commission <= MAX_COMMISSION , "The commission is more than the commission ceiling !!!");

        Collections memory collection = Collections({
            isExist : true,
            contractAddressCollection : IERC721(_contract),
            ownerOfCollection : msg.sender,
            percentOfCommission : _commission
        });

        CollectionsContract[_contract] = collection;
        

        emit AddCollection(_contract ,_msgSender(),_commission);        
    }


    function changeCommission (address _contract, uint256 _commission) public {
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

    function buy(uint256 tokenId , address _contract) payable public {
        Offer memory offer = OfferedForSale[_contract][tokenId];

        IERC721 buyOfContract =  CollectionsContract[_contract].contractAddressCollection; 


        require(offer.isForSale, "Not For Sale");
        require(msg.value >= offer.minValue, "Insufficient amount");

        address seller = offer.seller; // seller of token for send price 
      
        address ownerCollection =   CollectionsContract[_contract].ownerOfCollection; // owner collection for send profit

        // Send Amount for Bidder  
        Bid memory existing = ItemBids[_contract][tokenId];
        if(existing.hasBid) {
            ItemBids[_contract][tokenId] = Bid(false, tokenId, address(0), 0);
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        // Send Amount for Bidder
        
        // Transfer the NFT
        
        buyOfContract.safeTransferFrom(seller , _msgSender() , tokenId);
        
        // handle Calc

        uint FeeAmount = msg.value * percentage / 100;
    
        uint profit = msg.value *  CollectionsContract[_contract].percentOfCommission / 100;
            
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


        OfferedForSale[_contract][tokenId] =  Offer(false, tokenId,IERC721(_contract), seller, 0);
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


    function changepercentage (uint256 _percentage) public onlyOwner {
        percentage = _percentage;
    }


    function changeMarketUser (address payable _marketer) public onlyOwner {
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
        address ownerMarket = Ownable.owner();

    
       require(owner == msg.sender || ownerMarket ==msg.sender, "You are not the owner of the collection !!");
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
    event BidWithdrawn(uint256 tokenId , uint256 bidVal , address sender);

}