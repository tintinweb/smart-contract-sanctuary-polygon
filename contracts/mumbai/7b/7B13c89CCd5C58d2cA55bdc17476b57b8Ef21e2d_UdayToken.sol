// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract UdayToken {
    address public owner;

    string public symbol;
    string public name;
    uint256 public totalSupply = 0;
    uint256 public UINT_MAX = 2**256 - 1;

    mapping(address => mapping(address => bool)) public delegates;
    mapping(address => uint256) public balances;

    constructor(
        string memory _symbol,
        string memory _name,
        uint256 _totalSupply
    ) checkOverflow(_totalSupply) {
        owner = msg.sender;
        symbol = _symbol;
        name = _name;
        totalSupply += _totalSupply;
        balances[msg.sender] = _totalSupply;
    }

    // ==================
    // Function Modifiers
    // ==================

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function!");
        _;
    }

    modifier checkOverflow(uint256 _amount) {
        require(_amount <= UINT_MAX - totalSupply, "uint256 overflow!");
        _;
    }

    modifier checkBalance(address _of, uint256 _amount) {
        require(balances[_of] >= _amount, "Insufficient balance!");
        _;
    }

    modifier checkAddress(address _adr) {
        require(
            _adr != address(0),
            "Transfer to address(0) can only be done through burn function!"
        );
        _;
    }

    modifier checkAddresses(address _from, address _to) {
        require(
            _from != address(0),
            "Transfer to address(0) can only be done through burn function!"
        );
        require(
            _to != address(0),
            "Transfer to address(0) can only be done through burn function!"
        );
        _;
    }

    modifier checkDelegationRights(address _of, address _is) {
        require(
            delegates[_of][_is] == true,
            "You don't have delegation rights!"
        );
        _;
    }

    // ==================
    // Function Modifiers
    // ==================

    // ==================
    // Contract Functions
    // ==================

    /**
     * @dev Issue tokens -- Can only be called by the owner
     * @param _amount -- Number of tokens to be issued
     */
    function issue(uint256 _amount)
        public
        onlyOwner
        checkOverflow(_amount)
        returns (bool)
    {
        totalSupply += _amount;
        balances[msg.sender] += _amount;
        return true;
    }

    /**
     * @dev Burn tokens -- Tokens are sent to 0x0
     * @param _amount -- Number of tokens to be burned
     */
    function burn(uint256 _amount)
        public
        checkBalance(msg.sender, _amount)
        returns (bool)
    {
        totalSupply -= _amount;
        internalTransfer(msg.sender, address(0), _amount);
        return true;
    }

    /**
     * @dev Check balance of calling account
     */
    function myBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    /**
     * @dev Transfer tokens from caller to another address -- Sender is the caller; Receiver needs to be passed by the caller
     * @param _to -- Receiver address
     * @param _amount -- Number of tokens to be sent
     */
    function transfer(address _to, uint256 _amount)
        public
        checkAddress(msg.sender)
        checkBalance(msg.sender, _amount)
        returns (bool)
    {
        internalTransfer(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another -- Sender is the delegate; Receiver needs to be passed by the caller
     * @param _from -- Delegated address
     * @param _to -- Receiver address
     * @param _amount -- Number of tokens to be sent
     */
    function delegateTransfer(
        address _from,
        address _to,
        uint256 _amount
    )
        public
        checkDelegationRights(_from, msg.sender)
        checkAddresses(_from, _to)
        checkBalance(_from, _amount)
        returns (bool)
    {
        internalTransfer(_from, _to, _amount);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another -- Private function
     * @param _from -- Sender address
     * @param _to -- Receiver address
     * @param _amount -- Number of tokens to be sent
     */
    function internalTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) private {
        balances[_from] -= _amount;
        balances[_to] += _amount;
    }

    /**
     * @dev Grant delegation rights to an address
     * @param _to -- Address that will be given rights
     */
    function grantDelegationRights(address _to) public returns (bool) {
        delegates[msg.sender][_to] = true;
        return true;
    }

    /**
     * @dev Revoke delegation rights to an address
     * @param _to -- Address whose rights will be revoked
     */
    function revokeDelegationRights(address _to) public returns (bool) {
        delegates[msg.sender][_to] = false;
        return true;
    }

    // ==================
    // Contract Functions
    // ==================
}