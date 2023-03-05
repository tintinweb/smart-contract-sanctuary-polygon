/**
 *Submitted for verification at polygonscan.com on 2023-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

// ERC20 token interface
interface IERC20 {
        
    // Total number of coins
    function totalSupply() external view returns (uint256);
    
    // Check the balance of the address
    function balanceOf(address account) external view returns (uint256);

    // Token transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    // Returns the remaining number of tokens available for transfer
    function allowance(address owner, address spender) external view returns (uint256);

    // Approve the amount to be transferred
    function approve(address spender, uint256 amount) external returns (bool);

    // Transfer of the approved amount
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Entry in the event log about the transfer of funds
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Recording in the event log about the allowed transfer amount
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Distribution contract
contract Distribution {

    // Structure of tokens
    struct Token {
        // Name of the token
        string symbol;
        // Token contract address
        address token;
        // Token interface
        IERC20 ERC20;
    }

    // Native network Token
    string nativeToken = "MATIC";

    // Affordable staking rates
    mapping (string => Token) public currentTarif;

    // Address of the owner by contract
    address public owner;

    // Event triggered by change of ownership contract
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // Event triggered when funds are transferred from a contract
    event Refund(
        uint256 indexed timeStamp,
        address indexed addres,
        uint256 indexed amount
    );

    // The modifier checks if the function caller is the owner of the contract
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    // Executed at contract initialization
    constructor() {
        // The owner of the contract is appointed
        owner = msg.sender;

        // Native network Token
        addStakingToken(
            nativeToken, // symbol: Name of the native Token
            0x0000000000000000000000000000000000000000 // token: The address field in the native token is not used
        );
    }

    // Change of ownership by contract
    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(_newOwner);
    }

    // Immediate change of ownership by contract
    function _setOwner(address _newOwner) private {
        address _oldOwner = owner;
        owner = _newOwner;

        // Recording to the event log about the change of the contract owner
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    // Compare strings
    function _compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // Add new staking token
    function addStakingToken(string memory _symbol, address _token) public onlyOwner {

        // Check if there is a Token
        require(!_compareStrings(currentTarif[_symbol].symbol, _symbol), "Token already added");

        // ERC20 standard token 
        IERC20 ERC20;
        // ERC20 token interface is connected
        ERC20 = IERC20(_token);

        // Creating a New Token Structure
        Token memory newToken = Token(
            _symbol,
            _token,
            ERC20
            );

        // Adding a new Token structure to the array
        currentTarif[_symbol] = newToken;
    }

    // Edit staking token
    function editStakingToken(string memory _symbol, address _token) public onlyOwner {

        // Check if there is a tariff
        require(_compareStrings(currentTarif[_symbol].symbol, _symbol), "Tariff does not exist");

        // ERC20 standard token 
        IERC20 ERC20;
        // ERC20 token interface is connected
        ERC20 = IERC20(_token);

        // Edit Token Structure
        Token memory newToken = Token(
            _symbol,
            _token,
            ERC20
            );

        // Edit Token structure to the array
        currentTarif[_symbol] = newToken;
    }

    // Checking the balance of native coins on the contract
    function getBalance(string memory _symbol) public view returns (uint256) {
        // Request for native token
        if(_compareStrings(_symbol, nativeToken)){
            return address(this).balance;
        } else {
            return currentTarif[_symbol].ERC20.balanceOf(address(this));
        }
    }

    // Transferring a native coins from a contract
    function refund(string memory _symbol, address _address, uint256 _amount) public onlyOwner {
        // Request for native token
        if(_compareStrings(_symbol, nativeToken)){
            payable(_address).transfer(_amount);
        } else {
            currentTarif[_symbol].ERC20.transfer(_address, _amount);
        }

        // Recording in the event log about the transfer from the contract
        emit Refund(block.timestamp, _address, _amount);
    }

    // Function allowing the acceptance of funds for the contract
    receive() external payable {}
}