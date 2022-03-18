/**
 *Submitted for verification at polygonscan.com on 2022-03-17
*/

pragma solidity ^0.8.7;

interface AggregatorV3Interface{
    function latestAnswer() external view returns(uint);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ILottery {
    function viewCurrentLotteryId() external returns (uint256);
}

contract RandomGenerator is Ownable{

    address public lotteryContract;

    AggregatorV3Interface[] internal oracleFeeds;
    uint256 internal index;
    uint256 internal seed;
    uint256 public lastLotteryId;

    constructor(AggregatorV3Interface[] memory _oracleFeeds) {
        oracleFeeds = _oracleFeeds;
        uint _answer = oracleFeeds[index].latestAnswer();
        index = _answer % oracleFeeds.length;
    }

    function setLotteryContract(address _lottery) external onlyOwner {
        lotteryContract = _lottery;
    }

    /**
     * Returns the latest price
     */
    function getRandomNumber() external view returns (uint) {
        uint _index = index % oracleFeeds.length;
        uint val = oracleFeeds[_index].latestAnswer() + seed;
        val = uint32(1000000 + (val % 1000000));
        return val;
    }

    /**
    * update index
    */

    function updateIndex(uint _seed) external {
        require(msg.sender == address(lotteryContract), "Not lottery.");
        uint _index = (index + block.timestamp + _seed) % oracleFeeds.length;
        uint _answer = oracleFeeds[_index].latestAnswer();
        index += _answer % oracleFeeds.length;
        seed = _seed;
        lastLotteryId = ILottery(lotteryContract).viewCurrentLotteryId();
    }

    /**
     * @notice View lastLotteryId
     */
    function viewLatestLotteryId() external view returns (uint256) {
        return lastLotteryId;
    }
}