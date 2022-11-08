/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

// SPDX-License-Identifier: MIT
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


pragma solidity ^0.8.0;

interface IERC721 is IERC165 {

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

}

pragma solidity ^0.8.0;


contract OfferNFT{

  struct Order {
    bool mode;  //false:end, true:live
    address maker;
    address addressNFT;
    uint256 tokenID;
    uint256 expiration;
    uint256 price;
    uint256 timestamp;
  }
  struct Sale {
    address buyer;
    address seller;
    uint256 price;
    address addressNFT;
    uint256 tokenID;
  }

  address public owner;
  address public feeAddress;
  uint16 public feePercent;

  mapping (bytes32 => Order) listingList;
  mapping (address => mapping (uint256 => bytes32[])) listingListIDByNFT;
  mapping (bytes32 => Order) offerList;
  mapping (address => mapping (uint256 => bytes32[])) offerListIDByNFT;
  mapping (bytes32 => Sale) saleList;
  mapping (address => mapping(uint256 => bytes32[])) saleListIDByNFT;

  mapping (address => bytes32[]) listingHashByCollection;
  mapping (address => bytes32[]) offerHashByCollection;
  mapping (address => bytes32[]) saleHashByCollection;

  bytes32[] listingHashs;
  bytes32[] offerHashs;
  bytes32[] saleHashs;

  event MakeListing(address indexed collection, uint256 indexed tokenID, uint256 indexed price);
  event CancelListing(address indexed collection, uint256 indexed tokenID);
  event BuyNFT(address  seller, address  buyer, address indexed collection, uint256 indexed tokenID);

  event MakeOffer(address indexed maker, address indexed collection, uint256 indexed tokenID, uint256  price, uint256  period);
  event CancelOffer(address indexed maker, address indexed collection, uint256 indexed tokenID, uint256  price, uint256  period);
  event AcceptOffer(address indexed buyer, address indexed seller, address indexed collection, uint256  tokenID, uint256  price);

  constructor(uint16 _feePercent) {
    require(_feePercent <= 1000, "Input value is more than 10%");
    owner = msg.sender;
    feeAddress = msg.sender;
    feePercent = _feePercent;
  }

  function _hash(address _collection, uint256 _id, address _maker, string memory mode) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(_collection, _id, _maker, mode, block.timestamp));
  }
  function _hash_sale(address _collection, uint256 _id, address buyer, address seller, string memory mode) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(_collection, _id, buyer, seller, mode, block.timestamp));
  }

  //feeAddress must be either an EOA or a contract must have payable receive fx and doesn't have some codes in that fx.
  //If not, it might be that it won't be receive any fee.
  function setFeeAddress(address _feeAddress) external{
    require(msg.sender == owner, "you are not the owner of this smart contract");
    feeAddress = _feeAddress;
  }

  function updateFeePercent(uint16 _percent) external {
    require(msg.sender == owner, "you are not the owner of this smart contract");
    require(_percent <= 1000, "Input value is more than 10%");
    feePercent = _percent;
  }

//////////////////////////////////View Functions////////////////////////////////////////////////////
  

  function listAllListingByCollectionAndTokenID(address collection, uint256 tokenID, uint start, uint end) external view returns(Order[] memory, bytes32[] memory){
    uint index = 0;
    bytes32[] memory hash = new bytes32[](end-start+1);
    Order[] memory result = new Order[](end-start+1);
    for(uint i=start; i<= end; i++){
      result[index] = listingList[listingListIDByNFT[collection][tokenID][i]];
      hash[index] = listingListIDByNFT[collection][tokenID][i];
      index++;
    }
    return (result, hash);
  }

  function listAllListingByCollection(address collection, uint start, uint end) external view returns(Order[] memory, bytes32[] memory){
    uint index = 0;
    bytes32[] memory hash = new bytes32[](end - start + 1);
    Order[] memory result = new Order[](end - start + 1);
    for(uint i=start; i<= end; i++){
      result[index] = listingList[listingHashByCollection[collection][i]];
      hash[index] = listingHashByCollection[collection][i];
      index++;
    }
    return (result, hash);
  }


  function listAllOfferByCollectionAndTokenID(address collection, uint256 tokenID, uint start, uint end) external view returns(Order[] memory, bytes32[] memory){
    uint index = 0;
    bytes32[] memory hash = new bytes32[](end - start + 1);
    Order[] memory result = new Order[](end - start + 1);
    for(uint i=start; i<= end; i++){
      result[index] = offerList[offerListIDByNFT[collection][tokenID][i]];
      hash[index] = offerListIDByNFT[collection][tokenID][i];
      index++;
    }
    return (result, hash);
  }

  function listAllOffersByCollection(address collection, uint start, uint end) external view returns(Order[] memory, bytes32[] memory){
    uint index = 0;
    bytes32[] memory hash = new bytes32[](end - start + 1);
    Order[] memory result = new Order[](end - start + 1);
    for(uint i=start; i<= end; i++){
      result[index] = offerList[offerHashByCollection[collection][i]];
      hash[index] = offerHashByCollection[collection][i];
      index++;
    }
    return (result, hash);
  }

  function listAllSaleByCollectionAndTokenID(address collection, uint256 tokenID, uint start, uint end) external view returns(Sale[] memory, bytes32[] memory){
    uint index = 0;
    bytes32[] memory hash = new bytes32[](end - start + 1);
    Sale[] memory result = new Sale[](end - start + 1);
    for(uint i=start; i<= end; i++){
      result[index] = saleList[saleListIDByNFT[collection][tokenID][i]];
      hash[index] = saleListIDByNFT[collection][tokenID][i];
      index++;
    }
    return (result, hash);
  }

  function listAllSaleByCollection(address collection, uint start, uint end) external view returns(Sale[] memory, bytes32[] memory){
    uint index = 0;
    bytes32[] memory hash = new bytes32[](end - start + 1);
    Sale[] memory result = new Sale[](end - start + 1);
    for(uint i=start; i<= end; i++){
      result[index] = saleList[saleHashByCollection[collection][i]];
      hash[index] = saleHashByCollection[collection][i];
      index++;
    }
    return (result, hash);
  }

  function listAllListings(uint start, uint end) external view returns(Order[] memory, bytes32[] memory){
    uint256 index = 0;
    Order[] memory result = new Order[](end - start + 1);
    bytes32[] memory result_hash = new bytes32[](end - start + 1);

    for(uint i=start; i< end+1; i++){
        result[index] = listingList[listingHashs[i]];
        result_hash[index] = listingHashs[i];
        index++;
    }
    return (result, result_hash);
  }

  function listAllOffers(uint start, uint end) external view returns(Order[] memory, bytes32[] memory){
    uint index = 0;
    Order[] memory result = new Order[](end - start + 1);
    bytes32[] memory result_hash = new bytes32[](end - start + 1);

    for(uint i=start; i< end+1; i++){
        result[index] = offerList[offerHashs[i]];
        result_hash[index] = listingHashs[i];
        index++;
    }
    return (result, result_hash);
  }

  function listAllSales(uint start, uint end) external view returns(Sale[] memory, bytes32[] memory){
    uint256 index = 0;
    Sale[] memory result = new Sale[](end - start + 1);
    bytes32[] memory result_hash = new bytes32[](end - start + 1);

    for(uint i=start; i< end+1; i++){
      result[index] = saleList[saleHashs[i]];
      result_hash[index] = saleHashs[i];
      index++;
    }
    return (result, result_hash);
  }

  function totoalListing() public view returns(uint256){
    return listingHashs.length;
  }

  function totoalOffer() public view returns(uint256){
    return offerHashs.length;
  }

  function totalSale() public view returns(uint256){
    return saleHashs.length;
  }
//////////////////////////////////Sell NFT////////////////////////////////////////////

  ///////////owner can list his nft at fixed price///////////////////////////////// 
  function makeListing(address collection, uint256 tokenID, uint256 price) public {
    require(price > 0, "wrong price");
    require(IERC721(collection).ownerOf(tokenID) == msg.sender, "You are not owner of the NFT");

    IERC721(collection).transferFrom(msg.sender, address(this), tokenID);

    bytes32 hash = _hash(collection, tokenID, msg.sender, "listing");
    listingList[hash] = Order(true, msg.sender, collection, tokenID, 0, price, block.timestamp);
    listingHashByCollection[collection].push(hash);
    listingListIDByNFT[collection][tokenID].push(hash);
    listingHashs.push(hash);
    emit MakeListing(collection, tokenID, price);
  }

  function bulkList(address collection, uint256[] memory tokenIDs, uint256 price) external {
    for(uint i=0; i< tokenIDs.length; i++){
      makeListing(collection, tokenIDs[i], price);
    }
  }

  function bulkCancel(bytes32[] memory hash) external {
    for(uint i=0; i< hash.length; i++){
      cancelListing(hash[i]);
    }
  }

  //////////owner can unlist sale/////////////////////////////////////////////////
  function cancelListing(bytes32 hash) public {

    require (listingList[hash].maker == msg.sender, "You are not owner of the NFT");
    require (listingList[hash].mode == true, "the NFT is not available anymore");

    IERC721(listingList[hash].addressNFT).transferFrom(address(this), msg.sender, listingList[hash].tokenID);
    listingList[hash].mode = false;
   
    emit CancelListing(listingList[hash].addressNFT, listingList[hash].tokenID); 
  }

  //////////Anyone can buy NFT at fixed price////////////////////////////////////
  function buyNFT(bytes32 hash) external payable{
    require(listingList[hash].mode == true, "NFT is not available to buy");
    require(msg.value >= listingList[hash].price, "insufficient amount");

    uint256 fee = listingList[hash].price * feePercent / 10000;
    payable(listingList[hash].maker).transfer(listingList[hash].price - fee);
    IERC721(listingList[hash].addressNFT).transferFrom(address(this), msg.sender, listingList[hash].tokenID);
    listingList[hash].mode = false;

    bytes32 hash_sale = _hash_sale(listingList[hash].addressNFT, listingList[hash].tokenID, msg.sender, listingList[hash].maker, "offer");
    saleList[hash_sale] = Sale(msg.sender, listingList[hash].maker, msg.value, listingList[hash].addressNFT, listingList[hash].tokenID);
    saleListIDByNFT[listingList[hash].addressNFT][listingList[hash].tokenID].push(hash_sale);
    saleHashByCollection[listingList[hash].addressNFT].push(hash_sale);
    saleHashs.push(hash);

    emit BuyNFT(listingList[hash].maker, msg.sender, listingList[hash].addressNFT, listingList[hash].tokenID);
  }

/////////////////////////////////Offer NFT////////////////////////////////////////////

  ////////////Anyone can make a offer for NFT collection, NFT tokenID, Price, Expiration///////////////////////////////
  function makeOffer(address collection, uint256 tokenID, uint256 expiration) external payable{
    bytes32 hash = _hash(collection, tokenID, msg.sender, "offer");
    require (msg.value > 0, "wrong amount");
    require (offerList[hash].mode == false, "You have already made offer");
    require (IERC721(collection).ownerOf(tokenID) != msg.sender, "You are not able to make an offer to yourself");
    
    offerList[hash] = Order(true, msg.sender, collection, tokenID, expiration, msg.value, block.timestamp);
    offerListIDByNFT[collection][tokenID].push(hash);
    offerHashByCollection[collection].push(hash);
    offerHashs.push(hash);
    emit MakeOffer(msg.sender, collection, tokenID, msg.value, expiration);
  }

  ///////////Offer maker can cancel offer///////////////////////////////////
  function cancelOffer(bytes32 hash) external {
    require (block.timestamp - offerList[hash].timestamp > offerList[hash].expiration, "not expired yet");
    require (offerList[hash].maker == msg.sender, "You are not allowed to cancel");
    require (offerList[hash].mode == true, "Offer is not available");

    offerList[hash].mode = false;
    payable(msg.sender).transfer(offerList[hash].price);
    emit CancelOffer(msg.sender, offerList[hash].addressNFT, offerList[hash].tokenID, offerList[hash].price, offerList[hash].expiration);
  }

  //////////Owner accept offer/////////////////////////////////////////////
  function acceptOffer(bytes32 hash) external {

    require (IERC721(offerList[hash].addressNFT).ownerOf(offerList[hash].tokenID) == msg.sender, "You are not owner of the NFT");
    require (address(this).balance >= offerList[hash].price, "insufficiant balance in Contract");
    require (offerList[hash].mode == true, "Offer is not available any more");
    require (block.timestamp - offerList[hash].timestamp <= offerList[hash].expiration, "expired");
    
    

    IERC721(offerList[hash].addressNFT).transferFrom(msg.sender, address(this), offerList[hash].tokenID);
    IERC721(offerList[hash].addressNFT).transferFrom(address(this), offerList[hash].maker, offerList[hash].tokenID);

    uint256 fee = offerList[hash].price * feePercent / 10000;
    payable(msg.sender).transfer(offerList[hash].price - fee);
    offerList[hash].mode = false;

    bytes32 hash_sale = _hash_sale(offerList[hash].addressNFT, offerList[hash].tokenID, offerList[hash].maker, msg.sender, "offer");
    saleList[hash_sale] = Sale(offerList[hash].maker, msg.sender, offerList[hash].price, offerList[hash].addressNFT, offerList[hash].tokenID);
    saleListIDByNFT[offerList[hash].addressNFT][offerList[hash].tokenID].push(hash_sale);
    saleHashByCollection[offerList[hash].addressNFT].push(hash_sale);
    saleHashs.push(hash);

    emit AcceptOffer(offerList[hash].maker, msg.sender, offerList[hash].addressNFT, offerList[hash].tokenID, offerList[hash].price);
  }
}