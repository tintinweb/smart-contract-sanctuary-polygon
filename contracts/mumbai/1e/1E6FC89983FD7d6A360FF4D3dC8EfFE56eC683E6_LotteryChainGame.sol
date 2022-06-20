/**
 *Submitted for verification at polygonscan.com on 2022-06-20
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

// File: LotteryChainProject/LotteryChainGame.sol


pragma solidity >= 0.7.0 < 0.9.0;



interface LotteryChainTokenInterface {
    function balanceOf(address account) external view returns (uint256);
    function burnToken (address _who, uint256 _amount, uint256 _decimals) external;
    function claimToken (address _who, uint256 _amount, uint256 _decimals) external;
}

contract LotteryChainGame is Ownable {

    address lotteryChainAddress = 0xfdB0d64f1dcbAa9B92e5c2a4d6050b920082f9be;
    LotteryChainTokenInterface lotteryChainTokenInstance = LotteryChainTokenInterface(lotteryChainAddress);

    uint256 public allPlayers = 0;

    mapping (address => bool) public isParticipant;

    address [] public participantsAddresses;

    uint256 public priceToEnter = 3 ether;
    uint256 public tokensToEnter = 3;
    uint256 public decimalsTokensToEnter = 18;

    uint256 amount = 0;

    uint256 public startAt = 2;
    uint256 public numberOfWinners = 1;

    bool public isAvailable = true;
    bool public isPaused = false;
    bool public canApplySettings = false;

    uint256 [] public percentagesToWinners = [50];

    uint256 public tokensToClaim = 1;
    uint256 public decimalsTokensToClaim = 18;

    address [] public lastWinnersAddresses;
    mapping (address => uint256) public lastWinnersProfits;

    mapping(uint256 => bool) public isExtracted;


    modifier canEnter (address _user) {
        require(isAvailable);
        require(!isParticipant[_user]);
        _;
    }


    // ##### Game Functions #####
    function enterToLottery () public payable canEnter (msg.sender) {
        require(msg.value >= priceToEnter);
        isParticipant[msg.sender] = true;
        participantsAddresses.push(msg.sender);

        allPlayers++;

        amount += priceToEnter;

        if(participantsAddresses.length == startAt){
            isAvailable = false;
            startLottery();
        }
    }


    function enterToLotteryWithTokens() public canEnter (msg.sender) {
        require(lotteryChainTokenInstance.balanceOf(msg.sender) >= tokensToEnter * 10 ** decimalsTokensToEnter);
        lotteryChainTokenInstance.burnToken(msg.sender, tokensToEnter, decimalsTokensToEnter);
        isParticipant[msg.sender] = true;
        participantsAddresses.push(msg.sender);

        allPlayers++;

        amount += priceToEnter;

        if(participantsAddresses.length == startAt){
            isAvailable = false;
            startLottery();
        }
    }


    function startLottery () public {
        require(participantsAddresses.length == startAt || msg.sender == owner());

        uint256 counter = 0;
        uint256 [] memory extractedValues = new uint256 [](numberOfWinners);

        for(uint256 i = 0; i<lastWinnersAddresses.length; i++){
            delete lastWinnersProfits[lastWinnersAddresses[i]];
        }
        delete lastWinnersAddresses;


        while(lastWinnersAddresses.length < numberOfWinners) {
            uint256 randomValue = random();
            if(!isExtracted[randomValue]){
                isExtracted[randomValue] = true;
                extractedValues[counter] = randomValue;
                counter ++;
                lastWinnersAddresses.push(participantsAddresses[randomValue]);
            }
        }


        // Give profits
        for(uint256 i = 0; i<lastWinnersAddresses.length; i++){
            uint256 profit = amount / 100 * percentagesToWinners[i];
            lastWinnersProfits[lastWinnersAddresses[i]] = profit;
            payable(lastWinnersAddresses[i]).transfer(profit);
            lotteryChainTokenInstance.claimToken(lastWinnersAddresses[i], tokensToClaim, decimalsTokensToClaim);
        }


        if(isPaused){
            isAvailable = false;
            canApplySettings = true;
        } else {
            isAvailable = true;
        }

        //restore default values
        
        for(uint256 i = 0; i<participantsAddresses.length; i++){
            delete isParticipant[participantsAddresses[i]];
        }
        delete participantsAddresses;

        for(uint256 i = 0; i<extractedValues.length; i++) {
            delete isExtracted[extractedValues[i]];
        }
    }


    function restartLottery() public onlyOwner {
        isAvailable = true;
        isPaused = false;
        canApplySettings = false;
    }


    function random() internal view returns (uint256) {  
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % participantsAddresses.length;
    }


    // ##### Settings Functions ######
    function setPrices (uint256 _maticAmount, uint256 _tokensToEnter, uint256 _decimalsTokens) public onlyOwner {
        require(canApplySettings);
        priceToEnter = _maticAmount;
        tokensToEnter = _tokensToEnter;
        decimalsTokensToEnter = _decimalsTokens;
    }


    function setPrices (uint256 _tokensToClaim, uint256 _decimalsTokensToClaim) public onlyOwner {
        require(canApplySettings);
        tokensToClaim = _tokensToClaim;
        decimalsTokensToClaim = _decimalsTokensToClaim;
    }


    function setStartWinners (uint256 _startAt, uint256 _numberOfWinners) public onlyOwner {
        require(canApplySettings);
        startAt = _startAt;
        numberOfWinners = _numberOfWinners;
    }


    function setPercentagesToWinners (uint256 [] memory _newPercentages) public onlyOwner {
        require(canApplySettings);
        require(_newPercentages.length == numberOfWinners);

        delete percentagesToWinners;

        for(uint256 i = 0; i<_newPercentages.length; i++){
            percentagesToWinners.push(_newPercentages[i]);
        }
    }


    function setPaused(bool _isPaused) public onlyOwner {
        isPaused = _isPaused;
    }


    function withdraw () public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}