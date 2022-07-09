// SPDX-License-Identifier: MIT
pragma solidity >=0.6.3 <0.9.0;

import "../RDAO.sol";
import "./Executable.sol";

contract ChangeRole is Executable {
  event RoleChanged(uint roleId, uint16 rank, uint16 permissions);

  mapping(address => RDAO.Member) public members;
  mapping(uint256 => RDAO.Voting) public votings;
  mapping(uint => RDAO.Role) roles;
  address[] public memberList;

  function execute(bytes calldata data) public payable {
    (uint256 roleId, uint16 rank, uint16 permissions) = abi.decode(data, (uint256, uint16, uint16));
    roles[roleId] = RDAO.Role(rank, permissions);
    emit RoleChanged(roleId, rank, permissions);
  }

  function validate(uint executingRoleId, bytes calldata data) public payable {
    (uint256 roleId, uint16 rank, uint16 permissions) = abi.decode(data, (uint256, uint16, uint16));
    require(roles[executingRoleId].permissions & 128 == 128, "Not authorized");
    require(roles[roleId].rank != 0, "Role undefined");
    require(rank > 0, "Rank cannot be 0");
    if (executingRoleId != 0) {
      require(rank < roles[executingRoleId].rank, "New Rank too high");
      require(roles[roleId].rank < roles[executingRoleId].rank, "Role rank too high");
      require(permissions | roles[executingRoleId].permissions == roles[executingRoleId].permissions, "Invalid permissions");
    }
  }
}