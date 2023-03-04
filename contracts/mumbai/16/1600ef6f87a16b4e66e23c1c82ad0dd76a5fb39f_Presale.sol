/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: Presale/presale_temp.sol


pragma solidity 0.8.19;
// 0x068F62f072B9c15Df83426C3C6d598d138F930f4



interface erc20 {
    function mint(address to, uint256 amount) external;

}

contract Presale {
    uint256 public immutable minBuy = 10 * 10**2;

    uint256 totalBought;

    int256 private eur_to_usdPrice;

    address private erc20Address;
    address private OwnerIs;

    mapping(address => timestampInfo[]) storeTimeInfo;
    mapping(address => uint256) withdrawAble;

    constructor() {
        OwnerIs = msg.sender;
    }

    struct timestampInfo {
        uint256 tokens;
        uint256 timestamp;
    }

    function CurrentPrice() public view returns (uint256) {
        getEURtoUSDPrice();

        if (totalBought <= 10000000000 * 10**2) {
            return ((getEURtoUSDPrice()) / (10000)) * (10**7);
        } else if (totalBought <= 20000000000 * 10**2) {
            return ((getEURtoUSDPrice()) / (1000)) * (10**7);
        } else if (totalBought <= 30000000000 * 10**2) {
            return ((getEURtoUSDPrice()) / (100)) * (10**7);
        } else if (totalBought <= 40000000000 * 10**2) {
            return ((getEURtoUSDPrice()) / (10)) * (10**7);
        } else if (totalBought <= 50000000000 * 10**2){
            return ((getEURtoUSDPrice()) / (1)) * (10**7);
        }
        else{
            revert ("Already Max Minted, Now Only Owner Can Mint");
        }
        
    }

    function getEURtoUSDPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed;

        priceFeed = AggregatorV3Interface(
            0x7d7356bF6Ee5CDeC22B216581E48eCC700D0497A
        );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function buy(uint256 amount) public payable {
        address caller = msg.sender;

        require(amount >= minBuy, "Low Amount Pass");

        require(msg.value >= (CurrentPrice() * (amount/10**2)), "Low Value Pass");
        IERC20(erc20Address).transfer(caller, (amount));

        storeTimeInfo[caller].push(timestampInfo((amount), block.timestamp));

        totalBought = totalBought + (amount);
    }

    function transfer(uint256 amount) public virtual returns (bool) {
        address caller = msg.sender;

        require(
            IERC20(erc20Address).balanceOf(caller) >= amount,
            "Not Enough tokens abailable"
        );

        timestampInfo[] storage temp = storeTimeInfo[caller];

        for (uint256 i = 0; i < temp.length; i++) {
            if (temp[i].timestamp + 1 minutes <= block.timestamp) {
                withdrawAble[caller] += temp[i].tokens;

                temp[i] = temp[temp.length - 1];
                temp.pop();
            }
        }

        require(
            withdrawAble[caller] >= amount,
            "WithrawAble amount is not enough"
        );

        IERC20(erc20Address).transferFrom(caller, address(this), amount);

        return false;
    }

    function withdraw() external payable {
        require(msg.sender == OwnerIs, "invalid user");
        (bool success, ) = payable(msg.sender).call{value: msg.value}("");
        require(success, "Failed to send amount");
    }

    function withdrawTokens(uint256 amount, address account) public {
        require(msg.sender == OwnerIs, "only Owner Is allowed to call");

        IERC20(erc20Address).transfer(account, amount);
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == OwnerIs, "can be only called by Owner");
        erc20(erc20Address).mint(to, amount);

        storeTimeInfo[to].push(timestampInfo(amount, block.timestamp));
        totalBought = totalBought + amount;
    }

    function transferOwnership(address account) public {
        require(msg.sender == OwnerIs, "only Owner Function");
        OwnerIs = account;
    }

    function setTokenAddress(address tokenAddress) public {
        erc20Address = tokenAddress;
    }

    function checkUserBuyList() public view returns (timestampInfo[] memory) {
        return storeTimeInfo[msg.sender];
    }
}