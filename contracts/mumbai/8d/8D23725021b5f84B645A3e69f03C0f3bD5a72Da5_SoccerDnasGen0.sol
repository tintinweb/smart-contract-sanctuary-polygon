/**
 *Submitted for verification at polygonscan.com on 2022-06-29
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: contracts/SC_SoccerDnasGen0.sol



pragma solidity >=0.7.0 <0.9.0;


contract SoccerDnasGen0 is Ownable{
    string [] public commonsDNAs = [
        "001G00S068S070R071S0780",
        "002G00S069S053R064S0560",
        "003G00S079S053R070S0770",
        "004G00S074S074R065S0520",
        "005G00S069S068R075S0560",
        "006G00S051S065R053S0690",
        "007G00S075S072R051S0770",
        "008G00S061S071R073S0640",
        "009G00S068S054R065S0720",
        "010G00S077S052R057S0510",
        "011G00S079S060R075S0660",
        "012G00S065S074R077S0790",
        "013G00S077S050R078S0770",
        "014G00S060S073R062S0630",
        "015G00S074S053R074S0600",
        "016G00S076S067R079S0560",
        "017G00S070S050R070S0500",
        "018G00S052S071R078S0570",
        "019G00S054S054R070S0770",
        "020G00S067S051R062S0640",
        "021G00S073S056R060S0780",
        "022G00S057S057R072S0540",
        "023G00S073S051R076S0500",
        "024G00S051S079R064S0650",
        "025G00S066S060R061S0670",
        "026G00S051S064R054S0740",
        "027G00S075S061R061S0510",
        "028G00S064S058R069S0530",
        "029G00S068S073R053S0790",
        "030G00S054S073R053S0770",
        "031G00S073S058R060S0650",
        "032G00S061S053R054S0540",
        "033G00S052S069R066S0750",
        "034G00S056S054R071S0580",
        "035G00S063S056R060S0730",
        "036G00S072S069R051S0530",
        "037G00S054S067R055S0520",
        "038G00S069S058R062S0530"
    ];


    string [] public raresDNAs = [
        "039G00S087S078R077S0681",
        "040G00S087S076R057S0671",
        "041G00S065S069R072S0851",
        "042G00S061S077R082S0751",
        "043G00S053S084R065S0631",
        "044G00S090S054R076S0741",
        "045G00S069S085R052S0731",
        "046G00S073S075R081S0531",
        "047G00S056S082R062S0711",
        "048G00S057S077R089S0781",
        "049G00S086S056R072S0641",
        "050G00S078S052R050S0861"
    ];


    mapping(address => bool) public approvedContracts;


    function getCommonsDnaLength () public view returns(uint256) {
        return commonsDNAs.length;
    }


    function getRaresDnaLength () public view returns(uint256) {
        return raresDNAs.length;
    }


    function getCommonDna (uint256 index) public view returns(string memory){
        return commonsDNAs[index];
    }


    function getRareDna (uint256 index) public view returns(string memory){
        return raresDNAs[index];
    }


    function deleteCommonDna (uint256 index) public {
        require(approvedContracts[msg.sender]);
        commonsDNAs[index] = commonsDNAs[commonsDNAs.length - 1];
        commonsDNAs.pop();
    }


    function deleteRareDna (uint256 index) public {
        require(approvedContracts[msg.sender]);
        raresDNAs[index] = raresDNAs[raresDNAs.length - 1];
        raresDNAs.pop();
    }


    function approveContract(address contractAddress) public onlyOwner {
        approvedContracts[contractAddress] = true;
    }
    

    function disapproveContract(address contractAddress) public onlyOwner {
        approvedContracts[contractAddress] = false;
    }
}