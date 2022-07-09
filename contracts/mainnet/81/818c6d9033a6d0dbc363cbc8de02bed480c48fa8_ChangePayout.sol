// SPDX-License-Identifier: MIT
pragma solidity >=0.6.3 <0.9.0;

import "../RDAO.sol";
import "./Executable.sol";

contract ChangePayout is Executable {
  mapping(address => RDAO.Member) public members;
  mapping(uint256 => RDAO.Voting) public votings;
  mapping(uint => RDAO.Role) roles;
  address[] public memberList;
  mapping(RDAO.ActionType => address) public parameterProviders;
  mapping(address => uint) credits;

  struct Member {
    mapping(uint => bool) roles;
    address canPayOut;
    uint16 proposalCounter;
    uint lastPayout;
    // Maximum payout in wei per second
    uint maxPayout;
  }
  function execute(bytes calldata data) public payable {
    (address memberAddr, address canPayOut, uint newMaxPayout) = abi.decode(data, (address, address, uint));
    members[memberAddr].canPayOut = canPayOut;
    members[memberAddr].maxPayout = newMaxPayout;
  }

  function validate(uint executingRoleId, bytes calldata data) public payable {
    (address memberAddr, address canPayOut,) = abi.decode(data, (address, address, uint));
    require(roles[executingRoleId].permissions & 64 == 64, "Not authorized");
    require(members[memberAddr].proposalCounter > 0, "Address not a member");
    require(members[canPayOut].proposalCounter > 0, "Payer not a member");
  }
}