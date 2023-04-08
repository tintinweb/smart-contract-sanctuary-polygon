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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IDonorNFT {
    function mintReward(address _to, string calldata _rewardTier) external;
}

contract CrowdFunding is Ownable {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
        uint256 campaignId;
        string pdf;
        string video;
        string name;
    }

    mapping(uint256 => Campaign) public campaigns;

    uint256 public numberOfCampaigns = 0;
    uint256 public realNumberOfCampaigns = 0;

    address public rewardNFTcontract; 
    /**
     * Network: Mumbai
     * Aggregator: Matic/USD
     * Address: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada  
     */
    AggregatorV3Interface internal maticUsdPriceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada); // zamjenit adresu za mainet

    function setRewardNFTcontract(address _rewardNFTcontract) external onlyOwner { //postavit onlyowner ili stavit sve u konstruktor DONE
        rewardNFTcontract = _rewardNFTcontract;
    }

     function getLatestPrice() public view returns (uint256) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = maticUsdPriceFeed.latestRoundData();
        return uint256(price); // 1 Matic = 1$ * 1e8 ,  podijelit s 1e8 za dobit cijenu jednog matica u dolarima
    }

    function createCampaign(
        address _owner, 
        string memory _title, 
        string memory _description, 
        uint256 _target,
        uint256 _deadline,
        string memory _image,
        string memory _pdf,
        string memory _video,
        string memory _name
        ) public returns (uint256) {
            require(_deadline > block.timestamp, "Deadline in the past instead of future" );
            require(_target > 0, "Goal value must be greater than zero");
            Campaign storage campaign = campaigns[numberOfCampaigns];

            //is everything correct?
            // require(_deadline > block.timestamp, "Deadline in the past instead of future" );

            campaign.owner = _owner;
            campaign.title = _title;
            campaign.description = _description;
            campaign.target = _target;
            campaign.deadline = _deadline;
            campaign.amountCollected = 0;
            campaign.image = _image;
            campaign.campaignId = numberOfCampaigns;
            campaign.pdf = _pdf;
            campaign.video = _video;
            campaign.name = _name;

            numberOfCampaigns++;
            realNumberOfCampaigns++;

            return numberOfCampaigns - 1;
            

        }

    function donateToCampaign(uint256 _id) public payable {
        uint256 amount = msg.value;

        Campaign storage campaign = campaigns[_id];

        // campaign.donators.push(msg.sender);
        // campaign.donations.push(amount);

        // campaign.amountCollected = campaign.amountCollected + amount;
        // (bool sent,) = payable(campaign.owner).call{value: amount}("");
        // require(sent, "Failed to send Matic");

        uint256 onePercent = amount / 100;
        uint256 remainingAmount = amount - onePercent;

        campaign.donators.push(msg.sender);
        campaign.donations.push(remainingAmount);

        (bool sentToOwner,) = payable(owner()).call{value: onePercent}("");
        require(sentToOwner, "Failed to send 1% to contract owner");

        (bool sent,) = payable(campaign.owner).call{value: remainingAmount}("");
        require(sent, "Failed to send Matic");


        if(sent) {
            //campaign.amountCollected = campaign.amountCollected + amount; // stavit prije slanja i revert ako nije uspjesno slanje zbog sigurnosti
            
            uint256 maticPriceInUSD = getLatestPrice();  // price in USD * 1e8
             // "1e18 wei" is "1 MATIC" (on Polygon)
            uint256 totalDonationValueInUSD = (msg.value * maticPriceInUSD) / 1e18;  // Matic price in USD * 1e8
            IDonorNFT NFTcontract = IDonorNFT(rewardNFTcontract);

            if (totalDonationValueInUSD > (10 * 1e8)) {  // 100000000 = 1 USD ili 1$ * 1e8
                NFTcontract.mintReward(msg.sender, "0"); // gold NFT
            } else if (totalDonationValueInUSD > 50000000) { // 0.50 USD  ili 0.50$ * 1e8
                NFTcontract.mintReward(msg.sender, "1"); // silver NFT
            }
            
        }

    }

// mapping (address => uint) private userBalances;

// function withdrawBalance() public {
//     uint amountToWithdraw = userBalances[msg.sender];
//     userBalances[msg.sender] = 0;
//     // The user's balance is already 0, so future invocations won't withdraw anything
//     (bool success, ) = msg.sender.call.value(amountToWithdraw)("");
//     require(success);
// }b

    function getDonators(uint256 _id) view public returns (address[] memory, uint256[] memory) {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](realNumberOfCampaigns);

        uint j = 0;
        for(uint i = 0; i < numberOfCampaigns; i++) {
            if (campaigns[i].owner == address(0)) continue;

            Campaign storage item = campaigns[i];              
            // allCampaigns[j] = campaigns[i];                  
            allCampaigns[j] = item;
            j++;
        }

        return allCampaigns;
    }

    function getCampaign(uint256 _id) view public returns (Campaign memory) {
        return campaigns[_id];
    }

    function modifyCampaign(
        uint256 _id,
        string memory _title, 
        string memory _description, 
        uint256 _target,
        uint256 _deadline,
        string memory _image,
        string memory _pdf,
        string memory _video,
        string memory _name
    ) public {

        if(msg.sender != campaigns[_id].owner) {
            revert("Can't be modified. You are not the owner.");
        }
        require(_deadline > block.timestamp, "Deadline in the past instead of future" );
        require(_target > 0, "Goal value must be greater than zero");

        campaigns[_id].title = _title;
        campaigns[_id].description = _description;
        campaigns[_id].target = _target;
        campaigns[_id].deadline = _deadline;
        campaigns[_id].image = _image;
        campaigns[_id].pdf = _pdf;
        campaigns[_id].video = _video;
        campaigns[_id].name = _name;
    }

    function deleteCampaign(uint256 _id) public {

        if(msg.sender != campaigns[_id].owner) {
            revert("Can't be deleted. You are not the owner of this.");
        }
        require(realNumberOfCampaigns > 0, "No campaigns to delete");
        delete campaigns[_id];
        realNumberOfCampaigns--;
    }
    
    // constructor() {}

    // Helper functions:
    // function isCampaignDone(uint256 _deadline) public view returns(bool) {
    //     if(_deadline > block.timestamp) {
    //         return true;
    //     } else {
    //         return false;
    //     }
    // }
    
}


//   // Helper function to check the balance of this contract
//     function getBalance() public view returns (uint256) {
//         return address(this).balance;
//     }