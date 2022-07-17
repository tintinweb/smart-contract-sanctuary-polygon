//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./ERC721URIStorage.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./Strings.sol";
import "./Counters.sol";


interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - token ID and URI autogenerationA
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract MegaBabies is Context,  AccessControlEnumerable, ERC721Enumerable, ERC721URIStorage{
  using Counters for Counters.Counter;
  Counters.Counter public _tokenIdTracker;

  string private _baseTokenURI;
  uint private _price = 15000000000;  
  uint private _max = 10000;
  address private _admin;
  address private _feeReciever;
  IDEXRouter public router;
  bool public canMint = false;
  uint public _rewardPercent = 5; // 5% rewards to start with
  uint public MinterPercentage = 3;
  uint public MarketFeePercentage = 2;
  IBEP20 public payableToken;
  address WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
  address deadAddress = 0x000000000000000000000000000000000000dEaD;
  

  uint256 public reflectionBalance;
  uint256 public totalDividend;

  mapping(uint256 => uint256) lastDividendAt;
  mapping (uint256 => address ) public creator;
  mapping (address => bool) public excludedFromRewards; 

  uint256 private mintAMount = 100;
  bool marketPlaceLive = false;
  uint256 public totalrewards = 0;


  constructor(string memory name, string memory symbol, string memory baseTokenURI, uint mintPrice, uint max, address admin) ERC721(name, symbol) {
      _baseTokenURI = baseTokenURI;
      _price = mintPrice;
      _max = max;
      _admin = admin;
      //router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Mainnet
      router = IDEXRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // matic mainnet
      _setupRole(DEFAULT_ADMIN_ROLE, admin);
  }

  receive () external payable {
     payable(_admin).transfer(msg.value /2);
     reflectDividend(msg.value / 2);

  }

  function setPayableToken(IBEP20 token)external{
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MegaBabies: must have admin role to set payable token");
    payableToken = token;
  }

  function Harvest()external{
    address[] memory path = new address[](2);
            path[1] = router.WETH();
            path[0] = address(payableToken);
    uint balanceBefore = address(this).balance;
    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      payableToken.balanceOf(address(this)),
        0,
        path,
        address(this),
        block.timestamp + 100
    );
    uint balanceAfter = address(this).balance;
    uint totaldiff = balanceAfter - balanceBefore;
    payable(_admin).transfer(totaldiff /2);
    reflectDividend(totaldiff / 2);
  }



  function getPrice() external view returns (uint){
    return _price;
  }

  function setAdditionalAdmin(address newAdmin) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MegaBabies: must have admin role to add admins");
    _setupRole(DEFAULT_ADMIN_ROLE, newAdmin);
  } 

  // @DEV:  this is anything like a marketplace etc
  function excludeFromreward(address Add, bool excluded) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MegaBabies: must have admin role to add exclusions");
    excludedFromRewards[Add] = excluded;
  } 

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }

   function setFeeReciever(address reciever)public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MegaBabies: must have admin role to change fee reciever");
    _feeReciever = reciever;
  }

  function setBaseURI(string memory baseURI) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MegaBabies: must have admin role to change base URI");
    _baseTokenURI = baseURI;
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MegaBabies: must have admin role to change token URI");
    _setTokenURI(tokenId, _tokenURI);
  }

  function setMintingEnabled(bool Allowed) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MegaBabies: must have admin role to change minting ability");
    canMint = Allowed;
  }

  function setPrice(uint mintPrice) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MegaBabies: must have admin role to change price");
    _price = mintPrice;
  }
  

  function setRewardPercent(uint pcnt) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MegaBabies: must have admin role to change reward percentages");
    _rewardPercent = pcnt;
  }

 function getMintPrice() external view returns(uint256){
     return _price;
 }
 
  function mint() public payable {
    require(canMint, "MegaBabies: minting currently disabled");
    require(msg.value >= _price, "MegaBabies: must send correct price");
    require(_tokenIdTracker.current() < _max, "MegaBabies: all MegaBabies have been minted");
    _mint(msg.sender, _tokenIdTracker.current());
    creator[_tokenIdTracker.current()] = msg.sender;
    lastDividendAt[_tokenIdTracker.current()] = totalDividend;
    _setTokenURI(_tokenIdTracker.current(), string(abi.encodePacked(Strings.toString(_tokenIdTracker.current()), ".json")));
    _tokenIdTracker.increment();
    splitBalance(msg.value);
  }

    function mintMany(uint256 quantity) public payable {
    require(canMint, "MegaBabies: minting currently disabled");
    require (quantity < 11, "MegaBabies: minting more than 10 is prohibited");
    require(msg.value >= (quantity * _price), "MegaBabies: must send correct price");
    require((_tokenIdTracker.current() + quantity) < _max, "MegaBabies: all MegaBabies have been minted");
    for(uint i = 0; i < quantity; i++){
      _mint(msg.sender, _tokenIdTracker.current());
      creator[_tokenIdTracker.current()] = msg.sender;
      lastDividendAt[_tokenIdTracker.current()] = totalDividend;
      _setTokenURI(_tokenIdTracker.current(), string(abi.encodePacked(Strings.toString(_tokenIdTracker.current()), ".json")));
      _tokenIdTracker.increment();
    }
    splitBalance(msg.value);
  }

  function isApprovedForAll(
        address _owner,
        address _operator
    ) public override(ERC721, IERC721) view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
      // for Polygon's Mumbai testnet, use 0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

  function mintMultiples(address[] calldata recipients)public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MegaBabies: must have admin role to initial mint");
        for (uint256 i = 0; i < recipients.length; i++){
      _mint(recipients[i], _tokenIdTracker.current());
      creator[_tokenIdTracker.current()] = recipients[i];
      lastDividendAt[_tokenIdTracker.current()] = totalDividend;
      _setTokenURI(_tokenIdTracker.current(), string(abi.encodePacked(Strings.toString(_tokenIdTracker.current()), ".json")));
      _tokenIdTracker.increment();
    }
  }

  function BabyCreator(uint256 tokenId) public view returns(address){
    return creator[tokenId];
  }

  function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
    return ERC721URIStorage._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return ERC721URIStorage.tokenURI(tokenId);
  }
  
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
    if (totalSupply() > tokenId) claimReward(tokenId);
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
    * @dev See {IERC165-supportsInterface}.
    */
  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function currentRate() public view returns (uint256){
      if(totalSupply() == 0) return 0;
      return reflectionBalance/totalSupply();
  }

  function claimRewards() public {
    uint count = balanceOf(msg.sender);
    uint256 total = 0;
    for(uint i=0; i < count; i++){
        uint tokenId = tokenOfOwnerByIndex(msg.sender, i);
        //claimReward(tokenId);
        total += getReflectionBalance(tokenId);
        lastDividendAt[tokenId] = totalDividend;
    }
    if(total > 0){
         payable(msg.sender).transfer(total);
        reflectionBalance -= total;
    }
  }


  function claimReward(uint tokenId) internal {
      uint256 total = getReflectionBalance(tokenId);
    if(total > 0){
      reflectionBalance -= total;
      if(!excludedFromRewards[ownerOf(tokenId)]){
         payable(ownerOf(tokenId)).transfer(total);
      }else{
        payable(_admin).transfer(total);
      }
     
      lastDividendAt[tokenId] = totalDividend;
    }
  }

  function getReflectionBalances() public view returns(uint256) {
    uint count = balanceOf(msg.sender);
    uint256 total = 0;
    for(uint i=0; i < count; i++){
        uint tokenId = tokenOfOwnerByIndex(msg.sender, i);
        total += getReflectionBalance(tokenId);
    }
    return total;
  }

  function claimTokens () public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MegaBabies: must have admin role to claim the balance");
    // make sure we capture all BNB that may or may not be sent to this contract
    payable(_admin).transfer(address(this).balance - reflectionBalance);
  }

  function EmergencyWithdraw () public {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "MegaBabies: must have admin role to claim the balance");
    // make sure we capture all BNB that may or may not be sent to this contract
    payable(_admin).transfer(address(this).balance);
    totalDividend = 0;
    reflectionBalance = 0; 
  }

  function getReflectionBalance(uint256 tokenId) public view returns (uint256){
      return totalDividend - lastDividendAt[tokenId];
  }

  function splitBalance(uint256 amount) private {
      uint256 reflectionShare = ( amount * _rewardPercent / 100);
      reflectDividend(reflectionShare);
      payable(_admin).transfer(amount - reflectionShare);
  }

  function DepositDividend() public payable {
    reflectionBalance  = reflectionBalance + msg.value;
    totalDividend = totalDividend + (msg.value/totalSupply());
  }

  function reflectDividend(uint256 amount) private {
    reflectionBalance  = reflectionBalance + amount;
    totalDividend = totalDividend + (amount/totalSupply());
  } 
}