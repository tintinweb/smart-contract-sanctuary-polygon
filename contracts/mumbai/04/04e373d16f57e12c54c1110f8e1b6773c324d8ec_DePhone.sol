/**
 *Submitted for verification at polygonscan.com on 2023-02-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface DePhoneInterface {
    
    /**
     * @notice Get the owner of the `phoneNumber`
     * @param phoneNumber The hash phoneNumber of the owner to query
     * @return The wallet address owned by `owner`
     */
    function getOwnerOfPhoneNumber(string calldata phoneNumber) external view returns (address);

    /**
     * @notice Check if the wallet is claimed a phone number with authorization
     * @param wallet The Wallet address of the user
     */
    function isWalletClaimed(address wallet) external view returns (bool);

}

contract DePhone is DePhoneInterface {

    address public admin;
    address public pendingAdmin;

    /**
     * @notice Official mapping of hash phoneNumber -> wallet address
     */
    mapping(string => address) private dePhones;

    mapping(address => bool) private connectedWallets;

    event PhoneNumberAuthorized(
        address indexed owner,
        string phoneNumber
    );

    /**
     * @notice Construct a new DePhone
     */
    constructor() {
        admin = msg.sender;
    }

    /**
     * @notice Admin Authroize the hash(Phone number) with the wallet address
     * @param wallet The Wallet address the user
     * @param phoneNumber The hash phoneNumber of the user
     */
    function authorizePhoneNumber(address wallet, string calldata phoneNumber) external onlyAdmin { 
        require (dePhones[phoneNumber] == address(0), "DePhone: Phone number is already mapped with a wallet");
        // require (claimPhones[claimId] == address(0), "DePhone: Claim is already mapped with a wallet");

        dePhones[phoneNumber] = wallet;
        // claimPhones[claimId] = wallet;
        connectedWallets[wallet] = true;

        emit PhoneNumberAuthorized(wallet, phoneNumber);
    }
    
    /**
     * @notice Get the owner of the `phoneNumber`
     * @param phoneNumber The hash phoneNumber of the user to query
     * @return The wallet address owned by `owner`
     */
    function getOwnerOfPhoneNumber(string calldata phoneNumber) public override view returns (address) {
        return dePhones[phoneNumber];
    }

    /**
     * @notice Check if the wallet is claimed a phone number with authorization
     * @param wallet The Wallet address of the user
     */
    function isWalletClaimed(address wallet) public override view returns (bool) {
        return connectedWallets[wallet];
    }

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function _setPendingAdmin(address payable newPendingAdmin) external onlyAdmin {

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function _acceptAdmin() external {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin);
        require(msg.sender != address(0));

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
}