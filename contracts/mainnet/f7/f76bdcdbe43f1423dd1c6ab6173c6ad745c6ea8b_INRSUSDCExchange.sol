/**
 *Submitted for verification at polygonscan.com on 2023-01-16
*/

//SPDX-License-Identifier: MIT


// StableR INRS - USDC Exchange contract


/**
*   For StableR INRS Stablecoin - Know more about the project at StableR.in/links
*
*   This contract will make the StableR INRS as Stablecoin by pegging the value to Indian Rupee
*
*   It makes 1 INRS = 1 INR always.
*
*   This contract will  get the value of Indian Rupee via Chainlink oracle.
*
*   Using this contract, Users can exchange USDC to StableR INRS and vice versa.
*   
*   Users can simply send the USDC or INRS to this contract and receive the INRS or USDC respectively
*
*   The values of INR/USDC pair price feed via Chain.link - AggregatorV3Interface.sol using INR/USD & USDC/USD pair price feeds.
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/INRSUSDCExchange.sol

// StableR INRS - USDC Exchange contract




/**
*   For StableR INRS Stablecoin - Know more about the project at StableR.in/links
*
*   This contract will make the StableR INRS as Stablecoin by pegging the value to Indian Rupee
*
*   It makes 1 INRS = 1 INR always.
*
*   This contract will  get the value of Indian Rupee via Chainlink oracle.
*
*   Using this contract, Users can exchange USDC to StableR INRS and vice versa.
*   
*   Users can simply send the USDC or INRS to this contract and receive the INRS or USDC respectively
*
*   The values of INR/USDC pair price feed via Chain.link - AggregatorV3Interface.sol using INR/USD & USDC/USD pair price feeds.
*/


pragma solidity ^0.8.0;





contract INRSUSDCExchange {
    
    address public owner;
   

    address stableRINRS = address(0xadA9C4D142B5e8A1e269B9546906804Cb934BD0D);
    address USDC = address(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

    mapping(address => uint) public balanceOf;
    mapping(address => bool) public isApproved;
    mapping(address => bool) internal whitelisted;
    uint public INRSUSDCPrice;

    uint internal inrUsdcPrice;
    bool public paused;


     AggregatorV3Interface internal inrUsdFeed;
     AggregatorV3Interface internal usdcUsdFeed;




    // Threshold for how long the price feeds can go without being updated
    uint256 public updateThreshold = 10 minutes;

    constructor()  {
        owner = msg.sender;
        
         /**
         * Network: Polygon Network
            * Aggregator: USDC/USD
            * Address: 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7
            * Aggregator: INR/USD
            * Address: 0xDA0F8Df6F5dB15b346f4B8D1156722027E194E60

         */
        
         inrUsdFeed = AggregatorV3Interface(0xDA0F8Df6F5dB15b346f4B8D1156722027E194E60);

       
          usdcUsdFeed = AggregatorV3Interface(0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7);
    }

    function setINRSUSDCPrice(uint _INRSUSDCPrice) public {
        require(msg.sender == owner);
        // Check if the oracle's value is updated within the last 10 minutes
        (
            ,
            /*uint80 roundID*/ int inrUsdPrice /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,
            
        ) = inrUsdFeed.latestRoundData();

        (
            ,
            /*uint80 roundID*/ int usdcUsdPrice /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,
        ) = usdcUsdFeed.latestRoundData();

        int latestPrice = inrUsdPrice / usdcUsdPrice;

        /**
        1 INRS = 1 INR always.
        
        */

        if (latestPrice != 0) {
            INRSUSDCPrice = uint256(latestPrice);
           
        } else {
            INRSUSDCPrice = _INRSUSDCPrice;
        }
    }

    function depositINRS() public payable {
        require(msg.sender == stableRINRS);
        balanceOf[msg.sender] += msg.value;
    }

    function depositUSDC() public payable {
        require(msg.sender == USDC);
        balanceOf[msg.sender] += msg.value;
    }

    function depositOtherTokens(address token) public payable {
        balanceOf[token] += msg.value;
    }

    function approveOtherTokens(address token) public {
        require(msg.sender == owner);
        isApproved[token] = true;
    }

   function exchangeINRSforUSDC() public payable {
        require(msg.sender == stableRINRS);
        require(!paused);
        uint amount = msg.value;
        require(balanceOf[stableRINRS] >= amount);
        balanceOf[stableRINRS] -= amount;
          // Calculate the value of USDC to be sent
    uint usdcAmount = amount * INRSUSDCPrice;
    // Check if the contract has sufficient balance of USDC
    require(balanceOf[USDC] >= usdcAmount);
    // Transfer the USDC to the sender
    payable(msg.sender).transfer(usdcAmount);
    // Reduce the balance of USDC in the contract
    balanceOf[USDC] -= usdcAmount;
}

    function exchangeUSDCforINRS() public payable {
        require(msg.sender == USDC);
        require(!paused);
        uint amount = msg.value;
        require(balanceOf[USDC] >= amount);
        balanceOf[USDC] -= amount;
         // Calculate the value of INRS to be sent
    uint inrsAmount = amount / INRSUSDCPrice;
    // Check if the contract has sufficient balance of INRS
    require(balanceOf[stableRINRS] >= inrsAmount);
    // Transfer the INRS to the sender
    payable(msg.sender).transfer(inrsAmount);
    // Reduce the balance of INRS in the contract
    balanceOf[stableRINRS] -= inrsAmount;
}
    function withdraw(address token, uint amount) public {
    require(msg.sender == owner);
    require(balanceOf[token] >= amount); // check if the contract has enough of the token to withdraw
    payable(msg.sender).transfer(amount); // transfer the specified amount to the msg.sender
    balanceOf[token] -= amount; // update the contract's balance
}


       function pause() public {
        require(msg.sender == owner);
        paused = true;
    }

    function unpause() public {
        require(msg.sender == owner);
        paused = false;
    }

    
    fallback() external payable {
        require(!paused);
        if (msg.sender == stableRINRS) {
            exchangeINRSforUSDC();
        } else if (msg.sender == USDC) {
            exchangeUSDCforINRS();
        } else {
            depositOtherTokens(msg.sender);
        }
    }

    receive() external payable {
        require(!paused);
        if (msg.sender == stableRINRS) {
            exchangeINRSforUSDC();
        } else if (msg.sender == USDC) {
            exchangeUSDCforINRS();
        } else {
            depositOtherTokens(msg.sender);
        }
    }

    function addWhitelist(address _address) public{
    require(msg.sender == owner, "Only the current owner can add address to whitelist");
    whitelisted[_address] = true;
    }

    function changeOwner(address newOwner) public {
    require(whitelisted[newOwner], "Address not whitelisted");
    require(msg.sender == owner, "Only the current owner can change the contract owner");
    owner = newOwner;
    }
    /**
     * Modifier to restrict function access to the owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized access");
        _;
    }
}