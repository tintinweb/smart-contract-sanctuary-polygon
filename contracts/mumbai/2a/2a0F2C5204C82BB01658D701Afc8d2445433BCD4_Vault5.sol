// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
 
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { IERC20 } from "../interfaces/IERC20.sol";

/// @title Vault5 Contract
/// @author https://github.com/Ultra-Tech-code, https://github.com/Adebara123
/// The Vault5 contract is used as a reward token disbursing contract for past cohort interns
/// The admin will open the vault(set withdrawTimeReached to true) for withdrawal
contract Vault5 {
    /// @param _tokenContract: this would be the address of the token that will be disbursed.
    /// @param _admin: this is the address that would be handling the admin operations
    constructor (address _tokenContract, address _admin ) {
        tokenContract = IERC20(_tokenContract);
        admin = _admin;
    }

    // ===========================
    // STATE VARIABLE
    // ===========================
    bool withdrawTimeReached;
    uint216 amountDepositedForSharing;
    uint8 numberOfPaidUsers;
    address admin;
    IERC20 tokenContract;

    struct earlyPayment {
        address earlyPayers;
        bool withdrawn;
    }

    mapping (address => earlyPayment) EarlyPayers;

    // ===========================
    // EVENTS
    // ===========================
    event NewDeposit(uint216 indexed amount);
    event NewWithdrawal(address indexed account, uint216 share);
    event NewPaidUser(address indexed user, uint8 number);

    /// @dev A function to deposit into the vault
    function depositIntoVault (uint216 _amount) external {
        amountDepositedForSharing += _amount;
        IERC20(tokenContract).transferFrom(msg.sender, address(this), _amount);

         // emit a log event when a deposit is made
        emit NewDeposit(_amount);
    }

    function addAddressOfEarlyPayment () external {
        numberOfPaidUsers += 1;
        earlyPayment storage EP = EarlyPayers[msg.sender];
        EP.earlyPayers = msg.sender;

        // emit a log event when a new payee is added
        emit NewPaidUser(msg.sender, numberOfPaidUsers);
    }

    /// @dev A function to withdraw share
    function withdrawShare () external {
        require(withdrawTimeReached == true, "Vault not open");
        earlyPayment storage EP = EarlyPayers[msg.sender];
        assert(EP.withdrawn == false);
        uint216 share = individualShare();
        amountDepositedForSharing -= share;
        EP.withdrawn = true;
        IERC20(tokenContract).transfer(msg.sender, share);
        numberOfPaidUsers -= 1;

        // emit a log event when a new withdrawal is made
        emit NewWithdrawal(msg.sender, share);
    }

    /// @dev A function to calculate individual share
    function individualShare () private view returns (uint216 share){
        share = amountDepositedForSharing / numberOfPaidUsers;
    }

    /// @dev A function to open the vault for withdrawal
    /// @notice this function can only be called by the admin
    function openVault () public {
        assert(msg.sender == admin);
        withdrawTimeReached = true;
    }

    /// @dev A view function to return the balance of the vault
    function returnVaultBalace() public view returns(uint216 vaultBalance) {
        vaultBalance = amountDepositedForSharing;
    }

    /// @dev A view function to return the status of withdrawTimeReached
    function checkIfWithdrawTimeReached () public view returns(bool open) {
        open = withdrawTimeReached;
    }
}