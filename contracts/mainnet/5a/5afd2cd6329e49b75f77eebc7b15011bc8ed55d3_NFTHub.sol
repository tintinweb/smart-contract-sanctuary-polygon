// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./EnumerableSet.sol";

error WhitelistOnly();
error AgentOnly();

contract NFTHub is Ownable, IERC721Receiver {
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet private whitelists;
  mapping(address => EnumerableSet.AddressSet) private agents;
  mapping(address => EnumerableSet.AddressSet) private members;

  event Forward(address operator, address from, address to, uint256 tokenId);

  function isWhitelist(address _address) public view returns (bool) {
    return whitelists.contains(_address);
  }

  function addWhitelist(address _address) external onlyOwner {
    whitelists.add(_address);
  }

  function removeWhitelist(address _address) external onlyOwner {
    whitelists.remove(_address);
  }

  function getWhitelists() external view returns (address[] memory) {
    return whitelists.values();
  }

  function isAgent(address _owner, address _agent) public view returns (bool) {
    return agents[_owner].contains(_agent);
  }

  function addAgent(address _agent) external {
    agents[msg.sender].add(_agent);
    members[_agent].add(msg.sender);
  }

  function removeAgent(address _agent) external {
    agents[msg.sender].remove(_agent);
    members[_agent].remove(msg.sender);
  }

  function getAgents() external view returns (address[] memory) {
    return agents[msg.sender].values();
  }

  function getMembers() external view returns (address[] memory) {
    return members[msg.sender].values();
  }

  function forward(
    address collection,
    address from,
    address to,
    uint256[] calldata tokenIds
  ) external {
    if (!isWhitelist(msg.sender)) revert WhitelistOnly();
    if (msg.sender != from && !isAgent(from, msg.sender)) revert AgentOnly();
    for (uint256 i; i < tokenIds.length; i++) {
      IERC721(collection).safeTransferFrom(from, address(this), tokenIds[i]);
      IERC721(collection).safeTransferFrom(address(this), to, tokenIds[i]);

      emit Forward(msg.sender, from, to, tokenIds[i]);
    }
  }

  function onERC721Received(
    address operator,
    address,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    if (operator != address(this)) {
      if (!isWhitelist(operator)) revert WhitelistOnly();
      (address collection, address to) = abi.decode(data, (address, address));
      IERC721(collection).safeTransferFrom(address(this), to, tokenId);
      emit Forward(operator, operator, to, tokenId);
    }
    return IERC721Receiver.onERC721Received.selector;
  }
}