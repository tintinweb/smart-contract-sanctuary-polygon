/**
 *Submitted for verification at polygonscan.com on 2023-05-08
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

// File: contracts/FOMO.sol



pragma solidity ^0.8.6;


contract CyberFOMO is Ownable {
    
    address public immutable cyberMaster = 0xfd35157936dBdA64034D83eA93Fa6F861006fd03;
    address public mainContract;
    address public nftContract;

    uint256 public entryFee = 1 ether;
    uint256 public lastMinuteIncrement = 13;
    uint256 public normalIncrement = 18;
    bool public autoFeeCalculator = false;

    uint256 private gameCycle;
    uint256 private players;
    uint256 public timeOut;
    uint256 public prizePool;
    uint256 public cxcShare;
    uint256 public nftHolderShare;
    uint256 public cyberMasterShare;

    mapping(address=>uint256) public cxcPoints;
    mapping(uint256=>address[]) public playerByCycle;
    mapping(uint256=>uint256) public paidOutPrizeAmount;

    event FundIn(address from, uint256 amount, uint256 timestamp);
    event Winner(uint256 gameRound, address winner, uint256 rewardAmount);
    event FOMO(uint256 gameRound, uint256 playerCount, address player, uint256 amount, uint256 timestamp, uint256 timeLeft);

    receive() external payable {
        prizePool += (msg.value * 70 / 100);
        emit FundIn(msg.sender, msg.value, block.timestamp);
    }
    fallback() external payable {}

    constructor(
        address _nftContractAddr
    ) {
        nftContract = _nftContractAddr;
        gameCycle = 1;
        players = 1;
        timeOut = block.timestamp + 300;
        playerByCycle[gameCycle].push(msg.sender);
    }

    function joinFOMO() public payable {

        cxcShare += (msg.value * 5 / 100);
        nftHolderShare += (msg.value * 3 / 100);
        cyberMasterShare += (msg.value * 2 / 100);
        prizePool += (msg.value * 70 / 100);

        uint256 fee = entryFee;

        if (autoFeeCalculator == true) {
            if (prizePool >= 10000 ether) {
                fee = 100 ether;
            } else if (prizePool >= 1000 ether) {
                fee = 10 ether;
            } else {
                fee = 1 ether;
            }
        }

        require(msg.value >= fee, "Transaction value not enough to enter FOMO.");

        if (timeOut <= block.timestamp) {

            address winner = getWinner(gameCycle);
            (bool transferWinnerReward, ) = payable(winner).call{value: prizePool}("");
            require(transferWinnerReward, "Failed to transfer winner reward.");
            paidOutPrizeAmount[gameCycle] = prizePool;
            emit Winner(gameCycle, winner, prizePool);

            cxcPoints[winner] += players;
            prizePool = getBalance() - cxcShare - nftHolderShare - cyberMasterShare;

            gameCycle++;
            playerByCycle[gameCycle].push(msg.sender);
            players = 1;
            timeOut = block.timestamp + 300;

        } else {

            cxcPoints[msg.sender]++;
            playerByCycle[gameCycle].push(msg.sender);
            players++;
            if (timeLeft() > 280) {
                timeOut = block.timestamp + 300;
            } else if (timeLeft() < 60) {
                timeOut += lastMinuteIncrement;
            } else {
                timeOut += normalIncrement;  
            }

        }
        emit FOMO(gameCycle, players, msg.sender, msg.value, block.timestamp, timeLeft());    
    }

    function transferCXCPoints(address _to, uint256 _amount) external {
        require(cxcPoints[msg.sender] >= _amount, "Insufficient CXC points");
        cxcPoints[_to] += _amount;
        cxcPoints[msg.sender] -= _amount;
    }

    function updateEntryFee(uint256 newEntryFee) external onlyOwner {
        require(newEntryFee <= 200 ether, "Maximum entry fee cannot be higher than 200 MATIC.");
        entryFee = newEntryFee;
    }

    function updateTimeIncrement(uint256 normal, uint256 lastMinute) external onlyOwner {
        normalIncrement = normal;
        lastMinuteIncrement = lastMinute;
    }

    function setMainContract(address _mainContract) external onlyOwner {
        mainContract = _mainContract;
    }

    function setNFTContract(address _nftContract) external onlyOwner {
        nftContract = _nftContract;
    }

    function setAutoFee(bool _state) external onlyOwner {
        autoFeeCalculator = _state;
    }

    function distributeShare() external { 
        (bool transferMainContract, ) = payable(mainContract).call{value: cxcShare}("");
        require(transferMainContract, "Main contract transfer failed.");
        cxcShare = 0;

        (bool transferNFTHolder, ) = payable(nftContract).call{value: nftHolderShare}("");
        require(transferNFTHolder, "NFT contract transfer failed.");
        nftHolderShare = 0;

        (bool transferCyberMaster, ) = payable(cyberMaster).call{value: cyberMasterShare}("");
        require(transferCyberMaster, "Cyber Master transfer failed.");
        cyberMasterShare = 0;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getActualPool() public view returns(uint256) {
        return address(this).balance - cxcShare - nftHolderShare - cyberMasterShare;
    }

    function getWinnerReward() public view returns(uint256) {
        return prizePool;
    }

    function getGameCycle() public view returns(uint256) {
        return gameCycle;
    }

    function currentPlayers() public view returns(uint256) {
        return players;
    }

    function getTimeOut() public view returns(uint256) {
        return timeOut;
    }

    function timeLeft() public view returns(uint256) {
        if (timeOut <= block.timestamp) {
            return 0;
        } else {
            return timeOut - block.timestamp;
        }
    }

    function getWinner(uint256 round) public view returns(address) {
        uint256 last = playerByCycle[round].length;
        return playerByCycle[round][last-1];
    }

    function getWinnerRewardByRound(uint256 round) public view returns(uint256) {
        return paidOutPrizeAmount[round];
    }

    function getPlayersByRound(uint256 round) public view returns(address[] memory) {
        return playerByCycle[round];
    }
}