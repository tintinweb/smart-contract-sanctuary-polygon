/**
 *Submitted for verification at polygonscan.com on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IERC20 {
    function totalSupply() external view returns(uint256);

    function balanceOf(address account) external view returns(uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns(bool);

    function allowance(address owner, address spender)
    external
    view
    returns(uint256);

    function approve(address spender, uint256 amount) external returns(bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns(bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    function burnFrom(address user, uint256 amount) external;
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
	
	function mint(address value, uint256 mintAmount) external;
    function totalSupply() external view returns (uint256);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract AvatarLogic is Ownable {

	address public avatarBase = 0xBb45f950fc8Ed38b92b5D673b7f459958d8be7Dc;
    address public whitelistTicket = 0x22a705F0bC98E17321F0D07a6B4a37e4bD9e19D6;
    uint256 public cap = 4000;
	uint256 public avatarPrice = 125 ether;
    uint256 public whitelistPrice = 100 ether;
    uint256 public reserved = 321;
    uint256 public reservedMinted = 0;
    uint256 public pauseGate = 1;
	

    function buyAvatar(uint256 _mintAmount) public payable {
	IERC721 ab = IERC721(avatarBase);
    require(ab.totalSupply() + 1 <= cap);
    require(pauseGate == 1);
    require(_mintAmount > 0);
    require(msg.value >= avatarPrice * _mintAmount);
    ab.mint(msg.sender, _mintAmount);
  }

	function adminMint(address account, uint256 amount) external onlyOwner {
	IERC721 ab = IERC721(avatarBase);
    require(reservedMinted <= reserved);
	ab.mint(account,amount);
    reservedMinted++;
  }
    function whiteListMint(uint256 amount) external payable {
    IERC721 ab = IERC721(avatarBase);
    IERC20 wt = IERC20(whitelistTicket);
    require(amount <= 20);
    require(ab.totalSupply() + 1 <= cap);
    wt.burnFrom(msg.sender,amount);
    ab.mint(msg.sender,amount);
  }
	function setAvatar(address avContract) external onlyOwner {
	avatarBase = avContract;
  }
	function setPrice(uint256 price) external onlyOwner {
	avatarPrice = price;
  }
    function setWlPrice(uint256 price) external onlyOwner {
    whitelistPrice = price;
  }
    function setWlTokenAddr(address wltoken) external onlyOwner {
    whitelistTicket = wltoken;
  }
    function setCap(uint256 newCap) external onlyOwner {
    cap = newCap;
  }
    function setReserved(uint256 newValue) external onlyOwner {
    reserved = newValue;
  }
    function withdrawFTM(uint256 amount) onlyOwner public {
    payable(owner()).transfer(amount);
  }
}