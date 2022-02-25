// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./OperatorRole.sol";

contract MysteryBoxMarket is OperatorRole, ReentrancyGuard, Pausable {
  using SafeERC20 for IERC20;

  struct Custom {
    uint32 max;
    mapping(address => uint256) price;
  }

  struct Box {
    uint256 start;
    uint256 end;
    uint32 supply;
    uint8 mode; // 0 - Max per tx, 1 - Max per address, 2 - Fixed quantity
    uint8 target; // 0 - Public, 1 - Whitelist, 2 - Custom, 3 - Public + Whitelist, 4 - Public + Custom
    uint32 max;
    uint32 bulk;
    mapping(address => uint256) bulkDiscount;
    mapping(address => uint256) retailPrice;
    mapping(address => uint256) specialPrice;
    bytes32 merkleRoot;
    mapping(address => Custom) member;
  }

  mapping(bytes => Box) private boxes;
  mapping(bytes => mapping(address => uint32)) private addressPurchased;
  mapping(bytes => uint32) private boxSold;

  address public vault;

  error SalesNotAvailable();
  error BoxIdUsed();
  error InvalidPrice();
  error InvalidPurchase();
  error InvalidBoxQuantity();
  error InvalidMerkleProof();
  error InvalidCustomAddress();
  error InvalidPaymentMethod();
  error InvalidQuantity();
  error InvalidPayment();
  error PaymentFailed();
  error PurchaseFailed();
  error TransferFailed();

  event PurchasedBoxes(
    address indexed purchaser,
    bytes boxId,
    address paymentToken,
    uint32 quantity,
    uint256 paid
  );
  event MarketTransferBoxes(
    address indexed purchaser,
    bytes boxId,
    uint32 quantity,
    string reason
  );

  constructor(address _vault) {
    vault = _vault;
  }

  function purchaseBoxes(
    bytes calldata boxId,
    address paymentToken,
    uint32 quantity,
    bytes32[] calldata merkleProof
  ) external payable nonReentrant whenNotPaused {
    Box storage box = boxes[boxId];
    if (block.timestamp < box.start || block.timestamp > box.end)
      revert SalesNotAvailable();
    if (paymentToken == address(0)) revert InvalidPaymentMethod();
    uint32 max = box.max;
    uint256 price = box.retailPrice[paymentToken];

    if (box.target != 2 && box.target != 4) {
      if (box.mode == 1) {
        max = box.max - addressPurchased[boxId][msg.sender];
      } else if (box.mode == 2) {
        if (quantity != box.max || addressPurchased[boxId][msg.sender] > 0)
          revert InvalidBoxQuantity();
      }
    }
    if (box.target == 1 || box.target == 3) {
      bool wl = MerkleProof.verify(
        merkleProof,
        box.merkleRoot,
        keccak256(abi.encodePacked(msg.sender))
      );
      if (box.target == 1 && !wl) revert InvalidMerkleProof();
      if (box.target == 3 && wl) {
        price = box.specialPrice[paymentToken];
      }
    } else if (box.target == 2 || box.target == 4) {
      if (box.member[msg.sender].price[paymentToken] > 0) {
        price = box.member[msg.sender].price[paymentToken];
        max = box.member[msg.sender].max;
      } else {
        max = box.max;
      }
      if (box.mode == 1) {
        max = max - addressPurchased[boxId][msg.sender];
      } else if (box.mode == 2) {
        if (quantity != max || addressPurchased[boxId][msg.sender] > 0)
          revert InvalidBoxQuantity();
      }
      if (box.target == 2 && box.member[msg.sender].price[paymentToken] == 0)
        revert InvalidCustomAddress();
    }
    if (quantity > max || boxSold[boxId] + quantity > box.supply)
      revert InvalidQuantity();
    if (price <= 0) revert InvalidPurchase();
    if (box.bulk > 1) {
      price = price - ((quantity / box.bulk) * box.bulkDiscount[paymentToken]);
    }

    uint256 total = price * quantity;
    if (paymentToken == address(1)) {
      if (msg.value < total) revert InvalidPayment();
      (bool os, ) = payable(vault).call{ value: msg.value }("");
      if (!os) revert PaymentFailed();
      if (msg.value - total > 0) {
        (os, ) = payable(msg.sender).call{ value: msg.value - total }("");
      }
    } else {
      IERC20(paymentToken).safeTransferFrom(msg.sender, vault, total);
    }
    addressPurchased[boxId][msg.sender] += quantity;
    boxSold[boxId] += quantity;
    (address boxProducer, string memory method, uint32 model) = abi.decode(
      boxId,
      (address, string, uint32)
    );
    (bool success, ) = boxProducer.call(
      abi.encodeWithSignature(method, msg.sender, model, quantity)
    );
    if (!success) revert PurchaseFailed();
    emit PurchasedBoxes(msg.sender, boxId, paymentToken, quantity, total);
  }

  function canPurchase(
    bytes calldata boxId,
    address paymentToken,
    address who,
    bytes32[] calldata merkleProof
  )
    external
    view
    returns (
      bool,
      bool can,
      uint32 max,
      uint256 price
    )
  {
    Box storage box = boxes[boxId];
    max = box.max;
    price = box.retailPrice[paymentToken];
    if (box.target != 2 && box.target != 4) {
      if (box.mode == 1) {
        max = box.max - addressPurchased[boxId][who];
      } else if (box.mode == 2 && addressPurchased[boxId][who] > 0) {
        max = 0;
      }
    }
    if (box.target == 0) {
      can = true;
    } else if (box.target == 1 || box.target == 3) {
      can = MerkleProof.verify(
        merkleProof,
        box.merkleRoot,
        keccak256(abi.encodePacked(who))
      );
      if (box.target == 3) {
        if (can) {
          price = box.specialPrice[paymentToken];
        }
        can = true;
      }
    } else if (box.target == 2 || box.target == 4) {
      Custom storage custom = box.member[who];
      can = custom.price[paymentToken] > 0;
      if (can) {
        price = custom.price[paymentToken];
        max = custom.max;
      } else {
        max = 0;
        if (box.target == 4) {
          max = box.max;
        }
      }
      if (box.target == 4) {
        can = true;
      }
      if (box.mode == 1) {
        max = max - addressPurchased[boxId][who];
      } else if (box.mode == 2 && addressPurchased[boxId][who] > 0) {
        max = 0;
      }
    }
    return (paused(), can, max, price);
  }

  function getBoxSales(bytes calldata boxId, address who)
    external
    view
    returns (
      uint32,
      uint32,
      uint32
    )
  {
    return (boxes[boxId].supply, boxSold[boxId], addressPurchased[boxId][who]);
  }

  function getBoxInfo(bytes calldata boxId)
    external
    view
    returns (
      uint256,
      uint256,
      uint32,
      uint8,
      uint8,
      uint32,
      bytes32
    )
  {
    Box storage box = boxes[boxId];
    return (
      box.start,
      box.end,
      box.supply,
      box.mode,
      box.target,
      box.max,
      box.merkleRoot
    );
  }

  function getBoxPrice(bytes calldata boxId, address paymentToken)
    external
    view
    returns (
      uint256,
      uint256,
      uint32,
      uint256
    )
  {
    Box storage box = boxes[boxId];
    return (
      box.retailPrice[paymentToken],
      box.specialPrice[paymentToken],
      box.bulk,
      box.bulkDiscount[paymentToken]
    );
  }

  function transfer(
    bytes calldata boxId,
    address who,
    uint32 quantity,
    string calldata reason
  ) external onlyOperator {
    (address boxProducer, string memory method, uint32 model) = abi.decode(
      boxId,
      (address, string, uint32)
    );
    (bool success, ) = boxProducer.call(
      abi.encodeWithSignature(method, who, model, quantity)
    );
    if (!success) revert TransferFailed();
    emit MarketTransferBoxes(who, boxId, quantity, reason);
  }

  function batchAddOrUpdateBox(
    bytes[] calldata boxIds,
    address[] calldata paymentTokens,
    uint256[] calldata retailPrices,
    uint256[] calldata specialPrices,
    uint256[] calldata bulkDiscounts,
    bool update
  ) external onlyOperator {
    for (uint8 i; i < boxIds.length; i++) {
      Box storage box = boxes[boxIds[i]];
      if (!update && box.retailPrice[paymentTokens[i]] > 0) revert BoxIdUsed();
      if (paymentTokens[i] == address(0)) revert InvalidPaymentMethod();
      if (retailPrices[i] <= 0) revert InvalidPrice();
      box.retailPrice[paymentTokens[i]] = retailPrices[i];
      box.specialPrice[paymentTokens[i]] = specialPrices[i];
      box.bulkDiscount[paymentTokens[i]] = bulkDiscounts[i];
    }
  }

  function updateSales(
    bytes calldata boxId,
    uint256 start,
    uint256 end,
    uint32 supply,
    uint8 mode,
    uint8 target,
    uint32 max,
    uint32 bulk,
    bytes32 merkleRoot
  ) external onlyOperator {
    Box storage box = boxes[boxId];
    box.start = start;
    box.end = end;
    box.supply = supply;
    box.mode = mode;
    box.target = target;
    box.max = max;
    box.bulk = bulk;
    box.merkleRoot = merkleRoot;
  }

  function updateCustom(
    bytes calldata boxId,
    address[] calldata members,
    uint32[] calldata max,
    address[] calldata paymentToken,
    uint256[] calldata price
  ) external onlyOperator {
    Box storage box = boxes[boxId];
    for (uint8 i; i < members.length; i++) {
      Custom storage custom = box.member[members[i]];
      custom.max = max[i];
      custom.price[paymentToken[i]] = price[i];
    }
  }

  function flipPaused() external onlyOperator {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  function updateVault(address _vault) external onlyOwner {
    vault = _vault;
  }
}