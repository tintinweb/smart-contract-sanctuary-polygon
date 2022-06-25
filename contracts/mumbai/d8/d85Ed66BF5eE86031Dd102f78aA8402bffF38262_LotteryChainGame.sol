/**
 *Submitted for verification at polygonscan.com on 2022-06-24
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

// File: contracts/LotteryChain/LotteryChainGame.sol


pragma solidity >= 0.7.0 < 0.9.0;



interface LotteryChainTokenInterface {
    function balanceOf(address account) external view returns (uint256);
    function burnToken (address _who, uint256 _amount, uint256 _decimals) external;
    function claimToken (address _who, uint256 _amount, uint256 _decimals) external;
}

interface LotteryBalanceInterface {
    function claimTokensForWinners(address [] memory winnersAddresses, uint256 percentageForEvolveLiquidity) external;
    function transferBalance() external payable;
}

interface GenericContractRewardInterface {
    function claimTokensForWinners(address [] memory winnersAddresses) external;
}

contract LotteryChainGame is Ownable {

    address lotteryChainTokenAddress = 0xa2B5Fa2dFE5f6FA5c6669535882aDe911B6Fbf4E;
    LotteryChainTokenInterface lotteryChainTokenInstance = LotteryChainTokenInterface(lotteryChainTokenAddress);

    address lotteryBalanceAddress = 0xFfEB93a6B7df29Da7Efd03c5e399B44e70c988c3;
    LotteryBalanceInterface lotteryBalanceInstance = LotteryBalanceInterface(lotteryBalanceAddress);

    address genericContractAddress;
    GenericContractRewardInterface genericContractRewardInstance;
    bool genericIsSetted = false;

    mapping (address => bool) public isParticipant;

    address [] public participantsAddresses;

    uint256 public priceToEnter = 1 ether;
    uint256 public tokensToEnter = 3;
    uint256 public decimalsTokensToEnter = 18;

    uint256 amount = 0;

    uint256 public startAt = 3;
    uint256 public numberOfWinners = 1;

    bool public isAvailable = true;
    bool public isPaused = false;
    bool public canApplySettings = false;

    uint256 public percentageToWinners = 75;

    uint256 public tokensToClaim = 1;
    uint256 public decimalsTokensToClaim = 18;

    uint256 percentageForEvolveLiquidity = 10;

    address [] public lastWinnersAddresses = [
        0xBAb15eBE906A5a52cA50Fa03bFCD1397C6c40072,
        0xBAb15eBE906A5a52cA50Fa03bFCD1397C6c40072,
        0xBAb15eBE906A5a52cA50Fa03bFCD1397C6c40072
        ];

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
        uint256 profit = amount / 100 * percentageToWinners;

        uint256 amountForEvolveLiquidity = 0 wei;

        uint256 priceToEnterInWei = priceToEnter * 10 ** 18;

        amountForEvolveLiquidity = ((numberOfWinners * priceToEnterInWei) / 100 * percentageForEvolveLiquidity);

        for(uint256 i = 0; i<lastWinnersAddresses.length; i++){
            
            payable(lastWinnersAddresses[i]).transfer(profit / numberOfWinners);
            lotteryChainTokenInstance.claimToken(lastWinnersAddresses[i], tokensToClaim, decimalsTokensToClaim);
        }


        if(isPaused){
            isAvailable = false;
            canApplySettings = true;
        } else {
            isAvailable = true;
        }

        //restore default values
        
        amount = 0;

        for(uint256 i = 0; i<participantsAddresses.length; i++){
            delete isParticipant[participantsAddresses[i]];
        }
        delete participantsAddresses;

        for(uint256 i = 0; i<extractedValues.length; i++) {
            delete isExtracted[extractedValues[i]];
        }

        transferToBalance();

        if(!genericIsSetted){
            lotteryBalanceInstance.claimTokensForWinners(lastWinnersAddresses, amountForEvolveLiquidity);
        } else {
            genericContractRewardInstance.claimTokensForWinners(lastWinnersAddresses);
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


    function getLastWinnersAddresses() public view returns(address [] memory){
        return lastWinnersAddresses;
    }


    function getLotterySettings(address user) public view returns(uint256 [] memory){

        uint256 [] memory settings = new uint256[](9);

        settings[0] = priceToEnter;
        settings[1] = tokensToEnter;
        settings[2] = participantsAddresses.length;
        settings[3] = startAt;
        settings[4] = amount * percentageToWinners / 100;
        settings[5] = tokensToClaim;
        settings[6] = decimalsTokensToClaim;
        settings[7] = numberOfWinners;
        settings[8] = (isParticipant[user]) ? 1 : 0;

        return settings;
    }


    // ##### Settings Functions ######
    function setPrices (uint256 _maticAmount, uint256 _tokensToEnter, uint256 _decimalsTokens) public onlyOwner {
        require(canApplySettings);
        priceToEnter = _maticAmount;
        tokensToEnter = _tokensToEnter;
        decimalsTokensToEnter = _decimalsTokens;
    }


    function setTokensPrices (uint256 _tokensToClaim, uint256 _decimalsTokensToClaim) public onlyOwner{
        require(canApplySettings);
        tokensToClaim = _tokensToClaim;
        decimalsTokensToClaim = _decimalsTokensToClaim;
    }


    function setStartWinners (uint256 _startAt, uint256 _numberOfWinners) public onlyOwner {
        require(canApplySettings);
        startAt = _startAt;
        numberOfWinners = _numberOfWinners;
    }


    function setPercentagesToWinners (uint256 _newPercentage) public onlyOwner {
        require(canApplySettings);

        percentageToWinners = _newPercentage;
    }


    function setPaused(bool _isPaused) public onlyOwner {
        isPaused = _isPaused;
    }


    function setGenericContractReward (address _newContractAddress) public onlyOwner {
        require(canApplySettings);
        genericContractAddress = _newContractAddress;
        genericContractRewardInstance = GenericContractRewardInterface(genericContractAddress);
        genericIsSetted = true;
    }


    function removeGenericContractReward () public onlyOwner {
        require(canApplySettings);
        genericIsSetted = false;
    }


    function setPercentagesForEvolveLiquidity (uint256 _newPerc) public onlyOwner {
        percentageForEvolveLiquidity = _newPerc;
    }


    // ########## Manage Finance ##########
    function transferToBalance() internal {
        lotteryBalanceInstance.transferBalance{value: (address(this).balance)}();
    }
}