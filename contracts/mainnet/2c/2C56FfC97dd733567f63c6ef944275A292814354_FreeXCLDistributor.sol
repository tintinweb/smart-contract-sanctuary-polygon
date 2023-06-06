/**
 *Submitted for verification at polygonscan.com on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

abstract contract ReentrancyGuard {
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
       
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        
        _status = _NOT_ENTERED;
    }

    
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}


contract FreeXCLDistributor is Ownable, ReentrancyGuard {
    IERC20 public token;
    mapping (address => bool) public hasClaimed; // keep track of who has claimed tokens
    uint256 public tokensPerClaim = 1000000; // set limit of tokens per claim

    constructor(IERC20 _token) {
        token = _token; 
    }

    function claimTokens() public nonReentrant {
        require(!hasClaimed[msg.sender], "You have already claimed your tokens");
        require(token.balanceOf(address(this)) >= tokensPerClaim, "Not enough tokens left to claim");

        hasClaimed[msg.sender] = true;
        token.transfer(msg.sender, tokensPerClaim);
    }

    function addTokens(uint256 _amount) public onlyOwner {
        require(token.balanceOf(msg.sender) >= _amount, "Not enough tokens in owner balance");
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function setTokensPerClaim(uint256 _amount) public onlyOwner {
        tokensPerClaim = _amount;
    }
}