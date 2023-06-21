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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract KycContract is Ownable {

    struct BuyerData {
        bytes32 BuyerInfo;
        bool BuyerState;
    }

    struct SellerData {
        bytes32 SellerInfo;
        bool SellerState;
    }

    mapping (address => BuyerData) public Buyer;
    mapping(address => SellerData) public Seller;
    mapping(address => bool) public AuditorState;

    event AuditorGranted ( address indexed addr, string message);
    event AuditorRevoked ( address indexed addr, string message);
    event KycBuyerGranted ( address indexed addr, string message);
    event KycBuyerRevoked ( address indexed addr, string message);
    event BuyerInfoDeleted ( address indexed addr, string message);
    event KycSellerGranted ( address indexed addr, string message);
    event KycSellerRevoked ( address indexed addr, string message);
    event SellerInfoDeleted ( address indexed addr, string message);

    modifier onlyAuditor(){
        require(AuditorState[msg.sender]==true,"Only Auditor functionality");
        _;
    }

    //Owner will grant or revoke the auditor role 
    function setAuditorGranted(address _addr) public onlyOwner {
        AuditorState[_addr] = true;
        emit AuditorGranted (_addr, "Auditor state granted");
    }

    function setAuditorRevoked(address _addr) public onlyOwner {
        AuditorState[_addr] = false;
        emit AuditorRevoked (_addr, "Auditor state revoked");
    }

    // function ReturnAuditorState(address _addr) public view returns(bool) {
    //     return AuditorState[_addr];
    // }

    //Auditors will grant or revoke Buyer and Seller KYC
    function setBuyerCompleted(address _addr, bytes32 _info) public onlyAuditor{
        Buyer[_addr].BuyerInfo = _info;
        Buyer[_addr].BuyerState = true;
        emit KycBuyerGranted (_addr, "Buyer KYC granted");
    }

    function setBuyerRevoked(address _addr) public onlyAuditor{
        Buyer[_addr].BuyerState = false;
        emit KycBuyerRevoked (_addr, "Buyer KYC revoked");
    }
    
    //When a Buyer is deleted so is his information
    function deleteBuyer (address _addr) public onlyAuditor{
        delete Buyer[_addr];
        emit BuyerInfoDeleted (_addr, "Buyer's information deleted");
    }

    function ReturnBuyerState(address _addr) public view returns(bool) {
        return Buyer[_addr].BuyerState;
    }

    // function ReturnBuyerInfo (address _addr) public view returns(bytes32) {
    //     return Buyer[_addr].BuyerInfo;
    // }

    function setSellerCompleted(address _addr, bytes32 _info) public onlyAuditor{
        Seller[_addr].SellerInfo = _info;
        Seller[_addr].SellerState = true;
        emit KycSellerGranted (_addr, "Seller KYC granted");
    }

    function setSellerRevoked(address _addr) public onlyAuditor{
        Seller[_addr].SellerState = false;
        emit KycSellerRevoked (_addr, "Seller KYC revoked");
    }

    //When a Seller is deleted so is his information
    function deleteSeller (address _addr) public onlyAuditor{
        delete Seller[_addr];
        emit SellerInfoDeleted (_addr, "Seller's information deleted");
    }

    function ReturnSellerState(address _addr) public view returns(bool) {
        return Seller[_addr].SellerState;
    }

    // function ReturnSellerInfo (address _addr) public view returns(bytes32) {
    //     return Seller[_addr].SellerInfo;
    // }
}