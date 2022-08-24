/**
 *Submitted for verification at polygonscan.com on 2022-08-23
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: OazizOrganization.sol

pragma solidity ^0.8.0;

pragma solidity ^0.8.0;

/**
 * @dev Library to add all efficient functions that could get repeated.
 */
library GasLib {
    /**
     * @dev Will return unchecked incremented uint256
     */
    function unchecked_inc(uint256 i) internal pure returns (uint256) {
        // solhint-disable func-name-mixedcase
        unchecked {
            return i + 1;
        }
    }
}
contract OazizOrganization is Ownable{
    string public name;
    address public Admin;
    mapping(address => uint256) public roles; // 1 : admin 2 : contributor 3 : scanner
    /**
     * @dev Map the dataKeys to their dataValues
     */
    mapping(bytes32 => string) internal store;

    modifier onlyAdmin(address fromAddress) {
        require(roles[fromAddress] == 1, "only Admin can do this");
        _;
    }

    modifier onlyContributor(address fromAddress) {
        require(roles[fromAddress] == 1 || roles[fromAddress] == 2, "only Admin and Contributor can do this");
        _;
    }

    /**
     * @notice Emitted when data at a key is changed
     * @param dataKey The key which value is set
     */
    event DataChanged(bytes32 indexed dataKey);

    constructor(string memory orgName, address newOwner) {
        Admin = newOwner;
        name = orgName;
        roles[Admin] = 1;
    }

    function setRole(address _addr, uint256 roleId, address fromAddr) external onlyOwner onlyContributor(fromAddr) {
        roles[_addr] = roleId;
    }

    function setData(bytes32[] memory dataKeys, string[] memory dataValues, address fromAddr) external onlyOwner onlyContributor(fromAddr) {
        require(
            dataKeys.length == dataValues.length,
            "Keys length not equal to values length"
        );
        for (uint256 i = 0; i < dataKeys.length; i = GasLib.unchecked_inc(i)) {
            _setData(dataKeys[i], dataValues[i]);
        }
    }
    function getData(bytes32[] memory dataKeys) public view virtual returns (string[] memory dataValues)
    {
        dataValues = new string[](dataKeys.length);

        for (uint256 i = 0; i < dataKeys.length; i = GasLib.unchecked_inc(i)) {
            dataValues[i] = _getData(dataKeys[i]);
        }

        return dataValues;
    }

    function _getData(bytes32 dataKey) internal view virtual returns (string memory dataValue)
    {
        return store[dataKey];
    }

    function _setData(bytes32 dataKey, string memory dataValue) internal virtual
    {
        store[dataKey] = dataValue;
        emit DataChanged(dataKey);
    }
}
// File: OazizOrganizationManage.sol

pragma solidity ^0.8.0;



contract OazizOrganizationManage is Ownable {
    mapping(address => address) public OrgAddress; // find Org address by org owner address
    mapping(address => address) public OrgOwner; // find owner by employee address

    function createOrganization(string memory orgName, address newOwner) external onlyOwner {
        OazizOrganization org = new OazizOrganization(orgName, newOwner);
    }

    function setRole(address _addr, uint256 roleId, address fromAddr) external onlyOwner {
        require(OrgAddress[fromAddr] != address(0), "you don't have any organization");
        OazizOrganization org = OazizOrganization(OrgAddress[fromAddr]);
        org.setRole(_addr, roleId, fromAddr);
        OrgOwner[_addr] = fromAddr;
    }

    function removeRole(address _addr, address fromAddr) external onlyOwner {
        require(OrgAddress[fromAddr] != address(0), "you don't have any organization");
        OazizOrganization org = OazizOrganization(OrgAddress[fromAddr]);
        org.setRole(_addr, 0, fromAddr);
        OrgOwner[_addr] = address(0);
    }

    function setData(bytes32[] memory dataKeys, string[] memory dataValues, address fromAddr) external onlyOwner {
        OazizOrganization org = OazizOrganization(OrgAddress[fromAddr]);
        org.setData(dataKeys, dataValues, fromAddr);
    }
}