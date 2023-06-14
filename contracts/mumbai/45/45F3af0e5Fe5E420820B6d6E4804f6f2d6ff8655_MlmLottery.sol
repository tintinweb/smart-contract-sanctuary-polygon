// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IUSDT {
    function transferFrom(address _from, address _to, uint _value) external;
    function allowance(address _owner, address _spender) external returns (uint remaining);
}

interface ITicketNFT {
    function safeMint(address _user) external;
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external returns (address);
}

contract MlmLottery is Ownable {

    /**
    * @notice Struct - UserInfo
    * @param numberOfWonCyclesInRow Count of won cycles in a row.
    * @param lastWonCycle Number of last won cycle.
    * @param soldTicketsCount Count of bought tickets by his referrals.
    * @param ticketsArr Array of user's bought tickets.
    * @param referralsCount Count of invited users aka Referrals.
    * @param addressId ID of the user.
    */
    struct UserInfo{
        uint256 numberOfWonCyclesInRow;
        uint256 lastWonCycle;
        uint256 soldTicketsCount; 
        uint256[] ticketsArr; 
        uint256 referralsCount; 
        uint256 addressId; 
    }

    uint256 public numberOfTickets;
    uint256 public numberOfSoldTickets;
    uint256 public ticketPrice; // set in wei
    uint256 public usersCount;
    uint256 public cycleCount;
    uint256 public monthlyJackpotStartTimestamp;
    address public tetherAddress;
    address public bankAddress;
    address public ticketNFTAddress;
    address public lastMonthlyJackpotWinner;
    // All winning amounts are in USD (wei)
    uint256 public monthlyJackpotWinningAmount;
    // 0 index is jackpotWinningAmount, 1: top16Winners, 2: top62Winners, 3: top125Winners;
    uint256[4] public winningAmounts; 
    // 0 index is bonusForReferrals, 1: bonusForSoldTickets, 2: bonusForWinningInRow, 3: bonusForBoughtTickets
    // 4: refferalsCountForBonus, 5: soldTicketsCountForBonus, 6: winningInRowCountForBonus, 7: boughtTicketCountForBonus;
    uint256[8] public bonusParameters; 
    //0 index is the percentage of 1st parent, 1: 2rd parent, 2: 3rd parent 
    uint256[3] public parentsPercentages;
    // boolean for checking cycle activness
    bool public isCycleActive;

    mapping(uint256 => address) ticketNumberToAddress;
    mapping(address => address) addressToHisReferrer; // Referrer is higher in the tree
    mapping(uint256 => address) idToHisAddress; // ID is for referral system, user can invite other users by his id
    mapping(uint256 => bool) ticketUniqueness;
    mapping(address => UserInfo) userInfo;
    uint256[] private winningTickets;

    //events
    event TicketBought(address indexed buyer, uint256 indexed count, uint256 indexed timestamp);
    event TicketNumberSet(uint256 indexed ticketNumber, uint256 indexed timestamp);
    event TicketPriceSet(uint256 indexed ticketPrice, uint256 indexed timestamp);
    event BankAddressSet(address indexed bank, uint256 indexed timestamp);
    event TicketNFTAddressSet(address indexed NFTAddress, uint256 indexed timestamp);
    event StableCoinAddressSet(address indexed NFTAddress, uint256 indexed timestamp);
    event NewCycleStarted(address indexed caller, uint256 cycleCount, uint256 indexed timestamp);
    event WinnersRewarded(address indexed caller, uint256 indexed timestamp);
    event MonthlyJackpotExecuted(address indexed winner, uint256 indexed newJackpotStartingTime);

    receive() external payable {}

    fallback() external payable {}

    /**
    * @notice Modifier - activeCycle
    * @dev Ensures that the current lottery cycle is active before allowing function execution.
    * @dev Apply this modifier to functions in the MlmLottery contract that require an active cycle.
    */
    modifier activeCycle(){
        require(isCycleActive, "MlmLottery:: Currently you can not buy new tickets");
        _;
    }
    
    constructor() {
        usersCount = 1;
        monthlyJackpotStartTimestamp = block.timestamp;
    }

    /**
    * @notice Allows users to purchase a specified number of tickets for the ongoing lottery cycle.
    * @dev Requires an active lottery cycle as enforced by the activeCycle modifier.
    * @param _countOfTickets The number of tickets to be purchased by the user.
    * @param _refId The reference ID associated with the user's ticket purchase.
    * @dev Call this function to buy tickets during an active lottery cycle.
    */
    function buyTickets(uint256 _countOfTickets, uint256 _refId) external activeCycle{
        require(_countOfTickets > 0, "MlmLottery:: Count of tickets can not be 0");
        require(IUSDT(tetherAddress).allowance(msg.sender, address(this)) >= ticketPrice * _countOfTickets, "MlmLottery:: User has not given enough allowance"); //Checking Allowance in USDT Contract
        require((numberOfSoldTickets + _countOfTickets) <=  numberOfTickets * cycleCount, "MlmLottery:: tickets count + sold tickets count must be smaller than number of available tickets");
        require(!(addressToHisReferrer[msg.sender] != address(0) && idToHisAddress[_refId] != addressToHisReferrer[msg.sender]),"MlmLottery:: your referrer is already set and it is another user"); //checking refid
        uint256 leftAmount = ticketPrice * _countOfTickets;

        if(userInfo[msg.sender].ticketsArr.length == 0){
            userInfo[msg.sender].addressId = usersCount;
            idToHisAddress[usersCount] = msg.sender;
            ++usersCount;
        }

        if(_refId > 0 && addressToHisReferrer[msg.sender] == address(0)){
            address referrer = idToHisAddress[_refId];
            addressToHisReferrer[msg.sender] = referrer;
            ++userInfo[referrer].referralsCount;
            referralCountBonus(referrer);
        }

        for(uint256 i = 1; i <= _countOfTickets; ++i){
            ++numberOfSoldTickets;
            userInfo[msg.sender].ticketsArr.push(numberOfSoldTickets);
            ITicketNFT(ticketNFTAddress).safeMint(msg.sender);
            ticketNumberToAddress[numberOfSoldTickets] = msg.sender; //  can be removed
        }
        boughtTicketsCountBonus(msg.sender);

        //logic of rewarding referrer
        if(addressToHisReferrer[msg.sender] != address(0)){
            userInfo[addressToHisReferrer[msg.sender]].soldTicketsCount += _countOfTickets;
            soldTicketsCountBonus(addressToHisReferrer[msg.sender]);
            if(userInfo[addressToHisReferrer[msg.sender]].soldTicketsCount >= 5){
                leftAmount = leftAmount - leftAmount / 10;
                IUSDT(tetherAddress).transferFrom(msg.sender, addressToHisReferrer[msg.sender], leftAmount / 10);
            } else {
                leftAmount = leftAmount - leftAmount / 20;
                IUSDT(tetherAddress).transferFrom(msg.sender, addressToHisReferrer[msg.sender], leftAmount / 20);   
            }
        }
        IUSDT(tetherAddress).transferFrom(msg.sender, bankAddress, leftAmount);

        if(numberOfSoldTickets % numberOfTickets == 0){
            isCycleActive = false;
        }

        emit TicketBought(msg.sender, _countOfTickets, block.timestamp);
    }

    /**
    * @notice Function - setTicketsNumber
    * @dev Sets the number of tickets for the lottery cycle.
    * @param _numberOfTickets The new number of tickets to be set.
    * @dev Only the contract owner can execute this function.
    */
    function setTicketsNumber(uint256 _numberOfTickets) external onlyOwner{
        numberOfTickets = _numberOfTickets;
        emit TicketNumberSet(_numberOfTickets, block.timestamp);
    }

    /**
    * @notice Function - setTicketPrice
    * @dev Sets the price of the ticket for the lottery cycle.
    * @param _ticketPrice The new price of tickets to be set.
    * @dev Only the contract owner can execute this function.
    */
    function setTicketPrice(uint256 _ticketPrice) external onlyOwner{
        ticketPrice = _ticketPrice;
        emit TicketPriceSet(_ticketPrice, block.timestamp);
    }

    /**
    * @notice Function - setBankAddress
    * @dev Sets the address of the Bank.
    * @param _bank The new address of the Bank.
    * @dev Only the contract owner can execute this function.
    */
    function setBankAddress(address _bank) external onlyOwner{
        bankAddress = _bank;
        emit BankAddressSet(_bank, block.timestamp);
    }

    /**
    * @notice Function - setTicketNFTAddress
    * @dev Sets the address of the NFT contract.
    * @param _ticketAddress The new address of the NFT tickets.
    * @dev Only the contract owner can execute this function.
    */
    function setTicketNFTAddress(address _ticketAddress) external onlyOwner{
        ticketNFTAddress = _ticketAddress;
        emit TicketNFTAddressSet(_ticketAddress, block.timestamp);
    }

    /**
    * @notice Function - setStableCoinAddress
    * @dev Sets the address of the Stable coin.
    * @param _tokenAddress The new address of the Stable coin.
    * @dev Only the contract owner can execute this function.
    */
    function setStableCoinAddress(address _tokenAddress) external onlyOwner{
        tetherAddress = _tokenAddress;
        emit StableCoinAddressSet(_tokenAddress, block.timestamp);
    }

    /**
    * @notice Function - setWinningAmounts
    * @dev Sets the winning amount in WEI for each type.
    * @param _amounts The new winning amounts.
    * @dev Only the contract owner can execute this function.
    */
    function setWinningAmounts(uint256[4] memory _amounts) external onlyOwner{
        winningAmounts = _amounts;
    }

    /**
    * @notice Function - setTsetMonthlyWinningAmounticketPrice
    * @dev Sets the new winning amount in WEI.
    * @param _amount The new winning amount for month.
    * @dev Only the contract owner can execute this function.
    */
    function setMonthlyWinningAmount(uint256 _amount) external onlyOwner{
        monthlyJackpotWinningAmount = _amount;
    }

    /**
    * @notice Function - setParentsRewardPercentages
    * @dev Sets the Referrer(Parent) reward percentages for each parent type.
    * @param _percentages The new reward percentages.
    * @dev Only the contract owner can execute this function.
    */
    function setParentsRewardPercentages(uint256[3] memory _percentages) external onlyOwner{
        parentsPercentages = _percentages;
    }

    /**
    * @notice Function - setBonusVaraiablesValues
    * @dev Sets the bonus rewards in wei and, conditional counts to get bonuses.
    * @param _bonusParametres The new bonus system parametres.
    * @dev Only the contract owner can execute this function.
    */
    function setBonusVaraiablesValues(uint256[8] memory _bonusParametres) external onlyOwner{
        bonusParameters = _bonusParametres;
    }
    
    /**
    * @notice Function - monthlyJackpotExecuting
    * @dev Executes the monthly Jackot.
    * @dev Only the contract owner can execute this function.
    */
    function monthlyJackpotExecuting() external onlyOwner{
        require(monthlyJackpotStartTimestamp + 30 days <= block.timestamp ,"MlmLottery:: You can call monthlyJackpotExecuting function once in a month!");
        monthlyJackpotStartTimestamp = block.timestamp;
        address winner = idToHisAddress[getRandomNumberForMonthlyJackpot()];
        lastMonthlyJackpotWinner = winner;
        IUSDT(tetherAddress).transferFrom(bankAddress, winner, monthlyJackpotWinningAmount);
        emit MonthlyJackpotExecuted(winner, monthlyJackpotStartTimestamp);
    }

    /**
    * @notice Function - startNewCycle
    * @dev Starts new cycle, after deleting old winning tickets and incrementing cycle count.
    * @dev Only the contract owner can execute this function.
    */
    function startNewCycle() external onlyOwner{ 
        delete winningTickets;
        isCycleActive = true;
        ++cycleCount;
        emit NewCycleStarted(msg.sender, cycleCount, block.timestamp);
    }

    /**
    * @notice Function - referralCountBonus
    * @dev Checks conditions to send bonus for invited refferals.
    * @param _bonusWinner The Address of expected bonus winner.
    */
    function referralCountBonus(address _bonusWinner) private {
        if(userInfo[_bonusWinner].soldTicketsCount % bonusParameters[5] == 0)
            IUSDT(tetherAddress).transferFrom(bankAddress, _bonusWinner, bonusParameters[0]);
    }

    /**
    * @notice Function - soldTicketsCountBonus
    * @dev Checks conditions to send bonus for sold tickets.
    * @param _bonusWinner The Address of expected bonus winner.
    */
    function soldTicketsCountBonus(address _bonusWinner) private {
        if(userInfo[_bonusWinner].referralsCount % bonusParameters[4] == 0)
            IUSDT(tetherAddress).transferFrom(bankAddress, _bonusWinner, bonusParameters[1]);
    }

    /**
    * @notice Function - boughtTicketsCountBonus
    * @dev Checks conditions to send bonus for bought tickets.
    * @param _bonusWinner The Address of expected bonus winner.
    */
    function boughtTicketsCountBonus(address _bonusWinner) private {
        if(userInfo[_bonusWinner].ticketsArr.length % bonusParameters[7] == 0)
            IUSDT(tetherAddress).transferFrom(bankAddress, _bonusWinner, bonusParameters[3]);
    }

    /**
    * @notice Function - winningInRowBonus
    * @dev Checks conditions to send bonus for winning in a Row.
    * @param _bonusWinner The Address of expected bonus winner.
    */
    function winningInRowBonus(address _bonusWinner) private {
        if(userInfo[_bonusWinner].numberOfWonCyclesInRow == bonusParameters[6])
            IUSDT(tetherAddress).transferFrom(bankAddress, _bonusWinner, bonusParameters[2]);
    }

    /**
    * @notice Function - rewardWinners
    * @dev After selling all 777 tickets owner calls this function to distribute rewards.
    * @dev Only the contract owner can execute this function.
    */
    function rewardWinners() external onlyOwner {
        require(isCycleActive == false, "MlmLottery:: You can call rewardWinners function only after quiting cycle");
        getRandomNumbers();
        for(uint256 i; i < 204; ++i) {
            if(i == 0){
                rewardingReferrers(winningAmounts[0], ticketNumberToAddress[winningTickets[i]]);
            }
            else if(i > 0 && i < 17){
                rewardingReferrers(winningAmounts[1], ticketNumberToAddress[winningTickets[i]]);
            }
            else if(i >= 17 && i < 79){
                rewardingReferrers(winningAmounts[2], ticketNumberToAddress[winningTickets[i]]);
            }
            else if(i >= 79 && i < 204){
                rewardingReferrers(winningAmounts[3], ticketNumberToAddress[winningTickets[i]]);
            }

            if(cycleCount > userInfo[ticketNumberToAddress[winningTickets[i]]].lastWonCycle){
                if(cycleCount - userInfo[ticketNumberToAddress[winningTickets[i]]].lastWonCycle == 1) {
                    userInfo[ticketNumberToAddress[winningTickets[i]]].numberOfWonCyclesInRow++;
                    if(userInfo[ticketNumberToAddress[winningTickets[i]]].numberOfWonCyclesInRow == bonusParameters[6]){
                        winningInRowBonus(ticketNumberToAddress[winningTickets[i]]);
                        userInfo[ticketNumberToAddress[winningTickets[i]]].numberOfWonCyclesInRow = 0;
                    }
                }
                else {
                    userInfo[ticketNumberToAddress[winningTickets[i]]].numberOfWonCyclesInRow = 1;
                }
                userInfo[ticketNumberToAddress[winningTickets[i]]].lastWonCycle = cycleCount;
            }   
        }
        emit WinnersRewarded(msg.sender, block.timestamp);
    }

    /**
    * @notice Function - rewardingReferrers
    * @dev Checking if winner is in MLM structure, and after it distribute rewards to his referrers.
    * @param _winningAmount Reward of winner.
    * @param _winnerAddress The Address of winner.
    * @dev Only the contract owner can execute this function.
    */
    function rewardingReferrers(uint256 _winningAmount, address _winnerAddress) private {
        address temp = addressToHisReferrer[_winnerAddress];
        uint256 winningAmountDecriminated = _winningAmount; 
        for(uint8 j; j < 3; ++j) {
            if(temp == address(0))
                break;
            if(j == 0){
                IUSDT(tetherAddress).transferFrom(bankAddress, temp, (_winningAmount * parentsPercentages[0]) / 100);
                winningAmountDecriminated -= (_winningAmount * parentsPercentages[0]) / 100;
            } 
            if(j == 1){
                IUSDT(tetherAddress).transferFrom(bankAddress, temp, (_winningAmount * parentsPercentages[1]) / 100);
                winningAmountDecriminated -= (_winningAmount * parentsPercentages[1]) / 100;
            } 
            if(j == 2){
                IUSDT(tetherAddress).transferFrom(bankAddress, temp, (_winningAmount * parentsPercentages[2]) / 100);
                winningAmountDecriminated -= (_winningAmount * parentsPercentages[2]) / 100;
            } 
            temp = addressToHisReferrer[temp];
        }
        IUSDT(tetherAddress).transferFrom(bankAddress, _winnerAddress, winningAmountDecriminated); 
    }

    /**
    * @notice Function - getRandomNumbers
    * @dev Generating random numbers on chain for getting winning tickets (777 lottery).
    */
    function getRandomNumbers() private {
        uint16 i;
        uint256 ticketNumber;
        while(winningTickets.length < 204){
            ++i;
            ticketNumber = (cycleCount - 1) * numberOfTickets + uint256(keccak256(abi.encodePacked(block.timestamp+i,block.prevrandao, msg.sender))) % numberOfTickets + 1;
            if(!(ticketUniqueness[ticketNumber])){
                ticketUniqueness[ticketNumber] = true;
                winningTickets.push(ticketNumber);
            }
        }
    }

    /**
    * @notice Function - getRandomNumberForMonthlyJackpot
    * @dev Generating only one random number on chain for getting winner of monthly jackpot.
    */
    function getRandomNumberForMonthlyJackpot() private view returns(uint256){
        return uint256(keccak256(abi.encodePacked(block.timestamp,block.prevrandao, owner()))) % usersCount + 1;
    }
}