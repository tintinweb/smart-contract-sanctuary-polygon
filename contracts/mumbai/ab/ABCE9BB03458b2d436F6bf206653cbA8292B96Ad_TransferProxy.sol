//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import './IERC20.sol';
import './IERC721.sol';
import './IERC1155.sol';

contract TransferProxy {
  event operatorChanged(address indexed from, address indexed to);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  address public owner;
  address public operator;

  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */

  modifier onlyOwner() {
    require(owner == msg.sender, 'Ownable: caller is not the owner');
    _;
  }

  modifier onlyOperator() {
    require(
      operator == msg.sender,
      'OperatorRole: caller does not have the Operator role'
    );
    _;
  }

  /** change the OperatorRole from contract creator address to trade contractaddress
            @param _operator :trade address 
        */

  function changeOperator(address _operator) public onlyOwner returns (bool) {
    require(
      _operator != address(0),
      'Operator: new operator is the zero address'
    );
    operator = _operator;
    emit operatorChanged(address(0), operator);
    return true;
  }

  /** change the Ownership from current owner to newOwner address
        @param newOwner : newOwner address */

  function ownerTransfership(address newOwner) public onlyOwner returns (bool) {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    owner = newOwner;
    emit OwnershipTransferred(owner, newOwner);
    return true;
  }

  function erc721safeTransferFrom(
    IERC721 token,
    address from,
    address to,
    uint256 tokenId
  ) external onlyOperator {
    token.safeTransferFrom(from, to, tokenId);
  }

  function erc1155safeTransferFrom(
    IERC1155 token,
    address from,
    address to,
    uint256 tokenId,
    uint256 value,
    bytes calldata data
  ) external onlyOperator {
    token.safeTransferFrom(from, to, tokenId, value, data);
  }

  function erc20safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) external onlyOperator {
    require(token.transferFrom(from, to, value), 'failure while transferring');
  }
}