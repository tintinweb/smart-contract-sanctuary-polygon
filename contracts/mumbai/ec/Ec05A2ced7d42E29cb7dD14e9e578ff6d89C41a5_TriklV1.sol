// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Trikl
 * @dev Implements a decentralized version of patreon for crypto traders and content creators
 */

contract TriklV1 {
    // address owner;
    address private immutable i_owner;
    mapping(address => uint) membership;
    mapping(address => address[]) addressToMany;

    // struct Expert {
    //     address _expert;
    //     uint256 _membershipCharges;
    //     address [] _members;
    // }
    // Expert[] public experts;

    // custom error to save gas
    error TriklBasic__NotOwner();
    error InsufficientBalance();
    error ContractCalling();
    error TransactionFailed();

    /**
     * @dev Sets creator the owner of the smart contract.
     */
    constructor() {
        i_owner = msg.sender;
    }

    /**
     * @dev Checks if the function is accessed by owner, if not, throws an error .
     */
    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) revert TriklBasic__NotOwner();
        _;
    }

    /*********************************************************
     *                                                       *
     *                    MAIN FUNCTIONS                     *
     *                                                       *
     *********************************************************/

    /**
     * @dev Creates a new expert to Expert struct whenever a new users joins the platform.
     *
     * @param _expertAddress - Address of creator
     * @param _membershipCharges - Membership fee for the expert's community
     */
    function CreateExpert(address _expertAddress, uint256 _membershipCharges)
        external
    {
        membership[_expertAddress] = _membershipCharges;
    }

    /**
     * @dev Handles the payment for each subscription.
     * Called when subscriber initiates transfer to Creator's wallet.
     * 2.5% of the total amount goes to Trikl funds
     *
     * @param _expertAddress - Address of creator - 97.5% would be transfered to them
     * msg.value - Total amount paid by User
     */
    function subscribe(address _expertAddress) external payable {
        if (tx.origin != msg.sender) {
            revert ContractCalling();
        }
        (
            bool sent, /*memory data*/

        ) = _expertAddress.call{value: (msg.value * 975) / 1000}("");
        if (!sent) {
            revert TransactionFailed();
        }

        addressToMany[_expertAddress].push(msg.sender);
    }

    /**
     * @dev Handles fund withdrawl from Smart Contract.
     * Only accessible to smart Contract Owner.
     *
     * @param _amount - Amount being transferred from the smart contract
     */
    function withdraw(uint _amount) external onlyOwner {
        if (_amount > address(this).balance) {
            revert InsufficientBalance();
        }
        (
            bool sent, /*memory data*/

        ) = i_owner.call{value: _amount}("");
        if (!sent) {
            revert TransactionFailed();
        }
    }

    /*********************************************************
     *                                                       *
     *                    GET FUNCTIONS                      *
     *                                                       *
     *********************************************************/

    /**
     * @dev get functions to check the owner of the smart contract and
     * to fetch the balance of the smart contract
     */
    function getOwner() external view returns (address) {
        return i_owner;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getmembers(address _expertAddress)
        public
        view
        returns (address[] memory)
    {
        return addressToMany[_expertAddress];
    }

    function getmembershipcharges(address _expertAddress)
        public
        view
        returns (uint256)
    {
        return membership[_expertAddress];
    }
}