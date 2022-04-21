// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./EnumerableSet.sol";

error WhitelistOnly();
error AccountEmpty();

contract NFTBank is Ownable, IERC721Receiver {
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.AddressSet;

  mapping(address => mapping(address => EnumerableSet.UintSet))
    private operatorTokens;
  EnumerableSet.AddressSet private whitelists;

  event Deposit(address from, address operator, uint256 tokenId);
  event Withdraw(address operator, address to, uint256 tokenId);

  function isWhitelist(address _address) public view returns (bool) {
    return whitelists.contains(_address);
  }

  function addWhitelist(address _contract) external onlyOwner {
    whitelists.add(_contract);
  }

  function removeWhitelist(address _contract) external onlyOwner {
    whitelists.remove(_contract);
  }

  function getWhitelists() external view returns (address[] memory) {
    return whitelists.values();
  }

  function deposit(
    address collection,
    address operator,
    uint256[] calldata tokenIds
  ) external {
    if (!isWhitelist(operator)) revert WhitelistOnly();
    EnumerableSet.UintSet storage _tokens = operatorTokens[operator][
      collection
    ];
    for (uint256 i; i < tokenIds.length; i++) {
      IERC721(collection).safeTransferFrom(
        msg.sender,
        address(this),
        tokenIds[i]
      );
      _tokens.add(tokenIds[i]);

      emit Deposit(msg.sender, operator, tokenIds[i]);
    }
  }

  function withdraw(
    address collection,
    address to,
    uint256[] calldata tokenIds
  ) external {
    if (!isWhitelist(msg.sender)) revert WhitelistOnly();
    EnumerableSet.UintSet storage _tokens = operatorTokens[msg.sender][
      collection
    ];
    if (_tokens.length() == 0) revert AccountEmpty();
    for (uint256 i; i < tokenIds.length; i++) {
      IERC721(collection).safeTransferFrom(address(this), to, tokenIds[i]);
      _tokens.remove(tokenIds[i]);

      emit Withdraw(msg.sender, to, tokenIds[i]);
    }
  }

  function getDeposited(address collection, address operator)
    external
    view
    returns (uint256[] memory)
  {
    return operatorTokens[operator][collection].values();
  }

  function onERC721Received(
    address operator,
    address,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    if (operator != address(this)) {
      (address collection, address wlOperator) = abi.decode(
        data,
        (address, address)
      );
      if (!isWhitelist(wlOperator)) revert WhitelistOnly();
      operatorTokens[wlOperator][collection].add(tokenId);

      emit Deposit(operator, wlOperator, tokenId);
    }
    return IERC721Receiver.onERC721Received.selector;
  }
}