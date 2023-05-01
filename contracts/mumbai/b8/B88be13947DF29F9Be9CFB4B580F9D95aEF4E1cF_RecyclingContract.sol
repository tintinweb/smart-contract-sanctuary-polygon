// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Define the smart contract
contract RecyclingContract {

    // Define the variables
    address private owner;
    mapping(address => uint256) private recyclingCounts;
    mapping(address => uint256) private rewards;
    mapping(address => bool) private redeemed;
    uint256 public recycledItems;
    uint256 private rewardThreshold = 100;
    uint256 private maxReward = 100;
    uint256 public exchangeRate;

    // define events for when item is recycled
    event itemsRecycled(address indexed recycler, uint256 total_items);

    // Define the event for when rewards are swapped for Matic
    event rewardsSwapped(address indexed user, uint256 swapAmount, uint256 MaticAmount);

    // Define the events when rewards are redeemed
    event RewardRedeemed(address indexed user, uint256 rewardAmount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /*
    * @dev: recycle items at collection centres.
    *       only 50 items can be recycled at a time
    *       when items recycled is equal to 200, reward recycler 20 points
    * @param: number of items counted and recieved for recycling
    */
    function recycleItems(uint256 itemCount) public {
        // items are recycled in batch of 50 at a time
        require(itemCount > 0 && itemCount <= 50, "50 per batch");
        require(!redeemed[msg.sender], "already redeemed rewards.");

        // Check for potential integer overflow
        require(recyclingCounts[msg.sender] + itemCount >= recyclingCounts[msg.sender], "Integer overflow error.");

        // Add the number of items to the recycling count for the user
        recyclingCounts[msg.sender] += itemCount;

        // If the user has recycled enough items, award them tokens
        if (recyclingCounts[msg.sender] >= rewardThreshold) {
            uint256 rewardAmount = 10;
            // validate recycler does not exceed max reward to redeem
            require(rewards[msg.sender] + rewardAmount <= maxReward, "max reward amount exceeded");
            rewards[msg.sender] += rewardAmount;
            recyclingCounts[msg.sender] -= rewardThreshold;
        }
        recycledItems += itemCount;
        emit itemsRecycled(msg.sender, itemCount);
    }

    /*
    * @dev: redeem all available rewards
    */
    function redeemRewards() public payable {
        // validate recycler has rewards to redeem and check for re-entrancy
        require(rewards[msg.sender] > 0 && !redeemed[msg.sender], "null rewards or already redeemed");

        // Calculate the amount of Matic to transfer
        uint256 amountToRecieve = rewards[msg.sender] / exchangeRate;
        // check smart contract has enough funds to send to recycler
        require(msg.value >= amountToRecieve, "Insufficient Matic ");

        // Prevent reentrancy attacks
        redeemed[msg.sender] = true;

        // Transfer the rewards to the user
        rewards[msg.sender] = 0;
        // Transfer the Matic to the user's wallet
        (bool success,) = payable(msg.sender).call{value: amountToRecieve}("");
        require(success, "not sent.");
        redeemed[msg.sender] = false;
        emit RewardRedeemed(msg.sender, amountToRecieve);
    }

    /*
    * @dev: redeem some amount of rewards
    * @param: amount to be swapped
    */

    function redeemSomeRewards(uint256 swapAmount) public payable {
        // validate amount to be greater than 1
        require(swapAmount > 0, "zero amount");
        // validate recycler reward amount is not lower than amount to swap
        require(rewards[msg.sender] >= swapAmount, "low points");
        uint256 MaticAmount = swapAmount / exchangeRate;
        // Calculate the amount of Matic to transfer
        require(msg.value >= MaticAmount, "Insufficient Matic ");

        // Deduct the points from the user's account
        rewards[msg.sender] -= swapAmount;

        // Transfer the Matic to the user's wallet
        (bool success,) = payable(msg.sender).call{value: MaticAmount}("");
        require(success, "not sent");
        emit rewardsSwapped(msg.sender, swapAmount, MaticAmount);
    }

    /*
      * @dev: set the exchange rate for swapping rewards for $$
      * @param: value of rate set as exchange rate
    */
    function setExchangeRate(uint256 _exchangeRate) public onlyOwner() {
        // validate input is not null and amount is greater tha zero
        require(_exchangeRate > 0 && _exchangeRate != 0, "zero value");
        exchangeRate = _exchangeRate;
    }

    /*
    * @dev: get balance of the smart contract
    */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /*
    * @dev: function to recieve donations for the project
    * @param: amount to send to smart contract
    */
    function donatefunds(uint256 amount) public payable {
        //validate amount to donate is not 0 and sender has enough balance for transaction
        require(msg.sender.balance >= amount, "Insufficient funds");
        payable(address(this)).transfer(amount);
    }

    /*
    * @dev: get all items  ever recycled
    */
    function recycled_items() public view returns (uint256) {
        return recycledItems;
    }

    /*
    * @dev: get total rewards recieved and current items recycled
    */
    function myreward() public view returns (uint256 totalRewards, uint256 currentRecyclingCount){
        return (rewards[msg.sender], recyclingCounts[msg.sender]);
    }

    /*
    * dev: get addres of owner and value of exchange rate
    */
    function getSummary() public view returns (address _owner, uint256 _exchangeRate){
        return (owner, exchangeRate);
    }
  
    receive() external payable {}
}