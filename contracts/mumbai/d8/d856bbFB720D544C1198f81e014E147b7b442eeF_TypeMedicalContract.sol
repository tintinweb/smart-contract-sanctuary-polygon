/**
 *Submitted for verification at polygonscan.com on 2022-08-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

library Converter {
    function convertToBytes(string memory _str) internal pure returns(bytes memory) {
      return bytes(abi.encodePacked(_str));
    }
}

interface ITypeMedical {
    function isTypeMedical(bytes calldata) external returns (bool);
    function userMedical(address) external returns (bytes memory);
    function isRegistered(address) external returns (bool);

    function addTypeMedical(bytes calldata _type) external returns (bytes[] memory);
    function setUserMedical(address _address,bytes calldata _type) external returns(bool);
    function getListTypeMedicals() external view returns (bytes[] memory);
}

contract TypeMedicalContract is ITypeMedical, Ownable {
    using Converter for string;

    // Array Type Medical
    bytes[] TypeMedical;
    mapping(bytes => bool) public override isTypeMedical;

    mapping(address => bytes) public override userMedical;
    mapping(address => bool) public override isRegistered;

    constructor() {
        string memory data6 = "HOTEL";
        string memory data1 = "HOSPITAL";
        string memory data2 = "PATIENT";
        string memory data4 = "NURSE";
        string memory data3 = "DOCTOR";
        string memory data5 = "WELLNESS SERVICES";

        TypeMedical.push(data6.convertToBytes());
        TypeMedical.push(data1.convertToBytes());
        TypeMedical.push(data2.convertToBytes());
        TypeMedical.push(data4.convertToBytes());
        TypeMedical.push(data3.convertToBytes());
        TypeMedical.push(data5.convertToBytes());

        isTypeMedical[data6.convertToBytes()] = true;
        isTypeMedical[data1.convertToBytes()] = true;
        isTypeMedical[data2.convertToBytes()] = true;
        isTypeMedical[data4.convertToBytes()] = true;
        isTypeMedical[data3.convertToBytes()] = true;
        isTypeMedical[data5.convertToBytes()] = true;
    }

    /// can using web3js with function asciitoHex() for input params _type
    function addTypeMedical(bytes calldata _type) public onlyOwner returns (bytes[] memory) {
        require(!isTypeMedical[_type], "Type medical already registered !");

        TypeMedical.push(_type);
        isTypeMedical[_type] = true;

        return TypeMedical;
    }

    function setUserMedical(address _address,bytes calldata _type) public returns(bool) {
        require(msg.sender != address(0), "Non zero address !");
        require(isTypeMedical[_type], "Type medical not registered !");
        require(!isRegistered[_address], "Already registered !");
        
        isRegistered[_address] = true;
        userMedical[_address] = _type;
        
        return true;
    }

    function getListTypeMedicals() public view returns (bytes[] memory) {
        return TypeMedical;
    }

}