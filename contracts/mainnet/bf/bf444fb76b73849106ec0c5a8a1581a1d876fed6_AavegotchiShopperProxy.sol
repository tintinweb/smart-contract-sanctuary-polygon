/**
 *Submitted for verification at polygonscan.com on 2022-03-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.1;


struct ERC1155Listing {
    uint256 listingId;
    address seller;
    address erc1155TokenAddress;
    uint256 erc1155TypeId;
    uint256 category; // 0 is wearable, 1 is badge, 2 is consumable, 3 is tickets
    uint256 quantity;
    uint256 priceInWei;
    uint256 timeCreated;
    uint256 timeLastPurchased;
    uint256 sourceListingId;
    bool sold;
    bool cancelled;
}


struct ERC721Listing {
    uint256 listingId;
    address seller;
    address erc721TokenAddress;
    uint256 erc721TokenId;
    uint256 category; // 0 is closed portal, 1 is vrf pending, 2 is open portal, 3 is Aavegotchi
    uint256 priceInWei;
    uint256 timeCreated;
    uint256 timePurchased;
    bool cancelled;
}

interface IERC1155 {
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;
}

interface IERC721 {

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external;
}

interface ERC1155MarketplaceFacet {

    function executeERC1155Listing(
        uint256 _listingId,
        uint256 _quantity,
        uint256 _priceInWei
    ) external;
    function getERC1155Listing(uint256 _listingId) external view returns (ERC1155Listing memory listing_);
}

interface ERC721MarketplaceFacet {
    function executeERC721Listing(
        uint256 _listingId
    ) external;
    function getERC721Listing(uint256 _listingId) external view returns (ERC721Listing memory listing_);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
uint constant MAX_UINT = 2**256 - 1;

contract AavegotchiShopperProxy {
    // MATIC
    address private diamondAddr = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;
    address private ghstAddr = 0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7;
    
    // KOVAN
    //address private diamondAddr = 0x07543dB60F19b9B48A69a7435B5648b46d4Bb58E;
    //address private ghstAddr = 0xeDaA788Ee96a0749a2De48738f5dF0AA88E99ab5;
    ERC1155MarketplaceFacet private diamondMarketplaceERC1155 = ERC1155MarketplaceFacet(diamondAddr);
    ERC721MarketplaceFacet private diamondMarketplaceERC721 = ERC721MarketplaceFacet(diamondAddr);
    IERC20 private ghstERC20 = IERC20(ghstAddr);

    address public owner;

    constructor() {
        owner = msg.sender;
         ghstERC20.approve(diamondAddr, MAX_UINT);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function approveGhst() public onlyOwner {
        ghstERC20.approve(diamondAddr, MAX_UINT);
    }


    function findERC1155ListingId (uint256 listingId, uint256 priceInWei, uint256 maxAttempts) private view returns (uint256) {
        ERC1155Listing memory listing;
        uint256 foundListingId = 0;
        for (uint256 attempt = 0; attempt < maxAttempts; attempt++) {
            foundListingId = listingId + attempt;
            listing = diamondMarketplaceERC1155.getERC1155Listing(foundListingId);
            if (listing.listingId == foundListingId) {
                
                require(priceInWei == listing.priceInWei, "ERC1155Marketplace: wrong price or price changed");
                require(listing.timeCreated != 0, "ERC1155Marketplace: listing not found");
                require(listing.sold == false, "ERC1155Marketplace: listing is sold out");
                require(listing.cancelled == false, "ERC1155Marketplace: listing is cancelled");
                address buyer = address(this);
                address seller = listing.seller;
                require(seller != buyer, "Proxy - ERC1155Marketplace: buyer can't be seller"); 
                return foundListingId;
            }
        }
        return 0;
    }

    function withdrawERC1155(address erc1155TokenAddress, uint256[] memory ids, uint256[] memory values) public onlyOwner {
        IERC1155(erc1155TokenAddress).safeBatchTransferFrom(address(this), owner, ids, values, new bytes(0));
    }

    function executeERC1155Listing(uint256 listingId, uint256 quantity,
                                uint256 priceInWei, uint256 maxAttempts) public onlyOwner {
        require(quantity > 0, "Proxy - ERC1155Marketplace: _quantity can't be zero");
        uint256 cost = quantity * priceInWei;
        require(IERC20(ghstAddr).balanceOf(address(this)) >= cost, "Proxy - ERC1155Marketplace: not enough GHST");
        uint256 foundListingId = findERC1155ListingId(listingId, priceInWei, maxAttempts);
        require(foundListingId != 0, 'Proxy - Listing could not be found');
        diamondMarketplaceERC1155.executeERC1155Listing(foundListingId, quantity, priceInWei);
    }

    function findERC721ListingId (uint256 listingId, uint256 maxAttempts) private view returns (uint256) {
        ERC721Listing memory listing;
        uint256 foundListingId = 0;
        for (uint256 attempt = 0; attempt < maxAttempts; attempt++) {
            foundListingId = listingId + attempt;
            listing = diamondMarketplaceERC721.getERC721Listing(foundListingId);
            if (listing.listingId == foundListingId && listing.cancelled != true &&
                listing.timePurchased == 0 && listing.priceInWei > 0) {
                return foundListingId;
            }
        }
        return 0;
    }

    function withdrawERC721(uint256 id, address erc721TokenAddress) public onlyOwner {
        IERC721(erc721TokenAddress).safeTransferFrom(address(this), owner, id, new bytes(0));
    }

    function executeERC721Listing(uint256 listingId, uint256 maxAttempts) public onlyOwner {
        uint256 foundListingId = findERC721ListingId(listingId, maxAttempts);
        require(foundListingId != 0, 'Proxy - Listing could not be found');
        diamondMarketplaceERC721.executeERC721Listing(foundListingId);
    }

    function withdrawEther(uint256 amount) public onlyOwner {
        require(owner == msg.sender,"1");
        (bool sent,) = owner.call{value: amount}("");
        require(sent, "2");
    }

    function withdrawERC20(address erc20Address, uint256 amount) public onlyOwner {
        require(IERC20(erc20Address).transfer(msg.sender, amount), "Transfer failed");
    }
}