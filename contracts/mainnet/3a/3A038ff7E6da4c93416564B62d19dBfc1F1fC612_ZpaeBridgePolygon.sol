/**
 *Submitted for verification at polygonscan.com on 2022-04-21
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT LICENSE
// developed by tokenstation.dev


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Owned is Context {
    address private _contractOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() { 
        _contractOwner = payable(_msgSender()); 
    }

    function owner() public view virtual returns(address) {
        return _contractOwner;
    }

    function _transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Owned: Address can not be 0x0");
        __transferOwnership(newOwner);
    }


    function _renounceOwnership() external virtual onlyOwner {
        __transferOwnership(address(0));
    }

    function __transferOwnership(address _to) internal {
        emit OwnershipTransferred(owner(), _to);
        _contractOwner = _to;
    }


    modifier onlyOwner() {
        require(_msgSender() == _contractOwner, "Owned: Only owner can operate");
        _;
    }
}



contract Accessable is Owned {
    mapping(address => bool) private _admins;
    mapping(address => bool) private _tokenClaimers;

    constructor() {
        _admins[_msgSender()] = true;
        _tokenClaimers[_msgSender()] = true;
    }

    function isAdmin(address user) public view returns(bool) {
        return _admins[user];
    }

    function isTokenClaimer(address user) public view returns(bool) {
        return _tokenClaimers[user];
    }


    function _setAdmin(address _user, bool _isAdmin) external onlyOwner {
        _admins[_user] = _isAdmin;
        require( _admins[owner()], "Accessable: Contract owner must be an admin" );
    }

    function _setTokenClaimer(address _user, bool _isTokenCalimer) external onlyOwner {
        _tokenClaimers[_user] = _isTokenCalimer;
        require( _tokenClaimers[owner()], "Accessable: Contract owner must be an token claimer" );
    }


    modifier onlyAdmin() {
        require(_admins[_msgSender()], "Accessable: Only admin can operate");
        _;
    }

    modifier onlyTokenClaimer() {
        require(_tokenClaimers[_msgSender()], "Accessable: Only Token Claimer can operate");
        _;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IERC20Burnable is IERC20 {
    function burn(uint256 value) external;
}





contract ZpaeBridgePolygon is Accessable {

    IERC20Burnable  public tokenOld = IERC20Burnable(address(0));
    IERC20  public token = IERC20(address(0));
    bool    public isEnabled = false;

    uint256 public totalSwapped = 0;


    event TokenSwapped(uint256 _amount, address indexed _tokenAddress, address indexed _targetAddress);


    constructor() {}



    function _setTokenAddress(address _tokenAddress, address _oldTokenAddress) external onlyAdmin {
        token = IERC20(_tokenAddress);
        if (_tokenAddress == address(0)) {
            isEnabled = false;
        }

        tokenOld = IERC20Burnable(_oldTokenAddress);
    }

    function swapToken(uint256 amount) external
        enabled
    {
        tokenOld.transferFrom(_msgSender(), address(this), amount);
        // tokenOld.burn(amount);
        uint256 newAmount = amount * 1e9;

        totalSwapped += newAmount;
        token.transfer(_msgSender(), newAmount);
        emit TokenSwapped(newAmount, address(token), _msgSender());
    }

    function _setIsEnabled(bool _newIsEnabled) external onlyAdmin {
        require(address(token) != address(0), 'Token address is equal to zero');
        isEnabled = _newIsEnabled;
    }

    function _sendToken(address user, uint256 amount) external onlyAdmin enabled {
        totalSwapped += amount;
        token.transfer(user, amount);
        emit TokenSwapped(amount, address(token), user);
    }

    function _withdrawToken(address recipient, uint256 amount) external onlyAdmin {
        token.transfer(recipient, amount);
    }


    modifier enabled() {
        require(isEnabled, "Not enabled");
        _;
    }


    function _withdraw() external onlyTokenClaimer {
        payable(_msgSender()).transfer(address(this).balance);
    }
}