// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { AccessControl } from "./AccessControl.sol";
import { ERC1155 } from "./ERC1155.sol";
import "./Strings.sol";

contract EntryTicket is ERC1155, AccessControl {
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
  bytes32 public constant TRANSFER_ADMIN = keccak256("TRANSFER_ADMIN");

  address private owner;

  event ADMIN_GRANTED(address _beneficiary);
  event ADMIN_REMOVED(address _beneficiary);
  event MANAGER_GRANTED(address _beneficiary);
  event MANAGER_REMOVED(address _beneficiary);
  event TRANSFER_ADMIN_GRANTED(address _beneficiary);
  event TRANSFER_ADMIN_REMOVED(address _beneficiary);

  constructor(string memory url) ERC1155(url) {
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  modifier eitherRoles(bytes32 role1, bytes32 role2) {
    require(hasRole(role1, _msgSender()) || hasRole(role2, _msgSender()), "not permitted");
    _;
  }

  function name() external pure returns (string memory) {
      return "GFC Tickets";
  }

  function symbol() external pure returns (string memory) {
      return "GFCT";
  }

  function uri(uint256 tokenId) public view override returns (string memory) {
    string memory baseURI = ERC1155.uri(tokenId);
    return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /****** Owner functions  ******/

  function grantAdmin(address _beneficiary) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(ADMIN_ROLE, _beneficiary);
    emit ADMIN_GRANTED(_beneficiary);
  }

  function removeAdmin(address _beneficiary) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(ADMIN_ROLE, _beneficiary);
    emit ADMIN_REMOVED(_beneficiary);
  }

  function setURI(string memory newURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _setURI(newURI);
  }

  /****** Admin functions  ******/

  function grantManager(address _beneficiary) external onlyRole(ADMIN_ROLE) {
    _grantRole(MANAGER_ROLE, _beneficiary);
    emit MANAGER_GRANTED(_beneficiary);
  }

  function removeManager(address _beneficiary) external onlyRole(ADMIN_ROLE) {
    _revokeRole(MANAGER_ROLE, _beneficiary);
    emit MANAGER_REMOVED(_beneficiary);
  }

  function grantTransferAdmin(address _beneficiary) external onlyRole(ADMIN_ROLE) {
    _grantRole(TRANSFER_ADMIN, _beneficiary);
    emit TRANSFER_ADMIN_GRANTED(_beneficiary);
  }

  function removeTransferAdmin(address _beneficiary) external onlyRole(ADMIN_ROLE) {
    _revokeRole(TRANSFER_ADMIN, _beneficiary);
    emit TRANSFER_ADMIN_REMOVED(_beneficiary);
  }

  /****** Manager functions  ******/

  function mint(address to, uint256 id, uint256 amount, bytes memory data) public onlyRole(MANAGER_ROLE) {
    _mint(to, id, amount, data);
  }

  function burn(address from, uint256 id, uint256 amount) public onlyRole(MANAGER_ROLE) {
    _burn(from, id, amount);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override eitherRoles(TRANSFER_ADMIN, MANAGER_ROLE) {}
}