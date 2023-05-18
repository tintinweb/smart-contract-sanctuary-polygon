// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Donation {
  string public repository;
  address internal owner;

  event Paid(uint amount, address by);

  constructor(string memory _repository, address _owner) payable {
    repository = _repository;
    owner = _owner;
  }

  function payout(address payable _to) public {
    require(msg.sender == owner, "Only the ledger can request a payout");
    uint value = address(this).balance;
    (bool sent, ) = _to.call{value: value}("");
    require(sent, "Failed to pay out donation");

    emit Paid(value, _to);
  }

  /// @notice Shows the repository this donation was made to
  function getRepository() public view returns (string memory) {
    return repository;
  }
}