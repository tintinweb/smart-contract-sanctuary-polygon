// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./Ownable.sol";
import "./IERC721.sol";

contract NFTStaking is Ownable{

      IERC20 public token; 
      IERC721 public nft;

  bool private initialized = false;
  uint public nftPrice;
  uint256 public oneMonth = 30 days;
  uint256 public sixMonths = 180 days;
  uint256 public twelveMonths = 365 days;

  uint8 public reward1Month = 5;
  uint8 public reward6Months = 10;
  uint8 public reward12Months = 15;

  mapping(address => mapping(uint => uint256)) public stakings;

  constructor (IERC721 _nft, uint _nftPrice) public {
    nft = _nft;
    nftPrice = _nftPrice;
  }

  function initializeToken(address _token) onlyOwner public returns (bool) {
      require(!initialized, "Already Initialized");
      initialized = true;
      token = IERC20(_token);
      return true;
  }

  function stake(uint _nftId, uint256 _duration) public {
    require(nft.ownerOf(_nftId) == msg.sender, "NFT is not owned by the user");
    nft.transferFrom(msg.sender, address(this), _nftId);
    stakings[msg.sender][_nftId] = _duration * 86400;
  }

  function retrieve(uint _nftId) public {
    uint256 reward = 0;
    require(stakings[msg.sender][_nftId] != 0, "NFT not found");

    if (stakings[msg.sender][_nftId] >= oneMonth && stakings[msg.sender][_nftId] < sixMonths) {
      reward = nftPrice * reward1Month / 100;
    } else if (stakings[msg.sender][_nftId] >= sixMonths && stakings[msg.sender][_nftId] < twelveMonths) {
      reward = nftPrice * reward6Months / 100;
    } else if (stakings[msg.sender][_nftId] == twelveMonths) {
      reward = nftPrice * reward12Months / 100;
    }else { 
        reward = nftPrice * 15 / 100;
    }

    token.transfer(msg.sender, reward);

  }
}