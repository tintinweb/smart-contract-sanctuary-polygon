/**
 *Submitted for verification at polygonscan.com on 2022-04-11
*/

// SPDX-License-Identifier: None
pragma solidity 0.8.13;


interface IERC20 {
  function transferByContract(address from, address to, uint amount) external;
}

interface IWorldContract {
  function mintingActive() external returns(bool);
  function setTokenMintingActive(bool active) external;
  function saleStarts(uint tokenId) external returns(uint startTime);

  function buyNFTwithGAME(uint256 tokenId, uint256 pricePaid, uint256 buyAmount) external;

  function buyNFTwithMatic(
    uint256 tokenId, address[] calldata path, uint256 buyAmount
  ) external payable;

  function safeTransferFrom(
    address from, address to, uint256 id, uint256 amount, bytes memory data
  ) external;
}

contract BuyMiningClaims {
  IWorldContract worldContract;
  IERC20 gameToken;

  constructor(address _worldContract, address _gameToken) {
    worldContract = IWorldContract(_worldContract);
    gameToken = IERC20(_gameToken);
  }

  function buyNFTwithGAME(
    uint256 tokenId, 
    uint256 pricePaid, 
    uint256 buyAmount
  ) public {
    bool wasMintingActive = _beforeBuy(tokenId, buyAmount);
    gameToken.transferByContract(msg.sender, address(this), pricePaid);
    worldContract.buyNFTwithGAME(tokenId, pricePaid, buyAmount);
    _afterBuy(tokenId, buyAmount, wasMintingActive);
  }

  function buyNFTwithMatic(
    uint256 tokenId, 
    address[] calldata path, 
    uint256 buyAmount
  ) public payable {
    bool wasMintingActive = _beforeBuy(tokenId, buyAmount);
    worldContract.buyNFTwithMatic{value:msg.value}(tokenId, path, buyAmount);
    _afterBuy(tokenId, buyAmount, wasMintingActive);
  }

  function _beforeBuy(
    uint256 tokenId, 
    uint256 buyAmount
  ) internal returns(bool wasMintingActive) {
    // ban inter-contract calls
    require(msg.sender == tx.origin, "can only call from an EOA");
    // check the minting limits, make sure we follow them
    uint256 saleStart = worldContract.saleStarts(tokenId);
    if(block.timestamp < saleStart + 60) {
      // Limit to 1 in the first minute
      require(buyAmount == 1, "can buy a max of 1 in the first minute");
    } else if(block.timestamp < saleStart + 600) {
      // Limit to 3 in the first 10 minutes
      require(buyAmount <= 3, "can buy a max of 3 in the first 10 minutes");
    }

    // If minting is't active, turn it back on (requires admin privileges)
    wasMintingActive = worldContract.mintingActive();
    if(!wasMintingActive) {
      worldContract.setTokenMintingActive(true);
    }
  }

  function _afterBuy(
    uint256 tokenId, 
    uint256 buyAmount,
    bool wasMintingActive
  ) internal {
    // send the claims to the user
    worldContract.safeTransferFrom(address(this), msg.sender, tokenId, buyAmount, "");

    // Turn back on the
    if(!wasMintingActive) {
      worldContract.setTokenMintingActive(false);
    }
  }

  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  )
    external
    pure
  returns(bytes4) {
    return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
  }

  function updateLocalContract(address contract_, bool isLocal_) external {}

  function isLocalContract()
    external
    virtual
    pure
  returns(bool) {
    return true;
  }
}