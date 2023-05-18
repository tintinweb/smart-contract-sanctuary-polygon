/**
 *Submitted for verification at polygonscan.com on 2023-05-17
*/

// SPDX-License-Identifier: UNLICENSED
/*
*/
pragma solidity >=0.7.0 <0.9.0;

contract TokenContract {
    uint256 constant TOTAL_SUPPLY = 11111111111 * 10**9;
    uint8 m_Decimals = 9;
    string m_Name = "stonks";
    string m_Symbol = "stonks";
    bool m_Launched = false;
    address m_Owner = 0xF4c9DD03C74798daC0Ff81A8C243828dBCDe04f9;
    address m_MarketingWallet = 0x93f866E5AAEc2bC3313ba797357aD56418b62ca8;
    address m_ExchangeListingWallet = 0x04cbF1f060D97a879745dCBaA530303c6e685FdC;
    address m_UniswapPair;
    mapping (address => uint256) m_Balances;
    mapping (address => bool) m_WhiteListed; // Whitelisted address exist for the sole purpoe of exceeding wallet cap (eg: Uniswap Pair)
    mapping (address => mapping (address => uint256)) m_Allowances;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        m_WhiteListed[m_MarketingWallet] = true;
        m_WhiteListed[m_ExchangeListingWallet] = true;
        m_Balances[m_Owner] = TOTAL_SUPPLY - (TOTAL_SUPPLY/10); //90%
        m_Balances[m_MarketingWallet] = TOTAL_SUPPLY/20; //5%
        m_Balances[m_ExchangeListingWallet] = TOTAL_SUPPLY/20; //5%
        emit OwnershipTransferred(address(0), m_Owner);
        emit Transfer(address(0), m_Owner, TOTAL_SUPPLY - (TOTAL_SUPPLY/10));
        emit Transfer(address(0), m_MarketingWallet, TOTAL_SUPPLY/20);
        emit Transfer(address(0), m_ExchangeListingWallet, TOTAL_SUPPLY/20);
    }
    function owner() public view returns (address) {
        return m_Owner;
    }
    function name() public view returns (string memory) {
        return m_Name;
    }
    function symbol() public view returns (string memory) {
        return m_Symbol;
    }
    function decimals() public view returns (uint8) {
        return m_Decimals;
    }
    function totalSupply() public pure returns (uint256) {
        return TOTAL_SUPPLY;
    }
    function balanceOf(address _account) public view returns (uint256) {
        return m_Balances[_account];
    }
    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return m_Allowances[_owner][_spender];
    }
    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }
    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
        require(m_Allowances[_sender][msg.sender] >= _amount);
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, m_Allowances[_sender][msg.sender] - _amount);
        return true;
    }
    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        m_Allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");
        if(_amount + m_Balances[_recipient] > TOTAL_SUPPLY / 50) //2% Max wallet
            require(m_WhiteListed[_recipient], "Wallet cap would be exceeded");
        if(_sender != m_Owner) 
            require(m_Launched, "Trading not yet opened");

        // Safemath is obsolete as of 0.8
        m_Balances[_sender] -= _amount;
        m_Balances[_recipient] += _amount;
        emit Transfer(_sender, _recipient, _amount);
	}
    function whitelistExchange(address _address) external {
        require(msg.sender == m_Owner);
        m_WhiteListed[_address] = true;        
    }
    function renounceOwnership() external {
        require(msg.sender == m_Owner);
        m_Launched = true;
        m_Owner = address(0);
        emit OwnershipTransferred(msg.sender, address(0));
    }
}