// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

/*** CONTRACTS IMPORTED ***/
import "@openzeppelin/contracts/access/Ownable.sol";

contract Fundraiser is Ownable {
    /*** STATE VARIABLES ***/
    string public s_name;
    string public s_url;
    string public s_imageURL;
    string public s_description;
    address payable public s_beneficiary;
    address public s_custodian;
    struct Donation {
        uint256 value;
        uint256 date;
    }
    uint256 public s_totalDonations;
    uint256 public s_donationsCount;

    /*** EVENTS ***/
    event DonationReceived(address indexed donor, uint256 value);
    event Withdraw(uint256 amount);

    /*** MAPPINGS ***/
    mapping(address => Donation[]) private _donations;

    /*** CONSTRUCTOR ***/
    constructor(
        string memory _name,
        string memory _url,
        string memory _imageURL,
        string memory _description,
        address payable _beneficiary,
        address _custodian
    ) {
        s_name = _name;
        s_url = _url;
        s_imageURL = _imageURL;
        s_description = _description;
        s_beneficiary = _beneficiary;
        transferOwnership(_custodian);
    }

    /*** RECEIVE / FALLBACK ***/
    receive() external payable {
        s_totalDonations += msg.value;
        s_donationsCount++;
    }

    /*** MAIN FUNCTIONS ***/
    function setsBeneficiary(address payable _beneficiary) public onlyOwner {
        s_beneficiary = _beneficiary;
    }

    function donate() public payable {
        Donation memory donation = Donation({value: msg.value, date: block.timestamp});
        _donations[msg.sender].push(donation);
        s_totalDonations += msg.value;
        s_donationsCount++;
        emit DonationReceived(msg.sender, msg.value);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        s_beneficiary.transfer(balance);
        emit Withdraw(balance);
    }

    /*** VIEW / PURE FUNCTIONS ***/

    function myDonationsCount() public view returns (uint256) {
        return _donations[msg.sender].length;
    }

    function myDonations() public view returns (uint256[] memory values, uint256[] memory dates) {
        uint256 count = myDonationsCount();
        values = new uint256[](count);
        dates = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            Donation storage donation = _donations[msg.sender][i];
            values[i] = donation.value;
            dates[i] = donation.date;
        }
        return (values, dates);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

/*** CONTRACTS IMPORTED ***/
import "./Fundraiser.sol";

contract FundraiserFactory {
    /*** STATE VARIABLES ***/
    Fundraiser[] private _fundraisers;
    uint256 constant maxLimit = 20;

    /*** EVENTS ***/
    event FundraiserCreated(Fundraiser indexed fundraiser, address indexed owner);

    /*** MAIN FUNCTIONS ***/
    function fundraisersCount() public view returns (uint256) {
        return _fundraisers.length;
    }

    function createFundraiser(
        string memory name,
        string memory url,
        string memory imageURL,
        string memory description,
        address payable beneficiary
    ) public {
        Fundraiser fundraiser = new Fundraiser(
            name,
            url,
            imageURL,
            description,
            beneficiary,
            msg.sender
        );
        _fundraisers.push(fundraiser);
        emit FundraiserCreated(fundraiser, msg.sender);
    }

    /*** VIEW / PURE FUNCTIONS ***/
    function fundraisers(
        uint256 limit,
        uint256 offset
    ) public view returns (Fundraiser[] memory coll) {
        require(offset <= fundraisersCount(), "offset out of bounds");
        uint256 size = fundraisersCount() - offset;
        size = size < limit ? size : limit;
        size = size < maxLimit ? size : maxLimit;
        coll = new Fundraiser[](size);

        for (uint256 i = 0; i < size; i++) {
            coll[i] = _fundraisers[offset + i];
        }

        return coll;
    }
}