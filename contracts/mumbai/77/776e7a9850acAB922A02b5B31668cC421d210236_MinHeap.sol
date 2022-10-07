// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// implementation of binary min heap
contract MinHeap {
  //heap

  mapping(address => mapping(uint256 => Node[])) public heapPrice;
  mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
    public heapIndex;

  struct Node {
    uint256 index;
    uint256 sellOrderIndex;
    uint256 price;
  }

  //events
  event Inserted(uint256 price, uint256 index);
  event Removed(uint256 price, uint256 index);

  //insert
  function insert(
    address token,
    uint256 tokenId,
    uint256 price,
    uint256 sellOrderIndex
  ) public {
    Node memory node = Node(
      heapPrice[token][tokenId].length,
      sellOrderIndex,
      price
    );
    heapPrice[token][tokenId].push(node);
    heapIndex[token][tokenId][sellOrderIndex] = node.index;
    _bubbleUp(token, tokenId, node.index);
    emit Inserted(price, node.index);
  }

  //remove
  function remove(
    address token,
    uint256 tokenId,
    uint256 index
  ) public returns (uint256) {
    uint256 lastIndex = heapPrice[token][tokenId].length - 1;
    Node memory lastNode = heapPrice[token][tokenId][lastIndex];
    heapPrice[token][tokenId][index] = lastNode;
    heapIndex[token][tokenId][lastNode.sellOrderIndex] = index;
    heapPrice[token][tokenId].pop();
    if (index != lastIndex) {
      _bubbleUp(token, tokenId, index);
      _bubbleDown(token, tokenId, index);
    }
    emit Removed(lastNode.price, index);
    return lastNode.sellOrderIndex;
  }

  //getMin
  function getMin(address token, uint256 tokenId)
    public
    view
    returns (Node memory)
  {
    return heapPrice[token][tokenId][0];
  }

  //bubbleUp
  function _bubbleUp(
    address token,
    uint256 tokenId,
    uint256 index
  ) internal {
    uint256 parentIndex = (index - 1) / 2;
    while (
      index > 0 &&
      heapPrice[token][tokenId][index].price <
      heapPrice[token][tokenId][parentIndex].price
    ) {
      Node memory node = heapPrice[token][tokenId][index];
      Node memory parentNode = heapPrice[token][tokenId][parentIndex];
      heapPrice[token][tokenId][index] = parentNode;
      heapPrice[token][tokenId][parentIndex] = node;
      heapIndex[token][tokenId][node.sellOrderIndex] = parentIndex;
      heapIndex[token][tokenId][parentNode.sellOrderIndex] = index;
      index = parentIndex;
      parentIndex = (index - 1) / 2;
    }
  }

  //bubbleDown
  function _bubbleDown(
    address token,
    uint256 tokenId,
    uint256 index
  ) internal {
    uint256 leftChildIndex = 2 * index + 1;
    uint256 rightChildIndex = 2 * index + 2;
    uint256 smallestIndex = index;
    uint256 length = heapPrice[token][tokenId].length;
    if (
      leftChildIndex < length &&
      heapPrice[token][tokenId][leftChildIndex].price <
      heapPrice[token][tokenId][smallestIndex].price
    ) {
      smallestIndex = leftChildIndex;
    }
    if (
      rightChildIndex < length &&
      heapPrice[token][tokenId][rightChildIndex].price <
      heapPrice[token][tokenId][smallestIndex].price
    ) {
      smallestIndex = rightChildIndex;
    }
    if (smallestIndex != index) {
      Node memory node = heapPrice[token][tokenId][index];
      Node memory smallestNode = heapPrice[token][tokenId][smallestIndex];
      heapPrice[token][tokenId][index] = smallestNode;
      heapPrice[token][tokenId][smallestIndex] = node;
      heapIndex[token][tokenId][node.sellOrderIndex] = smallestIndex;
      heapIndex[token][tokenId][smallestNode.sellOrderIndex] = index;
      _bubbleDown(token, tokenId, smallestIndex);
    }
  }

  //getLength
  function getLength(address token, uint256 tokenId)
    public
    view
    returns (uint256)
  {
    return heapPrice[token][tokenId].length;
  }

  //getPrice
  function getPrice(
    address token,
    uint256 tokenId,
    uint256 index
  ) public view returns (uint256) {
    return heapPrice[token][tokenId][index].price;
  }

  //given a sellOrderIndex, get the index in the heap
  function getIndex(
    address token,
    uint256 tokenId,
    uint256 sellOrderIndex
  ) public view returns (uint256) {
    return heapIndex[token][tokenId][sellOrderIndex];
  }

  //given a sellOrderIndex, get the price in the heap
  function getPriceBySellOrderIndex(
    address token,
    uint256 tokenId,
    uint256 sellOrderIndex
  ) public view returns (uint256) {
    uint256 index = heapIndex[token][tokenId][sellOrderIndex];
    return heapPrice[token][tokenId][index].price;
  }

  //given a sellOrderIndex, remove
  function removeBySellOrderIndex(
    address token,
    uint256 tokenId,
    uint256 sellOrderIndex
  ) public returns (uint256) {
    uint256 index = heapIndex[token][tokenId][sellOrderIndex];
    return remove(token, tokenId, index);
  }

  //given a sellOrderIndex, update the price
  function updatePriceBySellOrderIndex(
    address token,
    uint256 tokenId,
    uint256 sellOrderIndex,
    uint256 price
  ) public {
    uint256 index = heapIndex[token][tokenId][sellOrderIndex];
    heapPrice[token][tokenId][index].price = price;
    _bubbleUp(token, tokenId, index);
    _bubbleDown(token, tokenId, index);
  }
}