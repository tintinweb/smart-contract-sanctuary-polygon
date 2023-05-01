/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title HawkInheritance
/// @author xdream.eth
/// @notice A smart contract for managing inheritance distribution of stablecoins.
contract LegacyKeeper {

    mapping(address => inheritance[]) public userToBeneficiaries;
    mapping(address => uint256) public userToNumOfBeneficiaries;

    /// @dev The inheritance struct stores details about the inheritance for a specific beneficiary.
    struct inheritance {
        string name;
        address beneficiary;
        uint256 amount;
        uint256 time;
    }

    IERC20 stablecoin;

    /// @notice Constructor initializes the HawkInheritance contract and sets the stablecoin.
    /// @param _stablecoinAddr The address of the deployed stablecoin token.
    constructor(address _stablecoinAddr) {
        stablecoin = IERC20(_stablecoinAddr);
    }

    /// @notice Adds a new beneficiary for the sender’s inheritance.
    /// @dev Transfers the token amount from sender to contract address and updates the inheritance struct.
    /// @param _name Name of the beneficiary.
    /// @param _beneficiary Address of the beneficiary.
    /// @param _amount Amount of stablecoin to be transferred.
    /// @param _time Time at which the inheritance should be claimable.
    function addBeneficiary(string memory _name, address _beneficiary, uint256 _amount, uint _time) public {
        _amount * 1 ether;
        stablecoin.transferFrom(msg.sender, address(this), _amount);

        inheritance memory _inheritance = inheritance(_name, _beneficiary, _amount, _time);

        userToBeneficiaries[msg.sender].push(_inheritance);

        userToNumOfBeneficiaries[msg.sender]++;
    }

    /// @notice Returns an array of inheritance structs for the sender.
    /// @return An array of inheritance structs.
    function getBeneficiaries() public view returns (inheritance[] memory) {
        return userToBeneficiaries[msg.sender];
    }

    /// @notice Allows beneficiaries to claim their share of the inheritance after the specified time has passed.
    /// @dev Iterates through the inheritance structs and transfers the relevant amount to the beneficiary if the specified time has passed.
    /// @param _deceased Address of the deceased account holder.
    /// @return The total amount claimed by the beneficiary.
    function claimInheritance(address _deceased) public returns (uint256) {
        inheritance[] memory inheritanceArr = userToBeneficiaries[_deceased];

        uint256 numOfBeneficiaries = userToNumOfBeneficiaries[_deceased];

        uint256 totalAmount;

        for (uint i; i < numOfBeneficiaries; i++) {
            uint256 amount = inheritanceArr[i].amount;
            address beneficiary = inheritanceArr[i].beneficiary;
            uint256 time = inheritanceArr[i].time;

            if (beneficiary == msg.sender && amount > 0 && time <= block.timestamp) {
                totalAmount += amount;
                inheritanceArr[i].amount = 0;
            }
        }

        stablecoin.approve(msg.sender, totalAmount);
        stablecoin.transfer(msg.sender, totalAmount);
        return totalAmount;
    }

}

/// @title IERC20 Interface
/// @notice An interface to interact with an ERC20 token.
interface IERC20 {

/// @notice Transfers stablecoins from one address to another.
/// @param from Address of the sender.
/// @param to Address of the receiver.
/// @param amount Amount to be transferred.
/// @return A boolean value indicating whether the operation succeeded.
function transferFrom(address from, address to, uint256 amount) external returns (bool);

/// @notice Sets an allowance for a spender to spend from the sender’s balance.
/// @param spender Address of the spender.
/// @param amount Amount to be approved.
/// @return A boolean value indicating whether the operation succeeded.
function approve(address spender, uint256 amount) external returns (bool);

/// @notice Transfers stablecoins from the sender’s address to another address.
/// @param to Address of the receiver.
/// @param amount Amount to be transferred.
/// @return A boolean value indicating whether the operation succeeded.
function transfer(address to, uint256 amount) external returns (bool);
}