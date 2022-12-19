/**
 *Submitted for verification at polygonscan.com on 2022-12-19
*/

/**
 *Submitted for verification at polygonscan.com on 2022-12-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;


struct InitiatorInfo {
    uint80 startTime;
    uint80 endTime;
    uint56 tokenAmount;
    uint8 category; //0 = portal 1 = open portal 2 = pending 3 = aavegotchi
    bytes4 tokenKind;
    uint256 tokenID;
}


//Generic presets
struct Preset {
    uint64 incMin;
    uint64 incMax;
    uint64 bidMultiplier;
    uint64 stepMin;
    uint256 bidDecimals;
}

struct Auction {
    address owner;
    uint96 highestBid;
    address highestBidder;
    uint88 auctionDebt;
    uint88 dueIncentives;
    bool biddingAllowed;
    bool claimed;
    address tokenContract;
    InitiatorInfo info;
    Preset presets;
}



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

struct GbmInfo {
  uint80 startTime;
  uint80 endTime;
  uint64 tokenAmount;
  bytes4 tokenKind;
  uint256 tokenID;

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
        bytes memory _data
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

interface Erc1155MarketplaceFacet {

    function executeERC1155Listing(
        uint256 _listingId,
        uint256 _quantity,
        uint256 _priceInWei
    ) external;
    
    function getERC1155Listing(uint256 _listingId) external view returns (ERC1155Listing memory listing_);
}

interface Erc721MarketplaceFacet {

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

interface GBMfacet {
    function commitBid(
        uint256 _auctionID,
        uint256 _bidAmount,
        uint256 _highestBid,
        address _tokenContract,
        uint256 _tokenID,
        uint256 _amount,
        bytes memory _signature
    ) external;

    function claim(uint256 _auctionID) external;

    function createAuction( GbmInfo calldata _info, uint160 _contractID,uint256 _auctionPresetID) external;

    function getAuctionInfo(uint256 _auctionID) external view returns (Auction memory auctionInfo_);

}
contract BuyProxy {
    // MATIC
    address private diamondAddy = 0x86935F11C86623deC8a25696E1C19a8659CbF95d;
    address private ghstAddy = 0x385Eeac5cB85A38A9a07A70c73e0a3271CfB54A7;
    address private gbmAddy = 0xD5543237C656f25EEA69f1E247b8Fa59ba353306;

    Erc1155MarketplaceFacet private diamondMarketplaceERC1155 = Erc1155MarketplaceFacet(diamondAddy);
    Erc721MarketplaceFacet private diamondMarketplaceERC721 = Erc721MarketplaceFacet(diamondAddy);
    GBMfacet private diamondGbmERC721 = GBMfacet(gbmAddy);
    IERC20 private ghstErc20 = IERC20(ghstAddy);

    address public owner;

    constructor() {
        owner = msg.sender;
         ghstErc20.approve(diamondAddy, 1e29);
         ghstErc20.approve(gbmAddy, 1e29);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4) {
        return this.onERC721Received.selector;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function commitBidGbm(
        uint256 _auctionID,
        uint256 _bidAmount,
        uint256 _highestBid,
        address _tokenContract,
        uint256 _tokenID,
        uint256 _amount,
        bytes memory _signature) public onlyOwner {

            diamondGbmERC721.commitBid(
                _auctionID,
                _bidAmount,
                _highestBid,
                _tokenContract,
                _tokenID,
                _amount,
                _signature);
    }

    function claim(uint256 _auctionID) public onlyOwner {
        diamondGbmERC721.claim(_auctionID);
    }

    function approveGhst() public onlyOwner {
        ghstErc20.approve(diamondAddy, 1e29);
    }

    function approveGhstToAddress(address addy) public onlyOwner {
        ghstErc20.approve(addy, 1e29);
    }

    function withdrawItems(address erc1155TokenAddress, uint256[] memory ids, uint256[] memory values) public onlyOwner {
        IERC1155(erc1155TokenAddress).safeBatchTransferFrom(address(this), owner, ids, values, new bytes(0));
    }

    function withdrawGotchi(uint256 gotchiId, address erc721TokenAddress) public onlyOwner {
        IERC721(erc721TokenAddress).safeTransferFrom(address(this), owner, gotchiId, new bytes(0));
    }

    function withdrawEther(uint256 amount) public onlyOwner {
        require(owner == msg.sender,"1");
        (bool sent,) = owner.call{value: amount}("");
        require(sent, "2");
    }

    function withdrawErc20(address erc20Address, uint256 amount) public onlyOwner {
        require(IERC20(erc20Address).transfer(msg.sender, amount), "Transfer failed");
    }
}