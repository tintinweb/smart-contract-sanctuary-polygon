// SPDX-License-Identifier: MIT
/*
Metaverse Penguins Smart Contract by Cahit Karahan

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@                       (@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@                               @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@                                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@                                         @@@@@@@@@@@@@@@@@@@@@@@@@@
@@@#                                                    @@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@                                                   @@@@@@@@@@@@@@@@@@@@@@@
@   #@@@@@@@@@*                                           @@@@@@@@@@@@@@@@@@@@@@
@          [email protected]@@@@@@@@@@@@@@@&&                             @@@@@@@@@@@@@@@@@@@@@
@@                     %@@@@@@@@@@@@@@@@@@@@@,             @@@@@@@@@@@@@@@@@@@@@
@@                                           ,@@@@@%        @@@@@@@@@@@@@@@@@@@@
@@                                                   @      @@@@@@@@@@@@@@@@@@@@
@@@                                                  %     @@@@@@@@@@@@@@@@@@@@@
@@@                                                  @     @@@@@@@@@@@@@@@@@@@@@
@@@@@                                               @      @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@.                                       @       @@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@  @@@@@@@#                            #@         @@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@  @  @@@@@@@@@@@.        [email protected]@@@@@             @@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@      @@@@@@@@((   //@@@//    (@@@               @@@@@@@@@@@@@@@@@@@@
@@@@@@@@             @@@@@@@@@@@@@@@@@@@@@                   @@@@@@@@@@@@@@@@@@@
@@@@@@/         @       @@@@@@@@@@@@                           @@@@@@@@@@@@@@@@@
@@@@@         @@@                @                              @@@@@@@@@@@@@@@@
@@@@@        @@@@               @@@@                              @@@@@@@@@@@@@@
@@@@@       @@@@@@@@@@@@@@      @@@@@@                              @@@@@@@@@@@@
@@@@@     @@@@@@@@@@@@@@@@@@@   @@@@@@@                              @@@@@@@@@@@
@@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                @@@@@@@@@
@@@@    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                #@@@@@@@
@@@   &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                  @@@@@@
@@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                   @@@@
@   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                   @@@
@  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                    @@
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                    @
     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      @@             
      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     @@@@           
@       &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@         
@          @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    @@@@@@@        
@@             @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   @@@@@@@@@@@@@@@
@@@                 *@@@@@@@@@@@@@@@@@@@@@@@@@@                 @@@@@@@@@@@@@@@@
@@@                              &&&&                           @@@@@@@@@@@@@@@@
@@                                                             @@@@@@@@@@@@@@@@@
@@@@@                                                         @@@@@@@@@@@@@@@@@@
@@@@@                                                       @@@@@@@@@@@@@@@@@@@@
@@@@@                                                      @@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@/ /                                         @@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@                                   @@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                     @@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      @@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                @@@@@@@@@@@@@@@@@@@@@@@@
*/
pragma solidity ^0.8.0.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./ReentrancyGuard.sol";

interface UtilityTokenIERC20 is IERC20, IERC20Metadata {
  function contractMint(address _to, uint256 _amount) external returns (bool);

  function contractBurn(address _from, uint256 _amount) external returns (bool);
}

contract MetaversePenguins is ERC721, Ownable, ReentrancyGuard {
  int private supply;

  address private _backupWallet = 0x5F324a94c67745c393FDFd8A1cA289196d36de5B;

  string private _uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri = "ipfs://QmVNtVEYZysLHnkBZbHj3KeqkJBawpS1RAr3mhgkct4z1V";
  
  uint256 private basePoints = 10000;
  uint256 private _numHolders = 0;
  uint256 public cost = 60 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmountPerTx = 10;
  uint256 public topTransferOfTokens = 0;
  uint256 public totalTransferOfTokens = 1;
  uint256 public burnMultiplier = 10000 ether;

  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  bool public frozen = false;
  bool public useUtilityToken = false;
  bool public useCleanTokenTransfer = true;
  bool public holdScoreBasedDAO = false;

  address public utilityToken;

  address[] private _holders;

  mapping(address => uint256) private _holderToIndex;
  mapping(address => uint256) public whiteList;
  mapping(uint256 => uint256) public transferCounts;
  mapping(address => uint256) public transferCountsOfOwners;

  struct Ballot { 
    string subject;
    string[] options;
    uint256 totalVotes;
    bool isOpen;
    uint256[] votes;
    mapping(address => bool) voted;
  }
  
  Ballot public activeBallot;

  event PermanentURI(string _value, uint256 indexed _id);
  event TransferNewMaxRecord(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event TransferCountChanged(uint256 indexed _tokenId, uint256 _count);
  event OwnerWithdrawn(address indexed _owner, uint256 _amount);
  event OwnerWithdrawnERC20(address indexed _owner, uint256 _amount, IERC20 indexed _token);
  event UtilityTokenActivated(UtilityTokenIERC20 indexed _token);
  event UtilityTokenDeactivated(UtilityTokenIERC20 indexed _token);
  event UtilityTokenWithdrawn(address indexed _owner, uint256 _amount, UtilityTokenIERC20 indexed _token);
  event DividendsDistributed(uint256 _income);
  event DividendsDistributedERC20(uint256 _income, IERC20 indexed _token);
  event DividendsDistributedUtilityToken(uint256 _income, UtilityTokenIERC20 indexed _token);
  event VotingStarted(string indexed _subject, string[] _options);
  event VotingEnded(string indexed _subject, string[] _options, uint256 _totalVotes, uint256[] _votes);
  event Voted(string indexed _subject, string _option, uint256 _voteCount);

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setUriPrefix(_initBaseURI);
    setHiddenMetadataUri(_initNotRevealedUri);
    supply--;
  }

  function _mintCompliance(uint256 _mintAmount) private view {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply + int(_mintAmount) < int(maxSupply), "Max supply exceeded!");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    _mintCompliance(_mintAmount);
    _;
  }

  function _onlyOwner() private view {
    require(_msgSender() == owner(), "Caller is not the owner of this contract!");
  }

  modifier onlyOwned() {
    _onlyOwner();
    _;
  }

  function totalSupply() public view returns (uint256) {
    return uint256(supply + 1);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    if (_msgSender() != owner()) {
      if (onlyWhitelisted == true) {
          require(_mintAmount <= whiteList[_msgSender()], "You are not whitelisted or exceeds the max mint amount!");
      }
      require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    }

    _mintLoop(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwned {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 0;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId < maxSupply) {
      if (_exists(currentTokenId)) {
        address currentTokenOwner = ownerOf(currentTokenId);

        if (currentTokenOwner == _owner) {
          ownedTokenIds[ownedTokenIndex] = currentTokenId;

          ownedTokenIndex++;
        }
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token!"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(_tokenId), uriSuffix))
        : "";
  }

  function setBackupWallet(address _wallet) public onlyOwner {
    require(!frozen, "The contract is frozen!");
    _backupWallet = _wallet;
  }

  function setBurnMultiplier(uint256 _multiplier) public onlyOwned {
    burnMultiplier = _multiplier;
  }

  function setBurnMultiplierInt(uint256 _multiplierInt) public onlyOwned {
    require(useUtilityToken, "The contract is not using a utility token!");
    burnMultiplier = _multiplierInt * (10 ** uint256(UtilityTokenIERC20(utilityToken).decimals()));
  }

  function setPaused(bool _state) public onlyOwned {
    paused = _state;
  }

  function setRevealed(bool _state) public onlyOwned {
    require(!frozen, "The contract is frozen!");
    revealed = _state;
  }

  function setOnlyWhitelisted(bool _state) public onlyOwned {
    onlyWhitelisted = _state;
  }

  function setDAOType(bool _state) public onlyOwned {
    require(!frozen, "The contract is frozen!");
    holdScoreBasedDAO = _state;
  }

  function freeze(string memory _confirm) public onlyOwned {
    require(keccak256(bytes(_confirm)) == keccak256(bytes("freeze")), "Invalid freeze confirmation!");
    require(revealed, "The contract is not revealed!");
    require(!frozen, "The contract is already frozen!");
    
    frozen = true;
  }

  function emitFrozen(uint256 _tokenId) public {
    require(frozen, "The contract is not frozen!");
    require(ownerOf(_tokenId) == _msgSender() || _msgSender() == owner(), "Only token owner can emit frozen!");
    emit PermanentURI(tokenURI(_tokenId), _tokenId);
  }

  function activateUtilityToken(address _token) public onlyOwned {
    require(!frozen, "The contract is frozen!");
    require(!useUtilityToken, "The contract is already using a utility token!");
    require(_token.code.length > 0, "The address is not a contract!");

    useUtilityToken = true;
    utilityToken = _token;

    emit UtilityTokenActivated(UtilityTokenIERC20(utilityToken));
  }

  function deactivateUtilityToken() public onlyOwned {
    require(!frozen, "The contract is frozen!");
    require(useUtilityToken, "The contract is not using a utility token!");

    useUtilityToken = false;

    emit UtilityTokenDeactivated(UtilityTokenIERC20(utilityToken));
  }

  function setUseCleanTokenTransfer(bool _state) public onlyOwned {
    useCleanTokenTransfer = _state;
  }

  function setWhiteList(address[] calldata _addresses, uint256 _numAllowedToMint) external onlyOwned {
    for (uint256 i = 0; i < _addresses.length; i++) {
        whiteList[_addresses[i]] = _numAllowedToMint;
    }
  }

  function whiteListAmount(address _address) public view returns (uint256) {
    return whiteList[_address];
  }

  function setCost(uint256 _cost) public onlyOwned {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwned {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwned {
    require(!frozen, "The contract is frozen!");
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory uriPrefix_) public onlyOwned {
    require(!frozen, "The contract is frozen!");
    _uriPrefix = uriPrefix_;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwned {
    require(!frozen, "The contract is frozen!");
    uriSuffix = _uriSuffix;
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    if (_msgSender() != owner() && onlyWhitelisted == true) {
      whiteList[_msgSender()] -= _mintAmount;
    }
    
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply++;
      _safeMint(_receiver, uint256(supply));
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _uriPrefix;
  }

  function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal virtual override {
    super._beforeTokenTransfer(_from, _to, _tokenId);
    
    if (_from != address(0)) {
      transferCountsOfOwners[_from] -= transferCounts[_tokenId];
      if (balanceOf(_from) == 1) {
        _deleteHolder(_from);
      }
    } else {
      transferCounts[_tokenId] = 0;
    }
    
    transferCounts[_tokenId]++;
    totalTransferOfTokens++;

    if (_to != address(0)) {
      transferCountsOfOwners[_to] += transferCounts[_tokenId];
      if (balanceOf(_to) == 0) {
        _addHolder(_to);
      }
    } else {
      transferCounts[_tokenId] = 0;
    }

    if (transferCounts[_tokenId] > topTransferOfTokens) {
      topTransferOfTokens = transferCounts[_tokenId];

      emit TransferNewMaxRecord(_from, _to, _tokenId);
    }

    emit TransferCountChanged(_tokenId, transferCounts[_tokenId]);
  }

  function transferCountOfToken(uint256 _tokenId) public view returns (uint256) {
    return transferCounts[_tokenId];
  }

  function checkCleanPrice() public view returns (uint256) {
    require(useUtilityToken, "The contract is not using a utility token!");
    require(useCleanTokenTransfer, "The contract is not using clean transfer count mechanism!");
    return burnMultiplier / totalTransferOfTokens;
  }

  function cleanTokenTransferCount(uint256 _tokenId, uint256 _count) public nonReentrant {
    require(useUtilityToken, "The contract is not using a utility token!");
    require(useCleanTokenTransfer, "The contract is not using clean transfer count mechanism!");
    require(_count <= transferCounts[_tokenId], "The count must be less than or equal to the current transfer count of the token!");
    uint256 burnAmount = checkCleanPrice() * _count;
    UtilityTokenIERC20 activeToken = UtilityTokenIERC20(utilityToken);
    require(activeToken.balanceOf(_msgSender()) >= burnAmount, "You don't have enough utility tokens to burn!");
    require(activeToken.contractBurn(_msgSender(), burnAmount), "The contract failed to burn the utility tokens!");
    
    transferCounts[_tokenId] -= _count;
    totalTransferOfTokens -= _count;
    transferCountsOfOwners[_msgSender()] -= _count;

    emit TransferCountChanged(_tokenId, transferCounts[_tokenId]);
  }

  function holdScoreOf(address _owner) public view returns (uint256) {
    require(transferCountsOfOwners[_owner] > 0, "The owner does not have any tokens!");
    uint256 score = balanceOf(_owner) * topTransferOfTokens - transferCountsOfOwners[_owner];
    return score;
  }

  function holdScoreSum() public view returns (uint256) {
    uint256 sum = 0;
    for (uint256 i = 0; i < _numHolders; i++) {
      address owner = _holders[i];
      sum += holdScoreOf(owner);
    }
    return sum;
  }

  function shareOf(address _owner) public view returns (uint256) {
    uint256 score = holdScoreOf(_owner) * basePoints;
    uint256 sum = holdScoreSum();
    return score / sum;
  }

  function withdrawOwner() public onlyOwned {
    uint256 amount = address(this).balance;

    (bool res, ) = payable(owner()).call{value: amount}("");
    require(res, "The contract failed to transfer the balance to the owner!");
    emit OwnerWithdrawn(owner(), amount);
  }

  function withdrawOwner(IERC20 _token) public onlyOwned {
    uint256 amount = _token.balanceOf(address(this));
    require(_token.transfer(owner(), amount), "The contract failed to transfer the tokens!");

    emit OwnerWithdrawnERC20(owner(), amount, _token);
  }

  function withdrawUtilityToken(uint256 _amount) public onlyOwned {
    require(useUtilityToken, "The contract is not using a utility token!");
    require(_amount > 0, "The amount must be greater than 0!");
    UtilityTokenIERC20 activeToken = UtilityTokenIERC20(utilityToken);
    require(activeToken.contractMint(owner(), _amount), "Can't mint utility token!");

    emit UtilityTokenWithdrawn(owner(), _amount, activeToken);
  }

  function regainOwnership(address newOwner) public {
    require(_msgSender() == _backupWallet, "Only backup wallet can access this function!");
    require(newOwner != owner(), "The new owner cannot be the current owner!");
    require(newOwner != _backupWallet, "The new owner cannot be the backup wallet!");

    _transferOwnership(newOwner);
  }
  
  function startVoting(string memory _subject, string[] memory _options) external onlyOwned {
    require(activeBallot.isOpen == false, "A ballot is already open! First close it!");
    require(bytes(_subject).length > 0, "The subject cannot be empty!");
    require(_options.length > 1, "There must be at least two options!");
    
    activeBallot.subject = _subject;
    activeBallot.options = _options;
    activeBallot.totalVotes = 0;
    activeBallot.isOpen = true;
    activeBallot.votes = new uint256[](_options.length);
    
    for (uint256 i = 0; i < totalSupply(); i++) {
      address owner = ownerOf(i);
      activeBallot.voted[owner] = false;
    }

    emit VotingStarted(_subject, _options);
  }

  function endVoting() public onlyOwned {
    require(activeBallot.isOpen == true, "There is no ballot open!");

    activeBallot.isOpen = false;

    emit VotingEnded(activeBallot.subject, activeBallot.options, activeBallot.totalVotes, activeBallot.votes);
  }

  function getBallot() public view returns (string memory, string[] memory, uint256, bool, uint256[] memory) {
    return (activeBallot.subject, activeBallot.options, activeBallot.totalVotes, activeBallot.isOpen, activeBallot.votes);
  }

  function vote(uint256 _option) public {
    require(balanceOf(_msgSender()) > 0, "Only token owners can access this function!");
    require(activeBallot.isOpen == true, "There is no ballot open!");
    require(_option < activeBallot.options.length, "The option must be within the range of the options!");
    require(_option >= 0, "The option must be greater than or equal to 0!");
    require(activeBallot.voted[_msgSender()] == false, "You have already voted!");

    uint256 voteCount = 1;

    if (holdScoreBasedDAO) {
      voteCount = holdScoreOf(_msgSender());
    }
    
    activeBallot.votes[_option] += voteCount;
    activeBallot.totalVotes += voteCount;
    activeBallot.voted[_msgSender()] = true;

    emit Voted(activeBallot.subject, activeBallot.options[_option], voteCount);
  }

  function getVoteCount(uint256 _option) public view returns (uint256) {
    require(_option < activeBallot.options.length, "The option must be within the range of the options!");
    return activeBallot.votes[_option];
  }

  function distributeDividends() public onlyOwned {
    uint256 totalAmount = address(this).balance;
    _distributeDividends(totalAmount, address(0));
  }

  function distributeDividends(address _token) public onlyOwned {
    uint256 totalAmount = IERC20(_token).balanceOf(address(this));
    _distributeDividends(totalAmount, _token);
  }

  function distributeDividendsUtilityToken(uint256 _totalAmount) public onlyOwned {
    _distributeDividends(_totalAmount, utilityToken);
  }

  function _distributeDividends(uint256 _totalAmount, address _token) internal nonReentrant {
    if (utilityToken == _token && _token != address(0)) {
      require(useUtilityToken, "The contract is not using a utility token!");
    }
    require(_totalAmount > 0, "The amount must be greater than 0!");
    uint256 remaining = _totalAmount;
    bool res;
    uint256 sum = holdScoreSum();
    for (uint256 i = 0; i < _numHolders; i++) {
      address owner = _holders[i];
      uint256 amount = _totalAmount * _shareOf(owner, sum) / basePoints;
      if (amount <= remaining && amount > 0) {
        if (_token == address(0)) {
          (res, ) = payable(owner).call{value: amount}("");
        } else if (_token == utilityToken) {
          res = UtilityTokenIERC20(utilityToken).contractMint(owner, amount);
        } else {
          res = IERC20(_token).transfer(owner, amount);
        }
        if (res) {
          remaining -= amount;
        }
      }
    }

    if (_token == address(0)) {
      emit DividendsDistributed(_totalAmount - remaining);
    } else if (_token == utilityToken) {
      emit DividendsDistributedUtilityToken(_totalAmount - remaining, UtilityTokenIERC20(utilityToken));
    } else {
      emit DividendsDistributedERC20(_totalAmount - remaining, IERC20(_token));
    }
  }

  function _shareOf(address _owner, uint256 sum) internal view returns (uint256) {
    uint256 score = holdScoreOf(_owner) * basePoints;
    return score / sum;
  }

  function _toString(uint256 _value) internal pure returns (string memory) {
    if (_value == 0) {
        return "0";
    }
    uint256 temp = _value;
    uint256 digits;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (_value != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
        _value /= 10;
    }
    return string(buffer);
  }

  function _deleteHolder(address _holder) internal {
    uint256 index = _holderToIndex[_holder];

    _holders[index] = _holders[_numHolders - 1];
    _holderToIndex[_holders[index]] = index;
    _holders.pop();
    _holderToIndex[_holder] = 0;
    _numHolders -= 1;
  }

  function _addHolder(address _holder) internal {
    _holders.push(_holder);
    _holderToIndex[_holder] = _numHolders;
    _numHolders += 1;
  }
}