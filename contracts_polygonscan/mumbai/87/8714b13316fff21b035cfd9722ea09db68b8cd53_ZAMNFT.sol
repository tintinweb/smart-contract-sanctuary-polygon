// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
contract ZAMNFT is ERC721Enumerable, Ownable {
  using Strings for uint256;
  // uint256 public level1 = 1;
  //uint public level2 = 7001;
  //uint public level3 = 8501;
  uint256 public AmountOfNFT;
  uint256 level1counter = 0;
  uint256 level2counter = 0;
  uint256 level3counter = 0;
  uint256 level1 = 1; 
  uint level2 = 70;
  uint level3 = 85;
  uint public level1left = 70 - level1counter; 
  uint public level2left = 15 - level2counter;
  uint public level3left = 15 - level3counter;
  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.18 ether;
  uint256 public presaleprice = 0.14 ether;
  uint256 public maxSupply = 100;
  uint256 public maxMintAmount = 100;
  bool public paused = false;
  bool public presale = true;
  uint256 public presaleAmount = 2000;
  mapping(address => bool) public whitelisted;
  mapping(address => bool) public secondLevel;
  mapping(address => bool) public thirdLevel;
  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
  }


  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }


  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    //uint256 balance = token.balanceOf(msg.sender);
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);
    if (presale = true){
      if (msg.sender != owner()){
    require(whitelisted[msg.sender] = true, "Sorry, but you can't buy NFT");
    require(msg.value >= presaleprice * _mintAmount,"Add Funds");
    require(msg.value != 0);
    }
    if(secondLevel[msg.sender]!=true && thirdLevel[msg.sender]!=true){
    require(level1<=70, "NFT LEVEL 1 SOLD OUT");
    require(_mintAmount + level1counter <= 70,"NFT is left or mint amount is too big");
    for (uint256 i = 0; i < _mintAmount; i++) {
      _safeMint(msg.sender, level1 + i);
    }
    level1 = level1+_mintAmount; 
    level1counter = level1counter + _mintAmount;
    }
    if(secondLevel[msg.sender] = true){
    require(level2<=85, "NFT LEVEL 2 SOLD OUT");
    require(_mintAmount + level2counter <= 85, "NFT is left or mint amount is too big");

     for (uint256 i = 0; i <_mintAmount;i++){ 
     _safeMint(msg.sender, level2 + i);
    }
    level2 = level2+_mintAmount;
    level2counter = level2counter + _mintAmount;

    }
    if(thirdLevel[msg.sender] = true ){
      require(level3 <=100, "NFT LEVEL 3 SOLD OUT");
      require(_mintAmount + level3counter <= 175, "NFT is left or mint amount is too big");

      for (uint256 i = 0; i< _mintAmount;i++){
        _safeMint(msg.sender, level3+i); 
      }
      level3 = level3+_mintAmount;
      level3counter = level3counter + _mintAmount;

    }
    }
    else {
      require(msg.value >= cost * _mintAmount); 
      if (whitelisted[msg.sender] = true){
      require(msg.value >= presaleprice * _mintAmount);
                 }
    
     if(secondLevel[msg.sender]!=true && thirdLevel[msg.sender]!=true){
      require(level1<=70, "NFT LEVEL 1 SOLD OUT");
      require(_mintAmount + level1counter <= 70, "NFT is left or mint amount is too big");
    for (uint256 i = 0; i < _mintAmount; i++) {
      _safeMint(msg.sender, level1 + i);
    }
    level1 = level1+_mintAmount; 
    }
    if(secondLevel[msg.sender] = true){
      require(level2<=85, "NFT LEVEL 2 SOLD OUT");
      require(_mintAmount + level2counter <= 85, "NFT is left or mint amount is too big");
     for (uint256 i = 0; i <_mintAmount;i++){ 
     _safeMint(msg.sender, level2 + i);
    }
    level2 = level2+_mintAmount;
    }
    if(thirdLevel[msg.sender] = true){
      require(level3<=100, "NFT LEVEL 3 SOLD OUT");
      require(_mintAmount + level3counter <= 100, "NFT is left or mint amount is too big");
      for (uint256 i = 0; i< _mintAmount;i++){
        _safeMint(msg.sender, level3+i);
      }
      level3 = level3+_mintAmount;
    }
    }
  }

 function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }


  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function endpresale(bool _state) public onlyOwner{
    presale = _state;
  }
  
  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function whitelistUser(address[] calldata users) external onlyOwner  {
   for (uint i =0;i<users.length;i++){
    whitelisted[users[i]] = true;
   }
  }
  function secondLeveluser(address[] calldata users) external onlyOwner {
    for(uint i =0;i<users.length;i++){
      secondLevel[users[i]] = true;
    }
  }
  function thirdLeveluser(address[] calldata users) external onlyOwner {
    for(uint i =0;i<users.length;i++){
      thirdLevel[users[i]] = true;
    }
  }
 
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdraw() payable external onlyOwner {
    uint256 amount = address(this).balance;
    payable(owner()).transfer(amount);
  }
}