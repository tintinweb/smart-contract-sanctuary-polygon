pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function balanceOf(address _owner) external view returns (uint256 balance);
}

contract TokenPayment {
    
    mapping (address => bool) public supportedTokens;
    
    event Payment(address indexed _from, address indexed _to, address indexed _token, uint256 _value);

    constructor() {
    }
    
    function addSupportedToken(address _tokenAddress) public {
        supportedTokens[_tokenAddress] = true;
    }

    function payWithToken(address _tokenAddress, address _to, uint256 _value) public {
        require(supportedTokens[_tokenAddress], "Token not supported.");
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(msg.sender) >= _value, "Insufficient balance.");
        require(token.transferFrom(msg.sender, _to, _value), "Transfer failed.");
        emit Payment(msg.sender, _to, _tokenAddress, _value);
    }
}