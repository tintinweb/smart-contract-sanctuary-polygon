pragma solidity ^0.4.24;

/**
 * @title Token
 * @dev Simpler version of ERC20 interface
 */
contract Token {
    function balanceOf(address owner) public returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract LPMirror is Ownable {
    // This declares a state variable that would store the contract address
    Token public tokenInstance;
    uint256 public updateCount = 0;

    /*
      constructor function to set token address
     */
    constructor(address _tokenAddress) public {
        tokenInstance = Token(_tokenAddress);
    }

    // force reserves to match balances
    function sync() external {
        updateCount +1;
    }

    function rescueToken(uint256 tokens)
    external
    onlyOwner
    returns (bool success)
    {
        return tokenInstance.transfer(msg.sender, tokens);
    }
}