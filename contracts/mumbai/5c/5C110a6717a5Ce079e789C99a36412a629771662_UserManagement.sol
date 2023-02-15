pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.5.0;

import "./Libs/SafeMath.sol";
import "./Ownable.sol";

/**
 * @dev Contract module which provides a basic storage system.
 *
 * This module is used through inheritance. It will make available the contract
 * addresses created, owners of the contract and receipts record detailing land documentations.
 */
contract ExternalStorage {
    using SafeMath for uint256;

    address[] internal admins;
    address[] internal authorizers;
    address[] internal userList;
    address[] internal blackList;

    string internal constant SuperAdmin = "SuperAdmin";

    VTDetails internal vtDetails;
    SellerDetails internal sellerDetails;
    BuyerDetails internal buyerDetails;
    AcOfficerDetails internal acOfficerDetails;
    AgreementDetails internal agreementDetails;
    SPAContractData internal spacontractData;
    SPAContractDetails internal spacontractDetails;

    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isAuthorizer;
    mapping(address => bool) public isUserListed;
    mapping(address => bool) public isBlackListed;

    mapping(string => address) superAdmin;
    mapping(address => AdminDetails) Admins;

    //Events for UserManagement
    event AdminAdded(address indexed Admin);
    event AdminRemoved(address indexed Admin);
    event AuthorizerAdded(address indexed Authorizer);
    event AuthorizerRemoved(address indexed Authorizer);
    event SetUserListEvent(address indexed User);
    event RemovedUserList(address indexed User);
    event SetBlackListEvent(address indexed EvilUser);
    event RemoveUserBlackList(address indexed RedeemedUser);

    //Admin Details
    struct AdminDetails {
        address AdminID;
        bytes32 AdminName;
        address AddedBy;
    }

    //Structs for Agreement Contract
    struct VTDetails {
        address VTAddr;
        bytes32 CompanyNameVT;
        bytes32 PhoneVT;
        bytes32 AddressVT;
        bytes32 EmailVT;
        bytes32 BankNameVT;
        bytes32 AccountNameVT;
        bytes32 AccountNoVT;
        bytes32 BankSwiftCodeVT;
    }

    struct SellerDetails {
        address SellerAddr;
        bytes32 NameSeller;
        bytes32 PhoneSeller;
        bytes32 AddressSeller;
        bytes32 CompanySeller;
        bytes32 EmailSeller;
        bytes32 BankNameSeller;
        bytes32 AccountNameSeller;
        bytes32 AccountNoSeller;
        bytes32 BankSwiftCodeSeller;
    }

    struct BuyerDetails {
        address BuyerAddr;
        bytes32 NameBuyer;
        bytes32 PhoneBuyer;
        bytes32 AddressBuyer;
        bytes32 CompanyBuyer;
        bytes32 EmailBuyer;
        bytes32 BankNameBuyer;
        bytes32 AccountNameBuyer;
        bytes32 AccountNoBuyer;
        bytes32 BankSwiftCodeBuyer;
    }

    struct AcOfficerDetails {
        bytes32 AccountOfficerNameVT;
        bytes32 AccountOfficerNoVT;
        bytes32 AccountOfficerEmailVT;
        bytes32 AccountOfficerNameSeller;
        bytes32 AccountOfficerNoSeller;
        bytes32 AccountOfficerEmailSeller;
        bytes32 AccountOfficerNameBuyer;
        bytes32 AccountOfficerNoBuyer;
        bytes32 AccountOfficerEmailBuyer;
    }

    struct AgreementDetails {
        bytes32 SellerIntermediaries;
        bytes32 BuyerIntermediaries;
        bytes32 VTPercentShare;
        bytes32 SellerPercentShare;
        bytes32 BuyerPercentShare;
    }

    //SPA Contract Data
    struct SPAContractData {
        uint256 AssetID;
        bytes32 CommodityCode;
        bytes32 Standard;
        bytes32 Origin;
        bytes32 LoadingTerminal;
        bytes32 DeliveryDay;
        bytes32 Doc1;
        bytes32 Doc2;
        bytes32 Doc3;
    }

    //SPA Contract Details
    struct SPAContractDetails {
        bytes32 Packaging;
        bytes32 Quality;
        bytes32 Quantity;
        bytes32 BarrelPrice;
        bytes32 ContractLength;
        bytes32 Vessel;
        bytes32 IMONumber;
        bytes32 Procedure;
    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    //  constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: Addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: Subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: Multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: Division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: Modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "./Libs/Context.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context, Initializable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address _superAdmin) public initializer {
        _owner = _superAdmin;
        emit OwnershipTransferred(address(0x0), _owner);
    }

    // constructor() internal {
    //     _owner = msg.sender;
    //     emit OwnershipTransferred(address(0x0), _owner);
    // }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0x0));
        _owner = address(0x0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0x0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./ExternalStorage.sol";

/**
 * @dev Contract module for creates user management.
 *
 * This module is used through inheritance. It will make available the contract
 * addresses of users, admin, whitelisting and blacklisting of users.
 */
contract UserManagement is Ownable, ExternalStorage {
    //     ***********     Modifiers    ************

    modifier adminExists(address _admin) {
        require(isAdmin[_admin], "Not an Admin");
        _;
    }

    modifier adminDoesNotExist(address admin) {
        require(!isAdmin[admin], "Admin already exists");
        _;
    }

    modifier authorizerDoesNotExist(address _authorizer) {
        require(!isAuthorizer[_authorizer], "Authorizer already exists");
        _;
    }

    modifier authorizerExists(address authorizer) {
        require(isAuthorizer[authorizer], "Address not Authorizer");
        _;
    }

    modifier checkUserList(address _user) {
        require(isUserListed[_user], "Not Registered User");
        _;
    }

    modifier checkBlackList(address _addr) {
        require(!isBlackListed[_addr], "User is BlackListed");
        _;
    }

    function initialize(address _superAdmin) public initializer {
        Ownable.initialize(_superAdmin);

        isUserListed[_superAdmin] = true;
        userList.push(_superAdmin);

        AddAdmin(_superAdmin, "SuperAdmin");

        isAuthorizer[_superAdmin] = true;
        authorizers.push(_superAdmin);
    }

    // constructor() public {
    //     isUserListed[_msgSender()] = true;
    //     userList.push(_msgSender());

    //     AddAdmin(_msgSender(), "SuperAdmin");

    //     isAuthorizer[_msgSender()] = true;
    //     authorizers.push(_msgSender());
    // }

    //        *************   Setters   *************

    function AddSuperAdmin(address _superAdminAddr, string memory _registrar)
        public
        onlyOwner
        returns (bool)
    {
        superAdmin[_registrar] = _superAdminAddr;
    }

    //Check if user is admin
    function IsAdmin(address _addr) public view returns (bool) {
        return isAdmin[_addr];
    }

    //Add platform Admin
    function AddAdmin(address _Admin, bytes32 _AdminName)
        public
        onlyOwner
        checkUserList(_Admin)
        adminDoesNotExist(_Admin)
        checkBlackList(_Admin)
        returns (bool)
    {
        if (!isUserListed[_Admin]) SetUserList(_Admin);

        Admins[_Admin] = AdminDetails(_Admin, _AdminName, _msgSender());
        admins.push(_msgSender());
        isAdmin[_Admin] = true;

        emit AdminAdded(_Admin);

        return true;
    }

    //Remove platform Admin
    function RemoveAdmin(address _addr)
        public
        onlyOwner
        adminExists(_addr)
        returns (bool)
    {
        isAdmin[_addr] = false;
        for (uint256 i = 0; i < admins.length - 1; i++)
            if (admins[i] == _addr) {
                admins[i] = admins[admins.length - 1];
                break;
            }

        admins.pop();
        delete Admins[_addr];

        emit AdminRemoved(_addr);

        return true;
    }

    function AddAuthorizer(address _authorizer)
        public
        checkUserList(_authorizer)
        adminExists(_msgSender())
        authorizerDoesNotExist(_authorizer)
        checkBlackList(_authorizer)
        returns (bool)
    {
        isAuthorizer[_authorizer] = true;
        authorizers.push(_authorizer);

        emit AuthorizerAdded(_authorizer);

        return true;
    }

    //Remove an Authorizer
    function RemoveAuthorizer(address _authorizer)
        public
        adminExists(_msgSender())
        authorizerExists(_authorizer)
        returns (bool)
    {
        isAuthorizer[_authorizer] = false;
        for (uint256 i = 0; i < authorizers.length - 1; i++)
            if (authorizers[i] == _authorizer) {
                authorizers[i] = authorizers[authorizers.length - 1];
                break;
            }
        authorizers.pop();

        emit AuthorizerRemoved(_authorizer);

        return true;
    }

    //Check if user is Blacklisted
    function IsBlackListed(address _addr) public view returns (bool) {
        return isBlackListed[_addr];
    }

    // Add adress to the BlackList
    function AddBlackList(address _evilUser)
        public
        adminExists(_msgSender())
        checkUserList(_evilUser)
        checkBlackList(_evilUser)
    {
        if (isAdmin[_evilUser]) {
            RemoveAdmin(_evilUser);
        }
        if (isAuthorizer[_evilUser]) {
            RemoveAuthorizer(_evilUser);
        }

        blackList.push(_evilUser);
        isBlackListed[_evilUser] = true;

        emit SetBlackListEvent(_evilUser);
    }

    // Remove Address from the BlackList
    function RemoveBlackList(address _clearedUser)
        public
        adminExists(_msgSender())
        returns (bool)
    {
        require(isBlackListed[_clearedUser], "Address not BlackListed");

        for (uint256 i = 0; i < userList.length - 1; i++)
            if (blackList[i] == _clearedUser) {
                blackList[i] = blackList[blackList.length - 1];
                break;
            }
        blackList.pop();
        isBlackListed[_clearedUser] = false;

        emit RemoveUserBlackList(_clearedUser);

        return true;
    }

    //Check if user is Registered
    function IsUserListed(address _addr) public view returns (bool) {
        return isUserListed[_addr];
    }
    
    //Add Users on the platform
    function SetUserList(address _addr)
        public
        adminExists(_msgSender())
        checkBlackList(_addr)
        returns (bool)
    {
        require(!isUserListed[_addr], "Address already Registered");

        isUserListed[_addr] = true;
        userList.push(_addr);

        emit SetUserListEvent(_addr);

        return true;
    }

    //Remove Users from the platform
    function RemoveUserList(address _addr)
        public
        adminExists(_msgSender())
        checkUserList(_addr)
        returns (bool)
    {
        isUserListed[_addr] = false;
        for (uint256 i = 0; i < userList.length - 1; i++)
            if (userList[i] == _addr) {
                userList[i] = userList[userList.length - 1];
                break;
            }
        userList.pop();

        emit RemovedUserList(_addr);

        return true;
    }

    //        *************   Getter   *************

    //Get list of Whitelisted Users
    function getUserList()
        public
        view
        adminExists(_msgSender())
        returns (address[] memory)
    {
        return userList;
    }

    //Get list of BlackListed Users
    function getBlackList()
        public
        view
        adminExists(_msgSender())
        returns (address[] memory)
    {
        return blackList;
    }
}