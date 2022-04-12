/**
 *Submitted for verification at polygonscan.com on 2022-04-12
*/

// SPDX-License-Identifier: None
pragma solidity 0.8.13;


interface IERC20 {
  function transferByContract(address from, address to, uint amount) external;
  function balanceOf(address user) external returns (uint256);
}

interface IWorldContract {
  function hasRole(bytes32 role, address account) external returns (bool);
  function mintingActive() external returns(bool);
  function burningActive() external returns(bool);
  function setTokenBurningActive(bool active) external;
  function setTokenMintingActive(bool active) external;
  
  function saleStarts(uint tokenId) external view returns(uint);
  function tokenSupply(uint tokenId) external view returns(uint);
  function feeReceiver() external view returns(address);
  function isApprovedForAll(address account, address operator) external view returns (bool);

  function burn(uint256 tokenId) external;

  function buyNFTwithGAME(uint256 tokenId, uint256 pricePaid, uint256 buyAmount) external;

  function buyNFTwithMatic(
    uint256 tokenId, address[] calldata path, uint256 buyAmount
  ) external payable;

  function safeTransferFrom(
    address from, address to, uint256 id, uint256 amount, bytes memory data
  ) external;
}

contract MiningClaimGuardian {
  IWorldContract public worldContract;
  IERC20 public gameToken;

  mapping(address => uint256) public mostRecentBlockTime;
  mapping(address => bool) public blockList;
  mapping(address => bool) public allowList;
  bool public useAllowList = false;
  bool public useBlockList = true;
  uint256 public first500limit = 1;
  uint256 public first1000limit = 3;
  uint256 public first1500limit = 3000;
  uint256 public first2000limit = 3000;
  uint256 public timeBetweenBuys = 5;

  event AllowList(bool isAllowed, address[] users);
  event BlockList(bool isBlocked, address[] users);

  function isAllowedToTransact(address user)
    external view 
  returns(bool isAllowedByAllowList, bool isAllowedByBlockList, bool isAllowedToSell) {
    isAllowedByAllowList = !useAllowList || allowList[user];
    isAllowedByBlockList = !useBlockList || !blockList[user];
    isAllowedToSell = worldContract.isApprovedForAll(user, address(this));
  }

  function getLimits() external view returns(
    uint256 first500,
    uint256 first1000,
    uint256 first1500,
    uint256 first2000,
    uint256 timeBetween
  ) {
    first500 = first500limit;
    first1000 = first1000limit;
    first1500 = first1500limit;
    first2000 = first2000limit;
    timeBetween = timeBetweenBuys;
  }

  modifier onlyWorldAdmin() {
    require(worldContract.hasRole(0x00, msg.sender), "must be world admin");
    _;
  }

  constructor(address _worldContract, address _gameToken) {
    worldContract = IWorldContract(_worldContract);
    gameToken = IERC20(_gameToken);
  }

  function updateAllowList(bool isAllowed, address[] calldata users) external onlyWorldAdmin {
    for(uint i = 0; i < users.length; i++) {
      allowList[users[i]] = isAllowed;
    }
    emit AllowList(isAllowed, users);
  }

  function updateBlockList(bool isBlocked, address[] calldata users) external onlyWorldAdmin {
    for(uint i = 0; i < users.length; i++) {
      blockList[users[i]] = isBlocked;
    }
    emit BlockList(isBlocked, users);
  }

  function setAllowListActive(bool isActive) external onlyWorldAdmin {
    useAllowList = isActive;
  }

  function setBlockListActive(bool isActive) external onlyWorldAdmin {
    useBlockList = isActive;
  }

  function setLimitsByTotalSupply(
    uint256 first500,
    uint256 first1000,
    uint256 first1500,
    uint256 first2000
  ) external onlyWorldAdmin {
    first500limit = first500;
    first1000limit = first1000;
    first1500limit = first1500;
    first2000limit = first2000;
  }

  function setTimeBetweenBuys(uint256 time) external onlyWorldAdmin {
    timeBetweenBuys = time;
  }

  function burn(uint256 tokenId, uint256 amount) public {
    require(amount > 0, "must burn at least one");
  
    // User must have approved this contract before burning.
    // Transfer the tokens from their address to this one
    worldContract.safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
    
    // If burning isn't active, turn it back on (requires admin privileges)
    bool wasBurningActive = worldContract.burningActive();
    if(!wasBurningActive) {
      worldContract.setTokenBurningActive(true);
    }

    // burn, one token at a time
    for(uint i = 0; i < amount; i++) {
      worldContract.burn(tokenId);
    }

    // Turn back off burning (if it was off before)
    if(!wasBurningActive) {
      worldContract.setTokenBurningActive(false);
    }

    // This sets a maximum burn amount of 1 GAME per hour after the sale starts
    // 1000 GAME is hit after 41 days (1.5 months)
    // 2000 GAME is hit after 83 days (3 months)
    uint256 onSale = worldContract.saleStarts(tokenId);
    uint256 maxBurnAmount = ((block.timestamp - onSale) / 3600) * 10 ** 18;
    require(maxBurnAmount >= 167, "must be at least 7 days elapsed");

    // Once we've calculated the max, multiply by the number burned.
    maxBurnAmount = maxBurnAmount * amount;

    // send the lower of maxBurnAmount or gameReceived to the user
    // send any remainder to the fee receiver
    uint256 gameReceived = gameToken.balanceOf(address(this));
    uint256 toRecipient = gameReceived > maxBurnAmount ? maxBurnAmount : gameReceived;
    uint256 toFeeReceiver = gameReceived - toRecipient;
    if(toFeeReceiver > 0) {
      gameToken.transferByContract(address(this), worldContract.feeReceiver(), toFeeReceiver);
    }
    if(toRecipient > 0) {
      gameToken.transferByContract(address(this), msg.sender, toRecipient);
    }
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

    // limit speed of calls
    require(mostRecentBlockTime[msg.sender] + timeBetweenBuys < block.timestamp, "can't call too quickly");
    mostRecentBlockTime[msg.sender] = block.timestamp;

    // check allow and block lists for transactions in the first 15 minutes of a claim sale; 
    uint256 onSale = worldContract.saleStarts(tokenId);
    if(block.timestamp < onSale + 900) {
      bool isBlockedByAllowList = useAllowList && !allowList[msg.sender];
      require(!isBlockedByAllowList, "cannot buy if you're not on the allow list");
      bool isBlockedByBlockList = useBlockList && blockList[msg.sender];
      require(!isBlockedByBlockList, "cannot buy if you're on the block list");
    }

    // check the minting limits, make sure we follow them
    uint256 supply = worldContract.tokenSupply(tokenId);
    if(supply < 500) {
      // Limit to 1 in the first minute
      require(buyAmount == first500limit, "can't buy that many in the first 500");
    } else if(supply < 1000) {
      // Limit to 3 in the first 10 minutes
      require(buyAmount <= first1000limit, "can't buy that many in the first 1000");
    } else if(supply < 1500) {
      require(buyAmount <= first1500limit, "can't buy that many in the first 1500");
    } else if(supply < 2000) {
      require(buyAmount <= first2000limit, "can't buy that many in the first 2000");
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
    // Turn back off minting (if it was off before)
    if(!wasMintingActive) {
      worldContract.setTokenMintingActive(false);
    }

    // send the claims to the user
    worldContract.safeTransferFrom(address(this), msg.sender, tokenId, buyAmount, "");
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