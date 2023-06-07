// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/Ownable.sol";

      
contract TOKEN is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 decimalfactor;
    uint256 public Max_Token;
    bool mintAllowed;
    bool isInitalized;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function initialize(
        string memory SYMBOL,
        string memory NAME,
        uint8 DECIMALS
    ) external {
        _setOwner(msg.sender);
        require(!isInitalized, "Already initalized");
        symbol = SYMBOL;
        name = NAME;
        decimals = DECIMALS;
        decimalfactor = 10 ** uint256(decimals);
        Max_Token = 1000000000000000000000000000 * decimalfactor;
        isInitalized = true;
        mintAllowed=true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(
            balanceOf[_from] >= _value,
            "ERC20: 'from' address balance is low"
        );
        require(
            balanceOf[_to] + _value >= balanceOf[_to],
            "ERC20: Value is negative"
        );

        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(
        address _to,
        uint256 _value
    ) public virtual returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual returns (bool success) {
        require(
            _value <= allowance[_from][msg.sender],
            "ERC20: Allowance error"
        );
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(
        address spender,
        uint256 value
    ) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function burn(uint256 _value) public {
        require(
            balanceOf[msg.sender] >= _value,
            "ERC20: Transfer amount exceeds user balance"
        );

        balanceOf[msg.sender] -= _value;

        totalSupply -= _value;
        mintAllowed = true;
        emit Transfer(msg.sender, address(0), _value);
    }

    function mint(address to, uint256 value) public {
        require(
            Max_Token >= (totalSupply + value),
            "ERC20: Max Token limit exceeds"
        );
        require(mintAllowed, "ERC20: Max supply reached");

        if (Max_Token == (totalSupply + value)) {
            mintAllowed = false;
        }

        require(msg.sender == owner, "ERC20: Only Owner Can Mint");

        balanceOf[to] += value;
        totalSupply += value;

        require(
            balanceOf[to] >= value,
            "ERC20: Transfer amount cannot be negative"
        );

        emit Transfer(address(0), to, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
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

    function _setOwner(address newOwner) internal {
        owner = newOwner;
    }
}