// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "./ERC1155.sol";
import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./CoolCats.sol";
import "./CloneX.sol";

contract CoolXVials is ERC1155, Ownable, PaymentSplitter {
    
  string public name;
  string public symbol;
  uint256 public maxSupply = 10000;
  uint256 public totalSupply = 0;
  uint256 public price = 0.1 ether;
  bool public paused = true;
  CoolCats public CC = CoolCats(0x1A92f7381B9F03921564a437210bB9396471050C);
  CloneX public CX = CloneX(0x49cF6f5d44E70224e2E23fDcdd2C053F30aDA28B);
  uint256 public whitelistTimestamp;
  uint256 public totalPublicWhitelistMints;
  uint256 public totalWhitelistMints;

  constructor(
    string memory _URI, 
    address[] memory _payees, 
    uint256[] memory _shares
    ) ERC1155("") PaymentSplitter(_payees, _shares) {
    name = "Cool X Vials";
    symbol = "CXV";
    _setURI(_URI);
  }

  function mint(address _to, uint256 _amount) public payable {
    require(totalSupply + _amount <= maxSupply && _amount > 0);
    require(balanceOf(_to, 1) + _amount <= 5);

    if(block.timestamp < whitelistTimestamp) {
        require((totalPublicWhitelistMints + _amount) < (maxSupply / 2));
        totalPublicWhitelistMints += _amount;
    }

    if(msg.sender != owner()) {
        require(!paused);
        require(msg.sender == _to);
        require(msg.value >= price * _amount);
    }

    _mint(_to, 1, _amount, "");
    totalSupply += _amount;
  }

  function mintWhitelist(address _to, uint256 _amount) public payable {
    require(!paused);
    require(CC.walletOfOwner(_to).length > 0 || CX.tokensOfOwner(_to).length > 0);
    require(block.timestamp < whitelistTimestamp);

    require((totalWhitelistMints + _amount) < (maxSupply / 2));
    require(totalSupply + _amount <= maxSupply && _amount > 0);
    require(balanceOf(_to, 1) + _amount <= 5);

    require(msg.sender == _to);
    require(msg.value >= price * _amount);
    
    _mint(_to, 1, _amount, "");
    totalWhitelistMints += _amount;
    totalSupply += _amount;
  }


  function burn(uint _amount) public {
    _burn(msg.sender, 1, _amount);
    totalSupply -= _amount;
  }

  function setURI(string memory _uri) external onlyOwner {
    _setURI(_uri);
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function setWhitelistTimestamp(uint256 _timestamp) public onlyOwner {
    whitelistTimestamp = _timestamp;
  }
}