/**
 *Submitted for verification at polygonscan.com on 2022-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
}

interface IERC721 {
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC1155 {
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

contract KaloscopeAirdrop {

/*
* _token: contract address of the token
* _to: array of reciever wallet address - [0x000000602f2201754215B5C239dCeCeD998F39f0, 0x000000d377f1c400EF39ffA4cf6F93a4C17712F5, ...]
* _ids/_value: token id in array, same index (sequence) as reciever wallet address - [105312291668557186697918027683670432318895095400549111254310977586, 105312291668557186697918027683670432318895095400549111254310977587,...]
* _amounts: for erc1155, total supply for each wallet/token - [1,1,1,1,1,1...]
*/
  function airDropERC20(IERC20 _token, address[] calldata _to, uint256[] calldata _value) public {
    require(_to.length == _value.length, "Receivers and amounts are different length");
    for (uint256 i = 0; i < _to.length; i++) {
      require(_token.transferFrom(msg.sender, _to[i], _value[i]));
    }
  }

  function airDropERC721(IERC721 _token, address[] calldata _to, uint256[] calldata _ids) public {
    require(_to.length == _ids.length, "Receivers and IDs are different length");
    for (uint256 i = 0; i < _to.length; i++) {
      _token.safeTransferFrom(msg.sender, _to[i], _ids[i]);
    }
  }

  function airDropERC1155(IERC1155 _token, address[] calldata _to, uint256[] calldata _ids, uint256[] calldata _amounts) public {
    require(_to.length == _ids.length, "Receivers and IDs are different length");
    require(_ids.length == _amounts.length, "IDs and Amounts are different length");
    for (uint256 i = 0; i < _to.length; i++) {
      _token.safeTransferFrom(msg.sender, _to[i], _ids[i], _amounts[i], "");
    }
  }

  //token
  function dropERC20(IERC20 _token, address[] calldata _to, uint256 firstTokeId) public {
    for (uint256 i = 0; i < _to.length; i++) {
      require(_token.transferFrom(msg.sender, _to[i], firstTokeId + i));
    }
  }

  function dropERC721(IERC721 _token, address[] calldata _to, uint256 firstTokeId) public {
    for (uint256 i = 0; i < _to.length; i++) {
      _token.safeTransferFrom(msg.sender, _to[i], firstTokeId + i);
    }
  }
}