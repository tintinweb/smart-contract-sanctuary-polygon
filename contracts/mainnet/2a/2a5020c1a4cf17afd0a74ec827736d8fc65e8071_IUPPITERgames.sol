// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

contract IUPPITERgames is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping (address => bool) public Lockable;
    mapping (address => uint256) public LockAmount;
    mapping (address => uint256) public LockTime;
    uint256 public LockTotal = 0;

    function LockTransfer(address _to, uint256 _amount, uint256 _time) public {
        require(hasRole(MINTER_ROLE, msg.sender), "IUPPITERgames: must have minter role to lock transfer");
        require(Lockable[_to] != true, "Lockable is false");
        require(_time > 0, "Lock time must be greater than current time");
        require(_amount <= balanceOf(msg.sender), "IUPPITERgames ERC20: transfer amount exceeds balance");

        Lockable[_to] = true;
        LockAmount[_to] = _amount;
        LockTime[_to] = _time + block.timestamp;
        LockTotal = LockTotal + _amount;

        _transfer(msg.sender, _to, _amount);
    }

    function Unlock() public {
        require(Lockable[msg.sender] == true, "Lockable is false");
        require(LockTime[msg.sender] < block.timestamp, "Lock time must be less than current time");
        uint256 amount = LockAmount[msg.sender];
        
        Lockable[msg.sender] = false;
        LockAmount[msg.sender] = 0;
        LockTime[msg.sender] = 0;
        LockTotal = LockTotal - amount;

        _transfer(address(this), msg.sender, amount);
    }

    function LockableOF(address _to) public view returns (bool) {
        return Lockable[_to];
    }

    function LockBalanceOf(address _owner) public view returns (uint256) {
        return LockAmount[_owner];
    }
    
    function LockTimeOf(address _to) public view returns (uint256) {
        return LockTime[_to];
    }

    function LockTotalAmount() public view returns (uint256) {
        return LockTotal;
    }

    constructor() ERC20("IUPPITERgames", "IUPX") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _mint(msg.sender, 1000000000 * 10**decimals());
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override whenNotPaused returns (bool) {
         require(!Lockable[msg.sender] || (Lockable[msg.sender] && block.timestamp >= LockTime[msg.sender] && LockAmount[msg.sender] == 0), "IUPPITERgames ERC20: tokens are locked");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override whenNotPaused returns (bool) {
        require(!Lockable[sender] || (Lockable[sender] && block.timestamp >= LockTime[sender] && LockAmount[sender] == 0), "IUPPITERgames ERC20: tokens are locked");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender, _msgSender()) - amount);
        return true;
    }

    function airdrop(address[] memory recipients, uint256[] memory amounts) public onlyRole(MINTER_ROLE) {
        require(recipients.length == amounts.length, "IUPPITERgames : recipients and amounts arrays must have the same length");

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            uint256 amount = amounts[i];
        
            // Ensure that the sender has enough balance to cover the airdrop
            require(balanceOf(msg.sender) >= amount, "IUPPITERgames ERC20: transfer amount exceeds balance");
        
            // Transfer tokens to the recipient
            _transfer(msg.sender, recipient, amount);
        }
    }
}