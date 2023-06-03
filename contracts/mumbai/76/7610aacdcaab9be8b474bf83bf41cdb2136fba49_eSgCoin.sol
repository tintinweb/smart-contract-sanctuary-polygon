/**
 *Submitted for verification at polygonscan.com on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// importing the Ownable contract to set the Ownership properties
contract Ownable {
    address public owner;

    // Emitted when Ownership of contract is transferred from `previousOwner` to `newOwner`.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// @title eSgCoin contract for Creating eSg token
contract eSgCoin is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    bool mintAllowed = true;
    uint256 public totalSupply;
    uint256 decimalfactor;
    uint256 public Max_Token;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // EVENTS
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    // Constructor
    constructor() {
        symbol = "eSgC";
        name = "eSg Coin";
        decimals = 18;
        decimalfactor = 10**uint256(decimals);
        Max_Token = 1_000_000_000 * decimalfactor;

        // Minting for Tokens for Sale 60%
        mint(
            0xd84C2637A1B63d9C483a7C3fd8a2B961C62A0E9F, 
            600_000_000 * decimalfactor
        ); // can be minted to the owner address & latar on transfered

        // Minting for Treasury  30%
        mint(
            0x0580046279B8FDB998457dCb3D91B70d3fb241dB, 
            300_000_000 * decimalfactor
        ); // can also be minted later on if required

        // Minting for Marketing 3%
        mint(
            0x64C5fBB09B4d5E1A09dE6Fcf6F94D916d4915A8B, 
            30_000_000 * decimalfactor
        );
        
        // Minting for Sponsors 2.75%
        mint(
            0x071153E3E1EDD704DFe1547d3Ff20c409c2f0668, 
            27_500_000 * decimalfactor
        );
        
        //Minting for Charitable 1%
        mint(
            0xDF47515F1bd1f5fF7bd761077f6575995F8d1e02,
            10_000_000 * decimalfactor
        );

        //Minting for Contributions 3.25%
        mint(
            0xc51d02CbbA99212233C7432A6c477aa77aDC7CB2, 
            32_500_000 * decimalfactor
        );
    }

    // Transfer is used to transfer '_value' number of tokens from '_from' address to '_to' address 
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    // Transfer '_value' number of tokens from '_from' address to '_to' address 
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    // TransferFrom is used to transfer '_value' number of tokens from '_from' address to '_to' address 
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Allowance error");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    // Approve is used to give access to '_spender' address to spend '_value' number of tokens
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    // Burn is used to destroy '_value' number of tokens 
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    // Mint '_value' number of tokens to '_to' address
    function mint(address _to, uint256 _value) public returns (bool success) {
        require(Max_Token >= (totalSupply + _value));
        require(mintAllowed, "Max supply reached");
        if (Max_Token == (totalSupply + _value)) {
            mintAllowed = false;
        }
        require(msg.sender == owner, "Only Owner Can Mint");
        balanceOf[_to] += _value;
        totalSupply += _value;
        require(balanceOf[_to] >= _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }
}