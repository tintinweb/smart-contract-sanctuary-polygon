/**
 *Submitted for verification at polygonscan.com on 2022-06-03
*/

/**
 *Submitted for verification at polygonscan.com on 2022-06-02
*/

// SPDX-License-Identifier: MIT

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


pragma solidity ^0.8.0;

contract PrismaMovie {
    address public owner;
    address public seller = 0x4001d9D646bB0f6545a5515c942FdE2Da367374D;
    uint256 public transactionIds = 0;
    address public sender;
    event BuyMovie(address from, string to, string film);

    constructor() {
        owner = msg.sender;
    }

    struct Movie {
        address from;
        string to;
        string film;
        uint256 time;
        uint256 price;
    }

    mapping(uint256 => Movie) public Histories;

    //buy with credit card
    function buyMovie(
        string memory  buyer,
        string memory film,
        address token,
        uint256 amount
    ) public payable {
        require(compareTwoStrings(buyer, "") == false, " can't be null");
        require(
            compareTwoStrings(film, "") == false,
            "From can't be null"
        );
        require(IERC20(token).allowance(msg.sender, address(this)) >= amount, "Not Correct");
        IERC20(token).transfer(address(this) , amount);

        Histories[transactionIds] = Movie(
            seller,
            buyer,
            film,
            block.timestamp,
            msg.value
        );

        transactionIds++;

        emit BuyMovie(seller, buyer, film);
    }

     function allowance(address from, address to, address token) public view returns(uint256) {
        require(from != address(0) , "Amount is not correct");
        uint256 amount = IERC20(token).allowance(from , to);
        return amount;
    }

    //get all histories
    function getHistory() public view returns(Movie[] memory histories) {
       for(uint i = 0; i < transactionIds; i++){
           histories[i] = Histories[i];
       }
    }

    //set seller
    function setSeller(address from) public {
        require (msg.sender == owner , "Not owner");
        require (from == address(0) , "Not correct");
        seller = from;
    }

     function compareTwoStrings(string memory s1, string memory s2)
        public
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

}