/**
 *Submitted for verification at polygonscan.com on 2022-11-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

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

interface ICarNftV1 {
  function MintFor(address account) external returns (bool);
}
abstract contract Ownable {
    address internal owner;
    constructor(address _owner) { owner = _owner; }
    modifier onlyOwner() { require(isOwner(msg.sender), "!OWNER"); _; }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract DepositVaultPool is Ownable {
  using SafeMath for uint256;

  address public depositToken;
  address public poolcontract;

  mapping(address => uint256) public mintingprice;

  constructor() Ownable(msg.sender) {
    depositToken = 0x877FF53c00Fa7AA0e0c65eB3953CBd8F56cf22E2;
    poolcontract = address(this);
  }

  function deposit(uint256 amount) external returns (bool) {
    IBEP20 a = IBEP20(depositToken);
    a.transferFrom(msg.sender,poolcontract,amount);
    return true;
  }

  function MintNft(address nftcontract,address account) external returns (bool) {
    require(mintingprice[nftcontract]>0,"ERROR: MINTING PRICE CANNOT BE ZERO");
    IBEP20 a = IBEP20(depositToken);
    ICarNftV1 b = ICarNftV1(nftcontract);
    a.transferFrom(msg.sender,poolcontract,mintingprice[nftcontract]);
    b.MintFor(account);
    return true;
  }

  function setMintPrice(address nftcontract,uint256 price) external onlyOwner returns (bool) {
    mintingprice[nftcontract] = price;
    return true;
  }
}