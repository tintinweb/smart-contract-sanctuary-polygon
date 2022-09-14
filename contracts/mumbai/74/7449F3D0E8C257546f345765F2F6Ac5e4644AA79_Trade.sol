// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import './SafeMath.sol';
import './TransferProxy.sol';

contract Trade {
  using SafeMath for uint256;

  enum BuyingAssetType {
    ERC1155,
    ERC721
  }

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );
  event SellerFee(uint8 sellerFee);
  event BuyerFee(uint8 buyerFee);
  event CharityAddressUpdated(address indexed charityAddress);
  event BuyAsset(
    address indexed assetOwner,
    uint256 indexed tokenId,
    uint256 quantity,
    address indexed buyer
  );
  event ExecuteBid(
    address indexed assetOwner,
    uint256 indexed tokenId,
    uint256 quantity,
    address indexed buyer
  );

  uint8 private buyerFeePermille;
  uint8 private sellerFeePermille;
  TransferProxy public transferProxy;
  address public owner;
  address public charity;
  uint256 platformFee;

  struct Fee {
    uint256 platformFee;
    uint256 assetFee;
    uint256 royaltyFee;
    uint256 charityFee;
    uint256 price;
    address tokenCreator;
  }

  /* An ECDSA signature. */
  struct Sign {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct Order {
    address seller;
    address buyer;
    address erc20Address;
    address nftAddress;
    BuyingAssetType nftType;
    uint256 unitPrice;
    uint256 amount;
    uint256 tokenId;
    uint256 qty;
    uint256 charityFee;
  }

  modifier onlyOwner() {
    require(owner == msg.sender, 'Ownable: caller is not the owner');
    _;
  }

  constructor(
    uint8 _buyerFee,
    uint8 _sellerFee,
    address _charity,
    TransferProxy _transferProxy
  ) {
    buyerFeePermille = _buyerFee;
    sellerFeePermille = _sellerFee;
    transferProxy = _transferProxy;
    owner = msg.sender;
    charity = _charity;
  }

  function buyerServiceFee() public view virtual returns (uint8) {
    return buyerFeePermille;
  }

  function sellerServiceFee() public view virtual returns (uint8) {
    return sellerFeePermille;
  }

  function setBuyerServiceFee(uint8 _buyerFee) public onlyOwner returns (bool) {
    buyerFeePermille = _buyerFee;
    emit BuyerFee(buyerFeePermille);
    return true;
  }

  function setSellerServiceFee(uint8 _sellerFee)
    public
    onlyOwner
    returns (bool)
  {
    sellerFeePermille = _sellerFee;
    emit SellerFee(sellerFeePermille);
    return true;
  }

  function ownerTransfership(address newOwner) public onlyOwner returns (bool) {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    return true;
  }

  function getSigner(bytes32 hash, Sign memory sign)
    internal
    pure
    returns (address)
  {
    return
      ecrecover(
        keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash)),
        sign.v,
        sign.r,
        sign.s
      );
  }

  function verifySellerSign(
    address seller,
    uint256 tokenId,
    uint256 amount,
    address paymentAssetAddress,
    address assetAddress,
    Sign memory sign
  ) internal pure {
    bytes32 hash = keccak256(
      abi.encodePacked(assetAddress, tokenId, paymentAssetAddress, amount)
    );
    require(seller == getSigner(hash, sign), 'seller sign verification failed');
  }

  function verifyBuyerSign(
    address buyer,
    uint256 tokenId,
    uint256 amount,
    address paymentAssetAddress,
    address assetAddress,
    uint256 qty,
    Sign memory sign
  ) internal pure {
    bytes32 hash = keccak256(
      abi.encodePacked(assetAddress, tokenId, paymentAssetAddress, amount, qty)
    );
    require(buyer == getSigner(hash, sign), 'buyer sign verification failed');
  }

  function getFees(
    uint256 paymentAmt,
    BuyingAssetType buyingAssetType,
    address buyingAssetAddress,
    uint256 tokenId,
    uint256 _charityFee
  ) internal returns (Fee memory) {
    address tokenCreator;
    platformFee = 0;
    uint256 royaltyFee;
    uint256 assetFee;
    uint256 royaltyPermille;
    uint256 price = paymentAmt.mul(1000).div((1000 + buyerFeePermille));
    uint256 buyerFee = paymentAmt.sub(price);
    uint256 sellerFee = price.mul(sellerFeePermille).div(1000);
    platformFee = buyerFee.add(sellerFee);
    if (buyingAssetType == BuyingAssetType.ERC721) {
      royaltyPermille = ((IERC721(buyingAssetAddress).royaltyFee(tokenId)));
      tokenCreator = ((IERC721(buyingAssetAddress).getCreator(tokenId)));
    }
    if (buyingAssetType == BuyingAssetType.ERC1155) {
      royaltyPermille = ((IERC1155(buyingAssetAddress).royaltyFee(tokenId)));
      tokenCreator = ((IERC1155(buyingAssetAddress).getCreator(tokenId)));
    }
    royaltyFee = price.mul(royaltyPermille).div(1000);
    assetFee = price.sub(royaltyFee).sub(sellerFee);
    uint256 charityFee = price.mul(_charityFee).div(1000);
    assetFee = assetFee.sub(charityFee);
    return
      Fee(platformFee, assetFee, royaltyFee, charityFee, price, tokenCreator);
  }

  function tradeAsset(Order memory order, Fee memory fee) internal virtual {
    if (order.nftType == BuyingAssetType.ERC721) {
      transferProxy.erc721safeTransferFrom(
        IERC721(order.nftAddress),
        order.seller,
        order.buyer,
        order.tokenId
      );
    }
    if (order.nftType == BuyingAssetType.ERC1155) {
      transferProxy.erc1155safeTransferFrom(
        IERC1155(order.nftAddress),
        order.seller,
        order.buyer,
        order.tokenId,
        order.qty,
        ''
      );
    }
    if (fee.platformFee > 0) {
      transferProxy.erc20safeTransferFrom(
        IERC20(order.erc20Address),
        order.buyer,
        owner,
        fee.platformFee
      );
    }
    if (fee.royaltyFee > 0) {
      transferProxy.erc20safeTransferFrom(
        IERC20(order.erc20Address),
        order.buyer,
        fee.tokenCreator,
        fee.royaltyFee
      );
    }
    if (fee.charityFee > 0) {
      transferProxy.erc20safeTransferFrom(
        IERC20(order.erc20Address),
        order.buyer,
        charity,
        fee.charityFee
      );
    }
    transferProxy.erc20safeTransferFrom(
      IERC20(order.erc20Address),
      order.buyer,
      order.seller,
      fee.assetFee
    );
  }

  function buyAsset(Order memory order, Sign memory sign)
    public
    returns (bool)
  {
    Fee memory fee = getFees(
      order.amount,
      order.nftType,
      order.nftAddress,
      order.tokenId,
      order.charityFee
    );
    require((fee.price >= order.unitPrice * order.qty), 'Paid invalid amount');
    verifySellerSign(
      order.seller,
      order.tokenId,
      order.unitPrice,
      order.erc20Address,
      order.nftAddress,
      sign
    );
    order.buyer = msg.sender;
    tradeAsset(order, fee);
    emit BuyAsset(order.seller, order.tokenId, order.qty, msg.sender);
    return true;
  }

  function executeBid(Order memory order, Sign memory sign)
    public
    returns (bool)
  {
    Fee memory fee = getFees(
      order.amount,
      order.nftType,
      order.nftAddress,
      order.tokenId,
      order.charityFee
    );
    verifyBuyerSign(
      order.buyer,
      order.tokenId,
      order.amount,
      order.erc20Address,
      order.nftAddress,
      order.qty,
      sign
    );
    order.seller = msg.sender;
    tradeAsset(order, fee);
    emit ExecuteBid(msg.sender, order.tokenId, order.qty, order.buyer);
    return true;
  }

  function setCharityAddress(address _charityAddress)
    public
    onlyOwner
    returns (bool)
  {
    charity = _charityAddress;
    emit CharityAddressUpdated(charity);
    return (true);
  }
}