/**
 *Submitted for verification at polygonscan.com on 2022-12-04
*/

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

// File: contracts/BriskMed.sol


/** 
 * @title BriskMed
 * @dev Implements Hospital registration, reviews and rating
 */
contract BriskMed is Ownable {

    event ProfileCreated(
        address indexed hospital,
        string name,
        string image,
        string desc,
        string location
    );

    
    struct profile {
       string name;
       address addr;
       uint256 avgRating;
       uint256 totalRating;
       string image;
       string location;
       string long;
       string lat;
       uint256 bed;
       string desc;
       string license;
       uint256 rateIndex;
    } 

    struct rating {
        string name;
        address userAddr;
        string review;
        uint256 rate;
    }

    /* User Types Arrays */
    address [] public allHospital;

    /* User profile mapping */
    mapping(address => profile) public HospitalProfile;
    
    mapping(address => rating []) public HospitalRating;

    function createProfile(string memory _name, string memory _desc, string memory _location, string memory _lat, string memory _long, string memory _image, string memory _license) public {
         if(HospitalProfile[msg.sender].addr == address(0)){
            allHospital.push(msg.sender);
        }
        
        HospitalProfile[msg.sender].addr = msg.sender;
        HospitalProfile[msg.sender].name = _name;
        HospitalProfile[msg.sender].desc = _desc;
        HospitalProfile[msg.sender].image = _image;
        HospitalProfile[msg.sender].license = _license;
        HospitalProfile[msg.sender].location = _location;
        HospitalProfile[msg.sender].long = _long;
        HospitalProfile[msg.sender].lat = _lat;

        emit ProfileCreated(msg.sender, _name, _image, _desc, _location);
 
    }

    function postReview (address _hospital, string memory _name, string memory _review, uint256 _rate ) public {
        HospitalProfile[_hospital].rateIndex ++;    

        rating memory NewRating;
        NewRating.name = _name;
        NewRating.userAddr = msg.sender;
        NewRating.review = _review;
        NewRating.rate = _rate;

        HospitalProfile[_hospital].totalRating += _rate;

        HospitalProfile[_hospital].avgRating = HospitalProfile[_hospital].totalRating / HospitalProfile[_hospital].rateIndex;

        HospitalRating[_hospital].push(NewRating);
        
    }

    function updateStatus(uint256 _bed) public {
        HospitalProfile[msg.sender].bed = _bed;
    }
    
    
    /** Getter Functions */
    function getProfile(address _addr) public view returns (profile memory) {
        return HospitalProfile[_addr];
    }

    function getAllHospital() public view returns (address [] memory) {
        return allHospital;
    }

    function getReviews(address _addr) public view returns (rating [] memory) {
        return HospitalRating[_addr];
    }
   
}