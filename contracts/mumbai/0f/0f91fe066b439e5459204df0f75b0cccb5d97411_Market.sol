// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import './ERC721.sol';
import './IERC721.sol';


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

contract Market is ERC721, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;

    mapping(uint256 => uint256) private assignOrders;

    address payable internal marketer;
    address payable internal developer;

    uint256 public constant MAX_SUPPLY = 10;
    uint256 public testRemainingToAssign = 10;

    uint256 public percentAge = 2;

    struct Offer {
        bool isForSale;
        uint256 itemIndex;
        address seller;
        uint256 minValue;       
        address onlySellTo;
    }

    mapping (uint256 => Offer) public OfferedForSale;

    
    uint collectionId =  0;
    mapping (address => IERC721) public CollectionsContract;

    constructor(string memory name, string memory symbol, string memory baseURI, address payable _marketer) ERC721(name, symbol) {
        // developer = _developer;
        marketer = _marketer;
        _setBaseURI(baseURI);
    }




    modifier onlyOwnerItem (address from, uint256 tokenId , address _contract) {
        IERC721 collectionContract =  CollectionsContract[_contract];
        
        require(collectionContract.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        _;
    }


    function balanceOfContract(address _contract ,address walletAddress) public view returns(uint){

        IERC721 collectionContract =  CollectionsContract[_contract];

        return collectionContract.balanceOf(walletAddress);

    }
    
    function ownerOfContract(address _contract ,uint256 tokenId) public view returns(address){

        IERC721 collectionContract =  CollectionsContract[_contract];

        return collectionContract.ownerOf(tokenId);
    }
    
    
    // Add Offer For sell
    function offerForSale(uint256 tokenId, uint256 minSalePriceInWei , address _contract) public onlyOwnerItem(_msgSender(), tokenId,_contract) {
        require(marketPaused == false, 'Market Paused');

        // IERC721 collectionContract =  CollectionsContract[_contract];

        // collectionContract.setApprovalForAll(_msgSender() , true);

        OfferedForSale[tokenId] = Offer(true, tokenId, _msgSender(), minSalePriceInWei, address(0));    
    }



    // Buy Offer For sell
    function buy(uint256 tokenId , address _constant) payable public {
        Offer memory offer = OfferedForSale[tokenId];
        IERC721 buyOfContract =  CollectionsContract[_constant]; 

        require(offer.isForSale, "No Sale");
        require(offer.onlySellTo == address(0) || offer.onlySellTo == _msgSender(), "Unable to sell");
        require(msg.value >= offer.minValue, "Insufficient amount");
        // require(ownerOf(tokenId) == offer.seller, "Not seller");
        address seller = offer.seller;
       
        // Transfer the NFT
        // _safeTransfer(seller, _msgSender(), tokenId, "");
        buyOfContract.safeTransferFrom(seller , _msgSender() , tokenId);
        
        // handle
        
        
        uint FeeAmount = msg.value * percentAge / 100;
        
        uint sellerAmount = (msg.value  - FeeAmount);

    
        marketer.transfer(FeeAmount);
        
        // payable(seller).transfer(sellerAmount);
        (bool sent, ) = seller.call{ value: sellerAmount }("");
        require(sent, "Not Payment");
        // handle
    }

    function changePercentAge (uint256 price) public onlyOwner {
        percentAge = price;
    }

    function addContractERC721 (address _contract) public {
        CollectionsContract[_contract] = IERC721(_contract);
    }




    function changeBaseURI(string memory baseURI) onlyOwner public {
       _setBaseURI(baseURI);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI(), tokenId.toString(),'.json'));
    }
    
    function pauseMarket(bool _paused) external onlyOwner {
        marketPaused = _paused;
    }
}