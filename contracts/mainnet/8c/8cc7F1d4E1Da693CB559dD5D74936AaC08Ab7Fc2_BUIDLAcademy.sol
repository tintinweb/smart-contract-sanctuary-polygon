// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//create a smart contract to keep track of courses created by the user

interface Token {
    //balanceOf(address account) returns (uint256)
    function balanceOf(address account) external view returns (uint256);
}

contract BUIDLAcademy is Context, Ownable {
    //create a struct to keep track of the courses
    struct Course {
        address owner;
        string name;
        uint256 id;
        uint256 price;
        uint256 courseCount;
        uint256 amountGeneratedStable;
        uint256 amountGeneratedMatic;
        mapping(address => bool) Buyers;
    }

    struct TokenInfo {
        IERC20 paytoken;
    }

    TokenInfo[] public AllowedCrypto;

    //create a mapping to keep track of the courses
    mapping(uint256 => Course) public courses;

    //map courses to the owner
    mapping(address => uint256[]) public ownerToCourses;

    //buyers will be able to buy courses map the buyers to the courses they own
    mapping(address => uint256[]) public buyerToCourses;

    //whitelist course creators
    mapping(address => bool) public whiteListCourseCreators;

    //create a counter to keep track of the courses
    uint256 public courseCounter;

    AggregatorV3Interface internal priceFeed;

    
    constructor() {
        courseCounter = 0;
        priceFeed = AggregatorV3Interface(
            0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/
            ,
            ,

        ) = /*uint80 answeredInRound*/
            priceFeed.latestRoundData();
        return price;
    }

    function addCurrency(IERC20 _paytoken) public onlyOwner {
        AllowedCrypto.push(TokenInfo({paytoken: _paytoken}));
    }

    //COURSE CREATOR FUNCTIONS //

    //create a function to create a course
    function createCourse(
        string memory _name,
        uint256 _price
    ) public {
        require(
            whiteListCourseCreators[_msgSender()] == true,
            "You are not whitelisted to create courses"
        );

        uint256 _courseId = courseCounter;
        //require that the course at the id does not exist
        require(courses[_courseId].id == 0, "Course already exists");

        
        
        courses[_courseId].owner = _msgSender();
        courses[_courseId].name = _name;
        courses[_courseId].id = _courseId;
        courses[_courseId].price = _price;
        courses[_courseId].courseCount = 0;
        courses[_courseId].amountGeneratedStable = 0;
        courses[_courseId].amountGeneratedMatic = 0;

        //add the course to the owner
        ownerToCourses[_msgSender()].push(_courseId);
        courseCounter++;
    }

    //create a function to transfer the ownership of the course
    function transferCourse(uint256 _id, address _newOwner) public {
        //check if the course exists
        require(courses[_id].id != 0, "Course does not exist");

        //check if the course belongs to the owner
        require(
            courses[_id].owner == _msgSender(),
            "You are not the owner of the course"
        );

        //remove mapping of old owner in ownertocourses
        address prevowner =courses[_id].owner;

        //in ownerTcourse remove _id from prev ownwer
        for(uint i=0; i<ownerToCourses[prevowner].length; i++){
            if(ownerToCourses[prevowner][i] == _id){
                delete ownerToCourses[prevowner][i];
            }
        }

       
        //transfer the ownership of the course
        courses[_id].owner = _newOwner;

        //add the course to the new owner
        ownerToCourses[_newOwner].push(_id);
       
    }

    //delete a course
    function deleteCourse(uint256 _id) public {
        //check if the course exists
        require(courses[_id].id != 0, "Course does not exist");

        //check if the course belongs to the owner
        require(
            courses[_id].owner == _msgSender(),
            "You are not the owner of the course"
        );

        //delete the course
        delete courses[_id];

        //delete the course from the owner
        uint256[] storage coursesOfOwner = ownerToCourses[_msgSender()];
        for (uint256 i = 0; i < coursesOfOwner.length; i++) {
            if (coursesOfOwner[i] == _id) {
                coursesOfOwner[i] = coursesOfOwner[coursesOfOwner.length - 1];
                coursesOfOwner.pop();
                break;
            }
        }
    }

    //change the price of a course
    function changeCoursePrice(uint256 _id, uint256 _newPrice) public {
        //check if the course exists
        require(courses[_id].id != 0, "Course does not exist");

        //check if the course belongs to the owner
        require(
            courses[_id].owner == _msgSender(),
            "You are not the owner of the course"
        );

        //change the price of the course
        courses[_id].price = _newPrice;
    }

    //add a buyer to the course
    function addBuyer(uint256 _id, address _buyer) public onlyOwner {
        //check if the course exists
        require(courses[_id].id != 0, "Course does not exist");

        //check if the course belongs to the owner
        require(
            courses[_id].owner == _msgSender(),
            "You are not the owner of the course"
        );

        //add the buyer to the course
        courses[_id].Buyers[_buyer] = true;

        //add the course to the buyer
        buyerToCourses[_buyer].push(_id);
    }

    //remove a buyer from the course
    function removeBuyer(uint256 _id, address _buyer) public onlyOwner {
        //check if the course exists
        require(courses[_id].id != 0, "Course does not exist");

        //check if the course belongs to the owner
        require(
            courses[_id].owner == _msgSender(),
            "You are not the owner of the course"
        );

        //remove the buyer from the course
        courses[_id].Buyers[_buyer] = false;

        //remove the course from the buyer
        uint256[] storage coursesOfBuyer = buyerToCourses[_buyer];
        for (uint256 i = 0; i < coursesOfBuyer.length; i++) {
            if (coursesOfBuyer[i] == _id) {
                coursesOfBuyer[i] = coursesOfBuyer[coursesOfBuyer.length - 1];
                coursesOfBuyer.pop();
                break;
            }
        }
    }

    //BUYER FUNCTIONS //

    //create a function to buy a course
    function buyCourse(uint256 _id, uint256 _pid) public payable {
        //check if the course exists
        require(courses[_id].id != 0, "Course does not exist");

        //check if the course belongs to the owner
        require(
            courses[_id].owner != _msgSender(),
            "You are the owner of the course"
        );

        if (_pid == 0 || _pid == 1) {
            TokenInfo storage tokens = AllowedCrypto[_pid];

            IERC20 paytoken;
            paytoken = tokens.paytoken;
            require(
                paytoken.balanceOf(_msgSender()) >= courses[_id].price,
                "You do not have enough balance to buy the course"
            );

            // //90% of the price goes to the course creator and 10% goes to the buidl platform
            uint256 creatorShare = (courses[_id].price * 90) / 100;
            // //push the amount generated to the course
            courses[_id].amountGeneratedStable += creatorShare;
            // //transfer the price to the contract owner

            //transfer courses[_id].price to the contract
            paytoken.transferFrom(
                _msgSender(),
                address(this),
                courses[_id].price
            );

            //transfer 90% of the price to the course creator
            paytoken.transfer(courses[_id].owner, creatorShare);
            //add the course to the buyer
            buyerToCourses[_msgSender()].push(_id);
            //add the buyer address to the buyers
            courses[_id].Buyers[_msgSender()] = true;
            //increment the course count
            courses[_id].courseCount += 1;
            

        }

        //if pid is 2 then execute this
        if (_pid == 2) {
            //get the price of the course using getcourseprice function
            uint256 coursePrice = getCoursePriceInETH(_id);

            //check if msg value is greater than or equal to the course price
            require(
                msg.value >= coursePrice,
                "You do not have enough balance to buy the course"
            );

            // //90% of the price goes to the course creator and 10% goes to the buidl platform
            uint256 creatorShare = (coursePrice * 90) / 100;
            // //push the amount generated to the course
            courses[_id].amountGeneratedMatic += creatorShare;

            // //transfer 90% of the price to the course creator
            payable(courses[_id].owner).transfer(creatorShare);

            //add the course to the buyer
            buyerToCourses[_msgSender()].push(_id);
            //add the buyer address to the buyers array
            courses[_id].Buyers[_msgSender()] = true;
            //increment the course count
            courses[_id].courseCount += 1;
            
        }
    }

    //calculate the price of the course in eth
    function getCoursePriceInETH(uint256 _id)
        public
        view
        returns (uint256 price)
    {
        //check if the course exists
        require(courses[_id].id != 0, "Course does not exist");

        //get the price of ETH in USD
        int256 ethPriceInUSD = getLatestPrice();
        // ethPriceInUSD has 8 decimals

        //get the price pf the course
        uint256 coursePriceInWEIusd = courses[_id].price;
        //coursePriceInWEIusd has 18 decimals

        //convert ethprice in usd to have 18 decimals
        uint256 ethPriceInUSD18 = uint256(ethPriceInUSD) * 10**10;

        //calculate the price of the course in ETH
        uint256 coursePriceInETH = (coursePriceInWEIusd * 10**18) /
            ethPriceInUSD18;

        return coursePriceInETH;
    }

    //GETTER FUNCTIONS //

    //create a function to get the course details
    function getCourse(uint256 _id)
        public
        view
        returns (
            address,
            string memory,
            uint256,
            uint256
        )
    {
        return (
            courses[_id].owner,
            courses[_id].name,
            courses[_id].price,
            courses[_id].id
        );
    }

    //create a function to get the courses of the buyer
    function getBuyerCourses() public view returns (uint256[] memory) {
        return buyerToCourses[_msgSender()];
    }

    //create a function to get the courses of the owner
    function getOwnerCourses() public view returns (uint256[] memory) {
        return ownerToCourses[_msgSender()];
    }

    function isBuyerOfCourseFromCourse(uint256 _id, address _buyer)
        public
        view
        returns (bool)
    {
        return courses[_id].Buyers[_buyer];
    }

    //check if the user has bought a specific course
    function isBuyerOfCourse(uint256 _id) public view returns (bool) {
        return courses[_id].Buyers[_msgSender()];
    }

    //WHITELIST FUNCTIONS //

    //create a function to whitelist course creators
    function whitelistCreator(address _courseCreator) public {
        whiteListCourseCreators[_courseCreator] = true;
    }

    //create a function to remove course creators from the whitelist
    function removeCreatorFromWhitelist(address _courseCreator)
        public
        onlyOwner
    {
        whiteListCourseCreators[_courseCreator] = false;
    }

    //create a function to check if the course creator is whitelisted
    function isCreatorWhitelisted(address _courseCreator)
        public
        view
        returns (bool)
    {
        return whiteListCourseCreators[_courseCreator];
    }

    //get current course count
    function getCourseCount() public view returns (uint256) {
        return courseCounter;
    }

    //ONLY OWNER FUNCTIONS//

    //create a function to withdraw the funds
    function withdraw(uint256 _pid) public onlyOwner {
        if (_pid == 0 || _pid == 1) {
            TokenInfo storage tokens = AllowedCrypto[_pid];
            IERC20 paytoken;
            paytoken = tokens.paytoken;
            paytoken.transfer(msg.sender, paytoken.balanceOf(address(this)));
        }
        if (_pid == 2) {
            payable(owner()).transfer(address(this).balance);
        }
    }
}