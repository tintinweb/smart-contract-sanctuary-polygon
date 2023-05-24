/**
 *Submitted for verification at polygonscan.com on 2023-05-24
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File: contracts/EwwLocker.sol

pragma solidity ^0.8.0;

struct TokenFund {
    address tokenAddress;
    uint256 funds;
}

contract EwwLocker {
    mapping(address => mapping(string => uint256)) public funds;
    mapping(address => mapping(address => mapping(string => bool)))
        public allowances;
    mapping(address => mapping(string => uint256)) public lastRetrievals;
    mapping(address => mapping(string => uint256)) public dailyFundsRetrieved;
    mapping(address => mapping(string => uint256)) private dailyLimit;
    mapping(address => mapping(string => address)) private fundOwners;
    mapping(string => address[]) private worldTokenAddresses;
    uint256 private blockStart;

    event AddedFunds(address _from, address _destAddr, uint256 _amount);
    event RetrievedFunds(address _toAddress, uint256 _amount);

    constructor() {
        blockStart = block.number;
    }

    function addFunds(
        address tokenAddress,
        string memory worldId,
        uint256 amount
    ) public payable {
        if (tokenAddress == address(0)) {
            // Native tokens (e.g., Ether)
            require(msg.value == amount, "Incorrect amount of native tokens");
            emit AddedFunds(msg.sender, address(this), amount);
            funds[address(0)][worldId] += amount;
            worldTokenAddresses[worldId].push(address(0));
            fundOwners[address(0)][worldId] = msg.sender;
        } else {
            // ERC-20 tokens
            IERC20 token = IERC20(tokenAddress);
            require(
                token.allowance(msg.sender, address(this)) >= amount,
                "Insufficient allowance"
            );
            require(
                token.transferFrom(msg.sender, address(this), amount),
                "Transfer failed"
            );
            emit AddedFunds(msg.sender, address(this), amount);
            funds[tokenAddress][worldId] += amount;
            worldTokenAddresses[worldId].push(tokenAddress);
            fundOwners[tokenAddress][worldId] = msg.sender;
        }
    }

    function retrieveFunds(
        address tokenAddress,
        address toAddress,
        string memory worldId,
        uint256 amount
    ) public {
        require(
            allowances[tokenAddress][msg.sender][worldId],
            "Address not authorized to retrieve funds"
        );
        require(amount <= funds[tokenAddress][worldId], "Insufficient funds");
        uint256 limit = dailyLimit[tokenAddress][worldId];
        uint256 todayFundsRetrieved = dailyFundsRetrieved[tokenAddress][
            worldId
        ];

        if (
            block.timestamp >= lastRetrievals[tokenAddress][worldId] + 24 hours
        ) {
            todayFundsRetrieved = 0;
        }

        require(
            todayFundsRetrieved + amount <= limit,
            "Amount exceeds daily limit"
        );

        funds[tokenAddress][worldId] -= amount;
        IERC20 token = IERC20(tokenAddress);
        token.transfer(toAddress, amount);
        lastRetrievals[tokenAddress][worldId] = block.timestamp;
        dailyFundsRetrieved[tokenAddress][worldId] += amount;

        emit RetrievedFunds(toAddress, amount);
    }

    function withdrawFunds(address tokenAddress, string memory worldId) public {
        require(
            fundOwners[tokenAddress][worldId] == msg.sender,
            "The msg.sender is not the owner of these funds"
        );
        uint256 amount = funds[tokenAddress][worldId];

        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, amount);
        funds[tokenAddress][worldId] = 0;
    }

    function allowAddress(
        address tokenAddress,
        address allowedAddress,
        string memory worldId
    ) public {
        require(
            fundOwners[tokenAddress][worldId] == msg.sender,
            "Only the fund owner can set allowances"
        );
        allowances[tokenAddress][allowedAddress][worldId] = true;
    }

    function disallowAddress(
        address tokenAddress,
        address disallowedAddress,
        string memory worldId
    ) public {
        require(
            fundOwners[tokenAddress][worldId] == msg.sender,
            "Only the fund owner can set allowances"
        );
        allowances[tokenAddress][disallowedAddress][worldId] = false;
    }

    function getAllFunds(string memory worldId)
        public
        view
        returns (TokenFund[] memory)
    {
        address[] memory tokenAddresses = worldTokenAddresses[worldId];
        TokenFund[] memory result = new TokenFund[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            result[i].tokenAddress = tokenAddresses[i];
            result[i].funds = funds[tokenAddresses[i]][worldId];
        }
        return result;
    }

    function setDailyLimit(
        address tokenAddress,
        string memory worldId,
        uint256 limit
    ) public {
        require(
            fundOwners[tokenAddress][worldId] == msg.sender,
            "The msg.sender is not the owner of these funds"
        );
        dailyLimit[tokenAddress][worldId] = limit;
    }
}