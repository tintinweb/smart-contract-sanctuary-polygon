/**
 *Submitted for verification at polygonscan.com on 2022-12-12
*/

// SPDX-License-Identifier: MIT 
pragma solidity >=0.4.21 <0.9.0; 

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}


contract Poster { 
    address public owner;

    string content;
    string tag;

    address public tokenAddress;
    uint256 public threshold;

    constructor(address _tokenAddress, uint256 _threshold) {
        tokenAddress = _tokenAddress;
        threshold = _threshold * 10**10;

        owner = msg.sender;
        emit OwnershipTransferred(address(0x0), owner);

    }

    modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address _newOwner) public virtual onlyOwner {
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
    function setTokenAddress(address _newTokenAddress) public virtual onlyOwner {
        address previousAddress = tokenAddress;
        tokenAddress = _newTokenAddress;
        emit TokenAddressSet(previousAddress, _newTokenAddress);
    }
    function setTreshold(uint256 _newTreshold) public virtual onlyOwner {
        uint256 oldTreshold = threshold;
        threshold = _newTreshold * 10**10;
        emit TresholdSet(oldTreshold, _newTreshold);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokenAddressSet(address indexed previousAddress, address indexed newAddress);
    event TresholdSet(uint256 indexed previousTreshold, uint256 indexed newTreshold);
    event NewPost(address indexed user, string _content, string indexed _tag); 

    function post(string memory _content, string memory _tag) public {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(msg.sender);
        if (balance < threshold) revert("Not enough tokens");
        // if (balance > threshold) token.transferFrom(msg.sender, tokenAddress, threshold);
        
        
        content = _content;
        tag = _tag;

        emit NewPost(msg.sender, content, tag);
    }
    function getContent() public view returns(string memory) {
        return content;
    }
    function getTag() public view returns(string memory) {
        return tag;
    } 
}