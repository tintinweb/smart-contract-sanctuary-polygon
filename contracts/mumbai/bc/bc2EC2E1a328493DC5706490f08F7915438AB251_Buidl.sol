//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MaticPrice.sol";

/**
 * @title Buidl Smart Contract for Courses Business
 * @dev Implementation of buying, selling, trasferring, deleting courses.
 * @dev Powered by https://buidlacademy.org/
 */

contract Buidl is Ownable, MaticPrice {
    
    /**
    * @dev Course Struct for saving courses information.
    * @param owner address The address of course creator.
    * @param name string The name of course.
    * @param id uint256 the id of course ordered by creation.
    * @param price uint256 the price of course in USD * 10^8 because it should be compatible with chainlink price.
    * @param amountGenerated uint256 the amount of fund for creator by course's sale
    * @param buyers address the list of buyers who bought the course.
    */

    struct Course {
        address owner;
        string name;
        uint256 id;
        uint256 price;
        uint256 amountGenerated;
        address[] buyers;
    }

    /**
    * @dev courseCounter the number of courses created 
    * @dev lastCourseId it will be different with courseCounter if there are some deletions of courses.
    */

    uint256 public courseCounter;
    uint256 public lastCourseId;

    mapping(uint256 => Course) public courses;
    mapping(address => uint256[]) public ownerToCourses;
    mapping(address => uint256[]) public buyerToCourses;
    mapping(address => bool) public whiteListCourseCreators;

    /**
    * @dev Transfer tokens from one address to another
    * @param _name string The course's name
    * @param _price uint256 The course's price
    */

    function createCourse(string memory _name, uint256 _price) external {
        
        require(
            whiteListCourseCreators[_msgSender()] == true,
            "You are not whitelisted to create courses"
        );

        lastCourseId++;
        courseCounter++;

        Course memory newCourse = Course({
            owner: _msgSender(),
            name: _name,
            id: lastCourseId,
            price: _price * 10**8,
            amountGenerated: 0,
            buyers: new address[](0)
        });

        courses[lastCourseId] = newCourse;
        ownerToCourses[_msgSender()].push(lastCourseId);
    }

    /**
    * @dev Edit the course with custom parameters by the creator.
    * @param _courseId uint256 The order number that course created in.
    * @param _name string The name what the creator want to change.
    * @param _price uint256 The price what the creator want to change.
    */

    function editCourse(uint256 _courseId, string memory _name, uint256 _price) external {
        
        require(courses[_courseId].id != 0, "Course does not exist");

        require(
            _msgSender() == courses[_courseId].owner,
            "You are not the owner of the course"
        );

        courses[_courseId].name  = _name;
        courses[_courseId].price = _price * 10**8;
    }

    /**
    * @dev Delete the course by course id
    * @param _courseId uint256 The order number that course created in.
    */

    function deleteCourse(uint256 _courseId) external {

        require(courses[_courseId].id != 0, "Course does not exist");
        
        require(
            _msgSender() == courses[_courseId].owner,
            "You are not the owner of the course"
        );

        require(courses[_courseId].id != 0, "Courses does not exist");

        
        
        uint256[] storage coursesOfOwner = ownerToCourses[_msgSender()];
        
        for(uint256 i = 0; i < coursesOfOwner.length; i ++) {
            if(coursesOfOwner[i] == _courseId) {
                coursesOfOwner[i] = coursesOfOwner[coursesOfOwner.length - 1];
                coursesOfOwner.pop();
                break;
            }
        }

        for(uint256 i = 0; i < courses[_courseId].buyers.length; i++) {
            address currentBuyer = courses[_courseId].buyers[i];
            uint256[] storage coursesOfBuyer = buyerToCourses[currentBuyer];
            for(uint256 j = 0; j < coursesOfBuyer.length; j++) {
                if(coursesOfBuyer[j] == _courseId) {
                    coursesOfBuyer[j] = coursesOfBuyer[coursesOfBuyer.length - 1];
                    coursesOfBuyer.pop();
                }
            }
        }

        courseCounter--;
        delete courses[_courseId];
    }

    /**
    * @dev Transfer the course ownership
    * @param _courseId uint256 The order number that course created in.
    * @param _newOwner address The new owner address of course
    */

    function transferCourseOwnership(uint256 _courseId, address _newOwner) external {

        require(courses[_courseId].id != 0, "Course does not exist");

        require(
            _msgSender() == courses[_courseId].owner,
            "You are not the owner of the course"
        );

        delete ownerToCourses[courses[_courseId].owner];
        
        courses[_courseId].owner = _newOwner;
        ownerToCourses[_newOwner].push(_courseId);
    }

    /**
    * @dev Buy the course with polygon native coin - Matic
    * @param _courseId uint256 The order number that course created in.
    */

    function buyCourseWithMatic(uint256 _courseId) external payable {

        require(courses[_courseId].id != 0, "Course does not exist");

        require (
            _msgSender() != courses[_courseId].owner,
            "You are the owner of the course"
        );

        uint256 receiveValue = uint256(getLatestPrice()) * msg.value / 10**10;

        require(
            courses[_courseId].price <= receiveValue,
            "The price of the course is not bigger than the msg.value"
        );

        uint256 amountForOwner = (msg.value * 90) / 100;
        buyerToCourses[_msgSender()].push(_courseId);
        courses[_courseId].buyers.push(_msgSender());
        courses[_courseId].amountGenerated += amountForOwner;

        payable(courses[_courseId].owner).transfer(amountForOwner);
    }

    /**
    * @dev Buy the course with Stable Coins that have 1 USD worth such as USDT, USDC, DAI
    * @param _courseId uint256 The order number that course created in.
    * @param _token address The address of Stable Coin
    */

    function buyCourseWithStableCoin(uint256 _courseId, address _token) external {

        require(courses[_courseId].id != 0, "Course does not exist");

        require (
            _msgSender() != courses[_courseId].owner,
            "You are the owner of the course"
        );

        require(
            courses[_courseId].price / 10**2 <= IERC20(_token).balanceOf(_msgSender()),
            "Insuffient Funds to buy this course"
        );

        uint256 amountForOwner = (courses[_courseId].price * 90) / 100;

        buyerToCourses[_msgSender()].push(_courseId);
        courses[_courseId].buyers.push(_msgSender());
        courses[_courseId].amountGenerated += amountForOwner;

        IERC20(_token).transferFrom(_msgSender(), courses[_courseId].owner, amountForOwner);
    }

    /**
    * @dev The Function to add the creator address to create and manage new course
    * @param _courseCreator address The address of whitelisted user
    */

    function addCreatorToWhitelist(address _courseCreator) external onlyOwner {
        whiteListCourseCreators[_courseCreator] = true;
    }

    /**
    * @dev The Function to delete the whitelisted creator address
    * @param _courseCreator address The address of whitelisted user
    */

    function removeCreatorFromWhitelist(address _courseCreator) external onlyOwner {
        whiteListCourseCreators[_courseCreator] = false;
    }

    /**
    * @dev The Function to check the whitelisted user.
    * @param _courseCreator address The address to check.
    */

    function isCreatorWhitelisted(address _courseCreator) external view returns(bool) {
        return whiteListCourseCreators[_courseCreator];
    }

    /**
    * @dev Withdraw the contract balance for Buidl community development with Matic
    * @param _amount uint256 The amount to withdraw
    */

    function withdrawMaticForBuidl(uint256 _amount) external onlyOwner {

        require(address(this).balance != 0, "Balance is zero");
        
        payable(_msgSender()).transfer(_amount * 10**18);
    }

    /**
    * @dev Withdraw the contract balance for Buidl community development with Stable Coins that have 1 USD worth such as USDT, USDC, DAI
    * @param _amount uint256 The amount to withdraw.
    * @param _token address The address of Stable Coin.
    */

    function withdrawStableCoinForBuidl(uint256 _amount, address _token) external onlyOwner {

        require(
            IERC20(_token).balanceOf(address(this)) >= _amount,
            "Insufficient Funds to withdraw from smart contract"
        );

        IERC20(_token).transfer(_msgSender(), _amount);
    }

    /**
    * @dev Represent the number of deleted courses.
    */

    function numberOfDeletedCourses() external view returns(uint256) {
        return lastCourseId - courseCounter;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MaticPrice {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Mumbai
     * Aggregator: MATIC/USD
     * Address: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
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