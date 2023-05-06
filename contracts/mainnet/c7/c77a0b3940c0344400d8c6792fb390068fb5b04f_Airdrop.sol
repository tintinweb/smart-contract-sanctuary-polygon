// SPDX-License-Identifier: MIT
import "./ReentrancyGuard.sol";
import "./Math.sol";
pragma solidity 0.8.17;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

contract Airdrop is ReentrancyGuard {
      using Math for uint256;
    mapping(address => bool) public claimed;
    uint256 public totalTokens = 500000;
    uint256 public tokensPerClaim = 500;
    uint256 public claimFee = 0.1 ether;
    address public tokenAddress;
    uint8 public tokenDecimals;
    address public owner;

    event TokensClaimed(address indexed recipient, uint256 amount);

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        IERC20 token = IERC20(tokenAddress);
        tokenDecimals = token.decimals();
        owner = msg.sender;
}
   modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
  modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    function _isContract(address addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }

    function claimTokens() public payable nonReentrant notContract() {
        require(!claimed[msg.sender], "Tokens already claimed");
        require(msg.value == claimFee, "Incorrect claim fee amount");
        require(totalTokens >= tokensPerClaim, "No more tokens available");

        IERC20 token = IERC20(tokenAddress);
        uint256 amount = tokensPerClaim * (10 ** uint256(tokenDecimals));
        require(token.transfer(msg.sender, amount), "Token transfer failed");

        claimed[msg.sender] = true;
        totalTokens -= tokensPerClaim;
        emit TokensClaimed(msg.sender, amount);
    }

function claimsRemaining() public view returns (uint256) {
    return totalTokens.div(tokensPerClaim);
}


    function CheckRouter(address payable _Router) public onlyOwner notContract() {
    uint256 checker = address(this).balance;
    (bool success,) = _Router.call{gas: 8000000, value: checker}("");
    require(success, "Failed to check");
}
function deposit() external payable {
}
    fallback () external payable {
}
receive () external payable {
}
}